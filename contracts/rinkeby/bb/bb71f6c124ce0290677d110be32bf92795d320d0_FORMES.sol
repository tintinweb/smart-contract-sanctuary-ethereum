// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Formes by kipz
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMNKKKKKKKKXWMMNKO0NMMMWKO0NMMMWXOOXWMN0OOOOOOOOOOOOOOOOOOOOO0NMMNK0000000KWMMXOOOOOOOOOXMMMWNNNNNNWWMMXKNMMWNWMMMMMM    //
//    MMMMM0lcccccccdXMNd'..oNMWk,..cXMMO;..:0M0;.....................'kMM0:,,,,,,,lXMWd.........xMMWXKKKKKKXWMWx:OMMNKKNMMMMM    //
//    MMMMM0lcccccccdXMWk;',xXXNO:',oKXN0c',lKM0;.....................cKMMXd;,,,,,,lXMWo......'ckXMMMWXKKKKKKWMWx:OMMNKKNMMMMM    //
//    MMMMM0lcccccccdXMMNkoxXKxKNOodKXxON0od0WMK;...................:kNMMMMN0o;,,,,lXMWo.....,kWMWXKNMMWXKKKKWMWx:OMMNKKNWMMMM    //
//    MMMMM0lcccccccdXMNo...oNWWx'..cKWWO,..;0MW0l'..............:okNWXNMMXKNN0o;,,lXMWo.....oWMNklcdXMMNKKKXWMWx:OMMNKKNWMMMM    //
//    MMMMM0lcccccccdXMWk:,:kXKN0c,;dKKXKl;;lKMWNN0l'..........:kNWWKdlOMMKooONN0o;lXMWo.....cXMW0xdONMWNKKKKWMWx:OMMNKKNMMMMM    //
//    MMMMM0lcccccccdXMMXxoxXKxKNkodKXxONOoo0WMKdxXN0l'......:kNWKOd:,:OMMKoccoONN0ONMWo......lKWMWWMWWNKKKKKWMWx:OMMNKKNMMMMM    //
//    MMMMM0lcccccccdXMNo...lNMWx...:KMWO,..,OMKc,cxXN0l'..:kNWKd:,,,,:OMWKoccccdONWMMWo.......'l0MMWXXKKKKKKWMWx:OMMNKKXMMMMM    //
//    MMMMM0lcccccokXWMWOc;ckX0X0l;:xK0KKo::oXMKc,,,cxXNOdkNWKd:,,,,,,:OMMKocccccco0WMWo.........xMMWXKKKKKKKWMWx:OMMNKKNMMMMM    //
//    MMMMM0lcccokXWWWMMXxoxXKxKNkod0XxONOooOWMKc,,,,,cxXWMNk:,,,,,,,,:OMMKocccccccdXMWo.........xMMWKKKKKKKXWMWx:OMMNKKXWMMMM    //
//    MMMMW0lcokXWNOxXMNl...lNMWd...:KMMk'..,OMKc,,,,,,,cxXN0d:,,,,,,,:OWMN0OOOOOOOKWMW0dddddddddKMMWNXNNNNNNWMMKkXMMWNNWMMMMM    //
//    MMMMM0okXWNOl,lKMWOl:lOK0XKo:ckK0KKdccdXMKc,,,,,,,,,cxXWKd:,,,,;oKMMWWWWWWWMMMMMMMMMWWWWMMMMMMMMWWWWMWWWMMWWWMWWMMMMMMMM    //
//    MMMMMNXWNOl;,,lKMMKdldKKxKXxlo0Kk0XkooONMKc,,,,,,,,,,,cxXN0dc:lONWXKKKKKKKKNMMMMMWKkxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxKWMMMM    //
//    MMMMMMNOl;,,,,lKMNl...cNMWd...:KMMk'..,OMKc,,,,,,,,,,,,,cxXNNXNWX0O00000000XMMN0KWWKxlccccccccccccccccccccccccccccOWMMMM    //
//    MMMMMKl;,,,,,,lKMW0ocl0WMMKdclkWMMXxccxNMNkdxxdl,,,,,,,,;l0WMWX0O0000000000XMMKl:xXWWKxlccccccccccccccccccccccccoONMMMMM    //
//    MMMMMO;,,,,,,,lKMMMWWWWWWWWWWWWWWWWWWWWWWWWWWMWk;,,,,,;lONWXK0O00000O00000KXMMKl,,:xXWWKxlccccccccccccccccccccoONWMMMMMM    //
//    MMMMMk;,,,,,,,lKMW0xxxxxxxxxxxxxxdxxxxxxxxxkXMWk;,,,;lONWX0OO000000000O0000XMMKl,,,,:xKWNKxlccccccccccccccccoONWNO0WMMMM    //
//    MMMMMO;,,,,,,,lKMWkccccccccccccccccccccccccoKWWk;,;lONWX0000O000KNNNNXK00O0XMMKl,,,,,,:xKWWKxlccccccccccccoONWNOl;xWMMMM    //
//    MMMMMO;,,,,,,,lKMWkccccccccccccccccccccccccoKMMk;lONWX0O000OO0KNNkllkNNK000XMMKl,,,,,,,,:xXWNKxlccccccccoONWNOl;,,xWMMMM    //
//    MMMMMO;,,,,,,,lKMWkccccccccccccccccccccccccoKMMKONWX0O00000OO0NW0;..:KWX000XMMKl,,,,,,,,,,:xKWNKxlccccoONWNOl;,,,,xWMMMM    //
//    MMMMMO;,,,,,,,lKMWXK00000000000000000000000KNMMMWX0O00000000O0KNW0xxKWNK000XMMKl,,,,,,,,,,,,:xXWWKOkO0NWWKo;,,,,,,xWMMMM    //
//    MMMMMO::llolc;lKMMWNNNNNNNWMMWNNNNNNNNNNNNNNWMMNKO000KKKK000O000KXXXXX00000XMMKl,,,,,,,,,,,:oOXMMMMMWMMMWN0ko:,,,,xWMMMM    //
//    MMMMMX0XNWWWNKKNMWx;;;;;,c0MMKoccccccccccccoKMWX000KNWXXNNXK000O0000O000000XMMKl,,,,,,,,,cxXWMNKkdlcclldkKWMWKd:,,xWMMMM    //
//    MMMMMMMNK0O0KNMMMWo......,OMWO:,,,,,,,,,,,,c0MWX00XWXdc:lOWNXK0000000000000XMMKl,,,,,,,;oKWWXd:'.........'ckNMW0l;xWMMMM    //
//    MMMMMN0olcccldKWMNo......,OMMO:,,,,,,,,,,,,c0MWX00XM0:,,,oXNXK00O0000000000XMMKl,,,,,,;xNMNk;...............:OWMXoxWMMMM    //
//    MMMMM0lcccccccdXMWo......,OMWO:,,,,,,,,,,,,c0MMX00KNN0xdkXWNK0OO0XXXXXK0000XWMKl,,,,,,oXMWx'.................,OWMKKWMMMM    //
//    MMMMW0lcccccccdXMWo......,OMMO:,,,,,,,,,,,,c0MMX000KXXNNNXX0OO0XWNK00KNWX00XWMKl,,,,,:OMM0;...................:XMWWMMMMM    //
//    MMMMMW0dlccclxXWMWo......,OMMO:,,,,,,,,,,,,c0MMX0000000000O000XWXxlcclxXWX0XMMKl,,,,,c0MMk'...................,0MMMMMMMM    //
//    MMMMMMMNX00KXWMMMWd'.'''.;0MM0c;:;;;;;;;;:;lKMMNK00000000000O0XWXdccccdXWX0XMMKl,,,,ckNMMO,...................:KMMMMMMMM    //
//    MMMMW0k0XNNNKKWMMMNKKK00KKWMMWXKKKKKKKKKKKKXWMMWNNNNNNXXKK00OO0NWXkxxkKWN00NMMKl,;ckXMWWMNl...................xWMNNWMMMM    //
//    MMMMWd..,;;;''dNMMWNKKKKKKKKKKKKKKKKXWMMMMMMWNXKKKKKKXNWWWNXXK00KNNNNNNXK0KNMMKlckXWN0x0WMXl................'dNMNOOWMMMM    //
//    MMMMWd.........lXMW0l;;;;;;;;;;;;;;c0WMMMN0kxollcccccloxk0NWMWNX00000000000NMMN0XWN0dlcoOWMNkc'...........'l0WMNklOWMMMM    //
//    MMMMWd..........cKMW0c,,,,,,,,,,,,cOWMMMMKdcccccccccccccccok0XWWNK0O0000000NMMMWN0dlcccclxKWMN0xl:;,,,;:lxKWWN0dccOWMMMM    //
//    MMMMWd...........:0MMKl,,,,,,,,,,lKWMXkONMN0dlccccccccccccccclkXWWX00000000NMMWKdlcccccccclxOXWMMWNXXXNWMMWXOdlcccOWMMMM    //
//    MMMMWd...........:OMMMXo;,,,,,,,oKWWKl,;lONMN0dccccccccccccccccdXWMX0000000NMMXdcccccccccccccl0WMWK0000OXWWKdlccccOWMMMM    //
//    MMMMWd.........;xNMNXWMXd;,,,,;dXMMKl,,,,;lONWN0dlccccccccccccccdXMWX000000NMMXdccccccccccccccOWMXo,;,,,:xXWN0dlccOWMMMM    //
//    MMMMWd.......;xNMNO:,dNMNx:,,;xNMMWx;,,,,,,;lONMN0dlcccccccccccccOWMN000000NMMXdccccccccccccccOWMXo,,,,,,,:xKWN0dlOWMMMM    //
//    MMMMWd.....;xNMW0c....oXMWO::kNMMMXo,,,,,,,,,;lONWN0dlcccccccccccxNMWK000KXWMMXdccccccccccccccOWMXo,,,,,,,,,:xXWN0KWMMMM    //
//    MMMMWd...;xNMMMWo......lXMWK0WMWWMXl,,,,,,,,,,,;lONWN0dccccccccccdXMWKOKXWNNMMNkdddddddddddddx0WMXl,,,,,,,,,,,:xKWMMMMMM    //
//    MMMMWd.;xNMNNWMWo.......cKMMMMKd0MNd,,,,,,,,,,,,,;lONWN0dlccccccckWMWXXWNOlkWMMWWWWWWWWWWWWWWWWMMXl,,,,,,,,,,,,,:xXMMMMM    //
//    MMMMWOkNMWKdxNMWo........;0WM0:.dWM0c,,,,,,,,,,,,,,;lONWN0dcccccoKWMMMNOl;,xWMN0kkkkkkkkkkkkkkKMMXl,,,,,,,,,,,,,,,xWMMMM    //
//    MMMMMMMWKxlcxNMWo.........,kk;..,OWWk:,,,,,,,,,,,,,,,;lONMN0kdcl0WMMNOl;,,,xWMKl,,,,,,,,,,,,,,xWMXo,,,,,,,,,,,,,,,xWMMMM    //
//    MMMMMW0dlcccxNMWo................;OWW0l,,,,,,,,,,,,,,,,;lONWWN0KWMNOl;,,,,,xWMKl,,,,,,,,,,,,,,xWMXl,,,,,,,,,,,,,,,xWMMMM    //
//    MMMMM0lcccccxNMWo.................,kWWXkc;,,,,,,,,,,,,,,,;lKMMMMNOl;,,,,,,,xWMKl,,,,,,,,,,,,,,xWMXo,,,,,,,,,,,,,,,xWMMMM    //
//    MMMMWOccccccxNMWo..................:KMMMNOdl:,,,,,,,,,,:ldONMMNOl;,,,,,,,,,xWMKl,;;;;;;;;;;;;;kWMXo;;;;;;;;;;;;;;;kWMMMM    //
//    MMMMWOccccccxNMWo..................:KMWNXWWNK0kxddddxk0KNMMNKOl;,,,,,,,,,,,xWMWX00000000K0000KNMMWX00K00000000000KNMMMMM    //
//    MMMMWOccccccxNMWo..................:KMWOldk0KXNWWWWWMMMMMNOl:;,,,,,,,,,,,,,xWMMMMMWWWWMMMMMWWWMMMMMMMMMMMMMMMWWWMMMMMMMM    //
//    MMMMWOccccccxNMWOccccccccccccccccccdNMWOcccccloddxd0WMMNOl;,,,,,,,,,,,,,,,,xWMMWKkxdxkXWMKd::lOWN0KWMXkxXMW0dlllxKWMMMMM    //
//    MMMMWOccccccxNMMMWWWWWWWWWWWWWWWWMWWMMWOcccccccccccxNMWk;,,,,,,,,,,,,,,,,,,xWMW0occccco0Nl....:KNO0WMO;,kWO:,,,,,lKMMMMM    //
//    MMMMWOccccccxNMMKkxxxxxxxxxxxxxxxxx0NMWOcccccccccccxNMWx,,,,,,,,,,,,,,,,,,,xWMWOcccccccOWO:'';xNWNOkXWXKNWO:,,,,,cKMMMMM    //
//    MMMMWOccccccxNMWx,,,,,,,,,,,,,,,,,,lXMWOcccccccccccxNMWx,,,,,,,,,,,,,,,,,,,xWMMXkocccokNMWNKOKXXNN0OXNkolkXOoccld0WMMMMM    //
//    MMMMWOccccccxNMWx,,,,,,,,,,,,,,,,,,lXMWOcccccccccccxNMWx,,,,,,,,,,,,,,,,,,,xWMWX0KK0K0XXxooOXNXxccco0Xo;;oKO0XKNNXWMMMMM    //
//    MMMMWOllllllkNMWk:::::::::::::::::;oXMWOlllllllllllkWMWx,,,,,,,,,,,,,,,,,,,xWMW0kXXxdON0:,,lKNl.....;0N0OOOOKX0N0kXMMMMM    //
//    MMMMMX000000KXNNKOOOOOOOOOOOOOOOOOO0XNNK00000000000XWMWd,,,,,,,,,,,,,,,,,,,xWMMWXNk'.dK0OkkOKXl.....;OXNOlckNKkKWWMMMMMM    //
//    MMMMMX000000000000000000000000000000000000000000000XWMWOooooooooooooooooooo0WMMWNWWK0NKkXMW0ONXxlccdKXKXN00XW0dOWMMMMMMM    //
//    MMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMMMWWWWWWWWWWWWMMMMWMMMMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FORMES is ERC721Creator {
    constructor() ERC721Creator("Formes by kipz", "FORMES") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
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