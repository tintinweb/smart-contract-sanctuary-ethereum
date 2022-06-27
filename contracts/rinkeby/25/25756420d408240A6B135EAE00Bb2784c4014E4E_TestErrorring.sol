pragma solidity ^0.8.10;

contract TestErrorring{

    error Errorparadigm(string);



    function havingError() public{
        if(true)
            revert Errorparadigm("have error string message");
    }
}