/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.26;

interface IERC20Token {
    function balanceOf(address owner) public returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function decimals() public returns (uint256);
}

contract NestIDO {
    IERC20Token public tokenContract;  // the token being sold
    uint256 public price;              // the price, in wei, per token
    address owner;
    uint256 public minTokens;
    uint256 public maxTokens;
    uint256 public tokensSold;

    event Sold(address buyer, uint256 amount);

    function NestIDO(IERC20Token _tokenContract, uint256 _price) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
        price = _price;
    }

    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }

    function buyTokens(uint256 numberOfTokens) public payable {
        require(numberOfTokens <= maxTokens, "Maximum Tokens not reached. Please try with lower tokens");
        require(numberOfTokens >= minTokens, "Minimum Tokens not reached. Please try with higher tokens");
        require(msg.value == safeMultiply(numberOfTokens, price), "Not Matching");

        uint256 scaledAmount = safeMultiply(numberOfTokens,
            uint256(10) ** tokenContract.decimals());

        require(tokenContract.balanceOf(this) >= scaledAmount, "InSufficent Balance");

        emit Sold(msg.sender, numberOfTokens);
        tokensSold += numberOfTokens;

        require(tokenContract.transfer(msg.sender, scaledAmount),"Unable to tranfer");
    }

    function changeOwnership(address newOwner) public {
        require(msg.sender == owner);
        owner = newOwner;
    }

    function changeAddress(IERC20Token _tokenContract) public {
        require(msg.sender == owner);
        tokenContract = _tokenContract;
    }

    function setMinTokens(uint256 tokens) public {
        require(msg.sender == owner);
        minTokens = tokens;
    }

    function setPrice(uint256 _price) public {
        require(msg.sender == owner);
        price = _price;
    }

    function setMaxTokens(uint256 tokens) public {
        require(msg.sender == owner);
        maxTokens = tokens;
    }

    function tokenWithdraw() public {
        require(msg.sender == owner);
        require(tokenContract.transfer(owner, tokenContract.balanceOf(this)));
    }

    function balanceWithdraw() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }

    function endSale() public {
        require(msg.sender == owner);
        require(tokenContract.transfer(owner, tokenContract.balanceOf(this)));
        msg.sender.transfer(address(this).balance);
    }
}