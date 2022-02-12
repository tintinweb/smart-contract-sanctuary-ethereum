/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

pragma solidity 0.8.11;

contract Hello {
    string public hello;

    function setHello(string memory _hello) public {
        hello = _hello;
    }

    function getHello() public view returns(string memory) {
        return hello;
    }   
}