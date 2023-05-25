//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Structs.sol";

interface ILiquidityPool {
    function swap(address, uint256, ToChainData memory) external payable;

    function release(address, uint256, address) external;
}

pragma solidity ^0.8.7;

struct FromChainData {
    address _fromToken;
    address _toToken;
    uint256 _amount;
    bytes _extraParams;
}

struct ToChainData {
    uint toChainId;
    address _fromToken;
    address _toToken;
    address _destination;
    address _receiver;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IEndpoint.sol";
import "./IReceiver.sol";
import "../liquidity-pool/ILiquidityPool.sol";

contract Endpoint is IEndpoint, IReceiver {
    address public LiquidityPool;

    constructor(address _liquidityPool) {
        LiquidityPool = _liquidityPool;
    }

    error InvalidAddress();

    event SendMessage(
        uint256 _nonce,
        address _destinationAddress,
        uint256 _destinationChainId,
        bytes _payload
    );

    event ReceiveMessage(
        uint16 _srcChainId,
        address _toToken,
        uint256 _amount,
        address _receiver
    );

    /// @notice This function is responsible for sending messages to destination chain
    /// @param _nonce nonce
    /// @param _destinationAddress Address of destination contract to send message on
    /// @param _destinationChainId chain id of destination chain
    /// @param _payload Address of destination contract to send message on
    function sendMessage(
        uint256 _nonce,
        address _destinationAddress,
        uint256 _destinationChainId,
        bytes calldata _payload
    ) external payable {
        if (_destinationAddress == address(0)) revert InvalidAddress();
        emit SendMessage(
            _nonce,
            _destinationAddress,
            _destinationChainId,
            _payload
        );
    }

    function receiveMessage(
        uint16 _srcChainId,
        address _toToken,
        uint256 _amount,
        address _receiver
    ) external {
        ILiquidityPool(LiquidityPool).release(_toToken, _amount, _receiver);

        emit ReceiveMessage(_srcChainId, _toToken, _amount, _receiver);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IEndpoint {
    /// @notice This function is responsible for sending messages to destination chain
    /// @param _nonce nonce
    /// @param _destinationAddress Address of destination contract to send message on
    /// @param _destinationChainId chain id of destination chain
    /// @param _payload Address of destination contract to send message on
    function sendMessage(
        uint256 _nonce,
        address _destinationAddress,
        uint256 _destinationChainId,
        bytes calldata _payload
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IReceiver {
    function receiveMessage(
        uint16 _srcChainId,
        address _fromToken,
        uint256 _amount,
        address _receiver
    ) external;
}