/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


interface ITellor{
    function submitValue(bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external;
    function getAddressVars(bytes32 _data) external view returns (address);
    function depositStake() external;
    function requestStakingWithdraw() external;
    function getCurrentReward(bytes32 _queryId) external view returns(uint256, uint256);
    function transfer(address _to, uint256 _amount)external returns (bool success);
    function withdrawStake() external;
}

contract Reporter {
    ITellor public tellor;
    ITellor public oracle;
    address public owner;
    uint256 public profitThreshold;//inTRB

    constructor(address _tellorAddress, uint256 _profitThreshold){
        tellor = ITellor(_tellorAddress);
        oracle = ITellor(
            tellor.getAddressVars(
                0xfa522e460446113e8fd353d7fa015625a68bc0369712213a42e006346440891e
            )
        );//keccak256(_ORACLE_CONTRACT)
        owner = msg.sender;
        profitThreshold = _profitThreshold;
    }

        modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    
    function changeOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function depositStake() onlyOwner external{
        tellor.depositStake();
    }

    function requestStakingWithdraw() external onlyOwner {
        tellor.requestStakingWithdraw();
    }

    function submitValue(bytes32 _queryId, bytes memory _value, uint256 _nonce, bytes memory _queryData) onlyOwner external{
        uint256 _reward;
        (,_reward) = oracle.getCurrentReward(_queryId);
        require(_reward > profitThreshold, "profit threshold not met");
        oracle.submitValue(_queryId,_value,_nonce,_queryData);
    }

    function submitValueBypass(bytes32 _queryId, bytes memory _value, uint256 _nonce, bytes memory _queryData) onlyOwner external{
        oracle.submitValue(_queryId,_value,_nonce,_queryData);
    }

    function transfer(address _to, uint256 _amount) external onlyOwner{
        tellor.transfer(_to,_amount);
    }

    function withdrawStake() onlyOwner external{
        tellor.withdrawStake();
    }
}