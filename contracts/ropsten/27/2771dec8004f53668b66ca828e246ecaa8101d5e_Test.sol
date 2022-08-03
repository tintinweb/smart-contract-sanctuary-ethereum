/**
 *Submitted for verification at Etherscan.io on 2022-08-03
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

    bool public tb1 = true;
    bool public tb2 = false;
    int256 public line_1 = 256;
    int16 public test_int16_max=type(int16).max;
    bool public tb3 = false;
    int16 public test_int16_minc=type(int16).min;
    int256 public line_2 = 256;
    int8 public test_int8_max=type(int8).max;
    bool public tb5 = false;
    int8 public test_int8_minc=type(int8).min;
    int256 public line_3 = 256;
    uint16 public test_uint16_max=type(uint16).max;
    bool public tb6 = false;
    uint16 public test_uint16_minc=type(uint16).min;
    int256 public line_4 = 256;
    uint8 public test_uint8_max=type(uint8).max;
    bool public tb7 = false;
    uint8 public test_uint8_minc=type(uint8).min;
    int256 public line_5 = 256;
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

    function edit_bool_1(bool t) public {
        tb1 = t;
    }
    function edit_bool_2(bool t) public {
        tb2 = t;
    }
    function edit_bool_3(bool t) public {
        tb3 = t;
    }
    constructor() {}

    function set_tt3(int256 _a) public {
        tt3 = _a;
    }

}