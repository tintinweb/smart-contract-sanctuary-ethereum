/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/*

 x7liquidityhub.sol

*/

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner_) {
        _transferOwnership(owner_);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface ILiquidityHub {
    function processFees(address) external;
}

interface IX7Token is IERC20 {
    function setAMM(address, bool) external;
    function setOffRampPair(address) external;
    function startTrading() external;
}

contract X7LiquidityHub is Ownable, ILiquidityHub {

    IUniswapV2Router02 public immutable router;
    address public immutable x7m105;
    address public immutable devWallet = address(0x7000a09c425ABf5173FF458dF1370C25d1C58105);
    bool public launched = false;

    bool public X7001PairsCreated = false;
    bool public X7002PairsCreated = false;
    bool public X7003PairsCreated = false;
    bool public X7004PairsCreated = false;

    uint256 public devPercent = 20;
    uint256 public liquidityPercent = 40;
    uint256 public x7m105liquidityPercent = 40;

    uint256 public initialTokensPerPair = 20000000 * 10**18;

    IERC20 public leastLiquidToken;
    uint256 public leastLiquidTokenWETHBalance = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    mapping(address => address) public nativeTokenPairs;

    mapping(address => mapping(address => address)) public swapPairs;

    constructor(address routerAddress, address x7m105_) Ownable(address(0x7000a09c425ABf5173FF458dF1370C25d1C58105)) {
        router = IUniswapV2Router02(routerAddress);
        x7m105 = x7m105_;
    }

    event FeesProcessed(
        address indexed liquidationToken,
        address indexed liquidityTarget,
        uint256 liquidationAmount,
        uint256 liquidityETH,
        uint256 devFee,
        uint256 x7m105LiquidityETH
    );

    receive() external payable {}

    function processFees(address tokenAddress) external {
        IERC20 token = IERC20(tokenAddress);
        swapTokensForEth(tokenAddress, token.balanceOf(address(this)));
        uint256 proceeds = address(this).balance;
        uint256 pairETHBalance = IERC20(router.WETH()).balanceOf(nativeTokenPairs[tokenAddress]);
        if (pairETHBalance <= leastLiquidTokenWETHBalance) {
            leastLiquidToken = IERC20(tokenAddress);
        }

        uint256 devProceeds = proceeds * devPercent / 100;
        (bool success, ) = address(devWallet).call{value: devProceeds}("");

        uint256 x7m105liquidityProceeds = proceeds * x7m105liquidityPercent / 100;
        swapEthForTokens(x7m105, x7m105liquidityProceeds/2);
        addLiquidityETH(x7m105, IERC20(x7m105).balanceOf(address(this)), x7m105liquidityProceeds / 2);

        uint256 liquidityProceeds = address(this).balance;
        swapEthForTokens(address(leastLiquidToken), liquidityProceeds/2);
        uint256 liquidityTokens = leastLiquidToken.balanceOf(address(this));
        addLiquidityETH(address(leastLiquidToken), liquidityTokens, address(this).balance);
        leastLiquidTokenWETHBalance = IERC20(router.WETH()).balanceOf(nativeTokenPairs[address(leastLiquidToken)]);
        emit FeesProcessed(tokenAddress, address(leastLiquidToken), proceeds, liquidityProceeds, devProceeds, x7m105liquidityProceeds);
    }

    function initiateLaunch() external payable onlyOwner {
        require(!launched, "Can only initiate launch once");
        launched = true;

        uint256 ethToAdd = msg.value / 5;

        address x7001 = address(0x7001629B8BF9A5D5F204B6d464a06f506fBFA105);
        address x7002 = address(0x70021e5edA64e68F035356Ea3DCe14ef87B6F105);
        address x7003 = address(0x70036Ddf2F2850f6d1B9D78D652776A0d1caB105);
        address x7004 = address(0x70041dB5aCDf2F8aa648A000FA4A87067AbAE105);
        address x7005 = address(0x7005D9011F4275747D5cb38bC3deB0C46EdbD105);

        IX7Token(x7001).startTrading();
        IX7Token(x7002).startTrading();
        IX7Token(x7003).startTrading();
        IX7Token(x7004).startTrading();
        IX7Token(x7005).startTrading();

        createETHPair(x7001, ethToAdd);
        createETHPair(x7002, ethToAdd);
        createETHPair(x7003, ethToAdd);
        createETHPair(x7004, ethToAdd);
        createETHPair(x7005, ethToAdd);
    }

    function createX7001Pairs() external onlyOwner {
        require(!X7001PairsCreated);
        X7001PairsCreated = true;

        address x7001 = address(0x7001629B8BF9A5D5F204B6d464a06f506fBFA105);
        address x7002 = address(0x70021e5edA64e68F035356Ea3DCe14ef87B6F105);
        address x7003 = address(0x70036Ddf2F2850f6d1B9D78D652776A0d1caB105);
        address x7004 = address(0x70041dB5aCDf2F8aa648A000FA4A87067AbAE105);
        address x7005 = address(0x7005D9011F4275747D5cb38bC3deB0C46EdbD105);

        createTokenPair(x7001, x7002);
        createTokenPair(x7001, x7003);
        createTokenPair(x7001, x7004);
        createTokenPair(x7001, x7005);
    }

    function createX7002Pairs() external onlyOwner {
        require(!X7002PairsCreated);
        X7002PairsCreated = true;
        address x7002 = address(0x70021e5edA64e68F035356Ea3DCe14ef87B6F105);
        address x7003 = address(0x70036Ddf2F2850f6d1B9D78D652776A0d1caB105);
        address x7004 = address(0x70041dB5aCDf2F8aa648A000FA4A87067AbAE105);
        address x7005 = address(0x7005D9011F4275747D5cb38bC3deB0C46EdbD105);
        createTokenPair(x7002, x7003);
        createTokenPair(x7002, x7004);
        createTokenPair(x7002, x7005);
    }

    function createX7003Pairs() external onlyOwner {
        require(!X7003PairsCreated);
        X7003PairsCreated = true;
        address x7003 = address(0x70036Ddf2F2850f6d1B9D78D652776A0d1caB105);
        address x7004 = address(0x70041dB5aCDf2F8aa648A000FA4A87067AbAE105);
        address x7005 = address(0x7005D9011F4275747D5cb38bC3deB0C46EdbD105);
        createTokenPair(x7003, x7004);
        createTokenPair(x7003, x7005);
    }

    function createX7004Pairs() external onlyOwner {
        require(!X7004PairsCreated);
        X7004PairsCreated = true;
        address x7004 = address(0x70041dB5aCDf2F8aa648A000FA4A87067AbAE105);
        address x7005 = address(0x7005D9011F4275747D5cb38bC3deB0C46EdbD105);
        createTokenPair(x7004, x7005);
    }

    function createETHPair(address tokenAddress, uint256 ethToAdd) internal {
        IX7Token token = IX7Token(tokenAddress);
        IUniswapV2Factory factory =  IUniswapV2Factory(router.factory());

        address nativePairAddress = factory.getPair(address(token), router.WETH());
        if (nativePairAddress == address(0)) {
            nativePairAddress = factory.createPair(address(token), router.WETH());
        }

        token.setOffRampPair(nativePairAddress);
        addLiquidityETH(address(token), initialTokensPerPair, ethToAdd);
        nativeTokenPairs[tokenAddress] = nativePairAddress;
    }

    function createTokenPair(address tokenAddress, address otherTokenAddress) internal {
        IX7Token token = IX7Token(tokenAddress);
        IX7Token otherToken = IX7Token(otherTokenAddress);
        IUniswapV2Factory factory =  IUniswapV2Factory(router.factory());

        address pairAddress = factory.getPair(address(token), address(otherToken));
        if (pairAddress == address(0)) {
            pairAddress = factory.createPair(address(token), address(otherToken));
        }

        token.setAMM(pairAddress, true);
        otherToken.setAMM(pairAddress, true);

        addLiquidity(address(token), initialTokensPerPair, address(otherToken), initialTokensPerPair);
        swapPairs[tokenAddress][otherTokenAddress] = pairAddress;
    }

    function addLiquidityETH(address tokenAddress, uint256 tokenAmount, uint256 ethAmount) internal {
        IERC20(tokenAddress).approve(address(router), tokenAmount);
        router.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            tokenAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function addLiquidity(address tokenAAddress, uint256 tokenAAmount, address tokenBAddress, uint256 tokenBAmount) internal {
        IERC20(tokenAAddress).approve(address(router), tokenAAmount);
        IERC20(tokenBAddress).approve(address(router), tokenBAmount);
        router.addLiquidity(
            tokenAAddress,
            tokenBAddress,
            tokenAAmount,
            tokenBAmount,
            0,
            0,
            address(0xdead),
            block.timestamp
        );
    }

    function swapTokensForEth(address tokenAddress, uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = tokenAddress;
        path[1] = router.WETH();

        IERC20(tokenAddress).approve(address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapEthForTokens(address tokenAddress, uint256 ethAmount) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddress;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }
}