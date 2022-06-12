// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC2981PerTokenRoyalties.sol";

/// @custom:security-contact [email protected]
contract LondonToken is ERC1155, Ownable, ERC2981PerTokenRoyalties {
    constructor(string memory uri_) ERC1155(uri_) {}

    string public name = "London Collection";

    uint256 public totalSupply;

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        string memory cid,
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyOwner {
        _mint(account, id, amount, "");
        if (royaltyValue > 0) {
            _setTokenRoyalty(id, royaltyRecipient, royaltyValue);
        }
        _cids[id] = cid;
        totalSupply += amount;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] memory cids,
        address[] memory royaltyRecipients,
        uint256[] memory royaltyValues
    ) public onlyOwner {
        require(
            ids.length == royaltyRecipients.length &&
                ids.length == royaltyValues.length,
            "ERC1155: Arrays length mismatch"
        );
        _mintBatch(to, ids, amounts, "");

        for (uint256 i; i < ids.length; i++) {
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(
                    ids[i],
                    royaltyRecipients[i],
                    royaltyValues[i]
                );
            }

            // update IPFS CID
            _cids[ids[i]] = cids[i];
        }

        uint256 count;
        for (uint256 i = 0; i < ids.length; i++) {
            for (uint256 j = 0; j < amounts.length; j++) {
                count += ids[i] * amounts[j];
            }
        }
        totalSupply += count;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function mintWithCreator(
        address creator,
        address to,
        uint256 tokenId,
        string memory cid,
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyOwner {
        require(to != address(0), "mint to the zero address");

        _balances[tokenId][to] += 1;
        totalSupply += 1;
        _cids[tokenId] = cid;

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }

        address operator = _msgSender();
        emit TransferSingle(operator, address(0), creator, tokenId, 1);
        emit TransferSingle(operator, creator, to, tokenId, 1);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setRoyalties(
        uint256 tokenId,
        address royaltyRecipient,
        uint256 royaltyValue
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
    }

    function setCID(uint256 tokenId, string memory cid) public onlyOwner {
        _cids[tokenId] = cid;
    }
}