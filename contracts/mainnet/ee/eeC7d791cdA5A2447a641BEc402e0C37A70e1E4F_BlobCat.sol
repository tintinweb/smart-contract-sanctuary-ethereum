// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

import "./erc721.sol";
import "./ownable.sol";
import "./erc2981.sol";


library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library SafeTransferLib {
    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }
}

contract BlobCat is ERC721, Ownable, ERC2981 {
    string baseURI = "";
    uint256 totalSupply = 0;
    uint256 public activationTimestamp;


    // should be less than difference between stage amounts
    uint256 public immutable transactionLimit = 20;

    uint256 public blobCatPrice = 0.035 ether;

    uint256 public immutable totalBlobCats = 1000;

    constructor(uint256 _activationTimestamp) ERC721("blobcat", "BLOBCAT") {
        _royaltyRecipient = msg.sender;
        _royaltyFee = 700;
        activationTimestamp = _activationTimestamp;
    }

    function setPrice(uint256 newPrice) onlyOwner public {
        blobCatPrice = newPrice;
    }

    function setActivationTimestamp(uint256 _activationTimestamp) onlyOwner public {
        activationTimestamp = _activationTimestamp;
    }


    function setRoyaltyRecipient(address recipient) onlyOwner public {
        _royaltyRecipient = recipient;
    }

    function setRoyaltyFee(uint256 fee) onlyOwner public {
        _royaltyFee = fee;
    }

    function setBaseURI(string memory _newBaseURI) onlyOwner public {
        baseURI = _newBaseURI;
    }

    function mintBlobCat(uint256 amount) public payable {
        require(amount > 0, "blobblobBLOBBLOB blobblob blobblob BLOB blobBLOB BLOBBLOB blobBLOBblobblob blobBLOBblobblob");
        require(amount <= transactionLimit, "blobblobBLOBBLOB blobblob blobblob BLOB BLOBblobblobBLOB blobBLOBblob BLOBblobblobblob BLOBBLOBBLOBBLOBblob");
        require(totalSupply + amount <= totalBlobCats, "BLOBblobblobblob blobblob BLOB blobBLOB BLOBBLOB BLOBBLOBBLOBblob blobblobBLOBBLOB");
        require(activationTimestamp <= block.timestamp, "blobblobblobblob blobBLOBblob BLOBBLOBblobblob blobblobBLOBBLOB");
        require(msg.value >= blobCatPrice * amount, "blobblobBLOB blobBLOB blobblob blobblobBLOB BLOB blobblobBLOBBLOB blobblob blobblob BLOB blobblobblob blob BLOBBLOB blobBLOBblob blobBLOBBLOBBLOB");
        require(msg.value == blobCatPrice * amount, "blobblobBLOB blobBLOB blobblob blobblobBLOB BLOB blobblobBLOBBLOB blobblob blobblob BLOB blobBLOBblobBLOB BLOBBLOBblobblob blobblobblob blob");
        uint256 currentSupply = totalSupply;
        for(uint i; i < amount; i++) {
            _safeMint(msg.sender, currentSupply + i);
        }
        totalSupply += amount;
    }

    function withdraw() public {
        SafeTransferLib.safeTransferETH(owner(), address(this).balance);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (bytes(baseURI).length == 0) return "ipfs://QmUy84PeTDoTWSpLvtXpiiocA9AJL2DeCd2cGfj6UizY3L";
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));

    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(ERC721, ERC2981)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

}