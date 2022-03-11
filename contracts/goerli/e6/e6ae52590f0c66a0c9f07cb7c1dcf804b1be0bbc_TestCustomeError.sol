/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

pragma solidity >=0.8.10;

contract TestCustomeError {
    uint256 public k;

    error FooError();
    error BarError(uint256);

    function f() public {
        uint x = 0;
        x--;
        k += 1;
    }

    function foo(uint256 i) external {
        k += 1;
        if (i > 10) {
            revert FooError();
        } else {
            revert BarError(i);
        }
    }
}