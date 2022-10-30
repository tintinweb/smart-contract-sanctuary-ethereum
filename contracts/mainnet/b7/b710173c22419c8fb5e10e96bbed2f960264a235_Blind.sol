// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: RyanAnnett5
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//    [size=9px][font=monospace][color=#294db5]╫[/color][color=#3e538d]╣[/color][color=#2f4ca0]▓[/color][color=#132b99]▓[/color][color=#141e4d]█[/color][color=#0f030d]█[/color][color=#120405]█[/color][color=#08010a]█[/color][color=#05000e]████[/color][color=#06001e]█[/color][color=#040027]██[/color][color=#050003]█[/color][color=#080006]███[/color][color=#0e0112]█[/color][color=#100114]███[/color][color=#240224]██████[/color][color=#150226]█[/color][color=#240835]█[/color][color=#0c0132]██[/color][color=#22113a]█[/color][color=#160636]█[/color][color=#190123]██[/color][color=#24063c]█[/color][color=#310943]█[/color][color=#38043c]█[/color][color=#290529]█[/color][color=#130109]█[/color][color=#0f0105]█[/color][color=#050103]█[/color][color=#12040e]█[/color][color=#0c023b]█[/color][color=#14014b]█[/color][color=#3c0730]█[/color][color=#370425]█[/color][color=#2c0823]█[/color][color=#0d0005]█[/color][color=#19000d]█[/color][color=#210322]█[/color][color=#260636]█[/color][color=#16023d]█[/color][color=#190650]█[/color][color=#290642]█[/color][color=#210540]██[/color][color=#0b0031]█[/color][color=#10012f]█[/color][color=#2b0236]██[/color][color=#090124]██[/color][color=#180138]█[/color][color=#18033e]█[/color][color=#02002e]█[/color][color=#010056]█[/color][color=#0e0395]█[/color][color=#0a02a5]▓[/color][color=#0401ab]█[/color][color=#1802b3]▓[/color][color=#320668]█[/color][color=#390959]█[/color][color=#330259]█[/color][color=#33024c]█[/color][color=#420154]█[/color][color=#4b028e]▓[/color][color=#3f0494]▓[/color]                                                                                                                                                                                                                                                              //
//    [color=#172b98]▓[/color][color=#191758]█[/color][color=#1b0b14]█[/color][color=#120603]█[/color][color=#0d0301]███[/color][color=#080101]█[/color][color=#070410]█[/color][color=#08071d]█[/color][color=#1a0b2f]█[/color][color=#2a0c29]█[/color][color=#360736]█[/color][color=#2e013b]█[/color][color=#27003e]█[/color][color=#220120]█[/color][color=#15002b]█[/color][color=#180136]█[/color][color=#230537]█[/color][color=#2a044e]█[/color][color=#290151]█[/color][color=#400952]█[/color][color=#24022c]█[/color][color=#170010]█[/color][color=#180011]█[/color][color=#2f0e13]█[/color][color=#2b071f]█[/color][color=#240621]████[/color][color=#170215]█[/color][color=#0a0109]██[/color][color=#2a0724]█[/color][color=#320629]█[/color][color=#3f0521]█[/color][color=#4d0923]█[/color][color=#560816]█[/color][color=#4d0949]█[/color][color=#3a0c5a]█[/color][color=#39173c]█[/color][color=#130311]█[/color][color=#050001]█[/color][color=#0e011f]█[/color][color=#210743]█[/color][color=#410730]█[/color][color=#4e050f]█[/color][color=#3a060f]█[/color][color=#300a23]█[/color][color=#21082a]█[/color][color=#13031a]█[/color][color=#220321]█[/color][color=#22062b]█[/color][color=#17022b]█[/color][color=#17032d]█[/color][color=#1d0437]█[/color][color=#190455]█[/color][color=#150555]█[/color][color=#26043e]█[/color][color=#28012e]█[/color][color=#35022e]█[/color][color=#360325]█[/color][color=#210225]█[/color][color=#210329]█[/color][color=#300a40]█[/color][color=#22044a]█[/color][color=#1f016a]█[/color][color=#0f0083]▓█[/color][color=#2e0477]▓[/color][color=#0a0157]█[/color][color=#310251]█[/color][color=#300842]█[/color][color=#2f0539]█[/color][color=#250234]█[/color][color=#350429]█[/color][color=#550626]█[/color][color=#48042e]█[/color][color=#3d0544]█[/color]                           //
//    [color=#0a0301]█[/color][color=#0a0101]███[/color][color=#0a0415]█[/color][color=#08082b]█[/color][color=#082045]█[/color][color=#09324d]█[/color][color=#2f4075]▀[/color][color=#2f2771]▓[/color][color=#312275]▓[/color][color=#2f1081]▓[/color][color=#540d62]▓[/color][color=#530461]█[/color][color=#2c0247]█[/color][color=#1b0132]█[/color][color=#120125]█[/color][color=#120210]█[/color][color=#190113]█[/color][color=#220132]█[/color][color=#240142]██[/color][color=#220219]█[/color][color=#180122]█[/color][color=#040002]██[/color][color=#280628]█[/color][color=#280419]█[/color][color=#2a0317]██[/color][color=#1b0131]█[/color][color=#230637]█[/color][color=#2d062a]█[/color][color=#2f0e2d]███[/color][color=#3e081f]█[/color][color=#4d0b10]█[/color][color=#4d0d04]█[/color][color=#3b070b]█[/color][color=#3d0420]█[/color][color=#41063d]█[/color][color=#3a033a]██[/color][color=#32092a]█[/color][color=#19032d]█[/color][color=#1d0535]█[/color][color=#210932]█[/color][color=#140626]█[/color][color=#0b0333]█[/color][color=#0d0439]█[/color][color=#0d0643]█[/color][color=#060242]█[/color][color=#0c0850]█[/color][color=#180d5c]█[/color][color=#2c0858]█[/color][color=#26084a]█[/color][color=#1b043f]██[/color][color=#321142]█[/color][color=#3d0a37]█[/color][color=#3e0f4d]█[/color][color=#2b0638]█[/color][color=#280240]█[/color][color=#24032b]█[/color][color=#360d33]█[/color][color=#3e0e3c]█[/color][color=#4d085e]█[/color][color=#280061]█[/color][color=#06006e]█[/color][color=#020034]█[/color][color=#0d0124]█[/color][color=#17002c]█[/color][color=#080015]██[/color][color=#100115]██[/color][color=#0c0106]███[/color]                                                                                                                                                                     //
//    [color=#050000]█[/color][color=#160220]█[/color][color=#2f0b57]█[/color][color=#391089]▓[/color][color=#34138a]▓[/color][color=#0a075b]█[/color][color=#0a0d6b]█[/color][color=#41326e]▓[/color][color=#582a82]▓[/color][color=#5f149a]▓[/color][color=#60097a]▓[/color][color=#3c0181]▓[/color][color=#19005f]█[/color][color=#1b024b]█[/color][color=#0c0037]█[/color][color=#060070]█[/color][color=#0c0052]█[/color][color=#1b0232]█[/color][color=#170123]███[/color][color=#09000a]█[/color][color=#040004]███[/color][color=#0c0042]█[/color][color=#0d014a]█[/color][color=#1f0344]█[/color][color=#35073f]█[/color][color=#32093f]█[/color][color=#210437]████[/color][color=#1b0134]█[/color][color=#160346]█[/color][color=#1b075d]█[/color][color=#270844]█[/color][color=#210421]█[/color][color=#2f0820]█[/color][color=#3b0a1c]█[/color][color=#3c0a23]█[/color][color=#350631]█[/color][color=#360a4d]█[/color][color=#230853]█[/color][color=#1b0c5c]██[/color][color=#170942]█[/color][color=#190427]█[/color][color=#0a0114]█[/color][color=#150220]█[/color][color=#23063e]█[/color][color=#1c0435]█[/color][color=#100124]██[/color][color=#180755]█[/color][color=#160754]█[/color][color=#17073f]█[/color][color=#1c0e51]█[/color][color=#210b3f]█[/color][color=#30062a]█[/color][color=#23042f]█[/color][color=#200323]███[/color][color=#1b012d]█[/color][color=#110134]█[/color][color=#0f0120]█[/color][color=#09001d]█[/color][color=#180339]█[/color][color=#1e041d]█[/color][color=#240428]█[/color][color=#230134]█[/color][color=#130114]█[/color][color=#070004]█[/color][color=#050003]██[/color][color=#0e0017]█[/color][color=#0d001c]██[/color]                                                                                                                                                                     //
//    [color=#36025e]▓[/color][color=#60034c]█[/color][color=#963008]▓[/color][color=#8c1e0e]▓[/color][color=#861123]▓[/color][color=#671042]▓[/color][color=#57158c]▓[/color][color=#390a94]▓[/color][color=#420f7e]▓[/color][color=#580b69]█[/color][color=#60044a]█[/color][color=#310218]█[/color][color=#1e0116]█[/color][color=#070017]█[/color][color=#030023]█[/color][color=#030034]█[/color][color=#0a0158]█[/color][color=#0d004a]█[/color][color=#0b002b]█[/color][color=#100034]█████[/color][color=#030003]█[/color][color=#0b001d]█[/color][color=#180242]█[/color][color=#160353]██[/color][color=#2e043d]█[/color][color=#3a0231]█[/color][color=#3b0214]█[/color][color=#4d062b]█[/color][color=#35086a]█[/color][color=#1f037e]█[/color][color=#1e0d8f]▓[/color][color=#0c0d60]█[/color][color=#061b61]█[/color][color=#051d53]█[/color][color=#0e2e57]▓[/color][color=#18163b]█[/color][color=#211426]█[/color][color=#27183e]█[/color][color=#2b1136]█[/color][color=#241654]█[/color][color=#201244]█[/color][color=#250d34]█[/color][color=#220e36]█[/color][color=#240538]█[/color][color=#270226]█[/color][color=#2f062a]█[/color][color=#2d0726]██[/color][color=#1b011d]█[/color][color=#18021b]██[/color][color=#15012d]█[/color][color=#0a0123]█[/color][color=#080539]█[/color][color=#0c000e]█[/color][color=#10021c]█[/color][color=#1a012c]█[/color][color=#0d000c]█[/color][color=#0e0008]██[/color][color=#1e001e]█[/color][color=#26012d]█[/color][color=#2d0136]██[/color][color=#2e0337]█[/color][color=#370558]█[/color][color=#260762]█[/color][color=#20084f]█[/color][color=#240845]█[/color][color=#140139]█[/color][color=#1a0549]█[/color][color=#28024f]█[/color][color=#1a0016]█[/color][color=#150111]█[/color][color=#100007]█[/color]                                                                         //
//    [color=#4c0759]█[/color][color=#610a31]█[/color][color=#8d1e03]█[/color][color=#7d1307]▓[/color][color=#982405]▓█[/color][color=#710544]█[/color][color=#55027f]▓[/color][color=#5b0769]▓[/color][color=#550a45]█[/color][color=#4b0531]█[/color][color=#4d0b2a]███[/color][color=#39062a]█[/color][color=#2f053a]█[/color][color=#250350]█[/color][color=#21034c]█[/color][color=#1c033d]█[/color][color=#29032f]█[/color][color=#270531]████[/color][color=#0f010a]█[/color][color=#220214]█[/color][color=#480528]█[/color][color=#4e062d]██[/color][color=#3d0430]██[/color][color=#490512]█[/color][color=#671201]█[/color][color=#953501]▓[/color][color=#530d04]█[/color][color=#5b0b2d]█[/color][color=#4a1258]▓[/color][color=#171651]█[/color][color=#032951]█[/color][color=#01425d]█[/color][color=#024b6f]▓[/color][color=#0a2e6e]█[/color][color=#063162]█[/color][color=#0b3530]█[/color][color=#053a3f]█[/color][color=#01295c]█[/color][color=#043961]█[/color][color=#102541]█[/color][color=#0b1537]█[/color][color=#100a34]█[/color][color=#220935]█[/color][color=#2b0c2a]█[/color][color=#150215]█[/color][color=#160415]█[/color][color=#090003]█[/color][color=#0f010a]██[/color][color=#140109]█[/color][color=#200413]█[/color][color=#1e0218]████[/color][color=#0c0008]██[/color][color=#270533]█[/color][color=#220018]█[/color][color=#250026]█[/color][color=#26023c]█[/color][color=#240235]█[/color][color=#30034b]█[/color][color=#1d014b]█[/color][color=#1d0544]█[/color][color=#1a032a]█[/color][color=#150221]████[/color][color=#2b0549]█[/color][color=#2f0435]█[/color]                                                                                                                                                                                                                                          //
//    [color=#290642]█[/color][color=#290415]█[/color][color=#4a0a27]█[/color][color=#441235]█[/color][color=#58370d]█[/color][color=#702d04]█[/color][color=#62030d]█[/color][color=#68022c]█[/color][color=#67062c]█[/color][color=#5c0827]█[/color][color=#630b46]▓[/color][color=#5c0b32]█[/color][color=#700a12]█[/color][color=#7f0d1c]█[/color][color=#590318]█[/color][color=#4b0436]█[/color][color=#390240]█[/color][color=#2f0335]█[/color][color=#3c0532]█[/color][color=#430d2f]█[/color][color=#29083e]█[/color][color=#22053f]█[/color][color=#2c092e]█[/color][color=#330834]█[/color][color=#1c020c]█[/color][color=#37081a]█[/color][color=#4c0614]█[/color][color=#5a051d]█[/color][color=#69052f]█[/color][color=#5d0a38]█[/color][color=#560833]█[/color][color=#4c0329]█[/color][color=#590d19]█[/color][color=#620e12]█[/color][color=#651705]█[/color][color=#4f020c]█[/color][color=#4c073c]█[/color][color=#2d105e]█[/color][color=#221b49]▓[/color][color=#103240]█[/color][color=#0d324e]█[/color][color=#0e3865]███[/color][color=#033162]█[/color][color=#00366d]██[/color][color=#021767]█[/color][color=#051a70]█[/color][color=#0d1e74]▓[/color][color=#0a095a]█[/color][color=#2d0a61]█[/color][color=#2a0743]█[/color][color=#260931]█[/color][color=#14030e]█[/color][color=#210418]█[/color][color=#3d0b12]█[/color][color=#3b0622]█[/color][color=#430d1d]█[/color][color=#430513]█[/color][color=#4a060f]█[/color][color=#5c0215]█[/color][color=#700521]▓[/color][color=#520529]█[/color][color=#2d0127]█[/color][color=#260218]█[/color][color=#21000c]█[/color][color=#2e0330]█[/color][color=#2e0423]█[/color][color=#0e000e]█[/color][color=#11001f]█[/color][color=#250229]█[/color][color=#1d0229]█[/color][color=#1c0108]█[/color][color=#0e0108]███[/color][color=#150013]██[/color][color=#210229]█[/color]    //
//    [color=#1e0149]█[/color][color=#19001b]█[/color][color=#3b0628]█[/color][color=#47142f]█[/color][color=#48091f]█[/color][color=#370215]█[/color][color=#290019]█[/color][color=#28002b]█[/color][color=#2d002d]█[/color][color=#360116]█[/color][color=#490215]█[/color][color=#4c0616]█[/color][color=#360015]█[/color][color=#4b012b]█[/color][color=#670236]█[/color][color=#590424]█[/color][color=#570317]█[/color][color=#5a0919]█[/color][color=#42031b]█[/color][color=#3d0332]█[/color][color=#2c0445]█[/color][color=#210641]██[/color][color=#250d36]█[/color][color=#140007]█[/color][color=#32062c]█[/color][color=#4a0431]█[/color][color=#640324]█[/color][color=#680326]██[/color][color=#72081e]█[/color][color=#7e0710]▓[/color][color=#60060b]█[/color][color=#410315]█[/color][color=#3f0921]█[/color][color=#290522]█[/color][color=#30073e]█[/color][color=#290c44]█[/color][color=#1b0c3a]█[/color][color=#1c0e36]█[/color][color=#200637]█[/color][color=#22042e]█[/color][color=#0f0458]█[/color][color=#080a65]█[/color][color=#09147b]▓[/color][color=#081972]█[/color][color=#0f1771]█[/color][color=#160c44]█[/color][color=#21142a]█[/color][color=#1e1943]█[/color][color=#1a1356]█[/color][color=#200c47]█[/color][color=#280d2a]█[/color][color=#230b23]█[/color][color=#25072e]█[/color][color=#351127]█[/color][color=#3a0c2e]█[/color][color=#35042d]█[/color][color=#3e0722]█[/color][color=#44091a]█[/color][color=#37030a]█[/color][color=#4e040d]█[/color][color=#690220]█[/color][color=#640860]▓[/color][color=#4b0b59]█[/color][color=#4e0d51]█[/color][color=#29022a]█[/color][color=#12000f]█[/color][color=#090005]█████[/color][color=#150404]█[/color][color=#19040a]█[/color][color=#1c0417]█[/color][color=#21031b]██[/color][color=#0f010c]██[/color]                                                  //
//    [color=#29035b]█[/color][color=#1b0245]█[/color][color=#2d074e]█[/color][color=#30032e]█[/color][color=#2f011e]█[/color][color=#0e0007]█[/color][color=#0a0007]███[/color][color=#090020]██[/color][color=#110016]█[/color][color=#150010]█[/color][color=#2b0027]█[/color][color=#32002b]█[/color][color=#1c0015]█[/color][color=#0d0005]██[/color][color=#2c012f]█[/color][color=#2b022d]█[/color][color=#2f0245]█[/color][color=#25024a]█[/color][color=#240339]█[/color][color=#160019]█[/color][color=#200313]█[/color][color=#42072d]█[/color][color=#47073f]█[/color][color=#69081c]█[/color][color=#6f050c]█[/color][color=#770512]█[/color][color=#840309]██[/color][color=#710409]█[/color][color=#380312]█[/color][color=#2e0413]█[/color][color=#38091b]██[/color][color=#521d0b]█[/color][color=#5a1f07]█[/color][color=#49100a]█[/color][color=#440714]█[/color][color=#2d041b]█[/color][color=#220446]█[/color][color=#1e0b70]▓[/color][color=#160b57]█[/color][color=#1d115b]█[/color][color=#2e0c43]█[/color][color=#2a0b37]█[/color][color=#2d0d27]███[/color][color=#36102e]█[/color][color=#41141e]█[/color][color=#370913]█[/color][color=#662b0b]█[/color][color=#6f2907]▓[/color][color=#5a1906]█[/color][color=#501306]█[/color][color=#450a0f]█[/color][color=#400c13]████[/color][color=#550b23]█[/color][color=#560d17]█[/color][color=#52130d]█[/color][color=#38082b]█[/color][color=#200435]█[/color][color=#210427]█[/color][color=#15030a]██[/color][color=#180312]█████[/color][color=#240728]█[/color][color=#291137]█[/color][color=#290d36]█[/color][color=#220737]█[/color]                                                                                                                                                                                                                                          //
//    [color=#030062]█[/color][color=#050157]█[/color][color=#120473]█[/color][color=#0e0025]█[/color][color=#0d0011]█[/color][co                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Blind is ERC721Creator {
    constructor() ERC721Creator("RyanAnnett5", "Blind") {}
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