/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.6.0;

interface IERC20Token {
     function balanceOf(address owner) external returns (uint256);
     function transfer(address to, uint256 amount) external returns (bool);
}

contract CocksERC20Sale {
    IERC20Token public tokenContract;          // the token being sold
    uint256 public tokensPerMatic;  // the exchange rate
    address owner;

    uint256 public tokensSold;

    event Sold(address buyer, uint256 amount);

    constructor(IERC20Token _tokenContract, uint256 _tokensPerMatic) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokensPerMatic = _tokensPerMatic;
    }

    // Guards against integer overflows
    function safeMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }
    }

    function buyTokens() public payable {
        uint256 numberOfTokens = safeMultiply(msg.value, tokensPerMatic);

        require(tokenContract.balanceOf(address(this)) >= numberOfTokens);

        emit Sold(msg.sender, numberOfTokens);
        tokensSold += numberOfTokens;

        require(tokenContract.transfer(msg.sender, numberOfTokens));
    }

    function withdrawMatic() public {
        require(msg.sender == owner);

        payable(msg.sender).transfer(address(this).balance);
    }
}