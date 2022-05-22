/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// File: contracts/IOmniDataGateway.sol


pragma solidity 0.8.9;

interface IOmniDataGateway {
    event OmniEvent(address indexed contractAddress, string indexed cid);
    event OmniEvent(address indexed contractAddress, bytes32 indexed uniqueId, string indexed cid);
    event OmniEvent(address indexed contractAddress, uint256 indexed uniqueId, string indexed cid);

    function triggerEvent(address contractAddress, string calldata cid) external;
    function triggerEvent(address contractAddress, bytes32 uniqueId, string calldata cid) external;
    function triggerEvent(address contractAddress, uint256 uniqueId, string calldata cid) external;
}

// File: contracts/OmniDataGateway.sol


pragma solidity 0.8.9;


contract OmniDataGateway is IOmniDataGateway {
    function triggerEvent(address contractAddress, string calldata cid) external {
        emit OmniEvent(contractAddress, cid);
    }

    function triggerEvent(address contractAddress, bytes32 uniqueId, string calldata cid) external {
        emit OmniEvent(contractAddress, uniqueId, cid);
    }

    function triggerEvent(address contractAddress, uint256 uniqueId, string calldata cid) external {
        emit OmniEvent(contractAddress, uniqueId, cid);
    }
}