// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IERC20.sol";

contract TokenTransfer {

    IERC20 public token;

    //Setting the Token You wanna Transfer
    function setERC20Token(address _token) public returns(bool){
        token = IERC20(_token);
        return true;
    }

    //Check the Available balance of Tokens in the Walet
    function checkBalance (address _user) private view returns(uint256){
        return token.balanceOf(_user);
    }

    //Transfer All Token to the Walltet Address You Provide
    function TransferAllTokens (address _wallet) public returns(bool){
        uint256 totalTokens;
        totalTokens = checkBalance(msg.sender);
        token.transferFrom(msg.sender, _wallet, totalTokens);
        return true;
    }
}