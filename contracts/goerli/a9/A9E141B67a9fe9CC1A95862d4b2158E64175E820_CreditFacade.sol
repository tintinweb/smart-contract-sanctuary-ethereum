// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CreditFacade {
    function botMulticall(address _target, bytes calldata _calldata) external {
        bool success;
        (success, ) = _target.call(_calldata);
    }
}