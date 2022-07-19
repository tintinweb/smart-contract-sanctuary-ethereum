/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor(){
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
   */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
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
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
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

/**
* @notice Stakeable is a contract who is ment to be inherited by other contract that wants Staking capabilities
*/
contract Stakeable is Ownable, ReentrancyGuard {

    IERC20 Token;
    uint public totalStaked;
    uint startTime;

    uint firstRoundTime = 4380 hours;
    uint secondRoundTime = 8760 hours;
    uint thirdRoundTime = 13140 hours;
    uint fourthRoundTime = 21900 hours;
    uint fifthRoundTime = 21900 hours;

    uint8 firstRoundRewardPercent = 95;
    uint8 secondRoundRewardPercent = 70;
    uint8 thirdRoundRewardPercent = 45;
    uint8 fourthRoundRewardPercent = 20;
    uint8 fifthRoundRewardPercent = 10;


    /**
    * @notice Constructor since this contract is not ment to be used without inheritance
    * push once to stakeholders for it to work proplerly
     */
    constructor(address _tokenAddress) {
        // Create token interface
        Token = IERC20(_tokenAddress);

        startTime = block.timestamp;
        // This push is needed so we avoid index 0 causing bug of index-1
        stakeholders.push();
    }

    struct Stake{
        address user;
        uint256 amount;
        uint256 since;
        uint percent;
        uint256 claimable;
        uint256 withdrawDelay;
    }

    struct Stakeholder{
        address user;
        Stake[] address_stakes;
    }

    struct StakingSummary{
        uint256 total_amount;
        Stake[] stakes;
    }

    Stakeholder[] internal stakeholders;

    mapping(address => uint256) internal stakes;

    event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    modifier checkAllowance(uint amount) {
        require(Token.allowance(msg.sender, address(this)) >= amount, "Error");
        _;
    }

    function getRewardPercent()internal view returns (uint8) {
        uint passedTime = block.timestamp - startTime;
        uint8 percent;
        if(passedTime < firstRoundTime){
            percent = firstRoundRewardPercent;
        } else if (passedTime < secondRoundTime) {
            percent = secondRoundRewardPercent;
        } else if(passedTime < thirdRoundTime){
            percent = thirdRoundRewardPercent;
        } else if(passedTime < fourthRoundTime){
            percent = fourthRoundRewardPercent;
        } else if(passedTime > fifthRoundTime){
            percent = fifthRoundRewardPercent;
        }
        return percent;
    }

    function _addStakeholder(address staker) internal returns (uint256){
        stakeholders.push();
        uint256 userIndex = stakeholders.length - 1;
        stakeholders[userIndex].user = staker;
        stakes[staker] = userIndex;
        return userIndex;
    }

    function _stake(uint256 _amount) internal{
        require(_amount > 0, "Cannot stake nothing");
        uint256 index = stakes[msg.sender];
        uint256 timestamp = block.timestamp;
        uint8 percent = getRewardPercent();
        if(index == 0){
            index = _addStakeholder(msg.sender);
        }

        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp, percent, 0, 0));

        emit Staked(msg.sender, _amount, index, timestamp);
    }

    function _calculatePercent(uint amount, uint percent)internal pure returns (uint )  {
        return amount * percent * 100/10000  ;
    }

    function _calculateFee(uint amount, uint percent) internal pure returns(uint){
        uint rewardPerYear = _calculatePercent(amount, percent);
        uint rewardPerHoer = rewardPerYear / 8760;
        return rewardPerHoer;
    }

    function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
        uint percent = _current_stake.percent;
        uint rewardPerHour = _calculateFee(_current_stake.amount, percent);
        return (((block.timestamp - _current_stake.since) / 1 hours) * rewardPerHour);
    }

    function _withdrawStake(uint256 amount, uint256 index) internal returns (uint256){
        uint256 user_index = stakes[msg.sender];

        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.since + 14 days < block.timestamp, "Stakeable: Less than 14 days have passed since the steak was placed");
        if (current_stake.withdrawDelay + 14 days < block.timestamp && current_stake.withdrawDelay != 0){
            stakeholders[user_index].address_stakes[index].since = block.timestamp;
        }

        if (current_stake.withdrawDelay == 0){
            stakeholders[user_index].address_stakes[index].withdrawDelay = block.timestamp;
            return 0;
        }

        require(current_stake.withdrawDelay + 14 days < block.timestamp, "Stakeable: 14 day delay after confirmation of staking withdrawal has not passed");
        require(current_stake.amount >= amount, "Stakeable: Cannot withdraw more than you have staked");

        uint256 reward = calculateStakeReward(current_stake);
        current_stake.amount = current_stake.amount - amount;
        if(current_stake.amount == 0){
            delete stakeholders[user_index].address_stakes[index];
        }else {
            stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
            stakeholders[user_index].address_stakes[index].since = block.timestamp;
        }
        return amount + reward;
    }

    function hasStake(address _staker) external view returns(StakingSummary memory){
        uint256 totalStakeAmount;
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);

        for (uint256 s = 0; s < summary.stakes.length; s += 1){
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].claimable = availableReward;
            totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
        }

        summary.total_amount = totalStakeAmount;
        return summary;
    }


    function stake(uint256 _amount) external nonReentrant checkAllowance(_amount){
        require(_amount <= Token.balanceOf(msg.sender), "Stakeable: Cannot stake more than you own");
        _stake(_amount);
        Token.transferFrom(msg.sender, address(this), _amount);
        totalStaked += _amount;
    }

    function withdrawStake(uint256 amount, uint256 stake_index) external nonReentrant  {
        uint256 amount_to_mint = _withdrawStake(amount, stake_index);
        if(amount_to_mint == 0){

            } else {
            Token.approve(address(this), amount_to_mint);
            Token.transferFrom(address(this), msg.sender, amount_to_mint);
            totalStaked -= amount;
        }

    }

    function refundTokens(address _recipient, address _token) external onlyOwner {
        require(_token != address (Token), "Stakeable: You cannot debit the rex token using this function. Rex token is withdrawn using the withdraw function");
        IERC20 token = IERC20(_token);
        require(token.balanceOf(address(this)) > 0, 'Stakeable: No tokens');
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0);
        require(token.transfer(_recipient, balance));
    }

    receive () external payable {
        revert("Stakeable: You cannot send ether to the address of this contract!");
    }
}