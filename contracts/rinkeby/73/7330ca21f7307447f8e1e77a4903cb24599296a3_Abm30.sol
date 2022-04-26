// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: fode
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//    [size=9px][font=monospace][color=#808080]                                                               [/color][color=#6d6969],[/color][color=#232121]█[/color][color=#09090a]█[/color][color=#080708]█[/color][color=#242120]▌[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              //
//    [color=#808080]                                                              [/color][color=#373434]▓[/color][color=#040605]█[/color][color=#030504]███[/color][color=#231a1a]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               //
//    [color=#808080]                                                            [/color][color=#4f4a4b]▄[/color][color=#09090a]█[/color][color=#030506]█[/color][color=#050706]█[/color][color=#312a2c]▀██[/color][color=#241919]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#808080]                                                          [/color][color=#625f5f]╓[/color][color=#161617]█[/color][color=#030505]█[/color][color=#050706]█[/color][color=#393636]▀  ██[/color][color=#261e1f]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 //
//    [color=#808080]                                                        [/color][color=#736f70],[/color][color=#2a2828]█[/color][color=#040504]█[/color][color=#050807]█[/color][color=#3b3737]▀   [/color][color=#403c3c]▄[/color][color=#060708]█[/color][color=#050506]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    //
//    [color=#808080]                              [/color][color=#131111]█                        [/color][color=#3f3d3d]▄[/color][color=#060607]█[/color][color=#050707]█[/color][color=#3a3636]▀   [/color][color=#3c3939]▓[/color][color=#070807]█[/color][color=#030505]███[/color][color=#312c2c]▌[/color]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            //
//    [color=#808080]                             [/color][color=#111110]█[/color][color=#030606]█[/color][color=#1c1b1b]█                     [/color][color=#575152]▄[/color][color=#0d0d0d]█[/color][color=#060607]█[/color][color=#3a3637]▀  [/color][color=#757071],[/color][color=#443f3f]#[/color][color=#555252]╙ [/color][color=#6c6766]└[/color][color=#080707]█[/color][color=#030506]███[/color]                                                                                                                                                                                                                                                                                                                                                                                                //
//    [color=#808080]                            [/color][color=#161414]█[/color][color=#030605]█[/color][color=#040504]██[/color][color=#4d4446]▌                  [/color][color=#6a6666]╓[/color][color=#1e1b1c]█[/color][color=#050808]█[/color][color=#3b3637]▀  [/color][color=#726d6c],▓[/color][color=#4b4948]▀    [/color][color=#3a3536]╟[/color][color=#030605]█[/color][color=#040504]██[/color][color=#453f40]▌[/color]                                                                                                                                                                                                                                                                                                                                                                        //
//    [color=#808080]                           [/color][color=#1a1818]█[/color][color=#030605]█[/color][color=#121111]█[/color][color=#50484a]╙[/color][color=#030505]█[/color][color=#050507]█                 [/color][color=#323131]▓█[/color][color=#3a3737]▀  [/color][color=#6e6969],[/color][color=#322d2d]▓[/color][color=#444140]▀       [/color][color=#040606]█[/color][color=#040505]██[/color][color=#1d1c1b]█[/color]                                                                                                                                                                                                                                                                                                                                                                        //
//    [color=#808080]                          █[/color][color=#030506]█[/color][color=#0d0e0d]█  [/color][color=#0b0b0c]██               [/color][color=#494544]▄█[/color][color=#3a3737]▀  [/color][color=#686564]╓[/color][color=#292726]█[/color][color=#393736]▀         [/color][color=#1f1d1d]█[/color][color=#030505]█[/color][color=#030504]█[/color][color=#0c0c0b]█[/color]                                                                                                                                                                                                                                                                                                                                                                                                                      //
//    [color=#808080]                         [/color][color=#242121]█[/color][color=#030505]█[/color][color=#08090a]█  [/color][color=#766f70]][/color][color=#040606]█[/color][color=#605658]⌐       [/color][color=#676363]╓[/color][color=#070707]█[/color][color=#292727]█[/color][color=#6d6969],   █[/color][color=#030505]█[/color][color=#393435]▌  [/color][color=#212121]█[/color][color=#2a2527]▌           [/color][color=#373535]╟[/color][color=#040504]█[/color][color=#030605]█[/color][color=#090b0b]█[/color]                                                                                                                                                                                                                                                                            //
//    [color=#808080]                        [/color][color=#292726]█[/color][color=#030506]█[/color][color=#060707]█[/color][color=#6a6363]¬  [/color][color=#1e1c1c]█[/color][color=#030506]█[/color][color=#080b0a]█[/color][color=#5d5858]▄     [/color][color=#6b6465]╓[/color][color=#070808]█[/color][color=#030605]█[/color][color=#030505]██[/color][color=#302c2e]█  [/color][color=#171413]█[/color][color=#030505]█[/color][color=#564d4e]▌ [/color][color=#665f60]▐[/color][color=#040606]█            [/color][color=#383736]╟██[/color][color=#181413]█       [/color][color=#605c5d]▄[/color][color=#252324]█[/color][color=#1d1b1a]█[/color]                                                                                                                                               //
//    [color=#808080]                       [/color][color=#2f2c2c]▓[/color][color=#030607]█[/color][color=#040606]█[/color][color=#605c5b]¬  [/color][color=#322f30]▓[/color][color=#040605]█[/color][color=#030506]███[/color][color=#4a4645]▌   [/color][color=#6f6869],[/color][color=#090b0a]█[/color][color=#030505]██[/color][color=#030504]███[/color][color=#0a0a0a]█[/color][color=#655e5e]µ[/color][color=#050706]█[/color][color=#040506]█  [/color][color=#2b2728]▓[/color][color=#282525]▌            [/color][color=#252323]█[/color][color=#040404]█[/color][color=#030507]█[/color][color=#3e3939]▌     [/color][color=#504b4c]▄[/color][color=#151414]█[/color][color=#030605]█[/color][color=#030505]██[/color][color=#4a4445]▌[/color]                                                  //
//    [color=#808080]                      [/color][color=#363232]▓[/color][color=#030505]█[/color][color=#030505]█[/color][color=#585251]▀  [/color][color=#403c3b]▓[/color][color=#232020]█ [/color][color=#524d4e]╙[/color][color=#090909]█[/color][color=#030507]█[/color][color=#030505]█[/color][color=#504949]▌ [/color][color=#706d6c],[/color][color=#0b0a0b]█[/color][color=#030606]█[/color][color=#151313]█ [/color][color=#2a2727]╟[/color][color=#030504]█[/color][color=#040505]█████  █[/color][color=#6a6565]¬            ███   [/color][color=#767271],[/color][color=#3c3b39]▓[/color][color=#0a0a09]█[/color][color=#030606]█[/color][color=#040404]█[/color][color=#080908]███[/color][color=#110f0e]█[/color]                                                                         //
//    [color=#808080]                     [/color][color=#40393a]▓[/color][color=#030605]█[/color][color=#030505]█[/color][color=#504948]▀  [/color][color=#464042]▄[/color][color=#252424]▌    [/color][color=#060707]█[/color][color=#030507]██[/color][color=#726867],[/color][color=#0e0c0d]█[/color][color=#030606]█[/color][color=#161515]█   [/color][color=#0b0b0b]█[/color][color=#030605]█[/color][color=#030605]███[/color][color=#322d2d]▌ [/color][color=#453e3f]╟[/color][color=#1a1919]█            ╫[/color][color=#030505]█[/color][color=#030605]█[/color][color=#504949]▀ [/color][color=#686261]╓[/color][color=#2c2929]█[/color][color=#040605]█[/color][color=#030505]██[/color][color=#201f1e]█[/color][color=#535151]╙ [/color][color=#030605]█[/color][color=#030605]██[/color]    //
//    [color=#808080]                    [/color][color=#454040]▄[/color][color=#030505]█[/color][color=#030505]█[/color][color=#433e3d]▀  [/color][color=#474242]▄[/color][color=#292627]▌     [/color][color=#403b3b]╟[/color][color=#030505]█[/color][color=#030506]█[/color][color=#0c0a09]██[/color][color=#191716]█    [/color][color=#524b4a]╟[/color][color=#020707]█[/color][color=#040404]███[/color][color=#655e5e]⌐ [/color][color=#0b0a0b]█⌐           [/color][color=#716b6b]][/color][color=#050607]█[/color][color=#030605]█[/color][color=#443c3c]▀[/color][color=#555050]▄[/color][color=#1a1818]█[/color][color=#030504]█[/color][color=#030604]█[/color][color=#0c0c0c]█[/color][color=#3e3b3c]▀   [/color][color=#615958]▐[/color][color=#030505]█[/color][color=#030605]██[/color]    //
//    [color=#808080]                   [/color][color=#4b4546]▄[/color][color=#030505]█[/color][color=#020705]█[/color][color=#383333]▌  [/color][color=#444040]▄[/color][color=#2b2828]▌      [/color][color=#625a59]▐[/color][color=#030505]█[/color][color=#030505]██[/color][color=#1a1a18]█      ███[/color][color=#0c0d0c]█ [/color][color=#514b4c]▐[/color][color=#171516]█            [/color][color=#111112]█[/color][color=#050607]█[/color][color=#231a1c]█[/color][color=#0d0c0c]█[/color][color=#030606]█[/color][color=#040505]█[/color][color=#272425]▀[/color][color=#5d5859]└     [/color][color=#1a1919]█[/color][color=#030506]█[/color][color=#040405]█[/color][color=#2f2d2d]▌[/color]                                                                                                //
//    [color=#808080]                  [/color][color=#524c4d]▐[/color][color=#030606]█[/color][color=#030505]█[/color][color=#2c2929]▌  [/color][color=#3e3939]▓▌       [/color][color=#615759]▐[/color][color=#030503]█[/color][color=#030504]█[/color][color=#1b1a19]█       [/color][color=#0e0f0e]█[/color][color=#040404]█[/color][color=#030607]█[/color][color=#4b4444]▌ [/color][color=#0d0d0e]█[/color][color=#655e5e]⌐           [/color][color=#161414]█[/color][color=#030505]█[/color][color=#030605]██[/color][color=#101011]█[/color][color=#454242]▀       [/color][color=#4c4647]▐[/color][color=#030605]█[/color][color=#030504]█[/color][color=#080909]█[/color]                                                                                                                        //
//    [color=#808080]                 [/color][color=#585253]▐[/color][color=#040505]█[/color][color=#030506]█[/color][color=#222022]█  [/color][color=#353132]▓[/color][color=#332f30]▌        [/color][color=#423c3d]╟[/color][color=#030506]█[/color][color=#1e1c1b]█        [/color][color=#0d0f0e]█[/color][color=#040406]██ [/color][color=#494444]╟[/color][color=#231f20]▌          [/color][color=#6c6868]╓[/color][color=#110e0f]█[/color][color=#030606]█[/color][color=#050607]█[/color][color=#2e2b2b]▀[/color][color=#625f5e]└        [/color][color=#544f4f]▄[/color][color=#030606]█[/color][color=#030505]██[/color][color=#676061]─[/color]                                                                                                                                               //
//    [color=#808080]                [/color][color=#5e5858]▐[/color][color=#040506]█[/color][color=#030506]█[/color][color=#1d191a]█  [/color][color=#292829]█[/color][color=#363232]▌         [/color][color=#100f0f]█[/color][color=#1f1f1f]█         [/color][color=#030504]█[/color][color=#040406]█[/color][color=#554e4e]▀ [/color][color=#080a09]█          [/color][color=#4c4848]▄█[/color][color=#161616]█▀          [/color][color=#3e393a]▓[/color][color=#040505]█[/color][color=#030506]█[/color][color=#121010]█[/color][color=#6d6867]`[/color]                                                                                                                                                                                                                                            //
//    [color=#808080]               [/color][color=#655d5f]╓[/color][color=#040706]█[/color][color=#030506]█[/color][color=#151313]█  [/color][color=#202020]█[/color][color=#393536]▌         [/color][color=#645b5d]▐[/color][color=#222020]█         [/color][color=#403b3b]╟[/color][color=#020607]█[/color][color=#221f20]▌ [/color][color=#2f2a2b]▓[/color][color=#443e3e]▌        [/color][color=#6e6c6c],[/color][color=#232121]█[/color][color=#333131]▀[/color][color=#696565]`          [/color][color=#635d5e]╓[/color][color=#151414]█[/color][color=#030505]█[/color][color=#050606]█[/color][color=#3b3839]▀[/color]                                                                                                                                                                         //
//    [color=#808080]               [/color][color=#0e0f10]█[/color][color=#030606]█[/color][color=#030506]█[/color][color=#423d3e]▌ [/color][color=#6e6667]j[/color][color=#130d0e]█          [/color][color=#383333]▌         [/color][color=#696563]╓[/color][color=#050607]█[/color][color=#0f0e0f]█ [/color][color=#5b5555]▐[/color][color=#1a1817]█        [/color][color=#504a4b]#[/color][color=#544f50]╙           [/color][color=#5f5c5b]▄[/color][color=#1e1f1f]█[/color][color=#030505]█[/color][color=#050707]█[/color][color=#343030]▀[/color]                                                                                                                                                                                                                                                //
//    [color=#808080]               [/color][color=#1e1b1b]█[/color][color=#030505]█[/color][color=#030506]█[/color][color=#40393a]▌  [/color][color=#171211]█         [/color][color=#595454]▐[/color][color=#524b4b]▄[/color][color=#403d3d]▓[/color][color=#363132]▓[/color][color=#1e1f1f]█[/color][color=#1c1f1f]█[/color][color=#2c292a]█   [/color][color=#686363]╓[/color][color=#09090a]█[/color][color=#0b0c0c]█ [/color][color=#706a6b]]█      [/color][color=#787878]."           ,[/color][color=#424040]▄[/color][color=#101011]█[/color][color=#030506]██[/color][color=#464341]▀[/color]                                                                                                                                                                                                    //
//    [color=#808080]               [/color][color=#322d2e]╟[/color][color=#030505]█[/color][color=#030505]█[/color][color=#3c3534]▌  [/color][color=#383130]╟     [/color][color=#676564]╓[/color][color=#585251]#[/color][color=#544e4e]▀╙[/color][color=#6a6766]─   [/color][color=#1d1919]█[/color][color=#030405]█[/color][color=#373432]▀[/color][color=#50494c]╙[/color][color=#575255]▄[/color][color=#464142]▄[/color][color=#050506]█[/color][color=#151615]█ [/color][color=#706b6b],[/color][color=#0f100f]█[/color][color=#696464]¬                [/color][color=#635e5e]╓[/color][color=#3c3a3a]▓[/color][color=#151514]█[/color][color=#030505]█[/color][color=#0f1011]█[/color][color=#3a3937]▀[/color][color=#686565]`[/color]                                                            //
//    [color=#808080]               [/color][color=#464243]╟[/color][color=#030505]█[/color][color=#030506]█[/color][color=#3a2f2f]▌  [/color][color=#625f5e]▐  [/color][color=#6c6867]»"└      [/color][color=#5f5c59]▄[/color][color=#131112]█[/color][color=#212021]█[/color][color=#666364]¬  [/color][color=#342f2f]▓[/color][color=#040605]█[/color][color=#3c3938]▀ [/color][color=#534e4e]▄[/color][color=#1b1919]█             [/color][color=#6e6a6a],[/color][color=#555351]▄[/color][color=#393736]▓[/color][color=#1b1a1a]█[/color][color=#040706]█[/color][color=#060808]█[/color][color=#221e1d]█[/color][color=#433d3d]▀[/color][color=#6a6464].[/color]                                                                                                                                    //
//    [color=#808080]               [/color][color=#5c5252]▐[/color][color=#030506]█[/color][color=#030606]█[/color][color=#231a1c]█[/color][color=#696766],           [/color][color=#5b5657]▄[/color][color=#1d1b1b]█[/color][color=#2e2c2d]▀[/color][color=#6a6566]`    [/color][color=#040605]█[/color][color=#554d4e]▌ [/color][color=#3a3636]╟[/color][color=#343133]▌          [/color][color=#655f5f]*[/color][color=#4a4545]▀[/color][color=#2c2829]▀[/color][color=#141415]█[/color][color=#0a0a0b]█[/color][color=#040506]█[/color][color=#030505]█████[/color][color=#191817]█[/color]                                                                                                                                                                                                          //
//    [color=#808080]             [/color][color=#6b6765]╓[/color][color=#3b3939]▓[/color][color=#0e0e0e]█[/color][color=#030606]██[/color][color=#403e3d]▀         [/color][color=#726d6d],▄[/color][color=#1d1c1b]█[/color][color=#494544]▀       [/color][color=#131213]█[/color][color=#2e2a2b]▌ [/color][color=#686364]j[/color][color=#272323]▌             [/color][color=#73706e],[/color][color=#5d5a59]▄[/color][color=#423e3f]▄[/color][color=#0f0f10]█[/color][color=#030505]█[/color][color=#131313]█[/color][color=#373435]▀[/color][color=#625e5e]└[/color]                                                                                                                                                                                                                                  //
//    [color=#808080]          [/color][color=#767272],[/color][color=#444241]▄[/color][color=#141212]█[/color][color=#020706]█[/color][color=#050606]█[/color][color=#2d2a2a]▀[/color][color=#625e5d]`        [/color][color=#747271],[/color][color=#474444]▄[/color][color=#1f1c1d]█[/color][color=#363234]▀[/color][color=#676364]`         [/color][color=#352e2e]╟[/color][color=#0a090b]█  [/color][color=#121412]█       [/color][color=#6c686a]ⁿ[/color][color=#494444]Φ[/color][color=#272525]█[/color][color=#181718]█[/color][color=#0c0b0c]█[/color][color=#040505]█[/color][color=#030506]█[/color][color=#3c3537]▌[/color][color=#595655]╙[/color][color=#6a6767]─[/color]                                                                                                                   //
//    [color=#808080]        [/color][color=#5a5556]▄[/color][color=#232121]█[/color][color=#030606]█[/color][color=#030505]█[/color][color=#151716]█[/color][color=#4e4949]▀        [/color][color=#6b6867],[/color][color=#413f40]▄[/color][color=#1a1819]█[/color][color=#292627]▀[/color][color=#5a5758]╙            [/color][color=#554f4f]▐[/color][color=#030505]█[/color][color=#6e6766]⌐ [/color][color=#322e2c]╟      [/color][color=#646161]╓[/color][color=#575555]▄[/color][color=#6d696a]- [/c                                                                                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Abm30 is ERC721Creator {
    constructor() ERC721Creator("fode", "Abm30") {}
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
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
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