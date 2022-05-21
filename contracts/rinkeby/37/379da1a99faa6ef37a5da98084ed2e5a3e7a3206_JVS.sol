// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: JennVisuals Editions
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//    GBGPPPGPPGBGGGGBGP55P5PPGGGGGP5PYJYJ5PGJYYBJY5J5YJJY5PPBGGY5BGPPYYBGYGGY5YGYPPGGP5PBPBGPG#G#&##BP#BB    //
//    BPGPGPGG5GG#5G5GBBBGPPBBB5PPJ55PGP5J5?P5?5JPPYY5JJ?YPJJY55JPP5JP5BGGBPGP55YJPGGP#GBG#GGBB#P##&###&B#    //
//    BG5P5YGGBBBY55GPB#BGPGBPPG55PYYPYP5Y?YP5YGPG555PJ5PPP#YY5J5JJPY5PB5#5P5GGGP5P5Y5GGGGPPBGB##BBGB&&GBB    //
//    B&GGG5YGBPGGBGGGGBGPPBBPPGPY5Y5GPPPG55JPPP555YYY7PYP555?5YJJJ5YBPJGG5PB5GB5PYYYJY##BBGPBG##BBPBBBB#G    //
//    GPGBGGGBGGPGBBPGPGGBBGPPBP5PG5PY5Y55GYJPJPPY5PY?JGY555PYP5P5J5Y5YPPGGPGGGPGPG5GPPG5G5GGBBPGP5GG5#5G#    //
//    #BBG5G#B&BPPPPPPGGGB5BYYYPJJYP5PPYP5PYGJ5Y5YYJY55PPPPGP55PPYP5YGPP555YGP5G55G5YYBPPPGPPP5BG&BB5GGBG#    //
//    GP55GPGGG5GY#P5PPPP5555YJPYYJJGP55PYYJ55PYP55P5PYJYGGP5YJJPY55PPG5PPBPGYJYPJGGPY5J55GYY5PYBGB55YY5GB    //
//    PG55BBBGGBGP555YYP55GGBJPP5?YJYGPG5GPY5P55YJJY5J?5PG5YY55B5J?55YPGYJB5PGPJJJ5PYPYPGPPPGGYGY5GGGGPBGP    //
//    GPBGYP5PYYPJY5PPYPG?J5G5PGP5Y5GP5555PPPJGY?YJJJJ555YY?YJJPPJYGJYPP5PP5Y555G5YJY5JYGGBPBYBGB5BYG5BGBB    //
//    GPGBGBG555P5Y5PPYJ555GP55Y5P55P55PP55Y55Y?5YYJJYJJYYYJYYPGJPGB5YP?JJJJPJYPPPPBPGPPB5BGY55YBYJP5GJJGP    //
//    P##GP5G55GYGG5YPYP5PPPB5P5P#PJ5Y5Y55555PP5G5JYJ5YYBGPYG5GGPBPP5PGYP??YJYBBP#5P5PYP5GGG5BPGPPJ5J?JYPP    //
//    5G#GPPPGP5PP5PPGPPPYY5G5YYY5G5555JYYJY5PYGPYP5GPJGY5GY55GGGYBPPYP?5JPGJYPPPP5PPPPGPPPBBGGB?5YYGYGGGP    //
//    BBG55G5PPPPPG55G5GPPP55JP#PJPGP55PG5GJPGGPPB5GGPGYGYPGYYPGJJGPBPP5G55GPP5BPBPGBGYGGG5GP5GGYP5PYP5PY5    //
//    BB55GPPGBYG5G5PY555GY5YYP5YYY?Y55PY555Y5GJGGG5PJB5B5PP5GG5Y5YYJYYBYY5PJPYB5JG#G5BP5GGPGBPGB5YJGYG5PP    //
//    BBP5PPYP55YPGJ55P5G55YY?5YB??JJJYJ#Y5GPPGG5PGGY555Y55YYJYPPY5GGYGJJ5J5GPGPYG55PGGG55PYBPGPGGGBPPPBG#    //
//    G55JYPYY5#JG5P5B5YJPJJYPBGJJJYJ5?PJ55GPG55P#GJPGYYPY?5GPPPG7GGPGBGBYJJJJ5YPP55Y5GGYYJBPBBPG5&PGB5#BG    //
//    GPBPGYJ5YG55YY55??JP5GYPGJYYJ5P7???5PPBPGGGBYJY??YJ5PGJ5P5PGPPPPGJ5YYYJJ?GYJ5PYPP?GGPGGPGGGGGG#BPGB5    //
//    BPGYJ5Y555JP5GYPJJ???55PYGPBPYY5J55Y5P5YGYPY?Y555P5Y5Y5GG5P5GPPGGGPBPY77JYJJPJ55JY555PPGGGPBGPBBBPGB    //
//    #GG5JP5PPY5555P55YJPY?7YJ5Y5?J5JJPP?PJ?555J5PPYPGG?P5Y5YPY55GP5YGG#PP?YJYJ?PJ5JJJ?GG5PGGBBBGGBGBPGPG    //
//    PG5GPG5Y55GGPYY?J5YGJ5PYYY??Y5BG!JPYG5J5YGGJYGPPGPYG555P55P55#GPPGGPP5PYY555PYP5JJ?5G5GBJPGBGGBYYYPG    //
//    JJGGJ55PBGPGJYJJYJPGYG55PYPPYPGYPPJ7?JGJ?PPGPJ5YY55PGP5YPJPJY?GPPPP5PPPJJJ5JP55YP5P5Y5YJYPYBPJP#PPGG    //
//    YYYGP?Y55PP55P55P5GP5PPGGPPPPP5GYY5YP7!?55YYYGPY5P55PP55PPPY5JYYY7?77?PG5P5YP55J555J5PYJYJY?YJP#GGPB    //
//    PGPYB5YPGP5PPY5555PG5GPPPPPP5YBY5J5YY?YJ?PJ~P5YYJ755YJP5JY755YJ?7JJ7~??555PPP5J?5?P5PPGBYP5PY#5G#BBG    //
//    JJJJYYP5PBYYPP5PG5PGGG5P#&BBPP5PBY5Y???YJ5Y!Y5J55775!JY7YYYY7YJ7?Y!75JYY55J5GYP?PGBGYP55P5GGPG5BGPG5    //
//    5J5PY5?5YGPG#5PPGG5G5P5PPBG5YY5GP5Y5755YJ577~!~~77~7!?!?JYY?5P5J5Y5PYG5GG#P?PPJPPPGPBP5GYYYG55BP5GGB    //
//    P55Y5?YJY5YY5PGJGPP5GG5PP5PPBGP&PYP5YGJJJ7?!!!~5!Y?~!!!?~YJBY!J7PJ55PYYPBP5#B5PGBPYPPGBYG5P5GBYPB5&&    //
//    555?YJ5Y55BG5JYPYP#PY5GPBPPG#BPJBPY5#YPY5YYB5Y5!YYJJ?5JJ57JJP?JJJJJ5??J5GBGPGBGPG#BBGBBBBPPB5YP#5G#G    //
//    Y55555Y5J55GYY7G5BPP55G##Y5#PPBGP&@5P55Y5B&#5?5J7?J#BYPY55PYP5YJGY5YYPPGBGB#BPBG#P&BGPG55YGBBGGGGGG5    //
//    P555YYJJJ?JJ?GPP55G?YBYPYPGGGPP5JBBPPGPPPPGG&#BPY5J5PGB5555BY5Y55YGYYJ?GBYBGGG5PBB&##BGGBP##B5PB5GPG    //
//    YG5??5JY!!JJ7BJPP#GJYJP5BPBYG5JJJYPGY&#&&#GPGP5GP5YPG5PBG#PPYGGPPPP?B#BGBPGPYBB##BB#GBB#PG#YGG&BB5##    //
//    5JJY5JJ??77BJJ5PYJPP5YJJGYP?Y5JJYYJJYGGGGGPGPGPGGBBBG#BBP##BBBB55PBB#P5GB55BGJBBBG###BGBBGBBPGGB5BGP    //
//    ???P7?JGPPYGGJPPPG5P5?G7?GJPB5J?JP5?JYY55P5555B5P55P55555PPGP5PPPYY!YP5JPGGBBGBB#PPBB#PB#BGGGB#BGGB#    //
//    P?J7P77?75!5J5PBJ5PJ5G7GJ7?P57??JPG5#YY#5P#PP5YP555PGGGBPP#GGPGP5GP!JPYJ7G5BBGBYPBBGG#YB?PG#5#BBGPGP    //
//    JJ?JJY7YJJ5YYPP5G5Y?YPG?P7?P?7J??PPYP55####5P5#PPP55G&#G5PP5GPP&5G?J~BY5~??7?GJY?GGBPG5GPBBY#GB#BG#G    //
//    ?7:J!!55YY5J?JP?5P55JG?YP7?PY#Y??GG?5BB#5PBP55#55PPPG#&P5P55P55#[email protected]&PBP    //
//    J55?YG?JJPG?PY5BBYYJ5JBJJJPGPJP??G5JYYY555#P5PBPY5PY5&#P5P55G5Y#5PYJ5PY?7P?!PJYJJJJJBYY?5YYYY#PPBPBB    //
//    YPP5PY5PJJJ5JP?PJ5PBYGG?J?YJ?Y7!?P5?Y5YY55BPY5#5P?JYY##G5PP5P5Y#5BYJYPYJJJP7?7!JJJJGJY5YYYYYY?#B##GG    //
//    555YYJJY5GYJGGYBGP5G55B5J???~777?GYJY5PPPGPP5Y#GY5Y5P##P5BG5GBGBPPJY5PJYY??J5P?J75YY?YGPPPYYJ5BGPBBY    //
//    YPJ5YYP55YGGYPYYPB#G5P5JY57?J7!~7PYJPY5Y5Y5B5##5B####B&P55Y5P#5Y#PPJG5Y55?JJ?Y5P77Y755JJ5YJ?JJYY5G55    //
//    PBPPY5GPG5PGBP&BBGYJPB5YJ?57?~7~757J5Y555Y5Y5P#P#&###&#P55YY555P5PGPBGJPGG57J77!YJJP5?BJJ?55Y?PGP555    //
//    5PGPYPG5J5YGG5YGBP5PYP5JPPY7Y!?.?G?JYYYY5JYY5P#PB&####BB555YP5GBPGPPBGPPPPJ?7?5^??7755BGJY5PGPJYBGG5    //
//    GGP55PYGBJ5G5YJPG#B#PBGG5GY5?!?~?PY?JY5YYJY5P5B5#&&#&##GGGPJP5555P5J#P5YP5PPJ?JJ?Y?G?YGJ#YG5BBPPPGG5    //
//    B5#G#PJPP&YGG57YGBPGB5PGPPJYYY7??5Y?YJY5YJY5GPP5B##&###G555G55PP5Y55P5Y5?JJBYGJ?JYP55YYJGG5Y5YJPGBYG    //
//    BPGPY5Y5YG55GJ?YPPPG#BPYPG#JJ??&7GGJY5G5Y5PG&5YP5555GB555PP55GP555J5YPGG#B5B##GYGPPG#P#GP55BGBPBPBBY    //
//    &#5GG5GPPPPPG55PYP555YGJPP???7G?PGP!?J5??JPPY55B#@@&&&&&&#@##5GBY5PB5PBGBBGGBBBGBB##BBGGGGBGPG#GGBB&    //
//    GPGBPPGGGPG55PGBP5BPY5YYBJPGG5B?JPJ7GB#BGGY&BB&#BPBBGPP5PPG#B##BBGGGBP#&GPYGGBGB#GG#BGBBBGBBB&GBBPGG    //
//    #GGPGBPPGP5GPBBPGBG5GYY5P5P5P#PPPYPPGBYYPYYJ5PPGP5GPPB5BYB&PGBGBBBPY55P5BBBGP5GP5PYBPBP5BG&BPBP##BGG    //
//    P55PBG#BGGGBB#BGGBB&B&B#PPB&Y55#PGG#P55P&Y5PG5GBJBPBBBPPBPGGGBP5PPPB5GGGPP5GPPYY55P5GPBPGPPGGP#&BBGG    //
//    #PPGGGGBGB#5PG&G5G&#&GGGY55#GJ5YPPJY##P?JJPY5Y?Y#5J?YBBBGGGB5PBBBBYG#P5PPP5PYJ55YPP555G5PP5PG5#BBBG#    //
//    BGBG&P&GBB#BB#GBPGGBGBG&5YP5#P55#BPBJYGB5JJJ#BGPPGBY#BG#BGBPBGPBGGPP5555PPPGP5PYJP5555G5YYPYGP#B5GGP    //
//    &#BBBGGGG#BG##B&B#&&BGP5GB5PGGPPGG55B5#BY5J?JJ5JYJY?YYJJGYJ5YYPJPGYYYYYGGGPP5YP5PP5PYP5P555PPBGGGP5P    //
//    G5PBBBBBG&#&B&&GBB#BBGPGBGPPYGY?5P55YJPPPG5YGPYYGJ?YJY?JY5YPJ5P##PYBPPGGGY?JJY55JYPPPYJJ5PG5Y5G5YP5P    //
//    @@B#@##&BBGGGGB&&P#P555BG5555#?55?7B?JY^?JJY5J?GGG#5G5PPGP5GPPYPPGGGGBPGY5JJYYYYY5P55P5P55PYPBPGBBBP    //
//    B##GBGGPB#G#P&BGB5BGPPGYGGJB5YJJP???YJ7Y7?JJJJPGB55JGJBPBG5PPPPPB#GG5555YYPY5JYYYJ5555YYY5YYPGYPG5JJ    //
//    ##B&GBGGPBG&&##GB#BGGPYPPG55YYG55?JJY7?JJYJYJGPYGBGYBYPPGGBPGBPPJYJ7?77!~77?YP5P5Y55YGP5P5PGB#GPP#BG    //
//    [email protected]#&GGGG&@#P&&GBGGB#5P5BGB#PBPY5J5Y?P?YYPGGGBGBGBBGG##P5P5YJP5PYJ????JYYYYJJJYYY55PGGB&##&#G5G5GB    //
//    #&BGBG5P5555G#BGGG5B##GPG#5P5G5PBPGGGBPBPGPGGGB5YPP555YP?JJJJ??J?PYY55J?YYP5555P555GBG#####BG5PGY5JY    //
//    @&@&#BGBPPP#GPPG&&5PPGBB#GGPGGBBBBBGBGGBY555?JJJJYPPJJ?JJJYYY?YYJJ?YJJYY55Y5Y5PBGG&GP#P555P5PYY5PPPY    //
//    G#B#&G&B&P5GBBB##B#BBBBBBBB&BP55P5P55YJJ5JJY?JJJ7?J77?JYJJYJ?YJY5PJYJYY?5GBP55P#GGGGB#PBBBGGGP55JJYJ    //
//    BB##B#BB#BB#B&B##&GGGBPYY5JYY5Y5YYJYPPY5YJYY55YYP???Y?YY5Y5J?Y?JJJYJJGGBYBYJ5PG5BGGGBY5PGBBBBBGPP5P5    //
//    ##B######&BGG5GG5PG5YYPGJJJ?JYJ?YJJ???JYJJJ??JY5YJ5Y5JJ?JJJJJY5?PGYJ?J5JJ?Y5P55YP5Y555Y5PYPPG5G#PB#G    //
//    ####BBGGPP5PPPP5P555G55B5Y?YJJ5YY55Y55YPPP5Y55YBY5YY55JJ?JGGPGPYYJJYPYPJY?555PGGBY5PBPGG#BYBBGBB#B&B    //
//    GBPBG5PP5BP5G55Y55PPGP55PP5YPY5GPG555P5P55YY55J5?J?P?JYGGB#PYYBY5YPJPP5YYYYYB5Y5P5BGBPBBBBBPBGGG&GBB    //
//    GGPPBGGPPPGP55P5P5PP5P55GGYG5P5555P5PP55G55Y5YYJJ?GYY5B5BP555Y5#5PPYYPPP5PG55JPG5B5G#&BB&G##&##GBBG#    //
//    GG5GP5G55PGPGGP55G5P55PPG55PG5GGPPP5BPP5PPYY5555555PB&5GBBGBBBGGBPGBPGGGGGGGGB5P##&#BG#BGGBBPBBB&&B&    //
//    G5BPG5P55PPP5PPP5YPY5G5PPY5PJ5Y5YJJY?JJJJPPY5Y5P5PP5G#&#[email protected]&B&BGPGG#B&&PGBGPGGGGG#PGYPGP55BB#PPGGPGBG    //
//    P5GP55PGPP5P5PG5G5Y5YY5YYJY5JPJ77?7?77~777JJJ55PGPGGG5PG#B#GG&##PBPGPGPBGBBPBPGYY5YYG55PPGP&#&BBBB&&    //
//    5YYYP5P55Y5PP5YY5YY5YJJ?J??J?JJGY??777!~!7JJJYP5Y55PPGP5PBBGG#BBGGPGGP#PBBBBBG55PJ5YYJ?JJY5PGB5GBGG#    //
//    PPYY?JY5PBB5PY5JYJJJJ??YJ??YYGP5JJJJ?7??JJ5PYYPYP5PPBPGBGG#BGGGGGBGGGBBPBPGBPGGP#BB?JYYJ5J5YPY5P5P#B    //
//    55P5B5P555GY55YJ?J????!7?YJ5Y55PB5JYYY5555GY5P5GB5GGPPPGGBBGGGB#GPGGBB&G5GGBPB#GGYPYJB7Y?JJ?JJJYY5PG    //
//    P5G5B5P55P5PJJ?JJJJJJ??7?JJ?J55PPGP55PPPP555PP5GPG5P5PG5GGGBBBGGGBBBBBBGGB#BGGPPGP5YP5PJ55JY5JY5GP&G    //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JVS is ERC1155Creator {
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x442f2d12f32B96845844162e04bcb4261d589abf;
        Address.functionDelegateCall(
            0x442f2d12f32B96845844162e04bcb4261d589abf,
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