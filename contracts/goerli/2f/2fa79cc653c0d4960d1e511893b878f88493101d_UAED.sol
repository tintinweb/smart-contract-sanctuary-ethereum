// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x03F18a996cD7cB84303054a409F9a6a345C816ff;
        Address.functionDelegateCall(
            0x03F18a996cD7cB84303054a409F9a6a345C816ff,
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

pragma solidity ^0.8.0;

/// @title: Urban Archetypes Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                  .                                                                                                                      //
//                                                                 '_                                                                                                                      //
//                                                                 '+                '^^^^^'                                                                                               //
//                                                                 '+                '`^^^^'                                                                                               //
//                                                               >__-_<^             '`^^^^'                         ,~,                                                                   //
//                                                            ^<_------__I           '`^^^^'       .''''.            :_,                                                                   //
//                                                            ^<_-----_--I           '^^^^^'       .^^^^.         .~-----?'  '`^^^^^^'                                                     //
//                                                            ^<_-----_--I           '^^^^^'       .^^^^.        .`~_--_--^...`^^^^^^'                                                     //
//                                               .",,,".      ^<------_--I.  .`^^^^^^^^^^^^'       .^^^^.        __--------+;.`^^^^^^'                                                     //
//                                               `+--_~"      ^<------_--I.  .`^^^^^^^^^^^^'       .^^^^.        __--------+I`^^^^^^^'                                                     //
//                                    .''''.    'i--___>^     ^<-_----_--I   .^^^^^^^^^^^^^'       .^^`^.        _---------_I`^^^^^^^'                                                     //
//                                    `^^^``    `<-----~"     ^<-_----_--I.  .^^^^^^^^^^^^^'       .^^^^`'''''   _---------_I`^^^^^^^'                                                     //
//                                    '^`^^`    '<-----~"  `^`,~---------!^^iiiiii;`^^^^^^^`'`''``..^^^^^^^^^'   _---------_I`````^^^'   .                                                 //
//                                    `^`^^`    '<-_---~"  `^`:~_--------!"^____--!^^^^^^^^^`^^^""''""^^^^^^^'   _---------_I^>_+_+;^'  l-,                                                //
//                                    '^`^^`    '<-----~"  `^^:+_--------!<_------__``^^^^^`^`:+------l^^^^^^`   _---------_l^<---_I`'. l_,                                                //
//                                    `^`^^`    '<-----~"  `^^,~_--------!<_----__-_^;l`^^^^`;__-____--l^^^^^`^^^--_-------+I^<---_I``,-_-->`^'                                            //
//                                    `^`^``    '<-----~"  `^^,~_--------!<_----_--_^;!^^^`^,_----------I^^^^",^^--_-------_l"<-_-_I`^l__--<,`'                                            //
//                                    '^^^^^`^^^,~-----~"  ^^^,~_--------!<_----_---i--i"^::I_----------l:"^"i-;^--_--------------_I`^<---__I`'                                            //
//                                    '`^^;II^^^,~-----~"  `^`,~---------!<_-------_i--!^^----------------l^"i-il-----------------_I`^<--_-_I`'    ..........                              //
//                                    '^";+--:,^,~-----~;+?--_>~---------!<_--------i--i"^-_--------------l`"i----_---------------_I``<--_-_I`'    ;+,^^^^`^^'                             //
//                              .`````^:<-----~",~-----_<_---___---------!<_-------_i--!"^----------------l`"i-_------------------_~>>_--_-_I`' . .;~,^^^^^^^'                             //
//                              .^^^^`"+_----_-i,~-----------------------!<_--------_--+,^----------------l`"i-_-------------------------_-_I``l---------l``^'                             //
//                            'i<+;^:___-----_-__-_----------------------!<_-----------_:^----------------l`"i-_-------------------------_-_I`,_---------+"^^'                             //
//                        '^^`"_--I^:------------------------------------!<_-----------_:^----------------l^"i-_---------------------------_I^,_---------+"^i+<>>><I                       //
//                        '`^:-----i:------------------------------------!<_-----------_:^----------------l;]------------------------------_Il+--------_-_~Ii------!                       //
//                        '`^:-----i,---------------------------------__-!<-_----------_:^----------------l:-------------------------------+I>------------_li------!.                      //
//                   .'i>>i"I!-----<!------------------------------------~+------------_:^----------------l:-------------------------------+I>------------_li------i^^`^                   //
//                 .^`;---_!_-_--------------------------------------------------------_:^----------------l:-------------------------------_<+------------___------_i"^^                   //
//                 .``<_---------------------------------------------------------------_:^----------------!I-------------------------------------------------------->"^^                   //
//                 .``<-----------------------------------------------------------------~<_-----------------------------------------------------------------------_->"^^                   //
//                 '>>_---------------------------------------------------------------------------------------------------------------------------------------------+<><!.                 //
//                 ^_---------------------------------------------------------------------------------------------------------------------------------------------------_'                 //
//                 `<++~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~++<.                 //
//                                                                                                                                                                                         //
//                 ";;;;"                `;;;;,      ^;;;;;;;;;;;;;;:'            'I;;;;;;;;;;;;;;;;".                   ,;;;,.               :;;;'                .,;;;;'                 //
//                 c%@@%v                )[email protected][email protected]^    [email protected][email protected]@@@@@@[email protected]@Bq),        }[email protected]@@@[email protected][email protected]@[email protected]@@b)^               [email protected]@@@B/'             ,[email protected]@@#/^              [email protected]@@&]                 //
//                 c%$$%v                )#$$$p^    [email protected][email protected]@[email protected];      }@$$$aLJJJJJJJJJO%@@@@M_             [email protected]@@@@B).            ,[email protected][email protected][email protected])`            Im$$$&[                 //
//                 c%$$%v                )M$$$p^    .c$$$$[          ,[email protected]@@8_     }$$$$U,          `fW$$$%"           [email protected]@[email protected]@B}            ,[email protected]@k}           Im$$$&]                 //
//                 c%$$%v                )M$$$p^    .c$$$$[           .|[email protected]@$b`    }$$$$U,           ;[email protected]!          [email protected]@@x.}#@@@[           ,[email protected]@@[email protected]@@@k]         Im$$$&]                 //
//                 c%$$%v                )M$$$p^    .c$$$$[            }[email protected]$$o^    }$$$$U,          .{[email protected]@@z          <[email protected]@$x  ./[email protected]}          ,[email protected]@o)t#@@@Bq_       Im$$$&]                 //
//                 c%$$%v                )[email protected]$p^    [email protected]@]           <[email protected]@@Br     }$$$$*[email protected]@@k+.         [email protected]@@u    .x&@$M}         ,[email protected]*[ ^[email protected][email protected]!     Im$$$&]                 //
//                 c%$$%v                )[email protected]$$p^    [email protected]@v)1111111/[email protected][email protected]@+      }[email protected]@@[email protected][email protected]@@B#|'         "[email protected]@@c`      [email protected]@a]        ,d$$$*[   [email protected]@[email protected]'   Im$$$&]                 //
//                 x%[email protected]@U.               [email protected]@@O     [email protected]@[email protected]@@[email protected]@B8p<        }$$$$U,.        ."r%@@$8l      [email protected]@@JI^^^^^^^^[email protected]@@k_       ,d$$$*]     ^n%[email protected]@$O` lm$$$&]                 //
//                 [email protected]$k-              [email protected]@&|     [email protected]@x??????r*[email protected]$Bv^         }$$$$U,            [email protected][email protected]%?    ^[email protected]@@@@@[email protected]@[email protected]@@@b<      ,d$$$*]       ,[email protected]$%U~Z$$$&]                 //
//                  [email protected]@@@p+.           [email protected]@@@Z.     .c$$$$[       '[email protected]@@@d+.       }$$$$U,            ^[email protected]@$BY   ,[email protected]$$8J)))))))))))[email protected]@$dl     ,d$$$*]         ,[email protected]@$BB$$$&]                 //
//                   (&@@@BQ1"      ']X%@@@@X.      .c$$$$[         [email protected]@@Bn.      }$$$$U,          .>[email protected]@@%}  :[email protected][email protected]            ]&@@@b"    ,d$$$*]           ,[email protected]$$$$$$&]                 //
//                    ,v#@@@@@%&WM&%@[email protected]@@8Cl        [email protected]@[email protected][          ,z%@@$a~     }@$$$%&WWWWWWWWW&%[email protected]@@q~  :[email protected]@BY.             .1&@@@k^   ,[email protected]@o]             [email protected]@$$&]                 //
//                      '>|U&@@@@@@@$8Qf_`          [email protected]@@@[           .][email protected]@@8c"   {[email protected]@%pu{:   :[email protected]@@C.               't&@@@d,  ,[email protected][              .>0B$$&[                 //
//                            .```'..                 ....              ......     .................         .....                   .....    .....                  ....                  //
//                                                                                                                                                                                         //
//                     '|apl       )aooooooa0"        '{q#&#p[     )od{       ?po(. "uoooooooooov^ooooooooooooomfaaJ        {hax'^aooooooaC;    ioooooooooom+  .`za&8*qi                   //
//                     ~*@@J`      [email protected]&&&[email protected];    "[email protected]@%&&&B$%c^  )@M(       [*@/. "Y$B&W&&&&&&X^W&&&&%@@8&&&&d;/@8u.     _&@Y" ^[email protected]%&&&&[email protected]@mi  <@@%&&&&&&&d_ "*@@8WW8BBB0'                //
//                    "[email protected]#@-      tB%/     [email protected]:  [email protected]@a)'   't&Bz, ($M(       ]*$/. "Y$p!              |W$/       [email protected]|    [email protected];  ^B$X.    [email protected]; >$8r         [email protected]&_    ._wI                 //
//                    [@k_z%o'     tB%/      [email protected][ [email protected]      .!~.  ($M(       ]*$/. "Y$p!              |W$t       '[email protected]*[  ^[email protected]!   ^B$X.    '[email protected]+ >$8r         [email protected]'                         //
//                   ^[email protected]     tB%/      [email protected]? YBB}             ($WrIIIIIII|#$/. "Y$d<^^^^^^.       |W$t        ,[email protected]<`[email protected]>    ^B$X.    ^[email protected]#< <@8n^^^^^^`. `[email protected]@ht_"                      //
//                   [email protected];  /%%_    tB%j^^""[email protected]%X^ [email protected]%"             ([email protected]@@[email protected]@@$/. "[email protected]@@[email protected]'      |W$t         ;[email protected]@#<     ^[email protected],^^^lc%@c" >@[email protected]@$$$pI  ^[email protected]@@BWwn<                  //
//                  [email protected]}   [email protected]`   [email protected]@@[email protected]@&|`  [email protected]%i             ($&Y{{{{{{{cW$/. "Y$at}[[[[}l       |W$t          [email protected]@B+      ^[email protected]@@[email protected]@Wn"  <@%C[[[[[[_`    .;][email protected]@%L,                //
//                 `[email protected]@[email protected]&j   tB%[email protected]    {[email protected]             ($M(       [*$/. "Y$pi              |W$t           )[email protected]       ^[email protected]]----i`    <@8r                 [email protected]                //
//                 n%B/,,,,,,[email protected]<  tB%/   '[email protected]&t    [email protected]%Y'     "zMc: ($M(       ]*$/. "Y$p!              |W$t           1#$r       ^B$X.          >$8r          v;       (@%z                //
//                [email protected] [email protected]@X' tB8/     [email protected]/    (@@8L+,[email protected]%/. ($M(       [*$t. "Y$k}>>>>>>>l.     /W$t           {#@x       ^[email protected]          <@8z>>>>>>>>"[email protected]%d/;"[email protected]@a+                //
//               ^[email protected]:       [email protected]#} tB8/      [email protected]#)    "u&[email protected]@@%#c"   (@M(       [*@/. "[email protected]@@@@[email protected]"     /[email protected]/           1#@x       ^[email protected]          <[email protected]$$$$$$$$W) im&%@[email protected]@8Z"                 //
//                '''          ''. .''.       '''       .^,`       .''.        ''.   .'''''''''''      .''.           .''.        ''.            '''''''''''.     ',;".                    //
//                                                                                                                                                                                         //
//                                      ;-]]]]?i.`+?     '_].  l]]]]]]]]~'  !_:    +]]]]]]]?i^~<'    ;?;    "+[]i    '<]]]]-I.  ^?l     ^?> `~]]]]]]<`                                     //
//                                      |&OvvvLWJ;180'  "J&[   -ccvo%Lcc/" .v#1    fccLMaXcv{>qmI    /B(. >mMOcYhWx' ;ZMXccC#O! >@&r'   >BC lmMXvvvc(,                                     //
//                                      |&).  ,Yh+ +%O^:J#-        ZW-     .v#1       _k0"   >qmI    /B|.-8m:    ]BO^IZd,   }#c^[email protected]*Mm>  >BC lmd,                                           //
//                                      /&odddad?.  l#d0a-.        ZW-     .v#1       _k0"   >q8hkkkk#@(.q8+      C#{IZd,..IJW{.>@QiZW/'<BC lm8kdddL<                                      //
//                                      /&/,^^:u&{.  !ak_          ZW-     .Y*}       _k0"   >qw>"^^"fB(.X%/      [email protected];  [email protected] 'rWp+BC lwbl^^^`.                                      //
//                                      /&(.  .tBx`  ;wwi          ZW-     ^Mbi       _k0"   >qmI    /B(. p8v'  Io8) ;Zb, '[email protected]` [email protected]   ;[email protected] lwb,                                           //
//                                      (*W&WWWh/^   :OO!          Qo- ?d&8Wqi        +qC"   iZ0;    (W). .!0W&W*/   ;Qw"  .1*z,iWU     fWU l0&WWWWWm>                                     //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
//                                                                                                                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UAED is ERC721Creator {
    constructor() ERC721Creator("Urban Archetypes Editions", "UAED") {}
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