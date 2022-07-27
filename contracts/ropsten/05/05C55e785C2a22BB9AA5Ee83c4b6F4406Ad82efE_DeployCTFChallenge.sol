pragma solidity ^0.4.21;

import "./CTFFuzzyIdentityChallenge.sol";

contract DeployCTFChallenge {
    // old 
    address public addrCtf;

    function deployOld(bytes32 _salt, bytes _contractByte) public {
        bytes memory byteCode = _contractByte;
        address addr;

        assembly {
            addr := create2(0, add(byteCode, 0x20), mload(byteCode), _salt)
        }

        // create2 produce address: keccak256(0xff ++ deployingAddr ++ salt ++ keccak256(bytecode))[12:]
        addrCtf = addr;
    }

    // new must use more than 0.8.0
    function deployNew(bytes32 _salt) public returns (address) {
        // CTFFuzzyIdentityChallenge c = new CTFFuzzyIdentityChallenge{salt: _salt}();
        return address(0);
    }

    function compareCallAddr(address _address) public view returns(bool) {
        bool bEqual = _address == addrCtf;
        return bEqual;
    }

    function callCTFViaAddress(address _address, address _attackAddess) public {
        CTFFuzzyIdentityChallenge ctf = CTFFuzzyIdentityChallenge(_address);
        ctf.attack(_attackAddess);
    }

    function callCTF(address _attackAddess) public {
        CTFFuzzyIdentityChallenge ctf = CTFFuzzyIdentityChallenge(addrCtf);
        ctf.attack(_attackAddess);
    }
}