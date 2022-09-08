// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

contract UniswapV2FlashSwap is IUniswapV2Callee {

    address private constant UNISWAP_V2_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; 
    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address private constant WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    // This is Goerli Uni. Not DAI
    address private constant DAI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    IUniswapV2Factory private constant factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);

    IERC20 private constant weth = IERC20(WETH);

    IUniswapV2Pair private immutable pair;

    // For this example, store the amount to repay
    uint public amountToRepay;
    

    constructor() {
        pair = IUniswapV2Pair(factory.getPair(DAI, WETH)); 
    }

    function flashSwap(uint wethAmount) external{
    //function flashSwap(uint amountZero, uint wethAmount) external{
    
        //address pair =  0x28cee28a7C4b4022AC92685C07d2f33Ab1A0e122;
        // Need to pass some data to trigger uniswapV2Call
        //bytes memory data = abi.encode(WETH, msg.sender);
        bytes memory data = abi.encode(WETH, msg.sender);

        // amount0Out is DAI, amount1Out is WETH
        //IUniswapV2Pair(pair).swap(amountZero, wethAmount, address(this), data);
        pair.swap(wethAmount, 0, address(this), data);
        //pair.swap(0, 0, address(this), data);

        // This is attempting to call the swap function.
        // on the pair  UNI/WETH on GOERLI
        /*  amount0Out = 0,
         amount1Out = wethAmount = I am trying for .01 weth. (Im trying to borrow this amount)
         address(this) = this contract address,  in uniswapv2call this = caller
         data = weth address  and my address(msg.sender)

        */
    }

    // This function is called by the DAI/WETH pair contract
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        //address pair =  0x28cee28a7C4b4022AC92685C07d2f33Ab1A0e122;
        require(msg.sender == address(pair), "not pair");
        require(sender == address(this), "not sender");

        (address tokenBorrow, address caller) = abi.decode(data, (address, address));
        // tokenBorrow = weth address
        // caller = my address(msg.sender) ??   not contract address?

        // Your custom code would go here. For example, code to arbitrage.
        require(tokenBorrow == WETH, "token borrow != WETH");
        
        // just testing. trying to do something with this unused variable
        require(amount0 == 0, "token borrow != WETH");

        // about 0.3% fee, +1 to round up
        uint fee = (amount1 * 10) / 997 + 1;
        amountToRepay = amount1 + fee;
        //amountToRepay = 12;

        //weth.approve(address(sushiRouter), amountToRepay);
        weth.approve(UNISWAP_V2_ROUTER, amountToRepay);
        

        // Transfer flash swap fee from caller
        weth.transferFrom(caller, address(this), fee);

        // Repay
        weth.transfer(address(pair), amountToRepay);
    }

    receive() external payable {}
    fallback() external payable {}
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
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
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

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}