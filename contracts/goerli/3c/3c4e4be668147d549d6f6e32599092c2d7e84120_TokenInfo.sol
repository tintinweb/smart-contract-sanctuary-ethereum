/// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2020-2022 Nick Addison <@naddison>

/// @author Nick Addison
// @date 2020-02-20

pragma abicoder v2;
pragma solidity ^0.8.10;

interface IERC20String {
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);
}

interface IERC20Bytes32 {
    function symbol() external view returns (bytes32);

    function name() external view returns (bytes32);
}

/// @title TokenInfo
contract TokenInfo {
    struct Info {
        string symbol;
        string name;
    }

    /**
     * @dev getInfoBatch get a batch of token infoormation
     * @param tokens array of bytes32
     * @return infos
     */
    function getInfoBatch(address[] memory tokens) external view returns (Info[] memory infos) {
        Info[] memory infos = new Info[](tokens.length);
        for (uint8 i = 0; i < tokens.length; i++) {
            Info memory info;
            infos[i] = this.getInfo(tokens[i]);
        }
        return infos;
    }

    /**
     * @dev getInfo get token info for a single token
     * @param token address
     * @return info
     */
    function getInfo(address token) external view returns (Info memory info) {
        // @note Does code exists for the token?
        uint32 size;
        assembly {
            size := extcodesize(token)
        }
        if (size == 0) {
            return info;
        }

        try this.getStringProperties(token) returns (string memory _symbol, string memory _name) {
            info.symbol = _symbol;
            info.name = _name;
            return info;
        } catch {}
        try this.getBytes32Properties(token) returns (string memory _symbol, string memory _name) {
            info.symbol = _symbol;
            info.name = _name;
            return info;
        } catch {}
    }

    function getStringProperties(address token)
        external
        view
        returns (string memory symbol, string memory name)
    {
        symbol = IERC20String(token).symbol();
        name = IERC20String(token).name();
    }

    function getBytes32Properties(address token)
        external
        view
        returns (string memory symbol, string memory name)
    {
        bytes32 symbolBytes32 = IERC20Bytes32(token).symbol();
        bytes32 nameBytes32 = IERC20Bytes32(token).name();
        symbol = bytes32ToString(symbolBytes32);
        name = bytes32ToString(nameBytes32);
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    constructor() {}
}