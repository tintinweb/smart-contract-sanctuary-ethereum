pragma solidity 0.8.9;
import { Denominations } from "chainlink/Denominations.sol";
import { ILineOfCredit } from "../interfaces/ILineOfCredit.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { IInterestRateCredit } from "../interfaces/IInterestRateCredit.sol";
import { ILineOfCredit } from "../interfaces/ILineOfCredit.sol";
import { LineLib } from "./LineLib.sol";

/**
  * @title Debt DAO P2P Line Library
  * @author Kiba Gateaux
  * @notice Core logic and variables to be reused across all Debt DAO Marketplace lines
 */
library CreditLib {

    event AddCredit(
        address indexed lender,
        address indexed token,
        uint256 indexed deposit,
        bytes32 positionId
    );

  event WithdrawDeposit(bytes32 indexed id, uint256 indexed amount);
  // lender removing funds from Line  principal
  event WithdrawProfit(bytes32 indexed id, uint256 indexed amount);
  // lender taking interest earned out of contract

  event InterestAccrued(bytes32 indexed id, uint256 indexed amount);
  // interest added to borrowers outstanding balance


  // Borrower Events

  event Borrow(bytes32 indexed id, uint256 indexed amount);
  // receive full line or drawdown on credit

  event RepayInterest(bytes32 indexed id, uint256 indexed amount);

  event RepayPrincipal(bytes32 indexed id, uint256 indexed amount);


  error NoTokenPrice();

  error PositionExists();


  /**
   * @dev          - Create deterministic hash id for a debt position on `line` given position details
   * @param line   - line that debt position exists on
   * @param lender - address managing debt position
   * @param token  - token that is being lent out in debt position
   * @return positionId
   */
  function computeId(
    address line,
    address lender,
    address token
  )
    external pure
    returns(bytes32)
  {
    return keccak256(abi.encode(line, lender, token));
  }

    function getOutstandingDebt(
      ILineOfCredit.Credit memory credit,
      bytes32 id,
      address oracle,
      address interestRate
    )
      external
      returns (ILineOfCredit.Credit memory c, uint256 principal, uint256 interest)
    {
        c = accrue(credit, id, interestRate);

        int256 price = IOracle(oracle).getLatestAnswer(c.token);

        principal = calculateValue(
            price,
            c.principal,
            c.decimals
        );
        interest = calculateValue(
            price,
            c.interestAccrued,
            c.decimals
        );

        return (c, principal, interest);
  }
    /**
     * @notice         - calculates value of tokens in US
     * @dev            - Assumes oracles all return answers in USD with 1e8 decimals
                       - Does not check if price < 0. HAndled in Oracle or Line
     * @param price    - oracle price of asset. 8 decimals
     * @param amount   - amount of tokens vbeing valued.
     * @param decimals - token decimals to remove for usd price
     * @return         - total USD value of amount in 8 decimals 
     */
    function calculateValue(
      int price,
      uint256 amount,
      uint8 decimals
    )
      public  pure
      returns(uint256)
    {
      return price <= 0 ? 0 : (amount * uint(price)) / (1 * 10 ** decimals);
    }
  

  function create(
      bytes32 id,
      uint256 amount,
      address lender,
      address token,
      address oracle
  )
      external 
      returns(ILineOfCredit.Credit memory credit)
  {
      int price = IOracle(oracle).getLatestAnswer(token);
      if(price <= 0 ) { revert NoTokenPrice(); }

      uint8 decimals;
      if(token == Denominations.ETH) {
          decimals = 18;
      } else {
          (bool passed, bytes memory result) = token.call(
              abi.encodeWithSignature("decimals()")
          );
          decimals = !passed ? 18 : abi.decode(result, (uint8));
      }

      credit = ILineOfCredit.Credit({
          lender: lender,
          token: token,
          decimals: decimals,
          deposit: amount,
          principal: 0,
          interestAccrued: 0,
          interestRepaid: 0
      });

      emit AddCredit(lender, token, amount, id);

      return credit;
  }

  function repay(
    ILineOfCredit.Credit memory credit,
    bytes32 id,
    uint256 amount
  )
    external
    returns (ILineOfCredit.Credit memory)
  { unchecked {
      if (amount <= credit.interestAccrued) {
          credit.interestAccrued -= amount;
          credit.interestRepaid += amount;
          emit RepayInterest(id, amount);
          return credit;
      } else {
          uint256 interest = credit.interestAccrued;
          uint256 principalPayment = amount - interest;

          // update individual credit position denominated in token
          credit.principal -= principalPayment;
          credit.interestRepaid += interest;
          credit.interestAccrued = 0;

          emit RepayInterest(id, interest);
          emit RepayPrincipal(id, principalPayment);

          return credit;
      }
  } }

  function withdraw(
    ILineOfCredit.Credit memory credit,
    bytes32 id,
    uint256 amount
  )
    external
    returns (ILineOfCredit.Credit memory)
  { unchecked {
      if(amount > credit.deposit - credit.principal + credit.interestRepaid) {
        revert ILineOfCredit.NoLiquidity();
      }

      if (amount > credit.interestRepaid) {
          uint256 interest = credit.interestRepaid;
          amount -= interest;

          credit.deposit -= amount;
          credit.interestRepaid = 0;

          // emit events before seeting to 0
          emit WithdrawDeposit(id, amount);
          emit WithdrawProfit(id, interest);

          return credit;
      } else {
          credit.interestRepaid -= amount;
          emit WithdrawProfit(id, amount);
          return credit;
      }
  } }


  function accrue(
    ILineOfCredit.Credit memory credit,
    bytes32 id,
    address interest
  )
    public
    returns (ILineOfCredit.Credit memory)
  { unchecked {
      // interest will almost always be less than deposit
      // low risk of overflow unless extremely high interest rate

      // get token demoninated interest accrued
      uint256 accruedToken = IInterestRateCredit(interest).accrueInterest(
          id,
          credit.principal,
          credit.deposit
      );

      // update credits balance
      credit.interestAccrued += accruedToken;

      emit InterestAccrued(id, accruedToken);
      return credit;
  } }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

pragma solidity 0.8.9;

import { LineLib } from "../utils/LineLib.sol";
import { IOracle } from "../interfaces/IOracle.sol";

interface ILineOfCredit {
  // Lender data
  struct Credit {
    //  all denominated in token, not USD
    uint256 deposit;          // total liquidity provided by lender for token
    uint256 principal;        // amount actively lent out
    uint256 interestAccrued;  // interest accrued but not repaid
    uint256 interestRepaid;   // interest repaid by borrower but not withdrawn by lender
    uint8 decimals;           // decimals of credit token for calcs
    address token;            // token being lent out
    address lender;           // person to repay
  }
  // General Events
  event UpdateStatus(uint256 indexed status); // store as normal uint so it can be indexed in subgraph

  event DeployLine(
    address indexed oracle,
    address indexed arbiter,
    address indexed borrower
  );

  // MutualConsent borrower/lender events

  event AddCredit(
    address indexed lender,
    address indexed token,
    uint256 indexed deposit,
    bytes32 positionId
  );
  // can reference only id once AddCredit is emitted because it will be indexed offchain

  event SetRates(bytes32 indexed id, uint128 indexed drawnRate, uint128 indexed facilityRate);

  event IncreaseCredit (bytes32 indexed id, uint256 indexed deposit);

  // Lender Events

  event WithdrawDeposit(bytes32 indexed id, uint256 indexed amount);
  // lender removing funds from Line  principal
  event WithdrawProfit(bytes32 indexed id, uint256 indexed amount);
  // lender taking interest earned out of contract

  event CloseCreditPosition(bytes32 indexed id);
  // lender officially repaid in full. if Credit then facility has also been closed.

  event InterestAccrued(bytes32 indexed id, uint256 indexed amount);
  // interest added to borrowers outstanding balance


  // Borrower Events

  event Borrow(bytes32 indexed id, uint256 indexed amount);
  // receive full line or drawdown on credit

  event RepayInterest(bytes32 indexed id, uint256 indexed amount);

  event RepayPrincipal(bytes32 indexed id, uint256 indexed amount);

  event Default(bytes32 indexed id);

  // Access Errors
  error NotActive();
  error NotBorrowing();
  error CallerAccessDenied();
  
  // Tokens
  error TokenTransferFailed();
  error NoTokenPrice();

  // Line
  error BadModule(address module);
  error NoLiquidity();
  error PositionExists();
  error CloseFailedWithPrincipal();
  error NotInsolvent(address module);
  error NotLiquidatable();
  error AlreadyInitialized();

  function init() external returns(LineLib.STATUS);

  // MutualConsent functions
  function addCredit(
    uint128 drate,
    uint128 frate,
    uint256 amount,
    address token,
    address lender
  ) external payable returns(bytes32);
  function setRates(bytes32 id, uint128 drate, uint128 frate) external returns(bool);
  function increaseCredit(bytes32 id, uint256 amount) external payable returns(bool);

  // Borrower functions
  function borrow(bytes32 id, uint256 amount) external returns(bool);
  function depositAndRepay(uint256 amount) external payable returns(bool);
  function depositAndClose() external payable returns(bool);
  function close(bytes32 id) external payable returns(bool);
  
  // Lender functions
  function withdraw(bytes32 id, uint256 amount) external returns(bool);

  // Arbiter functions
  function declareInsolvent() external returns(bool);

  function accrueInterest() external returns(bool);
  function healthcheck() external returns(LineLib.STATUS);
  function updateOutstandingDebt() external returns(uint256, uint256);

  function status() external returns(LineLib.STATUS);
  function borrower() external returns(address);
  function arbiter() external returns(address);
  function oracle() external returns(IOracle);
  function counts() external view returns (uint256, uint256);
}

pragma solidity 0.8.9;

interface IOracle {
    /** current price for token asset. denominated in USD */
    function getLatestAnswer(address token) external returns(int);
}

pragma solidity ^0.8.9;

interface IInterestRateCredit {
  struct Rate {
    // The interest rate charged to a Borrower on borrowed / drawn down funds
    // in bps, 4 decimals
    uint128 dRate;
    // The interest rate charged to a Borrower on the remaining funds available, but not yet drawn down (rate charged on the available headroom)
    // in bps, 4 decimals
    uint128 fRate;
    // The time stamp at which accrued interest was last calculated on an ID and then added to the overall interestAccrued (interest due but not yet repaid)
    uint256 lastAccrued;
  }

  function accrueInterest(
    bytes32 id,
    uint256 drawnAmount,
    uint256 facilityAmount
  ) external returns(uint256);

  function setRate(
    bytes32 id,
    uint128 dRate,
    uint128 fRate
  ) external returns(bool);
}

pragma solidity 0.8.9;
import { IInterestRateCredit } from "../interfaces/IInterestRateCredit.sol";
import { ILineOfCredit } from "../interfaces/ILineOfCredit.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20}  from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { Denominations } from "chainlink/Denominations.sol";

/**
  * @title Debt DAO P2P Line Library
  * @author Kiba Gateaux
  * @notice Core logic and variables to be reused across all Debt DAO Marketplace lines
 */
library LineLib {
    using SafeERC20 for IERC20;

    error TransferFailed();
    error BadToken();

    enum STATUS {
        UNINITIALIZED,
        ACTIVE,
        LIQUIDATABLE,
        REPAID,
        INSOLVENT
    }

    /**
     * @notice - Send ETH or ERC20 token from this contract to an external contract
     * @param token - address of token to send out. Denominations.ETH for raw ETH
     * @param receiver - address to send tokens to
     * @param amount - amount of tokens to send
     */
    function sendOutTokenOrETH(
      address token,
      address receiver,
      uint256 amount
    )
      external
      returns (bool)
    {
        if(token == address(0)) { revert TransferFailed(); }
        
        // both branches revert if call failed
        if(token!= Denominations.ETH) { // ERC20
            IERC20(token).safeTransfer(receiver, amount);
        } else { // ETH
            payable(receiver).transfer(amount);
        }
        return true;
    }

    /**
     * @notice - Send ETH or ERC20 token from this contract to an external contract
     * @param token - address of token to send out. Denominations.ETH for raw ETH
     * @param sender - address that is giving us tokens/ETH
     * @param amount - amount of tokens to send
     */
    function receiveTokenOrETH(
      address token,
      address sender,
      uint256 amount
    )
      external
      returns (bool)
    {
        if(token == address(0)) { revert TransferFailed(); }
        if(token != Denominations.ETH) { // ERC20
            IERC20(token).safeTransferFrom(sender, address(this), amount);
        } else { // ETH
            if(msg.value < amount) { revert TransferFailed(); }
        }
        return true;
    }

    /**
     * @notice - Helper function to get current balance of this contract for ERC20 or ETH
     * @param token - address of token to check. Denominations.ETH for raw ETH
    */
    function getBalance(address token) external view returns (uint256) {
        if(token == address(0)) return 0;
        return token != Denominations.ETH ?
            IERC20(token).balanceOf(address(this)) :
            address(this).balance;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}