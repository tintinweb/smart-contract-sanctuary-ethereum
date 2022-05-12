// SPDX-License-Identifier: MIT
 pragma solidity 0.7.5;

 contract TestSafetyModule {

     uint public amount;
     mapping(address => uint256) inactiveBalances; 
     
     event WithdrawalRequested(address indexed staker, uint256 stakeAmount);

     function getInactiveBalanceNextEpoch(address staker) public view returns (uint256){
         return inactiveBalances[staker];
     }

    function setInactiveBalanceNextEpoch(address staker, uint256 _inactiveBalance) public{
          inactiveBalances[staker] = _inactiveBalance;
     }

     function emitWithdrawalRequested(address _staker, uint256 _stakeAmount) public {
         emit WithdrawalRequested( _staker, _stakeAmount);
     }

 }