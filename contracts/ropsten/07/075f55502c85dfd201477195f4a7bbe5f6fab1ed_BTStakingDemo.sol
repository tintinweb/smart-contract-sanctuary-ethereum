/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT



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

// File: @openzeppelin/contracts/utils/Context.sol
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

pragma solidity ^0.8.0;

contract BTStakingDemo is Ownable {

    IERC20 _token; //Token

    uint256 deployTime; //t0

    uint256 rewardPool; //R

    uint256 constant rewardTime = 300; //T

    mapping(address => uint256) depositList;
    address[] depositAddr;

    uint256 totalDeposit;
    uint256 totalReward;

    constructor(address _addr) {
        _token = IERC20(_addr);
        deployTime = block.timestamp;
        // addRewardPool(_amount);
    }

    function addRewardPool(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        _token.approve(address(this), _amount);
        require(_token.balanceOf(msg.sender) >= _amount, "Insufficient funds");
        rewardPool = _amount;
        _token.transferFrom(msg.sender, address(this), _amount);
    }

    function depositTokens(uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        _token.approve(msg.sender, _amount);
        require(_token.balanceOf(msg.sender) >= _amount, "Insufficient funds");
        require(block.timestamp - deployTime <= rewardTime,"Deposit Period is over");
        if(depositList[msg.sender] <= 0){
            depositAddr.push(msg.sender);
            depositList[msg.sender] = _amount;
        }else{
            depositList[msg.sender] += _amount;
        }
        totalDeposit += _amount;
        _token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawTokens() public {
        uint256 _amount = depositList[msg.sender];
        require(_amount > 0, "Zero Balance");
        require(block.timestamp - deployTime > 2 * rewardTime,"You cannot withdraw in this time period");
        uint256 reward;
        if(block.timestamp - deployTime > 4 * rewardTime){
            reward = _amount * rewardPool / totalDeposit;
        }else if(block.timestamp - deployTime > 3 * rewardTime){
            reward = _amount * (rewardPool * 50 / 100) / totalDeposit;
        }else if(block.timestamp - deployTime > 2 * rewardTime){
            reward = _amount * (rewardPool * 20 / 100) / totalDeposit;
        }
        _amount += reward;
        _token.transfer(msg.sender,_amount);
        totalReward += reward;
        removeDepositAddr(msg.sender);
        depositList[msg.sender] = 0;
    }

    function withdrawRemain() public onlyOwner {
        require(block.timestamp - deployTime > 4 * rewardTime,"You cannot withdraw in this time period");
        require(depositAddr.length == 0,"Some users are remaining");
        uint256 _amount = rewardPool - totalReward;
        require(_amount > 0, "Zero Balance");
        _token.transfer(msg.sender,_amount);
    }

    function withdraw() public onlyOwner {
        uint256 _amount = _token.balanceOf(address(this));
         require(_amount > 0, "Zero Balance");
        _token.transfer(msg.sender,_amount);
    }

    function userBalance() public view returns(uint256) {
        return _token.balanceOf(msg.sender);
    }

    function removeDepositAddr(address _user) internal {
      for (uint256 i =0; i < depositAddr.length; i++) {
            if(depositAddr[i] == _user){
                depositAddr[i] = depositAddr[depositAddr.length-1];
                depositAddr.pop();
            }
        }
  }

}