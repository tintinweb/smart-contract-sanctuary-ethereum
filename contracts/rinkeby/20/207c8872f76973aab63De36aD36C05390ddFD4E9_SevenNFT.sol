// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ISevenNFTMarketplace.sol";

contract SevenNFT is ERC1155, Ownable {
    uint256 public total = 0;
    uint256 public maxRoyalty = 10;
    mapping(uint256 => string) public uris;
    ISevenNFTMarketplace public marketPlace;

    mapping(string => bool) private tokenName;
    mapping(uint256 => Attr) public attributes;

    struct Attr {
        address minter;
        uint256 royalty;
        uint256 createTime;
        string metadata;
        bool stackable;
    }

    struct UserBalance {
        address minter;
        uint256 royalty;
        uint256 createTime;
        string metadata;
        bool stackable;
        uint256 amount;
        uint256 tokenId;
    }

    constructor() ERC1155("https://ipfs.io/ipfs/{id}") {}

    // Events
    event MintEvent(uint256 tokenId, address minter);

    function uri(uint256 tokenId) public view override returns (string memory) {
        return (string(abi.encodePacked("https://ipfs.io/ipfs/", uris[tokenId])));
    }

    function mint(
        address to,
        string memory metadata,
        uint256 royalty,
        uint256 price,
        uint256 amount,
        bool stackable,
        bool forSale,
        uint256 auctionTime
    ) public payable {
        uint256 tokenId = total + 1;
        _mint(to, tokenId, amount, "");
        uris[tokenId] = metadata;

        attributes[tokenId] = Attr(msg.sender, royalty, block.timestamp, metadata, stackable);
        emit MintEvent(tokenId, msg.sender);

        if (forSale && auctionTime > 0) {
            marketPlace.putOnAuction(tokenId, price, amount, auctionTime);
        } else if (forSale) {
            marketPlace.putNftOnSale(tokenId, price, amount);
        }

        total++;
    }

    function updateTokenAttributes(
        uint256 tokenId,
        uint256 royalty,
        string memory metadata,
        bool stackable
    ) public {
        address minter = attributes[tokenId].minter;
        require(minter == msg.sender, "caller is not token owner");
        require(!marketPlace.isTraded(tokenId), "NFT traded you can't update anymore");

        if (royalty <= maxRoyalty && royalty >= 0) {
            attributes[tokenId].royalty = royalty;
        }
        attributes[tokenId].metadata = metadata;
        attributes[tokenId].stackable = stackable;
        uris[tokenId] = metadata;
    }

    function getUserTokens(address user) external view returns (UserBalance[] memory) {
        uint256 size = 0;
        for (uint256 i = 1; i <= total; i++) {
            uint256 blnc = balanceOf(user, i);
            if (blnc > 0) size++;
        }

        UserBalance[] memory balances = new UserBalance[](size);

        uint256 counter = 0;
        for (uint256 i = 1; i <= total; i++) {
            uint256 blnc = balanceOf(user, i);
            if (blnc > 0) {
                balances[counter] = UserBalance(
                    attributes[i].minter,
                    attributes[i].royalty,
                    attributes[i].createTime,
                    attributes[i].metadata,
                    attributes[i].stackable,
                    blnc,
                    i
                );
                counter++;
            }
        }

        return balances;
    }

    function isStackable(uint256 _tokenId) external view returns (bool) {
        return attributes[_tokenId].stackable;
    }

    function getMetaData(uint256 _tokenId) external view returns (string memory) {
        return attributes[_tokenId].metadata;
    }

    function setMarketPlace(address _marketAddress) public onlyOwner {
        marketPlace = ISevenNFTMarketplace(_marketAddress);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        _burn(from, id, amount);
    }
}