// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract A {
    uint256 public num;
    address public user;

    function delegateSetNum(address _addr, uint256 _num) public {
        // bytes memory data
        (bool success,) = 
        _addr.delegatecall(
            abi.encodeWithSignature("setNum(uint256)", _num)
        );
        require(success, "failed");
    }
}