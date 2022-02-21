// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./ERC_token.sol";

contract TokenDeal {
    address admin;
    ErcToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;
    address subcontract;
    uint256 public balance;

    event Sell(address _buyer, uint256 _amount);

    constructor(uint256 _initialSupply, uint256 _tokenPrice) payable {
        admin = msg.sender;
        tokenContract = new ErcToken(_initialSupply);
        subcontract = address(tokenContract);
        tokenPrice = _tokenPrice;
    }

    function multiply(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == multiply(_numberOfTokens, tokenPrice), "not enaught ether");
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens, "some wronge with balance");
        require(tokenContract.transfer(msg.sender, _numberOfTokens), "transfer failed");

        tokensSold += _numberOfTokens;

        emit Sell(msg.sender, _numberOfTokens);
    }

    function buyerBalance() public payable{
        balance = tokenContract.balanceOf(msg.sender);
    }

    function endSale() public {
        require(msg.sender == admin);
        require(tokenContract.transfer(admin, tokenContract.balanceOf(address(this))));

        // UPDATE: Let's not destroy the contract here
        // Just transfer the balance to the admin
        payable(admin).transfer(address(this).balance);
    }
}