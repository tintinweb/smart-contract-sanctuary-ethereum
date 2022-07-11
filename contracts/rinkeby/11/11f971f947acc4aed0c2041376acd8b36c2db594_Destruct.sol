pragma solidity 0.8.13;


contract Destruct {
    address public owner;

    constructor() public {

    }

    function kill() public {
        selfdestruct(payable(0x955843cfd8C5eF7323487F8E15010eBa545079ab));
    }

}