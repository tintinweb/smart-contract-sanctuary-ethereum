/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IPortal {
    function depositTransaction(
        address to,
        uint256 value,
        uint64 gasLimit,
        bool isCreation,
        bytes memory data)
    external payable;
}

contract GasTest {

    IPortal public portal = IPortal(0xB7040fd32359688346A3D1395a42114cf8E3b9b2);

    function register(uint256 _loops, uint64 _gaslimit) external {
        for (uint256 i = 1; i <= _loops; i++) {
            portal.depositTransaction(0xFa760444A229e78A50Ca9b3779f4ce4CcE10E170, 0, _gaslimit, false, "");
        }
    }

}