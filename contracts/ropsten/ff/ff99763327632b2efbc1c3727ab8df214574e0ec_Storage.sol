/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */

contract Storage {

    uint256 number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}

/*
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&5?P&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#?. .J&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B~ !5~ !#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&P: ?#@#7 ^G&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&J.:Y&&&&&Y..Y&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#7 ^G&&&&&&&P^ 7#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###&&&&G^ !#@&&&&&&&@#~ ~G&&&&##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B5?~^::P&&&J..^7YG#&&&#GY7^..Y&&&5::^!?5B&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&P!: .~7JY#&&&&5: .::^!?!:::. ^P&&&&BYJ7^. :7G&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#7. ^YB&&&&&&&&&&B!.^557~?5Y^.7#&&&&&&&&&&BY^ .?#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#~ .?#&&&&&&&&&&&&&&J.:Y&@&J.:Y&&&&&&&&&&&&&@#7. !#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&? .7&&&&&&&&&&&&&&&&&P^ 7P! ~G&&&&&&&&&&&&&&&&&!..J&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&~..P&&&&&&&&&&&&&&&&&&#7. .?#&&&&&&&&&&&&&&&&&&[email protected]&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#G5Y:..G&&&&&&&&&&&&&&&&&&&&5?P&&&&&&&&&&&&&&&&&&&&5..^Y5G&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#J^......G&&&&&&&&&#BG5555PB#&@@@&#BP555PGB&&&&&&&&&&P......^J#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B^ .7GG:.:B&&&&&&#P7^........^!5BY!:........~B&&&&&&&&P..^BP7. ~#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&? .?&@B:.:B&&&&&5~  ~?5GBBGPJ!. . .!YPGBBG5J5#&&&&&&&&G..^#@&!. Y&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&? [email protected]&B:.:B&&&&?. ~P&&&&&@@&&&G7~?B&&&@@&&&&&&&BPB&&&&B:.^#&&7. Y&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&G:.:[email protected]:.^#&&&5..~#&&&&&#PG&&&&&&&&&&#PP#&&&&&&!.:P&&&B:.:#@P: :B&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&5: :JY..^#&&&[email protected]&&&&B^..7&&&&&&&&#!..~B&&&&&?. ?&&&B:.:5?. ^P&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B?: ...~#&&&? .7&&&&&P.  ~#&&&&&&&#^  .G&&&&&!..Y&&&#^... ^JB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#P7..~&&&&B^ .Y&&&&&P?JB&&&&&&&&&G??P&&&&#J. ~#&&&#^..?P#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@5..!&&&&&B!. ~5B&&@@&&&&&&&&&&&&&@@&&BY~ .!B&&&&&[email protected]&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&Y..!&&&&&&&5!. .~!?B&&&&&&&&&&&&&G7!^. :!P&&&&&&&~..P&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&Y..7&&&&&&&&&B57. .G&&&&&&&&&&&&&5. .?PB&&&&&&&&&!..5&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&5..!&&&&&&&&&&@P..!&&&&&&&&&&&&&&#^[email protected]&&&&&&&&&&~..P&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B^[email protected]&&&&&&&&&G..^#&&&&&&&&&&&&&B:.:B&&&&&&&&&@5..~#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&5..^G&&&&&&&&&&?..!B&&&&&&&&&&&G~..J&&&&&&&&&&P:.:P&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&5: .J#&&&&&&&&&J: :?G#&&&&&#P?: :Y&&&&&&&&&B?. ^P&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B7^~B&&&&&&&&&&B?^..:~!!!^: .^JB&&&&&&&#P7: :?B&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&!: .^Y5B&&&&&&#GY?!~~~!?YG#&&&&&&BY!: .^JB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&Y. .~JP#&&@@@@&&&&@@@@@&&#P?~. :!YG&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&B57^. :~7Y5GBBB#BBGG5J7~: .^?P#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#GY7~:.....:::.....:~?5G#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BGP5YYYYY5PGB#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
*/


/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:;,,oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl',cdx:.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc;,''';cdKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx,'lkOOOx,;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl..;cllc;'..:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.,xOOOOOO:'kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc..oOOOOOOko,..cKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.;xOOOOOOOl'dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl .oOOOOOOOOOkl. 'xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.,xOOOOOOOOl'dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..cOOOOOOOOOOOOx;..:0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.'dOOOOOOOOOl'xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, ,xOOOOOOOOOOOOOkl. .dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKc.,dOOOOOOOOOOl'xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..lOOOOOOOOOOOOOOOOx:. ;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOl'.:xOOOOOOOOOOOl'xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc .dOOOOkdolodxkOOOOOko,..;xKWMMMMWWWNNXXXKK00OOkxdolc;'.'cdOOOOOOOOOOOOOo'dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; 'xOOOo;',,,,,',lxOOOOko;. .;clc:;,,''''.......''',;:coxkOOOOOOOOOOOOOOOx,;0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, ,kOOk:.:ccc:'':okOOOOOOOxl;,'.',;;:cclllooddxxkkOOOOOOOOOOOOOOOOOOOOOOOOd,;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, ,xOOk;':ccc,.ckOOOOOOOOOOOOOkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx:':kXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; 'xOOk:.:cccc,.,okOOOOOOOOOOOOOOOOOOkxddollllloodxkOOOOOOOOOOOOOOOOOOOOOOOOOd:,;lkXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX: .oOOOl.;cc;,,,:okOOOOOOOOOOOOOkdl:;;;;;;:::::::;;;::ldkOOOOOOOOOOOOOOOOOOOOOOxo;,,cdOXWMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo .cOOOd'.',;cdkOOOOOOOOOOOOOxl:;;:coxkkOOOOOOOOOkkdoc;,;:lxOOOOOOkkxddolllllllllc:,....;okKWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. ;kOOkc,cdkOOOOOOOOOOOOOko;,;cdkOOOOOOOOOOOOOOOOOOOOOkdc,,;cc:::::::::ccccccccccccc:;'...';lkXWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; .dOOOOkOOOOOOOOOOOOOOOOkocdkOOOOOOOOOOOOOOOOOOOOOOOOOOOkd:..,oxxkkOOOOOOOOOOOOOOOOOOOkkxol:::coxKWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0, .dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxddollccc::ccc:'.'lxOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdl::cd0WMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0; .ckOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOxo:;;;;;:::::ccccc:::,'',:loxOOOOOOOkxollcc:::::::::::ccllc;,lXMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK; .lkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxo;,;:loollcc::::::::ccllodolc;,cxdoc:::;;,,,,,,,,,,,,,,,,;;;;;'.ckXWMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXc .ckOOOOOOOOOO000KK00OOOOOOOOOOOOOOkxo:,,,:ooc:;;,''''..''''',,,,,;;;:c'.,,,'',,;;;;,,,,,'....''',,,;,,;;,,,xWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo. ;kOOOOOOOOOO0KKKKKKK00OOOOOOkxdoc:;,;:clc:,''''...  .:ccc:;;,,'''',,,,,',,;;;:ccc:,'....  .,;,,''....'',,,.'OWMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. 'xOOOOOOOOOO0KKKKKKKKKK0OOOOOxc;;;;::::;,'....       .cKMMWWNXK0kdl:,'''';lool:,..  ...    .lXNXK0kdl:,'.....,dXMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl .lOOOOOOOOOO0KKKKKKKKKKK0Okdc::;;;;;;,,'...    ,odl'    :KMMMMMMMMMMWNKko,.,:,.     'xOOl.   .dWMMMMMMWN0xl,....xMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, .dOOOOOOOOO0KKKKKKKKKKKKK0o'';::ccll:'.   ...  :kOx,     oWMMMMMMMMMMMMMMO.    .;;. .cdo;     ,KMMMMMMMMMMMN0d'.lNMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' 'xOOOOOOOOO0KKKKKKKKKKKKK0x:,;;;;,,.      ,o;   ...      :NMMMMMMMMMMMMMMk.    .:;.           '0MMMMMMMMMMMMMWx.,0MM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' ,xOOOOOOOO0KKKKKKKKKKKKKK0OOkxxxxdl,.                    oWMMMMMMMMMMMMMX:                    :XMMMMMMMMMMWNKd,.dNMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. ;kOOOOOOOO0KKKKKKKKKKKKKKK0OOOOOOOOkd:'.                ;KMMMMMMMMMWN0xl,.                   ;0WMWWNX0Oxol:,..;OWMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. cOOOOOOOO00KKKKKKKKKKKKKKKK00OOOOOkocoxdc;,.           :0NNNNNX0Oxl:,'',:,..'.              .;lc::;,,''',,,,.'kMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX: .dOOOOOOOO0KKKKKKKKKKKKKKKKKKK000OOOd:,,;cloooc:,'.... .',,,;;,,,',;:ldxdc';xkxdlc::;,,,,,,,,,;;::clodxkd:;:coOWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..lkOOOOOOOO0KKKKKKKKKKKKKKKKKKKKKK00OOOkdl:;;;;;::ccclllllcccllllooollc:;,;lkOOOOOOOOOOOOOOOOOOOOOOOOOOOo,;kXWMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'.:kOOOOOOOOO0KKKKKKKKKKKKKKKKKKKKKKKK00OOOOOOkkdocc:;;;;;;::;;:;;;;;'.,cloxOOOOOOOOOOOOOOOOOOOOOOOOOOOko;,lKMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMXc.;xOOOOOOOOO00KKKKKKKKKKKKKKKKKKKKKKKKKK0OOOOOOOOOOOOOOkkkkkkxxkkxo:,,:xOOOOOOOOdccoxkkOOOOOOOOOOkkxoc:;:o0WMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMWx.'dOOOOOOOOOO0KKKKKKOxollx0KKKKKKKKKKKKKKKK0OOOOOOOOOOOOOOOOOkdlc;,,:lxOOOOOOOOOOxl:;;;,,;::::::;;,,,..;ONMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMK,.lOOOOOOOOOOO0KKKK0d:;:c,.:OKKKKKKKKKKKKKKKK00OOOOOOOOOkdlc:;;,;:ldkOOOOOOOOOOOOOOOOOkxl,..,:ccccloxxd:,cOWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMNo.:kOOOOOOOOOOO0KKKKx,:xOOx;.l0KKKKKKKKKKKKKKKKK00OOOOOOOkl::loxkOOOOOOOOOOOOOOOOOOOOOOOOOkocldddooodxkOOd:,l0WMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMO''dOOOOOOOOOOOO0KKKKo'lkkkkd,'xKKKKKKKKKKKKKKKKKKK0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkdlc;,'....    ...':okd;,oXMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMNc.cOOOOOOOOOOOOO0KKKKx,:kOkkkd:;d0KKKKKKKKKKKKKKKKK0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOko;..        .......    ,oko,;OWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMk.,xOOOOOOOOOOOOO0KKKK0c'okkkkkkl;lOKKKKKKKKKKKKKKK0kolldxOOOOOOOOOOOOOOOOOOOOOOOOOx;.     .........',;,,..  .oOx:,dNMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMX:.lOOOOOOOOOOOOOO0KKKKKO:,dkkkkkkdc:oOKKKKKKKKKKKOkl......,cokOOOOOOOOOOOOOOOOOOOOk:   ...............,,'.    :kOkl,lKMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMWx.'xOOOOOOOOOOOOOO0KKKKKKk;:xOkkkkOkdccok0KKKKKKK0l...;cc:;'..';lxOOOOOOOOOOOOOOOOOx'       ...........'..    .oOOOOo':KMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMX:.ckOOOOOOOOOOOOOOO0KKKKKKd,lkkkkkkkkkxlclok0KKK0x' .;ccccccc:,...;lxOOOOOOOOOOOOOOkc.         .........     .ckOOOOOc.oWMMMMM
MMMMMMMMMMMMMMMMMMMMMMMk..dOOOOOOOOOOOOOOOO0KKKKKK0c;dOkkkOkkkkkkdccccloxo' .:cc;,,:cccc:;...;lxOOOOOOOOOOOOkl'         ........    .ckOOOOkd,..lxKWMM
MMMMMMMMMMMMMMMMMMMMMMNc ;kOOOOOOOOOOOOOOOO0KKKKKKKx;ckkkkkkkkkkkkkkxl:;;,. .,cc:,...',:ccc:,...;okOOOOOOOOOOOko,.       .....     'lkOOkdc,..','.'lKM
MMMMMMMMMMMMMMMMMMMMMM0'.lOOOOOOOOOOOOOOOOO00KKKKKK0:;xOkkkkkkkkkkkkkkkkkxol,.,:cccc;,...,:ccc:,...:okOOOOOOOOOOkxl;..          .,lxkxo:,..';ccccc'.cX
MMMMMMMMMMMMMMMMMMMMMWo..dOOOOOOOOOOOOOOOOOO0KKKKKKKo,oOkkkkkkkkkkkkkkkkkkOOxc'.',:cccc:,'..,:ccc:,...;ldkOOOOOOOOOOkxolc::;::clool:,'..,:cccccccc;.:X
MMMMMMMMMMMMMMMMMMMMMX; ,xOOOOOOOOOOOOOOOOOOO0KKKKKKx':kkkkkkkkkkOkkkkkkkkkOOkxo:,'.';cccc:,..',:ccc:,...';:lodxxxxxxdddollc:;,''..',;ccccccccccc:..dW
MMMMMMMMMMMMMMMMMMMMMO. :kOOOOOOOOOOOOOOOOOOO0KKKKKKk',xOkkkkkkkkkkkkkkkkkkkkkkkkkxl;'.',:ccc:,...,:cccc:,'....''''''.......'',;:ccccccccccccc:;'.,xNM
MMMMMMMMMMMMMMMMMMMMWd..lOOOOOOOOOOOOOOOOOOOOO0KKKKKk,'dOkkkkkkkkkkkkkkkkkkkkkkkOkkOkxo:,.',:ccc:,...',:cccccc:::::::::cccccccccccccccc::;,'......:0WM
MMMMMMMMMMMMMMMMMMMMNl .oOOOOOOOOOOOOOOOOOOOOOO0KKKKO,.lOkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkd:,..,:ccc:;'....'',;;;::::::;;;;,,,,'''''..........',::,.'oX
MMMMMMMMMMMMMMMMMMMMNc .oOOOOOOOOOOOOOOOOOOOOOOO00KKO;.cOOkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkkkkdc,.',:ccccc:;,''...................''',,;;:::cccccccc:'.:
MMMMMMMMMMMMMMMMMMMMX: .oOOOOOOOOOOOOOOOOOOOOOOOOO0KO;.ckOkkkkkkkkkkkxxxkkkkkkkkkkkkkkkkkkkkkkkdc,..,:cccccccccccccccccccccccccccccccccccccccccccccc'.
MMMMMMMMMMMMMMMMMMMM0' 'dOOOOOOOOOOOOOOOOOOOOOOOOOO0k;.:kOkkkkkkkkkkkkxddxxxkkkkkkkkkkkkkkkkkkOkkkdc,..';:ccccccccccccccccccccccccccccccccccccccccc:..
MMMMMMMMMMMMMMMMMMMWx. ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOx' :kkkkkkkkkkkkkkkxdddddxxkkkkkkkkkkkkkkkkkOOkkkdc;'..',;;::ccccccccccccccccccccccccccccccc:;'.'d
MMMMMMMMMMMMMMMMMMMNc  :OOOOOOOOOOOOOOOOOOOOOOOOOOOOx' :kkkkkkkkkkkkkOkxxdddddddxxkkkkkkkkkkkkkkkOkkOkkkxdl:;,'''...................''''''''''',,;lxXW
MMMMMMMMMMMMMMMMMMMX; .lOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.ckkkkkkkkkkkkkkkkkxdddddddddxxxkkkkkkkkkkkkkkkkkkkkkkkkkxddoolllllcc:::::;..ckkOOOOOOO00KNWMMMM
MMMMMMMMMMMMMMMMMMMX; .lOOOOOOOOOOOOOOOOOOOOOOOOOOOOx,.lOkkkkkkkkkkkkkkkkkxddddddddddddxxxkkkkkkkkkkkkkOOOkkkkkxxxkkkOOkOkkxddddl.'OMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMK, .lOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.lOkkkkkkkkkkkkkkkkkkkxxdddddddddddddxxxkkkkkkkkkkxxxxxxddddxkkOkkOkkxdddd:.;XMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMO. .oOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..dkkkkkkkkkkkkkkkkkkkkkkxxdddddddddddddddxxxxxxxdddddddddddxkkkkkkkkkxdddd;.lNMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWx. 'xOOOOOOOOOOOOOOOOOOOOOOOOOOOOo.'xOkkkkkkkkkkkkkkkkkkkkkkkxxdddddddddddddddddddddddddddddxkkkOkkkkkkxddddo'.dWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWo  ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOl.,xOkkkkkkkkkkkkkkkkOkkkkOOkkxxdddddddddddddddddddddddddxxkkkkkkkkkkkxddddl..OMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMNc  :kOOOOOOOOOOOOOOOOOOOOOOOOOOOOc.:kOkkkOkkkkkkkkkkkkkkkkkkkkkkkkxxdddddddddddddddddddxxkkkkkkkkkkkkkkxdddd:.,KMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMX: .oOOOOOOOOOOOOOOOOOOOOOOOOOOOOk;.ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxdddddddddddddxxxkkkkkkkkkkkkkkkxddddd; cNMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMM0' 'xOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxkkkkkkkkkkkkkkkkkkxxddddo'.oWMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWx. :kOOOOOOOOOOOOOOOOOOOOOOOOOOOOo.'xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkkkkkkkkkkkkkkOkkOkxdddddl..xMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWl .lOOOOOOOOOOOOOOOOOOOOOOOOOOOOOc.,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddc.'OMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMX: .dOOOOOOOOOOOOOOOOOOOOOOOOOOOOk;.:kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddd; ;KMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMK, ,xOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddd, cNMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMO. ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOk:.,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddo'.oWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMk. cOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..lOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddl..xMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWd..lOOOOOOOOOOOOOOOOOOOOOOOOOOOk: ,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddc.'OMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWo .oOOOOOOOOOOOOOOOOOOOOOOOOOOOd'.ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddd; ,KMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWl .dOOOOOOOOOOOOOOOOOOOOOOOOOOOc..dOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxkOkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddd; cNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNc ,xOOOOOOOOOOOOOOOOOOOOOOOOOOk, ,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl;.ckkkkkkkkkkkkkkkkkkkkkkkkkkkOkxdddddddo,.oWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMN: ;kOOOOOOOOOOOOOOOOOOOOOOOOOOd..ckkkOkkkkkkkkkkkkkkkkkkkkOkkkkdccc,;xkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxdddddddo..xMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMX; :kOOOOOOOOOOOOOOOOOOOOOOOOOOc..oOkkkkkkkkkkkkkkkkkkkkkkkkkkxccxKo:xOkkkkkkkkkkkkkkkkkkkkkkkkkkOkxddddddddl..OMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMK, cOOOOOOOOOOOOOOOOOOOOOOOOOOk; 'dOkOkkkkkkkkkkkkkkkkkkkkOkko:oXM0clkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl.'0MMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMM0'.lOOOOOOOOOOOOOOOOOOOOOOOOOOx' ;xOkkkkkkkkkkkkkkkkkkkOkkkko:xNMMO:okkOkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl..OMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMk..oOOOOOOOOOOOOOOOOOOOOOOOOOOo. ckkkkkkkkkkkkkkkkkkkkkkkOxo:oNMMMKcckkkOkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddo..OMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMWd..dOOOOOOOOOOOOOOOOOOOOOOOOOOc..lkkkkkkkkkkkkkkkkkkkkkkkkl,:0MMMMWd:dOkkkkkkOkkkkkkkkkkkkkkkkkkkkkxddddddddo,.kMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNc ,xOOOOOOOOOOOOOOOOOOOOOOOOOk: .dOkkkkkkkkkkkkkkkkkkkkkkkc'cKMMMMMXl:xOkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd;.dWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMK, ;kOOOOOOOOOOOOOOOOOOOOOOOOOk; 'xOkkOkkkkkkkkkkkkkkkkkkkkc'cKMMMMMMKl:dkkkOkkkkkkkkkkkkkkkkkkkkkkxdddddddddd;.lNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMk. :kOOOOOOOOOOOOOOOOOOOOOOOOOx' ,xOkkkkkkkkkkkkkkkkkkkkkkko;:OMMMMMMMNx:lxkkkkOkkkkkkkkkkkkkkkkkkkxdddddddddd: ,KMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMWd..cOOOOOOOOOOOOOOOOOOOOOOOOOOd. :kkkkkkkkkkkkkkkkkkkkkkkOOxd:lXMMMMMMMWKdccdkkOkkkkkkkkkkkkkkkkkkkxllddddddddc..xWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNl .oOOOOOOOOOOOOOOOOOOOOOOOOOOo..ckkkkkkkkkkkkkkkkkkkkkkOkkkkd:dNMMMMMMMMWXxocloxkkOkkkOkkkkkkkkdoc,.:ddddddddl. :XMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMX; .dOOOOOOOOOOOOOOOOOOOOOOOOOOo..okkkkkkkkkkkkkkkkkkkkkkkkkOkkd:oKWMMMMMMMMMWKkdolllloooooolllloodl,;oddddddddl. .dWMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMX; 'xOOOOOOOOOOOOOOOOOOOOOOOOOOd..dkOkkOkkkkkkkkkkkkkkkkkkkOkkkOxlcdKWMMMMMMMMMMMWXKOkxxxxxxxk0KNXx:codddddddddl.  'OMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMM0' ;kOOOOOOOOOOOOOOOOOOOOOOOOOOd..dOkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkdlcokXWMMMMMMMMMMMMMMMMMMMMMNKxlcoxddddddddddo....:XMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMO. :kOOOOOOOOOOOOOOOOOOOOOOOOOOd..oOkkkkkkkkkkkkkkkkkkkkkkkOkkkkkOkkxocloxOKNWMMMMMMMMMMWWX0kdolldkkxddddddddddo'.,..xWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMk. cOOOOOOOOOOOOOOOOOOOOOOOOOOOd'.lkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkkkkkdllloddxxkkkkxxddollldxkkkkkxddddddddddd, ;; ;KMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWx..lOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdoolllloodxkkkkkOkkkkkxxdddddddddd, ,l..xWMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWo..dOOOOOOOOOOOOOOOOOOOOOOOOOOOx,.:kOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ,d; cNMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWl 'dOOOOOOOOOOOOOOOOOOOOOOOOOOOk; ;kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ,xl.'OMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNc ,xOOOOOOOOOOOOOOOOOOOOOOOOOOOk: ,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; 'xx' oWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMN: ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOc.'xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; 'xk: ,0MMMMMMMMMMMMMMM
MMMMMMMMMMMMMX; :kOOOOOOOOOOOOOOOOOOOOOOOOOOOOl.'xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; 'xOl..dWMMMMMMMMMMMMMM
MMMMMMMMMMMMMK,.cOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo.'dOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ,xOd. cNMMMMMMMMMMMMMM
MMMMMMMMMMMMM0'.lOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ,xOk; ;KMMMMMMMMMMMMMM
MMMMMMMMMMMMMO..oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ,kOOc '0MMMMMMMMMMMMMM
MMMMMMMMMMMMMk..oOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ;kOOo..kMMMMMMMMMMMMMM
MMMMMMMMMMMMMx..dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx,.lkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd; ;kOOd..dWMMMMMMMMMMMMM
MMMMMMMMMMMMWd.'xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx'.lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd;.:kOOx' lWMMMMMMMMMMMMM
MMMMMMMMMMMMWo.,xOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..oOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd;.cOOOk;.lNMMMMMMMMMMMMM
MMMMMMMMMMMMNl ,kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOd..dOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd,.cOOOO:.:NMMMMMMMMMMMMM
MMMMMMMMMMMMNc ;kOOOOOOOOOOOOOOOOOOOOOOOOOOOOOl.'xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd,.lOOOOl.,KMMMMMMMMMMMMM
MMMMMMMMMMMMX; :OOOOOOOOOOOOOOOOOOOOOOOOOOOOOk:.,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkxdddddddddd,.lOOOOo..OMMMMMMMMMMMMM
MMMMMMMMMMMMK, cOOOOOOOOOOOOOOOOOOOOOOOOOOOOOx,.:kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkxdddddddddd,.lOOOOd..xMMMMMMMMMMMMM
MMMMMMMMMMMMK,.cOOOOOOOOOOOOOOOOOOOOOOOOOOOOOo..lOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkxdddddddddo'.oOOOOd..dWMMMMMMMMMMMM
MMMMMMMMMMMM0'.lOOOOOOOOOOOOOOOOOOOOOOOOOOOOk: 'xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddo'.oOOOOx,.oWMMMMMMMMMMMM
MMMMMMMMMMMMO..lOOOOOOOOOOOOOOOOOOOOOOOOOOOOx' :kOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl..oOOOOk, lWMMMMMMMMMMMM
MMMMMMMMMMMMk..oOOOOOOOOOOOOOOOOOOOOOOOOOOOOc..oOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl..dOOOOk;.lWMMMMMMMMMMMM
MMMMMMMMMMMMx..oOOOOOOOOOOOOOOOOOOOOOOOOOOOx, ;xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl..dOOOOk:.lWMMMMMMMMMMMM
MMMMMMMMMMMWd..dOOOOOOOOOOOOOOOOOOOOOOOOOOOl..lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl..oOOOOk:.lWMMMMMMMMMMMM
MMMMMMMMMMMWo .dOOOOOOOOOOOOOOOOOOOOOOOOOOx' ,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl..oOOOOk;.lWMMMMMMMMMMMM
MMMMMMMMMMMWl 'xOOOOOOOOOOOOOOOOOOOOOOOOOkc..lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddc..oOOOOk;.lWMMMMMMMMMMMM
MMMMMMMMMMMNc 'xOOOOOOOOOOOOOOOOOOOOOOOOOd' ;xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd:..oOOOOk,.oWMMMMMMMMMMMM
MMMMMMMMMMMX: ,xOOOOOOOOOOOOOOOOOOOOOOOOk: .okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd; .oOOOOx'.dWMMMMMMMMMMMM
MMMMMMMMMMMK, ;kOOOOOOOOOOOOOOOOOOOOOOOOo. :kkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd; .oOOOOd..xMMMMMMMMMMMMM
MMMMMMMMMMM0' ;kOOOOOOOOOOOOOOOOOOOOOOOx, 'dOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd; .oOOOOd..kMMMMMMMMMMMMM
MMMMMMMMMMMO. :kOOOOOOOOOOOOOOOOOOOOOOk: .ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd; .dOOOOo..OMMMMMMMMMMMMM
MMMMMMMMMMMk. :OOOOOOOOOOOOOOOOOOOOOOOo. ,xOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd, .dOOOOc.'0MMMMMMMMMMMMM
MMMMMMMMMMMx. cOOOOOOOOOOOOOOOOOOOOOOd' .okkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddo' .dOOOk: ;XMMMMMMMMMMMMM
MMMMMMMMMMWd..cOOOOOOOOOOOOOOOOOOOOOx; .ckOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddo' .dOOOk; cNMMMMMMMMMMMMM
MMMMMMMMMMWo .lOOOOOOOOOOOOOOOOOOOOkc. ;xkkkkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. 'dOOOx'.dWMMMMMMMMMMMMM
MMMMMMMMMMWo .lOOOOOOOOOOOOOOOOOOOOl. 'dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. 'xOOOo..OMMMMMMMMMMMMMM
MMMMMMMMMMWl .oOOOOOOOOOOOOOOOOOOOo. .okkOkkOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. 'xOOOc.:XMMMMMMMMMMMMMM
MMMMMMMMMMNc .dOOOOOOOOOOOOOOOOOOd. .lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. 'xOOx,.dWMMMMMMMMMMMMMM
MMMMMMMMMMNc .dOOOOOOOOOOOOOOOOOd' .ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. 'xOOl.'0MMMMMMMMMMMMMMM
MMMMMMMMMMNc 'dOOOOOOOOOOOOOOOOd' .:kOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. ,xOx, cNMMMMMMMMMMMMMMM
MMMMMMMMMMX: 'xOOOOOOOOOOOOOOko. .ckOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddl. ,xOc..kMMMMMMMMMMMMMMMM
MMMMMMMMMMX: ,xOOOOOOOOOOOOOkc. .ckOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddc. ,xd. cNMMMMMMMMMMMMMMMM
MMMMMMMMMMN: ,xOOOOOOOOOOOOx;  .okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddd:. ,d; .OMMMMMMMMMMMMMMMMM
MMMMMMMMMMX: ;kOOOOOOOOOOkl.  ;dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd;  ':. lNMMMMMMMMMMMMMMMMM
MMMMMMMMMMX: ;kOOOOOOOOko,  .lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd;  .. ,0MMMMMMMMMMMMMMMMMM
MMMMMMMMMMK; :OOOOOOOkd;. .:xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd;    .dWMMMMMMMMMMMMMMMMMM
MMMMMMMMMM0, cOOOOOko,. .;dkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd;    cXMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMO. cOOkdc'  .:dkkkOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd,   ,0MMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMx..:oc'. .,lxkOkkkOkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddo'  .xWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMWo  .    .lkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddl.  cNMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMWo. .:xd. ckkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkxdddddddddl. .xMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMNOOXXx'.'okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkkxdddddddddc. .OMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMWKo'..:xkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddd;  ,0MMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMNOc...cdkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd,  :NMMMMMMMMMMMMMMMMMMMMMM
MMMMMMWXx;..,lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkxdddddddddl. .dWMMMMMMMMMMMMMMMMMMMMMM
MMMMW0l...:okkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxdddddddddd;  ,KMMMMMMMMMMMMMMMMMMMMMMM
MMXk:..,lxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxddddddddddc. .dWMMMMMMMMMMMMMMMMMMMMMMM
Xd'..:dkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxddddddddddl'  cXMMMMMMMMMMMMMMMMMMMMMMMM
; .:dkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxddddddddddddo'  :KMMMMMMMMMMMMMMMMMMMMMMMMM
:. .';cdkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkkkkkkkkkkkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxdddddddddddddddl'  :KMMMMMMMMMMMMMMMMMMMMMMMMMM
N0dl;....;cdkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddddddddo:. .lXMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWXOo:....;ldkkOkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddl'  'kNMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMWXkl;. .':oxkkkkkkkkkkkkkkkkkkkkkxxxxddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddl,. .oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWKxc'...;ldkkkkkkkkkkkkkkxxxddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddo:'. .lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMN0d;. .,cdkkkkkkkxxxdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddol:;..   .lOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMWKxc'..':odxxddddddddddddddddddddddddddddddddddddooolcccccccccccccccclllllllcccc:;;,'... ......  ..,cdOKWMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWNOl,...;coddddddddddddddddddddddddddolc:;,''..... ............   ......       ....,;:clooolcc:,..  .,lx0NWMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMN0d:. .';clodddddddddddddoolc;,'.....',:lodxx;.:llllllccc::::::;;;;;;;:::ccllooooooooooodkOOkxo:,.. .':oOXWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx. ......',;;;;;;,,'.........;x0KNWMMMMMWo.:ooooooooooooooooooooooooooooooooooooooooxOOOOOOOOkdl;'.  .:oONMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. 'lc:,'.........',,;:cllol:;dXMMMMMMMMWo...,,:clooooooooooooooooooooooooooooooodxkOOOOOOOOOOOOOkxl;'. .'lONMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. 'loooooollllloooooooooooooc;c0WMMMMMMM0l,...  ..';codxddddddoooooooooooooooddxkOOOOOOOOOOOOOOOOOOOkdc,.  'l0WMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd. 'odooooooooooooooddxxxxdddoo;,dNMMMMMMMMWXKOxo:'.  .'cdkOOkkkkxxdddooddddxkkOOOOOOOOOOOOOOOOOOOOOOOOOOxl,. .:kNMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd. ,xOkxddooooooddxkkOOOOOOOkkkkl,lXMMMMMMMMMMMMMWN0d:.  .,lkOOOOOOOOkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkd:. .:OWMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx. ,xOOOOkkkxxxkkOOOOOOOOOOOOOOOOl':KMMMMMMMMMMMMMMMMWXx:.  'okOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkxxdoollllllllloool'  .xWMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk. 'xOOOOOOOOOOOOOOOOOOOOOOOOOOOOkl.:KMMMMMMMMMMMMMMMMMMW0l. .;xOOOOOOOOOOOOOOOOOOOOOOOOxl;,...      ...      .    .OMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO. .dOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkl.;KMMMMMMMMMMMMMMMMMMMWKl. .okOOOOOOOOOOOOOOOOOOOOOOc  .,clodxkkOOOOkkxddool:;':0MMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK, .lOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOkc.:KMMMMMMMMMMMMMMMMMMMMW0:..:xOOOOOOOOOOOOOOOOOOOOOl. '0MMMMMMMMMMMMMMMMMMMMWNWMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc  :kOOOOOOOOOOOOOOOOOOOkdoxkOOOOOOk:.cXMMMMMMMMMMMMMMMMMMMMMNx'.,dOOOOOOOOOOOOOOOOOOOOx,  oNMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd. 'dOOOOOOOOOOOOOOOOOOOd'..,:okOOOOk;.dWMMMMMMMMMMMMMMMMMMMMMMKc..lkOOOxolllodxxkOOOOOOo. .xWMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0' .cOOOOOOOOOOOOOOOOOOOo.'xx:'':dkOOd''OMMMMMMMMMMMMMMMMMMMMMMMNx..;xOo'      ...',:cldxc. .kWMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl  'dOko:;:lxOOOOOOOOOOl.,KMW0d;.,cxkl.:XMMMMMMMMMMMMMMMMMMMMMMMW0;..l; .lxdolc:,...   ..   .xNMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;  :xc. .  .,cdkOOOOOOc ,KMMMMNOl,';:..kMMMMMMMMMMMMMMMMMMMMMMMMMXo.   lNMMMMMWWNK0kdl;'.   .kWMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK: .'. c0Oo;. .,cxOOOO: ,KMMMMMMMXkc. .dWMMMMMMMMMMMMMMMMMMMMMMMMMWk;.,OMMMMMMMMMMMMMMWNKOdldKMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd'  :KMMMW0d;. .;okk: ,KMMMMMMMMMWKddKMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkkXMMMMMMMW0o,. .;' ,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl'   :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl''xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
******************************************************************************************************
*/