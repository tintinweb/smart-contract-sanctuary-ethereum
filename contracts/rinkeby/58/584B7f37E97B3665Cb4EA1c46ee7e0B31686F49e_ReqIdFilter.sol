// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract ReqIdFilter {
    mapping(bytes32 => bool) filter;
    address public owner = msg.sender;

    function testAndSet(bytes32 id) public returns (bool) {
        require(msg.sender == owner, "not owner");
        if (filter[id]) return true;
        filter[id] = true;
        return false;
    }

    function destroy() public {
        require(msg.sender == owner, "not owner");
        selfdestruct(payable(owner));
    }

    function getReqIdFilter(bytes32 id) public view returns (bool) {
        return filter[id];
    }
}