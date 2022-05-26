/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract Calculate{

    uint256 private aCommit;
    uint256 private bCommit;
    uint256 private aCommitPeriod;
    uint256 private bCommitPeriod;
    uint256 private totalCommit;

    uint256 private aCommitment;
    uint256 private bCommitment;
    uint256 private totalCommitment;
    
    uint256 private dDeposit;
    uint256 private dDepositPeriod;
    uint256 private totalDeposit;

    uint256 private reitgReductionRate = 50000000;
    uint256 private community = 780124995;

    uint256 public reitG;
    uint256 public comRatio;
    uint256 public depRatio;

    uint256 private comRatioNum;
    uint256 private comDepRatioDon;
    uint256 private depRatioNum;

    uint256 public comReitG;
    uint256 public depReitG;

    uint256 public aReitG;
    uint256 public bReitG;
    uint256 public dReitG;

    function getInvestment () external view returns(uint256 _aCommitment, uint256 _aCommitPeriod, uint256 _aCommit, uint256 _bCommitment, uint256 _bCommitPeriod, uint256 _bCommit, uint256 _totalCommit, uint256 _dDeposit, uint256 _dDepositPeriod, uint256 _totalDeposit, uint256 _reitG){
        return (aCommitment, aCommitPeriod, aCommit, bCommitment, bCommitPeriod, bCommit, totalCommit, dDeposit, dDepositPeriod, totalDeposit, reitG);
    }


    function totalInvestment (uint256 _aCommit, uint256 _aCommitPeriod, uint256 _bCommit, uint256 _bCommitPeriod, uint256 _dDeposit, uint256 _dDepositPeriod) public {
        aCommit = _aCommit;
        aCommitPeriod = _aCommitPeriod;

        bCommit = _bCommit;
        bCommitPeriod = _bCommitPeriod;

        dDeposit = _dDeposit;
        dDepositPeriod = _dDepositPeriod;

        totalCommit = aCommit+bCommit;

        aCommitment =  _aCommit*_aCommitPeriod;
        bCommitment =  _bCommit*_bCommitPeriod;
        totalCommitment = aCommitment+bCommitment;

        totalDeposit = _dDeposit*_dDepositPeriod;

        reitG = ((totalCommit+totalDeposit)*(community/100)*9999/10000)/(reitgReductionRate*100);
        
        comRatioNum = (4*1e18*totalCommit/(totalCommit+totalDeposit));
        comDepRatioDon = (4*1e8*totalCommit/(totalCommit+totalDeposit))+(1e8*totalDeposit/(totalCommit+totalDeposit));
        depRatioNum = (1e18*totalDeposit/(totalCommit+totalDeposit));

        comRatio = comRatioNum/(1e8*comDepRatioDon);
        depRatio = depRatioNum/(1e8*comDepRatioDon);

        comReitG = comRatio*reitG/100;
        depReitG = depRatio*reitG/100;

        aReitG = aCommit*comReitG/totalCommit;
        bReitG = bCommit*comReitG/totalCommit;
        dReitG = dDeposit*depReitG/totalDeposit;

    }
}