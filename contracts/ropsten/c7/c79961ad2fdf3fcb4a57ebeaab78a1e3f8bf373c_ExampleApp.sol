/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

pragma solidity ^0.4.18;

contract ExampleApp {

    string[]  myArray;

    function add(string x) public {
        myArray.push(x);
       
    }


    function del(string x) public {
        for (uint j = 0; j < myArray.length; j++) {
        if (keccak256(abi.encodePacked(myArray[j])) == keccak256(abi.encodePacked(x))) {

                delete myArray[j];
        }
        }
   
    }

    function show() public view returns (uint256, string) {
        string memory str;
        for (uint j = 0; j < myArray.length; j++) {
            str = string(abi.encodePacked(str, myArray[j]));

        }

        return(myArray.length,str);
    }

}