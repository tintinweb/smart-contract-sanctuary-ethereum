//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable as IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IFixedRateMarket.sol";
import "./libraries/ECDSA.sol";
import "./libraries/Interest.sol";
import "./QollateralManager.sol";
import "./QAdmin.sol";

contract FixedRateMarket is Initializable, ERC20, IFixedRateMarket {

  using SafeERC20 for IERC20;

  /// @notice Contract storing all global Qoda parameters
  QAdmin private _qAdmin;

  /// @notice Contract for managing anything collateral related
  QollateralManager private _qollateralManager;

  /// @notice Address of the ERC20 token which the loan will be denominated
  address private _tokenAddress;
  
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
                        address borrower,
                        address liquidator,
                        uint amount,
                        address collateralTokenAddress,
                        uint reward
                        );
  
  /// @notice Emitted when a borrower and lender are matched for a fixed rate loan
  event FixedRateLoan(
                      address borrower,
                      address lender,
                      uint amountPV,
                      uint amountFV);
  
  /// @notice Emitted when an account cancels their Quote
  event CancelQuote(address account, uint nonce);

  /// @notice Constructor for upgradeable contracts
  /// @param qAdminAddress_ Address of the `QAdmin` contract
  /// @param qollateralManagerAddress_ Address of the `QollateralManager` contract
  /// @param tokenAddress_ Address of the underlying loan token denomination
  /// @param maturity_ UNIX timestamp (in seconds) when the market matures
  /// @param name_ Name of the market's ERC20 token
  /// /@param symbol_ Symbol of the market's ERC20 token
  function initialize(
                      address qAdminAddress_,
                      address qollateralManagerAddress_,
                      address tokenAddress_,
                      uint maturity_,
                      string memory name_,
                      string memory symbol_
                      ) public initializer {
    __ERC20_init(name_, symbol_);
    _qAdmin = QAdmin(qAdminAddress_);
    _qollateralManager = QollateralManager(qollateralManagerAddress_);
    _tokenAddress = tokenAddress_;
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
            _checkApproval(msg.sender, _tokenAddress, amount),
            "FixedRateMarket: insufficient allowance"
            );

    // Check borrower has enough balance
    require(
            _checkBalance(msg.sender, _tokenAddress, amount),
            "FixedRateMarket: insufficient balance"
            );

    // Effects: Deduct from the account's total debts
    // Guaranteed not to underflow due to the flooring on amount above
    _accountBorrows[msg.sender] -= amount;

    // Transfer amount from borrower to contract for escrow until maturity
    IERC20 token = IERC20(_tokenAddress);
    token.safeTransferFrom(msg.sender, address(this), amount);

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

  /// @notice If an account is in danger of being undercollateralized (i.e.
  /// liquidityRatio < 1.0), any user may liquidate that account by paying
  /// back the loan on behalf of the account. In return, the liquidator receives
  /// collateral belonging to the account equal in value to the repayment amount
  /// in USD plus the liquidation incentive amount as a bonus.
  /// @param borrower Address of account that is undercollateralized
  /// @param amount Amount to repay on behalf of account in the currency of the loan
  /// @param collateralTokenAddress Liquidator's choice of which currency to be paid in
  function liquidateBorrow(
                           address borrower,
                           uint amount,
                           address collateralTokenAddress
                           ) external {

    // Ensure borrower is either undercollateralized or past payment due date.
    // These are the necessary conditions before borrower can be liquidated.
    require(
            _qollateralManager.liquidityRatio(borrower) < _qAdmin.minLiquidityRatio() ||
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
    uint amountUSD = _qollateralManager.localToUSD(_tokenAddress, amount);

    // Get USD value of amount plus liquidity incentive
    uint rewardUSD = amountUSD * _qAdmin.liquidationIncentive() / _qAdmin.MANTISSA_FACTORS();

    // Get the local amount of collateral to reward liquidator
    uint rewardLocal = _qollateralManager.USDToLocal(collateralTokenAddress, rewardUSD);

    // Ensure the borrower has enough collateral balance to pay the liquidator
    uint balance = _qollateralManager.collateralBalance(borrower, collateralTokenAddress);
    require(rewardLocal <= balance, "FixedRateMarket: borrower account balance too low");

    // Instantiate loan token interface
    IERC20 token = IERC20(_tokenAddress);

    // Liquidator repays the loan on behalf of borrower
    token.transferFrom(msg.sender, address(this), amount);

    // Credit the borrower's account
    _accountBorrows[borrower] -= amount;
      
    // Emit the event
    emit LiquidateBorrow(borrower, msg.sender, amount, collateralTokenAddress, rewardLocal);
    
    // Transfer the collateral balance from borrower to the liquidator
    _qollateralManager._transferCollateral(
                                           borrower,
                                           msg.sender,
                                           collateralTokenAddress,
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
  /// @return address
  function tokenAddress() external view returns(address){
    return _tokenAddress;
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
            _checkApproval(lender, _tokenAddress, amountPV),
            "FixedRateMarket: lender insufficient allowance"
            );

    // Check lender has enough balance
    require(
            _checkBalance(lender, _tokenAddress, amountPV),
            "FixedRateMarket: lender insufficient balance"
            );

    // The borrow amount of the borrower increases by the full `amountFV`
    _accountBorrows[borrower] += amountFV;


    // TODO: is there any way to only require the `amountPV` at time of inception of
    // loan and slowly converge the required collateral to equal `amountFV` by end
    // of loan? This allows for improved capital efficiency / less collateral upfront
    // required by borower

    // Check if borrower has sufficient collateral for loan. This should be
    // the `_initLiquidityRatio` which should be a larger value than the
    // `_minLiquidityRatio`. This protects users from taking loans at the
    // minimum threshold, putting them at risk of instant liquidation.
    uint liquidityRatio = _qollateralManager.hypotheticalLiquidityRatio(
                                                                        borrower,
                                                                        address(0),
                                                                        0,
                                                                        address(this),
                                                                        amountFV
                                                                        );
    require(
            liquidityRatio >= _qollateralManager.initLiquidityRatio(),
            "FixedRateMarket: borrower insufficient collateral"
            );
    
    // Net off borrow amount with any balance of qTokens the borrower may have
    uint repayAmountBorrower = Math.min(_accountBorrows[borrower], balanceOf(borrower));
    if(repayAmountBorrower > 0){
      _repayBorrowWithqToken(borrower, repayAmountBorrower);
    }
   
    // Record that the lender/borrow have participated in this market
    if(!_qollateralManager.accountMarkets(address(this), lender)){
      _qollateralManager._addAccountMarket(lender);
    }
    if(!_qollateralManager.accountMarkets(address(this), borrower)){
      _qollateralManager._addAccountMarket(borrower);
    }
    
    // Emit the matched borrower and lender and fixed rate loan terms
    emit FixedRateLoan(borrower, lender, amountPV, amountFV);
    
    // Transfer `amountPV` from lender to borrower
    IERC20 token = IERC20(_tokenAddress);
    token.safeTransferFrom(lender, borrower, amountPV);

    // Lender receives `amoutnFV` amount in qTokens
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
  /// @param tokenAddress_ Address of the ERC20 token
  /// @param amount Balance must be greater than or equal to this amount
  /// @return bool true if sufficient balance otherwise false
  function _checkBalance(
                         address userAddress,
                         address tokenAddress_,
                         uint256 amount
                         ) internal view returns(bool){
    if(IERC20(tokenAddress_).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }
  
  /// @notice Verify if the user has approved the smart contract for spend
  /// @param userAddress Address of the account to check
  /// @param tokenAddress_ Address of the ERC20 token
  /// @param amount Allowance  must be greater than or equal to this amount
  /// @return bool true if sufficient allowance otherwise false
  function _checkApproval(
                          address userAddress,
                          address tokenAddress_,
                          uint256 amount
                          ) internal view returns(bool) {
    if(IERC20(tokenAddress_).allowance(userAddress, address(this)) > amount){
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
    return IERC20Metadata(_tokenAddress).decimals();
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
        __Context_init_unchained();
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    uint256[45] private __gap;
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
  /// @param collateralTokenAddress Liquidator's choice of which currency to be paid in
  function liquidateBorrow(
                           address borrower,
                           uint amount,
                           address collateralTokenAddress
                           ) external;
  
  /** VIEW FUNCTIONS **/
  
  /// @notice Get the address of the `QollateralManager`
  /// @return address
  function qollateralManager() external view returns(address);

  /// @notice Get the address of the ERC20 token which the loan will be denominated
  /// @return address
  function tokenAddress() external view returns(address);

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {IERC20Upgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20MetadataUpgradeable as IERC20Metadata} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {SafeERC20Upgradeable as SafeERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IAggregatorV3.sol";
import "./interfaces/IFixedRateMarket.sol";
import "./libraries/QTypes.sol";
import "./Qontroller.sol";
import "./QAdmin.sol";


contract QollateralManager is Initializable {

  using SafeERC20 for IERC20;

  /// @notice Contract storing all global Qoda parameters
  QAdmin private _qAdmin;

  /// @notice Contract for controlling protocol functions
  Qontroller private _qontroller;
  
  /// @notice Use this for quick lookups of collateral balances by asset
  /// account => tokenAddress => balanceLocal
  mapping(address => mapping(address => uint)) private _collateralBalances;

  /// @notice Iterable list of all assets which an account has nonzero balance.
  /// Use this when calculating `collateralValue` for liquidity considerations
  /// account => tokenAddresses[]
  mapping(address => address[]) private _iterableAccountAssets;

  /// @notice Iterable list of all markets which an account has participated.
  /// Use this when calculating `totalBorrowValue` for liquidity considerations
  /// account => fixedRateMarketAddresses[]
  mapping(address => address[]) private _iterableAccountMarkets;

  /// @notice Non-iterable list of assets which an account has nonzero balance.
  /// Use this for quick lookups
  /// tokenAddress => account => bool;
  mapping(address => mapping(address => bool)) private _accountAssets;

  /// @notice Non-iterable list of markets which an account has participated.
  /// Use this for quick lookups
  /// fixedRateMarketAddress => account => bool;
  mapping(address => mapping(address => bool)) private _accountMarkets;

  /// @notice Emitted when an account deposits collateral into the contract
  event DepositCollateral(address account, address tokenAddress, uint amount);

  /// @notice Emitted when an account withdraws collateral from the contract
  event WithdrawCollateral(address account, address tokenAddress, uint amount);
  
  /// @notice Emitted when an account first interacts with the `Market`
  event AddAccountMarket(address account);

  /// @notice Constructor for upgradeable contracts
  /// @param qAdminAddress_ Address of the `QAdmin` contract
  /// @param qontrollerAddress_ Address of the `Qontroller` contract
  function initialize(
                      address qAdminAddress_,
                      address qontrollerAddress_
                      ) public initializer {
    
    _qAdmin = QAdmin(qAdminAddress_);

    _qontroller = Qontroller(qontrollerAddress_);
  }

  /// @notice Modifier which checks that the caller is the owner
  modifier onlyOwner() {
    require(_qAdmin.owner() ==  msg.sender, "QollateralManager: caller is not the owner");
    _;
  }

  /** ADMIN/RESTRICTED FUNCTIONS **/

  /// @notice Record when an account has either borrowed or lent into a
  /// `FixedRateMarket`. This is necessary because we need to iterate
  /// across all markets that an account has borrowed/lent to to calculate their
  /// `borrowValue`. Only the `FixedRateMarket` contract itself may call
  /// this function
  /// @param account User account
  function _addAccountMarket(address account) external {

    // Only enabled `FixedRateMarket` contracts can call this function
    require(
            _qontroller.isMarketEnabled(msg.sender),
            "QollateralManager: Unauthorized"
            );
    
    // Record that account now has participated in this Market
    if(!_accountMarkets[msg.sender][account]){
      _accountMarkets[msg.sender][account] = true;
      _iterableAccountMarkets[account].push(msg.sender);
    }

    // Emit the event
    emit AddAccountMarket(account);
  }

  /// @notice Transfer collateral balances from one account to another. Only
  /// `FixedRateMarket` contracts can call this restricted function. This is used
  /// for when a liquidator liquidates an account.
  /// @param from Sender address
  /// @param to Recipient address
  /// @param tokenAddress Address of the ERC20 token
  /// @param amount Amount to transfer
  function _transferCollateral(
                               address from,
                               address to,
                               address tokenAddress,
                               uint amount
                               ) external {

    // Only enabled `FixedRateMarket` contracts can call this function
    require(
            _qontroller.isMarketEnabled(msg.sender),
            "QollateralManager: Unauthorized"
            );

    // Check `from` address has enough collateral balance
    require(
            amount <= _collateralBalances[from][tokenAddress],
            "QollateralManager: `from` balance too low"
            );

    // Transfer the balance to recipient
    _collateralBalances[from][tokenAddress] -= amount;
    _collateralBalances[to][tokenAddress] += amount;    
  }

  
  /** USER INTERFACE **/

  /// @notice Users call this to deposit collateral to fund their borrows
  /// @param tokenAddress Address of the token the collateral will be denominated in
  /// @param amount Amount to deposit (in local ccy)
  /// @return uint New collateral balance 
  function depositCollateral(address tokenAddress, uint amount) external returns(uint) {

    // Sender must give approval to QollateralManager for spend
    require(
            _checkApproval(tokenAddress, msg.sender, amount),
            "QollateralManager: insufficient allowance"
            );
    
    // Sender must have enough balance for deposit
    require(
            _checkBalance(tokenAddress, msg.sender, amount),
            "QollateralManager: insufficient balance"
            );

    // Get the associated `Asset` to the token address
    QTypes.Asset memory asset = _qontroller.assets(tokenAddress);

    // Only enabled assets are supported as collateral
    require(asset.isEnabled, "QollateralManager: asset not supported");

    // Record that sender now has collateral deposited in this Asset
    if(!_accountAssets[tokenAddress][msg.sender]){
      _iterableAccountAssets[msg.sender].push(tokenAddress);
      _accountAssets[tokenAddress][msg.sender] = true;
    }

    // Transfer the collateral from the account to this contract as escrow
    _transferFrom(tokenAddress, msg.sender, address(this), amount);
    
    // Record the increase in collateral balance for the account
    _collateralBalances[msg.sender][tokenAddress] += amount;
    
    // Emit the event
    emit DepositCollateral(msg.sender, tokenAddress, amount);

    // Return the account's updated collateral balance for this token
    return _collateralBalances[msg.sender][tokenAddress];
  }
  
  /// @notice Users call this to withdraw collateral
  /// @param tokenAddress Address of the token to withdraw
  /// @param amount Amount to withdraw (in local ccy)
  /// @return uint New collateral balance 
  function withdrawCollateral(address tokenAddress, uint amount) external returns(uint) {

    // User may only withdraw up to their total local balance for any token
    amount = Math.min(amount, _collateralBalances[msg.sender][tokenAddress]);

    // Get the hypothetical liquidity ratio after withdrawal
    uint liquidityRatio_ = _getHypotheticalLiquidityRatio(
                                             msg.sender,
                                             tokenAddress,
                                             amount,
                                             address(0),
                                             0
                                             );
    
    // Amount must be positive
    require(amount > 0, "QollateralManager: amount must be positive");
    
    // Check the liquidity ratio after withdrawal is still healthy.
    // User is only allowed to withdraw up to `_initLiquidityRatio`,
    // not `_minLiquidityRatio`, for their own protection against
    // instant liquidations.
    require(
            liquidityRatio_ >= _qAdmin.initLiquidityRatio(),
            "QollateralManager: withdraw amount leaves account undercollateralized"
            );

    // Record the decrease in collateral balance for the account
    _collateralBalances[msg.sender][tokenAddress] -= amount;

    // Withdraw the collateral from the protocol to the account
    _transfer(tokenAddress, msg.sender, amount);
    
    // Emit the event
    emit WithdrawCollateral(msg.sender, tokenAddress, amount);
    
    // Return the account's updated collateral balance for this token
    return _collateralBalances[msg.sender][tokenAddress];
  }

  /** VIEW FUNCTIONS **/

  /// @notice Return the address of the current owner, stored in the `QAdmin` contract
  /// @return address Address of owner
  function owner() external view returns(address){
    return _qAdmin.owner();
  }

  /// @notice Get the address of the `QAdmin` contract
  /// @return address Address of `QAdmin` contract
  function qAdmin() external view returns(address){
    return address(_qAdmin);
  }
  
  /// @notice Get the address of the `Qontroller` contract
  /// @return address Address of `Qontroller` contract
  function qontroller() external view returns(address){
    return address(_qontroller);
  }
  
  /// @notice Return what the liquidity ratio for an account would be
  /// with a hypothetical collateral withdraw and/or token borrow.
  /// The liquidity ratio is calculated as:
  /// (`weightedCollateralValue` / `weightedBorrowValue`)
  /// This returns a value from 0-1, scaled by 1e8.
  /// If this value fals below 1, the account can be liquidated
  /// @param account User account
  /// @param withdrawTokenAddress Currency of hypothetical withdraw
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param borrowMarketAddress Market of hypothetical borrow
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @return uint Hypothetical liquidity ratio
  function hypotheticalLiquidityRatio(
                                      address account,
                                      address withdrawTokenAddress,
                                      uint withdrawAmount,
                                      address borrowMarketAddress,
                                      uint borrowAmount
                                      ) external view returns(uint){
    return _getHypotheticalLiquidityRatio(
                                          account,
                                          withdrawTokenAddress,
                                          withdrawAmount,
                                          borrowMarketAddress,
                                          borrowAmount
                                          );                                          
  }

  /// @notice Return the current liquidity ratio for an account.
  /// The liquidity ratio is calculated as:
  /// (`weightedCollateralValue` / `weightedBorrowValue`)
  /// This returns a value from 0-1, scaled by 1e8.
  /// If this value fals below 1, the account can be liquidated
  /// @param account User account
  /// @return uint Liquidity ratio
  function liquidityRatio(address account) external view returns(uint){
    return _getHypotheticalLiquidityRatio(account, address(0), 0, address(0), 0);
  }

  /// @notice Get the `collateralFactor` weighted value (in USD) of all the
  /// collateral deposited for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function virtualCollateralValue(address account) external view returns(uint){
    return _getHypotheticalCollateralValue(account, address(0), 0, true);
  }

  /// @notice Get the `collateralFactor` weighted value (in USD) for the tokens
  /// deposited for an account
  /// @param account Account to query
  /// @param tokenAddress Address of ERC20 token
  /// @return uint Value of token collateral of account in USD
  function virtualCollateralValueByToken(
                                         address account,
                                         address tokenAddress
                                         ) external view returns(uint){
    return _getHypotheticalCollateralValueByToken(account, tokenAddress, 0, true);
  }

  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD
  function virtualBorrowValue(address account) external view returns(uint){
    return _getHypotheticalBorrowValue(account, address(0), 0, true);
  }

  /// @notice Get the `marketFactor` weighted net borrows (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param marketAddress address of the `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD
  function virtualBorrowValueByMarket(
                                      address account,
                                      address marketAddress
                                      ) external view returns(uint){
    return _getHypotheticalBorrowValueByMarket(account, marketAddress, 0, true);
  }
  
  /// @notice Get the unweighted value (in USD) of all the collateral deposited
  /// for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function realCollateralValue(address account) external view returns(uint){
    return _getHypotheticalCollateralValue(account, address(0), 0, false);
  }
  
  /// @notice Get the unweighted value (in USD) of the tokens deposited
  /// for an account
  /// @param account Account to query
  /// @param tokenAddress Address of ERC20 token
  /// @return uint Value of token collateral of account in USD
  function realCollateralValueByToken(
                                      address account,
                                      address tokenAddress
                                      ) external view returns(uint){
    return _getHypotheticalCollateralValueByToken(account, tokenAddress, 0, false);
  }
  
  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD summed across all `Market`s participated in by the user
  /// @param account Account to query
  /// @return uint Borrow value of account in USD
  function realBorrowValue(address account) external view returns(uint){
    return _getHypotheticalBorrowValue(account, address(0), 0, false);
  }

  /// @notice Get the unweighted current net value borrowed (i.e. borrows - lends)
  /// in USD for a particular `Market`
  /// @param account Account to query
  /// @param marketAddress Address of the `FixedRateMarket` contract
  /// @return uint Borrow value of account in USD
  function realBorrowValueByMarket(
                                   address account,
                                   address marketAddress
                                   ) external view returns(uint){
    return _getHypotheticalBorrowValueByMarket(account, marketAddress, 0, false);
  }

  /// @notice Get the minimum liquidity ratio. Scaled by 1e8.
  /// @return uint Minimum liquidity ratio
  function minLiquidityRatio() external view returns(uint){
    return _qAdmin.minLiquidityRatio();
  }

  /// @notice Get the initial liquidity ratio. Scaled by 1e8
  /// @return uint Initial liquidity ratio
  function initLiquidityRatio() external view returns(uint){
    return _qAdmin.initLiquidityRatio();
  }

  /// @notice Get the close factor. Scaled by 1e8
  /// @return uint Close factor
  function closeFactor() external view returns(uint){
    return _qAdmin.closeFactor();
  }

  /// @notice Get the liquidation incentive. Scaled by 1e8
  /// @return uint Liquidation incentive
  function liquidationIncentive() external view returns(uint){
    return _qAdmin.liquidationIncentive();
  }

  /// @notice Use this for quick lookups of collateral balances by asset
  /// @param account User account  
  /// @param tokenAddress Address of ERC20 token
  /// @return uint Balance in local
  function collateralBalance(
                             address account,
                             address tokenAddress
                             ) external view returns(uint){
    return _collateralBalances[account][tokenAddress];
  }

  /// @notice Get iterable list of assets which an account has nonzero balance.
  /// @param account User account
  /// @return address[] Iterable list of ERC20 token addresses
  function iterableAccountAssets(address account) external view returns(address[] memory){
    return _iterableAccountAssets[account];
  }
  
  /// @notice Get iterable list of all Markets which an account has participated
  /// @param account User account
  /// @return address[] Iterable list of `FixedRateLoanMarket` contract addresses
  function iterableAccountMarkets(address account) external view returns(address[] memory){
    return _iterableAccountMarkets[account];
  }

  /// @notice Quick lookup of whether an account has nonzero balance in an asset.
  /// @param tokenAddress Address of ERC20 token
  /// @param account User account
  /// @return bool True if user has balance, false otherwise
  function accountAssets(address tokenAddress, address account) external view returns(bool){
    return _accountAssets[tokenAddress][account];
  }

  /// @notice Quick lookup of whether an account has participated in a Market
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param account User account
  /// @return bool True if participated, false otherwise
  function accountMarkets(address marketAddress, address account) external view returns(bool){
    return _accountMarkets[marketAddress][account];
  }

  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed.
  /// @return answer uint256, decimals uint8
  function priceFeed(address oracleFeed) external view returns(uint256, uint8){
    return _priceFeed(oracleFeed);
  }

  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param tokenAddress Address of the ERC20 token
  /// @param valueLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD
  function localToUSD(
                      address tokenAddress,
                      uint valueLocal
                      ) external view returns(uint){
    return _localToUSD(tokenAddress, valueLocal);
  }

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param tokenAddress Address of the ERC20 token
  /// @param valueUSD Amount in USD
  /// @return uint Amount denominated in terms of the ERC20 token
  function USDToLocal(
                      address tokenAddress,
                      uint valueUSD
                      ) external view returns(uint){
    return _USDToLocal(tokenAddress, valueUSD);
  }

  
  /** INTERNAL FUNCTIONS **/
  
  /// @notice Return what the liquidity ratio for an account would be
  /// with a hypothetical collateral withdraw and/or token borrow.
  /// The liquidity ratio is calculated as:
  /// (`collateralValueWeighted` / `borrowValueWeighted`)
  /// This returns a value from 0-1, scaled by 1e8.
  /// If this value fals below 1, the account can be liquidated
  /// @param account User account
  /// @param withdrawTokenAddress Currency of hypothetical withdraw
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param borrowMarketAddress Market of hypothetical borrow
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @return uint Hypothetical liquidity ratio
  function _getHypotheticalLiquidityRatio(
                                          address account,
                                          address withdrawTokenAddress,
                                          uint withdrawAmount,
                                          address borrowMarketAddress,
                                          uint borrowAmount
                                          ) internal view returns(uint){

    // The numerator is the weighted hypothetical collateral value
    uint num = _getHypotheticalCollateralValue(
                                               account,
                                               withdrawTokenAddress,
                                               withdrawAmount,
                                               true
                                               );

    // The denominator is the weighted hypothetical borrow value
    uint denom = _getHypotheticalBorrowValue(
                                             account,
                                             borrowMarketAddress,
                                             borrowAmount,
                                             true
                                             );

    if(denom == 0){
      // Need to handle division by zero if account has no borrows
      return _qAdmin.UINT_MAX();      
    }else{
      // Return the liquidity ratio as a value from 0-1, scaled by 1e8
      return num * _qAdmin.MANTISSA_LIQUIDITY_RATIO() / denom;
    }        
  }
  
  /// @notice Return what the total collateral value for an account would be
  /// with a hypothetical withdraw, with an option for weighted or unweighted value
  /// @param account Account to query
  /// @param withdrawTokenAddress Currency of hypothetical withdraw
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param applyCollateralFactor True to get the `collateralFactor` weighted value, false otherwise
  /// @return uint Total value of account in USD
  function _getHypotheticalCollateralValue(
                                           address account,
                                           address withdrawTokenAddress,
                                           uint withdrawAmount,
                                           bool applyCollateralFactor
                                           ) internal view returns(uint){
            
    uint totalValueUSD = 0;

    for(uint i=0; i<_iterableAccountAssets[account].length; i++){

      // Get the token address in i'th slot of `_iterableAccountAssets[account]`
      address tokenAddress = _iterableAccountAssets[account][i];

      // Check if token address matches hypothetical withdraw token
      if(tokenAddress == withdrawTokenAddress){
        // Add value to total minus the hypothetical withdraw amount
        totalValueUSD += _getHypotheticalCollateralValueByToken(
                                                                account,
                                                                tokenAddress,
                                                                withdrawAmount,
                                                                applyCollateralFactor
                                                                );
      }else{
        // Add value to total with zero hypothetical withdraw amount
        totalValueUSD += _getHypotheticalCollateralValueByToken(
                                                                account,
                                                                tokenAddress,
                                                                0,
                                                                applyCollateralFactor
                                                                );
      }
    }
    
    return totalValueUSD;
  }

  
  /// @notice Return what the collateral value by token for an account would be
  /// with a hypothetical withdraw, with an option for weighted or unweighted value
  /// @param account Account to query
  /// @param tokenAddress Address of ERC20 token
  /// @param withdrawAmount Amount of hypothetical withdraw in local currency
  /// @param applyCollateralFactor True to get the `collateralFactor` weighted value, false otherwise
  /// @return uint Total value of account in USD
  function _getHypotheticalCollateralValueByToken(
                                                  address account,
                                                  address tokenAddress,
                                                  uint withdrawAmount,
                                                  bool applyCollateralFactor
                                                  ) internal view returns(uint){

    require(
            withdrawAmount <= _collateralBalances[account][tokenAddress],
            "QollateralManager: withdraw amount must be <= to balance"
            );
    
    // Get the `Asset` associated to this token
    QTypes.Asset memory asset = _qontroller.assets(tokenAddress);

    // Value of collateral in any unsupported `Asset` is zero
    if(!asset.isEnabled){
      return 0;
    }
    
    // Get the local balance of the account for the given `tokenAddress`
    uint balanceLocal = _collateralBalances[account][tokenAddress];

    // Subtract any hypothetical withdraw amount. Guaranteed not to underflow
    balanceLocal -= withdrawAmount;
    
    // Convert the local balance to USD
    uint valueUSD = _localToUSD(tokenAddress, balanceLocal);
    
    if(applyCollateralFactor){
      // Apply the `collateralFactor` to get the discounted value of the asset       
      valueUSD = valueUSD * asset.collateralFactor / _qAdmin.MANTISSA_FACTORS();
    }
    
    return valueUSD;
  }

  /// @notice Return what the total borrow value for an account would be
  /// with a hypothetical borrow, with an option for weighted or unweighted value  
  /// @param account Account to query
  /// @param borrowMarketAddress Market of hypothetical borrow
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @param applyMarketFactor True to get the `marketFactor` weighted value, false otherwise
  /// @return uint Borrow value of account in USD
  function _getHypotheticalBorrowValue(
                                       address account,
                                       address borrowMarketAddress,
                                       uint borrowAmount,
                                       bool applyMarketFactor
                                       ) internal view returns(uint){
    
    uint totalValueUSD = 0;
    for(uint i=0; i<_iterableAccountMarkets[account].length; i++){
      
      // Get the market address in i'th slot of `_iterableAccountMarkets[account]`
      address marketAddress = _iterableAccountMarkets[account][i];
      
      // Check if the user is requesting to borrow more in this `Market`
      if(marketAddress == borrowMarketAddress){
        // User requesting to borrow more in this `Market`, add the amount to borrows
        totalValueUSD += _getHypotheticalBorrowValueByMarket(
                                                             account,
                                                             marketAddress,
                                                             borrowAmount,
                                                             applyMarketFactor
                                                             );
      }else{
        // User not requesting to borrow more in this `Market`, just get current value
        totalValueUSD += _getHypotheticalBorrowValueByMarket(
                                                             account,
                                                             marketAddress,
                                                             0,
                                                             applyMarketFactor
                                                             );
      }
    }
    return totalValueUSD;    
  }
  

  /// @notice Return what the borrow value by `Market` for an account would be
  /// with a hypothetical borrow, with an option for weighted or unweighted value  
  /// @param account Account to query
  /// @param marketAddress Address of `FixedRateMarket`
  /// @param borrowAmount Amount of hypothetical borrow in local ccy
  /// @param applyMarketFactor True to get the `marketFactor` weighted value, false otherwise
  /// @return uint Borrow value of account in USD
  function _getHypotheticalBorrowValueByMarket(
                                               address account,
                                               address marketAddress,
                                               uint borrowAmount,
                                               bool applyMarketFactor
                                               ) internal view returns(uint){
    
    // Instantiate interfaces
    IFixedRateMarket market = IFixedRateMarket(marketAddress);

    // Total `borrowsLocal` should be current borrow plus `borrowAmount`
    uint borrowsLocal = market.accountBorrows(account) + borrowAmount;

    // Total `lendsLocal` is just the user's balance of qTokens
    uint lendsLocal = market.balanceOf(account);
    if(lendsLocal >= borrowsLocal){
      // Default to zero if lends greater than borrows
      return 0;
    }else{
      
      // Get the net amount being borrowed in local
      // Guaranteed not to underflow from the above check
      uint borrowValueLocal = borrowsLocal - lendsLocal;     

      // Convert from local value to value in USD
      address tokenAddress = market.tokenAddress();
      QTypes.Asset memory asset = _qontroller.assets(tokenAddress);
      uint borrowValueUSD = _localToUSD(tokenAddress, borrowValueLocal);

      if(applyMarketFactor){
        // Apply the `marketFactor` to get the risk premium value of the borrow
        borrowValueUSD = borrowValueUSD * _qAdmin.MANTISSA_FACTORS() / asset.marketFactor;
      }
      
      return borrowValueUSD;
    }
  }
        
  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param tokenAddress Address of the ERC20 token
  /// @param valueLocal Amount denominated in terms of the ERC20 token
  /// @return uint Amount in USD
  function _localToUSD(
                       address tokenAddress,
                       uint valueLocal
                       ) internal view returns(uint){
    
    IERC20Metadata token = IERC20Metadata(tokenAddress);


    // Check that the token is an enabled asset
    QTypes.Asset memory asset = _qontroller.assets(tokenAddress);
    require(asset.isEnabled, "QollateralManager: token not supported");

    // Get the oracle feed
    address oracleFeed = asset.oracleFeed;    
    (uint exchRate, uint8 exchDecimals) = _priceFeed(oracleFeed);
    
    // Initialize all the necessary mantissas first
    uint exchRateMantissa = 10 ** exchDecimals;
    uint tokenMantissa = 10 ** token.decimals();
    
    // Convert `valueLocal` to USD
    uint valueUSD = valueLocal * exchRate * _qAdmin.MANTISSA_STABLECOIN();
    
    // Divide by mantissas last for maximum precision
    valueUSD = valueUSD / tokenMantissa / exchRateMantissa;
    
    return valueUSD;
  }

  /// @notice Converts any value in USD into its value in local using oracle feed price
  /// @param tokenAddress Address of the ERC20 token
  /// @param valueUSD Amount in USD
  /// @return uint Amount denominated in terms of the ERC20 token
  function _USDToLocal(
                       address tokenAddress,
                       uint valueUSD
                       ) internal view returns(uint){

    IERC20Metadata token = IERC20Metadata(tokenAddress);

    // Check that the token is an enabled asset
    QTypes.Asset memory asset = _qontroller.assets(tokenAddress);
    require(asset.isEnabled, "QollateralManager: token not supported");

    // Get the oracle feed
    address oracleFeed = asset.oracleFeed;
    (uint exchRate, uint8 exchDecimals) = _priceFeed(oracleFeed);

    // Initialize all the necessary mantissas first
    uint exchRateMantissa = 10 ** exchDecimals;
    uint tokenMantissa = 10 ** token.decimals();

    // Multiply by mantissas first for maximum precision
    uint valueLocal = valueUSD * tokenMantissa * exchRateMantissa;

    // Convert `valueUSD` to local
    valueLocal = valueLocal / exchRate / _qAdmin.MANTISSA_STABLECOIN();

    return valueLocal;    
  }
  
  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed
  /// @return answer uint256, decimals uint8
  function _priceFeed(address oracleFeed) internal view returns(uint256, uint8){
    IAggregatorV3 aggregator = IAggregatorV3(oracleFeed);
    (, int256 answer,,,) =  aggregator.latestRoundData();
    uint8 decimals = aggregator.decimals();
    return (uint(answer), decimals);
  }

  /// @notice Handles the transfer function for a token.
  /// @param tokenAddress Address of the token to transfer
  /// @param to Address of the receiver
  /// @param amount Amount of tokens to transfer
  function _transfer(
                     address tokenAddress,
                     address to,
                     uint amount
                     ) internal {
    IERC20 token = IERC20(tokenAddress);
    token.safeTransfer(to, amount);
  }
  
  /// @notice Handles the transferFrom function for a token.
  /// @param tokenAddress Address of the token to transfer
  /// @param from Address of the sender
  /// @param to Adress of the receiver
  /// @param amount Amount of tokens to transfer
  function _transferFrom(
                        address tokenAddress,
                        address from,
                        address to,
                        uint amount
                        ) internal {
    require(
            _checkApproval(tokenAddress, from, amount),
            "QollateralManager: insufficient allowance"
            );
    
    require(
            _checkBalance(tokenAddress, from, amount),
            "QollateralManager: insufficient balance"
            );
    
    IERC20 token = IERC20(tokenAddress);
    token.safeTransferFrom(from, to, amount);
  }

  /// @notice Verify if the user has enough token balance
  /// @param tokenAddress Address of the ERC20 token
  /// @param userAddress Address of the account to check
  /// @param amount Balance must be greater than or equal to this amount
  /// @return bool true if sufficient balance otherwise false
  function _checkBalance(
                         address tokenAddress,
                         address userAddress,
                         uint256 amount
                         ) internal view returns(bool){
    if(IERC20(tokenAddress).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }

  /// @notice Verify if the user has approved the smart contract for spend
  /// @param tokenAddress Address of the ERC20 token
  /// @param userAddress Address of the account to check
  /// @param amount Allowance  must be greater than or equal to this amount
  /// @return bool true if sufficient allowance otherwise false
  function _checkApproval(
                          address tokenAddress,
                          address userAddress,
                          uint256 amount
                          ) internal view returns(bool) {
    if(IERC20(tokenAddress).allowance(userAddress, address(this)) > amount){
      return true;
    }
    return false;
  }

  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract QAdmin is Initializable, Ownable {

  /// @notice If liquidity ratio falls below `_minLiquidityRatio`, it is subject to liquidation
  /// Scaled by 1e8
  uint private _minLiquidityRatio;

  /// @notice When initially taking a loan, liquidity ratio must be higher than this.
  /// `_initLiquidityRatio` should always be higher than `_minLiquidityRatio`
  /// Scaled by 1e8
  uint private _initLiquidityRatio;

  /// @notice The percent, ranging from 0% to 100%, of a liquidatable account's
  /// borrow that can be repaid in a single liquidate transaction.
  /// Scaled by 1e8
  uint private _closeFactor;
  
  /// @notice Additional collateral given to liquidator as incentive to liquidate
  /// underwater accounts. For example, if liquidation incentive is 1.1, liquidator
  /// receives extra 10% of borrowers' collateral
  /// Scaled by 1e8
  uint private _liquidationIncentive;

  /// @notice Annualized fee for loans in basis points. The fee is charged to
  /// both the lender and the borrower on any given deal. The fee rate will
  /// need to be scaled for loans that mature outside of 1 year.
  /// Scaled by 1e4
  uint private _protocolFee;
  
  /// @notice Emitted when `_initLiquidityRatio` gets updated
  event SetInitLiquidityRatio(uint oldValue, uint newValue);

  /// @notice Emitted when `_closeFactor` gets updated
  event SetCloseFactor(uint oldValue, uint newValue);
  
  /// @notice Emitted when `_liquidationIncentive` gets updated
  event SetLiquidationIncentive(uint oldValue, uint newValue);

  /// @notice Emitted when `_protocolFee` gets updated
  event SetProtocolFee(uint oldValue, uint newValue);

  /// @notice Constructor for upgradeable contracts
  function initialize() public initializer {

    __Ownable_init();
    
    // Set initial values for parameters
    _minLiquidityRatio = 1e8;
    _initLiquidityRatio = 1.1e8;
    _closeFactor = 0.5e8;
    _liquidationIncentive = 1.1e8;
    _protocolFee = .0020e4;
  }

  /** ADMIN FUNCTIONS **/
  
  /// @notice Set the global initial liquidity ratio
  /// @param initLiquidityRatio_ New liquidity ratio value
  function _setInitLiquidityRatio(uint initLiquidityRatio_) external onlyOwner {

    // `_initLiquidityRatio` cannot be below `_minLiquidityRatio`
    require(
            initLiquidityRatio_ >= _minLiquidityRatio,
            "QAdmin: init liquidity ratio must be greater than min liquidity ratio"
            );

    // Emit the event
    emit SetInitLiquidityRatio(_initLiquidityRatio, initLiquidityRatio_);
    
    // Set `_initialLiquidityRatio` to new value
    _initLiquidityRatio = initLiquidityRatio_;
  }

  /// @notice Set the global close factor
  /// @param closeFactor_ New close factor value
  function _setCloseFactor(uint closeFactor_) external onlyOwner {
    
    // `_closeFactor` needs to be between 0 and 1
    require(closeFactor_ <= MANTISSA_FACTORS(), "QAdmin: must be between 0 and 1");

    // Emit the event
    emit SetCloseFactor(_closeFactor, closeFactor_);
    
    // Set `_closeFactor` to new value
    _closeFactor = closeFactor_;
  }

  /// @notice Set the global liquidation incetive
  /// @param liquidationIncentive_ New liquidation incentive value
  function _setLiquidationIncentive(uint liquidationIncentive_) external onlyOwner {

    // `_liquidationIncentive` needs to be greater than or equal to 1
    require(
            liquidationIncentive_ >= MANTISSA_FACTORS(),
            "QAdmin: must be greater than or equal to 1"
            );

    // Emit the event
    emit SetLiquidationIncentive(_liquidationIncentive, liquidationIncentive_);   
    
    // Set `_liquidationIncentive` to new value
    _liquidationIncentive = liquidationIncentive_;
  }

  /// @notice Set the global annualized protocol fees in basis points
  /// @param protocolFee_ New protocol fee value (scaled to 1e4)
  function _setProtocolFee(uint protocolFee_) external onlyOwner {

    // Max annual protocol fees of 250 basis points
    require(protocolFee_ <= 250, "QAdmin: must be less than 2.5%");

    // Min annual protocol fees of 1 basis point
    require(protocolFee_ >= 1, "QAdmin: must be greater than .01%");
    
    // Emit the event
    emit SetProtocolFee(_protocolFee, protocolFee_);
    
    // Set `_protocolFee` to new value
    _protocolFee = protocolFee_;
  }

  /** VIEW FUNCTIONS **/
  function minLiquidityRatio() public view returns(uint){
    return _minLiquidityRatio;
  }

  function initLiquidityRatio() public view returns(uint){
    return _initLiquidityRatio;
  }

  function closeFactor() public view returns(uint){
    return _closeFactor;
  }

  function liquidationIncentive() public view returns(uint){
    return _liquidationIncentive;
  }
    
  /// @notice 2**256 - 1
  function UINT_MAX() public pure returns(uint){
    return type(uint).max;
  }
  
  /// @notice Generic mantissa corresponding to ETH decimals
  function MANTISSA_DEFAULT() public pure returns(uint){
    return 1e18;
  }

  /// @notice Mantissa for stablecoins
  function MANTISSA_STABLECOIN() public pure returns(uint){
    return 1e6;
  }
  
  /// @notice Mantissa for liquidity ratio
  function MANTISSA_LIQUIDITY_RATIO() public pure returns(uint){
    return 1e8;
  }

  /// @notice `assetFactor` and `marketFactor` have up to 8 decimal places precision
  function MANTISSA_FACTORS() public pure returns(uint){
    return 1e8;
  }

  /// @notice Basis points have 4 decimal place precision
  function MANTISSA_BPS() public pure returns(uint){
    return 1e4;
  }

  /// @notice `collateralFactor` cannot be above 1.0
  function MAX_COLLATERAL_FACTOR() public pure returns(uint){
    return 1e8;
  }

  /// @notice `marketFactor` cannot be above 1.0
  function MAX_MARKET_FACTOR() public pure returns(uint){
    return 1e8;
  }
  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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
pragma solidity ^0.8.9;

interface IAggregatorV3 {
    /**
     * Returns the decimals to offset on the getLatestPrice call
     */
    function decimals() external view returns (uint8);

    /**
     * Returns the description of the underlying price feed aggregator
     */
    function description() external view returns (string memory);

    /**
     * Returns the version number representing the type of aggregator the proxy points to
     */
    function version() external view returns (uint256);

    /**
     * Returns price data about a specific round
     */
    function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    /**
     * Returns price data from the latest round
     */
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QTypes {

  /// @notice Contains all the details of an Asset. Assets  must be defined
  /// before they can be used as collateral.
  /// @member isEnabled True if a asset is defined, false otherwise
  /// @member oracleFeed Address of the corresponding chainlink oracle feed
  /// @member collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @member marketFactor 0.0 1.0 for premium on risky borrows
  /// @member maturities Iterable storage for all enabled maturities
  struct Asset {
    bool isEnabled;
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IFixedRateMarket.sol";
import "./libraries/QTypes.sol";
import "./QAdmin.sol";
import "./QollateralManager.sol";

contract Qontroller is Initializable {
  
  /// @notice Contract storing all global Qoda parameters
  QAdmin private _qAdmin;

  /// @notice Contract for managing user collateral
  QollateralManager private _qollateralManager;
  
  /// @notice All enabled `Asset`s
  /// tokenAddress => Asset
  mapping(address => QTypes.Asset) private _assets;

  /// @notice Get the `FixedRateMarket` contract address for any given
  /// token and maturity time
  /// tokenAddress => maturity => fixedRateMarket
  mapping(address => mapping(uint => address)) private _fixedRateMarkets;

  /// @notice Mapping to determine whether a `fixedRateMarket` address
  /// is enabled or not
  /// fixedRateMarket => bool
  mapping(address => bool) private _enabledMarkets;

  /// @notice Emitted when a new FixedRateMarket is deployed
  event CreateFixedRateMarket(address marketAddress, address tokenAddress, uint maturity);
  
  /// @notice Emitted when a new `Asset` is added
  event AddAsset(
                 address tokenAddress,
                 address oracleFeed,
                 uint collateralFactor,
                 uint marketFactor);

  /// @notice Emitted when setting `collateralFactor`
  event SetCollateralFactor(address tokenAddress, uint oldValue, uint newValue);

  /// @notice Emitted when setting `marketFactor`
  event SetMarketFactor(address tokenAddress, uint oldValue, uint newValue);
  
  /// @notice Constructor for upgradeable contracts
  /// @param qAdminAddress Address of the `QAdmin` contract
  function initialize(address qAdminAddress) public initializer {
    
    // Set the `QAdmin` contract object
    _qAdmin = QAdmin(qAdminAddress);
  }
  
  /// @notice Modifier which checks that the caller is the owner
  modifier onlyOwner() {
    require(_qAdmin.owner() ==  msg.sender, "Qontroller: caller is not the owner");
    _;
  }

  /** ADMIN / RESTRICTED FUNCTIONS **/
  function _initializeQollateralManager(address qollateralManagerAddress) public onlyOwner {
    
    // Initialize the value
    _qollateralManager = QollateralManager(qollateralManagerAddress);
  }

  
  /// @notice Admin function for adding new Assets. An Asset must be added before it
  /// can be used as collateral or borrowed. Note: We can create functionality for
  /// allowing borrows of a token but not using it as collateral by setting
  /// `collateralFactor` to zero.
  /// @param tokenAddress Address of the token corresponding to the Asset
  /// @param oracleFeed Chainlink price feed address
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for premium on risky borrows
  function _addAsset(
                     address tokenAddress,
                     address oracleFeed,
                     uint collateralFactor,
                     uint marketFactor
                     ) external onlyOwner {

    // Cannot add the same asset twice
    require(!_assets[tokenAddress].isEnabled, "Qontroller: asset already exists");

    // `collateralFactor` must be between 0 and 1 (scaled to 1e8)
    require(
            collateralFactor <= _qAdmin.MAX_COLLATERAL_FACTOR(),
            "Qontroller: invalid collateral factor"
            );

    // `marketFactor` must be between 0 and 1 (scaled to 1e8)
    require(
            marketFactor <= _qAdmin.MAX_MARKET_FACTOR(),
            "Qontroller: invalid market factor"
            );

    // Initialize the `Asset` with the given parameters, and no enabled
    // maturities to begin with
    uint[] memory maturities;
    QTypes.Asset memory asset = QTypes.Asset(
                                             true,
                                             oracleFeed,
                                             collateralFactor,
                                             marketFactor,
                                             maturities
                                             );
    _assets[tokenAddress] = asset;

    // Emit the event
    emit AddAsset(tokenAddress, oracleFeed, collateralFactor, marketFactor);
  }

  /// @notice Update the `collateralFactor` for a given `Asset`
  /// @param tokenAddress Address of the token corresponding to the Asset
  /// @param collateralFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setCollateralFactor(
                                address tokenAddress,
                                uint collateralFactor
                                ) external onlyOwner {

    // Asset must already be enabled
    require(_assets[tokenAddress].isEnabled, "Qontroller: asset not enabled");

    // `collateralFactor` must be between 0 and 1 (scaled to 1e8)
    require(
            collateralFactor <= _qAdmin.MAX_COLLATERAL_FACTOR(),
            "Qontroller: invalid collateral factor"
            );

    // Look up the corresponding asset
    QTypes.Asset storage asset = _assets[tokenAddress];

    // Emit the event
    emit SetCollateralFactor(tokenAddress, asset.collateralFactor, collateralFactor);

    // Set `collateralFactor`
    asset.collateralFactor = collateralFactor;
  }

  /// @notice Update the `marketFactor` for a given `Asset`
  /// @param tokenAddress Address of the token corresponding to the Asset
  /// @param marketFactor 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _setMarketFactor(
                            address tokenAddress,
                            uint marketFactor
                            ) external onlyOwner {

    // Asset must already be enabled
    require(_assets[tokenAddress].isEnabled, "Qontroller: asset not enabled");

    // `marketFactor` must be between 0 and 1 (scaled to 1e8)
    require(
            marketFactor <= _qAdmin.MAX_MARKET_FACTOR(),
            "Qontroller: invalid asset factor"
            );

    // Look up the corresponding asset
    QTypes.Asset storage asset = _assets[tokenAddress];

    // Emit the event
    emit SetMarketFactor(tokenAddress, asset.marketFactor, marketFactor);
    
    // Set `marketFactor`
    asset.marketFactor = marketFactor;
  }

  function _addFixedRateMarket(address fixedRateMarketAddress) external onlyOwner {
    
    // Get athe values from the corresponding `FixedRateMarket` contract
    IFixedRateMarket market = IFixedRateMarket(fixedRateMarketAddress);
    uint maturity = market.maturity();
    address tokenAddress = market.tokenAddress();

    // Don't allow zero address
    require(tokenAddress != address(0), "Qontroller: invalid token address");

    // Only allow `Markets` where the corresponding `Asset` is enabled
    require(_assets[tokenAddress].isEnabled, "Qontroller: unsupported asset");

    // Check that this market hasn't already been instantiated before
    require(
            _fixedRateMarkets[tokenAddress][maturity] == address(0),
            "Qontroller: market already exists"
            );

    // Add the maturity as enabled to the corresponding Asset
    QTypes.Asset storage asset = _assets[tokenAddress];
    asset.maturities.push(maturity);
    
    // Add newly-created `FixedRateMarket` to the lookup list
    _fixedRateMarkets[tokenAddress][maturity] = fixedRateMarketAddress;

    // Enable newly-created `FixedRateMarket`
    _enabledMarkets[fixedRateMarketAddress] = true;

    // Emit the event
    emit CreateFixedRateMarket(
                               fixedRateMarketAddress,
                               tokenAddress,
                               maturity
                               );    
  }
  
  /** PUBLIC INTERFACE **/

  /// @notice Return the address of the current owner, stored in the `QAdmin` contract
  /// @return address Address of owner
  function owner() external view returns(address){
    return _qAdmin.owner();
  }

  
  /// @notice Get the address of the `QAdmin` contract
  function qAdmin() external view returns(address) {
    return address(_qAdmin);
  }

  /// @notice Get the address of the `QollateralManager` contract
  function qollateralManager() external view returns(address) {
    return address(_qollateralManager);
  }
  
  /// @notice Gets the `Asset` mapped to the address of a ERC20 token
  /// @param tokenAddress Address of ERC20 token
  /// @return QTypes.Asset Associated `Asset`
  function assets(address tokenAddress) external view returns(QTypes.Asset memory) {
    return _assets[tokenAddress];
  }

  /// @notice Gets the address of the `FixedRateMarket` contract
  /// @param tokenAddress Address of ERC20 token
  /// @param maturity UNIX timestamp of the maturity date
  /// @return address Address of `FixedRateMarket` contract
  function fixedRateMarkets(
                            address tokenAddress,
                            uint maturity
                            ) external view returns(address){
    return _fixedRateMarkets[tokenAddress][maturity];
  }

  /// @notice Check whether an address is a valid FixedRateMarket address.
  /// Can be used for checks for inter-contract admin/restricted function call.
  /// @param fixedRateMarketAddress Address of `FixedRateMarket` contract
  /// @return bool True if valid false otherwise
  function isMarketEnabled(address fixedRateMarketAddress) external view returns(bool){
    return _enabledMarkets[fixedRateMarketAddress];
  }  
  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}