//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILendingPoolAave {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    function rebalanceStableBorrowRate(address asset, address user) external;

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(
        address reserve,
        address rateStrategyAddress
    ) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

interface IWETHGateway {
    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address onBehalfOf
    ) external;
}

interface CEth {
    function balanceOf(address) external view returns (uint256);

    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function balanceOfUnderlying(address) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function repayBorrow() external payable;

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);
}

interface CErc20 {
    function balanceOf(address) external view returns (uint256);

    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function balanceOfUnderlying(address) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function repayBorrow(uint256) external returns (uint256);
}

contract LendingPool {
    ILendingPoolAave public constant AAVE =
        ILendingPoolAave(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
    IERC20 public constant DAI_AAVE =
        IERC20(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD);
    IWETHGateway public constant WETH_GATEWAY =
        IWETHGateway(0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70);
    IERC20 public constant A_WETH =
        IERC20(0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347);

    CEth public constant C_ETH =
        CEth(0x41B5844f4680a8C38fBb695b7F9CFd1F64474a72);

    CErc20 public constant C_DAI =
        CErc20(0xF0d0EB522cfa50B716B3b1604C4F0fA6f04376AD);

    IERC20 public constant DAI =
        IERC20(0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa);

    event MyLog(string, uint256);

    function depositAave(uint256 amount) external {
        WETH_GATEWAY.depositETH{value: amount}(address(AAVE), msg.sender, 0);
    }

    function withdrawAave(uint256 amount) external {
        A_WETH.approve(address(WETH_GATEWAY), amount);
        WETH_GATEWAY.withdrawETH(address(AAVE), amount, msg.sender);
    }

    function borrowAave(uint256 amount) external {
        AAVE.borrow(address(DAI_AAVE), amount, 2, 0, msg.sender);
    }

    function repayAave(uint256 amount) external returns (uint256) {
        return AAVE.repay(address(DAI_AAVE), amount, 2, msg.sender);
    }

    // function depositCompound(uint256 amount) public returns (bool) {
    //     C_ETH.mint{value: amount, gas: 250000}();
    //     return true;
    // }

    function depositCompound() public payable returns (bool) {
        // Amount of current exchange rate from cToken to underlying
        uint256 exchangeRateMantissa = C_ETH.exchangeRateCurrent();
        emit MyLog("Exchange Rate (scaled up by 1e18): ", exchangeRateMantissa);

        // Amount added to you supply balance this block
        uint256 supplyRateMantissa = C_ETH.supplyRatePerBlock();
        emit MyLog("Supply Rate: (scaled up by 1e18)", supplyRateMantissa);

        C_ETH.mint{value: msg.value, gas: 250000}();
        uint256 toMyWallet = C_ETH.balanceOf(address(this));
        C_ETH.transferFrom(address(this), msg.sender, toMyWallet);

        return true;
    }

    function withdrawCompound(uint256 amount, bool redeemType)
        public
        returns (bool)
    {
        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = C_ETH.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = C_ETH.redeemUnderlying(amount);
        }
        return true;
    }

    function borrowCompound(uint256 amount) public returns (uint256) {
        uint256 borrowNumber = C_DAI.borrow(amount);
        DAI.transferFrom(address(C_DAI), msg.sender, amount);
        return borrowNumber;
    }

    function repayCompound(uint256 amount) public returns (bool) {
        DAI.approve(address(C_DAI), amount);
        uint256 error = C_DAI.repayBorrow(amount);

        require(error == 0, "CErc20.repayBorrow Error");
        return true;
    }

    // This is needed to receive ETH when calling `redeemCEth`
    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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