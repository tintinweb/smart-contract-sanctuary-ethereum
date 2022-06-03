/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IDickenzas {
    function mint() external payable;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function totalSupply() external view returns (uint256);
}

contract SendOutDickenzas {
    IDickenzas dcontract;

    constructor() {
        dcontract = IDickenzas(0x6c0F9679dE42ca516e0AAeB3A661d3aCc1fc04A8);
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4 value) {
            return 0x150b7a02;
     } 

    function sendEm() public payable{
        address[35] memory  thanks_yall = [0x99799dBb5A66B2ED2499524a741AB7911236db1C,
                                0xe74ca58EF724b94fAC7f2e09E2e48536A5c1AD03,
                                0x68d99Ca0ce52fCcD7A4Ec688Df233cd93b73BD14,
                                0xB5D28319363e814ca3a89059b0b181b74cD1fEBa,
                                0x241e8b5475867e10781549d7b96c9691772099FF,
                                0xc711DF3edcA3cCcC375C18273780aA7dCd72F6e7,
                                0xb39F3b058148144572c79EBe24b17ba405cE7D9d,
                                0x9Bc27a47B4413c51f884AE4e4b9170F3A0D7f742,
                                0x6cC6F59f7016A83E1D7c5FaD30CDD8C4cDb4aad1,
                                0x0667640Ab57CB909B343157d718651eA49141A75,
                                0xbe30c4f0a10e4DAc5C2ee002F459734A7A4d2Be6,
                                0xFaF9B179E4A9Dc590f551c8827583f0bbDE7CFe6,
                                0x4c066845535a56b653B04B254A5E8Fa433306b25,
                                0xc968EB14B3ad83cBAe2F1b64d34DcBdc99543CD7,
                                0x14A170cc315CAaf9D6a7a3E4757b955389860E6b,
                                0x1770C692db5F54A642F7f0b96541e92F37fd7454,
                                0x1b716b052445D869c5b49d086d062A815dd6cD58,
                                0x3d7fA056685D3c5f12F96FE51d65cA28cf695d58,
                                0xc57b2900F3AB9b9BD4FFCdB8174Cd7665d0dA8bc,
                                0x40711B63dB79a5E8579bD53f84c5C558E856F806,
                                0x1663E1D4306bb249067F671F8dc573c4Daca92FD,
                                0x8e6df33545B05E1E79Dc159C1c2133a3B7CEA769,
                                0x517D822D3E0E8267E6DaeeA3651f0921B2Eadf2C,
                                0x021d5ABEA6EFbcD5dBa2C8Ae9237471448Ea0856,
                                0x50312d9DB6d19561A72D42361AE433D76CaCB52a,
                                0xdD2Ec9A41e07D490f4426e1F6F50F6DF66822490,
                                0xa085A660515b1711c147582895f9cf7B5f17431E,
                                0x26c9Fc612b005781127246BBc5dC39f823E3106E,
                                0xd1c053cEd027Ef33b8ACBb10AeB7711987B29554,
                                0x201F948e98513aBE8dc70047bA98A050fE67E9fB,
                                0x65546F3419e360b6C62c88F8A060cD1c112bb80B,
                                0xE28BC349f666a4281bbfed1e485e8DFAD90BB3D2,
                                0xEB470820841Ed4A43Fb43dDD047DB1ed96a0cDcD,
                                0x79C39331Bf0d2356db53CeE2dc8a5b42CF8dcE36,
                                0xF5A6bD45240cD607A3673492B66C2A7675b8a030];

        for (uint i=0; i<thanks_yall.length; i++) {
            dcontract.mint{value:0}();
            dcontract.transferFrom(address(this), thanks_yall[i], dcontract.totalSupply() - 1);
        }
    }

}