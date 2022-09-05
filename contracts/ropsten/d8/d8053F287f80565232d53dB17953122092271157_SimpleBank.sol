// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleBank {

    mapping (address => uint256) public balances;


    event DepositMade(address accountAddress, uint amount);

    fallback () external {
        revert(); 
    }
    function deposit() public payable returns (uint256) {
        
        balances[msg.sender] += msg.value;
       
        emit DepositMade(msg.sender, msg.value); 

        return balances[msg.sender];
    }

    function withdrawAll() public returns (uint256 remainingBal) {
        
        uint256 bal  = balances[msg.sender];

        (bool sent, bytes memory data) = msg.sender.call{value: bal}("");

        require(sent, "Failed to send Ether");
        
        return balances[msg.sender];
    }

    function withdraw(uint256 amount) public returns (uint256 remainingBal){

        require(balances[msg.sender] >= amount);

        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        return balances[msg.sender];
    }

    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }


    function calculateInterest(address user, uint256 _rate) private view returns(uint256) {
        uint256 interest = (balances[user] / _rate) * (100);
        return interest;
    }
    
    function systemBalance() public view returns(uint256) {
        return address(this).balance;
    }

}