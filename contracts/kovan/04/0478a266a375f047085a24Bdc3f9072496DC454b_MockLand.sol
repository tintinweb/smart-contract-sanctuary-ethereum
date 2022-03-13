// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MockLand {
    uint256 public totalSupply = 0;
    address public admin = msg.sender;

    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public updateOperator;

    function mint(address to) external {
        require(msg.sender == admin, "no right");
        ownerOf[totalSupply] = to;
        updateOperator[totalSupply] = to;
        totalSupply++;
    }

    // solhint-disable avoid-tx-origin
    function transferFrom(
        address from,
        address to,
        uint256 assetId
    ) external {
        require(from == tx.origin, "wrong from");
        require(ownerOf[assetId] == tx.origin, "no right");
        ownerOf[assetId] = to;
        updateOperator[assetId] = to;
    }

    function setUpdateOperator(uint256 assetId, address operator) external {
        require(ownerOf[assetId] == msg.sender, "no right");
        updateOperator[assetId] = operator;
    }
}