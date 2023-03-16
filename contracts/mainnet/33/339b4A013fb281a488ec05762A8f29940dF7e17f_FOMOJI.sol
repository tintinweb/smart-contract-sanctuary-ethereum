// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Ordinal Fomojis
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                    //
//                                                                                                    //
//                                                                                                    //
//                                  ▀███▄▄,                                                           //
//                                     ╙█████▓▄,         ,▄          ,▄,                              //
//                                        └╙▀██████▄▓███▀╙   ,▄███░  ███▌                             //
//                                         ,╓▄██████████▄▄█████▀└▀██▄ ╙▀█▄                ,╓▄▄▓█▓ε    //
//                                    ,▄▓██████▀▀└▄██████████▄,    ▀███▓▄▀⌐       ,▄▄▓████████▀╙      //
//                              ,▄▄███████▀▀└▄▄███████▀╙╙▀███████▄  ╙████⌐  ▄    ▐██████▀▀└           //
//                         ╓▄████████▀▀╓▄▄████████▀└  ,▄▄,  ╙▀██████▄ ╙▀└   ╙██,  ▀████████▄▄,        //
//                   ,▄▓████████▀▀▄▄▓██████████▄    ╓█████▌ ╔█████████µ  ██▄  ███,  '╙▀██████████╕    //
//              ╓▄▓████████▀▀┌▄▓█████████▀╙ █████▌,▓██████▌]████▀└╚████▄ ╙███  ╚███µ      └╙▀▀████    //
//         ,▄██████████▀╠▄▄▄▄██████████    ███████████████ ╫████   ╙████▌ ╚███▄ ╙████▄        ███⌐    //
//        ████████▀▓▄▓█████▓█████└█████   ███████████████▌]████⌐    ╙████▌ ╙████  █████µ     ▓██▌     //
//       ╫█████████████▀▀ ▄█████  ████▌ ,█████╙▀█████████ ▓████       █████ ╙████µ ╙████▌   ]███      //
//       ███████████▀└   ▐████▌   ████▌ █████      ▐████ ▐████▄▄▓██████████   ████  └████µ  ▓██⌐      //
//       ███████▀└      ▓████▀ ,▄▓████▌█████       ████▌ ╟██████████████▀▀`   ▐███▌   ╙▀▀  ]██▌       //
//      j████▌         ▓██████████████╙████       ▐████   ╙▀▀▀▀╙╙`            ║███⌐ ,,▄▄▄▄▄███        //
//      ▐████⌐        ███████████▀▀`    └         ████           ,,╓▄▄▄▄▓██▓  ████"▀▀█╙└` ▐██⌐        //
//      ║████        "██████▀╙`                  ▐███▌ ▄▄▄██████████▀▀▀╙╙└   ▐███¬   █⌐   ██▌         //
//      ╟████          ╙╙┌,,,╓▄▄▄▄▓█████████████▀████  └└└└└                ]███▌    █▌  ╟██          //
//      ▓███▌ ,▄▄▄▄██████████████▀▀▀▀╙╙└└       ▐███¬                       ████     ██ ]██▌          //
//      ████⌐ ▀███▀▀▀▀╙└└                       ███▌                       ▐███¬     ╟█▌███           //
//      ████                                   ]███                       ]███▌      ▐████            //
//     ]███▌                                   ███▌                       ████        ███▀            //
//     ▐███▌                                  ▐███                       ▐███         ╙█▀             //
//     ╟███⌐                                  ▓██¬                      ]███▌                         //
//     ╫███                                  ]██▌                       ████                          //
//     ████                                  ╫██                       ]███                           //
//     ███▌                                 ]██▌                       ▓██▀                           //
//     ███⌐                                 ╫██                       ]██▌                            //
//     ███                                  ██▀                       ▓██                             //
//    ]██▌                                 ╟█▌                       ,██⌐                             //
//    ▐██▌                                 ██                        ██▌                              //
//    ╟██⌐                                ]█⌐                       ▐██                               //
//    ╫██                                 ║▌                        ██                                //
//    ╟█▌                                                          ]█                                 //
//    ▐█                                                                                              //
//    `\                                                                                              //
//                                                                                                    //
//    Supply: 100                                                                                     //
//    Twitter: @OrdinalFomojis                                                                        //
//    Website: fomojis.io                                                                             //
//    Inscribed by @hash_bender                                                                       //
//                                                                                                    //
//    Ordinals Inscription IDs                                                                        //
//                                                                                                    //
//    Inscription #   Inscription ID                                                                  //
//    18951           258a956968b5c6304481d63d664df7466cbdff2ffa7f7bf20ea4baf65cb3ee00i0              //
//    18952           c1e62dd4f763d7a5940354f36e335f8952209d4d22768860e3ec58b289b8b501i0              //
//    18953           fd384e62603f4f81795b253cb3f31d87627bdcb9aee52051df56189c6c0dfb01i0              //
//    18954           193bf9e24f9a3d40083c31cb4a4872dfce8d12aedc964a55621615ffc6756107i0              //
//    18955           229eead6298036366b7f4f4aa8a2cd3220b43ed209a30d6fd61c9fb3e4ad650ei0              //
//    18956           f6dcffc66e0499c53d966a3f2be718308ee43f08d78d22ac2a2464b1030f4513i0              //
//    18957           7a2c3629d0b7c0973cb5288ca05642d084d7ce2c2d75df3ef609d6126c985f13i0              //
//    18958           59ff14cc732dc1633f7e03799a0bfc2c84a27dce2c2c7a733952ec99456a0719i0              //
//    18959           b85b3c51b281cc2b66076ebf29993710d93985a3674d635bac0f09ffc257631di0              //
//    18960           003f9cb205af588ae8ab065f74d720226f15c1b99bff6dc3aa569850d045b61ei0              //
//    18961           f79b7180eb873f69a9de35b7faacccd3a69a3d91237fc75aaf879cad3d0d0021i0              //
//    18962           3137492fc436ec9540fbd55d89882edd9a33d17159584c68fed5ea3730956524i0              //
//    18963           7b259364a2f23577976ed205c47cce0e343a8511c860ad96de2a4c3044367b25i0              //
//    18964           531ac2152c0f90dbfdce50297f5473f5e1c9827aeaf8847aae97ef4f98f5342fi0              //
//    18965           b76fb47892d05593a81d2bd7f2137e43632346bc2e282908d4fa11772155f031i0              //
//    18966           95eb8fb89266c22870a6e01af9b8364cb96794eacd6d9bc7a719d065a466f233i0              //
//    18967           f051327ac0f588b80ec57dc957a09e3372f6c4be1246f9db47c31bc2f0f2fc39i0              //
//    18968           1e9ded2f1c06ce1f4e057b05b20a219ba35d2b4f6c596dbea8c2842c665ed63fi0              //
//    18969           56eae7dd8c60682d9a45e686063a6a836f21288b1607ef62e5692dc61ffa5c40i0              //
//    18970           bd41768d0942dc73ed916b7e8e4e5d3b03df297d2c525414f2317dc981c49442i0              //
//    18971           9f2368467c25fa7b8b85ff2b96ccdaee47fe80716c24041ac36472c1780ff042i0              //
//    18972           f5d9b521ba7f66ebb2bbbd0078e115add924ef76b26f972f195966a3c56be843i0              //
//    18973           df2a2b2e871da47ce537227cca859cfee6744908f0155d43f8782f327064a045i0              //
//    18974           656e61a36efcfdb968bab4b9ae88a8086e76eb5b6a660982bb2c123c55cb6449i0              //
//    19024           28657729edf40b7b4b0e3c3dfa1782b73621614c65927c8cf0bd520670ebf547i0              //
//    19025           26962bc56cb9e678cac38db126754db5fadf8e726c9414b07c6990baba651a4ai0              //
//    19026           e52ece011ffde62b93d838e7a589cd0a4c66fde4ceb0b8d1110b91992f51e34bi0              //
//    19027           2905e667a9cbb3f6963fa625b4388a316667b1617b69291c38ee9defb7ebd150i0              //
//    19028           8f2f800439af4415317af1296012e653f7429d4c64c9b9f438cd3f4c146a7d5ai0              //
//    19029           6dd6c03b5439226db2a09da2ff7d208d2e73b45562451e2c5f872044ed89ae5ci0              //
//    19030           ac8f362b9448f1c16c9593bb380c542bc20b3a82cdee0d98e40ac84bb749225fi0              //
//    19031           db63ad7e13ae3a116152d979bb6ca3b87645eac7cd312c771cfe5c881a43b261i0              //
//    19032           05afe8e4d1da8f7bd60235f898c22a06bf99aa5e920b9c456712203777673863i0              //
//    19033           615fc67169afda020b6f41c25f9ddec39d6e418a3cda991d83fd65a855286d63i0              //
//    19034           a3c933fec0b33ce6cba6f8e834fb5396234e82ccaa16508db7495021ff8ceb64i0              //
//    19035           0cfa11d9ac89dabc27efc0276be8dc01ceef65b91400a11a0a2cb452534df667i0              //
//    19319           4e6b1b4d100d08d31e8ef972c74af569f7171f9df6b5961cba68936eda2aeb68i0              //
//    19320           4bde5fec70c08cad2d5251fae63de540fda98fdeb631f0c9f51d08eff1986b6ai0              //
//    19322           7dc6acad13e096ba3d9f0581e32ddb68699f1684c8f28d37f2e4618cd7e4896ci0              //
//    19323           65a84a6022a8cce5aaf861acd690a42b0cc9a3ccb332be78140b2ccc1189cf72i0              //
//    19355           21893eb02347a12c07bee38e9a373d25e9dece7d8d054794d2b6bacec016a16ei0              //
//    19358           6bceda29eb1bea32994d2ad7c69a2caccef5c45cade52ffe1d4b2b0f203a0e75i0              //
//    19359           7a31f0a81c9833f1730712b3150757b564220ad5588ba6d7a0b75c0429405679i0              //
//    19360           774db2bb02dca8316ccd10444b54a1f6838c4e264147c9b07f0be025126f257bi0              //
//    19361           449f03d5665af99543958962a62f535a50b54bc706d769dc7e3e11e4d73f147ci0              //
//    19363           e1a51c9675c67325768a5d3f7dc410c8fcc3d6a6ccf9b7524b420884a266697di0              //
//    19364           3efcca2f9578850599207d262797a92074b8d9db0883796d9149ba34943bf084i0              //
//    19365           0571417d91a9f9881e8eea0cf21ba155c63f609c7b09c830bfafe3b99b0f2c86i0              //
//    19367           9d1259820f10d10696e961191a4931a99d5b3213b24d1a92692f920794d8dc89i0              //
//    19368           71a71680c252b95e897a5a1d2db11bfc7c36a01778e1e654be7ced8a09f8138ci0              //
//    19369           f72ad9e4c943ffbb65dd4d638c5fbfaf861ffe338c0f21cecf70dad657d3d98fi0              //
//    19370           01df13e0eda7ed3938e3b2d7223efa28306adc59e86cd460edb1b970367cde92i0              //
//    19371           75942d7a867c8bd2ddabe4646ae911c7e3ef83351fbeb679b0c7032afba94594i0              //
//    19372           737d97c05b8369cf7e3a579ea02db4d985b22ff7a77de0111a71f93666859099i0              //
//    19374           d961ba36fe8d4ff075dd092dd4bb373b55d9cea1771507a5d2c37992a62c459ci0              //
//    19919           9b3225c13d318979447fa8c4768182380b56f4ae2f303dd6b782717cf19b2c9di0              //
//    19920           3075e3bc3519cbfc17bb0b7d5810d47a4248c06643e0d3b5a3406052c14f749di0              //
//    19921           713d2e36614f90fecf20ced72271b6922b8c5642f442ba37d066de0ba357e1a1i0              //
//    19926           7274218034ef39534dbad421c01f1a6bc0b860d4e60cfe369cb66cdd286871a6i0              //
//    19927           e3c61905f9493ed6ab8648b2ce408c61f8b1a92ab5f5a74af83758447db6c3a6i0              //
//    19928           74e2ed90214f523ce2e71d102c93baaefbb9159e349185247c45e29fe30a06a8i0              //
//    19929           cf5885978663e07752a4d2218cacb33a09bb0730448ccb6b61fdaf3772d975a8i0              //
//    19931           33a5c39ac249347b30898c0502ba4ec1f6b228a2c5f284a1e4df67d158882caai0              //
//    19935           7970799953bcc56661bfb0307e089a8fb7d1c5855b33c4016d19b390538c5badi0              //
//    19936           392282f30cad29d6fd869b93caf5a507ef7bd28792146dbd217f69a2c95823afi0              //
//    19938           8b038aacf23d0b1cbe555078cc0929deb437442f10201282fd2eff11faa12cb2i0              //
//    20027           21955aad1ef1d5a3ece27d3ff2892503dcabd87fa5d2c4ee69cf2c26da1accb5i0              //
//    20029           be88b0a100687814a50208bf445738e83cee4eeb0d0982e74901805c60d9e4b5i0              //
//    20033           8b2a4f8e2f1339713d6ecfd53423d43a7a73eeb879928a2e6e363223273b10bai0              //
//    20034           6d26299b0626b0dd4faaca0ae04580aa580cc8f424bd534d06adfae348ea5cbai0              //
//    21798           4890b11b0df6e688e17d038aad7e3652cd5e831efc6dc706e16b2257cf5aacc1i0              //
//    21802           88984d2b837a975a6b4df729ffb2dad2e3dfd68981544f22c48f925a1bd015c5i0              //
//    21804           f4eeebfb69f1c8ea81bc0c06ee6347ca885d2072ae0bf711b87512414b09f5c7i0              //
//    22638           16b621cf35d3b5de0c38f403831b5c47bb866eb5ba313697bd8e7a321e7d71c7i0              //
//    22639           43ed8cdfdcb3c239ecb707b907837fd625c69698c86fafaf8b131409457775c7i0              //
//    22644           7091db1420281dabd354365fa2d27941ee3feed50a97bc97b0426a1a304d26cfi0              //
//    22646           5e4cd934d568b6484806023fab3fe04d5570b7966c6f13997db30617838eefd0i0              //
//    22647           a03fda2786f1326a6dd6ac924d82ea8fe0ed9bca5c37a33dc7063d9b8cd560d1i0              //
//    22661           680e6be73cc201e30de404bc31970ef7d48beb90a9f2437059b415a501dca9d4i0              //
//    22665           391811652183e2135a352eec519522c0fb5715bc6bb79f1b56d334ba1af481d7i0              //
//    22666           c0401e1cd6e4d14933e5f16be044107ec06b0cfc4f7da87a3960cf33d7a4e0d7i0              //
//    22668           98603409c064bc5e44a4e7c919d25a86475dc0a0c1c173d152abd7ca45ac97d9i0              //
//    22673           a6bba3978af62a11d16d25f320446bae77c5ed6f5a5d721c174a97c4749501e2i0              //
//    22675           ff6fe6c78df1293bc9a1e78fdaf39286cbda64889b9a1ca435c6c3fb30cbd9e2i0              //
//    22686           6f26681c7dde830d933b71a907152d55bf27f95ebe9832caef7f223a5164f8e7i0              //
//    22689           0e9d7ffc6df1c9293003de71a50e35792cf0ce89ffbe085739f1d6d9f22b71ebi0              //
//    22690           adfb7de6b66466617a488d1a06e461d0dc051525894a7eb5c59b08fde60d86ebi0              //
//    22691           d4a0e53e61df12035a689ef14e5295059f30a76ac551f14ea710afd27a94f7ebi0              //
//    22692           27ae5dde940de9aa462c29ac2480a048ce67070f3a741fd723dbd48c991b75eci0              //
//    22909           f45d3b4cc67e54e2e5bd67a861d849f0237be8682204804e031695d2234290eei0              //
//    22910           00725a7cc892502a73cd429fdc60a140324a705c9df16a0e8f0777cae73389efi0              //
//    22911           f5c5220f179b15c3ba04bfb43a3c949f7fd4734dfacf0c45fc4a01f876e708f0i0              //
//    23426           b05cf10b3520689f0d95c47344b155c042789927286c684988ff609e9a5653f1i0              //
//    23428           d6369a51c32942aa68e800fd4bbb58894636ad0a22ff59c89e961be1c4b9b5f5i0              //
//    24097           8a78664efccbdbc4913fcd3e98ecfcdac280d309fe14c8cf308d83aa9e846ef6i0              //
//    24098           8d02e741753fec427572fd8dfcf7d0e7c17ec2acbcc46aa7f1a34974ea1442f7i0              //
//    24100           4ccd9ed590d976f2be3445f5e6bd72a2ed67581ea71d548e79d747921b08adf7i0              //
//    24106           6ab0654e1b2a0714a74fcd1315dbd5c8c3f50d1a1ee6d2f01293e6cd54753ffbi0              //
//    24108           010f0ebc0054cc2e24ebb51fe27a24c6c4b9b5a96c5b9b1969e53683423954fdi0              //
//    24112           1b81e7b12f3b7d7fe6925760121205c100d353527b749030abc701187a2e86fei0              //
//                                                                                                    //
//                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FOMOJI is ERC721Creator {
    constructor() ERC721Creator("Ordinal Fomojis", "FOMOJI") {}
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
        (bool success, ) = 0x2d3fC875de7Fe7Da43AD0afa0E7023c9B91D06b1.delegatecall(abi.encodeWithSignature("initialize(string,string)", name, symbol));
        require(success, "Initialization failed");
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