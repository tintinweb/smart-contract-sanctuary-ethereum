/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

pragma solidity ^0.8.0;

contract Timelock {

    address public owner;

    mapping(address => uint) public balances;
    mapping(address => uint) public waiting_period;

    event NewDeposit(
        uint indexed blocktime,
        address indexed from,
        uint amount
    );

    event NewWithdraw(
        uint indexed blocktime,
        address indexed from,
        address indexed to,
        uint amount
    );

    constructor(){
        owner = msg.sender;
    }

    function deposit(uint64 _timelock) external payable {
        //deposit funds
        //record block time deposited

        require(_timelock > 0, "timelock amount must be greater than 0");

        require(balances[msg.sender] == 0, "User already has ETH deposited");

        balances[msg.sender] += msg.value;
        waiting_period[msg.sender] = block.timestamp + _timelock;
        emit NewDeposit(block.timestamp, msg.sender, msg.value);

    }

    function withdraw() external {
        require(balances[msg.sender] > 0, "This address has no associated Ether");
        require(block.timestamp >= waiting_period[msg.sender], "Funds are not ready to be withdrawn");

        uint transfer_amount = balances[msg.sender];
        balances[msg.sender] = 0;

        payable(msg.sender).transfer(transfer_amount);

        emit NewWithdraw(block.timestamp, address(this), msg.sender,transfer_amount);
    }

}