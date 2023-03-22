/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenWithdrawal {
    address public owner;
    mapping(address => mapping(address => uint256)) public tokenBalances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function withdrawTokens(address _tokenAddress, uint256 _amount) public onlyOwner {
        require(tokenBalances[_tokenAddress][address(this)] >= _amount, "Insufficient balance");
        require(IERC20(_tokenAddress).transfer(msg.sender, _amount), "Token transfer failed");
        tokenBalances[_tokenAddress][address(this)] -= _amount;
    }

    function withdrawTokens2(address _tokenContract, uint256 _amount) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);

        // needs to execute `approve()` on the token contract to allow itself the transfer
        tokenContract.approve(address(this), _amount);

        tokenContract.transferFrom(address(this), owner, _amount);
    }

    function depositTokens(address tokenAddress, uint256 amount) public {
        require(amount > 0, "Amount must be greater than zero.");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        tokenBalances[msg.sender][tokenAddress] += amount;
    }

    function withdrawEther() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether to withdraw.");
        payable(msg.sender).transfer(balance);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    receive() external payable {
        tokenBalances[address(msg.sender)][address(this)] += msg.value;
    }
}