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

pragma solidity ^0.8.0;

/// @title: 1117 Collection
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                               //
//                                                                                                                                                               //
//    BBBBBBBBBBBBBB##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#PPGGB#####GP55PPPG#BG55???JJJYY55PP?PYPGGYJJ77??7???JJJJJJ?77?5#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&     //
//    BBBBBB##BBPPGBBB##&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&BP5PB#BGGGGGPPGGPPPPP5?????JJYY55PJ5Y5PPYJJ77777???JYYJ??7?YB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&     //
//    PGBB#B##BGGBGPGB####&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&BPPGBBBP5PGGGBBGPPGPJ?????JJJYY5Y5Y5PPYYJ77777???JJJ?77JG&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&     //
//    PPGGBB#####GGB##GPG###&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&BP5PBBBGGP5PGPPPPPJ??????JJJYYY5YYPPY5Y??7???JJJ???JG&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#GB&&&&&&&&&&&     //
//    PGGGBBB######BGPPGGPG###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&BP5PPGGGGGGGGGPJ???J???JJJJJYYYY55P#J????JJJJ??JP#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&BB##P#&&&&&&&&&&     //
//    JY5GGPYPB########GPG#####&&&&&&&&&&&&&&&&&&&&&&&&&&&&&@&B555Y555YY5YJ??JJJJJJJJ??JJJY555PY7JJJJJ??7?P#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&###BPB&&&&&&&&&&&&#     //
//    ???JYJ??JPB########BBGPPGB##&&&&&&&&&&&&&&&&&&&&&&&&&&&@@&BGY5YYYYYYJ?JJJJJJJJJ????JY5J?77JYY5J77?5#&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#GPB&&B&&&&&&&&&&###     //
//    ???????7?JY5B#&#####GPBGPPPB##&&&&&&&&&&&&&&&&&&&&&&&&&&@@@&BPY55YYJJJJJJJJJJ?JJJ?JJJYJ7?JY55?77YB&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&BP#&BG&&&&&&&&&&#BB###     //
//    J???77?JJYYJJYG########GBBBPPG#############&&&&&&&&&&&&&&&&@@&B5YJJ????JJJJJJJJJJJJJJYYJYYJ?77JG&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#B#BPPB&&&&&&&&&&&BPBBBBB     //
//    ?????77?5PP5YJJYG########GPBBBGPB#########&&&&&&&&@&@@@@@&&&&@#5JJJ7?JJJJJJJJJJJJJJJJJY557~7JG&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##BPG&&B#&&&&&&&&&#B5Y5555P     //
//    ???JJJ?77?Y555JJJYG#########PPGGB#B######&&@&&&&&&&@@@@@@@&GPGYJYYY7?YYJJJJJJJJ?JJJJJJYJ!!?P&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##BPB#B#&&&&&&&&&&####BBBBG5J     //
//    YJ???JJ??777J5PYJJJ5G########B###BBBB####&&&&&&&&&&@@@@@@&&G5PG5YPP??YYYJJJJ??JJ???JJJJY?5#@&&&&&&&&&&&&&&&&&&&&&&&&&&#&#GPBGP#&&&&&&&&&&###########BB     //
//    5YYJJ???JJ??7?P55YJJJ5G###########BBBB#&@@&&&&&&&&@@@@@@@@@@&#[email protected]&&&&&&&&&&&&&&&&&&&&&&&&&&###G#&BG&#&&&&&&&&############BB##     //
//    BGP5YJJ???J???GYJ555YJJYG##########BBB#&&&&@&&&&&&@@@@@@@@@&BBBGYYY??YYYYJJJJJ????JJJJJY5&&&&&&&&&&&&&&&&&&&&&#&#&##GGBGGGB#&&&&&&&&P5YP########BB###B     //
//    GBBGYYYJJ????JPYJY5PP5YYY5G########BBB#&&&&&&&&&&&@@@@@&&&&G?5GP55Y?7??JJJJJJJJJJJJJJJJY5B&&&&&&&&&&&&&&&&&&&######PGPPG##&&&&&&&&B5JY?7?#####BBB#BBBB     //
//    GBBBBP55YJ?77????75P55PP5JJYG#######B#&&&&#&@@@@@@&&@&&#BB##[email protected]&&&&&&&&&&&&&&&&######GPP5BB##&#&&&&&BPPPYJ!~?YB#BBBBBBBBBB     //
//    BB5G##G555J?7!!77?YJ??J555JJ?YP#####B#&#&&&&&&@&@@&&&&[email protected]@&&&&&&&&&&#&&#&###G###G5BB#####&&&B5PG5JJJ7?JJJPBBBBBBBBBB     //
//    BBGGBBBBGYYJ??!!7??????JYYYYJ?J5G#####&&&&@@&&&&@@&&#[email protected]@&&&&&&&&&&&&&&##BBBPP##########&#GYJGB5YY?77JJYY5GGGBBBBB#&     //
//    PGGGGGGGB5?5J?7??777??77?JYJJY5YJYG####&&&&@@&&&&@@#5JJJ??P#[email protected]&&&&&@@&&&&&&&&&##P5PBB########&#GYY5G5YY?7?JYJYPGBBBBBB#####     //
//    PPPGGGPYJJ75PY?!7?77????77J5PYJYYJYYPB###&&&@@@@@@@#Y????7YGPP5PJ~!?JY?!7?YYYYYYYYYYY5#@&&&&&@&&&&&&&&&#####GP########&#GJ??Y5J?7!7JYJJPGBBBBBB##&&##&     //
//    PPPPPPGPJ77PG???77??7?JJJYYPPY5YJYYJ?JPB###&&@@@@@&GJ???77JYJJJY5J!!7??7JJYYYYYYJJY5P&@&@&&&&&&&&&&&&&##############&#B5Y7755?7!7JJJY5GBBBBBBB#&#5YG&&     //
//    PPPPPPPPP5775J7?JJ??????J5PP5JJYYJJJYJJYGB######&&GJJJJ?J55P5JJJJJ!!!7?YYYYYYYYJJ5PB&@@&&&&&&&&&&&&&&&&###########&#BP55?Y5PPYJJJJJ5GBBBBBBB##BPYJJ?YG     //
//    P5PPPPPPPPPJ?GGPJYYJJ?J?!7YPPYYJJJYJJJJYJYPB###B###J77?Y555YYYY5Y!!!7?JYY55YYYY5B#&@@&&&&&&&&&&&&&&&&&&&##########BP55YJJYYJYYJYY5GBBBBBB###GYJJJJ???~     //
//    P5PPPPPPPPPPPP5PBG5YJJ???!!7Y5YYYJJJJYJ??JJYPB#####5!!!7?JY5555P5!~~77?PGGGGBBB&@&&&&&&&&&&&&&&&&&&&&&&&&#####&#BGP55YJYYPGPYJYPGBBBBBB###GY7?JJ?!!7~~     //
//    5PPPPPPPPPPPPPPJ?5GPYYYJ7!!~!?YY55YYJJJ????JJ5G####B?!!!7?Y55PPPJ!~~!7?#@@&B###&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#BPGG55YYJJPGGGGGGBBBBBB##BPJ??J??!!???J5     //
//    5PPPPPPPPPPPPPPP5?77!!~~7?!77!7?Y555JJJJJYPJ?5PPG###G7~!!7JY55P5!~~~!7?B&&&&&@@@@&&&&&&&&&&&&&&&&&&&&&&&&&&#BGPGP55YYJ5GGGGGGBBBBBB#BGGY????7!!?JJ5P5J     //
//    55555PPPPPPPPPPPPPYY55Y~:?5?!!!^!?Y55YYY5YGP555555GB#[email protected]@@@&&&&&&&&&&&&&&&&#########&&&&&&BGPGP5555YPGGGGGBBBBBBBBP555J??7~!7?7?PP7??     //
//    5P5PPPPPPPPPPPPPPPPPPPGY?^!5Y7!!!??J5PP5YY5YY55?JJJYG#B7~!7?JYY!!!~!!7?G&&&&&&&&&&@@@@&&&&&###########&&&&&#GGP555Y5GBGGGBBBBBBBBPPPJ7?YJJ7~!Y5J??55??     //
//    55P5PPPPPPPPPPPPPPPPPPPYYJ7~?Y?!!!7!7J5555YYYJ5PYY?JYYG5~!!7JY7!!!!!77?G&&&&&&&@@@@@@@@&&&&############&&&&&BPPP55PGGGGGBBBBBBBGPGGGG57JY7^!7JY5YJ7!~?     //
//    P5PP5555PPPPPPPPPPPPPPPPJPG5J?YY!~~~!!7J5GPYYYP5?JY5YJ?J7!!?J7!!!!!!7??B&&&&&&&@@@@@&&&&&&&&############&&&&&GPP5PPGGGBBBBBBBBGGGGGP5J77??!^^!7JYP5J77     //
//    55P55YY55PPPPPPPPPPPPPPPPPGBBBPYJY7~~~777Y55YYYYJJYYY5???!7?7!!!!7777?Y#&&&&&&#@@@&&&&&&&&&&&&###########&&&&&G5GGGGBBBBBBBBBGGGP5J7??JJYJJ?!~!?YYY5Y7     //
//    555Y55555555PPPPPPPPPPPPPPGBBBBG5YPJ~~~!!~7JYJJJJJ?YJJ??J?77!!!7!777??G&&&&&@&&&&&&&&&&&&&&&&&&&#########&&&&&BPGGBBBBPBBBBBBG5J??JJYY555P5YJ?!^~7!7JJ     //
//    55555555YY55555PPPPPPPPPPPPGGBGGGY~JY7~~~~77?YYJ?JJJ??????7!7!!!77???G&&&&&&@@@&&&&&&###&&&&&&BGB########&&&&#GGBGGPGP5GBBGPYJJJYY55P55PPPP5YYJ?!^~?5Y     //
//    555555Y55555YY55PPPPPPPPPPPPPGBBGBJ^!YY7!77??7?Y5YJ???????J?!~!77??JG##&&&&@@&@&&&&####&&&&#BP555PBG##&#&&&&#BGBBGYYYY5GP5YJYY5PPPP5PPPGGGGPGP5??7!^~?     //
//    555555555555555555PPPPPPPPPPPPPGGBBP?!YPY?7!77!!JYYJ?????????!!7???P###&&&&@&&@&&&#####&&#BP555Y5GGJYJG&&##GPGBBPYJYJYYG5YPPPPPPPGGBBGGGPP55Y55PJJ??~^     //
//    555555555555555YY55PPPPPPPPPPPPPPGPG5Y!~?J?7!!!??!?JYJJJ????YG5YYYP####&&&@&&&@&&#####&#GP55PP55GGGP5Y!?5GY77YPYJYYYYY5PGPGGGGBBBBGGP55555555YJJJJ?777     //
//    55555P5555P55555PPPPPPPPPPPPPPPPPPGGY7???JJ?7!!!?J?7?JYJJJYYJGB##B####&&&&&&&&@&######G555PP5PPPPPPPPGP?!~77!~7YYY5Y5GBP5GGBBBBGPPPP555YYJJ???????JY5J     //
//    55555P555555PPPPPPP555555PPPPPPPPPPPPPPGGPP5J?77!!???J5YY55J7YBB#BBB###&&&&&#&@&###BG5YYYPPPP555YPGGGGGGJ^~!!!~7JYY5YYYY5#BGBGGP55YYJJJJJYY555PPPGGGPP     //
//    5555P55P5555PP5P55555555PPPPPPPPPPPPPPPPGGP55JJJ?7!7JGP55Y?JJJBBBBB####&&PG##&&###PJ?JY55YJ5P5PPGGGBBBPY5?^~!^^~75YJYJJJ?J5#&#BPP555PPPPPPGGGGP5P5YJJJ     //
//    5555PP555555P55P55555PP55555PPPPPPPPPPPPY?PGGJ!JPY?7!7JPPY?77JBBBBB####&#5YYPB##GP5YJ?7J??555PGGGBBGP5P5PGJ!~~!!7JJYYY?7JP#&@&&###BGGPP55Y5YY55JY55YJJ     //
//    5PP5PPPPPPPPPPPPPPP5P5555555PP5PPPPPPPPPPY5PGGJ~JYY?7~^!??7??7JPBBB#####&YJ??JYYY5PP5Y?7??J5GGGGGGPP555P5YYYJJJY5YY5J7?5#&&&&&@&G55PP5YY555PGY5PPGB#GP     //
//    PPPPPPPPPPPPPPPPPPPPP5555PP5555PPPPPPPPPPPPP5Y~^!?PJ77!!!!?YJ?J7YGBBB###5~??????JYY5PP5J?JPGGBGGPPPP55Y5P5YYYJJYYY?!7J?YBB##GBBPGB#BJ!:7PBBGPGBBBGGPGB     //
//    PPPPPPPPPPPPPPPPPPPPPPPPP5Y5PPPPP55PPPPPPPPPPP5~.:~?PY!7!!~?5J77??7??J55!!577??77!7JY5PPPGGBG5YYYYYY5P5YYJJYJYYJ7!7?7!JGBPGG5YY5PBG5JYPGBBBBGGB#BGGGPG     //
//    PPPPPPPPPPPPPPPPPPPPPPPPPP55PPP5555PPPPPPPPPPPPPY^.:!JY!^!!!!?Y?JJ?7!~~~!!7777~~!7?JJ!?PGGGY?!7?7?JYYYYJJJJJJ?!!?557YB#BGB##BPYJYYJYB&&&#BBBGGPP5GBBBG     //
//    PPPPPPPPPPPPPPPPPPPPPPPPPPPPP5Y5PPPP5555PPPPPPPPPP?:.^~^77!77!77???J7^^^~^^!!~!7???JY?!~?J!^7J7!!?J?JJ???JJ7~!JPBGGBBGGGBBGGB&#PYJJYG#&&&&#BBBGGG55PPG     //
//    GGGPPPPPPPPPPPPPPPPPPPPPPPPPPP55P555Y5555PPPPPPPPPP57..755!~7?777????~..:^^~~!7?7J55J777!~~JGG5J7!77??J??!~!Y5GBBGGGGGBGPYJY5PB&B5YJY5G#&&&&#BGGBBPYY5     //
//    PGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPP5555PPP555PPPPPPPPPPY~.:!7~~7?77!77JJ~^^~~!JJP????J5YY?YGGP5555Y?!!!7?!~!JPGGGGGGGGGGPYJJJJYPGGGBGP5YY5B#&@@&#BBBBPY5     //
//    Y5PGBBGGGPPPPPPPPPPASHLANDPPPPPPPPPPPPPPPPPP5555PPPP5PPPPPPPPPJ^.^~~!7777!!?~!!7?5PG5?!7JJ?YJ5P5PPPGY7YPGPJ!!~!YGBBGGPPGGGG5YJJJY5PGPGP5PG##BG5YYPGGGG     //
//    #BBPJYPGGGGPPPPPPPPPPPPPPPAVEPPPPPPPP555PPPP5YY5PPPPPPPP5?.  :^~!?77!!77~~!J7!!~~~?J?JJY5Y555J!YYPBG5JYY5G55GPGBGGG5YYY5PG##G5555GBBB#&BYJJJJJJJJ?7!JJ     //
//    ####BG5?J5PGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555P55PPPPPPPPP5!. .~75Y7!!!!77~~!~~!!~~7?J??Y??J?J5JYY5PPPPPPJ?YPB###BBGGGGGBB##BPGGPPP55Y5YJYYYYJ?JJYJJ?J     //
//    #######BGP5YPGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP5555PPPPPPPPPY~..:^~~~!!!?77!~~!~!7!~~!??7777!!?YY55BGGG5Y5PBBB##BGGGBBG5J!7YG##G555YJ?JYPP5Y7^~7?YPP5J     //
//    Y5 ____ ____ _____________  _________        .__  .__                 __  .__ 1117          ^^^...:!?77?J7!!!~~!7!~~!J?7??77?J5YY5GBPGGGGBBGPPGGPPYJJJ     //
//    /_   /_   /_   \______  \ \_   ___ \  ____ |  | |  |   ____   _____/  |_|__| ____   ____  ????JJJ??J?Y5PGBBGGGP5GGPYJ?JJJ77YY7^!?YP5555PG5Y?JYYJ??JJJJ     //
//     |   ||   ||   |   /    / /    \  \/ /  _ \|  | |  | _/ __ \_/ ___\   __\  |/  _ \ /    \ YJ5PYJ5YYYGB#BB##BP5?Y5PPPPPUGLYSTEFFYPPPPPPPPPPPP55PP55YY55     //
//     |   ||   ||   |  /    /  \     \___(  <_> )  |_|  |_\  ___/\  \___|  | |  (  <_> )   |  \!!7JJJYY5YJ!~?Y5GPPGBG5Y????5?77?7?YJ~^7JY5J!!!!7JJJJJJJJJYJ     //
//     |___||___||___| /____/    \______  /\____/|____/____/\___  >\___  >__| |__|\____/|___|  /YYJYY55BBGB###BG57J5PPPPPPPPPPPPPPPARTPPPPPPPPP5555555555PPP     //
//                     gm                 \/                    \/     \/                    \/PGB#B####BG5J5PPPPPPPPPPPPPPPMakePPPPPPPPPPPPPP555P5Y5Y5PPPPP     //
//    Y555Y5PGBGY?????JPYJ55PPGB####GYJ555J???77J5BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPG5!^~!7Y7~~~~!J7~~~~~!!7!~~777777777!~:^J5JYPGGGGG57!YPGP5J!Y5PGP?~?PPJJYY     //
//    YYYY5Y5PPYJJYYYYYPP5Y5P5G#####B5JJ55YJJ?????YGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP?!Y5P5J?!~~!!~^^^~~~!77!77777!!!~~:.:^75Y?YGGGGGP5PGY!7J5PPPP57^~?5YYJJ     //
//                                                                                                                                                               //
//                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract S1117 is ERC721Creator {
    constructor() ERC721Creator("1117 Collection", "S1117") {}
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