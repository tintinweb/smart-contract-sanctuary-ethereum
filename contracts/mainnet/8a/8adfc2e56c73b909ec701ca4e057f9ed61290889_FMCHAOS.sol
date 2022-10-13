// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: feel my chaos
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    mr|wTxmKB$WdMZIG})zXyPKdGz;|Vxv|<vr~<*)r):<^=xu)xxxr^<*!^=rvv|LY)xi}uYViY}i)rc}vYv|YTVLVXulykXXkIscuckzVlT}}vcwXwzVkycczXYVcVlcVVYLTllLTVV}lcuTzmOMwyy    //
//    d^,|zY##@BgggORZVulVkwlWKzVsk|rrxuvVV)".-,<xv<~)v)^^)!:-:_*x*rvv^xr^v^**_=!!^"-=YVLT=x*krrVTwVlY<*)vvkXcyzzwkzIzkXzmzXzkViTXwTVyuLYcTTiLuTTY}kclwkTL}V    //
//    T^~!|lQ##BbRDRO3cTVl}ixVw}))v*vylV)^Y^_-_:xx)~:"!|T}Lvilv_~!_:;)==~rxv*=.```-``-=*^vvl^k)}}LcyyYv*rYiVkTx}yywXIskIVc|xlIcVVywlTVc}iLTLiiuY}LLTiuuPxxLk    //
//    ~=:)x|$QQOOZDDMwi)VyTXwTc*=i)uriV9mLyv<^)*l^!-__-.xr^:~v^,;:__"=^--"=L)!v))rv!_ '^vcuz|wwzywwylcxLxv}TV}VlkucyyyksVkVVzzwkzwuY}l}TuYYV}Lyu}xVzYvylxvxV    //
//    =;^|yID9OmMGX3zyKxzVvc*Y}uiYlGx|xvLyWrxzTVVvTr":=_**::;)|Y*^<r<=:,:)uY}ir!=:|r_`.,*r)rx::lxxuiluV}uLYuTxTcluVykkVuvwXXsywxIkswVVcTVkzkVyIVu}TkclzyxixV    //
//    x!=rVwgBgGOs9yPlKmku}WcV))r^v)rx^)<TVi*xXL}r)u^kux*x;^)**rxu;<;x="_"*))Tr<uxVyuLvx)v^rxYvxlcLx}lyLXTVL}yyyIwXKXPI3sKiIO$B##VV)xurxxc}uulXwVlVuLTmyxx}y    //
//    IQdxvYIOBMmDzukzkmYxrwY)L*~;)=|l)^!*i)^!<}xvTccKG3X3VTkvur)x~i*=~*=!^^uTXwV}zTVv}Tvuxr*Vxrv:!*r}}xy*iuuVPmXwuIW0$QQB#@@@@@#Y)l~)X}lluzyT}TVyyVlVMwYVuu    //
//    ,xLvcxVGP0MK3sGKluxczTv=*^;~)~;;<rx}}x:^)Vi|ixx)LXWVwYVxwxvr*xLVwuxuyT)r)T^;)Vwz}wx;i):xvvYxuLzVsMOdO98QBB##@@@@@@@@@@@@@@0VwyTwmkykkmzXwlVlVcTwXIyzVi    //
//    rkxrxx|YwwszIzGsyLlxvrPd$W3WZmXKmMWW$gMPgZWsGMWdGWMMZdPsZGWwzsMRObD$D9OMDZWWMRQg0B#B#B8###@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@kIV^vyzskVksmzGmkTkMVcKIzXsz    //
//    Q$Kix))xYczzYLILxLL<)xRgRgQ#@#gBB#QB##Q8##@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@yIIVmkLv*)zmIXsXVuXPuuzTYxxu    //
//    Q#WTY))xTlX33iyv)xxxYvcBQ#[email protected]#QQQ0g##B#@@@#@#@@@@@###@#@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BVw}wTVyVLx;xl}VccYuwVLsVT}xx    //
//    0$MTWmmOBgOQBdQWIVYx)[email protected]@##@8B#B###@@@@@@@@@@@@@@@#Q###@##@@@@@@#@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@QLVXckwxLVwkmV}LwyVlxVuyTlxxxi    //
//    BDgd$ysgRbM8#[email protected]@[email protected]@##gQQ0Ggg$Q9O##B###@@#@##B#@@@@#B###@@@#0QQBB##BB#BBQgQ#@@@@@@@QOOOGZVvTx=!=^|YxkwlcVVXzzyT}Vur*^VLYxiyV    //
//    MbBQZsQBZKXZPKgbbZGOmO$DdzYlxv)r*)vcLr^~*#@@@@#B;v*~:,,--'-_.`!~,=!",'`.ZQB##O._--"::_.- `'__.,:v*^:[email protected]#QB#DxxY)*x)!:=:!:-!:,xVkzwVXyVTyTuVYVVIPzvIPy    //
//    [email protected]#gWPRwMMZOkcKZ9bmKksw|vv)!!=*:,-_;B#gBBgO'_-_,-.`'-_```"_'```   `GQD#Qg:--."):.-.``-.!__:*:|r|[email protected]@@@#@QT|xY::^xx|vr~))~-*|TwuTVuLuY=!v}zcXwyl3zx    //
//    MBB##QB##mMPdOg$QgWlXKkKIY=ixTTzYVx)):"!v#BQB#QZ!r*)=:_-.--``._``_:-'`,:$#[email protected]@@)"-"-)l:_::_,_:~=)xrLxr)#@@@@@@D|~<v)=_":,,--_-_-"=xullu}Vur^YyYlvvylmuu    //
//    BQQ9gQgK0zz}l}sODOGwLziuiLx}LXzIyx;||<[email protected]@@@@@RTz):v)-`-..``.-.-"=--'!)[email protected]#@@@_,-"_,i)!_::!;!;:*v^r=|^[email protected]@@@@@gxv*v^^_:!~===_")vxYc}TLxxxi*xulyl}Y}x)v)    //
//    QDRQDDObOmgIscwWOOZW}cyzGG3mTlysT}LGr"[email protected]@#@@@G;rVViY! --```.':_`''._,:[email protected]#@@@,:)<*vx<!_:":~*=:v)iwcc*[email protected]@@@@@QLiuyL|)L)ilTlTVlL)uVYTuxxxlivvVyul|vxvi;    //
//    #QgQ0sMQPu}x3wPg#8M$OmbO$$bPzTxVOQ0#@#B0Q#Q##@@#[email protected]@@@g|,:"-_",__,,,:==;;[email protected]@@BQ^r*^rX}!=!;<*|rx||[email protected]@@@@@@@@@@@@@@@BTzwI3ViLwkVVYcVXwXcwwkyVVkIVxVVY)}L    //
//    @@@@[email protected]@@@@@@@@@@#@[email protected]@@@@@@@@@@@@@@@#BBB#g#[email protected]@@#@@@@##@#@@@@@@#[email protected]@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@0lwVVVVXyXzXXyVkmz|VIIXVwTxv)^    //
//    @@#BOYY}x)vibGbdOQ8$kTzOcL#@@@@@@@@#@@#@@@@@@@@@@@@@@@@@@@@########B###@@@@@@@@@@@@@@#@##@@@@@@[email protected]@@@##@@@@@@@@@@@@@@@@@@#BKwwws3zsXIVcwIsVs3IsksmuT3d    //
//    [email protected]@#BR$dmwwWMVIkKIYv!^*}<*[email protected]@@@@@@@#B#@@@@@@@@@@##@##B#@#BQQBB8BQQQBBB#@@#@#@#@@@@BBQG8QB#QB#######QB#[email protected]@@@@@@#@#$g######QIywTxwXsLcL}lcwwsm3mIcVXyyM3    //
//    [email protected]#B09WmuL=kxmwwyr<*;=r^xVxVx:^^3Yl=^[email protected]@@@@@@mcrxlv**vY:,-,!!:!LdBOzxwgBB###dMg##G*!vvVLc)[email protected]@@@@@@@Rcv)TkRzx}VkVXVlXmz|)vLVIkzsKKIkyVkVkP0    //
//    Q#BBQdPWK}TV3uWWyc**^,:vlluVvx)*rx=!!:*[email protected]@@@@@#Tr!:":rL}r``'--*sg#P^-!!~^;vKYr^^*[email protected];[email protected]@@@@@@#XlL*wuir)}VI}XxvYlyxxwYuXIKmXKmkVIKcKPD    //
//    QMbBQgWwIx}zXwXIYv)^;",=;x*T)xlc}r^^,-:#@@@@@@@8mWXTYYywyx)XO#$Icr;=:,=;=:~v<<=^*)^rP#@$PziV)VwszsX|[email protected]@@@@@@BYlxruzuxLcVwVTVkkGMs3ZmIKGmMmMMGlVG3POP    //
//    RQ9#Q93PdGKliYyVYvr=;:^}*cT}x}cixx*=,,*@@@@@@@BumzG$QggQD$MWV^r*;^^)r^r|=~rDVx|)|)|v=*b#@#[email protected]#@@@@@@@#Vc})VzVz}lyyT}kwwI3IKKkmywIKzGMycVW3IMR    //
//    bO$##MzKD$mzcxV3}*s)*^xL~ullxzIkVm}[email protected]@@@@@@QLxYiTlivx;*r**~*v)<;**^)|)[email protected]<)xVR$DQ######[email protected]@@@@@@@cxVczVIMTx}TluVVlkzkVWyw}lVcYVwLLiucVVO    //
//    cVMPRmkW$Oi^YyssksKs*)*:r:v<|KY<!rx))[email protected]@@@@@@#sPsXzVTwy}kuwW}uVucv)[email protected]@@@@@@@@|rLyvv^iVLuTyIuuluVckcXcyTVlY}}uciLxxKM    //
//    VvuRQ0X$D3i**=TG)rvir*T^V^*x}[email protected]@@@@@#0*==*;^^ui)[email protected]}[email protected]|[email protected]@@@@@@@vrx^:=,,_~xT}}xYV}LcyXm3OOdwcIcVL|||)kw    //
//    bcsORGVXmkix}vvci*xr^=^|)*^^**xYw}[email protected]@@@@#8Pr;*rvYv||<|[email protected]}[email protected]@@@@@@@@Y::ir=-""-"c3K3WOMZs9XGVzkxr^^)uVzVLYLz    //
//    Q8KIwlckyXV}yiix"-:::"*v|^!^r*x}lXVmc}[email protected]@@@@@#Mx)vril^)):!*W#GywTr)r;;xIr*::=rvvi}xYx)TVR#kwVuyk}}[email protected]@@@@@@@3xryr:!_:-_!ks3kVVukzKuxLYv)*^rvYLTxx3i    //
//    ggMRKcyyzY**uYzur:!=!,~^)*:r)|ucyl}Xyx#@@@@@@Bz||^)));^x;*rwIvryu^)vvTuVTx=:;:rYrL)L*;[email protected]@@@@@@@@b*yY<":!,";YckVTyyTIPGKLwlxrr)lTTx)xv}l    //
//    #bVbP3sWMX*=urmmlY}yzlwzVTv*[email protected]@@@@@@@dyuxi*)<|x;*vxr)lV}rvuY=*)~<^!:~r)xvxxvrLkQQVusYyPPcTci}[email protected]@@@@@@$luVTTcr~rVz}iLL}VTTmOPyuVxxxLv}llTcT|z    //
//    XY}wV3GMkWz)sXXwykPIKkwYIwL^*[email protected]@@@@@@@GwlxTLwYlu|uXs)Lk}luxcx*;v^^;*^v)vLVkyyvivLxvws)Xb}[email protected]@@@@@@#vy)}uc}iVVcYlYcuYvLIV}xxLixxlzYylz}uyV    //
//    WYuVclLmMbIzGwGXVwssz}wcIyT)[email protected]@@@@@@@ukw)=:TVIX}ylkx;s###Q##QQBg$#8RgQQQ#[email protected]@@@@@@@IVrVuyylcyVl}xL))!<lwcvrv))))x|ysKwTmk    //
//    WVkTVVvymIsMMIdZXsPKsyIccw}|)T}[email protected]@@@@@@#wGIkyTzxVV)lssTYcTVT}gMrT}[email protected][email protected]*rrvxx|[email protected]@@@@@@@bu*cxuwcxTYivxixx)YXzVLiTx}xTVricwwXId    //
//    B##RbViswkXOOc9QPmGZMsVx))[email protected]@@@@@@BwwwkuVu)iY*)[email protected]#[email protected]@@@@@@@@Bx)Vr}Llxyli}uGsGuV}TLl}ciTVskVlsbbXI3    //
//    [email protected]@QBdD##[email protected]@@@@@@Or|civxv^vL^*}[email protected]^)[email protected]@@@@@@@@dPbOdWGKODb3m9ZOXsPkwI3KzsXm3zlmZyybW    //
//    [email protected]@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@Ri}YxxxLr|x^|YclxvvxxLO$zQVxzRVzbBMX#zxv=xTV}xXyVLmzcysywxi#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@RmOM    //
//    #@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@PccY||)v<|r)ul}xixYxVxObiO***):*)Oxv#z|)*xyu|xVywmmzImsmG|[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$PDM    //
//    #@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@s}xlVywy}ux)lTLLxYLxivOWT0xrr^**[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@KIdM    //
//    Q#RB#@[email protected]@@@@@[email protected]@@@@@@@YcY)iTluiVi)Li)*r^~;^^mmxVv*TxxYVzx}QWr)^|iYxYv)[email protected]@@@@@@@[email protected]@@@@gM09dMGVOZy    //
//    BBQ$b99BQ#@@@@@@wYsMVuVLT):|[email protected]@@@@@@Qvv)^~*))<*)))^^^<!=":^PVvy*!^);^|Y*|gl=<*|iY^!^;;[email protected]@@@@@@@B~=vcVT}T}VwIWzkTYuT}@@@@@yxv}y<x|PmT    //
//    [email protected]@@@@@GuimxxT|lxYwu=*zL}x)[email protected]@@@@@@#^vvr^^xi!;xxr^;rx!r*;^suvi)<)}v^|YxxOVv*=||YxLYc;)rv)[email protected]@@@@@@@@*-=;rviLv|xxxYxLx}[email protected]@@@@kiuk)}iviVv    //
//    Q#Q03D#@@[email protected]@@@@@QYI03uwPTivuur*})Y)*#@@@@@@@Q=r*<=^~):;xx~;!*Y^rx)rK|*x))YuxxLxxxclvr<))ivYTl<~;r^r:rxx)[email protected]@@@@@@@Y!:rv||v**[email protected]@@@@w}yuTVsuVcx    //
//    dGM$#@@@@#@@@@@@g*vRmWOGsVvxY~r}^}Yv#@@@@@@@B*xLxL)=;,~rr*~!!^^;*^vXr)L)vV|v*}ii)k}v^;^rrxvll**^rrvv)v*[email protected]@@@@@@@3,xiuTTxvr)lc}L)^))[email protected]@@@@XiT}xyk)ii}    //
//    DPI$##@#B#@@@@@#dIRBOGZMwx!YT^^^<xYT#@@@@@@@QY=:!Y)*r!^|xr~="!~~<vvzivYxL*^,_:*LYkLv|<x|uTLc*xVr^*xiYr<;[email protected]@@@@@@@GrYTVVLxxrvvxYxr)vxY#@@@@Pl}VVzw^v)}    //
//    swWQ#@@@##@@@@@#bG$#Bbb93cYcT|xz)xxT#@#@@@@@$i|<~L*rx;<xLi=^~^*)*vxLxv|ri*=",<:|)T)*^^vTx~<=Yxc|x|YTx~:)[email protected]@@@@@@@vrcTx)YLc}x*rV}[email protected]@@@by|)*lv:Y;*    //
//    Q#@@@@@@@@@@@@@#[email protected]@[email protected]@[email protected]@@@@@@@#xXl|xiviv*xxx*vx!=YLTT))x|rvV="!^xT))rvrrzw)vuxlcl)xxxT))!v}#@@@@@@@@r:rrrr==*lT,=*lyYx)[email protected]@@@MvLvxwy}:~V    //
//    #@@@@@@@@@@@@@@#[email protected]@@###[email protected]@@@@@@@#}YVuizYL)xx|xxx)=x)lxVL|x||)iv<[email protected]@gsVc)iuv*ruTixxY<#@@@@@@@#i)l)<)xxixv)kxlxyyKW#@@@@B$Q$gBQ$)cl    //
//    @@@@@@@@@@@@@@@@g##@@@##@#B####@#0$R#@@@@@@@@KMzmuzuTvvxvvYlxlLrl}}Y)v)ivT}[email protected]#LTVyuvVx|[email protected]@@@@@@@@G}[email protected]@###BQB####ggd    //
//    @@@@@@@@@@@@@@@@##[email protected]@@@@@#@###[email protected]##Qg#@@@@@@@@09MOKPVkxTLx}VYLiYLxLlzixvvu;)Llx}i}[email protected]@@k}VVuwyVx}xxi}lx}#@@@@@@@#MTwKX3Z0KkIX8$0WXMZ3d#####$Z0D##dsQQ    //
//    @@@@@@@@@@@@@@@@@##@@@@@@@@@@B#@@@##@@@@@@@@@#BM9GcIuimI}cuucTTkc^r}L}lx}Y|iTyV}[email protected]@@@mlkzVcvVTY|vxcVYx#@@@@@@@BOsxLzmmZmZXsdWwOz3bGP####B$D9BB#dGQ9    //
//    @@@@@@@@@@@@@@@@@##@@#@@@@@@@#@@@@#@@@@@@@@@@@#@@#g8DZ$OwzczkRKMOdRsy}yixVTLVuVTcK}[email protected]@@@Qz}yT~};ix=*Lv*|[email protected]@@@@@@@#8OTvwVV^lOYylKsyysZ3PB##B80RdOQQ$gdQ    //
//    #@@@@@@@@@@@@@@@@@[email protected]@@@@@#@@@@g0#@##@@@@@@@@@#[email protected]@@@@@@@##@@@@@@@@BdVX}ucyuxiMuO$W0#@@@@kTl}lT*=!<ukVx*[email protected]@@@@@@@@#QGmVvObZ9OMOR9MM$99b$QgDMQdMZ$QO$sZ    //
//    #@@@@@@@@@@@@@@@@##@@@@@@[email protected]@@BQ#@@[email protected]@@@@@@@@83d####@#@@@@@@@@@@@@@@@@@@#@###@##[email protected]@DVVwl=::,"[email protected]@@@@@@@#$ZxVX=GcMMGzkKPZK3OdcZRdRMDRbgQQQ#BB    //
//    @@@@@@@@@@@@@@@@@#@@@@@@@8#@@@#[email protected]@#@@@@@@@@@[email protected]@@@##@@@@@@@@#[email protected]@w*ix^r_:,=^[email protected]@@@@@@@#gk!=T~w}uKIi^YusX3Md|VdD800$M9$B#B#Q    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BB#@@#@@@@@@@@@[email protected]@@@@@[email protected]@@@@@@QyXkcD#liQO;:!L~;<rVv)[email protected]@@@@@@@#$WVrx^rw}yMP)xXlx)cKWWMgM90#@@QB##QMI    //
//    @@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@B#@@@@@@@@#[email protected]##BOwVKK3PWXPGQB#[email protected]##@#[email protected]@@@@@@@#gODZYLwmzyKXIG0dkxZbZXlVxuG8#[email protected]#@BQQs    //
//    @@@@@@@@@@@@@@@@@@#@#@@@[email protected]@@@@@@@@#[email protected]@@@@@@@Q$ZZ$QPP88R$bbZ9ORg9$kMzk3yMWZ9VZOWsMG##@@@@BQKixPBBBBRB###@@@@@@@@@##Q9M3M9M8ODQ#@#$$MDgg8QgD0BBR80gbzzY    //
//    @##@@@@@@@@@@@@@@@@##@@@@#@@@#@#@@@@#@@@@@@@@##$BB#QBB#BBMZQDgs$R$bbOO0MB##[email protected]@@@@BBB$ODQ##QB#@@@@@@@@@@@@@#B$$WQQ##Q8QB##BB#@@#@@@##@@gb9Omml)    //
//    #@@@@@@@@@@@@@@@@@@@@@@#@#@@@@@@@@@@@@@@@@@@@#@@@@@[email protected]####Qg###[email protected]@@#@##[email protected]@@@#@#@#[email protected]@#[email protected]@@@@@@@@@@@@@BMdDG$Q#g$Q##B##@@@@#@@@##@@@8QgWKks    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####$##@Q#gQ##@#[email protected]#8$RBBg#@@@[email protected]@QQ0Q#@@@@@BQ##[email protected]@###@@@@@@@@@@@@@8Pb9MRM$GdggB0BQBB####@@@#@##OQQgB0O    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####$Q$BBBg$B#@#Q##QQB##8Q##@[email protected]##B#$Q#@@@@DgQ#BQQ##gQ###@@@@@@@@@@@BQ#Q9$Z0MMO9$OgQQR#[email protected]@@@#@#@@#BOZ    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@####@#[email protected]#@@#B#@###g##@QQ#@[email protected]@@##gQQ$Q$D##QQ##@@@@@@@@@@@@Q$g$O8g8#$gQ09Q##B#@#[email protected]#@@@@#@BgZ00g    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@#@Q#QBQQ#####Q#@#@#$##@BQQB##[email protected]@@@##B#8QQ$BBg$B##@@@@@@@@@@@B8gO9D$B#Q$BBQQ#@@@@@###BQ#@B#8Q0bW9    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@#[email protected]@@@@##@8#QB#QB#@@[email protected]@@@@@@@@@@#@##BBBBBQB##@@@@@@@@@@@Bb3Pm3s$0DdBBBQ##@@@@@@@##QDKyGbR9MO    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@@#@@@@####QB##@[email protected]@@@##@@@@@#@@@@@@@#####@@#@@@@@@@@@@@@@@#BBQOR9MGzsZ8Q$B#@##[email protected]######B$QBQQB$    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@#@@#@@@@#@@@@@####B#####@@@#B#@@@@@#@@@@@@#@##@@@@@@@@@@@@@@@@@@@###B#####Q####[email protected]@@@@@@#[email protected]#######@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@##@@@@#@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@##Q#@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#B#@@#@@@@@##@@@@@@@#@@@@@@@#@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@#@@@#B#@@@#@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##@@@@@#@#@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@###@@@@@@@@@@@@@@@@###@#@@@@@@#@#@@@@@@@@@@@@@@@@    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FMCHAOS is ERC721Creator {
    constructor() ERC721Creator("feel my chaos", "FMCHAOS") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}