// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4;
        Address.functionDelegateCall(
            0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4,
            abi.encodeWithSignature("initialize()")
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

pragma solidity ^0.8.0;

/// @title: Raices
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    kkxxxxkkkOOO0000OOkxxdoodxxxxxddlo00xddoooooddddddddooooddddddkKK00OOOOO00OkkkOO0000KK00OOOOOOOOO0Kk    //
//    xxxkkOOOOO0O0OkkkkkxxxdoookKKXXXK00OOOOkkkkkkxxxkkkkxdooolccc:lOXXXNXKKKKK0OxxxxxxdddddddddddddxxkOx    //
//    dddddxxxxkkkkkkO00KKXXXXK0000KKOdolcldddxxxxkkkkkkkkxxxdol:;,'cOKKKXK0O0KKK00000000KKXXXXXXXXXXXNXXk    //
//    00OkkkxxxxxxxxddxxddddooodxOkoc::loxk000KK0KKK0000000KKKK0OkxoccldOKXXXX0xxdddddddxkkkkkkkkkkOOO00KO    //
//    kkOOOOOOOOkkOOkkOOOOOkxddl:;;:oxO0000000000000000000K000K000KK0ko:;dKXXX0kkO000K0KKKKKKKKKKKKKKKKKKO    //
//    lloooooooooooollllcokOOxl;;cxO000000000000000000000000000000K0KKK0kollx0KK0kdddddxddxxxdddddddddddxx    //
//    xxkkOOOOOOOkkkkkOOOkOkl,,lxO000O00000K0OO0KKK0000KK0kxxk0KK0000000K0xl:d0KK0OO00O0000OOOOOOkkkkkkxkx    //
//    lolollooooooooooooodd:,cxO0O00O0000Od:,''';dKK0KOoc:'..';o0K0000KKKKK0xoc;lOXKKK0000OOOOOkkkOOOOOOOk    //
//    OOOOOOkkkkkkOkkkxkxc,;dOOOO000O0000o..',,,..;kXk,..',,,,'.;kK0000KKKKKKOd:.,xK0kxxddddddxxxxkOOOOkOO    //
//    lllllllcccllllcclc,':xOOOOOO000000l..,,,,,;,.;k:.',,'',',,.;OK00000KKKKK0d:''o00OOOkkkkxkkOOOOkkkxxk    //
//    OOOOOOkkkkkkkkOOkl,:xO00OO00000Od;.',,,;;;,,,....,,,,,,,,,,.oKK000KKKKK0K0d:'.cdddddxxxxkO00000O0OOO    //
//    ollooollllllllloc':xOOO00O00O0x;..,,,,;:;;,','..,,,,;;,,,;,.lXK0000KKKKKKK0d:''xNXNXXXXXXXXXXXXXXXXK    //
//    OOOOOOkkkkkkkkOd,;dOOO000OO000:.',,,,,,,,,,',,'',,,,,,,,;,.,OXK00KKKKKKKKKK0d:.;kkdddddxxkkkkkkkkkxk    //
//    oooolllllllllll;'lkOO00000OO00x:,'...',,,,,,,,;;'''',,,,'...:xXX0KKKKKKKKKKKOo,.l000KKKKXXXXXKXXKKK0    //
//    OOOOOOOOOOOOOOd,,dOOOOOOOO000000Okdc'..,:;,'.,,,:cc,.,,,'','..xXK0KKKKKKKKKK0x:.:0KOkxddddddddxxxxxO    //
//    lllloooollllll:':kOOOOOOO000K0kdl;,'..',::::,.;locc'.;;;;;;:. lXK0KKKKKKKKKKKxc';OK0OOOO000000000000    //
//    kOkkkkkkkxxxdd:'lkOOOOOO0KOo:,'...';::;;,'.',;c;....,:cccc::..oX00KK0KKK0KKKKkl';OK0OkkkxxxxxxkkkkkO    //
//    llooolllllcccc;,lOOOOOOO0Xo...',,,,clc;;;;,;l::l:;;::cclc:::..xX00K00KK000KKKkc':kxdooooddddddddxxxk    //
//    00000OOOOOOOkko;oOOOOOOO0KOo;,'..',;;;;;;'.,;..;,';;cllc:::;.'OX0KKKKKKKKKKKKx:'lKXXXXXXXXXXXXXKXXXK    //
//    olooooooooooll:,lOOOOO0000O00Okd;..,,,,'...'..,'..,;:cc:;;:,..kX0KKKKKKKKKKK0o,,dOkkkkkOOOOOOOOO0000    //
//    ddolllclllllll:,:kOOOOO00000000KKx,.,'.....,,,,'....,;;;;;;..l0K00KKKKKKKKKKkc':kkooooooooooddoodddx    //
//    dddoooollllloooc;oOOOOOOOOO000000KO:,;'...,::;;,. .',..','..oKK00000000KKKK0o,'dKKKKKKKKKKKKKKKKXXK0    //
//    ooolllllllllooll;;xOOOOOOO0000000KXKKx:,..,;;;;,'. ,xxl;,,:kK00000KK000KKK0d:'c0KKKXXXXXXXXXXXXXXXKK    //
//    kxxxddddxddxxxxdl,;xOOOOOOkkOO0KKK0K0ccl..;,,,,,,'..,OXKKKKK000000KKK0KKK0x:':kOdddddddddddddddddddk    //
//    dooollllooooooolll;;dOOOOkd:;:cdO000k:ok;....',;;,'..dK00K00K000000K0OxO0d:':kKkdddddxxxkkOOO000K000    //
//    xxddooooooooddddddl,'lkOOkkl''',;lOKO:c0KkxxkkO00OkOOK0000000K0000Odl;,ld;'cOKKKKXXXKKXKKKKKKKKXXXKK    //
//    doooooooooooooooooolc,;okOOx;,:lc';x0l,dK00K00000000000000000K0Odc;''.,o:'lOOxxxxdddddddddddddddddod    //
//    xdddooolllllloooooooo:'.;okOl;::oc',dk:;xK000000000000000000Kkc;;,'''.;xod0KOdooddxxxxxxxxxxxxxxxxxk    //
//    ddddooodddddddddoooddddl,.,oo::;;l:',okc:xKK0000K000000000K0d;;:,,;,.'l000OO0OOOkkkkkkkkkkkkkkkOOKKK    //
//    ddddddoooooooooollllloool;..',,;,',,',lOd:oOK000000000000K0o;c:..::..:k0OxooooooooodddddxxxxxxxkO0KK    //
//    kxdddoooooooooooooloolllllllcll:'....''ckkc:d0K0000KK0KKK0o;c;.'c:..:k00000KKKKKKKKKKKKK0000000000KK    //
//    OOOOOOkkOOkkkxddoooooooooolllllodl;'..'';oxd::xKK00Okxddkx;',,;c:..lOOdllllllllllccllllllllloooooooo    //
//    lcccccccccc::::ccccccccccccccllokOkdc;'...,;;''ck0Odc::lxl'';;;,,:x0KOkxkkkkkkkkkkkOOOO0000KKKK000K0    //
//    OxdoooollloddxxxkkOOdlccloxOOOOkkOOOOkxolc:::,..,okkkkk0k:':;,:dk000000000Okxxdoddx0KKKKKKKKKKKKKXXX    //
//    OkkkOOkkkkkkxxxxxkOo'.'''';lxkOOOOOOOOOOOxoool:,'',ckKKKx;:c:d0KKK000Oxoc:;;,,'''',cxkdolllllllooooo    //
//    xdolllllllccccccllxl..''..',;:ldkkOOOOOOO00OOOOko;,',oKKo':d0K00KKOxc,'',,,,,''''''';dOOOOOO0OOOOOOO    //
//    lcccccllooooodddxxOk:..;;..''..,;ccccllooddooodxxxdl;,lOl;xKKK00ko;',,,,,,:cllodxxxocx00KKKKKKKKKKKK    //
//    doooollllllccccccclldl:;,'''....,,....',:lloodddl::::;';;l0KKKOo;,;;;;:ldkOkdodooooooooooooodddddddd    //
//    l:cccc:ccclclllllllodOOxoc;,,'',;::clodxxkkOOO000o:,.....:kK0d:,',:ldkOkkkxdlccclclllooooddddddddddd    //
//    Okkkkkxkxxxddddooollcccccccccccccccccc:::::::lxO0xc;.....'coc,',cdO00OdccccloooddddddxxxxxxkkkkkkkOO    //
//    dooooodddoollc::;;;,''''''.......'''....'''''ck00kxc.....'''';lk0K0Oxoc::;;;::::c::::::::::::::;::;:    //
//    oc::ccc::::;;;;;,......';'....'''',,;;::cllodkOOOOkc.;;..'''ckKKKK0x:,;:cclldxdl,.,ldll::::;;;;;;;;;    //
//    l;;:ccc:::::ccol,......,llclloddddddxdddddddoooodxd:.;;',',okOKKKKKK00KKKK0KKK0c...;llc:::cccccccccc    //
//    xoddoddodxxxxxx;...':oxkOOkdolcccccccccccclllclloddc..';;,dOkk0OOOOOkkkxkkO0KKKx;..'cl::;;:ldOKKKKK0    //
//    Oxdoollcc::cdkxc',cddooolcclccloddxxkkkkkkkkkkkkkkkc...,;lO000000000OOOkxxxxkOO0kl,.........':ddllll    //
//    oc::ccccclodxxoc,',,,:oxkkkxxxxxxxkkxxxxkkkkkkkkkxo;...':k0O000000KK00KKK000000Oko;.;oxdoc:;;:dOOOkk    //
//    0Okxo:lk0ko:,....;cll;;okOkxxxxxxxxxxxxxxkkkxxkkko;,....lOOOOOOO00000KK0OOOO0K0kdc:oooodOkollooooodd    //
//    kl::clol:......,okOO0d':kOkxxxxxxxxxxxxxxkkkkkkkx;.'. .'oOOOOOOOO0000kl;',;;:lc,.:k000xollldxdoollll    //
//    kdxxoc:c:...';lkOOOOx;.cxxxxxxxxxkkkkkkkOOxddool;.... ..cddxkOOOOOO00kl,.'';cloldO00OO00Oxoldk0OO00O    //
//    KOdlldxkd'.cx0Okxdc,',cdxxkkkxolloooool:::,'''....    ...,::coxOOOOOO00kxxkOK0000000O000000Odlok00OO    //
//    0kkOkxxxxloOOkxko;';lxkkkxo:::cllcccoxxo:,,'....'','';::,,;;coxkkOOkkO000000000O0000OO000O000OxookOO    //
//    OkOOOkxxkOkxxxkkxddkOOxl;,;clolccclodl:,..'',;:;:od;;kOxxxl'.',:loddoddooooodxkk0OOOOOOO0OO0O0OOxodO    //
//    OkkOOkkxxxxxxxxkkkxolcc:coddoodxxdc:::;'';lodd,.lkxc,okxkOl:odo;.':,,cc;'';cllllllokOOOOOOOOdlxO0Oxx    //
//    OkkOOOkkxxkOOkdolc:codlccldkxkxl;;:cod:'cdo;co;'ckOxc,dkxkc:xxkkl;:ldOkl;cc:lk0OkollldkkOOOOOdccdOOO    //
//    OkkOOOOOOOkd:;;cdxkko;:okkkkkd:;ldddxdc,;xl'cxo,;xxxd;cOxkx::xkxkxc,lkdddlod:;dkkOOkdoooloxdoxOd:lkO    //
//    OkkOOOOOkd:'cdOOOkd:;okOkkkOx:;dddxxxxd:,ox:,ox;;dxxo,cOkxkx:okllxkl,dx:lx::k::kkkkkOOOOOOOkdccxkldO    //
//    0OkOOkkkOdlx00OOxl;lkOOkOOOd:.:xxkkkkxd;'okxc,lo;:oxl,oOxxxxookl';dx;ckdldc,xo;dkxkkkkkkkkkkOOo:oOOk    //
//    00O00OOOOkO0OOOd:cx0OOO00xc;ll;oOkkxdo:,,;oxxl,ldc:oolxOx::oookxc'cxc:dxxkc;dkccxxkkkkkkkkkOOOOxcoOO    //
//    000000OOO00OOOxoxO00000xc:cxkkc:dkkdc,.cdl;;ldl;okxxxxxl;:oxloxxc,cxc,ldxxl,:xxclxkxkkkkkOOOOOOOOkkx    //
//    0000000000000000KKKK0kocokOOOOd;lOo;;':xxxdlcdxddxxxko::dkxddddxl,;dolldxxxo;:do;;oxxkkkkdxkOOOxlddc    //
//    00KKK0KKK00K000KKK000OO000000Oo;lkoododxxxxxkxxxxxxxl;lkxdddddooo:':ddooddxxxloxdc;:dkxl:ldo:ckl.',.    //
//    000KXXKKKKKKKKKK0K0000K0000000dcxOkkkkkxxxxxxxxxxkkdcdkxdddddooooo:coooooddxxxxddddodxo;,::'..,;,,;;    //
//    KK0KXXXKKKKKKKKK00000K00OO0000OkkOOOkkkkxxxxxkkxxxxxkkxxdddooooollololllcloooooodoooooooc:,.,',clclo    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RCS is ERC1155Creator {
    constructor() ERC1155Creator() {}
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