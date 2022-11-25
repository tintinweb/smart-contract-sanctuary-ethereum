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

/// @title: arttimetais
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//    [size=9px][font=monospace][color=#0f1215]█[/color][color=#111421]█[/color][color=#0e162b]█[/color][color=#0c1b39]█[/color][color=#061b40]█[/color][color=#033078]█[/color][color=#013592]▓[/color][color=#064aac]▓[/color][color=#126bb9]▓[/color][color=#1565b1]▓▓[/color][color=#026ad1]▓[/color][color=#035bc2]▓[/color][color=#011d6d]█[/color][color=#0c2f83]▓[/color][color=#123c90]▓▓[/color][color=#041c7d]█[/color][color=#011573]█[/color][color=#020d5a]█[/color][color=#030f58]█[/color][color=#061668]█[/color][color=#203772]▓[/color][color=#436691]▒[/color][color=#567496]╖[/color][color=#537699]╖[/color][color=#5b7a97]░▒[/color][color=#2f4977]▓[/color][color=#152441]█[/color][color=#13274c]█[/color][color=#122b56]█[/color][color=#142b55]█[/color][color=#124081]▓[/color][color=#0e4c9b]▓[/color][color=#0b60bd]▓[/color][color=#0c5ab0]▓[/color][color=#1258a6]▓[/color][color=#11498b]▓[/color][color=#133c7e]▓[/color][color=#0f417d]█▓▓[/color][color=#0d458a]▓▓▓[/color][color=#0a60ac]▓[/color][color=#0a71b6]▓[/color][color=#1163a3]▓[/color][color=#1f5270]▓[/color][color=#6a632b]▓[/color][color=#6e6431]▓▓[/color][color=#7b7030]▓[/color][color=#594e49]╣[/color][color=#585171]▒[/color][color=#51576f]▒▒[/color][color=#4d597d]▒[/color][color=#4d5a7f]▒▒▒▒[/color][color=#30416d]▓[/color][color=#2a3965]▓[/color][color=#2c3955]▓[/color][color=#a08d26]▒[/color][color=#b1921d]▒[/color][color=#d6ab13]▒[/color][color=#e0b310]╢▒╢╣╢[/color][color=#e8ac05]╢[/color][color=#e6ad06]╣[/color][color=#d3980e]╢[/color][color=#d28513]╢[/color][color=#dc8d0d]╢[/color][color=#80593b]╣[/color]                                                                                                                                                                  //
//    [color=#0b111a]█[/color][color=#0c1529]█[/color][color=#061a3c]█[/color][color=#021e51]█[/color][color=#012058]██[/color][color=#012869]█[/color][color=#002a6f]██[/color][color=#023792]▓[/color][color=#044fb4]▓[/color][color=#0b53b0]▓[/color][color=#03153b]█[/color][color=#020f36]█[/color][color=#071b5d]█[/color][color=#0e2b7f]█[/color][color=#0b46ab]▓[/color][color=#1a4a9c]▓[/color][color=#1c438f]▓[/color][color=#1f52a2]▓[/color][color=#2262bf]▓[/color][color=#3366a7]▒[/color][color=#375786]▌[/color][color=#567293]▒[/color][color=#587395]▒░[/color][color=#4273a3]▒[/color][color=#4a709b]▒[/color][color=#4c6d99]▒[/color][color=#152e58]█[/color][color=#081c3c]█[/color][color=#082450]█[/color][color=#062f73]▓[/color][color=#033593]▓[/color][color=#317cb6]▒[/color][color=#1666ab]▓[/color][color=#0b2e61]█[/color][color=#062e73]█[/color][color=#0a3b83]▓[/color][color=#0b367a]█[/color][color=#0b2e63]███[/color][color=#0d3f82]▓[/color][color=#0d4589]▓[/color][color=#114a86]▓[/color][color=#19497e]▓[/color][color=#26527a]▓[/color][color=#385d82]▓[/color][color=#53637d]▒[/color][color=#555c6c]▒[/color][color=#535b62]▒[/color][color=#525655]▒[/color][color=#766b4a]╬[/color][color=#736642]╢[/color][color=#545b71]▒[/color][color=#4c5980]▒[/color][color=#4e5b83]╢▒▒▒▒▒[/color][color=#94863c]▒[/color][color=#5c583f]▐[/color][color=#212f55]▓[/color][color=#212e51]▓█[/color][color=#2b3654]▓[/color][color=#b5a237]▒[/color][color=#bba530]▒[/color][color=#706744]@[/color][color=#6e643b]▓[/color][color=#7c6c33]▒[/color][color=#b59a39]▒[/color][color=#b49637]▒[/color][color=#c49a22]╢[/color][color=#af8e25]▓[/color][color=#898624]╣[/color][color=#66663e]╣[/color]                                                                         //
//    [color=#0d1d3a]█[/color][color=#05265d]█[/color][color=#022a6c]███[/color][color=#01337f]▓[/color][color=#013995]▓[/color][color=#013894]▓[/color][color=#0244a4]▓[/color][color=#064bae]▓[/color][color=#0b4aa9]▓[/color][color=#416496]▒[/color][color=#3b669d]▒[/color][color=#0448aa]▓[/color][color=#03409c]▓[/color][color=#0658b5]▓[/color][color=#265b9c]╣[/color][color=#335b8d]▓[/color][color=#4477a3]▒[/color][color=#3c75a8]╢▒[/color][color=#073a95]▓[/color][color=#063a9b]▓[/color][color=#134fa2]▓[/color][color=#1d5fa9]▓[/color][color=#1d5b99]▓[/color][color=#1f5390]▓▓[/color][color=#2b63a1]▒[/color][color=#073172]█[/color][color=#053d89]▓[/color][color=#044699]▓[/color][color=#0353af]▓[/color][color=#0653b0]▓[/color][color=#1e4a86]▓[/color][color=#153d78]▓[/color][color=#0d2b63]█[/color][color=#0e276d]█[/color][color=#143c84]█▓[/color][color=#0a2c66]▓[/color][color=#0a3070]▓██[/color][color=#114672]▓[/color][color=#134c70]▓[/color][color=#195a78]▓[/color][color=#206378]▓[/color][color=#2a5582]▓[/color][color=#445987]╢[/color][color=#495782]▒▒▒[/color][color=#4f596f]╣[/color][color=#988338]╢[/color][color=#605b59]▒[/color][color=#5b595b]▒▒▒▒▒▒[/color][color=#6d6351]▒[/color][color=#c5aa2b]▒[/color][color=#a68c29]▒[/color][color=#3a3832]▀[/color][color=#333539]█▀[/color][color=#5c583e]▀[/color][color=#b7a83c]▒[/color][color=#baaa36]▒[/color][color=#2d3455]▓[/color][color=#29345b]▓▓[/color][color=#6a5c3b]▓[/color][color=#7e6d41]╢[/color][color=#957c34]╫[/color][color=#92732f]▓[/color][color=#ab6e30]╢[/color][color=#7c6f39]╣[/color]                                                                                                                                                                                            //
//    [color=#041634]█[/color][color=#011b4c]█[/color][color=#01235c]█[/color][color=#002866]█[/color][color=#023682]▓[/color][color=#0042aa]▓[/color][color=#0043c2]▓[/color][color=#0046d5]▓[/color][color=#014bd0]▓▓[/color][color=#0243b1]▓[/color][color=#023da5]▓▓▓[/color][color=#0e50ad]▓[/color][color=#3870a4]▒[/color][color=#436e9c]░░▀[/color][color=#1366b1]▓[/color][color=#0150b7]▓[/color][color=#0153b8]▓[/color][color=#043374]█[/color][color=#062454]█[/color][color=#052758]█[/color][color=#062e65]█[/color][color=#0d2e69]█[/color][color=#133a7f]▓[/color][color=#3c649a]▒[/color][color=#194684]▓[/color][color=#054292]▓[/color][color=#044ca6]▓[/color][color=#064baf]▓[/color][color=#0c378c]▓[/color][color=#132f6a]▓[/color][color=#132961]█[/color][color=#253565]▌[/color][color=#4d6489]╙[/color][color=#255a96]▓[/color][color=#0456ad]▓[/color][color=#035ab7]▓▓[/color][color=#083877]█[/color][color=#0a295c]█[/color][color=#0a2957]██[/color][color=#0f3254]█[/color][color=#194358]█[/color][color=#2b3d4d]▓[/color][color=#454c52]▒[/color][color=#5d5f51]▒[/color][color=#6a674f]▒[/color][color=#6f6b50]▒[/color][color=#877c48]▒[/color][color=#bd9029]▒[/color][color=#c0952d]▒▒[/color][color=#af8d2e]▒[/color][color=#ab8d2c]▒▒╢[/color][color=#b88929]▒[/color][color=#bc8f29]▒[/color][color=#b98f2e]▒[/color][color=#c7a329]▒[/color][color=#cab42d]▒[/color][color=#b9a43a]▒[/color][color=#b49c37]╥[/color][color=#bea429]@[/color][color=#c3a21f]╢[/color][color=#c0ac2f]▒[/color][color=#b4a53f]▒[/color][color=#968239]╫[/color][color=#7c652f]▓[/color][color=#775e2c]▓╣▓[/color][color=#6a5d36]▓[/color][color=#7f8b3d]▒[/color][color=#665a43]╣[/color]                                                                                                //
//    [color=#041e48]█[/color][color=#012c6f]█[/color][color=#01328f]█[/color][color=#094db6]▓[/color][color=#205b9e]▓[/color][color=#1153a4]▓[/color][color=#1852a0]▓[/color][color=#1050c0]▓[/color][color=#0555db]▓[/color][color=#1159cd]▓[/color][color=#1460bf]▓[/color][color=#146abc]▓[/color][color=#155dae]▓[/color][color=#1a5092]▓[/color][color=#4a749c]░[/color][color=#587c9a]░[/color][color=#5a7b99]░░[/color][color=#3e7cb0]▒[/color][color=#3d6a9d]║[/color][color=#0f53a8]▓[/color][color=#034399]▓[/color][color=#014fb0]▓[/color][color=#024aa8]▓[/color][color=#0b4199]▓[/color][color=#1140a7]▓[/color][color=#294aa0]▓[/color][color=#2e58ab]╣[/color][color=#587095]░[/color][color=#4f6e98]░[/color][color=#15479c]▓[/color][color=#0c419f]▓[/color][color=#135cb5]▓[/color][color=#2151ab]▓[/color][color=#16316f]▓[/color][color=#12316a]█▓▓[/color][color=#0f3c7c]▓[/color][color=#0b2954]█[/color][color=#073f81]████[/color][color=#07386f]██▓▓[/color][color=#0a336c]▓[/color][color=#0c2852]█[/color][color=#0f203a]█[/color][color=#222a29]█[/color][color=#48472f]▄[/color][color=#716a3e]▄[/color][color=#9b792c]║[/color][color=#ab8329]╣[/color][color=#b78a29]╣[/color][color=#b88e2e]╢▒▒[/color][color=#b39030]▒▒▒▒▒▒[/color][color=#ae7f2f]▒[/color][color=#a27737]▒[/color][color=#9d753a]▒[/color][color=#ac853a]╢[/color][color=#96782e]╠[/color][color=#776d35]▓[/color][color=#6f6234]▓[/color][color=#5a4c37]▓[/color][color=#86652a]▓[/color][color=#9f751f]▓[/color][color=#9b6e21]▓[/color][color=#685b3f]▓[/color][color=#78503e]╫[/color][color=#455d5d]╣[/color]                                                                                                                                                                                            //
//    [color=#041d4e]█[/color][color=#002b7a]█[/color][color=#0145c2]▓[/color][color=#315790]╣[/color][color=#1c4479]▓[/color][color=#1d4272]▓▓[/color][color=#24558c]▓[/color][color=#0b58d0]▓[/color][color=#024cde]▓[/color][color=#0150d8]▓[/color][color=#0056c7]▓[/color][color=#004bb0]▓▓[/color][color=#175ea8]▓[/color][color=#4b719a]╓[/color][color=#436795]▒[/color][color=#2252a4]▓[/color][color=#18367f]█[/color][color=#09439d]▓[/color][color=#113f8d]▓[/color][color=#214f9c]▓[/color][color=#1b529f]▓[/color][color=#0d3b98]▓[/color][color=#0639a4]▓[/color][color=#3464ab]W[/color][color=#51709b]░[/color][color=#4a6da0]▒[/color][color=#3e6ca9]▒[/color][color=#193361]█[/color][color=#071d4b]█[/color][color=#214792]▌[/color][color=#506e9d]▒[/color][color=#4868a1]▒[/color][color=#2a51a5]╣[/color][color=#1a3997]▓[/color][color=#1e3d8f]▓[/color][color=#22469b]▓[/color][color=#0c346d]▓[/color][color=#0e1c30]█[/color][color=#0e2d58]█[/color][color=#0b2548]█[/color][color=#0c2445]██[/color][color=#12243c]█[/color][color=#122649]█[/color][color=#0e264b]█[/color][color=#0b2345]█[/color][color=#0b2144]██[/color][color=#0c2855]█[/color][color=#0d2751]█▓[/color][color=#0d1f3d]█[/color][color=#0d192f]█[/color][color=#212421]█[/color][color=#886d29]▄[/color][color=#b5852b]╣[/color][color=#bb8b28]▒▒▒[/color][color=#ac8a2f]▒[/color][color=#b8902f]▒[/color][color=#b79231]▒▒[/color][color=#d1aa1d]▒[/color][color=#a57f2f]╫[/color][color=#957646]▒[/color][color=#9a7845]▒[/color][color=#a8823b]▒[/color][color=#4e4540]▓[/color][color=#1f2a4d]▓[/color][color=#202e52]▓[/color][color=#222f51]▓[/color][color=#9f8129]▒[/color][color=#ce9f13]╢[/color][color=#916f2e]╣[/color][color=#a36227]╣[/color][color=#676a35]╣[/color][color=#5d4952]▒[/color]    //
//    [color=#042662]█[/color][color=#0037a3]▓[/color][color=#0254d5]▓[/color][color=#0769dd]▓[/color][color=#1861c4]▓[/color][color=#1456bb]▓[/color][color=#1150c1]▓[/color][color=#064dcf]▓▓[/color][color=#0552d4]▓▓▓[/color][color=#0056ca]▓[/color][color=#075ecc]▓[/color][color=#1863bf]▓[/color][color=#0351ba]▓[/color][color=#04409a]▓[/color][color=#043681]█[/color][color=#05357b]▓[/color][color=#063073]█[/color][color=#05225d]█[/color][color=#1f5198]▓[/color][color=#2056a9]▓[/color][color=#2e5fa0]▓[/color][color=#2b60a3]▓[/color][color=#2568b5]╢[/color][color=#265cb1]▓[/color][color=#305fa7]╣[/color][color=#355d9f]▒[/color][color=#285b9d]▓[/color][color=#164a94]▓[/color][color=#1257b8]▓[/color][color=#326aaf]╣[/color][color=#3973b2]╫[/color][color=#1858bb]▓[/color][color=#174ba4]▓[/color][color=#174196]▓▓[/color][color=#153869]▓[/color][color=#1b273d]█[/color][color=#1f335b]▓[/color][color=#1e3d6d]▓▓[/color][color=#253659]▓[/color][color=#2c374e]▓[/color][color=#2e394f]▓[/color][color=#30384f]▓▓[/color][color=#283353]▓[/color][color=#273757]▓[/color][color=#1d3257]█[/color][color=#13264a]█[/color][color=#0e264c]██[/color][color=#102e58]███[/color][color=#222825]█[/color][color=#68582a]▄[/color][color=#b58b2b]▒[/color][color=#b58a2b]▒╢[/color][color=#b19131]▒[/color][color=#b09239]▒[/color][color=#b29239]▒[/color][color=#b58d31]▒[/color][color=#c0972b]▒▒▒[/color][color=#c29e24]▒▒[/color][color=#8f7520]▄[/color][color=#958023]▄[/color][color=#d2b323]▒[/color][color=#be9d20]╫[/color][color=#8e702d]╢[/color][color=#684640]╣[/color][color=#5e4155]╬[/color][color=#3e7045]╣[/color][color=#475172]▒[/color]                                                                                                                       //
//    [color=#02276c]█[/color][color=#0954b6]▓[/color][color=#1e7bc0]╢[/color][color=#1175c5]▓[/color][color=#167bc8]▓▓[/color][color=#023d9a]▓[/color][color=#013596]▓▓[/color][color=#0343ae]▓[/color][color=#216abe]▓[/color][color=#3580b9]▒[/color][color=#3e85b3]▒[/color][color=#3a84b9]▒[/color][color=#4171a4]▒[/color][color=#1858ab]▓[/color][color=#063276]█[/color][color=#052a65]█▓█[/color][color=#0f397a]▓[/color][color=#15579a]▓[/color][color=#145aa4]▓▓[/color][color=#3f7097]▒[/color][color=#3d8296]╢[/color][color=#497083]▒[/color][color=#3d6ba0]╢[/color][color=#2e6ba2]╣[/color][color=#3775a0]╢[/color][color=#1770b1]▓[/color][color=#176fad]▓[/color][color=#1d72b4]╣[/color][color=#1d70b9]╫[/color][color=#1058ae]▓▓[/color][color=#2a60a4]▓[/color][color=#205398]▓[/color][color=#13284d]█[/color][color=#1a2949]█[/color][color=#20396a]▓[/color][color=#223970]▓▓[/color][color=#1f3158]▓[/color][color=#3c3a39]▓[/color][color=#6f583b]▓[/color][color=#796651]▒[/color][color=#746656]▒[/color][color=#887241]▒[/color][color=#8a7133]╣[/color][color=#665a43]▓[/color][color=#7b6a49]Ñ╙[/color][color=#3f494d]▀[/color][color=#163152]█[/color][color=#122e58]█[/color][color=#112d5b]██[/color][color=#14233b]█[/color][color=#645a2c]▓[/color][color=#af852f]╢[/color][color=#b2882e]▒[/color][color=#b59433]▒[/color][color=#af933b]▒▒▒[/color][color=#bd8f2e]▒[/color][color=#be902f]▒[/color][color=#bc9636]▒▒[/color][color=#c6b027]▒[/color][color=#83732b]▀[/color][color=#88771d]▀[/color][color=#cab92b]▒[/color][color=#9a8d43]▒[/color][color=#827b48]▒[/color][color=#6d5c44]╫[/color][color=#3b6a51]▓[/color][color=#363476]▓[/color][color=#53576e]▒[/color]                                                                                                //
//    [color=#032564]█[/color][color=#013493]█[/color][color=#0e509e]▓[/color][color=#115ea8]▓[/color][color=#1563ac]▓[/color][color=#0f55a2]▓[/color][color=#0145a2]▓[/color][color=#003d9e]▓[/color][color=#01338f]█[/color][color=#063f8f]▓[/color][color=#2065b8]▓[/color][color=#427cad]▒[/color][color=#437ead]▒▒[/color][color=#477298]▒[/color][color=#1a4f86]▓[/color][color=#124688]▓▓[/color][color=#275387]▄[/color][color=#355480]▄[/color][color=#2d598b]▓[/color][color=#275082]▓[/color][color=#2c547f]▓[/color][color=#506581]░[/color][color=#627274]░[/color][color=#406d6e]╢[/color][color=#39749b]╬[/color][color=#3478ab]╢[/color][color=#427aa4]╣[/color][color=#3786b5]╟[/color][color=#2f7db7]▒[/color][color=#257ab6]▓[/color][color=#2481ba]╢[/color][color=#327cb4]╣[/color][color=#155ead]▓[/color][color=#116ebe]▓▓[/color][color=#084898]▓[/color][color=#093f86]▓[/color][color=#0b3877]▓[/color][color=#0d182c]█[/color][color=#0d121e]█[/color][color=#0c111b]█[/color][color=#273837]▌[/color][color=#9e914a]▒[/color][color=#b8992d]╢[/color][color=#9d7b2a]╫[/color][color=#9f7e32]▒[/color][color=#8c7446]▒[/color][color=#a28437]▒[/color][color=#9b7d35]▒[/color][color=#93783a]K[/color][color=#a48a33]▒[/color][color=#736b5c]╜[/color][color=#464b5c]▀[/color][color=#12223d]█[/color][color=#102851]█[/color][color=#112c57]█[/color][color=#122c5a]▓[/color][color=#1f3848]█[/color][color=#6c6235]▓[/color][color=#b6812c]▒[/color][color=#af8c33]▒[/color][color=#ab8b37]▒▒▒▒▒▒▒[/color][color=#bba537]▒[/color][color=#c1b02e]▒[/color][color=#bba529]▒[/color][color=#b39e2c]▒[/color][color=#aca02c]▒[/color][color=#424229]█[/color][color=#31362d]█[/color][color=#32283b]█[/color][color=#453f4c]▓[/color][color=#614c66]▒[/color]                           //
//    [color=#032668]█[/color][color=#012d7e]▓[/color][color=#012d78]████[/color][color=#0752a9]▓[/color][color=#0a6bc7]▓[/color][color=#024abd]▓[/color][color=#0f55b1]▓[/color][color=#1057bb]▓[/color][color=#3270b1]@[/color][color=#3269ba]▐[/color][color=#4b70a4]M[/color][color=#28559e]▒[                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract arttime is ERC721Creator {
    constructor() ERC721Creator("arttimetais", "arttime") {}
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