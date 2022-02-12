//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Donation {
    
    address constant owner = 0x3194cBDC3dbcd3E11a07892e7bA5c3394048Cc87;

    mapping (address => uint) valueToUser;
    address[] public users;

    modifier ability_to_pay() {
        require(msg.sender.balance >= msg.value, "Not Fund Enough");
        _;
    }

    function donate(uint _value) payable public ability_to_pay {   
        payable(owner).transfer(_value);
        if (valueToUser[msg.sender] == 0){users.push(msg.sender);}
        valueToUser[msg.sender] += _value;  
    }

    function output(address payable _target, uint _value) payable external ability_to_pay {
        _target.transfer(_value);
    }

    function getDonateByUser(address _donater) public view returns(uint) {
        return valueToUser[_donater];
    }

    function getUsers() public view returns(address[] memory) {
        return users;
    }
}