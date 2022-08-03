/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

pragma solidity >=0.4.22 <0.9.0;

contract DigitalSignature {
    // Contract owner
    address public owner;

    // Signing Event
    event Signing (
        address indexed _signer,
        bytes32 indexed _hash
    );

    // Signatures
    mapping(address => mapping(bytes32 => bytes32)) public signatures;

    constructor () public {
        owner = msg.sender;
    }

    function sign(bytes32 _hash) public returns (bool success) {
        signatures[msg.sender][_hash] = _hash;
        emit Signing(msg.sender, _hash);
        return true;
    }

    function verify(bytes32 _hash, address _signer) public view returns (bool success) {
        require(_hash == signatures[_signer][_hash]);
        return true;
    }
}