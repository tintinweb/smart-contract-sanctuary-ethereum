/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

pragma solidity >0.8.13;

contract FirstToken {

string TestString = "Ma vezi ?";
uint256 TestUINT = 69;

function getUint () public view returns (uint256) {
return TestUINT;
}


function getString () public view returns (string memory) {
return TestString;
}


}