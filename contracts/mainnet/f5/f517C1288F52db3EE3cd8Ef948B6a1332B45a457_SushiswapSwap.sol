// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token1() external view returns (address);
}

interface IWETH {
    function deposit() external payable;
}

interface Sushiswap {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract SushiswapSwap {
    address public weth;
    address public sushiswap;
    IERC20 public outputToken;
    address public swapOutputDestinationAddress;
    address[] public swapOutputDestinationAddressOptions;
    address public maintainer;
    address public admin;
    address public pairAddress;
    uint256 public maxSlippagePercentageBasisPoints;
    uint256 public maxPriceOverride;
    bool public isSwapOutputDestinationLocked;

    event SwapForMinimum(uint256 wethAmount, uint256 minOutputTokenAmount);

    constructor(
        address _outputTokenAddress,
        address[] memory _swapOutputDestinationAddresses,
        address _maintainer,
        address _admin, // ideally a multisig
        address _pairAddress,
        address _wethAddress,
        address _sushiswapAddress,
        uint256 _maxSlippagePercentageBasisPoints
    ) {
        outputToken = IERC20(_outputTokenAddress);
        swapOutputDestinationAddress = _swapOutputDestinationAddresses[0];
        swapOutputDestinationAddressOptions = _swapOutputDestinationAddresses;
        maintainer = _maintainer;
        admin = _admin;
        pairAddress = _pairAddress;
        weth = _wethAddress;
        sushiswap = _sushiswapAddress;
        IERC20(weth).approve(_sushiswapAddress, type(uint256).max);
        maxSlippagePercentageBasisPoints = _maxSlippagePercentageBasisPoints;
    }

    modifier onlyMaintainerOrAdmin() {
        require(msg.sender == maintainer || msg.sender == admin, "Only maintainer or admin may call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin may call this function.");
        _;
    }

    function swap() public {
        uint256 minimumAcceptableBuyAmount = getMinAcceptableBuyAmount();

        IWETH(weth).deposit{value: address(this).balance}();
        uint256 amountIn = IERC20(weth).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(outputToken);

        emit SwapForMinimum(amountIn, minimumAcceptableBuyAmount);

        Sushiswap(sushiswap).swapExactTokensForTokens(
            amountIn,
            minimumAcceptableBuyAmount,
            path,
            swapOutputDestinationAddress,
            block.timestamp
        );
    }

    function getMinAcceptableBuyAmount() public view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 Res0, uint256 Res1,) = pair.getReserves();
        uint256 res0 = Res0*(10**18);
        uint256 autoPrice = address(this).balance / (res0/Res1);
        uint256 price = (maxPriceOverride > autoPrice) ? autoPrice : maxPriceOverride;
        uint256 minimumAcceptableBuy = ((price * (10000 - maxSlippagePercentageBasisPoints))*(10**18)) / 10000;
        return minimumAcceptableBuy;
    }

    function viewAutoPrice() public view returns(uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 Res0, uint256 Res1,) = pair.getReserves();
        uint256 res0 = Res0*(10**18);
        uint256 autoPrice = address(this).balance / (res0/Res1);
        return autoPrice;
    }

    receive() external payable {}

    // onlyMaintainerOrAdmin functions below

    function setMaxSlippagePercentageBasisPoints(uint256 _maxSlippagePercentageBasisPoints) public onlyMaintainerOrAdmin {
        require(_maxSlippagePercentageBasisPoints > 0, "_maxSlippagePercentageBasisPoints must be more than zero");
        maxSlippagePercentageBasisPoints = _maxSlippagePercentageBasisPoints;
    }

    function setMaxPriceOverride(uint256 _maxPriceOverride) public onlyMaintainerOrAdmin {
        require(_maxPriceOverride > 0, "_maxPriceOverride must be more than zero");
        maxPriceOverride = _maxPriceOverride;
    }

    // onlyAdmin functions below

    function setSwapOutputDestinationAddressByOptionIndex(uint256 _outputDestinationAddressOptionIndex) public onlyAdmin {
        require(isSwapOutputDestinationLocked == false, 'swapOutputDestinationAddress has been locked');
        swapOutputDestinationAddress = swapOutputDestinationAddressOptions[_outputDestinationAddressOptionIndex];
    }

    function lockSwapOutputDestinationAddress() public onlyAdmin {
        require(isSwapOutputDestinationLocked == false, 'swapOutputDestinationAddress has already been locked');
        isSwapOutputDestinationLocked = true;
    }

    function setMaintainer(address _maintainer) public onlyAdmin {
        maintainer = _maintainer;
    }

    function setAdmin(address _admin) public onlyAdmin {
        admin = _admin;
    }

    // Failure case fallback functions below

    function fallbackSwap(uint256 _amountOutMin) public onlyAdmin {
        IWETH(weth).deposit{value: address(this).balance}();
        uint256 amountIn = IERC20(weth).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(outputToken);

        emit SwapForMinimum(amountIn, _amountOutMin);

        Sushiswap(sushiswap).swapExactTokensForTokens(
            amountIn,
            _amountOutMin,
            path,
            swapOutputDestinationAddress,
            block.timestamp
        );
    }

    function emergencyExit() public onlyAdmin {
        (bool success, ) = admin.call{value: address(this).balance}("");
        require(success, "Emergency exit failed.");
    }

    function emergencyExitToEndpoint(address endpoint) public onlyAdmin {
        (bool success, ) = endpoint.call{value: address(this).balance}("");
        require(success, "Emergency exit to endpoint failed.");
    }

}