/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.2;

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

contract stakeReward is Ownable{
    IERC20 internal StakeToken;
    IERC20 internal RewardToken;
    address internal RewardTokenOwner;

    // tear levals
    enum tearLevel{
        noLevel,
        browns,
        silver,
        gold,
        platnium
    }

    constructor(address _StakeToken,address _RewardToken){
        StakeToken=IERC20(_StakeToken);
        RewardToken=IERC20(_RewardToken);
    }

    mapping(address=>uint) stakeBalance;
    mapping(address=>uint)updatedTime;

    function tearLevelCalculator(uint _stakeBalance) public pure returns(tearLevel){
        if(_stakeBalance<10000*1e18){
            return tearLevel.noLevel;
        }else if(_stakeBalance>=10000*1e18 && _stakeBalance<30000*1e18){
            return tearLevel.browns;
        }else if(_stakeBalance>=30000*1e18 && _stakeBalance<50000*1e18){
            return tearLevel.silver;
        }else if(_stakeBalance>=50000*1e18 && _stakeBalance<80000*1e18){
            return tearLevel.gold;
        }else{
            return tearLevel.platnium;
        }
    } 

    function stake(uint _amount) external{
        require(StakeToken.balanceOf(msg.sender)>=_amount,"stakeReward:You can not stake more then your balance");
        require(StakeToken.allowance(msg.sender,address(this))>=_amount,
        "stakeReward:You have not approve the token to this contract,or allowance is less then the amount");
        if((block.timestamp-updatedTime[msg.sender])/1 minutes>=1){
            claimReward();
        }
        StakeToken.transferFrom(msg.sender,address(this),_amount);
        stakeBalance[msg.sender]= stakeBalance[msg.sender]+_amount;
        updatedTime[msg.sender]=block.timestamp;
    }

    function getStakeBalane() external view returns(uint){
        return stakeBalance[msg.sender];
    }
        function claimReward() public{
             uint numberOfCycle=(block.timestamp-updatedTime[msg.sender])/1 minutes;   //TODO: Change 1 to 10 minutes;
             require(numberOfCycle >=1,"stakeReward:Reward time cycle has not been completed.You have to wait at least 10 minutes");
             uint stakerTearLevel=uint(tearLevelCalculator(stakeBalance[msg.sender]));
             uint rewardRate;
             if(stakerTearLevel==0){
                 rewardRate=0;
             }else if(stakerTearLevel==1){
                 rewardRate=stakeBalance[msg.sender]*12/1000;
             }else if(stakerTearLevel==2){
                 rewardRate=stakeBalance[msg.sender]*33/1000;
             }else if(stakerTearLevel==3){
                 rewardRate=stakeBalance[msg.sender]*6/100;
             }else{
                 rewardRate=stakeBalance[msg.sender]*8/100;
             }
             uint rewardAmount=rewardRate*numberOfCycle;
             RewardToken.transferFrom(RewardTokenOwner,msg.sender,rewardAmount);
             updatedTime[msg.sender]=block.timestamp;
        }

        function unstake() external{
            require(stakeBalance[msg.sender]>0,"stakeReward:You have not stake any token amount");
            StakeToken.transfer(msg.sender,stakeBalance[msg.sender]);
            delete stakeBalance[msg.sender];
            delete updatedTime[msg.sender];
        }

        function getRewardTokenOwner() external view returns(address){
        return RewardTokenOwner;
        }
        function setRewardTokenOwner(address _RewardTokenOwner) external onlyOwner{
         RewardTokenOwner=_RewardTokenOwner;
        }

    
}