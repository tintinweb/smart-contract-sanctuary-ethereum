pragma solidity ^0.8.4;

// [[1,2],[6,9],[2323,10,11,12]]

contract Test {

    // uint[3][2] data;

    constructor() {
    //   data[0] = [1,2,3,5,6];
    //   data[1] = [4,5,6];
    }

    // function length() public view returns (uint) {
    //   return data.length;
    // }

    // function length(uint i) public view returns (uint) {
    //   return data[i].length;
    // }


    function lengthOfArray(uint[][] memory _data) public view returns (uint) {
      return _data.length;
    }

    function lengthOfNestArrayByIndex(uint[][] memory _data, uint i) public view returns (uint) {
      return _data[i].length;
    }

}