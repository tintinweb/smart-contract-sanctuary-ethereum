// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JTJ - REWARDS
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                                                                             .7?JJYYYJJ:                                                        //
//                                                                                                                                    ..       JP777?775&^                                                        //
//                                                                                              ..::^^^~~~~~~~~~^^::...      .:~!^:!JPPP!     .B~:::::!G^                                                         //
//                                                                                      .:^~!7?JYY55555555555555555555YJ???J5PP5JGY?!~:^Y7    !G::^::7G:                                                          //
//                                                                                 .^~7JY55555555555555555555555PGGPP5GG5P#~^^:::?Y::::::?J.  YJ:^::?P:                                                           //
//                                                                             :~7JY55555555555555555555PPGBBGG#P!~^::^5G5B?:::^:^P~::^^::~J! G!:::J5.                                                            //
//                                                                         .^7J5555555555555555555PP555B5J?!~^:GP::::^::7GPB~:^^^:?P:::::::^?YP^::YJ                                                              //
//                                                                      .~?Y55555555555PGGGGGBGGGPYPG55GJ::::::!B^:^^^^::^Y#5::^^::BG55J7~^::~~::^G:                                                              //
//                                                                    ^?Y5555PPGGGPB55BY!!~~^G?~^::^5G55B~:^^^::PJ:^^^:^~::7B!:^^^:?&PPGBBBY:::^^:57                                                              //
//                                                                 :7Y55555PBJ7!~^:GPYGJ:::::J?:::^::JG5GY:^^^^:~B~:^^::YP^:^^:^^^::BBY5555B!:^^^:7G                                                              //
//                                                             :~!!?JY5PP5YPP::::::PP5G5::^^:7Y:^^^^::!PPB~:^^^^:JG::^^:^#G!::^^^^^:[email protected]:::::^#J.                       .::                                  //
//                                                       .   ^?!^^:::::~75PPP::^^::PP5PG::^^:!P::^^^:::^J#5::^^^::GY::^^:7&G?:::::::^B&55555G7^!?5G&BY!.              .:~7JYYY?~                                  //
//                                                .:^~~!!JJ !Y^::::^^:::::?BG::^^^:5P55#^:^^:~G^:^^:75~::!?::^^^^:~#?:^^::5#G5^:~7YP#&#555555GGGGGP55PPPJY!   .:^~!7JY55PY7^.                                     //
//                                          .:^!!77!~~^^::Y?P^:^:!Y5557::::7#^:^^^:YG5P&!:^^:^G~:^^:^PBJ^::^^::::::?&!::::!&#PGPB#BGP555555555PPPPP5YPG##G7!777?JJJ?7~:.                                          //
//                                    .:^!777!!~^:::::::^::G?:^:^P5555G5::::5?:^^^:!5YJ?^:^^::P?:^^^:^PBP?^:::~7YPGB&P!?5G##G5555555Y555PPPP5Y?7!~~Y55J7!~!!777!~:.                                               //
//                                  ~Y77!~^^:::::::^::^^^^:57:^:!G55555#J:^:7B::^^^::^^^:^^^^:Y5:^^^^:^BGPP?JG##BGP55PGGGP5YY5555555PPYJ7!~^::~7^::^:^~7JY5P5^                                                    //
//                                  ^BY:::::::^~7J5G5^:^^^:JJ:^:^GP555YBG:::7&^:^^^:7PP5::^^^:7#^::::^^[email protected]#G555&G::^!?J5GBY^~7JYPPP55555Y~                                                   //
//                                    JG!^~7?YYJ7~::GP::^^:~G^:^:[email protected]:^:[email protected]~:^^^:!BYB!:::::^&?^!J5GBBG555YY55555PPPP55YJ7!~^[email protected]&PPGPPB&GYYPPPP55555555555!                                                  //
//                                     ~5J?!^.      .&J:^^^:7P^:::~YGGGJ^::!&#?:^::::GPPP^!?YPB&BGGGP555555PPGGGG5B?~~^:::::^~!?&G555PP555G#BPP55555555555555555!                                                 //
//                                         .^:       PB::^^^:?B7:::::^::::?&#5P:::^!?B#5BBBBGPP555Y5PPG555GYJ7!^YPPJ:::!?JYPGPPP555555555555555555555555555555555~         .^!!.                                  //
//                                   .:~!777!7!.    !&5::^^^:7&BGJ!~^^^!JG&G55GYYG###BP5555555PPGBGP5JJB55B^::::~G5G^:^PP5YJPB555PP555555555555555555555555555555Y^ :^!J5GB##@&:                                  //
//                                   7G!^^::::~??7?JGY^:^^::^BBY5GBBGGBBBG55555PPP555555PPP5YJ?7!J&~:::PPYB5::^^:YPPJ::^JY5PGGPP5YP&55555555555555555555555555PGB##B##BG5J7~5&^                                   //
//                                    !57^:::^::^~~~^::::::7B#55555555555555555555PP55Y?7!~^::::::PG:::!BPPY::^^:~B5G^:^5YJ7!~^::::GB5555555555555555555555P#GGPYJ7!~^^::::J#^                                    //
//                                     :J5J!^::::::::::^!JG#G555555555555555P55YJ?!~^::::::::::^~!?#~:^:~7??^:^^^:YGPY:::::::^!7JY5GG55555555PGGBB#B5555555&J^:::::^^^^^^:J#^                                     //
//                                       .!Y55YJ?77?JYPB#BP5Y5555PPPPPGG555G&!:::::::::^^^:^7J5PPPG5::^::GPGJ:::::^#PB!~7JYPGGGGPP55555PGBBBGP5Y?77&G55555P#~^^^^^^^^^^^:?#^                                      //
//                                          .:!7?5BBGGP555PPPPP5YJ?!~^~##555&#!::::^~!~:^^:^BG55555G!::::?B5B7!?YPG#G5GGGGP55555555555GB7!~^^::::::P#Y5555BP:^^^^^^^^^^^7&~                                       //
//                                               !555PP55YJ7!~^::^~!7?JG&[email protected]&JJY5PPG#~:^^:!#555555P^:[email protected]^:^^^^^^^^^7&55555#?^^^^^^^^^^^!&7                                        //
//                                              .P###GGP5J^::!YPPGGGGPP555555PBGPP555YBB^::::?#55555PPPB#BG55555YYYY555PPGGBB########BG#5^::^^^^^^^^GG5555#~^^^^^^^^^^~#J                                         //
//                                            .:~5P5J?7!^^^^^~7JYPB&#P55555555555555555#P:^~7J#P55555555Y5555555PPGB###BGP5YYJ?????JY5PG##GJ~:^^^^^^?#555GP^^^^^^^^~~~B5                                          //
//                                      .:~!7???7!!!77?JYY55PPPPP55555555Y5B555555555555#GGGGP555555PGBBP5PGBB#BGPYJ7!~^^::::::::::::::^^!JG#P~^^^^^^GP55BJ^~~~~~~~~~PB                                           //
//                                :^7?JYYYJJ?7!!!5PPPP555555555PP55YJ?!~^^^[email protected]@#BPY?!~^:::^^^^^^^^^^^^^^^^^^^^^^^^!G&7^^^^^?B55#7~~~~~~~~~Y&:                                           //
//                           :!?Y555Y?!~^:..     J555555PPPP5YJ7!~^::::::^:!&G5555555555PPGBBGPY?!~^:::[email protected]#^:::^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^P&[email protected]                                            //
//                           :^:..               ?PPPP5Y?7!^^::::::^^^^^^^^:J&5555PGGBBGPY?7~^:::^^^^^^^[email protected]:^^^^^^^^^:^^^^^^^^^^^^^^^^^~~~~~~~!&Y~~~~~?BPG~!!!!!!!7##~                                            //
//                                         .^~7??J?7~^^:::::^^^^^^^^^^^^^^^^^B#BBGPY?!~^:::^^^^^^^^^^^^^~#@!^^^^^^^^!YPPGGGG5?^^~~~~~~~~~~~~~~!&Y~!!!!!P#5!!!!!!!!G&5:                                            //
//                                    :!7?JJ?7~^^:::::^^^^^^^^^^^::::^^^^^^^:[email protected]~^:::^^^^^^^^^^^^^^^^^^^:[email protected]^^^^^^^^J#[email protected]~~~~~~~~~~!!!!~Y#[email protected][email protected]#Y                                             //
//                                   .#G~^^::::^^^^^^^^^^^:::::^~!7JY~^^^^^^^^BY:^^^^^^^^^^^^^^^^^^^^!7J5BB?^^^^^[email protected]~~!!!!!!!!!!!Y#?!!!!!!7!Y?77777777JPB5!.                                          //
//                                    7&!:^^^^^^^^^^:::::^~7JYPBB#BG#P:^^^^^^:?#^^^^^^^^^^^^^^^~!?YPGGGGPG#~^~~~~~~~~!B555555#@Y~!!!!!!!!!!?GB7!77777777777777777777?YGG5!.                                       //
//                                     Y&~:^^^::::^^!7J5GB##BGPP55555#7:^^^^^^~&7^^^^^^^^^~7J5PGBGP5555555&[email protected]!!!!!!!!!!?P#BB777777777777777?????????7?YGGY~.                                    //
//                                      GB^:^^!?Y5GGB#BGP555555555555PB^^^^^^^^GP^^^^[email protected]?~!!!!!!!!!5BPG&#57!7777777JPBG5Y#57777777????J?7?????????????J5GGY~                                  //
//                                      :#B5PP5J7~: :YY555555555555555#J^^^^^^^JB^^^^[email protected]#B555555555##!!!!!!!!!!!5PPJ7!7777777JBGP5555P#?7?????????##5????????????????J5GGJ^                               //
//                                       .~^:     .^!5G555555555555555GG^^^^^^^7&!~~~7&GPGGGP5Y?J&#[email protected]!!!77777!!!!7?7777777?5GP55555BG7?????????Y#GBPJ??????JJJJJJJJ??JPGP?:                            //
//                                           ^!J5PPPYJ&B555555555555555#~~~~~~~!&7~~~~?YJ7!!~!!?JG#55555PGB##[email protected]&J!77777777YPPGG?7?????7?PBP5555&[email protected]@Y                           //
//                                          Y#YJ7~^^^:7&GY5555555555555#!~~~~~~7&[email protected]&?77777777Y#55BB?????????JGBG5YG#???????JJJ?BGJ:!PGYJJJJJJJJJJYPB&&#57^                           //
//                                          :G7:^^^^^^^7&G5555555555555#!~!!!!~?&7!!!!!!B#[email protected]??????7GBY5GB??????????YG#B5#P?JJJJJJJJJY&!   !PB5JJJJYPB&&#57^                               //
//                                           ^BJ^^~~~~~^7BB5555555555YGG!!!!!!!P#!!!!!!!5#[email protected]????????#G55GBJ???????J??YG&#@YJJJJJJJJJJ5&^    !GBPG#&#57^                                   //
//                                            :B5~~~~~~~~!5BP55555555P#?!!!!!!7&[email protected]????????Y&P55GBJ?JJ???JJ5PB&@&#JJJJJJJJJJJB#^     !YY7^                                       //
//                                             .5G7~~!!!!!~75BGP555PBG?!77777!P&[email protected][email protected]?JYPB#&&#BG55#GJJJJJJJJJJJ&#^                                                //
//                                               [email protected]&J777777??????????????????JY5PGBB&#YJ?JJJJJ????#&555G#B#&#BGP5555555&5JJJJJY5PGB&@5                                                //
//                                                :[email protected]?????????????????JY5PGB#BBGP55P&J?J???JJY5PG&@B5555PP555555555555G&PPGB#&#BPY7~.                                                //
//                                                  ^YGPJ7!777777777777777Y#&PY5&Y???????????JY5PGB##BGPP55555555##JY5PB#&&&#BGP555555555555555555Y77PPY?!^.                                                      //
//                                                    .75GPYJ?7777777??YP#&G5555G#?????JY5PGBBBBGPP555555555555555#####BGP5555555555555555555555J!.                                                               //
//                                                       .~J5PGGGGGGGGGP5P5555555&PYPGGBBGGP5555555555555555555555555555555555555555555555555Y7:                                                                  //
//                                                            .:^^^^^:.  .^7Y55555PPP55555555555555555555555555555555555555555555555555555J7^.                                                                    //
//                                                                          .:!?Y55555555555555555555555555555555555555555555555555555Y?~:                                                                        //
//                                                                              .^!?JY5555555555555555555555555555555555555555555YJ7~:.                                                                           //
//                                                                                   .^~7?JY5555555555555555555555555555555YJ?7~:.                                                                                //
//                                                                                         .:^~!7??JJYYYYYYYYYYYYYJJ??7!~^:.                                                                                      //
//                                                                                                    ...........                                                                                                 //
//                                                                                                                                                                                                                //
//                                      :JPPPYJ???JYY?::JP5: .JPJ.   ^?5PPPY!       ^YPGBBBG57.   .!YPPP5?: ~PBP7      7GBGJ.   .?GGJ.    :YPGBBBG5?: :!~::::.      .!YPGG57.                                     //
//                                     .#@@@@@@@@@@@@@&&@@@P [email protected]@@G :[email protected]@@@@@@@P      [email protected]@@@#&@@@#^ ?&@@@@@@@&!#@@@@!    [email protected]@@@@Y   [email protected]@@@B.   [email protected]@@@#&@@@&^[email protected]@&&&&&BY:  ~#@@@@@@@#~                                    //
//                                      !PGGB&@@@#BB#B5&@@@G.&@@@# [email protected]@@#GB&@@P      [email protected]@@[email protected]@@@[email protected]@@&GB#@@#[email protected]@@@?    [email protected]@@@@J  [email protected]@[email protected]@G   [email protected]@@B:[email protected]@@@[email protected]@@@@@@@@&7 #@@@&[email protected]@@5                                    //
//                                           ^&@@^  .  [email protected]@@[email protected]@@@P [email protected]@@! .^^:       [email protected]@@@&@@@@B::@@@P .:^:. [email protected]@@@~ ~~ [email protected]@@@#. [email protected]@[email protected]@@5  [email protected]@@@&@@@@#:[email protected]@@@#5&@@@@[email protected]@@@PYBPJ:                                    //
//                                           :&@@5     [email protected]@@@@@@@@J [email protected]@@&B##Y        [email protected]@@@@@@B?. ^@@@@B##B^  [email protected]@@@:[email protected]@[email protected]@@@? [email protected]@@@@@@@@? [email protected]@@@@@@BJ. :&@@@5 [email protected]@@@5 [email protected]@@@&G~                                     //
//                                           [email protected]@@@~    [email protected]@@@[email protected]@@5 [email protected]@@@&##Y        [email protected]@@@@@&P7. [email protected]@@@&&#G^  [email protected]@@@[email protected]@@&[email protected]@@&:^#@@@[email protected]@@@@@:[email protected]@@@@@@P7: .#@@@Y [email protected]@@@5 [email protected]@@@@J                                    //
//                                          .#@@@@5    [email protected]@@@^[email protected]@@#:#@@@?^7YPGJ      [email protected]@@[email protected]@@@#^[email protected]@@G^!J5GP:^@@@@@@&[email protected]@@@@#!&@@@@:.&@@@@@[email protected]@@[email protected]@@@&~.&@@@##@@@@@[email protected]@# [email protected]@@@@:                                   //
//                                          [email protected]@@@@G   ^@@@@@!&@@@@^#@@@&&@@@@@:    :&@@@[email protected]@@@@[email protected]@@@&@@@@@?^@@@@@@Y^@@@@@[email protected]@@@P ^@@@@@@?#@@@P.&@@@@[email protected]@@@@@@@@@[email protected]@@@B&@@@@#.                                   //
//                                          ~&@@@#~   [email protected]@@P:#@@@Y [email protected]@@@@@@G~     :&@@@! [email protected]@@#^ Y&@@@@@@#J. [email protected]@@@5  [email protected]@@#^[email protected]@@#^ .B                                                                              //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JTJREWARDS is ERC721Creator {
    constructor() ERC721Creator("JTJ - REWARDS", "JTJREWARDS") {}
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