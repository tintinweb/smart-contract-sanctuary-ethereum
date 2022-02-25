/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

pragma solidity ^0.8.12;

contract Certificates {
    address issuer;
    mapping (bytes32 => bool) public issued_certificates;
    mapping (bytes32 => bool) public revoked_certificates;
    
    event IssuedCertificate(bytes32 hash);
    event RevokedCertificate(bytes32 hash);
    
    constructor(address _issuer) {        
        issuer = _issuer;
    }
    
    function transfer(address new_issuer) public {
        require(msg.sender == issuer);
        issuer = new_issuer;
    }
    
    function issue(bytes32 hash) public {
        require(msg.sender == issuer);
        require(!issued_certificates[hash]);
        issued_certificates[hash] = true;
        emit IssuedCertificate(hash);
    }
    
    function revoke(bytes32 hash, bytes32 root) public {
        require(msg.sender == issuer);
        require(issued_certificates[root]);
        require(!revoked_certificates[hash]);
        revoked_certificates[hash] = true;
        emit RevokedCertificate(hash);
    }
}