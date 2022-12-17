pragma solidity 0.8.9;

interface IEscrow {
    struct Deposit {
        uint amount;
        bool isERC4626;
        address asset; // eip4626 asset else the erc20 token itself
        uint8 assetDecimals;
    }

    event AddCollateral(address indexed token, uint indexed amount);

    event RemoveCollateral(address indexed token, uint indexed amount);

    event EnableCollateral(address indexed token);

    error InvalidCollateral();

    error CallerAccessDenied();

    error UnderCollateralized();

    error NotLiquidatable();

    // State var getters.

    function line() external returns (address);

    function oracle() external returns (address);

    function borrower() external returns (address);

    function minimumCollateralRatio() external returns (uint32);

    // Functions

    function isLiquidatable() external returns (bool);

    function updateLine(address line_) external returns (bool);

    function getCollateralRatio() external returns (uint);

    function getCollateralValue() external returns (uint);

    function enableCollateral(address token) external returns (bool);

    function addCollateral(uint amount, address token) external payable returns (uint);

    function releaseCollateral(uint amount, address token, address to) external returns (uint);

    function liquidate(uint amount, address token, address to) external returns (bool);
}

pragma solidity 0.8.9;

import {IEscrow} from "./IEscrow.sol";

interface IEscrowedLine {
    event Liquidate(bytes32 indexed id, uint256 indexed amount, address indexed token, address escrow);

    function liquidate(uint256 amount, address targetToken) external returns (uint256);

    function escrow() external returns (IEscrow);
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

interface ILineFactory {
    struct CoreLineParams {
        address borrower;
        uint256 ttl;
        uint32 cratio;
        uint8 revenueSplit;
    }

    event DeployedSecuredLine(
        address indexed deployedAt,
        address indexed escrow,
        address indexed spigot,
        address swapTarget,
        uint8 revenueSplit
    );

    error ModuleTransferFailed(address line, address spigot, address escrow);
    error InvalidRevenueSplit();
    error InvalidOracleAddress();
    error InvalidSwapTargetAddress();
    error InvalidArbiterAddress();
    error InvalidEscrowAddress();
    error InvalidSpigotAddress();

    function deployEscrow(uint32 minCRatio, address owner, address borrower) external returns (address);

    function deploySpigot(address owner, address operator) external returns (address);

    function deploySecuredLine(address borrower, uint256 ttl) external returns (address);

    function deploySecuredLineWithConfig(CoreLineParams calldata coreParams) external returns (address);

    function deploySecuredLineWithModules(
        CoreLineParams calldata coreParams,
        address mSpigot,
        address mEscrow
    ) external returns (address);

    function rolloverSecuredLine(address payable oldLine, address borrower, uint256 ttl) external returns (address);
}

pragma solidity 0.8.9;

import {LineLib} from "../utils/LineLib.sol";
import {IOracle} from "../interfaces/IOracle.sol";

interface ILineOfCredit {
    // Lender data
    struct Credit {
        //  all denominated in token, not USD
        uint256 deposit; // The total liquidity provided by a Lender in a given token on a Line of Credit
        uint256 principal; // The amount of a Lender's Deposit on a Line of Credit that has actually been drawn down by the Borrower (USD)
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
     * @notice       - see LineOfCredit._repay() for more details
     * @param amount - amount of `token` in `id` to pay back
     * @return - if function executed successfully
     */
    function depositAndRepay(uint256 amount) external payable returns (bool);

    /**
     * @notice       - A Borrower deposits enough tokens to repay and close a credit line.
     * @dev          - callable by borrower
     * @return - if function executed successfully
     */
    function depositAndClose() external payable returns (bool);

    /**
     * @notice - Removes and deletes a position, preventing any more borrowing or interest.
     *         - Requires that the position principal has already been repais in full
     * @dev      - MUST repay accrued interest from facility fee during call
     * @dev - callable by `borrower` or Lender
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
     * @return - (uint, uint) - active credit lines, total length
     */
    function counts() external view returns (uint256, uint256);
}

pragma solidity 0.8.9;

interface IModuleFactory {
    event DeployedSpigot(address indexed deployedAt, address indexed owner, address operator);

    event DeployedEscrow(address indexed deployedAt, uint32 indexed minCRatio, address indexed oracle, address owner);

    function deploySpigot(address owner, address operator) external returns (address);

    function deployEscrow(uint32 minCRatio, address oracle, address owner, address borrower) external returns (address);
}

pragma solidity 0.8.9;

interface IOracle {
    /** current price for token asset. denominated in USD */
    function getLatestAnswer(address token) external returns (int);
}

pragma solidity 0.8.9;

import {IEscrowedLine} from "./IEscrowedLine.sol";
import {ISpigotedLine} from "./ISpigotedLine.sol";

interface ISecuredLine is IEscrowedLine, ISpigotedLine {
    // Rollover
    error DebtOwed();
    error BadNewLine();
    error BadRollover();

    // Borrower functions

    /**
     * @notice - helper function to allow Borrower to easily transfer settings and collateral from this line to a new line
     *         - usefull after ttl has expired and want to renew Line with minimal effort
     * @dev    - transfers Spigot and Escrow ownership to newLine. Arbiter functions on this Line will no longer work
     * @param newLine - the new, uninitialized Line deployed by borrower
     * @return success - if
     */
    function rollover(address newLine) external returns (bool);
}

pragma solidity ^0.8.9;

interface ISpigot {
    struct Setting {
        uint8 ownerSplit; // x/100 % to Owner, rest to Operator
        bytes4 claimFunction; // function signature on contract to call and claim revenue
        bytes4 transferOwnerFunction; // function signature on contract to call and transfer ownership
    }

    // Spigot Events

    event AddSpigot(address indexed revenueContract, uint256 ownerSplit);

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

pragma solidity ^0.8.9;

import {ISpigot} from "./ISpigot.sol";

interface ISpigotedLine {
    // @notice Log how many revenue tokens are used to repay debt after claimAndRepay
    // dont need to track value like other events because _repay already emits that
    // Mainly used to log debt that is paid via Spigot directly vs other sources. Without this event it's a lot harder to parse that offchain.
    event RevenuePayment(address indexed token, uint256 indexed amount);

    error ReservesOverdrawn(uint256 totalAvailable);

    // @notice Log many revenue tokens were traded for credit tokens.
    // @notice differs from Revenue Payment because we trade revenue at different times from repaying with revenue
    // @dev Can you use to figure out price of revenue tokens offchain since we only have an oracle for credit tokens
    // @dev Revenue tokens might be reserves or just claimed from Spigot.
    event TradeSpigotRevenue(
        address indexed revenueToken,
        uint256 revenueTokenAmount,
        address indexed debtToken,
        uint256 indexed debtTokensBought
    );

    // Borrower functions

    /**
     * @notice - Directly repays a Lender using unused tokens already held by Line with no trading
     * @param amount - amount of unused tokens to use to repay Lender
     * @return - if function executed successfully
     */
    function useAndRepay(uint256 amount) external returns (bool);

    /**
    * @notice - Claims revenue tokens from the Spigot, trades them for credit tokens via a Dex aggregator (Ox protocol) and uses the bought credit tokens to repay debt.
              - see SpigotedLine._claimAndTrade and SpigotedLineLib.claimAndTrade for more details on Spigot and trading logic
    *         - see LineOfCredit._repay() for more details on repayment logic
    * @dev    - does not trade asset if claimToken = credit.token
    * @dev    - non-rentrant
    * @dev    - callable `borrower` + `lender`
    * @param claimToken - The Revenue Token escrowed by Spigot to claim and use to repay debt
    * @param zeroExTradeData - data generated by the 0x dex API to trade `claimToken` against their exchange contract
    * @return newTokens - amount of credit tokens claimed or bought during call
    */
    function claimAndRepay(address claimToken, bytes calldata zeroExTradeData) external returns (uint256);

    /**
     *
     * @notice  - allows borrower to trade revenue to credit tokens at a favorable price without repaying debt
                - sends all bought tokens to `unused` to be repaid later
     *          - see SpigotedLine._claimAndTrade and SpigotedLineLib.claimAndTrade for more details
     * @dev    - ensures first token in repayment queue is being bought
     * @dev    - non-rentrant
     * @dev    - callable by `borrower`
     * @param claimToken - The revenue token escrowed in the Spigot to sell in trade
     * @param zeroExTradeData - 0x API data to use in trade to sell `claimToken` for `credits[ids[0]]`
     * @return tokensBought - amount of credit tokens bought
     */
    function claimAndTrade(address claimToken, bytes calldata zeroExTradeData) external returns (uint256 tokensBought);

    // Spigot management functions

    /**
     * @notice - allow Line (Owner on Spigot) to add new revenue streams to repay credit
     *         - Requires mutualConsent between `borrower` and `arbiter`
     * @dev    - see Spigot.addSpigot()
     * @dev    - callable `arbiter` + `borrower`
     * @return - if function call was successful
     */
    function addSpigot(address revenueContract, ISpigot.Setting calldata setting) external returns (bool);

    /**
     * @notice - Sets or resets the whitelisted functions that a Borrower [Operator] is allowed to perform on the revenue generating contracts
     * @dev    - see Spigot.updateWhitelistedFunction()
     * @dev    - callable `arbiter` ONLY
     * @return - if function call was successful
     */
    function updateWhitelist(bytes4 func, bool allowed) external returns (bool);

    /**
     * @notice Changes the revenue split between the Treasury and the Line (Owner) based upon the status of the Line of Credit
     * @dev    - callable `arbiter` + `borrower`
     * @param revenueContract - spigot to update
     * @return didUpdate - whether or not split was updated
     */
    function updateOwnerSplit(address revenueContract) external returns (bool);

    /**
    * @notice - Transfers ownership of the entire Spigot from its then Owner to either the Borrower (if a Line of Credit has been been fully repaid) 
                or to the Arbiter (if the Line of Credit is liquidatable).
    * @dev    - callable by borrower + arbiter
    * @param to - address that caller wants to transfer Spigot ownership to
    * @return - whether or not a Spigot was released
    */
    function releaseSpigot(address to) external returns (bool);

    /**
   * @notice - sends unused tokens to borrower if REPAID or arbiter if LIQUIDATABLE or INSOLVENT
             -  does not send tokens out if line is ACTIVE
   * @dev    - callable by anyone 
   * @param token - token to take out
  */
    function sweep(address to, address token) external returns (uint256);

    // getters

    /**
     * @notice getter for `unusedTokens` mapping which is a private var
     * @param token - address for an ERC20
     * @return amount - amount of revenue tokens available to trade for fcredit tokens or credit tokens availble to repay debt with
     */
    function unused(address token) external returns (uint256);

    function spigot() external returns (ISpigot);
}

pragma solidity 0.8.9;

import {IEscrow} from "../../interfaces/IEscrow.sol";
import {LineLib} from "../../utils/LineLib.sol";
import {IEscrowedLine} from "../../interfaces/IEscrowedLine.sol";
import {ILineOfCredit} from "../../interfaces/ILineOfCredit.sol";

// used for importing NATSPEC docs, not used
import {LineOfCredit} from "./LineOfCredit.sol";

// import { SecuredLine } from "./SecuredLine.sol";

abstract contract EscrowedLine is IEscrowedLine, ILineOfCredit {
    // contract holding all collateral for borrower
    IEscrow public immutable escrow;

    constructor(address _escrow) {
        escrow = IEscrow(_escrow);
    }

    /**
     * see LineOfCredit._init and SecuredLine.init
     * @notice requires this Line is owner of the Escrowed collateral else Line will not init
     */
    function _init() internal virtual returns (LineLib.STATUS) {
        if (escrow.line() != address(this)) return LineLib.STATUS.UNINITIALIZED;
        return LineLib.STATUS.ACTIVE;
    }

    /**
     * see LineOfCredit._healthcheck and SecuredLine._healthcheck
     * @notice returns LIQUIDATABLE if Escrow contract is undercollateralized, else returns ACTIVE
     */
    function _healthcheck() internal virtual returns (LineLib.STATUS) {
        if (escrow.isLiquidatable()) {
            return LineLib.STATUS.LIQUIDATABLE;
        }

        return LineLib.STATUS.ACTIVE;
    }

    /**
     * see SecuredlLine.liquidate
     * @notice sends escrowed tokens to liquidation.
     * @dev priviliegad function. Do checks before calling.
     *
     * @param id - The credit line being repaid via the liquidation
     * @param amount - amount of tokens to take from escrow and liquidate
     * @param targetToken - the token to take from escrow
     * @param to - the liquidator to send tokens to. could be OTC address or smart contract
     *
     * @return amount - the total amount of `targetToken` sold to repay credit
     */
    function _liquidate(
        bytes32 id,
        uint256 amount,
        address targetToken,
        address to
    ) internal virtual returns (uint256) {
        IEscrow escrow_ = escrow; // gas savings
        require(escrow_.liquidate(amount, targetToken, to));

        emit Liquidate(id, amount, targetToken, address(escrow_));

        return amount;
    }

    /**
     * see SecuredLine.declareInsolvent
     * @notice require all collateral sold off before declaring insolvent
     *(@dev priviliegad internal function.
     * @return isInsolvent - if Escrow contract is currently insolvent or not
     */
    function _canDeclareInsolvent() internal virtual returns (bool) {
        if (escrow.getCollateralValue() != 0) {
            revert NotInsolvent(address(escrow));
        }
        return true;
    }

    /**
     * see SecuredlLine.rollover
     * @notice helper function to allow borrower to easily swithc collateral to a new Line after repyment
     *(@dev priviliegad internal function.
     * @dev MUST only be callable if line is REPAID
     * @return - if function successfully executed
     */
    function _rollover(address newLine) internal virtual returns (bool) {
        require(escrow.updateLine(newLine));
        return true;
    }
}

pragma solidity ^0.8.9;

import {Denominations} from "chainlink/Denominations.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";

import {LineLib} from "../../utils/LineLib.sol";
import {CreditLib} from "../../utils/CreditLib.sol";
import {CreditListLib} from "../../utils/CreditListLib.sol";
import {MutualConsent} from "../../utils/MutualConsent.sol";
import {InterestRateCredit} from "../interest-rate/InterestRateCredit.sol";

import {IOracle} from "../../interfaces/IOracle.sol";
import {ILineOfCredit} from "../../interfaces/ILineOfCredit.sol";

contract LineOfCredit is ILineOfCredit, MutualConsent, ReentrancyGuard {
    using SafeERC20 for IERC20;

    using CreditListLib for bytes32[];

    uint256 public immutable deadline;

    address public immutable borrower;

    address public immutable arbiter;

    IOracle public immutable oracle;

    InterestRateCredit public immutable interestRate;

    uint256 private count; // amount of open credit lines on a Line of Credit facility. ids.length includes null items

    bytes32[] public ids; // all open credit lines

    mapping(bytes32 => Credit) public credits; // id -> Reference ID for a credit line provided by a single Lender for a given token on a Line of Credit

    // Line Financials aggregated accross all existing  Credit
    LineLib.STATUS public status;

    /**
     * @notice            - How to deploy a Line of Credit
     * @dev               - A Borrower and a first Lender agree on terms. Then the Borrower deploys the contract using the constructor below.
     *                      Later, both Lender and Borrower must call _mutualConsent() during addCredit() to actually enable funds to be deposited.
     * @param oracle_     - The price oracle to use for getting all token values.
     * @param arbiter_    - A neutral party with some special priviliges on behalf of Borrower and Lender.
     * @param borrower_   - The debitor for all credit lines in this contract.
     * @param ttl_        - The time to live for all credit lines for the Line of Credit facility (sets the maturity/term of the Line of Credit)
     */
    constructor(
        address oracle_,
        address arbiter_,
        address borrower_,
        uint256 ttl_
    ) {
        oracle = IOracle(oracle_);
        arbiter = arbiter_;
        borrower = borrower_;
        deadline = block.timestamp + ttl_; //the deadline is the term/maturity/expiry date of the Line of Credit facility
        interestRate = new InterestRateCredit();

        emit DeployLine(oracle_, arbiter_, borrower_);
    }

    function init() external virtual returns (LineLib.STATUS) {
        if (status != LineLib.STATUS.UNINITIALIZED) {
            revert AlreadyInitialized();
        }
        return _updateStatus(_init());
    }

    function _init() internal virtual returns (LineLib.STATUS) {
        // If no collateral or Spigot then Line of Credit is immediately active
        return LineLib.STATUS.ACTIVE;
    }

    ///////////////
    // MODIFIERS //
    ///////////////

    modifier whileActive() {
        if (status != LineLib.STATUS.ACTIVE) {
            revert NotActive();
        }
        _;
    }

    modifier whileBorrowing() {
        if (count == 0 || credits[ids[0]].principal == 0) {
            revert NotBorrowing();
        }
        _;
    }

    modifier onlyBorrower() {
        if (msg.sender != borrower) {
            revert CallerAccessDenied();
        }
        _;
    }

    /**
     * @notice - mutualConsent() but hardcodes borrower address and uses the position id to
                 get Lender address instead of passing it in directly
     * @param id - position to pull lender address from for mutual consent agreement
    */
    modifier mutualConsentById(bytes32 id) {
        if (_mutualConsent(borrower, credits[id].lender)) {
            // Run whatever code is needed for the 2/2 consent
            _;
        }
    }

    /**
     * @notice - evaluates all covenants encoded in _healthcheck from different Line variants
     * @dev - updates `status` variable in storage if current status is diferent from existing status
     * @return - current health status of Line
     */
    function healthcheck() external returns (LineLib.STATUS) {
        // can only check if the line has been initialized
        require(uint256(status) >= uint256(LineLib.STATUS.ACTIVE));
        return _updateStatus(_healthcheck());
    }

    /// see ILineOfCredit.counts
    function counts() external view returns (uint256, uint256) {
        return (count, ids.length);
    }

    function _healthcheck() internal virtual returns (LineLib.STATUS) {
        // if line is in a final end state then do not run _healthcheck()
        LineLib.STATUS s = status;
        if (
            s == LineLib.STATUS.REPAID || // end state - good
            s == LineLib.STATUS.INSOLVENT // end state - bad
        ) {
            return s;
        }

        // Liquidate if all credit lines aren't closed by deadline
        if (block.timestamp >= deadline && count > 0) {
            emit Default(ids[0]); // can query all defaulted positions offchain once event picked up
            return LineLib.STATUS.LIQUIDATABLE;
        }

        // if nothing wrong, return to healthy ACTIVE state
        return LineLib.STATUS.ACTIVE;
    }

    /// see ILineOfCredit.declareInsolvent
    function declareInsolvent() external returns (bool) {
        if (arbiter != msg.sender) {
            revert CallerAccessDenied();
        }
        if (LineLib.STATUS.LIQUIDATABLE != _updateStatus(_healthcheck())) {
            revert NotLiquidatable();
        }

        if (_canDeclareInsolvent()) {
            _updateStatus(LineLib.STATUS.INSOLVENT);
            return true;
        } else {
            return false;
        }
    }

    function _canDeclareInsolvent() internal virtual returns (bool) {
        // logic updated in Spigoted and Escrowed lines
        return true;
    }

    /// see ILineOfCredit.updateOutstandingDebt
    function updateOutstandingDebt() external override returns (uint256, uint256) {
        return _updateOutstandingDebt();
    }

    function _updateOutstandingDebt() internal returns (uint256 principal, uint256 interest) {
        // use full length not count because positions might not be packed in order
        uint256 len = ids.length;
        if (len == 0) return (0, 0);

        bytes32 id;
        address oracle_ = address(oracle); // gas savings
        address interestRate_ = address(interestRate); // gas savings

        for (uint256 i; i < len; ++i) {
            id = ids[i];

            // null element in array from closing a position. skip for gas savings
            if (id == bytes32(0)) {
                continue;
            }

            (Credit memory c, uint256 _p, uint256 _i) = CreditLib.getOutstandingDebt(
                credits[id],
                id,
                oracle_,
                interestRate_
            );
            // update total outstanding debt
            principal += _p;
            interest += _i;
            // save changes to storage
            credits[id] = c;
        }
    }

    /// see ILineOfCredit.accrueInterest
    function accrueInterest() external override returns (bool) {
        uint256 len = ids.length;
        bytes32 id;
        for (uint256 i; i < len; ++i) {
            id = ids[i];
            Credit memory credit = credits[id];
            credits[id] = _accrue(credit, id);
        }

        return true;
    }

    /**
      @notice - accrues token demoninated interest on a lender's position.
      @dev MUST call any time a position balance or interest rate changes
      @param credit - the lender position that is accruing interest
      @param id - the position id for credit position
    */
    function _accrue(Credit memory credit, bytes32 id) internal returns (Credit memory) {
        if (!credit.isOpen) {
            return credit;
        }
        return CreditLib.accrue(credit, id, address(interestRate));
    }

    /// see ILineOfCredit.addCredit
    function addCredit(
        uint128 drate,
        uint128 frate,
        uint256 amount,
        address token,
        address lender
    ) external payable override nonReentrant whileActive mutualConsent(lender, borrower) returns (bytes32) {
        LineLib.receiveTokenOrETH(token, lender, amount);

        bytes32 id = _createCredit(lender, token, amount);

        require(interestRate.setRate(id, drate, frate));

        emit SetRates(id, drate, frate);

        return id;
    }

    /// see ILineOfCredit.setRates
    function setRates(
        bytes32 id,
        uint128 drate,
        uint128 frate
    ) external override mutualConsentById(id) returns (bool) {
        Credit memory credit = credits[id];
        credits[id] = _accrue(credit, id);
        require(interestRate.setRate(id, drate, frate));
        emit SetRates(id, drate, frate);
        return true;
    }

    /// see ILineOfCredit.increaseCredit
    function increaseCredit(bytes32 id, uint256 amount)
        external
        payable
        override
        nonReentrant
        whileActive
        mutualConsentById(id)
        returns (bool)
    {
        Credit memory credit = credits[id];
        credit = _accrue(credit, id);

        credit.deposit += amount;

        credits[id] = credit;

        LineLib.receiveTokenOrETH(credit.token, credit.lender, amount);

        emit IncreaseCredit(id, amount);

        return true;
    }

    ///////////////
    // REPAYMENT //
    ///////////////

    /// see ILineOfCredit.depositAndClose
    function depositAndClose() external payable override nonReentrant whileBorrowing onlyBorrower returns (bool) {
        bytes32 id = ids[0];
        Credit memory credit = _accrue(credits[id], id);

        // Borrower deposits the outstanding balance not already repaid
        uint256 totalOwed = credit.principal + credit.interestAccrued;

        // Borrower clears the debt then closes the credit line
        credits[id] = _close(_repay(credit, id, totalOwed), id);

        LineLib.receiveTokenOrETH(credit.token, borrower, totalOwed);

        return true;
    }

    /// see ILineOfCredit.close
    function close(bytes32 id) external payable override nonReentrant onlyBorrower returns (bool) {
        Credit memory credit = _accrue(credits[id], id);

        uint256 facilityFee = credit.interestAccrued;
        // clear facility fees and close position
        credits[id] = _close(_repay(credit, id, facilityFee), id);

        LineLib.receiveTokenOrETH(credit.token, borrower, facilityFee);

        return true;
    }

    /// see ILineOfCredit.depositAndRepay
    function depositAndRepay(uint256 amount) external payable override nonReentrant whileBorrowing returns (bool) {
        bytes32 id = ids[0];
        Credit memory credit = credits[id];
        require(credit.isOpen);
        credit = _accrue(credit, id);

        require(amount <= credit.principal + credit.interestAccrued);

        credits[id] = _repay(credit, id, amount);

        LineLib.receiveTokenOrETH(credit.token, msg.sender, amount);

        return true;
    }

    ////////////////////
    // FUND TRANSFERS //
    ////////////////////

    /// see ILineOfCredit.borrow
    function borrow(bytes32 id, uint256 amount) external override nonReentrant whileActive onlyBorrower returns (bool) {
        Credit memory credit = _accrue(credits[id], id);

        if (!credit.isOpen) {
            revert PositionIsClosed();
        }

        if (amount > credit.deposit - credit.principal) {
            revert NoLiquidity();
        }

        credit.principal += amount;

        credits[id] = credit; // save new debt before healthcheck and token transfer

        // ensure that borrowing doesnt cause Line to be LIQUIDATABLE
        if (_updateStatus(_healthcheck()) != LineLib.STATUS.ACTIVE) {
            revert NotActive();
        }

        LineLib.sendOutTokenOrETH(credit.token, borrower, amount);

        emit Borrow(id, amount);

        _sortIntoQ(id);

        return true;
    }

    /// see ILineOfCredit.withdraw
    function withdraw(bytes32 id, uint256 amount) external override nonReentrant returns (bool) {
        Credit memory credit = credits[id];

        if (msg.sender != credit.lender) {
            revert CallerAccessDenied();
        }

        // accrues interest and transfers to Lender
        credit = CreditLib.withdraw(_accrue(credit, id), id, amount);

        // save before deleting position and sending out. Can remove if we add reentrancy guards
        (address token, address lender) = (credit.token, credit.lender);

        // if lender is pulling all funds AND no debt owed to them then delete positions
        if (credit.deposit == 0 && credit.interestAccrued == 0) {
            delete credits[id];
        }
        // save to storage if position still exists
        else {
            credits[id] = credit;
        }

        LineLib.sendOutTokenOrETH(token, lender, amount);

        return true;
    }

    /**
     * @notice  - Steps the Queue be replacing the first element with the next valid credit line's ID
     * @dev     - Only works if the first element in the queue is null
     */
    function stepQ() external returns (bool) {
        if (ids[0] != bytes32(0)) {
            revert CantStepQ();
        }
        ids.stepQ();
        return true;
    }

    //////////////////////
    //  Internal  funcs //
    //////////////////////

    /**
     * @notice - updates `status` variable in storage if current status is diferent from existing status.
     * @dev - privileged internal function. MUST check params and logic flow before calling
     * @dev - does not save new status if it is the same as current status
     * @return status - the current status of the line after updating
     */
    function _updateStatus(LineLib.STATUS status_) internal returns (LineLib.STATUS) {
        if (status == status_) return status_;
        emit UpdateStatus(uint256(status_));
        return (status = status_);
    }

    /**
     * @notice - Generates position id and stores lender's position
     * @dev - positions have unique composite-index on [lineAddress, lenderAddress, tokenAddress]
     * @dev - privileged internal function. MUST check params and logic flow before calling
     * @param lender - address that will own and manage position
     * @param token - ERC20 token that is being lent and borrower
     * @param amount - amount of tokens lender will initially deposit
     */
    function _createCredit(
        address lender,
        address token,
        uint256 amount
    ) internal returns (bytes32 id) {
        id = CreditLib.computeId(address(this), lender, token);
        // MUST not double add the credit line. otherwise we can not _close()
        if (credits[id].isOpen) {
            revert PositionExists();
        }

        credits[id] = CreditLib.create(id, amount, lender, token, address(oracle));

        ids.push(id); // add lender to end of repayment queue

        unchecked {
            ++count;
        }

        return id;
    }

    /**
   * @dev - Reduces `principal` and/or `interestAccrued` on a credit line.
            Expects checks for conditions of repaying and param sanitizing before calling
            e.g. early repayment of principal, tokens have actually been paid by borrower, etc.
   * @dev - privileged internal function. MUST check params and logic flow before calling
   * @param id - position id with all data pertaining to line
   * @param amount - amount of Credit Token being repaid on credit line
   * @return credit - position struct in memory with updated values
  */
    function _repay(
        Credit memory credit,
        bytes32 id,
        uint256 amount
    ) internal returns (Credit memory) {
        credit = CreditLib.repay(credit, id, amount);

        return credit;
    }

    /**
     * @notice - checks that a credit line is fully repaid and removes it
     * @dev deletes credit storage. Store any data u might need later in call before _close()
     * @dev - privileged internal function. MUST check params and logic flow before calling
     * @dev - when the line being closed is at the 0-index in the ids array, the null index is replaced using `.stepQ`
     * @return credit - position struct in memory with updated values
     */
    function _close(Credit memory credit, bytes32 id) internal virtual returns (Credit memory) {
        if (!credit.isOpen) {
            revert PositionIsClosed();
        }
        if (credit.principal != 0) {
            revert CloseFailedWithPrincipal();
        }

        credit.isOpen = false;

        // nullify the element for `id`
        ids.removePosition(id);

        // if positions was 1st in Q, cycle to next valid position
        if (ids[0] == bytes32(0)) ids.stepQ();

        unchecked {
            --count;
        }

        // If all credit lines are closed the the overall Line of Credit facility is declared 'repaid'.
        if (count == 0) {
            _updateStatus(LineLib.STATUS.REPAID);
        }

        emit CloseCreditPosition(id);

        return credit;
    }

    /**
     * @notice - Insert `p` into the next availble FIFO position in the repayment queue
               - once earliest slot is found, swap places with `p` and position in slot.
     * @dev - privileged internal function. MUST check params and logic flow before calling
     * @param p - position id that we are trying to find appropriate place for
     * @return - if function executed successfully
     */
    function _sortIntoQ(bytes32 p) internal returns (bool) {
        uint256 lastSpot = ids.length - 1;
        uint256 nextQSpot = lastSpot;
        bytes32 id;
        for (uint256 i; i <= lastSpot; ++i) {
            id = ids[i];
            if (p != id) {
                if (
                    id == bytes32(0) || // deleted element. In the middle of the q because it was closed.
                    nextQSpot != lastSpot || // position already found. skip to find `p` asap
                    credits[id].principal > 0 //`id` should be placed before `p`
                ) continue;
                nextQSpot = i; // index of first undrawn line found
            } else {
                if (nextQSpot == lastSpot) return true; // nothing to update
                // swap positions
                ids[i] = ids[nextQSpot]; // id put into old `p` position
                ids[nextQSpot] = p; // p put at target index
                return true;
            }
        }
    }
}

pragma solidity ^0.8.9;
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {LineLib} from "../../utils/LineLib.sol";
import {EscrowedLine} from "./EscrowedLine.sol";
import {SpigotedLine} from "./SpigotedLine.sol";
import {SpigotedLineLib} from "../../utils/SpigotedLineLib.sol";
import {LineOfCredit} from "./LineOfCredit.sol";
import {ILineOfCredit} from "../../interfaces/ILineOfCredit.sol";
import {ISecuredLine} from "../../interfaces/ISecuredLine.sol";

contract SecuredLine is SpigotedLine, EscrowedLine, ISecuredLine {
    constructor(
        address oracle_,
        address arbiter_,
        address borrower_,
        address payable swapTarget_,
        address spigot_,
        address escrow_,
        uint ttl_,
        uint8 defaultSplit_
    ) SpigotedLine(oracle_, arbiter_, borrower_, spigot_, swapTarget_, ttl_, defaultSplit_) EscrowedLine(escrow_) {}

    /**
     * @dev requires both Spigot and Escrow to pass _init to succeed
     */
    function _init() internal virtual override(SpigotedLine, EscrowedLine) returns (LineLib.STATUS) {
        LineLib.STATUS s = LineLib.STATUS.ACTIVE;

        if (SpigotedLine._init() != s || EscrowedLine._init() != s) {
            return LineLib.STATUS.UNINITIALIZED;
        }

        return s;
    }

    /// see IsecuredLine.rollover
    function rollover(address newLine) external override onlyBorrower returns (bool) {
        // require all debt successfully paid already
        if (status != LineLib.STATUS.REPAID) {
            revert DebtOwed();
        }
        // require new line isn't activated yet
        if (ILineOfCredit(newLine).status() != LineLib.STATUS.UNINITIALIZED) {
            revert BadNewLine();
        }
        // we dont check borrower is same on both lines because borrower might want new address managing new line
        EscrowedLine._rollover(newLine);
        SpigotedLineLib.rollover(address(spigot), newLine);

        // ensure that line we are sending can accept them. There is no recovery option.
        if (ILineOfCredit(newLine).init() != LineLib.STATUS.ACTIVE) {
            revert BadRollover();
        }

        return true;
    }

    /**
     * see EscrowedLine._liquidate
     * @notice - Forcefully take collateral from Escrow and repay debt for lender
     *          - current implementation just sends "liquidated" tokens to Arbiter to sell off how the deem fit and then manually repay with DepositAndRepay
     * @dev - only callable by Arbiter
     * @dev - Line status MUST be LIQUIDATABLE
     * @dev - callable by `arbiter`
     * @param amount - amount of `targetToken` expected to be sold off in  _liquidate
     * @param targetToken - token in escrow that will be sold of to repay position
     */

    function liquidate(uint256 amount, address targetToken) external returns (uint256) {
        if (msg.sender != arbiter) {
            revert CallerAccessDenied();
        }
        if (_updateStatus(_healthcheck()) != LineLib.STATUS.LIQUIDATABLE) {
            revert NotLiquidatable();
        }

        // send tokens to arbiter for OTC sales
        return _liquidate(ids[0], amount, targetToken, msg.sender);
    }

    function _healthcheck() internal override(EscrowedLine, LineOfCredit) returns (LineLib.STATUS) {
        LineLib.STATUS s = LineOfCredit._healthcheck();
        if (s != LineLib.STATUS.ACTIVE) {
            return s;
        }

        return EscrowedLine._healthcheck();
    }

    /**
     * @notice Wrapper for SpigotedLine and EscrowedLine internal functions
     * @dev - both underlying calls MUST return true for Line status to change to INSOLVENT
     * @return isInsolvent - if the entire Line including all collateral sources is fuly insolvent.
     */
    function _canDeclareInsolvent() internal virtual override(EscrowedLine, SpigotedLine) returns (bool) {
        return (EscrowedLine._canDeclareInsolvent() && SpigotedLine._canDeclareInsolvent());
    }
}

pragma solidity ^0.8.9;

import {Denominations} from "chainlink/Denominations.sol";
import {LineOfCredit} from "./LineOfCredit.sol";
import {LineLib} from "../../utils/LineLib.sol";
import {CreditLib} from "../../utils/CreditLib.sol";
import {SpigotedLineLib} from "../../utils/SpigotedLineLib.sol";
import {MutualConsent} from "../../utils/MutualConsent.sol";
import {ISpigot} from "../../interfaces/ISpigot.sol";
import {ISpigotedLine} from "../../interfaces/ISpigotedLine.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

/**
  * @title  - Debt DAO Spigoted Line of Credit
  * @author - Kiba Gateaux
  * @notice - The SpigotedLine is a LineofCredit contract with additional functionality for integrating with a Spigot.
            - allows Borrower or Lender to repay debt using collateralized revenue streams
  * @dev    -  Inherits LineOfCredit functionality
 */
contract SpigotedLine is ISpigotedLine, LineOfCredit {
    using SafeERC20 for IERC20;

    /// see Spigot
    ISpigot public immutable spigot;

    /// @notice exchange aggregator (mainly 0x router) to trade revenue tokens from a Spigot for credit tokens owed to lenders
    address payable public immutable swapTarget;

    /// @notice % of revenue tokens to take from Spigot if the Line of Credit  is healthy. 0 decimals
    uint8 public immutable defaultRevenueSplit;

    /**
     * @notice - excess unsold revenue claimed from Spigot to be sold later or excess credit tokens bought from revenue but not yet used to repay debt
     *         - needed because the Line of Credit might have the same token being lent/borrower as being bought/sold so need to separate accounting.
     * @dev    - private variable so other Line modules do not interfer with Spigot functionality
     */
    mapping(address => uint256) private unusedTokens;

    /**
     * @notice - The SpigotedLine is a LineofCredit contract with additional functionality for integrating with a Spigot.
               - allows Borrower or Lender to repay debt using collateralized revenue streams
     * @param oracle_ - price oracle to use for getting all token values
     * @param arbiter_ - neutral party with some special priviliges on behalf of borrower and lender
     * @param borrower_ - the debitor for all credit positions in this contract
     * @param spigot_ - Spigot smart contract that is owned by this Line
     * @param swapTarget_ - 0x protocol exchange address to send calldata for trades to exchange revenue tokens for credit tokens
     * @param ttl_ - time to live for line of credit contract across all lenders set at deployment in order to set the term/expiry date
     * @param defaultRevenueSplit_ - The % of Revenue Tokens that the Spigot escrows for debt repayment if the Line is healthy. 
     */
    constructor(
        address oracle_,
        address arbiter_,
        address borrower_,
        address spigot_,
        address payable swapTarget_,
        uint256 ttl_,
        uint8 defaultRevenueSplit_
    ) LineOfCredit(oracle_, arbiter_, borrower_, ttl_) {
        require(defaultRevenueSplit_ <= SpigotedLineLib.MAX_SPLIT);

        spigot = ISpigot(spigot_);
        defaultRevenueSplit = defaultRevenueSplit_;
        swapTarget = swapTarget_;
    }

    /**
     * see LineOfCredit._init and Securedline.init
     * @notice requires this Line is owner of the Escrowed collateral else Line will not init
     */
    function _init() internal virtual override(LineOfCredit) returns (LineLib.STATUS) {
        if (spigot.owner() != address(this)) return LineLib.STATUS.UNINITIALIZED;
        return LineOfCredit._init();
    }

    function unused(address token) external view returns (uint256) {
        return unusedTokens[token];
    }

    /**
     * see SecuredLine.declareInsolvent
     * @notice requires Spigot contract itselgf to be transfered to Arbiter and sold off to a 3rd party before declaring insolvent
     *(@dev priviliegad internal function.
     * @return isInsolvent - if Spigot contract is currently insolvent or not
     */
    function _canDeclareInsolvent() internal virtual override returns (bool) {
        return SpigotedLineLib.canDeclareInsolvent(address(spigot), arbiter);
    }

    /// see ISpigotedLine.claimAndRepay
    function claimAndRepay(
        address claimToken,
        bytes calldata zeroExTradeData
    ) external whileBorrowing nonReentrant returns (uint256) {
        bytes32 id = ids[0];
        Credit memory credit = _accrue(credits[id], id);

        if (msg.sender != arbiter) {
            revert CallerAccessDenied();
        }

        uint256 newTokens = claimToken == credit.token
            ? spigot.claimOwnerTokens(claimToken) // same asset. dont trade
            : _claimAndTrade(claimToken, credit.token, zeroExTradeData); // trade revenue token for debt obligation

        uint256 repaid = newTokens + unusedTokens[credit.token];
        uint256 debt = credit.interestAccrued + credit.principal;

        // cap payment to debt value
        if (repaid > debt) repaid = debt;

        // update reserves based on usage
        if (repaid > newTokens) {
            // using bought + unused to repay line
            unusedTokens[credit.token] -= repaid - newTokens;
        } else {
            // high revenue and bought more than we need
            unusedTokens[credit.token] += newTokens - repaid;
        }

        credits[id] = _repay(credit, id, repaid);

        emit RevenuePayment(claimToken, repaid);

        return newTokens;
    }

    /// see ISpigotedLine.useAndRepay
    function useAndRepay(uint256 amount) external whileBorrowing returns (bool) {
        bytes32 id = ids[0];
        Credit memory credit = credits[id];

        if (msg.sender != borrower && msg.sender != credit.lender) {
            revert CallerAccessDenied();
        }

        if (amount > unusedTokens[credit.token]) {
            revert ReservesOverdrawn(unusedTokens[credit.token]);
        }

        // reduce reserves before _repay calls token to prevent reentrancy
        unusedTokens[credit.token] -= amount;

        credits[id] = _repay(_accrue(credit, id), id, amount);

        emit RevenuePayment(credit.token, amount);

        return true;
    }

    /// see ISpigotedLine.claimAndTrade
    function claimAndTrade(
        address claimToken,
        bytes calldata zeroExTradeData
    ) external whileBorrowing nonReentrant returns (uint256) {
        if (msg.sender != arbiter) {
            revert CallerAccessDenied();
        }

        address targetToken = credits[ids[0]].token;
        uint256 newTokens = claimToken == targetToken
            ? spigot.claimOwnerTokens(claimToken) // same asset. dont trade
            : _claimAndTrade(claimToken, targetToken, zeroExTradeData); // trade revenue token for debt obligation

        // add bought tokens to unused balance
        unusedTokens[targetToken] += newTokens;
        return newTokens;
    }

    /**
     * @notice  - Claims revenue tokens escrowed in Spigot and trades them for credit tokens.
     *          - MUST trade all available claim tokens to target credit token.
     *          - Excess credit tokens not used to repay dent are stored in `unused`
     * @dev     - priviliged internal function
     * @param claimToken - The revenue token escrowed in the Spigot to sell in trade
     * @param targetToken - The credit token that needs to be bought in order to pat down debt. Always `credits[ids[0]].token`
     * @param zeroExTradeData - 0x API data to use in trade to sell `claimToken` for target
     *
     * @return - amount of target tokens bought
     */
    function _claimAndTrade(
        address claimToken,
        address targetToken,
        bytes calldata zeroExTradeData
    ) internal returns (uint256) {
        (uint256 tokensBought, uint256 totalUnused) = SpigotedLineLib.claimAndTrade(
            claimToken,
            targetToken,
            swapTarget,
            address(spigot),
            unusedTokens[claimToken],
            zeroExTradeData
        );

        // we dont use revenue after this so can store now
        unusedTokens[claimToken] = totalUnused;
        return tokensBought;
    }

    //  SPIGOT OWNER FUNCTIONS

    /// see ISpigotedLine.updateOwnerSplit
    function updateOwnerSplit(address revenueContract) external returns (bool) {
        return
            SpigotedLineLib.updateSplit(
                address(spigot),
                revenueContract,
                _updateStatus(_healthcheck()),
                defaultRevenueSplit
            );
    }

    /// see ISpigotedLine.addSpigot
    function addSpigot(address revenueContract, ISpigot.Setting calldata setting) external returns (bool) {
        if (msg.sender != arbiter) {
            revert CallerAccessDenied();
        }
        return spigot.addSpigot(revenueContract, setting);
    }

    /// see ISpigotedLine.updateWhitelist
    function updateWhitelist(bytes4 func, bool allowed) external returns (bool) {
        if (msg.sender != arbiter) {
            revert CallerAccessDenied();
        }
        return spigot.updateWhitelistedFunction(func, allowed);
    }

    /// see ISpigotedLine.releaseSpigot
    function releaseSpigot(address to) external returns (bool) {
        return SpigotedLineLib.releaseSpigot(address(spigot), _updateStatus(_healthcheck()), borrower, arbiter, to);
    }

    /// see ISpigotedLine.sweep
    function sweep(address to, address token) external nonReentrant returns (uint256) {
        uint256 amount = unusedTokens[token];
        delete unusedTokens[token];

        bool success = SpigotedLineLib.sweep(to, token, amount, _updateStatus(_healthcheck()), borrower, arbiter);

        return success ? amount : 0;
    }

    // allow claiming/trading in ETH
    receive() external payable {}
}

pragma solidity 0.8.9;

import {ILineFactory} from "../../interfaces/ILineFactory.sol";
import {IModuleFactory} from "../../interfaces/IModuleFactory.sol";
import {LineLib} from "../../utils/LineLib.sol";
import {LineFactoryLib} from "../../utils/LineFactoryLib.sol";
import {ISecuredLine} from "../../interfaces/ISecuredLine.sol";

contract LineFactory is ILineFactory {
    IModuleFactory immutable factory;

    uint8 constant defaultRevenueSplit = 90; // 90% to debt repayment
    uint8 constant MAX_SPLIT = 100; // max % to take
    uint32 constant defaultMinCRatio = 3000; // 30.00% minimum collateral ratio

    address public immutable arbiter;
    address public immutable oracle;
    address payable public immutable swapTarget;

    constructor(
        address moduleFactory,
        address arbiter_,
        address oracle_,
        address payable swapTarget_
    ) {
        factory = IModuleFactory(moduleFactory);
        if (arbiter_ == address(0)) {
            revert InvalidArbiterAddress();
        }
        if (oracle_ == address(0)) {
            revert InvalidOracleAddress();
        }
        if (swapTarget_ == address(0)) {
            revert InvalidSwapTargetAddress();
        }
        arbiter = arbiter_;
        oracle = oracle_;
        swapTarget = swapTarget_;
    }

    /// see ModuleFactory.deployEscrow.
    function deployEscrow(
        uint32 minCRatio,
        address owner,
        address borrower
    ) external returns (address) {
        return factory.deployEscrow(minCRatio, oracle, owner, borrower);
    }

    /// see ModuleFactory.deploySpigot.
    function deploySpigot(address owner, address operator) external returns (address) {
        return factory.deploySpigot(owner, operator);
    }

    function deploySecuredLine(address borrower, uint256 ttl) external returns (address line) {
        // deploy new modules
        address s = factory.deploySpigot(address(this), borrower);
        address e = factory.deployEscrow(defaultMinCRatio, oracle, address(this), borrower);
        uint8 split = defaultRevenueSplit; // gas savings
        line = LineFactoryLib.deploySecuredLine(oracle, arbiter, borrower, payable(swapTarget), s, e, ttl, split);
        // give modules from address(this) to line so we can run line.init()
        LineFactoryLib.transferModulesToLine(address(line), s, e);
        emit DeployedSecuredLine(address(line), s, e, swapTarget, split);
    }

    function deploySecuredLineWithConfig(CoreLineParams calldata coreParams) external returns (address line) {
        if (coreParams.revenueSplit > MAX_SPLIT) {
            revert InvalidRevenueSplit();
        }

        // deploy new modules
        address s = factory.deploySpigot(address(this), coreParams.borrower);
        address e = factory.deployEscrow(coreParams.cratio, oracle, address(this), coreParams.borrower);
        line = LineFactoryLib.deploySecuredLine(
            oracle,
            arbiter,
            coreParams.borrower,
            payable(swapTarget),
            s,
            e,
            coreParams.ttl,
            coreParams.revenueSplit
        );
        // give modules from address(this) to line so we can run line.init()
        LineFactoryLib.transferModulesToLine(address(line), s, e);
        emit DeployedSecuredLine(address(line), s, e, swapTarget, coreParams.revenueSplit);
    }

    /**
     *   @dev   We don't transfer the ownership of Escrow and Spigot internally
     *          because they aren't owned by the factory, the responsibility falls
     *          on the [owner of the line]
     *   @dev   The `cratio` in the CoreParams are not used, due to the fact
     *          they're passed in when the Escrow is created separately.
     */
    function deploySecuredLineWithModules(
        CoreLineParams calldata coreParams,
        address mSpigot,
        address mEscrow
    ) external returns (address line) {
        if (mSpigot == address(0)) {
            revert InvalidSpigotAddress();
        }

        if (mEscrow == address(0)) {
            revert InvalidEscrowAddress();
        }

        line = LineFactoryLib.deploySecuredLine(
            oracle,
            arbiter,
            coreParams.borrower,
            payable(swapTarget),
            mSpigot,
            mEscrow,
            coreParams.ttl,
            coreParams.revenueSplit
        );

        emit DeployedSecuredLine(address(line), mEscrow, mSpigot, swapTarget, coreParams.revenueSplit);
    }

    /**
      @notice sets up new line based of config of old line. Old line does not need to have REPAID status for this call to succeed.
      @dev borrower must call rollover() on `oldLine` with newly created line address
      @param oldLine  - line to copy config from for new line.
      @param borrower - borrower address on new line
      @param ttl      - set total term length of line
      @return line - address of newly deployed line with oldLine config
     */
    function rolloverSecuredLine(
        address payable oldLine,
        address borrower,
        uint256 ttl
    ) external returns (address line) {
        address s = address(ISecuredLine(oldLine).spigot());
        address e = address(ISecuredLine(oldLine).escrow());
        line = LineFactoryLib.deploySecuredLine(oracle, arbiter, borrower, swapTarget, s, e, ttl, defaultRevenueSplit);
        emit DeployedSecuredLine(line, s, e, swapTarget, defaultRevenueSplit);
    }
}

pragma solidity ^0.8.9;

import {IInterestRateCredit} from "../../interfaces/IInterestRateCredit.sol";

contract InterestRateCredit is IInterestRateCredit {
    // 1 Julian astronomical year in seconds to use in calculations for rates = 31557600 seconds
    uint256 constant ONE_YEAR = 365.25 days;
    // Must divide by 100 too offset bps in numerator and divide by another 100 to offset % and get actual token amount
    uint256 constant BASE_DENOMINATOR = 10000;
    // = 31557600 * 10000 = 315576000000;
    uint256 constant INTEREST_DENOMINATOR = ONE_YEAR * BASE_DENOMINATOR;

    address immutable lineContract;
    mapping(bytes32 => Rate) public rates; // position id -> lending rates

    /**
     * @notice Interest rate / acrrued interest calculation contract for Line of Credit contracts
     */
    constructor() {
        lineContract = msg.sender;
    }

    ///////////  MODIFIERS  ///////////

    modifier onlyLineContract() {
        require(msg.sender == lineContract, "InterestRateCred: only line contract.");
        _;
    }

    /// see IInterestRateCredit
    function accrueInterest(
        bytes32 id,
        uint256 drawnBalance,
        uint256 facilityBalance
    ) external override onlyLineContract returns (uint256) {
        return _accrueInterest(id, drawnBalance, facilityBalance);
    }

    function _accrueInterest(bytes32 id, uint256 drawnBalance, uint256 facilityBalance) internal returns (uint256) {
        Rate memory rate = rates[id];
        uint256 timespan = block.timestamp - rate.lastAccrued;
        // update last timestamp in storage
        rates[id].lastAccrued = block.timestamp;

        return (_calculateInterestOwed(rate.dRate, drawnBalance, timespan) +
            _calculateInterestOwed(rate.fRate, (facilityBalance - drawnBalance), timespan));
    }

    /**
     * @notice - total interest to accrue based on apr, balance, and length of time
     * @dev    - r = APR in bps, x = # tokens, t = time
     *         - interest = (r * x * t) / 1yr / 100
     * @param  bpsRate - interest rate (APR) to charge against balance in bps (4 decimals)
     * @param  balance - current balance for interest rate tier to charge interest against
     * @param  timespan - total amount of time that interest should be charged for
     *
     * @return interestOwed
     */
    function _calculateInterestOwed(
        uint256 bpsRate,
        uint256 balance,
        uint256 timespan
    ) internal pure returns (uint256) {
        return (bpsRate * balance * timespan) / INTEREST_DENOMINATOR;
    }

    /// see IInterestRateCredit
    function setRate(bytes32 id, uint128 dRate, uint128 fRate) external onlyLineContract returns (bool) {
        rates[id] = Rate({dRate: dRate, fRate: fRate, lastAccrued: block.timestamp});

        return true;
    }
}

pragma solidity 0.8.9;
import {Denominations} from "chainlink/Denominations.sol";
import {ILineOfCredit} from "../interfaces/ILineOfCredit.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IInterestRateCredit} from "../interfaces/IInterestRateCredit.sol";
import {ILineOfCredit} from "../interfaces/ILineOfCredit.sol";
import {LineLib} from "./LineLib.sol";

/**
 * @title Debt DAO Line of Credit Library
 * @author Kiba Gateaux
 * @notice Core logic and variables to be reused across all Debt DAO Marketplace Line of Credit contracts
 */
library CreditLib {
    event AddCredit(address indexed lender, address indexed token, uint256 indexed deposit, bytes32 id);

    /// @notice Emits data re Lender removes funds (principal) - there is no corresponding function, just withdraw()
    event WithdrawDeposit(bytes32 indexed id, uint256 indexed amount);

    /// @notice Emits data re Lender withdraws interest - there is no corresponding function, just withdraw()
    // Bob - consider changing event name to WithdrawInterest
    event WithdrawProfit(bytes32 indexed id, uint256 indexed amount);

    /// @notice After accrueInterest runs, emits the amount of interest added to a Borrower's outstanding balance of interest due
    // but not yet repaid to the Line of Credit contract
    event InterestAccrued(bytes32 indexed id, uint256 indexed amount);

    // Borrower Events

    event Borrow(bytes32 indexed id, uint256 indexed amount);
    // Emits notice that a Borrower has drawn down an amount on a credit line

    event RepayInterest(bytes32 indexed id, uint256 indexed amount);
    /** Emits that a Borrower has repaid an amount of interest 
  (N.B. results in an increase in interestRepaid, i.e. interest not yet withdrawn by a Lender). There is no corresponding function
  */

    event RepayPrincipal(bytes32 indexed id, uint256 indexed amount);
    // Emits that a Borrower has repaid an amount of principal - there is no corresponding function

    error NoTokenPrice();

    error PositionExists();

    error RepayAmountExceedsDebt(uint256 totalAvailable);

    /**
     * @dev          - Creates a deterministic hash id for a credit line provided by a single Lender for a given token on a Line of Credit facility
     * @param line   - The Line of Credit facility concerned
     * @param lender - The address managing the credit line concerned
     * @param token  - The token being lent out on the credit line concerned
     * @return id
     */
    function computeId(address line, address lender, address token) external pure returns (bytes32) {
        return keccak256(abi.encode(line, lender, token));
    }

    // getOutstandingDebt() is called by updateOutstandingDebt()
    function getOutstandingDebt(
        ILineOfCredit.Credit memory credit,
        bytes32 id,
        address oracle,
        address interestRate
    ) external returns (ILineOfCredit.Credit memory c, uint256 principal, uint256 interest) {
        c = accrue(credit, id, interestRate);

        int256 price = IOracle(oracle).getLatestAnswer(c.token);

        principal = calculateValue(price, c.principal, c.decimals);
        interest = calculateValue(price, c.interestAccrued, c.decimals);

        return (c, principal, interest);
    }

    /**
    * @notice         - Calculates value of tokens.  Used for calculating the USD value of principal and of interest during getOutstandingDebt()
    * @dev            - Assumes Oracle returns answers in USD with 1e8 decimals
                      - If price < 0 then we treat it as 0.
    * @param price    - The Oracle price of the asset. 8 decimals
    * @param amount   - The amount of tokens being valued.
    * @param decimals - Token decimals to remove for USD price
    * @return         - The total USD value of the amount of tokens being valued in 8 decimals 
    */
    function calculateValue(int price, uint256 amount, uint8 decimals) public pure returns (uint256) {
        return price <= 0 ? 0 : (amount * uint(price)) / (1 * 10 ** decimals);
    }

    /**
     * see ILineOfCredit._createCredit
     * @notice called by LineOfCredit._createCredit during every repayment function
     * @param oracle - interset rate contract used by line that will calculate interest owed
     */
    function create(
        bytes32 id,
        uint256 amount,
        address lender,
        address token,
        address oracle
    ) external returns (ILineOfCredit.Credit memory credit) {
        int price = IOracle(oracle).getLatestAnswer(token);
        if (price <= 0) {
            revert NoTokenPrice();
        }

        uint8 decimals;
        if (token == Denominations.ETH) {
            decimals = 18;
        } else {
            (bool passed, bytes memory result) = token.call(abi.encodeWithSignature("decimals()"));
            decimals = !passed ? 18 : abi.decode(result, (uint8));
        }

        credit = ILineOfCredit.Credit({
            lender: lender,
            token: token,
            decimals: decimals,
            deposit: amount,
            principal: 0,
            interestAccrued: 0,
            interestRepaid: 0,
            isOpen: true
        });

        emit AddCredit(lender, token, amount, id);

        return credit;
    }

    /**
     * see ILineOfCredit._repay
     * @notice called by LineOfCredit._repay during every repayment function
     * @param credit - The lender position being repaid
     */
    function repay(
        ILineOfCredit.Credit memory credit,
        bytes32 id,
        uint256 amount
    ) external returns (ILineOfCredit.Credit memory) {
        unchecked {
            if (amount > credit.principal + credit.interestAccrued) {
                revert RepayAmountExceedsDebt(credit.principal + credit.interestAccrued);
            }

            if (amount <= credit.interestAccrued) {
                credit.interestAccrued -= amount;
                credit.interestRepaid += amount;
                emit RepayInterest(id, amount);
                return credit;
            } else {
                require(credit.isOpen);
                uint256 interest = credit.interestAccrued;
                uint256 principalPayment = amount - interest;

                // update individual credit line denominated in token
                credit.principal -= principalPayment;
                credit.interestRepaid += interest;
                credit.interestAccrued = 0;

                emit RepayInterest(id, interest);
                emit RepayPrincipal(id, principalPayment);

                return credit;
            }
        }
    }

    /**
     * see ILineOfCredit.withdraw
     * @notice called by LineOfCredit.withdraw during every repayment function
     * @param credit - The lender position that is being bwithdrawn from
     */
    function withdraw(
        ILineOfCredit.Credit memory credit,
        bytes32 id,
        uint256 amount
    ) external returns (ILineOfCredit.Credit memory) {
        unchecked {
            if (amount > credit.deposit - credit.principal + credit.interestRepaid) {
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
        }
    }

    /**
     * see ILineOfCredit._accrue
     * @notice called by LineOfCredit._accrue during every repayment function
     * @param interest - interset rate contract used by line that will calculate interest owed
     */
    function accrue(
        ILineOfCredit.Credit memory credit,
        bytes32 id,
        address interest
    ) public returns (ILineOfCredit.Credit memory) {
        unchecked {
            // interest will almost always be less than deposit
            // low risk of overflow unless extremely high interest rate

            // get token demoninated interest accrued
            uint256 accruedToken = IInterestRateCredit(interest).accrueInterest(id, credit.principal, credit.deposit);

            // update credit line balance
            credit.interestAccrued += accruedToken;

            emit InterestAccrued(id, accruedToken);
            return credit;
        }
    }
}

pragma solidity 0.8.9;
import {ILineOfCredit} from "../interfaces/ILineOfCredit.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {CreditLib} from "./CreditLib.sol";

/**
 * @title Debt DAO Line of Credit Library
 * @author Kiba Gateaux
 * @notice Core logic and variables to be reused across all Debt DAO Marketplace Line of Credit contracts
 */
library CreditListLib {
    event QueueCleared();
    event SortedIntoQ(bytes32 indexed id, uint256 newIdx, uint256 oldIdx);

    /**
     * @dev assumes that `id` of a single credit line within the Line of Credit facility (same lender/token) is stored only once in the `positions` array 
     since there's no reason for them to be stored multiple times.
     * This means cleanup on _close() and checks on addCredit() are CRITICAL. If `id` is duplicated then the position can't be closed
     * @param ids - all current credit lines on the Line of Credit facility
     * @param id - the hash id of the credit line to be removed from active ids after removePosition() has run
     * @return newPositions - all active credit lines on the Line of Credit facility after the `id` has been removed [Bob - consider renaming to newIds
     * Bob - consider renaming this function removeId()
     */
    function removePosition(bytes32[] storage ids, bytes32 id) external returns (bool) {
        uint256 len = ids.length;

        for (uint256 i; i < len; ++i) {
            if (ids[i] == id) {
                delete ids[i];
                return true;
            }
        }

        return true;
    }

    /**
     * @notice - swap the first element in the queue, provided it is null, with the next available valid(non-null) id
     * @dev    - Must perform check for ids[0] being valid (non-zero) before calling
     * @param ids - all current credit lines on the Line of Credit facility
     * @return swapped - returns true if the swap has occurred
     */
    function stepQ(bytes32[] storage ids) external returns (bool) {
        uint256 len = ids.length;
        if (len <= 1) return false;
        if (len == 2 && ids[1] != bytes32(0)) {
            (ids[0], ids[1]) = (ids[1], ids[0]);
            emit SortedIntoQ(ids[0], 0, 1);
            return true;
        } // skip the loop if we don't need

        // we never check the first id, because we already know it's null
        for (uint i = 1; i < len; ) {
            if (ids[i] != bytes32(0)) {
                (ids[0], ids[i]) = (ids[i], ids[0]); // swap the ids
                emit SortedIntoQ(ids[0], 0, i);
                return true; // if we make the swap, return early
            }
            unchecked {
                ++i;
            }
        }
        emit QueueCleared();
        return false;
    }
}

pragma solidity 0.8.9;

import {SecuredLine} from "../modules/credit/SecuredLine.sol";
import {LineLib} from "./LineLib.sol";

library LineFactoryLib {
    event DeployedSecuredLine(
        address indexed deployedAt,
        address indexed escrow,
        address indexed spigot,
        address swapTarget,
        uint8 revenueSplit
    );

    event DeployedSpigot(address indexed deployedAt, address indexed owner, address operator);

    event DeployedEscrow(address indexed deployedAt, uint32 indexed minCRatio, address indexed oracle, address owner);

    error ModuleTransferFailed(address line, address spigot, address escrow);
    error InitNewLineFailed(address line, address spigot, address escrow);

    function transferModulesToLine(address line, address spigot, address escrow) external returns (bool) {
        (bool success, bytes memory returnVal) = spigot.call(
            abi.encodeWithSignature("updateOwner(address)", address(line))
        );
        (bool success2, bytes memory returnVal2) = escrow.call(
            abi.encodeWithSignature("updateLine(address)", address(line))
        );

        // ensure all modules were transferred
        if (!(success && abi.decode(returnVal, (bool)) && success2 && abi.decode(returnVal2, (bool)))) {
            revert ModuleTransferFailed(line, spigot, escrow);
        }

        if (SecuredLine(payable(line)).init() != LineLib.STATUS.ACTIVE) {
            revert InitNewLineFailed(address(line), spigot, escrow);
        }

        return true;
    }

    function deploySecuredLine(
        address oracle,
        address arbiter,
        address borrower,
        address payable swapTarget,
        address s,
        address e,
        uint256 ttl,
        uint8 revenueSplit
    ) external returns (address) {
        return address(new SecuredLine(oracle, arbiter, borrower, swapTarget, s, e, ttl, revenueSplit));
    }
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
            if (msg.value > 0) {
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

// forked from https://github.com/IndexCoop/index-coop-smart-contracts/blob/master/contracts/lib/MutualConsent.sol

pragma solidity 0.8.9;

/**
 * @title MutualConsent
 * @author Set Protocol
 *
 * The MutualConsent contract contains a modifier for handling mutual consents between two parties
 */
abstract contract MutualConsent {
    /* ============ State Variables ============ */

    // equivalent to longest msg.data bytes, ie addCredit
    uint256 constant MAX_DATA_LENGTH_BYTES = 164;

    // equivalent to any fn with no args, ie just a fn selector
    uint256 constant MIN_DATA_LENGTH_BYTES = 4;

    // Mapping of upgradable units and if consent has been initialized by other party
    mapping(bytes32 => address) public mutualConsents;

    error Unauthorized();
    error InvalidConsent();
    error NotUserConsent();

    // causes revert when the msg.data passed in has more data (ie arguments) than the largest known fn signature
    error UnsupportedMutualConsentFunction();

    /* ============ Events ============ */

    event MutualConsentRegistered(bytes32 _consentHash);
    event MutualConsentRevoked(address indexed user, bytes32 _toRevoke);

    /* ============ Modifiers ============ */

    /**
     * @notice - allows a function to be called if only two specific stakeholders signoff on the tx data
     *         - signers can be anyone. only two signers per contract or dynamic signers per tx.
     */
    modifier mutualConsent(address _signerOne, address _signerTwo) {
        if (_mutualConsent(_signerOne, _signerTwo)) {
            // Run whatever code needed 2/2 consent
            _;
        }
    }

    /**
     *  @notice - allows a caller to revoke a previously created consent
     *  @dev    - MAX_DATA_LENGTH_BYTES is set at 164 bytes, which is the length of the msg.data
     *          - for the addCredit function. Anything over that is not valid and might be used in
     *          - an attempt to create a hash collision
     *  @param  _reconstrucedMsgData The reconstructed msg.data for the function call for which the
     *          original consent was created - comprised of the fn selector (bytes4) and abi.encoded
     *          function arguments.
     *
     */
    function revokeConsent(bytes calldata _reconstrucedMsgData) external {
        if (
            _reconstrucedMsgData.length > MAX_DATA_LENGTH_BYTES || _reconstrucedMsgData.length < MIN_DATA_LENGTH_BYTES
        ) {
            revert UnsupportedMutualConsentFunction();
        }

        bytes32 hashToDelete = keccak256(abi.encodePacked(_reconstrucedMsgData, msg.sender));

        address consentor = mutualConsents[hashToDelete];

        if (consentor == address(0)) {
            revert InvalidConsent();
        }
        if (consentor != msg.sender) {
            revert NotUserConsent();
        } // note: cannot test, as no way to know what data (+msg.sender) would cause hash collision

        delete mutualConsents[hashToDelete];

        emit MutualConsentRevoked(msg.sender, hashToDelete);
    }

    /* ============ Internal Functions ============ */

    function _mutualConsent(address _signerOne, address _signerTwo) internal returns (bool) {
        if (msg.sender != _signerOne && msg.sender != _signerTwo) {
            revert Unauthorized();
        }

        address nonCaller = _getNonCaller(_signerOne, _signerTwo);

        // The consent hash is defined by the hash of the transaction call data and sender of msg,
        // which uniquely identifies the function, arguments, and sender.
        bytes32 expectedHash = keccak256(abi.encodePacked(msg.data, nonCaller));

        if (mutualConsents[expectedHash] == address(0)) {
            bytes32 newHash = keccak256(abi.encodePacked(msg.data, msg.sender));

            mutualConsents[newHash] = msg.sender;

            emit MutualConsentRegistered(newHash);

            return false;
        }

        delete mutualConsents[expectedHash];

        return true;
    }

    function _getNonCaller(address _signerOne, address _signerTwo) internal view returns (address) {
        return msg.sender == _signerOne ? _signerTwo : _signerOne;
    }
}

pragma solidity 0.8.9;

import {ISpigot} from "../interfaces/ISpigot.sol";
import {ISpigotedLine} from "../interfaces/ISpigotedLine.sol";
import {LineLib} from "../utils/LineLib.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

import {Denominations} from "chainlink/Denominations.sol";

library SpigotedLineLib {
    // max revenue to take from Spigot if line is in distress
    uint8 constant MAX_SPLIT = 100;

    error NoSpigot();

    error TradeFailed();

    error BadTradingPair();

    error CallerAccessDenied();

    error ReleaseSpigotFailed();

    error NotInsolvent(address module);

    error ReservesOverdrawn(address token, uint256 amountAvailable);

    event TradeSpigotRevenue(
        address indexed revenueToken,
        uint256 revenueTokenAmount,
        address indexed debtToken,
        uint256 indexed debtTokensBought
    );

    /**
     * @notice              Allows revenue tokens in 'escrowed' to be traded for credit tokens that aren't yet used to repay debt. 
                            The newly exchanged credit tokens are held in 'unusedTokens' ready for a Lender to withdraw using useAndRepay 
                            This feature allows a Borrower to take advantage of an increase in the value of the revenue token compared 
                            to the credit token and to in effect use less revenue tokens to be later used to repay the same amount of debt.
     * @dev                 MUST trade all available claimTokens to targetTokens
     * @dev                 priviliged internal function
     * @param claimToken    - The revenue token escrowed in the Spigot to sell in trade
     * @param targetToken   - The credit token that needs to be bought in order to pat down debt. Always `credits[ids[0]].token`
     * @param swapTarget    - The 0x exchange router address to call for trades
     * @param spigot        - The Spigot to claim from. Must be owned by adddress(this)
     * @param unused        - Current amount of unused claimTokens
     * @param zeroExTradeData - 0x API data to use in trade to sell `claimToken` for target
     * @return (uint, uint) - amount of targetTokens bought, total unused claimTokens after trade
     */
    function claimAndTrade(
        address claimToken,
        address targetToken,
        address payable swapTarget,
        address spigot,
        uint256 unused,
        bytes calldata zeroExTradeData
    ) external returns (uint256, uint256) {
        // can't trade into same token. causes double count for unused tokens
        if (claimToken == targetToken) {
            revert BadTradingPair();
        }

        // snapshot token balances now to diff after trade executes
        uint256 oldClaimTokens = LineLib.getBalance(claimToken);
        uint256 oldTargetTokens = LineLib.getBalance(targetToken);

        // @dev claim has to be called after we get balance
        // reverts if there are no tokens to claim
        uint256 claimed = ISpigot(spigot).claimOwnerTokens(claimToken);

        trade(claimed + unused, claimToken, swapTarget, zeroExTradeData);

        // underflow revert ensures we have more tokens than we started with
        uint256 tokensBought = LineLib.getBalance(targetToken) - oldTargetTokens;

        if (tokensBought == 0) {
            revert TradeFailed();
        } // ensure tokens bought

        uint256 newClaimTokens = LineLib.getBalance(claimToken);

        // ideally we could use oracle to calculate # of tokens to receive
        // but sellToken might not have oracle. buyToken must have oracle

        emit TradeSpigotRevenue(claimToken, claimed, targetToken, tokensBought);

        // used reserve revenue to repay debt
        if (oldClaimTokens > newClaimTokens) {
            uint256 diff = oldClaimTokens - newClaimTokens;

            // used more tokens than we had in revenue reserves.
            // prevent borrower from pulling idle lender funds to repay other lenders
            if (diff > unused) revert ReservesOverdrawn(claimToken, unused);
            // reduce reserves by consumed amount
            else return (tokensBought, unused - diff);
        } else {
            unchecked {
                // excess revenue in trade. store in reserves
                return (tokensBought, unused + (newClaimTokens - oldClaimTokens));
            }
        }
    }

    function trade(
        uint256 amount,
        address sellToken,
        address payable swapTarget,
        bytes calldata zeroExTradeData
    ) public returns (bool) {
        if (sellToken == Denominations.ETH) {
            // if claiming/trading eth send as msg.value to dex
            (bool success, ) = swapTarget.call{value: amount}(zeroExTradeData);
            if (!success) {
                revert TradeFailed();
            }
        } else {
            IERC20(sellToken).approve(swapTarget, amount);
            (bool success, ) = swapTarget.call(zeroExTradeData);
            if (!success) {
                revert TradeFailed();
            }
        }

        return true;
    }

    /**
     * @notice cleanup function when a Line of Credit facility has expired.
        Used in the event that we want to reuse a Spigot instead of starting from scratch
     */
    function rollover(address spigot, address newLine) external returns (bool) {
        require(ISpigot(spigot).updateOwner(newLine));
        return true;
    }

    function canDeclareInsolvent(address spigot, address arbiter) external view returns (bool) {
        // Must have called releaseSpigot() and sold off protocol / revenue streams already
        address owner_ = ISpigot(spigot).owner();
        if (address(this) == owner_ || arbiter == owner_) {
            revert NotInsolvent(spigot);
        }
        // no additional logic in LineOfCredit to include
        return true;
    }

    /**
     * @notice Changes the revenue split between a Borrower's treasury and the LineOfCredit based on line health, runs with updateOwnerSplit()
     * @dev    - callable `arbiter` + `borrower`
     * @param revenueContract - spigot to update
     * @return whether or not split was updated
     */
    function updateSplit(
        address spigot,
        address revenueContract,
        LineLib.STATUS status,
        uint8 defaultSplit
    ) external returns (bool) {
        (uint8 split, , bytes4 transferFunc) = ISpigot(spigot).getSetting(revenueContract);

        if (transferFunc == bytes4(0)) {
            revert NoSpigot();
        }

        if (status == LineLib.STATUS.ACTIVE && split != defaultSplit) {
            // if Line of Credit is healthy then set the split to the prior agreed default split of revenue tokens
            return ISpigot(spigot).updateOwnerSplit(revenueContract, defaultSplit);
        } else if (status == LineLib.STATUS.LIQUIDATABLE && split != MAX_SPLIT) {
            // if the Line of Credit is in distress then take all revenue to repay debt
            return ISpigot(spigot).updateOwnerSplit(revenueContract, MAX_SPLIT);
        }

        return false;
    }

    /**

   * @notice -  Transfers ownership of the entire Spigot and its revenuw streams from its then Owner to either 
                the Borrower (if a Line of Credit has been been fully repaid) or 
                to the Arbiter (if the Line of Credit is liquidatable).
   * @dev    - callable by anyone 
   * @return - whether or not Spigot was released
  */
    function releaseSpigot(
        address spigot,
        LineLib.STATUS status,
        address borrower,
        address arbiter,
        address to
    ) external returns (bool) {
        if (status == LineLib.STATUS.REPAID && msg.sender == borrower) {
            if (!ISpigot(spigot).updateOwner(to)) {
                revert ReleaseSpigotFailed();
            }
            return true;
        }

        if (status == LineLib.STATUS.LIQUIDATABLE && msg.sender == arbiter) {
            if (!ISpigot(spigot).updateOwner(to)) {
                revert ReleaseSpigotFailed();
            }
            return true;
        }

        revert CallerAccessDenied();

        return false;
    }

    /**
   * @notice -  Sends any remaining tokens (revenue or credit tokens) in the Spigot to the Borrower after the loan has been repaid.
             -  In case of a Borrower default (loan status = liquidatable), this is a fallback mechanism to withdraw all the tokens and send them to the Arbiter
             -  Does not transfer anything if line is healthy
   * @return - whether or not spigot was released
  */
    function sweep(
        address to,
        address token,
        uint256 amount,
        LineLib.STATUS status,
        address borrower,
        address arbiter
    ) external returns (bool) {
        if (amount == 0) {
            revert ReservesOverdrawn(token, 0);
        }

        if (status == LineLib.STATUS.REPAID && msg.sender == borrower) {
            return LineLib.sendOutTokenOrETH(token, to, amount);
        }

        if ((status == LineLib.STATUS.LIQUIDATABLE || status == LineLib.STATUS.INSOLVENT) && msg.sender == arbiter) {
            return LineLib.sendOutTokenOrETH(token, to, amount);
        }

        revert CallerAccessDenied();

        return false;
    }
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