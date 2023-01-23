// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Fimmina
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKK0000OOOO000KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKK000OOOkkkkkOO0KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKK0000OOOOkkkOOO00KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKK0000OOOOOOOOO000KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK00OOOOOOOOOOkkxkkkkkOO00KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKOkkxxdxxk0K0OkxdddddxxxkkOO00KKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0Okxdoodk0KXNNXK0OxdodddddxxkkOO000KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0OkxdoooxO00KXXXXXNNX0xdddddddxxkkOO0KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK00KKXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0Okxdooodk000KKKK000KKK0kxddddddxkkO00KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK00KKXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0OkxdollodxOKXXX0kkOkOOkxxxddxxxxkO00KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0OkxdoooodxxOXNX0xoodxxxxxxkOOOO000KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKOkkxdddddkkkOXWNKkdddxkOO0KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0OkkxxddxxO0KKNNNKOkkOO00KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0OOkkxxxkO0KXNWNKOkOO00KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKK00OOkkOO0KNWWNX0OOO00KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKK00OOOO0XNWWNNKOOO00KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKK00OOxxOXNWWNNKOkkOO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXKK0000OOOkdkXNNWWN0kxkkkO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXKK00OOOkOkdkKNNXNN0xdxxkkkO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXK00OOOkO0kdOXXNXXKOxdxxxxkkO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXKK0000OO00OOKXXXKOxxxkkxxxxkO00KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXKKK00000K0kk0KXNXkoldkOxxxxxkO00KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXKKK0000OOOkddO0KNX0xllxOOkxdxxxkO00KKKKKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXKK00OOOkkxdoooxOOKXKkolok00OxdxxkkkO00000OOOOOOOOO00KKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXKK0OOkxxdoolloxkkOKKOkkk0NNNKKK0OkxdddxxxdooodddddxOOOOO00KKKKXXXXXXXXNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKKKKKKKKXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0OkxdddoooooxxkKXXKKKKXNNNXK0OkkOO00O0Okxdlodx0KXK0OkkkkkkkO00KKKXXXXXXXXXXXXXXXXXXXXXXKKK0000000OOOOOkkkkxxxxkkO0XXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0Okkxxddddodxk0XKKKXXXNXNXKK0kxxxkkxddkO00KKXXNNWNXKKOdlloodxkkkk0KKXXXXXXXXXXXXXXXXK0Okxxxxxxddddddxxdoooooooodk0KXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0OOkkkkxxxddxkOO00KXXXXXXNXXXXXKK000KKKXXXXXXXNNNXKKX0ocdkkxdooxkkOKKXXXXXXXXXXXXK0Oxdoollllllloddolcloxxollllcok0XXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK00OOOOOkkxxdddxkO0XXXNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXNW0ldXKkdodxkxxk0KXXXXXXXXXXK0kdollcccccclol,......;lddcclloxOKXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK000000OOkkxdddddxOKXNNNXXXXXXXXXXXXXXXXXXXXXXXXXXXXNWXlc00dcokOK0kkkO0KKXXXKK0Okxdollcccccc:cc'....','..,l:,clodk0KX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0000000OOkkxxxxxk0K0kO0KXNXXXXXXXXXXXXXXXXXXXXXXXXXXXXNXl,dOoldOKXK0kkkxkkkOOOOOxdollcccccc::cllloolodddolodlcllldxO0X    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0OOOOOOkkkxxkkxxk0X0dlloddOKXXXXXXXXXXXXXXXXXXXXXXXXXXXXk,.oOxdOKKK0OOO0Oxdddddodoolcccccclolll:',,';c;,;:cloodddooxk0K    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXKK0OkkkxxxxxxddxkkkO00KOolool:cxKXXXXXXXXXXXXXXXXXXXXXXXXXKx;.;x0O0KXXXKKXXNN0xolc;:c:cccccccclc;'.......'''',,.';:ldxxxkOK    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXKK0OkxxdddddxkOO0KXKK0000Oxkkdoc:o0XXXXXXXXXXXXXXXXXXXXXXKOxc'.,lOKKXXXXXXXXXNNX0xlc;:lc::cccc;;,'....;cccooddodo:''';cdxdxO0    //
//    KNXXXXXXXXXXXXXXXXXXXXXKK0OkxxdddoodkKK0O0KKOdoodxxkxoloddxKXXXXXXXXXXXXXXXXXXXXXKkc,'',:x0KXXXXXXXXXXXXXXKxc::ccccccc;,'...';clxOO0KKKKKKkc,,;coddxO0    //
//    KNXXXXXXXXXXXXXXXXXXXXK0Okkxdddoodk0KNX0O0XX0OO0000kdoddxxOKXXNXXXXXXXXXXXXXXXXXXXKxc:;:lx0KXXXXXXXXXXXXXKK0kl:;ccccccc:;,:lolcdOO0XXXXXXXXOo:cloddxk0    //
//    KNXXXXXXXXXXXXXXXXXXXK0Okxxddddook0KXX0O000Oxk0KXXK0kkxdoloOXXXXXXXXXXXXXXXXXXXXXNNXK0kxdxk0KXXXXXXXXXXXXK0KKKkl:clclddlcloolldOKKKXXXXXXXX0dooooddxk0    //
//    KNXXXXXXXXXXXXXXXXXXK0Okxxddddddx0XXKOkkO000KKKXXXXXXXXKOxookKXXXXXXXXXXXXXXXXXXXXXXXXXXX0kkOKXXXXXXXXXXXK00000OkdlokkdoddoccdOKXKXXXXXXXNXkdooooddxkO    //
//    KNXXXXXXXXXXXXXXXXXXKOkxxddxxkxx0XX0kk0KKXXXXXXXXXXXXXXXXNXkox0XXXXXXXXXXXXXXXXXXXXXXXXXXX0ddkKXXXXXXXXXXXK0kdddxOO00xooxdcclkXXXKKXXXXNNX0doooooddxkO    //
//    KNXXXXXXXXXXXXXXXXXK0Okxddx00kxxOKKOOXXXXXXXXXXXXXXXXXXXXXK0dokKXXXXXXXXXXXXXXXXXXXXXXXXXNKdcoOXXXXXXXXXXXXKOxocco00xooxdooldKXKKK0KXNNNNKdllooooodxxk    //
//    KNXXXXXXXXXXXXXXXXXK0kxxddOKOxxxxOOOKXXXXXXXXXXXXXXXXXNKOkkkkxk0XXXXXXXXXXXXXXXXXXXXXXXXXNXd:oOKXXXXXXXXXXXXK0kdok0kxdxdlcloxOOxxxxOKKKXXxclloooooddxk    //
//    KNXXXXXXXXXXXXXXXXXK0kxddxO0kxxdxxxOXXXXXXXXXXXXXXXKK0K0dllllok0XXXXXXXXXXXXXXXXXXXXXXXXNXOlcdk0XXXXXXXXXXXXXKK00KKOkkxoccclllddolllloxkdllodoooooddxx    //
//    KNXXXXXXXXXXXXXXXXXK0kxddxOOkxdooddOXXXXXXXXXXXXXX0kdodxo:;,:d0KXXXXXXXXXXXXXXXXXXXXXXXXKOocclx0XXXXXXXXXXXXXXXXXXK0OOkdolc;,,;;;,..':ll,',cdxddoooddx    //
//    KNXXXXXXXXXXXXXXXXXK0kxdddkkkxdodddkKXXXXXXXXXXXX0kdooolc:;:o0XXXXXXXXXXXNXXXXXXXXXXKK0kolc;;okKXXXXXXXXXXXXXXXXXXXXXKOxlc:,..''.....''..,,,:ldxxdddxx    //
//    KNXXXXXXXXXXXXXXXXXK0OxxdddkkdllodddO0KXXXXXXXXKOdoddl::::;:xKXXXXXXXXXXXXXXXXKOxxxxl:;:;,',cdOKXXXXXXXXXXXXXXXXXXXXXXKkl;cl;''...''''';::c:;:ldxdddxk    //
//    KNXXXXXXXXXXXXXXXXXK0OkxddddkkkkkkxodxO00000000xl:cldlcl:...ckKXXXXXXXXXXXXXK0Od::cclccol:codkKXXXXXXXXXXXXXXXXXXXXXXXKkl:lxdxxllodddxkOdcc:,;loddxxkO    //
//    KNXXXXXXXXXXXXXXXXXXK0Okxdooddxk000koldOkdooolllcoxkOkoc:'..'cx0XXXXXXXXXX00OkxolodolllllodkOKXXXXXXXXXXXXXXXXXXXXXXXKOxl:okkKK0KKKKKKXOoc:;:loodxxkO0    //
//    KNXXXXXXXXXXXXXXXXXXXK0kxddooolox0OxooxOxl:ldoddoddolc;,,....'cxkO0KKK000Okxxddolc,....';cdOKXXXXXXXXXXXXXXXXXXXXK0Okxoc;:dk0XXXXXXXXXXklc::looodxkO00    //
//    KNXXXXXXXXXXXXXXXXXXXK0OxddoooodxOkdddxkkxxOO0kl:ldollllc;,,,,,:cldkOOkkxdooool;'......,cdOKXXXXXXXXXXXXXXXXXXXK0kdlcc:,.:k0KXXXXXXXXXKklcc;:lodxxkO0K    //
//    KNXXXXXXXXXXXXXXXXXXXKOkxddooooxk0kdxkOO0000K0l,:c:,'''''''.....',;codxkxoloooc;,'.'',:lxOKXXXXXXXXXXXXXXXXXXXKOxoc;',;''oKXKKXXXXXXXXKklc:;:oddxkO0KK    //
//    KNXXXXXXXXXXXXXXXXXK0OkxdddooooddxkkxO0OkkkOko:;;'',;;;;;;;,,,;,...,;:codooddxxoc;'',:loxOKXXXXXXXXXXXXXXXXXXK0xol:,',:,:kKX00KXXXXXXXOdcccclddxkOO0KK    //
//    KNXXXXXXXXXXXXXXKK0OkxxdddooooooodddllxOolool;,',:ldxkxdlc;;ll:,'...,;:loddooddollc;,,;cox0KXXXXXXXXXXXXXXXXK0kdllc;',;;:xKKkkO0KXXXNKxllloodxkO00KKKX    //
//    KNXXXXXXXXXXXXXK0OkxddoooodxxxddoodddokOdc:;,'';lxOKKXKOxoloxl'......';cllllloolcodc;,,;:ldk0KKXXXXXXXXXXXK0Okdocccccc:;:kK0xkOkO0KXNOolloodkO0KXXXXXX    //
//    KXXXXXXXXXXXXXK0OkxdolloddxkkOOkxxxxxxxdlc:;',:lx0KXXXXKOkkOx;.''....',clllclllcccccc:;;,;ldxxxkO0O000OOkkxdooollllllllclkOxoooox0KXKxlloodxOKXXXXXXXX    //
//    KXXXXXXXXXXXXXX0Oxdooolll::ccccccclllcccloolclldk0XXXXXX0OOkxl;;,...,,,;ccccc::cccll:;,,;codl::lodddoolccccllooolllllllccll:;,;coOKXkllloodk0KXXXXXXXX    //
//    KXXXXXXXXXXXXXX0Oxdlooc:::clllllccccclloddddkOdox0KXXXXXXK0OOOOOkdol;,,;:clcllccclolc:,,:odl;,,;:ccccccclodxxxddoollllllodxddol:cokxollloodkOKXXXXXXXX    //
//    KNXXXXXXXXXXXXK0Oxollc::clllllllllllloooodddxkOxdxO0KXXXXXXXKKXXXNXX0kxolloodxOkdddolcc:cloc:;:cclllodxkO00000OkxdoollloxOO00KOdlc:cllooddxkO0KXXXXXXX    //
//    KNXXXXXXXXXXXXK0kxollcccllllllloooddddxddxxxddxkxxkkkOKXXXXXXXXXXXXXNNXXOdolodxOOOkxooolc:::codxxkOO000KXXXXXXKKOkxdodxkOKKKKXK0ko::lodxddkO000KXXXXXX    //
//    KNXXXXXXXXXXXXKOkxooolllllloooddxkOOO000OOOkxdoooodxkO0XXXXXXXXXXXXXNXXXXKOxdooxkO0OdollllodxO0KKXXXXXXXXXXXXXXXKOkxx000KXXXXXXNXklclooooddkO0KKXXXXXX    //
//    KNXXXXXXXXXXXXKOkxddooooooodxkO00KKXXXXXXXK0Okxdoolldxk0XXXXXXXXXXXNNXXNXNXX0kxxxkOkdlooodxk0KXXXXXXXXXXXXXXXXXXK0OOOKXKXXXXXXXNXkoooooddxxkO0KXXXXXXX    //
//    KNXXXXXXXXXXXXK0OkxxdddddxkO0KKXXXXXXXXXXXXXK0kxxdoolllodk0XXXXXXXXXXXXXXNNNXKOkkkkdooodkkk0KXXXXXXXXXXXXXXXXXXXK0OkOKXXXXXXXXXXKkdddddxxxkO0KXXXXXXXX    //
//    KNXXXXXXXXXXXXK0OkxxdddxkO0KXXXXXXXXXXXXXXXXXKOkxxdooodxddxxO0KKXXXXXXXXXXXXXXXKKK0kdodddxOKXXXXXXXXXXXXXXXXXXXXKOkk0KXXXXXXXNXK0xddddxxxxO0KXXXXXXXXX    //
//    KNXXXXXXXXXXXXXK0OkxxxkO0KXXXXXXXXXXXXXXXXXXXXK0OOkxxxxxdolccldxkO0XXXXXXXXXXXXNNNXX0kdooxOKXXXXXXXXXXXXXXXXXXX0OkkOKXXXXXXXXXK0kdoodxxdxkO0KXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXK00OOO0KXXXXXXXXXXXXXXXXXXXXXXXXXKKK00kxolcllclccclxkO000KXXXXXXXXXNXXKOOkO0KKXXXXXXXXXXXXXXXK0kkkkk0XXXXXXNXX0xdoooxxddxO0KKXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0OkxdooolcccccldxOKKXXXXXXXXXXXXXKK00KKKKXXXXXXXKK00OkkkkkkOKXXXXXXXNKkoooodxdodkO0KXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0Oxdooooooc,,:lxkkO0KKXXXXXXXXXXXXKK00OOOOOOOkkxxddkOkO0KXXXXXKKXXOollllddooxO0KKXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0Okxddoll;...';:clodxk0KXXXXXXXXXXXXXKOxdddddooookOkOKXXNXXXXKO0OdlllloddllxO0KXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0kxdol::,.....';c::cok0XXXXXXXXXXXXNNX0dlllllllk000KXXXXXXXXXKkollllloddoodO0KXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0kxdl:,,,'.....',:clodO0KXXXXXXXXXXXXXKxllllldOK0Ok0KXXXXXXXXOdccllllooxkxxk0KXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0Okkxdc;,;;''....',;cddoxxk0KXXXXXXXXXKKOdlllldOKK0xldkO0KK00kxolccllloooxkkkO0KXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKK0Okxdddol:;;;,''..',;c:cooooodxk0KXXXXXXXKOdllllloxO00kOxooooollc::::::clloddxO000KXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK00OOOOOkkxdooooxd:,''''....',::cclllloodxk0KXXXXKOxollllcccloodkoc::::cccccccclooodxxkO0KKXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK00Okxxddddddddoooodkl,''''...';:cllccccccllolcoxOOOOkdlllllc:ccllccccc::cclddollllxkxkkOO00KKXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0Okxdooooddxdoooolllllddc,'''..'',:ccodlccccccccccllllllc;;colcccloooooooollllodlllodxk0000KKKKXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0kkxoc:;,,:okKXXXK00OOOkkxkdc;,'.',:::cccodlcccccccc::cllcllc,,:ooollodxkkOOOOkxxdxxddxkO0KKKXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX0kdlcl:,.....;x00OO00000KKK00Od:;;;;::::::::c:;;:::;;;;,',:x0KOo;;llloodxO0KKXXXXXK0OOOOO00KKXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOdl:;'........;ccoOK000Okdddoolc:::;,''''''''...........';lxKNNOololcldkOKXXXXXXXXXXKK000KXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOxo:'...........:xKO:':oxkkxoc::,'......................cx0KXNNKkolldxxO0XXXXXXXXXXXXKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0ko:,'..........;ll;;xXOo:,''''...'',,,'.......'''..';oOKXXX0kddddxxxk0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKOxoc;,''........'':kk:.....',:::;;;;:c::;'',;:c::cccldddol::cldxdxO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0kdlc:;;'.........,;''..';:ll:;,,,,;:loolc:clllllc:;;,,,;cclodxxO0KXXXXXXXXXXXXXKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0kdlllol:,''....',;;:::clllccclllccodxxxdoooooooollc:;cloodxkO0KXXXXXXXXXXXXXXK00KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0kdlcloolllllllodxxxxkkkOOOO000OOkkOOOOOOOOkkkxxxdoodxkkOO0KKXXXXXXXXXXXXXXXKK00KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0OkdddddxkOOO0000KKKXXXXXXXXXXXXXXXXXXXKKK0000000000KKXXXXXXXXXXXXXXXXXXXXXXKKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    0XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK000KKKKKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKXXXXXXXXXXXXXXXXXXXXXXXXXXXX    //
//    OKKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKKKKXXXXXXXXXXXXXXXXXXXXXXXX    //
//    xO0KXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXKK0000000KKKKKXXXXXXXXXXXXXX    //
//    dkO0KKXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXK0OOOOOOOO000KKKKKKKKKKKKKK    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract F22 is ERC1155Creator {
    constructor() ERC1155Creator("Fimmina", "F22") {}
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