/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

abstract contract Token{
    function balanceOf(address account) public virtual view returns (uint);
    function allowance(address account, address spender) external virtual view returns (uint);
    function transfer(address recipient, uint amount) external virtual returns (bool);
    function transferFrom (address sender, address recipient, uint amount) external virtual returns (bool);
}

contract ethPurse{
    address payable public owner;
    constructor() {
        owner = payable(msg.sender);
    }
    receive() external payable {}
    function TransferOwnership(address who) external{
        require(msg.sender == owner, "Must be the owner.");
        owner = payable(who);
    }
    function withdrawETH(uint _amount) external {
        require(msg.sender == owner, "Must be the owner.");
        payable(msg.sender).transfer(_amount);
    }
    function withdrawToken(uint _amount, address tokenContract) external {        
        require(msg.sender == owner, "Must be the owner.");
        require(_amount >= tokenBalance(address(this),tokenContract), "Not enough balance.");
        require(Token(tokenContract).transfer(owner, _amount), "Error on token transfer.");
    }
    function depositToken(uint _amount, address tokenContract) external{
        require(_amount >= tokenBalance(msg.sender,tokenContract), "Not enough balance.");
        require(_amount <= Token(tokenContract).allowance(msg.sender, address(this)), "Not enough allowance.");
        require(Token(tokenContract).transferFrom(msg.sender, address(this), _amount), "Error on transferFrom.");
    }
    function tokenBalance(address user, address token) public view returns(uint){
        uint256 tokenCode;
        assembly { tokenCode := extcodesize(token)}

        if (tokenCode > 0){
            return Token(token).balanceOf(user);
        } else {
            return 0;
        }
    }
    function balances(address[] memory tokens)  external view returns (uint[] memory)  {
        uint[] memory addrBalances = new uint[](tokens.length);
        
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] != address(0x0)) { 
            addrBalances[i] = tokenBalance(address(this), tokens[i]);
            } else {
            addrBalances[i] = address(this).balance; // ETH balance    
            }
        }        
    
        return addrBalances;
    }
}