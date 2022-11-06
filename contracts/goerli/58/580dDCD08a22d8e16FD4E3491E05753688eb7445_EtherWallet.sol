//SPDX-License-Identifier:MIT
pragma solidity^0.8.10;

contract EtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    // receive function is called if msg.data is empty 
    receive() external payable {}

    function withdraw(uint _amount) external {
        require(msg.sender == owner, "Caller is not the owner");
        require(_amount <= getBalance() && getBalance() > 0, "Insufficient balance");
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Failed to withdraw ether");
    }

    function deposit() external payable {
        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Failed to deposit ether");
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
}