/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity >= 0.7.0 < 0.9.0;

contract lec{
    event JustFallback(string _str);
    event JustReceive(string _str);
    function addNumber(uint256 _num1, uint256 _num2) public pure returns(uint256){
        return _num1 + _num2;
    }
    fallback() external payable{
        emit JustFallback("Justfallback is called");
    }
    receive() external payable{
        emit JustReceive("JustReceive is called");
    }
}

contract called{
    event calledFunction(bool _success, bytes _output);

    //1. 송금하기
    function transferEther(address payable _to) public payable{
        (bool success, ) = _to.call{value:msg.value}("");
        require(success,"Failed to transfer ether");
    }

    //2. 외부 스마트 컨트렉 함수 부르기
    function calledMethod(address _contractAddr,uint256 _num1, uint256 _num2) public{
        (bool success,bytes memory _outputFromCalledFunction ) = _contractAddr.call(
            abi.encodeWithSignature("addNumber2(uint256,uint256)", _num1, _num2)
        );
        require(success,"failed to transfer ether");
        emit calledFunction(success,_outputFromCalledFunction);
    }

    //3. 외부 스마트 + 없는 함수와 이더 call로 fallback 실행 ^payable 붙임
    function calledMethod3(address _contractAddr) public payable{
        (bool success,bytes memory _outputFromCalledFunction ) = _contractAddr.call(
            abi.encodeWithSignature("nothing()")
        );
        require(success,"failed to transfer ether");
        emit calledFunction(success,_outputFromCalledFunction);
    }
}