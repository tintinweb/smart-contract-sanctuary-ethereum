/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.15;

/*

 /$$   /$$ /$$$$$$$$       /$$$$$$$$ /$$
| $$  / $$|_____ $$/      | $$_____/|__/
|  $$/ $$/     /$$/       | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$
 \  $$$$/     /$$/        | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
  >$$  $$    /$$/         | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
 /$$/\  $$  /$$/          | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
| $$  \ $$ /$$/           | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
|__/  |__/|__/            |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

Contract: Uniswapv2 Fork - XchangeRouterWithDiscounts

This router implements all the familiar Uniswap V2 router swapping functions but checks the discount authority and applies the discount to the swap.
If you will not receive a discount, you can just use the XchangeRouter.

This contract will be trusted by the factory to send accurate discounts to liquidity pairs while swapping.

This contract will NOT be renounced, however it has no functions which affect the contract. The contract is "owned" solely as a formality.

*/

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IXchangeFactory {
    function discountAuthority() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IXchangePair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swapWithDiscount(uint amount0Out, uint amount1Out, address to, uint feeAmountOverride, bytes calldata data) external;
}

interface IXchangeRouterWithDiscounts {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function swapExactTokensForTokensWithDiscount(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokensWithDiscount(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokensWithDiscount(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETHWithDiscount(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETHWithDiscount(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokensWithDiscount(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function getAmountOutWithDiscount(uint amountIn, uint reserveIn, uint reserveOut, uint feeAmount) external pure returns (uint amountOut);

    function getAmountInWithDiscount(uint amountOut, uint reserveIn, uint reserveOut, uint feeAmount) external pure returns (uint amountIn);

    function getAmountsOutWithDiscount(uint amountIn, uint feeAmount, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsInWithDiscount(uint amountOut, uint feeAmount, address[] calldata path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokensWithDiscount(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokensWithDiscount(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokensWithDiscount(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

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

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

interface IXchangeDiscountAuthority {
    function fee(address) external view returns (uint256);
}

contract XchangeRouterWithDiscounts is IXchangeRouterWithDiscounts, Ownable {
    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'Xchange: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) Ownable(msg.sender) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        require(msg.sender == WETH);
        // only accept ETH via fallback from the WETH contract
    }

    function getAmountsOutWithDiscount(uint amountIn, uint feeAmount, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return XchangeLibrary.getAmountsOut(factory, amountIn, feeAmount, path);
    }

    function getAmountsInWithDiscount(uint amountOut, uint feeAmount, address[] memory path)
    public
    view
    virtual
    override
    returns (uint[] memory amounts)
    {
        return XchangeLibrary.getAmountsIn(factory, amountOut, feeAmount, path);
    }

    function swapExactTokensForTokensWithDiscount(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        uint feeAmount = IXchangeDiscountAuthority(IXchangeFactory(factory).discountAuthority()).fee(msg.sender);
        amounts = XchangeLibrary.getAmountsOut(factory, amountIn, feeAmount, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'Xchange: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, XchangeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swapWithDiscount(amounts, path, to, feeAmount);
    }

    function swapTokensForExactTokensWithDiscount(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        uint feeAmount = IXchangeDiscountAuthority(IXchangeFactory(factory).discountAuthority()).fee(msg.sender);
        amounts = XchangeLibrary.getAmountsIn(factory, amountOut, feeAmount, path);
        require(amounts[0] <= amountInMax, 'Xchange: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, XchangeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swapWithDiscount(amounts, path, to, feeAmount);
    }

    function swapExactETHForTokensWithDiscount(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'Xchange: INVALID_PATH');

        uint feeAmount = IXchangeDiscountAuthority(IXchangeFactory(factory).discountAuthority()).fee(msg.sender);
        amounts = XchangeLibrary.getAmountsOut(factory, msg.value, feeAmount, path);

        require(amounts[amounts.length - 1] >= amountOutMin, 'Xchange: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value : amounts[0]}();
        assert(IWETH(WETH).transfer(XchangeLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swapWithDiscount(amounts, path, to, feeAmount);
    }

    function swapTokensForExactETHWithDiscount(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'Xchange: INVALID_PATH');

        uint feeAmount = IXchangeDiscountAuthority(IXchangeFactory(factory).discountAuthority()).fee(msg.sender);
        amounts = XchangeLibrary.getAmountsIn(factory, amountOut, feeAmount, path);
        require(amounts[0] <= amountInMax, 'Xchange: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, XchangeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swapWithDiscount(amounts, path, address(this), feeAmount);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapExactTokensForETHWithDiscount(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'Xchange: INVALID_PATH');
        uint feeAmount = IXchangeDiscountAuthority(IXchangeFactory(factory).discountAuthority()).fee(msg.sender);
        amounts = XchangeLibrary.getAmountsOut(factory, amountIn, feeAmount, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'Xchange: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, XchangeLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swapWithDiscount(amounts, path, address(this), feeAmount);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function swapETHForExactTokensWithDiscount(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    virtual
    override
    payable
    ensure(deadline)
    returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'Xchange: INVALID_PATH');
        uint feeAmount = IXchangeDiscountAuthority(IXchangeFactory(factory).discountAuthority()).fee(msg.sender);
        amounts = XchangeLibrary.getAmountsIn(factory, amountOut, feeAmount, path);
        require(amounts[0] <= msg.value, 'Xchange: EXCESSIVE_INPUT_AMOUNT');
        IWETH(WETH).deposit{value : amounts[0]}();
        assert(IWETH(WETH).transfer(XchangeLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swapWithDiscount(amounts, path, to, feeAmount);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokensWithDiscount(address[] memory path, address _to, uint feeAmount) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = XchangeLibrary.sortTokens(input, output);
            IXchangePair pair = IXchangePair(XchangeLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            {// scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
                amountOutput = XchangeLibrary.getAmountOut(amountInput, reserveInput, reserveOutput, feeAmount);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? XchangeLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swapWithDiscount(amount0Out, amount1Out, to, feeAmount, new bytes(0));
        }
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokensWithDiscount(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, XchangeLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        uint feeAmount = IXchangeDiscountAuthority(IXchangeFactory(factory).discountAuthority()).fee(msg.sender);
        _swapSupportingFeeOnTransferTokensWithDiscount(path, to, feeAmount);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'Xchange: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokensWithDiscount(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    payable
    ensure(deadline)
    {
        require(path[0] == WETH, 'Xchange: INVALID_PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value : amountIn}();
        assert(IWETH(WETH).transfer(XchangeLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        uint feeAmount = IXchangeDiscountAuthority(IXchangeFactory(factory).discountAuthority()).fee(msg.sender);
        _swapSupportingFeeOnTransferTokensWithDiscount(path, to, feeAmount);
        require(
            IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
            'Xchange: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokensWithDiscount(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
    external
    virtual
    override
    ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'Xchange: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, XchangeLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint feeAmount = IXchangeDiscountAuthority(IXchangeFactory(factory).discountAuthority()).fee(msg.sender);
        _swapSupportingFeeOnTransferTokensWithDiscount(path, address(this), feeAmount);
        uint amountOut = IERC20(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'Xchange: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    function getAmountOutWithDiscount(uint amountIn, uint reserveIn, uint reserveOut, uint feeAmount)
    public
    pure
    virtual
    override
    returns (uint amountOut)
    {
        return XchangeLibrary.getAmountOut(amountIn, reserveIn, reserveOut, feeAmount);
    }

    function getAmountInWithDiscount(uint amountOut, uint reserveIn, uint reserveOut, uint feeAmount)
    public
    pure
    virtual
    override
    returns (uint amountIn)
    {
        return XchangeLibrary.getAmountIn(amountOut, reserveIn, reserveOut, feeAmount);
    }

    function _swapWithDiscount(uint[] memory amounts, address[] memory path, address _to, uint256 feeAmount) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = XchangeLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? XchangeLibrary.pairFor(factory, output, path[i + 2]) : _to;
            IXchangePair(XchangeLibrary.pairFor(factory, input, output)).swapWithDiscount(
                amount0Out, amount1Out, to, feeAmount, new bytes(0)
            );
        }
    }
}

library XchangeLibrary {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'XchangeLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'XchangeLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'579e9bdec156a1150f17cf9884a4421f309e7e9be6b26dcfbd9a52883418ee21' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IXchangePair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'XchangeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'XchangeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint feeAmount) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'XchangeLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'XchangeLibrary: INSUFFICIENT_LIQUIDITY');
        require(feeAmount <= 200, 'XchangeLibrary: EXCESSIVE_FEE');
        uint amountInWithFee = amountIn * (100000 - feeAmount);
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 100000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint feeAmount) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'XchangeLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'XchangeLibrary: INSUFFICIENT_LIQUIDITY');
        require(feeAmount <= 200, 'XchangeLibrary: EXCESSIVE_FEE');
        uint numerator = reserveIn * (100000 - feeAmount);
        uint denominator = (reserveOut - amountOut) * (100000 - feeAmount);
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, uint feeAmount, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'XchangeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, feeAmount);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, uint feeAmount, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'XchangeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, feeAmount);
        }
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}