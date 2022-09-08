//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract BoxV3{
    uint256 private value;
    string rec;
    event ValueChanged(uint256 newValue);
   
    function store(uint256 newValue) public{
        value=newValue;
        emit ValueChanged(value);
    }
  function nijednaRec(string memory _rec) public {
        rec=_rec;
    }
   
    function retrieve()public view returns (uint256){

        return value;
    }
     function read()public view returns(string memory){
        return rec;
    }
    function increment() public {
       value=value+1;
        emit ValueChanged(value);
    }
    function decrement()public {
        value=value-1;
        emit ValueChanged(value);
    }
}