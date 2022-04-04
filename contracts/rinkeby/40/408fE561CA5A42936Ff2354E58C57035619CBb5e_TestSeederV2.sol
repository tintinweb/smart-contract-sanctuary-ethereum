// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ISeederV2.sol';

// Originally deployed at https://etherscan.io/address/0x2Ed251752DA7F24F33CFbd38438748BB8eeb44e1
contract TestSeederV2 is ISeederV2 {
    uint256 batch;
    mapping(uint256 => bytes32) batchToReqId;

    function setBatch(uint256 batch_) external {
        batch = batch_;
    }

    function setBatchToReqId(uint256 batch_, bytes32 reqId) external {
        batchToReqId[batch_] = reqId;
    }
    function executeRequestMulti() external {
        batch = batch + 1;
        batchToReqId[batch] = keccak256(abi.encodePacked(batch));
    }

    function getBatch() external override view returns (uint256) {
	    return batch;
    }
    function getReqByBatch(uint256 batch_) external override view returns (bytes32) {
        return batchToReqId[batch_];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Originally deployed at https://etherscan.io/address/0x2Ed251752DA7F24F33CFbd38438748BB8eeb44e1
interface ISeederV2 {
    function getBatch() external view returns (uint256);
    function getReqByBatch(uint256 batch) external view returns (bytes32);
}