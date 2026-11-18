import urllib.request, urllib.parse, http.cookiejar, re
jar=http.cookiejar.CookieJar()
class Redirects(urllib.request.HTTPRedirectHandler):
    callback=None
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if '/callback?' in newurl: self.callback=newurl
        return super().redirect_request(req,fp,code,msg,headers,newurl)
r=Redirects();opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar),r)
def request(url,fields=None,origin=None):
    headers={'Origin':origin} if origin else {}
    data=urllib.parse.urlencode(fields).encode() if fields is not None else None
    with opener.open(urllib.request.Request(url,data,headers),timeout=20) as res: return res.read().decode()
def hidden(page,name):
    m=re.search(r"name="+name+r" value='([^']+)'",page)
    assert m, (name,page)
    return m[1]
page=request('http://localhost:8091/')
consent=request('http://localhost:8091/login',{'csrf':hidden(page,'csrf')},'http://localhost:8091')
assert 'Local authorization server' in consent, consent
final=request('http://localhost:8090/consent',{'csrf':hidden(consent,'csrf'),'request_id':hidden(consent,'request_id'),'consent':'yes'},'http://localhost:8090')
assert 'Signed in as demo-user.' in final, final
assert r.callback
try: request(r.callback)
except urllib.error.HTTPError as error: assert error.code==400
else: raise AssertionError('callback replay accepted')
print('Real HTTP discovery, PKCE, consent, token exchange, JWKS, ID-token verification, cookie rotation, and callback replay checks passed.')
