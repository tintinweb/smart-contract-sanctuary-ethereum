// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./WithdrawalAddress.sol";
import "./Errors.sol";

contract RoyaltiesSplit {
    // Addresses where money from the contract will go if the owner of the contract will call withdraw function
    WithdrawalAddress[] public withdrawalAddresses;

    constructor(WithdrawalAddress[] memory _withdrawalAddresses) {
        uint256 length = _withdrawalAddresses.length;
        if (length == 0) revert Errors.WithdrawalPercentageWrongSize();

        uint256 sum;
        for (uint256 i; i < length; ) {
            uint256 percentage = _withdrawalAddresses[i].percentage;
            if (percentage == 0) revert Errors.WithdrawalPercentageZero();
            sum += percentage;
            withdrawalAddresses.push(_withdrawalAddresses[i]);
            unchecked {
                ++i;
            }
        }
        if (sum != 100) revert Errors.WithdrawalPercentageNot100();
    }

    // Contract owner can call this function to withdraw all money from the contract into a defined wallet
    function withdrawAll() external {
        uint256 balance = address(this).balance;
        if (balance == 0) revert Errors.NothingToWithdraw();

        uint256 length = withdrawalAddresses.length;
        for (uint256 i; i < length; ) {
            uint256 percentage = withdrawalAddresses[i].percentage;
            address withdrawalAddress = withdrawalAddresses[i].account;
            uint256 value = (balance * percentage) / 100;

            (withdrawalAddress.call{ value: value }(""));

            unchecked {
                ++i;
            }
        }

        balance = address(this).balance;
        if (balance > 0) {
            (withdrawalAddresses[0].account.call{ value: balance }(""));
        }
    }

    receive() external payable {}

    fallback() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Errors {
    error WithdrawalPercentageWrongSize();
    error WithdrawalPercentageNot100();
    error WithdrawalPercentageZero();
    error MintNotAvailable();
    error InsufficientFunds();
    error SupplyLimitReached();
    error ContractCantMint();
    error InvalidSignature();
    error AccountAlreadyMintedMax();
    error TokenDoesNotExist();
    error NotOwner();
    error NotAuthorized();
    error MaxSupplyTooSmall();
    error CanNotIncreaseMaxSupply();
    error InvalidOwner();
    error TokenNotTransferable();

    error RoyaltiesPercentageTooHigh();
    error NothingToWithdraw();
    error WithdrawFailed();

    /* ReentrancyGuard.sol */
    error ContractLocked();

    /* Signable.sol */
    error NewSignerCantBeZero();

    /* StableMultiMintERC721.sol */
    error PaymentTypeNotEnabled();

    /* AgoriaXLedger.sol */
    error WrongInputSize();
    error IdBeyondSupplyLimit();
    error InvalidBaseContractURL();
    error InvalidBaseURI();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

struct WithdrawalAddress {
    address account;
    uint96 percentage;
}