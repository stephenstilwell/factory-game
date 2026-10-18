const fs = require('fs');
const out = 'assets/art/hero';
fs.mkdirSync(out,{recursive:true});
const ink = '#293d3a';
function fillAttributes(color){if(/^#[0-9a-f]{8}$/i.test(color))return 'fill="'+color.slice(0,7)+'" fill-opacity="'+(parseInt(color.slice(7),16)/255).toFixed(4)+'"';return 'fill="'+color+'"';}
function path(d,color,stroke='',width=1){return '<path d="'+d+'" '+fillAttributes(color)+(stroke?' stroke="'+stroke+'" stroke-width="'+width+'"':'')+'/>';}
function rect(x,y,w,h,color,r=0,stroke=''){return '<rect x="'+x+'" y="'+y+'" width="'+w+'" height="'+h+'" rx="'+r+'" '+fillAttributes(color)+(stroke?' stroke="'+stroke+'" stroke-width="1.2"':'')+'/>';}
function ellipse(x,y,rx,ry,color){return '<ellipse cx="'+x+'" cy="'+y+'" rx="'+rx+'" ry="'+ry+'" '+fillAttributes(color)+'/>';}
function line(x,y,a,b,color,width=1){return path('M'+x+' '+y+'L'+a+' '+b,'none',color,width);}
const defs = '<defs>'+
'<linearGradient id="stone" x1="0" y1="0" x2="1" y2="0"><stop stop-color="#c4c1a5"/><stop offset=".45" stop-color="#a6ab96"/><stop offset="1" stop-color="#71827b"/></linearGradient>'+
'<linearGradient id="brick" x1="0" y1="0" x2="1" y2=".3"><stop stop-color="#c39b74"/><stop offset=".4" stop-color="#9d7556"/><stop offset="1" stop-color="#5f5146"/></linearGradient>'+
'<linearGradient id="copper" x1="0" y1="0" x2="1" y2=".8"><stop stop-color="#e0b078"/><stop offset=".4" stop-color="#b88057"/><stop offset="1" stop-color="#725542"/></linearGradient>'+
'<linearGradient id="roof" x1="0" y1="0" x2=".8" y2="1"><stop stop-color="#bc9b76"/><stop offset=".38" stop-color="#7f947e"/><stop offset="1" stop-color="#38565b"/></linearGradient>'+
'<linearGradient id="leaf" x1="0" y1="0" x2=".5" y2="1"><stop stop-color="#c1c28a"/><stop offset=".34" stop-color="#96ae73"/><stop offset="1" stop-color="#3c6b57"/></linearGradient>'+
'<linearGradient id="leaf2" x1="0" y1="0" x2=".7" y2="1"><stop stop-color="#aebd87"/><stop offset=".4" stop-color="#7c9d71"/><stop offset="1" stop-color="#365f52"/></linearGradient>'+
'<linearGradient id="wood" x1="0" y1="0" x2="1" y2="0"><stop stop-color="#c6a77c"/><stop offset=".45" stop-color="#a28560"/><stop offset="1" stop-color="#6b6049"/></linearGradient>'+
'<linearGradient id="cloth" x1="0" y1="0" x2="1" y2=".5"><stop stop-color="#a9b38e"/><stop offset=".4" stop-color="#788e76"/><stop offset="1" stop-color="#405f56"/></linearGradient>'+
'<radialGradient id="fire"><stop stop-color="#fff0b5"/><stop offset=".35" stop-color="#f1bb67"/><stop offset="1" stop-color="#8c4430"/></radialGradient>'+
'<radialGradient id="mist"><stop stop-color="#b0b5a3" stop-opacity=".2"/><stop offset="1" stop-color="#b0b5a3" stop-opacity="0"/></radialGradient>'+
'</defs>';
function save(name,w,h,frames){
 const content = frames.map((frame,i)=>'<g transform="translate('+i*w+',0)">'+frame+'</g>').join('');
 fs.writeFileSync(out+'/'+name+'.svg','<svg xmlns="http://www.w3.org/2000/svg" width="'+w*frames.length*2+'" height="'+h*2+'" viewBox="0 0 '+w*frames.length+' '+h+'" stroke-linecap="round" stroke-linejoin="round">'+defs+content+'</svg>\n');
}
function furnace(frame){
 const hot=frame>0&&frame<5, dead=frame===5;
 let s=ellipse(33,101,25,6,'#243b3533');
 s+=path('M9 89L47 88L57 96L49 103L10 101L5 96Z','#4c6059',ink,1.4);
 s+=path('M10 89L46 88L54 94L17 97L6 94Z','#9b9f88');
 s+=path('M16 61Q13 55 22 52L45 52Q52 55 51 63L51 91Q48 98 33 99Q14 97 13 90Z','url(#brick)',ink,1.5);
 s+=path('M36 54L48 57L48 91Q45 95 36 96Z','#564b3b33');
 for(let y=63;y<91;y+=9){s+=path('M16 '+y+'Q33 '+(y+4)+' 49 '+y,'none','#634e3e',1);s+=line(y%2?25:38,y-7,y%2?25:38,y,'#634e3e',1);}
 s+=path('M16 57Q33 50 50 57L49 63Q33 68 15 62Z','url(#copper)',ink,1);
 s+=path('M19 57Q31 53 45 57','none','#e2c29a',1.4);
 s+=rect(39,40,9,18,'#3d5556',1.5,ink)+rect(37,38,13,5,'#a4b1a2',1,ink);
 s+=line(41,44,41,54,'#92a69a',1.5)+rect(38,50,11,3,'#71887c',.6);
 s+=path('M21 92L21 82Q21 70 33 70Q45 70 45 82L45 92Z','#34443e',ink,1.3);
 s+=path('M24 91L24 82Q24 74 33 74Q42 74 42 82L42 91Z',hot?'url(#fire)':'#273a35');
 if(hot){
  const lift=[0,3,1,4][frame-1];
  s+=path('M27 90Q24 84 30 '+(77-lift)+'Q30 84 34 84Q38 80 37 '+(78-lift/2)+'Q44 85 39 91Z','#f2b25f');
  s+=path('M31 91Q29 86 33 82Q33 87 36 86Q39 91 35 92Z','#fff2be');
  for(let i=0;i<3;i++)s+=ellipse(44+(i%2)*3+(frame%2),31-i*9,8+i*2,5+i*2,'url(#mist)');
 }
 for(let x=26;x<=40;x+=7)s+=line(x,79,x,92,'#6f6b54',1.5);
 s+=rect(20,92,25,3,'#a09b79',1,ink);
 for(const x of [17,47])s+=ellipse(x,95,1.4,1.1,'#d1c3a0');
 s+=path('M14 70L19 71M46 68L49 67M16 85L20 85','none','#d2b28a',1);
 if(dead)s+=path('M28 54L31 64L27 68L33 74M45 90L39 86L42 83','none','#2d3e37',1.6)+path('M15 58L22 59M40 61L47 59','none','#3e4940',2);
 return s;
}
save('furnace',64,112,Array.from({length:6},(_,i)=>furnace(i)));
function tree(frame){
 let s=path('M37 103Q43 92 42 78L37 65L48 70L61 57L58 78L51 88L54 103L63 106L48 104L34 107Z','url(#wood)',ink,1.2);
 s+=path('M45 98L47 76L43 70M49 85L55 75M43 103L45 95','none','#dfc594',1.6);
 const leaf=frame===1?'url(#leaf2)':'url(#leaf)';
 s+=path('M12 59Q5 44 18 37Q15 23 31 23Q38 9 52 18Q67 10 73 26Q90 28 83 45Q95 60 77 68Q74 81 57 75Q42 85 31 75Q13 78 12 59Z',leaf,'#446953',1.4);
 s+=path('M15 57Q21 65 35 58Q47 70 59 60Q73 68 83 51Q89 67 75 68Q68 80 55 73Q42 82 31 72Q16 75 15 57Z','#365e4d66');
 s+=path('M18 38Q21 26 32 29Q37 18 49 23Q40 28 40 38Q29 34 25 45Z','#d0ce944d');
 s+=path('M48 23Q61 15 69 29Q62 25 56 34Z','#e0d5a74d');
 s+=path('M19 49Q27 42 34 45M39 33Q46 30 51 35M57 47Q66 39 74 45M30 63Q38 56 43 60','none','#bdd09a',1.2);
 for(let i=0;i<17;i++){
  const x=19+(i*19)%58, y=29+(i*13)%37;
  s+=path('M'+x+' '+y+'q4 -5 7 -1q-3 5 -7 1Z',i%3===0?'#c2cc8b':'#7d9f68');
 }
 if(frame>=2){
  for(let i=0;i<12;i++){
   const [x,y]=[[27,39],[43,27],[59,33],[74,43],[23,55],[38,60],[56,54],[70,61],[49,44],[34,48],[63,66],[54,24]][i];
   if(frame===2)s+=ellipse(x-2,y,2.8,2,'#e4b9b6')+ellipse(x+2,y,2.5,2.4,'#f2d5c3')+ellipse(x,y+2,2.3,2.5,'#e2b6be')+ellipse(x,y,1,1,'#ead69a');
   else s+=ellipse(x,y,2.8,3.1,'#d3a65d')+ellipse(x-1,y-1,1,1,'#f3d191')+line(x,y-3,x+1,y-5,'#675f3d',1);
  }
 }
 return s;
}
save('tree',96,112,Array.from({length:4},(_,i)=>tree(i)));
function player(frame){
 let s=path('M5 22Q15 17 27 23L29 38L24 41L8 40L3 36Z','url(#cloth)',ink,1);
 s+=rect(frame===2?20:3,23,9,14,'url(#wood)',2,ink);
 s+=path('M8 24L8 38M24 24L23 38','none','#d4bf8a',1.6);
 s+=path('M10 31L21 31L22 40L10 40Z','#537263',ink,.7);
 s+=line(5,38,26,38,'#66513c',2);
 s+=rect(13,37,5,3,'#d8b581',.5);
 s+=ellipse(16,15,9,8,'#bf956c')+path('M7 15Q7 24 15 23L17 21Q9 21 10 15Z','#815f45');
 s+=path('M4 10Q4 1 16 1Q28 1 28 11L24 16L6 15Z','url(#copper)',ink,1);
 s+=path('M5 11Q16 7 28 11L30 15Q17 18 2 15Z','#ccae75',ink,.7);
 s+=path('M7 8Q11 3 18 4M21 4L24 8','none','#edd39d',1.3);
 s+=path('M6 23Q16 26 26 22L24 27L8 28Z','#b67155',ink,.7);
 if(frame!==1){
  const x=frame===2?21:(frame===3?11:16);
  s+=rect(x-7,16,14,4,'#344b46',1);
  s+=ellipse(x-3,18,2.2,1.7,'#b9d4c5')+ellipse(x+3,18,2.2,1.7,'#8eb5aa');
 }else{
  s+=rect(7,23,18,14,'url(#wood)',3,ink)+line(9,25,23,25,'#e1c393',1)+line(16,25,16,35,'#66573e',1);
 }
 s+=rect(25,32,4,6,'#edc17b',1,ink)+rect(25.8,33,2.4,2.4,'#fff0b4',.5);
 return s;
}
save('player',32,44,Array.from({length:4},(_,i)=>player(i)));
function hall(frame){
 const ruin=frame===0, stone=frame===2||frame===4, warm=frame===1||frame===2;
 let s=ellipse(80,151,72,12,'#233b3533');
 s+=path('M15 139L141 139L151 151L139 157L18 155L9 149Z','#526b62',ink,1.6);
 s+=rect(18,92,125,54,ruin?'#889082':(stone?'url(#stone)':'url(#wood)'),2,ink);
 s+=path('M112 92L143 94L143 144L112 144Z','#3e5c5340');
 for(let row=0;row<4;row++){
  const y=104+row*11;
  s+=line(20,y,140,y,stone?'#7c8c7c':'#7e7355',.8);
  if(stone)for(let col=0;col<5;col++){const x=27+col*24+(row%2)*10;if(x<140)s+=line(x,y-10,x,y,'#7c8c7c',.8);}
 }
 for(const x of [23,137])s+=rect(x,91,5,54,'#6b6048',.7);
 s+=path('M10 97L79 48L150 97L150 108L79 67L10 108Z',ruin?'#647565':'url(#roof)',ink,1.5);
 s+=path('M10 97L79 48L79 67L10 108Z',ruin?'#73826a':'#b6aa7a');
 s+=path('M80 50L148 97M13 96L78 51','none',ruin?'#9b9e79':'#d4c69b',2.3);
 for(let row=0;row<4;row++){
  const y=65+row*10;
  s+=line(79+(y-50)*1.4,y,144,96,'#46665f',.6);
  s+=line(79-(y-50)*1.4,y,16,96,'#817b59',.6);
 }
 s+=path('M63 145L63 113Q63 101 80 101Q96 101 96 113L96 145Z','#6c765e',ink,1);
 s+=path('M68 145L68 114Q68 106 80 106Q91 106 91 114L91 145Z','#354f47',ink,1);
 s+=line(80,111,80,145,'#627264',1)+ellipse(86,130,1.6,1.6,'#d6b67a');
 for(const x of [35,113]){
  s+=rect(x-9,111,23,25,'#4b6255',2,ink)+rect(x-6,114,17,19,warm?'url(#fire)':'#304d47',1);
  s+=line(x+2,114,x+2,133,'#917e58',1.5)+line(x-6,123,x+10,123,'#917e58',1.2);
  s+=rect(x-11,136,27,4,'#a99c76',1);
 }
 s+=rect(57,147,47,4,'#aaa98b',1)+rect(52,152,57,4,'#c1b593',1);
 for(const x of [18,127]){
  s+=rect(x,140,17,10,'url(#wood)',1,ink);
  s+=path('M'+x+' 142q4 -12 8 -1q5 -13 10 0Z',warm?'#7b9c6d':'#627963');
  if(warm)s+=ellipse(x+5,139,2,2,'#dfb78b')+ellipse(x+12,138,2,2,'#ead0a0');
 }
 if(ruin){
  s+=path('M80 49L110 70L99 87L78 75L68 88L56 72Z','#304b43');
  s+=path('M70 57L72 82M85 56L86 80M99 68L93 87','none','#a39169',3);
  s+=path('M24 117L49 132M111 119L137 130M68 117L89 138','none','#ad9870',4);
  for(let i=0;i<8;i++)s+=rect(17+i*15,144+(i%2)*6,10,5,'#969781',1);
  s+=path('M28 92L34 105L29 111M124 132L130 139L126 145','none','#52675a',2);
 }
 return s;
}
save('town_hall',160,176,Array.from({length:5},(_,i)=>hall(i)));
console.log('Generated four 2x SVG hero atlases in '+out);
