/**
 *Submitted for verification at Etherscan.io on 2022-06-20
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: YFDAI2_Locking.sol


pragma solidity >=0.8.0;


interface Token {
    function transferFrom(address, address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function balanceOf(address _owner) external returns (uint256);
}

/* @dev
    Contract used for locking X YFDAI2 tokens for Y (daysFirstWithdraw) days,
    then will be able to unlock them in batches of X / 12
    tokens each Z (daysBetweenWithdraws) days.
*/
contract YFDAI2_Locker is Ownable {
    // ERC20 token (YFDAI2) contract address
    address public constant tokenAddress = 0x0C72C6fa50422aeA10B49e12Fe460103d0fa9c3e;
    
    uint public timeDeposited;
    uint public totalDeposited;
    uint public totalWithdrawn;
    uint public daysFirstWithdraw = 180 days;
    uint public daysBetweenWithdraws = 30 days;
    uint public totalWithdraws = 12;

    function lock(uint _amount) public onlyOwner returns(bool){
        require(Token(tokenAddress).transferFrom(msg.sender, address(this), _amount) , "Error depositing tokens");
        require(totalDeposited == 0 , "Already locked tokens");
        totalDeposited = _amount;
        timeDeposited = block.timestamp;
        return true;
    }

    function unLock() public onlyOwner returns(bool){
        uint _amount = getUnlockableAmount();
        totalWithdrawn = totalWithdrawn + _amount;
        require(_amount > 0 , "Nothing to unlock");
        uint inContract = Token(tokenAddress).balanceOf(address(this));
        if(inContract < _amount) _amount = inContract;
        require(Token(tokenAddress).transfer(owner(), _amount) , "Error sending tokens");
        return true;
    }

    function getUnlockableAmount() public view returns(uint){
        require(block.timestamp - timeDeposited >= daysFirstWithdraw, "Wait till the first withdraw");
        uint numWithdraws = getNumPeriods();
        uint amountWithdrawable = getTotalAmountWithdrawable(numWithdraws);
        uint _toSend = getAmountToSend(amountWithdrawable);
        return _toSend;
    }
    
    function getNumPeriods() public view returns(uint){
        return (block.timestamp - timeDeposited - daysFirstWithdraw) / daysBetweenWithdraws + 1;
    }

    function getAmountPerPeriod() public view returns(uint){
        return totalDeposited / totalWithdraws;
    }

    function getTotalAmountWithdrawable(uint _numWithdraws) public view returns(uint){
        return _numWithdraws * getAmountPerPeriod();
    }

    function getAmountToSend(uint _amountWithdrawable) public view returns(uint){
        return _amountWithdrawable - totalWithdrawn;
    }
}