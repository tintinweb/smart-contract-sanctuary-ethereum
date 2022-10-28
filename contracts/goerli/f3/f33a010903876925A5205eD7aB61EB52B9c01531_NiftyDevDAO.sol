// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./utils/ReentrancyGuard.sol";
import "./utils/NiftyDevPermissions.sol";

contract NiftyDevDAO is ReentrancyGuard, NiftyTeamBankPermissions { 
    
    event EthReceived(address depositee, uint256 amount);
    event RecipientSet(address recipient);
    event WithdrawLimitUpdate(uint256 amount);
    event EthWithdrawn(address recipient, uint256 amount);

    uint256 public maxWithdrawLimit = uint256(8);
    bool isPaused = false;

    function pauseWallet() external {
        _requireOnlyValidNiftyDevAddresses();
        require (isPaused == false, "Wallet already paused.");
        isPaused = true;
    }

    function resumeWallet() external {
        _requireOnlyValidNiftyDevAddresses();
        require (isPaused, "Wallet already unpaused.");

        isPaused = false;
    }

    function getMaxWithdrawLimit() external view returns (uint256) {
        return maxWithdrawLimit;
    }

    function setWithdrawLimit(uint8 newWithdrawalLimit_) external {
        _requireOnlyValidNiftyDevAddresses();

        maxWithdrawLimit = newWithdrawalLimit_;
        emit WithdrawLimitUpdate(newWithdrawalLimit_);
    }

    function getBankBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawETH(uint256 amount) external nonReentrant {
        _requireOnlyValidNiftyDevAddresses();
        require (isPaused == false, "Wallet is Paused.");
        require(amount > 0, ERROR_ZERO_ETH_TRANSFER);
        require(amount < maxWithdrawLimit, "Request Amount is over the current withdraw size");
        require(msg.sender != address(0), "Transfer to zero address");

        uint256 currentBalance = address(this).balance;
        require(amount <= currentBalance, ERROR_INSUFFICIENT_BALANCE);

        //slither-disable-next-line arbitrary-send        
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, ERROR_WITHDRAW_UNSUCCESSFUL);
        emit EthWithdrawn(msg.sender, amount);
    }

    // For this contract we would want developers
    // to deposit used testEth back into the bank
    // or allow for funds to be topped off.
    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    } 

    fallback() external payable {
        emit EthReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.8.9;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./GenericErrors.sol";

contract NiftyTeamBankPermissions is Ownable, GenericErrors {
    mapping (address => bool) public validRecipients;
    mapping (address => bool) public nominatedRecipients;

    uint public recipientCount = uint(0);

    event addressNominated(address nominator, address nominee);
    event nominationChange(address nominee, bool accepted);
    event recipientDeleted(address recipient);

    function setRecipients(address recipient_) public {
        require(recipientCount == 0, "Only callable on first recipient.");
        validRecipients[recipient_] = true;
        recipientCount++;
        
        emit nominationChange(recipient_, true);
    }

    function nominateRecipient(address recipient_) public {
        _requireOnlyValidNiftyDevAddresses();

        require(contains(recipient_) == false, "Nominee is already a Valid Nifty Team Member.");
        nominatedRecipients[recipient_] = true;
        
        emit addressNominated(msg.sender, recipient_);
    }

    function isNomineeStatus(address nominee) public view returns (bool) {
        return(nominatedRecipients[nominee]);
    }

    function acceptNomination() public {
        require(contains(msg.sender) == false, "Address is already a Valid Nifty Team Member.");
        require(nominatedRecipients[msg.sender], "Address is not currently nominated.");

        nominatedRecipients[msg.sender] = false;
        validRecipients[msg.sender] = true;
        recipientCount++;
        emit nominationChange(msg.sender, true);
    }

    function rejectNomination() public {
        require(nominatedRecipients[msg.sender], "Address is not currently nominated.");

        nominatedRecipients[msg.sender] = false;
        emit nominationChange(msg.sender, false);
    }

    function deleteNomination(address nominatedAddress) public {
        _requireOnlyValidNiftyDevAddresses();
        nominatedRecipients[nominatedAddress] = false;

        emit nominationChange(nominatedAddress, false);
    }

    function deleteRecipient(address recipientToDelete) public {
        _requireOnlyValidNiftyDevAddresses();

        validRecipients[recipientToDelete] = false;
        recipientCount--;
        emit recipientDeleted(recipientToDelete);
    }

    function isPermissionedRecipient(address recipient_) view public returns (bool) {
        return(contains(recipient_));
    }

    function contains(address recipient_) view internal returns (bool) {
        return validRecipients[recipient_];
    }

    function _requireOnlyValidNiftyDevAddresses() view internal {
        require(contains(msg.sender), "Sender is not a Valid Nifty Team Member");
    }


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


abstract contract Ownable {        
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);        

    function owner() public view virtual returns (address) {
        return _owner;
    }
        
    function transferOwnership(address newOwner) public virtual {               
        address oldOwner = _owner;        
        _owner = newOwner;        
        emit OwnershipTransferred(oldOwner, newOwner);        
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract GenericErrors {
    string internal constant ERROR_INPUT_ARRAY_EMPTY = "Input array empty";
    string internal constant ERROR_INPUT_ARRAY_SIZE_MISMATCH = "Input array size mismatch";
    string internal constant ERROR_INVALID_MSG_SENDER = "Invalid msg.sender";
    string internal constant ERROR_UNEXPECTED_DATA_SIGNER = "Unexpected data signer";
    string internal constant ERROR_INSUFFICIENT_BALANCE = "Insufficient balance";
    string internal constant ERROR_WITHDRAW_UNSUCCESSFUL = "Withdraw unsuccessful";
    string internal constant ERROR_CONTRACT_IS_FINALIZED = "Contract is finalized";
    string internal constant ERROR_CANNOT_CHANGE_DEFAULT_OWNER = "Cannot change default owner";
    string internal constant ERROR_UNCLONEABLE_REFERENCE_CONTRACT = "Uncloneable reference contract";
    string internal constant ERROR_BIPS_OVER_100_PERCENT = "Bips over 100%";
    string internal constant ERROR_NO_ROYALTY_RECEIVER = "No royalty receiver";
    string internal constant ERROR_REINITIALIZATION_NOT_PERMITTED = "Re-initialization not permitted";
    string internal constant ERROR_ZERO_ETH_TRANSFER = "Zero ETH Transfer";
}