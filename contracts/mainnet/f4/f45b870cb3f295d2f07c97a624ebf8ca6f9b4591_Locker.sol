/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface TokenContractIN {
    function transfer(address to, uint256 amount) external returns(bool);
    function balanceOf(address user) external view returns(uint256);
}

contract Locker { 
    

    uint public unlockDate;
    address public lockedWallet = 0x6a212CcD2452Bb08824AE3b33eb628dE92371188;
    

    constructor (){
        unlockDate = block.timestamp + 23328000; //(30*9*86400)
    }

    event withdraw(address _to, uint _amount);

    function withdrawTokens(address tokenAddress) public {
             require(block.timestamp >= unlockDate, "tokens locked");
             require(msg.sender == lockedWallet, "Invalid caller");

             uint256 amount = TokenContractIN(tokenAddress).balanceOf(address(this));

             TokenContractIN(tokenAddress).transfer(msg.sender, amount);
             emit withdraw(msg.sender,amount);
           
    }

    
}