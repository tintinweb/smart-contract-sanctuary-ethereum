/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

contract Bend {

    address owner;
    address public bend;
    address public bendProtocolIncentivesController;
    address public bendWeth;
    address public bendDebtWeth;

    constructor (address _bend, address _bendProtocolIncentivesController, address _bendWeth, address _bendDebtWeth) {
        owner = msg.sender;
        bend = _bend;
        bendProtocolIncentivesController = _bendProtocolIncentivesController;
        bendWeth = _bendWeth;
        bendDebtWeth = _bendDebtWeth;
    }

    function setBend(address _bend) external onlyOwner {
        bend = _bend;
    }

    function setBendProtocolIncentivesController(address _bendProtocolIncentivesController) external onlyOwner {
        bendProtocolIncentivesController = _bendProtocolIncentivesController;
    }

    function setBendWeth(address _bendWeth) external onlyOwner {
        bendWeth = _bendWeth;
    }

    function setBendDebtWeth(address _bendDebtWeth) external onlyOwner {
        bendDebtWeth = _bendDebtWeth;
    }

    function getBendInfo(address _queryAddress) external view returns (
        uint256 ownedBend, uint256 unclaimedBend, uint256 totalBend
    ) {
        bytes memory lowLevelCallResult;

        (, lowLevelCallResult) = bend.staticcall(abi.encodeWithSignature(
            "balanceOf(address)",
            _queryAddress
        ));
        ownedBend = abi.decode(lowLevelCallResult, (uint256));

        address[] memory assets = new address[](2);
        assets[0] = bendWeth;
        assets[1] = bendDebtWeth;

        (, lowLevelCallResult) = bendProtocolIncentivesController.staticcall(abi.encodeWithSignature(
            "getRewardsBalance(address[],address)",
            assets,
            _queryAddress
        ));
        unclaimedBend = abi.decode(lowLevelCallResult, (uint256));

        totalBend = ownedBend + unclaimedBend;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender != owner");
        _;
    }
}