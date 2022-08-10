/**
 *Submitted for verification at Etherscan.io on 2022-08-10
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

// File: stakingARTR.sol


pragma solidity ^0.8.9;



contract StakingARTR {
    IERC20 public ARTR;
    address public owner;

    mapping (address => uint) holder_Amount;
    mapping (address => uint) holder_Duration;
    mapping (address => uint) holder_Percents;
    mapping (address => uint) holder_Tier;
    mapping (address => uint) holder_CF;
    mapping (address => uint) holder_Finish;
    mapping (address => uint) holder_Earned;

    mapping (address => uint) holders;

    mapping (uint => uint) percents;
    mapping (uint => uint) cf;

    uint totalStaked;

    event Staked(address indexed holderAddress, uint indexed amount, uint indexed time);
    event Unstaked(address indexed holderAddress, uint indexed amount);

    constructor(address _stakingToken)  {
        owner = msg.sender;

        percents[1] = 0;
        percents[3] = 18;
        percents[6] = 24;
        percents[12] = 48;

        cf[1] = 0;
        cf[3] = 11;
        cf[6] = 12;
        cf[12] = 14;

        ARTR = IERC20(_stakingToken);
    }

    function Stake(uint months, uint amount) payable external {
        address holder = msg.sender;
        require(holder != address(0), "invalid address");  
        require(amount > 0, "invalid amount"); 
        require(months == 1 || months == 3 || months == 6 || months == 12, "invalid time");
        holder_Amount[holder] = amount;
        holder_Duration[holder] = months;
        holder_Percents[holder] = percents[months];
        holder_CF[holder] = cf[months];
        holder_Finish[holder] = block.timestamp + months * 2629743;
        if (amount/2500 > 10) {
            holder_Tier[holder] = 10;
        } else {
            holder_Tier[holder] = amount/2500;
        }
        ARTR.transferFrom(msg.sender, address(this), amount);
        totalStaked += amount;
        emit Staked(holder, amount, months);
    }

    function Unstake(uint amount) payable external {
        address holder = msg.sender;
        require(holder != address(0), "invalid address");  
        require(amount > 0 && amount <= holder_Amount[holder], "invalid amount"); 
        holder_Amount[holder] -= amount;
        holder_Tier[holder] = holder_Amount[holder]/2500;
        ARTR.transfer(msg.sender, amount);
        totalStaked -= amount;
        if (block.timestamp >= holder_Finish[msg.sender]) {
            ARTR.transfer(msg.sender, holder_Percents[msg.sender] * holder_CF[msg.sender] * holder_Amount[msg.sender]/1000);
        }
        emit Unstaked(holder, amount);
    }

    function getReward() payable external {
        require(block.timestamp >= holder_Finish[msg.sender], "Exceeded staking time");
        uint reward = holder_Percents[msg.sender] * holder_CF[msg.sender] * holder_Amount[msg.sender]/1000;
        ARTR.transfer(msg.sender, reward);
        holder_Earned[msg.sender] += reward;
    }

    function holderData(address holder) external view returns(uint amount, uint time, uint percent, uint tier, uint cfs, uint finish){
        return(holder_Amount[holder], holder_Duration[holder], holder_Percents[holder], holder_Tier[holder], holder_CF[holder], holder_Finish[holder]);
    }

    function getContractBalance() external view returns(uint balance){
        return ARTR.balanceOf(address(this));
    }

    function getTotalStaked() external view returns(uint){
        return totalStaked;
    }

    function checkMyReward(address account) external view returns(uint) {
        return holder_Percents[account] * holder_CF[account] * holder_Amount[account]/1000;
    }

    function getHolderTier(address holder) external view returns (uint) {
        return holder_Tier[holder];
    }

    function getHolderCf(address holder) external view returns (uint) {
        return holder_CF[holder];
    }

    function getHolderAmount(address holder) external view returns (uint) {
        return holder_Amount[holder];
    }

    function getHolderStakingTime(address holder) external view returns (uint) {
        return holder_Duration[holder];
    }

}