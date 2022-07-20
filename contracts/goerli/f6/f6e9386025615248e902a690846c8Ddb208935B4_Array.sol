pragma solidity ^0.8.9;

contract Array{
    uint[] public arr;

    function get(uint i) public view returns(uint){
        return arr[i];
    }

    function getLength() public view returns (uint){
        return arr.length;
    }

    function push(uint i) public{
        //Append to array
        arr.push(i);
    }

    function pop() public{
        //Remove last element from array
        arr.pop();
    }

    function remove(uint index) public{
        require(index < arr.length, "Index out of bounds!");

        //Delete resets the value at index to it's default value, in this case 0
        delete arr[index];
    }
}