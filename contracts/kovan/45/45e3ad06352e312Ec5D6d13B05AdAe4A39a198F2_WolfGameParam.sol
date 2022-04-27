/**
 *Submitted for verification at Etherscan.io on 2022-04-27
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
    function guardOneVIT() external view returns(uint);
    function maxStealTime() external view returns(uint);
    function calcSteal(uint incomeValue,uint stolen,uint incomeAll,uint stealTime,bool _driveAway) external view returns(uint stealValue);
    function calcSteal(uint incomeValue,uint stolen,uint incomeAll,uint stealTime,bool _driveAway,uint cowGrade) external view returns(uint stealValue);
}
// File: my/wolf/game/param/WolfGameParam.sol



pragma solidity ^0.8.0;



contract WolfGameParam is IWolfGameParam {
    uint[] public override vitalityLimit=[uint(0),2,3,4,6,8];
    uint[] public override vitalityRecover=[uint(0),12 hours,8 hours,6 hours,4 hours,3 hours];
    uint public override freeDriveAway=3;
    uint public override freezeDriveAwayTime=0;
    uint public override guardVITperSecondX64=MathX64.oneX64/4 hours;
    uint public override guardOneVIT=4 hours;
    uint public override maxStealTime=30 minutes;
    uint[] public cowGradeRelief=[uint(100),100,85,40,10];

    function calcSteal(uint incomeValue,uint stolen,uint incomeAll,uint stealTime,bool _driveAway) public view returns(uint stealValue) {
        stealValue=incomeValue*3/100;
        stealValue+=60*10**18*incomeValue/incomeAll;
        if(stealTime<maxStealTime) {
            stealValue=stealValue*stealTime/maxStealTime*7/10;
        }
        if(_driveAway) {
            stealValue=stealValue*9/10;
        }
        uint stealValueMax=_sub(incomeValue,stolen*2)/3;
        if(stealValue>stealValueMax){
            stealValue=stealValueMax;
        }
    }

    function calcSteal(uint incomeValue,uint stolen,uint incomeAll,uint stealTime,bool _driveAway,uint cowGrade) public view returns(uint stealValue) {
        stealValue=incomeValue*3/100;
        stealValue+=60*10**18*incomeValue/incomeAll;
        if(stealTime<maxStealTime) {
            stealValue=stealValue*stealTime/maxStealTime*7/10;
        }
        if(_driveAway) {
            stealValue=stealValue*9/10;
        }
        stealValue=stealValue*cowGradeRelief[cowGrade]/100;
        uint stealValueMax=_sub(incomeValue,stolen*2)/3;
        if(stealValue>stealValueMax){
            stealValue=stealValueMax;
        }
    }

    function _sub(uint a,uint b) public pure returns(uint) {
        return (a>b)?(a-b):0;
    }
}