/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

contract LiquityMonitor {

    struct LiquityDetails {
        uint256 debt;
        uint256 collateral;
        uint256 lusdDeposit;
        uint256 ethGain;
        uint256 lqtyGain;
        uint256 lusdBalance;
        uint256 lqtyBalance;
        uint256 netEth;
        int256 netLusd;
        uint256 netLqty;
    }

    address owner;
    address public liquityStabilityPool;
    address public liquityTroveManager;
    address public lusd;
    address public lqty;


    constructor (
        address _liquityStabilityPool, address _liquityTroveManager, address _lusd, address _lqty
    ) {
        owner = msg.sender;
        liquityStabilityPool = _liquityStabilityPool;
        liquityTroveManager = _liquityTroveManager;
        lusd = _lusd;
        lqty = _lqty;
    }

    function setLiquityStabilityPool(address _liquityStabilityPool) external onlyOwner {
        liquityStabilityPool = _liquityStabilityPool;
    }

    function setLiquityTroveManager(address _liquityTroveManager) external onlyOwner {
        liquityTroveManager = _liquityTroveManager;
    }

    function setLusd(address _lusd) external onlyOwner {
        lusd = _lusd;
    }

    function setLqty(address _lqty) external onlyOwner {
        lqty = _lqty;
    }

    function getLiquityInfo(address _queryAddress) external view returns (LiquityDetails memory liquityDetails) {
        bytes memory lowLevelCallResult;

        (, lowLevelCallResult) = liquityTroveManager.staticcall(abi.encodeWithSignature(
            "getEntireDebtAndColl(address)",
            _queryAddress
        ));
        (liquityDetails.debt, liquityDetails.collateral,,) = abi.decode(lowLevelCallResult, (uint256, uint256, uint256, uint256));

        (, lowLevelCallResult) = liquityStabilityPool.staticcall(abi.encodeWithSignature(
            "getCompoundedLUSDDeposit(address)",
            _queryAddress
        ));
        liquityDetails.lusdDeposit = abi.decode(lowLevelCallResult, (uint256));

        (, lowLevelCallResult) = liquityStabilityPool.staticcall(abi.encodeWithSignature(
            "getDepositorETHGain(address)",
            _queryAddress
        ));
        liquityDetails.ethGain = abi.decode(lowLevelCallResult, (uint256));

        (, lowLevelCallResult) = liquityStabilityPool.staticcall(abi.encodeWithSignature(
            "getDepositorLQTYGain(address)",
            _queryAddress
        ));
        liquityDetails.lqtyGain = abi.decode(lowLevelCallResult, (uint256));

        (, lowLevelCallResult) = lusd.staticcall(abi.encodeWithSignature(
            "balanceOf(address)",
            _queryAddress
        ));
        liquityDetails.lusdBalance = abi.decode(lowLevelCallResult, (uint256));

        (, lowLevelCallResult) = lqty.staticcall(abi.encodeWithSignature(
            "balanceOf(address)",
            _queryAddress
        ));
        liquityDetails.lqtyBalance = abi.decode(lowLevelCallResult, (uint256));

        liquityDetails.netEth = liquityDetails.collateral + liquityDetails.ethGain;
        liquityDetails.netLusd = int256(liquityDetails.lusdBalance) + int256(liquityDetails.lusdDeposit) - int256(liquityDetails.debt);
        liquityDetails.netLqty = liquityDetails.lqtyBalance + liquityDetails.lqtyGain;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender != owner");
        _;
    }
}