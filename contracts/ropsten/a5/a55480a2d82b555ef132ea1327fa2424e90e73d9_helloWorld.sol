/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.7;

contract helloWorld{
   
    string strinx;
    function setNmae(string memory _name) public {
      strinx = _name;
    }

    // function getName() public view returns(bytes32){
    //     return(namex);
    // }
function testOne(string memory _index, uint32 _inxa, uint32 _outxa)public view returns(string memory, string memory, uint32){
uint32 krake = _inxa + _outxa;
return (strinx, _index, krake);
}
    }