// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Jenn Visuals
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    BBGG#&#&&##@@@&##&&@&&&&&&&@@@@@&#BB&&&#GPPJ7!JY?7J?7&#JYPJ5PPP55??~~^JPBGBBP?Y?&#Y5^^::::::........    //
//    &&#P5G#B#&&#&@&B&#&&&&&&##&&&&#BGGGGPPG5G5?!7?JYJ7?J?5?~~~!YJ!~^^^^!7~75PP5YP5~:?7:^:::::::.........    //
//    &#B#PJBGG&&&@@&&&&&&&#GPPB&##BBP5PGP5J5P5?J~7!755GG5YJG57Y?J?!~7!777~!!7YJ!JPG?!J77^.::.............    //
//    BGB&&[email protected]&&@&&@@@@@&&@@&#5PBB#G#BBGBGGGPP55GG?J!!7??J!75P#YY?!YG?JJ!^^?!~^^^:^!!^77Y5~::::::.:........    //
//    BBB#&@@G#&&&&&&&&@@@&BB&BGP5PGGGBGGP?JYJ?JY?!!7?5??JJYJ5YJJ?G57?7^^~7^~!~~!^~~:^~^!:::::::::........    //
//    ##&&&&&5GB&&&&&B#@@&&@@#GGPPG#BGYY5YJ???7!7PP??GG5Y7~!!!?7?JY!7PJ~^^^^?J777~^^^?!:^^:::::...........    //
//    &##&&&BY##&##BBG#&&&@&#BPGGGB&#BPYGB5?5?55YBPYGPJ?!~7YYJ7?~~J~^!~~~^^~!~^^^~^7Y?!!?:::.:::..........    //
//    &&#&##G5BBBB&@@&@@@@@&&&&&&#B#[email protected]#Y7Y55G5G#&GJ7~~7J?77!!7~!!!?~~^!!~^::^~7!J7::::::::.............    //
//    &&&@@@&&&#B#@@@@@@@@@@@@@@&@@&&&B##PP57G&&BGGY?~~!75YJJJJ!7?J!~~!~!~^~^:^^7?7J^:~^^::::.:...........    //
//    &@@@@&B#@@&&&@@@@@@@@@@@@@@@&#&@@@#?J5GG&#GB57???~~7Y?7?77!75775Y77J~~^~77J!!~~7?7~:.:.::..:........    //
//    &&@@&&B&@@@@@@@@@@@@@@@@&&&&&#&&@@&&G#BP55Y7??55Y?57?JJ~!!77~~7?J~~!~^!?!~7!?!~~^:::::..:...........    //
//    &&&&&&&&&@@@@&&@@@@@@@&&@@&&&&&&BG#B##5?JP?7JBG!~??!7?!!7?J7!7G7!7!^~~~7~::!!~^!!~^::::.............    //
//    Y5G#B###&&&&&&@&&@@@&&&&&&&&@&&&BGPPGJ!J?!??JGG7!!^~77??7!??YJY77^^^77~~:~!?~~~::!^::::::...........    //
//    ?55GBBBBB#&&&&##&&&&&&&&&#&&B#&#GY5#5JPGJ5YPPGGP???5557!77!~~~~^7J~~~~!!^~Y?!?~^~^^:.::::...........    //
//    5GGP#&GGB###&&&#&&&##BG#&##&&&&#PP#B#&&&GY5PG#BG??J!7!^^^^^^^^~^~::^~777?Y7777:~!!^^:::::::.........    //
//    55GBBPJBG#&&&&&&@@@@&B###&&@&B#&#&&&&&#GBBB55PP557~^~7~~~^~^!~~!~!~~^^?YJ!!57!YYJ?^^::::::..........    //
//    P5PB#P7PGB##&&&&#&&##&&###&&&@&&@@@&&#GGGG5?7?!??7777!7!!^!77??P57?7!^77Y?!?JJYP!^~:::.::...........    //
//    BPGBBY!YG#####BBB#&&&&#GGGB&&&&&&&&&#PPGGJ7?J7!77JY!7J7!7?7!?Y7?YPY7!^!?YY????!?~~:::..::...........    //
//    ####BJ!J5#&#&&&#&&&&&#&&&#&&&&&&&&&BGPGG?!Y?77~!!?YGB##B#BPY7!JPY?!!!~!77!~J55Y?7~:::.::...:........    //
//    PB###J?PGBBB##&&##&&&BB###&&&GPBGGGG#BG?!!~?7J!PPGGG55#&BJ5#BPPYJ??77????JY?!~7J5~.:::.::...........    //
//    Y5###P5GG#&&&&&&&&&&&&&##BPGP5YJ7YY5GYJ?~!!7!?7JY?G#BGPGJYPG#BBY!Y57!5Y5PPYJ77!?Y~:::::::.::....:..:    //
//    55PGY5555G###&&###B#&#&BBGGB##57?YJJYY5Y75G5YPPB#B#BP57?PG##PGBB###G5YPP##BP5PJY5!.:.:::::.:..:::.:.    //
//    GG#&5?P#GB&&&&#PPYYB#&#G###&&GGPYYYJJGYPB&BB5YB&B#GJ5?PGP5?P5PG##&555YG##&&##BY5J^::::::::::...:.:..    //
//    BG&&#7P&BG##&&P?J555B&GB#GB&@&#PGGP5B##&#GPBPJJ5PGBP?YB&B#BGYJGBG&BBGBBBG##BPB#P#!::::::::::.:.^..:.    //
//    GG&&B7B&&B5PB&&#B###&&&&#GBB&#BGBGG#&&&&BB&&GPBGGGPJGGG#&&##5G&BB#&###B#&#5YPGBGY^:::::::::.........    //
//    P5##G7#&#BG##PGGB#&#&&@@@&#B#[email protected]@&&&&&&&&B&&&GYGBBB#####B&&##&&&&&#P55P#&#&&Y:::::^::.::.:....:.    //
//    GG#&Y!5GP5G##GB###B#&&&&###&&#BGGPB&##GB#&&#GJY5JJGGPP##BGB##&&&##&&BGGBPY5G#PPBJ::^:^::::.:...:::..    //
//    BG##Y~?55GB#P?J7?YJ?YPB#BPBBP5PPPPGGYY555555Y55?5PGG555Y5PPB##&&&&&G5#@&BGPP555P!::^:~::.:::...:.:.:    //
//    &PGB?~YGG######BB#&BB##B##BP5Y5GGGGG55GPJJJ5P55PPPGGPP5JJPGGBB#&&BYP#&&&#GGGPBGP7:::^::.::::...:.:..    //
//    PY5?!~7Y55P555GB#&&##BP55JYYY5Y55G&&##&#GGGGBBBB#BPGBG5PPY5BPG#&#GG#B##P5PYP5#&#!^::^:::.......:.:..    //
//    !?YY!~5GGGB#BGBB#B&&57J7?YPGGG55YJPGBBGPGBGGGG##&&#BBGBBGJYB5G#G&P5#BBBPG5?PGG&#!^^:::^:.:::...:.:..    //
//    5GGG?!B5~?55YJYPPG#BGY5YYPPP5P5YJ5P55B#B##BGPBBJ~~~~7JB&&###BB#&PPB##&&&&&&&&BGG~:^:::::.::::.:.....    //
//    @&#BPP#BGPG&&##&&&&&&G5JYBBP555Y5GBBGBB#&GPGGBG!^^^.  .?#&&GG#BG?P##B##B#&&&B##G^^::::::::::.:......    //
//    &&##P?B&&&@&&&##&&BBGBBB##BPPPPY5GGGP###B5JPY7YYYYJ7:  .!B&&&&P755PGPPBGB#&&&#BJ:^:::::.:.:..:.:.:.:    //
//    P55P?~GGGB&&&PG55JJ5?JY?PB#PYYPY!?!!5BGBBGG5.7~~Y?^^^: ^!JG#BG5J5Y5BG###GG#&&B#Y^^:::::::::.....::..    //
//    GGGGJ~BBGGBB#B#&&&#B5J!7J5BYJJ~!^:!JGJ?GY5G:.Y775J7??7: .7?JP5PP?7?BB&#BBPP###&5:^::^:::::::........    //
//    PGGBJ~5PY5Y5GG5GBBBGYY5Y5GBJ?J77?J?JY?JG5PP:.P5YJ77JY?:  :7^JJJJJ?Y5YJGBGGBGGPB~:^:::::::.::........    //
//    B&&&Y!#B5GB#GGG##BBBBBBGB#BP55YYYP5YJJY5PG5: 7Y7?7!!?!.  ...^JPY??JYYJYYPG#BGBB~:::^:^:::.:::.::..:.    //
//    GGB#?!#&#####B######BBBB##BBBBBBBBBBBBBBBBP:  ^JYJJ7^.    ..!5B#BPPBBGGBBB##B#B!^:^:^:::::^:.::.:...    //
//    #BBB77B##BBBBB############################P::^. :Y?~~.    ..^?GB&########BBBBBG~^:^^^::^::::::.:....    //
//    #BBB!?#####BB#######&#####################B?~?:  :J??^    :!7JGB#&####BBBBBBBB5::^:^:::::::.::.:..:.    //
//    #BBG~Y#####&########&########B##############GY~~^~!?7:.  .?Y5#&&&#####BBBBBBB#Y:^^^^:^::::.:......:.    //
//    B##G~P&&###&#&&&&&&&##################&&#BP55J7??JJ?J!.  .?5JY5P#BG5####BBB###7:^^^:::::::.:.:.:.:..    //
//    BBBP~P&##&&&&&&###########BBB#########BGYJJ?!7JJYY555!   .:77?YYPPPY##########~:^^^::^:::..::.:.....    //
//    ###G~5##&&&################GPGBB###BPY??7!~~!?JJ555P!   .~!^~?55GGYPB########B~:::^.:::::::::.:.:...    //
//    &&&G~P####&###########&&&&#BPG##&#Y?77!~~!?5B&BY555P7.  .:JJ^^!!!?YPPPBB#####B~:^:::::::::::.:......    //
//    ###5~P&&&&##############&&&&#GG&@G~!!7JPG###&&&P555557 ...^^. . :JJGGPP5#####P:^^:.::..^:.::::......    //
//    ##&P~P&&&##########B#####&##GJ5&#J?G##&&####&&&GY5555~ .^:.......?J5Y5~Y&G###?:::.::.::::.:.........    //
//    B##G!5##&&&#####&&####B#BB#GY7YP^~JJYPB#5#&&&&&#YJYYY~.~!^.......7JY5~75B?G&B::::::...:..:.:.:......    //
//    G##G!5#####&&&&#&@&##B&&#BGY?77^^!777!!7?B#&##&BG?7?7~!~~:......^JYY5?Y5G:P#!.::::.:.:.:..:.........    //
//    Y&&G!Y#####&@@@&&@&&#B&&#&BJ77^~!7!!77!~!Y5G555??~^?77!!^^::^^:.!YYY?!!77!JJ:^::::.:.::.............    //
//    ^B#P!Y####&&&&###&&#G5B##&BJJJ!77!!!!?5#BYJ??Y?7!::?J7!7!!~~!!~^7JYY7^J55!^::^:......:..............    //
//    ^!55!5#5G##&&#GGBBBGPY5B#G5JJJJ77?J5G###PJ??7!7???J5Y77!~~~~!~~!JY5Y5PJ5J:^:........................    //
//    ^:^77?BYB#GPP5JJ?!7YY!5B5YY??JY?!!5J??777???!^!?JJJ?!~~~~~~~^^^!7?JJJY5Y~~~:........................    //
//    ~^?P55P#&#BGP5PGBGGBPPP5JYJ??JJ7^?J?777777777?J5PPP5J~^^:::^^^~!~77??5?^:~:.........................    //
//    B##BB###&&&&@@@&&#B5PPYJJJJ??J7^7JJ?7?77?7?Y5PY5555PP55J!~^^~7?7!7?J?^~:...:::^:....................    //
//    ######&&&@@&&&&&&G?55JJJ??????J?B5???5JY5Y5J5J??JJYY5555PY?7!777777?7:^:..^^^7?J~.............  .       //
//    &&&&&&&@@&&&&#BBY7G5JJ?!~~77!!5#P7?7?YJJYJ^~J!~~!~!7?JJJY5Y5J?!7JJ?7?^!^::^..^~!7. ............... .    //
//    ##&#&&&&&&#BB##Y!JYJ?7~^^!7!!~!?7!!!7!^!~~::^^^^~^^~~~!!!77??7?7!???7^^::!!7^::?7  ............:....    //
//    B##BBBGG5PGGG#B5JJ?!~~^~!7777?YJ!7~:~^::^~77~^:::^^:^^^~~~!77777!~~!:.   ..^PG7?!............ .  ..     //
//    BBBGP555555GP?7Y5!~!!~~!!YPY55Y!7~..::^^~~~!!~~^:.::::::^^^~~~~^~~:..::.:^7^YBP?!:........  .           //
//    555555JY5PBG?!~^!~7J55PGGPJ77!?~~:.:!7!~^~~^.....  .........................:^755Y?~::::::..........    //
//    BBBGBB#BGP5YY?!!^^JPPG#BPP?7~::^:...:!J77~:.                . . .......~^:......::^~~^:::.:::.......    //
//    5GG5GBGPPJ55YJ?JJ?7~^!?77!^~:.....  ..^^~^::.......................^J7JBG5PGP557:::....::....:::::..    //
//    5??77J7??!~^^:~~~^:..:^:::......................................::7GB#&#&&&#BPBGY?7:..:7:........       //
//    ?:...:^^:....:~~?~^^^^!~::::.::...::......................:.....^7GB##B#BBY!~:^:^:::...~:...........    //
//    B5PPJ?JBG5PP55Y5PYJ7~~!^^:^~!JJ!:^::^^:......:....::......:::!Y5G#&&&B5YYJ^.:^:^^~?5Y!^::...........    //
//    &@@&&&&&&##BGBGGPJ~^^~!YPPB###GJ?GBBB#GY~::::...::.:^7YPGGPPGBB#BGP5?7~^~~?55J^^JPBGP??J7^..........    //
//    GGGBBBBGJ7!~^~7777!!~~!!!JYY?JJ5PPP555GGY7^::::!JJJ5B#BY?PB#BBGBG55YJ?Y5YYJ?!:..:^~:..:::.......:...    //
//    !!~~^~77JY55PGGY?7JY7?YPJ~~5GPGB#&&##BPY77!!!~JGGBB#&&G??PB#&&&&&#BGY75P5Y~::::^JY?~:^::..:.....:::.    //
//    PY?!~77?P5B##BY7!JGBBY7??~:^~~?P5J~?PGG5Y5B#BB#B5Y55J?!^!?5G#&&###BB5^~^:.:::~!!J!~!YPP57:::....::..    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JVS is ERC721Creator {
    constructor() ERC721Creator("Jenn Visuals", "JVS") {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
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