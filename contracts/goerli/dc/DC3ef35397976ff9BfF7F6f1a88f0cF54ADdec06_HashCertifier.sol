/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract HashCertifier {

    struct Stamp {
        string hash; 
        uint256 blockNumber;
    }

    mapping(string => Stamp) public certifiedHashesMap;

    Stamp[] public certifiedHashesArray;

    function certifyDocument(
        string memory _hash
        
    ) 
        public
    {
        Stamp memory stamp = Stamp({
            hash: _hash,
            blockNumber: block.number
        }); 

        certifiedHashesArray.push(stamp);
        certifiedHashesMap[_hash] = stamp;
        
    }

    function allStamps()
        public
        view
        returns (Stamp[] memory coll)
    {
        return certifiedHashesArray;
    }
}