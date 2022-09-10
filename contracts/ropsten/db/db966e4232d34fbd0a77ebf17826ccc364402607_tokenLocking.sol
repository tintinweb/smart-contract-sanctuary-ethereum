/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: Token Lock/TokenLocking.sol


pragma solidity ^0.8.4;



contract tokenLocking{

    IERC20 tokenAddress;

    uint256 private constant _Locked = 1;
    uint256 private constant _Redeem = 2;
    uint256 private _status;
    uint256 tokenRate = 10;
   
    constructor(IERC20 _tokenAddress){
        tokenAddress = _tokenAddress;
        _status = _Locked;
    }

    struct lock{
        uint256 lockId;
        uint256 lockTime;
        uint256 amount;
        uint256 endDate;
        uint256 status;
        address lockedBy;
    }

    mapping (address => mapping(uint256 => lock)) addressData;
    mapping (address => uint256) LockId;

    function setTokenRate(uint256 _rate) public {
        tokenRate = _rate;
    }

    function lockYourMoney(address _add, uint256 _tokenAmount, uint256 _endDate) public payable {
        require(_add != address(0), "lock to zero address not possible");
        require(_tokenAmount == msg.value, "Amount Mismatch");
        require(LockId[_add] == 0, "Already Subscribed");
        uint256 lockIdGenrate = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        LockId[_add] = lockIdGenrate;
        _status = _Locked;
        _endDate = block.timestamp + _endDate;
        addressData[_add][lockIdGenrate] = lock (
                    lockIdGenrate,
                    block.timestamp,
                    _tokenAmount,
                    _endDate,
                    _status,
                    _add);
    }


    function getLockIdsDetail(address _add) public view returns(
        uint256 lockId,
        uint256 lockTime,
        uint256 amount,
        uint256 endDate,
        uint256 status,
        address lockedBy){
        require(LockId[_add] != 0, "No LockIds found");
        uint256 id =LockId[_add];   
        lock memory p = addressData[_add][id];
        return(p.lockId, p.lockTime, p.amount, p.endDate, p.status, p.lockedBy);
    }

    function redeem(uint256 lockId)public {
        address _add = msg.sender;
        require(LockId[_add] == lockId, "LockId not Found");
        require(addressData[_add][lockId].status == 1, "Already Redeemed");
        require(addressData[_add][lockId].endDate <= block.timestamp, "Lock in Period not over so unable to redeem now");
        // require(addressData[_add][lockId].amount > 0, "Already Redeemed");
        tokenAddress.transfer(_add, addressData[_add][lockId].amount / tokenRate);
        addressData[_add][lockId].amount = 0;
        _status = _Redeem;
        addressData[_add][lockId].status = _status;
    }

    function getOnlyLockIds() public view returns(uint256){
        require(LockId[msg.sender] > 0, "LockId not Found");
        return LockId[msg.sender];
    }

    function contractBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function balanceOf(address _add) public view returns(uint256){
        return tokenAddress.balanceOf(_add);
    }
    
}