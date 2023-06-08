/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <0.9.0;

library ECDSA {
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            revert("ECDSA: invalid signature 'v' value");
        }

        return ecrecover(hash, v, r, s);
    }
}

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 tempValue = value;
        uint256 digits;

        while (tempValue != 0) {
            digits++;
            tempValue /= 16;
        }

        bytes memory buffer = new bytes(digits);

        for (uint256 i = 0; i < digits; i++) {
            buffer[digits - i - 1] = alphabet[value & 0xf];
            value >>= 4;
        }

        return string(buffer);
    }
}

contract PasswordManager {
    using ECDSA for bytes32;
    using Strings for uint256;

    struct PasswordData {
        string password;
        address owner;
        bytes32 publicKey;
        bytes32 privateKey;
        mapping(string => bool) siteUsage;
    }

    mapping(address => PasswordData) private passwords;

    event PasswordCreated(address indexed owner, string password, bytes32 publicKey);
    event PasswordDeleted(address indexed owner);
    event PasswordModified(address indexed owner, string newPassword);
    event PasswordUsedOnSite(address indexed owner, string site);

    modifier onlyOwner(address _owner) {
        require(msg.sender == _owner, "Only the password owner can call this function");
        _;
    }

    function createRandomPassword() public {
        require(passwords[msg.sender].owner == address(0), "Credentials already exist for this address");

        bytes memory charset = "[email protected]#$%^&*()-_=+{}[]<>,.?/";
        uint256 length = 20;
        bytes memory randomPassword = new bytes(length);
        uint256 randSeed = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender)));

        for (uint256 i = 0; i < length; i++) {
            randSeed = uint256(keccak256(abi.encodePacked(randSeed, i, blockhash(block.number - 1))));
            randomPassword[i] = charset[randSeed % charset.length];
        }

        PasswordData storage newPasswordData = passwords[msg.sender];
        newPasswordData.password = string(randomPassword);
        newPasswordData.owner = msg.sender;
        (newPasswordData.publicKey, newPasswordData.privateKey) = generateKeyPair();
        emit PasswordCreated(msg.sender, newPasswordData.password, newPasswordData.publicKey);
    }

    function deletePassword() public {
        require(passwords[msg.sender].owner != address(0), "No credentials exist for this address");

        delete passwords[msg.sender];
        emit PasswordDeleted(msg.sender);
    }

    function modifyPassword(string memory _newPassword) public onlyOwner(msg.sender) {
        require(bytes(_newPassword).length > 0, "New password cannot be empty");

        passwords[msg.sender].password = _newPassword;
        emit PasswordModified(msg.sender, _newPassword);
    }

    function getPassword() public view returns (string memory) {
        require(passwords[msg.sender].owner != address(0), "No credentials exist for this address");

        return passwords[msg.sender].password;
    }

    function getPublicKey() public view returns (bytes32) {
        require(passwords[msg.sender].owner != address(0), "No credentials exist for this address");

        return passwords[msg.sender].publicKey;
    }

    function getPrivateKey() public view onlyOwner(msg.sender) returns (bytes32) {
        require(passwords[msg.sender].owner != address(0), "No credentials exist for this address");

        return passwords[msg.sender].privateKey;
    }

    function generateKeyPair() private view returns (bytes32, bytes32) {
        bytes32 privateKey = bytes32(uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender))));
        bytes32 publicKey = keccak256(abi.encodePacked(privateKey));

        return (publicKey, privateKey);
    }

    function usePasswordOnSite(string memory _site) public onlyOwner(msg.sender) {
        require(passwords[msg.sender].owner != address(0), "No credentials exist for this address");

        passwords[msg.sender].siteUsage[_site] = true;
        emit PasswordUsedOnSite(msg.sender, _site);
    }

    function checkPasswordUsageOnSite(address _owner, string memory _site) public view returns (bool) {
        require(passwords[_owner].owner != address(0), "No credentials exist for this address");

        return passwords[_owner].siteUsage[_site];
    }
}