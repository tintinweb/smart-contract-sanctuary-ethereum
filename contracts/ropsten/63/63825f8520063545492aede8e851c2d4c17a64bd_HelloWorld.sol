/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity >=0.4.22 <0.9.0;
contract HelloWorld {
    uint256 counter = 5; //state variable we assigned earlier
    function add() public { //increases counter by 1
        counter++;
    }
    function subtract() public { //decreases counter by 1
        counter--;
    }
    function getCounter() public view returns (uint256) {
        return counter;
    }
}