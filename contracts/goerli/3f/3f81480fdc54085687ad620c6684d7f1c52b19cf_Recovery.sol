// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface SimpleToken {
  function destroy(address payable _to) external;
}

contract Recovery {
    function remove(address _token, address payable _lostContract) public {
        SimpleToken(_token).destroy(_lostContract);
    }
}