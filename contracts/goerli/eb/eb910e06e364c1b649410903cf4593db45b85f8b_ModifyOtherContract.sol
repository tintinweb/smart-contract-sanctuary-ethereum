pragma solidity ^0.8.17;
  
contract ModifyOtherContract {

    address destination;
    uint256 balance;

    receive() external payable {
        balance += msg.value;
    }

    function sendFunds() public {
        require(destination != address(0), "Set address of the other contract first");
        (bool sent, ) = payable(destination).call{value: balance}("");
        require(sent, "Failed to transfer the balance");
        balance = 0;    
    }

    function getDestination() public view returns (address) {
        return destination;
    }

    function setDestination(address _destination) public {
        destination = _destination;
    }

    function getBalance() public view returns (uint256) {
        return balance;
    }
}