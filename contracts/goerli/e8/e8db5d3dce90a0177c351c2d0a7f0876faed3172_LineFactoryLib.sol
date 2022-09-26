pragma solidity 0.8.9;

import {SecuredLine} from "../modules/credit/SecuredLine.sol";


library LineFactoryLib {
    event DeployedSecuredLine(
        address indexed deployedAt,
        address indexed escrow,
        address indexed spigot,
        address swapTarget,
        uint8 revenueSplit
    );

    event DeployedSpigot(
        address indexed deployedAt,
        address indexed owner,
        address indexed treasury,
        address operator
    );

    event DeployedEscrow(
        address indexed deployedAt,
        uint32 indexed minCRatio,
        address indexed oracle,
        address owner
    );

    error ModuleTransferFailed(address line, address spigot, address escrow);
    error InitNewLineFailed(address line, address spigot, address escrow);

    /**
      @notice sets up new line based of config of old line. Old line does not need to have REPAID status for this call to succeed.
      @dev borrower must call rollover() on `oldLine` with newly created line address
      @param oldLine  - line to copy config from for new line.
      @param borrower - borrower address on new line
      @param ttl      - set total term length of line
      @return newLine - address of newly deployed line with oldLine config
     */
    function rolloverSecuredLine(
        address payable oldLine,
        address borrower, 
        uint ttl,
        address oracle,
        address arbiter
    ) external returns(address) {
        address s = address(SecuredLine(oldLine).spigot());
        address e = address(SecuredLine(oldLine).escrow());
        address payable st = SecuredLine(oldLine).swapTarget();
        uint8 split = SecuredLine(oldLine).defaultRevenueSplit();
        SecuredLine line = new SecuredLine(oracle, arbiter, borrower, st, s, e, ttl, split);
        emit DeployedSecuredLine(address(line), s, e, st, split);
        return address(line);
    }

    function transferModulesToLine(address line, address spigot, address escrow) external {
        (bool success, bytes memory returnVal) = spigot.call(
          abi.encodeWithSignature("updateOwner(address)",
          address(line)
        ));
        (bool success2, bytes memory returnVal2) = escrow.call(
          abi.encodeWithSignature("updateLine(address)",
          address(line)
        ));
        (bool res) = abi.decode(returnVal, (bool));
        (bool res2) = abi.decode(returnVal2, (bool));
        if(!(success && res && success2 && res2)) {
          revert ModuleTransferFailed(line, spigot, escrow);
        }
    }

    function deploySecuredLine(
        address oracle, 
        address arbiter,
        address borrower, 
        address payable swapTarget,
        address s,
        address e,
        uint ttl, 
        uint8 revenueSplit
        ) external returns(SecuredLine){

      SecuredLine line = new SecuredLine(oracle, arbiter, borrower, swapTarget,s, e, ttl, revenueSplit);
      return line;
    }


}

pragma solidity ^0.8.9;
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import { LineLib } from "../../utils/LineLib.sol";
import { EscrowedLine } from "./EscrowedLine.sol";
import { SpigotedLine } from "./SpigotedLine.sol";
import { SpigotedLineLib } from "../../utils/SpigotedLineLib.sol";
import { LineOfCredit } from "./LineOfCredit.sol";
import { ILineOfCredit } from "../../interfaces/ILineOfCredit.sol";
import { ISecuredLine } from "../../interfaces/ISecuredLine.sol";

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
    ) SpigotedLine(
        oracle_,
        arbiter_,
        borrower_,
        spigot_,
        swapTarget_,
        ttl_,
        defaultSplit_
    ) EscrowedLine(escrow_) {

    }

  function _init() internal override(SpigotedLine, EscrowedLine) virtual returns(LineLib.STATUS) {
     LineLib.STATUS s =  LineLib.STATUS.ACTIVE;
    
    if(SpigotedLine._init() != s || EscrowedLine._init() != s) {
      return LineLib.STATUS.UNINITIALIZED;
    }
    
    return s;
  }

  function rollover(address newLine)
    external
    onlyBorrower
    override
    returns(bool)
  {
    // require all debt successfully paid already
    if(status != LineLib.STATUS.REPAID) { revert DebtOwed(); }
    // require new line isn't activated yet
    if(ILineOfCredit(newLine).status() != LineLib.STATUS.UNINITIALIZED) { revert BadNewLine(); }
    // we dont check borrower is same on both lines because borrower might want new address managing new line
    EscrowedLine._rollover(newLine);
    SpigotedLineLib.rollover(address(spigot), newLine);

    // ensure that line we are sending can accept them. There is no recovery option.
    if(ILineOfCredit(newLine).init() != LineLib.STATUS.ACTIVE) { revert BadRollover(); }

    return true;
  }


  // Liquidation
  /**
   * @notice - Forcefully take collateral from borrower and repay debt for lender
   * @dev - only called by neutral arbiter party/contract
   * @dev - `status` must be LIQUIDATABLE
   * @dev - callable by `arbiter`
   * @param amount - amount of `targetToken` expected to be sold off in  _liquidate
   * @param targetToken - token in escrow that will be sold of to repay position
   */

  function liquidate(
    uint256 amount,
    address targetToken
  )
    external
    whileBorrowing
    returns(uint256)
  {
    if(msg.sender != arbiter) { revert CallerAccessDenied(); }
    if(_updateStatus(_healthcheck()) != LineLib.STATUS.LIQUIDATABLE) {
      revert NotLiquidatable();
    }

    // send tokens to arbiter for OTC sales
    return _liquidate(ids[0], amount, targetToken, msg.sender);
  }

  
    /** @notice checks internal accounting logic for status and if ok, runs modules checks */
    function _healthcheck() internal override(EscrowedLine, LineOfCredit) returns(LineLib.STATUS) {
      LineLib.STATUS s = LineOfCredit._healthcheck();
      if(s != LineLib.STATUS.ACTIVE) {
        return s;
      }

      return EscrowedLine._healthcheck();
    }


    /// @notice all insolvency conditions must pass for call to succeed
    function _canDeclareInsolvent()
      internal
      virtual
      override(EscrowedLine, SpigotedLine)
      returns(bool)
    {
      return (
        EscrowedLine._canDeclareInsolvent() &&
        SpigotedLine._canDeclareInsolvent()
      );
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

pragma solidity 0.8.9;

import { IEscrow } from "../../interfaces/IEscrow.sol";
import { LineLib } from "../../utils/LineLib.sol";
import { IEscrowedLine } from "../../interfaces/IEscrowedLine.sol";
import { ILineOfCredit } from "../../interfaces/ILineOfCredit.sol";

abstract contract EscrowedLine is IEscrowedLine, ILineOfCredit {
  // contract holding all collateral for borrower
  IEscrow immutable public escrow;

  constructor(address _escrow) {
    escrow = IEscrow(_escrow);
  }

  function _init() internal virtual returns(LineLib.STATUS) {
    if(escrow.line() != address(this)) return LineLib.STATUS.UNINITIALIZED;
    return LineLib.STATUS.ACTIVE;
  }

  /** @dev see BaseLine._healthcheck */
  function _healthcheck() virtual internal returns(LineLib.STATUS) {
    if(escrow.isLiquidatable()) {
      return LineLib.STATUS.LIQUIDATABLE;
    }

    return LineLib.STATUS.ACTIVE;
  }

  /**
   * @notice sends escrowed tokens to liquidation. 
   *(@dev priviliegad function. Do checks before calling.
   * @param positionId - position being repaid in liquidation
   * @param amount - amount of tokens to take from escrow and liquidate
   * @param targetToken - the token to take from escrow
   * @param to - the liquidator to send tokens to. could be OTC address or smart contract
   * @return amount - the total amount of `targetToken` sold to repay credit
   *  
  */
  function _liquidate(
    bytes32 positionId,
    uint256 amount,
    address targetToken,
    address to
  )
    virtual internal
    returns(uint256)
  { 
    IEscrow escrow_ = escrow; // gas savings
    require(escrow_.liquidate(amount, targetToken, to));

    emit Liquidate(positionId, amount, targetToken, address(escrow_));

    return amount;
  }

  /**
   * @notice require all collateral sold off before declaring insolvent
   *(@dev priviliegad internal function.
   * @return if line is insolvent or not
  */
  function _canDeclareInsolvent() internal virtual returns(bool) {
    if(escrow.getCollateralValue() != 0) { revert NotInsolvent(address(escrow)); }
    return true;
  }

  function _rollover(address newLine) internal virtual returns(bool) {
    require(escrow.updateLine(newLine));
    return true;
  }
}

pragma solidity ^0.8.9;

import { Denominations } from "chainlink/Denominations.sol";
import { ReentrancyGuard } from "openzeppelin/security/ReentrancyGuard.sol";
import {LineOfCredit} from "./LineOfCredit.sol";
import {LineLib} from "../../utils/LineLib.sol";
import {CreditLib} from "../../utils/CreditLib.sol";
import {SpigotedLineLib} from "../../utils/SpigotedLineLib.sol";
import {MutualConsent} from "../../utils/MutualConsent.sol";
import {ISpigot} from "../../interfaces/ISpigot.sol";
import {ISpigotedLine} from "../../interfaces/ISpigotedLine.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20}  from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract SpigotedLine is ISpigotedLine, LineOfCredit, ReentrancyGuard {
    using SafeERC20 for IERC20;

    ISpigot public immutable spigot;

    // 0x exchange to trade spigot revenue for credit tokens for
    address payable public immutable swapTarget;

    // amount of revenue to take from spigot if line is healthy
    uint8 public immutable defaultRevenueSplit;

    // credit tokens we bought from revenue but didn't use to repay line
    // needed because Revolver might have same token held in contract as being bought/sold
    mapping(address => uint256) private unusedTokens;

    /**
     * @notice - LineofCredit contract with additional functionality for integrating with Spigot and borrower revenue streams to repay lines
     * @param oracle_ - price oracle to use for getting all token values
     * @param arbiter_ - neutral party with some special priviliges on behalf of borrower and lender
     * @param borrower_ - the debitor for all credit positions in this contract
     * @param swapTarget_ - 0x protocol exchange address to send calldata for trades to
     * @param ttl_ - the debitor for all credit positions in this contract
     * @param defaultRevenueSplit_ - the debitor for all credit positions in this contract
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

    function _init() internal virtual override(LineOfCredit) returns(LineLib.STATUS) {
      if(spigot.owner() != address(this)) return LineLib.STATUS.UNINITIALIZED;
      return LineOfCredit._init();
    }

    function unused(address token) external view returns (uint256) {
        return unusedTokens[token];
    }

    function _canDeclareInsolvent() internal virtual override returns(bool) {
        return SpigotedLineLib.canDeclareInsolvent(address(spigot), arbiter);
    }


    /**

   * @notice - Claims revenue tokens from Spigot attached to borrowers revenue generating tokens
               and sells them via 0x protocol to repay credits
   * @dev    - callable `borrower` + `lender`
   * @notice see _repay() for more details
   * @param claimToken - The revenue token escrowed by Spigot to claim and use to repay credit
   * @param zeroExTradeData - data generated by 0x API to trade `claimToken` against their exchange contract
  */
    function claimAndRepay(address claimToken, bytes calldata zeroExTradeData)
        external
        whileBorrowing
        nonReentrant
        returns (uint256)
    {
        bytes32 id = ids[0];
        Credit memory credit = credits[id];
        credit =  _accrue(credit, id);

        if (msg.sender != borrower && msg.sender != credit.lender) {
            revert CallerAccessDenied();
        }

        uint256 newTokens = claimToken == credit.token ?
          spigot.claimEscrow(claimToken) : // same asset. dont trade
          _claimAndTrade(                   // trade revenue token for debt obligation
              claimToken,
              credit.token,
              zeroExTradeData
          );

        // TODO abstract this into library func

        uint256 repaid = newTokens + unusedTokens[credit.token];
        uint256 debt = credit.interestAccrued + credit.principal;

        // cap payment to debt value
        if (repaid > debt) repaid = debt;
        // update unused amount based on usage
        if (repaid > newTokens) {
            // using bought + unused to repay line
            unusedTokens[credit.token] -= repaid - newTokens;
        } else {
            //  high revenue and bought more than we need
            unusedTokens[credit.token] += newTokens - repaid;
        }

        credits[id] = _repay(credit, id, repaid);

        emit RevenuePayment(claimToken, repaid);
    }

    function useAndRepay(uint256 amount) external whileBorrowing returns(bool) {
      bytes32 id = ids[0];
      Credit memory credit = credits[id];
      if (msg.sender != borrower && msg.sender != credit.lender) {
        revert CallerAccessDenied();
      }
      require(amount <= unusedTokens[credit.token]);
      unusedTokens[credit.token] -= amount;

      credits[id] = _repay(_accrue(credit, id), id, amount);

      return true;
    }

    /**
     * @notice allows tokens in escrow to be sold immediately but used to pay down credit later
     * @dev ensures first token in repayment queue is being bought
     * @dev    - callable `arbiter` + `borrower`
     * @param claimToken - the token escrowed in spigot to sell in trade
     * @param zeroExTradeData - 0x API data to use in trade to sell `claimToken` for `credits[ids[0]]`
     * returns - amount of credit tokens bought
     */
    function claimAndTrade(address claimToken, bytes calldata zeroExTradeData)
        external
        whileBorrowing
        nonReentrant
        returns (uint256)
    {
        require(msg.sender == borrower);

        address targetToken = credits[ids[0]].token;
        uint256 newTokens = claimToken == targetToken ?
          spigot.claimEscrow(claimToken) : // same asset. dont trade
          _claimAndTrade(                   // trade revenue token for debt obligation
              claimToken,
              targetToken,
              zeroExTradeData
          );

        // add bought tokens to unused balance
        unusedTokens[targetToken] += newTokens;
        return newTokens;
    }

    /**
     * @notice allows tokens in escrow to be sold immediately but used to pay down credit later
     * @dev MUST trade all available claim tokens to target
     * @dev    priviliged internal function
     * @param claimToken - the token escrowed in spigot to sell in trade
     * @param targetToken - the token borrow owed debt in and needs to buy. Always `credits[ids[0]].token`
     * @param zeroExTradeData - 0x API data to use in trade to sell `claimToken` for target
     * returns - amount of target tokens bought
     */

    function _claimAndTrade(
      address claimToken,
      address targetToken,
      bytes calldata zeroExTradeData
    )
        internal
        returns (uint256)
    {
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

    /**
     * @notice changes the revenue split between borrower treasury and lan repayment based on line health
     * @dev    - callable `arbiter` + `borrower`
     * @param revenueContract - spigot to update
     * @return whether or not split was updated
     */
    function updateOwnerSplit(address revenueContract) external returns (bool) {
        return SpigotedLineLib.updateSplit(
          address(spigot),
          revenueContract,
          _updateStatus(_healthcheck()),
          defaultRevenueSplit
        );
    }

    /**
     * @notice - allow Line to add new revenue streams to reapy credit
     * @dev    - see Spigot.addSpigot()
     * @dev    - callable `arbiter` + `borrower`
     */
    function addSpigot(
        address revenueContract,
        ISpigot.Setting calldata setting
    )
        external
        mutualConsent(arbiter, borrower)
        returns (bool)
    {
        return spigot.addSpigot(revenueContract, setting);
    }

    /**
     * @notice - allow borrower to call functions on their protocol to maintain it and keep earning revenue
     * @dev    - see Spigot.updateWhitelistedFunction()
     * @dev    - callable `arbiter`
     */
    function updateWhitelist(bytes4 func, bool allowed)
        external
        returns (bool)
    {
        require(msg.sender == arbiter);
        return spigot.updateWhitelistedFunction(func, allowed);
    }

    /**

   * @notice -  transfers revenue streams to borrower if repaid or arbiter if liquidatable
             -  doesnt transfer out if line is unpaid and/or healthy
   * @dev    - callable by anyone 
   * @return - whether or not spigot was released
  */
    function releaseSpigot() external returns (bool) {
        return SpigotedLineLib.releaseSpigot(
          address(spigot),
          _updateStatus(_healthcheck()),
          borrower,
          arbiter
        );
    }

  /**
   * @notice - sends unused tokens to borrower if repaid or arbiter if liquidatable
             -  doesnt send tokens out if line is unpaid but healthy
   * @dev    - callable by anyone 
   * @param token - token to take out
  */
    function sweep(address to, address token) external nonReentrant returns (uint256) {
        uint256 amount = unusedTokens[token];
        delete unusedTokens[token];

        bool success = SpigotedLineLib.sweep(
          to,
          token,
          amount,
          _updateStatus(_healthcheck()),
          borrower,
          arbiter
        );

        return success ? amount : 0;
    }

    // allow claiming/trading in ETH
    receive() external payable {}
}

pragma solidity 0.8.9;

import { ISpigot } from "../interfaces/ISpigot.sol";
import { ISpigotedLine } from "../interfaces/ISpigotedLine.sol";
import { LineLib } from "../utils/LineLib.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";

import { Denominations } from "chainlink/Denominations.sol";

library SpigotedLineLib {

    // max revenue to take from spigot if line is in distress
    uint8 constant MAX_SPLIT = 100;

    error NoSpigot();

    error TradeFailed();

    error BadTradingPair();

    error CallerAccessDenied();
    
    error ReleaseSpigotFailed();

    error NotInsolvent(address module);

    error UsedExcessTokens(address token, uint256 amountAvailable);


    event TradeSpigotRevenue(
        address indexed revenueToken,
        uint256 revenueTokenAmount,
        address indexed debtToken,
        uint256 indexed debtTokensBought
    );


    /**
     * @notice allows tokens in escrow to be sold immediately but used to pay down credit later
     * @dev MUST trade all available claim tokens to target
     * @dev    priviliged internal function
     * @param claimToken - the token escrowed in spigot to sell in trade
     * @param targetToken - the token borrow owed debt in and needs to buy. Always `credits[ids[0]].token`
     * @param swapTarget  - 0x exchange router address to call for trades
     * @param spigot      - spigot to claim from. Must be owned by adddress(this)
     * @param unused      - current amount of unused claimTokens
     * @param zeroExTradeData - 0x API data to use in trade to sell `claimToken` for target
     * @return (uint, uint) - (amount of target tokens bought, total unused claim tokens after trade)
     */
    function claimAndTrade(
        address claimToken,
        address targetToken,
        address payable swapTarget,
        address spigot,
        uint256 unused,
        bytes calldata zeroExTradeData
    )
        external 
        returns(uint256, uint256)
    {
        // can not trade into same token. causes double count for unused tokens
        if(claimToken == targetToken) { revert BadTradingPair(); }

        // snapshot token balances now to diff after trade executes
        uint256 oldClaimTokens = LineLib.getBalance(claimToken);
        uint256 oldTargetTokens = LineLib.getBalance(targetToken);
        
        // claim has to be called after we get balance
        uint256 claimed = ISpigot(spigot).claimEscrow(claimToken);

        trade(
            claimed + unused,
            claimToken,
            swapTarget,
            zeroExTradeData
        );
        
        // underflow revert ensures we have more tokens than we started with
        uint256 tokensBought = LineLib.getBalance(targetToken) - oldTargetTokens;

        if(tokensBought == 0) { revert TradeFailed(); } // ensure tokens bought

        uint256 newClaimTokens = LineLib.getBalance(claimToken);

        // ideally we could use oracle to calculate # of tokens to receive
        // but sellToken might not have oracle. buyToken must have oracle

        emit TradeSpigotRevenue(
            claimToken,
            claimed,
            targetToken,
            tokensBought
        );

        // used reserve revenue to repay debt
        if(oldClaimTokens > newClaimTokens) {
          uint256 diff = oldClaimTokens - newClaimTokens;

          // used more tokens than we had in revenue reserves.
          // prevent borrower from pulling idle lender funds to repay other lenders
          if(diff > unused) revert UsedExcessTokens(claimToken,  unused); 
          // reduce reserves by consumed amount
          else return (
            tokensBought,
            unused - diff
          );
        } else { unchecked {
          // excess revenue in trade. store in reserves
          return (
            tokensBought,
            unused + (newClaimTokens - oldClaimTokens)
          );
        } }
    }

    function trade(
        uint256 amount,
        address sellToken,
        address payable swapTarget,
        bytes calldata zeroExTradeData
    ) 
        public
        returns(bool)
    {
        if (sellToken == Denominations.ETH) {
            // if claiming/trading eth send as msg.value to dex
            (bool success, ) = swapTarget.call{value: amount}(zeroExTradeData);
            if(!success) { revert TradeFailed(); }
        } else {
            IERC20(sellToken).approve(swapTarget, amount);
            (bool success, ) = swapTarget.call(zeroExTradeData);
            if(!success) { revert TradeFailed(); }
        }

        return true;
    }


    /**
     * @notice cleanup function when borrower this line ends 
     */
    function rollover(address spigot, address newLine) external returns(bool) {
      require(ISpigot(spigot).updateOwner(newLine));
      return true;
    }

    function canDeclareInsolvent(address spigot, address arbiter) external view returns (bool) {
            // Must have called releaseSpigot() and sold off protocol / revenue streams already
      address owner_ = ISpigot(spigot).owner();
      if(
        address(this) == owner_ ||
        arbiter == owner_
      ) { revert NotInsolvent(spigot); }
      // no additional logic in LineOfCredit to include
      return true;
    }


    /**
     * @notice changes the revenue split between borrower treasury and lan repayment based on line health
     * @dev    - callable `arbiter` + `borrower`
     * @param revenueContract - spigot to update
     * @return whether or not split was updated
     */
    function updateSplit(address spigot, address revenueContract, LineLib.STATUS status, uint8 defaultSplit) external returns (bool) {
        (,uint8 split,  ,bytes4 transferFunc) = ISpigot(spigot).getSetting(revenueContract);

        if(transferFunc == bytes4(0)) { revert NoSpigot(); }

        if(status == LineLib.STATUS.ACTIVE && split != defaultSplit) {
            // if line is healthy set split to default take rate
            return ISpigot(spigot).updateOwnerSplit(revenueContract, defaultSplit);
        } else if (status == LineLib.STATUS.LIQUIDATABLE && split != MAX_SPLIT) {
            // if line is in distress take all revenue to repay line
            return ISpigot(spigot).updateOwnerSplit(revenueContract, MAX_SPLIT);
        }

        return false;
    }


    /**

   * @notice -  transfers revenue streams to borrower if repaid or arbiter if liquidatable
             -  doesnt transfer out if line is unpaid and/or healthy
   * @dev    - callable by anyone 
   * @return - whether or not spigot was released
  */
    function releaseSpigot(address spigot, LineLib.STATUS status, address borrower, address arbiter) external returns (bool) {
        if (status == LineLib.STATUS.REPAID) {
          if (msg.sender != borrower) { revert CallerAccessDenied(); } 
          if(!ISpigot(spigot).updateOwner(borrower)) { revert ReleaseSpigotFailed(); }
          return true;
        }

        if (status == LineLib.STATUS.LIQUIDATABLE) {
          if (msg.sender != arbiter) { revert CallerAccessDenied(); } 
          if(!ISpigot(spigot).updateOwner(arbiter)) { revert ReleaseSpigotFailed(); }
          return true;
        }

        return false;
    }


        /**

   * @notice -  transfers revenue streams to borrower if repaid or arbiter if liquidatable
             -  doesnt transfer out if line is unpaid and/or healthy
   * @dev    - callable by anyone 
   * @return - whether or not spigot was released
  */
    function sweep(address to, address token, uint256 amount, LineLib.STATUS status, address borrower, address arbiter) external returns (bool) {
        if(amount == 0) { revert UsedExcessTokens(token, 0); }

        if (status == LineLib.STATUS.REPAID) {
            if (msg.sender != borrower) { revert CallerAccessDenied(); } 
            return LineLib.sendOutTokenOrETH(token, to, amount);

        }

        if (status == LineLib.STATUS.LIQUIDATABLE) {
            if (msg.sender != arbiter) { revert CallerAccessDenied(); } 
            return LineLib.sendOutTokenOrETH(token, to, amount);
        }

        return false;
    }
}

pragma solidity ^0.8.9;

import { Denominations } from "chainlink/Denominations.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20}  from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import {LineLib} from "../../utils/LineLib.sol";
import {CreditLib} from "../../utils/CreditLib.sol";
import {CreditListLib} from "../../utils/CreditListLib.sol";
import {MutualConsent} from "../../utils/MutualConsent.sol";
import {InterestRateCredit} from "../interest-rate/InterestRateCredit.sol";

import {IOracle} from "../../interfaces/IOracle.sol";
import {ILineOfCredit} from "../../interfaces/ILineOfCredit.sol";

contract LineOfCredit is ILineOfCredit, MutualConsent {
    using SafeERC20 for IERC20;

    using CreditListLib for bytes32[];

    uint256 public immutable deadline;

    address public immutable borrower;

    address public immutable arbiter;

    IOracle public immutable oracle;

    InterestRateCredit public immutable interestRate;

    uint256 private count; // amount of open positions. ids.length includes null items

    bytes32[] public ids; // all active positions

    mapping(bytes32 => Credit) public credits; // id -> Credit

    // Line Financials aggregated accross all existing  Credit
    LineLib.STATUS public status;

    /**
   * @dev - Line borrower and proposed lender agree on terms
            and add it to potential options for borrower to drawdown on
            Lender and borrower must both call function for MutualConsent to add credit position to Line
   * @param oracle_ - price oracle to use for getting all token values
   * @param arbiter_ - neutral party with some special priviliges on behalf of borrower and lender
   * @param borrower_ - the debitor for all credit positions in this contract
   * @param ttl_ - time to live for line of credit contract across all lenders
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
        deadline = block.timestamp + ttl_;
        interestRate = new InterestRateCredit();

        emit DeployLine(oracle_, arbiter_, borrower_);
    }

    function init() external virtual returns(LineLib.STATUS) {
      if(status != LineLib.STATUS.UNINITIALIZED) { revert AlreadyInitialized(); }
      return _updateStatus(_init());
    }

    function _init() internal virtual returns(LineLib.STATUS) {
       // If no modules then line is immediately active
      return LineLib.STATUS.ACTIVE;
    }

    ///////////////
    // MODIFIERS //
    ///////////////

    modifier whileActive() {
        if(status != LineLib.STATUS.ACTIVE) { revert NotActive(); }
        _;
    }

    modifier whileBorrowing() {
        if(count == 0 || credits[ids[0]].principal == 0) { revert NotBorrowing(); }
        _;
    }

    modifier onlyBorrower() {
        if(msg.sender != borrower) { revert CallerAccessDenied(); }
        _;
    }

    /** @notice - mutualConsent but uses position to get lender address instead of passing it in directly */
    modifier mutualConsentById(address _signerOne, bytes32 id) {
      if(_mutualConsent(_signerOne, credits[id].lender))  {
        // Run whatever code needed 2/2 consent
        _;
      }
    }

    function healthcheck() external returns (LineLib.STATUS) {
        // can only check if line has been initialized
        require(uint(status) >= uint( LineLib.STATUS.ACTIVE));
        return _updateStatus(_healthcheck());
    }

    /** 
     * @notice - getter for amount of active ids + total ids in list
     * @return - (uint, uint) - active positions, total length
    */
    function counts() external view returns (uint256, uint256) {
        return (count, ids.length);
    }

    function _healthcheck() internal virtual returns (LineLib.STATUS) {
        // if line is in a final end state then do not run _healthcheck()
        LineLib.STATUS s = status;
        if (
            s == LineLib.STATUS.REPAID ||               // end state - good
            s == LineLib.STATUS.INSOLVENT               // end state - bad
        ) {
            return status;
        }

        // Liquidate if all lines of credit arent closed by end of term
        if (block.timestamp >= deadline && count > 0) {
            emit Default(ids[0]); // can query all defaulted positions offchain once event picked up
            return LineLib.STATUS.LIQUIDATABLE;
        }

        return LineLib.STATUS.ACTIVE;
    }

    /**
     * @notice - Allow arbiter to signify that borrower is incapable of repaying debt permanently
     *           Recoverable funds for lender after declaring insolvency = deposit + interestRepaid - principal
     * @dev    - Needed for onchain impairment accounting e.g. updating ERC4626 share price
     *           MUST NOT have collateral left for call to succeed.
     *           Callable only by arbiter. 
     * @return bool - If borrower is insolvent or not
     */
    function declareInsolvent() external whileBorrowing returns(bool) {
        if(arbiter != msg.sender) { revert CallerAccessDenied(); }
        if(LineLib.STATUS.LIQUIDATABLE != _updateStatus(_healthcheck())) {
            revert NotLiquidatable();
        }

        if(_canDeclareInsolvent()) {
            _updateStatus(LineLib.STATUS.INSOLVENT);
            return true;
        } else {
          return false;
        }
    }

    function _canDeclareInsolvent() internal virtual returns(bool) {
        // logic updated in Spigoted and Escrowed lines
        return true;
    }

    /**
  * @notice - Returns total credit obligation of borrower.
              Aggregated across all lenders.
              Denominated in USD 1e8.
  * @dev    - callable by anyone
  */
    function updateOutstandingDebt() external override returns (uint256, uint256) {
        return _updateOutstandingDebt();
    }

    function _updateOutstandingDebt()
        internal
        returns (uint256 principal, uint256 interest)
    {
        uint256 len = ids.length;
        if (len == 0) return (0, 0);

        bytes32 id;
        address oracle_ = address(oracle);  // gas savings
        address interestRate_ = address(interestRate);
        
        for (uint256 i; i < len; ++i) {
            id = ids[i];

            // gas savings. capped to len. inc before early continue
            

            // null element in array
            if(id == bytes32(0)) { continue; }

            (Credit memory c, uint256 _p, uint256 _i) = CreditLib.getOutstandingDebt(
              credits[id],
              id,
              oracle_,
              interestRate_
            );
            // update aggregate usd value
            principal += _p;
            interest += _i;
            // update position data
            credits[id] = c;
        }
    }

    /**
     * @dev - Loops over all credit positions, calls InterestRate module with position data,
            then updates `interestAccrued` on position with returned data.
    */
    function accrueInterest() external override returns(bool) {
        uint256 len = ids.length;
        bytes32 id;
        for (uint256 i; i < len; ++i) {
          id = ids[i];
          Credit memory credit = credits[id];
          credits[id] = _accrue(credit, id);
          
        }
        
        return true;
    }

    function _accrue(Credit memory credit, bytes32 id) internal returns(Credit memory) {
      return CreditLib.accrue(credit, id, address(interestRate));
    }

    /**
   * @notice        - Line borrower and proposed lender agree on terms
                    and add it to potential options for borrower to drawdown on
                    Lender and borrower must both call function for MutualConsent to add credit position to Line
   * @dev           - callable by `lender` and `borrower
   * @param drate   - interest rate in bps on funds drawndown on LoC
   * @param frate   - interest rate in bps on all unused funds in LoC
   * @param amount  - amount of `token` to initially deposit
   * @param token   - the token to be lent out
   * @param lender  - address that will manage credit position 
  */
    function addCredit(
        uint128 drate,
        uint128 frate,
        uint256 amount,
        address token,
        address lender
    )
        external
        payable
        override
        whileActive
        mutualConsent(lender, borrower)
        returns (bytes32)
    {
        LineLib.receiveTokenOrETH(token, lender, amount);

        bytes32 id = _createCredit(lender, token, amount);

        require(interestRate.setRate(id, drate, frate));
        
        return id;
    }

    /**
    * @notice           - Let lender and borrower update rates on a aposition
    *                   - can set Rates even when LIQUIDATABLE for refinancing
    * @dev              - include lender in params for cheap gas and consistent API for mutualConsent
    * @dev              - callable by borrower or any lender
    * @param id - credit id that we are updating
    * @param drate      - new drawn rate
    * @param frate      - new facility rate
    
    */
    function setRates(
        bytes32 id,
        uint128 drate,
        uint128 frate
    )
      external
      override
      mutualConsentById(borrower, id)
      returns (bool)
    {
        Credit memory credit = credits[id];
        credits[id] = _accrue(credit, id);
        require(interestRate.setRate(id, drate, frate));
        emit SetRates(id, drate, frate);
        return true;
    }


 /**
    * @notice           - Let lender and borrower increase total capacity of position
    *                   - can only increase while line is healthy and ACTIVE.
    * @dev              - include lender in params for cheap gas and consistent API for mutualConsent
    * @dev              - callable by borrower    
    * @param id         - credit id that we are updating
    * @param amount     - amount to increase deposit / capaciity by
    */
    function increaseCredit(bytes32 id, uint256 amount)
      external
      payable
      override
      whileActive
      mutualConsentById(borrower, id)
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

    /**
    * @notice - Transfers enough tokens to repay entire credit position from `borrower` to Line contract.
    * @dev - callable by borrower    
    */
    function depositAndClose()
        external
        payable
        override
        whileBorrowing
        onlyBorrower
        returns (bool)
    {
        bytes32 id = ids[0];
        Credit memory credit = credits[id];
        credit = _accrue(credit, id);

        uint256 totalOwed = credit.principal + credit.interestAccrued;

        // borrower deposits remaining balance not already repaid and held in contract
        LineLib.receiveTokenOrETH(credit.token, msg.sender, totalOwed);

        // clear the debt then close and delete position
        _close(_repay(credit, id, totalOwed), id);

        return true;
    }

    /**
     * @dev - Transfers token used in credit position from msg.sender to Line contract.
     * @dev - callable by anyone
     * @notice - see _repay() for more details
     * @param amount - amount of `token` in `id` to pay back
     */
    function depositAndRepay(uint256 amount)
        external
        payable
        override
        whileBorrowing
        returns (bool)
    {
        bytes32 id = ids[0];
        Credit memory credit = credits[id];
        credit = _accrue(credit, id);

        require(amount <= credit.principal + credit.interestAccrued);

        credits[id] = _repay(credit, id, amount);

        LineLib.receiveTokenOrETH(credit.token, msg.sender, amount);

        return true;
    }

    ////////////////////
    // FUND TRANSFERS //
    ////////////////////

    /**
     * @dev - Transfers tokens from Line to lender.
     *        Only allowed to withdraw tokens not already lent out (prevents bank run)
     * @dev - callable by lender on `id`
     * @param id - the credit position to draw down credit on
     * @param amount - amount of tokens borrower wants to take out
     */
    function borrow(bytes32 id, uint256 amount)
        external
        override
        whileActive
        onlyBorrower
        returns (bool)
    {
        Credit memory credit = credits[id];
        credit = _accrue(credit, id);

        if(amount > credit.deposit - credit.principal) { revert NoLiquidity() ; }

        credit.principal += amount;

        credits[id] = credit; // save new debt before healthcheck

        if(_updateStatus(_healthcheck()) != LineLib.STATUS.ACTIVE) { 
            revert NotActive();
        }

        credits[id] = credit;

        LineLib.sendOutTokenOrETH(credit.token, borrower, amount);

        emit Borrow(id, amount);

        _sortIntoQ(id);

        return true;
    }

    /**
     * @dev - Transfers tokens from Line to lender.
     *        Only allowed to withdraw tokens not already lent out (prevents bank run)
     * @dev - callable by lender on `id`
     * @param id -the credit position to pay down credit on and close
     * @param amount - amount of tokens lnder would like to withdraw (withdrawn amount may be lower)
     */
    function withdraw(bytes32 id, uint256 amount)
        external
        override
        returns (bool)
    {
        Credit memory credit = credits[id];

        if(msg.sender != credit.lender) { revert CallerAccessDenied(); }

        // accrue interest and withdraw amount
        credits[id] = CreditLib.withdraw(_accrue(credit, id), id, amount);

        LineLib.sendOutTokenOrETH(credit.token, credit.lender, amount);

        return true;
    }

    /**
     * @dev - Deletes credit position preventing any more borrowing.
     *      - Only callable by borrower or lender for credit position
     *      - Requires that the credit has already been paid off
     * @dev - callable by `borrower`
     * @param id -the credit position to close
     */
    function close(bytes32 id) external payable override returns (bool) {
        Credit memory credit = credits[id];
        address b = borrower; // gas savings
        if(msg.sender != credit.lender && msg.sender != b) {
          revert CallerAccessDenied();
        }

        // ensure all money owed is accounted for
        credit = _accrue(credit, id);
        uint256 facilityFee = credit.interestAccrued;
        if(facilityFee > 0) {
          // only allow repaying interest since they are skipping repayment queue.
          // If principal still owed, _close() MUST fail
          LineLib.receiveTokenOrETH(credit.token, b, facilityFee);

          credit = _repay(credit, id, facilityFee);
        }

        _close(credit, id); // deleted; no need to save to storage

        return true;
    }

    //////////////////////
    //  Internal  funcs //
    //////////////////////

    function _updateStatus(LineLib.STATUS status_) internal returns(LineLib.STATUS) {
      if(status == status_) return status_;
      emit UpdateStatus(uint256(status_));
      return (status = status_);
    }

    function _createCredit(
        address lender,
        address token,
        uint256 amount
    )
        internal
        returns (bytes32 id)
    {
        id = CreditLib.computeId(address(this), lender, token);
        // MUST not double add position. otherwise we can not _close()
        if(credits[id].lender != address(0)) { revert PositionExists(); }

        credits[id] = CreditLib.create(id, amount, lender, token, address(oracle));

        ids.push(id); // add lender to end of repayment queue
        
        unchecked { ++count; }

        return id;
    }

  /**
   * @dev - Reduces `principal` and/or `interestAccrued` on credit position, increases lender's `deposit`.
            Reduces global USD principal and interestUsd values.
            Expects checks for conditions of repaying and param sanitizing before calling
            e.g. early repayment of principal, tokens have actually been paid by borrower, etc.
   * @param id - credit position struct with all data pertaining to line
   * @param amount - amount of token being repaid on credit position
  */
    function _repay(Credit memory credit, bytes32 id, uint256 amount)
        internal
        returns (Credit memory)
    { 
        credit = CreditLib.repay(credit, id, amount);

        // if credit fully repaid then remove lender from repayment queue
        if (credit.principal == 0) ids.stepQ();

        return credit;
    }

    /**
     * @notice - checks that credit is fully repaid and remvoes from available lines of credit.
     * @dev deletes Credit storage. Store any data u might need later in call before _close()
     */
    function _close(Credit memory credit, bytes32 id) internal virtual returns (bool) {
        if(credit.principal > 0) { revert CloseFailedWithPrincipal(); }

        // return the lender's deposit
        if (credit.deposit + credit.interestRepaid > 0) {
            LineLib.sendOutTokenOrETH(
                credit.token,
                credit.lender,
                credit.deposit + credit.interestRepaid
            );
        }

        delete credits[id]; // gas refunds

        // remove from active list
        ids.removePosition(id);
        unchecked { --count; }

        // brick line contract if all positions closed
        if (count == 0) { _updateStatus(LineLib.STATUS.REPAID); }

        emit CloseCreditPosition(id);

        return true;
    }

    /**
     * @notice - Insert `p` into the next availble FIFO position in repayment queue
               - once earliest slot is found, swap places with `p` and position in slot.
     * @param p - position id that we are trying to find appropriate place for
     * @return
     */
    function _sortIntoQ(bytes32 p) internal returns (bool) {
        uint256 lastSpot = ids.length - 1;
        uint256 nextQSpot = lastSpot;
        bytes32 id;
        for (uint256 i; i <= lastSpot; ++i) {
            id = ids[i];
            if (p != id) {

              // Since we aren't constantly trimming array size to to remove empty elements
              // we should try moving elemtns to front of array in this func to reduce gas costs 
              // only practical if > 10 lenders tho
              // just inc an vacantSlots and push each id to i - vacantSlot and count = len - vacantSlot

                if (
                  id == bytes32(0) ||       // deleted element
                  nextQSpot != lastSpot ||  // position already found. skip to find `p` asap
                  credits[id].principal > 0 //`id` should be placed before `p` 
                ) continue;
                nextQSpot = i;              // index of first undrawn line found
            } else {
                if(nextQSpot == lastSpot) return true; // nothing to update
                // swap positions
                ids[i] = ids[nextQSpot];    // id put into old `p` position
                ids[nextQSpot] = p;       // p put at target index
                return true; 
            }
          
        }
    }
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

interface ISecuredLine {
  // Rollover
  error DebtOwed();
  error BadNewLine();
  error BadRollover();

  // Borrower functions
  function rollover(address newLine) external returns(bool);
}

pragma solidity ^0.8.9;

interface IInterestRateCredit {
  struct Rate {
    // interest rate on amount currently being borrower
    // in bps, 4 decimals
    uint128 drawnRate;
    // interest rate on amount deposited by lender but not currently being borrowed
    // in bps, 4 decimals
    uint128 facilityRate;
    // timestamp that interest was last accrued on this position
    uint256 lastAccrued;
  }

  function accrueInterest(
    bytes32 positionId,
    uint256 drawnAmount,
    uint256 facilityAmount
  ) external returns(uint256);

  function setRate(
    bytes32 positionId,
    uint128 drawnRate,
    uint128 facilityRate
  ) external returns(bool);
}

pragma solidity 0.8.9;

interface IOracle {
    /** current price for token asset. denominated in USD */
    function getLatestAnswer(address token) external returns(int);
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

    // State var etters. 

    function line() external returns(address);

    function oracle() external returns(address);

    function borrower() external returns(address);

    function minimumCollateralRatio() external returns(uint32);

    // Functions 

    function isLiquidatable() external returns(bool);

    function updateLine(address line_) external returns(bool);

    function getCollateralRatio() external returns(uint);

    function getCollateralValue() external returns(uint);

    function enableCollateral(address token) external returns(bool);

    function addCollateral(uint amount, address token) external payable returns(uint);

    function releaseCollateral(uint amount, address token, address to) external returns(uint);
    
    function liquidate(uint amount, address token, address to) external returns(bool);
}

pragma solidity 0.8.9;

interface IEscrowedLine {
  event Liquidate(bytes32 indexed positionId, uint256 indexed amount, address indexed token, address escrow);

  function liquidate(uint256 amount, address targetToken) external returns(uint256);
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

    // Mapping of upgradable units and if consent has been initialized by other party
    mapping(bytes32 => bool) public mutualConsents;

    error Unauthorized();

    /* ============ Events ============ */

    event MutualConsentRegistered(
        bytes32 _consentHash
    );

    /* ============ Modifiers ============ */

    /**
    * @notice - allows a function to be called if only two specific stakeholders signoff on the tx data
    *         - signers can be anyone. only two signers per contract or dynamic signers per tx.
    */
    modifier mutualConsent(address _signerOne, address _signerTwo) {
      if(_mutualConsent(_signerOne, _signerTwo))  {
        // Run whatever code needed 2/2 consent
        _;
      }
    }

    function _mutualConsent(address _signerOne, address _signerTwo) internal returns(bool) {
        if(msg.sender != _signerOne && msg.sender != _signerTwo) { revert Unauthorized(); }

        address nonCaller = _getNonCaller(_signerOne, _signerTwo);

        // The consent hash is defined by the hash of the transaction call data and sender of msg,
        // which uniquely identifies the function, arguments, and sender.
        bytes32 expectedHash = keccak256(abi.encodePacked(msg.data, nonCaller));

        if (!mutualConsents[expectedHash]) {
            bytes32 newHash = keccak256(abi.encodePacked(msg.data, msg.sender));

            mutualConsents[newHash] = true;

            emit MutualConsentRegistered(newHash);

            return false;
        }

        delete mutualConsents[expectedHash];

        return true;
    }


    /* ============ Internal Functions ============ */

    function _getNonCaller(address _signerOne, address _signerTwo) internal view returns(address) {
        return msg.sender == _signerOne ? _signerTwo : _signerOne;
    }
}

pragma solidity ^0.8.9;

interface ISpigot {

    struct Setting {
        address token;                // token to claim as revenue from contract
        uint8 ownerSplit;             // x/100 % to Owner, rest to Treasury
        bytes4 claimFunction;         // function signature on contract to call and claim revenue
        bytes4 transferOwnerFunction; // function signature on conract to call and transfer ownership 
    }

    // Spigot Events

    event AddSpigot(address indexed revenueContract, address token, uint256 ownerSplit);

    event RemoveSpigot (address indexed revenueContract, address token);

    event UpdateWhitelistFunction(bytes4 indexed func, bool indexed allowed);

    event UpdateOwnerSplit(address indexed revenueContract, uint8 indexed split);

    event ClaimRevenue(address indexed token, uint256 indexed amount, uint256 escrowed, address revenueContract);

    event ClaimEscrow(address indexed token, uint256 indexed amount, address owner);

    // Stakeholder Events

    event UpdateOwner(address indexed newOwner);

    event UpdateOperator(address indexed newOperator);

    event UpdateTreasury(address indexed newTreasury);

    // Errors 
    error BadFunction();

    error ClaimFailed();

    error NoRevenue();

    error UnclaimedRevenue();

    error CallerAccessDenied();

    error BadSetting();
    

    // ops funcs 

    function claimRevenue(address revenueContract, bytes calldata data) external returns (uint256 claimed);
 
    function operate(address revenueContract, bytes calldata data) external returns (bool);


    // owner funcs  
    function claimEscrow(address token) external returns (uint256 claimed) ;
 
    function addSpigot(address revenueContract, Setting memory setting) external returns (bool);
 
    function removeSpigot(address revenueContract) external returns (bool);
        
  
    // stakeholder funcs 

    function updateOwnerSplit(address revenueContract, uint8 ownerSplit) external returns(bool);

    function updateOwner(address newOwner) external returns (bool);
 
    function updateOperator(address newOperator) external returns (bool);
 
    function updateTreasury(address newTreasury) external returns (bool);
 
    function updateWhitelistedFunction(bytes4 func, bool allowed) external returns (bool);

    // Getters 
    function owner() external view returns (address);
    function treasury() external view returns (address);
    function operator() external view returns (address);
    function isWhitelisted(bytes4 func) external view returns(bool);
    function getEscrowed(address token) external view returns(uint256);
    function getSetting(address revenueContract) external view
      returns (address token, uint8 split, bytes4 claimFunc, bytes4 transferFunc);

}

pragma solidity ^0.8.9;

import {ISpigot} from "./ISpigot.sol";

interface ISpigotedLine {
  event RevenuePayment(
    address indexed token,
    uint256 indexed amount
    // dont need to track value like other events because _repay already emits
    // this event is just semantics/helper to track payments from revenue specifically
  );




  // Borrower functions
  function useAndRepay(uint256 amount) external returns(bool);
  function claimAndRepay(address token, bytes calldata zeroExTradeData) external returns(uint256);
  function claimAndTrade(address token,  bytes calldata zeroExTradeData) external returns(uint256 tokensBought);
  
  // Manage Spigot functions
  function addSpigot(address revenueContract, ISpigot.Setting calldata setting) external returns(bool);
  function updateWhitelist(bytes4 func, bool allowed) external returns(bool);
  function updateOwnerSplit(address revenueContract) external returns(bool);
  function releaseSpigot() external returns(bool);


  function sweep(address to, address token) external returns(uint256);

  // getters
  function unused(address token) external returns(uint256);
}

pragma solidity 0.8.9;
import { ILineOfCredit } from "../interfaces/ILineOfCredit.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import { CreditLib } from "./CreditLib.sol";
/**
  * @title Debt DAO P2P Loan Library
  * @author Kiba Gateaux
  * @notice Core logic and variables to be reused across all Debt DAO Marketplace loans
 */
library CreditListLib {
    /**
     * @dev assumes that `id` is stored only once in `positions` array bc no reason for Loans to store multiple times.
          This means cleanup on _close() and checks on addDebtPosition are CRITICAL. If `id` is duplicated then the position can't be closed
     * @param ids - all current active positions on the loan
     * @param id - hash id that must be removed from active positions
     * @return newPositions - all active positions on loan after `id` is removed
     */
    function removePosition(bytes32[] storage ids, bytes32 id) external returns(bool) {
      uint256 len = ids.length;

      for(uint256 i; i < len; ++i) {
          if(ids[i] == id) {
              delete ids[i];
              return true;
          }
          
      }

      return true;
    }

    /**
     * @notice - removes debt position from head of repayement queue and puts it at end of line
     *         - moves 2nd in line to first
     * @param ids - all current active positions on the loan
     * @return newPositions - positions after moving first to last in array
     */
    function stepQ(bytes32[] storage ids) external returns(bool) {
      uint256 len = ids.length ;
      if(len <= 1) return true; // already ordered

      bytes32 last = ids[0];
      
      if(len == 2) {
        ids[0] = ids[1];
        ids[1] = last;
      } else {
        // move all existing ids up in line
        for(uint i = 1; i < len; ++i) {
          ids[i - 1] = ids[i]; // could also clean arr here like in _SoritIntoQ
          
        }
        // cycle first el back to end of queue
        ids[len - 1] = last;
      }
      
      return true;
    }
}

pragma solidity ^0.8.9;

import {IInterestRateCredit} from "../../interfaces/IInterestRateCredit.sol";

contract InterestRateCredit is IInterestRateCredit {
    uint256 constant ONE_YEAR = 365.25 days; // one year in sec to use in calculations for rates
    uint256 constant BASE_DENOMINATOR = 10000; // div 100 for %, div 100 for bps in numerator
    uint256 constant INTEREST_DENOMINATOR = ONE_YEAR * BASE_DENOMINATOR;

    address immutable lineContract;
    mapping(bytes32 => Rate) public rates; // id -> lending rates

    /**
     * @notice Interest contract for line of credit contracts
     */
    constructor() {
        lineContract = msg.sender;
    }

    ///////////  MODIFIERS  ///////////

    modifier onlyLineContract() {
        require(
            msg.sender == lineContract,
            "InterestRateCred: only line contract."
        );
        _;
    }

    ///////////  FUNCTIONS  ///////////

    /**
     * @dev accrueInterest function for revolver line
     * @dev    - callable by `line`
     * @param drawnBalance balance of drawn funds
     * @param facilityBalance balance of facility funds
     * @return repayBalance amount to be repaid for this interest period
     *
     */
    function accrueInterest(
        bytes32 id,
        uint256 drawnBalance,
        uint256 facilityBalance
    ) external override onlyLineContract returns (uint256) {
        return _accrueInterest(id, drawnBalance, facilityBalance);
    }

    function _accrueInterest(
        bytes32 id,
        uint256 drawnBalance,
        uint256 facilityBalance
    ) internal returns (uint256) {
        Rate memory rate = rates[id];
        uint256 timespan = block.timestamp - rate.lastAccrued;
        rates[id].lastAccrued = block.timestamp;

        // r = APR in BPS, x = # tokens, t = time
        // interest = (r * x * t) / 1yr / 100
        // facility = deposited - drawn (aka undrawn balance)
        return (((rate.drawnRate * drawnBalance * timespan) /
            INTEREST_DENOMINATOR) +
            ((rate.facilityRate * (facilityBalance - drawnBalance) * timespan) /
                INTEREST_DENOMINATOR));
    }

    /**
     * @notice update interest rates for a position
     * @dev - Line contract responsible for calling accrueInterest() before updateInterest() if necessary
     * @dev    - callable by `line`
     */
    function setRate(
        bytes32 id,
        uint128 drawnRate,
        uint128 facilityRate
    ) external onlyLineContract returns (bool) {
        rates[id] = Rate({
            drawnRate: drawnRate,
            facilityRate: facilityRate,
            lastAccrued: block.timestamp
        });

        return true;
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