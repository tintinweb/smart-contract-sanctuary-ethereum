// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.16;

contract Counter {

    uint256 public init;

    constructor(uint256 initialValue) {
        init = initialValue;
    }

    function increment() public {
        init++;
    }

    function decrement() public {
        init--;
    }

    function viewInit() public view returns(uint256){
        return init;
    }

}