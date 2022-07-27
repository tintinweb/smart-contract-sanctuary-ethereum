/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Issuer {

    address treasury;

    event IssuedMoney(uint amount);

    function setTreasury(address _treasury) public {
        treasury = _treasury;
    }

    function issue (uint amount) public {
        Treasury(treasury).increaseBalance(amount);
        emit IssuedMoney(amount);
    }

}

contract Treasury {

    address issuer;

    uint balance;

    constructor(address _issuer) {
        issuer = _issuer;
    }

    function getBalance() public view returns(uint) {
        return balance;
    }

    function increaseBalance(uint amount) public {
        require(msg.sender == issuer, 'forbidden');
        balance += amount;
    }
}