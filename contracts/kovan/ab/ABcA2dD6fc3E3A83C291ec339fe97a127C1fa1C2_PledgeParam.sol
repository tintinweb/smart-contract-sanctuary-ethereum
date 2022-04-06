/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// File: my/NewCowPledge/IPledgeParam.sol



pragma solidity ^0.8.0;

interface IPledgeParam {
    function levelWithdrawTime(uint i) view external returns(uint);

    function levelPowerMul(uint i) view external returns(uint);
    
    function incomeFee(uint value,uint lastBlock) view external returns(uint);
}

// File: my/NewCowPledge/param/PledgeParam.sol



pragma solidity ^0.8.0;


contract PledgeParam is IPledgeParam {
    uint[] public override levelWithdrawTime=[uint(0),30 days,90 days,180 days,360 days];
    uint[] public override levelPowerMul=[uint(0),1,5,15,45];

    function incomeFee(uint value,uint lastBlock) view external override returns(uint) {
        uint day=_sub(block.number,lastBlock)/28800;
        uint feeRatePercentage=0;
        if(day<=15)feeRatePercentage=15-day;
        return value*feeRatePercentage/100;
    }

    function _sub(uint l,uint r) internal pure returns(uint){
        return (l>=r)?(l-r):0;
    }
}