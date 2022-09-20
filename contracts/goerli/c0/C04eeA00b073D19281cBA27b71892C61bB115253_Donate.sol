// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';

contract Donate is Ownable {
    /// Receipt addresses
    address[] private _receipts;
    /// Donation amount options
    uint256[] private _donationAmounts;
    /// Mapping from receipt address to exists flag
    mapping(address => bool) public isRegisteredReceipt;
    /// Mapping from donation amount to exists flag
    mapping(uint256 => bool) public isRegisteredAmount;

    /// @dev Emitted when a `donor` donates `amount` of ETH to `receipt`
    /// @param donor address of donor
    /// @param receipt address of receipt
    /// @param amount donation amount
    event Donation(address indexed donor, address indexed receipt, uint256 amount);

    /// @dev Emitted when the owner add `newReceipt` to `_receipts`
    /// @param newReceipt address of the new receipt
    event ReceiptAdded(address indexed newReceipt);

    /// @dev Emitted when the owner add `newDonationAmount` to `_donationAmounts`
    /// @param newDonationAmount donation amount
    event DonationAmountAdded(uint256 newDonationAmount);

    constructor(address _receipt, uint256 _donationAmount) {
        _receipts.push(_receipt);
        isRegisteredReceipt[_receipt] = true;
        _donationAmounts.push(_donationAmount);
        isRegisteredAmount[_donationAmount] = true;
    }

    /// @dev Donate ETH to receipt
    /// Requirements
    ///   - `msg.value` must be same as donation amount
    /// Emits a {Donation} event
    function donate(uint256 receiptOption, uint256 donateOption) external payable {
        require(receiptOption < _receipts.length, 'Donate: invalid receipt option');
        require(donateOption < _donationAmounts.length, 'Donate: invalid donate option');
        address donor = _msgSender();
        address receipt = payable(_receipts[receiptOption]);
        require(msg.value == _donationAmounts[donateOption], 'Donate: invalid donation amount');

        (bool sent, ) = receipt.call{value: msg.value}('');
        require(sent, 'Donate: failed to donate');

        emit Donation(donor, receipt, msg.value);
    }

    /// @dev Add a new receipt address
    /// @param newReceipt new receipt address
    /// Requirements
    ///   - `newReceipt` must be valid
    ///   - `newReceipt` must not be registered
    /// Emits a {ReceiptUpdated} event
    function addReceipt(address newReceipt) external onlyOwner {
        require(newReceipt != address(0), 'Donate: invalid receipt address');
        require(isRegisteredReceipt[newReceipt] == false, 'Donate: address is already registered');

        _receipts.push(newReceipt);
        isRegisteredReceipt[newReceipt] = true;

        emit ReceiptAdded(newReceipt);
    }

    /// @dev Add a new donation amount option
    /// @param newDonationAmount new donation amount
    /// Requirements
    ///   - `newDonationAmount` must be positive number
    ///   - `newDonationAmount` must not be registered
    /// Emits a {DonationAmountUpdated} event
    function addDonationAmount(uint256 newDonationAmount) external onlyOwner {
        require(newDonationAmount != 0, 'Donate: amount must not be zero');
        require(isRegisteredAmount[newDonationAmount] == false, 'Donate: amount is already registered');

        _donationAmounts.push(newDonationAmount);
        isRegisteredAmount[newDonationAmount] = true;

        emit DonationAmountAdded(newDonationAmount);
    }

    /// @notice Get all receipt addresses
    /// @dev Returns `_receipts`
    /// @return _receipts registered receipt addresses
    function getReceiptAddresses() external view returns (address[] memory) {
        return _receipts;
    }

    /// @notice Get all donation amounts
    /// @dev Returns `_donationAmounts`
    /// @return _donationAmounts registered donation amounts
    function getDonationAmounts() external view returns (uint256[] memory) {
        return _donationAmounts;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}