/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.6.0;

contract DepositsV2 {

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);
    
    mapping(address => uint256) private _deposits;

    function deposit() public payable {
        uint256 amount = msg.value;
        address payee = msg.sender;
        _deposits[payee] = _deposits[payee] + amount; // should use SafeMath .add() here

        emit Deposited(payee, amount);
    }

    function withdraw() public {
        address payable payee = msg.sender;
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.transfer(payment);

        emit Withdrawn(payee, payment);
    }


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }
}