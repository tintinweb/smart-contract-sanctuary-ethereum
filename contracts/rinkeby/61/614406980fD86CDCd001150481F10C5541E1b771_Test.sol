/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

pragma solidity 0.8.4;

contract Test{

    uint256 public value;

    function reset() external {
        value = 0;
    }

    function test(uint256 _value) external {
        require(value == 0, "Value already set");
        value = _value;
    }

}