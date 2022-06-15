/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: BUSL-1.1 

//由于 msg.value 发送单位只能是 ether 所以要用 call 来发送主币，可以设置数量 也可以设置单位。

//视频 solidity0.8  43-低级 call   uniswap 第六课 5分钟



pragma solidity ^0.8.10;
contract testCall{
    string public message;
    uint public x;

    event log(string message);
    fallback() external payable{
        emit log("fallback was called");
    }

    function foo(string memory _message, uint _x) external payable returns(bool, uint){
        message = _message;
        x = _x;
        return(true , 999);
    }
}


contract Call{
    bytes public data;

    function callfoo(address _test,uint o) external payable{   
        (bool success,bytes memory _data) = _test.call{value: o, gas:100000}(abi.encodeWithSignature("foo(string,uint256)","call foo",123));
        require(success,"call failed");
        data = _data;
    }
    function call_bu_cun_zai_de_han_shu_hui_diaoyong_fallbac(address _test) external {
        (bool success,) = _test.call(abi.encodeWithSignature("abc"));
        require(success,"call failed");
    }
}