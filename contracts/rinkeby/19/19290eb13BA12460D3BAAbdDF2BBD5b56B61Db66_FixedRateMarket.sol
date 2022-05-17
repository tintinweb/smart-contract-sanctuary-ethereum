//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable as IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IFixedRateMarket.sol";
import "./interfaces/IQollateralManager.sol";
import "./interfaces/IQAdmin.sol";
import "./libraries/ECDSA.sol";
import "./libraries/Interest.sol";

contract FixedRateMarket is Initializable, ERC20, IFixedRateMarket {

  using SafeERC20 for IERC20;

  /// @notice Contract storing all global Qoda parameters
  IQAdmin private _qAdmin;

  /// @notice Contract for managing anything collateral related
  IQollateralManager private _qollateralManager;

  /// @notice Address of the ERC20 token which the loan will be denominated
  IERC20 private _underlyingToken;
  
  /// @notice UNIX timestamp (in seconds) when the market matures
  uint private _maturity;

  /// @notice True if a nonce for a Quote is void, false otherwise.
  /// Used for checking if a Quote is a duplicate, or cancelled.
  /// Note: We need to use a map of all nonces here instead of just storing
  /// latest nonce because: what if users have multiple live orders at once?
  /// account => nonce => bool
  mapping(address => mapping(uint => bool)) private _voidNonces;

  /// @notice Storage for all borrows by a user
  /// account => principalPlusInterest
  mapping(address => uint) private _accountBorrows;
  
  /// @notice Storage for the current total partial fill for a Quote
  /// signature => filled
  mapping(bytes => uint) private _quoteFill;

    /// @notice Emitted when a borrower repays borrow
  event RepayBorrow(address borrower, uint amount);

  /// @notice Emitted when a borrower repays borrower using qTokens
  event RepayBorrowWithqToken(address borrower, uint amount);

  /// @notice Emitted when a borrower is liquidated
  event LiquidateBorrow(
                        address indexed borrower,
                        address indexed liquidator,
                        uint amount,
                        address collateralTokenAddress,
                        uint reward
                        );
  
  /// @notice Emitted when a borrower and lender are matched for a fixed rate loan
  event FixedRateLoan(
                      address indexed borrower,
                      address indexed lender,
                      uint amountPV,
                      uint amountFV);
  
  /// @notice Emitted when an account cancels their Quote
  event CancelQuote(address indexed account, uint nonce);

  /// @notice Emitted when an account redeems their qTokens
  event RedeemQTokens(address indexed account, uint amount);
  
  /// @notice Constructor for upgradeable contracts
  /// @param qAdminAddress_ Address of the `QAdmin` contract
  /// @param qollateralManagerAddress_ Address of the `QollateralManager` contract
  /// @param underlyingTokenAddress_ Address of the underlying loan token denomination
  /// @param maturity_ UNIX timestamp (in seconds) when the market matures
  /// @param name_ Name of the market's ERC20 token
  /// /@param symbol_ Symbol of the market's ERC20 token
  function initialize(
                      address qAdminAddress_,
                      address qollateralManagerAddress_,
                      address underlyingTokenAddress_,
                      uint maturity_,
                      string memory name_,
                      string memory symbol_
                      ) public initializer {
    __ERC20_init(name_, symbol_);
    _qAdmin = IQAdmin(qAdminAddress_);
    _qollateralManager = IQollateralManager(qollateralManagerAddress_);
    _underlyingToken = IERC20(underlyingTokenAddress_);
    _maturity = maturity_;
  }

  /** USER INTERFACE **/

  /// @notice Execute against Quote as a borrower.
  /// @param amountPV Amount that the borrower wants to execute as PV
  /// @param lender Account of the lender
  /// @param quoteType *Lender's* type preference, 0 for PV+APR, 1 for FV+APR
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return uint, uint Loan amount (`amountPV`) and repayment amount (`amountFV`)
  function borrow(
                  uint amountPV,
                  address lender,
                  uint8 quoteType,
                  uint64 quoteExpiryTime,
                  uint64 APR,
                  uint cashflow,
                  uint nonce,
                  bytes memory signature
                  ) external returns(uint, uint){

    require(block.timestamp < _maturity, "FixedRateMarket: market expired");
    
    QTypes.Quote memory quote = QTypes.Quote(
                                             address(this),
                                             lender,
                                             quoteType,
                                             1, // side=1 for lender
                                             quoteExpiryTime,
                                             APR,
                                             cashflow,
                                             nonce,
                                             signature
                                             );

    // Calculate the equivalent `amountFV`
    uint amountFV = Interest.PVToFV(
                                    APR,
                                    amountPV,
                                    block.timestamp,
                                    _maturity,
                                    _qAdmin.MANTISSA_BPS()
                                    );

    return _processLoan(amountPV, amountFV, quote);
  }

  /// @notice Execute against Quote as a lender.
  /// @param amountPV Amount that the lender wants to execute as PV
  /// @param borrower Account of the borrower
  /// @param quoteType *Borrower's* type preference, 0 for PV+APR, 1 for FV+APR
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return uint, uint Loan amount (`amountPV`) and repayment amount (`amountFV`)
  function lend(
                uint amountPV,
                address borrower,
                uint8 quoteType,
                uint64 quoteExpiryTime,
                uint64 APR,
                uint cashflow,
                uint nonce,
                bytes memory signature
                ) external returns(uint, uint){
    
    require(block.timestamp < _maturity, "FixedRateMarket: market expired");
    
    QTypes.Quote memory quote = QTypes.Quote(
                                             address(this),
                                             borrower,
                                             quoteType,
                                             0, // side=0 for borrower
                                             quoteExpiryTime,
                                             APR,
                                             cashflow,
                                             nonce,
                                             signature
                                             );

    // Calculate the equivalent `amountFV`
    uint amountFV = Interest.PVToFV(
                                    APR,
                                    amountPV,
                                    block.timestamp,
                                    _maturity,
                                    _qAdmin.MANTISSA_BPS()
                                    );

    return _processLoan(amountPV, amountFV, quote);
  }
  
  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param amount Amount to repay
  /// @return uint Remaining account borrow amount
  function repayBorrow(uint amount) external returns(uint){
    
    // Don't allow users to pay more than necessary
    amount = Math.min(amount, _accountBorrows[msg.sender]);

    // Repayment amount must be positive
    require(amount > 0, "FixedRateMarket: zero repay amount");

    // Check borrower has approved contract spend    
    require(
            _checkApproval(msg.sender, amount),
            "FixedRateMarket: insufficient allowance"
            );

    // Check borrower has enough balance
    require(
            _checkBalance(msg.sender, amount),
            "FixedRateMarket: insufficient balance"
            );

    // Effects: Deduct from the account's total debts
    // Guaranteed not to underflow due to the flooring on amount above
    _accountBorrows[msg.sender] -= amount;

    // Transfer amount from borrower to contract for escrow until maturity
    _underlyingToken.safeTransferFrom(msg.sender, address(this), amount);

    // Emit the event
    emit RepayBorrow(msg.sender, amount);

    return _accountBorrows[msg.sender];
  }
  
  /// @notice By setting the nonce in `_voidNonces` to true, this is equivalent to
  /// invalidating the Quote (i.e. cancelling the quote)
  /// param nonce Nonce of the Quote to be cancelled
  function cancelQuote(uint nonce) external {

    // Set the value to true for the `_voidNonces` mapping
    _voidNonces[msg.sender][nonce] = true;

    // Emit the event
    emit CancelQuote(msg.sender, nonce);
  }

  /// @notice This function allows net lenders to redeem qTokens for the
  /// underlying token. Redemptions may only be permitted after loan maturity
  /// plus `_maturityGracePeriod`. The public interface redeems the entire qToken
  /// balance.
  /// @param amount Amount of qTokens to redeem
  function redeemQTokens(uint amount) external {    
    // Enforce maturity + grace period before allowing redemptions
    require(
            block.timestamp > _maturity + _qAdmin.maturityGracePeriod(),
            "FixedRateMarket: cannot redeem early"
            );

    // Burn the qToken balance
    _burn(msg.sender, amount);

    // Release the underlying token back to the lender
    _underlyingToken.transfer(msg.sender, amount);

    // Emit the event
    emit RedeemQTokens(msg.sender, amount);
  }
  
  /// @notice If an account is in danger of being undercollateralized (i.e.
  /// collateralRatio < 1.0), any user may liquidate that account by paying
  /// back the loan on behalf of the account. In return, the liquidator receives
  /// collateral belonging to the account equal in value to the repayment amount
  /// in USD plus the liquidation incentive amount as a bonus.
  /// @param borrower Address of account that is undercollateralized
  /// @param amount Amount to repay on behalf of account in the currency of the loan
  /// @param collateralToken Liquidator's choice of which currency to be paid in
  function liquidateBorrow(
                           address borrower,
                           uint amount,
                           IERC20 collateralToken
                           ) external {

    // Ensure borrower is either undercollateralized or past payment due date.
    // These are the necessary conditions before borrower can be liquidated.
    require(
            _qollateralManager.collateralRatio(borrower) < _qAdmin.minCollateralRatio() ||
            block.timestamp > _maturity,
            "FixedRateMarket: account ineligible for liquidation"
            );    

    // For borrowers that are undercollateralized, liquidator can only repay up
    // to a percentage of the full loan balance determined by the `closeFactor`
    uint closeFactor = _qollateralManager.closeFactor();

    // For borrowers that are past due date, ignore the close factor - liquidator
    // can liquidate the entire sum
    if(block.timestamp > _maturity){
      closeFactor = _qAdmin.MANTISSA_FACTORS();
    }
        
    // Liquidator cannot repay more than the percentage of the full loan balance
    // determined by `closeFactor`
    uint maxRepayment = _accountBorrows[borrower] * closeFactor / _qAdmin.MANTISSA_FACTORS();
    amount = Math.min(amount, maxRepayment);

    // Amount must be positive
    require(amount > 0, "FixedRateMarket: liquidation/owed amount must be positive");
    
    // Get USD value of amount paid
    uint amountUSD = _qollateralManager.localToUSD(_underlyingToken, amount);

    // Get USD value of amount plus liquidity incentive
    uint rewardUSD = amountUSD * _qAdmin.liquidationIncentive() / _qAdmin.MANTISSA_FACTORS();

    // Get the local amount of collateral to reward liquidator
    uint rewardLocal = _qollateralManager.USDToLocal(collateralToken, rewardUSD);

    // Ensure the borrower has enough collateral balance to pay the liquidator
    uint balance = _qollateralManager.collateralBalance(borrower, collateralToken);
    require(rewardLocal <= balance, "FixedRateMarket: borrower account balance too low");

    // Liquidator repays the loan on behalf of borrower
    _underlyingToken.transferFrom(msg.sender, address(this), amount);

    // Credit the borrower's account
    _accountBorrows[borrower] -= amount;
      
    // Emit the event
    emit LiquidateBorrow(borrower, msg.sender, amount, address(collateralToken), rewardLocal);
    
    // Transfer the collateral balance from borrower to the liquidator
    _qollateralManager._transferCollateral(
                                           collateralToken,
                                           borrower,
                                           msg.sender,
                                           rewardLocal
                                           );
  }

  /** VIEW FUNCTIONS **/
  
  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManager() external view returns(address){
    return address(_qollateralManager);
  }

  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return IERC20
  function underlyingToken() external view returns(IERC20){
    return _underlyingToken;
  }

  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function maturity() external view returns(uint){
    return _maturity;
  }
  
  /// @notice True if a nonce for a Quote is voided, false otherwise.
  /// Used for checking if a Quote is a duplicated.
  /// @param account Account to query
  /// @param nonce Nonce to query
  /// @return bool True if used, false otherwise
  function isNonceVoid(address account, uint nonce) external view returns(bool){
    return _voidNonces[account][nonce];
  }

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function accountBorrows(address account) external view returns(uint){
    return _accountBorrows[account];
  }

  /// @notice Get the current total partial fill for a Quote
  /// @param signature Quote signature to query
  /// @return uint Partial fill
  function quoteFill(bytes memory signature) external view returns(uint){
    return _quoteFill[signature];
  }

  /** INTERNAL FUNCTIONS **/

  /// @notice Intermediary function that handles some error handling, partial fills
  /// and managing uniqueness of nonces
  /// @param amountPV Size of the initial loan paid by lender
  /// @param amountFV Final amount that must be paid by borrower
  /// @param quote Quote struct for code simplicity / avoiding 'stack too deep' error
  /// @return uint, uint Loan amount (`amountPV`) and repayment amount (`amountFV`)
  function _processLoan(
                        uint amountPV,
                        uint amountFV,
                        QTypes.Quote memory quote
                        ) internal returns(uint, uint){

    address signer = ECDSA.getSigner(
                                     quote.marketAddress,
                                     quote.quoter,
                                     quote.quoteType,
                                     quote.side,
                                     quote.quoteExpiryTime,
                                     quote.APR,
                                     quote.cashflow,
                                     quote.nonce,
                                     quote.signature
                                     );
    
    // Check if signature is valid
    require(signer == quote.quoter, "FixedRateMarket: invalid signature");

    // Check if `Market` is already expired
    require(block.timestamp < _maturity, "FixedRateMarket: market expired");
    
    // Check that quote hasn't expired yet
    require(
            quote.quoteExpiryTime == 0 ||
            quote.quoteExpiryTime > block.timestamp,
            "FixedRateMarket: quote expired"
            );

    // Check that the nonce hasn't already been used
    require(!_voidNonces[quote.quoter][quote.nonce], "FixedRateMarket: invalid nonce");    

    if(quote.quoteType == 0){ // Quote is in PV terms

      // `amountPV` cannot be greater than remaining quote size
      if(amountPV > quote.cashflow - _quoteFill[quote.signature]){

        // Cap `amountPV` at remaining quote size
        amountPV = quote.cashflow - _quoteFill[quote.signature];

        // Recalculate `amountFV` based on updated `amountPV`
        amountFV = Interest.PVToFV(
                                   quote.APR,
                                   amountPV,
                                   block.timestamp,
                                   _maturity,
                                   _qAdmin.MANTISSA_BPS()
                                   );
      }

      // Update the partial fills for the quote
      _quoteFill[quote.signature] += amountPV;
      
    }else if(quote.quoteType == 1){ // Quote is in FV terms

      // `amountFV` cannot be greater than remaining quote size
      if(amountFV > quote.cashflow - _quoteFill[quote.signature]){

        // Cap `amountFV` at remaining quote size
        amountFV = quote.cashflow - _quoteFill[quote.signature];

        // Recalculate `amountPV` based on updated `amountFV`
        amountPV = Interest.FVToPV(
                                   quote.APR,
                                   amountFV,
                                   block.timestamp,
                                   _maturity,
                                   _qAdmin.MANTISSA_BPS()
                                   );
      }

      // Update the partial fills for the quote
      _quoteFill[quote.signature] += amountFV;
      
    }else{
      revert("invalid quoteType"); 
    }

    // Nonce is used up once the partial fill equals the original amount
    if(_quoteFill[quote.signature] == quote.cashflow){
      _voidNonces[quote.quoter][quote.nonce] = true;
    }

    // Determine who is the lender and who is the borrower before instantiating loan
    if(quote.side == 1){
      // If quote.side = 1, the quoter is the lender
      return _createFixedRateLoan(msg.sender, quote.quoter, amountPV, amountFV);
    }else if (quote.side == 0){
      // If quote.side = 0, the quoter is the borrower
      return _createFixedRateLoan(quote.quoter, msg.sender, amountPV, amountFV);
    }else {
      revert("invalid side"); //should not reach here
    }
  }

  /// @notice Mint the future payment tokens to the lender, add `amountFV` to
  /// the borrower's debts, and transfer `amountPV` from lender to borrower
  /// @param borrower Account of the borrower
  /// @param lender Account of the lender
  /// @param amountPV Size of the initial loan paid by lender
  /// @param amountFV Final amount that must be paid by borrower
  /// @return uint, uint Loan amount (`amountPV`) and repayment amount (`amountFV`)
  function _createFixedRateLoan(
                                address borrower,
                                address lender,
                                uint amountPV,
                                uint amountFV
                                ) internal returns(uint, uint){

    // Loan amount must be strictly positive
    require(amountPV > 0, "FixedRateMarket: invalid amount");

    // Interest rate needs to be positive
    require(amountPV < amountFV, "FixedRateMarket: invalid APR"); 

    require(lender != borrower, "FixedRateMarket: invalid counterparty");

    // Cannot Create a loan past its maturity time
    require(block.timestamp < _maturity, "FixedRateMarket: invalid maturity");

    // Check lender has approved contract spend
    require(
            _checkApproval(lender, amountPV),
            "FixedRateMarket: lender insufficient allowance"
            );

    // Check lender has enough balance
    require(
            _checkBalance(lender, amountPV),
            "FixedRateMarket: lender insufficient balance"
            );

    // The borrow amount of the borrower increases by the full `amountFV`
    _accountBorrows[borrower] += amountFV;

    // TODO: is there any way to only require the `amountPV` at time of inception of
    // loan and slowly converge the required collateral to equal `amountFV` by end
    // of loan? This allows for improved capital efficiency / less collateral upfront
    // required by borower

    // Check if borrower has sufficient collateral for loan. This should be
    // the `_initCollateralRatio` which should be a larger value than the
    // `_minCollateralRatio`. This protects users from taking loans at the
    // minimum threshold, putting them at risk of instant liquidation.
    uint collateralRatio = _qollateralManager.hypotheticalCollateralRatio(
                                                                          borrower,
                                                                          IERC20(address(0)),
                                                                          0,
                                                                          IFixedRateMarket(address(this)),
                                                                          amountFV
                                                                          );
    require(
            collateralRatio >= _qollateralManager.initCollateralRatio(),
            "FixedRateMarket: borrower insufficient collateral"
            );
    
    // Net off borrow amount with any balance of qTokens the borrower may have
    uint repayAmountBorrower = Math.min(_accountBorrows[borrower], balanceOf(borrower));
    if(repayAmountBorrower > 0){
      _repayBorrowWithqToken(borrower, repayAmountBorrower);
    }
   
    // Record that the lender/borrow have participated in this market
    if(!_qollateralManager.accountMarkets(lender, IFixedRateMarket(address(this)))){
      _qollateralManager._addAccountMarket(lender, IFixedRateMarket(address(this)));
    }
    if(!_qollateralManager.accountMarkets(borrower, IFixedRateMarket(address(this)))){
      _qollateralManager._addAccountMarket(borrower, IFixedRateMarket(address(this)));
    }
    
    // Emit the matched borrower and lender and fixed rate loan terms
    emit FixedRateLoan(borrower, lender, amountPV, amountFV);
    
    // Transfer `amountPV` from lender to borrower
    _underlyingToken.safeTransferFrom(lender, borrower, amountPV);

    // Lender receives `amountFV` amount in qTokens
    // Put this last to protect against reentracy
    //TODO Probably want use a reentrancy guard instead here
    _mint(lender, amountFV);

    // Net off the minted amount with any borrow amounts the lender may have
    uint repayAmountLender = Math.min(_accountBorrows[lender], balanceOf(lender));
    if(repayAmountLender > 0){
      _repayBorrowWithqToken(lender, repayAmountLender);
    }

    return (amountPV, amountFV);
  }
  
  /// @notice Borrower makes repayment with qTokens. The qTokens will automatically
  /// get burned and the accountBorrows deducted accordingly.
  /// @param account User account
  /// @param amount Amount to pay in qTokens
  /// @return uint Remaining account borrow amount
  function _repayBorrowWithqToken(address account, uint amount) internal returns(uint){
    require(amount <= balanceOf(account), "FixedRateMarket: Amount exceeds balance");

    // Don't allow users to pay more than necessary
    amount = Math.min(_accountBorrows[account], amount);

    // Burn the qTokens from the account and subtract the amount for the user's borrows
    _burn(account, amount);
    _accountBorrows[account] -= amount;

    // Emit the repayment event
    emit RepayBorrowWithqToken(account, amount);

    // Return the remaining account borrow amount
    return _accountBorrows[account];
  }

  /// @notice Verify if the user has enough token balance
  /// @param userAddress Address of the account to check
  /// @param amount Balance must be greater than or equal to this amount
  /// @return bool true if sufficient balance otherwise false
  function _checkBalance(
                         address userAddress,
                         uint256 amount
                         ) internal view returns(bool){
    if(_underlyingToken.balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }
  
  /// @notice Verify if the user has approved the smart contract for spend
  /// @param userAddress Address of the account to check
  /// @param amount Allowance  must be greater than or equal to this amount
  /// @return bool true if sufficient allowance otherwise false
  function _checkApproval(
                          address userAddress,
                          uint256 amount
                          ) internal view returns(bool) {
    if(_underlyingToken.allowance(userAddress, address(this)) > amount){
      return true;
    }
    return false;
  }




  /** ERC20 Implementation **/

  /// @notice Number of decimal places of the qToken should match the number
  /// of decimal places of the underlying token
  /// @return uint8 Number of decimal places
  function decimals() public view override(ERC20, IERC20Metadata) returns(uint8) {
    //TODO possible for ERC20 to not define decimals. Do we need to handle this?
    return IERC20Metadata(address(_underlyingToken)).decimals();
  }
  
  /// @notice This hook requires users trying to transfer their qTokens to only
  /// be able to transfer tokens in excess of their current borrows. This is to
  /// protect the protocol from users gaming the collateral management system
  /// by borrowing off of the qToken and then immediately transferring out the
  /// qToken to another address, leaving the borrowing account uncollateralized
  /// @param from Address of the sender
  /// @param to Address of the receiver
  /// @param amount Amount of tokens to send
  function _beforeTokenTransfer(
                                address from,
                                address to,
                                uint256 amount
                                ) internal virtual override {

    // Call parent hook first
    super._beforeTokenTransfer(from, to, amount);
    
    // Ignore hook for 0x000... address (e.g. _mint, _burn functions)
    if(from == address(0) || to == address(0)){
      return;
    }

    // Transfers rejected if borrows exceed lends
    require(
            balanceOf(from) > _accountBorrows[from],
            "FixedRateMarket: account borrows exceeds balance"
            );
    
    // Safe from underflow after previous require statement
    uint maxTransferrable = balanceOf(from) - _accountBorrows[from];
    require(
            amount <= maxTransferrable,
            "FixedRateMarket: amount must be in excess of borrows"
            );
      
  }

  /// @notice This hook requires users to automatically repay any borrows their
  /// accounts may still have after receiving the qTokens
  /// @param from Address of the sender
  /// @param to Address of the receiver
  /// @param amount Amount of tokens to send
  function _afterTokenTransfer(
                                address from,
                                address to,
                                uint256 amount
                                ) internal virtual override {

    // Call parent hook first
    super._afterTokenTransfer(from, to, amount);
    
    // Ignore hook for 0x000... address (e.g. _mint, _burn functions)
    if(from == address(0) || to == address(0)){
      return;
    }
    
    if(_accountBorrows[to] > 0){
      uint amountOwed = Math.min(_accountBorrows[to], amount);
      _repayBorrowWithqToken(to, amountOwed);
    }    
  }


  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable as IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IFixedRateMarket is IERC20, IERC20Metadata {

  /** USER INTERFACE **/

  /// @notice Execute against Quote as a borrower.
  /// @param amountPV Amount that the borrower wants to execute as PV
  /// @param lender Account of the lender
  /// @param quoteType *Lender's* type preference, 0 for PV+APR, 1 for FV+APR
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return uint, uint Loan amount (`amountPV`) and repayment amount (`amountFV`)
  function borrow(
                  uint amountPV,
                  address lender,
                  uint8 quoteType,
                  uint64 quoteExpiryTime,
                  uint64 APR,
                  uint cashflow,
                  uint nonce,
                  bytes memory signature
                  ) external returns(uint, uint);

  /// @notice Execute against Quote as a lender.
  /// @param amountPV Amount that the lender wants to execute as PV
  /// @param borrower Account of the borrower
  /// @param quoteType *Borrower's* type preference, 0 for PV+APR, 1 for FV+APR
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  /// @return uint, uint Loan amount (`amountPV`) and repayment amount (`amountFV`)
  function lend(
                uint amountPV,
                address borrower,
                uint8 quoteType,
                uint64 quoteExpiryTime,
                uint64 APR,
                uint cashflow,
                uint nonce,
                bytes memory signature
                ) external returns(uint, uint);
  
  /// @notice Borrower will make repayments to the smart contract, which
  /// holds the value in escrow until maturity to release to lenders.
  /// @param amount Amount to repay
  /// @return uint Remaining account borrow amount
  function repayBorrow(uint amount) external returns(uint);

  /// @notice By setting the nonce in `_voidNonces` to true, this is equivalent to
  /// invalidating the Quote (i.e. cancelling the quote)
  /// param nonce Nonce of the Quote to be cancelled
  function cancelQuote(uint nonce) external;

  /// @notice If an account is in danger of being undercollateralized (i.e.
  /// liquidityRatio < 1.0), any user may liquidate that account by paying
  /// back the loan on behalf of the account. In return, the liquidator receives
  /// collateral belonging to the account equal in value to the repayment amount
  /// in USD plus the liquidation incentive amount as a bonus.
  /// @param borrower Address of account that is undercollateralized
  /// @param amount Amount to repay on behalf of account
  /// @param collateralToken Liquidator's choice of which currency to be paid in
  function liquidateBorrow(
                           address borrower,
                           uint amount,
                           IERC20 collateralToken
                           ) external;
  
  /** VIEW FUNCTIONS **/
  
  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManager() external view returns(address);

  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return IERC20
  function underlyingToken() external view returns(IERC20);

  /// @notice Get the UNIX timestamp (in seconds) when the market matures
  /// @return uint
  function maturity() external view returns(uint);
  
  /// @notice True if a nonce for a Quote is voided, false otherwise.
  /// Used for checking if a Quote is a duplicated.
  /// @param account Account to query
  /// @param nonce Nonce to query
  /// @return bool True if used, false otherwise
  function isNonceVoid(address account, uint nonce) external view returns(bool);

  /// @notice Get the total balance of borrows by user
  /// @param account Account to query
  /// @return uint Borrows
  function accountBorrows(address account) external view returns(uint);

  /// @notice Get the current total partial fill for a Quote
  /// @param signature Quote signature to query
  /// @return uint Partial fill
  function quoteFill(bytes memory signature) external view returns(uint);
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IFixedRateMarket.sol";

interface IQollateralManager {

  /// @notice Constructor for upgradeable contracts
  /// @param qAdminAddress_ Address of the `QAdmin` contract
  /// @param qPriceOracleAddress_ Address of the `QPriceOracle` contract
  function initialize(address qAdminAddress_, address qPriceOracleAddress_) external;

 /** ADMIN/RESTRICTED FUNCTIONS **/

  /// @notice Record when an account has either borrowed or lent into a
  /// `FixedRateMarket`. This is necessary because we need to iterate
  /// across all markets that an account has borrowed/lent to to calculate their
  /// `borrowValue`. Only the `FixedRateMarket` contract itself may call
  /// this function
  /// @param account User account
  /// @param market Address of the `FixedRateMarket` market
  function _addAccountMarket(address account, IFixedRateMarket market) external;

  /// @notice Transfer collateral balances from one account to another. Only
  /// `FixedRateMarket` contracts can call this restricted function. This is used
  /// for when a liquidator liquidates an account.
  /// @param token ERC20 token
  /// @param from Sender address
  /// @param to Recipient address
  /// @param amount Amount to transfer
  function _transferCollateral(IERC20 token, address from, address to, uint amount) external;
  
  /** USER INTERFACE **/
  
  /// @notice Users call this to deposit collateral to fund their borrows
  /// @param token ERC20 token
  /// @param amount Amount to deposit (in local ccy)
  /// @return uint New collateral balance
  function depositCollateral(IERC20 token, uint amount) external returns(uint);

  /// @notice Users call this to withdraw collateral
  /// @param token ERC20 token
  /// @param amount Amount to withdraw (in local ccy)
  /// @return uint New collateral balance
  function withdrawCollateral(IERC20 token, uint amount) external returns(uint);
  
  /** VIEW FUNCTIONS **/

  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address);

  /// @notice Return what the collateral ratio for an account would be
  /// with a hypothetical collateral withdraw and/or token borrow.
  /// The collateral ratio is calculated as:
  /// (`virtualCollateralValue` / `virtualBorrowValue`)
  /// This returns a value from 0-1, scaled by 1e8.
  /// If this value fals below 1, the account can be liquidated
  /// @param account User account
  /// @param withdrawToken Currency of hypothetical withdraw
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param borrowMarket Market of hypothetical borrow
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @return uint Hypothetical collateral ratio
  function hypotheticalCollateralRatio(
                                       address account,
                                       IERC20 withdrawToken,
                                       uint withdrawAmount,
                                       IFixedRateMarket borrowMarket,
                                       uint borrowAmount
                                       ) external view returns(uint);

  /// @notice Return the current collateral ratio for an account.
  /// The collateral ratio is calculated as:
  /// (`virtualCollateralValue` / `virtualBorrowValue`)
  /// This returns a value from 0-1, scaled by 1e8.
  /// If this value fals below 1, the account can be liquidated
  /// @param account User account
  /// @return uint Collateral ratio
  function collateralRatio(address account) external view returns(uint);
  
  /// @notice Get the `collateralFactor` weighted value (in USD) of all the
  /// collateral deposited for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function virtualCollateralValue(address account) external view returns(uint);
  
  /// @notice Get the `collateralFactor` weighted value (in USD) for the tokens
  /// deposited for an account
  /// @param account Account to query
  /// @param token ERC20 token
  /// @return uint Value of token collateral of account in USD
  function virtualCollateralValueByToken(
                                         address account,
                                         IERC20 token
                                         ) external view returns(uint);

  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD
  function virtualBorrowValue(address account) external view returns(uint);
  
  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param market `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD
  function virtualBorrowValueByMarket(
                                      address account,
                                      IFixedRateMarket market
                                      ) external view returns(uint);
  
  /// @notice Get the unweighted value (in USD) of all the collateral deposited
  /// for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function realCollateralValue(address account) external view returns(uint);
  
  /// @notice Get the unweighted value (in USD) of the tokens deposited
  /// for an account
  /// @param account Account to query
  /// @param token ERC20 token
  /// @return uint Value of token collateral of account in USD
  function realCollateralValueByToken(
                                      address account,
                                      IERC20 token
                                      ) external view returns(uint);
  
  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD
  function realBorrowValue(address account) external view returns(uint);

  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param market `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD
  function realBorrowValueByMarket(
                                   address account,
                                   IFixedRateMarket market
                                   ) external view returns(uint);

  /// @notice Get the minimum collateral ratio. Scaled by 1e8.
  /// @return uint Minimum collateral ratio
  function minCollateralRatio() external view returns(uint);
  
  /// @notice Get the initial collateral ratio. Scaled by 1e8
  /// @return uint Initial collateral ratio
  function initCollateralRatio() external view returns(uint);
  
  /// @notice Get the close factor. Scaled by 1e8
  /// @return uint Close factor
  function closeFactor() external view returns(uint);

  /// @notice Get the liquidation incentive. Scaled by 1e8
  /// @return uint Liquidation incentive
  function liquidationIncentive() external view returns(uint);
  
  /// @notice Use this for quick lookups of collateral balances by asset
  /// @param account User account
  /// @param token ERC20 token
  /// @return uint Balance in local
  function collateralBalance(address account, IERC20 token) external view returns(uint);

  /// @notice Get iterable list of collateral addresses which an account has nonzero balance.
  /// @param account User account
  /// @return address[] Iterable list of ERC20 token addresses
  function iterableCollateralAddresses(address account) external view returns(IERC20[] memory);
  
  /// @notice Get iterable list of all Markets which an account has participated
  /// @param account User account
  /// @return address[] Iterable list of `FixedRateLoanMarket` contract addresses
  function iterableAccountMarkets(address account) external view returns(IFixedRateMarket[] memory);
                                                                         
  /// @notice Quick lookup of whether an account has participated in a Market
  /// @param account User account
  /// @param market`FixedRateLoanMarket` contract
  /// @return bool True if participated, false otherwise
  function accountMarkets(address account, IFixedRateMarket market) external view returns(bool);
                                                                       
  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param token ERC20 token
  /// @param amountLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD
  function localToUSD(IERC20 token, uint amountLocal) external view returns(uint);

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param token ERC20 token
  /// @param valueUSD Amount in USD
  /// @return uint Amount denominated in terms of the ERC20 token
  function USDToLocal(IERC20 token, uint valueUSD) external view returns(uint);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IFixedRateMarket.sol";
import "../libraries/QTypes.sol";

interface IQAdmin {
  
  /** ADMIN FUNCTIONS **/

  /// @notice Call upon initialization after deploying `QollateralManager` contract
  /// @param qollateralManagerAddress Address of `QollateralManager` deployment
  function _initializeQollateralManager(address qollateralManagerAddress) external;
  
  /// @notice Admin function for adding new Assets. An Asset must be added before it
  /// can be used as collateral or borrowed. Note: We can create functionality for
  /// allowing borrows of a token but not using it as collateral by setting
  /// `collateralFactor` to zero.
  /// @param token ERC20 token corresponding to the Asset
  /// @param isYieldBearing True if token bears interest (eg aToken, cToken, mToken, etc)
  /// @param underlying Address of the underlying token
  /// @param oracleFeed Chainlink price feed address
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for premium on risky borrows
  function _addAsset(
                     IERC20 token,
                     bool isYieldBearing,
                     address underlying,
                     address oracleFeed,
                     uint collateralFactor,
                     uint marketFactor
                     ) external;
  
  /// @notice Adds a new `FixedRateMarket` contract into the internal mapping of
  /// whitelisted market addresses
  /// @param market New `FixedRateMarket` contract
  function _addFixedRateMarket(IFixedRateMarket market) external;
  
  /// @notice Update the `collateralFactor` for a given `Asset`
  /// @param token ERC20 token corresponding to the Asset
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setCollateralFactor(IERC20 token, uint collateralFactor) external;

  /// @notice Update the `marketFactor` for a given `Asset`
  /// @param token Address of the token corresponding to the Asset
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setMarketFactor(IERC20 token, uint marketFactor) external;
  
  /// @notice Set the global initial collateral ratio
  /// @param initCollateralRatio_ New collateral ratio value
  function _setInitCollateralRatio(uint initCollateralRatio_) external;

  /// @notice Set the global close factor
  /// @param closeFactor_ New close factor value
  function _setCloseFactor(uint closeFactor_) external;

  function _setMaturityGracePeriod(uint maturityGracePeriod_) external;
  
  /// @notice Set the global liquidation incetive
  /// @param liquidationIncentive_ New liquidation incentive value
  function _setLiquidationIncentive(uint liquidationIncentive_) external;

  /// @notice Set the global annualized protocol fees in basis points
  /// @param protocolFee_ New protocol fee value (scaled to 1e4)
  function _setProtocolFee(uint protocolFee_) external;

  /** VIEW FUNCTIONS **/

  function ADMIN_ROLE() external view returns(bytes32);

  function MARKET_ROLE() external view returns(bytes32);

  function hasRole(bytes32 role, address account) external view returns(bool);
  
  /// @notice Get the address of the `QollateralManager` contract
  function qollateralManager() external view returns(address);
  
  /// @notice Gets the `Asset` mapped to the address of a ERC20 token
  /// @param token ERC20 token
  /// @return QTypes.Asset Associated `Asset`
  function assets(IERC20 token) external view returns(QTypes.Asset memory);

  /// @notice Gets the address of the `FixedRateMarket` contract
  /// @param token ERC20 token
  /// @param maturity UNIX timestamp of the maturity date
  /// @return IFixedRateMarket Address of `FixedRateMarket` contract
  function fixedRateMarkets(IERC20 token, uint maturity) external view returns(IFixedRateMarket);

  /// @notice Check whether an address is a valid FixedRateMarket address.
  /// Can be used for checks for inter-contract admin/restricted function call.
  /// @param market `FixedRateMarket` contract
  /// @return bool True if valid false otherwise
  function isMarketEnabled(IFixedRateMarket market) external view returns(bool);

  function minCollateralRatio() external view returns(uint);

  function initCollateralRatio() external view returns(uint);

  function closeFactor() external view returns(uint);

  function maturityGracePeriod() external view returns(uint);
  
  function liquidationIncentive() external view returns(uint);

  function protocolFee() external view returns(uint);
  
  /// @notice 2**256 - 1
  function UINT_MAX() external pure returns(uint);
  
  /// @notice Generic mantissa corresponding to ETH decimals
  function MANTISSA_DEFAULT() external pure returns(uint);

  /// @notice Mantissa for stablecoins
  function MANTISSA_STABLECOIN() external pure returns(uint);
  
  /// @notice Mantissa for collateral ratio
  function MANTISSA_COLLATERAL_RATIO() external pure returns(uint);

  /// @notice `assetFactor` and `marketFactor` have up to 8 decimal places precision
  function MANTISSA_FACTORS() external pure returns(uint);

  /// @notice Basis points have 4 decimal place precision
  function MANTISSA_BPS() external pure returns(uint);

  /// @notice `collateralFactor` cannot be above 1.0
  function MAX_COLLATERAL_FACTOR() external pure returns(uint);

  /// @notice `marketFactor` cannot be above 1.0
  function MAX_MARKET_FACTOR() external pure returns(uint);
  
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library ECDSA {

  /// @notice Recover the signer of a Quote given the plaintext inputs and signature
  /// @param marketAddress Address of `FixedRateMarket` contract
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR Annualized simple interest, scaled by 1e2
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @param signature Signed hash of the Quote message
  /// @return address Signer of the message
  function getSigner(
                     address marketAddress,
                     address quoter,
                     uint8 quoteType,
                     uint8 side,
                     uint64 quoteExpiryTime,
                     uint64 APR,
                     uint cashflow,
                     uint nonce,
                     bytes memory signature
                     ) internal pure returns(address){
    bytes32 messageHash = getMessageHash(
                                         marketAddress,
                                         quoter,
                                         quoteType,
                                         side,
                                         quoteExpiryTime,
                                         APR,
                                         cashflow,
                                         nonce
                                         );
    return  _recoverSigner(messageHash, signature);    
  }

  /// @notice Hashes the fields of a Quote into an Ethereum message hash
  /// @param marketAddress Address of `FixedRateMarket` contract
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR Annualized simple interest, scaled by 1e2
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @return bytes32 Message hash
  function getMessageHash(
                          address marketAddress,
                          address quoter,
                          uint8 quoteType,
                          uint8 side,
                          uint64 quoteExpiryTime,
                          uint64 APR,
                          uint cashflow,
                          uint nonce
                          ) internal pure returns(bytes32) {
    bytes32 unprefixedHash = keccak256(abi.encodePacked(
                                                        marketAddress,
                                                        quoter,
                                                        quoteType,
                                                        side,
                                                        quoteExpiryTime,
                                                        APR,
                                                        cashflow,
                                                        nonce
                                                        ));
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", unprefixedHash)); 
  }

  /// @notice Recovers the address of the signer of the `messageHash` from the
  /// signature. It should be used to check versus the cleartext address given
  /// to verify the message is indeed signed by the owner.
  /// @param messageHash Hash of the loan fields
  /// @param signature The candidate signature to recover the signer from
  /// @return address This is the recovered signer of the `messageHash` using the signature
  function _recoverSigner(
                          bytes32 messageHash,
                          bytes memory signature
                          ) private pure returns(address) {
    (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
    
    //built-in solidity function to recover the signer address using
    // the messageHash and signature
    return ecrecover(messageHash, v, r, s);
  }

  
  /// @notice Helper function that splits the signature into r,s,v components
  /// @param signature The candidate signature to recover the signer from
  /// @return r bytes32, s bytes32, v uint8
  function _splitSignature(bytes memory signature) private pure returns(
                                                                        bytes32 r,
                                                                        bytes32 s,
                                                                        uint8 v) {
    require(signature.length == 65, "invalid signature length");
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Interest {

  function PVToFV(
                  uint64 APR,
                  uint PV,
                  uint sTime,
                  uint eTime,
                  uint mantissaAPR
                  ) internal pure returns(uint){

    require(sTime < eTime, "invalid time interval");

    // Seconds per 365-day year (60 * 60 * 24 * 365)
    uint year = 31563000;
    
    // elapsed time from now to maturity
    uint elapsed = eTime - sTime;

    uint interest = PV * APR * elapsed / mantissaAPR / year;

    return PV + interest;    
  }

  function FVToPV(
                  uint64 APR,
                  uint FV,
                  uint sTime,
                  uint eTime,
                  uint mantissaAPR
                  ) internal pure returns(uint){

    require(sTime < eTime, "invalid time interval");

    // Seconds per 365-day year (60 * 60 * 24 * 365)
    uint year = 31563000;
    
    // elapsed time from now to maturity
    uint elapsed = eTime - sTime;

    uint num = FV * mantissaAPR * year;
    uint denom = mantissaAPR * year + APR * elapsed;

    return num / denom;
    
  }  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QTypes {

  struct Order {
    address quoter;
    uint8 side;
    uint64 quoteExpiryTime;
    uint64 APR;
    uint cashflow;
  }
  
  /// @notice Contains all the details of an Asset. Assets  must be defined
  /// before they can be used as collateral.
  /// @member isEnabled True if an asset is defined, false otherwise
  /// @member isYieldBearing True if token bears interest (eg aToken, cToken, mToken, etc)
  /// @member underlying Address of the underlying token
  /// @member oracleFeed Address of the corresponding chainlink oracle feed
  /// @member collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @member marketFactor 0.0 1.0 for premium on risky borrows
  /// @member maturities Iterable storage for all enabled maturities
  struct Asset {
    bool isEnabled;
    bool isYieldBearing;
    address underlying;
    address oracleFeed;
    uint collateralFactor;
    uint marketFactor;
    uint[] maturities;
  }
    
  /// @notice Contains all the fields of a published Quote
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @param signature Signed hash of the Quote message
  struct Quote {
    address marketAddress;
    address quoter;
    uint8 quoteType;
    uint8 side;
    uint64 quoteExpiryTime; //if 0, then quote never expires
    uint64 APR;
    uint cashflow;
    uint nonce;
    bytes signature;
  }
}