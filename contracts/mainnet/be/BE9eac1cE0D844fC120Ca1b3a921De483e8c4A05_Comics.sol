// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Ownable.sol";

interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// @author: jolan.eth
contract Comics is Ownable {
    string public symbol = "COMICS";
    string public name = "0N1 Comics";
    string public CID;

    address public NANOHUB;

    uint256 private currentId = 1;

    mapping(uint256 => uint256) private packedOwnerships;
    mapping(address => uint256) private packedAddressData;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    constructor() {}

    function setCID(string memory _CID)
    public onlyOwner {
        CID = _CID;
    }

    function setNANOHUB(address _NANOHUB)
    public onlyOwner {
        NANOHUB = _NANOHUB;
    }

    function mintComics(address to)
    public {
        require(msg.sender == NANOHUB, "error NANOHUB");
        _mint(to, 1);
    }

    function transferFrom(address from, address to, uint tokenId)
    public {
        require(msg.sender == NANOHUB, "error NANOHUB");
        _transfer(from, to, tokenId);
    }

    function exist(uint256 tokenId)
    public view returns (bool) {
        return 1 <= tokenId && tokenId < currentId && (
            packedOwnerships[tokenId] & (1 << 224) == 0
        );
    }

    function supportsInterface(bytes4 interfaceId)
    public pure returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function totalSupply()
    public view returns (uint256) {
        unchecked {
            return currentId - 1;
        }
    }

    function balanceOf(address owner)
    public view returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return packedAddressData[owner] & ((1 << 64) - 1);
    }

    function ownerOf(uint256 tokenId)
    public view returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    function tokenURI(uint256 tokenId)
    public view returns (string memory) {
        if (!exist(tokenId)) revert URIQueryForNonexistentToken();
        return string(
            abi.encodePacked("ipfs://", CID, "/", _toString(tokenId))
        );
    }

    function _mint(address to, uint256 quantity)
    internal {
        uint256 startTokenId = currentId;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        unchecked {
            packedAddressData[to] += quantity * ((1 << 64) | 1);
            packedOwnerships[startTokenId] = (
                _addressToUint256(to) |
                (block.timestamp << 160) |
                (_boolToUint256(quantity == 1) << 225)
            );

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            while (updatedIndex < end)
                emit Transfer(address(0), to, updatedIndex++);

            currentId = updatedIndex;
        }
    }

    function _transfer(address from, address to, uint256 tokenId)
    private {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from)
            revert TransferFromIncorrectOwner();
        if (to == address(0))
            revert TransferToZeroAddress();

        unchecked {
            --packedAddressData[from];
            ++packedAddressData[to];

            packedOwnerships[tokenId] =
                _addressToUint256(to) | (block.timestamp << 160) | (1 << 225);

            if (prevOwnershipPacked & (1 << 225) == 0) {
                uint256 nextTokenId = tokenId + 1;
                if (packedOwnerships[nextTokenId] == 0)
                    if (nextTokenId != currentId)
                        packedOwnerships[nextTokenId] = prevOwnershipPacked;
            }
        }

        emit Transfer(from, to, tokenId);

        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, ''))
                revert TransferToNonERC721ReceiverImplementer();
    }

    function _packedOwnershipOf(uint256 tokenId)
    private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (1 <= curr)
                if (curr < currentId) {
                    uint256 packed = packedOwnerships[curr];
                    if (packed & (1 << 224) == 0) {
                        while (packed == 0) {
                            packed = packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    function _unpackedOwnership(uint256 packed)
    private pure returns (address, uint64, bool) {
        return (
            address(uint160(packed)),
            uint64(packed >> 160),
            packed & (1 << 224) != 0
        );
    }

    function _initializeOwnershipAt(uint256 index)
    internal {
        if (packedOwnerships[index] == 0)
            packedOwnerships[index] = _packedOwnershipOf(index);
    }

    function _ownershipOf(uint256 tokenId)
    internal view returns (address, uint64, bool) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721TokenReceiver(to).onERC721Received(
            msg.sender, from, tokenId, _data
        ) returns (bytes4 retval) {
            return retval == ERC721TokenReceiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0)
                revert TransferToNonERC721ReceiverImplementer();
            else assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    function _toString(uint256 value)
    private pure returns (string memory) {
        if (value == 0) return "0";

        uint256 digits;
        uint256 tmp = value;

        while (tmp != 0) {
            digits++;
            tmp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function _addressToUint256(address value)
    private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    function _boolToUint256(bool value)
    private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    error TransferToNonERC721ReceiverImplementer();
    error OwnerQueryForNonexistentToken();
    error URIQueryForNonexistentToken();
    error BalanceQueryForZeroAddress();
    error TransferFromIncorrectOwner();
    error TransferToZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

abstract contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(owner() == msg.sender, "error owner()");
        _;
    }

    constructor() { _transferOwnership(msg.sender); }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "error newOwner");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}