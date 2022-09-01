pragma solidity =0.8.9;

contract Foo {
    function bar(bytes3[2] memory) public pure {}

    function baz(uint32 x, bool y) public pure returns (bool r) {
        r = x > 32 || y;
    }

    function sam(
        bytes memory,
        bool,
        uint256[] memory
    ) public pure {}
}