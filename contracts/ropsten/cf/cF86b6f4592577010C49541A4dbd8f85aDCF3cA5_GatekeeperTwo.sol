pragma solidity ^0.4.18;

contract GatekeeperTwo {

    address public entrant;

    modifier gateOne() {
        require(msg.sender == tx.origin);
        _;
    }

    modifier gateTwo() {
        uint x;
        assembly {x := extcodesize(caller)}
        require(x == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint64(keccak256(msg.sender)) ^ uint64(_gateKey) == uint64(0) - 1);
        _;
    }

    function enter(bytes8 _gateKey, address to) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        suicide(entrant);
        return true;
    }
    
    function () payable public {
        
    }
}