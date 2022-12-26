/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

pragma solidity >=0.5.0 <0.9.0;

contract local {
    uint256 public age = 10;
    uint256 public constructor_will_change_me;

    constructor(uint256 x) {
        constructor_will_change_me = x;
    }

    function getter() public view returns (uint256) {
        return age;
    }

    function setter(uint256 newage) public {
        age = newage;
    }
}