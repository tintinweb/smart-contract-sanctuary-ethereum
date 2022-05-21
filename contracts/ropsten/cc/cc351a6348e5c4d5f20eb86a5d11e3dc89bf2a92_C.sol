/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// pragma solidity ^0.4.0; 
// contract A {
//     address public temp1;
//     uint256 public temp2;
//     function three_call(address addr) public {
//             //addr.call(bytes4(keccak256("test()")));                 // 情况1 msg.sender= 合约B调用地址
//             addr.delegatecall(bytes4(keccak256("test()")));       // 情况2  msg.sender= 钱包调用地址
//            // addr.callcode(bytes4(keccak256("test()")));           // 情况3   msg.sender= 合约A地址
//     }
// } 
 
// contract B {
//     address public temp1;
//     uint256 public temp2;    
//     function test() public  {
//         temp1 = msg.sender;     
//         temp2 = 100;    
//     }
// }
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract D {
    uint public x;
    constructor(uint a) payable {
        x = a;
    }
}

contract C {

     address public nowAdr;
     address public prenowAdr;

    function createDSalted(bytes32 salt, uint arg) public {
        /// 这个复杂的表达式只是告诉我们，如何预先计算地址。
        /// 这里仅仅用来说明。
        /// 实际上，你仅仅需要 ``new D{salt: salt}(arg)``.
        address predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(D).creationCode,
                arg
            ))
        )))));
        D d = new D{salt: salt}(arg);
        nowAdr = address(d);
        prenowAdr = predictedAddress;
        require(address(d) == predictedAddress);

    }
}