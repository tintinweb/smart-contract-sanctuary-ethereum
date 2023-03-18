// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

pragma experimental ABIEncoderV2;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract Bot {
    address private immutable owner;
    //mainnet
    // IWETH private constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    //goerli
    IWETH private constant WETH = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }


    // ======== OWNER FUNCTIONS ========
    function checkAndSend(uint256 expectAmount) external payable onlyOwner {
        require(expectAmount > 0, "expectAmount must be greater than 0");
        // 获取sender的weth余额
        uint256 _wethBalance = WETH.balanceOf(msg.sender);
        // 如果余额小于expectAmount 回滚交易
        require(_wethBalance >= expectAmount, "weth balance is not enough");
        // 如果余额大于等于expectAmount，将value通过coinbase.transfer转给矿工
        block.coinbase.transfer(msg.value);
    }
}