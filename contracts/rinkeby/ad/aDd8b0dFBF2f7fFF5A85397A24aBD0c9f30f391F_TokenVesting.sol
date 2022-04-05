// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenVesting is Ownable{

    uint private TotalSupply = 1e26;
    uint private denominator = 1000;
    uint private startTime = block.timestamp;
    IERC20 public NiceToken;

    
    /**
     *@dev sets the address of NiceToken
     *
     *@param token addres of token to distribute during vesting
     */
    constructor(IERC20 token) Ownable(){
        NiceToken = IERC20(token);
    }

    enum Roles { 
        advisor,
        partnership,
        mentor
    }

    struct Receipients{
        Roles role;
        uint lastRewardUpdateTime;
    }

    mapping(address=>Receipients) private Shares;
    mapping(Roles=>uint) private roles;
    mapping(address =>uint) public balnaces;
    mapping(Roles=>uint) public rewardPerRole;

    /**
     *@dev adds new Receipient to vesting according to role
     *
     *@param person is address of the person to be added to vesting
     *@param role is role to dedicate the person
     */
    function addReceipient(address person,Roles role)public onlyOwner {
        require(block.timestamp <cliff(),"Can not add receipient after the cliff period");
        uint lastRewardUpdate = Shares[person].lastRewardUpdateTime;
        require(lastRewardUpdate == 0,"receipient should not be part of the program already");
        Shares[person].role = role;
        roles[role]++;
        rewardPerRole[role] = getNewPercentage(role);
        Shares[person].lastRewardUpdateTime = cliff();   
    }

    /**
     *@dev updates the balance og the caller and
     *transfers 'amount' of tokens to the caller
     *and sets the balance of the caller to '0'
     */
    function collect() public {
        require(block.timestamp > cliff(), "Cliff period is not over yet");
        updatebalance(msg.sender);
        uint amount = balnaces[msg.sender];
        require(amount >0,"Can't withdraw 0 tokens");
        unchecked{
            NiceToken.transfer(msg.sender,amount);
        }
        balnaces[msg.sender] = 0; 
    }

    /**
     *@dev updates the percentage of tokens for a role 
     *as a new user joins vesting with that role
     *   
     *Returns uint value of new percentage for the role
     *   
     *@param role role of the new receipient  
    */
    function getNewPercentage(Roles role) internal view returns (uint) {
        uint participants = roles[role];
        uint rolePercentage;
        
        if(Roles.advisor == role){
            rolePercentage =75;
        }
        else if(Roles.partnership == role){
            rolePercentage =100;
        }
        else {
            rolePercentage = 50;
        }
        return rolePercentage/participants;
    }
    /**
     *@dev updates the balance of the user
     *calculates the unpaid tokens for the vesting
     *
     *@param user address of the user whose balance we want to update
     */
    function updatebalance(address user) internal {
        uint unPaidDays;
        uint percentage = rewardPerRole[Shares[user].role];
        uint dailyReward = TotalSupply *percentage /(denominator *365);

        if(block.timestamp >vestingDuration()){
            unPaidDays = (vestingDuration() - Shares[user].lastRewardUpdateTime)/day(); 
        }
        else {
            unPaidDays = (block.timestamp - Shares[user].lastRewardUpdateTime)/day();
        } 
        balnaces[user] += dailyReward*unPaidDays;
        Shares[user].lastRewardUpdateTime += (unPaidDays*day());
    }

    /**
     *@dev Returns seconds of a day
     */
    function day() internal view returns(uint){
        return 86400;
    }

    /**
     *@dev Returns the cliff time of the contract
     */
    function cliff() internal view returns(uint){
        return startTime + (90 * day());
    }
    
    /**
     *dev Returns the vesting period for the tokens
     */
    function vestingDuration() internal view returns(uint){
        return cliff() + (365 *day());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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