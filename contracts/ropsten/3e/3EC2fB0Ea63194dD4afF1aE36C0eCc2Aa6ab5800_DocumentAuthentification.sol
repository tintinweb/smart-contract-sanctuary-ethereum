// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.16 <0.9.0;


contract DocumentAuthentification {

    struct DocumentInfos {
        string hash;
        string signature;
        string public_key;
        address user;
    }

    DocumentInfos[] public docinfos; 

    function upload_to_docinfos(string memory _hash, string memory _signature, string memory _public_key) public {
        bool valid = verify_docinfos(_hash);
        require (!valid, "Document already uploaded");
        docinfos.push(DocumentInfos(_hash, _signature, _public_key, msg.sender));   
    }

    function verify_docinfos(string memory _hash) public view returns (bool) {
        for (uint i=0; i < docinfos.length; i++) {
            if (keccak256(bytes(_hash)) == keccak256(bytes(docinfos[i].hash))) {
                return true;
            }
        }
        return false;
    }

    function delete_from_docinfos(string memory _hash) public {
        for (uint i=0; i < docinfos.length; i++) {
            if (keccak256(bytes(_hash)) == keccak256(bytes(docinfos[i].hash))) {
                docinfos[i] = docinfos[docinfos.length-1];
                docinfos.pop();
            }
        }
    }
}