pragma solidity 0.8.9;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { LineLib } from  "../../utils/LineLib.sol";
import { SpigotState, SpigotLib } from  "../../utils/SpigotLib.sol";

import {ISpigot} from "../../interfaces/ISpigot.sol";

/**
 * @title Spigot
 * @author Kiba Gateaux
 * @notice Contract allowing Owner to secure revenue streams from a DAO and split payments between them
 * @dev Should be deployed once per line. Can attach multiple revenue contracts
 */
contract Spigot is ISpigot, ReentrancyGuard {
    using SpigotLib for SpigotState;

    // Stakeholder variables
    
    SpigotState private state;

    /**
     *
     * @dev Configure data for contract owners and initial revenue contracts.
            Owner/operator/treasury can all be the same address
     * @param _owner Third party that owns rights to contract's revenue stream
     * @param _treasury Treasury of DAO that owns contract and receives leftover revenues
     * @param _operator Operational account of DAO that actively manages contract health
     *
     */
    constructor (
        address _owner,
        address _treasury,
        address _operator
    ) {
        state.owner = _owner;
        state.operator = _operator;
        state.treasury = _treasury;
    }

    function owner() public view returns (address) {
        return state.owner;
    }

    function operator() public view returns (address) {
        return state.operator;
    }

    function treasury() public view returns (address) {
        return state.treasury;
    }

    // ##########################
    // #####   Claimoooor   #####
    // ##########################

    /**

     * @notice - Claim push/pull payments through Spigots.
                 Calls predefined function in contract settings to claim revenue.
                 Automatically sends portion to treasury and escrows Owner's share.
     * @dev - callable by anyone
     * @param revenueContract Contract with registered settings to claim revenue from
     * @param data  Transaction data, including function signature, to properly claim revenue on revenueContract
     * @return claimed -  The amount of tokens claimed from revenueContract and split in payments to `owner` and `treasury`
    */
    function claimRevenue(address revenueContract, bytes calldata data)
        external nonReentrant
        returns (uint256 claimed)
    {
        return state.claimRevenue(revenueContract, data);
    }


    /**
     * @notice - Allows Spigot Owner to claim escrowed tokens from a revenue contract
     * @dev - callable by `owner`
     * @param token Revenue token that is being escrowed by spigot
     * @return claimed -  The amount of tokens claimed from revenue garnish by `owner`

    */
    function claimEscrow(address token)
        external
        nonReentrant
        returns (uint256 claimed) 
    {
        return state.claimEscrow(token);
    }


    // ##########################
    // ##### *ring* *ring*  #####
    // #####  OPERATOOOR    #####
    // #####  OPERATOOOR    #####
    // ##########################

    /**
     * @notice - Allows Operator to call whitelisted functions on revenue contracts to maintain their product
     *           while still allowing Spigot Owner to own revenue stream from contract
     * @dev - callable by `operator`
     * @param revenueContract - smart contract to call
     * @param data - tx data, including function signature, to call contract with
     */
    function operate(address revenueContract, bytes calldata data) external returns (bool) {
        return state.operate(revenueContract, data);
    }



    // ##########################
    // #####  Maintainooor  #####
    // ##########################

    /**
     * @notice Allow owner to add new revenue stream to spigot
     * @dev - callable by `owner`
     * @param revenueContract - smart contract to claim tokens from
     * @param setting - spigot settings for smart contract   
     */
    function addSpigot(address revenueContract, Setting memory setting) external returns (bool) {
        return state.addSpigot(revenueContract, setting);
    }

    /**

     * @notice - Change owner of revenue contract from Spigot (this contract) to Operator.
     *      Sends existing escrow to current Owner.
     * @dev - callable by `owner`
     * @param revenueContract - smart contract to transfer ownership of
     */
    function removeSpigot(address revenueContract)
        external
        returns (bool)
    {
       return state.removeSpigot(revenueContract);
    }

    function updateOwnerSplit(address revenueContract, uint8 ownerSplit)
        external
        returns(bool)
    {
      return state.updateOwnerSplit(revenueContract, ownerSplit);
    }

    /**
     * @notice - Update Owner role of Spigot contract.
     *      New Owner receives revenue stream split and can control Spigot
     * @dev - callable by `owner`
     * @param newOwner - Address to give control to
     */
    function updateOwner(address newOwner) external returns (bool) {
        return state.updateOwner(newOwner);
    }

    /**

     * @notice - Update Operator role of Spigot contract.
     *      New Operator can interact with revenue contracts.
     * @dev - callable by `operator`
     * @param newOperator - Address to give control to
     */
    function updateOperator(address newOperator) external returns (bool) {
        return state.updateOperator(newOperator);
    }
    
    /**

     * @notice - Update Treasury role of Spigot contract.
     *      New Treasury receives revenue stream split
     * @dev - callable by `treasury`
     * @param newTreasury - Address to divert funds to
     */
    function updateTreasury(address newTreasury) external returns (bool) {
        return state.updateTreasury(newTreasury);
    }

    /**

     * @notice - Allows Owner to whitelist function methods across all revenue contracts for Operator to call.
     *           Can whitelist "transfer ownership" functions on revenue contracts
     *           allowing Spigot to give direct control back to Operator.
     * @dev - callable by `owner`
     * @param func - smart contract function signature to whitelist
     * @param allowed - true/false whether to allow this function to be called by Operator
     */
     function updateWhitelistedFunction(bytes4 func, bool allowed) external returns (bool) {
        return state.updateWhitelistedFunction(func, allowed);
    }

    // ##########################
    // #####   GETTOOOORS   #####
    // ##########################

    /**
     * @notice - Retrieve amount of tokens tokens escrowed waiting for claim
     * @param token Revenue token that is being garnished from spigots
    */
    function getEscrowed(address token) external view returns (uint256) {
        return state.getEscrowed(token);
    }

    /**
     * @notice - If a function is callable on revenue contracts
     * @param func Function to check on whitelist 
    */

    function isWhitelisted(bytes4 func) external view returns(bool) {
      return state.isWhitelisted(func);
    }

    function getSetting(address revenueContract)
        external view
        returns(address, uint8, bytes4, bytes4)
    {
        return state.getSetting(revenueContract);
    }

    receive() external payable {
        return;
    }

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
import { IInterestRateCredit } from "../interfaces/IInterestRateCredit.sol";
import { ILineOfCredit } from "../interfaces/ILineOfCredit.sol";
import { IOracle } from "../interfaces/IOracle.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Denominations } from "@chainlink/contracts/src/v0.8/Denominations.sol";

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

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {LineLib} from "../utils/LineLib.sol";
import {ISpigot} from "../interfaces/ISpigot.sol";

struct SpigotState {
    address owner;
    address operator;
    address treasury;
    // Total amount of tokens escrowed by spigot
    mapping(address => uint256) escrowed; // token  -> amount escrowed
    //  allowed by operator on all revenue contracts
    mapping(bytes4 => bool) whitelistedFunctions; // function -> allowed
    // Configurations for revenue contracts to split
    mapping(address => ISpigot.Setting) settings; // revenue contract -> settings
}


library SpigotLib {
    // Maximum numerator for Setting.ownerSplit param
    uint8 constant MAX_SPLIT = 100;
    // cap revenue per claim to avoid overflows on multiplication when calculating percentages
    uint256 constant MAX_REVENUE = type(uint256).max / MAX_SPLIT;

    modifier whileNoUnclaimedRevenue(SpigotState storage self, address token) {
        // if excess revenue sitting in Spigot after MAX_REVENUE cut,
        // prevent actions until all revenue claimed and escrow updated
        // only protects push payments not pull payments.
        if (LineLib.getBalance(token) > self.escrowed[token]) {
            revert UnclaimedRevenue();
        }
        _;
    }

    function _claimRevenue(SpigotState storage self, address revenueContract, bytes calldata data, address token)
        public
        returns (uint256 claimed)
    {
        uint256 existingBalance = LineLib.getBalance(token);
        if(self.settings[revenueContract].claimFunction == bytes4(0)) {
            // push payments
            // claimed = total balance - already accounted for balance
            claimed = existingBalance - self.escrowed[token];
        } else {
            // pull payments
            if(bytes4(data) != self.settings[revenueContract].claimFunction) { revert BadFunction(); }
            (bool claimSuccess,) = revenueContract.call(data);
            if(!claimSuccess) { revert ClaimFailed(); }
            // claimed = total balance - existing balance
            claimed = LineLib.getBalance(token) - existingBalance;
        }

        if(claimed == 0) { revert NoRevenue(); }

        // cap so uint doesnt overflow in split calculations.
        // can sweep by "attaching" a push payment spigot with same token
        if(claimed > MAX_REVENUE) claimed = MAX_REVENUE;

        return claimed;
    }

    function operate(SpigotState storage self, address revenueContract, bytes calldata data) external returns (bool) {
        if(msg.sender != self.operator) { revert CallerAccessDenied(); }
        bytes4 func = bytes4(data);
        // extract function signature from tx data and check whitelist
        if(!self.whitelistedFunctions[func]) { revert BadFunction(); }
        // cant claim revenue via operate() because that fucks up accounting logic. Owner shouldn't whitelist it anyway but just in case
        if(
          func == self.settings[revenueContract].claimFunction ||
          func == self.settings[revenueContract].transferOwnerFunction
        ) { revert BadFunction(); }

        (bool success,) = revenueContract.call(data);
        if(!success) { revert BadFunction(); }

        return true;
    }

    function claimRevenue(SpigotState storage self, address revenueContract, bytes calldata data)
        external
        returns (uint256 claimed)
    {
        address token = self.settings[revenueContract].token;
        claimed = _claimRevenue(self, revenueContract, data, token);

        // split revenue stream according to settings
        uint256 escrowedAmount = claimed * self.settings[revenueContract].ownerSplit / 100;
        // update escrowed balance
        self.escrowed[token] = self.escrowed[token] + escrowedAmount;
        
        // send non-escrowed tokens to Treasury if non-zero
        if(claimed > escrowedAmount) {
            require(LineLib.sendOutTokenOrETH(token, self.treasury, claimed - escrowedAmount));
        }

        emit ClaimRevenue(token, claimed, escrowedAmount, revenueContract);
        
        return claimed;
    }

     function claimEscrow(SpigotState storage self, address token)
        external
        whileNoUnclaimedRevenue(self, token)
        returns (uint256 claimed) 
    {
        if(msg.sender != self.owner) { revert CallerAccessDenied(); }
        
        claimed = self.escrowed[token];

        if(claimed == 0) { revert ClaimFailed(); }

        LineLib.sendOutTokenOrETH(token, self.owner, claimed);

        self.escrowed[token] = 0; // keep 1 in escrow for recurring call gas optimizations?

        emit ClaimEscrow(token, claimed, self.owner);

        return claimed;
    }

    function addSpigot(SpigotState storage self, address revenueContract, ISpigot.Setting memory setting) external returns (bool) {
        if(msg.sender != self.owner) { revert CallerAccessDenied(); }
        
        
        require(revenueContract != address(this));
        // spigot setting already exists
        require(self.settings[revenueContract].transferOwnerFunction == bytes4(0));
        
        // must set transfer func
        if(setting.transferOwnerFunction == bytes4(0)) { revert BadSetting(); }
        if(setting.ownerSplit > MAX_SPLIT) { revert BadSetting(); }
        if(setting.token == address(0)) {  revert BadSetting(); }
        
        self.settings[revenueContract] = setting;
        emit AddSpigot(revenueContract, setting.token, setting.ownerSplit);

        return true;
    }

    function removeSpigot(SpigotState storage self, address revenueContract)
        external
        whileNoUnclaimedRevenue(self, self.settings[revenueContract].token)
        returns (bool)
    {
        if(msg.sender != self.owner) { revert CallerAccessDenied(); }

        (bool success,) = revenueContract.call(
            abi.encodeWithSelector(
                self.settings[revenueContract].transferOwnerFunction,
                self.operator    // assume function only takes one param that is new owner address
            )
        );
        require(success);

        delete self.settings[revenueContract];
        emit RemoveSpigot(revenueContract, self.settings[revenueContract].token);

        return true;
    }

    function updateOwnerSplit(SpigotState storage self, address revenueContract, uint8 ownerSplit)
        external
        whileNoUnclaimedRevenue(self, self.settings[revenueContract].token)
        returns(bool)
    {
      if(msg.sender != self.owner) { revert CallerAccessDenied(); }
      if(ownerSplit > MAX_SPLIT) { revert BadSetting(); }

      self.settings[revenueContract].ownerSplit = ownerSplit;
      emit UpdateOwnerSplit(revenueContract, ownerSplit);
      
      return true;
    }

    function updateOwner(SpigotState storage self, address newOwner) external returns (bool) {
        if(msg.sender != self.owner) { revert CallerAccessDenied(); }
        require(newOwner != address(0));
        self.owner = newOwner;
        emit UpdateOwner(newOwner);
        return true;
    }

    function updateOperator(SpigotState storage self, address newOperator) external returns (bool) {
        if(msg.sender != self.operator) { revert CallerAccessDenied(); }
        require(newOperator != address(0));
        self.operator = newOperator;
        emit UpdateOperator(newOperator);
        return true;
    }

    function updateTreasury(SpigotState storage self, address newTreasury) external returns (bool) {
        if(msg.sender != self.operator && msg.sender != self.treasury) {
          revert CallerAccessDenied();
        }

        require(newTreasury != address(0));
        self.treasury = newTreasury;
        emit UpdateTreasury(newTreasury);
        return true;
    }

    function updateWhitelistedFunction(SpigotState storage self, bytes4 func, bool allowed) external returns (bool) {
        if(msg.sender != self.owner) { revert CallerAccessDenied(); }
        self.whitelistedFunctions[func] = allowed;
        emit UpdateWhitelistFunction(func, allowed);
        return true;
    }

    function getEscrowed(SpigotState storage self, address token) external view returns (uint256) {
        return self.escrowed[token];
    }

    function isWhitelisted(SpigotState storage self, bytes4 func) external view returns(bool) {
      return self.whitelistedFunctions[func];
    }

    function getSetting(SpigotState storage self, address revenueContract)
        external view
        returns(address, uint8, bytes4, bytes4)
    {
        return (
            self.settings[revenueContract].token,
            self.settings[revenueContract].ownerSplit,
            self.settings[revenueContract].claimFunction,
            self.settings[revenueContract].transferOwnerFunction
        );
    }


    // Spigot Events

    event AddSpigot(
        address indexed revenueContract,
        address token,
        uint256 ownerSplit
    );

    event RemoveSpigot(address indexed revenueContract, address token);

    event UpdateWhitelistFunction(bytes4 indexed func, bool indexed allowed);

    event UpdateOwnerSplit(
        address indexed revenueContract,
        uint8 indexed split
    );

    event ClaimRevenue(
        address indexed token,
        uint256 indexed amount,
        uint256 escrowed,
        address revenueContract
    );

    event ClaimEscrow(
        address indexed token,
        uint256 indexed amount,
        address owner
    );

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