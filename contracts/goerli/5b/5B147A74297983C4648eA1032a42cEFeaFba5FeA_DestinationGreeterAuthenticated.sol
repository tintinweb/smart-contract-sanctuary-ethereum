// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IXReceiver {
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  ) external returns (bytes memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { IXReceiver } from "@connext/smart-contracts/contracts/core/connext/interfaces/IXReceiver.sol";

contract DestinationGreeterAuthenticated is IXReceiver {
    address public immutable connext;
    uint32 public immutable originDomain;
    address public immutable source;
    string public greeting;

    modifier onlySource(address _originSender, uint32 _origin) {
        require(_origin == originDomain && _originSender == source && msg.sender == connext, "Expected original caller to be source contract on origin domain and this to be called by Connext");
        _;
    }

    constructor(uint32 _originDomain, address _source, address _connext) {
        originDomain = _originDomain;
        source = _source;
        connext = _connext;
    }

    function xReceive(bytes32 _transferId, uint256 _amount, address _asset, address _originSender, uint32 _origin, bytes memory _callData) external onlySource(_originSender, _origin) returns (bytes memory) {
        string memory newGreeting = abi.decode(_callData, (string));
        _updateGreeting(newGreeting);
    }

    function _updateGreeting(string memory newGreeting) internal {
        greeting = newGreeting;
    }
}