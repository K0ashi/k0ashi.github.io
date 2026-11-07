self.addEventListener('push',e=>{var d={};try{d=e.data.json()}catch(x){}
e.waitUntil(self.registration.showNotification(d.title||'Сеня',{body:d.body||'',tag:d.tag,renotify:true,requireInteraction:!!d.sleep,
vibrate:d.sleep?[800,300,800,300,800,300,800]:[200,100,200],icon:'icon.svg'}))});
self.addEventListener('notificationclick',e=>{e.notification.close();
e.waitUntil(clients.matchAll({type:'window'}).then(l=>l.length?l[0].focus():clients.openWindow('./')))});
