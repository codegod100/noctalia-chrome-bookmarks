#!/usr/bin/env node
const http = require('http');
const net = require('net');
const crypto = require('crypto');
const { URL } = require('url');

function log(msg) {
    console.log(`[CDP-Debug] ${msg}`);
}

function error(msg) {
    console.error(`[CDP-Error] ${msg}`);
}

function tryOpen() {
    const url = process.argv[2];
    const newWindow = process.argv[3] === 'true';

    if (!url) {
        error('Usage: open-cdp.js <url> [newWindow]');
        process.exit(1);
    }

    log(`Fetching browser version from http://localhost:9222/json/version`);
    
    const req = http.get('http://localhost:9222/json/version', (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
            try {
                const info = JSON.parse(data);
                const wsUrl = info.webSocketDebuggerUrl;
                if (!wsUrl) throw new Error('No webSocketDebuggerUrl found in /json/version');

                log(`Connecting to WebSocket: ${wsUrl}`);
                sendCdpCommand(wsUrl, url, newWindow);
            } catch (e) {
                error(`Parse Error: ${e.message}`);
                process.exit(1);
            }
        });
    });

    req.on('error', e => {
        error(`Failed to connect to Chrome CDP: ${e.message}. Is Chrome running with --remote-debugging-port=9222?`);
        process.exit(1);
    });
    
    req.end();
}

function sendCdpCommand(wsUrl, targetUrl, newWindow) {
    const u = new URL(wsUrl);
    
    log(`Creating TCP connection to ${u.hostname}:${u.port || 80}`);
    const client = net.createConnection(u.port || 80, u.hostname, () => {
        log('TCP connected, sending WebSocket handshake...');
        const key = crypto.randomBytes(16).toString('base64');
        const handshake = [
            `GET ${u.pathname}${u.search} HTTP/1.1`,
            `Host: ${u.hostname}`,
            'Upgrade: websocket',
            'Connection: Upgrade',
            `Sec-WebSocket-Key: ${key}`,
            'Sec-WebSocket-Version: 13',
            '\r\n'
        ].join('\r\n');
        
        client.write(handshake);
    });

    let handshaked = false;
    client.on('data', (data) => {
        const response = data.toString();
        if (!handshaked) {
            if (response.toLowerCase().includes('101 switching protocols') || response.toLowerCase().includes('101 websocket protocol handshake')) {
                log('WebSocket handshake successful!');
                handshaked = true;
                
                const cmd = {
                    id: 1,
                    method: 'Target.createTarget',
                    params: {
                        url: targetUrl,
                        newWindow: newWindow
                    }
                };
                
                log(`Sending command: Target.createTarget (${targetUrl}, newWindow=${newWindow})`);
                client.write(encodeFrame(JSON.stringify(cmd)));
                
                // Close after a short delay to allow the command to be processed
                setTimeout(() => {
                    log('Closing connection');
                    client.destroy();
                    process.exit(0);
                }, 500);
            } else {
                error(`Handshake failed. Response: ${response}`);
                client.destroy();
                process.exit(1);
            }
        } else {
            log(`Received data after handshake: ${response.substring(0, 100)}...`);
        }
    });

    client.on('error', (e) => {
        error(`Socket error: ${e.message}`);
        process.exit(1);
    });

    client.on('close', () => {
        log('Connection closed');
    });

    // Timeout if no response
    setTimeout(() => {
        if (!handshaked) {
            error('Timeout waiting for WebSocket handshake');
            client.destroy();
            process.exit(1);
        }
    }, 5000);
}

function encodeFrame(text) {
    const payload = Buffer.from(text);
    const length = payload.length;
    let header;

    if (length <= 125) {
        header = Buffer.alloc(2 + 4); 
        header[1] = 0x80 | length;
    } else if (length <= 65535) {
        header = Buffer.alloc(4 + 4);
        header[1] = 0x80 | 126;
        header.writeUInt16BE(length, 2);
    } else {
        header = Buffer.alloc(10 + 4);
        header[1] = 0x80 | 127;
        header.writeUInt32BE(0, 2);
        header.writeUInt32BE(length, 6);
    }

    header[0] = 0x81; // fin + text frame
    const mask = crypto.randomBytes(4);
    mask.copy(header, header.length - 4);

    for (let i = 0; i < length; i++) {
        payload[i] ^= mask[i % 4];
    }

    return Buffer.concat([header, payload]);
}

tryOpen();
