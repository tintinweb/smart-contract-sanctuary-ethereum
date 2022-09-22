pragma solidity 0.8.9;

import {IModuleFactory} from "../../interfaces/IModuleFactory.sol";

import {Spigot} from "../spigot/Spigot.sol";
import {Escrow} from "../escrow/Escrow.sol";

contract Factory is IModuleFactory {    
    function DeploySpigot(address owner, address treasury, address operator) external returns (address){
        return address(new Spigot(owner, treasury, operator));
    }

    function DeployEscrow(uint32 minCRatio, address oracle, address owner, address borrower) external returns(address){
        return address(new Escrow(minCRatio, oracle, owner, borrower));   
    }
    
}

pragma solidity 0.8.9;

interface IModuleFactory {

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

    function DeploySpigot(address owner, address treasury, address operator) external returns(address);

    function DeployEscrow(uint32 minCRatio, address oracle, address owner, address borrower) external returns(address);
}

pragma solidity 0.8.9;

import { ReentrancyGuard } from "openzeppelin/security/ReentrancyGuard.sol";
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

pragma solidity 0.8.9;

import { Denominations } from "chainlink/Denominations.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20}  from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IEscrow} from "../../interfaces/IEscrow.sol";
import {IOracle} from "../../interfaces/IOracle.sol";
import {ILineOfCredit} from "../../interfaces/ILineOfCredit.sol";
import {CreditLib} from "../../utils/CreditLib.sol";
import {LineLib} from "../../utils/LineLib.sol";
import {EscrowState, EscrowLib} from "../../utils/EscrowLib.sol";

contract Escrow is IEscrow {
    using SafeERC20 for IERC20;
    using EscrowLib for EscrowState;

    // the minimum value of the collateral in relation to the outstanding debt e.g. 10% of outstanding debt
    uint32 public immutable minimumCollateralRatio;

    // Stakeholders and contracts used in Escrow
    address public immutable oracle;
    address public immutable borrower;

    EscrowState private state;

    constructor(
        uint32 _minimumCollateralRatio,
        address _oracle,
        address _line,
        address _borrower
    ) {
        minimumCollateralRatio = _minimumCollateralRatio;
        oracle = _oracle;
        state.line = _line;
        borrower = _borrower;
    }

    function line() external view override returns(address) {
      return state.line;
    }

    function isLiquidatable() external returns(bool) {
      return state.isLiquidatable(oracle, minimumCollateralRatio);
    }

    function updateLine(address _line) external returns(bool) {
      return state.updateLine(_line);
    }

    /**
     * @notice add collateral to your position
     * @dev updates cratio
     * @dev requires that the token deposited can be valued by the escrow's oracle & the depositor has approved this contract
     * @dev - callable by anyone
     * @param amount - the amount of collateral to add
     * @param token - the token address of the deposited token
     * @return - the updated cratio
     */
    function addCollateral(uint256 amount, address token)
        external payable
        returns (uint256)
    {
        return state.addCollateral(oracle, amount, token);
    }

    /**
     * @notice - allows  the lines arbiter to  enable thdeposits of an asset
     *        - gives  better risk segmentation forlenders
     * @dev - whitelisting protects against malicious 4626 tokens and DoS attacks
     *       - only need to allow once. Can not disable collateral once enabled.
     * @param token - the token to all borrow to deposit as collateral
     */
    function enableCollateral(address token) external returns (bool) {
        return state.enableCollateral(oracle, token);
    }

    /**
     * @notice remove collateral from your position. Must remain above min collateral ratio
     * @dev callable by `borrower`
     * @dev updates cratio
     * @param amount - the amount of collateral to release
     * @param token - the token address to withdraw
     * @param to - who should receive the funds
     * @return - the updated cratio
     */
    function releaseCollateral(
        uint256 amount,
        address token,
        address to
    ) external returns (uint256) {
        return state.releaseCollateral(borrower, oracle, minimumCollateralRatio, amount, token, to);
    }

    /**
     * @notice calculates the cratio
     * @dev callable by anyone
     * @return - the calculated cratio
     */
    function getCollateralRatio() external returns (uint256) {
        return state.getCollateralRatio(oracle);
    }

    /**
     * @notice calculates the collateral value in USD to 8 decimals
     * @dev callable by anyone
     * @return - the calculated collateral value to 8 decimals
     */
    function getCollateralValue() external returns (uint256) {
        return state.getCollateralValue(oracle);
    }

    /**
     * @notice liquidates borrowers collateral by token and amount
     *         line can liquidate at anytime based off other covenants besides cratio
     * @dev requires that the cratio is at or below the liquidation threshold
     * @dev callable by `line`
     * @param amount - the amount of tokens to liquidate
     * @param token - the address of the token to draw funds from
     * @param to - the address to receive the funds
     * @return - true if successful
     */
    function liquidate(
        uint256 amount,
        address token,
        address to
    ) external returns (bool) {
        return state.liquidate(amount, token, to);
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

import { ReentrancyGuard } from "openzeppelin/security/ReentrancyGuard.sol";
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

interface IOracle {
    /** current price for token asset. denominated in USD */
    function getLatestAnswer(address token) external returns(int);
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

pragma solidity 0.8.9;

import { Denominations } from "chainlink/Denominations.sol";
import { IERC20 } from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20}  from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {ILineOfCredit} from "../interfaces/ILineOfCredit.sol";
import {IEscrow} from "../interfaces/IEscrow.sol";
import {CreditLib} from "../utils/CreditLib.sol";
import {LineLib} from "../utils/LineLib.sol";

struct EscrowState {
    address line;
    address[] collateralTokens;
    /// if lenders allow token as collateral. ensures uniqueness in collateralTokens
    mapping(address => bool) enabled;
    /// tokens used as collateral (must be able to value with oracle)
    mapping(address => IEscrow.Deposit) deposited;
}

library EscrowLib {
    using SafeERC20 for IERC20;

    // return if have collateral but no debt
    uint256 constant MAX_INT =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;

    function isLiquidatable(EscrowState storage self, address oracle, uint256 minimumCollateralRatio) external returns(bool) {
      return _getLatestCollateralRatio(self, oracle) < minimumCollateralRatio;
    }

    function updateLine(EscrowState storage self, address _line) external returns(bool) {
      require(msg.sender == self.line);
      self.line = _line;
      return true;
    }

    /**
     * @notice updates the cratio according to the collateral value vs line value
     * @dev calls accrue interest on the line contract to update the latest interest payable
     * @return the updated collateral ratio in 18 decimals
     */
    function _getLatestCollateralRatio(EscrowState storage self, address oracle) public returns (uint256) {
        (uint256 principal, uint256 interest) = ILineOfCredit(self.line).updateOutstandingDebt();
        uint256 debtValue =  principal + interest;
        uint256 collateralValue = _getCollateralValue(self, oracle);
        if (collateralValue == 0) return 0;
        if (debtValue == 0) return MAX_INT;

        uint256 _numerator = collateralValue * 10**5; // scale to 2 decimals
        return ((_numerator / debtValue) + 5) / 10;
    }

    /**
    * @dev calculate the USD value of all the collateral stored
    * @return - the collateral's USD value in 8 decimals
    */
    function _getCollateralValue(EscrowState storage self, address oracle) public returns (uint256) {
        uint256 collateralValue;
        // gas savings
        uint256 length = self.collateralTokens.length;
        IOracle o = IOracle(oracle); 
        IEscrow.Deposit memory d;
        for (uint256 i; i < length; ++i) {
            address token = self.collateralTokens[i];
            d = self.deposited[token];
             // new var so we don't override original deposit amount for 4626 tokens
            uint256 deposit = d.amount;
            if (deposit != 0) {
                if (d.isERC4626) {
                    // this conversion could shift, hence it is best to get it each time
                    (bool success, bytes memory assetAmount) = token.call(
                        abi.encodeWithSignature(
                            "previewRedeem(uint256)",
                            deposit
                        )
                    );
                    if (!success) continue;
                    deposit = abi.decode(assetAmount, (uint256));
                }

                collateralValue += CreditLib.calculateValue(
                  o.getLatestAnswer(d.asset),
                  deposit,
                  d.assetDecimals
                );
            }
        }

        return collateralValue;
    }

    function addCollateral(EscrowState storage self, address oracle, uint256 amount, address token)
        external
        returns (uint256)
    {
        require(amount > 0);
        if(!self.enabled[token])  { revert InvalidCollateral(); }

        LineLib.receiveTokenOrETH(token, msg.sender, amount);

        self.deposited[token].amount += amount;

        emit AddCollateral(token, amount);

        return _getLatestCollateralRatio(self, oracle);
    }

    function enableCollateral(EscrowState storage self, address oracle, address token) external returns (bool) {
        require(msg.sender == ILineOfCredit(self.line).arbiter());

        bool isEnabled = self.enabled[token];
        IEscrow.Deposit memory deposit = self.deposited[token]; // gas savings
        if (!isEnabled) {
            if (token == Denominations.ETH) {
                // enable native eth support
                deposit.asset = Denominations.ETH;
                deposit.assetDecimals = 18;
            } else {
                (bool passed, bytes memory tokenAddrBytes) = token.call(
                    abi.encodeWithSignature("asset()")
                );

                bool is4626 = tokenAddrBytes.length > 0 && passed;
                deposit.isERC4626 = is4626;
                // if 4626 save the underlying token to use for oracle pricing
                deposit.asset = !is4626
                    ? token
                    : abi.decode(tokenAddrBytes, (address));

                int256 price = IOracle(oracle).getLatestAnswer(deposit.asset);
                if (price <= 0) {
                    revert InvalidCollateral();
                }

                (bool successDecimals, bytes memory decimalBytes) = deposit
                    .asset
                    .call(abi.encodeWithSignature("decimals()"));
                if (decimalBytes.length > 0 && successDecimals) {
                    deposit.assetDecimals = abi.decode(decimalBytes, (uint8));
                } else {
                    deposit.assetDecimals = 18;
                }
            }

            // update collateral settings
            self.enabled[token] = true;
            self.deposited[token] = deposit;
            self.collateralTokens.push(token);
            emit EnableCollateral(deposit.asset);
        }

        return true;
    }

    function releaseCollateral(
        EscrowState storage self,
        address borrower,
        address oracle,
        uint256 minimumCollateralRatio,
        uint256 amount,
        address token,
        address to
    ) external returns (uint256) {
        require(amount > 0);
        if(msg.sender != borrower) { revert CallerAccessDenied(); }
        if(self.deposited[token].amount < amount) { revert InvalidCollateral(); }
        self.deposited[token].amount -= amount;
        
        LineLib.sendOutTokenOrETH(token, to, amount);

        uint256 cratio = _getLatestCollateralRatio(self, oracle);
        // fail if reduces cratio below min 
        // but allow borrower to always withdraw if fully repaid
        if(
          cratio < minimumCollateralRatio &&         // if undercollateralized, revert;
          ILineOfCredit(self.line).status() != LineLib.STATUS.REPAID // if repaid, skip;
        ) { revert UnderCollateralized(); }
        
        emit RemoveCollateral(token, amount);

        return cratio;
    }

    function getCollateralRatio(EscrowState storage self, address oracle) external returns (uint256) {
        return _getLatestCollateralRatio(self, oracle);
    }

    function getCollateralValue(EscrowState storage self, address oracle) external returns (uint256) {
        return _getCollateralValue(self, oracle);
    }

    function liquidate(
        EscrowState storage self,
        uint256 amount,
        address token,
        address to
    ) external returns (bool) {
        require(amount > 0);
        if(msg.sender != self.line) { revert CallerAccessDenied(); }
        if(self.deposited[token].amount < amount) { revert InvalidCollateral(); }

        self.deposited[token].amount -= amount;
        
        LineLib.sendOutTokenOrETH(token, to, amount);

        return true;
    }

    event AddCollateral(address indexed token, uint256 indexed amount);

    event RemoveCollateral(address indexed token, uint256 indexed amount);

    event EnableCollateral(address indexed token);
    
    event Liquidate(address indexed token, uint256 indexed amount);

    error InvalidCollateral();

    error CallerAccessDenied();

    error UnderCollateralized();

    error NotLiquidatable();
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