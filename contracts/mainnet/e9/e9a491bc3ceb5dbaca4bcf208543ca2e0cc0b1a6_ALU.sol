// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Aliens Learn Ukranian
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                `````````````````.....''''''''''''',,,,,,,    //
//                                                                                                                    ````````````````......''''''''''''',,,    //
//                                                                                                                       ```````````````..........''''''''',    //
//                                                                                                                           ````````````````......'''''''''    //
//                                                                                                                            ` ````````````````......''''''    //
//                                                                                                                                   `````````````........''    //
//                                                                                                                                    `````````````````.....    //
//                                                                                                                                       ````````````````...    //
//                                                                                                                                         `` `````````````.    //
//                                                                                                                                             `````````````    //
//                                                                                                                                                 `````````    //
//                                                                                                                                                    ``````    //
//                                                                                                                                                       ```    //
//                                                                                                                                                              //
//                                                                          `',,~+;,'.                                                                          //
//                                                                    `'~^vyXbbKqUAbdbEc;.                                                                      //
//                                                               `'~+7akkUq6XXPmSmwhAKR%Rbj!`                                                                   //
//                                                            `_<Jymm5}xtJJtJJJJJJJtYuyw6bDDq?'                                                                 //
//                                                         `,<fafIcL|Li\7JtIYYnYYssstJzzzzzsyXUi`                                                               //
//                                                        'Ljomf\>>|\7ztn}fjjJxjj}}}{YsJz7v\iiiJ=`                                                              //
//                                                      '=zommj7|>*izx}jyojz||yyyyjjj}{YsJzz7\i|<;                                                              //
//                                                    `;f}Smm5}zc||LL|{aSj*<<?yZaoyyyfs7JYxJJz7\L<;                                                             //
//                                                   `=yoShEmojfsc|*<<*c5a?<<<|j5yyfv|*\{uIsxJzviL*;`                                                           //
//                                                   !fZPUhPSaofuzc|<<<*}E}*<<*ISSaT<<?t{{nYsz7\iiL*;                                                           //
//                                                  ,7oXkwkEmSajYzqb6L{bRRDa*JhA6Uh\7sjfjjjf{J7\LLL|<`                                                          //
//                                                  =JSkXkEmaoI|*S8W%UhmhUKqmW#Q&Wbb6PSjjyyyjfnzi|||*,                                                          //
//                                                 `|yAqowmjT?<<***<<<<<<****?|L\Jjaoj}ItJT7aoj{J7i||!`                                                         //
//                                                 'imXa?\*Ji<<<<<<<<<<<<<<<<<<<<<<<<<<<<<y8&N8%DKqkmu;`                                                        //
//                                                 'zwkL<<*z*<*\7jkX6P6bE\<<<*oZy}xL<<<<<jQQQQQNW6af7*~^*i!.                                                    //
//                                                 _}yni<<<<<<*?ijqd#QQQRj*<LKQQQQQz<<<*JEQQQQQB8RqofL   'KgS,                                                  //
//                                              `<jyowRdoY\?*<<<<<<<LtaD#BKnNQQQQDi<<<*SqmybQQQQQ#%Uoz .=wD%;                                                   //
//                                              *EPX66bbEES\>*?||*<<<<<*7a%RN888h*<<<?PbUmjuNQQQQQQQq5oK\,j<                                                    //
//                                             `jExwkmKb5jY?+=|7nszc|*<<<<*nKggWo*<<ik6kXkZf}RWNNWDqKJ;` ,q                                                     //
//                                             'oIoh6RKh}z7<+^*Li7}aPEy7*<<<iNQQQz*vXX6KqqEytuq666Efi    a:                                                     //
//                                             `sIUqqdEwX{jz|=**itSqdD%gqI*<|&QQQiuRN&#N##%qwYWgbky\*` `7_                                                      //
//                                              !7wUXq6qKawji??|7aqDR%gW8NZ*EQQQgoQQQQQQQQBQBqK8NN%Xj+;;`                                                       //
//                                               ;{S}ZAdqKkjJi|7jAD%gW8#QQQjBB##WQQQQQQQQB&QNKR8DqPf\,                                                          //
//                                                ;xI6bD%%q}uxzfEDggWN#QQQQNBNWW8N#QQQQQQgDdXhA8NDkyz,                                                          //
//                                                 `~z6bRgdyIy5PK%NNNN&QQQQQQB###&BQBN8WWDqP5akgQWqo7`                                                          //
//                                                    `\S6Ez}wKbD8&BN8#QQQQQQQQQQQQQQQQQBNgDXSXDQgAy;                                                           //
//                                                     `7o5vukDgW&QQ&N8QQQQQQQQ#B%gNWg8RDRWQQ8gN#bXc`                                                           //
//                                                      'Ij7jXbg8BQQQ#N#&[email protected]%K6%QQQ&dUj'                                                            //
//                                                       ;}JyUb%N&QQBNNN888NNN&[email protected]@Qgq%#Dkj'                                                             //
//                                                        =soqgg#QQQQB#BN8g%%%gWN##WWWWgNgkyS%Rkm_                                                              //
//                                                        `z}X%8NQQQQQQQBNg%%%ggN&BB&#NgRKoukDkX^                                                               //
//                                                         ~j6bDWB##QQQBNW%%ggW8##BB#N8RKSfjKq6=                                                                //
//                                                          zUD%%WN#QQQBNgRDR%ggWW8Wg%DKXZyyAUz                                                                 //
//                                                          ~wRN#NNNQQQQ&NgRDdbKKKKKqAXm5jjoqz`                                                                 //
//                        `.':~~,'`  ``                      7bNB#WNQQQQQQB&#8%RDdbDRDAwyySwz`                                                                  //
//    ,,,'''`         `,+7ymk6A6hajJ|L7Jv=,`    `'__,'``     :mgBQ&gkDBQQQQQQQQQ&NN#&NgDbKAy`                                                                   //
//    ;;;;;;^,      '+}XDR%%%%88gRDDbdR%Rqm}=~;Jk6qDKqXXmu=.  cD#B&DZZKgQQQQQQQQQQQQQQB&gWXv                                                                    //
//    !!!!!!^;`   ~7hbgBQQQQQQQ&Ng%%WNNN#QQ8A5}IuywUR%%8ggDa~ ,68#NRZoAK%BQQQQQQQQQQQQQBgUy7.                                                                   //
//    !!!^^^=!, .LXqDQQQ#gRdAXEmSwkKgBQQQQQQQgUSxsyhb8QQBBNgy,`nDN#gXaXqgBQQQQQQQB##NN%qXwyJ;`                                                                  //
//    !!!^^^=!~;jgb%QQ%kyjjjjyyyyoZEUbgBQQQQQQQDkfyERQ8gggg8%m';hg#NqmqR#QQQQQQQ#gg8NWDK6P5fiL!'                                   `~?v                         //
//    =<<+^^<^7UQNNQ&Xj}jy5SSSmwwEEEkXUdgQQQQQQQ%KEUg6XfL^;~;;;;tDN&RkqDBQQQQQQB8g8NW%DK6Paysfyy}||^~~;;~_'             `.         'ivz.                        //
//    L|=^^^^JqQQ8QQAyyawhXU666UUUUXUUXUK%QQQQQQQ%bkk6WBQQ#RK6khj6NQNqARQQQQQQQ&NNN8gRDqUPmaoSEhjjyjfnfkbgNRUS}\*^;,..'^>v    .~*yKWNWRX7!.        `,,          //
//    ==>==={b#QQQQ#hmwPkXU6Aqqqq66UUXXXXq%QQQQQQQD%UkUKQQQQQQDS#yWQB%KgQQQQQQQBB&NW%DbAUXXkkXEyoSwEkRQQQQQQQQQQQDs*|LL|<^,`.v8QQQQQQQQQQQWw;    `yQQQQD#Wf~    //
//    kz<*<zd8QQQQQ#XPPPPPXXXUU6UUUUXkPEEXKgQQQQQQQRgd%[email protected]@@Q!,'5QjRNBNR8QQQQQQQQQB#8%[email protected]@@@@@@QQQQD5sf}}}unY7\L|<<[email protected]@@QQD|:`'DQQQQQQQQQ    //
//    kDz*[email protected]@[email protected]@QQWg&[email protected]#BN#QQQQQQQQQ&#8gDKbdDdUhwmh%[email protected]@@@@@@@@@@BZyyfjjjjffjyyyfs7L|<*j%[email protected]@@@@@@@QQQQSsd%[email protected]@    //
//    [email protected]@@[email protected]@@@@Q8QBkRbwN#Qqz=|jKNBQQBQQQQQQQB#N8g%R%[email protected]@@@@@@@@@@Qqy5aaaZZZaoyjjjffyay}ziL*[email protected]@@@@@@QDW|[email protected]    //
//    [email protected]@@QQQQQQQQQQQNgDD%&[email protected]@[email protected]@@[email protected]#oz?^;<LvEW#BQBQQQQB##&#NNN8RdKqqq#@@@@@@@@@@@@@QUXXXkkhEEPEEmSZayyjjjyayfz\i|[email protected]@@@@8mmWf<|7}omk    //
//    [email protected]@@[email protected]@@[email protected]@@@@[email protected]@@QDwz*|||LiLi*zTy%8N&BQQQ&N#[email protected]@@@@@@@@@@@@@NqKqA66UXXkXXXXkkPwSayyjjjyao}zvi|}%@@@@%yi\y6gWRXm    //
//    ^[email protected]@@[email protected]@@[email protected]@@@@QQQ8EwhD#[email protected]@@@@@@[email protected]@QNdoJ\iLLLi\7zz?>{7Id88&[email protected]@@@@@@@@@@@@@@%KqqqqqqqqAqAqAq66UXkEwmayyyyjyoy{[email protected]\[email protected]@@@@@Q    //
//    zZ#[email protected]@@@@@@Q&#N8#QQQQ#8gbEEEqD%NQQQQQBQQQ6YstJJI{jyj{tz\***LxokW8BQQN%[email protected]@@@@@@@@@@@@@#q6U666AqqqqqKKqqqqqqq6UXkPmZa5yyyyoZynzcLS%7!\[email protected]@#SB    //
//    m#[email protected]@@@@QQ#N8g%%gg%%ggRXahw6DRR%gN#&QWw{YY}yof7}5yz|**>=**[email protected]@@@@@@@@@@@@@@dXXkkkXXU6AqqKKKqqKKKqqqA6UXkEwSZooyyyyS5Yz7ii|zw%8%ggQ    //
//    [email protected]@@@@8aYuuj5EDgg%%R%WgoEA6XgQNWWN&QbfyoShkajzJyo}|*<=>**[email protected]@@@@@@@@@@@@@@NXEwEEEPkkXU6AqqqqKqqKKKKqq666UXXhEwmZoyyy5Sa{J7i7K&#QQQQ    //
//    @@@@@@Q7wwSSZajz7xaKDR8NNNNN&QQQ8N&ga5wwmEwajYvsyyz|***|i|*<|[email protected]@@@@@@@@@@@@@QqEwmwwmwEPkXU66AqqKKKqqKKqqqA66U66UUkkEwZao5oaES}Jz\Z#QQQQ    //
//    @@@@@@@QB8%DbqXEZy}J{U%8QQQQQQQNN#NjjomwEEaj}z\nyfv||*L7zL|[email protected]@@@@@@@@@@@@@@gEmmmmmSmmwEhkXU66AqqqqqqKKKqqA666Aqq666UXPwSSZoSSwauzT7DQQQ    //
//    @@@@@@@@@@@@Q8%bUhEmoutjqKgWW###BQSfamwPEaj}IvinfI\||[email protected]@@@@@@@@@@@@@QASZSmmSSSSSmEhhXU66qqqKqqqKqqqq6U6UU6qqKKqqAXEmSaSmZZwo{z\zw8    //
//    @@@@@@@@@@@@@QQWRdqXhEmjxuK&BQQQQRsySEkhwyfuziiJsz\L||z{Yi||Lzjj}[email protected]@@@@@@@@@@@@@@Dwoy5oaZaZSSSwEhkUUUUAqqqAqqKqqqqA6UUUUqqKbbdbKUPmamwmaSZZ5}}J7    //
//    @@@@@@@@@@@@@@[email protected]}amEXhSjuYzii7z7vi||t}n|*iizfnt}5yyk#@@@@@@@@@@@@@@Qha5yyoaaaaSSSSwEkXU6UU6qqAAqqqqqqqqAUUXkXqqKbbddK6hSmmmSSmZoyjIT    //
//    @@@@@@@@@@@@@@@6<7hqmyyojjyu6DKKX|vt}jyyjnJJz\iv77zi|L{yt**c\[email protected]@@@@@@@@@@@@@@q5yyyyyoaaoZZZmmwkXU66666qq66qqqqqqqq66UXkk6qKbbdDdqXwmwEmSwwwmSay    //
//    @@@@@@@@@@@@@j~_;*7zc7z=+<*|iL\T|<<<<>=+^;;;;!!^^+++^?nj7*?\\TJtYjm&@@@@@@@@@@@@@@8Z5yy5yy5aaooaaZmmEkX66qqU6qqAAqAqKqqqqqA6XhPXqbdddDDdqXPPEwmwSkXkkP    //
//    @@@@@@@@@@@@%v!=so5js7cii\cL||*=+^^!!!!;;;;!+==++=^;,,;*7*|[email protected]@@@@@@@@@@@@@Qkj5aoaoyyyoao5aZmEwhXUqqqqU66A666qbqqKqqAq6UkwEUqbbKdDDK6XXhPkwkwmEkX    //
//    @@@@@@@@@@@NE^LjAdKUwSmwEhPkX6a}zYywwm5yyyy}[email protected]@@@@@@@@@@@@@8yjyZmaaoyyoaao5aSmwEXXXqKbq6UqAUXUqqqqqqqqqUUXEwkAbddDDDDKUXhkPhXPoaEh    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ALU is ERC721Creator {
    constructor() ERC721Creator("Aliens Learn Ukranian", "ALU") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a;
        Address.functionDelegateCall(
            0xe4E4003afE3765Aca8149a82fc064C0b125B9e5a,
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