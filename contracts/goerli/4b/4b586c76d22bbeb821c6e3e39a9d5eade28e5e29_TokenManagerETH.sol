/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
}
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)





/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)



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
interface IECREDS {
    function mint(address to, uint256 amount) external;

    function burn(address customer, uint256 amount) external;

    function transferFrom(
        address customer,
        address to,
        uint256 amount
    ) external;

    function transferOwnership(address newOwner) external;
}
interface IWETHCREDUT {
    function createCREDUT(address customer, uint256 amount) external;

    function subtractValueFromCREDUT(
        address customer,
        uint256 tokenId,
        uint256 amount
    ) external;

    function deleteCREDUT(address customer, uint256 tokenId)
        external
        returns (uint256 value);

    function transferFrom(
        address customer,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;
}

error CeilingReached();
error EmptySend();
error EmergencyNotActive();
error EmergencyActive();
error NoFeesToTransfer();
error FeeTooLow();
error FeeTooHigh();

contract TokenManagerETH is Ownable, Pausable, ReentrancyGuard {
    IECREDS public creds;
    IWETHCREDUT public credut;

    uint256 public globalDepositValue;
    uint256 public globalCeiling;
    uint256 public feePercentage = 5; //5% default
    uint256 public feeToTransfer;

    uint256 public emergencyStatus = 1; //inactive by default
    uint256 private immutable emergencyNotActive = 1;
    uint256 private immutable emergencyActive = 2;

    address payable public treasury;

    uint256 private constant MINIMUM_FEE_PERCENTAGE = 1;
    uint256 private constant MAXIMUM_FEE_PERCENTAGE = 10;

    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    event SubtractFromCredut(
        address indexed customer,
        uint256 tokenId,
        uint256 amount
    );

    constructor(
        IECREDS _creds,
        IWETHCREDUT _credut,
        address payable _treasury,
        uint256 _globalCeiling
    ) {
        creds = _creds;
        credut = _credut;
        treasury = _treasury;
        globalCeiling = _globalCeiling;
    }

    function deposit() public payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert EmptySend();
        if (globalDepositValue >= globalCeiling) revert CeilingReached();

        address customer = msg.sender;
        uint256 adjustedFee = _calculateFee(msg.value);
        feeToTransfer += adjustedFee;
        uint256 amount = msg.value - adjustedFee;
        globalDepositValue += amount;
        creds.mint(customer, amount);
        credut.createCREDUT(customer, amount);
        emit Deposit(customer, amount);
    }

    function partialWithdraw(uint256 tokenId, uint256 amount)
        public
        whenNotPaused
        nonReentrant
    {
        address customer = msg.sender;
        credut.subtractValueFromCREDUT(customer, tokenId, amount);
        creds.burn(customer, amount);
        globalDepositValue -= amount;
        (bool success, ) = payable(customer).call{value: amount}("");
        require(success, "Partial withdraw failed");
        emit SubtractFromCredut(customer, tokenId, amount);
    }

    function claimAllUnderlying(uint256 tokenId)
        public
        whenNotPaused
        nonReentrant
    {
        address customer = msg.sender;
        uint256 amount = credut.deleteCREDUT(customer, tokenId);
        globalDepositValue -= amount;
        creds.burn(customer, amount);
        (bool success, ) = payable(customer).call{value: amount}("");
        require(success, "Total Claim failed");
        emit Withdrawal(customer, amount);
    }

    receive() external payable {
        deposit();
    }

    function activateEmergency() public onlyOwner whenPaused {
        if (emergencyStatus == emergencyActive) revert EmergencyActive();
        emergencyStatus = emergencyActive;
    }

    function deactivateEmergency() public onlyOwner {
        if (emergencyStatus == emergencyNotActive) revert EmergencyNotActive();
        emergencyStatus = emergencyNotActive;
    }

    //same as claimAllUnderlying except customer doesnt need an equal number of creds
    function emergencyWithdraw(uint256 tokenId) public whenPaused nonReentrant {
        if (emergencyStatus == emergencyNotActive) revert EmergencyNotActive();

        address customer = msg.sender;
        uint256 amount = credut.deleteCREDUT(customer, tokenId);
        globalDepositValue -= amount;
        (bool success, ) = payable(customer).call{value: amount}("");
        require(success, "Emergency Withdraw Failed");
        emit Withdrawal(customer, amount);
    }

    function _calculateFee(uint256 msgValue) internal view returns (uint256) {
        uint256 adjustedMsgValue;
        if (feePercentage == 1) {
            adjustedMsgValue = msgValue / 100;
            return adjustedMsgValue;
        }
        adjustedMsgValue = (msgValue * feePercentage) / 100;
        return adjustedMsgValue;
    }

    function setTreasuryAddress(address payable _newTreasuryAddress)
        public
        onlyOwner
    {
        treasury = _newTreasuryAddress;
    }

    function sendToFeesTreasury() public onlyOwner {
        if (feeToTransfer == 0) revert NoFeesToTransfer();

        uint256 allFees = feeToTransfer;
        feeToTransfer -= allFees;
        (bool success, ) = treasury.call{value: allFees}("");
        require(success, "fee send failed");
    }

    function setFeePercentage(uint256 _feePercentage) public onlyOwner {
        if (_feePercentage < MINIMUM_FEE_PERCENTAGE) revert FeeTooLow();

        if (_feePercentage > MAXIMUM_FEE_PERCENTAGE) revert FeeTooHigh();

        feePercentage = _feePercentage;
    }

    function adjustCeiling(uint256 _amount) public onlyOwner {
        globalCeiling = _amount;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        if (emergencyStatus == emergencyActive) revert EmergencyActive();
        _unpause();
    }
}