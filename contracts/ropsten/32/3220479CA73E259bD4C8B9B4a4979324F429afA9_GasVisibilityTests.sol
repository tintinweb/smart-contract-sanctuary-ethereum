/**
 *Submitted for verification at Etherscan.io on 2022-04-22
*/

pragma solidity ^0.8.13;

contract GasVisibilityTests {
    uint public publicValue;
    uint private privateValue;
    uint internal internalValue;

    // public variebles tests
    function publicFuncTest() public {
        publicValue = 100; // transaction cost 23444 gas
    }

    function privateFuncTest() private {
        publicValue = 100; // transaction cost 22138 gas
    }

    function internalFuncTest() internal {
        publicValue = 100; // transaction cost 22138 gas
    }

    function externalFuncTest() external {
        publicValue = 100; // transaction cost 23423 gas
    }

    // private variebles tests
    function publicFuncTest1() public { 
        privateValue = 100; // transaction cost 43388 gas
    }

    function privateFuncTest1() private {
        privateValue = 100; // transaction cost 22138 gas
    }

    function internalFuncTest1() internal {
        privateValue = 100; // transaction cost 22138 gas
    }

    function externalFuncTest1() external { 
        privateValue = 100; // transaction cost	23410 gas
    }

    // internal variebles tests
    function publicFuncTest2() public {
        internalValue = 100; // transaction cost 43345 gas
    }

    function privateFuncTest2() private {
        internalValue = 100; // transaction cost 22138 gas
    }

    function internalFuncTest2() internal {
        internalValue = 100; // transaction cost 22138 gas
    }

    function externalFuncTest2() external {
        internalValue = 100; // transaction cost 23466 gas
    }


    // calls private & internal funcs
    function test22() public {
        internalFuncTest();
    }
}