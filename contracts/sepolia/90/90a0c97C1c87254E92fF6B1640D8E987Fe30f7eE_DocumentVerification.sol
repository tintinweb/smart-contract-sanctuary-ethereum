/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

contract DocumentVerification {

    struct Document {
        bytes32 hashes;
        string issuedBy;
        string issuedTo;
    }

    Document[] public documents;

    event CreatedDocument(
        string hashes,
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

    modifier uniqueHashes(string[] memory hashes) {
        for (uint256 i = 0; i < hashes.length; i++) {
            bytes32 hashBytes = stringToBytes32(hashes[i]);
            for (uint256 j = 0; j < documents.length; j++) {
                require(documents[j].hashes != hashBytes, "Duplicate hash found");
            }
        }
        _;
    }

    function UploadMultipleHashes(
        string[] memory hashes,
        string memory issuedBy,
        string memory issuedTo
    ) external uniqueHashes(hashes) {
        require(hashes.length > 0, "Hashes array cannot be empty");

        for (uint256 i = 0; i < hashes.length; i++) {
            string memory hash = hashes[i];
            require(bytes(hash).length > 0, "Hash cannot be empty");

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
    }

    function getDocument(string memory hash)
        external
        view
        returns (Document memory)
    {
        bytes32 hmacDigest = stringToBytes32(hash);
        for (uint256 i = 0; i < documents.length; i++) {
            if (documents[i].hashes == hmacDigest) {
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