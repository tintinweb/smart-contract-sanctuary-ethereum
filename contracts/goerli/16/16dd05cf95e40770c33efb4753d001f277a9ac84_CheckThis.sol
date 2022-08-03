/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

pragma solidity ^0.8.14;

error BadDenomination(uint256 passedIn, uint256 denomination);

contract CheckThis {
    uint256 public denomination = 1;
    uint256 public accumulator;

    function addSum(uint256 addition) external {
        if (addition % denomination != 0) revert BadDenomination(addition, denomination);
        accumulator += addition;
        denomination += 1;
    }
}