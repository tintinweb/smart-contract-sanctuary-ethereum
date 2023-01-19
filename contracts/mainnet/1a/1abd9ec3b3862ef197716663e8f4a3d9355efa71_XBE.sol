// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BONSAI EDITIONS
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                             //
//                                                                                                                                                             //
//                .?!;#O'./1 ILq{1l.J&? ^},*M,`}^<dz. uo):u;                      'Zd,}#c`}]'u*- .;' ,mw":l'fk}                                 ?br'-1iqdaM    //
//                ,mk+0}.:&q`[n(vLI.C%] /W/.'.-h{+aX. }1^                          >['lx},Xb+ItI <8O `]_,c#/'`                                  ^!".cm!l~wk    //
//                 <}^   ,Wq!hMmCX^`L8? xWI'w/|#r<O/ ",.                                 '|Xi+bL:{8h >%p':_,                                        _[;LW-.    //
//                        `'!k&Jli l_;..'" ]%v'>'   "cY;                                     t#dI`?I ;0J"                                             :pB}:    //
//                           '^.  'Yb< Xk: Ua^ `?>. <0u,                                     }mr^                                                     ^vO[U    //
//                                ,Jr^ q$;     !MO,                                                                      .,^.^                            .    //
//                                 '.  0M: zO. ."'                                                                    I  iMC[Z>                                //
//                                         #M"                                                                        *] !#O_c!                                //
//                                         (h!                                                                        &L ^`'^                                  //
//                                                                                     "l^                            Y_;8dxd~"+I                              //
//                                                                                    `xMt                           ', I8m}Oi{h|";`               '{~.        //
//     .^.                                                                            ,z&j  !mr"                     0B,I8L^}|![Ic%).    ``     :zn>ZLI,'      //
//     zW{                                                    .. ,uX.                 ^nk]  !qw!                     qB( '<1bQlvrY8|''  'Wa'  -QjmUIUc}b{.     //
//     0MfWU ^^                                               hd.:Lbl                    {ht-dv,                     ]#" i&#WJ-wYl^'c&_ ,%q  .{bnJx^;^.`.      //
//     "lnBQ!Qz":^                                            hh';0h_.<}"       .' `va{  (#f>ci                     `  *a]Mc''?bXYb-Y%+]rX>~*j}or[xtku>d1}0    //
//     ["~*mif}1)`                                         :. ,; "xk-^no}       n8i^JMt:+jMn^                      z%?.%#{oj  ~mrX#[LB+qB! _#u<n>rwvhu[kr/h    //
//    >8_,;'   .'!:   !'                                  <k(.    .`..t#) `nj"  }M>"0#jraUm/.+wc"                  L8~;Bh_d?     v#[^,.p8;vn`.^tUcm1v][kuI<    //
//    '~_8dItp] ~mCI ]Wx;a0                               ]ov' +p^<ou'jo} iqal ^Q( "O*|j*(   f#Y,                  kB[l%O        l_"   l~.Mw;JL0O<I'  <bJ<0    //
//      >&L"nh} >0Ql ]Wf[@c'1f                         ici]*n. fa^`<!:I>^ ipkI I#Q ^cb>-X-   [ht`                  [email protected]{;8c                .MQIdLnL;    ^0U1%    //
//      .:`'<]^ .;:.  " I&Yi&C >0f l:               +{^(h_,C). c*] .1k}   lqw; <WQ      >fi./0>  .m*l          _C+.*@} '                  i,!hv^,        ^+    //
//                         +8z ]a|,CLI             ^nQlitl     _X;  l{;lcu>0al IWw  ^fXIf&f'UM~  [email protected]!          [af`*@)                      ,/<                //
//                         "{i .`.1oc,.         ;~ ?bJ:                +pw>l+` lWp  :Qb1v%r.i_^   O%I>#L       nWf`m%]                                         //
//                                ix~'xi;.     ;wQ.1#z^                iZq< i[`I#O  ;wh)u&/        " IMp ._(,  uWt`:{'                                         //
//                                   ^i:h1.q"  !*J.;}+.                ._{: v*> ..  "zZi?c<          IWp "nq_  v&{.                                            //
//                                     "rII&'  `<:                          ro> |&).+f;              `}] :Xm<  u#+                                             //
//                                        ;U.                               i(" q%/^Jo[                  :zOi   .                                              //
//                                                                          ,dL'xh>']n;                   ,;                                                   //
//                                                                         "1oL`  '^)?                                                                         //
//                                                                       ^i)bt"LU'odMm_,                                                                       //
//                                                                       [bO#j`do:8ZYZd-I:                                                                     //
//                                                                    ;Xcc#JaU"k8,+`"zm+xt                                                                     //
//                                                                 'l!>OhLanl^,#B_na}Ownd] ?(,                                                                 //
//                                                                 !db{U&/>>i^^a%IXo!`inc^`cu,"`                                                               //
//                                                                 ipWxv&f'}ot''^ .^      >Q)`YY,                                                              //
//                           ' lJn_t![I                          '}wQ8x^<|>(#c^            '.-hnxj'                                                            //
//                          ibr-*Xz%f0?;[`                      ,_rozZ['?pv,"`               -wtkq` l[`                                                        //
//                       ~c .:",/tX8{  Ld,'                    'n*zMt"cO)0JI                   )*). |W( ^+;.`'^' ,.'['                                         //
//                       ZW,l1 lx]^,`  I`-W.                   .?WYr},zb-                      ;}`  v#< ?%X/Wnzn,w{:*?                                         //
//                      I!(,wq,1%mmrL}   dk                    m/Mw'?wmh]                           wo:'|MncoOaflp["of    :|+                   '](,           //
//                   r#i8C .~|^(&qp|       &^                 ^Wc  ^xk]                             mb ;mq~zJ!l,   ?M? WY ~WO'                  :Ym~           //
//              ^]! .wWi&J     ',^        'W!                 :ML)*(nh]                                 ..         j&< B*'~#Q'}ar`           ~c"!0Zvx<},       //
//              [dj` -).                   ` 'Ud'     >)I  .Y, ''?o};+^                                            j&~ %*'~MQ'}#x'        ^ZIrwlIJX1(xd+-`     //
//        "t(lUr1bx,C}'                      ^&b{Y`   n81. -#- 'n,'                                                [W[ %o'lQc.{*xxo('     [#(Cwi     /kxqI     //
//     1ZbYaC}oj^>;xMc^                      `dcXm>)zivW]..)W- -a_                                                 >#j Bo.    [hxzW|'     rM}tc,     .`1k!     //
//     "0O]Mz?L/1v)m('                         ;OZ]m8xvQij*_;. u#-                                                 .<^ Bb     .,^v8(''r_  J#i          [o_     //
//       .';^ "z8&Zd+                           ^:[#w<l>`U8_  :"!'                                                     %Q        z%1.l*Y  qo,          iw[.    //
//     :c+Lt/J?jz<'.                              ]bx'c#]ZM> >%x                                                       -<        Xo- l#Y  wp'                  //
//     )8J#Lmb-                                      ^Yk+1]` l8U                                                                 ..  _MU  ..                   //
//     _hzMr{zl                                      ^YQl  ;u;/_                                                                     f8/                       //
//       .^.                                          .    [*l                                                                       -0l                       //
//                                                     ~m{'/W>      '.                                                                                         //
//                                                     1o/'f&<[/   +oc                                                                                         //
//                                                     }o|'t&(wz ^+u8c.                                                                                        //
//                                                     (o/' !"hv`xbX8v}Y<               `](;                                                                   //
//                                                  l-">Y[':>^MO;kZvWnx%v,.~i.       .`';Ud_                                                                   //
//                                                  )Z+    0%;'`I#ZxornBx`lqC,       -8d(Ud_..                                                                 //
//                                                '"/k[!pt"qM,  lMQ  '[ni ~pL:>+.  ;z{&b(Yp100I                    `'                                          //
//                                                ]U}i`?hn^I, +`'+I    "?i?dL>hMI  +WC*Z?JL]0LIII.         .'      kC'                                         //
//                                                10> '_J{`!^,&[  '/w! -px1m{<#&; .[%U''   <wYIOw, :      ^no)    'oU' xI                                      //
//                                             ^i'(O~ ]O_ {o1/B[  ,Cpi ?dx^  ~*d^ii1&x     iY1,mo:;%-     :Yd]  nZ>ot.'8z '^                                   //
//                                            'tm, `[[nh- rW}to>  :0w; <mx`  +#/<Ba>X;        ^Za:?BL .II.;Uq_ .0U,". "8Llkz                                   //
//                                            "mp, :zwm*-'f<.       .        iO<{Bm            .. t$x iBq":Ym+ "Zc" . ,%Q<Mu                                   //
//                                       .l  .!!}. <ZQ<;'_h<.w]                 [M/               [email protected] l8Z  ;I  :mQ: kL'av+Wzl); .'                             //
//                                       _8_h_a.   <0v^-+n#<-8f                                   iu  !%Z      'Uz, ok  'j&z?h| un,                            //
//                                    .Q{U%#%[a' +u:   zx,^!f)"                                       !BZ           X}  `]` ?#jILn,  'bl                       //
//                                    :dQ".#8'. `fd_ 'xx;  Qh"                                        .,"               _d' ]&v-dn"  I#]  `                    //
//                                    ,dC^ &%{  ^jk] _dt.  LM;                                                         .|b" .'.<wX;}J}#c hC   ^xJ`  -b(,w0'    //
//                                 "1l'qL" >;+p' .'  1*/. j)`                                                           >Y.;JU.>ZXIXM<"'"&0   >wU",'n8vlqp`    //
//                                 [h/` L). 'Y*I;1`  .^' "boI                                                              ."^ .;,.YW<  'Wa:cr+dx>QxLBf;pk`    //
//                              .. ]k/`;hv'  ;c^/0[d0l;)l"dQ"                                                                 'x#1.Y&~/&~:I;az.'.}*vU8CI-|'    //
//                {q]. "^ 'uq; <pQI,/> laz'rw  "X0(8X'jM[ :"nc                                                                :YOi vW-OBI  +#x+Z/1Wcli;C~      //
//     ."  ''     {of`"Mo .?f. -Mz. '. Ihm'z&.  `"-U_ '^.  `kt                                                                !}; x0> Z%; !>O]]#c+C/c0(kj`     //
//     f&rIpU.![; `>" >WU     .?or (h?  ," u&+    ..    "fl>o~                                                                /*)'Ubi [email protected];r&l .1orit1ZOtaC^     //
//     w#iloq-U%x^.jk[`i!<" IwZlII rW] '-' .I',wX.      z8-`>.                                                               'fWt,Jc, ch^qW:,ucwr?Yxdd}bd,     //
//     ,; '>_iU8r`^0B)' m$w _B0+J/ `I` )M;   .]&L.+pX^  ",.                                                                  .?{`   .f/' po"_oj  }mYk8})|`     //
//      '.   .<|i 'C%{..h$J.]Wn-ax!JZ> ")`   .(Q^ -hJ"                                                                            {[]oo^ Yv`1*/?YYhtnm_.;`     //
//     `pX    _z+ ./JI  Q$b'I(:>mc/#%]   [vI'UJ. ..:,                                                                            ~qQC&W,   ')*jnbrn-.{Y~O(.    //
//     ,o0 lji}aQ> ^tr^ x$h,.i_'.'<wo+   d%)^%o^<aX'                                                                             _ppp%vj] L)(*nXh{  .Uofb).    //
//     +%J.]Wz(*#) 'm&; ,{f]Ipa/.]c)!+}" xw^I8h^[%J'                                                                              I:^!IMql8dl_<Uarnx!0#ua(.    //
//     +8C,}%X)*#1 `Qh,  fBY;q8J.{zi YW+    +%k`(&u                                                                              <wdi ;WQ<Bo: '~((pQ>|r{h[.    //
//                                                                                                                                                             //
//                                                                                                                                                             //
//                                                                                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract XBE is ERC1155Creator {
    constructor() ERC1155Creator("BONSAI EDITIONS", "XBE") {}
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