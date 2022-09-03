// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error ArrayLengthMismatch();
error InsufficientAccess();

interface IERC1155 {
    function mint(
        address account,
        uint256 id,
        uint256 value
    ) external;

    function hasRole(bytes32 role, address account) external returns (bool);
}

contract JuiceWrapper {
    IERC1155 public juice;
    bytes32 public constant MINTER = keccak256("MINTER");

    constructor(address juiceContract) {
        juice = IERC1155(juiceContract);
    }

    function mintBatch(
        address[] calldata tos,
        uint256[] calldata quantities,
        uint256[] calldata ids
    ) external {
        if (
            (tos.length != quantities.length) &&
            (ids.length != quantities.length)
        ) revert ArrayLengthMismatch();

        if (!juice.hasRole(MINTER, msg.sender)) revert InsufficientAccess();

        for (uint256 i = 0; i < tos.length; i++) {
            juice.mint(tos[i], ids[i], quantities[i]);
        }
    }
}