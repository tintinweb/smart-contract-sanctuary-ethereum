// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './SafeMath.sol';
import './SafeERC20.sol';
import './Ownable.sol';
import './IERC20.sol';
import "./ReEntrance.sol";


interface IsACX
{
    function transferFrom( address from, address to, uint256 value ) external returns ( bool );
    function transfer(address to, uint256 value)external returns ( bool );
    function gonsForBalance( uint amount ) external view returns ( uint );
    function balanceForGons( uint gons ) external view returns ( uint );
    function balanceOf( address who ) external view returns ( uint256 );
}

contract SynthReward is Ownable
{
    using SafeMath for uint256;   
    IsACX public sACX;
    uint256 public Fee = 1; // default is 0.01% of Harvesting Reward. 
    // % of Harvest Amount
    // 10000 => 100%
    // 1000 => 10%
    // 100 => 1%
    // 10 => 0.1%
    // 1 => 0.01%
    struct Stake 
    {
        uint deposit;
        uint gons;
    }
    mapping( address => Stake ) public StakeInfo;
    constructor(address _sacx)
    {
        sACX = IsACX(_sacx);
    }

    function stake(uint256 _amount)public
    {
        StakeInfo[msg.sender] = Stake({
            deposit: StakeInfo[msg.sender].deposit.add(_amount),
            gons: StakeInfo[msg.sender].gons.add(sACX.gonsForBalance(_amount))
        }); 
        sACX.transferFrom(msg.sender, address(this), _amount);
    }

    function unstake(uint256 _amount)public
    {
        uint256 amount_in_gons = sACX.gonsForBalance(_amount);
        StakeInfo[msg.sender].deposit = StakeInfo[msg.sender].deposit.sub(_amount);
        StakeInfo[msg.sender].gons = StakeInfo[msg.sender].gons.sub(amount_in_gons);
        sACX.transfer(msg.sender, _amount);
    }
    function unstakeAll()public
    {
        sACX.transfer(msg.sender, sACX.balanceForGons(StakeInfo[msg.sender].gons));
        delete StakeInfo[msg.sender];

    }
    function TotalReward(address _staker)public view returns (uint256 _reward)
    {
        uint256 oldBalance = StakeInfo[_staker].deposit;
        uint256 newBalance = sACX.balanceForGons(StakeInfo[_staker].gons);
        uint256 reward = newBalance.sub(oldBalance);
        return reward;
    }
    function harvestReward(address _recipient)public returns(uint256 _reward)
    {
        uint256 deposit = StakeInfo[_recipient].deposit;
        uint256 gons = StakeInfo[_recipient].gons;
        uint256 newbalance = sACX.balanceForGons(gons);
        uint256 reward = newbalance.sub(deposit);
        uint256 rewardInGons = sACX.gonsForBalance(reward);
        // Reward Deduction...
        uint256 fee = reward * Fee / 10000;
        uint256 updatedReward = reward - fee;
        sACX.transfer(_recipient, updatedReward);
        sACX.transfer(owner(), fee);
        // after transfer reward updating the gons stored against user.
        uint256 updatedGons = StakeInfo[_recipient].gons.sub(rewardInGons);
        Stake memory _updatedInfo = Stake({
            deposit : StakeInfo[_recipient].deposit,
            gons : updatedGons
        });
        StakeInfo[_recipient] = _updatedInfo;
        return _reward;
    }

    function setFee(uint256 _fee)public onlyOwner returns(bool success)
    {
        Fee = _fee * 100;
        return true;
    }

}