//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Copyright {
    // copyright is a string of bytes, unqiuely assigned to each cover
    string public copyright_id;

    // Chapter is a struct that contains the title, context, and address of the cover
    // Representing a chapter in the book(cover)
    struct Chapter {
        uint256 id;
        string title;
        string context;
        string status;
    }

    // Cover is a struct that contains the title, description, and address of the cover
    // Representing a cover in the book(cover) also the data for NFT
    struct Cover {
        uint256 id;
        string title;
        string description;
        address owner;
        string status;

        Chapter[] chapters;
    }


    mapping(uint256 => Cover) public covers;

    mapping(uint256 => Chapter) public chapters;

    uint256 public numCovers;
    uint256 public numChapters;

    // modifier
    modifier onlyOwner(uint256 _id) {
        require(covers[_id].owner == msg.sender);
        _;
    }

    // create a new cover
    // @param _title: string - title of the cover
    // @param _description: string - description of the cover
    // @param _owner: address - address of the owner of the cover
    // @returns uint256 - id of the cover
    function createCopyright(string memory _title, string memory _description) external returns (uint256) {
        Cover storage cover = covers[numCovers];
        cover.id = numCovers;
        cover.title = _title;
        cover.description = _description;
        cover.owner = msg.sender;
        numCovers++;
        return numCovers - 1;
    }

    // create a new chapter
    // @param _title: string - title of the chapter
    // @param _context: string - context of the chapter
    // @param _cover: uint256 - id of the cover
    // @returns uint256 - id of the chapter
    function createChapter(uint256 _coverId, string memory _title, string memory _context) external onlyOwner(_coverId) returns (uint256) {
        require(covers[_coverId].id == 0, "error");
        Chapter memory newChapter = Chapter({
        id : numChapters,
        title : _title,
        context : _context,
        status : "active"
        });
        covers[_coverId].chapters.push(newChapter);
        numChapters++;
        return numChapters - 1;
    }

    // get the cover by id
    // @param _id: uint256 - id of the cover
    // @returns Cover - cover with the id
    function getCopyright(uint256 _id) external view returns (string memory, string memory, address, uint256, address, string memory, Chapter[] memory) {
        Cover storage cover = covers[_id];
        return (cover.title, cover.description, cover.owner, block.timestamp, block.coinbase, cover.status, cover.chapters);
    }

    // get all the covers for specific user
    function getAuthorCover() external view returns (Cover[] memory){
        uint256 resultCount;
        for (uint256 i = 0; i < numCovers; i++) {
            if (covers[i].owner == msg.sender) {
                resultCount++;
            }
        }
        Cover[] memory result = new Cover[](resultCount);
        uint j;
        for (uint256 i = 0; i < numCovers; i++) {
            if (covers[i].owner == msg.sender) {
                result[j] = covers[i];
                j++;
            }
        }
        return result;
    }

    // get a chapter by id
    // @param _id: uint256 - id of the chapter
    // @returns Chapter - chapter struct
    function getChapter(uint256 _id) external view returns (string memory, string memory, uint256, address) {
        Chapter storage chapter = chapters[_id];
        return (chapter.title, chapter.context, block.timestamp, block.coinbase);
    }

    // get all the chapters for specific cover
    // @param _id: uint256 - id of the cover
    // @returns Chapter[] - array of chapters
    function getChapters(uint256 _coverId) external view returns (Chapter[] memory) {
        Cover storage cover = covers[_coverId];
        return cover.chapters;
    }

    // update the information of a chapter
    // @param _id: uint256 - id of the chapter
    // @param _title: string - title of the chapter
    // @param _description: string - context of the chapter
    // @returns uint - id of the chapter
    function updateChapter(uint256 _id, string memory _title, string memory _context) external onlyOwner(_id) returns (uint256) {
        Chapter storage chapter = chapters[_id];
        chapter.title = _title;
        chapter.context = _context;
        return _id;
    }

    // update the information of a cover
    // @param _id: uint256 - id of the cover
    // @param _title: string - title of the cover
    // @param _description: string - description of the cover
    // @returns uint - id of the cover
    function updateCover(uint256 _id, string memory _title, string memory _description) external onlyOwner(_id) returns (uint256)  {
        Cover storage cover = covers[_id];
        cover.title = _title;
        cover.description = _description;
        return _id;
    }
}