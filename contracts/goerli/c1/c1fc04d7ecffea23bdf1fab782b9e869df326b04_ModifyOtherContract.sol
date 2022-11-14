pragma solidity ^0.8.17;

contract ModifyOtherContract {

    address public destination;
    uint256 balance;

    receive() external payable {
        balance += msg.value;
    }

    function sendFunds() public payable {
        require(destination != address(0), "Set address of the other contract first");
        (bool sent, ) = payable(destination).call{value: balance}("");
        require(sent, "Failed to transfer the balance");
    }

    function getBalance() public view returns (uint256) {
        return balance;
    }
}