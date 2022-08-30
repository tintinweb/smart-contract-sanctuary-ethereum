// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IAnyCall.sol";

contract Source {
    address public owner;
    uint256 public targetChain = 4002;
    address public targetChainAddr;
    address public endpoint = 0x273a4fFcEb31B8473D51051Ad2a2EdbB7Ac8Ce02;

    event BackMsg(address addr);

    modifier OnlyOwner() {
        require(owner == msg.sender, "not owner");

        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setTargetChainAddr(address _addr) external OnlyOwner {
        targetChainAddr = _addr;
    }

    // cross-chain func
    function send(string calldata _msg) external OnlyOwner {
        bytes memory data = abi.encode(_msg);

        IAnyCall(endpoint).anyCall(
            targetChainAddr,
            data,
            address(0),
            targetChain,
            0
        );
    }

    // anycall receive func
    function anyExecute(bytes memory _data)
        external
        returns (bool success, bytes memory result)
    {
        address[] memory msg = abi.decode(_data, (address[]));
        uint256 msgLength = msg.length;

        for (uint256 i = 0; i < msgLength; i++) {
            emit BackMsg(msg[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IAnyCall {
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags
    ) external payable;

    function context()
        external
        view
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );

    function executor() external view returns (address executor);
}