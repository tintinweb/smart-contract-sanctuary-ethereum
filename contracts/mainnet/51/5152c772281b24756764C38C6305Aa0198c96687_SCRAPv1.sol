/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
    unchecked {
        uint256 length = 1;
        uint256 valueCopy = value;
        if (valueCopy >= 10**64) {
            valueCopy /= 10**64;
            length += 64;
        }
        if (valueCopy >= 10**32) {
            valueCopy /= 10**32;
            length += 32;
        }
        if (valueCopy >= 10**16) {
            valueCopy /= 10**16;
            length += 16;
        }
        if (valueCopy >= 10**8) {
            valueCopy /= 10**8;
            length += 8;
        }
        if (valueCopy >= 10**4) {
            valueCopy /= 10**4;
            length += 4;
        }
        if (valueCopy >= 10**2) {
            valueCopy /= 10**2;
            length += 2;
        }
        if (valueCopy >= 10**1) {
            length += 1;
        }
        string memory buffer = new string(length);
        uint256 ptr;
        assembly {
            ptr := add(buffer, add(32, length))
        }
        while (true) {
            ptr--;
            assembly {
                mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
            }
            value /= 10;
            if (value == 0) break;
        }
        return buffer;
    }
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
    unchecked {
        uint256 length = 1;
        uint256 valueCopy = value;
        if (valueCopy >= 1 << 128) {
            valueCopy >>= 128;
            length += 16;
        }
        if (valueCopy >= 1 << 64) {
            valueCopy >>= 64;
            length += 8;
        }
        if (valueCopy >= 1 << 32) {
            valueCopy >>= 32;
            length += 4;
        }
        if (valueCopy >= 1 << 16) {
            valueCopy >>= 16;
            length += 2;
        }
        if (valueCopy >= 1 << 8) {
            valueCopy >>= 8;
            length += 1;
        }
        return toHexString(value, length);
    }
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721A is IERC721, IERC721Metadata {
    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApproveToCaller();
    error ApprovalToCurrentOwner();
    error BalanceQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();
    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
    }
    struct AddressData {
        uint64 balance;
        uint64 numberMinted;
        uint64 numberBurned;
        uint64 aux;
    }
    function totalSupply() external view returns (uint256);
}

interface NFT is IERC721A {

}

contract SCRAPv1 is Ownable {

    function name(address _collectionAddr) external view returns (string memory) {
        return NFT(_collectionAddr).name();
    }

    function symbol(address _collectionAddr) external view returns (string memory) {
        return NFT(_collectionAddr).symbol();
    }

    function totalSupply(address _collectionAddr) public view returns (uint256) {
        uint256 _total = 0;
        try NFT(_collectionAddr).totalSupply()  returns (uint256 v) {
            _total = v;
        } catch {
        }
        return _total;
    }

    function balanceOf(address _collectionAddr, address owner) external view returns (uint256) {
        return NFT(_collectionAddr).balanceOf(owner);
    }

    function ownerOf(address _collectionAddr, uint256 tokenId) external view returns (address) {
        return NFT(_collectionAddr).ownerOf(tokenId);
    }

    function tokenURI(address _collectionAddr, uint256 _tokenId) external view returns (string memory) {
        return NFT(_collectionAddr).tokenURI(_tokenId);
    }

    function _tokenURI(address _collectionAddr, uint256 _start, uint256 _amount) external view returns (string[] memory) {
        string[] memory tokenURIs = new string[](_amount);
        uint256 uriIndex = 0;
        for (uint256 i = _start; i < _start + _amount; ++i) {
            try NFT(_collectionAddr).tokenURI(i) returns (string memory v) {
                tokenURIs[uriIndex] = v;
                uriIndex++;
            } catch {
                tokenURIs[uriIndex] = "";
                continue;
            }
        }
        return tokenURIs;
    }

    function _checkReveal(address _collectionAddr, uint256 _start, uint256 _amount) external view returns (string[] memory) {
        string[] memory tokenURIs = new string[](2);
        uint256 uriIndex = 0;
        for (uint256 i = _start; i < _start + _amount; ++i) {
            if(uriIndex < 2){
                try NFT(_collectionAddr).tokenURI(i) returns (string memory v) {
                    tokenURIs[uriIndex] = v;
                    uriIndex++;
                } catch {
                    continue;
                }
            }else{
                break;
            }
        }
        return tokenURIs;
    }

    function _startIndex(address _collectionAddr, uint256 _start, uint256 _amount) external view returns (string memory) {
        uint256 uriIndex = 0;
        string memory _tokenId = "-1";
        for (uint256 i = _start; i < _start + _amount; ++i) {
            if(uriIndex < 1){
                try NFT(_collectionAddr).tokenURI(i) {
                    _tokenId = Strings.toString(i);
                    break;
                } catch {
                    continue;
                }
            }else{
                break;
            }
        }
        return _tokenId;
    }

}