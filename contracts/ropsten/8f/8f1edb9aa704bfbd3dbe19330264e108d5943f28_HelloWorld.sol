pragma solidity ^0.6.12;

import "./A.sol";

contract HelloWorld {
    function get() public returns (string memory){
        return HelloWorld.get();
    }
}