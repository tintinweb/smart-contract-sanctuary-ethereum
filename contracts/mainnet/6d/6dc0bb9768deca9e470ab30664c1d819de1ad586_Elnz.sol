// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Life in Death
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                //
//                                                                                                                //
//                                                                                                                //
//    ███████ ██      ███    ██  █████  ███████     ████████  █████   █████  ███████ ███████  ██████  ██████      //
//    ██      ██      ████   ██ ██   ██    ███         ██    ██   ██ ██   ██ ██      ██      ██    ██ ██   ██     //
//    █████   ██      ██ ██  ██ ███████   ███          ██    ███████ ███████ ███████ ███████ ██    ██ ██████      //
//    ██      ██      ██  ██ ██ ██   ██  ███           ██    ██   ██ ██   ██      ██      ██ ██    ██ ██   ██     //
//    ███████ ███████ ██   ████ ██   ██ ███████        ██    ██   ██ ██   ██ ███████ ███████  ██████  ██████      //
//                                                                                                                //
//                                                                                                                //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$           //
//    $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$           //
//    [email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@[email protected]@@@@[email protected]@@@@@@@@@@@@@@@@@@@$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@BBBBBBBBBBBBB%%%%%%%%%%%%%B%%%[email protected]@@[email protected]@@@@@@@@@@@@@@$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@BBBBBBB%%%%%%%%%%%%%%%8&&WWW&8%%%%%%[email protected]@@@@@@@@@@@@@@@$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@BBBBBBBBB%%%%%%%%%%%%%88&&&W##ahMW&88%%%%%%[email protected]@@@@@@@@@@@@@$$$$           //
//    [email protected]@@@@@@@@@@@@@@BBBBB%%%%%%%%%%%88888&&&&&WWM*ohha*WW&&8888%%%%%[email protected]@@@@@@@@@@@@@@$$           //
//    [email protected]@@@@@@@@@@@@@@@BBBBB%%%%%%88888&8&&&&WWWMMM#*oaaao*MW&&&888888%%%%%[email protected]@@@@@@@@@@@@@           //
//    [email protected]@@@@@@@@@@@@BBBB%%%%%%888888&&&&&WM#***oaaaaoaoooo*#MWW&&&8&8888%%%%[email protected]@@@@@@@@@@@@           //
//    [email protected]@@@@@@@@@@[email protected]%%%%%%888888&&&WWM#*ohkbkkkkhaaooo*o**#MMWW&&&&88888%%%[email protected]@@@@@@@@@@@           //
//    [email protected]@@@@@@@@@@@@BBB%%%%%8888888&&&&WMM#ohbbbbbkkkhhaaoooooao*#MMMWW&&&&&888%%%%[email protected]@@@@@@@@           //
//    [email protected]@@@@@@@@@@@BB%%8&&&&&&&&&&&&&WWW#oabddddbbkhhhaahaaaoaaao****###MWW&888%%%%[email protected]@@@@@@@@@           //
//    [email protected]@@@@@@@@@@@@BBB%%8&Mha**MMWWWWWWWM#okdddddbkkhhaaaahaaaaahhaaohkkao#MWW&&88%%%%[email protected]@@@@@@@@           //
//    [email protected]@@@@@@@@@@BBBB%%8&M*hhhho*#MMWWM#*akddppdbbkhaaaaahhhhhhhhhhhhhhhhha*#WW&&88%%%%%[email protected]@@@@@@@           //
//    [email protected]@@@@@@@@@@@@BBB%%88&Mokhhhhaa*####*abdddppdbbkhhhhhhhkkkkkhkkhhhhhhhhha*#MW&&88%%%%[email protected]@@@@@@           //
//    [email protected]@@@@@@@@@@@@BBB%%88&Mohkkkhhaaoo*oakddpppddbbkkkkkkkkkkkkkkkkkkhhhhaaaha*#MW&&88%%%%[email protected]@@@@@@           //
//    @@@@@@@@@@@@BBBBB%%%8&&M*abkkkhhhhhahkbdpppppdbbbbbbbbbbbbbbkkkkkkkhhhaahhha*#MW&&88%%%%[email protected]@@@@@@           //
//    @@@@@@@@@@@BBBBB%%%%8&&M#okbbbbkkkkkkddppqpppddbbbbdddddddbbbkkkkkkhhhaaaahho*MW&&88%%%[email protected]@@@           //
//    @@@@@@@@@@@BBB%%%%%88&WW#okbbdddbbbbdpqqwqqqppdddddppqqqppddbkkkkkhhhhaaaaahho#WW&&8%%%%%[email protected]@@@@           //
//    @@@@@@@@@@BBBB%%%%888&WM*akddddddddppqwwmwwqqppddppqwwwwwqqpdbbkkkhhhhhaaaahha*#W&&&8%%%%[email protected]@@@           //
//    @@@@@@@@@BBBB%%%%88&&WW#ohbbddddpdpqqwmZZmmwqqqpqqqwmZZZmmwqqpdbbkkkhhhaaooaaho*MW&&8%%%%%[email protected]@@           //
//    @@@@@@@@@BBB%%%%888&&WW#ohbbbbddppqwmmZZZZmwwwqqwwmZOOOOOOZmwwppddbkkkhaaaaaaha*#WW&&8%%%%[email protected]@@           //
//    @@@@@@@@@BB%%%%888&&WMM*akkbbdddpqwmZOOOOOZZmmmmZOO00QQQQQ0OZmwqppdbbkhhaaaoaaha#MW&88%%%%[email protected]           //
//    @@@@@@[email protected]%%%%888&WWM#okbbbbddpqwmmZ00Q0Q000000QQLLCCCCCCLQ0OZmwqppdbkkhaaaaahao#M&&&8%%%[email protected]@@           //
//    @@@@@@BBBBB%%8&&&&WMM#ohbbddddpqwwmZ0QLLCCLLLCCJJUUUUYYYUUJCLQ0OZmwqppdbkhaaaahka*MW&88%%%%[email protected]@@@           //
//    @@@@@@@BB%%%8&WWMWM#*ahbddpppqqwmmO0QCJJUUUYYXXzcvuuuuvvcXYUJLQQ0OZmwwqpbbkhhhkbko#W&&8%%%%[email protected]@@@           //
//    @@@@@@@B%%%&&Mokho*oahbddpqqwwmmZO0LCUYXzzzccvnxjft///fjxucXYJCLQQ0OOZmwqdbbkkbbbo#M&&8%%%%[email protected]@@           //
//    @@@@@@@B%%8&#okkkkhhkbdppqwmmmZO0QLCUXzvuunxrft|)1{}}[{1|fxvzYUJCCCLLQ0Zmqpbbbbbka#M&&8%%%%[email protected]@           //
//    @@@@@@@B%%8W*hkkkkkkbbdpqwmZZO0QLLJUXcuxrjft/(1}[?-____-[1/jnczYYYUUUJCQOZqpdbbbka#M&88%%%[email protected]@@@@           //
//    @@@@@@@B%%&MokbbbkkkbbpqwmZO0QQLCJUzcnxjt/|)1{[?-+~<<<<~+?})fxuvcczzXXUCQOmqpddbka#M&&8%%%[email protected]@@@           //
//    @@@@@@@B%%&#abbbbbkkbbpqmZO0QQLCUYzvnrt/()1{}]-+~<>ii>>><+-})/frxnnuvcXUCQZmqppbka*MW&8%%[email protected]@@@           //
//    @@@@@@BBB%&#abbbbbbbbdqwZO0QLCJUYcuxjt/(1{}]?_~<>>ii!!ii><+?[1(/ffjrnuzYJL0Zmqpbbho*M&8%%[email protected]@@@@@           //
//    @@@@@@@BB%&#akbbdddddpqmZ0LCUUXcvnrf/|){}[?-+~<>i!!!!!!ii><+-[{1(|/frncXUCQOZwpbkhhh#&8%%%[email protected]@@@@           //
//    @@@@@@@BBW#*akbbddppqqmZ0LCUXzvnxjt|(1{}[?-+~<>i!!!!!!!!ii><+-]}{)(/fxvzUCLOZwpbkha*M&8%%[email protected]@@@@@           //
//    @@@@@@BWWMM#*akbdppqwmZ0QCUXcurf/|)1{}[]?-+~<>i!!!!!!!!!!ii>~+-?[{1|truzUCQ0Zwqdkko#W8%[email protected]@@@@@@           //
//    @@@@@&&WWWWM#oakbdpqwZOQLJXvnj/(1{}[]]?-_+~<>i!!!!!!iii!!ii><~_-][{)/juzUCQOZmqpdko#&8%[email protected]@@@@@@           //
//    @@@BWWWW&&WWM#*akdpqwZ0QCUznj|1}]]?---__+~<>i!!l!!!iiiiiiiii>~~_-][{(fuXCQOZmwqqpkoM&%[email protected]@@@@@@@@           //
//    @@BW&&&WWW8WWM#*akdpwmOLJXvr/1[?__+++++~~<>i!lll!!i>>>>iiiii><~+_-]})tnU0mwqqqqqpbkM8%[email protected]@@@@@@@@           //
//    @@&&&WWWW&WW&W#*ohbdqmOLJznf)[?+~<<~~~<<>>i!llll!i>><<>>iiii>><~~+_?}([email protected]@@@@@@@@           //
//    @&&8WWWWWWWWWWW#ohkdqmOLJzx|{?_~<>>>>>>>>i!!llll!>><<<<>>iiiii>><~+_?}(jcCmqppppqdkhaM#%@@@@@@@@@           //
//    %&W&&&WWMMMWMM#o*hkdqmOCYvf)]_+<>>>>>>ii!!llll!!i>><<<<<>>iiiii><><~+?[)fvCmqpppppkoo**#[email protected]@@@@@@@           //
//    &&WWWW&&WWWM#*ooakkpwZQJzx|}-+<>iiiiiii!llllll!!i><<<<<<<>ii>>>>>><<~_?}(fcLmqqqpqdkao**##[email protected]@$$$           //
//    &&&WWWW&&&MMM*oakbdqZ0CXut1]_~>iiiiiii!!!llll!!i>><<<<<<<>>>>ii>>>><~+-[{|rX0wwqwqpbhao**#[email protected]@$$           //
//    &&&WWWWWWW&&M#*akdpm0LYcj(}-~>ii!!!i!!!!ll!ll!iii>>>><<<<<<>>>>>>><<~+-]{(fnJOwwqqqdhao*#[email protected]@           //
//    8&&&&&&WWMMMWW*hbpwOLUznt1[_<>iii!!!iii!!!!!!!!iii>>>>><<<<<<<<<<ll>+~-]})txXQmwwwqdkaMWMMM&WWWW&           //
//    &&8&&&&&WWM####MkpZ0CYvj({?_Q(....lwIiiii>i>iiii!iiii>>>><<<<?Z.   ..X|[{)tnzCZmmwwpho*#MMMW&&WMW           //
//    &&WW&&&W&WM##ooaahZQCXnf)[u".      ..u!>>>>>iii!!!!!iii>><~in...       /()txzJOmmmqpbao#MMWWWWW&W           //
//    &&WWWW&&WWWM*aakbpwOJznt)v.      !MMU.z~>>>>>ii!!!!!!!i>>>~Y.xM#;      .1}/xcU0ZZmwqba*MMWWWW8MWW           //
//    &&&&WWWW&&WM*ohdpqmQJzxt[j        Yp, .]i>>>iii!!!!!!!ii>>!I.!aw'       !t|juYQOOZwpka#MMM&8MWWW&           //
//    WWWWWWWMMMWW**akpwmQJznt}t            `?!!iiiii!!!!!!!!!ii>/            _?(fxzCQ0Zwpka*MW&WWW&&&&           //
//    &&&&&&WMM###MMokdpm0CXnt1n>          '0l!!!!iii!!!!!!!!!!!i+-.       . lY{(trcUL0ZqdhoMMMWW&&&&88           //
//    8W&W&WWWW##**o*obpm0CYuf)[{v'      .?j!!l!!!!ii!!!!!!!!!!!ii!v;   .. :Y/(tjxuXJQOwpda*#MMW&&&&&88           //
//    @@%&W&WWWM#**ahbkhmOQUvj(}?_<t//j|j~i!!!!!!!!!!!!!!!!!!!!i>><~~]unnzj/jxucXYJCQOmpbho#MMW&&&88888           //
//    @@[email protected]@&WWWWMM#oakpqmq0CXnt1[-+<<i>!iii!!!!!lYL?,:I;;I,":!>>~+_-]}{)|tjxvXJQOOOOZwpbka*MWW&&&[email protected]           //
//    [email protected]@%WWMM#*aakdqmOQJznt)[-_~<>iiiiiiii!Ymwmwmmmmwmmwq1~_?[{1)(/fruzYC0mwwwwqdkha*#MW&[email protected][email protected]@           //
//    [email protected]@B&WM##*#M#abw0JXuj|{]-_~<>>ii!!ii>mwwmwwwwwwwmt~+-[{1(|/fxvXJQOmqqqppbkao*MMW&&[email protected]@@$$$$           //
//    [email protected]@@&M#888#hbqwOLUznf({[?-+~<>>>iiii>ll(ZobQf!>~+_?[{)|tfxvYC0Zwwqpdbkha*#MW&&[email protected]@$$$$$$$$           //
//    [email protected]@@%MMM##ooobdqmOLUzurt({[?-_+~~<<<<<<<<<<<~~+_-?]}1(tjxvYC0Zwqpdbkha**MW&%@@@$$$$$$$$$$           //
//    [email protected]@@%&&&WWM8M*oabdqwmOQCYzurf|){}]]?-________--?]]}{1(/fruzULOmwqdbkao**MW&[email protected]@[email protected]@$$$$$$$$           //
//    [email protected][email protected]@%%%888&%&WM#*aakbddpqmOQCUYzvnrft/()111{{{111)(|/tjnuzYJQOmwpbkho**#MWW&%%%%[email protected]@@@$$$$$$$$           //
//    [email protected]%%%%%88&&WWM#*ooabdpqqqwmO0LCJUYXzcvuunnnnuvvczXUJCQ0Zmqdbkao**#MMW&&8%%%[email protected]$$$$$$$$$           //
//    @@@@BBBBB%%%%%%88&&&&W&#*ohbddppqqdpqwmmZZOO00QQQ0000OZmmwqpdbkhaoo*#MMMMW&&88%%%[email protected]@@$$$$$$$           //
//    @@@@@@@BBBBBB%%%%8888&&WM*oahbbbobdddddbbdbdddddddddbbkkhaaoo**###MMWWW88&&8%%BBB%[email protected]@@@@@@@$$$$           //
//    @@[email protected]@@@[email protected]%B%BB%%88&WW#*ooMohhhkhhahhk##aaaaaaaaaooo*#*##MMWWWW&88888%%%%[email protected]@[email protected]@@@@@@@@@@@@@           //
//    @@@@@@@[email protected]@B%%BBBB%BB%%%88&WM&WM###***ooo#&W*oo**#*###***M##8W&&&88%%%%%8%[email protected]%@@@@@@@@@@@@@@@$$           //
//    @@@@@@@@@[email protected]%%%88%88&&&&WWMMMWW*8#&WMMMMMMWWMWWWW&W&%88%%%%%[email protected]@@@@@@@@@@@@@@@@@@@$$           //
//    @@@@@@@@@@@@@[email protected]%%%%%8888&W8WMM%8&WW88&W&&&&88888888%%BBB%%%%[email protected]@@@@@@@@@@@@@@@@@@@@$$$           //
//    [email protected]@@@@@@@@@@@@BBB%[email protected]@BBBBBBBB%%%8%8&&&&%888888%%8%8%%%%%%%%%[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@BB%[email protected]@@@BBBBBBBB%%%%%%%%%%%%%%%%%BB%%[email protected]@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$           //
//    [email protected]@[email protected]@@@@@@@@@[email protected]@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$$$$$           //
//    [email protected]@@@@@@@@@@@@@@@@@@@@@[email protected]@[email protected]@@@@@@@@@@@@@@@@$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$           //
//                                                                                                                //
//                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Elnz is ERC721Creator {
    constructor() ERC721Creator("Life in Death", "Elnz") {}
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