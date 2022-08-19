/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface INearBridge {
    event BlockHashAdded(uint64 indexed height, bytes32 blockHash);
    event BlockHashReverted(uint64 indexed height, bytes32 blockHash);

    function blockHashes(uint64 blockNumber) external view returns (bytes32);
    function blockMerkleRoots(uint64 blockNumber) external view returns (bytes32);
    function balanceOf(address wallet) external view returns (uint256);
    function deposit() external payable;
    function withdraw() external;
    function initWithValidators(bytes calldata initialValidators) external;
    function initWithBlock(bytes calldata data) external;
    function addLightClientBlock(bytes calldata data) external;
    function challenge(address payable receiver, uint256 signatureIndex) external;
    function checkBlockProducerSignatureInHead(uint256 signatureIndex) external view returns (bool);

    function lastValidAt() external view returns (uint);
    function lockDuration() external view returns (uint256);
}

contract InternalTest {

    address public owner;
    INearBridge public bridge;

    constructor(address bridge_) {
        owner = msg.sender;
        bridge = INearBridge(bridge_);
    }

    fallback() external payable {}
    receive() external payable {}

    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    function depositAndAddLightClientBlock(bytes memory data) public payable onlyOwner {
        require(msg.value > 0, "first value error");

        uint temp_lastValidAt = bridge.lastValidAt();
        require(block.timestamp >= temp_lastValidAt && temp_lastValidAt != 0, "pre data error");

        bridge.deposit{value: msg.value}();
        bridge.addLightClientBlock(data);

        require(bridge.lastValidAt() == block.timestamp + bridge.lockDuration(), "time error");
        require(bridge.balanceOf(address(this)) == msg.value, "value error");
    }

    function withdraw() public onlyOwner {
        require(bridge.balanceOf(address(this)) > 0, "value error");
        bridge.withdraw();
    }

    function destory() public onlyOwner {
        selfdestruct(payable(owner));
    }
}