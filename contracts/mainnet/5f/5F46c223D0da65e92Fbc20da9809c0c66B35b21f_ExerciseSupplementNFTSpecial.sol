// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";
import "./ERC721Burnable.sol";

contract ExerciseSupplementNFTSpecial is ERC721, Ownable, ERC721Burnable{
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    string public baseURI;
    string public baseExtension = ".json";
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private admins;

    modifier onlyAdmin() {
        require(admins.contains(_msgSender()), "NOT ADMIN");
        _;
    }

    constructor(
        string memory _initBaseURI
    ) ERC721("ExerciseSupplementNFT2", "ESPLNFT2") {
        setBaseURI(_initBaseURI);
        admins.add(msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function safeMint(address to) public payable {
        require(_msgSender().code.length > 0 || admins.contains(_msgSender()), 
            "Address can't mint NFT"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function nextTokenIdToMint() public view returns(uint256) {
        return _tokenIdCounter.current();
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

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function updateAdmin(address _adminAddr, bool _flag) external onlyAdmin {
        require(_adminAddr != address(0), "INVALID ADDRESS");
        if (_flag) {
            admins.add(_adminAddr);
        } else {
            admins.remove(_adminAddr);
        }
    }

    function getAdmins() external view returns (address[] memory) {
        return admins.values();
    }
}