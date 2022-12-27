/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Ownable From OpenZeppelin Contracts v4.4.1 (Ownable.sol)

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Based on ERC1155 implementation by Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)

contract ERC1155_Comic is Ownable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(uint256 => string) public tokenURIs;

    mapping(uint256 => bool) public uriLocked;

    mapping(uint256 => bool) public mintIdLocked;

    // ERC-2981: NFT Royalty Standard
    address payable private _royaltyRecipient;

    uint256 private _royaltyBps;
    
    mapping(uint256 => uint256) private _royaltyBpsTokenId;

    constructor() {
        _royaltyRecipient = payable(msg.sender);
        _royaltyBps = 250;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0xd9b67a26 || // ERC1155
            interfaceId == 0x0e89341c || // ERC1155MetadataURI
            interfaceId == 0x2a55205a;   // ERC2981 = 0x2a55205a;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }

    /*//////////////////////////////////////////////////////////////
                        COMIC MINT/BURN/URI LOGIC
    //////////////////////////////////////////////////////////////*/

    function mint (
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual onlyOwner {
        require(!mintIdLocked[id], "No more minting allowed");
        _mint(to, id, amount, data);
    }

    function batchMint (
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes calldata data
    ) public virtual onlyOwner {
        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                require(!mintIdLocked[ids[i]], "No more minting allowed");
            }
        }
        _batchMint(to, ids, amounts, data);
    }

    function mintMultipleUsers(
        address[] calldata recipients,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public onlyOwner {
        require(!mintIdLocked[id], "No more minting allowed");
        unchecked {
            for (uint256 i = 0; i < recipients.length; i++) {
                _mint(recipients[i], id, amount, data);
            }   
        }
    }


    function uri(uint256 id) public view virtual returns (string memory) {
        return tokenURIs[id];
    }

    function setUri(uint256[] calldata tokenId, string[] calldata newUri) public onlyOwner {
        require(tokenId.length == newUri.length, "Length mismatch");

        unchecked {    
            for (uint256 i = 0; i < tokenId.length; i++) {
                require(!uriLocked[tokenId[i]], "URI locked");

                tokenURIs[tokenId[i]] = newUri[i];

                emit URI(newUri[i], tokenId[i]);
            }
        }
    }

    function lockUri(uint256[] calldata tokenId) public onlyOwner {
        unchecked {
            for (uint256 i = 0; i < tokenId.length; i++) {
                uriLocked[tokenId[i]] = true;
            }
        }
    }

    function lockMintId(uint256[] calldata tokenId) public onlyOwner {
        unchecked {
            for (uint256 i = 0; i < tokenId.length; i++) {
                mintIdLocked[tokenId[i]] = true;
            }
        }
    }

    function burn (
        address from,
        uint256 id,
        uint256 amount
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");
        _burn(from, id, amount);
    }

    function batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");
        _batchBurn(from, ids, amounts);
    }

    /*//////////////////////////////////////////////////////////////
                        EIP-2981 ROYALTY STANDARD
    //////////////////////////////////////////////////////////////*/
    function setRoyaltyBps(uint256 royaltyPercentageBasisPoints) public onlyOwner {
        _royaltyBps = royaltyPercentageBasisPoints;
    }

    function setRoyaltyBpsForTokenId(uint256 tokenId, uint256 royaltyPercentageBasisPoints) public onlyOwner {
        _royaltyBpsTokenId[tokenId] = royaltyPercentageBasisPoints;
    }

    function setRoyaltyReceipientAddress(address payable royaltyReceipientAddress) public onlyOwner {
        _royaltyRecipient = royaltyReceipientAddress;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        uint256 bps;

        if(_royaltyBpsTokenId[tokenId] > 0) {
            bps = _royaltyBpsTokenId[tokenId];
        }
        else {
            bps = _royaltyBps;
        }

        uint256 royalty = (salePrice * bps) / 10000;
        return (_royaltyRecipient, royalty);
    }
    
}

abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}