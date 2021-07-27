import requests
import traceback

# ===========================================
import os

for k,v in sorted(os.environ.items()):
    print(f'{k:<24} {v}')
# ===========================================


try:
    value = requests.get("https://self.test").text
    if value != 'ok':
        print('Got something other than ok: ' + value)
        exit(1)
    print('Custom CA worked.')
except:
    print('Custom CA cert failed to work.')
    traceback.print_exc()
    exit(1)
try:
    requests.get("https://fail.test")
    print('Accepted a self signed cert! That\'s bad.')
except:
    print('Self signed cert didn\'t work, which is good.')
    exit(0)
exit(1)
