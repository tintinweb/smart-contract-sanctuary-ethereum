pragma solidity ^0.4.18;
contract Owner{
mapping (address => uint) private userBalances;
mapping (address => bool) private claimedBonus;
mapping (address => uint) private rewardsForA;

function untrustedWithdrawReward(address recipient) public {
    uint amountToWithdraw = rewardsForA[recipient];
    rewardsForA[recipient] = 0;

    if (recipient.call.value(amountToWithdraw)() == false) {
        throw;
    }
}

function untrustedGetFirstWithdrawalBonus(address recipient) public {
   
    if (claimedBonus[recipient] == false) {throw;}
    claimedBonus[recipient] = true;
    rewardsForA[recipient] += 100;
    untrustedWithdrawReward(recipient);  
}
}