/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Test {

uint256 public a;

function tryTest(uint x, uint y) external {
   a = x - y;
   require(a > 20 , 'Wrong Number');
}

}