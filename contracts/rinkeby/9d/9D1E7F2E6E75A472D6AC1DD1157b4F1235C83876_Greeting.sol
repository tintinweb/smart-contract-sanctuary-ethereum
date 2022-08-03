/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MITz
pragma solidity ^0.8.0;
contract Greeting {
    string public greeting = "hello";
    event hello(
        string hello
    );

    function sayHello() external view returns (string memory) {
        return greeting;
        
    }

    function updateGreeting(string calldata _greeting) payable external{
        emit hello("emitted event");
        greeting = _greeting;
    }
    function balanceO() view public returns(uint256){
        return address(this).balance;
    }
    function withdraw() public payable {
        address owner = 0xe3f7CAD5c871b1aF011b11776BbCc12B20FB2A73;
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
  }

}