/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract LoopboardCollectionsV1 {
    enum NFTLink {
        UNUSED,
        Marketplace,
        Explorer
    }

    struct Collection {
        string headerImageUri;
        string key;
        string label;
        NFTLink linksTo;
        string[] nftIDs;
    }

    mapping(address => Collection[]) private collections;

    function setCollection(
        string memory _imageUri,
        string memory _key,
        string memory _label,
        uint8 _linksTo
    ) public returns (bool) {
        NFTLink linksTo = getNFTLinkEnum(_linksTo);
        if (linksTo == NFTLink.UNUSED) {
            return false;
        }

        //TODO check blacklist (custom admin NFT? zkEVM|onchain)

        Collection[] storage ownCollections = collections[msg.sender];

        (bool isMatched, uint256 matchingCollectionIndex) = getCollectionIndex(
            ownCollections,
            _key
        );

        uint256 collectionIndex = ownCollections.length;
        if (isMatched) {
            collectionIndex = matchingCollectionIndex;
        }
        Collection storage collection = collections[msg.sender][
            matchingCollectionIndex
        ];
        collection.headerImageUri = _imageUri;
        collection.key = _key;
        collection.label = _label;
        collection.linksTo = linksTo;

        return true;
    }

    function addCollectionTokens(string memory _key, string[] memory _nftIDs)
        public
        returns (bool[] memory, string[] memory)
    {
        bool[] memory result;
        string[] memory errors;

        Collection[] storage ownCollections = collections[msg.sender];

        (bool isMatched, uint256 matchingCollectionIndex) = getCollectionIndex(
            ownCollections,
            _key
        );
        if (!isMatched) {
            for (uint256 nftIndex = 0; nftIndex < _nftIDs.length; nftIndex++) {
                result[nftIndex] = false;
                errors[nftIndex] = "not existing collection";
            }
            return (result, errors);
        } else {
            for (uint256 nftIndex = 0; nftIndex < _nftIDs.length; nftIndex++) {
                result[nftIndex] = false;
                errors[nftIndex] = "not existing NFT";
            }
        }

        Collection storage collection = ownCollections[matchingCollectionIndex];

        bytes32[] memory prevNftHashes;
        for (uint256 nftIndex = 0; nftIndex < _nftIDs.length; nftIndex++) {
            if (uint256(collection.linksTo) < 1) {
                result[nftIndex] = false;
                errors[nftIndex] = "not existing collection";
            } else {
                string memory nftID = _nftIDs[nftIndex];
                bytes32 nftValue = keccak256(abi.encode(nftID));
                bool isPrevExisting = false;
                for (
                    uint256 prevNftIndex = 0;
                    prevNftIndex < collection.nftIDs.length;
                    prevNftIndex++
                ) {
                    if (prevNftIndex > prevNftHashes.length) {
                        prevNftHashes[prevNftIndex] = keccak256(
                            abi.encode(collection.nftIDs[prevNftIndex])
                        );
                    }
                    if (prevNftHashes[prevNftIndex] == nftValue) {
                        isPrevExisting = true;
                    }
                }
                if (!isPrevExisting) {
                    collection.nftIDs.push(nftID);
                    result[nftIndex] = true;
                    errors[nftIndex] = "";
                } else {
                    result[nftIndex] = false;
                    errors[nftIndex] = "already existing NFT ";
                }
            }
        }

        return (result, errors);
    }

    function removeCollectionTokens(string memory _key, string[] memory _nftIDs)
        public
        returns (bool[] memory, string[] memory)
    {
        bool[] memory result;
        string[] memory errors;

        Collection[] storage ownCollections = collections[msg.sender];

        (bool isMatched, uint256 matchingCollectionIndex) = getCollectionIndex(
            ownCollections,
            _key
        );
        if (!isMatched) {
            for (uint256 nftIndex = 0; nftIndex < _nftIDs.length; nftIndex++) {
                result[nftIndex] = false;
                errors[nftIndex] = "not existing collection";
            }
            return (result, errors);
        } else {
            for (uint256 nftIndex = 0; nftIndex < _nftIDs.length; nftIndex++) {
                result[nftIndex] = false;
                errors[nftIndex] = "not existing NFT";
            }
        }

        Collection storage collection = ownCollections[matchingCollectionIndex];

        bytes32[] memory nftHashes;

        if (uint256(collection.linksTo) < 1) {
            for (uint256 nftIndex = 0; nftIndex < _nftIDs.length; nftIndex++) {
                errors[nftIndex] = "collection does not link anywhere";
            }
            return (result, errors);
        } else {
            string[] memory newNfts;

            for (
                uint256 prevNftIndex = 0;
                prevNftIndex < collection.nftIDs.length;
                prevNftIndex++
            ) {
                newNfts[prevNftIndex] = collection.nftIDs[prevNftIndex];
            }

            for (
                uint256 prevNftIndex = 0;
                prevNftIndex < collection.nftIDs.length;
                prevNftIndex++
            ) {
                string memory prevNftID = collection.nftIDs[prevNftIndex];
                bytes32 prevNftValue = keccak256(abi.encode(prevNftID));
                for (
                    uint256 nftIndex = 0;
                    nftIndex < _nftIDs.length;
                    nftIndex++
                ) {
                    if (nftIndex > nftHashes.length) {
                        nftHashes[nftIndex] = keccak256(
                            abi.encode(_nftIDs[nftIndex])
                        );
                    }
                    if (nftHashes[prevNftIndex] == prevNftValue) {
                        string[] memory newNftsWithoutMatched;
                        bool isRemoved = false;
                        for (
                            uint256 newNftIndex = 0;
                            newNftIndex < newNfts.length;
                            newNftIndex++
                        ) {
                            if (
                                keccak256(abi.encode(newNfts[newNftIndex])) !=
                                nftHashes[nftIndex]
                            ) {
                                uint256 newNftIndexWithOffset = newNftIndex;
                                if (isRemoved) {
                                    newNftIndexWithOffset--;
                                }
                                newNftsWithoutMatched[
                                    newNftIndexWithOffset
                                ] = prevNftID;
                            } else {
                                isRemoved = true;
                            }
                        }
                        if (isRemoved) {
                            newNfts = newNftsWithoutMatched;
                            result[prevNftIndex] = true;
                            errors[prevNftIndex] = "";
                        }
                    }
                }
            }
            if (newNfts.length < collection.nftIDs.length) {
                collection.nftIDs = newNfts;
            }
        }

        return (result, errors);
    }

    function getCollections(address creator)
        public
        view
        returns (Collection[] memory)
    {
        return collections[creator];
    }

    function getNFTLinkEnum(uint256 value) private pure returns (NFTLink) {
        NFTLink result = NFTLink.UNUSED;

        if (value == 1) {
            result = NFTLink.Marketplace;
        }
        if (value == 2) {
            result = NFTLink.Explorer;
        }

        return result;
    }

    function getCollectionIndex(
        Collection[] memory lookedCollections,
        string memory _key
    ) private pure returns (bool, uint256) {
        bytes32 keyHash = keccak256(abi.encode(_key));
        for (
            uint256 collectionIndex;
            collectionIndex < lookedCollections.length;
            collectionIndex++
        ) {
            if (
                keccak256(abi.encode(lookedCollections[collectionIndex].key)) ==
                keyHash
            ) {
                return (true, collectionIndex);
            }
        }
        return (false, 0);
    }
}