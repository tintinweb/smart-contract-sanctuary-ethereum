// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: AMATSU OTOME
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//                .J"`````  .......(7<~:~:~~~~_~___~:~:(J:+===1?1dV1>~~~~~~~_-_<._....-?1-:~:::~____-~.                           //
//              .Y!```` `..>~_?=--=:~~~~_.~__~._~:~:~(J<_<?>><<jZ<(C~~~~~~~~~~_..?+--....._<-~::___.___?-                         //
//           .-= ````  `J` ``````(o~...._-??,_:~:~:(<~_:(;<<_(jZ<(Z~~~:~~:~~:~~_...(1_.-...__(1-~:-  ` `.(-                       //
//         .(=```    `  %``````  ` 6~.(/!``.=?+~:(J!_~:~~_.._zZ<_J<_~~:_~j+~~~~~~-..._<_-  .__~_<-~:_.```  ?,                     //
//        .=`` .__ ```.()`````    `.[J` ``````j(J!__:~__..._Jd!!  .~::~~<(<O-~~~~~j,-_.__. `  <-~_?-___.`` `-4.                   //
//      .C ` .~~_   .!` t` `````` `.P `  ```  .r__::~_.....Jw{`_j>~~:~~~~iI;?o.....1+~~_.<- ``  1.:__-.  ``` _?&           ..     //
//    .J^` .~~__(/(J-  _z.`````````(]```  ````.~:~~~~...~.(w>  (C~~~~~:~~~1;;?I_...(+I~~..(.```` ?v+:_.< _.``___I       ..$_?7    //
//    <` ..~~__J!(?``-?1.?- ````.  ,$ ```````.C::~~~..~._(S>. (D{_:_~~~~~~_>;;:1_~..<;1_~..?,```` (=z-``(. <_.(---.    .:_._~~    //
//    ` -~...(=..j_```````_7-..    G' ```` .v<:~~~~..~._(dI! -f+  ~_~(~..~_(<;:_1__._z;1~~~_(+```` j=z1.` i`.--(- .,   ,.~:_~~    //
//    .J~~~.(!..._I``.``....`?,   <!_.`..Z??!`J~~~..~__:jX{` J<:`.~~_d-...(-1<;:_<;__(<<1__~<(i```` 1z?<-``1` ~~j- .;...1::~~~    //
//    c~~~_/..~.._(UZ!.(^...?-.-+ux-_(I=  ```(~~~..__::(Sf``.>+: ~~~:d{___(I?c;:_.;;_~I;?2(<:<(l` ``(Oz1_i `~```.t. ,,``.z_:~~    //
//    ~~~(2~...-(ZC~l..`......_1?UfJ^<(.` ..v:~~.~_:~(JXd!`.C;j`_::~(zr+;;;Z<1(;:_<;;_(<<j<(<<~jl``` (1?v/<`.l.``(<. j,`.,7G.:    //
//    ~:(2_~.(jdf<~~~(<(.-(JJi-.(dV(-?<?=!~~_~.(-(:~(XwZf.`c;>2.::~:(+b>>?>I$(_;;<.>><(2;(r~1_` Il```-1zlx+>`(?i._<..`j; (` `?    //
//    ~(d(~_JQSV~~~_~:(v0OI~-J:~` `_~~~~~~_<_(v!?~1JSvrO\`.>;j%_:~::j<k====tO~:(;;_<>><b;_1`.;``,x{ ` ((zO_1- C_O,(..  X..i.      //
//    (O61(XXU>~~:((J61<<(-?<_ `` ` -~~(?<<-_J:```.uZ=!?I Z;>d`` _~($:01==1jz<: ;;<(>?1w<<(.`1```C?,`` ~(zc~:.>_1dz_._ _I 1._.    //
//    ZJkuSXC~~~:(d6z<<_~-~/`````` ~_-<(_```.O. ` (>````(d>;jP```` (~:v(<<~.z{.`(>;(<<`J(;()`,-`.,.1..._~jl_<.>~<J4<.___(` 1.`    //
//    $dSSX3((,((d0>-J!.-(C___~_.-(?<::~1.``` _. ._`` ``.f;<d\```` r.:>````.=) _ <;j:``(<;<t`.]..-[.z.._<(4+(_>~.(O--::~J    7    //
//    XJk?>~!~~(v=(/!.-Jj3~:~:(J7>:::~_ .Ji. .-_._<. ` .X><(X`````.!.;}````.=r`_`(>j:``,<(<I..b...t`(l..1(+I>(<~<_.(1_~(^         //
//    3~_....-+6+>..(zlv>:~(J7<;;:++JJJZ4>`  ___.~<~ Jr(3~`<P..`` r` <\```..=}._`.>J{..J_(;>.(W.~~u..j_.(-(z:(I~__<_.?+)          //
//    .._~.~(9v<<_(=luZ<(JV<;;;;;;;<<:~:z `````. `  ` 1v~...!~~..(``.j{` ..Jj{~~` >j>~~Z._>c.(d..~dvvW[~~l(z__z_~__(i-(t4.        //
//    ..~.(JIz<(+11zOC;+Yj++++++<<<:~~:~?+- ``.v<(...,Z-..df~.~.(SzzdW~ .~(0v.(_``<j<~(%._>{.JJ~..z``.$~~(<1..<l~~___?>1.?l.      //
//    ~-JWWAwZllz++v1z1>>><;<<<:~:~:::::(+wV1<!.J-(~J,0vzXW%~~.(%```(Z` ~~Jv~_/```(+~~(!`_+>.fd.~.2```j_._1?-..(-~~<+_~j-.?>.     //
//    d9Y^..?THI=zvCO+<::::::::::::~:(+wwV<J!...+=_,JV7!(l2~~~(%```.1$..~(f~_J ```(z~:r`._j_(3z~.~r```.r.~_O>...1-:::(<-1_.1.-    //
//    ?,.~..~~_T+__<<?I+::::::~(((JxOOZ6zi7....C_`.Y `` +v~~.(^`.` +d~~(J:~(v````.<2~(!`.(v_J(c.~(>````?/~~~?+_..<?1+:::~t.(<.    //
//    1x1-..~~.~?c~.-._<vXwwUUUVI1?1d3<1/_...?~` (^``` (d>~-J!```?v<=~<~_(?!``.``.j>(%``.+\($<}..J`.````?e_~~?x~_.?&+Cv+(/l.[`    //
//    -+G?1-_.._.?/~~.-._T&c>>>>>>j6jJ^..--<_ ..Y```` (j3~(=`````.<JI1zC:_ ````` ~Z->`.-(z~(;J.~(~ (c.._ R7G.-(n-~_.1?1R?h(.r`    //
//    TUrO,~~<_-._(/~~~_..._?6v1zC7<~..(<_..JwC!```` (J!(C--__:::++I<(C~```..```.J<2`..(+r(3j!-J~-(+H2<<[email protected]_W04G-_._<9:1U L     //
//    <1Ovvo-...~_-(/~~~~~~..(JC7CTC<_:<<=zZC~......(v(v<~~$~_<?1z1(<_~..`.`..`.J(=``--+2_Jw-?!(e7+(MWWHH<~((dX<>?1?i--  _??Tz    //
//    _>OtrXuZw--_.(d+_..~~~(Y:J>~~~~j-+vC>_.....-J7uv++<<<dx<+gXGf-_~<__.(+-(Jo7~``.(v^(v<` .(<dWM#MWBHgMM#"J>::;><<__j?O1K;1    //
//    (JllzduOtwvwOlzZ1+_~_J^(v~.~.(J<?n+~....-(zozCqc(.gMMMpWHnJO_<<ul___.``.````(7<1Z= ```-?QWMBYC-~..(UHhJI((I:;>>><d-1($(-    //
//    J==z>d0zzkOwtOd><:~~+%-Z~~~(>(:<><(?TUSO+7<<:jdMNMMMMHHWWkWWXsf!_<_..-``.```` ``````` ~.WP!:~.1<.~~jdWf7=~:::>_(<z>j O.(    //
//    ??<;>X1vzI1IzXI<:((<d.({.~J~:;>><_._<<<~j,~JWWMM9=  _z?><O+_?TX0&J?=```````.```````.`_.YC,.+++zW:(:(Z4n(-~~::><__([(<(i.    //
//    <<~_(K11z=zdY~_j>~~:J/~<.(t(;;><~_``(` !((WdWMC>;_-.+c(>>>z-~:~(T,```````````````````.z<+dOdC?~Z`` I~($~~~~:;>>.:.I.1-_>    //
//    .`_.jR==lz=_(Z=74x_~:?x~~(r:<>><```_ _..1tdB<Wz>>>jKtd2+z<(p_~~____```.``.````.``   ``d<>?<< <(=`` x-_S~~~::;?=_<.j;-l(.    //
//    ``..13=zC.(v!~~_:?VI<~(1~_b:<;;_ ```(..<.d=!_d><z<?Clz~_1>(D````` ``.`````.``... .~...(!`<__:(j!..J77~V7=<?C+&z>(_(X<_i:    //
//    `` ~(=zC_(O1JzA<:::?1++(1-?o:;;_..```````.!.`(h~___ _._(?!(/```````````.``.`......-_~..__-(<<+j?I-  ~.k:(+Ozv7&vzi-O.:.1    //
//    ``-.=jC(3jCf(vCOTU&<::::~4nJ1;;_..```.__-`` (+(S.~_ __<_-(d-`` .```.`````.`........~__.`.```` `-````..07?!~~~~~?Tx;?1j,.    //
//    `..=z0v==vkn(7<+x0tXs<:::(Ov4w+;_..``.<?;-!`_(v1--<1&<<iJ777"< ``.``````.`......~.~._<_`.`````....```,,_~~~(,_~~~~?u+<j.    //
//     .I=dv==l=ZXc;:dZttrd>::::~O-(zs<_ ``.-._````` `_____'.. `.?<.`````````.`..........~~~?:..````(-  ..`,yV<<<<?3---``_J<f     //
//    J===rIl=l==vR(;?1OttS._:::~~1(:?U+_```````` ..Z=?r```````.\  c?i``````````......  __.. _``...```-?!``.kdx?<(o~(: ```jW`     //
//    ====3Ill=l=zXn_<:<1wwOwUs::~~z::(w< ```.JY=<?<<~.%`````.!`!.__..\````````````.``` -(.`(!`` : :`````.`.WY::(v~-{_```.f\      //
//    ====vwzlllzOl=VG+~;;:<?4ZX_~~(I_~(P_. .Y~..~~~_(=``````(i,!__` 1```````````````` ```` ```` +-'```````,1JJJC:(J:````.W.      //
//    ===llzWylzrOl=llvWWVG++<?T<~~~I..($_(V!...._(dk-. ```````?.,!??```````````````````````````````````.`.3:::::x'``````($_      //
//    =zlllllZUWX9llllzf! _4=7=7u-~~+..(+Y:.....__.  `./7<?i.. ````````````````````````````````````````.`.3::~:+c `````` Zj)      //
//    zllllltOOw0llllls=!?_-.?77G+:_c.(v~~__.`.J_....,~....` _?4G...````````````.`.``.``` ...-````````.`(3:~::+'````````.I-\_     //
//    llllltOO=XZllllzh``.c___```(kw~(d_~_...J0d-...`1_...`..<v  ` .4.`````` ....-((+7777:_~`````````..J<:((J7!````````..S-j`     //
//    lllttO==lvRlllllz+<+] `.n.-71:J7Xh_~~~~(Wyr..``,_... `.zr```   4,``````_!! `.......```````````..WwY=```````````` _ ?+(;     //
//    llllz==zOllZwlll<>;<4.JV>::(>d>:(ZW,~~~~(WX_.``._.``.` ?O ```  `(S,````````````````````````..J=```````````````` (w+(+_O     //
//    Ztv==??zlllllllv>>+<;;0::::<d3::(b:On_~~~_7[ `` {_`.``.<z_``` .-_`C````````````````````` .Z^````````````````` .ZI=l??<(;    //
//    O1?=??jIllllltl?>>v>>jK:::((D:~~:0~:?S-~~~~<.```>.`````.d:``` (r`.$``````````````.`.```.f``````````````````.J6z<1=lz?<.O    //
//    =?=??zSllltlttv>>j?+uf4k&-zK:::~~(:~~?W/~~~(-```(.````` w{````.].J<.``````````..`..`...V````````````````.,?1zz>>>+=l>>_(    //
//    ???=zZlltllltlz>jf!_' J.` -4-:~::(~:~:?k_~~~1_`.,< ````.<:`````.7&-...``````.`.`.`.`.J=\.`````````````.v>  .zk<;;>+=<>:-    //
//    ???zdlllltlllv<+Xl .(^.?&..7?,:~(>~:~~:jn<;<<:...<_``` .:!``````` ?4,....`.``.`.`..Jf!..`.``````````.Z>:~  (Iwx:;;>+?/<-    //
//    ?=zdOllltl=zI<<vb.(h..-.z(1.,7~:<(+J7OJJ?U&+<:___<<...._~: `````````_?T1--...`...XWr..`.`.````````.J3>(:::<;?2W+<;>>=<-~    //
//    1zZIllllz1tZ<(J??z1+67d7<::?s<(JY12~+.(3_<>+7U&(::~~~~~~~~_...`..``````.`.7CwpVVI?=vl..`.``````` .(r<=-<::::;?cW(:<>+=_<    //
//    lIllllz1ztZ<(v??>?>>;:(:((JJTh.(JC~_#=~~_;>>>>>v6+-~~~~~~~~_......``.`..`.``` ?4z???+G--.`..`` .~~~?i==_+++:;><<0::<>+<_    //
//    4zllz1ztwC:(0&&&&zv7T9Xx:::::~:~~~~~O/~(>>>;;;<?>?vn._~~~~~~~~_-.....`.`.`..```.(kUe1zk__.._~~~~~~~~(XCz<<dZ3<<??Zr:<;>_    //
//    __?GJAy0+J"<?1z-~~~~~~(__<<<<~~~~~~~~?x;;;;;;;;;;<??z4x_~~~~~~~~~~.....`..`..`.`.S:?R?dI_~...~.~~~~~~?s<:~;~~~:::d+J-;;<    //
//    <++<1-__._?<___1+?__<UXwuw+_~~~~~~.~~.(W+;;;;;;;;;:<<??7n.~~~~~~~~~~~.._.`.`.....J>;Jf?Xc~~......~~~~~?I~~<<~_ ~_(_(d2:;    //
//    ..__??1J/....__(:``.'     ?n-_~~.~~~~~..?m;:;:;;:::::;<>>1TG._~.~~~~~~~~~-......_d<;;WudW+~~.~....~~~~~(l~_<~~-.+v= _D-(    //
//    ...`..._~_....._?(-r  `.+`. z2_~~.~.~~~~.-W+;;:;;::;;;;;>>>>;?T&J<<~~_~~..~..~.(Z!~:;WslOX-.........~~~~(o~(K4+J!````1_7    //
//    .`..`....(u_~.~.._un.-.C:<<<::~~.~~~.~~~...Tx<;;;;:::::;;;;;+++dk~~((-.~.~.~..~J>~~jYTCllwk_~.......~_(J7^` ._``` ```(_~    //
//    ..`.____:::?,~~.~._jO<:::::::::~~~~~~.~~~~_.(h+;;;;::::+Jzu(IjzWm<c(J3_.~(JJ---d~~JIz<+ttuXn-_.._((,.X~~~ ` __```_ ``(<~    //
//    4,..`.....-_jx-~.~..?O(::::_<:<_.~.~~~..~~~..-4x>>;;;;:d<AJm&Kj0+(GdJiC.._G~::~?Tr<(d9K+wb~~dx_4<~~k(?_~~ `.~_`` : ` d~_    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract AMOT is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

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