/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract PortraitRegistrySimple {
    struct Record {
        string portraitObjectIpfsCID;
        bool killSwitch;
    }

    mapping(address => Record) records;

    function activateKillSwitch() public {
        records[msg.sender].killSwitch = true;
    }

    function getPersonalIpfsCID(address _address)
        public
        view
        returns (string memory)
    {
        require(
            records[_address].killSwitch == false,
            "Address has been killed"
        );
        require(
            keccak256(
                abi.encodePacked(records[_address].portraitObjectIpfsCID)
            ) != keccak256(""),
            "Address has no portraitObjectIpfsCID"
        );
        return records[_address].portraitObjectIpfsCID;
    }

    function setPersonalIpfsCIDByOwner(string memory _portraitObjectIpfsCID)
        public
    {
        require(
            records[msg.sender].killSwitch == false,
            "Address has been killed"
        );
        require(
            keccak256(
                abi.encodePacked(records[msg.sender].portraitObjectIpfsCID)
            ) != keccak256(abi.encodePacked(_portraitObjectIpfsCID)),
            "Ipfs CID is the same as the previous one"
        );
        records[msg.sender].portraitObjectIpfsCID = _portraitObjectIpfsCID;
    }

    function setPersonalIpfsCidByProof(
        address _address,
        string memory _portraitObjectIpfsCID,
        uint256 _blockHeight,
        bytes memory _signature
    ) public {
        bytes memory _messagePrefix = "\x19Ethereum Signed Message:\n32";

        bytes32 _hashPrefix = keccak256(
            abi.encodePacked(_portraitObjectIpfsCID, _blockHeight)
        );

        bytes32 _message = keccak256(
            abi.encodePacked(_messagePrefix, _hashPrefix)
        );
        require(
            _address == recover(_message, _signature),
            "Signature does not match address"
        );
        require(
            keccak256(
                abi.encodePacked(records[_address].portraitObjectIpfsCID)
            ) != keccak256(abi.encodePacked(_portraitObjectIpfsCID)),
            "Ipfs CID is the same as the previous one"
        );
        require(
            records[_address].killSwitch == false,
            "Address has been killed"
        );
        require(_blockHeight <= block.number, "Block height is in the future");
        require(
            _blockHeight >= block.number - 50,
            "Block height is too far in the past"
        );
        require(
            keccak256(
                abi.encodePacked(records[_address].portraitObjectIpfsCID)
            ) != keccak256(abi.encodePacked(_portraitObjectIpfsCID)),
            "Ipfs CID is the same as the previous one"
        );
        records[_address].portraitObjectIpfsCID = _portraitObjectIpfsCID;
    }

    function recover(bytes32 _message, bytes memory _signature)
        private
        pure
        returns (address)
    {
        bytes32 _r;
        bytes32 _s;
        uint8 _v;
        if (_signature.length != 65) {
            return (address(0));
        }
        assembly {
            _r := mload(add(_signature, 32))
            _s := mload(add(_signature, 64))
            _v := byte(0, mload(add(_signature, 96)))
        }
        if (_v < 27) {
            _v += 27;
        }
        if (_v != 27 && _v != 28) {
            return (address(0));
        } else {
            return ecrecover(_message, _v, _r, _s);
        }
    }
}