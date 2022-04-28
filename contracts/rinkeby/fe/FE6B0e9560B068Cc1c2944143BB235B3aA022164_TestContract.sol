/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SolaClaim {
    function withdrawClaim(uint amount, bytes32 _hash, bytes memory _signature) external;
    function checkAddress(address addr) external view returns (bool);
    function isContract(address _addr) external view returns (bool);
}

contract TestContract {
    function interactWithSolaClaim(address addr, uint amount, bytes32 _hash, bytes memory _signature) external {
        SolaClaim SC = SolaClaim(addr);
        SC.withdrawClaim(amount, _hash, _signature);
    }
}