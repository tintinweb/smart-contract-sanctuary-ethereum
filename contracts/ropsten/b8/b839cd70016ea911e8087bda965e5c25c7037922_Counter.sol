/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Counter{
    int256 private _counter;
    int8 private incrementStep;
    int8 private decrementStep;


    enum CounterType{
        increment, decrement
    }

    constructor(int256 _value){
        _counter = _value;
        incrementStep = 1;
        decrementStep = -1;
    }

    
    modifier resetIncCounterStep(int8 _value){
        require(_value >0 && _value < 101, "Invalid Counter Step");
        _;
    }

    
    modifier resetDecCounterStep(int8 _value){
        require(_value < 0 && _value > -101, "Invalid Counter Step");
        _;
    }

    function incrementCounterStep(int8 _value) public resetIncCounterStep(_value){
        incrementStep = _value;
    }

    function decrementCounterStep(int8 _value) public resetDecCounterStep(_value){
        decrementStep = _value;
    }

    function getCounterStep(int8 _type) public view returns(int8){
        CounterType c = CounterType(_type); 
        if(c == CounterType.increment){
            return incrementStep;
        }
        else if(c == CounterType.decrement){
            return decrementStep;
        }
        else{
            return 0;
        }
    }


    function incrementCounter() public{
        _counter = _counter + incrementStep;
    }

    function deccrementCounter() public {
         _counter = _counter + decrementStep;
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