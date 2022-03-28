pragma solidity 0.6.0;


contract sample {

    

function a()public pure returns(uint){
    return 1;
}
function b()public pure returns(uint){
return 3;
}

function g()public pure returns(uint){
    return (a()+b());
}

}