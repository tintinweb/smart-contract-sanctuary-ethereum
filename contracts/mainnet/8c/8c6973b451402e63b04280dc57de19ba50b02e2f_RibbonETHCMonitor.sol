/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

contract RibbonETHCMonitor {

    address owner;
    address public ethc;
    address public rethStaking;

    constructor (address _ethc, address _rethStaking) {
        owner = msg.sender;
        ethc = _ethc;
        rethStaking = _rethStaking;
    }

    function setAddress(address _ethc, address _rethStaking) external {
        if (msg.sender != owner) revert("msg.sender != owner");

        ethc = _ethc;
        rethStaking = _rethStaking;
    }

    function rTokenState(address _queryAddress) external view returns (uint256 shares, uint256 sharePrice) {
        bytes memory lowLevelCallResult;
        (, lowLevelCallResult) = ethc.staticcall(abi.encodeWithSignature("pricePerShare()"));
        sharePrice = abi.decode(lowLevelCallResult, (uint256));
        (, lowLevelCallResult) = ethc.staticcall(abi.encodeWithSignature("shares(address)", _queryAddress));
        shares += abi.decode(lowLevelCallResult, (uint256));
        (, lowLevelCallResult) = rethStaking.staticcall(abi.encodeWithSignature("balanceOf(address)", _queryAddress));
        shares += abi.decode(lowLevelCallResult, (uint256));
    }
}