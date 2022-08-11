/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

interface IUSDT {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}


contract preSale {
    address public owner;
    uint256 public min;
    address public tokenContract;
    address public usdtContract;
    uint256 public init;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event Buy(address indexed user, uint256 usdt, uint256 tokens, uint256 timestamp);

    constructor(uint256 _min, uint256 _init, address _tokenContract, address _usdtContract) {
        owner = msg.sender;
        min = _min;
        init = _init;
        tokenContract = _tokenContract;
        usdtContract = _usdtContract;
    }
    
    function buy(uint256 amount) public {
        require(amount >= min);

        IUSDT usdt = IUSDT(usdtContract);
        usdt.transferFrom(msg.sender, address(this), amount);

        uint256 tokens = amount / init;
        
        IERC20 token = IERC20(tokenContract);
        token.transfer(msg.sender, tokens * 10**18);

        emit Buy(msg.sender, amount, tokens, block.timestamp);
    }

    function withdrawUsdt() onlyOwner external {
        IUSDT token = IUSDT(usdtContract);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function withdrawTokens() onlyOwner external {
        IERC20 token = IERC20(tokenContract);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function changeParams(uint256 _min, uint256 _init, address _tokenContract, address _usdtContract) onlyOwner external {
        min = _min;
        init = _init;
        tokenContract = _tokenContract;
        usdtContract = _usdtContract;
    }

    function transferOwnership(address _owner) onlyOwner external {
        owner = _owner;
    }
}