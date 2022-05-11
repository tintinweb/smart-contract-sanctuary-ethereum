/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

pragma solidity >=0.7.0 <0.9.0;


contract TestContract {

    struct Request {
        function(uint) external callback;
        bytes data;
    }

    Request[] private requests;

    function testCallbackParameter(function(uint) external callback, bytes memory data) public {
        requests.push(Request(callback, data));
    }

    function returnRequests() public view returns (Request[] memory) {
        return requests;
    }
}