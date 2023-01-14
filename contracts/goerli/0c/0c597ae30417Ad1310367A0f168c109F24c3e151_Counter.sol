/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

contract Counter {
    event messageToBridge(address from, address to, uint256 nonce, uint256 value, 
        bytes sig);
    event logCounterIncrement(address from, uint256 nonce, uint256 value);

    address public owner;
    uint256 public counter;
    mapping(address => mapping(uint256 => bool)) public nonce;

    modifier onlyOwner() {
        require(owner == msg.sender, "Only Owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setNewOwner(address newOwner) external onlyOwner{
        require(newOwner != address(0), "Zero Address");
        owner = newOwner;
    }

    function send(address to, uint256 _nonce, uint256 value, bytes calldata sig) 
        payable external {
        address _from = msg.sender;
        require(nonce[_from][_nonce] == false, "nonce already used");
        require(value > 0 && value <= 3, "increment out of range");
        require(msg.value == value*0.001 ether, "Not enough ether");
        nonce[_from][_nonce] = true;
        unchecked {
            emit messageToBridge(_from, to, _nonce, value, sig);
        }
    }

    function increment(address from, address to, uint256 _nonce, 
        uint256 value, bytes calldata sig)  external onlyOwner {
        require(to == address(this), "wrong contract address");
        require(nonce[from][_nonce] == false, "nonce already used");
        nonce[from][_nonce] = true;
        bytes32 hash = prefixed(keccak256(abi.encodePacked(
            from, to, _nonce, value
        )));
        require(recoverSigner(hash, sig) == from, "wrong signer");
        unchecked {
            counter += value;
        }
        emit logCounterIncrement(from, _nonce, counter);
    }

    function withdraw(address payable to) onlyOwner external {
        require(to != address(0), "Zero Address");
        to.transfer(address(this).balance);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            '\x19Ethereum Signed Message:\n32',
            hash
        ));
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure
    returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65, "Invaid sig length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }
}