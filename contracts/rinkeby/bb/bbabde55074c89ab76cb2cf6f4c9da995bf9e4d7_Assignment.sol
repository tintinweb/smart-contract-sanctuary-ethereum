/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// File: Assignment.sol


pragma solidity ^0.8.7;

//ethereum.request({method: "personal_sign", params: ["account", "hash message"]})
contract Assignment {
    address owner;
    uint256[] values;
    enum Type { Unique, Account, Available }
    Type showType;
    bytes32 secretMessage;
    event Log(bytes32, address);


    constructor() {
        owner = msg.sender;
        values.push(rand());
        values.push(111111111);
        values.push(150);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Sender is not owner");
        _;
    }

    function changeOwner(address _address) public onlyOwner {
        owner = _address;
    }

    function setSecretMessage(string calldata _message) public onlyOwner {
        bytes32 hashMessage = keccak256(abi.encodePacked(_message));
        secretMessage = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    hashMessage
                )
            );
    }

    function setType(Type _showType) public onlyOwner {
        showType = _showType;
    }

    function show(bytes calldata _sig) 
    public 
    view
    returns(uint256)
    {
        require(_isSigned(_sig), "not signed");
        return values[uint256(showType)];
    }


    function rand()
    internal
    view
    returns(uint256){
        uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit + 
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
        block.number
    )));

    return (seed - ((seed / type(uint256).max) * type(uint256).max));
    }

    function _isSigned(
        bytes memory _sig
    ) internal view returns (bool){
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, secretMessage));
        address signer = ecrecover(prefixedHashMessage, v, r, s);
        return signer == msg.sender;
    }

    function _split(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }

    function getMessageHash(string memory _message)
        public
        pure
        returns (bytes32)
    {
        bytes32 hashMessage = keccak256(abi.encodePacked(_message));
        return keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    hashMessage
                )
            );
    }
}