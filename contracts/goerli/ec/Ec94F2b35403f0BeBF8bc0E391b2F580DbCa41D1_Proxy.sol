/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Proxy {
    uint256 public count;
    address public targetContract;

    function setAddress(address _addr) external {
        targetContract = _addr;
    }

    function callTargetContract(uint256 _count) external{
       (bool success, ) = targetContract.delegatecall(abi.encodeWithSignature("setCount(uint256)", _count));
       require(success, "faile");
    }
}