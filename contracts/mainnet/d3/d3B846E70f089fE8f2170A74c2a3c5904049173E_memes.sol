// SPDX-License-Identifier: MIT
// This is just a test NFT collections that helps decentralized Finance, NFT Finance, Social Finance and others kind Dapps building on testnet.
pragma solidity ^0.8.14;

import "./Counters.sol";
import "./Strings.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC721Receiver.sol";
import "./IERC165.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./ERC721.sol";

// This is just a test NFT collections that helps decentralized Finance, NFT Finance, Social Finance and others kind Dapps building on testnet.
contract memes is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private supply;

    string public uriPrefix =
        "https://static.memeslab.xyz/json/";
    string public uriSuffix = "";

    uint256 public mintCost = 0 ether;
    uint256 public maxSupply = 5555;
    mapping(address => uint256) public mintCount;

    constructor() ERC721("memes", "memes") {}

    modifier mintRequire(uint256 _mintAmount) {
        require(
            supply.current() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        _;
    }

    function getBlockTimestamp() public view returns(uint) {
        return block.timestamp;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 _mintAmount) public payable mintRequire(_mintAmount) {
        require(getBlockTimestamp() >=1678039200,"status false!");
        require(msg.value >= mintCost * _mintAmount, "Insufficient funds!");

        if (mintCount[msg.sender]>0) {
            mintCost = 0.004 ether;
            require(msg.value >= mintCost * _mintAmount, "Insufficient funds!");
        }else {
            require(msg.value >= mintCost * ( _mintAmount-1 ), "Insufficient funds!");
        }


        _mintLoop(msg.sender, _mintAmount);
        mintCount[msg.sender] += _mintAmount;
    }

    function getmintCount() public view returns (uint256) {
        return mintCount[msg.sender];
    }

    function walletOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory currentBaseURI = _baseURI();
        return (
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : ""
        );
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(_receiver, supply.current());
            supply.increment();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
// This is just a test NFT collections that helps decentralized Finance, NFT Finance, Social Finance and others kind Dapps building on testnet.