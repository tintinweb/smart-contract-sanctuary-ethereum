/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity >=0.7.0 <0.9.0;

contract Ownable {
    int256 public tt1=1;
    int256 public test1 = 10;
    int256 public constant test_constant1 = 11;
    mapping(address => uint256) public test_map1;

    function set_tt1(int256 k) public {
        tt1 = k;
    }
}


contract Ownable2 {
    int256 public tt2=2;
    int256 public test2 = 20;
    int256 public constant test_constant2 = 12;
    mapping(address => uint256) public test_map2;
    function set_tt2(int256 k) public {
        tt2 = k;
    }

    
}

contract Test is Ownable,Ownable2{

    int256 public tt3 = 3;
    int256 public test3 = 30;
    int256 public constant test_constant3 = 13;
    mapping(address => uint256) public test_map3;

    function add_test_map3(address k,uint256 v) public {
        test_map3[k] = v;
    }
    function add_test_map3(address k) public {
        delete(test_map3[k]);
    }


    constructor() {}

    function set_tt3(int256 _a) public {
        tt3 = _a;
    }

}