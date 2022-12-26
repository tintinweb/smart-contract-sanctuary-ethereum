// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Sylphy's Appreciation
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    WZVuuX1XZk+wuuuXZuuuuuuuuuuuuuXXuuuXXuuuZuuZZuuuuuuuzuzzzzzXXzvvzvvvvvrvrvrrrrrrttttttllllltlllzOzz1vXP``````(-_dH%.`.>-    //
//    HS:_?7XZuCwuuuuuuuuuuXXuuuuuuXXZuXXUuZZuuZuuuuuuuuuzuuuXXXwwwwAwwwwwzvvrrrrrrrtrrrrtltttllllOOz===zO=zI-+zu+..+<?>.`-r_.    //
//    ?:(JuXZZuXuuZZuuuXXuZXuuuuuXXuXXWuuXuZuZuuuuuuuuXXXHMMMMMMMMMMMMMMMMMMHHmmAyrtrtttttOtllllll==lzOz==zz=Ozv!_UHm+_``.v_-(    //
//    wXXZuuXZZZZZZZZuXSXZuuXXuuZuuXXZZuXSuZuZZZXQQ9ZttXHWWUXZZuuVOOwwrZVUwzltOVWMMHmmAtttttlttOll======1=?zOzZ`..`?Ul+(+wc!_`    //
//    kZuuuuWZXXZuZuuXXuXUuXXuXZuXXXXXZuZZZuXQqMHMMrtOvrwXrrrrrwwXwz???1zOOOwwOllwXZOOVWHZtttllllll=====??zv7?C+--.-?UOv!?1-v<    //
//    [email protected]z??1llOtlOwzlOwllllllzXAOlll=z===?==zwwO=JHB=_<<?i  (%..    //
//    UUWkuuuuuuuuuXZuXXXZUuZuuXZuuuuuuXXHHHgMMHuX0OXtllllltOrOllllllllzOz====zlllOOzll==lzOlzUHszl========ztOXzC``` _ j>!<o<:    //
//    uuuuZuZZXuuuuZXXXuXXuXuuXuuuuuuXX80wXUXX0CzwIzZ1>>1<>>>1lz=llll====zz=?==?=z<?7wv=<<?<<~~?OUWAzllll==OvtwW:```.>(H;` ?<<    //
//    HXXkXZXyZXWZXWZWSXkuuuuXuuuuuuXH0twXwrvXI>>l<+rz+>?>>>>>1z===zOz???<<<<!~``  ```?_ ``` ~-``?0wUWAz==l==llC`` .WHHUU>_~<<    //
//    uZW%(NdyuXZuZuuXuXuuuuuuuuuZXW9ttwOtttw0llzr<;zzll??>>;>>1z??<<<<~.```-_````` .`` ~ ````_~ `_  ?7Wmsz===z-.+W#~wkXXZ-``_    //
//    uXf (>vWXWXXWuWSXWuZuuuuuuXdH0ttOlllllwzlllt1+zI==?<>;;;<<?>`````` _.``._.```` _```` <<<<(~_.<```(UXHmzzwXXMMMh(WWWR_``.    //
//    Xf__(<(yZWXXZZZuZuuuuuuuuXH#ZtOO====1zI1===t==1l???<<~```_-__````. .`` ``__```` _ ````_-`(_`` _-.`(_?OTWkuuWHMWRwyZXo...    //
//    $_((Z;(ZZUZXuuuuUXXuuzuuXM#OtOOl==1?>=<z===lz??z<<~.`.``. _.  ```````... `-_ `.~__.```` - _``````- ~.-1-?TuuWMHHkXyZXkXW    //
//    .++zz;dZZXXuuuuXXzuuuzXXWH0llOllz??>+v:j===zv<<<<```.`.```__`_ `_.`````` .`.<._``` -```` _ _. ```._.(- <_` ?OWMHgRWXWHyy    //
//    zzOO<+XyZXyuuuzuZzXzzXWSW0lllllllllzjz(jz?<<!-_._`.``` -`. _``_.` _``````` .jm,`. ...`.`` _ _ ~1x!~~_-_.(.`` [email protected]    //
//    ??z1jHWyZXWXZuuuZuWzzXSXSzOwll=l=lllzZ=zI!  _`_-  ```.` -``-<.._-` _.````` (HMHgf^``._ _____``.-1_``` _.`<-```?MggHyVWyy    //
//    1O1dMNVyZZyZuZuuZupXXSuXC1=Zl=ll=z=lOI<`~ ``_. _`..```` _...j+_.<-.._-`.`.J4dMH$ ````__``.`__`...1-. ``_ .O1-.`[email protected]    //
//    I=dWWHVyZZZZuZuuuzXXHuwk=zzI=====l==Z~.`__.` _`-__(<....(<..(Mm-.?+_.-<-.1dB=`<w{ ``` _```.`_  _ `_<<<-(<-(< _~.UHgHZVyZ    //
//    1dWyWWyZZXuuzuuzzzdHSvwIllt<1==??=v<I_.__<```(_._<~<<-((jI_-,K?9n-(G-~(vuW=`.` (O-`.``__````..` ~ ```` <-`._~_ ~(<?WXyZZ    //
//    WWVyWWZZuWuuXzuzuXWHwruI==t<::<<?z>~z_`_ +-.` <_._<:1+>?1C;<.S_._7n(4gXH91-```` <n.``` ~.```` _` _ ````.1-..` _ (+~(SZZZ    //
//    yfyyZZuZuuuzzzzuzXMSrrXv==t;::(<(<~.z_(_`(I+++(O,~(<:<>>>1;+>I_.`..?wHNI<~~<-.``(jo ``.._..```. `-_..__`(~~<<++;<zs_dXZu    //
//    ZWWZuuZuXXuuXzzzzXM0ltV=?1O::<<:<__(d+++-(zz????vA-<:::::<>;1I_`..`.-?zU+_~~:<<..>z> .` _` .```.``(_```-````.zl.._><zXuu    //
//    ZZWkuXXuuuzzzvrvwWWZllI???l:<<:(:(>+WI=zzltw+>>;<O01+(::::<;jI ..(+&zzZ0dWe---((++1w-```__ ````  ` >.`.```` _(Wx..__?Ruu    //
//    UVCz1zWuXvzzzwrrdHXZ==l????(<:<z>>?1HR=zZ1+Ok<;;;;vo<<<+++jxdUYT1<:<~~~~~_?Ts-_~<;<10_``._ _``.`_``(_._``` . +vHo-<__duZ    //
//    +==?=uSXuvzzzvrw0rzZ==l??1I+<:<Xc>>jM#OzI;;+XG<::::jz<<<<<(I(I;<<~~~~~~~~~~_<?O-___<jl ` (._````  `.<_``` .`(>(XWU0zzWZZ    //
//    ===uy0vvzzvzXzwZzfjz<<v:<jI=1+=Z>>;j#Vz>z>;;?Izx::~:1x::~_(S(<~~~~~~~~~~~~~~~~~(11-(=X-..(__```. .`.<_` .~`.v_(uI.-(<4uz    //
//    =zvTMkvvvXwzzXkId$<;<(O;;jZ1=?<X2;<dRzO<+o<::jz+I+:~~1<::_dZo<~~~~~~~~~~~__(_:_(d#0wwdo  j<_``.``.-`-z+<``.+~.(Xw-._<(zz    //
//    dWWWdHkvzZXwdbK(W6>:::z<1zZ+<><WI;;d0=Oc<d<:::1>;<1+_:1<:(V>jz_~~~~_((<<(+gHMHMMMMNNMMN+(zc_..``` _` j> `.(>` +(XX&(1wzv    //
//    yZZZWHWklltZXk$jH0<::_jz?zI<;;(WI;;dZugkcdN+:::1<:::?<_(1dC::1>~~(+<;+jgMMMMMMMMMMMNNNMeJJkv!```` .``({ ((y_..< wXkdkXvv    //
//    ZZZZWWWWkztlwU1VWI+1+?zI?1O:::(Ow(+d9C<~1<W6<::~<_~::::j++<~~:+++<;jdMMMMMMXXwWMHNzwTMNNMU'````.``.`. wz+ZS<-+<(dHkWHrrr    //
//    ZZZX6dHZZWylzZdwuI+v<<+w>?z<::(zdv<w<~~~~~(111_~~____::dDzv11<+zz<[email protected]?zdNM$~````.```..``(o___---(_dMXHSrrr    //
//    ZyWXWWZZZSWHdwHHH>(v:~~z<>1<::(WS<(O~~~~~~<<<;+1-~<._.(0I>~~~~~~:(dY><(HM9UXWW9UUMD~(dBW<`.``.````-.``.Ozv<~(;!-dMXHwrtO    //
//    ZZZZZXXWUUUWNWHWHI_<~:~(I;+><(JC+I:1~~~~~~~_1_::(<+(XA-t>~~~~~~~~(C~:~(dDlz<?V<<zXS<<z;j:````.``.`..`. +>_._<~.(dMHStttt    //
//    ZuuZZXWXWWXXMMkfHI_<:~~~I;><::j<;1<+<(((;<<<1O+(_:~?<~?<~~~~~~~~~~~~~~~(Sz1_(+<++z<;<;;+<`.`._.``..````(I=z<__(Z<X.?Oltt    //
//    uuuuuuuUWkXWXHHkWz_(<:~~(z;<<:z<:<+<GgggmQHHmme+<<<~~~~~~~~~~~~~~~~:~:::(TC::;:;;;;<:;;+~ `` _`.``.``...zzv::+1I<z<IJwlO    //
//    uuuuuuuuuwXSW0XWNI:_<<_:_z+;+<w++ugmdMMMMMMMqWWWm+~~~~~~~~~~~~~~~~~::~::::::;;>;;>>;;;;z__``._.``  ```` jI;<x=?z<(r(w?XV    //
//    uuuuuuuuzzWXHvXWNz>_<;;:_(O>;zkAgH##[email protected]_~~~~~~~___`__~~~~::~::::;;;;;;;;;;;+I=<-`(_```-_```__(yzz=v~z~(R+wl ?    //
//    uuuuuuzuzdSXKvXWNz<_(;;::(O<;[email protected]@@HWHXWHH<~~~~~_````. _~~:~~::~::::;;:;;;;;;;juk<_.+_..`~ ``.(_ uz?=!`__ dWU$-`    //
//    uuuuuzzzzXuWRvXWNz><_<::::jI;zpWMMM$?><[email protected]>z$_~~~~-`..._~~~~:~~~~:~::::::::::::+Od#:<(>_`` _```` <`.I??_` _.(WQk-`    //
//    uzuzzzzzzkuWkwydHI><_+<::;+w<zHWMMNz>;::?WOO<:(<<::~~~~~~__~~~~~~~~:~~:~~~~~~:~::~::(01JD((v;<``._```._j{ jz?_``__.WvVI     //
//    uzzzzzzzwSZXRzZdHI>;<(z<;;;(IdHMBHqHe<:::?WHy<::::~:~~~~~~~~~~~~~~~~~~~~~~~:~~~~~:(?<z>j>:Jv;<.._ ````~(R.(I?_`` _ dI<O_    //
//    zzuzzzzvwkw<WuZdHI;;:_1z::::1OMMHz<++1<<(<+v>;::::~:~~~~~~~~~~~~~~~~~~~~~~~~:~~:~~~(<:;z<j$;;<_ _```` _(H[ j1<`.`__($_+O    //
//    zzzzzzvvwkwczuXdHX;;:<(z+:::(jdWWNs>;;+>;<;;;;:::~:~~:~~~~~~~~~~~~~~~~~~~~~~~~~~~~(<::+>+WI<;:_-`````._.WN-(I< ```_.C  j    //
//    zzzzzvvrrXXk(XuK<w>;::_?l+(::<OzzXMm<;;>;;;;::::~:~~~~~~~~~~~~~~~(((+u+dk<~~~~~~_?>~~(?J1WI?<;__```` _  dWI.1<_`.` -(..d    //
//    zzzzvvrrrrZW<jXK<dI;::::+lz+::(XzX0ZHx;;;;;::::~:~~:~~~~~~~~_(+xrOOOv11zX>~~~~~~~~~~(+<_(Hv>>><_``.`._`.(XX>(<~.`.`_(I<?    //
//    zzzvvvvrrrtd9C(I-d0<;::::1tlz+:jXHvlzWs;::::::~:~~:~~~~~~~(gKwVlvz1<>>>;z<~~~~~~~~-(<!.-dMI>;+<```` (<``(Orv-<__``. .1<<    //
//    vvvvrrrvrOZ:(wX3 O+O;:::::+tO=1zd#O=dHWR_:~~~~~~~~~~~~~~~~?HHI1>>>>;>>;+>~~~~~~_(<<<_.-dMHI>;;>` _`.z>` (ltOI:___```_(z>    //
//    vvvrvrvrrU&J<;+! j;1z<::;::?====wNzOHkwdN-~~~~~~~~~~~~~~~~~_7O+>;;;;;;<<~~~~~__~:<~.`.dMHHR;>><.._.+zI` j=Otwz_ _.`` _O+    //
//    vrvrrvrrrrOUk+< `(>;1<:;;;1(<1==zWUAI=OVXN+:~~~~~~~~~~~~~~~~~~~<<<<<<~~~~~~~~~~~_`` (UMUHHb;;>_._ (=wI`.+=zOzZ<` _``` (I    //
//    rrrrrrrrrrtrOX{``(<;;1;:;;jNx:uz=VuZUXszlZTk+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~_`..Z1dStUHH<>;<~ (?zu>`.O=zrlwl``-_``` z    //
//    vrvrrrrrrrrrtX:``(z;;;;<;;;WHm+?XHuI=llOwUUOUe-._~~~~~~~~~~~~~~~~~~~~~~~~~~~~~_ .vC?>zZtZWww<+:.(??wI``.ZlztlOl ``__```_    //
//    rrrrrrrrrtttzC (.(z>;;;z2;;zZZWmx4XI====zzZllzUn..__~~~~~~~~~~~~~~~~~~~~~~~~_..dZ1??>zZttXkwO>-<>>zV~``-Z=lIlZjr`` ~ ```    //
//    rrrrrrrrtttOZ!.z_ 1+;>+zOz>(XuuXHNAO==llzvOl==zvdHk+--__~~~~~~~~~~~~~~~~~~~.(uSI?????dAwwwSZi(?>>zC````(Ill=v~dW-`` _```    //
//    rrrrrrttttlz> (O<`(??>+rjHs<OXzzXKvXUXwzwOlzllwOdHOllOOww&(--_~~~~~~~~~~~~(dUZI??????wOrrrsdHv?+v:``.``(Ilv!_(WXn.``--``    //
//    rrrrttttlv>-_ (O<[email protected]+wvvXSrrrrrtrOlllzrtXIlllllll=OdMHWHA+--_~~((WSO1????????zrrwXMXHKzC`````` z<~-..XpuWl `._ `    //
//    rttrtttz(>(k  jO?<`(z?td#0twOzXvXOrrrrrwZlllzrOw0lllllll=zOddHWM0rrZUSdW0I1?????????>1rwUOWHX#!```.````.(!_(VyVuXW-.` _`    //
//    rttttOdXI(W$  jtz>_.1jdHOlllzwxXktrrtrwZll=zrOzZlllllll==Ij0wWWMZtrrrrOv??????????>>>+vzOOVW=```.```` _<_.uVVVVuwwS-``_-    //
//    ttwZ=<<<z+z>_ jI?>>_(OW0lllltwHOZwtttwZll=zrOltlllllll=lv>dVdI=XZttllz???????????>+z1zC??jC~```````....-jpVyyyyuzrXk_` _    //
//    Z=<-((+gMMD_~`(I>>>><(0llllldWtOZrrOwOtOwXrOlOlllllll=1v<jZw$=1kOllz?????????>>>>+1ZC??1v!```````` . -&kzWyVyyy0zrrZn.`     //
//    gWKI??dHZXI(_``(z>>>jHSwllld0tOZtOwOOOwuvOtlOOlllll==zI<<[email protected]??????????>?>+zvC?>1uy!.``.`..```.dHHKvXyyyyy0vrrvwn.`    //
//    3.?A=1XWyXIJ[`` 1+>jWZttwXX6tOZtwZllzw0ZtllOOlllllllzI;:jwZzwXW$?????????>?>?>+zC+?jdWX!..._-(<- .JOWWWHwwZZyyykvOrrrds.    //
//     (.-7HK><?<dS-`` ?uWSAU0OtOSOzwZllwX0ZllltwOlllllllOI;;JwXzvrX6??>>?>>?>>?>>?1Xkz+wZvZ>_::(>;;;;(zlzXuuX0wZZZZZ0rwtrrrXn    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SYLA is ERC1155Creator {
    constructor() ERC1155Creator("Sylphy's Appreciation", "SYLA") {}
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