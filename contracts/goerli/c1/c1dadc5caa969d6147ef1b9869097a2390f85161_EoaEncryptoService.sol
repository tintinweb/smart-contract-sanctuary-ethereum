/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;


contract EoaEncryptoService{

    event MessageCreated (address indexed from, address indexed to, bytes encryptedMessage);
    event Registerd(address indexed user, bytes publicKey);
    
    mapping(address => bytes) public publicKeys;

    function createMessge(address _to, bytes calldata _encryptedMessage) external{
        emit MessageCreated(msg.sender,_to,_encryptedMessage);
    }

    function createMessges(address[] calldata _tos, bytes[] calldata _encryptedMessages) external{
        require(_tos.length == _encryptedMessages.length,"INVAILED LENGTH");
        for(uint256 i = 0;i < _tos.length;i++){
            unchecked{
                emit MessageCreated(msg.sender,_tos[i],_encryptedMessages[i]);
            }
        }
    }

    function registerPublicKey(bytes calldata _publicKey) external {
        publicKeys[msg.sender] = _publicKey;
        emit Registerd(msg.sender, _publicKey);
    }
}