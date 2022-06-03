// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;
import "Stakable.sol";
import "Referral.sol";
import "ERC20.sol";

contract MyToken is Stakeable, Referral, ERC20 {
    address internal constant LPOXLP_ADDRESS = 0x369587ce4d3c58978b31e44e5Cb681917Ae65170;
    address internal constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    struct StakingSummary{
        Stake stake;
     }

    constructor() ERC20("My Stakeable Token", "MST", 0){}

     /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function hasStake(address _staker) public view returns(StakingSummary memory){
        require(_isStaker(_staker) == true, "Not a staker!");
        StakingSummary memory summary = StakingSummary(stakeholders[stakes[_staker]].stake);
        summary.stake.claimable = calculateStakeReward(stakeholders[stakes[_staker]].stake);

        return summary;
    }

    function getReferralInfo() public view returns(Referal memory)
    {
        require(_isReferral(msg.sender), "Not a staker, become a staker to get a referral code.");

        return referrals[referral[_getReferralCode(msg.sender)]];
    }

    function getReferralMaster() public view returns(uint160)
    {
        return _get_referral_master(msg.sender);
    }

    function getReferralMaster(address sender) internal view returns(uint160)
    {
        return _get_referral_master(sender);
    }

    function stake(uint256 _amount) public 
    {
        require(!_isStaker(msg.sender), "Cannot stake while having open stake!");

        IERC20 LPOXLP = IERC20(LPOXLP_ADDRESS);
        require(_amount < LPOXLP.balanceOf(msg.sender), "Cannot stake more than you own!");
        require(LPOXLP.allowance(msg.sender, address(this)) >= _amount, "Please approve transfer before attempting to stake!");
        require(LPOXLP.transferFrom(msg.sender, address(this), _amount), "Couldn't transfer funds!");

        _add_or_get_Referral(msg.sender);
        _stake(_amount);
    }

    function restake(address _staker) public 
    {
        require(_isStaker(_staker) == true, "Not a staker!");
        require(checkIfMaximumTimePassed(stakeholders[stakes[_staker]].stake), "Finish stake first!");

        _restake();
    }

    /**
    * @notice withdrawStake is used to withdraw stakes from the account holder
     */
    function withdrawStake() public 
    {
        require(_isStaker(msg.sender), "Cannot withdraw non stake!");
        IERC20 LPOXLP = IERC20(LPOXLP_ADDRESS);

        uint256 original_LP_staked = _getOriginalLPStaked();
        uint256 exit_LP_fee = _getEarlyExiteLPFee();

        uint256 amount_to_mint = _withdrawStake();

        //reward the referrer
        uint160 code = getReferralMaster(msg.sender);
        if(code != 0)
        {
            _add_reward_to_referral_master(code, amount_to_mint);
        }

        require(original_LP_staked <= LPOXLP.balanceOf(address(this)), "LPOX LP must be higher, this shouldn't happen ever!");

        // Return staked tokens 
        uint256 amount_to_return_LP = original_LP_staked - exit_LP_fee;
        LPOXLP.approve(address(this), amount_to_return_LP );
        LPOXLP.transferFrom(address(this), msg.sender, amount_to_return_LP);

        //burn fee
        if(exit_LP_fee != 0)
        {
            LPOXLP.approve(address(this), exit_LP_fee);
            LPOXLP.transferFrom(address(this), DEAD_ADDRESS, exit_LP_fee);
        }

        // Mint rewarded tokens
        _mint(msg.sender, amount_to_mint);
    }

    function stakewithreferralcode(uint256 _amount, uint160 _referralcode) public 
    {
        require(!_isStaker(msg.sender), "Cannot stake while having open stake!");

        require(!_check_if_referral_code_used(msg.sender), "Already used referral code!");
        require(_checkIfValidReferralCode(msg.sender, _referralcode), "Must be valid referral code!");

        IERC20 LPOXLP = IERC20(LPOXLP_ADDRESS);

        require(_amount < LPOXLP.balanceOf(msg.sender), "Cannot stake more than you own!");
        require(LPOXLP.allowance(msg.sender, address(this)) >= _amount, "Please approve transfer before attempting to stake!");
        require(LPOXLP.transferFrom(msg.sender, address(this), _amount), "Couldn't transfer funds!");

        _stake(_amount);
        
        _add_or_get_Referral(msg.sender);
        _try_add_address_to_master_referral(msg.sender, _referralcode);
    }

    function withdrawReferralRewards() public{
        require(_isReferral(msg.sender), "Must be a referre.");
        require(referrals[referral[_getReferralCode(msg.sender)]].amountEarned > 0, "Must have referre rewards to withdraw.");
        uint256 amount_to_mint = referrals[referral[_getReferralCode(msg.sender)]].amountEarned;
        _mint(msg.sender, amount_to_mint);

        referrals[referral[_getReferralCode(msg.sender)]].amountEarned = 0;
    }
}