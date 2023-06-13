// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Dark Enough No. 0
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                  //
//                                                                                                  //
//    [email protected]@B%%%8&&WM#*zcuxjt|)}?+>!;::,,,""""""",,,:;I!<_?})\tjxuc*#MWW&88%%%[email protected]$$$$$$$$$$    //
//    [email protected]@BB%%88&WWM#zcuxjt|)}?+>l;:,,"""^^^^^^^^^""",,:;!>+?})\trnvc*#MW&&88%%[email protected]@$$$$$$$$    //
//    [email protected]@BB%88&&WM#*cvnrf\(}?+>l;:,""^^^^`````````^^^""",:;!<_]{(/fxuvz*#MW&88%%[email protected]@$$$$$$$    //
//    [email protected]@B%%88&WM#*zcuxjt|1[-<!;:,""^^`````````````````^^"",:Ii~-[)\trnucz#MW&&8%%[email protected]$$$$$$    //
//    [email protected]@BB%88&WM#*zvuxj/|{]_>l;,,"^^````,!-{)1}1(|1-I"```^^",:;!<_[1|tjxucz*#MW&8%%[email protected]@$$$$$    //
//    [email protected]%88&WM#*zvuxjt(1]_>l;,,"^^`^!(nr(?>;,,::I<}tnr[;^^^",:;!<_[1|tjxucz*#MW&8%%[email protected]$$$$$    //
//    [email protected]%%8&WM#*zvuxjt|1[-<!;:,"^^,{cu\-i;,"^^`,^",:l+1rcu?"^",:;!~-[1|tjxucz#MW&8%%[email protected]@$$$$    //
//    [email protected]%%%8&WM*zcunrt|)}?~iI:,"":\*v/}~;,"^``^;(:^"",I>](rzz{,",:Ii+?})\tjnucz#MW&8%%[email protected]$$$$    //
//    [email protected]@B%%8&WM#*cvnrf/({]_>l;,,"}*zf{+;,"`^1~^`^,`"n,^",l~[|u#ci,,;l>_]{(/frnvc*#M&88%%[email protected]@$$$    //
//    [email protected]@B%88&WM*zcuxjt\)}?+iI:,:f#*j{<:"^``:[:`''''`}""^",;<}\c#M(::Ii+?})\tjxucz*MW&8%%[email protected]$$$    //
//    [email protected]%%8&WM#*cvnxj/|1}?~i;:~zM#u)~:"^`''`-`''''.'I''``^";>}j*MWv+Ii~-}1|/frnvc*#M&88%%[email protected]$$$    //
//    [email protected]%%8&WM*zcunrf/(1[?~>~\MWWz/-l:^`'''',.......`..''`^:i_)vWMW#|~~-[1(\fjxucz#MW&8%%[email protected]@$$    //
//    [email protected]%%8&W#*zvuxrf/(1}?[/v&8&Wx1+l,^`'...;......;i...'`^,l_{j#&&8Mn(][1(\tjxuvz*#W&8%%[email protected]@$$    //
//    [email protected]%88&M#*zvuxjt/(1{txu#888z/{_i;"``''>\...  '|!''''^":>_{\u88%Wuur)1(\tjxnvc*#MW&8%[email protected]@$$    //
//    [email protected]%8&WM#*cvnxjf/|)jttx#88Wv|}?<l:,^``"t,'..''-'.'`",:!+?1|nW%%Wux/n(|\tjxnucz*#W&8%[email protected]$$    //
//    [email protected]%8&W#*zvunrjf/|(xt\cM%%Mu([?~<;,,,^`ll;^'`"~'``",;l<?]||nW%B&zxjr\|\tjrnuvc*#W&8%%[email protected]$$    //
//    $$B%%8&M#*cvuxrjt/\|rttnz%BMv\)f{_i!I::^:::,~>[i`"":i!>-1)xjv&%%#Mufr||\tfrxnvcz#M&8%%[email protected]$$    //
//    $$B%8&WM#zcvnxrjt/||ft/xu8B&zjtvt1{+>!;,~~i+\[},,;!<__]1/jznz8B%Mvu|r||\tfrxnucz*MW&8%[email protected]$$    //
//    [email protected]%8&WM#zcunxrft\||t)\ru8%&znfr*tf{]_~>_)>+f}];i<~}{{(\jucv#&B8Wnn(t|(\/fjxnucz*MW&8%[email protected]$$    //
//    [email protected]%8&WM*zcunxjf/\()||(rvM%W#nrjxrn\)1{?](]]rt]_?[{(\fjjxczc&&B&Wur|\|(|/tjxnucz*MW&8%BB$$    //
//    [email protected]%8&&W#*zcunrjt/|(){/1jv*%8&*nxnvzrjj\)1/|)nvt{\|tfrnvz***WB8B&Mvu\|))(\tfrnuvz*#W&8%[email protected]$$    //
//    [email protected]%8&WM#*zvuxrf/\(11}11/u*8%%&vvv*W&cnrt/jxjczuffrxnvc*###*88B%W#rj/})1)|/frxnvz*#M&8%[email protected]$$    //
//    [email protected]%8&WM#*cvnxjt\(1}[?}])vu&BB%*c*W&#*zuxrxcu*W*nxuvc*#MMMMWB%B%M#tf([}[{)|/frnuc*#MW&8%@$$    //
//    @@%8&WM*zcuxjt\(1}]-_?-|uuWBBB#*#&W#***zvvzc#&#cczz*MMM#WW&%B%%M#r/(]??[{)|tjxuvz*MW&8%@$$    //
//    @B%&&W#*zvnrf/(1}]-~>~]jrcW%%%M*W8W&WWW*zc*#M&M#**#M&W&M&888%8B#vv({_+_?}1(\frnvc*#M&8%B$$    //
//    @B8&WM#*cnrjt|){]-~>!i]xtcW8&&MM88WW&WM#*z#MWWWM#*#M&&&&W8WM%8B&xj|__>~-]{)|tjxuc*#MW&%[email protected]$    //
//    @B8&WM#zcnrf/(1[?+>!;![1)*&&#WM&88&WWWMM*##M&M&&M##MWW&&W8%%%x|1}]!~+?[1|/jxuc*#MW&[email protected]$      //
//    @B8&M#*zvnrf\(1[-~iI;<~1|W8&WW&%88&&&WMM#MWWWM&&W#MMW&&8&%%&8888v|){]+>~-[1|/fxucz*#W&[email protected]$    //
//    @B8WM#*cvnrf\({]-~!I;~~{xW888%%%%%888&WWWW&&&WW&WMWW&&8%&%%%%%%Wz(1{--!<-[1|/frnvcz#MW8%@$    //
//    $B&W#*zcuxjt|){]_<!I;i>)u#%%&BBB%%88%88&&&888&W&&W&&88%%%BBB%%BMcf(]+-l<_[{(\tjxuvz*#W&%@$    //
//    $B&W#*cvnrf/|1}?_<!;;~{{\#8%%[email protected]%%%%%8888%%%8&88888%8%%%[email protected]%B&z|(}+-!<_]{)|/tjxuc*#W&%@$    //
//    $B8W#*cuxjt\({[?+>l;;1{x*&[email protected]@BBB%%BB%%8%8%%%88888%%%%%[email protected]@@B%8Mv(\+!<_]}1(\/fxucz#W&%@$    //
//    $B8W#zcuxjt|1}]-?[)tcWW&W8%[email protected]@BB8%BBB%%%%%%%%%8%%%%%%%%[email protected]@@@B%&&&WMMx/|){{1(/trnvz#W8%@$    //
//    [email protected]%WM*cuxjjrxnv*###**##MM&[email protected]@@%%BBBBBBBBB%%%%8%%%%BBB%%[email protected]@@@B%&WW#WM#MMMM#zvuuunvz#[email protected]$    //
//    [email protected]%&M*zzzzvnrrrrxxnuczMW&W&%[email protected]@@%BBBBBBBBBBB%88%BBBBBBBB%@@@@BB8&&&W#zcvunnxrrxuc*###W8B$$    //
//    [email protected]#W*vxf/\||\/tfrnvzW&8%[email protected]@@BBBBBBBBBB%%%%BBBBBBBBBB%@@@BBB%8&WMvunxrft/\/tfruzW8&%@$$    //
//    [email protected]%&8&zxf\){}{1)|\trc*M&%[email protected]@@BBBBBBBBBBBB%%[email protected]@@BBBB%&WMvnrf/\()1)(\fxc8%%[email protected]$$    //
//    [email protected]%%8WWvj\(1}}}{1(/xu#M&%B%[email protected]@@B%[email protected]@[email protected]@BBB%[email protected]@@@@@[email protected]@@@BBB%&MMvxjt|()11)\trc&&8BB$$$    //
//    [email protected]%&WWMvrt/|)111|tnu*M8%%[email protected]@@@@[email protected]@@@@@@@B%[email protected]@@@@@@@[email protected][email protected]@@BB%&W*zxj/\||//[email protected]$$$    //
//    [email protected]%&WM#Mvxrtt((|/fu*#M8B%[email protected]@[email protected]@@@@@@@@B%[email protected]@@@@@@@@@[email protected][email protected]@[email protected]@B8&Mzujt//tnrnuv8&*W8%@$$$    //
//    [email protected]%8WW*MMuvrr\\/fxvMM&%[email protected]@@@@@@@@@B%[email protected]@@@@@@@@@[email protected]@@[email protected]%&W*urfffjcvcvM%z#W%%$$$$    //
//    [email protected]&z*uujfrrc*WM8%@B%%%[email protected]@@@@@@@@BB%@@@@@@@@@@[email protected]%%%@BB&WMvnxjxncM#*%W*W88%$$$$    //
//    [email protected]@&8&MWW8W**uvnuz#&MWBB%8B%[email protected]@[email protected]@@@@[email protected]@@[email protected]@@@@@@@@@[email protected]%%%B%B&&&cuuvvz*%W&B*&W%&@$$$$    //
//    [email protected]%&%W8WB%&M#cvu#M8W&&B%&%[email protected]@@[email protected]@@@@@@@[email protected]@@@@@@@@@@@@@@BB%B88B88zvvz*M&%%B&W8%88$$$$$    //
//    [email protected]&8%&B%@%&M*zcMW&%MWB%8%[email protected]@@@[email protected][email protected]@@@@@[email protected]@@@[email protected]@@[email protected]@@@@BBBB88B%8zvc*W&%[email protected]@W%%B&@$$$$$    //
//    [email protected]%8&%B%@@B8W#**M&W8MW%88%[email protected]@@@[email protected]@@[email protected]@@[email protected]@[email protected][email protected]@@@[email protected]%%%@&%88&zzz#[email protected]$$BB%B&8$$$$$$    //
//    [email protected]%[email protected]@@B%&WM##&#&M88&[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@@@%BB%%%%%W&%%**#W&%@[email protected]@$$$$$$    //
//    [email protected]%&M%@[email protected]*zM#M*W&8&%@@%[email protected]@[email protected]@[email protected]@@@@[email protected]@@@%%BB%8&BW&%&**#[email protected][email protected][email protected]$$$$$    //
//    [email protected]$$B8&&[email protected]%8W*vcz&*%M&&8BB%%@@@[email protected][email protected]@[email protected]@[email protected]@@@B%%%@8W&&8&Bzvc*[email protected]%&%[email protected]@$$$$$    //
//    [email protected]@@@%88B$$B%&#vnncWMW*&MWBB%%[email protected]@@@[email protected]@[email protected]@[email protected]@@@B%%%@&WWM%&[email protected][email protected]%@@@@$$$$$    //
//    [email protected]@@@B%@[email protected]%8MzuxxcW8MMMMMBB8%[email protected]@@[email protected]@[email protected][email protected][email protected][email protected][email protected]@B88%BWWMM8W8vxuc#&[email protected][email protected]@@@@$$$$$$    //
//    [email protected]@@@$B$$B%&#zvnxv8%Wz*MM%%88%@@@@@[email protected][email protected]@[email protected]@@B&8&BMWMMM%&vxxv*M%@[email protected]@[email protected]$$$$$$$    //
//    [email protected]@@[email protected]*cuxu#%Mcc##8888%@@@[email protected][email protected]@@88&WBWW#MM%8urxc*[email protected][email protected]@$$$$$$$    //
//    [email protected]@@@$$$$B%&Mzvnu&8Wz*WM%88&%@@@[email protected]@@%8&&@&MMW&&&unvz#W%@[email protected]@$$$$$$$$    //
//    [email protected]@[email protected]&M*z#&%%WWW%B%[email protected]@[email protected]@@B%%[email protected]&&8%88zc*#W8B$$$$$$$$$$$$$$$    //
//    [email protected]%8WW&W%B%[email protected]@@@[email protected]@[email protected]$%%BB%%%WW&8%@$$$$$$$$$$$$$$$$    //
//    [email protected]%%[email protected]@@@@@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]$$$$$$$    //
//    [email protected][email protected]@@@@@@@@[email protected][email protected][email protected]$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$    //
//                                                                                                  //
//                                                                                                  //
//                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////


contract DARK0 is ERC721Creator {
    constructor() ERC721Creator("Dark Enough No. 0", "DARK0") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xa60e235c7e7e27AB9f5E7b5a7d67e82088314CA6;
        (bool success, ) = 0xa60e235c7e7e27AB9f5E7b5a7d67e82088314CA6.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}