// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Document.sol";

contract DocumentFactory {
    mapping (address=>Document[]) addressToDocument;

    function createDoc(string memory name, string memory desc, string memory ipfs, string memory ownerName) public returns (Document){
        Document newDocument = new Document(name, desc, ipfs, msg.sender, ownerName);
        addressToDocument[msg.sender].push(newDocument);
        return newDocument;
    }

    function getDocuments(address account) public view returns (Document[] memory){
        return addressToDocument[account];
    }

    function giveAccessToDoc(string memory signer_name, address signer, Document Doc) public {
        addressToDocument[signer].push(Doc);
        Doc.addSigner(signer_name, signer, msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Document{
    address public owner;
    string public name;
    string public description;

    address [] public signers;

    mapping (address=>bool) public addressToAllowed;
    mapping (address=>bool) public addressToSigned;
    mapping (address=>uint) public addressToTimeSigned;
    mapping (address=>string) public addressToString;

    uint public timestamp;
    string ipfs_hash;
    uint left;
    event signed (address signer );

    constructor(string memory _name, string memory _description, string memory _ipsf, address _creator, string memory ownerName){
        owner = _creator;
        name = _name;
        description = _description;

        signers.push(owner);
        left++;
        ipfs_hash = _ipsf;

        addressToString[_creator] = ownerName;
        addressToAllowed[_creator] = true;

        timestamp = block.timestamp;

    }
    //Sign function

    function sign() external payable isSigner(msg.sender){
        uint sentAmt = msg.value;

        addressToSigned[msg.sender] = true;
        addressToTimeSigned[msg.sender] = block.timestamp;
        left --;

        emit signed(msg.sender);

        payable((msg.sender)).transfer(sentAmt);

    }

    //allow to sign

    function addSigner(string memory signer_name, address signer, address sender) public {
        require(sender == owner, "You can't give permission to another cause your are not owner");
        require(addressToAllowed[signer] != true, "You have alerady permission to sign this doc");

        signers.push(signer);
        left++;

        addressToAllowed[signer] = true;
        addressToString[signer] = signer_name;
    }

    function getSignersCount() public view returns(uint){
        return signers.length;
    }

    function checkIntegrity(string memory hash) public view returns (bool){
        if (keccak256(bytes(hash)) == keccak256(bytes(ipfs_hash))) {
            return true;
        } else {
            return false;
        }
    }

    modifier isSigner(address sender){
        require(addressToAllowed[sender] == true, "You are not permited to sign");
        require(addressToSigned[sender] != true, "You are alredy signed");
        _;
    }

}