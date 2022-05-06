/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

pragma solidity ^0.8.13;

type alert is uint;

contract bugged {
    mapping (alert => function() external) public functions; 
    mapping (address => function() external returns (function() external returns (alert))) public more_functions; 
    
    function bar(function() external returns (function() external) a) external returns (function() external[] memory)  {
        function() external[] memory x;
        x[0] = a();
        return x;
    }

    function foo(function() external returns (uint) f)  external returns (uint) {
        return f();
    }

    function blah(function(alert) external) external {}
}