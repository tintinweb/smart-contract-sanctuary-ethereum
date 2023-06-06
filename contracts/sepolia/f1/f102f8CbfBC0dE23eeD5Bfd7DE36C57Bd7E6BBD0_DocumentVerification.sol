/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

contract DocumentVerification {

     struct Document {
        bytes32 hash;
        string issuedBy;
        string issuedTo;
    }
    Document[] public documents;

    event CreatedDocument(
        string hash,
        string issuedBy,
        string issuedTo,
        uint256 createTime
    );

    mapping(bytes32 => bool) private verifiedHashes;
    bytes32[] private documentHashes;


    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    modifier uniqueHash(string memory hash) {
        bytes32 hashBytes = stringToBytes32(hash);
        for (uint256 i = 0; i < documents.length; i++) {
            require(documents[i].hash != hashBytes, "Duplicate hash found");
        }
        _;
    }

    function createDocument(
        string memory hash,
        string memory issuedBy,
        string memory issuedTo
    ) external uniqueHash(hash) {
        require(bytes(hash).length > 0, "Hash cannot be empty");
        require(bytes(issuedBy).length > 0, "Issued by cannot be empty");
        require(bytes(issuedTo).length > 0, "Issued to cannot be empty");
        
        bytes32 hashBytes = stringToBytes32(hash);

        Document memory newDocument = Document(
            hashBytes,
            issuedBy,
            issuedTo
        );
        documents.push(newDocument);
        documentHashes.push(hashBytes);
        verifiedHashes[hashBytes] = true; // Update the verifiedHashes mapping
        emit CreatedDocument(
            hash,
            issuedBy,
            issuedTo,
            block.timestamp
        );
    }

    function documentCount() external view returns (uint256) {
        return documents.length;
    }

    function getDocument(string memory hash)
        external
        view
        returns (Document memory)
    {
        bytes32 hmacDigest = stringToBytes32(hash);
        for (uint256 i = 0; i < documents.length; i++) {
            if (documents[i].hash == hmacDigest) {
                return documents[i];
            }
        }
        revert("Document not found");
    }

    function verifyHash(string memory _hash) external view returns (bool) {
        bytes32 hashBytes = stringToBytes32(_hash);
        return verifiedHashes[hashBytes];
    }

    function verifyMultipleHashes(string[] memory _hashes)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory verificationResults = new bool[](_hashes.length);
        for (uint256 i = 0; i < _hashes.length; i++) {
            bytes32 hashBytes = stringToBytes32(_hashes[i]);
            verificationResults[i] = verifiedHashes[hashBytes];
        }
        return verificationResults;
    }
}