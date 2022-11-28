/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract HashIDCertifier {

    struct Stamp {
        string hash; 
        uint256 blockNumber;
        uint256 order;
    }    

    mapping(string => Stamp[]) public certifiedHashesMap;

    Stamp[] public certifiedHashesArray;

    function certifyDocument(
        string memory _id, 
        string memory _hash
    ) 
        public
    {        
        Stamp memory stamp = Stamp({
            hash: _hash,
            blockNumber: block.number,
            order: certifiedHashesMap[_id].length + 1
        }); 

        certifiedHashesArray.push(stamp);
        certifiedHashesMap[_id].push(stamp);
    }

    function allStamps()
        public
        view
        returns (Stamp[] memory coll)
    {
        return certifiedHashesArray;
    }

    function allStampsByID(
        string memory _id
    )
        public
        view
        returns (Stamp[] memory coll)
    {
        return certifiedHashesMap[_id];
    }

    function lastByID(
        string memory _id
    )
        public
        view
        returns (Stamp memory element)
    {
        uint lastIndex = certifiedHashesMap[_id].length-1;
        return certifiedHashesMap[_id][lastIndex];
    }
}