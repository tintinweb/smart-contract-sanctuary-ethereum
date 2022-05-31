// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Still Life
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
//                                                                                          ~?:!:.:. .^.! ..^7.!!:                                                                                                //
//                                                                                  ^.:~...!. .^^^.^?Y::?.J:J!Y^^!7^~~:!7!^                                                                                       //
//                                                                          : .   .. : .~....^::.:~.:~!Y~!?7^!?!!7!?57PPYY^P~!PJ57G                                                                               //
//                                                                     ^.^..  :.^...:^! :..:.~...:??P:7!!!~??^55?~YJJ7Y?J555P75GB#B5P!^                                                                           //
//                                                                  ~ . .  ..:.....^::.~7:~J?7J^.?~~?7P5J!J^J?5!?YPJBP#BBB#G#J5PBBYGPY!G755?                                                                      //
//                                                             ..   ... ~:.:~.^.:~:^~:.^^:[email protected]#PBPB##&#YGJG555##B#G                                                                  //
//                                                             ..:::.  :. ..:~.^^:^:^5J~.^^!~!?PYP5#GG&BB##BJYP5G555#GBB#!YJJ7G5BGG#&##[email protected]&&&&&@@#                                                              //
//                                                        :  ..^........^~^^...^.7^:~.~7^~P!!!G5GGJPBB####P&##G##[email protected]#BBPPG5P5##P#BB5#@&#5GB&#@@&#@@@@[email protected]                                                           //
//                                                    :.. ..::  . ..:.::.:.^:.^~!~^:7Y:!:^~!^^[email protected]&@#&##&&@#@###BP&G5P!PBGBY&B&##Y#BBG&G55G5#@@@@@[email protected]                                                        //
//                                                     :  ... ^....^::^:~^^::^7^7.7~7:.:^?^.:^?!~7?GYB&[email protected]&B###B&@#PPGPPBB#Y#&B#&[email protected]@&@@&&5##YGB&@@@&&@&@@@@&                                                      //
//                                                :. . :. ..^....! :.^:~~!!~~~.77:.^.~!!~J!^7:~7~7!?&[email protected]#####&@&G#G##GBB&#@JP5&B#&&@&&@@&&@@@@##G&&@@@@@&@@@@@&@                                                   //
//                                               . .^:..: ..... :!.~~!::7^:.~~7~7.:.^^^!J7~!7^Y!!!?JJ5BB&&GG##&#&#&G5B&B&@&PG#&[email protected]&B##@&&B&&&@@###@@@@@@@@&@@@@@@@                                                 //
//                                             .. ...... :.::.::^~..^::^^^^:~!:~^:~^!!J77??~?~!~7~~!7PG#B#G5B#GB#BGBYB#P5##&@##[email protected]#&&@@@@@@@&@&@@@@@@#&@@@@@                                                //
//                                            !. . :.^::.~.^.?:.^~!?^.^!^7.^J:^^!J!~~~.::^Y7^.:~^~575PP#&&##&##B&@GYP#PB5G&#P#[email protected]@PP5##&@@@@@@@@@@@@&@@@@@@&&@@@@@                                              //
//                                           ..... . .:...^^~~::!^:J7.!:.^G:7PG5^5!~^:Y!?^75??J~5JPJP5#PBB#B&&[email protected]@BG!P&GBB&#BB#&@@@@@@@@&&@&@#@[email protected]&#@#@&&@@@                                             //
//                                          ^...:.:.! ~^!^:^.^: .?!^7^:?~!J5YP^YG^5P!~^PJ^J?7~P?J5YGYPGG#&PB#&[email protected]?5Y5&&@&G5P&7PP#YPP#@@@@@@@@@@&@@&@@@@@&@@@@&&&@@                                            //
//                                         ^:::.:^:::.:::.:~^^^!^~:!~?^7~!7?J!J!~PYYJGYPJ??J5?G^YJ~55#G#B##B&@#GGG5BYBPP?&&&#B~##PBB#P#[email protected]@@@@@@@@@@@@@&@@@@@@@&@@@@@@@@@                                          //
//                                        ^::..:::^~~:~:.!!7^!^^^!7?^~?J7!!!.7~^7JP?BGY5GPYB5BGGBG#&GGP?B#&B#BBG##[email protected]@&?7PBGB##B&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@                                         //
//                                       .^:~:..?:^:^.!:!:Y::!:^777?!7~!:?:~~~5?BGP&BPPJY#PG5Y555&@@&@@@&#B#&&B#PB#&[email protected]#GBGBB##&#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@                                        //
//                                      ^7^.^?7~7!7JJ:J!:P77~~7~7^~YJJ::~^!:P#J5PBB&#BGGYBP5JBGG5Y&&@@@@@@&##@BBGBG#5PG#5&B:PB#&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@&@@@@@@@@P                                        //
//                                      ~7:~~^!:?^~5^^~^:^7Y7~~?~J!JGY:.~.:^J:PBYBG&#&YBPJJ???7B5YYY55#@@@&#G#B##BPBBPP?P#G5BY&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@                                       //
//                                      ::~^7Y7^:^!?7^77~77~5G7?J?7PP7. :^Y?:~PY75JGB#5G5Y?7~^^^^^?7JY#B&YBBG#B&GB#GG&#B###P5G#&B&#&#@@&##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                      //
//                                     ^~~^~^^77^^^.^:^:!~!^^[email protected]&BGYP?YY!^~75YYJ57~:!:.Y:~^~J?7YG5G&&##&@@@@G~P&G&#BB&&&##&@#&@@@@@@@#@@@@@&@@@@@@@@@@@@@@@@@@@B                                     //
//                                     !~~.:^~~J:~^~..^... ..:^7?!:^^^[email protected]^~~PGP?J&@@@@#&&##Y!Y!^?.!~ .:J~^^!J!JG&@@#@[email protected]#[email protected]&@#B&#@@@@@@@@@@@&@@@&@@@@@@@@@&@@@@@@@@@                                     //
//                                     ::.:^.7^?7?7^^5~B??^^^.^7~^::^[email protected]&@@#P7?!:.^[email protected]@@@@@@@@@@@@@@@@@@@@@@PG7^^~~ .J^^P?J&#&5&&&#@@@@@PP&@@@@@@@@@@&@@&@@@@@@@@@@@@@@@@@@&@@@                                    //
//                                     7^.:..^^~.:~!~Y#J5YPJ7.^~7^[email protected]@@&JJ::.~?#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&[email protected]&P?G&PB#@@&@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@&                                   //
//                                     7.~^.^.:.~^7Y:[email protected]@J:..Y~Y.^#G&&@@#?^7!J&@@@@@@#&&&@&@@@@@&@@@@@@@@@@@@@@@@@@@@@@@#[email protected]&@@@@@@&&#@@@@@@@@@@@@@@@@&@@@@@&@#@@@@@@@@@[email protected]@                                   //
//                                     7.....:.^~J.~7~JJY^ :5~..:.^[email protected]@@@[email protected]@@&&&&##&@&@&#&@#@@@@@@@@@@@@@@@@@@@@@@@G^[email protected]&@&@@@#@&#&&@@@@@@@@@#@@@&&@@@@@&@@@@@@@@@@@@@                                   //
//                                     :  ..:7:~~5:: ~G&#PY^[email protected]@@?Y. .^Y&@J5P#&&B&&&##&&B&@@#&@@@@@@@@@@@@@@@@@@@&555#&&#@@@@@@@@G&@@@@@@@@&@@@@&@@@@@@@#@&@@@@@@@@&@@                                  //
//                                    ^   ~PP~^[email protected]@@@@@@@&@@@BY::77Y7!G&@@#5^.:~^B#GY?P#@#&&&&&&@#B#&&@@&@@@@@@@@@@@@@@@@@@@@&?7&#&&@@@@@@@&&@@@@@@@@&&@&@@@@@#@&@@@[email protected]@@@@@@@@@@                                  //
//                                    .::7::7&@@@@@&&@&#@&&&&#G?7JY&@@@&PPPJ?^^!7~JJ~GP&B#[email protected]@&@@&@&&&B&&@&@@@@@@@@@@@@@@@@@@@!.!^[email protected]&@@@@@@@@&&&@#@&&@&@#@@@@@@@&&&&@&@&@@@@@@@@@                                  //
//                                   5J^P:[email protected]@@@@@&&&&&@#&#&&7.?!~  ^&@@@@GY?^GP!.::?P5&@&&#B&&&#@&@&&&@&&@&@@@@@@@@@@@@@@@@@@Y.:Y&&#&@#&@@@@#&@@@&@&@@@&@@@@@@B&&#@@#@@@&@@@@@@#                                  //
//                                  #^ ^[email protected]@@&@@&#@@&&#@@&G:JPJ.^:  :[email protected]@5Y?!77. ^:YP5G#&#BB##&#&&&B&@&@&&@@@@@@@@@@@@@@@@@@@@^~YB#@@@##&@@@#@&@&&&@@@&@&@@@@@@&#&@&@@@@@@@@@@@@                                  //
//                                  :.~#@@@@@@&@&&&&@&@B#P~ @&~77::[email protected]&PYP~^^!^#@&&@B##&##@&@@@&&&&@@@@@@@@@@@@@@@@@@@@@@@Y:55P#@@&J&@@@@@@&@@&&&&@@@@@@@@@@@&&@@@@@@@@@@@@@@P                                 //
//                                 [email protected]@@&@&@&@&#&&@@#&P^ [email protected]@@JG:~G?!#@5?G757.:J#&&&@&@@@@@@&@@&@@@@@@@@@@@@@@@@@@@@@@@@@@#5:YY5P&@@@@@@@@@@@@@@@@@@@@@@@&@&@@@B&@@@&&&@@@@@@@@                                 //
//                                 !^^[email protected]@@&&#&#B&B&&#&&G5. @@##@@@@P&7G&BGB#G#[email protected]#[email protected]@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B .!^[email protected]@@@@@@@@@@@@@&@@@@@@@&@&&@@@@@@@@#@@@@@@@@                                 //
//                                 ?:[email protected]@&@@&B&@@&#B&&[email protected]@@@@@@@@[email protected]&@@@YYJ?~&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B^.J5^::[email protected]^[email protected]@@@@@@@@@@@@@@@@@@@@&&&@@@@#@@@@@@@@@@@@@                                 //
//                                 .^.Y#@&&&&##&#&&&&&#[email protected]@@@@&@@@&7~PP#&#G#GPG#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@# ^?!~^..#[email protected]@@@@@@@@@@@@@@@@@@@@&@&&@@@#@@&@@@@@@@@@@                                 //
//                                  ~^.&@@#[email protected]&[email protected]&&##B&#B^&@@@@@##@@@J~~B&#&##[email protected]#@B!!J~??7:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@Y.55P~7:^5B##5?##@@@@@@@@@@@@@@@@@@@@#@@@@@@#@@@@@@@@@@@@                                 //
//                                   ~:[email protected]&#@@&#&#&@&[email protected]@@@@@@&@@@@.P~75YB&#Y#@#@B5J57!~^:...?PY##@@@@@@@@@@@@@@@@@@&!7Y!P!!~.:JGPY5PG&#&@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@                                 //
//                                    !^[email protected]@&G&#&&&##@&#:^@@@@@@@[email protected]&@@&:7!~J&~5^PB##PPPGYB&P!~^~J?5G77.~7 ?^[email protected]!:.^BP&5&PGYYYBGPBPBJGP~?JYPP#[email protected]@@@@@#&&&@@&@@@@@@@                                  //
//                                     ^.YBB&&@@5&@#&&B?&@@@@@@@&&@&@Y^.~!^[email protected]@BJJY^5#@@@&#B#G&P&G&[email protected]@B#@@@@#BPG#[email protected]~^.^7J~Y5GJ5PY?#[email protected]&&&&&BB#@@@&@@@&@                                  //
//                                     :^[email protected]&#@&#&[email protected]&[email protected]@@@@@@B#@&&@#~.^[email protected]@@&55P#[email protected]@@@#J#B&[email protected]@##@@B##P55PG5^?:^:~~7?7#5P5G&Y5GBB5GPBP5??GP#P&@@@G#@&@&##@@@&@@@&                                   //
//                                     [email protected]&&&###@&&&[email protected]@@@@@#[email protected]&@@@@@~ .JG&[email protected]@&&Y&[email protected]@@@&@&[email protected]@B:J^7Y!77~7PJ^^.:^:.:^~!YPYBGY5G#Y#@@@##5YGBPBB#@@@@B#&@#@@@@@@@@@@                                   //
//                                     ~~&@@@&&&&&&&&&[email protected]@@@@&J&@@@&@@@@&..^[email protected]@PGY5PB#Y5P&BB#[email protected]!~!~77?:~^  . .~:^[email protected]@@G#&@@@&#P#&@@@@@@@@@@&@&&&@@@@&&                                    //
//                                    ?^[email protected]@&&@&@&@@&##&[email protected]@@@GJ##@@@@@@@@@~~.7J&@@#&&&BBBPPP55&PG5JJ:~~^:7JB&Y577^!!^^^!:: ..::^~JYPJJBG#G#@@@&B&&@&G&@@@@@@@@@[email protected]@@@@@@@@@@@@                                     //
//                                    ^ [email protected]@@@@&&@&@@&#@@[email protected]@[email protected]@#@&:[email protected]@@@@@B~::[email protected]@#&&@BG&JBG5?GG5?^^7!?J^PJJB#?^??J775B!~~!^^:~~YG5YPBBB&&@@#&&&#@[email protected]@@@@@@@@@@@@@@@@#@@@&@@@                                      //
//                                    !~:#@@@@@@&&&J?B&@&[email protected]@&^@@&[email protected]#[email protected]@B7Y^^:?7##B#57P&@[email protected]#~Y!?5P&@@@[email protected]@@@@@@@@&@@@@@@@@@@@@@@@@@&@@#@@@@@@^                                      //
//                                   ~~:?:[email protected]@@#@J^GPB&B&& @@[email protected]@[email protected]~P^!!?!BY&B&5BJ5#&@5#YBG5#?BB7Y~!J?5##BG5#[email protected]&G&PGB##GGPG&@@@@&@#@@@@@@@@@@@@@@@@@@@@G#&&&@@@@@@                                       //
//                                   :.Y:GP??G5#[email protected][email protected]@@@@#G!~JJJYYB###PGYJBG&B5PBB!Y5#G5YPG#Y?&#&@@@@@@&&&@@&@@B5B&#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@#@@@@@@                                        //
//                                   ^ ..YJBB#75#5GP?~::^!JP57J.5#7#@&5?^^:^~P&&&&BPYYBBP&[email protected]?7P5BP&#&&@[email protected]#G##?GG&@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@                                         //
//                                    :  ::~Y7J!!?!~?~~^..?YJ?~? 5Y:5PJJ~~.:^5YJPYJY&[email protected]@@B#G5&5#5G&@&BB&[email protected]&@@&&@@&@@@@@@     @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&                                          //
//                                    ^ ....^...~!?^.^:~.^!~.!?!.:J:^77?7!.^[email protected]@@:[email protected]&#GBG&[email protected]#@&&@@@&&@@@@         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@                                            //
//                                     .  .  . ^.:!.  : .^7Y?^Y^.~JJ.^:J~!:...^P5!?~::::~B:&?B#[email protected]@#[email protected]@[email protected]&@@&@@@@            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                             //
//                                     ^~.....!!&&Y55: :^?~7^75#^:P .  ~??~  .:PGJYY:~:^~#BG75BJ5#@#G?#&P&@[email protected]@@@@@&@@              @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                                              //
//                                      [email protected]@&PP&@Y  ~7~5~::~&~5!  ~~~~!^. :#Y:~P#J:..:?&PB7?5&YJ#JG&@[email protected]@&BJ&@&B&#@@                 @@@@@@@@@@@@@@@@@@@@@@@@@@                                                 //
//                                        ?PP#        :.:.7~.:^Y!P:[email protected]@@@!::^&G#&&5YP!Y!?5&P!###@PB&&#@&B##&#@&&@@@&&&                     @@@@@@@@@@@@@@@@@@&&                                                   //
//                                                    ^..:.:::P&7Y [email protected]@@@@@@#P?.JG#[email protected]&[email protected]@@@&##55&&@&J#@&#&B#5G#G#[email protected]&&                         7                                                                 //
//                                                       YG^[email protected]@@@B~:J&@@&#@@:.~75G#G         Y^:P#G#!5B#GYJ##[email protected]&&                                                                                            //
//                                                     ^[email protected]@[email protected]@BG          #. ^7J5&B#        #^[email protected]~~YPP#7B&YJJB                                                                                                //
//                                                       G~&#               B!..:[email protected]@        B7:~#&GP^~J#&?Y                                                                                                     //
//                                                                            #[email protected]          @G?!YGB?#P&Y                                                                                                        //
//                                                                                                                                                                                                                //
//                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract STLIFE is ERC721Creator {
    constructor() ERC721Creator("Still Life", "STLIFE") {}
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