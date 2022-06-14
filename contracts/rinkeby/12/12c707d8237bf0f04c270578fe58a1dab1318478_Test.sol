/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;
 

contract Test  {
 
    uint public num = 0;
    address public addressGas;
    //0.001
    uint256 public numGas = 1E15;
    modifier payGas()  {
        //require(_owner == _msgSender(), "Ow1");
        require(addressGas != address(0));
        require(msg.value >= numGas);
        _;
       payable(addressGas).transfer(numGas);
    }

    constructor()   { 
        addressGas = msg.sender;
    }
    function test() public payable payGas{
        num = num +1;
    }
 
}