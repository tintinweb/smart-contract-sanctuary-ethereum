//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Copyright {

    string public copyright_id;

    struct Cover {
        uint256 id;
        string title;
        string description;
        address owner;
    }

    Cover[] covers;

    uint256 public numCovers;

    function createCopyright(string memory _title, string memory _description) external returns (uint256) {
        covers.push(Cover(numCovers, _title, _description, msg.sender));
        numCovers++;
        return numCovers - 1;
    }

    function getCopyright(uint256 _id) external view returns (string memory, string memory, address, uint256, address) {
        Cover storage cover = covers[_id];
        return (cover.title, cover.description, cover.owner, block.timestamp, block.coinbase);
    }

    function getAllcover() external view returns (Cover[] memory) {
        return covers;
    }

//    function getCoverOwner(address _owner) external view returns (Cover[]) {
//        Cover[] storage authorCover = new Cover[](0);
//        for (uint256 i = 0; i < numCovers; i++) {
//            Cover storage cover = covers[i];
//            if (cover.owner == _owner) {
//                authorCover.push(cover);
//            }
//        }
//        return authorCover;
//    }
//
//    function getAllcover() external view returns (Cover[]) {
//        Cover[] storage allCover = new Cover[](numCovers);
//        for (uint256 i = 0; i < numCovers; i++) {
//            Cover storage cover = covers[i];
//            allCover.push(cover);
//        }
//        return allCover;
//    }
}