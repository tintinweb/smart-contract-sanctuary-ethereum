// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: BUNGA
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                         :!!!7?!~!777~7?!.                                                                                    //
//                                                   .::^!!7??!!77!?J!!P7^!?!^:                                                                                 //
//                                                   7??J?!~~!JPPGYJJY!5!~^~5JY?!!??.                                                                           //
//                                                   7J!^^^!?YPBBBBGPP5PPPPP7!~!YJYP~^^.  .!!^.                                                                 //
//                                                  .!7!!?YYJJJ5GBBYYY5P555PY5JJ55JJ77P7  :5?5Y.                                                                //
//                                                   :^~7YY!.:~7J5GPPPP55Y555PPGG55J??JJ:  JJ5G~                                                                //
//                                     ..               .~~!J!7Y7^~!7YP7!?PPY5PP5YPY7YP!~  !Y7G5!                                                               //
//                                    ^J?:.~~:!J7:..       .?7?J~JJ^^~5GY777~^^JJ7JJ?7Y.   ^Y:JPP~                                                              //
//                               ^^~7!J!^J?7^JP!!YYY7~7?J!!!??. .Y!^7PG5Y7^~?7?Y7JY?~~7.   .?~~P5J                                                              //
//                           .^:^Y5JJ!J^.^Y7:^Y!:~5?Y!JY??J?7P:  ^!~7G5?!7!!....  ..        .J7JPP:                                                             //
//                          :~YJ7?5!:^77!~^7?!!5!J?~^~P5?!!!!P~     7JJY^.  .:::.            :YJ5P7                                                             //
//                         ~Y7~!~!?J~^~~J5J!J5YP5577?YY??J?!7P5Y?. ^5YGPJY77YPYJJ:            ~YY55.                                                            //
//                        .?YJJ7^:^!7?YJJGBYPPGGGG5PP55JY?!~^!5Y!  ?55PYPP5?JJYYY???^         :Y?5G7                                                            //
//                      :^77777!!7!!JPBG55YJ??J?PPYPPPPJ7~!7???JJ.!5??55JY5Y?7Y55Y5GY7:       .5YJGP^                                                           //
//                   ^7!JYJ??!^^^!JYYPGY77?J5PGGPYYJ5PGP5YJJ?!75~!Y5PP5YJPY5Y55GPJYBY!Y!       YP7555.                                                          //
//                 :.:?J?Y55?77?J??JY5P77PYPPPP5Y555P5GGY7~^^?YYY55Y7~^::5GPPP55PGGG5J5J      :5JY55B?                                                          //
//                ^57!^YYJ77?7~!?YPGGBGYYPPPP555PPGGYJYYYY?!75JY5P5?!!7!?Y5YY77JP5P5PPG~      !YJ5YYGG!                                                         //
//                .Y:~7JY~:..::^!7JYY5PGP55PGGGYYYJYYYJ775J??5P?J5PP5GG55Y5Y5J5P5?JGJY?      .JY7Y?555P~                                                        //
//               ::7!7?J557!!!!7J5J^:^J57!?JY?57^:.J5!!~:?5YJPP5JYJJ?J55PGP55Y5PYYYY!J?     .7Y?JYPPY555~                                                       //
//              .7JJ7~J555YY?Y7Y5P??7JB!..?~^~Y577!YY777!?5P5YPYY7YJ?^~J!?PGG5PP5?5GPJ:    .7!7J5PP7:~55Y!.                                                     //
//              ~??Y^~JJY7~J?Y5P5YJP55G~:JJ^?PP?:^!J7~7YJJJ7?JGG?:~Y~:~G57J?PG55PJ?5~.    ^?7!JJPY^   :Y55?.                                                    //
//             .??JYJJY?J~!7!?5P5J55J?5YYPYPGJ5PJJYJ:7:?JJ:!?!G5!^^7!!!P~:JJPG5Y7^.?!   .!7!7Y5Y~.     .?55Y^                                                   //
//           :!?J?J5GGGP5J57?J!77YP5YJJ5YPPYYYJJY5?JYJ?Y7J~7??P!~?Y5YYY?^^PPPY7^...!P: :?7!?557.        .7555!.                                                 //
//           ~?7?7?JPB5?Y577J577755?5JYY?PPYYY5YJYGBPYGJ~~JJJYP7~7GG5PG5JJP5J!77 ^:~YY??JY5P5~            ^JP5J^                                                //
//           ~7?J??555Y?YYYY??JJ5PY7J55GP5P5P5JJJJG5JYPY7YGY?7??Y5555GGG5YJPY7JJ!^.???JYGPP5?.             .!5Y5!                                               //
//          :!!J7!7??JYYPJ?Y55P5YYJJJYYJP55J5P??PY?Y55J77PBPY??Y5PJ55PGPY?7Y5?^:J7!P5YPGP?J~YY:              !YYP^                                              //
//          .^?~:^~~?77?JJ?JY5PYYP5YYJ??5?YJJJ?JYJ??PY7?5PPGBG?J5P!GG5GPJ??J5J^ :555JYGG5!YY77Y:              7JYY.                                             //
//            ~!:^^7~755J5J?JY55555PPGGYYY7J~!?55!!JP5?PPYYYGGPPYJ~YPPGP?7J5Y7~::5P?JGGGJY!Y?!JJ?:             :~!.                                             //
//             .?7J5YYGYYY5JPPGGPYYYP5GJ?J5YPPPYJ555Y?!P5???5Y?GY!~7YBG5Y!55?~^:.~YJPGG5JY:J7^?^?7                                                              //
//              ?!?555?~7JJ?YPYJJYP5PPP55PP5JPJ5PJJ5P7?5?!!!J~~Y55J77Y?~J5PYJ?7!7^^PGBYYJY~?..!!?Y.                                                             //
//              ~!~?Y!.^~7J5PP5PP5PGB5PJ7Y5P55Y5PP5G57Y5!^^~~.:J?YY^!Y~!?JB55!77^7!PG55YJ7?~.^  :5^                                                             //
//               ^77~:^~!??JJYJP5JPBP557?5Y5PPPGPPGBPJJP?..::^??~!??5YYJ7JGJJ^~~~7?GB5J7~?7.:..~?5^                                                             //
//               ^7~^::...:^~!?7!7P5Y5PYY5Y55Y?5PPPGP?YY57^?Y5JJ^.:~5Y5J??J557?JJ!YGP~~?~!^  :7?7Y^:.                                                           //
//                 .:^~~~!?!!~^^^J?PPJYY57?5??JYYY5P5Y7Y?5YYPP?JY!:?JPG?~YJ55Y5GP5PGJ~^!7?!~7J?!77~!7?^                                                         //
//                       .J:..:!7^:PY?5~!7YYYJY5YPP5Y!YJYYJJYJY77J??YJ??YP5YYYJ55YJYYJJYJJJYJ~^^~7^^~Y?   .:^:                                                  //
//                        ~!!!~:   ^?!!?..7777JP5PYY5^5PPP5PP?!Y:.~?J?YYJY5Y?~?5?^...:?Y7^^^^7J55?J7?~.  ^?~^77                                                 //
//                                  .^!?^ ....!JJP?YYJJGP5P5J:.!Y!^7JJ?J5P555Y55Y?7!!!!7!!?Y?~!JJYP?.  .7Y^. :5.                                                //
//                                          ^?!!7PY7?YYY!!?^. :~?J7?J?YYPPPPJ!~75JJJJYY5YJJ57 ..^^~?7.:JJ^^..^Y.                                                //
//                                          :^^~~^. ~!:.    :7?7?J5Y77YGBGG5J??77JYYJ?J5?!~!P~:^::^~?JY7~!~:^??                                                 //
//                                                       .^7?J5GGG5^^J5GGJJP?YJ?7JY5J7JPGYY5PY~77~7?JJ!!??7??Y:                                                 //
//                                                     :!J??5PY?PG5J~JP5~~?PGPYY!~^^!?55?~^!5GJJYJJPY77J555Y5!:..          :~^:.                                //
//                                                  :~?JJJ55?^.?B5??YGP^ ~Y5YY?YJ?!^:~Y!  .^75GGG5YPJ5JYY?7~~~!!77:     ^~!J^~?J~                               //
//                                               .~?YJJ55J~.  ^GGY?GJGP^!5JJ7^?!?PPJ!?! .:~7J5GBBBGPGBPY?!~^:..:!?Y.   !?^:. .:?P: .^~~.                        //
//                                            .^7JYJYPPJ^     JG5J?G?YG5P?7YY~7JJJ5GGYY7~!?Y5PBBBGGGGGG5Y?!~^:~?7JY?7!?J:..:^^!?B!7J!^7Y.                       //
//                                        .:!JYJ7J5PGJ:      ~G5Y?JB!?G5YJJYPYPY??5YJYPY:^~7?J5BGY5GPY5555YYY55YYYY^:7?:^^~!?YYPGJ5^:~~5!.                      //
//                                  :^~~!?Y55PPPGGG5~       :5G55PGB~~YBP?!?PPJ7?^7Y555^.:~^^~?5JJYPY7JYYJ5BY~:::~?~^!7?~7J55P?~!!~!?555J?7:                    //
//                                 ~5YJJJYJJJ?YGGG7.   :~:  ?G55GG?P!:!5PGJ~^7JY7^~~!JY.....:~JP!?7?J^?~5G5YJ~^~^^:^7Y?JJ5BGJ7!!J?77PGY7~:~Y~.:~7J7.            //
//                                 .^^^^:.. .!PPP7    ^5J?7?5~!7G5.?J.^?PGGY7^^!Y7^~~J7  :~!JY7??~~^~~7~JBB5Y5J777!^^5G5J7?5YJPPYYJ5P!~^:::7P??7J5Y.            //
//                                         ^JPGP!     ~PPJYPY~~?P7 ^5~:!YGPG5?!^^7?~~J!.!Y555P??5?^:.:.:7GBGYPG5Y55?JJG7^!!J5PJ!^::^!!!::Y5Y7~?J7P!             //
//                                       :?55GY^      .?BGGP5J?JP^!5JY7~75PPPPJ?!:?77JJJPPJJ55PJY5?7^:^^!5YJ?J5PPP55Y55YJ!!YG7::.  :^^7J5G?^~JYJ~Y?             //
//                                     .75Y5P7.         7GBGGGPGP?P7!7J?~?55GBPPY~~P??JJPP5Y5PG5JYYP?!^!5PPG55YYYYJJJJ?YJYY5GJ!^^~!?77!^?J:!YYJ!7J^             //
//                                   .~YY5PJ^         .~7YY?7!!!777!!!7Y?~?5GBGBG?~G5?!!!7JYGBPJYY!~!7J5G5J?7~~!7?7J77!~!JGYJ~!??!^!5YYYY~7Y557:J!              //
//                                  ^JYYP5!.       .^7?7!~!7?JJJ????7!77YY!!5BBBB5!PJ7!^:...~J???!!?5PYY5!:..  ..^~!^:..7GY~7~^7J!?JG5J7!?Y55J!:J~              //
//                               .^?YJ5P?:       :!7!!!?Y555YYY5YY55P5YY5GG7!5GGBGJGY?7~^::^!7J77?75GGPJ??!:.     .:   !Y?~7!?5PBBBP5J?J555Y?!~??.              //
//                             :!JJ?YPJ:      .~??77JYYYYJJJJJJYYY555YYJY5BB?!5PGGPPY5YYY77!!J?!5JJYG5Y?7~^^^~~^~~^~^:~J^!~?!^~!7J5PGGP5YJ?7???~                //
//                          .~?55YYP5~        ?5JJ55YJ??7~~~!^^~~!!7?J55YJ?PG775~75G5G57Y5!7J5~?J?7~?Y!:.....^Y755YP55J7~^~!J55?!!!7JPBG5J??J?!^.               //
//                       .^?YYYY5J7^.         ~?????7!~!7!!!??77!^^^~!7JY5J!J5J57?YPJJG!7P^!5Y?Y?77~:~!^^~!7^7YY55PPPGPJ?7~^!JPJ~::~!!JPY?7~^^!Y?^              //
//                     ^???J?J?!:                            ^5P5JY?!^~!J5!.:!YJ^YG7:^YPPJ^?PJ^?YY?7~::...:Y~YJP5PPP5YYY77?7:?PJ!^. .~7JG5YJ5J7^..              //
//                     ~J77!^.                                75YY57JJ??~!!.^!Y7.7PJ??Y75J?55P!J5YYJ?!~:.  7^?J55P555YYY!?5555Y7^:.   7!YPJ7?J7.                //
//                                                            .?YJ57??PY^^~!!?Y57!7JPG5!7PP??BGPGGGPY?~:  .?:?P55PYYYJ7?P5PPPG5J!:.   ^?7PJJ7?7.                //
//                                                             .J5Y5!~55?J7~!?JY~!J5GBBGGP5JJPBG?~7YJ!:  .!~^!7!YJ77!~~:~5BYJBB57~:.  7!7GPYJ7:                 //
//                                                              :5G?J5J5^755555~ .:!PBBBGPY7^:JB57^^??^.!Y~..::.!!~::..  ?BY5BB5?~:.:!7^Y5PJ!!J7.               //
//                                                        .:^^:. !GPYJ55..^!?YY7^^~?GBGPY55Y~^JYY5J!^~!75G5Y5Y?:.^:.   .7?J5PP5J!^..?^^?G5P57^:7?.              //
//                                                       .JYY!7?7~JY5??5~:^^~!?P5?JYP?!??JJ5JJ?7?JP5J?~^:^^^~7Y?7^:..:^JJ!~??7?5Y7^:?!J57PJ5J!^.7?.             //
//                                                       :G?!:^.:!J5YYPG5!!!7??5GYJJYY5GBG5J!!^!JYJ7P55YJ?7!7?YPG5YJ?7!7?J?7?5GJ:?JJ5YJ^ ~YJYY7~:!J^.           //
//                                                        ?P:!?~. :JYYY5P55555PP?7?!?Y5PPYYP??7Y5J~!J!YBJ????J5PY??YY?!!!?J??7YJ..^~^:    .~?Y5Y7^!YY7.         //
//                                                        :J!:??7^^!!JPJYY5YP5557JY?~J5Y!YJ5JYJY?!!YYY5!7JJ?7~~~~~~!777!7Y7!JJ5PJ7.          .:^~!777~.         //
//                                                     :!??77~~7?7J7JYP?:^?YGBPGP5J7?!7J7Y^!5Y?P5?7?7?!^!7^:.~7?JJJ?!!!J7!?J57J77J^                             //
//                                                    ~Y~:~~!7!!~~7J?7!?7.75PB5?YGP5?!7!J!77JGGP5Y?~!?:^^::.^J??!J5P55PP5JYYG5J7!Y:                             //
//                                                    757!^:.!JJ??77?J7!J?~JYPGP55GB5?7~: ..:!PPPY?!^!7?YYJ55?~:^YPG5YYY57J?5YY?7^                              //
//                                                    .^!7J5?7^^~~:::~?5YYJ7?YPB5!?BGY7: .::::!GGY7^..!5~~?P7!:^?YY?!J!?JJ5Y7?^.                                //
//                                                        .YJ!!^:!77!^:!7:~JJ?J5GP5BB57: .^^~!~YGJ!:..57  :?J~~?5?!. ^!7??!::.                                  //
//                                                         .^!7J!:.~JY7!!!?J5PJ?Y5GBBP?: .!??Y!5P?^:??J.    ~7!~:                                               //
//                                                             .^!7~^7?7??5PYJJJ7YPBBBJ^  :!??~PY!: JJ.                                                         //
//                                                                .^7???YYJ~~^!5Y7JPBBP7^.:77!~7Y..:Y^                                                          //
//                                                                   ..?P!!~!~7?YY?77PB5J~?^:~!J577!^                                                           //
//                                                                     ~J!!!~~!~~~?Y!75BB5?..^!57.                                                              //
//                                                                      .::::::^~~~!7J?JPGGY?YPBJ:                                                              //
//                                                                                   :?J?JJPPGGGBP7.                                                            //
//                                                                                     :?YJ?5P5555G!                                                            //
//                                                                                       ~Y?!7JY5JP?                                                            //
//                                                                                        :??7!7?J5J~.                                                          //
//                                                                                         .!5PPJ???JJ~.                                                        //
//                                                                                           :JGG5?JJ?JJ:                                                       //
//                                                                                             ^YG5J??^YJ                                                       //
//                                                                                              .~PGJ!!?P.                                                      //
//                                                                                       .:::....:?BJ:^7P^                                                      //
//                                                                                      .Y5Y55YJ?JPG^:~!5?                                                      //
//                                                                                       7555Y5YJYP5~^~JYP^                                                     //
//                                                                                        :~?5G5JY5GYJ!?Y5P^                                                    //
//                                                                                           :JPGGGGPYP?J?5P~                                                   //
//                                                                                             :~!7JP5GGYJJ5G?.                                                 //
//                                                                                                  .^75B5Y5YP5!.                                               //
//                                                                                                     .~YPP5YYP57:                                             //
//                                                                                                       .^JP55YY5PJ~..                                         //
//                                                                                                          :?5PP5YJ55J?!~:.                                    //
//                                                                                                            .~?5P55JJJJJJJ7.                                  //
//                                                                                                               .~JPPP555J7?J!:                                //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RHKMBUNGA is ERC1155Creator {
    constructor() ERC1155Creator() {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC1155Creator is Proxy {

    constructor() {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4;
        Address.functionDelegateCall(
            0x142FD5b9d67721EfDA3A5E2E9be47A96c9B724A4,
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