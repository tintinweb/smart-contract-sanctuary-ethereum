/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// File: contracts/Distribute.sol


pragma solidity >=0.8.0;

contract Distribute {
   
    receive() external payable {
        uint _amount;
        _amount = msg.value;
        payable(0x2947d8134f148B2A7Ed22C10FAfC4d6Cd42C1054).transfer(_amount * 150 / 1000);
        payable(0x1695e62192959A93625EdD8993A2c44faed666Ac).transfer(_amount * 40 / 1000);
        payable(0x49C4D560C2b8C2C72962dA8B02B1C428d745a6Fd).transfer(_amount * 40 / 1000);
        payable(0xce9F8dDA015702E40cF697aDd3D55E2cF122c641).transfer(_amount * 20 / 1000);
        payable(0xe34f72eD903c9f997B9f8658a1b082fd55093DA7).transfer(_amount * 200 / 1000);
        payable(0x79C61C20e9C407E4D768a78F7350B78157530183).transfer(_amount * 100 / 1000);
        payable(0x12A75919B84810e02B1BD4b30b9C47da4c893B10).transfer(_amount * 400 / 1000);
        payable(0xD48b024D9d0751f19Ab3D255101405EB534Ea76A).transfer(_amount * 50 / 1000);
    }
}