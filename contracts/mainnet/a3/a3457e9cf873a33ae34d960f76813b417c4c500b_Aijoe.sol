// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: A.I.Joe
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    AiJoeMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:;;;;;;;;;;;;;;;;;;;,;:::ccloodddooollcc:::,'    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:;;;;;;;;;;;;;;;;;;::cclooddddddoollc:::,''    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o:;;;;;;;;;;;,;;::ccloodddxxddoolcc::;,'',    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOl;;;;;;;;;,;::clloddxxxxxddoolcc::;,'',,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo:;;;;,;;::ccloddxxxxxxddollc:::;,,',,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXKXWMMMXd:;,,;;:cclodxxkkkkxxdoolcc::;;co;',,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdlcokKWMMMMKl,,;::clodxxkkkkkxxdolcc:::;:d0d,,,,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dc,''ckNMMMMMMNk:;::cclodxkkkkkkxdollc:::;;lONO:,,,,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0o;''',oXMMMMMMMKo:;::cllodxkkkkxxddolc::::;:xXWXo,,,,,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;'''';xNMMMMMMW0l;::ccloodxxkkxxddollcc::;:oKWMWx;,,,,,,    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNWWMMMMMMMMMMMMMMMMMMMMMMMMNKk:,,,,,;dNMMMMMMWOc;::cclooddxxxxddolcc:::;;l0WMMW0:',,,,''    //
//    MMMMMMMMMMMMMMMMMMMMMMWNKOkxddoooodxkKNWMMMMMMMMMMMMMMMMMWKo;,',,,,,oXMMMMMMWOc;::cclooddddddoollc:::;,,lKMMMMXo,',,,,,;    //
//    MMMMMMMMMMMMMMMMMMMWXOxlccloooollc::;:ld0NMMMMMMMMMMMMMMW0c,'',,,,':0WMMMMMW0c;::ccloodddoooolcc:::;;,;;c0MMMNx;'',,,';x    //
//    MMMMMMMMMMMMMMMMMNOdc::cloddxxxdddolcc:;:lkXWMMMMMMMMMMMKl,',,,,,,,dNMMMMMMKl;::cclodddoollccc::;;,;;;;;:kWMXd;''',,,;xN    //
//    MMMMMMMMMMMMMMWXOo:;:::cloodxxxxxxxxdolc:;;ckNMMMMMMMMMWk;',,,,,,':OWMMMMMNd;:::cloooollccc:::;;;;;;;;;;;xN0l,''''',:kNW    //
//    MMMMMMMMMMMMMNkl;;;;:::::ccloddxxxxxxxdolc:;:oKWMMMMMMMNo,',,,,,,,lXMMMMMWk:;::clooolcc::::;;;;;::::::;;;od;'..''',c0NXk    //
//    MMMMMMMMMMMW0l,'';lk00OOkdlccloodxxxxxxxdolc:;ckNMMMMMMNo',,,,,,,,dWMMMMMXo;::cllollc:::;;;;;;:::clllc:;,''......,dXXkc,    //
//    MMMMMMMMMMNk;..,l0NMMMMMMWN0xlccloddxxxxxxdlc:;:dKWMMMMNd,,,,,,,,,xWMMMMWk:::cclllcc::::;;;;:::clodddlc;,'.....'cON0o;,,    //
//    MMMMMMMMMNx,..:kNMMMMMMMMMMMWKxl:clodxxxxxxdol:;;c0WMMMWk;',,,,,,,xWMMMMNd;::cclcc::lx0x:;;;:::codkkxoc;'....':xXKx:,,,,    //
//    MMMMMMMMWx,..c0WMMMMMMMMMMMMMMWKd::clddxxxxxxdl::;cOWMMMXl,,,,,,,,dNMMMMKl;:::c:::cxXWWx;;;;:::coxkkdl:,'..':xKXkc,,,,,,    //
//    MMMMMMMM0;..:0MMMMMMMMMMMMMMMMMMNOl:cloddxxxxxol:;;c0WMMWO:',,,,,,oXMMMM0c;::::::o0WMMKl;;;;:::ldxkxoc;'',lkXXkc,,,,,,,,    //
//    MMMMMMMNd'.:OWMMMMMMMMMMMMMMMMMMMWKd::cloddxxxdoc:;;l0WMMWk:'',,,'c0MMMMO:;:::;cxNMMNOc;;;;:::cldxxdl:,;o0NXkc,,,,,,,,,,    //
//    MMMMMMMK:.,kWMMMMMMMMMMMMMMMMMMMMMMNkc::loddddddlc:;;lKMMMWkc;,,,,;OWMMWk;;::;cOWMWKo,,;;;:;::loddol::dKNKd:,,,,,,,,,,,,    //
//    MMMMMMWk,'oNMMMMMMMMMMMMMMMMMMMMMMMMWOl::cooddddolc:;;dNMMMX0o,,,,,xWMMWx;;:;cOWMNx:',;;:::::coddol:;dKOo:,,,,,,,,,,,',,    //
//    MMMMMMWk,;OMMMMMMMMMMMMMMMMMMMMMMMMMMWKo::cloodddoc:;;cOWMMMW0:',,,dNMMWd,;:;dNWKl'',;;:::::clddol:;:oc,,,,,,,,,,,,,,:ox    //
//    MMMMMMWk,lXMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd::clloddolc:;;dNMMMMXo,,,,oXMMNo,;;:OWO:''';;:::::clodol:,',,,,,,,,,',',;cxOXWM    //
//    MMMMMMMk;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx:::clooolc::;c0MMMMWx,,,'lKMMKc,;,c0O:''';;;::::cooooc:,'',,,,'''',',cd0NWMMMM    //
//    MMMMMMMOckMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:;:cclolc::;:kWMMMWk;,,':0MWk;,,,oOl'',;;;:::clooolc;,'''''''''',:dOXWMMMMMMM    //
//    MMMMMMM0lOMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd:::ccllcc:;;dNMMMWk;',';kWXl',,,lo,',;;::::cloooc:;,'''''''',:oOXWMMMMMMMMMM    //
//    MMMMMMMKlkWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd:::cclcc:;;lKMMMWd,,,';kNx;'''','',;::::clloolc;,,''''''';lOXWMMMMMMMMMMMMM    //
//    MMMMMMMKloXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKo;::cccc::;c0MMMXo'''':OO:''''.',;;:::clllllc;,''''''.':dKWMMMMMMMMMMMMMMMM    //
//    MMMMMMMXl,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc;::ccc::;:OWMWO:'''':dc'''.'';;:::cclllc:;,'......':dXWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMXl',dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;:::c:::;:kWXOl''''',,''.'',;:::::cccc:;''.......;dXWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMNo'',xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:;:::::;;;kXd;,.''..''.',;;:::::::::;,''.......,lKWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMWk,''oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0c;;:::;;;;ll,........',;:ccc:::;;;;,'........'cONMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMXo,,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo;::;:;;;,'.......'',;cclllc::;;;,'.........;xXMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMKl:kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo;;::;;;;,'.....',;:ccllllc::;;,'.......'''':dxxxkkO0KXNWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKl;;:::;;;,..''',;:cclllcc::;;,''''',,,,;;;;;;;;;;;;;::clodkOKNWMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:;;:::;;;,',,;;::clllcc::;;;,,,;;;;:::::ccccccccccccc:::;;;;:ldOXWMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl;;;;;;;;;;;;:::ccllcc:::;;;;;;::::::ccccllllllllllllllccc::::;;;cdONWMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdc;;;;;;;;;;;;:::ccccc:::::;;;:::::cccccccccccccccccccccccccccccc::;;;lONMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l;,;;;;;;;;;;;;:::cccc:::::::;;:::::ccccccc:::::::::::::::::::ccclllcc:;;;oKWM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc,,;;;;;;;;;;;:::cccc::::::::;;:::::::::::::;;;;;::ccccc:;;;;:::::clllllc:;;l0W    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:,,,;;;;;;;;::::::::::::::::::::::;;;;;;;;;;:coxk0KXXNNXXK0kdc:;;:::cclooolc:;oX    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo,,;;;;;;;;;;;::::::::::::::::::::;;;;;;;;;:o0XWMMMMMMMMMMMMMWN0dc;;:::clooolc::k    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNkc;;;;;;;;;;;;;;;;::::::::::::::::;;;;;;;;;lONMMMMMMMMMMMMMMMMMMMWKd:;;::clloolc:c    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWW0o;,,,,;;;;;;;;;;;;;;;;::::::::::::;;;,,''',lKWMMMMMMMMMMMMMMMMMMMMMMWOl;;;:clloolc:    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMWX0kxdddol:,,,,;;;;;;;;;;,,,,;;;;;;;;;;;;;;;::;,''...'kWMMMMMMMMMMMMMMMMMMMMMMMMMKl;;;:cllool:    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMXkl:;;;;;;:::::::::::::::::;;;;,,,,,,;;;;;;;;:;'..    '0MMMMMMMMMMMMMMMMMMMMMMMMMMWKl;;;:cclllc    //
//    MMMMMMMMMMMMMMMMMMMMMMMNOl;;;;::::::::::::::::::::::::::::;;;,,,,,;;;;,''.    .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:;;::ccccc    //
//    MMMMMMMMMMMMMMMMMMMMMWKd:;;:;::::::::::cccccccclccccccc::::::::;;,,,;;,...   'dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo;;;::::::    //
//    MMMMMMMMMMMMMMMMMMMMNkc;;;;;::::::::ccccllllooodooolllllccc:::::::;,,,,,'.':xXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:;;;:::::    //
//    MMMMMMMMMMMMMMMMMMWKo;;;;;:::::::::cclllooodxxkkxxdddooolllccc::::::;,,,,:xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0c,;;:::::    //
//    MMMMMMMMMMMMMMMMMNkc;;;;;:::::::ccclllooddxkkOkkkxxxxdddooolllcc::::::;,,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl,;;:::::    //
//    MMMMMMMMMMMMMMMMXd:;;;;;::::::ccccllloodxkkkkkxxxxxxxdddddoolllcc::::::;;:kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd,;;:::::    //
//    MMMMMMMMMMMMMMMKo;;;;;;;:::::ccclllloddxkkkkxxdddddddddddooolllcc::::::::;;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd;;;::::;    //
//    MMMMMMMMMMMMMW0l;;;;;;;;::::cccllloodxkkkkkxxxddddddddddooolllccc:::::::::;;dXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd;;;:::::    //
//    MMMMMMMMMMMMW0c;;;;;;;;:::::ccllloodxkkkkxxxxxxddddddoooolllcccc:::::::::::;;xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd;;;::::l    //
//    MMMMMMMMMMMMKc,;;;;;;;;:::::cclllodxkkkxxxxxxxxxdddddoolllcccc::::::::::::;:;c0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo;;;;:::k    //
//    MMMMMMMMMMMKl,;;;;;;;;::::::clloodxkkxxxxxxxxxxxdddooollccc::::::::::::;;;;;,:OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0c;;;;:;oK    //
//    MMMMMMMMMMNd;;;;;;;;;;;::::ccloodxkkkxxxxxxxxxddddoollccc:::::::::::;;;;;;;,;dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;;;;;;cOW    //
//    MMMMMMMMMWO:,;;;;;;;;:::::ccllodxkkkxxxxxxxxddddooollcc:::::::::;;;;;;;;,,;o0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0c,;;;;:xNM    //
//    MMMMMMMMMKl,;;;;;;;;;:::::cllodxkkxxxxxxxxdddddoollccc::::::::;;;;;;;,,,cxKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo,;;;;:dXMM    //
//    MMMMMMMMWx;;;;;;;;;;;::::ccloodxxxxxxxxxddddddoollcc:::::::;;;;;;;;,,;lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;,;;;:dXMMM    //
//    MMMMMMMMNo,;;;;;;;;:::::ccllodxxxxxxxxxddddddoollcc::::::;;;;;;;;,,;l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc,;;;:oKMMMM    //
//    MMMMMMMMKl,;;;;;;;::::::ccloodxxxddddddddddooollccc:::::;;;;;;;,,,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl,;;;:dXWMMMM    //
//    MMMMMMMMO:,;;;;;;;;::::ccloodxxxxxxddddddooolllccc::::;;;;;;;;,,ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd;;;;:xXMMMMMM    //
//    MMMMMMMMk;;;;;;;;;;::::cloodxxxxxxxxddddooollccc::::;;;;;;;,,,;oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx:,;;ckNMMMMMMM    //
//    MMMMMMMWx;;;;;;;;;;:::ccloddxxxxxxxxdddoolllccc::::;;;;;;,,,,cOWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO:,,;cOWMMMMMMMM    //
//    MMMMMMMNd,;;;;;;;;;:::clooddxxxxxxxxdddoolccc:::::;;;;;;,,;dOXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc,,;oKWMMMMMMMMM    //
//    MMMMMMMNd,;;;;;;;;:::cclooddxxxxxxxdddoollcc::::;;;;;;;,,;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOc,,:xXMMMMMMMMMMM    //
//    MMMMMMMWx,;;;;;;;;:::cclooddxxddddddddollcc::::;;;;;;;,,;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:,,cONMMMMMMMMMMMM    //
//    MMMMMMMWk;,;;;;;;;:::ccloodddddddddddoollc::::;;;;;;;,,;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk:,;oKWMMMMMMMMMMMMM    //
//    MMMMMMMM0:,;;;;;;;:::ccloodddddddddooollcc:::;;;;;;;,,;kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd;,:kNMMMMMMMMMMMMMMM    //
//    MMMMMMMMXo,;;;;;;;:::ccloooddddooooooolcc::::;;;;;;,,;xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOc,,l0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMWO:,;;;;;;:::cclloodddddddooollcc:::;;;;;;;,,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOo;,,c0WMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMNo,;;;;;;;:::cclooddddddddoollcc::;;;;;;;,,oXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl:;,,:OWMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMM0c,;;;;;;:::cclloddddddddoollcc::;;;;;;;,lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkoc;;;;,;dNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMNd;;;;;;;;:::cclooddddddooollcc::;;;;;;,:OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkoc:;:;;;;;:OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMKl,;;;;;;;:::ccllooooooooollcc::;;;;;,;dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xo:;:::::::;;;c0MMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMWO:;;;;;;;::::cclllooooooollcc::;;;;;,lKMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl:;:ccccccc:::;;:OWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNx;;;;;;;;::::cclloooddooolcc::;;;;,;xWMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:;::clloollcc:::;;;xWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMXd;;;;;;;:::::cclooddddoolcc::;;;;,:0MMMMMMMMMMMMMMMMMMMMMMMMMW0o:;::cloooollc::::;;;;dNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXo;;;;;;;:::::clloddddoolcc::;;;,';OMMMMMMMMMMMMMMMMMMMMMMMWKd:;::clooooolcc:::::;;;;oXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMKl;;;;;;;;:::ccllooooollcc:;;;;,',xWMMMMMMMMMMMMMMMMMMMMMNkc;::clloooollc:::::::;;;,oXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMM0l;;;;;;;::::cclllllllcc::;;;;'',oXMMMMMMMMMMMMMMMMMMMWKo:;:cclooooollc::::::::;;;,oXMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMW0c,;;;;;;::::ccccccccc:::;;;,'',;dNMMMMMMMMMMMMMMMMMMKl;:cclloodoolcc::::::::;;;;,oNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMW0c,;;;;;;::::::cccc:::::;;;,'',,;dXMMMMMMMMMMMMMMMMKl;:clloodddolcc:::::::::;;;,,xWMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMWO:,;;;;;;:::::::::::::;;;;,',,;;;oKWMMMMMMMMMMMMMNd;:clooodddollc::::::::::;;;,;OMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMWO:,;;;;;;;:::::::::::;;;;,',,;;;;cONMMMMMMMMMMMWO:;cloooddxdolc::::::::::::;;'cXMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMWOc,;;;;;;;:::::::::::;;;,',,;;;:;:dKWMMMMMMMMMNo;:cloodxxdolc::::::::::::;;,,xWMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMW0l,;;;;;;;::::::::::;;;,',,;;:::;;ckNMMMMMMMM0c;cloooxkdolc:::::::::::::;,,oXMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMO:',;;;;;;::::::::;;;;,',,;;:::::;;oXWMMMMMWO::clooxkxdlc:::::::::::::;,,lKMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMXl',,;;;;;;;:::::::;;;;,',;;::::::;;xNWMMMMWk::llodxkdolc::::::::::::;,,lXMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWk;,,,;;;;;;;::::::;;;;,',;;::::::;:kNWMMMMWk::loodxxdolc::::::::::;;',dNMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMKc,,,,,;;;;;;;::::;;;;,',;;;;::::;lKWMMMMMWO::clodddolc::::::::::;,'cOWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMWx;,;;,,;;;;;;;;:;;;;;;,,;;;;;;;;c0WMMMMMMM0c:cloooollc:::::::;;,':xXMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMKc,;;;,,;;;;;;;;;;;;;;,',,;;;;;cOWMMMMMMMMKl:clllllcc:::::;;,,,ckXWMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMWk;,;:;;,,;;;;;;;;;;;;;,,,,,;,c0WMMMMMMMMMXo;cccccc::::;;,,;lxKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMNx;;;:;;,,;;;;;;;;;;;;,,,,,,;kWMMMMMMMMMMWx::::::::;,,;cokKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMNOc,;:;;,,,;;;;;;;;;;,,,,,,oXMMMMMMMMMMMMKl;;;;,;;cokKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd:;;;;;,,,,;;;;;;;;,',,:OWMMMMMMMMMMMMWKkxxxk0XNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKkl:,,,,,,,,;;;;;;,'',lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOxoc:,,,,,;;;;,,',dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOxo:;,;;;,,''dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKkdc;,,,,dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKx:'',xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Aijoe is ERC721Creator {
    constructor() ERC721Creator("A.I.Joe", "Aijoe") {}
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