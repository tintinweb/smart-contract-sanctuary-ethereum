pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPrecogCore.sol";
contract PrecogCore is IPrecogCore {

    modifier onlyAdmin() {
        require(msg.sender == admin, "PrecogV5: NOT_ADMIN_ADDRESS");
        _;
    }

    address admin;
    address middleware;
    address exchange;
    address public override PCOG;

    // uint32 public firstInvestmentCycle = 604800; // 7 days
    // uint32 public firstWithdrawalCycle = 604800; // 7days
    // uint32 public investmentCycle = 86400; // 1 day
    // uint32 public withdrawalCycle = 172800; // 2 days
    // uint32 public profitCycle = 86400; // 1 day
    uint32 firstInvestmentCycle = 1; // 7 days
    uint32 firstWithdrawalCycle = 1; // 7days
    uint32 investmentCycle = 1; // 1 day
    uint32 withdrawalCycle = 1; // 2 days
    uint32 profitCycle = 1; // 1 day
    uint8  public override constant feeDecimalBase = 18;
    uint64 depositFee = 1000000000000000;
    uint64 withdrawalFee = 1000000000000000;
    uint64 tradingFee = 1000000000000000;
    uint64 lendingFee = 1000000000000000;

    event SetCoreConfiguration(
        address indexed newAdmin,
        address indexed newMiddleware,
        address indexed newExchange
    );

    event SetCycleConfiguration(
        uint32 firstInvestmentCycle, 
        uint32 firstWithdrawalCycle, 
        uint32 investmentCycle,
        uint32 withdrawalCycle,
        uint32 profitCycle
    );
    event SetFeeConfiguration( 
        uint256 depositFee, 
        uint256 withdrawalFee, 
        uint256 tradingFee,
        uint256 lendingFee
    );

    constructor(address _admin, address _middleware, address _PCOG, address _exchange) {
        admin = _admin;
        middleware = _middleware;
        PCOG = _PCOG;
        exchange = _exchange;
    }

    //

    function getCoreConfiguration() external view override returns (CoreConfiguration memory) {
        return CoreConfiguration(admin, middleware, exchange);
    }

    function getFeeConfiguration() external view override returns (FeeConfiguration memory) {
        return FeeConfiguration(depositFee, withdrawalFee, tradingFee, lendingFee);
    }

    function getCycleConfiguration() external view override returns (CycleConfiguration memory) {
        return CycleConfiguration(firstInvestmentCycle, firstWithdrawalCycle, investmentCycle, withdrawalCycle, profitCycle);
    }

    function setCoreConfiguration(CoreConfiguration memory config) external override onlyAdmin {
        admin = config.admin;
        middleware = config.middleware;
        exchange = config.exchange;
        emit SetCoreConfiguration(admin, middleware, exchange);
    }

    function setCycleConfiguration(CycleConfiguration memory config) external override onlyAdmin {
        firstInvestmentCycle = config.firstInvestmentCycle;
        firstWithdrawalCycle = config.firstWithdrawalCycle;
        investmentCycle = config.investmentCycle;
        withdrawalCycle = config.withdrawalCycle;
        profitCycle = config.profitCycle;
        emit SetCycleConfiguration(firstInvestmentCycle, firstWithdrawalCycle, investmentCycle, withdrawalCycle, profitCycle);
    }

    function setFeeConfiguration(FeeConfiguration memory config) external override onlyAdmin {
        depositFee = config.depositFee;
        withdrawalFee = config.withdrawalFee;
        tradingFee = config.tradingFee;
        lendingFee = config.lendingFee;
        emit SetFeeConfiguration(depositFee, withdrawalFee, tradingFee, lendingFee);
    }

    function collectFee(address token) public override onlyAdmin {
        IERC20(token).transfer(admin, IERC20(token).balanceOf(address(this)));
    }
    
}

interface IPrecogCore {
    struct CoreConfiguration {
        address admin;
        address middleware;
        address exchange;
    }

    struct CycleConfiguration {
        uint32 firstInvestmentCycle;
        uint32 firstWithdrawalCycle;
        uint32 investmentCycle;
        uint32 withdrawalCycle;
        uint32 profitCycle;
    }

    struct FeeConfiguration {
        uint64 depositFee;
        uint64 withdrawalFee;
        uint64 tradingFee;
        uint64 lendingFee;
    }

    event SetCoreConfiguration(address indexed admin, address newAdmin, address newMiddleware, address newExchange);
    event SetCycleConfiguration(
        address indexed admin, 
        uint32 firstInvestmentCycle,
        uint32 firstWithdrawalCycle,
        uint32 investmentCycle,
        uint32 withdrawalCycle,
        uint32 profitCycle
    );
    event SetFeeConfiguration(
        address indexed admin,
        uint64 depositFee,
        uint64 withdrawalFee,
        uint64 tradingFee,
        uint64 lendingFee
    );
    event CollectFee(
        address indexed admin, 
        address indexed token,
        uint256 amount
    );
    function PCOG() external returns (address);
    function feeDecimalBase() external view returns (uint8);
    function getCoreConfiguration() external view returns (CoreConfiguration memory);
    function getFeeConfiguration() external view returns (FeeConfiguration memory);
    function getCycleConfiguration() external view returns (CycleConfiguration memory);

    function setCoreConfiguration(CoreConfiguration memory config) external;
    function setCycleConfiguration(CycleConfiguration memory config) external;
    function setFeeConfiguration(FeeConfiguration memory config) external;
    function collectFee(address token) external;
    
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