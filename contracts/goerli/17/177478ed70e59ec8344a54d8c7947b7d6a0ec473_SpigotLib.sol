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

    /**
     * @notice - allows `lineContract to calculate how much interest is owed since it was last calculated charged at time `lastAccrued`
     * @dev    - pure function that only calculates interest owed. Line is responsible for actually updating credit balances with returned value
     * @dev    - callable by `lineContract`
     * @param id - position id on Line to look up interest rates for
     * @param drawnBalance the balance of funds that a Borrower has drawn down on the credit line
     * @param facilityBalance the remaining balance of funds that a Borrower can still drawn down on a credit line (aka headroom)
     *
     * @return - the amount of interest to be repaid for this interest period
     */
    function accrueInterest(bytes32 id, uint256 drawnBalance, uint256 facilityBalance) external returns (uint256);

    /**
     * @notice - updates interest rates on a lender's position. Updates lastAccrued time to block.timestamp
     * @dev    - MUST call accrueInterest() on Line before changing rates. If not, lender will not accrue interest over previous interest period.
     * @dev    - callable by `line`
     * @return - if call was successful or not
     */
    function setRate(bytes32 id, uint128 dRate, uint128 fRate) external returns (bool);
}

pragma solidity 0.8.9;

import {LineLib} from "../utils/LineLib.sol";
import {IOracle} from "../interfaces/IOracle.sol";

interface ILineOfCredit {
    // Lender data
    struct Credit {
        //  all denominated in token, not USD
        uint256 deposit; // The total liquidity provided by a Lender in a given token on a Line of Credit
        uint256 principal; // The amount of a Lender's Deposit on a Line of Credit that has actually been drawn down by the Borrower (in Tokens)
        uint256 interestAccrued; // Interest due by a Borrower but not yet repaid to the Line of Credit contract
        uint256 interestRepaid; // Interest repaid by a Borrower to the Line of Credit contract but not yet withdrawn by a Lender
        uint8 decimals; // Decimals of Credit Token for calcs
        address token; // The token being lent out (Credit Token)
        address lender; // The person to repay
        bool isOpen; // Status of position
    }

    // General Events
    event UpdateStatus(uint256 indexed status); // store as normal uint so it can be indexed in subgraph

    event DeployLine(address indexed oracle, address indexed arbiter, address indexed borrower);

    event SortedIntoQ(bytes32 indexed id, uint256 indexed newIdx, uint256 indexed oldIdx, bytes32 oldId);

    // MutualConsent borrower/lender events

    event AddCredit(address indexed lender, address indexed token, uint256 indexed deposit, bytes32 id);
    // can only reference id once AddCredit is emitted because it will be indexed offchain

    event SetRates(bytes32 indexed id, uint128 indexed dRate, uint128 indexed fRate);

    event IncreaseCredit(bytes32 indexed id, uint256 indexed deposit);

    // Lender Events

    // Emits data re Lender removes funds (principal) - there is no corresponding function, just withdraw()
    event WithdrawDeposit(bytes32 indexed id, uint256 indexed amount);

    // Emits data re Lender withdraws interest - there is no corresponding function, just withdraw()
    event WithdrawProfit(bytes32 indexed id, uint256 indexed amount);

    // Emitted when any credit line is closed by the line's borrower or the position's lender
    event CloseCreditPosition(bytes32 indexed id);

    // After accrueInterest runs, emits the amount of interest added to a Borrower's outstanding balance of interest due
    // but not yet repaid to the Line of Credit contract
    event InterestAccrued(bytes32 indexed id, uint256 indexed amount);

    // Borrower Events

    // receive full line or drawdown on credit
    event Borrow(bytes32 indexed id, uint256 indexed amount);

    // Emits that a Borrower has repaid an amount of interest Results in an increase in interestRepaid, i.e. interest not yet withdrawn by a Lender). There is no corresponding function
    event RepayInterest(bytes32 indexed id, uint256 indexed amount);

    // Emits that a Borrower has repaid an amount of principal - there is no corresponding function
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
    error PositionIsClosed();
    error RepayAmountExceedsDebt(uint256 totalAvailable);
    error CantStepQ();
    error EthSupportDisabled();
    error BorrowFailed();

    // Fully public functions

    function init() external returns (LineLib.STATUS);

    // MutualConsent functions

    /**
    * @notice        - On first call, creates proposed terms and emits MutualConsentRegistsered event. No position is created.
                      - On second call, creates position and stores in Line contract, sets interest rates, and starts accruing facility rate fees.
    * @dev           - Requires mutualConsent participants send EXACT same params when calling addCredit
    * @dev           - Fully executes function after a Borrower and a Lender have agreed terms, both Lender and borrower have agreed through mutualConsent
    * @dev           - callable by `lender` and `borrower`
    * @param drate   - The interest rate charged to a Borrower on borrowed / drawn down funds. In bps, 4 decimals.
    * @param frate   - The interest rate charged to a Borrower on the remaining funds available, but not yet drawn down 
                        (rate charged on the available headroom). In bps, 4 decimals.
    * @param amount  - The amount of Credit Token to initially deposit by the Lender
    * @param token   - The Credit Token, i.e. the token to be lent out
    * @param lender  - The address that will manage credit line
    * @return id     - Lender's position id to look up in `credits`
  */
    function addCredit(
        uint128 drate,
        uint128 frate,
        uint256 amount,
        address token,
        address lender
    ) external payable returns (bytes32);

    /**
     * @notice           - lets Lender and Borrower update rates on the lender's position
     *                   - accrues interest before updating terms, per InterestRate docs
     *                   - can do so even when LIQUIDATABLE for the purpose of refinancing and/or renego
     * @dev              - callable by Borrower or Lender
     * @param id         - position id that we are updating
     * @param drate      - new drawn rate. In bps, 4 decimals
     * @param frate      - new facility rate. In bps, 4 decimals
     * @return - if function executed successfully
     */
    function setRates(bytes32 id, uint128 drate, uint128 frate) external returns (bool);

    /**
     * @notice           - Lets a Lender and a Borrower increase the credit limit on a position
     * @dev              - line status must be ACTIVE
     * @dev              - callable by borrower
     * @dev              - The function retains the `payable` designation, despite not accepting Eth via mutualConsent modifier, as a gas-optimization
     * @param id         - position id that we are updating
     * @param amount     - amount to deposit by the Lender
     * @return - if function executed successfully
     */
    function increaseCredit(bytes32 id, uint256 amount) external payable returns (bool);

    // Borrower functions

    /**
     * @notice       - Borrower chooses which lender position draw down on and transfers tokens from Line contract to Borrower
     * @dev          - callable by borrower
     * @param id     - the position to draw down on
     * @param amount - amount of tokens the borrower wants to withdraw
     * @return - if function executed successfully
     */
    function borrow(bytes32 id, uint256 amount) external returns (bool);

    /**
     * @notice       - Transfers token used in position id from msg.sender to Line contract.
     * @dev          - Available for anyone to deposit Credit Tokens to be available to be withdrawn by Lenders
     * @dev          - The function retains the `payable` designation, despite reverting with a non-zero msg.value, as a gas-optimization
     * @notice       - see LineOfCredit._repay() for more details
     * @param amount - amount of `token` in `id` to pay back
     * @return - if function executed successfully
     */
    function depositAndRepay(uint256 amount) external payable returns (bool);

    /**
     * @notice       - A Borrower deposits enough tokens to repay and close a credit line.
     * @dev          - callable by borrower
     * @dev          - The function retains the `payable` designation, despite reverting with a non-zero msg.value, as a gas-optimization
     * @return - if function executed successfully
     */
    function depositAndClose() external payable returns (bool);

    /**
     * @notice - Removes and deletes a position, preventing any more borrowing or interest.
     *         - Requires that the position principal has already been repais in full
     * @dev      - MUST repay accrued interest from facility fee during call
     * @dev - callable by `borrower` or Lender
     * @dev          - The function retains the `payable` designation, despite reverting with a non-zero msg.value, as a gas-optimization
     * @param id -the position id to be closed
     * @return - if function executed successfully
     */
    function close(bytes32 id) external payable returns (bool);

    // Lender functions

    /**
     * @notice - Withdraws liquidity from a Lender's position available to the Borrower.
     *         - Lender is only allowed to withdraw tokens not already lent out
     *         - Withdraws from repaid interest (profit) first and then deposit is reduced
     * @dev - can only withdraw tokens from their own position. If multiple lenders lend DAI, the lender1 can't withdraw using lender2's tokens
     * @dev - callable by Lender on `id`
     * @param id - the position id that Lender is withdrawing from
     * @param amount - amount of tokens the Lender would like to withdraw (withdrawn amount may be lower)
     * @return - if function executed successfully
     */
    function withdraw(bytes32 id, uint256 amount) external returns (bool);

    // Arbiter functions
    /**
     * @notice - Allow the Arbiter to signify that the Borrower is incapable of repaying debt permanently.
     *         - Recoverable funds for Lender after declaring insolvency = deposit + interestRepaid - principal
     * @dev    - Needed for onchain impairment accounting e.g. updating ERC4626 share price
     *         - MUST NOT have collateral left for call to succeed. Any collateral must already have been liquidated.
     * @dev    - Callable only by Arbiter.
     * @return bool - If Borrower has been declared insolvent or not
     */
    function declareInsolvent() external returns (bool);

    /**
     *
     * @notice - Updates accrued interest for the whole Line of Credit facility (i.e. for all credit lines)
     * @dev    - Loops over all position ids and calls related internal functions during which InterestRateCredit.sol
     *           is called with the id data and then 'interestAccrued' is updated.
     * @dev    - The related internal function _accrue() is called by other functions any time the balance on an individual
     *           credit line changes or if the interest rates of a credit line are changed by mutual consent
     *           between a Borrower and a Lender.
     * @return - if function executed successfully
     */
    function accrueInterest() external returns (bool);

    function healthcheck() external returns (LineLib.STATUS);

    /**
     * @notice - Cycles through position ids andselects first position with non-null principal to the zero index
     * @dev - Only works if the first element in the queue is null
     * @return bool - if call suceeded or not
     */
    function stepQ() external returns (bool);

    /**
     * @notice - Returns the total debt of a Borrower across all positions for all Lenders.
     * @dev    - Denominated in USD, 8 decimals.
     * @dev    - callable by anyone
     * @return totalPrincipal - total amount of principal, in USD, owed across all positions
     * @return totalInterest - total amount of interest, in USD,  owed across all positions
     */
    function updateOutstandingDebt() external returns (uint256, uint256);

    // State getters

    function status() external returns (LineLib.STATUS);

    function borrower() external returns (address);

    function arbiter() external returns (address);

    function oracle() external returns (IOracle);

    /**
     * @notice - getter for amount of active ids + total ids in list
     * @return - (uint256, uint256) - active credit lines, total length
     */
    function counts() external view returns (uint256, uint256);
    /**
     * @notice - getter for amount of active ids + total ids in list
     * @return - (uint256, uint256) - active credit lines, total length
     */

    function interestAccrued(bytes32 id) external returns (uint256);
       /**
     * @notice - info on the next lender position that must be repaid
     * @return - (bytes32, address, address, uint, uint) - id, lender, token, principal, interestAccrued
     */
    function nextInQ() external returns (bytes32, address, address, uint256, uint256);

    /**
     * @notice - how many tokens can be withdrawn from positions by borrower or lender
     * @return - (uint256, uint256) - remaining deposit, claimable interest 
     */
    function available(bytes32 id) external returns (uint256, uint256);
}

pragma solidity 0.8.9;

interface IOracle {
    /** current price for token asset. denominated in USD */
    function getLatestAnswer(address token) external returns (int);

    /** Readonly function providing the current price for token asset. denominated in USD */
    function _getLatestAnswer(address token) external view returns (int);
}

pragma solidity ^0.8.9;

interface ISpigot {
    struct Setting {
        uint8 ownerSplit; // x/100 % to Owner, rest to Operator
        bytes4 claimFunction; // function signature on contract to call and claim revenue
        bytes4 transferOwnerFunction; // function signature on contract to call and transfer ownership
    }

    // Spigot Events
    event AddSpigot(address indexed revenueContract, uint256 ownerSplit, bytes4 claimFnSig, bytes4 trsfrFnSig);

    event RemoveSpigot(address indexed revenueContract, address token);

    event UpdateWhitelistFunction(bytes4 indexed func, bool indexed allowed);

    event UpdateOwnerSplit(address indexed revenueContract, uint8 indexed split);

    event ClaimRevenue(address indexed token, uint256 indexed amount, uint256 escrowed, address revenueContract);

    event ClaimOwnerTokens(address indexed token, uint256 indexed amount, address owner);

    event ClaimOperatorTokens(address indexed token, uint256 indexed amount, address operator);

    // Stakeholder Events

    event UpdateOwner(address indexed newOwner);

    event UpdateOperator(address indexed newOperator);

    // Errors
    error BadFunction();

    error OperatorFnNotWhitelisted();

    error OperatorFnNotValid();

    error OperatorFnCallFailed();

    error ClaimFailed();

    error NoRevenue();

    error UnclaimedRevenue();

    error CallerAccessDenied();

    error BadSetting();

    error InvalidRevenueContract();

    // ops funcs

    function claimRevenue(
        address revenueContract,
        address token,
        bytes calldata data
    ) external returns (uint256 claimed);

    function operate(address revenueContract, bytes calldata data) external returns (bool);

    // owner funcs

    function claimOwnerTokens(address token) external returns (uint256 claimed);

    function claimOperatorTokens(address token) external returns (uint256 claimed);

    function addSpigot(address revenueContract, Setting memory setting) external returns (bool);

    function removeSpigot(address revenueContract) external returns (bool);

    // stakeholder funcs

    function updateOwnerSplit(address revenueContract, uint8 ownerSplit) external returns (bool);

    function updateOwner(address newOwner) external returns (bool);

    function updateOperator(address newOperator) external returns (bool);

    function updateWhitelistedFunction(bytes4 func, bool allowed) external returns (bool);

    // Getters
    function owner() external view returns (address);

    function operator() external view returns (address);

    function isWhitelisted(bytes4 func) external view returns (bool);

    function getOwnerTokens(address token) external view returns (uint256);

    function getOperatorTokens(address token) external view returns (uint256);

    function getSetting(
        address revenueContract
    ) external view returns (uint8 split, bytes4 claimFunc, bytes4 transferFunc);
}

pragma solidity 0.8.9;
import {IInterestRateCredit} from "../interfaces/IInterestRateCredit.sol";
import {ILineOfCredit} from "../interfaces/ILineOfCredit.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {Denominations} from "chainlink/Denominations.sol";

/**
 * @title Debt DAO Line of Credit Library
 * @author Kiba Gateaux
 * @notice Core logic and variables to be reused across all Debt DAO Marketplace Line of Credit contracts
 */
library LineLib {
    using SafeERC20 for IERC20;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet WETH

    error EthSentWithERC20();
    error TransferFailed();
    error SendingEthFailed();
    error RefundEthFailed();

    error BadToken();

    event RefundIssued(address indexed recipient, uint256 value);

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
    function sendOutTokenOrETH(address token, address receiver, uint256 amount) external returns (bool) {
        if (token == address(0)) {
            revert TransferFailed();
        }

        // both branches revert if call failed
        if (token != Denominations.ETH) {
            // ERC20
            IERC20(token).safeTransfer(receiver, amount);
        } else {
            // ETH
            bool success = _safeTransferFunds(receiver, amount);
            if (!success) {
                revert SendingEthFailed();
            }
        }
        return true;
    }

    /**
     * @notice - Receive ETH or ERC20 token at this contract from an external contract
     * @dev    - If the sender overpays, the difference will be refunded to the sender
     * @dev    - If the sender is unable to receive the refund, it will be diverted to the calling contract
     * @param token - address of token to receive. Denominations.ETH for raw ETH
     * @param sender - address that is sendingtokens/ETH
     * @param amount - amount of tokens to send
     */
    function receiveTokenOrETH(address token, address sender, uint256 amount) external returns (bool) {
        if (token == address(0)) {
            revert TransferFailed();
        }
        if (token != Denominations.ETH) {
            // ERC20
            if (msg.value != 0) {
                revert EthSentWithERC20();
            }
            IERC20(token).safeTransferFrom(sender, address(this), amount);
        } else {
            // ETH
            if (msg.value < amount) {
                revert TransferFailed();
            }

            if (msg.value > amount) {
                uint256 refund = msg.value - amount;

                if (_safeTransferFunds(msg.sender, refund)) {
                    emit RefundIssued(msg.sender, refund);
                }
            }
        }
        return true;
    }

    /**
     * @notice - Helper function to get current balance of this contract for ERC20 or ETH
     * @param token - address of token to check. Denominations.ETH for raw ETH
     */
    function getBalance(address token) external view returns (uint256) {
        if (token == address(0)) return 0;
        return token != Denominations.ETH ? IERC20(token).balanceOf(address(this)) : address(this).balance;
    }

    /**
     * @notice  - Helper function to safely transfer Eth using native call
     * @dev     - Errors should be handled in the calling function
     * @param recipient - address of the recipient
     * @param value - value to be sent (in wei)
     */
    function _safeTransferFunds(address recipient, uint256 value) internal returns (bool success) {
        (success, ) = payable(recipient).call{value: value}("");
    }
}

pragma solidity 0.8.9;

import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {LineLib} from "../utils/LineLib.sol";
import {ISpigot} from "../interfaces/ISpigot.sol";

struct SpigotState {
    /// @notice Economic owner of Spigot revenue streams
    address owner;
    /// @notice account in charge of running onchain ops of spigoted contracts on behalf of owner
    address operator;
    /// @notice Total amount of revenue tokens help by the Spigot and available to be claimed by owner
    mapping(address => uint256) ownerTokens;      // token -> claimable
    /// @notice Total amount of revenue tokens help by the Spigot and available to be claimed by operator
    mapping(address => uint256) operatorTokens;   // token -> claimable
    /// @notice Functions that the operator is allowed to run on all revenue contracts controlled by the Spigot
    mapping(bytes4 => bool) whitelistedFunctions; // function -> allowed
    /// @notice Configurations for revenue contracts related to the split of revenue, access control to claiming revenue tokens and transfer of Spigot ownership
    mapping(address => ISpigot.Setting) settings; // revenue contract -> settings
}

/**
 * @notice - helper lib for Spigot
 * @dev see Spigot docs
 */
library SpigotLib {
    // Maximum numerator for Setting.ownerSplit param to ensure that the Owner can't claim more than 100% of revenue
    uint8 constant MAX_SPLIT = 100;
    // cap revenue per claim to avoid overflows on multiplication when calculating percentages
    uint256 constant MAX_REVENUE = type(uint256).max / MAX_SPLIT;

    function _claimRevenue(
        SpigotState storage self,
        address revenueContract,
        address token,
        bytes calldata data
    ) public returns (uint256 claimed) {
        if (self.settings[revenueContract].transferOwnerFunction == bytes4(0)) {
            revert InvalidRevenueContract();
        }

        uint256 existingBalance = LineLib.getBalance(token);

        if (self.settings[revenueContract].claimFunction == bytes4(0)) {
            // push payments

            // TODO: test this with multiple revenue streams

            // claimed = total balance - already accounted for balance
            claimed = existingBalance - self.ownerTokens[token];
            // underflow revert ensures we have more tokens than we started with and actually claimed revenue
        } else {
            // pull payments
            if (bytes4(data) != self.settings[revenueContract].claimFunction) {
                revert BadFunction();
            }
            (bool claimSuccess, ) = revenueContract.call(data);
            if (!claimSuccess) {
                revert ClaimFailed();
            }

            // claimed = total balance - existing balance
            claimed = LineLib.getBalance(token) - existingBalance;
            // underflow revert ensures we have more tokens than we started with and actually claimed revenue
        }

        if (claimed == 0) {
            revert NoRevenue();
        }

        // cap so uint doesnt overflow in split calculations.
        // can sweep by "attaching" a push payment spigot with same token
        if (claimed > MAX_REVENUE) claimed = MAX_REVENUE;

        return claimed;
    }

    /** see Spigot.claimRevenue */
    function claimRevenue(
        SpigotState storage self,
        address revenueContract,
        address token,
        bytes calldata data
    ) external returns (uint256 claimed) {
        claimed = _claimRevenue(self, revenueContract, token, data);

        // splits revenue stream according to Spigot settings
        uint256 ownerTokens = (claimed * self.settings[revenueContract].ownerSplit) / 100;
        // update escrowed balance
        self.ownerTokens[token] = self.ownerTokens[token] + ownerTokens;

        // update operator amount
        if (claimed > ownerTokens) {
            self.operatorTokens[token] = self.operatorTokens[token] + (claimed - ownerTokens);
        }

        emit ClaimRevenue(token, claimed, ownerTokens, revenueContract);

        return claimed;
    }

        /** see Spigot.operate */
    function operate(SpigotState storage self, address revenueContract, bytes calldata data) external returns (bool) {
        if (msg.sender != self.operator) {
            revert CallerAccessDenied();
        }

        // extract function signature from tx data and check whitelist
        bytes4 func = bytes4(data);

        if (!self.whitelistedFunctions[func]) {
            revert OperatorFnNotWhitelisted();
        }

        // cant claim revenue via operate() because that fucks up accounting logic. Owner shouldn't whitelist it anyway but just in case
        // also can't transfer ownership so Owner retains control of revenue contract
        if (
            func == self.settings[revenueContract].claimFunction ||
            func == self.settings[revenueContract].transferOwnerFunction
        ) {
            revert OperatorFnNotValid();
        }

        (bool success, ) = revenueContract.call(data);
        if (!success) {
            revert OperatorFnCallFailed();
        }

        return true;
    }

    /** see Spigot.claimOwnerTokens */
    function claimOwnerTokens(SpigotState storage self, address token) external returns (uint256 claimed) {
        if (msg.sender != self.owner) {
            revert CallerAccessDenied();
        }

        claimed = self.ownerTokens[token];

        if (claimed == 0) {
            revert ClaimFailed();
        }

        self.ownerTokens[token] = 0; // reset before send to prevent reentrancy

        LineLib.sendOutTokenOrETH(token, self.owner, claimed);

        emit ClaimOwnerTokens(token, claimed, self.owner);

        return claimed;
    }

    /** see Spigot.claimOperatorTokens */
    function claimOperatorTokens(SpigotState storage self, address token) external returns (uint256 claimed) {
        if (msg.sender != self.operator) {
            revert CallerAccessDenied();
        }

        claimed = self.operatorTokens[token];

        if (claimed == 0) {
            revert ClaimFailed();
        }

        self.operatorTokens[token] = 0; // reset before send to prevent reentrancy

        LineLib.sendOutTokenOrETH(token, self.operator, claimed);

        emit ClaimOperatorTokens(token, claimed, self.operator);

        return claimed;
    }

    /** see Spigot.addSpigot */
    function addSpigot(
        SpigotState storage self,
        address revenueContract,
        ISpigot.Setting memory setting
    ) external returns (bool) {
        if (msg.sender != self.owner) {
            revert CallerAccessDenied();
        }

        if (revenueContract == address(this)) {
            revert InvalidRevenueContract();
        }

        // spigot setting already exists
        if (self.settings[revenueContract].transferOwnerFunction != bytes4(0)) {
            revert SpigotSettingsExist();
        }

        // must set transfer func
        if (setting.transferOwnerFunction == bytes4(0)) {
            revert BadSetting();
        }
        if (setting.ownerSplit > MAX_SPLIT) {
            revert BadSetting();
        }

        self.settings[revenueContract] = setting;
        emit AddSpigot(revenueContract, setting.ownerSplit, setting.claimFunction, setting.transferOwnerFunction);

        return true;
    }

    /** see Spigot.removeSpigot */
    function removeSpigot(SpigotState storage self, address revenueContract) external returns (bool) {
        if (msg.sender != self.owner) {
            revert CallerAccessDenied();
        }

        (bool success, ) = revenueContract.call(
            abi.encodeWithSelector(
                self.settings[revenueContract].transferOwnerFunction,
                self.operator // assume function only takes one param that is new owner address
            )
        );
        require(success);

        delete self.settings[revenueContract];
        emit RemoveSpigot(revenueContract);

        return true;
    }

    /** see Spigot.updateOwnerSplit */
    function updateOwnerSplit(
        SpigotState storage self,
        address revenueContract,
        uint8 ownerSplit
    ) external returns (bool) {
        if (msg.sender != self.owner) {
            revert CallerAccessDenied();
        }
        if (ownerSplit > MAX_SPLIT) {
            revert BadSetting();
        }

        self.settings[revenueContract].ownerSplit = ownerSplit;
        emit UpdateOwnerSplit(revenueContract, ownerSplit);

        return true;
    }

    /** see Spigot.updateOwner */
    function updateOwner(SpigotState storage self, address newOwner) external returns (bool) {
        if (msg.sender != self.owner) {
            revert CallerAccessDenied();
        }
        require(newOwner != address(0));
        self.owner = newOwner;
        emit UpdateOwner(newOwner);
        return true;
    }

    /** see Spigot.updateOperator */
    function updateOperator(SpigotState storage self, address newOperator) external returns (bool) {
        if (msg.sender != self.operator && msg.sender != self.owner) {
            revert CallerAccessDenied();
        }
        require(newOperator != address(0));
        self.operator = newOperator;
        emit UpdateOperator(newOperator);
        return true;
    }

    /** see Spigot.updateWhitelistedFunction*/
    function updateWhitelistedFunction(SpigotState storage self, bytes4 func, bool allowed) external returns (bool) {
        if (msg.sender != self.owner) {
            revert CallerAccessDenied();
        }
        self.whitelistedFunctions[func] = allowed;
        emit UpdateWhitelistFunction(func, allowed);
        return true;
    }

    /** see Spigot.isWhitelisted*/
    function isWhitelisted(SpigotState storage self, bytes4 func) external view returns (bool) {
        return self.whitelistedFunctions[func];
    }

    /** see Spigot.getSetting*/
    function getSetting(
        SpigotState storage self,
        address revenueContract
    ) external view returns (uint8, bytes4, bytes4) {
        return (
            self.settings[revenueContract].ownerSplit,
            self.settings[revenueContract].claimFunction,
            self.settings[revenueContract].transferOwnerFunction
        );
    }

    // Spigot Events
    event AddSpigot(address indexed revenueContract, uint256 ownerSplit, bytes4 claimFnSig, bytes4 trsfrFnSig);

    event RemoveSpigot(address indexed revenueContract);

    event UpdateWhitelistFunction(bytes4 indexed func, bool indexed allowed);

    event UpdateOwnerSplit(address indexed revenueContract, uint8 indexed split);

    event ClaimRevenue(address indexed token, uint256 indexed amount, uint256 ownerTokens, address revenueContract);

    event ClaimOwnerTokens(address indexed token, uint256 indexed amount, address owner);

    event ClaimOperatorTokens(address indexed token, uint256 indexed amount, address ooperator);

    // Stakeholder Events

    event UpdateOwner(address indexed newOwner);

    event UpdateOperator(address indexed newOperator);

    event UpdateTreasury(address indexed newTreasury);

    // Errors

    error BadFunction();

    error OperatorFnNotWhitelisted();

    error OperatorFnNotValid();

    error OperatorFnCallFailed();

    error ClaimFailed();

    error NoRevenue();

    error UnclaimedRevenue();

    error CallerAccessDenied();

    error BadSetting();

    error InvalidRevenueContract();

    error SpigotSettingsExist();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}