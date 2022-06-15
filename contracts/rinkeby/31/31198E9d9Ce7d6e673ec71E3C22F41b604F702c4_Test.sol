//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Test {
    address payable owner;

    constructor(address payable _address) {
        owner = _address;
    }  

    function donate () payable public {
       require(msg.value > 0);
    }

    function withdraw(uint _amount) public {
        _amount = _amount*1000000000000000;
        require(msg.sender == owner);
        require(_amount <= address(this).balance);
        owner.transfer(_amount);
    }

    function confirm() public view returns(uint){
        return address(this).balance;
    }

}