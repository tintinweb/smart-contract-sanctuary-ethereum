/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

// File: my/wolf/game/param/IWolfAttackCowParam.sol



pragma solidity ^0.8.0;

interface IWolfAttackCowParam {
    function calcSteal(uint incomeValue,uint stolen) external view returns(uint stealValue);
    function levelDown(uint randomX128) external view returns(bool);
    function blood(uint randomX128,uint levelLife) external view returns(uint);
    function attackSuccess(uint randomX128,uint cowLevel,uint cowGrade,uint wolfGrade,uint cowLife,uint cowLevelLife) external view returns(bool);
}
// File: my/MathX128.sol



pragma solidity ^0.8.0;

library MathX128 {
    uint constant x128=(1<<128)-1;
    
    uint constant oneX128=(1<<128);
    
    function mulX128(uint l, uint r) internal pure returns(uint result) {
        uint l_high=l>>128;
        uint r_high=r>>128;
        uint l_low=(l&x128);
        uint r_low=(r&x128);
        result=((l_high*r_high)<<128) + (l_high*r_low) + (r_high*l_low) + ((l_low*r_low)>>128);
    }
    
    function mulUint(uint l,uint r) internal pure returns(uint result) {
        result=(l*r)>>128;
    }
    
    function toPercentage(uint numberX128,uint decimal) internal pure returns(uint result) {
        numberX128*=100;
        if(decimal>0){
            numberX128*=10**decimal;
        }
        return numberX128>>128;
    }
    
    function toX128(uint percentage,uint decimal) internal pure returns(uint result) {
        uint divisor=100;
        if(decimal>0)
            divisor*=10**decimal;
        return oneX128*percentage/divisor;
    }
}
// File: my/wolf/game/param/WolfAttackCowParam.sol



pragma solidity ^0.8.0;



contract WolfAttackCowParam is IWolfAttackCowParam {
    uint[] public levelProbability=[uint(0),
    0,0,0,0,0,
    0,0,0,0,0,
    0,0,0,0,0,
    3000,3038,3081,3130,3185,
    3249,3321,3406,3507,3633,3789,4000,4253,4552,5000
    ];

    uint[] public cowGradeProbability=[uint(2400),2400,2422,2547,3000];

    uint[] public wolfGradeProbability=[uint(600),600,700,800,900,1100];

    uint[] public cowRemainLifeProbability=[uint(0),2500,2600,2800,2900,3000];

    uint[] public cowRemainLifeProportion=[uint(0),30,50,70,90,100];

    function calcSteal(uint incomeValue,uint stolen) public pure returns(uint stealValue) {
        stealValue=incomeValue*15/100;
        uint stealValueMax=_sub(incomeValue*2,stolen*3)/5;
        if(stealValue>stealValueMax){
            stealValue=stealValueMax;
        }
    }

    function levelDown(uint randomX128) public pure returns(bool) {
        return randomX128<=MathX128.toX128(40,0);
    }

    function blood(uint randomX128,uint levelLife) public pure returns(uint) {
        return levelLife/5;
        // if(randomX128<=MathX128.toX128(35,0)){
        //     return levelLife/10;
        // } else {
        //     return 0;
        // }
    }

    function attackSuccess(uint randomX128,uint cowLevel,uint cowGrade,uint wolfGrade,uint cowLife,uint cowLevelLife) public view returns(bool) {
        uint cowLifeRemainX128=MathX128.oneX128*cowLife/cowLevelLife;
        uint probability=levelProbability[cowLevel]+cowGradeProbability[cowGrade];
        uint i;
        for(i=1;i<5;i++){
            if(cowLifeRemainX128<MathX128.toX128(cowRemainLifeProportion[i],0)){
                break;
            }
        }
        probability+=cowRemainLifeProbability[i];
        probability=_sub(probability,wolfGradeProbability[wolfGrade]);
        return randomX128>MathX128.toX128(probability,2);
    }

    function _sub(uint a,uint b) public pure returns(uint) {
        return (a>b)?(a-b):0;
    }
}