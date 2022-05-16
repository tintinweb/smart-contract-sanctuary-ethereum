/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

interface ITargetContract {
    function tokensOfOwner(address _owner) external returns (uint256[] memory);
}

contract SourceContract {
    uint[] public returnedValue;

    function baz(address _owner) external {
        ITargetContract WorklyRemus = ITargetContract(address(0x45489b29Cf209A88688294515D9333F4fb58B245));
        returnedValue = WorklyRemus.tokensOfOwner(_owner);
    }
}