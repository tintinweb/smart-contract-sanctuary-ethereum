// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC721.sol";
import "./Ownable.sol";

contract FlammablePunksV2 is ERC721, Ownable {
    using Strings for uint256;
    uint256 private tokenCounter;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) private _tokenVitals;

    constructor() ERC721("Flammable Punks V2", "FLAMS") {}

    function mintPunks(uint256 _quantity) public {
        require(tokenCounter < 10000, "All punks have been rescued!");
        require(_quantity > 0, "You must mint more than 0 punks");
        require(_quantity <= 5, "You can only mint 5 punks at a time.");
        require(
            tokenCounter + _quantity <= 10000,
            "There aren't that many punks left to be saved."
        );

        address rescuer = msg.sender;
        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(rescuer, tokenCounter);
            _setTokenURI(
                tokenCounter,
                string(
                    abi.encodePacked(
                        "https://ipfs.io/ipfs/QmcAWGaNav1PrYMGQSSFHSSzeysFXQWPHWs5MFyf8VNydV/",
                        tokenCounter.toString(),
                        "%20-%200.json"
                    )
                )
            );
            _tokenVitals[tokenCounter] = 0;
            tokenCounter = tokenCounter + 1;
        }
    }

    function rescuePunk(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "Token not in wallet. To rescue a punk you must own it first."
        );
        require(
            _tokenVitals[tokenId] == 0,
            "You are too kind, this punk has already been rescued."
        );
        _setTokenURI(
            tokenId,
            string(
                abi.encodePacked(
                    "https://ipfs.io/ipfs/QmcAWGaNav1PrYMGQSSFHSSzeysFXQWPHWs5MFyf8VNydV/",
                    tokenId.toString(),
                    "%20-%201.json"
                )
            )
        );
        _tokenVitals[tokenId] = 1;
    }

    function murderPunk(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "Token not in wallet. To murder a punk you must own it first."
        );
        require(
            _tokenVitals[tokenId] == 0,
            "Please have mercy, this punk is already dead."
        );
        _setTokenURI(
            tokenId,
            string(
                abi.encodePacked(
                    "https://ipfs.io/ipfs/QmcAWGaNav1PrYMGQSSFHSSzeysFXQWPHWs5MFyf8VNydV/",
                    tokenId.toString(),
                    "%20-%202.json"
                )
            )
        );
        _tokenVitals[tokenId] = 2;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];

        return _tokenURI;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}