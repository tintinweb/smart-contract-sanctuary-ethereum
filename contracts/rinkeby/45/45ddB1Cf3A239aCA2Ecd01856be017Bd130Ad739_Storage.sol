// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Storage {

    uint256 number;
    bool trust;

    function store(uint256 num) public {
        require(trust == true);
        number = num;
    }

    function set(bool bb) public {
        trust = bb;
    }

    function store1(uint256 num) external {
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }

    constructor() {
        trust = false;
    }
}