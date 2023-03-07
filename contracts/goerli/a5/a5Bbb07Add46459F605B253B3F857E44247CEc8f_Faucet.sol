/**
 *Submitted for verification at Etherscan.io on 2023-03-07
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

// File: Faucet.sol


pragma solidity ^0.8.18;


// Generic ERC-20 interface
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// Generic ERC20 faucet that drips designated tokens over a period of time
contract Faucet is Ownable {
    
    // Sample values for faucet parameters
    uint256 constant private decimals = 18;
    uint256 public tokenAmount = 25 * 10 ** decimals ;
    uint256 public waitTime = 10 minutes;

    IERC20 public tokenInstance;
    
    mapping(address => uint256) lastAccessTime;

    // Set token address, wait time and amount for each faucet drip
    constructor(address _tokenInstance, uint256 _tokenAmount, uint256 _waitTime) {
        require(_tokenInstance != address(0));
        tokenInstance = IERC20(_tokenInstance);

        tokenAmount = _tokenAmount;
        waitTime = _waitTime;
    }

    // Sets the faucet token amount
    function setTokenAmount(uint256 _tokenAmount) external onlyOwner {
        tokenAmount = _tokenAmount;
    }

    // Sets the faucet drip duration
    function setWaitTime(uint256 _waitTime) external onlyOwner {
        waitTime = _waitTime;
    }

    // Returns token amount to callers after wait time
    function requestTokens() external {
        require(msg.sender == tx.origin);
        require(allowedToWithdraw(msg.sender));
        lastAccessTime[msg.sender] = block.timestamp + waitTime;
        tokenInstance.transfer(msg.sender, tokenAmount);
    }

    // Determines if user can withdraw the designated token amount
    function allowedToWithdraw(address _address) public view returns (bool) {
        if(lastAccessTime[_address] == 0) {
            return true;
        } else if(block.timestamp >= lastAccessTime[_address]) {
            return true;
        }
        return false;
    }

    // Used by the owner to retract funds
    function withdraw(uint256 amount) external onlyOwner {
        require(this.getWithdrawableAmount() >= amount, "Not enough withdrawable funds");
        tokenInstance.transfer(owner(), amount);
    }

    // Returns the number of freely available tokens
    function getWithdrawableAmount() public view returns(uint256){
        return tokenInstance.balanceOf(address(this));
    }

    // Time for the next token release. 0 if tokens are immediately available
    function withdrawTime(address _address) public view returns (uint256) {
        if ((lastAccessTime[_address] == 0) || (block.timestamp >= lastAccessTime[_address])) {
            return 0;
        } else {
            return lastAccessTime[_address];
        }
    }
}