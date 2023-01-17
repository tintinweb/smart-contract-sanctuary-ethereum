// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bryan Minear Editions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    ,:,'''-'',''',~+=>^^^;;;;;;;;;~;;;~:,'',:_;;;^;?>=LiiiiL=;;:~;~,''...'..```-``':,',,,:~;;;;;+^r++==|*|il1zl11zi*+^;;;;;;;;;;;;;;;;+;;~_,'','''',,,~;;;    //
//    :::,,'''''..'',;;rr==^^^r++++r^;;;;;;;;;;;^^^^^^+++>>+^;:,',_~''...-'''''''''....-''-.':_~~;;;;~;;~;~:~~~;>L|*^~~,,,,:~;;r=>++>>=+=;:,'''-```.','',',:    //
//    '-.'''''--.-'-.-',;^^;::~~;r====^;;;;;;;;;^+==^;;+^^rr;~,,,,:~'''-'''',,,,,,,''''--..',~~~:,'''''''''''',~~~~~;::,,',_;;r>Lii\lliiL*r;~:,,,''',,,,,_~;    //
//    ~,,,''---...--.''-',~~;~~~;;^^r^;;;;;;;;^^^^^^^;;^^^r;;;;;;;;;~::~,''',''''''''-''''''''''``.``.-.-....-''''''''''',;^=>*??||||LLiL>^;;;;;;~~~;;;;;;;;    //
//    ',,',,:,''-........'''''''',,~~~~~~;;;;;;;;;;;;;;;;;;^;;;;;;;;;;;;;~~:,,:*\t=;~'-'.-```.```.````...-...'''-'',,'-'''',~;^r===>>>***^^;;;;;;~~~~;;;;;;r    //
//    ''''''',,,'''''..-.'',,,,,'-''''''.''',,~~;;lp8ARDy\yl*;~~~~*==L|*l}UQDpX$svX1{HK4u|;;~~~^;,~,_-'''-.`-':''',,,,,,,,~~_:_~~;;~~~:,::~~~~~~;;~~~;;;^;;;    //
//    ''''',,,,:_,,,''''...'''''''',:,''''-'''~}QQ4Q&p8BQbzF1v\|iq)*LLFRQQ%QX8BUtaQx}[email protected]@@0bXPVF)Fyj3j*''-'''''''''''''-''',,,,,,'',,:,:~~~~;;;~;;;~~~~~~~~~    //
//    ...```-'',,,,''''''....-'''-''''';s\rr}[email protected]%O&qQX^;;[email protected]|[email protected]?ymQQjKU>[email protected]@@@QN%[email protected]}r^;;~'';\1||xj}~'',,,,,::~~~~~~~~~~~~~~~~;_,''.`.    //
//    ,,,'''''''',,,,:;>++*~,'.'--'[email protected]@@@[email protected]&h3D|t^:_;*%OWS*[email protected]@@@@@Qy}z*SpPUF|[email protected]@@@[email protected]@Q%gQ0DNyFhylLljKNRQQ1>;1j%x~..-''',,,'',,,''-','',,,','',,,    //
//    ''''''''''',>xAWQNz30yzji$j%[email protected]@@@@QVKi1hK3~:~ix|r;>^[email protected]@@[email protected];;+?;azXp|[email protected]@@@@[email protected]@@@8Fi>}Q%L\[email protected]@[email protected]*~iwy3a3jxFL=^,''',''','',,,,,,,,,:~~~~    //
//    '--..`.'.:;UQQDDA0Dj4O%[email protected]@Qp|j>zFv\~~*ObR|;[email protected]@@[email protected];^=^^[email protected]@@@@D%[email protected]&[email protected]@QQQZXPl|m0&QQQNQ&U$sKXKhP41hw*;,,,,,~~~~;:_,'    //
//    ==+^rr>=^|^^;;;[email protected]&lt{AORpkv?;~:[email protected]@@@QDD=}qRzy;[email protected]&8K|[email protected]|[email protected]*v&&W&&RB&QQQBQBQQR0%[email protected]}^;^;;;*+^    //
//    4l\itAQDzz1}usy}[email protected]||?^;;~~~~~^OQy8KQ%[email protected]}[email protected]|y|zDDzZ*=;z*~;zyj4QBaRDmD3|t{>tyl:>;[email protected]@AD&[email protected]>|lXmRDwXD&@[email protected]@DQWgXU$ADXN&pD&@Qj)i\x*=)    //
//    @[email protected]@NPlljtj|iQ4}$\3&Q0yzj^;;;;[email protected]@@@@QQ*wQQ0&x;;>r+*L?}Ll=,;?|~rF3{XD8F\i_;;~~:,,'''',^[email protected]@@QQ&j*lpp&DB&[email protected]@@[email protected]=_+|[email protected]    //
//    [email protected]@QQ$Uj?V$i{[email protected]\*|l?;~~~~~~__~~;;~;[email protected]@[email protected]@KUzQU+=L?{w|kS+;~^;*~z|+s>;L}SjSQU*;,;l{~,:rsir,',r''1%@[email protected]{)>[email protected]@[email protected]@@@@    //
//    zKV0*Q&jjVDij&&QqDs|=|||>=|*;^^;;;^^;;_;[email protected]&@RkizOQQbAQm*~=~*~=L=*il*FVNQ8%NO;~~~>+|l\vr;;~L,;~~yjLpDw1a\[email protected]@[email protected]@@[email protected]@@QBH%QQQQQ&[email protected]@@    //
//    [email protected]@QRDwjZ3hjX{\|*|i)zs|+?+=>^r>;[email protected]@[email protected][email protected]@@&hsO1i;^~r1g&[email protected]@@@[email protected]&OA&KDKX3;>~;V0%jjl*[email protected]@@[email protected]@@[email protected]@@[email protected]@[email protected]    //
//    0RwyU&mP\[email protected]\L\j3wl?|Lsl?|>rxj|[email protected]@[email protected]&\[email protected]@B%KUu\>[email protected]@[email protected]@@@@@@@tySFL}}RWOsFKaSs}kQB3wQNW&pBQ8%OQ&[email protected]@@@@@@@@[email protected]@QQ&@[email protected]@@[email protected]    //
//    QQj}sBF*i}L>|[email protected]@[email protected]%pmSVt}sl=*xaPzvPOZ\=;;?*^[email protected]@[email protected]&[email protected]@[email protected]@@@QQXZzQDK$}|[email protected]@@[email protected]@@@@[email protected]@Qai}[email protected]@Q    //
//    8D=>$}|jjP>yt=O&QX>OQF&[email protected]@@@@@[email protected]@QBHkU$Uj}1v1it}ljPyzyQ%@P&@[email protected]@QbAwUptQKm%SUB0HK&[email protected]@QN%[email protected]@8jsiF|^\8Q}[email protected]@Q3sp&[email protected]@@@@QQXp$t1g8HQDirrr*Fy    //
//    \*is$RyyDp*ph;';;xUQ)[email protected]@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@[email protected]@0{\iiUDQAKX}[email protected]@[email protected]@@@@@@[email protected]&B0Wgq    //
//    S{*=l\RbQNixOO>,;.'LzmHP?;j|wqQq&&@y;[email protected]@[email protected]@@@@@@@@@@@@@[email protected]@QQQDBRpHXKOHD&[email protected]@@@[email protected]@@@@@@@@@@@@@@@[email protected]@Q8QOKQQp&@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@    //
//    =|*\\*3ABRVz&Qjlpw,?h`.lq?V}zPz^=>1~;;>1=>X*|*l^[email protected]@@@@[email protected]@@QQ$^j%[email protected]}}}[email protected]@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@    //
//    .'=j;,,,rvvhQQv|lQisQl;:?uH3jw;iL|lL*:+v_jj|ZF>[email protected]@U\%HNDOi1AQQQDpPPm43y334P&@@@@@@@@@@@@@@[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@    //
//    .'jQ}-v~`';331~;=)|wQwv~k0O;;Um3S0}b|=jz=pPKO1)=3t~;|P}[email protected]@@@@lH}hkhX%[email protected]@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@QQQ    //
//    ,,[email protected];a1`.~$X;`,,;i3QL3i0QQ*|%R3KBpQs3HFxQPjzj3;mv,*ty}ptz|yy*}Q%[email protected]@QPX=i;[email protected]@@@@@[email protected]@@[email protected]@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@jU4    //
//    [email protected]^';3;``^~~1P%|4wQQ8*j%0FRQBQX}HqXQh1VbR1hK=}$}[email protected]|s^Fz;[email protected]@@@@[email protected]@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@0QD8%@@@RUNQQ8jjB    //
//    KkQQQQL;bL'_::1|>1;;y+4jBHSK0Bpy0QQQ}$Dijj|PUOVZwUX8Qg|'|mLwDQ&&QDbR\QX?3KDDi*yD^;?;?*[email protected]@@@@@Q}[email protected]@@@@@@@@@@@[email protected]@@@[email protected]$D&&Q%QpSmQQKNkXRD%jsOQ    //
//    @QQQQ&yRQX~;;zDpOUU\uvDOQKkN8Qyw0QQPjDQXipZDDj^{DWDQQQyLF%4ksiDQBAhp)zFwPDQQh|80|i*[email protected]@[email protected]@@@[email protected]@@@[email protected]&O$0NBQODw$30%[email protected]    //
//    [email protected]@@Dr\\[email protected]:[email protected]@Q3SDQQmS0QFj&Ob0Ki4Q%[email protected]%bp\|>h3Oqykj|uAzP+;[email protected]@&[email protected]&%Q&&[email protected]@&$XPQ    //
//    @[email protected]@@@@@[email protected]@@R^[email protected]@@[email protected]@&mBQV%QQQQmFw&&&[email protected]@QQ8kAQW%[email protected]@8BQQDDQPayx3W}U%8QSh8QDWpq0Kwwbp%8QQQ&8Q&BQR8gQQN&[email protected]@Q&@[email protected]@QQW&QBg8888Q%[email protected]@DK&OQ    //
//    [email protected]@@@@@@@[email protected]@@@@[email protected]@@Q|[email protected]&Q&@@&NQ&QQq&[email protected]&pB%QQQQ&[email protected]&8OQKKQ8&QQQQQQQQ&B)kQQHNBQQQ&Q&[email protected]@@@[email protected]@@@@@[email protected]&NQQQQ8QQ$NBQNQ    //
//    [email protected]@@@@@@@@[email protected]@@[email protected]@@@[email protected]@[email protected]@@@@@[email protected]@[email protected]@BQQ8N&Q&[email protected]&@[email protected]@[email protected]&BQQQ&N0DQQQQQQQB&Q&Q8&[email protected]&[email protected]@@[email protected]@@@@[email protected]@[email protected]@    //
//    @@@@@[email protected]@@[email protected]@[email protected]&K&[email protected]&[email protected]@@@@[email protected]@@[email protected]@@[email protected]@@[email protected]@@@@[email protected]&NQQQBQB&[email protected]@&QQQ8Q&[email protected]@@@[email protected]@Q&[email protected]@[email protected]    //
//    @@[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@@@@@@@@[email protected]@QQQ&QQQQQQ&[email protected]@@@[email protected]@@QQQ&QNQW&@@QQQ&[email protected]@@[email protected]@[email protected]@[email protected]@@    //
//    @[email protected]@[email protected]@@[email protected]@@BwQQPZKQBp0R%[email protected]@[email protected]@@[email protected]&[email protected]@@@@@@@@@@@@@@@@@[email protected]@&[email protected]@@[email protected]@@@@@[email protected]@@@@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@    //
//    @&[email protected]@@@@[email protected]@@@$8Q%yw%[email protected]@@Q8DbBQN8QQQXQQ&[email protected]@@@[email protected]@@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@[email protected]@[email protected]@[email protected]@@@@@[email protected]@[email protected]@&[email protected]@[email protected]@@@@@@[email protected]@[email protected]    //
//    [email protected]@@@[email protected]@[email protected]@[email protected]@@@yjypQ0QQD}|[email protected]@[email protected]@@@@@@@@@@@@@@@[email protected]@@@@[email protected]&[email protected]@@@@@@@@@[email protected]@@[email protected]@@@[email protected]@@[email protected]@@@[email protected]@@@@[email protected]@&[email protected]    //
//    @[email protected]@@@@QQQO%QQpQVKQQQQO3FD%[email protected]@@[email protected]|lkDR%%[email protected]@@@@@@@@@@@@@@@@@[email protected]@[email protected]@&N&[email protected]@@@@@@@[email protected]@@@[email protected]@@@@@[email protected]@@@@D%[email protected]@@@@[email protected]@    //
//    @@&[email protected]@@@[email protected][email protected]@@@@@s\P$&Q8A?w$D0NQ8gO}[email protected]@@@@@@@@@[email protected]@@@@[email protected]@[email protected]@@[email protected]@@@@@@[email protected]@[email protected]@[email protected]@[email protected]@@@@@@@@@@ND&[email protected]@[email protected]@@[email protected]    //
//    &@[email protected]@Q&[email protected]@@@KUO&[email protected]@@[email protected])j0QQQQx|[email protected]}[email protected]@@@@@[email protected]@[email protected]@@[email protected]@@@Q&&[email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@@@@@@@@[email protected]@@[email protected]@[email protected]@[email protected]@@    //
//    @@@@DjDNWg%QQQ%[email protected]@@@[email protected]@[email protected]@[email protected]&[email protected]@@@@@@@[email protected]@[email protected]@[email protected]@@@@@@[email protected]@[email protected]@@@[email protected]@@@@@Q0&@[email protected]@@@@@@@@@@@@@    //
//    @@@&[email protected]@[email protected]@@@@[email protected]&[email protected]@@@$QQQ&[email protected]@&[email protected]&[email protected]@@@@@[email protected]@[email protected]@@[email protected]@@@@@[email protected]%QBg&[email protected]&8%[email protected]@    //
//    R%&Ow%@@Q0QQDKpwX%QAw3;~_:hpt1;=+|iiL\|[email protected]&B%[email protected]{[email protected]@@@[email protected]@Q%@@[email protected]@&DXZwKN%QR$XxFFtjF}hkNQ}$jljX}Dq3pAKD%QQ%KHDDNbQQ8%pR0    //
//    isFyw&QB%|j$|j}r\|lvb$**+\USpD{|=;~:,'''>+L|1z1)x4HpQD$X$kb%qSp%[email protected]&8&&[email protected]%QQQ&QQQQQQQNQRHRw{X}=^^:';r.-,',,;;:=,,,,;z*~;~;;^+;r=?zv\visi;=?>    //
//    '~;[email protected]~~',;,,,',;i^~,'....-.'-',','''.````    ``````.,~~~_;:;~LPD&QQQkj$UhPmXuQQ$Z}}xza3Vp$XUXqPUPUFuj}t1y|\?>>?t=*|riL?FL\=*=>;;>L;=>i\>?z3yi}3ttt    //
//    j>;\3&QQp?*=^^>=l{F{|i?|ztz|i|\iLL|z1{zvltl{a3taL\}}F}{syjjyyjFju}mR%KUu^;^+;;~^;1RDP}S|?r+?*=vz*t)|11|*llli=|*=*L?*+*Lz|^*LLV$XSFu1>LFii\?*|Lzy1L?Fwt    //
//    DRQQQ8QQQBKKXPXHROODDW0bORHO8KqPDDB%0%RNR%DD0pp$D&DVjXKRBUsw0DOqXqpXDR4+;v^L=^~^;^1Wh3FuusyF\Fjl|\L+Lill|ll*i?iLliFtw%DqykKDNQQDD$wjXOUPp8KR%g&QQRDDKX    //
//    [email protected]%WODDDbKXHSUD$KSkkhVap$KqO0D8%DRQQN0RD%88%Q0DD0B&R0&QQQDl>SmiZxliis^ihQ8H$hUpUj{1}}j}1Vw3}sj{}jy$43bNND%0DD%&&RRVmOKp8QQQQQQ&R0QQQX4h0DR    //
//    0WQQB%gNQQQQQQWWNQQQNQQBNQQQQB%%K$Xy4XaXHbSyjj4NQ&%QQN%Q0DRKNBQQQQQQQlz>k}vmzv||F|rjNQQ&RXPhwVwhw}}3$PUSjl}jw33ZpR0R0QQRRKDKp%DR&QQ&[email protected]@Q&QQNN&BQQQQQ    //
//    [email protected]@@[email protected]@@[email protected]@[email protected]&&%QQQQQQQQQQQQQN8g%RRNDSpXORqUAymmy}Pys4O8%&QQQQQQQ3z+F{?ls|z?*ul;[email protected]@@[email protected]    //
//    @@[email protected]@[email protected]@@@@@[email protected]&8&QN%BQBQB&8bgRHPmw%&QgRHRUwwqRQ&D%&80NX|^=1)+Li=*+^?i+;FwQNg&%KO4Um}jyyjRDDUwhtySy}FVUUZS}a%[email protected]@QQQQQQN&D%[email protected]@@@@@@@@@@    //
//    [email protected]@@[email protected]@@@QQQQQQQQ&BQQ&[email protected]{L++LlFjjFl|^;r||?*?^~;>*|\L+|*ltuy}s1?+=*s4}3pWBQQQRQQQgpK%%kS\}[email protected]@@@@@@@@    //
//    [email protected]@[email protected]@@@@@@@QgAwSww{>>tPX$XXPVjziljZjujyj|'?zyj4khSPw4wXqpOOU3z=+FD%[email protected]@@@@Q&[email protected]@[email protected]@@@@@@@[email protected]@@@@@@@@QDRQ    //
//    [email protected]@[email protected]@[email protected]@@[email protected]@@@@@@@@@@QB%H$ODHs>vH0%%00RHXZFt}XDqP$qKU^_jVXPU$KAAOOKpODR%%RDUSir)W&N%D%[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    [email protected]@[email protected]@@@@@@@@@@@@@Q8O$XARWk|>4&&N&&B&RkV}FjPD0RKbHDDK'i^3kU$ODDUSPUpHD08WN&8D$4s;*[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@    //
//    @[email protected]@QQQQQ[email protected]@@@@@@@@@@@@@@@@QQ&%bpqH8RPr?SBQQ&B&&%qVajt{VHg%KKHHOOP.1^VPhXpbHqjj3kHRDR08NW0RHPZl;zRQQN0RR&[email protected]@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@[email protected]@@@@@@[email protected]@@@@@@@@@@@@@QQW0RDR%gWpi=t%QB&&NN&8DSyyy}jhKD0DpKKApHs,K`3UX$$RDKUSyyhKOHRW&&NN&Wqw3s==w&QQQ80%[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@QQ&88RDR%&&DF>|4&Q&&&&N&8DXyyZjF}PKDDOAKKpOHp|,D`sV4$XORDOK$4m$%0RWN&&B&NW%[email protected]@@@@@@@@@@@@@@@@@@@@@@QQQ&Q    //
//    @@@@@@@@[email protected]@@@@@@@@@@@@@@@QQNWODRRNQBRx*\P&QQQB&QBQ&%p43jFF}jXDRR%KOH$$KDDi,%.|hwmwkODDAwySkhDOqpK%8N8gWN0RKAHq)*vDQQQQB&[email protected]@@@@@@@@@@@@@@@@@@Q&&Q&Q    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@QQB&RRD%g&QBDu+>j0QQQQQQQQQQ8HPZZV{uFjw$%WWDKODOKH%Oi,$;:jmXUUAD0D$XPmwpOROqUH%%Wg&&Ng%OUhU}^^lDQQQ&%[email protected]@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@QQQBBN&N&QQQQ&Ui=|4BQQQQQQQQQQQ8DAwZ443jj4XO0N8RDR0%0WNRR\,PL`=w$$p$K080DDDHKDRNQRSUHDg&BQQQBQWDKAqZi=*V8QQQ&80%N&[email protected]@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@QQQQQQBNBQQQQ8m|L1pQQQQQQQQQQQQQB%OK$hwV3y4XODNN&RR00RRRRN0%i,VZ`~X$XXq$R&Ng%RDR%%08BNR$UbN&&&QQQQQQN0OKKp}LLjRQQQQQQ&[email protected]@@@@@@@@    //
//    @@@@@@@@@QQQQQQQQQQQQQQQK{||tKQQQQQQQQQQQQQBWDDKq$XPaj3V$OR&&Q&08NN8N&&8%0i,xR.'mOp$pKpRN8g0DbKKKD8&8Op$K%8N8NQQQQQQQBN%[email protected]@@@@    //
//    @@@@@QQQQQQQQQQQQQQQb$t\}[email protected]%%00RKpAUkUb%NBQQQQBQB&BB&QQ&80>:FQ'.w08W08g%NQQQBgg8&&QQQQQQ&88B&QQQQQQQQQQQQQQ&[email protected]@    //
//    [email protected]@QQQX\i1pBQQQQQQQQQQQQQQQQN80Wg%DDbqXkUpDWNQQQQQBQQQQQQQQQBBB:[email protected],-F0W888&8N&QQQQBN880RR0%%08&&&BBQQQQQQQQQQQQQQQQ&&BWV)[email protected]@@@[email protected]@    //
//    [email protected]@@@QQQ%[email protected]@@@@@@@@@@[email protected]@@QQQB&&&g%DDDDbHD8N&QQQQQQQQQQQQQQQQQQQN,[email protected];'L&BQQQQQQQQQQQQQQQQQQQQQQQQQQQQBQQQQQQQQQQQQQQQQQQQQ&B&p}[email protected]@@@@@@@    //
//    @@@@@@QQ&hFl}[email protected]@@@@@@@@@@@@@@@@QQQQB&B&NN0g%%DR%[email protected]+,;&&&&BBB&N&QQQQQQQQQQNNNNQBB&BNBB&[email protected]@@@QQQQQQQQQRVxFS%[email protected]@@@    //
//    @@@[email protected]@@@@@@@@@@@@@@@@@QQQQQQQQQBB&&Q&888&[email protected]@@[email protected]~|[email protected]|:~8QQQQQQQQQQQQQQQQQQQQBNNN&&N&8&[email protected]@@@QQQQQQQQQQHajjX0    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@QQQQQQL~|[email protected][email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@QQQQQQQ$    //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@QQQB=;[email protected]^;[email protected]@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]>[email protected]^[email protected]@@[email protected]@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]*|[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@}[email protected]@Qt|*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BME is ERC1155Creator {
    constructor() ERC1155Creator("Bryan Minear Editions", "BME") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB;
        Address.functionDelegateCall(
            0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB,
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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