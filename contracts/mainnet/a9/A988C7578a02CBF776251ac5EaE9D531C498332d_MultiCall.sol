/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
  ------------------------------------------------------------------------------------------------------
  |   ███████████          █████                          █████   █████  ███                           |
  |  ░█░░░███░░░█         ░░███                          ░░███   ░░███  ░░░                            |
  |  ░   ░███  ░   ██████  ░███ █████  ██████  ████████   ░███    ░███  ████   ██████  █████ ███ █████ |
  |      ░███     ███░░███ ░███░░███  ███░░███░░███░░███  ░███    ░███ ░░███  ███░░███░░███ ░███░░███  |
  |      ░███    ░███ ░███ ░██████░  ░███████  ░███ ░███  ░░███   ███   ░███ ░███████  ░███ ░███ ░███  |
  |      ░███    ░███ ░███ ░███░░███ ░███░░░   ░███ ░███   ░░░█████░    ░███ ░███░░░   ░░███████████   |
  |      █████   ░░██████  ████ █████░░██████  ████ █████    ░░███      █████░░██████   ░░████░████    |
  |     ░░░░░     ░░░░░░  ░░░░ ░░░░░  ░░░░░░  ░░░░ ░░░░░      ░░░      ░░░░░  ░░░░░░     ░░░░ ░░░░     |
  -------------------------------------Created by Tokenview------------------------------------------ 
                                          
*/
contract MultiCall {

    // 通用MultiCall
    function commonMultiCall(address[] calldata targets, bytes[] calldata data)
        external
        view
        returns (bytes[] memory)
    {
        require(targets.length == data.length, "target length != data length");
        bytes[] memory results = new bytes[](data.length);
        for (uint i; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].staticcall(data[i]);
            // require(success, "call failed");
            if (success){
                results[i] = result;
            } else {
                results[i] = "call failed";
            }
        }
        return results;
    }

    // 批量获取地址余额
    function getBalances(address[] calldata addrs)
        public 
        view 
        returns (uint256[] memory) 
    {
        uint256[] memory results = new uint256[](addrs.length);
        for (uint i; i < addrs.length; i++) {
            results[i] = addrs[i].balance;
        }
        return results;
    }

    // 批量获取合约code
    function getContractCodes(address[] calldata targets)
        public
        view
        returns (bytes[] memory)
    {
        bytes[] memory results = new bytes[](targets.length);
        for (uint i; i < targets.length; i++) {
            (bytes memory result) = targets[i].code;
            results[i] = result;
        }
        return results;
    }

}