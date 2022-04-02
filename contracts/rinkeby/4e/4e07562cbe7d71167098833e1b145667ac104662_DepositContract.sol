/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

pragma solidity 0.5.0;

contract DepositContract {

    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    function deposit() public payable {
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
        emit Withdrawn(msg.sender, balance);
    }


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

}