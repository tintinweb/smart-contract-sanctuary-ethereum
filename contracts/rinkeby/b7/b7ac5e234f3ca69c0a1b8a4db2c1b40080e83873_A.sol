/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

pragma solidity 0.8.0 ;

contract A {

    uint a;
    uint [] array;
    string [] sarray;
   
   function pushString(string memory s) public {
        sarray.push(s);
   }

    function getString(uint _n) public view returns(string memory) {
        return sarray[_n-1];
    }
    function getArrayLength() public view returns(uint) {
        return array.length;
    }

    
    function lastNumber() public view returns(uint) {
        return array[array.length-1];
    }
}