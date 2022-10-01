/**
 *Submitted for verification at Etherscan.io on 2022-10-01
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
    address public token;
    address public usdt;
    uint256 public initEth;
    uint256 public initUsd;
    bool public pause;
    uint8 public decimals;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notPaused {
        require(pause == false);
        _;
    }

    event Buy(address indexed user, uint256 payed, uint256 tokens, uint256 timestamp);

    constructor(uint256 _min, uint256 _initEth, uint256 _initUsd, address _token, address _usdt, uint8 _decimals) {
        owner = msg.sender;
        min = _min;
        initEth = _initEth;
        initUsd = _initUsd;
        token = _token;
        usdt = _usdt;
        pause = false;
        decimals = _decimals;
    }

    function buy() notPaused public payable {
        uint256 amount = msg.value / initEth;
        
        require(amount >= min);

        IERC20 itoken = IERC20(token);
        itoken.transfer(msg.sender, amount * 10**decimals);

        emit Buy(msg.sender, msg.value, amount, block.timestamp);
    }
    
    function buyUsd(uint256 amount) notPaused public {
        uint256 tokens = amount / initUsd;

        require(tokens >= min);

        IUSDT iusdt = IUSDT(usdt);
        iusdt.transferFrom(msg.sender, address(this), amount);
        
        IERC20 itoken = IERC20(token);
        itoken.transfer(msg.sender, tokens * 10**decimals);

        emit Buy(msg.sender, amount, tokens, block.timestamp);
    }

    function withdrawEthers() onlyOwner external {
        address payable owner_temp = payable(owner);
        address this_contract = address(this);
        owner_temp.transfer(this_contract.balance);
    }

    function withdrawUsd() onlyOwner external {
        IUSDT iusdt = IUSDT(usdt);
        iusdt.transfer(owner, iusdt.balanceOf(address(this)));
    }

    function withdrawTokens() onlyOwner external {
        IERC20 itoken = IERC20(token);
        itoken.transfer(owner, itoken.balanceOf(address(this)));
    }

    function changeParams(uint256 _min, uint256 _initEth, uint256 _initUsd, address _token, address _usdt, uint8 _decimals) onlyOwner external {
        min = _min;
        initEth = _initEth;
        initUsd = _initUsd;
        token = _token;
        usdt = _usdt;
        decimals = _decimals;
    }

    function transferOwnership(address _owner) onlyOwner external {
        owner = _owner;
    }

    function setPause(bool _pause) onlyOwner external {
        pause = _pause;
    }
}