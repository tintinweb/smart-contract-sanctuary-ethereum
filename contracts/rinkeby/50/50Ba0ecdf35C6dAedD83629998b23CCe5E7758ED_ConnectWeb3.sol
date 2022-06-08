// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.9.0;

contract ConnectWeb3 {

    string private _greetings = "Hello world";
    uint private _counter = 0;

    function setGreetings(string memory greetings) public {
        _greetings = greetings;
    }

    function setIncrement() public {
        _counter += 1;
    }
            
    function getGreetings() public view returns(string memory){
        return _greetings;   
    }

    function getCounter() public view returns(uint) {
        return _counter;
    }

}