// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: GUN METAL - EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                     `;;/|i|\/_.                                                                                                                                                                                                                                                                                                //
//                               ;s}onL6TT6noyo5Lnuafj\`        :Lzz]]zz]}xxJJJuv.        iuJJaaaJJJJJJJJJIIxxJIJJxuj             }5ooooyaJJJJJan-     ~nxJJJJaaaaaaaaao}              -uyaaaaaJJJJJJJJJJJJJJJJJJJxJxxJLa[jjj[[[[[[[[[[[[[x5Ixxxe}ffffffff}}}ff}f}[[]}}}}}}ff}}fxx}][}f}eexe}n:        _JaxIIIIIxxxxexyn,                         //
//                           .toTqLoJyaJe[oIJ[?jjzrv[l}ouf:     jL.`"!":`!jl\:~z6u        6yooyaou5525LLLLTTTLkbYgqUNx           _STSPZZ%%%ZZZZ6qj     LPZZZZZZ%%%%%%E%SZ;            ;U%EEE%Z%SZZZZZPPP8US8USUU8gqpTTgLYYYYYYY66b66bkTTTTTy5L5oI}}}ll[jlritr?il}}av"!||tll[c\|trl\"\!tlIuuII%a       }L}I2LLLTLLTbTTTSP.                         //
//                         -cT65L55yI}[lrtsvj[i/!!!\i\ivvzLn!   Tc;/|!/\i5oj/~c]6J       "8juuou2nLLLT66dTYYppFCSPZZ%NI          [%%%%EmmOXmmmEuC!    `SPNNNOOXNNNNNNNNOOu           !Z%[email protected]%ZdSZZZZZZPSPSLbbTTTTTLLLLLLnnnn25yLn5ooaoyJJJf[}ju8}yp}uUa|\!"t}oovvJzrjrr[[l[JLnuLUY      "SvroT6TTTkYF$UUSNo                          //
//                        "dYLLnnnn2ox[rrri|itjr|"\|iv\vs|!?kL_:F~rjl\i[?Jya[eacZ"       aTxounLLnLTbb6bbTn6gSUSUSP%%[email protected]         bP%EmEEEEmOX%EJb     [email protected]@@@[email protected]%          rEONNOONNEEEmNOOXmmXm%%%ZZ%ZZZZZSZSkLLdY66kTTTLLLLLLL5ounLL5n5uouuaaouou5jo5tJnt"/ij[xxztrli|tjj[j[}oouuok%`     [email protected]~                          //
//                       [ULTTTTL5n5ofcj[[ti||?[Icj~;~iifyf\iuTF8/![ujJr|jlv\ryod        YIyooonnLT6Ydbbd6Tb6pSSSPZZZ%[email protected]       ZP%EXmmmmmOOXp2J     TZOENNNNXm%XXZ%NNONN_        [[email protected]%%mEZZZZ%%ZZPUPSY6TTLLLLLLLLnn52LLLLLLLLn5oooyyu2n5fzu]\oeij}jzaJ[e[?jsljjeI}}]yI]xJyN|     6}v}][TkT6LT$UPF%p                           //
//                     .nCTbTbbTLLLL2ouyuL5uajIoJz]xl}}IJ[?|ijtIz_"ti~;""iv]vIjg[       tS[uuoL5nnLTbdbdYqFSSSSUPZZ%%%%ZNg`     "EONOEUEOOOXONyY;     [email protected]@@NNOZEOONONmu      -6OONNOOOONNOXOmEXZmEEE%EZZZZZ%ZZ%ZgPZ%ZZPPZZPUUg$gdbCYbkTTLLLnnLnouooyou5ufoo[]y]}a[][j[vcjIuyjs[xo2u}}xJxcjPu    [email protected]                           //
//                     u8TkTTbYkTkTL5yn8%ZUPpTL5qn]r|i|i\;rj|!jvxv}Jjv!/ij}riJjP_       LLonLuunnLLTbdYCYFUUUSPPPPZ%%%Z%%Ng-    xZXNEEONNNNXOEyT     ;[email protected]@@@@@NNmNNNNNOXO%-    ;[email protected]%E%%%ZZZZZZZPPSqSSSUg$pFpY66bTTLLLLLL25nn5uunL2nJIx[JooJz}]uJJJynnJxyuLLLofzoxyy6$    tnl]uLTdYnC$8SSPXO:                           //
//                    iZ6Y6LTTbdkbLnnbZ%%OTi`  .}mlieji|\""~|t[?t?x5xos/~|yfcxuk        Sey5no2LLL2uLYCpp88SUSPZPPZZZZ%%%%OF-   6ZmmOONNNNNOXTLj     [email protected]@[email protected][   /[email protected]@NOOOOOOXXOOO%%mmXOOXm%%EEmmEm%%Z%%%ZZZZZSFgSSSFUUpppCYd6bTTLLLLL2LLnoJoLn252aJJaoIJounyooyouuo5nLun2uouu2Lkm_   LjvJTk6USFSSSSSPNT                            //
//                   .qTY6dkTTbkLTLLLPSZm\      :ULlxx]j]jvjccjrt[e}xolttjuvxlUc       ,F}ou5ouLLLLLT6CgUU8USSZPUZZZ%PPZZZZX$, ~E%%EmOOONOXXXJF:     [email protected]@NNNNNOp  [email protected]@@@@NOONNXmmONOmmZ%mmXXmP%mmEZZZZm&&[email protected]&[email protected]@[email protected]@@@N8TLLLLLnoouLLTONNNNZoJ}yoyJxy5LYONULLkTLTLnnLLnOt  -SljLT6YUS$g8SPSZKr                            //
//                   i%T6bLY6TTTLTTLddqm\        .lueexeeeeeeLoc}}?!]Jfs?\irfcP:       lLuu52unnLLLkT6YqYZZPPPPPPPZPZZZZ%%Z%NS_I%%EEEXOmXXOXZuT     "[email protected]@[email protected]|[[email protected]%%EEm%%%%EmmEEXmmmmmmmEEmDMQQDQMMMQQNuLLLLLLL22nLLUQQQQN5oouuunnnn5LNQQdynnLTLTT6dLT%5  sUly66dg8pqT6PSP%%.                            //
//                   LS8qpFYYTLLLLnnTLPL   ;axx}z][cllvv????rnxl}fJ]xaxtll]o}5T        T[u2nLuLLTTTkkYYYpg88SPPZPSSZZSSZZ%%%EN%ZPXmm%EmXONXEnYr     xZXmE%[email protected]$TXOOONNNONNZZXNONXZmN%5ZmEmEEEEEXmmEEmXXmmE%mEmmE%%%Z%mE%ZZZZZPPSURMMMMMQQQQQ$uT6TTTTLLLL6L%QQWOu5n2u5nkkLou%QQW6JunnLLLLTTLL8U  [email protected]                             //
//                  `STFqqqd6CFTTLLkLnE!   TLooxj]jl?lsvr|\|||\tjsljll[[vscyrSs       _pyuunLuLLTTT6bddYYFUSSPPPPS$SY$PZZZZ%EEEPSE%%%S%mOXEmyg.     [email protected]%PZ%[email protected]@ZLPOOmmmmmOEXmEEEmmmmmEEEEmE%EmE%%[email protected]@[email protected]@NE5nnnnnn2n5uLgNNNXLonLLLLbLuLLLbm__Uv[TYqFUSSUS8SZmR/                             //
//                  |@ZPSZ%ZPZZPPUFT56Y    FTLnouuoyIJJezjv?rr?clrslscjljzu]jS.       l%522nLnnLLLTTTTbd6YqpFg8$$ujPdqgpSPPPPPPZSPPZSSSPZZZY5o     |%YPPZZZZZZZZk8%LZZZZZPPPPgCUZZZZZLTNZPZZPPPSZZZZPSUZZZZZPPPPPSSSSSSSSUU$g$8gg$S%o[[zexJyoZIod6bTLLTbb666ZSZTxLLnn2uoaounPY}[email protected]                              //
//                  [email protected][$]   ~Nqn5uuuooyaaJIe}z]z]]]]]]][]]]}ui25        LUouuu555nn2nnLLLTLTTb6YqFSvYNmSSSSPPPPPPPPZZZZZZZZZZxY~     n8UZZZZZZZ%ZZkkx8ZZZZZZZZZZZZZZZPuLrS6PPZZZZZZZZZZZPPPSPPPPPPPU$PSSUUUUUUUU$FCC$m_        [email protected]%nYxin6YCppg$USSPZNe                              //
//                  [email protected]$g$gYL}l%\   uELLLLLL5uuuuoooyaIIIIJIxIxxxxxIJ/S|       :ELu5522nnnLLLLLTTb6dYFFFg8Y!F;pmSSPSSSSSPPPPZZZZZZZZP}k     .ZbZZZZZZZZZZP$]_8TZZZZZZZZZZZZZ8o6/|ECZZZZZZZZZZZZZZZZPPPPPPPSLl]z}xJyoooooooooSx        \Ytk666YYd666Y6YD%uLTTTLLLLLLLLLooouuuunLLTTTTTT6dbbP%$|]bCpCpg8USSPZ%O;                              //
//                  |@ZSSUUUUUU8gYuz\Cl   :eooxxy6nn255uuoooooooooyyoyyyooz;F:       oZu22nnnnLLLLTTTTb6YYp$$$$Uo[L `6mSSSSSSPPPPPPPPPZPPPLuf     rm8ZZZZZZZZZZLY; L$ZZZZZZZZZZZZdoT; nPPPPPPPPZZZZPPPZZPPZPPPSSSOuj[]}fxxxxxxxxx}~         nJJY66dddd66666UNuLTTTTTTTLLLTTTTLTTTTTkkb6bkk66YddYSDY\uYg$8UUUUSSPPX6                               //
//                  :mZSSUUUU8$ggqTottY`    ._|XZLLLnnn25uuuL2uuuuuuuuooouusFx.   -iL8u2nnLLLLLLLTTTTb66YYqpFg$Utbr  .TESSSSSSSSSSSPPPPPPP]6;     TZPPPPPPPZZZPLT  !PqPZZPPZPPZPLuL` .PgSPPPPPSPPPPPPPPPPPSSSSSSSE-                        .F|LYddY6dYYYYd6PoTbkbbTTTTTTTTTTTTTTTTkbbbbbYYd666YCSX[[email protected]            ...                //
//                   uNPSUU8$$gFFCYk5[odxe}[oTPdLLLLLLLLnnnLL6Tnnn2255uuuuuuuCbkLLLLounLLLLLLLTTTT6bk666YYYCCpgT/p`   .LEUUUUSSSSSSSSSSSS$}T     ,ZCSSSSSPPPPP$Y[   T6PPPPPPPPSu5u.  rOSSSSSSSSSSSSSSSSSSSSSUUU8U%LLLLLLLnLnnnnnnnT[       rkr6YYY6dYdYYYd6uT6bb66b6kTTTTTbkkkkbkb66666dYdddYdYq8T/[LFFFFg$88UUUPmPUUUSSSPPPPZZZ%O~               //
//                   `CESUU88$$FpCqqdbTLTdbTTTTTTTTTLLLLLLLusL8Lnnnnnn225255nnnn552nLLLLLLLLLTTT6ddqk66ddYYqqCpx[L     .L%UUUUUUUSUUUSSSS55j     sEpSSSSSSSSSSu6_   jZUSSSSSS8yLz    TZUSSSSSSSSSSSUUUUUUUUU8UU$gFF$g$gggppppFFFFCma       TfoYYYYdddYddYddk6666d6666b6T5u5u55n252nL66ddd6dYqqCF$6\udpgFFgg8UUUUUSSPPPPPPPZZZZZZEZ.               //
//                    -dXSU8$ggFFFFpqCYYddd66bkTTkTTTTLLk6ojLPESLnLnnnnnnnnnLLLLLLLLLLLLLLLTTTTbL[[TbddYYCpqpCF|6i      .L%UU88UUUUUUSSSUjY:     TSUSSSUSSSSSULT    `FyoooooajTv    ,ZgUUUUUUUUUUUUU88UUUUU8$$$ggg$gg$$g$FCpCqYYYCm"      :C|Ld6ddY6b6666ddd6d666666ddUCJIJJJIIIIJ|IYddYqqYqCCpCpUanYg8$$8$8U8UUSSSSSPPPPPPPZZZZNu                //
//                      |ZXS8gFFFpFCCqqYddd666bkkkkTk6CY2[xgl :o%S6LLLLLLLLLLLLLLLLLTTTkTTTk6CkIiubTdYYqqqCpFFn/b         e%$UU8UUUUUUUU6aL     ;%qUSSSSSSSSSbgv     "f}fxIJJ[:     [EUUUUU88$88888$$$$$$$$ggggFFggpFggggpCqYqYYdZk       ]o[dd66666bTbb6666bb6kkb666gX!         qtcddYqCqqdYCCCpCkdF$gF888UUUUUSSSSSSSPPPPPPPPZN~                //
//                       .|$EPSU$$gFpCqYddY666666dYpYLocyLI:    :oPZ66TTTTLTLTTTTTTTTTkbYqp65[[email protected]          f%$8UUUUUUUUUJbi     f%UUUUUUUUUSUop,                    6S88U$$$$gg$$$$$$gFFFppCppppppppppFpCqYYYdY6qNl       Tt2kkkkTTTTTLTTTkkkkbTkTbbYOj          ZevYYYqqqYqqqCpppFFFF$$8UUUUUUSSSSSSSPPPPPPPPP%8                 //
//                          ~xTPFL6$U88$gg$FFFgYLnozsJnuj:        .i2Ydn2TqpqqqYYYqCFpkLozlz5yz"iNYqqqqqqqqqY6/6/           eEpCCqCCCCCYjC.     68CCCCCCppppYLT                    ~EdYYYYYYYd6666d666bbkkTTkTTTTkkTTTbkTTTLLLLLY%-      "6tLnu5nn5ooouunnnLLLLLLLLLEu           LerTTbkk6666666dYYYYYqYqqCCppFggggg$$$8$$$$88UNJ                 //
//                             :v[zy2noeIJJx}}jzIoyx}r-              `|j[[aunuxz}}z[eyofax}r_   -oyexef}z][[[[ey             [2JJIxef}z]u}      eu[[[[[[[[[[[n/                    iT[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[L|       iSu5uuuuuuuuuuuuuuuu55uu55ul.           zqn555255555555555555uuu55uuuuuuuuuuuuuuuuuuoyj`                 //
//                                  -"iis}xef[ri",                         .;!iirtiii"_.           .....                       .......                                                                                                    ,;;;;;;;;;;;;;;;;;;;;;;;_.              `____________::::::::::::::::::::::::::::::.                    //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GNMTLE is ERC1155Creator {
    constructor() ERC1155Creator("GUN METAL - EDITIONS", "GNMTLE") {}
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