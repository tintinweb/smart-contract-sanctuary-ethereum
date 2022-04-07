/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ChargingEV {
    //存储充电数据（即充电桩编号，充电时长，充电量）的结构
    struct ChargingData {
        //充电桩编号
        uint chargingPileID;
        //以分钟为单位的充电时长
        uint chargingTimeInMinutes;
        //充电结束时间
        uint chargingFinishTime;
        //一次充电的充电量
        uint energyUsed;
    }
    
    //存储健康状态相关数据（即充电桩编号，健康状态，当前时间）的结构
    struct PileHealthData {
        //充电桩编号
        uint chargingPileID;
        //充电桩正常运行为true，故障为false
        bool pileHealth;
        //当前时间
        uint currentTime;
    }

    //充电桩编号到工作状态（是否开始充电）的映射
    mapping(uint => bool) public PileWorkingStatus;
    //充电桩编号到健康状态的映射
    mapping(uint => bool) public PileHealth;

    //充电结束，数据已上报的事件
    event chargingFinished(
        uint indexed chargingPileID,
        uint chargingTimeInMinutes,
        uint chargingFinishTime,
        uint energyUsed);
    //开始充电的事件
    event ChargingStarted(uint indexed chargingPileID);
    //健康状态已上报的事件
    event PileHealthReported(
        uint indexed chargingPileID,
        bool pileHealth,
        uint currentTime);

    ChargingData[] public chargingDatas;
    PileHealthData[] public pileHealthDatas;

    //开始充电的函数，充电桩开始充电时执行
    function startCharging(uint _chargingPileID) public{
        //开始充电，将工作状态设为true
        PileWorkingStatus[_chargingPileID] = true;
        //触发开始充电的事件
        emit ChargingStarted(_chargingPileID);
    }
    
    //健康状态上报函数，充电桩定时上报健康状态时执行
    function ReportingPileHealth(
        uint _chargingPileID,
        bool _pileHealth,
        uint _currentTime) public {
        //设置某一充电桩的健康状态
        PileHealth[_chargingPileID] = _pileHealth;
        //上传充电桩编号、健康状态、当前时间三个数据至区块链
        pileHealthDatas.push(PileHealthData(
            _chargingPileID,
            _pileHealth,
            _currentTime));
        //触发事件HealthReported
        emit PileHealthReported(
            _chargingPileID,
            _pileHealth,
            _currentTime);
    }

    //充电结束及数据收集函数，当充电桩结束充电时执行
    function finishCharging(
        uint _chargingPileID,
        uint _chargingTimeInMinutes,
        uint _chargingFinishTime,
        uint _energyUsed) public {
        //上传充电桩编号、充电时间、充电量三个数据
        chargingDatas.push(ChargingData(
            _chargingPileID,
            _chargingTimeInMinutes,
            _chargingFinishTime,
            _energyUsed));
        //充电结束，将工作状态设为false
        PileWorkingStatus[_chargingPileID] = false;
        //触发充电结束，数据已上报的事件
        emit chargingFinished(
            _chargingPileID,
            _chargingTimeInMinutes,
            _chargingFinishTime,
            _energyUsed);
    }

    //读取充电数据
    function getChargingData(uint _index) public view returns (
        uint _chargingPileID,
        uint _chargingTimeInMinutes,
        uint _chargingFinishTime,
        uint _energyUsed) {
        ChargingData storage chargingData = chargingDatas[_index];
        return (
            chargingData.chargingPileID,
            chargingData.chargingTimeInMinutes,
            chargingData.chargingFinishTime,
            chargingData.energyUsed);
    }

    //读取健康状态数据
    function getPileHealth(uint _index) public view returns (
        uint _chargingPileID,
        bool _pileHealth,
        uint _currentTime) {
        PileHealthData storage pileHealthData = pileHealthDatas[_index];
        return (
            pileHealthData.chargingPileID,
            pileHealthData.pileHealth,
            pileHealthData.currentTime); 
    }
}