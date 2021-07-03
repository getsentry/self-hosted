import requests
try:
  value = requests.get("https://self.test").text
  if value != 'ok':
    print('Got something other than ok: ' + value)
    exit(1)
  print('Custom CA worked.')
except:
  print('Custom CA cert failed to work.')
  exit(1)
try:
  requests.get("https://fail.test")
  print('Accepted a self signed cert! That\'s bad.')
except:
  print('Self signed cert didn\'t work, which is good.')
  exit(0)
exit(1)
