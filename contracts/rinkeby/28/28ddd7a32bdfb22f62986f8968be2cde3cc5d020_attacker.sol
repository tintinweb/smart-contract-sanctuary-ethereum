/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

pragma solidity 0.5.9;
// SPDX-License-Identifier: MIT
contract attacker{
        function attack1(address watch_addr, uint x) public {
        watch_addr.call(abi.encodeWithSignature("subtractVal(uint)", x));
    }
    
    // address public contractAddress = 0x96Ac225AcfEeeB7628DF5d46Ae60ff23437a1605;
    // function attack1(uint x) external returns(uint){
    //     return contractAddress.subtractVal(x);
    // }
    // function attack2(uint x) external returns(uint){
    //     return contractAddress.addVal(x);
    // }
}