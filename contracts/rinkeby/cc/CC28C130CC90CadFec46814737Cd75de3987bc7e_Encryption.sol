/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: test.sol

contract Encryption {
    event addressEcrypted(address _address, uint256 _key);

    uint256 digits16 = 10**16;

    struct EncryptedAddress {
        address senderAddress;
        uint256 encryptedAddress;
    }

    mapping(address => uint256) public ecryptedMapping;
    mapping(address => bool) private blacklisted;

    modifier notBlacklisted() {
        require(!blacklisted[msg.sender]);
        _;
    }

    uint256 alreadySigned;

    EncryptedAddress[] public encryptedAddress;

    function _generateMapping(address _address, uint256 _encryption) private {
        ecryptedMapping[_address] = _encryption;
        encryptedAddress.push(EncryptedAddress(_address, _encryption));
        blacklisted[_address] = true;
    }

    function _generateEncyption(address _address)
        private
        view
        returns (uint256)
    {
        uint256 _key = uint256(keccak256(abi.encodePacked(_address)));
        uint256 key = _key % digits16;
        return key;
    }

    function encryptAddress() public notBlacklisted {
        uint256 encryptedaddress = _generateEncyption(msg.sender);
        _generateMapping(msg.sender, encryptedaddress);
        emit addressEcrypted(msg.sender, encryptedaddress);
    }
}