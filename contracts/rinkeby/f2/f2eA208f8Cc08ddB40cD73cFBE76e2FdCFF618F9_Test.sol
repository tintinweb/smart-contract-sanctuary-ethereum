pragma solidity ^0.8.4;

// [[1,2],[6,9],[2323,10,11,12]]

contract Test {

    constructor() {
    }

    function lengthOfArray(uint[][] memory _data) public view returns (uint) {
      return _data.length;
    }

    function lengthOfNestArrayByIndex(uint[][] memory _data, uint i) public view returns (uint) {
      return _data[i].length;
    }

}