/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

pragma solidity ^0.8.9;

contract ReceiveEther {
    event Received(address caller, uint256 amount, string msg);

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function foo(string memory _msg, uint256 _x) public payable returns(uint256){
        emit Received(msg.sender, msg.value, _msg);
        return _x + 1;
    }
}

contract Caller {

    event Re(bool success, bytes data);

    function callFoo(address payable _addr) public payable {
        (bool success, bytes memory data) = _addr.call{value: msg.value}(
            abi.encodeWithSignature("foo(string,uint256)", "call foo", 1000)
        );
        emit Re(success, data);
    }
}