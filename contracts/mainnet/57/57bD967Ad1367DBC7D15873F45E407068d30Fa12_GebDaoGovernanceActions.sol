pragma solidity ^0.6.7;

contract CustomDataTypes {
    enum ChangeType {
        Add,
        Remove,
        Replace
    }

    struct Change {
        ChangeType action;
        uint256 executionTimestamp;
        uint256 oracleIndex;
        address newOracle;
    }
}

abstract contract Setter is CustomDataTypes{
    function modifyParameters(bytes32, uint256) external virtual;
    function modifyParameters(bytes32, int256) external virtual;
    function modifyParameters(bytes32, address) external virtual;
    function modifyParameters(bytes32, bytes32, address) external virtual;
    function modifyParameters(address, bytes32, uint) external virtual;
    function modifyParameters(address, bytes32, address) external virtual;
    function modifyParameters(address, bytes4, bytes32, uint256) external virtual;
    function connectSAFESaviour(address) external virtual;
    function disconnectSAFESaviour(address) external virtual;
    function transferERC20(address, address, uint256) external virtual;
    function restartRedemptionRate() external virtual;
    function changePriceSource(address) external virtual;
    function updateResult(uint256) external virtual;
    function addFundingReceiver(address, bytes4, uint256, uint256, uint256) external virtual;
    function addFundingReceiver(address, bytes4, uint256, uint256, uint256, uint256) external virtual;
    function removeFundingReceiver(address, bytes4) external virtual;
    function addRewardAdjuster(address) external virtual;
    function removeRewardAdjuster(address) external virtual;
    function addFundedFunction(address, bytes4, uint256) external virtual;
    function removeFundedFunction(address, bytes4) external virtual;
    function createStream(address, uint256, address, uint256, uint256) external virtual;
    function cancelStream() external virtual;
    function mint() external virtual;
    function _setVotingDelay(uint256) external virtual;
    function swapOracle(uint256) external virtual;
    function ScheduleChangeTrustedOracle(
        ChangeType,
        uint256,
        address
    ) external virtual;
    function executeChange() external virtual;
    function cancelChange() external virtual;
}

// @notice Contract to be used by GEB DAO allowing changes in all RAI parameters that were not ungoerned
// @dev Supposed to be delegatecalled into by the RAI Ungovernor
contract GebDaoGovernanceActions is CustomDataTypes{

    function modifyParameters(address target, bytes32 param, uint256 val) external {
        Setter(target).modifyParameters(param, val);
    }

    function modifyParameters(address target, bytes32 param, int256 val) external {
        Setter(target).modifyParameters(param, val);
    }

    function modifyParameters(address target, bytes32 param, address val) external {
        Setter(target).modifyParameters(param, val);
    }

    function modifyParameters(address target, bytes32 collateralType, bytes32 parameter, address data) external {
        Setter(target).modifyParameters(collateralType, parameter, data);
    }

    function modifyParameters(address target, address reimburser, bytes32 parameter, uint256 data) external {
        Setter(target).modifyParameters(reimburser, parameter, data);
    }

    function modifyParameters(address target, address reimburser, bytes32 parameter, address data) external {
        Setter(target).modifyParameters(reimburser, parameter, data);
    }

    function modifyParameters(address target, address fundingTarget, bytes4 fundedFunction, bytes32 parameter, uint256 data) external {
        Setter(target).modifyParameters(fundingTarget, fundedFunction, parameter, data);
    }

    function connectSAFESaviour(address target, address saviour) external {
        Setter(target).connectSAFESaviour(saviour);
    }

    function disconnectSAFESaviour(address target, address saviour) external {
        Setter(target).disconnectSAFESaviour(saviour);
    }

    function transferERC20(address target, address token, address dst, uint256 amount) external {
        Setter(target).transferERC20(token, dst, amount);
    }

    function restartRedemptionRate(address target) external {
        Setter(target).restartRedemptionRate();
    }

    function changePriceSource(address target, address source) external {
        Setter(target).changePriceSource(source);
    }

    function updateResult(address target, uint256 result) external {
        Setter(target).updateResult(result);
    }

    function addFundingReceiver(
        address target,
        address receiver,
        bytes4  targetFunctionSignature,
        uint256 updateDelay,
        uint256 gasAmountForExecution,
        uint256 fixedRewardMultiplier
    ) external {
        Setter(target).addFundingReceiver(
            receiver,
            targetFunctionSignature,
            updateDelay,
            gasAmountForExecution,
            fixedRewardMultiplier
        );
    }

    function addFundingReceiver(
        address target,
        address receiver,
        bytes4  targetFunctionSignature,
        uint256 updateDelay,
        uint256 gasAmountForExecution,
        uint256 baseRewardMultiplier,
        uint256 maxRewardMultiplier
    ) external {
        Setter(target).addFundingReceiver(
            receiver,
            targetFunctionSignature,
            updateDelay,
            gasAmountForExecution,
            baseRewardMultiplier,
            maxRewardMultiplier
        );
    }

    function removeFundingReceiver(address target, address receiver, bytes4  targetFunctionSignature) external {
        Setter(target).removeFundingReceiver(receiver,targetFunctionSignature);
    }

    function addRewardAdjuster(address target, address adjuster) external {
        Setter(target).addRewardAdjuster(adjuster);
    }

    function removeRewardAdjuster(address target, address adjuster) external {
        Setter(target).removeRewardAdjuster(adjuster);
    }

    function addFundedFunction(address target, address targetContract, bytes4 targetFunction, uint256 latestExpectedCalls) external {
        Setter(target).addFundedFunction(targetContract, targetFunction, latestExpectedCalls);
    }

    function removeFundedFunction(address target, address targetContract, bytes4 targetFunction) external {
        Setter(target).removeFundedFunction(targetContract, targetFunction);
    }

    function createStream(
        address target,
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external {
        Setter(target).createStream(recipient, deposit, tokenAddress, startTime, stopTime);
    }

    function cancelStream(address target) external {
        Setter(target).cancelStream();
    }

    function mint(address target) external {
        Setter(target).mint();
    }

    function _setVotingDelay(address target, uint256 newVotingDelay) external {
        Setter(target)._setVotingDelay(newVotingDelay);
    }

     function swapOracle(address target, uint256 oracleIndex) external {
        Setter(target).swapOracle(oracleIndex);
    }

    function ScheduleChangeTrustedOracle(
        address target,
        ChangeType changeType,
        uint256 oracleIndex,
        address newOracle
    ) external {
        Setter(target).ScheduleChangeTrustedOracle(
            changeType,
            oracleIndex,
            newOracle
        );
    }

    function executeChange(address target) external {
        Setter(target).executeChange();
    }

    function cancelChange(address target) external {
        Setter(target).cancelChange();
    }
}