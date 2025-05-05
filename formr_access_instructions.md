# Accessing FormR Securely

## Option 1: Zero Setup Method (Recommended)

This method requires no setup on your device but will show a security warning.

1. Open your browser and navigate to:
   - https://192.168.2.107

2. When you see the security warning:
   - Click "Advanced" or "More Information"
   - Click "Proceed to 192.168.2.107 (unsafe)" or similar
   - You only need to do this once per browser session

## Option 2: Using Domain Name (Optional)

If you prefer to use a domain name, you'll need to modify your hosts file:

### Windows:
1. Open Notepad as Administrator
2. Open file: C:\Windows\System32\drivers\etc\hosts
3. Add this line at the end: 192.168.2.107 formr.local
4. Save the file
5. Visit https://formr.local in your browser

### macOS/Linux:
1. Open Terminal
2. Run: sudo nano /etc/hosts
3. Add this line at the end: 192.168.2.107 formr.local
4. Save (Ctrl+O, then Enter) and exit (Ctrl+X)
5. Visit https://formr.local in your browser

### Note About Security Warnings:
With either method, you'll see a security warning because we're using a self-signed certificate.
This is normal in testing environments and doesn't mean the connection isn't encrypted.
