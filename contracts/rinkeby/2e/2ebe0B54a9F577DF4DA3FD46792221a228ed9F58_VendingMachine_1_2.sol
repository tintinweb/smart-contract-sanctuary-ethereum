/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

pragma solidity >  0.8.7;



contract VendingMachine_1_2 {



    // Declare state variables of the contract

    address public owner;

    mapping (address => uint) public cupcakeBalances;



    // When 'VendingMachine' contract is deployed:

    // 1. set the deploying address as the owner of the contract

    // 2. set the deployed smart contract's cupcake balance to 100

    constructor() {

        owner = msg.sender;

        cupcakeBalances[address(this)] = 100;

    }



    // Allow the owner to increase the smart contract's cupcake balance

    function refill(uint amount) public {

        require(msg.sender == owner, "Only the owner can refill.");

        cupcakeBalances[address(this)] += amount;

    }



    // allow the owner to disburse smart contract's balance

    function disburseAll() public {

        require(msg.sender == owner, "Only the owner can disburse.");

        payable(owner).transfer(address(this).balance);

    }



    // allow the owner to disburse smart contract's balance

    function disburseAmount(uint amount) public {

        require(msg.sender == owner, "Only the owner can disburse.");

        require(address(this).balance >= amount, "Amount must be lower then balance");

        payable(owner).transfer(amount);

    }



    // Allow anyone to purchase cupcakes

    function purchase(uint amount) public payable {

        require(msg.value >= amount * 0.0001 ether, "You must pay at least 0.0001 ether per cupcake");

        require(cupcakeBalances[address(this)] >= amount, "Not enough cupcakes in stock to complete this purchase");

        cupcakeBalances[address(this)] -= amount;

        cupcakeBalances[msg.sender] += amount;

    }

}