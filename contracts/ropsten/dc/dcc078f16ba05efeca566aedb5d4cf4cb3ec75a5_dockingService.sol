/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

contract dockingService{

    struct bank{
        uint amount;
        uint totalTransactions;
    }

    mapping(address => bank) balances;

    function dock() public payable returns (bool success){
        balances[msg.sender].amount = msg.value;
        balances[msg.sender].totalTransactions = balances[msg.sender].totalTransactions + 1;
        return true;
    }

    function undock(uint amount) public returns (bool success){
        require(amount <= balances[msg.sender].amount);
        payable(msg.sender).transfer(amount);
        balances[msg.sender].amount = balances[msg.sender].amount - amount;
        balances[msg.sender].totalTransactions = balances[msg.sender].totalTransactions + 1;
        return true;
    }
}