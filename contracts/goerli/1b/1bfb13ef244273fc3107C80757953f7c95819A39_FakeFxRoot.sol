//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface ILandToken {
    function batchTransferQuad(
        address from,
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes calldata data
    ) external;

    function transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "./ILandToken.sol";

interface IPolygonLand is ILandToken {
    function mintQuad(
        address user,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) external;

    function exists(
        uint256 size,
        uint256 x,
        uint256 y
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/interfaces/IPolygonLand.sol";

// solhint-disable

/// @dev This is NOT a secure FxRoot contract implementation!
/// DO NOT USE in production.

interface IFakeFxChild {
    function onStateReceive(
        uint256 stateId,
        address receiver,
        address rootMessageSender,
        bytes memory data
    ) external;
}

/**
 * @title FxRoot root contract for fx-portal
 */
contract FakeFxRoot {
    address fxChild;

    function setFxChild(address _fxChild) public {
        fxChild = _fxChild;
    }

    function sendMessageToChild(address _receiver, bytes calldata _data) public {
        IFakeFxChild(fxChild).onStateReceive(0, _receiver, msg.sender, _data);
    }
}