// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Golden_FNIX
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#&&##########################&###&&#####&&&&    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##&&#&&#################################################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#########################################################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##################################################################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&########################################################################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&##############################################################################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#########################&G5?5&&##################################################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&######################G~P?!GB7.:B##YB#&#############################################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&#################B##YYB###[email protected]&#GPBB#########################################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&&&&##&##################&Y:^7YGB##GG:Y#G7::^[email protected]@@&555B#########################################    //
//    &&&&&&&&&&&&&&&&&&&&&&&&########################GG?!JPGP&&@&J!~:..:^^7&@@@@#GP&&&#######################################    //
//    &&&&&&&&&&&&&&&&&&&&&&###########################&&Y55G&@5PBBP~~!~~!?PB&&&&&&#GG###&####################################    //
//    &&&&&&&&&&&&&&&&&&&###########################&#5BB^P&@@#[email protected]&JJ5GG57~Y&#&&&@@@@#5GGG&&############BBB#BBBB#BBBBBBBBBBBB##    //
//    &&&&&&&&&&&&&&&&&############################&&####GPB&&GP#PP#GGBG5~~YG#&@&@@@PPB5GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    &&&&&&&&&&&&&&############################&@@&@&&@&G5YPYYBB#&#P5PJBGPP#&@&#&B?JPPPPJ5PYBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    &&&&&&&&&&&###########################&&&@@@@&&&&##G7!7Y5BB&&#&@@5J5BYP&&B5J!?JYJ?^.:G?GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    &&&&&&&&&#############################@@&@@@&&&&#BBBY~7~~J5B&@@@@&JJ55JYP5!5J?Y!....~BYJBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    &&&&&&#################################&@@&&&&&&B~^:7YGP#&G5G&@&&@@PP#&&P!~7~!J:....JP7YBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    &&&&&&##################################&#&@@@&BJ~...:~?PB&#GG#&@@&^~#@@:.^:.::.^^:!#BJGBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    &&&&####################################@@&@&&BB7 ...:^!J!?G&#55&&:.~P#J.::.....^^^J55GBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    &&&###################################&@@@&&&&#J~:...!5BGYYG&@&G5Y~77~^::.....::^^!5PBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    &&&&#################################&@@@@@@&#GP?77!~~7!7JP#&@P:...~7775Y7:::::^~^PP?BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB    //
//    &&###################################BB####B5YYYJJ?!~^:^~7J5BB!:..   ..:YJ7!!^...~GPY##BBBBBBBBBBBBBBBBBBBBBBGBGBBBBBBBB    //
//    &&####################################&B5?JB#PJ!~^^:^^~!:.?PPG#BYYG7 .:.~JY!!~:^!YBBGP5BBBBBBBBBBGGGGGGGGGGGGGGGGGGGGGGG    //
//    &##################################BBBBY~^!GPY~~!^^^^^:!7:.~?7!7YBJ~75J^^Y5!755?P&&&#YGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    ##################################BBBBG7~~Y57?!!!^...:^??!7^:^:^7?Y#BB?^:YP!~!^~J55YP5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    #################################BBBBBB#&&&&&JJ?77^ .::!?!??~^^!J5G5?P?^:?Y7:::7J~~^?GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    ################################BBBBBBBB##&##B###&#~.^?P5YJ~!:!YP##57GJ^.7J7:~~::..:YGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    ################################BBBBBBBBBBB75#&&@@@J^7JYYJP~~.JGG#B?!G7::!777:..:~.!5GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    ###############################BBBBBBBBBBB&GP#@@@@#7?5J!::77..YPB&#P5#JJPY!^::.:7!JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    ##############################BBBBBBBBBBB&@&&@@&@&&###P?!~7?~^7YPP55J77PB?^~7~^??YGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    ##############################BBBBBBBBB#&&&@@@@@@&@@@P?77!^^:^!7?JJ?J?JY!::^~7YPPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG    //
//    ##############################BBBBBBBBB#@&&&&&&@@@&&&B~:^^::~:~J5GBBJ!~^..:.:~7JPGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGP    //
//    #############################BBBBBBBBBBB&@@@&&@@&&@@@@#?~^^^:^.7J7~^:.:..^J?^!J5PGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGPPPGPP    //
//    #############################BBBBBBBBBB&@@@&@&&###P&@@@&#GBJ... ...::::.~?YPY??PGGGGGGGGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPP    //
//    ############################BBBBBB#&&@@@@@&&BG&@@@@&&&@@@&&#5^.!^...:.:^!7?JJJ5GGGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPP    //
//    ############################BBBBB&@@@@@@&G??#&&&@&&@@#&&&@&&#B55Y?7~~~:^JPGPPGGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    ############################BBBB#@@@@@@@GY!75BB&&&G#@&BBPGBGPGB57!!??!!YPPPGGGGGGGGGGGGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    ###########################BBBBB#@@@@@@B5?G77P#@&#&@@#G55P555JJ?J!JPPY7PPGGGPGGGGGGGGPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    ############################BBBBB###@@&[email protected]&&@@@@BPGBBG#G?!~7Y7GB?!??PPPPGPPGPGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    ###########################BBBBBBBB#@@GY#5:7#@&@@@@@@&5PG5Y?!?^7YJ7YG7?JYY?555GPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    ###########################BBBBBBB##@@[email protected]&&@&@@@&57JJ7~^^!P57^JJY????J77YJ5PPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    ###########################BBBBBB&&BG##GYB##&#&&&&@@B~~!7~::^^^::!G77J!JJ??YJ!~!5BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    #########################BG##BBB#@@@#G#&&&PYYB&#&B#&J!~7~..^~:..::J5JJ~?Y5??!~^^JJYYPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    #########################G5&#B#@BJ&@&#&&&Y~~!P#&#PGBJ?P#&Y......:!?J~::!7YPGP?7!^^:~?GBGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    ########################&@&#&&#&&B#&&#&#G!~^~JGGBB55GB&@&B!...::::~^:.::!75#&&&BGPY7^~?P##GPPPPPPPPPPPPPPPPPPPPPPPPPPPPP    //
//    ######################&&@@@&&B#&@&&@@&@&#J~Y5J5PPPPGYJPP7:.:^:.::^^^:.:^~7JP#&###&&&#5??P5YPPPPGGGGPPPPPPPPPPPPPPPPPPPPP    //
//    ##############&&####&@@&@@@&&&@@@@@@&@@@@P5GJ??PGP55??~:..:^^.::^7J55J~:!?77J#&#B#BGB##[email protected]@&&#GY5PPPPPPPPPPP5P555P    //
//    #########&&####@&&&&@@@&&&&@@@&&@@&G&&&@@#YJ?7?YJJ7!~~....:^::.:^J5PP557~Y5?~7YG&###PYPGG55PPB##&&&##BG5PPPPPPPPP555555P    //
//    ########&&###&&&@@&@@@@&&&&@@@@@@@BB&B&&&P7J7!?7J7!^^^^^^::::^:^J#&&&&##J!JY5?PG5P#&&B#B&&&&B&&#@@@&&&&##PPPPPPP55555555    //
//    ######&&#&@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&J!7J!~!~!!!7~!^^J5Y!7~!YPBGPY#&!.:~7Y?YB#&@@@@@@&&&##&##B#&@@&&&GP#Y5P5555555555    //
//    ####&@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@5~~JP~!!?!??!~...~J!B&#5J57:~!J&G^J!YGGB&@@@@&&&&#GP###B#5G&@@@@@##&#5Y555P555555    //
//    #&@@@@@@@@@@@@@@@@@@@@@@&@&[email protected]@@@@@@@@@@!~!GG~^?B?7~:^!:..7J#@@#[email protected]!?BBB&@@@@&#&&&B#BBB#B#BB#&@@@@@@@&#5555##GPP55    //
//    &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@?:~BG^^7?!~!::?:.~J?&#P5JG&&&&@B&&7?GG&@@@@&#####PBBPPBG#GB&G&@&&&&&&&PPPP#@&&BGP    //
//    &&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#&@@@#!^J&P?7!!::~!7!!7PJ^~!!^~&@@@@@@&#5~JB&@@@@####&##&@@&#B#G5#BB#BGPP5?GG75PG#@@&GG    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@&##G&@&#BY5YJ5!^^:^!!:^J!^7JY#Y!7B&@&@@&@&BP7P&&@@@###B#&&&@@@@#B#GBBBBJ777!^7BJ7755#@@BP    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@&B#&@&J5&@@@&GGP##PJ7!?!^^J!:~?~~Y&#BB#&&&&@@&##B&@@&&&#BB###&&&B&@&BGGBBB#BGPYJ!~P7!7YP#&@@&    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@&B&@&&@@@@&&GG#&##BGB57Y#&5~?PG5?#&#GP##&&#BB#&@&&@@&&BPPG#B#&G75&&#GPBBGBBB5YYPJ?~~^?5###&#    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@&&#GPGB&#BPPGBP&&&#Y5GGG##BGGB&BY#&@@@@&&&&@@&BGPBG&&#P#&&&BGGGPG5#~::::^^!^^7Y5?J?    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@B#@@@@@G7~Y&GGJJB#GBBGYYPBY?YB#PPGGB&&&&###B&@@@@@@@&&&B&@&#GGG#&#B&&BB#GB??P5&Y.....:~~:^:!:::    //
//    @@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@&G&@@&BJ~^[email protected]@@GP#GG#&#GYP&BBGG5&@@@@&@&@@@&&&&&&&&#Y&&&BGPPBBB&@&[email protected]@5. ...~!:^.:...    //
//    @@@@@@@@@@@@@@@@@@@@@@@&@@@@@@#[email protected]@@@#&@@@@@&G&@@@&@&P#&&B#BP#@@@@@@&#@&&#&&&&&&&B&@@&5B55GB#[email protected]@BB##@[email protected]@@#^ ..^!~~.....    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#&@@@@@@@&&@@&&&&@@&&@&@@&#&#B#&&&@@@@&&&@@@@&&[email protected]@@@[email protected]@@&#&#^[email protected]@@@7 .7!~^ ....    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@&&@@@@@&@@@&B#&&&##&@@@@@&&&&##&&&&#B&@@@@@&B#B?!7B&@&#&@[email protected]@@@?.~B#. ....    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@&&&#B&&&&&&@@@@@&###B#&&&&&@@@@@@@##B&@&BB&&&&@@&:[email protected]@@@^:P&. . .:    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#7P&&&@&&###BPGB&@@&&@@@&##&&&&&&&@@@@@@@@@&&&##@@&&&&[email protected]@@#..:&@@&~7~? .  ..    //
//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G####@#BGGP5JP#&@&&&&&&#&@@#GB##&@@&@@@@@@&&@@@&&@#&[email protected]@@5:7&@&BY77:          //
//    @@@@@@@@@@&G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&G5PB&@BJ5PPPJ?GB#GB#BGGB&@@#GPGB&@@@##@@@@@@@@@@@&&&GYG5&@@[email protected]&B&J?#^ .   !    //
//    @&&@@@@@@@55&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#B#&@@@@77YPP55##B##B5Y5G&@@&&##&@@@@@@B&@@@&&@@@@@@&#5?!??B&GB&#PB&#&@G... ^&    //
//    ###@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@&7Y55P#&[email protected]&#PYP&@@@@@@@@@@@@@@@&@@@@@@@@@@&&B5~~!~7Y&@##5J#@@@@[email protected]    //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract GFNIX is ERC1155Creator {
    constructor() ERC1155Creator("Golden_FNIX", "GFNIX") {}
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