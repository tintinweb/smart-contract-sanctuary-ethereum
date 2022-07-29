// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: CityCitizens
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    55yyyyyyyyyyy5yyyyyyy55y5555555oooooooooooooooooooaaaaaaaaaaaaZZZZZZZZZSSSSSSSSSSmmmmmmmmmmwwwwmwwwwwEEEwwwEEEEEEEEPPPhhhhhhhhhhkkkkkkkXXXXXXXXXXXXXXX    //
//    yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy555555555oooooooooooaaaaaaaaaaaaaaZZZZZZZSSSSSSSSSSmmmmmmmmwwwwwwwwwwwEwEEEEEEEEEEEEPPhPhhhhhhhkkkkkkkXXXXXXXXXXXXXX    //
//    yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy555555555o5oooooooooaaaaaaaaaaaaaZZZZSZSZSSSSSSSSSSmmmmmmmwmwwwwwwwEwEEEEEEEEEEEPPPhhhhhhhhhkkkkkkkkXXXXXXXXXXX    //
//    yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy5555555ooooooooooooooaaaaaaaaaaaaZZZZSZZSSSSSSSSSSmmmmmmwwwmwwwwwwEEwEEEEEEEEEEEPhhPhhhhhhkkkkkkkkXXXXXXXXXX    //
//    yjyyjjjjjyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy555555555ooooooooooooooaaaaaaaaaaZZZZZSZZSSSSSSSSSmmmmmmmwwwwwwwwwEwEEEEEEEEEEPPhhhhhhhhkkkkkkkkkXXXXXXXX    //
//    jjjjjjjjjjjjjjjjyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy555555ooooooooooooooooaaaaaaaaZZZZZSSSSSSSSSSmmmmmmmwwwwwwwwwwwwEEEEEEEEEEPPPhhhhhhhhkkkkkkkXXXXXXX    //
//    jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjyyyyyyyyyyyyyyyyyyyyyyy55555555oooooooooooaaaaoaaaaaaaaZZZZSSSSSSSSSmmmmmmmwwwwwwwwwwEEEEEEEEEEPPPPhhhhhhhhkkkkkkkXXXXXX    //
//    jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjyyyyyyyyyyyyyyyyyyyyy555555ooooooooooooaoaaaaSwEPhhkPmSSSSSSSSSSSmmmmmmwwwwwwwwwEEEEEEEEEEEEPPPhhhhhhhkkkkkkkkXXXX    //
//    jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjyyyyyyyyyyyyyyyyamEkXUU6qqKKbbddDDDDDR%gWN8W%DR#QQRXEEmSSSSSSSSmmmmmmwwwwwwwwwEEEEEEEEEEEEPPhhhhhhhhkkkkkkkXXX    //
//    jjjfjjjfffffjfffffjjjjjjjjjjjjjjjjjjjjjjjjjjyyyyy5E6Dg#BBB&#NNNN88WWWWWWWWWWWWWWWWg%DdD&QQNKUdW8gDKUhSSSSmmmmmmwwwwwwwwwEwEEEEEEEEEPPhPhhhhhhkkkkkkXXX    //
//    ffffffffffffffffffffffjjfjjjjjjjjjjjjjjjjjjjjjjjym6DW#BBB##NNN888WWWWWWggggggggggg%RDbD&QQBRbDW#BBB#N%KUESSSmmmmmwwwwwwwwwEEEEEEEEEEEPPhhhhhhhkkkkkkkk    //
//    }}}}}}}}}}}}}}ffffffffffffffffffjjjjjjjjjjjjjjjjywq%N&BB&##NNN88WWWWWggggggggg%%%RRDdbDBQQQNgg8#BB&#NgDAm}7jSmmmmmmwwwwwwwEEEEEEEEEEEPPPhhhhhhhhkkkkkk    //
//    }}}}}}}}}}}}}}}}}}}}}}}fffffffffffffffjjjjjjjjjfyhbgN&B&&#NNN88WWWWWgggggg%%%%RRDDDDdbDBQQQQB##BQB&#8gDAm{i*SSSmmmmmmwwwwwwwwEEwEEEEEEEPPhhhhhhhhkkkkk    //
//    {{{{{{{{{{{{{{{}}}}}}}}}}}}}}}ffffffffffffjjjjj}aUDW#BB&##NNN88WWWWggggg%%%%RRDDDDddbbRBQQQQQQQQQQB#NgDqwf\^ySSSmmmmmwwwwwwwwwEEEEEEEEEEEhPhhhhhhhkkkk    //
//    uuuuuuuuuuuuu{u{{{}}}}}}}}}}}}}}}}}}fffffffffj{fEq%N#BB&#NNN888WWWggggg%%%RRDDDDdddbbbRBQQQQQQQQQQQ&NgDKPj7=TSSSSSmmmmmwwwwwwwwEwEEEEEEEEPPhhhhhhhhkkk    //
//    nunnnuuuuuuuuuuuuuu{{{{{{{{{{}}}}}}}}}}ffffff}I5XdgN&B&##NNN88WWWWgggg%%%RDDDDDddbbbKb%QQQQQQQQQQQQB#WRbXyz*+ZSSSSSmmmmmmwwwwwwwEEwEEEEEEEPPPhhhhhhhkk    //
//    nnnnnnnnnnnnnnnnnnnuuuuuuuuuu{{{{}}}}}}}}ffffs}mqD8#&&&##NNN88WWWgggg%%RRDDDDDddbbbKKb%QQQQQQQQQQQQQB8%dUos|;YSSSSSSmmmmmwwwwwwwwwEEEEEEEEEEPPhhhhhhhk    //
//    IIIIIIIYYYYYYYYYYYnnnnnnnnnuuuuu{{{{{{}}}}f}uxyXd%N#B&##NNN888WWWggg%%RRDDDDDddbbbKKKd%QQQQQQQQQQQQQQ#gD6S}i^*SSSSSSSSmmmmmwwwwwwwwEEEEEEEEEEPPhhhhhhk    //
//    sssssssssIIIIIIIYYYYYYYYYYYnnnnnuuuu{{{{{{}{JjwqRWN&&&##NNN888WWggg%%RRDDDDDddddbbbbbdgQQQQQQQQQQQQQQQN%KEj7=;oZSSSSSSSmmmmmwwwwwwwEEEEEEEEEEPPhhhhhhh    //
//    sxxsxxxxxxxssssIjnssIIIIIIYYYYYnnnnnuuu{{{{tYZUdgN#&&&##NNN888WWgg%%RDDDDDDDddddddbbbDgQQQQQQQQQQQQQQQBWDXoJ?!vSSSSSSSSSmmmmmmwwwwwwwEEEEEEEEEEPhhhhhh    //
//    xxxttxxttttxxxzzh%%DKUhSy}sIIIIIYYYnnnunY}f}okqR8N#&&###NN8Wg%DDbq6UXkhPhkXU6qKbdddddDgQQQQQQQQQQQQQQQQB%qw}i=^aSSSSSSSSSmmmmmwwwwwwwwEEEEEEEEEEPPhhhh    //
//    ttttJJJJJJJJJJtJT7abW#BQQQ&WDKUPZy}YYnnIjoSwEPPEEPhPEEwmSZZZZSZSSSSSSSmmmmmmmmmmSmmEkXAdD%ggggggWW88N&B#WDU5z|!zSSSSmmmmmmmwwwwwwwwwwwwEEEEEEEEEPPhhhh    //
//    JJJJJzJJJJzzJJJJJz77jXKD%g8N#B&BBB&WRdAUqKbKUhEEEEEwwmmmSSSZaaaZSwkUqKbbKq6XwmSSmmwEEhkXU6AqKbbddDDDDDDDDDDKX57|kUwwwwwwwwwwwwEEEEEEEPEEEEEEEPEPPPPhhh    //
//    zzzzzzzzzzzzzzzzzzzzzIykqKbbdDDR%ggW8N#&BBQQQQ&8Wgggg%ggggW8NN&QQQQQQQQQQQQQQQQQ#WgDDbKqqqKbDDR%gg%%RDDDDDR%%%%RDqwShhhhhkXU6qKbDDR%Db6kPhhhhhhhhhhhhh    //
//    zzzzzzzzzzzzzzzzzzzzzzzx}oPAbDRR%%ggWggggR%g8N#BQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQB&##NWRDq6888N#BBBBBBBBBBB&&NRqkkkkkhhhhhhhh    //
//    zzzzzzzzzzzzzzzzzzzzzzzzzzzzJnfjjyyyy55ooZ6bDWQQQQ&N8NNNBQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQB##NNNNNN88888888WWWgg%%R6otXXXXkkkkhhhh    //
//    [email protected]@@@@@@QQQBNggg8&QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQBBB&&&&BBBQ#8gDdKUkXUUUXXXXXkkkhh    //
//    77777777777zzzzzzzzzzzzzzzzzzzzzzJJJtttxx{[email protected]@@@@@@@@@@@@QQQ#g%ggNQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQ#NW%DDddbbKqqqA66UUUXXXXkkk    //
//    777777777777777zz7zzzzzzzzzzzzzzzzJJJtttt{[email protected]@@[email protected]@[email protected]@@@QQNggg8#QQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQBNg%%%%%%%RRDDDdbKKqqq6UUUXXXXkk    //
//    777777777777777777777zzzzzzzzzzzzzzzJJtttumkXq%[email protected]?|[email protected]@@QQQNW88NBQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQQb#NWWWWWWWWWWgggg%RDDDdbKKqq66UUXXXXk    //
//    777777777777777777777777zzzzzzzzzzzzzJJJz}mkX6DQQQQQQQQQQQQ!;;*7J{[email protected]@@@@@QQQQ&&BBBQQQQQQQQQQQQQQQQQQQQ&@@grDWWWWWWWWWWWWWWWgg%RDDddKKqq66UUUXXX    //
//    777777777777777777777777777zzzzzzzzzzzzJzfwXU6KBQQQBQQQQQQf;;;;~~,,,~^[email protected]@@@@@[email protected]@[email protected]@Q<DWWWWWWWWWWWWWWWWg%%RDDDbbKqqA66UUUX    //
//    777777777777777777777777777zzzzzzzzzzzzzzjEXqK6WQQBBQQQQQg!;;;;~_,:;!;;;!!^<Ltmafmqwjyw6d%[email protected]@@@@QQQQ&b8#[email protected]@@L%WWWWWWWWWWWWWWWWgg%RDDDddbKKKqq666U    //
//    v7v777777777777777777777777777zzzzzzzzzzzfjj5Ek%QQQQQQQQQL;;;;;~_,;;;;;~~;;^=?cIi!?i^^+<[email protected]##&[email protected]@@sWWWWWWWWWWWWWWWWWWgg%RRDDDddbbKKKqqq    //
//    TTvvv7vvvvvv77777777777777777777zzzzzzzz*!!^^!!IQQQQQQQQb;;;;;;~~,.  Iqhq%mjI!<\n!*|^;!!!!^r=*?WRfywh6kww\[email protected]@@a6wgWWWWWWWWWWWWWWWggg%%RDDDDDdddbbKK    //
//    TTTTvvvvvvvvv7v777777777777777777zzzzzz*;!<|||>;EQQQQQQQL;;;;;;~~,`  ybANQRRy`'~!!<?^;;;!!!^^^^[email protected]@@&N{^|!%Z~,[email protected]@k*~*WWWWWWWWWWWWWWWWWggg%%%RDDDDDDDdd    //
//    TTTTTvvvvvvvvvvvv7777777777777777zzzzzz^;!>=^!!^!WQQQQQB!!;;;;;~~_'  `<aAqS<..:;;!<?>^^^^^r=><<[email protected]%%j:;?*Ds'`[email protected]@sK%XUWWWWWWWWWWWWWWWWWWgggg%%%%%RRDDD    //
//    TccccTTTvvvvTvvvv77777777777777z7zzzzzz!;^<+;;~;;iQQQQQq!!;;;;;;~~:,...''''',~;;;!<?*<**?|LicT7jg%w+,,;<zXS|` [email protected]%%%%    //
//    ccccccTvvvvvvvvvvv777777777777777zzzzzz^;^*+;;~:;~KQQQQh!!;;;;;;;~~::;!^=<*<=!;;;!*?<**?||Li\\\wBBqx7syyo}z^``[email protected]%P%%E6WWWWWWWWWWWWWWWWWWWWWWWWWWWWWggg    //
//    cccccccTvvvTTTvvv7777777777777777zzzzzz*!!L>;;;~;;<QQQQk^!;;;;;;;;~~:,,,,:~~~;;;;!<+!^^^r+=<<**m#gyi|ic7xsi~`[email protected]    //
//    TTTcccTTvvvvTvv7v777777777777777zzzzzzzz^!+|!;;;;;!j&QDu!^!;;;;;;;~~~:,,,,_~~~;;;r=;;;;;;!!!!!!=%Kz|L\7zI7='``@Qjdgq|WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    cTTTTccTvvvvvvv77777777777777777zzzzzzzz\^!^=^^!;;;=++7T?>!;;;;;;;;~~~:,,:_~~~~;;<^;;;;;;!!!!!!!7WZ\iczxsL;.` #gv^q!wWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW    //
//    TTTcTTTvvvvvvvv7777777777777777zzzzzzzzzzv=^!!!!;;;**>?<zz+!+;!;;;;;~~~::_~~~~;rLjw}*!;!!!!!!!^zENWo77zIz=_.`=Qq|,'*WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWggg    //
//    TTTTTTvvvvvvv777777777777777777zzzzzzzzzzzJc?=^!!!?y+;^iZYzxL*!!;;;;;~~~_~~?jq#QQQQQQ#Kmj}[email protected]@@@QqnxY7^_'~6Nq\~zgWWWWWWWWWWWWWWWWWWWWWWWWWWWWgggg%%    //
//    Tvvvvv77v77777777777777777777zzzzzzzzzzzzzzJtJm%D#@W5'!<azt=vfL?^;;;;;[email protected]@@@@@@@@Qdy\r;;xQgDqbWWWWWWWWWWWWWWWWWWWWWWWWWWWWgggg%%%R    //
//    [email protected],^fuyE\jyL=!!!;;;;;[email protected]@@@@@@@@@@KT*yjQQWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgggg%%%RRD    //
//    [email protected]@X!:zzcTwIsk><?!^;;;[email protected]@@@@@@@@@@#{[email protected]%%%RRDDD    //
//    77777777777777777777777777zzzzzzzzzzzzzzzJJttxsI#@@@Q|,+hkkzvyci|<*?;;;[email protected]@@@@@@@@@QshQQQWWWWWWWWWWWWWWWWWWWWWWWWWWWWWggg%%RRRDDDD    //
//    [email protected]@@m<=ivzjI<o?\i>?!|=jXRDqkaEjj7Jmj{jEf}}7i|7xzzsY{ykU6QKQNWWWWWWWWWWWWWWWWWWWWWWWWWWWWggg%%RRDDDDdd    //
//    [email protected]@Qi!=XzS+fyjL|I?S<^^;;!;;;;~~;;;;^=^*?*i\i7z7z}akXoyszuoqgWWWWWWWWWWWWWWWWWWWWWWWWWWWg%%%RDDDDDdbb    //
//    7777777777777777zzzzzzzzzzzzzzzzzzJzzJJJJttxxsssIIYwqb\==iIxt==LZ=oi*j**;*=^;;;^!<^zr=*<inicZEkhw}{ESNNW8Q8wJic5KWWWWWWWWWWWWWWWWWWWWWWWWg%%RDDDDddbKK    //
//    zzzzzzzzz777zzzzzzzzzzzzzzzzzzzzzJJJJJttttxxxsIIIIYnnns>^?L\sIu{jf|=S=i7!w<L|;|*+!i?^L}<L?vfyyY5ohSUD&N#QBWWWW%EtaWWWWWWWWWWWWWWWWWWWWWWg%%RDDDDddbKKK    //
//    zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzJJtJttttxxxxsIIYYYYnnuux^^!?aaYSo7yyc7J7*^;|I;;**x+>|i7=7TfsfSyywXmR&QQQNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgg%%RDDDddbKKqq    //
//    zzzzzzzzzzzzzzzzzzzzzzzzzzzJJJJJJtttxxxxxxsssIIIYnnnuuu{7!!!?zYokZXwzSa7Joi^<\^};^\;^\7Lcz*7UznXaS6QQQNWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWg%%RDDDdbbKKqqq    //
//    zzzzzzzzzzzzzzzzzzzzzzzzJJJJJttttxxxxxxsssIIIIIInnuuu{{}}?;;^*i7swkdXbqUUTgLz+z^z7+zzL*oz{zjyUSyX#QQ8WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgg%RDDDDdbKKqqAA    //
//    JJJzzzzzzzzJJzJJJJJJJJJJJtttttttxxssssIIIIYYYYYYnnu{{usnjy<^^<|L\7zsj5ahKbwUE{iy<<I|L}o}zSy6mkq#QQWWW8WWWWW8WWWWWWWWWWWWWWWWWWWWWWWWWgg%%RDDDdbKKKqq66    //
//    JJJJJJJJJJJJJJJJtJttJtttttttxxxxxssIIIYYYYnnnnnnuuu{tzvJywPi**||Li\T7zJs{faUK6WDDAD%wXdNAD%RSg%dgWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgg%RDDDdbbKKqqA66    //
//    tttttttttttttttttttttxxxxxxxxssssIIIYYYYnnnnuuuuuu{zzJzzujyZY7L||||Lii\c77zxujoEUqdDRRDDRDKw6gdmsSD8WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgg%%RDDDdbKKKqA666    //
//    xxxxxxxxxxxxxxxxxxxxxxsssssssssIIIIYYnnnnnuuuuu{{{}it{nIufjyoaajn7||||Lii\T7zs}j5mPUKKKdDDDRQB%X7xzDWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWgg%RDDDDdbKKqqA66U    //
//    sssssssssssssssssssssssssIIIIIIYYnnnnnnuuuuuu{{{{}}\sufjffjoaZZaoaZy}7iLLLic7Jn}jyomEhkXUqDNQgKu|YsYWWWWWWWWWW88WWWWWWWWWWWWWW8WWWWgg%RRDDDddKKKqq666U    //
//    IIIIIIIIIIIIIIIIIIIIIIIIYYYYYYYnnnnuuuuuuuuu{}}}}nxL\7j5oyjj5aSmmmSSSEkwyxvc7zsY{}jyyyyoZwUKqEjvIyTn%WWWWWWWWW8WWWWWWWWWWWWWWWWWWWgg%%RDDDDdbKKqqA66UU    //
//    YYYYYYYYYYYYYYYYYYYYYYYYYYnnnnnuuuuuu{{uYJ77\iL||||L\nyoaaojy5ZSwEPhESZmhXkZjuxxxsYu}ffjoSa5oo5Swf7iLvzYjomXqDWWWWWWWWWWWWWWWWWWWgg%%RDDDDdbKKKqqA66UU    //
//    nnnnnnnnnnnnnnnnnnnnnnnnnnuuu{uunt7cL|**<<**||LLLi\\cjoaaaooZSSSmmEhXXhmSSwPkkwoj}}jyjjj}{j5SEkXy}f<i7Ti|**<==LzyU%WWWWWWWWWWWWggg%%RDDDDdbbKKqqA666UU    //
//    uuuuuuuuuuuuuuunuuuuuuuuuuu{{7*^+++>*????|LLLLicci\vzzsZmSSSSSSSmmmmwhXXXhwSmwwwPUAKKKbKAEoowkhaojL<zY\L?****<<>=+=ijqgW8WWWWWggg%RRDDDddbKKKqqA66UUUU    //
//    {{{{{{{{{{{{uuuu{{{{{{{{{{z*!;;;^?*||??|iiiL\Tcii7zzv7JY}wEmmSSZaZmEEmmmPkXXESSEXqbDdbqUPmmwEwEXasiiyniiL||||?***<<>==|jAWWWWgg%%%RDDDDdbKKKqqqA66UUUX    //
//    }}}}}}}}{{}}{{{}}{{}}}}I|^~~;!!;^\|i||ic\Li77vivzzvTzxJ7tfymEmSao5y5ShXESaZwhXXXXU6UXhEEPEEEXdDEy{7jwJTc\\iiiLLL||??**<==?fbggg%%RRDDDDdbKKqqA666UUUUU    //
//    }}}}}}}}}}}}}}}}}}}}{i^~;~;;!^+^=zLLLc77ii7zci7zz\7Jt7vtYYzIoSPmoyyyyyoEXUhSooSwkXXXXXkkX6bgNdkSoj{6Szz77777vTc\\iiiLL|?>*>!*yDg%%RRDDDdbbKKqq666UUUXX    //
//    }}}}}}}}}}}}}}}}}fu|;~~;;;!!=<<=?JL|L77ci7zviTzzc7JtvTzxz7znuJYmEmoyjjyyomX66XPmSmEXUqd%NB#%AXkESokKfJzJzzzzzzz77777Tc\iL?iL+!^76%%RDDDDddbKKqqA66UUXX    //
//    ffffffffffffffff}L;~~;;!^^^+?||*iJL|i77iTzzi\zzc\zJ7\zt7c7xx77Yutykmoyyyyy5ZwXAKbDD%gWW%DK6UUUXXkURoIIYssxttxxxxttJJzzz7vc|}7L<+^Tk%%RDDDDdbKKKqA66UUU    //
//    fffffffffffffffi;~;;;!^=<*<*i\i|vzL|c7ci7z7i7zTiTz7i7zJ\TJJTctsz7z}jPwayyyyyyoamEkXXUUU6UUUUU66AbgEnIssYYnnnYYYYYYYYYIsstz77o}t7L<+iU%RDDDDddbKKqqA66U    //
//    jjjjjjjjjjjjjsr~;;!^+==*Li||v7i|7zL|v7LLzziizziizziizzvizzci7z7\zxt7zSEwaoyyyyyoaSwEhkXUU66AAqK%NPIxYu{unnYnu{}}}{{{{}}}{uYzjZjjuz\?>7KRRDDDDdbbKKqqA6    //
//    jjjjjjjjjjjjc^;!!^r<?L?|c7L|77i|T7L|77||77L\7zL\zTL\z7i7zziTzzi\Jz7czxzykEZoyyyy5oaSmEhXUAqKKdNN5IY{unYInu}}}uu{}}}ffffffffYzUaaayjxTL|E%%RDDDDdbbKKqq    //
//    jjjjjjjjjjj|!!^+><*|icLLT7i|7vi?\7L|7c|L7c|77cL77iL7ziLzz\izzii7zvizzz\7njSPmoyyyy5oaSEkUqbDgQ%jY{uYtsn}}{YYu}ff}ff}fjjjjjjj}mXooaaay}7iYD%%RDDDDddbKK    //
//    jjjjjjjjjf|^r+>?|i|L77iL\7i|TTi*\vL|7i?Lvi|77iL77|i7vLi77L7z7iTz7i\zz\vJJv7}5SPmao55aZwX6b%BQqfuusttu{}YII{}f}}}}}fjjjjjjyyyj}%wooaaZa5uzIDg%%%RDDDDdb    //
//    jjjjjjjjji=><*?|\7\Lv7i|ivi?\\i*\vLL7i?iv|?77|i77|\7iLT7iLzz\izzii7zcizzz\7xz7JyZmhhEPXqDNQgSYunxzIu{YsIn}}{{n{}fjjffjjjyyy5yjDbaoaZSmSS5Y}Dggg%%RDDDD    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CICI is ERC721Creator {
    constructor() ERC721Creator("CityCitizens", "CICI") {}
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