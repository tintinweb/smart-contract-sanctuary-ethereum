// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IUpgradeableProxy {
    function upgradeTo(address newImplementation) external;
}

interface IAMB {
    function requireToPassMessage(
        address _contract,
        bytes calldata _data,
        uint256 _gas
    ) external returns (bytes32);
}

contract NovaUpgradeProposal {
    event MessagePassed(bytes32 msgId);

    address public immutable novaProxy;
    address public immutable newNovaImpl;
    IAMB public immutable bridge;
    uint256 public immutable gasLimit;

    constructor(
        address _novaProxy,
        address _newNovaImpl,
        address _bridge,
        uint256 _gasLimit
    ) public {
        novaProxy = _novaProxy;
        newNovaImpl = _newNovaImpl;
        bridge = IAMB(_bridge);
        gasLimit = _gasLimit;
    }

    function executeProposal() external {
        bytes4 methodSelector = IUpgradeableProxy(address(0)).upgradeTo.selector;
        bytes memory data = abi.encodeWithSelector(methodSelector, newNovaImpl);
        bytes32 msgId = bridge.requireToPassMessage(novaProxy, data, gasLimit);
        emit MessagePassed(msgId);
    }
}