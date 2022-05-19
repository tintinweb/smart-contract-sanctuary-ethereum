// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interface/external/ILandRegistry.sol";

contract NewMockLand is ILandRegistry {
    // solhint-disable-next-line
    uint256 constant clearLow =
        0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
    // solhint-disable-next-line
    uint256 constant clearHigh =
        0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    // solhint-disable-next-line
    uint256 constant factor = 0x100000000000000000000000000000000;

    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public updateOperator;
    mapping(address => mapping(uint256 => address)) public approvals;
    mapping(address => uint256[]) internal _assetsOf;

    function mint(int256 x, int256 y) external {
        uint256 assetId = _encodeTokenId(x, y);
        require(ownerOf[assetId] == address(0), "Already minted");
        ownerOf[assetId] = msg.sender;
        updateOperator[assetId] = msg.sender;
        uint256[] storage assets = _assetsOf[msg.sender];
        assets.push(assetId);
    }

    function approve(address to, uint256 assetId) external override {
        approvals[msg.sender][assetId] = to;
    }

    function transferFrom(
        address from,
        address to,
        uint256 assetId
    ) external override {
        require(ownerOf[assetId] == from, "Not owner");
        require(
            approvals[from][assetId] == msg.sender || from == msg.sender,
            "Not approved"
        );
        ownerOf[assetId] = to;
        updateOperator[assetId] = to;
    }

    function setUpdateOperator(uint256 assetId, address operator)
        external
        override
    {
        require(ownerOf[assetId] == msg.sender, "Not owner");
        updateOperator[assetId] = operator;
    }

    function tokensOf(address addr)
        external
        view
        override
        returns (uint256[] memory)
    {
        return _assetsOf[addr];
    }

    function encodeTokenId(int256 x, int256 y) external pure returns (uint256) {
        return _encodeTokenId(x, y);
    }

    function decodeTokenId(uint256 value)
        external
        pure
        returns (int256, int256)
    {
        return _decodeTokenId(value);
    }

    function _encodeTokenId(int256 x, int256 y)
        internal
        pure
        returns (uint256 result)
    {
        // solhint-disable-next-line
        require(
            -1000000 < x && x < 1000000 && -1000000 < y && y < 1000000,
            "The coordinates should be inside bounds"
        );
        return _unsafeEncodeTokenId(x, y);
    }

    function _unsafeEncodeTokenId(int256 x, int256 y)
        internal
        pure
        returns (uint256)
    {
        return ((uint256(x) * factor) & clearLow) | (uint256(y) & clearHigh);
    }

    function _unsafeDecodeTokenId(uint256 value)
        internal
        pure
        returns (int256 x, int256 y)
    {
        x = expandNegative128BitCast((value & clearLow) >> 128);
        y = expandNegative128BitCast(value & clearHigh);
    }

    function _decodeTokenId(uint256 value)
        internal
        pure
        returns (int256 x, int256 y)
    {
        (x, y) = _unsafeDecodeTokenId(value);
        // solhint-disable-next-line
        require(
            -1000000 < x && x < 1000000 && -1000000 < y && y < 1000000,
            "The coordinates should be inside bounds"
        );
    }

    // solhint-disable-next-line
    function expandNegative128BitCast(uint256 value)
        internal
        pure
        returns (int256)
    {
        if (value & (1 << 127) != 0) {
            return int256(value | clearLow);
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILandRegistry {
    function approve(address to, uint256 assetId) external;

    function transferFrom(
        address from,
        address to,
        uint256 assetId
    ) external;

    function setUpdateOperator(uint256 assetId, address operator) external;

    function tokensOf(address addr) external view returns (uint256[] memory);
}