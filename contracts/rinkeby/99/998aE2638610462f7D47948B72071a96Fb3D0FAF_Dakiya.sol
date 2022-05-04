/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Dakiya {
    uint256 public threadCount = 0;
    mapping(address => string) private pubEncKeys; // mapping of address to public encryption key https://docs.metamask.io/guide/rpc-api.html#eth-getencryptionpublickey

    struct UriTimestamp {
        string uri;
        uint256 timestamp;
    }

    event MessageSent (
        address receiver,
        string uri,
        uint256 timestamp,
        address sender,
        uint256 thread_id
    );

    event ThreadCreated (
        address receiver,
        address sender,
        uint256 thread_id,
        uint256 timestamp,
        string _sender_key,
        string _receiver_key,
        bool _encrypted,
        string cloned_to,
        string applicationKey
    );

    function getPubEncKeys(address receiver) public view returns(string memory sender_key, string memory receiver_key) {

        require(bytes(pubEncKeys[msg.sender]).length != 0, "Sender isn't registered on Dakiya");

        if (bytes(pubEncKeys[msg.sender]).length != 0) {
            sender_key = pubEncKeys[msg.sender];
        }
        if (bytes(pubEncKeys[receiver]).length != 0) {
            receiver_key = pubEncKeys[receiver];
        }
        return (sender_key, receiver_key);
    }

    function checkUserRegistration() public view returns(bool) {
        return bytes(pubEncKeys[msg.sender]).length != 0;
    }

    function setPubEncKey(string memory encKey) public {
        pubEncKeys[msg.sender] = encKey;
    }

    function sendMessage(
        uint256 _thread_id,
        UriTimestamp[] memory _uriTimestamp,
        address _receiver,
        string memory _sender_key,
        string memory _receiver_key,
        bool encrypted,
        string memory _cloned_to,
        string memory applicationKey
    ) public {
        if (_thread_id == 0) {
            emit ThreadCreated(
                _receiver,
                msg.sender,
                threadCount,
                block.timestamp,
                _sender_key,
                _receiver_key,
                encrypted,
                _cloned_to,
                applicationKey
            );
            emit MessageSent(_receiver, _uriTimestamp[0].uri, _uriTimestamp[0].timestamp, msg.sender, threadCount);

            threadCount++;

        } else {
            for (uint i = 0; i < _uriTimestamp.length; i++) {
                emit MessageSent(
                    _receiver,
                    _uriTimestamp[i].uri,
                    _uriTimestamp[i].timestamp,
                    msg.sender,
                    threadCount
                );
            }
            // emit MessageSent(_receiver, _uri[0], block.timestamp, msg.sender, _thread_id);
        }
    }

    function cloneToEncryptedThread(string memory _thread_id) public {
    }
}