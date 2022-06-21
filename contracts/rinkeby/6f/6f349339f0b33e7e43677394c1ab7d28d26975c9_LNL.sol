// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Laura Leonello
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    N8&&&[email protected]&QQQ&0$8$$$8DWbMWHNM54qPhXjhXKAXXhAZqMqAeZPXAee5Zbqq4qbMMWpMGGGG#8&&Q&B&Q&[email protected]@@[email protected]@#    //
//    $0&[email protected]@@@@@@@@@@@@@Q&&&&0$8GGRGD%DGRqWqePqqbAmqeqqqNMpqMpqqpmMbMpmbpmGRGG8%%%00&[email protected]@@@[email protected]@[email protected]@    //
//    &[email protected]@@[email protected]@@QQQ&Q&&B$DDDDGGGRHHGpqpRmppmGpGpGNpGGRHbNRbbbNMpRNGD%#[email protected]@@@@@@@@[email protected]@gggggg    //
//    [email protected]@@@[email protected]@QQQ&&&B$BDDDDWmRpWGNMWMqpWGGNRGGDGGHGRGRNGGGGRpGDDDD%00&&[email protected]@@@@[email protected]@    //
//    &@[email protected]@Q&Q&#&&[email protected]@@@Q&&&&BB&$DDDGWphqq4bbpqmRGHGGGDGGDWWWHRpGqRRNmbpGD&&#0&Q&&&&Q&&QQ&&[email protected]&[email protected]    //
//    &Q0GGbWWqGoqfjf4G0&#0B#&B0088DHN5PPZ4hbqqbqppNMbpNWRN45PabbRepbqqqRGD8$&B##[email protected]    //
//    DG4eqaqqZAXVzTLLcsAG$G8D$%%RGGWah5haqejZqWmqbeqqbAbpmpaZj4qbAebeAqMGGRD#DDGDMpPITT|?=sVuVKGD8&&[email protected]&    //
//    WN4hAe4jZPjwf=c?___YXqNDGGGGq5Pe4joZjIhbZPPqZaPAqhjjjqZ5Aa4eqAqa4pppqHGRNppGXw?_"~_)Tc}sz=oXjGD&[email protected]&    //
//    AZIhqqqXjXKjw}wc)_~__)za4p4jAknzs=s}uzzk}sunVVkIXIXfowVIjXIhIqP555qqbqW4PIVc_,,^__vsVfnoVjIqA4qpD&Q0    //
//    AjA4qphjjXXhKoVnT|__>>_)sVV=Y))_))__)))))LY==s=ukVVs}xzzVszk}wfjjAPhh5PIk|~^",""c?LVIhaqbe5apqhIpD0D    //
//    qePAN4aPjjXhoswoVnYc_>":_____,^:^"""",,^^,>""~__;__;____;;!)__v))v)???|))^.:<_)YV}XX5hWMG4pRGRqemGDG    //
//    Wa4HbHqpqZhXXwwuwzs=T_!,,:"">^:'^",,^^::^::::^:::,^,"<"",^,,^"",,,,!",,:``.,>)xuoIX4AqmWGHHHGH4bMWDN    //
//    bqqNmHmmqqZhXIIKXKzYx|)>,^",^,::^^::::'.''':::''':'::^^^,:^^^",">"~<":'` `^"_=VXZhP4bqpGNHpRRGRDGGGp    //
//    pRGGNGmNGmq54hjj4jXTLYv_":::^^::>^^^",::'^"<_;!!">""",^^:':':^,,"!;":'```."~LkoPqPqbpHGWGGRGDGGD8DDR    //
//    WGGRDGGGGGRb4AhAajfwsc|_>,::''^^~"",",:::^,"_)_____)|))?__>>""",""~",^'':^")soAM4eNpGGDD8DRD8D$$$$DG    //
//    NGGDD$GDGGbmqZhZ55IIwsL)_,:^'''',:^^""^:,""~)??_))v))v|L|))))__~!>>,^'::::"|kIPWAbpmNGD8DDGDG%$%8DDN    //
//    NpGGG%D%%GHHpWPq4qhIwnTL)_::..::,,,"">""~!_)?c?|))|LL)??|_)__;!>!""^'''^^"_zoXbpMppRGD$$088$0D$8%D$G    //
//    RGD8G88%8DGGHHNMbbahXKkY|)":.`:^^>""""">>_>__))__)))|v?))|v?|))_;;":''^,")xohhqWNmmGGD$8BB0$$888$8$G    //
//    WGDB%#80$DDGDGRMppqAhos=sY)"'.':,!_)__;~____)~_><;_)))__))?LLLTLL);^::,;_LzVhAqHGRHGG$#0&B$8D#D888DG    //
//    HD#&&##&80DDDGGRpbqaAIV}zxL_"^:,?szsz}=YL|?|?L|)))___>,,">~;~__);,:.`':")zVIe4pmpGNGGDD%$$$$80D$$%$R    //
//    GG0B&0&B0B8$DGGGRMmpqjXzsT=)",^^?kXaXfXVVkcTccL|L|c=c?)||=VoZjwn?":''^";?kIXebqWGRGWGDDD8&000B$08D%D    //
//    G8&0B&&$##DDDGGGHpqpA5Afusx|_"^^)s5qbAjVVsx=YYY?|Lx==YssTzofaAhhw|,^^,;_=kKIq5qNpGHGGDD88&&&B$D$0%$D    //
//    G%B000$80#DD8DDDRHpGqePjozY?)_^:_kPp5ZwKkssTTTcL?LLTLc?YxTkwfoowx_,^^,_vsVfjpbbqbGGGDD$%8B0B80B08D$8    //
//    8$&808DDDGD%G$DGGGWW4MqensxL);^:_?zojXwouz=s=L|))|?cc||??Yz}fhXos;^^^"_LTkIZPbppWRRGDD88BQ$B$&0#$8$8    //
//    DD08B$D%DG%DDGGGWRpGmAP5IuTc|;,:>LVjeIIIVwzTxYL)))||c||??csVooXu|"^^^")cznjjAqqqbRHGGDD$B&800BB00$0D    //
//    D0##8D%D#%DDDDGGNRGHMqpqhosx?),:"vofjXIwwknkx|?)|))_)_))csnwfKIs_,^^,<_Y}uIjqmmWHWWRGD$$&$B0$$&#0$#G    //
//    DB0$%8$$D%DDDGD$NmGGMWpqAVks?),::)zaIfAjAKokcc?_______)?TsuskIVx"^:^"_)cVVKAqHMWMHmDGG#$B0$0$0B00$08    //
//    8$%0B#0$DD%D%DD8HGGGpMqqAIzTL)",^_ssfIfjaXIKL|))____;_))|cLsVzV?,^^^>)vxuoIabMmHHbWGG88$0#0B0B&0B$&$    //
//    %00&B0#$0%%$DDDDGHDGRMpAhoz=|~^:::^"~____",::'.'''..`.....''''.`  `.^;)YusjhqWbmNmNRG$GDB$8$B###$BB8    //
//    8B0&00B#$8DDGD$DGGGDRWb4joks);::'''''::''::'''.'.'.....'....`.``  .'"_)=T}XZ4GWqWMGD%$D%00$B#B000$08    //
//    0$$$#$8#$8DDGDDDDRGGGHW5Io}=?_^:'''::::::,:':':''''''':'::':''.```.:>_?TsnhAbGNNNmDD8D$0#$80&&B0BB0$    //
//    $8#B#88088DG$DD%GGGGGmp5hosxL~^::':,"""^^,^^^'':::::::':::::::.```.^>_|soKAXpRbHNGWD8D$$#$$$&&#B&#&%    //
//    $$00&$$$$DDGDDD8DGRGDpm5hosc_!::':,,""",,",,",^:^:::^::::^^,^,^:'.:"_)c}VXhPbRWGGDGG8D$0&0B&BBB&Q0&D    //
//    B0#B0888888$DDDGDGDDGpmp4j}L|;,^,_cszY?|)____)__))v?=x}c=sVIjIIw_^"_)?cnKaeqpGNRDDDD$$$B0B0B&&&&&B&$    //
//    &0&BB0BD$D$$DDGD8GGGHpNHNZsT)_;"_zwIZ44qanL|LLLLxssuVonszuVfoVwx),"_)?ckVjAMRGNG%%$$0$00#000&&Q&B&&$    //
//    B$&0#&&$%D$8GDGRGGGDpGRHqIzc);~"!TPepqAbqo}T=cY=sskzooVss}wIXAhj)",;|LxnVIqqWHHRD%8$$800&BBBB&&&&BBD    //
//    #0#$&$B8B$DDD%GGGDGpWGRNbVsY_><,>cZhMbpZXXwks=s=ssVnwVwsnVXjI5ZKY<"_||TnujIeHNWGD%D$D$0$00000&Q&0BB$    //
//    %#0$B08$$%8DD$DGRGRHRHmbPkx?_">,^_|LxTxY|cY|?ccxxYnofIIoAaqPhjZw?",,_)skwoo5pmMG8DD$DB0%$$0#&&Q&&&&0    //
//    #$$#$DD$D%8GDDDGGWpNHHmeIs=);"^,:,"!~_;>"";!;_))|YszVIjahjeZeI5o|^:,<)TVIKo5qbNR8GDD$&$$%BBB&0&QQ&&#    //
//    #$$%$D88$%DD8DGGRbHRNWqqo=)_^'':':^",",^^^,"">__)?==njwXfjjAAwkV=:':,~?sVzkXbWbGDDDD$$B0$B00&&Q&Q&&8    //
//    %#$$D80$$8DDDDG8GbNNGHbZu)),:..'::^,^^^::^^^"","__))||?xszT}k}nTx"'',")cwVVZNqbGGDG8#D0$$0&&&B&&&&#$    //
//    DD8DGG8$&DD8$D%DGHRGDHpAs)_<,:::""!,:::':'':^:::^^::::^,"<;)c|v)>,:`.:"_=szAqepGGGD%$88%%$$&BB&&&B08    //
//    $8D$GD$%8%G8D00GDRHRNWeVL));!!_)|L)))_!__)?cTsxL"::::'':''.::^^:::```.^"?xzX5ebGDDD8%$DD8DD#&&&&&&G8    //
//    $DD88D0DD8%D$D8DGGRRb4X}L)_"^,<_|L?|)|))))||x??Tz)__!~~",,^,,,,,^:'```.,)=nh4A4GGGD0DDDGDD%8&&&&&BB$    //
//    D8$DDDDGGDD%D8DGGGHGpAVz?_^:^^"~)Lc)))__))?LLc??Y|)_;<"""",",>"""":'```:_L=IPAbMRGG$DDRGGD$0&&BB#$$G    //
//    8$DDDDDDGGDDDDDGMRp45Kzs_,:::^~))|cv)))_~~___))?))_~~___>_"",""!">"^'``.,_YfZqqqDDHDGGpRDGD0B00008DR    //
//    D$DGDD88D%GDDGGDGRmajoz?,...',>_))))__~>"""">;___)_<!!!_>>",,<<""",^:'``',_Lwee4pGGGGGHRGD8D88#$0DGN    //
//    GDDGDD8D%8DGRGWbpMqXoz=_:'.':""";_~>;"!"",,",""!__;!""",,^^,""""""""^:'`.'_LK4aqPMNRpHqWGNG$D80$DGRR    //
//    RWGDGDGGDDGWbWbqq5Inzxv>^':;|)))_)|____>!""<><>>_"<!"","",^,,",",","",,.:^>LcIIaepMHGRbppRRDDDDDGGHM    //
//    pmWRGDGGGGRmqeXjIIo=TL;,,"??TVVzns=zsz}sT=x?cLLL?)_)~;>">"""<!;___!;<~~,'""_YkoIAbbGRMpqmMRG8GDDGbMe    //
//    bHRNGRmmpM4ZhIwwoKu?)>^^~=okIqqbHW4qP4P5AAAAZbbAIjKVoz}uz}=ss}sszsssYxT}x>";)x=nZ5bHmbNRRmGRDGGDGHpM    //
//    GD$GNMGbb5AjIVoVfo=)_<!"=ZMGD$DDDDGDGRRppqbWNMRpNWHbMHq4qqppGGDRDDDDHNWpRz_"<_?|k}V4H4qHHRHeNpRRNmGR    //
//    &@BDHGppqAwxVszk?s|))_vzWDGG8&0D8GDRDGGRRRmGGRGDGNRmmbbbqbqmNqqmDD88GG8%$$ec<")_||LznsInIZXjIqqpmG&D    //
//    @ggQDGH44ZwcTcxc|LTxsKbG$0%$&&0$GD%8DGGRmGRDGGRGGDDDmHmRNNRHGbpGG%DDD8$0$&&GIT)__))?)_s=kfKKIIAND&&0    //
//    @[email protected]&DpNhwkksLTzIj4G&88&0$&&QB$%DDDDDGGHGWDDGGWRGDHpGHGpmGHGGGG%G#D8$0&QQ&0%%RhzY|Lx|)cszoXabG&[email protected]&    //
//    @gggggggQ&$DGqDG8&QQBQ&&0B&0&&&&#DD$GDDGmRMGGRHRRRGGHWRNRRGHGRD888%$B&@[email protected]@QQ&&[email protected]@Q    //
//    @[email protected]@@[email protected]@@QQ#D8#Q&&&08DDGGDRNRGDGGDRmRGGGpppRGGGGG88&&&&QQQQ&@[email protected]@@@[email protected]@@@0BB##[email protected]@gQ    //
//    [email protected]@@QQ0$$$$&&$$88%D$GGRGppmGGDRqRGHHNHGpGDGDGD#0#0&&Q&&&[email protected]@@@[email protected]&    //
//    [email protected]@@Q&&$%8$$0G8DGGGGGGGMWmHGRRGGWRRGGGRGGGDDD8%0&&B&&QB&&@gggggggggggggggggggggggg&    //
//    [email protected]&&$D$%GGDGHHGRpRmbpbbWmbGHpbpbRNGNWWRDDGDD%88$$0$$B&[email protected]@gggggggggggggggggggggg&    //
//    [email protected]@[email protected]@@@[email protected]&&#8DRDMmGWNpqM4bqq4qqbbZabqqPZZqAbe4bbeqMmWWGRRGRGGRD%$%[email protected]@@@@@gggggggggggggggg&    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LNL is ERC721Creator {
    constructor() ERC721Creator("Laura Leonello", "LNL") {}
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