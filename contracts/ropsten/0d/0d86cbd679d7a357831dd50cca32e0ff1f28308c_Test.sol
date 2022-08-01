/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity >=0.7.0 <0.9.0;

contract Ownable {
    int256 private tt;
    address private _owner;
    address private _previousOwner;
    
    function set_c(int256 k) public {
        tt = k;
    }
}


contract Ownable2 {
    int256 private tt2;
    address private _owner;
    address private _previousOwner;
    
    function set_d(int256 k) public {
        tt2 = k;
    }
}

contract Test is Ownable,Ownable2{

    int256 a = 1;

    constructor() {}

    function set_a(int256 _a) public {
        a = _a;
    }

}