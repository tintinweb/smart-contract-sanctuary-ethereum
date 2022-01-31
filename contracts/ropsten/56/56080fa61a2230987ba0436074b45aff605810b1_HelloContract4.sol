/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

pragma solidity ^0.4.0;

contract HelloContract4 {

    address creator;

    event print_log(string message);

    function HelloContract4() {
        creator = msg.sender;
    }

    function sayHello() returns(string) {
        print_log("Call Hello world");
        return "Hello world";
    }

    function sayHi(string name) returns(string) {
        print_log("Call sayHi");
        return strConcat("Hi ", name);
    }

    function strConcat(string _a, string _b) internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ab = new string(_ba.length + _bb.length);
        bytes memory result = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) result[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) result[k++] = _bb[i];
        return string(result);
    }

}