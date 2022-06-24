// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import "../interfaces/IActionMsgReceiver.sol";
import "../interfaces/IStateSender.sol";

/***
 * @title MockMsgSender
 * @dev It is assumed to run on the mainnet/Goerli. An EOA can
 * call the `bridgeMessage` function and bridge the message to
 * polygon/mumbai
 */
contract MockMsgSender {
    event MsgBridged(bytes data);

    // solhint-disable var-name-mixedcase

    /// @notice Address of the `FxRoot` contract on the mainnet/Goerli network
    /// @dev `FxRoot` is the contract of the "Fx-Portal" on the mainnet/Goerli.
    address public immutable FX_ROOT;

    /// @notice Address on the MsgRelayer on the Polygon/Mumbai
    address public immutable MSG_RECEIVER;

    /// @param _msgReceiver Address of the MsgRelayer on Polygon/Mumbai
    /// @param _fxRoot Address of the `FxRoot` (PoS Bridge) contract on mainnet/Goerli
    constructor(address _msgReceiver, address _fxRoot) {
        require(_fxRoot != address(0) && _msgReceiver != address(0), "AMS:E01");

        FX_ROOT = _fxRoot;
        MSG_RECEIVER = _msgReceiver;
    }

    function bridgeMessage(uint256 num1, uint256 num2) external {
        bytes memory content = abi.encode(num1, num2);

        IStateSender(FX_ROOT).syncState(MSG_RECEIVER, content);

        emit MsgBridged(content);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IActionMsgReceiver {
    function onAction(bytes4 action, bytes memory message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/***
 * @dev An interface of the `FxRoot` contract
 * `FxRoot` is the contract of the "Fx-Portal" (a PoS bridge run by the Polygon team) on the
 * mainnet/Goerli network. It passes data to s user-defined contract on the Polygon/Mumbai.
 * See https://docs.polygon.technology/docs/develop/l1-l2-communication/fx-portal
 */
interface IStateSender {
    function syncState(address receiver, bytes calldata data) external;
}