// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Mignonverse Assets
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                               //
//                                                                                                                                               //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNK0kxooooodddxk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWN0kxolc:;;;;;;;;;,''';lkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0kdl::cloooddoooodddoolc;,.,dXMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKOxoccllllloddol:,,:odxxdddxddl,'oOOkkkkOOOO0KXWMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0dlccloodddodddxxl'   'clldxxdlc::;;ldxOOO00OOkxxxkOO0NWMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOoccoooc:ldxxdddxxdl;',;,...;lccccldoloxddodk0000OkddxkxxkKWMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0oclooc;'...lxxxdxdoodkxdo;..,;coxxxxkdll:....;d00x:'...:k0kdOWMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKdcclloo;.....cddddoldkkdoccllodolodxxxxxo;......l00c......okdllOWMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXd:::clooc::cllooollloxxoc:cloxxxc...;oxxdol;....'ck0xl;'.'';:...,lOWMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc;;...:oc:;,;cdolcclool::cldol:cc'  ..lxdc;lxdlodkkdodO0Okkd:,..'lxo0MMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc:l:'',:ll;...colloolc:::ldo:.....,;;codl::oxkkkkdlodxkkkkxdl::::cdOddXMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXd:colcolcclccclllloooc::lodxx:. ....;cclc::oxddxxdodxOOOkdloxO0kdllodOko0MMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWk:colcllcllldolllddoc;;coxxdoo:,,'',c;...':odddolldkOOOkdoodk0Oxoooodddoo0MMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKlcolclllloddoloddoc:'.'lddxdl:cdxxxdl'...'lxxdlodkkkxolldxdodo,....:oddclKMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMWNX0Oxdoooooodk0XWMMMMMNkccc:;;::col:llc:;;;'....:xkolldoooo::c:;cdddooxkkkdooodxxxdd:.  ....cddcdNMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMN0kdl:,.          ..;dO0kddl;,,,,',,;;,',,'....'.....:oc:looooolokxlodoodxkOkdlldkkkkxxxkc.  ...'ldooKMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMWXxlldxO0K0o.     .',,;,''',,''',;cooodollooooc;''',,;::;,,;:::;,,;odxxdlldkkkxooodxdxkkOkxddlc:;;:codoo0WMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMW0l''dXWMMMWNx. .';;::;,,,,,;;:c:coxkkkOkxxxxxxd:'';;,:loc;:odo:,',;::c:;,,coollooxxdoloxkkdooxkOOkxxxoloKWMMMMMMMMW    //
//    // MMMMMMMMMMMMMMWOc.  cXWWX0xc,.,:::c::cc:::;;;:cloxkkOOOkxkkxoddc,;:;;:c:::lxkd:;:lxxolc:;,;;,,,;cddodooollloxOOkkkxdoc:dXMMMMMMMMMMW    //
//    // MMMMMMMMMMMMMWx.  ..':c;'. .:c:;:cllccc::::;;:coxxddxxxddxdooo:',;,:l:;:ldkko;';odolcllc:;;;;,',colc:;;:cloxkOOOOkxo::xNMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMWOc;,''...    ',',cllc::::::;,,;codddddxddxddddo:',;;cc;;clolc:;,',c:,:ooc:::::;'':dolllcc:,'';dkkkkkd:l0WMMMMMMMMMMMMM    //
//    // MMMMMMMMMMWXkc'.               ..,;;::;;;;,,:loooddxddkkxxxd:.'',:;,',ll:;;:clcc:..;lc:c::c:clllllooooo,. ..;dxxdcckNMMMMMMMMMMMMMMM    //
//    // MMMMMMMMWKl'    .;cooc'           ..;::;,,,;ldxxkOO00KKKOOKk;',,'.....,;;:lodoccc::cc:ccc:cloolloodollc,...',clclxXMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMXo.   .cOXWMMMMXx,           .,c:;,;cdOKKKKXXXXXXKK0c'','.'','';ccccoolllll:colllc:clododolllllddoooc''',dNWMMMMMMMMMMMMMMMMM    //
//    // MMMMMM0;   .cKWMMMMMMMMM0'           .,;;:lddk0KK00XXXXXXKd,.''';c;,,:cc:ccccclccllodol:;coollll:::,;oxolo:;:oo:;dXMMMMMMMMMMMMMMMMM    //
//    // MMMMM0;   .dNMMMMMMMMMMMX:             ':lkkxxOKKKKXXX00XKd,..',;;,;c::ccc:::loooooo:,;;;clcclcc:c;.'clc:::okOkd::kWMMMMMMMMMMMMMMMM    //
//    // MMMMNc    oWMMMMMMMMMMMM0'             .;xOkxkO0KKXXXXKKXOdc',,';::::::::::colldoooc,..':llcclloddoc:;;codxkOOxxd:c0WMMMMMMMMMMMMMMM    //
//    // MMMMk.   .OMMMMMMMMMMMW0;               'odoook00KXXXXXXXOo:;c:;:,',;,',;cclolcol;;::;;;::'..:dxdc:cookK0OOkkkOOxl;dNMMMMMMMMMMMMMMM    //
//    // MMMWd    .lNMMMMMMMMWKo.                .cdoook0KKXXXXXX0xl;;::lolc:,'';clcclc:clccc:;;::;;;:::llldKXXKXK0K0xdkOkdcoXMMMMMMMMMMMMMMM    //
//    // MMMWo      ,oOKNNX0x:.                  .lxkxdOKKK0000XXKxc,,:ldxxxdllc:c:,;cccc:::::::cooldxdx0K0KXXXXXXXXX0kxxkxcl0WMMMMMMMMMMMMMM    //
//    // MMMMx.        .....                     ,xOkdx00OOOkxxOOOo,,;:ldddxddxdl:,,;;:lc:c:'..,lddk0XXXXXXXK00000KK000xddo::OWMMMMMMMMMMMMMM    //
//    // MMMMK;                                 .cOkxddxkOOOxdllcol;:lccoodxxxxdxdlc:;:c:;;;,,;ckOOKKKXXX0OOOxkOkxkkddkOxooccOWMMMMMMMMMMMMMM    //
//    // MMMMWk.                   .:xxc.       ,x0OOkxkO00Oxddool::clcldddxdddoxxddl:::cc:cdoclk0xxxxO0OxkO000K0000OkOkkdlccOWMMMMMMMMMMMMMM    //
//    // MMMMMWx.                 .xWMMWk.     .lO0OO0OOOOOOkxkkxxoccodxxxkOkxdodxodxxxxdddxkoldxddkkxkxdk0000KK00KKKKKOkdcclOWMMMMMMMMMMMMMM    //
//    // MMMMMMWO,                .xNMMNx.    .;d00OOOOxxOkkkxkOxxxlloxkkO00OOkddddxxxkkxdxxxdxOkdxO000OkO00Ok0KOkKK000Oko::o0WMMMMMMMMMMMMMM    //
//    // MMMMMMMMXd'               .,::,.   .;oloO0kOOOOOOOOOOOOkkxldxxOOO0OkxxddddxxkkxxxxdddxOkxk00000000KOO0KKKK0kO0kxo:lONMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMXx:.                   .;lodooOK000000000000000kodddkOO0KOkkddxxkxxkxxxxdolldkOOOkk0OOO000KKKKKKK0000d::kNMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMWKkl;'.          ...;lodoc:ckKKKKKK0KKKOk0K00kdxOkkOO00OOkddkxkxkxolccc:;,;lxkOxk0kxk0Ok0KKK0KK0kOOl;oXMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMWNKOo;'..'',;:;;coldl;,;oO00K0OOKKKK0KKOkxoxOxdddxkkkkddxxkkxxl,'''',;;coxOOO0Oxk0OO0KKOk00Oxxo;lKWMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMWO:.,:c::c:;:;;cc;;;cxkOKK00KKKKKK0kdoccloxxoodooddoddxxddl;',,,;::ldkOOOOOOO00000KK0000klcdKWMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMNd'.,::;::cc:::c:::cokOKKK00KKKK00Oxo:'',lxoloodxdodooocc:::::;:clodxkkO0K0KKK0kOKXK000ocdKMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMXo,';:;:cclllllccc:ldkO00OO0000OOkdxo;,'':lloolddl::cclolllll:::cddxOOdd0XKKXX0OKXKOxl;dXMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMKo:,,;;cclllolc::;:ldk00OkOKKOkOOodxlc;;:llclloocllododoccloc:c:lllol:;xX0OKXKKKKKOc;oKWMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMNkc;,;::::;,,;;;,':oxkkkk0XKOkkkdkkc:::cooloooolodxxdooloooc:c::::ll:;kXXXKKXXKkdc;l0WMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMWKxl:;:c;',lool:'.;oxkO0OKX00kxOK0l;:::cc::;;;;cxxxoclooool;,;:ccll:,o0XXK0KX0l':kXWMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMWKl'',.':lllc'.':dk0XXKKXXK0O0K0d:c:,;:::c:'';dkxdllllddl:'.;cccl:,ckKXK0kxl''xWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMKd:',clll;.';:;cx0XXXXXXXXXXX0kol;'coooo;',:dkdolloloolc;'',:lc:';kKX0dc,.',kMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO;':cl:,.,::::;:ok0KXK0KXXXXX0dc,,loooc'':cdkxddoddlllc:;,'':lc,,ok0d,..,;;kMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:,clc:,',;c;;::;,:okKKKXXXX00Od:',llol,.;ccclolooodoool:::c;';l;.:c;;ll;:c;dWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMKc,cc:oOK0Okdl,.,;,',cxO0K00XXK0Ol',lll;.,ccc::llldoodlcllcccc,.,,..;oONWKl;,cXMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMNo';:cxNMMMMWNO;......,:oxOO00KK00d''c:;'':llcc::cccllll::c:;;,'''...cXMMMMXl.'kWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMWk;,;lKMMMMMMMMk,,;'.,ll::clddxxdkOo'':,.';:ll::c;:c;:c:,,;;,:oookOo'.:XMMMMM0;.oWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMK:';xNMMMMMMMMWd,:;'lKWX0Okxddocclo:.';'.';,::.....',:::lokOOKNWMMMWk';KMMMMMW0okWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMNl.:0WMMMMMMMMMNl'',xNMMMMMMWNNXXK00x,.,cdk0O00kc.'';OXKXNWWMMMMMMMMMWOkNMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMWx,lXMMMMMMMMMMMK;.,kWMMMMMMMMMMMMMMMXc.;0WMMMMMMXo',dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMWOkNMMMMMMMMMMMM0,,OWMMMMMMMMMMMMMMMMWx'cXMMMMMMMMXl'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxOWMMMMMMMMMMMMMMMMMMNxkWMMMMMMMMMXdkWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    // MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                               //
//                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MGV is ERC1155Creator {
    constructor() ERC1155Creator("Mignonverse Assets", "MGV") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x6bf5ed59dE0E19999d264746843FF931c0133090;
        Address.functionDelegateCall(
            0x6bf5ed59dE0E19999d264746843FF931c0133090,
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