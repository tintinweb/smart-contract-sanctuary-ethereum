/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract Distribute  {
    address payable public devAddress;
    uint public totalweight;
    //event TransferReceived(address _from, uint _amount);
    //event TransferSent(address _from, address _destAddr, uint _amount);
    
    constructor(address payable _devAddress) {
        devAddress = _devAddress;
        totalweight = 125;
    }
    
    function distribute(address payable[] memory _to, uint[] memory weights) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        require(_to.length == weights.length,"Arrays are not of equal length");
        uint sum_ = 0;
        uint i;
        for (i = 0; i < weights.length; i++) {
            sum_ += weights[i];
        }
        require(sum_==100,"Weights must total to 100");
        uint value = msg.value / totalweight;
        devAddress.transfer(value * (totalweight-100));
        for(i=0; i < weights.length; i++) {
            address payable addr = _to[i];
            addr.transfer(value*weights[i]);
        }
    }

    function updateDevAddress(address payable _devAddress) public {
        require(msg.sender==devAddress,"Only dev can call this");
        devAddress = _devAddress;
        }
    
    function updateDevAllocation(uint alloc) public {
        require(msg.sender==devAddress,"Only dev can call this");
        totalweight = alloc;
    }
    

}