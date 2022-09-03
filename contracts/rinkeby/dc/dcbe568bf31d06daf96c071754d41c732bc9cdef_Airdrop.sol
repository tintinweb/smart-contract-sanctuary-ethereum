/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Airdrop{
    IERC20 public mil;
    uint256 public tokens = 3571429*10**18;
    address public owner;

    modifier onlyOwner(){
        require(msg.sender == owner, "You're not the owner!");
        _;
    }

    constructor(IERC20 _mil){
        mil = _mil;
        owner = msg.sender;
    }

    function setTokensPerNFT(uint256 _tokens) external onlyOwner{
        tokens = _tokens;
    }

    function airdrop(address [] memory _addresses, uint256[] memory _amountOfTokens) external onlyOwner
    {
        require(_addresses.length == _amountOfTokens.length, "length not same!" );
        for(uint256 i=0; i<_addresses.length; i++ )
        {
            mil.transfer(_addresses[i],_amountOfTokens[i]*tokens);
        } 
    }
}