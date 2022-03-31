// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./eToken.sol";
contract Ether is Token {
    constructor(ComptrollerInterface comptroller_,
                uint initialExchangeRateMantissa_,
                address payable admin_) public {
        // Creator of the contract is admin during initialization
        admin = msg.sender;
        initialize(comptroller_, initialExchangeRateMantissa_);
        // Set the proper admin now that initialization is done
        admin = admin_;
    }
    // User Interface 
    function _mint() external payable {
        (uint err,) = mintInternal(msg.value);
        requireNoError(err, "mint failed");
    }
    function redeem(uint redeemTokens) external returns (uint) {
        return redeemInternal(redeemTokens);
    }
    function redeemUnderlying(uint redeemAmount) external returns (uint) {
        return redeemUnderlyingInternal(redeemAmount);
    }
    function borrow(uint borrowAmount) external returns (uint) {
        return borrowInternal(borrowAmount);
    }
    function repayBorrow() external payable {
        (uint err,) = repayBorrowInternal(msg.value);
        requireNoError(err, "repayBorrow failed");
    }
    function repayBorrowBehalf(address borrower) external payable {
        (uint err,) = repayBorrowBehalfInternal(borrower, msg.value);
        requireNoError(err, "repayBorrowBehalf failed");
    }
    function liquidateBorrow(address borrower, Token TokenCollateral) external payable {
        (uint err,) = liquidateBorrowInternal(borrower, msg.value, TokenCollateral);
        requireNoError(err, "liquidateBorrow failed");
    }
    function _addReserves() external payable returns (uint) {
        return _addReservesInternal(msg.value);
    }
    function mint () external payable {
        (uint err,) = mintInternal(msg.value);
        requireNoError(err, "mint failed");
    }
    //Safe Token 
    function getCashPrior() internal view override returns (uint) {
        (MathError err, uint startingBalance) = subUInt(address(this).balance, msg.value);
        require(err == MathError.NO_ERROR);
        return startingBalance;
    }
    function doTransferIn(address from, uint amount) internal override returns (uint) {
        // Sanity checks
        require(msg.sender == from, "sender mismatch");
        require(msg.value == amount, "value mismatch");
        return amount;
    }
    function doTransferOut(address payable to, uint amount) internal override {
        /* Send the Ether, with minimal gas and revert on failure */
        to.transfer(amount);
    }
    function requireNoError(uint errCode, string memory message) internal pure {
        if (errCode == uint(Error.NO_ERROR)) {
            return;
        }
        bytes memory fullMessage = new bytes(bytes(message).length + 5);
        uint i;
        for (i = 0; i < bytes(message).length; i++) {
            fullMessage[i] = bytes(message)[i];
        }
        fullMessage[i+0] = byte(uint8(32));
        fullMessage[i+1] = byte(uint8(40));
        fullMessage[i+2] = byte(uint8(48 + ( errCode / 10 )));
        fullMessage[i+3] = byte(uint8(48 + ( errCode % 10 )));
        fullMessage[i+4] = byte(uint8(41));
        require(errCode == uint(Error.NO_ERROR), string(fullMessage));
    }
}