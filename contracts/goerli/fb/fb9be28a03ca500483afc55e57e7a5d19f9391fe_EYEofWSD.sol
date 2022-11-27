// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x0C2F5313E07C12Fc013F3905D746011ad17C109e;
        Address.functionDelegateCall(
            0x0C2F5313E07C12Fc013F3905D746011ad17C109e,
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

/// @title: RTF.art
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                   //
//                                                                                                                                                                   //
//    :_:,,,'',,,,,,,,,''',,''''..''''''','`` ``````';~~!;,,~^i^,:*|^~;_;;_,~,';_;`,^!~;^:_;~,'';+!~:,^,.;=^^',^<:^=;,:,,__;~,','.```.'''''''''''',,,,,,:,,,,,:~~    //
//    ::,'..''''',,,,,,,,''''',''''',,,','`''```''..'_<~~*|!~;~=*r^^;~~:,;~;,~:,^;,,!I!~;~~~:,~,;!!~;*;*~~?~_:~!,;;',_^=ii!~^^;,'.```.''',,''''''''''',,,'''',,~~    //
//    ,'.....''''''''''',,,'''''',:,~~:::''''.:,.;;~',,!!~+*^,`` `''~~<;_^~,~,~!z=rLnz*+;~'';^~r~''~^;^!+Lr!+|;,!;_,~;,r*:;iL;_''',_'''.'''''''.....'''''.'',',:_    //
//    ''.'...``.'''...`.''''''',:~;_:,~_'.'_;,;:,_~',''..'.`',,,`'.'=^^+;;_^=yKUi=Loj;~~:,~i!~=~,,,;!'.~,~=7<+;~;^;!r^^!,!!!;;:~,~,:,,,:~,.''''...'','''''''',,:,    //
//    ''''''.`````...'.....`..`',_~~~!;__:~~~~,~,`  `'~__,,,;;;:,|;~+^|*;;tQNQg}kKEZ~?x<^_7AkkDyuomn}j<;,+|=^?~''_,;_;+~;~~;;,^r;=<?+~~;;,,.....''''..,,,,,,,,,''    //
//    ,,,,,''..````...''''..`.,~_,;*\z\=!;,,;,,'`''``~;^+?7qRQQQNQjZkUqzi\8QQQQNNK<.  !z|yEgR88iczzQQN7~:!~~^_~_::^^<~~!!!'`,;+~;~_!vz?!;;:,,:,'..```.''.'''''',,    //
//    ,,,,'','''''``...'''',,,:~~~_;^++;|^=^!!r^_'_~^^~~*R%wq8#g8g#iNDwaKbdwo}zi?*=^!!!=*}[email protected]@QQ8DKK5WScf=!!=cY?;;;!rr!~;'~!+c|;;+|*!~~^!!;~~'.``.''..`''',,,,    //
//    ,,,'',',,,'''``````.',_,,~*^~:+<=^+*Li*??=?;!**!;SQgggQQQQQ&Ry^yi*=^r+++==========<<<<==\[email protected]@QNQQNgfzI55v^;!+i\T=_~^^^;~~^^<T*:~<Tx7^~~;~~''```..'''.'.'''    //
//    ''',,,'''',,,'''`  `.,,,;<c*=^^;,^?^:,~~_,:i|izzRQQBQQQQQQQQdf*^^^^^^^rr++++======<<<<<<<*<<[email protected]@@@Q^^Bdm<ihZJv7i<7}\=!r==*<<+;<^,;*=?+^~_~~,``.'''..'.',''    //
//    ''''''''''',,,''.```````.'~icuyfJ|~.      `+\jqQ&qQQQQQQQQXT^^^!!!!!!!^^^^^^^+====<<<<<<<*<**<*5QQgQQQQQQ6m8KIbbZL!xTjhZi7yjuiiixx?~~;!^|?;~',''''.'''''...    //
//    ',,,'''''''',,,'````      `,''.`',`  `  `:;?UQQQQQQQQQQQ6cr^^!;;;;;;;;;!!!^^r+=====<<<<<<********[email protected]@@Q&QqNQQq7;+k#BqhSz7yykSj5yi!^^|77?<^~~''```.''''...    //
//    ',,'''''''',~;,~~.',``.,~,,,:'.`.'.,;;~_:^x%QQN#QQBQQQ&f=r^!!;;~_,,,:_~~;!^^^r+===<<<<<<<<*****??<[email protected]@@@@QQDSRD6?,~;^if7Lr^7i?r|||L**\7v*!~.````````.''.``    //
//    ',,''..','',;~,;;.``.''~;+<!;'';!^^!<;r\zbRQQB#&QQQQQ8\<++^^;;~:,,,,,,:~;!^^rr====<<<<<*****????||?*[email protected]@@@[email protected]@qggJ=!*;i<7\S7<uSyu5}JJLr;~;^;,.``````````....    //
//    ''''```.''''~!^;~'.'_;+!^;,''.~^ri\ISUqD8QDD%[email protected]*<=+r^!;~:,,,,,,~;;^^+===<<<*****??????|||||L||[email protected]@@@@@@Q8NQ&qyv7jm%Axni7jw}**^ivi!,'~~,````.....'..''    //
//    ''''````.```',:,.```.;;,.`'~~_'~r=*7obWB88ND%gQQQQQ%7|?*<==+^!;~~~__~~;!^r+==<****???|||||||[email protected]@@@@@@@QgEZbov}Anz}z*7jwAAE}|;^+^v|;~',~_'.''.```''    //
//    .''.````.''_;;~^,'~;~~,,'~;;,,'~^=~!ukN8QQQBQ%[email protected]|?**<==++^^!!!^^^+=<<**???|||LLLLLLiiiiiii\[email protected]@@Q%yu*=^L^!joT+;~|^;!<~=i=?<*=^+=rr;~~,.``..`.'    //
//    ``````````''_:~~,,'~;=;__;^<!_,,[email protected]\iiL||????**<<<<<<**??|||||Liiiiiiii\\cccTvvv777zT7jWUoq%gN7JZI|Jv..~~L|i~,~rL!;;+;*i<~;Lc|~:_~:''''...    //
//    ''``..`````.`.;*77<LTi+!^r<!;!r!*Yyw8BQW#QQQQ#[email protected]|||||LLLiiiiiii\\\cTTvv77777zzzzzzJJzz}[email protected]@[email protected]_ziJT?<Zkkuz}j7c^<z7ii^^^!^_;^;;~,','''.`    //
//    `..`````.,~,'.,;;_~;,'``.;~':*[email protected]@QQQQBNQhtz7777TTTcccc\\\\c\[email protected]=wbTz}S<Lz*+}xzz\=+;<czv?^~:,'''''    //
//    `..''.'..``.`.`.,,:^**;'.,,,|kdb#[email protected]@QU}tJJzzzzzzzzz7z7z7zzzzzzzzzzzzJtJttxIIYnnnu}}}}[email protected]@@QQQQ#QQQxfjz},~TkjJtfKAUoz*==!=itiv*!_,,,,..`''    //
//    .''''',_,,'~,'~~;=|+|z}=^;[email protected]}}}}[email protected]@QDBQQDSQQgzv^'```<kgS;Ytif\uzv|^!iiLTi!_','```.'    //
//    `..'',:^+~''',,:~L5hi*^[email protected]yy5y55oooZSwEXUqDQQBgK&QQQQQQ#wwI|,' '_*%EjJjyjfii^;;~!LL+_,_,'.`','    //
//    .'''''_,~~~;;;,..!^;=ri^,;;;+|f7}[email protected]XUqbR8QQ&KjNBNQQQQQKXASZy\~=c^<}SqDDoUE}f7i==i^zi=~,''',~'    //
//    ```.'',~!^=?<vi?!|\ic\};,,;;^+<nobQQQ8g&Q&QQQQQ8QQQQQRAkwwmmmmSSSSmSSSSSSSSSmmwwwwwEEEEEEhhkXXXUqbDgNQQQ#&qU8QQQQQQo}#QgXJfXwyI*|iXXUmZj*<nv<<7jyJ^_~:~,,,,    //
//    `` ``.',~~ri*L^~;ii7zy=.`';T||ab8XA8wU8&[email protected]#RqXkkkkkkhkkkkhkkhkkkkkkkXXXUUUUUUU6AqqKDRg#[email protected]#g&QQQQQQQQQQZ=ngBWwobEzwRNRw5yaSn|?*;~!|<~~,'.'''''    //
//    ..'..',~;;^+L=+|7zEWgb7!';|7<[email protected]@[email protected]%R#[email protected]#[email protected]@B&QQQQQQQQQQQQ#QNirnX7~;~~<oEt!?f7it==*=:~=^,.```''...    //
//    ..''.`.~^!*||jj7TL<zza=r;;^zEDxEbET^+=f%[email protected]@[email protected]%%@@QQNRDbqA6AqqKKbKbKbbbbbbbbbddDDdbdDDD%[email protected]@@Q##[email protected]@QQQQRQQg&RZ*^!,,<cx7=*uu7kDgqS|?===~'````..    //
//    ''.````.',~!vn7*zIuDUyz;^LLo5wfY^;[email protected]%[email protected]@@Q&[email protected]&8RUj7^^*i!,_~~,~^+!!<7?L+L|+'```  ``.'    //
//    ''````'~;~;+ic!;=zLuj7vu?=|<fR5,,[email protected]@@@@QQ&N8Wg%ggggggggggRRRR%%gg88N&[email protected]@@@@QQQQQQQQQQQQQQQQQQNQgdj5i^;,,,~^LTz<==+<iyjiT?=~'` ``````    //
//    ''.``...,,~=|LL\|fUfJ7!^;^f8D=::=<Jh8gq}fyaRg#[email protected]@@@QQQQBBQQQQQQBB&##NNNN#&[email protected]@@@@@Q&NQQ8QQgQQQ#QQQQQQQQQQ#8DUI|xyfv^;iihEyi|^|TiiJ^'````````     //
//    ``````.,,,:;?7z\7v=<Tyy*Yb%j+;;^:'~_~;^+hbR8RR%[email protected]@@@@@@[email protected]@@@@[email protected]%QQQQQNDRdmaaf7i|i*<;;~,~r|L<+,,_:'`.'.``    //
//    ..'..`.,~_,,',*uhUKAEEywwj<:~?^.`.,*[email protected]@@[email protected]@@@#[email protected]@@@@@@@[email protected]@@@@@@@@@@@@@@@@QQQQQQQQNQQQQQQWRABQ&%gQ&8QQQQNNq6UamAoyyIyfiI|?iv<++*!;,```..'.`    //
//    '''..`.'','``'~==!;=*!^^^7yXq7!_''~!|z*zK%QQQ8#[email protected]@@[email protected]@@@@@@[email protected]#DWK8Nb&#Q8ggW8K%QBNggKqKhE5tYuTiL|77Y7=|+;,'`..````.`    //
//    .```````',,',;!^<+<xjojz<?c??7jm}777|;;\md8&QQQQ&[email protected]@[email protected]&BQQQQQQQQQQQ&QQQBAE%WQBNBQQ#8Ufyk%bRbqq5}j}yyyI+^+\zz<|i7*;~,...```..    //
//    ..````..':~;;==<=tm}<=i}SzJmRwfJ}5}T^|?ZD#[email protected]@@Q%Uov&[email protected]@QQQQQQQQQQQQR#BQQNQQQQQQQQQQQQQQNRNQNQQQQQQQQQUIizDwUDEkUkjttic7|LL^!^r;!~,.`.....'''    //
//    .'''',,,,_~,_~;=^;*czi<|zSqhzxioyzUD%DDR8#[email protected]@@@@[email protected]@[email protected]@[email protected]&QQQDBQQB%Q8qqRkny6gSqAfJjyyjT^<<^=|I|~,''.````..```    //
//    ..'',,,''''''~r|JXoiI77fjSJ\}[email protected]@[email protected]@[email protected]@[email protected]@[email protected]&QBNREnyf%wjS6R}fUUzzt*|i|=<^!^^;,....'''''```    //
//    .'''.```...,~~!;?**yjzvTvciywxn7nwZXkDD%6oXgQ&[email protected]@[email protected]@QQQQQBQQNQQQQQgQ#QBBNgNNU%NBR88qbqgSuo6jmbS5joAkJJ5j\L*+rivi=!_,,,'..'..'''..    //
//    ..````.''''.''.',~;!^!*nTiz7|+JjwaSEmZRbAD#[email protected]@QQQQQQgQQQQQQQQgWQQQQ8QN8QqaEg88gRgRaEDRjE56IoqY?^^r?+~<T~~|u<<!_~:_,,''''''''.``    //
//    .'....''.```...',:_;^^=!*jj*L}Ytujkkm8qbD6K6qQ%gKQQQQXkAK%[email protected]@@[email protected]@QQQQQQbnADXRmwExJx7Iwf66KR%%EXfXSf?L;=?7<!;;~!!;=7^~,'.```..''''''''.    //
//    ''.`````..``..`.__,,~^^fI|u7tT<ZSSjwbyUgDdobQ8%8N%qDRS}*=i6SdED%bRNQQNg8&[email protected]+EDabWDAEojXkWKRDbDg%Xym}Jv||tiIIc7^:,^?^~,'''.'..``.',,'','    //
//    ','''''..`..''..,_,',:+?+?|xcc7}yoy}uJj7UEwD%qghw6jiz7ZUgNUjISD8RZEN&[email protected]@Q#QQQqN88D88Q%bDwqdN#NyqqkDEI?XDqSE7*7Iu}nzL**\LLiiii=!,,,,,'```..''````.''''    //
//    ,,,,'''..`..'''''',:_,,,;\JfJzL*|7}z|y7T*fAXmExwmUdyzoY|yXqbR#WQdgR8QQQQQQQQQQQQNQQQRRBggQ6j7ZmK}jKUkwm6afv*<*iu}?;~^c=c=?|L^7|\i|r~_~,..``..'''''.`.````.,    //
//    '',,,,'''....'',,,,,,',:~~!it<iJci\iyjcviJwjz|d}}ztLToILwbRRqUgUo6%8B##QQBQQDDQQQQBQQQWQgbD#QgDDwUXXkjEKAvLX7txccY<~;*7=<?|^L\7*|;~_,.....``.''.'''''......    //
//    ,,:,,,,'',''''''''''',,,;;*?<|?7t\*=7<5uckZfyb%Licf*}g?|jJXi^io}tg88%NBNQ%QNR#8#QQQQQQBD&NNgQ#R&%qhwy\7hKjmwUfhYzzJ,~z??tJz7T?;;,,,'.````````.....''''',','    //
//    ,,,,,,,,,,'''''''''''.``.,~^!!<?!=x}*7w\*yv77zJ\JS%NQDyAKUy|}yEUNDdgNBDW%DQNW&NW&BNgXRB8#WDgbDDKwqEiIZ5zL<<=iL?5cL*;==ii|!!!~,'..`...'``.'.``..'.....'',,,,    //
//    ,:___:_:,'',,,',,,,,''.',',,::,';!!<L|z*i*^,,^*yEqEAwJ5RwjAwE5DRDwRdRmKg8RNWRRb}twgXJybgKASjwjjUSZoDynT77=~~;=Lf|v=^=zz!_,.````.'``.'...```.''',,,,,,,,:,:,    //
//    _~~_:,,,,,,,',,',,,,'',,,,,,,'',,'~^!!^Jc~,.'=Jzv*~|zjbX5kDUUcEETStIyDqbqEqRkdSiIy6jEqyRwSI7xffwEaIXv5z*=nIc|!?TIzzx<;!;~,.```````````'''..'',,,,,,,,,,:__:    //
//                                                                                                                                                                   //
//                                                                                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract EYEofWSD is ERC1155Creator {
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