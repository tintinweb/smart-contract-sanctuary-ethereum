/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

pragma solidity ^0.8.13;

/// @title Abstract token contract - Functions to be implemented by token contracts
abstract contract Token {
    /*
     *  Events
     */
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    /*
     *  Public functions
     */
    function transfer(address to, uint value) public virtual returns (bool);
    function transferFrom(address from, address to, uint value) public virtual returns (bool);
    function approve(address spender, uint value) public virtual returns (bool);
    function balanceOf(address owner) public virtual view returns (uint);
    function allowance(address owner, address spender) public virtual view returns (uint);
    function totalSupply() public virtual view returns (uint);
}


contract TokenSplitter {
    function splitTokens(address[] memory _recipients, address _tokenAddress, uint _amountForEach) public {
        Token erc20Token = Token(_tokenAddress);
        for (uint i = 0; i < _recipients.length; i++) {
            erc20Token.transferFrom(msg.sender, _recipients[i], _amountForEach);
        }
    }
}