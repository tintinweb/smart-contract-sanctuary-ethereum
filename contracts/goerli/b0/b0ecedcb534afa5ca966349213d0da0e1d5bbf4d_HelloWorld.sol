/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

pragma solidity >= 0.7.0 < 0.9.0;

contract HelloWorld {
    uint256 number;

    function store(uint256 num) public {
        number = num;
    }

    function get() public view returns (uint256) {
        return number;
    }
}