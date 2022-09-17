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

    /// @notice the loan service address
    address loanServiceExtensionAddress;

    /// @notice get loan service
    function getLoanServiceExtensionAddress() public view returns (address) {
        require (loanServiceExtensionAddress != address(0x0), "loan service extension must be set");
        return loanServiceExtensionAddress;
    }

    /// @notice set the loan service address
    /// @param _address The new address
    function setLoanServiceExtensionAddress(address _address) public onlyOwner {
        loanServiceExtensionAddress = _address;
    }

    /// @notice the loan service bid address
    address loanBidServiceAddress;

    /// @notice get loan service bid
    function getLoanBidServiceAddress() public view returns (address) {
        require (loanBidServiceAddress != address(0x0), "loan service bid must be set");
        return loanBidServiceAddress;
    }

    /// @notice set the loan bid service address
    /// @param _address The new address
    function setLoanBidServiceAddress(address _address) public onlyOwner {
        loanBidServiceAddress = _address;
    }

    /// @notice the loan service nft collateral address
    address loanNftCollateralServiceAddress;

    /// @notice get loan service nft collateral
    function getLoanNftCollateralServiceAddress() public view returns (address) {
        require (loanNftCollateralServiceAddress != address(0x0), "loan service nft collateral must be set");
        return loanNftCollateralServiceAddress;
    }

    /// @notice set the loan service nft collateral address
    /// @param _address The new address
    function setLoanNftCollateralServiceAddress(address _address) public onlyOwner {
        loanNftCollateralServiceAddress = _address;
    }

    /// @notice the loan service offer address
    address loanOfferServiceAddress;

    /// @notice get loan service offer
    function getLoanOfferServiceAddress() public view returns (address) {
        require (loanOfferServiceAddress != address(0x0), "loan service offer must be set");
        return loanOfferServiceAddress;
    }

    /// @notice set the loan service offer address
    /// @param _address The new address
    function setLoanOfferServiceAddress(address _address) public onlyOwner {
        loanOfferServiceAddress = _address;
    }

    /// @notice the loan service payment address
    address loanPaymentServiceAddress;

    /// @notice get loan service payment
    function getLoanPaymentServiceAddress() public view returns (address) {
        require (loanPaymentServiceAddress != address(0x0), "loan payment service must be set");
        return loanPaymentServiceAddress;
    }

    /// @notice set the loan service payment address
    /// @param _address The new address
    function setLoanPaymentServiceAddress(address _address) public onlyOwner {
        loanPaymentServiceAddress = _address;
    }

    /// @notice the loan service treasury address
    address loanTreasuryServiceAddress;

    /// @notice get loan service treasury
    function getLoanTreasuryServiceAddress() public view returns (address) {
        require (loanTreasuryServiceAddress != address(0x0), "loan treasury service must be set");
        return loanTreasuryServiceAddress;
    }

    /// @notice set the loan service treasury address
    /// @param _address The new address
    function setLoanTreasuryServiceAddress(address _address) public onlyOwner {
        loanTreasuryServiceAddress = _address;
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

    /// @notice the loan bid storage address
    address loanBidStorageAddress;

    /// @notice get loan bid storage
    function getLoanBidStorageAddress() public view returns (address) {
        require (loanBidStorageAddress != address(0x0), "loan bid storage must be set");
        return loanBidStorageAddress;
    }

    /// @notice set the loan bid storage address
    /// @param _address The new address
    function setLoanBidStorageAddress(address _address) public onlyOwner {
        loanBidStorageAddress = _address;
    }

    /// @notice the loan storage nft collateral address
    address loanNftCollateralStorageAddress;

    /// @notice get loan storage nft collateral
    function getLoanNftCollateralStorageAddress() public view returns (address) {
        require (loanNftCollateralStorageAddress != address(0x0), "loan storage nft collateral must be set");
        return loanNftCollateralStorageAddress;
    }

    /// @notice set the loan storage nft collateral address
    /// @param _address The new address
    function setLoanNftCollateralStorageAddress(address _address) public onlyOwner {
        loanNftCollateralStorageAddress = _address;
    }

    /// @notice the loan storage offer address
    address loanOfferStorageAddress;

    /// @notice get loan storage offer
    function getLoanOfferStorageAddress() public view returns (address) {
        require (loanOfferStorageAddress != address(0x0), "loan storage offer must be set");
        return loanOfferStorageAddress;
    }

    /// @notice set the loan storage offer address
    /// @param _address The new address
    function setLoanOfferStorageAddress(address _address) public onlyOwner {
        loanOfferStorageAddress = _address;
    }

    /// @notice the loan storage payment address
    address loanPaymentStorageAddress;

    /// @notice get loan storage payment
    function getLoanPaymentStorageAddress() public view returns (address) {
        require (loanPaymentStorageAddress != address(0x0), "loan storage payment must be set");
        return loanPaymentStorageAddress;
    }

    /// @notice set the loan storage payment address
    /// @param _address The new address
    function setLoanPaymentStorageAddress(address _address) public onlyOwner {
        loanPaymentStorageAddress = _address;
    }

    /// @notice the loan storage treasury address
    address payable loanTreasuryStorageAddress;

    /// @notice get loan storage treasury
    function getLoanTreasuryStorageAddress() public view returns (address payable) {
        require (loanTreasuryStorageAddress != address(0x0), "loan storage treasury must be set");
        return loanTreasuryStorageAddress;
    }

    /// @notice set the loan storage treasury address
    /// @param _address The new address
    function setLoanTreasuryStorageAddress(address payable _address) public onlyOwner {
        loanTreasuryStorageAddress = _address;
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

    /// @notice the loan collection offer address
    address loanCollectionOfferStorageAddress;

    /// @notice get loan collection offer address
    function getLoanCollectionOfferStorageAddress() public view returns (address) {
        require (loanCollectionOfferStorageAddress != address(0x0), "loan collection offer storage address must be set");
        return loanCollectionOfferStorageAddress;
    }

    /// @notice set the loan collection offer address
    /// @param _address The new address
    function setLoanCollectionOfferStorageAddress(address _address) public onlyOwner {
        loanCollectionOfferStorageAddress = _address;
    }

    /// @notice the loan collection offer address
    address loanCollectionOfferServiceAddress;

    /// @notice get loan collection offer address
    function getLoanCollectionOfferServiceAddress() public view returns (address) {
        require (loanCollectionOfferServiceAddress != address(0x0), "loan collection offer service address must be set");
        return loanCollectionOfferServiceAddress;
    }

    /// @notice set the loan collection offer address
    /// @param _address The new address
    function setLoanCollectionOfferServiceAddress(address _address) public onlyOwner {
        loanCollectionOfferServiceAddress = _address;
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