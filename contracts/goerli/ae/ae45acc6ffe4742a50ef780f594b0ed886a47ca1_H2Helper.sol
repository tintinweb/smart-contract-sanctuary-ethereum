// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error H2Helper__Nope();
error H2Helper__NopeCall();

contract H2Helper {
    uint256 public s_variable = 0;
    uint256 public s_otherVar = 0;

    function callContract(address yourAddress) public returns (bool) {
        (bool success, ) = yourAddress.delegatecall(
            abi.encodeWithSignature("doSomething()")
        );
        require(success);
        if (s_variable != 123) {
            revert H2Helper__NopeCall();
        }
        s_variable = 0;
        return true;
    }

    function callContractAgain(address yourAddress, bytes4 selector)
        public
        returns (bool)
    {
        s_otherVar = s_otherVar + 1;
        (bool success, ) = yourAddress.call(abi.encodeWithSelector(selector));
        require(success);
        if (s_otherVar == 2) {
            return true;
        }
        s_otherVar = 0;
        return false;
    }
}