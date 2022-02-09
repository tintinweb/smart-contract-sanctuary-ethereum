/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

pragma solidity ^0.8.7;

//SPDX-License-Identifier: MIT

contract DistributeRoyalty {
    address public owner1;
    address public owner2;
    
    constructor (address _owner1, address _owner2) {
        owner1 = _owner1;
        owner2 = _owner2;
    }


    function Withdraw() public payable {
        require (msg.sender == owner1 || msg.sender == owner2);
        
        uint percentage1 = 75;
        uint percentage2 = 25;

        uint value1 = (address(this).balance)*percentage1/100;
        uint value2 = (address(this).balance)*percentage2/100;

        payable(owner1).transfer(value1);
        payable(owner2).transfer(value2);
    }
}