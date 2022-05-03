/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

contract RosePadStake is Ownable {
    IERC20 public stakeToken;
    IERC20 public rewardToken;
    uint public currentId = 1;
    uint public stakeAmounts;
    uint public rewardAmounts;


    event Stake(address indexed user,uint id, uint stakeAmount, uint time);
    event Unstake(address indexed user,uint id, uint rewardAmount, uint time);

     struct User{
        uint id;
        address user;
        uint stakeAmount;
        uint rewardAmount;
        uint stakeTime;
        uint plan;
     }

     struct plans{
         uint planDays;
         uint planPercentage;
     }

     mapping(uint => plans)public planDetails;
     mapping(uint => User)public userDetails;

     constructor(address _stakeToken,address _rewardToken){
         stakeToken = IERC20(_stakeToken);
         rewardToken = IERC20(_rewardToken);

         planDetails[1].planDays = 365 days;
         planDetails[1].planPercentage = 100e18;

         planDetails[2].planDays = 180 days;
         planDetails[2].planPercentage = 50e18;

     }

     function updatePlan(uint _plan,uint _days,uint _percentage)public onlyOwner{
         require(planDetails[_plan].planDays > 0 ,"RosePadStake: Plan is Not Activated");
         planDetails[_plan].planDays = _days;
         planDetails[_plan].planPercentage = _percentage;
     }

     function setPlan(uint _plan,uint _days,uint _percentage)public onlyOwner{
         require(planDetails[_plan].planDays == 0 ,"RosePadStake: Plan is Already Exists");
         planDetails[_plan].planDays = _days;
         planDetails[_plan].planPercentage = _percentage;
     }

     function addrewardToken(uint _rewardAmount)public onlyOwner{
            require(_rewardAmount > 0 , "RosePadStake: Invalid Reward Amount");
            IERC20(rewardToken).transferFrom(_msgSender(),address(this),_rewardAmount);
            rewardAmounts += _rewardAmount;
     }

     function stake(uint _stakeAmount, uint _plan)external {
        require(_stakeAmount > 0 , "RosePadStake: Invalid Staked Amount");
        require(planDetails[_plan].planDays > 0 ,"RosePadStake: Invalid Plan");

        IERC20(stakeToken).transferFrom(_msgSender(),address(this),_stakeAmount);

        User storage UserDetails =  userDetails[currentId];
        UserDetails.id = currentId;
        UserDetails.user = _msgSender();
        UserDetails.stakeAmount = _stakeAmount;
        UserDetails.rewardAmount = 0;
        UserDetails.stakeTime = block.timestamp + planDetails[_plan].planDays;
        UserDetails.plan = _plan;

        stakeAmounts += _stakeAmount;

        emit Stake(_msgSender(),currentId,_stakeAmount,block.timestamp);
        currentId++;
     }

     function UnStake(uint id)external{
         require(id < currentId , "RosePadStake: Invalid User ID");
         require(userDetails[id].user == _msgSender() , "RosePadStake: Invalid User Address");
         require(userDetails[id].stakeAmount > 0 , "RosePadStake: Invalid Reward Amount");
         require(userDetails[id].stakeTime < block.timestamp , "RosePadStake: Time is not Reached");
         require(rewardAmounts > 0 , "RosePadStake: Invalid Reward Amount");

         uint amount = calculateReward(id);
         userDetails[id].stakeAmount = 0;
         userDetails[id].rewardAmount = amount;
         IERC20(rewardToken).transfer(_msgSender(), amount);
         rewardAmounts -= amount;

        emit Unstake(_msgSender(),id,amount,block.timestamp);

     }

     function calculateReward(uint _id)public view returns(uint){
         return (userDetails[_id].stakeAmount * planDetails[userDetails[_id].plan].planPercentage) / 100e18;
     }

     function failcase( address tokenAdd, uint amount) external onlyOwner{
        address self = address(this);
        if(tokenAdd == address(0)) {
            require(self.balance >= amount);
            require(payable(owner()).send(amount));
        }
        else {
            require(IERC20(tokenAdd).balanceOf(self) >= amount);
            require(IERC20(tokenAdd).transfer(owner(),amount));
        }
    }


}