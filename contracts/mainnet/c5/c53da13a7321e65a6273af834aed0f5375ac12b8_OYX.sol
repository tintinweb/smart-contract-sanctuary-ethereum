// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: O.Y.X COLLECTIVE
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    MWWWWWWWWWWWWWÐÐÐÐÐ@###55A%%$33JJCC7==((¦¦¦¦!!*****************!!¦¦¦¦((==77CCJJ33$$%%%A5555######@@@    //
//    MMWWWWWWWWWWWÐÐÐ@@##55A%%$33JCC7==(¦¦¦!***,,,,,""""""""""",,",,,,,,***!!¦¦((==77CCJ33$$%%AA5555####@    //
//    WWWWWWWWWWÐÐÐÐÐ@##55%%%3%A3C7=¦%¦!***,,,,""""""‘‘‘‘"‘"‘‘"‘,W*‘=,,",*,,*,,***!¦¦((=7CCJJ3$%%%AA555###    //
//    WWWWWWWWWÐÐÐÐ@##55%%$3JCÐM$CJ##C=C,,""*"""‘‘‘‘‘‘‘‘‘*7M®MMW#®®®®MM*!!#MMMM=",,(¦*!¦((=77CJ33$%%%A555#    //
//    WWWWWWWÐÐÐÐ@##55%%$3J$%%5ÐW®MMÐJ#5J,*"5‘‘‘‘‘......."Ð®®®®W®®®®®®®MMÐ®®®®®®®Ð%#",,**!¦¦(=7CCJ33$%%A55    //
//    WWWWWÐÐÐÐ@##55A%$3JCM®®®®®®®®ÐÐ3%#%%%5%¦...........J®®®®®®®®®®®®®®®®®®®®®®®®®Ð,""",,***¦¦(77CJJ3$%%%    //
//    WWWWÐÐÐÐ@##5A%$3JC7WM®M®®®®®®®WM®M#%ÐM®®W7........3®®®®®®®®®®®®®®®®®®®®®®®®®MÐMW(‘""",,**!¦(=7CCJ3$%    //
//    WWÐÐÐÐ@##5A%$3JC77=(J®®MM®®®®®®®®®®®®®®®®®®!....%M®®®®®®®®®®®®®®®®®®®®®®®®®®®®MWWJ*‘"""",,*!¦(=7CJJ3    //
//    WÐÐÐ@##55A%$3J77(C3ÐW®%#MM®®®®®®®®®®®®®®®W##..‘W®®®®®®®®®®®®®®®®®®®®®®®®®®®®(%%$MMMWÐ*‘""",,*!¦(=7CJ    //
//    ÐÐÐ@##5A%$3JC7=(¦%%5#MM®®®®®®®®®®®®®®®®MW#A$".7MMÐWMM®®M®MMWM®®®®®®®®®®®®®®M3C5®[email protected]!$"‘‘""",,*!¦(=7    //
//    ÐÐ##55A%$3JC==¦AAAAAMMMW®®®®®®®®®®®®®®®Ð5*"...... ."(5#¦Ð*[email protected]®M®®®®®®®®®®®®Ð[email protected]¦*557‘‘"",,*!¦(    //
//    Ð##55%%3JC7=(¦(ÐÐAÐM®%5®®®®®®®®®®®®MWMMÐC"..         .¦.C.,A=!A¦$M®®M®®®M®®[email protected]@%C#@Ð#55%5%W,‘‘‘"",*!¦    //
//    @#55%$3JC7=C=(¦(CÐ®®®®WÐ®®®®®®®®MM#@W¦#7$=..         .!!*"=‘=C.(@(¦%MMMM®MÐ@##%[email protected]@$J".‘‘‘"",,*    //
//    #5A%$3JC7=7C3A$35#®®®®®®®®®®®®®®[email protected]Ð¦"3(7%%‘. .........!*"7(%!%,J7*A,%Ð®MMWM®®®M$%[email protected],,J‘‘‘‘"",,    //
//    5A%$3JC=CMW®5#@#Ð®®®®®®®®®®®®®®®M5#A¦@=%*5!J¦¦,"A%$J"$‘‘!(!JA%=%=(3¦‘5CÐ®®®®®®®®®®®®®5$#CCÐ3.‘.‘‘‘""    //
//    5%$3JJJ3#MÐ5#®ÐW%M®®®®®®®®®®®®®®%#$J##7A!J"7(‘.,"A35A=‘"."!.C((¦7,=$..,¦ÐM®®®®®®®®®M®®MMMMMÐ#(¦.‘‘‘"    //
//    A%33$Ð@MWMM®M®®®®®®®®®®®®®®M$ÐÐ$#5377J!*!".!""**    "" "J,‘***!"=J¦(‘!77*#®MM®®®®®®®®®®MMMMWÐ#%"..‘‘    //
//    %$5AMMMMMM®®®®®®®®®®®®®®MMWAC((77%!,!!,¦,"‘,.       ."    *¦,C!**#!*C=",C5M®®®®®®®®®®®®®MMMMMWÐ,‘.‘‘    //
//    $ÐMMMMMMMMM®®®®®®®®®®®®®®MJ%3(73J$"(¦"*"".          .,     .,‘",!‘*=¦‘‘¦!!AÐA3®®®®®®®®®®®MM®®[email protected]*...‘    //
//    $3CAMMMWMMMM®®®®®®®®®®®®®Ð$C,,#$(C¦‘!"‘. .          .         ¦‘‘‘‘,¦,.....*$M®®®®®M®®MMMMMMM#7!‘‘..    //
//    [email protected]Ð@M®®®M®®®®®®®®®®MWJ‘!7=#J¦,!""*              .          ,‘,¦‘[email protected]ÐWMMM®®®#AMM®®®®Ð533¦‘.    //
//    JC73(=$Ð@ÐM5AM®®®®®®®®®MÐ"‘...A¦.¦=*"               ‘     .    .*‘,.,!!,*!!*=JÐM®®®®®®®®®®WÐMM#=‘...    //
//    J7=(=J%Ð®®®®M®®®®®®®®®®MÐJCC7=*¦",‘,                .            .,‘."J¦!"",¦(ÐM®®®®®®®®@M#@@ÐÐC". .    //
//    C7=(¦¦($%#5WWW®®®®®®®®MWAJCCC$!"‘‘‘‘                .            ‘‘.‘(33¦¦!*(7ÐW®®®®®MMMÐÐ#W#%JJ((..    //
//    C=((¦!!75JJÐWÐ®®®®®[email protected]#AJ,....,¦."*‘                  ‘           .‘‘‘!¦73(¦!"AM®®®®®®W®MÐÐ#####5!...    //
//    C=(¦!!**,*¦¦((3AÐ®®®®®®®®®Ð$((,!,*".                  ‘          .*‘"!¦5."=ACÐM®®®®®®®®®®@###A$!....    //
//    C=(¦!!*,,!¦¦¦([email protected]®®®®®M®®MM#,57"*‘.                   .         =‘‘=$7J‘‘‘($$M®®®®®®®®A5#5#Ð#J‘ . .    //
//    7=(¦!!*,,"%MWA%$%$W®®®®®®®MÐ@%7,".‘‘.                      .   .‘‘*"¦A3C!‘.¦@M®®®®®®®®MÐWWWWÐ@#%....    //
//    C=(¦!!*,,,7%@®®®ÐÐ@Ð®®®®®®W(3!=A!=‘"C.                        .,"*C5%%¦!("‘*@M®®®®®®®®®ÐÐ@@#ÐWWC....    //
//    C=(¦!!**"®M®®®®®®®®®®®®®®®W!C¦¦C%J*","..                   .‘"‘¦*¦7J¦C¦7‘.,ÐM®®®®®®®®®WÐW®®M5$......    //
//    C7((¦!!*,,"=M®MÐ#@®®®®®®®®®W"(¦(¦J%¦¦*,‘.‘..  .         ..‘"..,‘A==‘!(‘,"Ð(#M®®MW®®®®®®@5$WM(,.. ...    //
//    C7=(¦!!*$Ð@ÐÐMWMMW®®®®®®®®®MÐ7"J.!(7J3=¦,*‘‘"*‘‘"..""",‘,."*‘A%7"J=3"*7CÐM®MM®®®®®®[email protected]®@ . . ...    //
//    JC=((¦!!,,®®®®®®®®®®®®®®®®®MMÐ*.*=¦!¦3*7AA$$*¦(,,‘‘"*!"(7J7==(7¦‘,.‘C%M®®®®®®®®®®®®MWAC=C=.. . .....    //
//    JC7=(¦!!,¦#[email protected]®®®®®®®®®®®®®®®MWM%!(.7C=!.3"=337JJAJ3!7!*"7*="  =¦""ÐMM®®®®®®®®®®®®3A,$A*"...    ....    //
//    3CC=(((=C%W#Ð®®®®®®®®®®®®®®®®®®®Ð3.=3%(.J% ¦J=3 ¦‘=‘"..7".7.(C. "Ð@ÐM®®®®®®®®®®MM®®MÐ@#3="‘.........    //
//    $3CC=((([email protected]#MWM®®®®®®®®®®MMMMM®®®M#MÐ@¦..==.##W%,3!.7.! .3"‘¦.",%‘M®MMM®®®®®®®®®®®®MA5####577‘.......    //
//    %$JCC=(¦!ÐMMMM®®®®®ÐWÐWA%#®®®®®®®®®®MM$WWW5M®®[email protected]#¦=C%‘..$%##AJÐ®®M®®®®®®®®®®®®®®®[email protected]@[email protected]@5C(......‘    //
//    A%3JC7=(¦¦AM®®®®®®®®AJ%%ÐÐ®®®®®®®®®®®®®®®®®®®®®®®®M®®®MC=J®®®®®®®®®®®®®®®®=J=5$MMMMÐ5ÐÐÐ##57......‘‘    //
//    A%%3JC7((¦!¦5®®®®®®53%53%A®®®®®®®®®®M®®Ð®®®®®®®®®®®®®®®M®®®®®®®®®M#%@33([email protected][email protected]#@@#5Ð@ÐÐ‘.....‘‘"    //
//    5A%%3JC7((¦!!**$®M#®Ð3#Ð3ÐM®®M3A#Ð[email protected]#Ð®®®®®®®®®®®®®®®®®®®®®#®W®®®®®M$C¦!*(%3777773J5%J$%CJ‘.....‘‘""    //
//    #5A%%$JC=((!!!!¦[email protected]#M7®MMÐ$¦7=CJC3®®®®®®®MMMMJCAW®®Ð®®#Ð5Ð#@A%5CC¦"‘*!!!#%7¦**(.!C*""......‘‘‘"",    //
//    ##5AA%$JC7((¦!!****!*,77*CMM#3$55($7===$MMMMMMMM5#W®Ð%(M#3#%[email protected]#%3(*,",!,*!77¦‘. ..""........‘‘‘",*!    //
//    @##55A%$JC7=(¦!*,,,"""""*%@@%MM$,@W=C(55MMMMMMMWMWMÐÐMWÐJC$%[email protected]##3,*,,**,,‘‘.. . ..........‘‘‘"",*!¦    //
//    @@##55A%$3CC=(¦!!,,,""‘‘#AJ‘*=(!,"!C$7#ÐMMMWÐ@Ð#J$5W53W!"=*[email protected]®37C%""C!*$**=.. .  ........‘‘‘"",*!!¦(    //
//    Ð@@##55A%$3JC7((!!*,,"""‘,‘‘."(""*CJ#%$WMÐÐ@5#Ð#=!J777!¦¦‘,%‘.‘..,‘‘"*¦‘...,..........‘‘‘‘"",,*!¦(=7    //
//    ÐÐ@@@##5AA%$3C7=(¦!!*,,"""‘‘‘‘‘"""JC,=#ÐWÐ#5###%%*!!!!.  .‘.    . *"...............‘‘‘‘‘"",**!¦(==CC    //
//    ÐÐÐÐ@@##55A%$3JC7=(¦!**,"""‘‘‘‘‘‘CC¦..‘$Ð#%@AC(*‘‘.......        ................‘‘‘‘""",*!!¦((=CCJJ    //
//    WÐÐÐÐ@@###5AA%$3JC7=(¦¦**,,""‘‘‘‘","...."JJ=(.................................‘‘‘‘""",**!¦¦(==CCJ333    //
//    WWWWÐÐÐ@####5A%%$3JC7=(¦¦!*,,""""‘‘‘‘....."".............................‘‘‘‘‘‘""",**!!¦(==7CCJJ3$$$    //
//    WWWWWÐÐÐ@@###5AA%%$3JC77=(¦!**,,"""‘‘‘‘‘‘‘..........................‘‘‘‘‘‘‘""",,**!¦¦((==CCJJ33$$$%%    //
//    -= EfeitoEspecial.com =-                                                                                //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract OYX is ERC721Creator {
    constructor() ERC721Creator("O.Y.X COLLECTIVE", "OYX") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1;
        Address.functionDelegateCall(
            0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1,
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