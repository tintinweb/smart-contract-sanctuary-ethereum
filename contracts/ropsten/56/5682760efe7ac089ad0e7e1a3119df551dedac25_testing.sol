/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

pragma solidity ^0.8.2;

contract testing {

    uint hello = 0;
    string baseuri = "";
    function writing(uint _num1, uint _num2) public {
        hello = _num1 + _num2;
    }

    function writing2(string memory _uri) public payable {
        baseuri = _uri;
    }

    function reading() public view returns(uint) {
        return hello;
    }
    function reading2() public view returns(string memory) {
        return baseuri;
    }
    
}