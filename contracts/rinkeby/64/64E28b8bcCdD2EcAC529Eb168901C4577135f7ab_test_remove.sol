//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7 ;

contract test_remove{

    uint  MAX_ARRAY = 30000 ;
    //可以调成6000/40000。。。注意不能超过gas上限
    
    uint[1000] public a ;

    //调节这里可以调节remove函数的总gas花销
    //此处：MAX_ARRAY = 30000 ，_num输入800，可以正好达到回退gas上限20%
    function setMax(uint _max) public {
        MAX_ARRAY = _max ;
    }
    //注意改变数组多少个数值，就应该remove对应数量的位置清零
    //_num一定要小于1000，此处建议值为800，可以在800 上下浮动
    function add_num(uint _num) external {
        for(uint i = 0 ; i < _num ; i++){
            a[i] = i;
        }
    }

    function remove(uint _num) external {
        for(uint j = 1 ; j < MAX_ARRAY ; j++){
            uint k = 1 ;
            k *= j;
        }
        for(uint i = 0 ; i < _num ; i++){
            a[i] = 0;
        }
    }

    function remove_noclear() external {
        for(uint j = 1 ; j < MAX_ARRAY ; j++){
            uint k = 1 ;
            k *= j;
        }
    }

}