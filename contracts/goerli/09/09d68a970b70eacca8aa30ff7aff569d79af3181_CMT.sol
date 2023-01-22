// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ChemTales
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777    //
//    777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777    //
//    777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777    //
//    777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777    //
//    77777777777777777777777777777777777777777777777777777777~~!7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777    //
//    7777777777777777777777777777777777777777777777777777777!^:!777777777!!!!!!!!!!!!!!!!!7777777~:::^!7777777777777777777777777777777777777777777777777777    //
//    777777777777777777777777777777777777777777777777777777!^^~!!!!!~~~~77!!!!!!^^!!!!!!!!!!!7!!^ :^^^:!777777777~::^~7777777777777777777777777777777777777    //
//    77777777777777777777777777777777777777777777777777777!:::^^!~^^~7!!~7!!!!!!~~!!!!!!!!!!~^^^:.~^^^^!!!!7!77~!::^^^77~~!77!!7777777777777777777777777777    //
//    7777777777777777777777777777777777777777777777!!!!7!!!:.:~!^:~~7J!!7!7!!!!!!!!!!!!!!!~:.:^..^~~~~!!!!!^!!!^^~^:~!7!^~777777777777777777777777777777777    //
//    777777777777777777777777777777777!!!777~^^:^^^::::^!!!~ ^!~!~!!Y?7?!!?!!~~~~~~~~~~~~!:^^~^:^~!!777777?77!777!^~777777777777777777777777777777777777777    //
//    777777777777777777777777777777!^^::::^^::::::::::::~~^:^!~!7?7!5YJ77JY?!~~~~~~!!!~~~^:~~!!^^~!!!7!77??!7?J???77!!!!7777777777!~~~!77777777777777777777    //
//    77777777777777777777777777777^:::::::::::::.:^^::::^^^~!~!7~7JJP577YYJ??!~!7~!??77^^^~~7J?~!!!!????JY??J5YYYYYJ?!!!!~!777777!.::^^77777777777777777777    //
//    7777777777777777777777777777~::::::::::::^.:^^^^:::~~!77!7J????P5J5YJY55?!7?!~!J7?!??7J5Y!!J?7?YYY5PP5PPP55PPP5YJ!!!^^!777777^^^^~77777777777777777777    //
//    777777777777777777777777!!!7~:::::::::::::^^^^~^:^^~~~!77??JYYYPGP55PPPPYYYJ??7J7?JY5P55?JJ5?5GGGGGGGPPPPPP55YYYJ7!!~:^!~:!!77777777777777777777777777    //
//    7777777777777777777777~:::::^:::::::::^^::^!!!^.:^~^~~7!???JYYYPBPPPPPPG5PP5PPPJPPY5PG5J?PPGGBBGPPPPPGP55PPYJ?!!!!!!!~.~^~!~!!!!7777777777777777777777    //
//    777777777777777777777~:::::::::::::^^^^^:^^~~^^:^^~!!!?7?JYYPPPBBYJJYPPGGBBGGBPPG55PBBG?5BGGPP55PPGPPPJ77?77!~~~~~~~^..^~!!!!!!!!777777777777777777777    //
//    777777777777777777!^^:::::::::::::::^::::~~~^^~:~!!~!7?YJ55PGGP??J5GGBGPPPBBB#GPJ5GP5P55P5555P55YYYYYJ7^^^!!^~~~~^^^::^^^!!!!^::::^!777777777777777777    //
//    77777777777777777!::::^::::::::::::::::^^~~~~~~~!~77J??J5Y5GG5^7JY5GBG??5PPPPPPYYJ??5PGGPPPPY?77JJJJY55YY5Y!!77!!!!:^~^~!!!~::::::::~77777777777777777    //
//    77777777777777777~:^^^^^::::::::::^^:::^~~^^^~!!!777YJJY7JGBG~~?YYPPBGJ5GGPP5J???J5GGGPPP5PYJ5PGPGGGGG5YYYYJ7?JJY?77!~~!!!!^:::^::::~77777777777777777    //
//    777777777777!^^^^^::^^^:::::::::::^::^^^~^^~~7^?YJ?YP5J7!5PBG^!?Y5PGBBBPP5YYJY5PGGGGGPPP5PGGBGP5GBGP5YY5PP555YYYJJJ??!~~~!!~:::::::~!77777777777777777    //
//    777777777777::::::::::::::::::::::^~^^^^:~~!77!??5PGPP?7?YGGG7~JYPPBGP5Y5PGGGGGGGP55YY5GGPPGPY5GGPP55YYYYYY55P5YYYYYJ?7~^::^:::::::^!77!^^^!7777777777    //
//    777777777777~:::::::::::::::::::::^~^::.~~7?7???JYGBGBP?Y5P?Y5!J5PGPY?77YPGGPP5YJJJYYYY55Y5PPGG555YYYYJJJJJJJJJY55Y5YYJ!.:::::::::::!7!^:::!7777777777    //
//    77777777!^^~~!!^::::::::::::::::::^:::.~~7?JJYYY5PP#GYJYYPY!7PYYPBPY7777JYJYYJJJJJJYYYYYY555PPGGGPP5555PGGGGP5P55PPP5JJ7.:::::::::^!!!!!!!!77777777777    //
//    7777777!::::::!!^:::::::::::::::^^::::.~^JJJYY5PGBP?~^^~7?Y?!?PPGPY7777?777???JJJJJYYYYYYY5555PPGGPP55YJ?JYP5PGGGPP55?!:::::::::::!!!!!!~77!!!77777777    //
//    77777777~^~!!^::::::::::::::::::^:::^:.^!7YY555PG?^~:::^!!!7!!7YP?777!^??7????JJJYYYYY555555555PGGGGGGGPPY??5PGGPY7~^:..:::::::::::::::^:~7~:^77777777    //
//    7777777777777!~~!~:::::::::::::~7::::::.~!JPGGGP~:^~~~~~~!!^!7!!?77777??7????JJY5Y?7??JYY5GP5555PPGPGPP5PPG5?GGPPPJ~...::::::::::^~~^^^~!!7!!!77777777    //
//    77777777777777!7!~^^^^:::::::::?P!.:::...~YPGGG7~!~~!!!!~!!~77!!??777777???JY5YJ777?JYY55GGP555PP5PGPGGGBBGBP5BGGP?JJ:...::.^~~~~~~~!!!!!!!!7777777777    //
//    77777777777777!!!!~^:::::::::::^!::::.^~!75Y!~~~!!??!!!!!~7777!777~~?????JY5Y?777?JY55PPGGBPPPPPGP55GPP55PGGGPGGG5?:7!.::^7~77!!777?7!!!!!!!7777777777    //
//    7777777777777!!!~:::::::::::::::.::::!!7Y55~!!7!!!~!??77777~777???!75J??JYY?!77?J5PGB##BBBBPPPPPGG55PGGGP555PPGGPGPJ7?77JYY55Y?YYJY5Y?7!!!!!7777777777    //
//    7777777777777!!!~:::::::::::::!!:.:::?J57?JYPPPP5J7!~!?J?777?JJJJ?JJJJYYJ7!77JY5GBBGGGB#BGGPPPGGGGGPP5Y5PGGGGPPPPP55?~~7J5PPGPPPPPPPY?^^^~!!!777777777    //
//    77777777777!!!!!!~~~^:::::::::J5Y^.:.?Y^.~^?5GBB#BPY7!~!?YJ?????????JJ7!!7?JYPPPG55Y555PBGGP5PGGGGGGBGP555PPBBBGBGGY~~77JPGGBBGGGPP5?77^::^!!!77777777    //
//    7777777777!!!!!!!!!!^::::::::.!5P~.:.~~......?PG#PGBG5J??5PJ???JJ???Y57?JY5PBPJ~7???!7?JBBP55P5PPGGPYYY5PBPP5BBGGP!7?7:!5Y?PP?PPPP??5J^^~:~!!!!7777777    //
//    777777777!!!!~~^^^~~~^::::::^~.:::::..........7PBJ?7YPPGGGP?????J??JYGPPGGB##J!:^~~~~^!7BG555?YPPB5Y???55P#P55BBGP!...~5!:YP7:5!755^~5?:~~~~!!!!777777    //
//    77777777!77777!~~~~^^^^:::::!Y!:::::...........YB?::^~~7BGP5Y????YPP5PGBBBGGB?:..:::^~~JBPPP555YPGGPPPPGGBBBP5BB5GP7..?!.:5J.^7::^5?:~Y^~~~!!!!!777777    //
//    7777777!7?JJJJ???7777!^:::::?PP!.:.::^^~~^...:7YP5~::^^JPJYYY????J5YJJY5PPPPGG?^^:^^^~JBPPPGGP5Y5PGBBBBBBBB#GP#BPYGP~.~::?P^:^::::77:^7^~~!!!!!!!77777    //
//    7777777!7J5YYYJYJ?JJJJJ7^:::^?J^.:^~~!7?!!~..:?JYYPYJJYY?JPY????????5PJ?JYYYY5GPYJJJ5GG555555PGPPJYGBBBBBBBBG55B5.!G!...75?.::::::~^^^^^~~~!!!!!!!7777    //
//    777777!!!JY55555YYJYYJJ?~::::...:!!!??JJJ77^.7?J???JYJJ?PB##P?5J5J?P&&#YJYJJY5YY5PPP5PPPGBBBP5GBPPPPPPGB#BBBB5?G~.:5^..~55:::::::^^:^^^^^~~!!!!!!!!777    //
//    77777!!!!!7YY555P555YYYJ?!^:::::~7??YJYYJ??~:JYYJGYYB5GG&&&#&#&GB#B&&###GP?P&BYPY5P5Y5#&&###G5GBGGGPPPPPGBB75B5!..~?..^YGY~:::::::::::^^~~~~!!!!!!!!77    //
//    77777!!!!!~!7YYPPPPPP5555Y?^.:!7JJ?JY55YJJJ^:Y5!?&55&###&PG###G#####5GB#&BPB&&B#B5G#BB#&&57YGGGGB#BGPPPY5PP?!Y^.?77..:?PGP5?:::::^~~~~~^^^~~~!!!!!!!77    //
//    7777!!!!!!!~^!J5PPPPPGGPPPY???JJJY5JYP5YYJ??.~5YYP!?B77#P!!B#?!G#5GP~?##B#B~J#####&G75BGBYJ5PGGGB##GBGPPP5555J:.JG7..!5GGGPP?~7?Y55PPPP5J!~~~~!!!!!!!!    //
//    7777!!!!!!!~~~~!?J5PGGGGGGGPJ55YYY55PG555YYJ..^5P5YY5JJ5YJJY5YYY5Y55YYP5PG5?JPG?5BBP?JPGGPGGGGBGB&#BGGPPPPPPPP5^.77.^YGGGGGGP5PGGGGGP5J?7!~~~~!!!!!!!!    //
//    777!!!!!!!~~~~~~^^~!?YY5GBB55PPP555PBP55555?.^~YGPGPPPP55PPP5PPPPPPPPPPPPPPPPPPPPGGGGGGGGGGGGB#GPPPP5PPPPPPPPPPJ^...JP55GGGPGBGGBPY7~^^^^~~~~~~!!!!!!!    //
//    77!!!!!!!!~~~~~~~^^^~~?J?5GPPGPPPGGGBPPP5P5^!7?YP5G5PGPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBBB#BBYPBGGPPPPPGGGGP!..~5J?PBGGGP5Y?7~::^^^^^~~~~~~!!!!!!!    //
//    7!!!!!!!!~~~~~~^^^^^?5PGJ?JYPGGGGGGBBGGGPP5^7JP5P55GBBG5PPGGGGGGGGGGGGGGGPGGGGGGGGGGGGGGGGB#B#BBPYBB#GPPGGGGGGGP?.~JJJJBBP5Y?!^:^~!!77777~~~~~~~!!!!!!    //
//    !!!!!!!!~~~!!!!!!~~^^!?JYJJJJ5YGBBGB#BGGGGP7JJPPPGGBB##55G##PPPPPGGPPPGGGPPGGPGGPPPPB#BBGBBBBBBGYJPPBBGGGGGGGBGG5^YJYJYGPYPG~~7?JJYYJ?!~~~~~~~~~~!!!!!    //
//    !!!!!!!~~~!77??JYYJ??7~^7YYJJYJJGBBBBBGGGGY:?YPGBGBBGBP!!PGBBG5PGBBGPYPBBGPPPPB#G55P#BBBBBBGGGB?^.75PGBBGGB#BGBG!?5YYYYPPPBGYYJYYY?~^^^^^~~~~~~~~~!!!!    //
//    !!!!!!!~~~~~~~~~!7JYYYYYJPYYYYYJYBBBB#BBGGP7!JPP5BBB5?:..!?7GGBBBBBBBPGBBBBGGBBBB5PBBBGGGGGGGBG?~.!5PGGGPGPJYY7^:Y555YYPGGP5YY55?~^^^^^^^~~~~~~~~~!!!!    //
//    !!!!!!~~~~~~!7?YY5Y5PPPPPPP5555YJPBBGBBBBBGJ.^^^:~7!.......7GBGGGGGGGGGPGGGGGGGGGGBGGGGGBBBB##B~...:^~:^^:^77~:!5P55555GGP5Y5GBY!^^^^^^^^~~~~~~~~~~!!!    //
//    !!!!!!~~~~~~~^^^~7Y5PPPGGPGPP55555BGPBBGGGGY~:.............7PBB#BGGGGPPPPPPGGPGGGGBBBB##BBBBBBBY.......^J!^:75YYGP5P55PGP55PGGGY??J???7!~~~~~~~~~~~!!!    //
//    !!!!!~~~~~~~~~!777?J5PP555PPGPPPPPGPGG55GGGP!^:^^^^::^:::^~7YGBBBB###BBBGP5YYP!PP^!PB#BBBBBGBBBP!:::....^Y5J!!PPPPPPPPGGPPGGPPP55J?77!!!~~~~~~~~~~~!!!    //
//    !!!!!~~~~~!?JYYYJYY55PGGGPPPPPGGPPGGP5GBGBBP?YY?~~~~!?JYJJY5PGBBBBB#####G?^:^!:77:^^!GBBGGBBBBBBPY!~^^^~~~?5P5PGGGPGGGGGPGGGGY!~^^^^^^^^^~~~~~~~~~~~!!    //
//    !!!!!~~~~~77!~~~~^~!?JYGGGGGGGGGGGGGPGBPPGYP55J!77?YJ5PPGGGBBBBBBBBBBBBBBGJ77!!!!!!7!?BBBBBGGGGBBPP?77777??YPPPGGGGGGGGGGBGGG5JY?7!~^^^^^~~~~~~~~~~~!!    //
//    !!!!~~~~~~~~~~^~7J5YP555GGBBBGGGBGBGGGPP5GP5PPJ?JJY55PGGG5GGBBPBGPBBBBBBBG5J?????JJJYPGGGGBBBBBBBGGPYYJJJJY5PGGGGBGBGBBBBGPPPGG57~~~^^^^~~~~~~~~~~~~!!    //
//    !!!!!~~~~~~~~~~~!7775GGGBBBBBBBBBBBBBPGGP5PP5YYYJYY5YJY55PPPGGGGGPP555PPPP5555JJYY55PPPGGGBBGBBBGGPGP555YYYPPPPPBBBBBBBBBBBGGGPJ??!7!~^^~~~~~~~~~~~!!!    //
//    !!!!!!~~~~~~~~!!YJJJYGGGGGPGGBBBGGBBGPGPPP55J??777??JJ??YYY555YYY?7???JYYYYJJ??Y5PPPPPPGGY5GPG5GPBGG5YJ?JJ55P5GPGGPGB###BBPPGGPJYJ???!!~~~~~~~~~~~~!!!    //
//    !!!!!~~~~~~~~~J?!?YY5GGGBGGBBBBBP5555555YYYJJJJ?77!7?7?77????7!!~~777777???????77??JYYY5P5PPPPPPPYYJ7?JYJJJJY5555555GBGGBGGGGGPYYYJ77JY~~~~~~~~~~~!!!!    //
//    !!!!!!!~~~~~~~75Y???JY5P55555YYJJ??JJJJJJJJ?777777777????J????~~^~7J??77777???7777???JJYYYYYJJJYYYYJYJ???JJJJJJJJJYYJJJJY5PPPP5YJJJJYY!~~~~~~~~~~!!!!!    //
//    ~!!!!!!!~~~~~~~!?JYYYJJJJJJJJJJYYYYYYJJ?????7?????JJ??????????777?????????77777777????JJ????7?JJJJYJ???JJJJJJJJJJJJJJJJJJJJJJJJYYYY?!~~~~~~~~~~!!!!!!!    //
//    !!!!!!!!!~~~~~~~~?J?!?JJYY55555YYYYYYYYYYYJJJJYJJJ?JJJJJJ?????JJJJJJ?JYYYYYJ77??JJJJJJJJJJJ?JYYYJJJJ?JJYY5YYYJJYYYY555555555YJ??7!!!!~~~~~~~~~!!!!!!!!    //
//    ~!!!!!!!!!~~~~~~~~!~~~~7J!~?5PPPPPPP555555555YYYYYYYJJJJJJYYYYYJJJYYJ55YY55YYYYYYYYYJJJJJJJJJJJJJJJYY5555YYY55555PPPPPPPPPPPYYYYYYYY?~~~~~~~!!!!!!!!!!    //
//    !!!!!!!!!!!!~~~~~~~~~7JJJ?7?JJYY5PPPPPPPPPP5555YYY55555555555555555555555Y55555555YY55555YYYYYYY55555555555555PPPPPPPPP5777JJ?!!!~~~~~~~~~!!!!!!!!!!!!    //
//    !!!!!!!!!!!!!!~~~~~~~7JJYYYY55555555YY5PPPPP5555555555555555555555555PPPP55P5555555555PPPPPPP55555555555PPPPPPP55YYJ??7!~~~!7!~~~~~~~~~~!!!!!!~~!!~~~~    //
//    ~~~~~!!!!!!!!!!!!!~~~~~~~~~~~~!!!~~!?J5PPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555PP555555PPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555YY?~~~~~~~~~~~~~~~~~!!!!!!!~~~~~~~~~    //
//    ~~~!!!!!!!!!!!~!!!!!~~~~~~~~~~~~~~~~?YY555PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP55PPPPPPPPPPPPPPPPPPPPPPPPPPPPP5Y?~~~~~~~~~~~~~~!!!!!!!!!!!~~~~~~~~    //
//    ~~~~~~~~~~~!!!!!!!!!!!~~~~~~~~~~~~~~~~~~!!!!!!!777!!!!!777?JPPPPPPPPPPPPPPPPPPPPPPPPPYJ??JYJ???????????????????77!~~~~~~~~~~~~~~!!!!!!!!!!!~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~!!!~~!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~?YY555555555555PPPPPPPPPPPPPPPP5J!~7??~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~!!!!!!!!!!~!!!!!7777???????777!!!~~~~~~~~~~~~~~~~~~~~~!~~~~~~!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!~~!!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~!!~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~~~!!!!~~~~!!!~~~~~~~~~!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract CMT is ERC721Creator {
    constructor() ERC721Creator("ChemTales", "CMT") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xEB067AfFd7390f833eec76BF0C523Cf074a7713C;
        Address.functionDelegateCall(
            0xEB067AfFd7390f833eec76BF0C523Cf074a7713C,
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