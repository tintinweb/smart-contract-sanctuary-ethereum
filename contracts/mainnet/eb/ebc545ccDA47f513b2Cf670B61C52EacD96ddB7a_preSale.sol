/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        if(_getDeposit(amount) == true) {
            uint256 tokens = amount / init;
            
            IERC20 token = IERC20(tokenContract);
            token.transfer(msg.sender, tokens * 10**18);

            emit Buy(msg.sender, amount, tokens, block.timestamp);
        }
    }

    function _getDeposit(uint256 _amount) private returns (bool) {
        IERC20 usdt = IERC20(usdtContract);
        return usdt.transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawUsdt() onlyOwner external {
        IERC20 token = IERC20(usdtContract);
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