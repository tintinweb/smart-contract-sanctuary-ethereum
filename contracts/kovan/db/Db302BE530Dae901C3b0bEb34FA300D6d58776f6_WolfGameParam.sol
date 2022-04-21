/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// File: my/wolf/MathX64.sol



pragma solidity ^0.8.0;

library MathX64 {
    uint constant x64=(1<<64)-1;
    
    uint constant oneX64=(1<<64);
    
    function mul(uint l, uint r) internal pure returns(uint result) {
        uint l_high=l>>64;
        uint r_high=r>>64;
        uint l_low=(l&x64);
        uint r_low=(r&x64);
        result=((l_high*r_high)<<64) + (l_high*r_low) + (r_high*l_low) + ((l_low*r_low)>>64);
    }
    
    function toPercentage(uint numberX64,uint decimal) internal pure returns(uint result) {
        numberX64*=100;
        if(decimal>0){
            numberX64*=10**decimal;
        }
        return numberX64>>64;
    }
    
    function toX64(uint percentage,uint decimal) internal pure returns(uint result) {
        uint divisor=100;
        if(decimal>0)
            divisor*=10**decimal;
        return oneX64*percentage/divisor;
    }
}
// File: my/wolf/game/param/IWolfGameParam.sol



pragma solidity ^0.8.0;

interface IWolfGameParam {
    function vitalityLimit(uint grade) external view returns(uint);
    function vitalityRecover(uint grade) external view returns(uint);
    function freeDriveAway() external view returns(uint);
    function freezeDriveAwayTime() external view returns(uint);
    function guardVITperSecondX64() external view returns(uint);
    function maxStealTime() external view returns(uint);
    function calcSteal(uint incomeValue,uint stolen,uint incomeAll,uint stealTime,bool _driveAway) external view returns(uint stealValue);
}
// File: my/wolf/game/param/WolfGameParam.sol



pragma solidity ^0.8.0;



contract WolfGameParam is IWolfGameParam {
    uint[] public override vitalityLimit=[uint(0),2,3,4,6,8];
    uint[] public override vitalityRecover=[uint(0),12*1 hours,8*1 hours,6*1 hours,4*1 hours,3*1 hours];
    uint public override freeDriveAway=3;
    uint public override freezeDriveAwayTime=20 minutes;
    uint public override guardVITperSecondX64=MathX64.oneX64/4 hours;
    uint public override maxStealTime=30 minutes;

    function calcSteal(uint incomeValue,uint stolen,uint incomeAll,uint stealTime,bool _driveAway) public view returns(uint stealValue) {
        stealValue=incomeValue/100;
        stealValue+=50*10**18*incomeValue/incomeAll;
        if(stealTime<maxStealTime) {
            stealValue=stealValue*stealTime/maxStealTime;
        }
        if(_driveAway) {
            stealValue=stealValue*9/10;
        }
        uint stealValueMax=_sub(incomeValue,stolen*2)/3;
        if(stealValue>stealValueMax){
            stealValue=stealValueMax;
        }
    }

    function _sub(uint a,uint b) public pure returns(uint) {
        return (a>b)?(a-b):0;
    }
}