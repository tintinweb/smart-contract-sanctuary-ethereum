/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

pragma solidity 0.8.7;

contract TestLoop{

uint256 a;
uint256 b;


function TestIt() public {


for(uint256 i = 0; i < 10; i++) {

a+= a;

for (uint256 j = 0; j < 5; j++)

b+= b;
}

}


function QueryA() public view returns (uint256){
return a;
}


function QueryB() public view returns (uint256){
return b;
}
}