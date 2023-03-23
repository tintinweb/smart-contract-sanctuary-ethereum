// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

contract UniswapV2FlashSwap is IUniswapV2Callee {
    address private constant UNISWAP_V2_FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant TKB = 0x6a5749baBad7833e2e1AABCb6425292873Bbc885;
    address private constant TKA = 0xDD4EA9227Dc4b95BC83718568b8Ae179D104547f;

    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    IERC20 private constant tka = IERC20(TKA);

    IUniswapV2Pair private immutable pair;

    // For this example, store the amount to repay
    uint public amountToRepay;

    constructor() {
        pair = IUniswapV2Pair(factory.getPair(TKB, TKA));
    }

    function flashSwap(uint tkaAmount) external {
        // Need to pass some data to trigger uniswapV2Call
        bytes memory data = abi.encode(TKA, msg.sender);

        // amount0Out is TKB, amount1Out is TKA
        pair.swap(0, tkaAmount, address(this), data);
    }

    // This function is called by the TKB/TKA pair contract
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        require(msg.sender == address(pair), "not pair");
        require(sender == address(this), "not sender");

        (address tokenBorrow, address caller) = abi.decode(data, (address, address));

        // Your custom code would go here. For example, code to arbitrage.
        require(tokenBorrow == TKA, "token borrow != TKA");

        // about 0.3% fee, +1 to round up
        uint fee = (amount1 * 3) / 997 + 1;
        amountToRepay = amount1 + fee;

        // Transfer flash swap fee from caller
        tka.transferFrom(caller, address(this), fee);

        // Repay
        tka.transfer(address(pair), amountToRepay);
    }
}

interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface Itka is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}