/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.8.10;

contract Bank {
    // uint8 number;
    // uint256 public prizePool;

    // event GuessReceive(address user,uint8 number,bool isCorrect);

    // address public owner;
    // constructor() {
    //     owner = msg.sender;
    // }

    //Declare title list
    string [] public money;

    //Declare accounts parameter
    mapping (address => uint256) private accounts;

    //Get balance
    function balance() public view returns(uint256) { 
        return accounts[msg.sender];
    }

    //Deposit function
    function deposit() public payable { 
        require(msg.value > 0, "Amount must than 0.");
        accounts[msg.sender] += msg.value;
    }

    //withdraw function
    function withdraw(uint256 money) public {
        require(money <= accounts[msg.sender], "balance more.");
        payable(msg.sender).transfer(money);
        accounts[msg.sender] -= money;
    }

}