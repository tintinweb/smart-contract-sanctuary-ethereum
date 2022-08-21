// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LoanOracle is Ownable {

    /// @notice the loan common address
    address loanCommonAddress;

    /// @notice get loan common
    function getLoanCommonAddress() public view returns (address) {
        require (loanCommonAddress != address(0x0), "loan common must be set");
        return loanCommonAddress;
    }

    /// @notice set the loan common address
    /// @param _address The new address
    function setLoanCommonAddress(address _address) public onlyOwner {
        loanCommonAddress = _address;
    }

    /// @notice the loan service address
    address loanServiceAddress;

    /// @notice get loan service
    function getLoanServiceAddress() public view returns (address) {
        require (loanServiceAddress != address(0x0), "loan service must be set");
        return loanServiceAddress;
    }

    /// @notice set the loan service address
    /// @param _address The new address
    function setLoanServiceAddress(address _address) public onlyOwner {
        loanServiceAddress = _address;
    }

    /// @notice the loan service bid address
    address loanServiceBidAddress;

    /// @notice get loan service bid
    function getLoanServiceBidAddress() public view returns (address) {
        require (loanServiceBidAddress != address(0x0), "loan service bid must be set");
        return loanServiceBidAddress;
    }

    /// @notice set the loan service bid address
    /// @param _address The new address
    function setLoanServiceBidAddress(address _address) public onlyOwner {
        loanServiceBidAddress = _address;
    }

    /// @notice the loan service nft collateral address
    address loanServiceNftCollateralAddress;

    /// @notice get loan service nft collateral
    function getLoanServiceNftCollateralAddress() public view returns (address) {
        require (loanServiceNftCollateralAddress != address(0x0), "loan service nft collateral must be set");
        return loanServiceNftCollateralAddress;
    }

    /// @notice set the loan service nft collateral address
    /// @param _address The new address
    function setLoanServiceNftCollateralAddress(address _address) public onlyOwner {
        loanServiceNftCollateralAddress = _address;
    }

    /// @notice the loan service offer address
    address loanServiceOfferAddress;

    /// @notice get loan service offer
    function getLoanServiceOfferAddress() public view returns (address) {
        require (loanServiceOfferAddress != address(0x0), "loan service offer must be set");
        return loanServiceOfferAddress;
    }

    /// @notice set the loan service offer address
    /// @param _address The new address
    function setLoanServiceOfferAddress(address _address) public onlyOwner {
        loanServiceOfferAddress = _address;
    }

    /// @notice the loan service payment address
    address loanServicePaymentAddress;

    /// @notice get loan service payment
    function getLoanServicePaymentAddress() public view returns (address) {
        require (loanServicePaymentAddress != address(0x0), "loan service payment must be set");
        return loanServicePaymentAddress;
    }

    /// @notice set the loan service payment address
    /// @param _address The new address
    function setLoanServicePaymentAddress(address _address) public onlyOwner {
        loanServicePaymentAddress = _address;
    }

    /// @notice the loan service treasury address
    address loanServiceTreasuryAddress;

    /// @notice get loan service treasury
    function getLoanServiceTreasuryAddress() public view returns (address) {
        require (loanServiceTreasuryAddress != address(0x0), "loan service treasury must be set");
        return loanServiceTreasuryAddress;
    }

    /// @notice set the loan service treasury address
    /// @param _address The new address
    function setLoanServiceTreasuryAddress(address _address) public onlyOwner {
        loanServiceTreasuryAddress = _address;
    }

    /// @notice the loan storage address
    address loanStorageAddress;

    /// @notice get loan storage
    function getLoanStorageAddress() public view returns (address) {
        require (loanStorageAddress != address(0x0), "loan storage must be set");
        return loanStorageAddress;
    }

    /// @notice set the loan storage address
    /// @param _address The new address
    function setLoanStorageAddress(address _address) public onlyOwner {
        loanStorageAddress = _address;
    }

    /// @notice the loan storage bid address
    address loanStorageBidAddress;

    /// @notice get loan storage bid
    function getLoanStorageBidAddress() public view returns (address) {
        require (loanStorageBidAddress != address(0x0), "loan storage bid must be set");
        return loanStorageBidAddress;
    }

    /// @notice set the loan storage bid address
    /// @param _address The new address
    function setLoanStorageBidAddress(address _address) public onlyOwner {
        loanStorageBidAddress = _address;
    }

    /// @notice the loan storage nft collateral address
    address loanStorageNftCollateralAddress;

    /// @notice get loan storage nft collateral
    function getLoanStorageNftCollateralAddress() public view returns (address) {
        require (loanStorageNftCollateralAddress != address(0x0), "loan storage nft collateral must be set");
        return loanStorageNftCollateralAddress;
    }

    /// @notice set the loan storage nft collateral address
    /// @param _address The new address
    function setLoanStorageNftCollateralAddress(address _address) public onlyOwner {
        loanStorageNftCollateralAddress = _address;
    }

    /// @notice the loan storage offer address
    address loanStorageOfferAddress;

    /// @notice get loan storage offer
    function getLoanStorageOfferAddress() public view returns (address) {
        require (loanStorageOfferAddress != address(0x0), "loan storage offer must be set");
        return loanStorageOfferAddress;
    }

    /// @notice set the loan storage offer address
    /// @param _address The new address
    function setLoanStorageOfferAddress(address _address) public onlyOwner {
        loanStorageOfferAddress = _address;
    }

    /// @notice the loan storage payment address
    address loanStoragePaymentAddress;

    /// @notice get loan storage payment
    function getLoanStoragePaymentAddress() public view returns (address) {
        require (loanStoragePaymentAddress != address(0x0), "loan storage payment must be set");
        return loanStoragePaymentAddress;
    }

    /// @notice set the loan storage payment address
    /// @param _address The new address
    function setLoanStoragePaymentAddress(address _address) public onlyOwner {
        loanStoragePaymentAddress = _address;
    }

    /// @notice the loan storage treasury address
    address payable loanStorageTreasuryAddress;

    /// @notice get loan storage treasury
    function getLoanStorageTreasuryAddress() public view returns (address payable) {
        require (loanStorageTreasuryAddress != address(0x0), "loan storage treasury must be set");
        return loanStorageTreasuryAddress;
    }

    /// @notice set the loan storage treasury address
    /// @param _address The new address
    function setLoanStorageTreasuryAddress(address payable _address) public onlyOwner {
        loanStorageTreasuryAddress = _address;
    }

    /// @notice the loan parameters address
    address loanParametersAddress;

    /// @notice get loan parameters
    function getLoanParametersAddress() public view returns (address) {
        require (loanParametersAddress != address(0x0), "loan parameters must be set");
        return loanParametersAddress;
    }

    /// @notice set the loan parameters address
    /// @param _address The new address
    function setLoanParametersAddress(address _address) public onlyOwner {
        loanParametersAddress = _address;
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