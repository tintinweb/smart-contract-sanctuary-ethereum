/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

pragma solidity >=0.7.0 <0.9.0;

contract SendingEtherContract {
    mapping(address => uint256) balances;

    // Deposit into contract address from your account address
    // Declared payable to enable Ether transactions
    function deposit() public payable {}

    // Check current contract address balance
    function checkContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawFromContract(uint256 amountToWithdraw) public {
        // Contract -> Account

        // Add error handling, make sure the amount that you withdraw < contract balance
        // You should an error if happens
        require(address(this).balance > amountToWithdraw, "Insufficient Ether");

        // Alternative error hanlding for require
        // if (address(this).balance < amountToWithdraw) {
        //     revert("Insuficient Ether");
        // }

        // Withdraw your contract balances back to your account
        payable(msg.sender).transfer(amountToWithdraw);
    }

    function sendToOtherAccount(address payable receiver) public payable{
        // Transfer you current account Ether to the receiver
        receiver.transfer(msg.value);
    }
}