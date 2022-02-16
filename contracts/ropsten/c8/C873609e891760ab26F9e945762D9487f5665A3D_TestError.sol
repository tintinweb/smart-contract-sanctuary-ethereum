pragma solidity ^0.8.10;

contract TestError{

    error Errorparadigm(string);


    function haveError() public{
        if(true)
            revert Errorparadigm("have error string message");
    }

    function haveRevert ()  public {
        revert();
    }

    function haveRevertMessage ()  public {
        revert("revert with message");
    }

    function haveRequire ()  public {
        require(false);
    }


     function haveRequireMessage ()  public {
        require(false,"require with message");
    }

    function haveAssert ()  public {
        assert(false);
    }

    function haveAssertWithID ()  public {
        assert(false);
    }

}