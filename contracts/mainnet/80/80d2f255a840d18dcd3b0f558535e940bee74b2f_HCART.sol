// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: HENRY CHEN ARTWORK
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                      ...'''';;;c;:,:d::;;;,'.'.,.....                                                                 //
//                                                  ...,.':'lllo:olc:ldodcl;cOcllllcc::coc::lc;:,'.....                                                  //
//                                          ...;,cl,dl;d;ck:xxdxcdol:cdodcc;lOcclloccccldcclooldllllllc;::;...                                           //
//                                     .,'l:cockdkO:xo;d;ck:dxdkcddo:coldol;o0c:cloc::cldlclooodcllllol:lddlooc:;'..                                     //
//                               ...'c.:Ocxxlockdx0ckd;d;:x:dxdx:ooo::oldll;l0lcccoc:;cldlllooldcllllol:lddoooolocllc;.'.                                //
//                            .,':O:;k;;kcdxlockdx0lkx;d:;xcdxdkldoo:coldll;lOllllllccclxlclolloclllclc:lxddolold:lldo:d;;,..                            //
//                        ..,o:kd:Ol,xc,klodcdlxdd0cxx;d:;xcdkxkldooccoldll;lOcllclllllldccllclo:cllclc:lxdoololo:cldlcd;oc;d,,'                         //
//                     .',xl:Olxk:Ox,dl'xoldcdcddo0ldk;xl,dcxOxkldlolcololl;lkcllclllccloccllccl:ccllc::oxoolcoldccloclo,o::d:ddc;.                      //
//                   ''lk:xd:OooO:xk,oo.ddldco:oxo0loO:xo;dcdkxkldlollococl;lkclocccc::ldccolccoclcoolccddoolclldllolcll;d;lo:xodl:c..                   //
//                .';xlckcok:xdlOcoO;ld.oxldcocoxoOco0cdd;dcokdxcolol:lcocc;cx:loll:c:cldlcolccolllollccdollllllolldl:occd;olcxox:od:o,.                 //
//              .,:dldd:klckcxdc0lcO;:x,cxldloclxlOll0cod;dcokdxcdloc:l:lcc;cx:clllcc;cldlcolccolololcccxolcoollllloc:o:lo;dcldod:dlld:o;                //
//              .doddoxckd:klokcOd:Oc;k;:xldloccxlOdl0cox;dllxdxldllc:l:ccc,:d:clcc:c;clolcocccoloooollldcc:lolollloccd:ol:dcdddocd:olcd:l;              //
//               ldoxlxcdx:xdoOlkk;xo,x:;xldooocklkdcOlok;oolxdxcoclc:l:ccc,:x::cc:::,lloccdlcclldoooclldcc:loldloooclo:dcco:xdxcco:dclo:x;              //
//               ;xododolk:dxlOodk,od'oc;xloooo:klxkl0llk:oolxxxloclc:l:ccc;ck::lll::;llolcdlccllddllclldllcloldlooolol:x:llcxddcolld:dllx.              //
//               .dddoodlOllklxdoO;lx'lc,xloooo:xldklOolk:oocxkkldcll:l:ccc;lkcclclcc,lllccoll:clooll:oodllclocollooooccd:dclxddcdcdlcd:do               //
//                cxxddxlkdckldxoOcck,co,dololl;dodkckdlkcoo:dkOldlol;l:ccc,ckcclclcl;llllco:c:clolll:ololcllocolooolo:locd:oddolocx:od:k:               //
//                'xkdoxodkcxooklkl;k::o,ddodll;oookcxock:oo:dxkodool;l::::,:k::lclll;lodlco:c:cooolo:oclcclcl:llldloo:ollocxdocolod:xllx.               //
//                .okkdxooOlddckoxo,xc,o;ddldlo:oooOcddck:lo:odkodoll;oc:cc,:k::cclcc,coxlcdcc:cooooo:dllcclcl:clldloo:oclllxoococdolk:do                //
//                 ;kkdoxlkoox:xddd,do'o:locdlo:ldoOcdd:xclo:odklooll;occcc;ckc:ccl::':odc:d:::lolooo:olll:occ;clldcolcococdddolllkcod:x;                //
//                 .dOdoxoxdcxlddok;od'l::dcdlo:cdoOlod:kccd:loklloll:occcc;ckc:lcl::,:odccx:::lollcl:olllcoccccoodclclllolxddolcdd:xlld.                //
//                  ckxlddokcdooxoOclx':c:dcdllccdo0ood:kllxcooxlllco:occc:;cOlclcl:c;:odclkcc:locccc;oollcocclclloclclllloxddolcxccxcdc                 //
//                  ;xkolxoklldoxokock;;l:dclllccxlOxdxlkllkcooxooococlccc:;cOlclcc:c,:dxlcxc::locccl;llllcllll:lllclclllloddoolok:oocd'                 //
//                  .dkdlddxdcxdxodx:kc;o:ocooolcxlkkdklklcOlodxdoocdcolcc:;cOlllcc;:,:dxlcdc:;colcco:lololooll:llclccclcloddoocddcxcol                  //
//                   ckkoodoxcddddlkcdd;ocooodolcxokkdklxlcOloodooococdolc;,:xcclll;:,:dxccxlc;cocccl:loldoodldlodcc:ccc:ldooolcxcodld'                  //
//                   ,xOdcooxoldodcxlok:oodooxoo:xoxkokoxlc0lodxoldcoldollc;;d:cdol;:;cdxllxlc;coclclclololodlooodllccl::loooolod:dlol                   //
//                   .oOklloodlxoxldxlklddoolxdocddxOokoxoc0oodxdldcoloollc::x::ool;:;cxxllklc;cdllclccoldooxlddodllllolllllodlxllold'                   //
//                    ,kOdldodoxxkdoklxooxxkxOOOk000X0KO00kXOO00OkOxkdxdolccck::ooollcdO0kkKkxxk0OkkOkxOkOkkOkkkxxolocdoooolooodcocl:                    //
//                    .oOkodddddkxxokO0XKNWWWMMMMMMMMMMMMMMMMMMMMMMWWWWNXK0kxKOOXXXXNNWMMWMMMMMMMMMMMMMMMMMWWWWNNXKOOddddkoooldllolo.                    //
//                     'xOxdxxxdk0KXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXK0kddodololo,                     //
//                      cO0xxxxOKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0xdxooooc                      //
//                      .d0OdxKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOddddl.                      //
//                       'x0O0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOdxd.                       //
//                        ,kKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKkx,                        //
//                         ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,                         //
//                         .xMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                          //
//                         .kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                         //
//                         .kMMMMMMMMMMMMMWNNK0OkkO00000KXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXK0OOkkkOOKXNWWMMMMMMMMMMMMd.                         //
//                         .kMMMMMMMMMNk;                  .ox0XWMMMMMMMMMMMMMMMMMMMMMMMMMMNX0Ok                YoOKNMMMMMMMMWd                          //
//                         .OMMMMMMWx     moXcoddddxxl:cc:;    lxO0NMMMMMMMMMMMMMMMMMMMNK0ko     ::clodxdddddolc    .xKWMMMMMWd                          //
//                         .OMMMMW.   cdkOKXXNWWMWWMWNXXKOdoc:    :okXWMMMMMMMMMMMMMWNOo:    cldxOKXNWWMMWWWWWNXK0kd   dKWMMMMd.                         //
//                         .OMMM.  jkKNWMMMMMMWNWMWXNMMWWMWWX0xc;   :o0WMMMMMMMMMMMMXo:    lk0NWMMWWMMNXWMMWWMMMMMMWWXOd .XMMMx.                         //
//                         .OMM od0NMMMMXkxXMXc dNO;;OWk .NX .XXOdl  lOWMMMMMMMMMMMM0l  :lkXXxdXNd:xW0;,OWk;lXW0kXMMMMMWXk NMMx.                         //
//                         '0MMNKWMMWNXW0' ,ONo  dKl  O0, o0c :KMWNXXXWMMMMMMMMMMMMMWXK00XN0; :Kx..kK; ;KO' lXk  xWNXWMMMWWWMMx.                         //
//                         '0MMMMMMM0 'dXk. 'OK: .dO; 'dc  cd. ,0WWWWWMMMMMMMMMMMMMMMWWWWNk' .ld. ,x: .d0: :XO' cKO;'dWMMMMMMMx.                         //
//                         '0MMMNOkXXc. lXO'   '                'OWWX0XWMMMMMMMMMMMWKKNWNx.                    ;Kk. ,0NKKWMMMMx.                         //
//                         '0MMMk. ;0Nd.          ........       'OWXko0WMMMMMMMMMNkxKNNd.        ........         ;0Kl  OMMMMx.                         //
//                         '0MMMNo. 'dd'      .:dOKXNWWNXKkl,     ,0Xx:;kWMMMMMMMNd;oOXx.     'cxOKXNNNNX0kl,.          cXMMMMx.                         //
//                         '0MMMMNo.        .oKWWKOkxddxk0NMNk:.   cKd..'OMMMMMMWk..'dk'   .ckNWN0kxxxdxkKNMNOc.       cXMMMMWd                          //
//                  ....   .OMMMMMNX      .lKWWOloxO000OxllkNMWO,  .xk'  :XMMMMMK; .c0l  .:0WMNkoodkO0kxoldOWMWO;     ;KMMMMMWo    ....                  //
//               .;x0KX0x:..OMMMMMMN.    ,OWMNd:dKKkoldOX0l,oXMMXl. :Ko. .xMMMMMk. 'OK; .dNMMXdlxK0dlclxK0d:xNMMNo.   OMMMMMMWo..ck0XK0x:.               //
//              .x0OkOKNMWx;xMMMMMMMN.  ,0MMMk:dX0:    .lKKo;xWMMNl '0K,  lWMMMMk. :XK, lNMMWxckXO´     c00o:OMMMNl  dWMMMMMMWo;OWMN0xdx0k'              //
//             .dd'.'lxOKNNoxWMMMMMMMK  .kWMWd;xXx  oo  'kXx;oNMMNc ,0k.  oWMMMM0' .kXc :XMMNdl0Nd  oo   OKd:xWMMK; cNMMMMMMMNdxWNOxdc'..ox'             //
//             od..lKWNOldKdoNMMMMMMMMK  'kWM0cl0Ko    'dKKo:kMMWx  oO;  ,0MMMMMWo. ;0O  dWMWOcxKKo    ,dKOlc0MMX: ,KMMMMMMMMNdkXocxXWNd..lo             //
//             kl.cNWO:. .ddlXMMMMMMMMMK  .oNWO:ck00kxk00kcckWMNx  l0xc,,xWMMMMMMKc,:xXd  xNMNkclOKKOkO00xccOWMXc  OWMMMMMMMMXdkd.  .oXWx.;x             //
//             xo.dWX; .lodlc0MMMMMMMMMMXl  :0WKxllloolcccdKWW0:  dNN0d.xNMMMMMMMWO.o0NNx  c0WWKxoooooolclxKWWO,  OWMMMMMMMMM0lxdox; .xWK;:d             //
//             :x:dW0'.kWOkd:OMMMMMMMMMMMNx  .cONNKOkxxOKNWXx:  c0WWWX.kNMMMMMMMMMWO.0NWWKo  ;xXWNKOxxxOKNWNk:  cKMMMMMMMMMMMOckkOW0'.dWKllc             //
//              lddXX::XXx0k;kMMMMMMMMMMMMMXo   'ldkO00Oxo:  ,oKWMWWX.kNMMMMMMMMMMMW0.KNWWWXd;  ;oxO000Oxdc'  cOWMMMMMMMMMMMMx:0KxKK;;KWkll.             //
//              .lxkXOdKOkNk,dMMMMMMMMMMMMMMMNOo,.        .x0NMMMMWX.xNMMMMMMMMMMMMMW0.0NWWWMWM...        ..kXWMMMMMMMMMMMMMWl;KWOkkl0WOdl.              //
//               .dOOX0kkxKk'oWMMMMMMMMMMMMMMMMMWNXKK0KXNWMMMMMMMW.CONMMMMMMMMMMMMMMMMK.0WWWWMMMWNXK0OO0XNWMMMMMMMMMMMMMMMMMX;;K0xxkKXkxo.               //
//                .kKOK0kxxo.cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX.XKMMMMMMMMMMMMMMMMMMMXO.NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO.,dxO000k0x'                //
//                 ,0XOKNKkl.;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMC.0WMMMMMMMMMMMMMMMMMMMMMW0.KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo ,okNX0KNK;                 //
//                  ;KWNWXKx..OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.K0WMMMMMMMMMMMMMMMMMMMMMMMM0k.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK: ;0XWWWMNc                  //
//                   :XMMMMO'.oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM.0KMMMMMMMMMMMMMMMMMMMMMMMMMNO.MMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx..cXMMMMWx.                  //
//                   .xWMMMO' ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM 0WMWXOkk0XWMMMMMMNK00KNWMMK NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;  cXMMMMK;                   //
//                    ;KWMWk' .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWK Nk'    'dNMMMNd,     kW. NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.  ;0MMWKc                    //
//                     .cddc.  .dNMMMMMMMMMMMMMMMMMMMMMMMMWNNXKKKk xoc:;;:dXMMMXd:,;:cd0 O0KXXXXNWMMMMMMMMMMMMMMMMMMMMMMWx'.. .:ddc'                     //
//                         .. . .dNMMMMMMMMMMMMMMMMMMMWKkdl: ,,' '.'...ooddddddoooooo....'''', ,:ld0XWMMMMMMMMMMMMMMMMMWk,... .                          //
//                         . .....oXMMMMMMMMMMMMMMMWKxc'..   ..  ..    .    ..  ...    .  ...     ..;cxXWMMMMMMMMMMMMMNx'..  .                           //
//                         .  .   .:OWMMMMMMMMMMMWOl'.   . .   . .       ..   .. . .  ..      ..      .;dKWMMMMMMMMMW0l.... ..                           //
//                         .. ..   ..lKWMMMMMMMWKl  . ., .´ol.olo.oll.llccccc.clc:c:;::;;:clcc.cn. ' .  .,xNMMMMMMWKo'...  ...                           //
//                         . ..   .. .'o0WMMMMXx; . ..,dOkk0KKXXNNNNNNNNNNNNNNNNNNNXXXXKKKKK00Okdddl.   ...oXMMMNOo,. ....  ..                           //
//                         ..    ...   .'cdOKk:.  ..  PxX xXNNO.NNNNKO.NNNNX0,KNNNNN.0XNNNX,0NNKk NkO      .;dOx:....   ..  ..                           //
//                         .. ..  ...   .............  OE FEKER DMMM0k XMMMWO 0MMMMX OXMMMG CXNWH OD   .     ........ ..  ....                           //
//                         ...  . .....   ...... ..       ´vEW+ ´CXRTY O00Odc KK00ON ZUEPX´ +OPu´          .........  .... ...                           //
//                         ......  .....   ......  ..                   █         █                    ....  .......... ......                           //
//                          ... .. . ...  ...   ...... .               █ H E N R Y █              .  ... . ....  ..... ......                            //
//                          .... . ....   .. .  ......':x ,            █  C H E N  █              xcc:..  ..... ...  ....  ..                            //
//                           . .. ......  .....  . ...'co xOkc.         █  N F T  █           cxxd xdc..  ..... ....  .... ..                            //
//                           ...  .....     ..  ..  ...'lddONWK Ac,.     █████████     .;cD XWNkooo:.. ...... ....   ...  ..                             //
//                            ....  ...  ......     ... .:dkkOO GWWXkc cdk00k OK0kxo lkXWMV O0Okxl'... ......... ... ......                              //
//                             ..  ......  ..   ...  ....:dOOxk0KNXOKM MMWOo0 MMMMXK NK0kxO0kl,. ... ..     .  ... ... ...                               //
//                             . . .....    .......     ..  .,cxKK0KOxOKKKXKdcxKK000OkO00KK0xc'...    ...  ...   ... .....                               //
//                              .. ....    ..... .....    ..  ..,lx0KXKKK000OOOOO0KXXNXKkdc'......   ..  ....   .........                                //
//                                ....  ..  ...  .   ......    .....;:loodkkkkO0Okxdoc;'.........   ..... ......   .. ..                                 //
//                                 ... ...  .. .    .  ....  ...  ...........  ....... ......   .. ... ...    ....  ...                                  //
//                                  .. .. .   .. .......    .....  ... ...... ....  ......  .... ...  .....     ......                                   //
//                                   .. .... .. ...  ...   ....   ...  ... ..  ..... ......  ............ ....  .....                                    //
//                                     .... ...      ..   .   ...... .....  ........   .....  ........ ..  ..... ...                                     //
//                                      . ...   ... ..    ......... ..  ..  ... ..    .......  .......   .......  .                                      //
//                                         ......   .   ...  .......  ...   .   ....   ... . ..   .....  ....  ..                                        //
//                                           ......  ....  ....   ...  .. .... .     .  .... ...  .. .........                                           //
//                                             .....  .....      ...  ......   .   .  ..   ....    . ......                                              //
//                                                ....  ...  .. ....  ... ... ..   ......    .. .  ..  .                                                 //
//                                                   ....    . .....   ..  .......        ......   ..                                                    //
//                                                      .. ...   ...    .......   .....   .... .                                                         //
//                                                            .   .......     ...    ....                                                                //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                                                                                                                                                       //
//                               ██   ██  ███████  ███   ██  ██████  ██    ██         ███████  ██   ██  ███████  ███   ██                                //
//                               ██   ██  ██       ████  ██  ██   ██  ██  ██          ██       ██   ██  ██       ████  ██                                //
//                               ███████  ███████  ██ ██ ██  ██████    ████           ██       ███████  ███████  ██ ██ ██                                //
//                               ██   ██  ██       ██  ████  ██   ██    ██            ██       ██   ██  ██       ██  ████                                //
//                               ██   ██  ███████  ██   ███  ██    ██   ██            ███████  ██   ██  ███████  ██   ███                                //
//                                                                                                                                                       //
//                                                                                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract HCART is ERC721Creator {
    constructor() ERC721Creator("HENRY CHEN ARTWORK", "HCART") {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

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
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}