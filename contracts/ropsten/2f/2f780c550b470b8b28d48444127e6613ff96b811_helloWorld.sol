/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.7;

contract helloWorld{
   
    bytes32 namex;
    function setNmae(bytes32 _name) public {
        namex = _name;
    }

    // function getName() public view returns(bytes32){
    //     return(namex);
    // }
function testOne(string memory _index, uint32 _inxa, uint32 _outxa)public view returns(string memory, string memory, uint256){
uint32 krake = _inxa + _outxa;
string memory strinx = string(abi.encodePacked(namex));
return (strinx, _index, krake);
}
    }