// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "Token.sol";
interface CompLike {
  function delegate(address delegatee) external;
}
contract ERC20 is Token,ERC20Interface {
    function initialize(address underlying_,
                        ComptrollerInterface comptroller_,
                        InterestRateModel interestRateModel_,
                        uint initialExchangeRateMantissa_,
                        string memory name_,
                        string memory symbol_,
                        uint8 decimals_) public {
        // CToken initialize does the bulk of the work
        super.initialize(comptroller_, interestRateModel_, initialExchangeRateMantissa_, name_, symbol_, decimals_);

        // Set underlying and sanity check it
        underlying = underlying_;
        EIP20Interface(underlying).totalSupply();
    }
    function mint(uint mintAmount) external override returns (uint) {
        (uint err,) = mintInternal(mintAmount);
        return err;
    }
    function redeem(uint redeemTokens) external override returns (uint) {
        return redeemInternal(redeemTokens);
    }
    function redeemUnderlying(uint redeemAmount) external override returns (uint) {
        return redeemUnderlyingInternal(redeemAmount);
    }
    function borrow(uint borrowAmount) external override returns (uint) {
        return borrowInternal(borrowAmount);
    }
    function repayBorrow(uint repayAmount) external override returns (uint) {
        (uint err,) = repayBorrowInternal(repayAmount);
        return err;
    }
    function repayBorrowBehalf(address borrower, uint repayAmount) external override returns (uint) {
        (uint err,) = repayBorrowBehalfInternal(borrower, repayAmount);
        return err;
    }
    function liquidateBorrow(address borrower, uint repayAmount, TokenInterface tokenCollateral) external override returns (uint) {
        (uint err,) = liquidateBorrowInternal(borrower, repayAmount, tokenCollateral);
        return err;
    }
    function sweepToken(EIP20NonStandardInterface token) external override {
    	require(address(token) != underlying, "ERC20::sweepToken: can not sweep underlying token");
    	uint256 balance = token.balanceOf(address(this));
    	token.transfer(admin, balance);
    }
    function _addReserves(uint addAmount) external override returns (uint) {
        return _addReservesInternal(addAmount);
    }
    function getCashPrior() internal view override returns (uint) {
        EIP20Interface token = EIP20Interface(underlying);
        return token.balanceOf(address(this));
    }
    function doTransferIn(address from, uint amount) internal override returns (uint) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        uint balanceBefore = EIP20Interface(underlying).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);
        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was *actually* transferred
        uint balanceAfter = EIP20Interface(underlying).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
    }
    function doTransferOut(address payable to, uint amount) internal override {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying);
        token.transfer(to, amount);
        bool success;
        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                     // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_OUT_FAILED");
    }
    function _delegateCompLikeTo(address compLikeDelegatee) external {
        require(msg.sender == admin, "only the admin may set the comp-like delegate");
        CompLike(underlying).delegate(compLikeDelegatee);
    }
}