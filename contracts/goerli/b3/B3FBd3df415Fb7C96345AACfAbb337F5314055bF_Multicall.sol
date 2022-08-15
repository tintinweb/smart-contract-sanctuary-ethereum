// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Multicall {
    struct MultiCall {
        address target;
        bytes data;
    }

    function multicall(MultiCall[] memory calls)
        public
        returns (bytes[] memory)
    {
        bytes[] memory res = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory data) = calls[i].target.call(
                calls[i].data
            );
            require(success);
            res[i] = data;
        }
        return res;
    }

    function getEthBalance(address user) public view returns (uint256) {
        return user.balance;
    }

    function getEthBalances(address[] memory users) public view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            res[i] = users[i].balance;
        }
        return res;
    }

    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
}