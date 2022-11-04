// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtScript is Ownable {
    string public constant PROJECT_NAME = "Timings";
    string public constant ARTIST_NAME = "1Abstract";
    string public externalLibraryUsed =
        "https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.4.1/p5.min.js";
    string public twofivesixLibraryUsed = "None";
    string public constant LICENSE = "NFT License 2.0";
    string public constant ARTSCRIPT =
        "class e{constructor(){this.useA=!1;let e=function(e){let f=parseInt(e.substr(0,8),16),d=parseInt(e.substr(8,8),16),a=parseInt(e.substr(16,8),16),c=parseInt(e.substr(24,8),16);return function(){f|=0,d|=0,a|=0,c|=0;let e=(f+d|0)+c|0;return c=c+1|0,f=d^d>>>9,d=a+(a<<3)|0,a=a<<21|a>>>11,a=a+e|0,(e>>>0)/4294967296}};this.prngA=new e(inputData.hash.substr(2,32)),this.prngB=new e(inputData.hash.substr(34,32));for(let e=0;e<1e6;e+=2)this.prngA(),this.prngB()}random_dec(){return this.useA=!this.useA,this.useA?this.prngA():this.prngB()}}let f,c,r,t,o=0,b=[],i=1,n=20,m=[],C=[],s=['#ffffff','#000000'],F=['#f4f8fb','#989391','#f4f8fb','#989391','#f4f8fb','#989391','#d7d9dc','#d7d9dc','#141513','#42413f'],B=['#d9e1eb','#9ec9d1','#d9d9d9','#eee8e2','#d8e7e5','#fefefe','#02aad7','#005089','#fac80b','#d9872b','#d9e1eb','#9ec9d1','#d9d9d9','#eee8e2','#d8e7e5','#fefefe','#d9e1eb','#9ec9d1','#d9d9d9','#eee8e2','#d8e7e5','#fefefe','#fefefe','#fefefe','#fefefe'],D=['#faf8f5','#ebe4d8','#ffffff','#fbfbfb','#faf8f5','#ebe4d8','#ffffff','#fbfbfb','#faf8f5','#ebe4d8','#ffffff','#fbfbfb','#315f8c','#db4f54','#fcd265','#a5a29e','#ffffff','#000000'],u=['#232b46','#193147','#3c7792','#c3be68','#d9b36d','#6fa060','#2b283b','#39859c','#1b2743','#72a066','#b88f4f','#abba65','#232b46','#193147','#3c7792','#c3be68','#d9b36d','#6fa060','#2b283b','#39859c','#1b2743','#72a066','#b88f4f','#abba65','#fbfbfb','#232b46','#193147','#3c7792','#c3be68','#d9b36d','#6fa060','#2b283b','#39859c','#1b2743','#72a066','#b88f4f','#abba65','#232b46','#193147','#3c7792','#c3be68','#d9b36d','#6fa060','#2b283b','#39859c','#1b2743','#72a066','#b88f4f','#abba65','#fbfbfb','#d9aaf6'],p=['#f3f3fc','#00003f','#000000','#f3f3fc','#00003f','#000000','#f3f3fc','#00003f','#000000','#f3f3fc','#00003f','#000000','#ffb400'],l=['#f2f2f2','#f9d158','#e9e3d5','#121210','#67655e','#fdfdfc','#54514c','#eedba5','#45433e','#e9e3d5','#807c74','#f4f2eb'],A=['#3f0000','#000000','#fafafa','#010a1c','#013766','#490009','#bc4558'],E=['#f5f1f3','#B1615C','#BF6F69','#CD7D78','#D98A85','#DD9893','#E1A5A1','#E5B4B1','#E8C4C3','#ECD4D6','#E1D2DA','#D4CDDB','#C6C6DB','#B6B6D3','#A6A6CB','#9898C2','#8E8EB7','#8484AD','#77779F','#686891','#5A5A83','#fbfbfb','#000000'],h=['#e8e2be','#aaa78d','#131210','#3d3d35','#e8e2be','#aaa78d','#131210','#3d3d35','#e8e2be','#aaa78d','#131210','#3d3d35','#e8e2be','#aaa78d','#131210','#3d3d35','#e8e2be','#aaa78d','#131210','#3d3d35','#e8e2be','#aaa78d','#131210','#3d3d35','#f2a413','#f34f1c','#fbfbfb'],R=['#d9dee4','#dce1e7','#dbe0e6','#c4651b','#4677c3','#402b7f','#daaf82','#add0e3','#dfd5ae','#e1544e','#d9dee4','#dce1e7','#dbe0e6','#d9dee4','#dce1e7','#dbe0e6','#fbfbfb','#ffffff'],g=['#cec8b8','#cec8b8','#cec8b8','#89847a','#89847a','#89847a','#89847a','#231812','#f3a413','#8a98c8','#8a98c8','#8ab7b5','#8ab7b5','#dad4d8','#ffffff'],k=['#e8dabb','#e8dabb','#e8dabb','#aba28f','#161616','#a62025','#e8dabb','#e8dabb','#e8dabb','#aba28f','#161616','#a62025','#e8dabb','#e8dabb','#e8dabb','#aba28f','#161616','#a62025','#ffffff'],S=['#f7e8ca','#f7e8ca','#f7e8ca','#060406','#f7e8ca','#f7e8ca','#f7e8ca','#060406','#827a71','#448745','#387a3a','#387a3a','#f7e8ca','#f7e8ca','#f7e8ca','#060406','#f7e8ca','#f7e8ca','#f7e8ca','#060406','#827a71','#448745','#387a3a','#387a3a','#ffffff'],G=['#421a4c','#000000','#fafafa','#421a4c','#000000','#fafafa','#421a4c','#000000','#fafafa','#421a4c','#000000','#fafafa','#421a4c','#000000','#fafafa','#421a4c','#000000','#fafafa','#421a4c','#000000','#fafafa','#421a4c','#000000','#fafafa','#90c900','#ffcc01'],X=['#99D0D3','#FCE0D5','#C8C3C9','#99D0D3','#FCE0D5','#C8C3C9','#99D0D3','#FCE0D5','#C8C3C9','#B47EB2','#2E958C','#6288b9','#fceba6','#fac05f','#000000','#ffffff'],x=['#fbf4ec','#c7cfd7','#87a4c0','#ccd7cd','#86aa9b','#635f5c','#1b1d1d','#fbf4ec','#c7cfd7','#ccd7cd','#fbf4ec','#c7cfd7','#87a4c0','#ccd7cd','#86aa9b','#635f5c','#1b1d1d','#fbf4ec','#c7cfd7','#ccd7cd','#ffffff'],T=['#feebdf','#feebdf','#feebdf','#fe9958','#b5d2c7','#d3c3bb','#feebdf','#feebdf','#feebdf','#fe9958','#b5d2c7','#d3c3bb','#252323','#feebdf','#feebdf','#feebdf','#fe9958','#b5d2c7','#d3c3bb','#feebdf','#feebdf','#feebdf','#fe9958','#b5d2c7','#d3c3bb','#252323','#ffffff'],W=['#1f0905','#806c43','#ddcc7e','#ddcc7e','#ddcc7e','#ddcc7e','#ddcc7e','#ddcc7e','#d3c177','#d3c177','#ffffff','#1f0905','#806c43','#ddcc7e','#ddcc7e','#ddcc7e','#ddcc7e','#ddcc7e','#ddcc7e','#d3c177','#d3c177','#ffffff','#1f0905','#806c43','#ddcc7e','#ddcc7e','#ddcc7e','#ddcc7e','#ddcc7e','#ddcc7e','#d3c177','#d3c177','#ffffff','#e1544e','#90c900'],I=['#3B2319','#5F3B1A','#84551E','#AF7C33','#D49F49','#E1B362','#EBC681','#ECD7B0','#D5DBD4','#9BCCE9','#6FB4E3','#5192C3','#3978AB','#276497','#1E4E85','#193974','#2A3A82','#404198','#4F52AB','#5E65BE','#3B2319','#5F3B1A','#84551E','#AF7C33','#D49F49','#E1B362','#EBC681','#ECD7B0','#D5DBD4','#9BCCE9','#6FB4E3','#5192C3','#3978AB','#276497','#1E4E85','#193974','#2A3A82','#404198','#4F52AB','#5E65BE','#ffffff','#000000'],v=['#f7ede3','#f7ede3','#f7ede3','#f7ede3','#f7ede3','#f7ede3','#b6bd32','#cecf6c','#fccd88','#fa9a1b','#0d080c','#756f69','#756f69','#f7ede3','#f7ede3','#f7ede3','#f7ede3','#f7ede3','#f7ede3','#b6bd32','#cecf6c','#fccd88','#fa9a1b','#0d080c','#756f69','#756f69','#ffffff'],w=['#8d1d1e','#5b1815','#451416','#23120f','#f5483a','#086890','#f3483a','#001f4d','#719aa8','#b5911b','#fdf0fe','#ecfff9','#f3fd00','#ee5563','#4a61c1','#f80405','#ffffe7','#8d1d1e','#5b1815','#451416','#23120f','#8d1d1e','#5b1815','#451416','#23120f','#8d1d1e','#5b1815','#451416','#23120f','#8d1d1e','#5b1815','#451416','#23120f','#8d1d1e','#5b1815','#451416','#23120f','#8d1d1e','#5b1815','#451416','#23120f','#8d1d1e','#5b1815','#451416','#23120f'],Z=['#fcf0d2','#a62121','#e84e49','#f7a290','#fadbc0','#861b1b','#000000','#fcf0d2','#a62121','#e84e49','#f7a290','#fadbc0','#861b1b','#000000','#fcf0d2','#a62121','#e84e49','#f7a290','#fadbc0','#861b1b','#000000','#ffffff'],z=['#e5f5fc','#fcf0d2','#02C9AF','#2B4F8D','#011034','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#e5f5fc','#fcf0d2','#02C9AF','#2B4F8D','#011034','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#ffffff'],L=['#E76254','#EA744D','#EE8747','#F2974E','#F6A656','#F9B860','#FDCA6B','#FFD685','#FFE1A7','#E8E3C1','#C0DED5','#9ED5DD','#83C6D8','#6CB4CE','#5D9FBB','#4F8AAA','#42779F','#356592','#295580','#1E466E','#ffffff','#000000'],N=['#fcf0d2','#A40000','#770F27','#4A1E4E','#1D2E76','#104568','#095D4F','#027537','#358E28','#86A71F','#D6C016','#F3BB26','#DD994E','#C67677','#B05889','#9A426E','#842D54','#6B2343','#485464','#248585','#00B7A7','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#fcf0d2','#ffffff','#000000'],P=['#FCFFA6','#C1FFD7','#B5DEFF','#B5DEFF','#CAB8FF','#F6AE99','#F2E1C1','#F0D9FF','#CC5079','#CA9CA9','#FDDB93','#FF9AA2','#FFB7B2','#FFDAC1','#C7CEEA','#97C1A9','#8FCACA','#FFC8A2','#CCE2CB','#C1CFC0','#F29191','#DE8971','#949CDF','#F69E7B','#B590CA','#562349','#39375B','#5C8D89','#00303F'],$=['#f2f2f2','#959595','#242424','#3a3a3a','#0d0d0d'],_=['#e9e3d4','#4c8ab3','#07418d','#d6af98','#3a3746','#e9e3d4','#4c8ab3','#07418d','#d6af98','#3a3746','#ffffff','#000000'],H=['#f1e7e2','#ee533b','#812929','#410504','#480100','#f1e7e2','#f1e7e2','#f1e7e2','#f1e7e2','#f1e7e2','#ee533b','#812929','#410504','#480100','#f1e7e2','#f1e7e2','#f1e7e2','#f1e7e2','#ffffff','#000000'],O=['#f4f1ea','#11244f','#506482','#babf90','#e9e3d5','#e9e3d5','#f4f1ea','#f4f1ea','#f4f1ea','#f4f1ea','#f4f1ea'],j=['#06052e','#9e98ab','#33306a','#0c0b3c','#06052e','#e9e3d5','#e99f47','#012606','#e9e3d5','#9e98ab','#33306a','#0c0b3c','#e9e3d5','#e99f47','#012606'],q=['#f1f2f1','#da7e77','#eb6c70','#ea4e53','#eb666b','#f1f2f1','#f1f2f1','#da7e77','#eb6c70','#ea4e53','#eb666b','#f1f2f1','#f1f2f1','#da7e77','#eb6c70','#ea4e53','#eb666b','#f1f2f1','#f1f2f1','#da7e77','#eb6c70','#ea4e53','#eb666b','#f1f2f1','#000000','#e6a865'],J=['#f5f5f5','#eabdb8','#c5dbe9','#192553','#a6a6a6','#050608','#eabdb8','#c5dbe9','#a6a6a6','#f5f5f5','#eabdb8','#c5dbe9','#a6a6a6','#f5f5f5'],K=['#e9e3d5','#e9cb80','#e99f13','#e76b13','#2e936c','#d9bfb5','#4c3d56','#041e44','#093844','#a8b377','#e9e3d5'],M=['#e3ebe4','#a9bdcc','#5b7ead','#abbecd','#e3ebe4','#050608','#e3ebe4','#a9bdcc','#5b7ead','#abbecd','#e3ebe4','#e3ebe4','#a9bdcc','#5b7ead','#4a71a6','#abbecd','#f05c86','#e3ebe4'],Q=['#eee2c6','#fcf0d2','#bab29c','#413e37','#191919','#bfb69f','#7a7468','#f44a01','#ffffff','#fcf0d2','#eee2c6','#bab29c','#191919','#bfb69f','#7a7468','#eee2c6'],U=['#000000','#2b3070','#9d9cd5','#6c5d9e','#f7b3b0','#be3729','#e29808','#edb457','#ffffff','#f4b8a8','#345828','#aba239'],V=['#FBFBFB','#FBFBFB','#ECCBAE','#046C9A','#D69C4E','#ABDDDE','#000000','#ECCBAE','#FBFBFB','#FBFBFB','#ECCBAE','#ABDDDE','#000000','#ECCBAE'],Y=['#FBFBFB','#FBFBFB','#D3DDDC','#899DA4','#C93312','#FAEFD1','#FBFBFB','#FBFBFB','#D3DDDC','#899DA4','#C93312','#FAEFD1','#DC863B','#FBFBFB','#FBFBFB','#D3DDDC','#899DA4','#FAEFD1','#000000'],ee=['#FBFBFB','#ffffff','#D5D5D3','#F3DF6C','#CEAB07','#FBFBFB','#ffffff','#D5D5D3','#CEAB07','#24281A'],fe=['#315f8c','#fbebd7','#FBFBFB','#F1BB7B','#FD6467','#5B1A18','#D67236','#fbebd7','#FBFBFB','#fbebd7','#F1BB7B','#fbebd7','#fbebd7','#FBFBFB','#fbebd7','#F1BB7B','#fbebd7','#000000'],de=['#feefec','#dbcecc','#6f6a6b','#312f32','#272629'],ae=['#8093a6','#516d94','#343e4c','#d47985','#cc959c','#c7bfb3','#94798b','#39394c','#102440','#000000','#ffffff'],ce=['#fceed3','#fceed3','#fceed3','#dac6ae','#dac6ae','#77231b','#77231b','#fceed3','#fceed3','#fceed3','#dac6ae','#dac6ae','#77231b','#77231b','#c3a894','#aa8474','#5482a2','#bd3937','#10354f'],re=['#0d0d2b','#2e2d4d','#8988a8','#fef853','#1949a0','#302f52','#9d9bc0','#383552','#1a193d','#ba9e11','#0d0d2b','#2e2d4d','#8988a8','#302f52','#9d9bc0','#383552','#1a193d','#0d0d2b','#2e2d4d','#8988a8','#302f52','#9d9bc0','#383552','#1a193d','#0d0d2b','#2e2d4d','#8988a8','#302f52','#9d9bc0','#383552','#1a193d'],te=['#f43624','#3b58cc','#fdd730','#deecf7','#efeef1','#d7dae3','#d0cfe2','#ffffff','#deecf7','#efeef1','#d7dae3','#d0cfe2','#ffffff','#deecf7','#efeef1','#d7dae3','#d0cfe2','#ffffff'],oe=['#fbf4ec','#d8cfac','#eeead7','#ec8334','#f07a22','#669194','#d04815','#345156','#1b687a','#6d5721','#dfd6b5','#000000','#eeead7','#eeead7'],be=['#0a0702','#2e291b','#0f0901','#252325','#0a0702','#2e291b','#0f0901','#252325','#f75179','#d61c22','#002f9c','#0d3cab','#1bbb69','#067c2b','#ebc337','#fe8600','#0a0702','#2e291b','#0f0901','#252325','#0a0702','#2e291b','#0f0901','#252325'],ie=['#db4f54','#261c15','#d12a2f','#e57d32','#fcd265','#fcbc19','#f7b1a1','#e0d7c5','#b8d9ce','#29a691','#121a33','#1f3359','#315f8c','#7ca9bf','#543e2e','#000000','ffffff'],ne=['#624f87','#402f63','#8f6f87','#fbe582','#f6da1f','#e9b52e','#6b6dc1','#d08138','#000000','#000000','#000000','ffffff'],me=[s,F,B,D,u,p,l,A,E,h,R,g,k,S,G,X,x,T,W,I,v,w,Z,z,L,N,P,$,_,H,O,j,q,J,K,M,Q,U,V,Y,ee,fe,de,ae,ce,re,te,oe,be,ie,ne];function setup(){let f=new e;seed=int(123456789*f.random_dec()),randomSeed(seed),noiseSeed(seed),pIndex=floor(random(0,me.length)),pal=me[pIndex],b=pal[floor(random(0,pal.length))],aspectRatio=.5;let d=window.innerHeight,r=window.innerWidth;r/d<aspectRatio?(createCanvas(r,r/aspectRatio),c=r/1800):(createCanvas(d*aspectRatio,d),c=d*aspectRatio/1800);let t=[365,375,380];xOffset=random(0,500),int=t[floor(random(t.length))],size2=random(12,22),diceNoise=random(.35,.39),noiseDetail(4,diceNoise),diceStroke=random(0,1),diceStrokeCol=random(0,1),diceStrokeRectW=random(0,1),diceRGB=random(0,1),diceShape=random(0,1),diceContext=random(0,1),diceRect=random(0,1),diceRotate=random(0,1),diceGradDiff=random(0,30),diceGradStrength=random(70,90),prob00=random(0,1),dTransp=random(20,100),dicePointInt=random(0,1),dicePointInt2=random(25,42),a=.0174533,diceRotSpeed0=[a/2,a,a/2,a,1.5*a,1.5*a,150*a,300*a,600*a,1200*a,1500*a,3e3*a,6e3*a,1e4*a,12e3*a],diceRotSpeed1=floor(random(diceRotSpeed0.length)),diceRotSpeed=diceRotSpeed0[diceRotSpeed1],i=1,rotAmp=2,rectDiv=random(14,20),diceAmplit0=[.01,1,100,200,450,550,550,550,550,550,600,650,700,1e3],diceAmplit1=floor(random(diceAmplit0.length)),diceLengthX=random(1750,1950),diceAmplit=diceAmplit0[diceAmplit1],diceZoom0=[random(5e-4,8e-4),random(8e-4,0,3),random(.003,.006),random(.003,.006),random(.003,.006),random(.003,.006),random(.006,.0095),random(.006,.0095),.005],diceZoom1=floor(random(diceZoom0.length)),diceZoom=diceZoom0[diceZoom1],diceRectXGrad=random(1.4,2.3),diceDim=random(0,1),diceFill=random(0,1),diceXshift=random(1,11),s5=random(12,18),s6=random(12,18),diceTime=random(0,1),randContext=random(151,228)*c,frameRate(60),background(b);for(let e=0;e<n;e++)m.push(random(1500,2100)),C.push(random(-200,3800));angle=2,speed0=[random(.0018,.005),random(.0018,.005),random(.0018,.005),random(.0018,.005),random(.005,5)],speed1=floor(random(speed0.length)),speed=speed0[speed1],pointType=random(0,1),scalar=random(250,600),dFiR=random(2,5),xt=random(-200,2e3),yt=random(-200,3800),diceStripe=random(0,1),diceFrame=random(0,1)}function draw(){randomSeed(seed),noiseSeed(seed);millis();function e(e){drawingContext.setLineDash(e)}diceContext<.6||diceContext>.35&&e([randContext,randContext]),push(),e([]),fill(0,0,0,0),stroke(b),strokeWeight(55*c),rect(28*c,28*c,1748*c,3545*c),pop();let f=0,a=random(me);function r(e,d,r,t,b){if(frameCount>e)for(let e=-180;e<3600;e+=random(50,d)){noiseDetail(4,diceNoise+.09);let d=1+noise(e);hex1=random(a);const i=Fe(hex1);diceRGB<.18?stroke(i.r,i.g-diceGradDiff+e/diceGradStrength,i.b,255-e/dTransp):diceRGB>.18?stroke(i.r-diceGradDiff+e/diceGradStrength,i.g,i.b,255-e/dTransp):diceRGB>.36?stroke(i.r,i.g,i.b-diceGradDiff+e/diceGradStrength,255-e/dTransp):diceRGB>.54?stroke(i.r+diceGradDiff-e/diceGradStrength,i.g,i.b,255-e/dTransp):(diceRGB>.7||diceRGB>.88)&&stroke(i.r,i.g,i.b+diceGradDiff-e/diceGradStrength,255-e/dTransp),angle+=speed;for(let a=random(0,b);a<=b/d;a+=random(5,10)){y=map(noise(f,o),0,1,-20,0);let d=diceZoom,b=diceAmplit;random(139*c/t,140*c/t)-r*frameCount*random(1*c,1.5*c)<-188*c?strokeWeight(random(2.3,3)*c):random(139*c/t,140*c/t)-r*frameCount*random(1*c,1.5*c)>.01*c&&strokeWeight(random(139*c/t,140*c/t)-r*frameCount*random(1*c,1.5*c)),point((a+random(12)+cos(1.25*angle)*scalar)*c,(random(10)+noise(a*d)*b+80+e+50*noise(a)-250+sin(angle)*scalar)*c),f+=5}o+=5}}function t(){push(),translate((xt-9*frameCount)*c,(xt+1500*noise(frameCount/100))*c),rotate(diceRotSpeed*frameCount*i),fill(0,0,0,0),stroke(b),diceTime<.6&&diceRotate>.45&&((80*.3622-frameCount/4)*c>-5*c?strokeWeight((36.22-frameCount/4)*c):(36.22-frameCount/4)*c<-5*c&&strokeWeight(.6*c)),(80*.3622-frameCount/4)*c>-1*c?strokeWeight((80*.3622-frameCount/4)*c):(80*.3622-frameCount/4)*c<-1*c&&strokeWeight(.6*c),rect(0,0,1400*c,1400*c),pop()}function s(){push(),hex2=random(a);const e=Fe(hex2);s55=s5+800*noise(frameCount/1500),s66=s6+800*noise(frameCount/1500),diceStroke<.2?strokeWeight((random(size2,size2)-frameCount/8)*c):diceStroke<.4?strokeWeight(0+frameCount/random(5,50)*c):diceStroke<.6?strokeWeight((0+frameCount/91)*c):diceStroke<.85?strokeWeight((9-frameCount/random(17,24))*c):diceStroke>.85&&strokeWeight((9-frameCount/25)*c),diceStrokeCol<.15?stroke(random(a)):diceStrokeCol<.3?stroke(random(255)):diceStrokeCol<.45?stroke(255-frameCount/1.05+random(255)):diceStrokeCol<.65?stroke(e.r,e.g,e.b,255-frameCount/4.5):diceStrokeCol<.75?stroke(e.r-frameCount/5,e.g,e.b,255):diceStrokeCol<.9?stroke(e.r,e.g-frameCount/5,e.b,255):diceStrokeCol>.9&&stroke(e.r-frameCount/5,e.g,e.b-frameCount/5,255),diceFill<.3?fill(e.r-frameCount/diceRectXGrad,e.g-frameCount/diceRectXGrad,e.b-frameCount/diceRectXGrad,255-frameCount/diceRectXGrad*1.5):diceFill<.45||diceFill<.5?fill(e.r+frameCount/diceRectXGrad,e.g+frameCount/diceRectXGrad,e.b+frameCount/diceRectXGrad,255-frameCount/diceRectXGrad*1.5):diceFill<.75?fill(e.r-frameCount/diceRectXGrad,e.g-frameCount/diceRectXGrad,e.b-frameCount/diceRectXGrad,255-frameCount/diceRectXGrad*1.5):diceFill<.85?fill(e.r-frameCount/diceRectXGrad,e.g-frameCount/diceRectXGrad,e.b-frameCount/diceRectXGrad,0+frameCount/diceRectXGrad*1.5):diceFill>.85&&fill(e.r+frameCount/diceRectXGrad,e.g+frameCount/diceRectXGrad,e.b+frameCount/diceRectXGrad,0+frameCount/diceRectXGrad*1.6)}if(f=0,diceRotate>.45?(r(0,1e3,1.5,1,2100),r(175,random(400,1200),.64,1.05,2200)):diceRotate<.45&&(r(0,1e3,1.5,1,2100),r(50,1500,.95,9,2100),r(175,1500,.64,1.05,2200),r(198,700,random(1.3,1.4),1.05,2200)),diceRotate<.45){for(let e=0;e<n;e++)s(),push(),diceDim<.12?(rect((m[e]-9*frameCount)*c,(C[e]+1500*noise(frameCount/100))*c,random(300)*c,random(300)*c),diceStripe<.95&&t()):diceDim<.6?s66<280?(d=280-s66,rect((m[e]-9*frameCount)*c,(C[e]+1500*noise(frameCount/100))*c,(s55/rectDiv+d)*c,(s66+d)*c),diceStripe<.95&&t()):s66>280?(rect((m[e]-9*frameCount)*c,(C[e]+1500*noise(frameCount/100))*c,s55/rectDiv/1.5*c,s66/1.5*c),diceStripe<.97&&t()):s66>300&&(d=s66-300,rect((m[e]-9*frameCount)*c,(C[e]+1500*noise(frameCount/100))*c,(s55/rectDiv-d)*c,(s66-d)*c),diceStripe<.95&&t()):diceDim>.6&&(s66<180?(d=180-s66,rect((m[e]-2e3+9*frameCount)*c,(C[e]+1500*noise(frameCount/100))*c,(s55/rectDiv+1.5*d)*c,(s66+1.5*d)*c),diceStripe<.95&&t()):s66>180&&(rect((m[e]-2e3+9*frameCount)*c,(C[e]+1500*noise(frameCount/100))*c,s55/rectDiv*c/1.5,s66/1.5*c),diceStripe<.95&&t())),diceTime<.6||diceTime>.6&&pop();pop()}else if(diceRotate>.45){hex2=random(a);Fe(hex2);prob00<.5&&(prob0=random(0,1),prob0<.0089&&(i*=-1)),diceTime<.6&&diceRotate>.45?n=24:diceTime>.6&&diceRotSpeed>2.6?n=12:diceTime<.6&&diceRotSpeed<2.6&&(n=20);for(let e=0;e<n;e++)push(),s(),r1=random(1,480),r2=random(1,480),d1=r1-300,d2=r2-300,translate((m[e]-9*frameCount)*c,(C[e]+1500*noise(frameCount/100))*c),rotate(diceRotSpeed*frameCount*i),diceDim<.55?rect(0,0,(r1-d1)*c,((r2-d2)/15+frameCount/2.5)*c):diceDim>.55?rect(0,0,((r1-d1)/1.4-frameCount/dFiR)*c,((r2-d2)/1.4-frameCount/dFiR)*c):diceDim>.85&&rect(0,0,((r1-d1)/52+3*frameCount/dFiR)*c,((r2-d2)/52+3*frameCount/dFiR)*c),diceTime<.6||diceTime>.6&&pop();pop()}function F(f){frameCount>f&&(diceFrame<.15&&(push(),e([]),fill(0,0,0,0),stroke(b),strokeWeight(55*c),rect(28*c,28*c,1748*c,3545*c),pop()),noLoop())}push(),e([]),fill(0,0,0,0),stroke(b),(36.22-frameCount/4)*c<-1?strokeWeight((36.22-frameCount/3)*c):strokeWeight(-1),rect(35*c,34*c,1730*c,3530*c),rect(50*c,50*c,1730*c,3530*c),pop(),diceTime<.6?F(198):diceTime>.6?F(280):diceTime>.9&&F(300)}function Fe(e){e=e.replace(/^#?([a-f\\d])([a-f\\d])([a-f\\d])$/i,(function(e,f,d,a){return f+f+d+d+a+a}));var f=/^#?([a-f\\d]{2})([a-f\\d]{2})([a-f\\d]{2})$/i.exec(e);return f?{r:parseInt(f[1],16),g:parseInt(f[2],16),b:parseInt(f[3],16)}:null}";
    string public constant HEAD =
        "<meta name='viewport' content='width=device-width, initial-scale=1, maximum-scale=1'> <style type='text/css'> html{height: 100%; width: 100%;}body{height: 100%; width: 100%; margin: 0; padding: 0; background-color: rgb(40, 40, 40);}canvas{display: block; max-width: 100%; max-height: 100%; padding: 0; margin: auto; display: block; position: absolute; top: 0; bottom: 0; left: 0; right: 0; object-fit: contain;}</style>";

    function projectName() external pure returns (string memory) {
        return PROJECT_NAME;
    }

    function artistName() external pure returns (string memory) {
        return ARTIST_NAME;
    }

    function externalLibrary() external view returns (string memory) {
        return externalLibraryUsed;
    }

    function twoFiveSixLibrary() external view returns (string memory) {
        return twofivesixLibraryUsed;
    }

    function license() external pure returns (string memory) {
        return LICENSE;
    }

    function artScript() external pure returns (string memory) {
        return ARTSCRIPT;
    }

    function head() external pure returns (string memory) {
        return HEAD;
    }

    function setExternalLibrary(string calldata _externalLibraryUsed)
        external
        onlyOwner
    {
        externalLibraryUsed = _externalLibraryUsed;
    }

    function setTwoFiveSixLibrary(string calldata _twoFiveSixLibraryUsed)
        external
        onlyOwner
    {
        twofivesixLibraryUsed = _twoFiveSixLibraryUsed;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}