// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Symctrae OE
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//    @@@@@@@@@@@@@&&&&&&&&&&&###P~::::~GBY7!!!!?PB#BBB##BGPPP55YYYJJ???777777!!!!?J5PGB##&&&&&&&&&&&&#P?!!777?????????????JJJJJJJJJJJYYYYYYYYY55555PPP?!~~~!!!!77?JJYYY555PPPGGGBBBB#####&&&&&&&&&@@@@@@@@@@@    //
//    @@@@@@@@@@@&&&&&&&&&&&#####5~:..:^GBJ!~~!!75BGYJJJPGP55YYYJJJ??7777!!!!!7JPB##&&&&&&&@@@@@@@@@@@@@@#P7!777??????????????JJJJJJJJJJYYYYYYYY5555PP5?!~~~!!!!!!77??JJYY555PPPGGGBBBB####&&&&&&&&&&@@@@@@@@@    //
//    @@@@@@@@@@&&&&&&&&&&#######5^:..:^GG?!~~~~7YPJ~~~~755YYYJJ???777!!!~!?5B#&&&&&&&@@@@@@@@@@@@@@@@@@@@@@P77???????JJJJJJJJJJYYYYYYYYYYY5555555PPPGP?!!~~!!!~~!!!7??JJYYY555PPGGGBBBB#####&&&&&&&&&@@@@@@@@    //
//    @@@@@@@@&&&&&&&&&&&######B#Y^...:^PG?~^^^^!Y57^:::~Y5YJJ???777!!~~!YB&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&7~!!!!!77777777777777777777777!!777777777~~~~!77!!!~!!!77??JJYY555PPPGGGBBB#####&&&&&&&&&@@@@@@@    //
//    @@@@@@@&&&&&&&&&&######BBBBJ^....^PP7~^^^^~J57^:::~YYJJ??777!!~~7G&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&^.........................................::^!!!!!!!!!!77???JYYY55PPPGGGBBBB####&&&&&&&&@@@@@@@    //
//    @@@@@@&&&&&&&&&&######BBBBBJ^....^PP7^^^^^~JY!:..:~JYJ??77!!~~?G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@: ........................................::::::^~!!!!7777??JJYY55PPPGGGBBBB####&&&&&&&&@@@@@@    //
//    @@@@@&&&&&&&&&&#####BBBBBBBJ^....^PP!^::::~?Y!:..:^JYJ?777!~7B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&. .::^::::::::::::::::::^^^^^^^^^^^~~~^^:^^.....:^~!77777???JJYY555PPGGGBBBB####&&&&&&&&@@@@@    //
//    @@@@&&&&&&&&&&#####BBBBBGGBJ^:...^P5!^::::^?J!:...^JYJ?77!~?&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#...:^^^^^^^^^^^^^^^^^^^^~~~~~~~~~!!7!~^^^^:......:^~!7777???JJYY555PPGGGBBBB####&&&&&&&&@@@@    //
//    @@@@&&&&&&&&#####BBBBBGGGGGP7^:::^P5~:::::^?J!:...^JJJ?77!!&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:..:::::::::::::::^^^^^^^^^^^^^^^^~^:::::^^:......::~!777???JJYY555PPGGGBBBB###&&&&&&&&@@@@    //
//    @@@&&&&&&&&#####BBBBGGGGPPGJ~:..:^5Y~:::::^?J~....^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@! .......................................:::::......:^!7???JJJYY555PPGGGBBB####&&&&&&&&@@@    //
//    @@&&&&&&&&#####BBBBGGGGPPPP!:....:55~:::::^7J~....^JJJ?7!~&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Y................................:::.......:^^:......:~!7?JJJYYY555PPGGGBBB####&&&&&&&&@@    //
//    @&&&&&&&&#####BBBGGGGPPPPP5~..  .:5Y~:...:^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#^:^^^^~~~~~~~~~~~~~~~!!!!!!!!!!777!^:......:::::....::^!?JJJYYY55PPPGGGBBB####&&&&&&&@@    //
//    &&&&&&&&&####BBBBGGGPPP5555^.   .:5Y^:...:^7?~....^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?:^^^^~~~~~~~~~!!!!!!!!!!!!!!!77777!~^:......:^^:....::~!?JYYY555PPPGGBBBB###&&&&&&&&@    //
//    &&&&&&&&####BBBGGGGPPP55555^.   .:5Y^:....^7?^....^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G::^^^^^^~~~~~~~~~!!!!!!!!!!!!!!!!777!~:.....::^^^:::::^~7JYYY555PPGGGBBB####&&&&&&&@    //
//    &&&&&&&####BBBBGGGPP555555Y^.   ..YJ^:....:7?^[email protected]@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&!.:^^^^^^~~~~~~~~~~~!~!!!!!!!!!!!!!777!~^:..::^~!~^:::^~?JYYY555PPGGGBBB####&&&&&&&    //
//    &&&&&&####BBBBGGGPP5555YYYY^.    .YJ^.....:7?^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5:::^^^^^^~~~~~~~~~~~~~~~~!!!!!!!!!777?77~^^^^~~!~^:::~?JJYYY55PPPGGGBBB####&&&&&&    //
//    &&&&&&###BBBBGGGPP555YYYYYJ:.    .YJ^.....:7?^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#~.:^^^^^^~~~~~~~~~~~~~~~!!!!!!!!!7777????7!~~~~^::::^7JJJYY555PPPGGGBBB###&&&&&&    //
//    &&&&&####BBBGGGPPP55YYYYYYJ:.    .YJ^.....^7?^....~JJ??7!^&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J:::^^^^^~~~~~~~~~~~~~~!!!!!!!!!!777777??7~^^::...:^7JJJJYY555PPGGGBBB####&&&&&    //
//    &&&&####BBBBGGPPP55YYYYYJYJ:.    .YJ^.....^7?^....~JJ??7!^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@B^.:^^^^^~~~~~~~~~~~~~~!!!!!!!!!!!!!!!77!^::......^7?JJJYYY55PPPGGGBBB###&&&&&    //
//    &&&&####BBBGGGPP55YYYYJJJJ?:     .Y?^.....^7?^....!JJ??7!^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#B##&@@@@@@@@@@@@@@@@@@@@@@@@@@?.:^^^^^~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!~:........:7?JJJJYY555PPPGGGBB####&&&&    //
//    &&&####BBBGGGPPP55YYJJJJJJ?:     .Y?^.....^7?^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#BBBB#&@@@@@@@@@&&@@@@@@@@@@@G::^^^^^~~~~~~~~~~~~~~~!!!!!!!!!!!!!!~:........:7?JJJJYYY55PPPGGGBBB###&&&&    //
//    &&&####BBBGGGPP55YYYJJJJJJ?:     .Y?^.....^7?^....!YJJ?7!~^&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&#BGBB#&@@@@@@&&&&&@@@@@@@&~::^^^^~~~~~~~~~~~~~~~~~!!!!!!!!!!!~:........:7JJJJJYYY555PPPGGBBB###&&&&    //
//    &&&###BBBGGGPP555YYJJJJJJJ?:     .YJ^.....^77^....!YJJ?7!~^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@&&#BGGB#&&@@@@&&&&&&@@@&J^:^^^^^~~~~~~~~~~~~~~~~~~~~~!!!!!~:........:7JJJJJYYY555PPPGGBBB####&&&    //
//    &&####BBBGGGPP55YYYJJJJ??J?:     .YJ^.....^77^....!YJJ?7!!~^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@&#####&&&&&#####&&#Y~::^^^^^^^~~~~~~~~~~~~~~~~~!!!7~:........:7JJJJJYYY5555PPGGGBBB###&&&    //
//    &&####BBBGGPPP55YYJJJJ????7:     .YJ^.....^77^....~JJ??77!~^^&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&###&&@@@@@@@@@@@@@@@@@@&&&&&&#5!::::^^^^^^^^~~~~~~~~~~~~!!!7~:........:7JJJJJYYYY555PPGGGBBB###&&&    //
//    &&####BBBGGPPP55YYJJJ?????7:     .5J^.....^77^....~YJ??77!!~^^#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&&&##BBBGGGGGGB##&&@@&G?^:::^^^^^^^^~~~~~~~~~!!!!~:........:7JJJJJYYYY555PPGGGBBB###&&&    //
//    &&####BBBGGPP555YYJJJ?????7:     .5J^.....^77^....!YJ??77!!~~^:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&#BBBB##&&&&&&&&&&&@@@B7:::::^^^^^^^^~~~~~~!!!~:........:7JJJJJYYY5555PPGGGBBB###&&&    //
//    &&###BBBGGGPP55YYYJJJ?????7:     .5J:.....^77^....!YJJ?777!!~~^:^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&##BG5YJJ????JJY5PGBB#&&&@@@@@@#J:..:::^^^^^^^~~~~~!!~:........:7JJJJJYYYY555PPGGGBBB####&&    //
//    &&###BBBGGGPP55YYYJJ??????7.     .5?^.....:77^....!YJJ??77!!!~~^^:^J&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#BPYJ???77777???JYY55PPGB##&&&&@@@&BJ^.:::^^^^^^~~~~!!~:........:7JJJJJYYYY555PPGGGBBB###&&&    //
//    &&###BBBGGGPP55YYJJJ??????7.     .5J^.....^77:....!YJJ??777!!!~~^^::.~G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&BG5J???JYPGB#&&@@@@@@@@@@@@@@@@@@@@@@@@@@G~::::^^^^^~~~!!~:........:7JJJJYYYY5555PPGGGBBB###&&&    //
//    &&###BBBGGGPP55YYYJJ??????7.     .P?^.....^??:....!YJJ??777!!!~~~^^^::.:!G&@@@@@@@@@@@@@@@@@@@@@&&&#GP5YJY5PB#&@@@@@@@@@&&#######&&&&&@@@@@@@@@@@@@@~.:::^^^^^~~!!~:........:7JJJJYYYY5555PPGGGBBB###&&&    //
//    &&###BBBGGGPP55YYYJJJ?????7.     .P?^.....:??:....!YJ???777!!!!~~~^^^^::...~5&@@@@@@@@@@@@@@@@@&&##B#&&@@@@@@@@@@@@&&#GGGGBB####&&&&&&&&@@@@@@@@@@@@Y:.:::^^^^~~!!~:........:7JJJJYYYY555PPPGGGBBB###&&&    //
//    &&###BBBGGGPP555YYJJJ?????7.     .P?^.....:??:....!YJ???777!!!!~~~~~^^^:::....:!5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&#GGGGBB##&&&&&&&@@@@&&@@@@@@@@@@@@@P^.::^^^~~~!~:........^7JJJYYYY5555PPPGGGBBB###&&&    //
//    &&####BBBGGPP555YYJJJ?????7.     .G?^.....:??:....!YJ???777!!!!~~~~~^^^^:::.... ^#&@@@@@@@@@@@@@@@@@@@@@@@@@@&##&@&BGGGGB#&&&&&&&@@@@@@@@&@@@@@@@@@@@@@@5::^^^~~~!~:.......:^7JJYYYY55555PPPGGBBB####&&&    //
//    &&&###BBBGGGPP55YYJJJ?????7.     .G?^.....:??.....!YJ??7777!!!!~~~~~~^^^::::.:!?P###&&&@@@@@@@@@@@@@@@@@@@&&&#&@@&BBGGGGB#&&&&&&&@@@@@@@@@&@@@@@@@@@@@@@@G::^^~~~!~::......:^?YYYYYY5555PPPGGGBBB####&&&    //
//    &&&###BBBGGGPP55YYYJJJ????7.     .G?:.....:??.....!Y???7777!!!!~~~~~~^^^^::::5GGGB&&@@@@@@@@@@@@@@@@@@@@@&&&#&@@@#BGPGGBB&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@?:^^~~~!~:::.....:^?YYYYY5555PPPPGGGBBB####&&&    //
//    &&&####BBBGGPPP55YYJJJJ??J7.     .G?:.....:JJ.....!Y???777!!!!!~~~~~~^^^^:::?##BGPG#&&@@@@@@@@@@@@@@@@@@@&&#@@@@&BPPGGBB#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#:^^~~!!~^::::...:^?YYYY5555PPPPGGGBBBB###&&&&    //
//    &&&&###BBBGGGPP555YYJJJJJJ7:    ..G?^.....:??.....!Y??7777!!!!~~~~~~~^^^^:::G&&#GGGB##&&&&@@&&@@@@@@@@@@@&&@@@@&BPPGBBB##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@~^^~~!!!^:::::.::^?YYY55555PPPGGGGBBB####&&&&    //
//    &&&&####BBBGGGPP55YYYJJJJJ?:.   ..G?^:....^??.....!J??777!!!!!!~~~~~^^^^^::~&@&#GGGB##&&&&&&#@@@&@@@@@@@&&@@@@&B5PGBBB###&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@7^~~~!!!^^:::::::~?YY55555PPPGGGGBBBB###&&&&&    //
//    &&&&&###BBBGGGPP555YYYJJJJ?:.   .:G?^:....^??:....!J???777!!!!!~~~~~^^^^^::#@@@#GBB##&&##@&#@@@&&@@@@@@&&@@@@@B5PGBBBB###&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J:~!!!7!~^^^::::^~JYY5555PPPPGGGBBBB####&&&&&    //
//    &&&&&####BBBGGPPP555YYYJJJ?:.   .:G?^:....^?J:....7J???777!!!!!~~~~~^^^^^:[email protected]@@@#G###&@&B&@#@@@@&@@@@@@&@@@@@&B5PGBBB###&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P:!7!77!~^^^^:::^!JY5555PPPPGGGGBBB####&&&&&&    //
//    &&&&&&####BBBGGPPP555YYYYY?:.   .^G?^:::::^?J^...:7J???777!!!!!~~~~~~^^^:^@@@@@#G&&#@@&#@&&@@@@@@@@@@&@@@@@&BPPGBB####&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&^~77777!~~^^^::^!J5555PPPPGGGGBBBB####&&&&&&    //
//    &&&&&&####BBBGGGPP5555YYYY?:.   .^GJ~:::::~?J^...:7Y???7777!!!!!~~~~~^^^:[email protected]@@@@##@&&@@#&&&@@@@&@@@@@&@@@@@&BPPGBB####&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@J~777?7!!~~^^^^~!Y555PPPPGGGGBBBB####&&&&&&&    //
//    &&&&&&&####BBBGGGPPP555YY5J^.. ..^GJ~^::::~JY^...:7YJ???7777!!!!!~~~~~^^^&@@@@@#&@&&@@&&&@@@@@@@@@@&@@@@@&BPGGB#####&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&!777??7!!~~^^^~7Y5PPPPPGGGGBBBB####&&&&&&&&    //
//    &&&&&&&#####BBBGGGPPP55555Y~:....~GY~^::::~JY^:.::7YJJ???7777!!!!!~~~~~^[email protected]@@@@@#@@&@@&&&@@@@@@@@@@&@@@@@&BPGGB###&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P!7??J?77!~~^^~7YPPPPGGGGGBBBB####&&&&&&&&@    //
//    &&&&&&&&#####BBBGGGPPP5555Y~:...:~BY!^^^^^~JY~:::^?YJJJ???7777!!!!!!~~~~&@@@@@@&@@&@@@&@@@@@@@@@@&@@@@@&BGGGB#&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@77??JJJ?7!~^^~75PPPGGGGBBBBB#####&&&&&&&@@    //
//    &&&&&&&&&#####BBBGGGPPPPPPY~:...:!BY!~^^^^!Y5~:::^[email protected]@@@@@@@@@@@@&&@@@@@@@@@@@@@@@&BBBBB#&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@G7?JJYYYJ7!~~!?5PGGGGGBBBBB#####&&&&&&&&@@    //
//    &&&&&&&&&&#####BBBGGGPPPPP5~:...:7B5!~^^^^!Y5~^:^^J5YYJJJJ????77777!!!!&@@@@@@@@@@@@@&@@@@@@@@@@@@@@@&#BBB#&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@??JYY55Y?!~~!?5GGGGBBBBBB#####&&&&&&&&@@@    //
//    &&&&&&&&&&&#####BBBGGGGGPG5!:...^7#57~~~~~75P!^^^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#####&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B?JYY555J7!!7?PGGBBBBBB######&&&&&&&&&@@@    //
//    @&&&&&&&&&&&#####BBBBGGGGG5!^:.:^7#57!~~~~75P!^^^~YP55YYYYJJJJJ?????77&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&####&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@YYY55PPY?777JPBBBBBBB######&&&&&&&&&@@@@    //
//    @@&&&&&&&&&&&#####BBBBGGGGP!^:::^?#57!~~~~75P7^^^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BY55PPP5J???YPBBBBB#######&&&&&&&&&@@@@@    //
//    @@@&&&&&&&&&&&#####BBBBBBBP!^:::^?#P?!!!!!?PP7~^~!5PPP5555YYYYYYJJJY#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?J5PGGG5YY5PBBBB#######&&&&&&&&&&&@@@@@    //
//    @@@@&&&&&&&&&&&######BBBBBP7^:::^?#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@P^7JPGBBGGGB##########&&&&&&&&&&@@@@@@@    //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract A1337 is ERC1155Creator {
    constructor() ERC1155Creator("Symctrae OE", "A1337") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB;
        Address.functionDelegateCall(
            0xb08Aa31Cc2B8C0582bE42D38Bb643292e0A4b9EB,
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