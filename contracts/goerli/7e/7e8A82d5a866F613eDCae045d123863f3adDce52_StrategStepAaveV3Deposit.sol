// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IPoolV3.sol";
import "../StrategStep.sol";



/* solhint-disable */
contract StrategStepAaveV3Deposit is StrategStep {

    struct Parameters {
        address lendingPool;
        uint256 tokenInPercent;
        address token;
        address aToken;
    }

    constructor() {
    }

    function enter(bytes calldata _parameters) external {
        Parameters memory parameters = abi.decode(_parameters, (Parameters));
        uint256 amountToDeposit = IERC20(parameters.token).balanceOf(address(this)) * parameters.tokenInPercent / 100;

        IERC20(parameters.token).approve(address(parameters.lendingPool), amountToDeposit);

        IPool(parameters.lendingPool).supply(
            parameters.token,
            amountToDeposit,
            address(this),
            0
        );
    }

    function exit(bytes calldata _parameters) external {
        Parameters memory parameters = abi.decode(_parameters, (Parameters));
        uint256 amountToWithdraw = IERC20(parameters.aToken).balanceOf(address(this));

        IPool(parameters.lendingPool).withdraw(
            parameters.token,
            amountToWithdraw,
            address(this)
        );
    }
    
    function oracleEnter(IStratStep.OracleResponse memory _before, bytes memory _parameters) external view returns (OracleResponse memory) {
        Parameters memory parameters = abi.decode(_parameters, (Parameters));
        uint256 amountToDeposit = _findTokenAmount(parameters.token, _before) * parameters.tokenInPercent / 100;

        if(amountToDeposit == 0) {
            amountToDeposit = IERC20(parameters.token).balanceOf(msg.sender);
            _before = _addTokenAmount(parameters.token, amountToDeposit, _before);
        }

        IStratStep.OracleResponse memory _after = _removeTokenAmount(parameters.token, amountToDeposit, _before);
        _after = _addTokenAmount(parameters.aToken, amountToDeposit, _after);
        
        return _after;
    }
    
    function oracleExit(IStratStep.OracleResponse memory _before, bytes memory _parameters) external view returns (OracleResponse memory) {
        Parameters memory parameters = abi.decode(_parameters, (Parameters));
        uint256 amountToWithdraw = _findTokenAmount(parameters.aToken, _before);

        if(amountToWithdraw == 0) {
            amountToWithdraw = IERC20(parameters.aToken).balanceOf(msg.sender);
            _before = _addTokenAmount(parameters.aToken, amountToWithdraw, _before);
        }

        IStratStep.OracleResponse memory _after = _removeTokenAmount(parameters.token, amountToWithdraw, _before);
        _after = _addTokenAmount(parameters.aToken, amountToWithdraw, _after);
        
        return _after;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.12;

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {


  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;


  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   **/
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) external returns (uint256);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line
pragma solidity ^0.8.12;

import "../interfaces/IStratStep.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/* solhint-disable */
abstract contract StrategStep is IStratStep {

    function _findTokenAmount(address _token, OracleResponse memory _res) internal pure returns (uint256) {
        for (uint i = 0; i < _res.tokens.length; i++) {
            if(_res.tokens[i] == _token) {
                return _res.tokensAmount[i];
            }
        }
        return 0;
    }

    function _addTokenAmount(address _token, uint256 _amount, OracleResponse memory _res) internal pure returns (IStratStep.OracleResponse memory) {
        for (uint i = 0; i < _res.tokens.length; i++) {
            if(_res.tokens[i] == _token) {
                _res.tokensAmount[i] += _amount;
                return _res;
            }
        }

        address[] memory newTokens = new address[](_res.tokens.length + 1);
        uint256[] memory newTokensAmount = new uint256[](_res.tokens.length + 1);

        for (uint i = 0; i < _res.tokens.length; i++) {
            newTokens[i] = _res.tokens[i];
            newTokensAmount[i] = _res.tokensAmount[i];
        }

        newTokens[_res.tokens.length] = _token;
        newTokensAmount[_res.tokens.length] = _amount;

        _res.tokens = newTokens;
        _res.tokensAmount = newTokensAmount;
        return _res;
    }

    function _removeTokenAmount(address _token, uint256 _amount, OracleResponse memory _res) internal pure returns (IStratStep.OracleResponse memory) {
        for (uint i = 0; i < _res.tokens.length; i++) {
            if(_res.tokens[i] == _token) {
                _res.tokensAmount[i] -= _amount;
                return _res;
            }
        }

        return _res;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


interface IStratStep {

    struct OracleResponse {
        address[] tokens;
        uint256[] tokensAmount;
    }


    function enter(bytes memory parameters) external;
    function exit(bytes memory parameters) external;

    function oracleEnter(OracleResponse memory previous, bytes memory parameters) external view returns (OracleResponse memory);
    function oracleExit(OracleResponse memory previous, bytes memory parameters) external view returns (OracleResponse memory);
}