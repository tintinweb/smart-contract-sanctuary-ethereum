/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

pragma solidity ^0.6.7;

abstract contract Setter {
    function setOwner(address) external virtual;
    function setDelay(uint) external virtual;
}

contract PauseActions {

    function setOwner(address target, address newOwner) public {
        Setter(target).setOwner(newOwner);
    }    

    function setDelay(address target, uint val) public {
        Setter(target).setDelay(val);
    }        

    function codeHash(address who) public view returns (bytes32 hash) {
        assembly {
            hash := extcodehash(who)
        }
    }
}