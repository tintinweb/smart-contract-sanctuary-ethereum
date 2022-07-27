/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.7;

contract tomfirstcontract {
    
    address payable owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function givetommoney() public payable {
        require(msg.value > 0);
    }

    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }
}