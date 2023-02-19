// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../src/interfaces/IRegistration.sol";

contract Registration is IRegistration {
    event OperatorRegistered(
        string ipfsHash,
        uint256 totalKeys,
        uint256 keysUsed
    );
    // user address => IPFS hash
    mapping(address => bytes) public addressToIpfsHash;

    // user address => IPFS hash => number of keys
    mapping(address => uint256) public numberOfKeysUsed;

    // user address => OperaterData Struct
    mapping(address => OperatorData) public addressToOperatorData;

    function increaseKeysIndex(address _user) public {
        numberOfKeysUsed[_user]++;
    }

    function registerNodeOperator(string memory _ipfsHash, uint256 _totalKeys)
        public
    {
        addressToOperatorData[msg.sender] = OperatorData({
            ipfsHash: _ipfsHash,
            totalKeys: _totalKeys,
            keysUsed: 0
        });
        emit OperatorRegistered(
            addressToOperatorData[msg.sender].ipfsHash,
            addressToOperatorData[msg.sender].totalKeys,
            addressToOperatorData[msg.sender].keysUsed
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IRegistration {
    struct OperatorData {
        string ipfsHash;
        uint256 totalKeys;
        uint256 keysUsed;
    }

    function registerNodeOperator(string memory ipfsHash, uint256 totalKeys)
        external;
}