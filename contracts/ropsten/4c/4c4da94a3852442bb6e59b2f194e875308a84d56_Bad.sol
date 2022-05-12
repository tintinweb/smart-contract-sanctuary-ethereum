pragma solidity ^0.4.10;

contract Bad {
    
    function doFail() public {
        require(false, "It's fail, bro!");
    }
}