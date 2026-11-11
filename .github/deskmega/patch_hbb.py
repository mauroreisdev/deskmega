# Applies DeskMEGA branding to libs/hbb_common/src/config.rs (run after checkout).
import re, sys
p = sys.argv[1] if len(sys.argv) > 1 else 'libs/hbb_common/src/config.rs'
s = open(p, encoding='utf-8').read()
HOST = 'rd.megawifi.com.br'  # DNS-only (sem proxy Cloudflare): TCP 21115-21117 + UDP 21116
WEB = 'deskmega.megawifi.com.br'
KEY = '16WFXKsxFEYQWPgQI6cVNoyBm25Kdf6wz0MQ0lK5uqY='
subs = [
    (r'pub static ref APP_NAME: RwLock<String> = RwLock::new\("RustDesk"\.to_owned\(\)\);',
     'pub static ref APP_NAME: RwLock<String> = RwLock::new("DeskMEGA".to_owned());'),
    (r'pub const RENDEZVOUS_SERVERS: &\[&str\] = &\[[^\]]*\];',
     f'pub const RENDEZVOUS_SERVERS: &[&str] = &["{HOST}"];'),
    (r'pub const RS_PUB_KEY: &str = "[^"]*";',
     f'pub const RS_PUB_KEY: &str = "{KEY}";'),
    (r'pub static ref OVERWRITE_SETTINGS: RwLock<HashMap<String, String>> = Default::default\(\);',
     'pub static ref OVERWRITE_SETTINGS: RwLock<HashMap<String, String>> = RwLock::new(HashMap::from([\n'
     f'        ("api-server".to_owned(), "https://{WEB}".to_owned()),\n'
     f'        ("relay-server".to_owned(), "{HOST}".to_owned()),\n'
     f'        ("custom-rendezvous-server".to_owned(), "{HOST}".to_owned()),\n'
     f'        ("key".to_owned(), "{KEY}".to_owned()),\n'
     '    ]));'),
]
for pat, rep in subs:
    s, n = re.subn(pat, lambda m: rep, s)
    if n != 1:
        sys.exit(f'patch failed ({n} matches): {pat}')
open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('hbb_common config.rs patched for DeskMEGA')
