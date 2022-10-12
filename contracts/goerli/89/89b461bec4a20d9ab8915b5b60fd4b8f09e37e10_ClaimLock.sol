/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: MIT

/// @title QEVClaimLock
/// @author André Costa @ TQOE

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

contract IClaimLock {
    /**
     * @dev Allows a nft collection contract to send a new claim
     */
    function newClaim(uint256, address) external virtual {}
}

contract ClaimLock is IClaimLock, Ownable {

    struct QEVClaim {
        uint256 claimed;
        uint256 unclaimed;
        uint256 timeOfClaim;
        uint numberOfClaims;
    }

    //stores the info about each claim of QEV after a contribution per address
    mapping(address => QEVClaim) private QEVClaims;
    //the amount of time QEV is locked before it can be claimed
    uint256 public claimTimeLock = 259200; //3 days

    //storing the addresses of the smart contracts approved for creating new claims
    mapping(address => bool) private approved;

    /// $QEV Token
    IERC20 public QEV;
    /// Platform Treasury
    address public platformTreasury;

    constructor() {
        approved[0x764c631C787199A5E7A94aC21c81265E8e4d7909] = true; //The Oracles Verse
    }

    //
    // MODIFIERS
    //

    /**
     * Ensure that the address that is calling is approved
     */
    modifier onlyApproved(address approvedAddress) {
        require(isApproved(approvedAddress), "Invalid state");
        _;
    }

    //
    // SETTERS
    //

     /**
     * Set new time for claim lock
     * @param newTime The new time that the QEV will be locked after contribution
     */
    function setClaimTimeLock(uint256 newTime) external onlyOwner {
        claimTimeLock = newTime;
    }

    /**
     * Set QEV token Contract
     * @param newAddress The new address for the QEV token
     */
    function setQEV(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Cannot be the 0 address!");
        QEV = IERC20(newAddress);
    }

    /**
     * Set Platform Treasurt Address
     * @param newAddress The new address for the QEV token
     */
    function setPlatformTreasury(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Cannot be the 0 address!");
        platformTreasury = newAddress;
    }

    /**
     * Adding a new address to the list of approved
     * @param newAddress address to be added
     */
    function addToApproved(address newAddress) external onlyOwner {
        require(newAddress != address(0) && !approved[newAddress], "Invalid Address");
        approved[newAddress] = true;
    }

    /**
     * Removing a deprecated address from the list of approved
     * @param deprecatedAddress address to be removed
     */
    function removeFromApproved(address deprecatedAddress) external onlyOwner {
        require(deprecatedAddress != address(0) && approved[deprecatedAddress], "Invalid Address");
        approved[deprecatedAddress] = false;
    }

    //
    // GETTERS
    //

    /**
     * Checks if an address is approved
     * @param approvedAddress the address to be checked
     */
    function isApproved(address approvedAddress) public view returns(bool){
        return approved[approvedAddress];
    }

    //
    // QEV LOCK & CLAIM
    //

    /**
     * @dev Allows a nft collection contract to send a new claim
     */
    function newClaim(uint256 amount, address contributor) external override onlyApproved(msg.sender) {
        QEVClaims[contributor].unclaimed += amount;
        QEVClaims[contributor].timeOfClaim += block.timestamp + claimTimeLock;
    }

    /**
     * @dev Allows a user to claim their available QEV tokens
     */
    function claim() external {
        uint256 claimableQEV = getClaimableQEV(msg.sender);
        require(claimableQEV > 0, "No QEV to be claimed!");

        QEVClaims[msg.sender].claimed += claimableQEV;
        QEVClaims[msg.sender].unclaimed = 0;
        QEVClaims[msg.sender].numberOfClaims++;

        QEV.transferFrom(platformTreasury, msg.sender, claimableQEV);
    }

    /**
     * @dev Gets the information related to the claims by a specific address
     */
    function getClaimedInfo(address claimer) public view returns(QEVClaim memory) {
        return QEVClaims[claimer];
    }

    /**
     * @dev Gets the information related to the claims by a specific address
     */
    function getClaimableQEV(address claimer) public view returns(uint256) {
        if (block.timestamp >= QEVClaims[claimer].timeOfClaim) {
            return QEVClaims[claimer].unclaimed;
        }
        else {
            return 0;
        }
    }

}