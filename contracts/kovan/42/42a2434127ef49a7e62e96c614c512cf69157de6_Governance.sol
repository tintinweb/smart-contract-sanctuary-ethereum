/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

pragma solidity ^0.6.6;

contract Governance {
    uint256 public one_time;
    address public lottery;
    address public randomness;
    constructor() public {
        one_time = 1;
    }
    function init(address _lottery, address _randomness) public {
        require(_randomness != address(0), "governance/no-randomnesss-address");
        require(_lottery != address(0), "no-lottery-address-given");
        //require(one_time > 0, "can-only-be-called-once");
        //one_time = one_time - 1;
        randomness = _randomness;
        lottery = _lottery;
    }
}