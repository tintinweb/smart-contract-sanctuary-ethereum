// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/AppStorage.sol";

contract Bank{
    // @title A basic bank upgradable contract
    // @author Sayrarh

    AppStorage internal a;

    error ZeroEther(); //Zero ether not allowed

    error NoSufficientFunds(); //No sufficient fund

    /// @dev function that user trigger to deposit funds
    function deposit() external payable {
        if(msg.value == 0){
            revert ZeroEther();
        }else{
            a.balances[msg.sender] += msg.value;
        }
    }

    /// @dev function to withdraw ether from balance
    function withdraw(uint amount) external payable{
        if(amount > a.balances[msg.sender]){
            revert NoSufficientFunds();
        }else{
            a.balances[msg.sender] -= amount;
            payable(msg.sender).transfer(amount);
        }
    }

    /// @dev function to get user balance
    function getUserBal() public view returns(uint userBal){
        userBal = a.balances[msg.sender];
    }

    /// @dev function to get the contract balance
    function getContractBal() public view returns(uint256 bal){
        bal = address(this).balance;
    }

    /// @dev function to receive ether into the contract
    receive() external payable{}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct AppStorage{
     mapping(address => uint) balances;
}