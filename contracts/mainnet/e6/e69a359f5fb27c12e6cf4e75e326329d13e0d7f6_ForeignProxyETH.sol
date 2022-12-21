/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAMB {
    function requireToPassMessage(
        address _contract,
        bytes memory _data,
        uint256 _gas
    ) external returns (bytes32);

    function maxGasPerTx() external view returns (uint256);

    function messageSender() external view returns (address);

    function messageSourceChainId() external view returns (bytes32);

    function messageId() external view returns (bytes32);
}

interface IHomeProxy {
  
    function receiveArbitrationRequest() external;

    function handleNotifiedRequest() external;
}

interface IForeignProxy {

    function requestArbitration() external;

    function receiveArbitrationAcknowledgement() external;
}

contract ForeignProxyETH is IForeignProxy {
    enum Status {
        None,
        Requested,
        Created
    }

    IAMB public immutable amb;
    address public homeProxy;
    bytes32 public immutable homeChainId;
    Status public status;

    /* Modifiers */

    modifier onlyHomeProxy() {
        require(msg.sender == address(amb), "Only AMB allowed");
        require(amb.messageSourceChainId() == homeChainId, "Only home chain allowed");
        require(amb.messageSender() == homeProxy, "Only home proxy allowed");
        _;
    }

    constructor(
        IAMB _amb,
        uint256 _homeChainId
    ) {
        amb = _amb;
        homeChainId = bytes32(_homeChainId);
    }

    function requestArbitration() external override {
        bytes4 methodSelector = IHomeProxy.receiveArbitrationRequest.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector);
        amb.requireToPassMessage(homeProxy, data, amb.maxGasPerTx());

        status = Status.Requested;
    }

    function receiveArbitrationAcknowledgement()
        external
        override
        onlyHomeProxy
    {
        status = Status.Created;

    }

    function setDefault() external {
        status = Status.None;
    }

    function setHomeProxy(address _homeProxy) external {
        homeProxy = _homeProxy;
    }
}