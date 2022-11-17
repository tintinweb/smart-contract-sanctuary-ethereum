/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
}

contract QueryHelper {
    function getBalanceForAddresses(address[] memory queryAddresses)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](queryAddresses.length);
        for (uint256 i = 0; i < queryAddresses.length; i++) {
            result[i] = queryAddresses[i].balance;
        }
        return result;
    }

    function getBalanceForToken(IERC20 token, address[] calldata addrs)
        external
        view
        returns (uint256[] memory)
    {
        uint256 len = addrs.length;
        uint256[] memory result = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = token.balanceOf(addrs[i]);
        }
        return result;
    }

    function getBalanceForToken(IERC20[] calldata tokens, address[] calldata addrs)
        external
        view
        returns (uint256[][] memory)
    {
        uint256 len = tokens.length;
        uint256[][] memory result = new uint256[][](len);
        for (uint256 i = 0; i < len; i++) {
            result[i] = this.getBalanceForToken(tokens[i], addrs);
        }
        return result;
    }

    function query(address addr, bytes[] calldata payloads)
        public
        view
        returns (bytes[] memory)
    {
        uint256 len = payloads.length;
        bytes[] memory returnDataArr = new bytes[](len);
        for (uint256 i = 0; i < len; i++) {
            returnDataArr[i] = _query(addr, payloads[i]);
        }
        return (returnDataArr);
    }

    function query(
        address addr,
        bytes4 sig,
        bytes[] calldata args
    ) public view returns (bytes[] memory) {
        bytes[] memory returnDataArr = new bytes[](args.length);
        for (uint256 i = 0; i < args.length; i++) {
            bytes memory payload = new bytes(args[i].length + 4);
            for (uint256 j = 0; j < 4; j++) {
                payload[j] = sig[j];
            }
            for (uint256 k = 0; k < args[i].length; k++) {
                payload[k + 4] = args[i][k];
            }
            returnDataArr[i] = _query(addr, payload);
        }
        return returnDataArr;
    }

    function _query(address addr, bytes memory payload)
        internal
        view
        returns (bytes memory)
    {
        (, bytes memory returnData) = addr.staticcall(payload);
        return returnData;
    }

    function batchQuery(address[] calldata addrs, bytes[] calldata payloads)
        external
        view
        returns (bytes[][] memory)
    {
        uint256 len = addrs.length;
        bytes[][] memory returnDataArr = new bytes[][](len);
        for (uint256 i = 0; i < len; i++) {
            bytes[] memory returnData = query(addrs[i], payloads);
            returnDataArr[i] = returnData;
        }
        return (returnDataArr);
    }
}