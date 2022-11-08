pragma solidity ^0.8.0;

contract TestRemove {
    uint256[] array1 = [1, 2, 3, 4, 5];
    uint256[] array2 = [6, 7, 8, 9, 10, 14, 15, 16];
    uint256[] array3 = [11, 12, 13];

    mapping(uint256 => uint256[]) allArtworkEditions;
    uint256[] _allArtworks = [100, 250, 400, 600];

    constructor() {
        allArtworkEditions[100] = array1;
        allArtworkEditions[250] = array2;
        allArtworkEditions[400] = array3;
    }

    function _getEditionIndex(uint256 editionID)
        private
        view
        returns (uint256, uint256)
    {
        for (uint256 j = 0; j < _allArtworks.length; j++) {
            uint256 artworkID = _allArtworks[j];
            for (uint256 k = 0; k < allArtworkEditions[artworkID].length; k++) {
                if (allArtworkEditions[artworkID][k] == editionID) {
                    return (artworkID, k);
                }
            }
        }
        return (0, 0);
    }

    function remove(uint256 editionID) public {
        uint256 artworkID;
        uint256 index;
        (artworkID, index) = _getEditionIndex(editionID);
        if (artworkID > 0 && index >= 0) {
            for (
                uint256 i = index;
                i < allArtworkEditions[artworkID].length - 1;
                i++
            ) {
                allArtworkEditions[artworkID][index] = allArtworkEditions[
                    artworkID
                ][i + 1];
            }
            allArtworkEditions[artworkID].pop();
        }
    }

    function getItem(uint256 artworkID, uint256 index)
        public
        view
        returns (uint256)
    {
        return allArtworkEditions[artworkID][index];
    }

    function getLength(uint256 artworkID) public view returns (uint256) {
        return allArtworkEditions[artworkID].length;
    }
}