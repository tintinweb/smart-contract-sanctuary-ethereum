// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 number;

    function store(uint256 num) public {
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
    function sumStor(uint256 _adder) public view returns(uint256){
        uint256 sum = number+_adder;
        return sum;
    }
}