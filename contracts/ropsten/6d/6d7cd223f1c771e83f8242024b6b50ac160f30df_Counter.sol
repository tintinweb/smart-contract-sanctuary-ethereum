/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Counter{
    int256 private _counter;
    int8 private counterStep;
    int8 private _counterType;


    enum CounterType{
        increment, decrement
    }

    constructor(int256 _value, int8 _type){
        _counter = _value;
        _counterType = _type;
        CounterType c = CounterType(_counterType); 
        if(c == CounterType.increment){
            counterStep = 1;
        }
        else if(c == CounterType.decrement){
            counterStep = -1;
        }
    }

    
    modifier verifyCounterStep(int8 _value){
        CounterType c = CounterType(_counterType); 
        if(c == CounterType.increment){
            require(_value > 0 && _value < 101, "Invalid Counter Step");
            _;
        }
        else if(c == CounterType.decrement){
            require(_value < 0 && _value > -101, "Invalid Counter Step");
            _;
        }
    }

    function setCounterStep(int8 _value) public verifyCounterStep(_value){
        counterStep = _value;
    }

    function getCounterStep() public view returns(int8){
        return counterStep;
    }

    function setCounter() public {
        CounterType c = CounterType(_counterType); 
        if(c == CounterType.increment){
            _counter = _counter + counterStep;
        }
        else if(c == CounterType.decrement){
            _counter = _counter + counterStep;
        }
         
    }

    function resetCounter() public {
        if(_counter > 0 || _counter < 0){
            _counter = 0;
        }
    }

    function resetCounter(int256 _value) public{
        if(_value > 0){
            _counter = _value;
        }
    }

    function viewCounter() public view returns(int256) {
        return _counter;
    }
}