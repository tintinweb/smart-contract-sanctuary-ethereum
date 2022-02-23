pragma solidity ^0.8.10;

contract TestError{

    error Errorparadigm(string);

    error Errorparadigm2(uint256);

    error Errorparadigm3(uint256 testError);



    function haveError() public{
        if(true)
            revert Errorparadigm("have error string message");
    }

    function haveError2() public{
        if(true)
            revert Errorparadigm2(10);
    }

    function haveError3() public{
        if(true)
            revert Errorparadigm3(256);
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