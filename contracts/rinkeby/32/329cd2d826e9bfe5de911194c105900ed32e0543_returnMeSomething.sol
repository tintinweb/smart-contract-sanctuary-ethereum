/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

pragma solidity 0.8.0;

contract returnMeSomething {

    uint256 first;
    uint256 second;

    function returnMeSingle() public pure returns (string memory) {
        return "HERE I AM WITH A TEST CASE";
    }

    function returnMeDouble() public pure returns (string memory) {
        return "HERE I AM WITH ANOTHER TEST CASE BUT THIS ONE IS A LOT LONGER AND MAY CAUSE PROBLEMS WITH A MERE 64 HEX-BYTE CHARACTER.";
    }

    function returnMeSingleTrigger() public returns (string memory) {
        first = first + 1;
        return "HERE I AM WITH A TEST CASE";
    }

    function returnMeDoubleTrigger() public returns (string memory) {
        second = second + 1;
        return "HERE I AM WITH ANOTHER TEST CASE BUT THIS ONE IS A LOT LONGER AND MAY CAUSE PROBLEMS WITH A MERE 64 HEX-BYTE CHARACTER.";
    }

    function test() public pure returns (string[3] memory) {
        return ["aaa","bbbb","HERE I AM WITH ANOTHER TEST CASE BUT THIS ONE IS A LOT LONGER AND MAY CAUSE PROBLEMS WITH A MERE 64 HEX-BYTE CHARACTER."];
    }
}