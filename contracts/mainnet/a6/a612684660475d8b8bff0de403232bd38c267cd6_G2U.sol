// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Glory to Ukraine
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    kkkkkkkkkkkkkkkkkxo:;'':oxxc,,,''.';l:'.';;::c::;,;::cdkOOOxl;;;;cdkxlccx0000000000000000000000xollccldkOkkkOOkdoldkkkdlcoolc;;;,;odddddddolcccloxxxxx    //
//    kxkkxxxxxxxxxxxxxo:,'.':oxl'...''..,:,...',::;,;;,''''':lodlc:;;;:ldkxooxOOOOkkkxxxxxxxkkkkkkkxdoooc:ldooxkkkOkxdooxkkkdloddolldoccdddddo:;;,.,:;:ldxx    //
//    kkkxxxxxxxxxxxxxdl;'..,cdd;...'''.',;'...';cc;',;:;;,;;:ldxxdlcc:::cllc:cloooddxxxkkkOOOOOOOOOOOOkd::ldl;ckkkOkkxxddxkkxdddlcloOKxlodddl,;ldl,cxd:,cxx    //
//    kkxxxxxxxxxxxxxxdc,'.':ldc'...,,'..',....':loc;;:;,,;:clodxxxxdoc;'.';ldxkOOO0000OOOOO000000000KK0xdoddl:lkOOOkkkkkxxkkkkxdl;cox0Ooldxd:'lxd:.,odd;;dx    //
//    kkkxxxxxxxxxxxxxl:,..,:oo;...','...''....':odolc:'..;:ldxxkkkkkdc,'',oO000OOOOOOOOOOOOO0000OOOOkkxddddl:cdOOOOkkkkkkkkkkkkko::oxO0xloxdc';:;,.';::,:dx    //
//    kkkxxxxxxxxxxxxdc;,..,cdl,...,,...',;'.'',coddool:,:oxkkkOOOOOOx:,,;;cx000000OOOOO0OOkO00OOkxxxdxxkkkkxdxxdxxkkkkkkkkkkkOOkdc;coxOkoldxdc'.:l,;l;';oxx    //
//    kkkxxkkxxxxxxxxoc;'.',cdc'...'...',;:;,:::lddolloollxkOOOOOOkkxoc::;,;lk00OkkkxkkkkkkkOOOkkOOOOOOO000K000OxooooodddddxxxkOkoc;;lxxo:;lxxxoc::;;:clxxxk    //
//    kkkkkkkxxxxxxxdc,,;:cclc,'cc'...',;:::;colodxoccdocldkkxdoooollloddddxOOOOOOOOOOOkkkkOOOOOOOOOOOOOO00000KK0OOOkxxddoooodxkOdlllkKK0xc:oxxxxxxxxxxxxxkk    //
//    kkkkkkkkkxxxxd:,;loolc;'':xx:...';cll::ldodxxo;:lc,,:cc:cclodxxxO00KK00kxkOOOOOkkkkkkkkkkkOOOOO000000000KK00KKKKK000Okxxddddodk0KKKKx:lxxxxxxkkkkkkkkk    //
//    kkkkkkkkkxxxxxl,;;;;:lo:;lkkc...,:loo:;odxxxo:',,;;clodxxxddxxxddkkkkkkxkO000OOOOOOOOOO0000000000K0000KKKKKKKK000KKKKKK00Okdooddxxxd:;lxxxxxkkkkkkkkkk    //
//    kkkkkkkkxxxxdl:,;clxO0Od:lxko,.',coxo;:oolc:;;:loxkkOkkxxxxxkOOOOOOO00000000000000OOOOOOOOO000000000000000K00OdccdKKKKKKKKKK0Okxdol:;cdxxxxkkkkkkkkkkk    //
//    kkkkkkkkkxxxc'';ccokxlldocokxc,;coxxc;;;;:coxkOOOkkkOOOO0000000000000000000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOko;..;kKKKKKKKXXKKKK00Oxlldkkkkkkkkkkkkkkk    //
//    kkkkkkkkkxxxo;',;clddodOk::dkdccllc:;:coxkOOOOOO0000KKKKKKK00000000000OOOOOOOOOOkkkkkxxxxxxxxxxxxxxxxxxxxkxxo:'...l0KKKKKKXXXXXXKKKxldkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkxl,,cdddxkxxdccdkxl:cccoxkkkkkOO00KKKKKKKKKKKKK00000000OOOkkkxxxxddoolllllcccccllooollllloooddooc;''..,xKK00O0XXXXXXXXXOdxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkxl;cdxoccldkkkkxoodxkOOOOOOO00KKKKKKKKKKKKKK000000OOOkkxxdoollccc::;;;,,,,,,,;;:ccc::;;;:ccllll:,'....cOK0Ok0XXXXXXXXX0xxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkd:,:cclok00kxxxk000OOkO00KKKKKKOkxO0000000000OOOkxxdoollcc::;;;,,,,,,,,,,,,,;:lodddddddxxkkOkxl:,'...,xK0xokKXXXKKXXKOxxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkxdolc::ldddk0OxdkO000OkkO00KKKKK0ko:',cxOO000000OOkxdollc:;;;;;;;;,,,;;;;;;:cllodk0KKXXKKKKKKK00Oxdc,,''.'l0OocdKXXXKKKK0kxxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkko:;;:lodxxoodooxO000kxxk0KXXXK00ko:,''',:lok00000Okxdoooddolc:coolllccloooooxO000KXXXKKKKK0000Okdc;,;;,'''.:k0d:o0XXXK000Oxxxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkko::loolldxolcoxOOkxodk0XXXXXX0kxc''',''''';ok00000OOkO00KKKK0OO00000Oxxddoodk0KKKKKKK00OO00O000Odll:,,,'''.,d0xllOXXXX0OOkxdxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkxlodxxolooloodolllokKXXXXXXXXKd;'.'',,''..'ck0KKKKK000KKKKKKKXXXXXKKK0koc:,,:x0KK0000OxoxK00KXXKOdlol,''...'cOOdokKXXX0kkxddxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkxxxddxxoodxkkxdkKXXXXXXXXKKXx;.''',,,''.,o0KXK0OOkkOOOOO00KK000KKKK0kdc;'',lk00OOOkd:,:x0KKK0dddlcl:,,''..;xKkxk0OkO0kxoodxkkkkkkkkkkkkkkkk    //
//    kkkkkkkkkkkkkkkk0KKKKKkx0KXXXXXXXK0KKKX0l'..'',,,',lkKKXKK00KKK000K000000OO00K0Oxo:;;;lxOOOOkxol::coddooc:,';lolc;,'.,dK0kxOOdoxkdccoxkkkkkkkkkkkkkkkk    //
//    OkkkkkkkkkkkkkkkOKXXXKOdxOKXXXXXXK00K0KXx;''',,,,:oO00KXXXK0xx000KKXkdxO0OkOO00Okoc:;;cdkOkxddoooollllllc:;,;cllcc;,''l0KOxkK0dxkoccoxkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOkkkkkkkk0XXXKkddk0KXXXXXX0O000K0l''',,;:dO0OOKXKOOd:;lkOOOkdlodxdxkO00Okdl:;;:lldkkxdoddddoolcc::;;::;:::;,'';kXKkxOkk0Oo::ldkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOOOOkkkkxk0XXKkddxOKXXXXXXKkkOO0Kx;''';clx00OOOko::lolllooodxxxddxkO00OOOxoc:;;:;:dkkddooloollcc:::;;;;:cc:,'''oKXOxkOKXko::ldkkkkkkkkkkkkOkkk    //
//    OOOOOOOOOOOOOOkOkdx0KKkdxkOKXXXXXXKkdkkk0Oc'',:ldk000kl,;:oxxxxdddddxxddddkOOOOOOkdoc:;;,':xxdoollllccc:::;;;;:ccc:,'''cOXKO0KXKOoccodkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOOOOOOOOOkddkOxodO0KXX0OO00OooxxkOd,''',;clodxc,;lxkxxdddooddoooodkOOOOOOkxoc:;;;,;oxddoolllllcccc:::ccclc;,''';xKOk0NXKOdoooxkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOOOOOOOOkkkdoxxoldO00kolooooc:ccccc'.....','.;llcoxxdooollooollloxOOO00OOkxol::::::lxxxdoooooollllllllllc:,'''''lOkkKNXKOxdddkkkkkkkkkkkkkkkkk    //
//    OOOOOOOOOOOOOOOkkkkkdodo:;ldxdoxO0Oxo:;,.. .....;oxo'.cdooooooooollllllodkOOO0Okkkxol::::cllloxxxoooooooooddddol:;,''''':k0k0XXKOkdxkkkkkkkkkkkkkkkkkx    //
//    OOOOOOOOOOOOOOOOkkkxocclc;cx0X0O0XKOl'. ..,c:'..':oc.,loooooolllccccllodxxO00Oxddxxoc:;;;cllc;:oxdoooooooodxxxdc;,'''''',dOdxXXKOxxkkkkkkkkkkkkkkkkOko    //
//    OOOOOOOOOOOOOOkkdoooddodxclkOKXKxoc'. ..,ldkx;''.''.'lddddoolccc::cclooddxOK0OxxkOOxolc::lllccccodoooooollcccc:;,,'''''',okod0KOkkkkkkkkkkxo::dkOOOOxl    //
//    OOOOOOOOOOOOkxooodkkkkxdxdoxO00d;.  ..;coxkkxo;''...:dxxxxdoolcccccclooodk0KKK0KKKK0Okxxxdccx00koooooooollc:;,,,,,,,'''''cdlokOkkkkOOOOxl;...:xOOOOkll    //
//    OOOOOOOOOOkdoodkkkkkkOkxxxoldo;.. .,c:cloooldkd,...,:dkkkkxdoolc:cccloodxxOKXXXXXXXXXXXK0kx0XX0xoloooooollc:;,,',,,,,'''':oodkxdoxkOOOkc....,dOOOOkocd    //
//    OOOOOOOOxoooxkkkkkkOOOOkkxd:.....';dOdoxkxxkkxl'...;lkOOOkxxdolcccllloddllx0KKXKKKKKXNNNK0KKOxdolloooooooollc:;,,,,,,'''';lc:;'.;xkkkko'....lkOOOOxcok    //
//    OOOOOOkdodkOOOOOOOOOOOOOxl,.....ck0xkkodxkkkd,.,,.';oO0Okxxxdoooooooodoc::dO00KKKKKKXXXXXXKkolooooooooooooollc:;,,;,,,,,'.... .'oxxxxd;....,dxxxxdccdx    //
//    kkkkkdlodxxxxxxxxdddddol;.....,dKXX0dxkddxd:.'oOo'';lxd;,:looddddddddoc:::ccodkO0KKKKKKXXKkdooooooooooooooooll:;;;;,,,,,..    ..,;,,,'. ....,,,,,'.',,    //
//    ::;;,,,;;;;;,,,,,,''''.......'cx0K0kooOXX0l,cOXKo,,;::...,:cloddolodollcccccccloxO0000000kdoddddddddxxxdddooolc:;,,,,,,'.  ...........   .............    //
//    ''...''''.....''..............',::;'';oxo;,dKXKOl;;,'...';;::;,'.;ooooooooooooodddxkkkkkxdddxxxxkkkkkkkkkxddol:'...',,,.. ............ ...............    //
//    '..'''...............................','':x0KKOolo:'...';;;'.. .'lddddddddxxxxxxxxxdddooodxkkkkkkOOOOxoloxxdl;.....',,'...............................    //
//    '''''...................................;d00OOoldd:...',;;'.....cxxxxkkkkOOOOOOO000000OOO0XXXKK0000kc'...:do,. ...,;,,................................    //
//    ''''''..................................,;:cllllol'..',,;,.....:xkkOOO00KKKXXXXXNNNNNNNNNNNXXKK00Ox:......c;...';::;;'.....,c;........................    //
//    ''''''''''...................................:ddc'..,,,;,.....;xOOOO0KXXXXXXXXXNNXXXXXKKKK00OOkxdc;;,.....'..':llcc:,.....'lo:'.......................    //
//    '''''''''''..................................,ld;..;l:,;'....'okkkkkO00OOkxxxxxkOOOO00OOOkkkkkxdo:cl'......':ooollc;......cdo;........................    //
//    '''''''''''...................................,;.';cxxc,.....ckkkkkkxxxddddoooodddxkkOOOO000Okkxlld:......'cdddool:,.....'lxl,.......................'    //
//    '''''''''''..........'''''......................'loldOd,....;dkOOkkkkxxxxxxdxxxxkkkOO000000000Ooldl'.....;:coddoccc;.....;lc,..........',,;:c:,'.....'    //
//    ''''''''''.........''''''.......................,lxxodc....'cdkOOOOOOOkkkdlcc:::ldO0000OOOOOOkoloo;......coccllloxx:......'.........':lodddooodc'....'    //
//    ,''''''''........''''''..........................,cxxc.....;odxO00000Oko;'...','..;dkxxxxxxxdlclo:......,lddddxO0KKl..............':odol:;,,''cdc'...'    //
//    ,'''''''........'''''.............................':o;....:dddxkO000xc,..,clodxdo;.'lddddddoccloc'......:oxkO0KXXXKx;...........':ldxx:'......'cd:'.''    //
//    ,,''''''........'''..............................',:;....'d00OkkOOxc'..;okOOkxo:;;..:oddddoccodo;......;dk00KKKK0OOOkdlclc;'...'cdxkkl'........,lo;'''    //
//    ,,,,,''........''...'''''''''',;,'.....'......',;cdl'....:dO0KK0kl,..'lOK000Ol'.....;dxxdlcodxdc......,okkOOOkkxxdddxkkkkkxl,..:dkOOo,..........,odl::    //
//    ,,,,,,'........''''''''''''';ldxdo:'.''......cdkkkx;....:xxxO00Oc...,dKXXXKKk;......:kxoloxkkkxc,;:loddxddollc:;,,'',;:okkkxc';oxOOx:...........';dkkk    //
//    ,,,,,,'.......'''''''''''';okOOkkkOd:'......,dkOOOl....,kXKOkOkc...'dKXXXXXXx,.....'colok0000Oxodxxdoc:;;,'............'cxkd;,lxkOkc'...........'':xkk    //
//    ,,,,,''......'',,,,,,,,,,ck0K0OkkkO0kc'.....:xOOOd,....lKNNNKOc....cOKXXXXXXO:..',,;ldOKKKK0OxdxOx:''...................,okl;cdkOOo,........'...'''ckO    //
//    ,,,''''.....'''''''''',,ckKXK0OOkOOxl:lc'..'oO00x;....:ONNNNNk,...;x00KKXXK0OxoooolokKXXXX0kdxkOOx:'.......',,,'........,oxccdxOOx:'.....'''''...'',lO    //
//    ,',,,,'''...'''''''''''':kKXK00OOOxc:dk:...;x00k:....'dKXXNX0l'..'o0KKKK0Okkdoc:;,',lOXNXOxdkOOOOx:'.....'':dkd:'.....'':xxloxOOkc''...'',;,'''...'';o    //
//    ,,,,,,''''..',,,,,,,,,,,,cdOKKK0Oo:lO0o'..'cO0Ol'....:k00Okkxdl;.;kXXXKOkkxdc''..''',oOXKkdxkOOOOx:'......'ckOxc'....''cxkddxOOOo,'...'''lxc''''..''';    //
//    ;,,,,,,''''''',,,,,,,,,,,:odkKKxc:oO0o,...;xK0o,',;:cdxkkkkxxxkl':OXKOkxkkl;,'.....'',o0KkdxkOOOOx:'......':ol:'....''':dxdxOOOd;''...'';xOx:'''...'',    //
//    ,,,,,,,,'''''',,,,,,,,,,,,cdolc:okOOo,..',lkOxoodxxkkxddolc;,cxl'cOOxxxOOd;''.......'';oOxdxOOOOOx:''....'''''.......''';dkOOOx:''...'',cddl;''''..'',    //
//    ;,,,,,,,,''''''',,,,,,,,,,,;;;lxkOko:;:cloxkkxxxdolc:;,,''''':xo';xxdxOOx:'''...'...''';oxdxOOOOOx:''.......''''''....''':xOOkl,''..'''',,'''''''...',    //
//    ;;;;;;,,,,,''''''''''''''';lookOOOxooxkkxddolc:;,''''''...''':xo',ldxkOkc,''...'''...''';oxxOOOOOx:''....'',:cc:,'''..''',oOOo;''...''''''''''',''''',    //
//    ;;;;;,,,,;;;,,,,,;;;:::cccdkxdO00OxxkOOd:;,''''''''''''...''':xo,;odkOOo;'''...''''...''';dkOOOOOx:'''...',lkOOOd;''..''',oOx:'''.''''',,;:clldl;,,;:c    //
//    ;;;;,,,,,;:cloddxkkkOOkkkkOOkk00kxxkOOOd;,,'..''''''''''''''':xkoodxOOx:''....''''''..'''':xOOOOOx:'''..'',lOOOOd;''..''':xkc,''.'',;cooddxxxkOOdoddxk    //
//    ;;;,,,:codxkO00OkxdollccccccloxOkkO00OOx:,,'''',,,,,,'''.''',:x0kdxOOkl,''...'';:,'''''''',cxOOOOx:'''..'',lkkxl;'''.''';okl,''''',,lxkxxxxxkOOkkxxxxx    //
//    ::;:coxkO000kxol::;;;,,,,,;;:okkkO00000xc,,'',,,,:ol;,'''',,,:xOxxkOOo;''''''',lxc''''''''',ckOO0x:'''..''';:;,''''''',:dOd;,;;::cloxxxxxxkO0Okxxxxxxk    //
//    ccodkO000Oxoc:;;;,,,,,,'',;:okkxxO00000kc,,'',,,,oOx:,,,'',,,ckkxkOOx:''''''',:xOd;,,,''''',,lk00x:,''...'''''''''',;cdkOOdoodddxxxkkxxdodk0Okkxxxdooo    //
//    dxkO000Oxl:;;;,,,,;;;;;;;;;okkxxxO00000x:,,,,,,,;oOx:,,,,',,,ckOkO0kl,'''',,,,:ll:,,'''''',,,;oO0x:,,''''''''',,;cldkO00Okxxxxxxxxkxdodo:;lddollc:::cc    //
//    kkO000kl:;;;;;;;;;::cccc::okxloxxk00000x:,,,,,,,;d0x:,,,,',,,ckOO0Oo;,'''',,,,,,''''''''''',,,;oOx:,,,,,,,;:clodxO00OO0Okxxxxxxxk0K00XNXd;;;:clodxk000    //
//    O000Odc:;;;;;;:coxkkOOOOkkOOl;oxxk00000d;,,,,,,,:d0xc,,,,',,,ck000x:,''''''''''''''''',,''',,,,:dd::cllooddxkOkkO0OxdkOkkkkkxxkOKXXXXXXX0xxkO00XNWWNK0    //
//    0KK0dc:;;;;;:lxO0000000000Oo;;oxxk0000Ol;;,,,,,,cx0xc,,,'',,,ck00kc,,'''''',,,,,;:cllc;,,;::clodkkxxxxxxxxxkOkkOOOxcoxxdoollcokXNNXXXKK000000OO0XNNX0O    //
//    KK0xc::;;;:cdO000000000000d:,cdxxO0000d:;;,,,,;;lO0xc,,,'',,;ck0Oo;,''',,,:clodxxkOO0OdodxxxkkkOOxxxxxdxxxOOkxddkOo::cccllodxOXXXXNNNXKKK00O000KXNNXOO    //
//    KKOo:::;;::oO000000000KKKOo:cdxxkO000xc;;;,,;;;:x00xc;;,'',;;ckOd:,,,,,,,:dOO00000000OkxxxxxxkOkxxxxxxxxdddlccoOXKkkOO000000OO0KK0KXXK0000000KKXNNXKOO    //
//    KKkl::;;::cx000xoolodOKK0OOkxxxkO00Oxc;;;,,;;;;oO00kc;;,',,;;ckxc;;;;;:cldO000000000OxxxxxxxkOOxxddoolcc:::ldkKNNNNNNNNXXKKK0000OOO0KKOOOOOOOO0O000000    //
//    KKkl:::;::cx00OkkxdloOK0OdokOOO00Oxoc;;;,,;;;;lk000kc;;;;;;;:lkdlooddxkO000OOkkkO00Okkxxxddoollc::::ccloxkk00KKKKXXXKK0KXXXK0K000OO0KXK0OOOOOOOOOO000K    //
//    KKkl:::;::clxO0KKK0OOOxdl::cxO00xl::;;;;;;;;:ok0000kl:ccloddxkOkkkkkkkOOkdollc::oxdoolcc::::clooddxxkO0KKKK0000000KKKK0OO0OkkOOkxxxkO00OkkkkkkkkkkO0KK    //
//    KKOocc:::::ccloddddolcc:::;:cdOOo:;;,,;;;::ldO00000OkxkkkkkO0OkxxxxxkOOxoloddddl:::cclodxkO00KKKK00OOOO0KK00KKKKK0000KK00Okxk00OOOkO0KK00OOkkOOOOO0KXX    //
//    KK0dccc::;::cccccc::::::;;,;:cdko::;,;;::cdkxx00000Okkxxxxk0OkxxxxxkO0OOO0KXXXXOddxO00KKXXXXXXXXKKK00OOO00OOO0KXXKK00KKKK00OO0XXKK0KNWNNXXKK00KKKKKXXX    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract G2U is ERC721Creator {
    constructor() ERC721Creator("Glory to Ukraine", "G2U") {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
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