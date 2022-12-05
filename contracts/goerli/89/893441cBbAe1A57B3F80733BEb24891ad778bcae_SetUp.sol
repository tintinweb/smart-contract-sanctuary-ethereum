/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-28
 */

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SetUp {
    mapping(address => mapping(address => bool)) onlyMasters;
    mapping(address => bytes[]) pubKeys;
    mapping(address => bytes[]) metadatas;
    uint fee;

    address _contractOwner;

    constructor() {
        _contractOwner = msg.sender;
    }

    modifier onlyMaster(address _address) {
        require(onlyMasters[_address][msg.sender], 'sender is not master');
        _;
    }

    modifier onlyOwner() {
        require(_contractOwner == msg.sender, 'sender is not owner');
        _;
    }

    function setMasters(address master_address) external {
        if (master_address == address(0x0)) {
            onlyMasters[msg.sender][msg.sender] = true;
        } else {
            onlyMasters[msg.sender][master_address] = true;
        }
    }

    function setPubKey(address _address, bytes[] memory _pubKey) external {
        if (pubKeys[_address].length != 0) {
            require(
                onlyMasters[_address][msg.sender],
                'Data is set already and sender is not master.'
            );
        } else {
            require(
                onlyMasters[_address][msg.sender] || _address == msg.sender,
                'You cannot set the value for this address.'
            );
        }
        pubKeys[_address] = _pubKey;
    }

    function setMetadata(address _address, bytes[] memory _metadata) external {
        if (metadatas[_address].length != 0) {
            require(
                onlyMasters[_address][msg.sender],
                'Data is set already and sender is not master.'
            );
        } else {
            require(
                onlyMasters[_address][msg.sender] || _address == msg.sender,
                'You cannot set the value for this address.'
            );
        }
        metadatas[_address] = _metadata;
    }

    function getMetadata(
        address _address
    ) external view returns (bytes[] memory _metadata) {
        return metadatas[_address];
    }

    function getPubKey(
        address _address
    ) external view returns (bytes[] memory _pubkey) {
        return pubKeys[_address];
    }

    function setFee(uint new_fee) external onlyOwner {
        fee = new_fee;
    }
}