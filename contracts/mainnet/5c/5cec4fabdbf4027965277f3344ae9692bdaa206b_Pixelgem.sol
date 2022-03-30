/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
   Pixelgem

   Isaac
   0x29F41098F6d8c733A877dDda9Efa837e4115f15D
   pixelgem.eth
   pixelgem.io

   Pixelgem was inspired by OnChain Monkey.

   Pixelgem is a collection of 888 unique fully on-chain SVG gem NFTs with the following properties:
   - a single Ethereum transaction created everything
   - all metadata on chain
   - all images on chain in svg format
   - all created in the constraints of a single txn without need of any other txns to load additional data
   - no use of other deployed contracts
   - there are 4 traits with 37 values
   - everything on chain can be used in other apps and collections in the future

████████████████████████████████████████████████████████████████████
██████████████████▓▓▒▒▒▒▒▒▒▒▒▒▓▓▒▒▓▓████▒▒▒▒▓▓▒▒▒▒██████████████████
██████████████▓▓▒▒▒▒▒▒▓▓▒▒░░░░░░░░▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▒████████████████
████████████░░▒▒▒▒▒▒▒▒▒▒░░  ░░  ▒▒▒▒██▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▓▓███████████████
██████████░░░░▓▓▒▒██▒▒░░░░    ░░▒▒██▒▒▒▒██▓▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒█████████████
██████▒▒▒▒░░▒▒▓▓▒▒▒▒▒▒░░░░▒▒░░  ▓▓▒▒▒▒██▓▓▓▓▒▒░░░░▒▒▒▒██▓▓░░▓▓████████
████░░▒▒░░░░▒▒▒▒▒▒▓▓▓▓░░░░░░  ░░░░▓▓▓▓▒▒▓▓▓▓██▒▒▒▒▓▓▓▓▓▓▓▓▓▓░░▒▒██████
██████▒▒▓▓██▒▒██▓▓▓▓░░▒▒▓▓░░░░██▓▓░░▒▒░░▒▒▒▒██▓▓██▓▓░░▓▓▒▒▒▒▓▓███████
████████▒▒▒▒▓▓▒▒▓▓▓▓▓▓▒▒▓▓░░░░██▒▒▓▓▓▓▓▓▒▒▓▓▒▒▓▓▓▓▒▒▓▓▓▓▓▓▓▓█████████
██████████▓▓▒▒▓▓▓▓▓▓▒▒▒▒▒▒░░░░▓▓▒▒▒▒▓▓▒▒▓▓▓▓░░▓▓▒▒▒▒▓▓▓▓█████████████
████████████▓▓▒▒▓▓██▓▓▒▒░░▓▓▒▒▓▓░░▒▒░░░░▒▒░░░░▒▒▓▓██▒▒███████████████
████████████████░░▒▒██▓▓▓▓▒▒▓▓▓▓░░▓▓░░░░▒▒░░░░▓▓▓▓▒▒█████████████████
████████████████▓▓░░▓▓██▒▒▒▒██▓▓░░▓▓▒▒▓▓░░░░██▒▒▓▓███████████████████
████████████████████░░████▒▒▓▓▓▓░░▒▒▓▓▒▒░░██░░▓▓█████████████████████
██████████████████████▓▓████▒▒▓▓░░▒▒██░░████▓▓███████████████████████
████████████████████████████▓▓▓▓░░▒▒▓▓███████████████████████████████
██████████████████████████████▓▓▒▒▒▒█████████████████████████████████
████████████████████████████████▒▒▒▒█████████████████████████████████
██████████████████████████████▓▓▒▒▓▓▓▓███████████████████████████████
████████████████████████████████▒▒███████████████████████████████████
█████████████████████████████████████████████████████████████████████
                                                          

*/

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }


    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

contract Pixelgem is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Strings for uint256;

  uint256 public constant maxSupply = 888;
  uint256 public constant mintPrice = 0.03 ether;
  uint256 public numClaimed = 0;
  string[] private clarity = ["1","2","3","4","5","6","7","8"];
  uint8[] private clarity_w =[249, 246, 223, 180, 150, 140, 100, 50];
  string[] private gemcut = [
    '<path d="M438.824 35.915c-76.473 0-148.263 41.846-202.145 117.828-53.548 75.514-83.04 175.836-83.04 282.485 0 106.651 29.492 206.973 83.04 282.485 53.882 75.983 125.672 117.828 202.145 117.828s148.262-41.845 202.144-117.828c53.548-75.512 83.04-175.834 83.04-282.485 0-106.65-29.492-206.971-83.04-282.485C587.086 77.761 515.297 35.915 438.824 35.915zm0 791.63c-152.291 0-276.188-175.544-276.188-391.317S286.533 44.912 438.824 44.912c152.29 0 276.187 175.543 276.187 391.316S591.114 827.545 438.824 827.545z"/><path d="m565.35 564.587 48.035-40.881-24.018-73.587zm24.017-142.301 24.018-73.587-48.035-40.882zm-26.495 153.862-33.098 130.48 125.192-46.634-39.255-128.815zM315.049 296.256l33.098-130.479-125.192 46.634 39.255 128.815zM171.69 436.202l87.017 82.166 26.818-82.166-26.818-82.166zm143.359 139.946-52.839-44.97-39.255 128.816 125.192 46.633zm238.008-289.312L521.99 164.364l-75.867 18.81zm16.285-183.479-39.09 54.918 121.37 45.21c-22.296-40.738-50.291-74.916-82.28-100.128zM226.3 668.92c22.295 40.738 50.29 74.915 82.28 100.127l39.09-54.918-121.37-45.21zm358.633-232.718L556.37 300.07 438.96 186.253 321.552 300.07l-28.564 136.133 28.564 136.133 117.41 113.816L556.37 572.335zM314.297 773.427c35.188 26.175 74.94 41.646 117.095 43.304l-77.916-98.347-39.18 55.043zm132.232 43.304c42.155-1.658 81.907-17.13 117.095-43.304l-39.179-55.043-77.916 98.347zm261.268-388.947c-.568-36.865-4.855-72.454-12.353-106.046l-71.247 27.106 83.6 78.94zM563.624 98.978c-35.188-26.175-74.94-41.647-117.095-43.305l77.916 98.347 39.18-55.042zm130.193 215.679c-8.097-33.936-19.5-65.73-33.644-94.645l-37.036 121.535 70.68-26.89zm-124.475 454.39c31.989-25.212 59.984-59.39 82.28-100.128l-121.37 45.21 39.09 54.918zm90.831-116.655c14.144-28.914 25.547-60.709 33.644-94.645l-70.68-26.89 37.036 121.535zm35.271-101.726c7.498-33.592 11.785-69.18 12.353-106.045l-83.6 78.94 71.247 27.105zM182.477 321.738c-7.498 33.592-11.785 69.18-12.353 106.046l83.6-78.94-71.247-27.106zM706.23 436.202l-87.016-82.166-26.819 82.166 26.819 82.166zM562.872 296.256l52.839 44.97 39.255-128.815-125.192-46.634zM442.56 695.762v114.39l75.746-95.61zm0-633.509v114.39l75.746-18.781zM170.124 444.621c.568 36.865 4.855 72.453 12.353 106.045l71.247-27.105-83.6-78.94zm265.238 365.53V695.762l-75.747 18.78zM184.104 557.747c8.098 33.936 19.5 65.73 33.644 94.645l37.036-121.535-70.68 26.89zM431.392 55.673c-42.155 1.658-81.907 17.13-117.095 43.305l39.179 55.042 77.916-98.347zM308.58 103.357c-31.99 25.212-59.985 59.39-82.28 100.128l121.37-45.21-39.09-54.918zm-90.832 116.655c-14.144 28.915-25.546 60.71-33.644 94.645l70.68 26.89-37.036-121.535zm214.05 469.218L324.864 585.569l31.067 122.471zM324.864 286.836l106.934-103.662-75.867-18.81zm-60.328 61.863 24.017 73.587 24.018-114.469zm24.017 101.42-24.017 73.587 48.035 40.881zm264.504 135.45L446.123 689.23l75.867 18.81zM435.362 62.253l-75.747 95.609 75.747 18.78z"/></g>',
    '<path d="M828.242 429.27c-.009-.09.001-.175-.012-.264l-23.238-160.459c-.019-.126-.065-.24-.091-.364-.044-.206-.085-.412-.153-.614-.06-.175-.14-.337-.214-.502-.073-.16-.138-.321-.226-.475-.115-.202-.253-.384-.392-.568-.065-.087-.111-.181-.182-.265l-.118-.139a.039.039 0 0 1-.004-.004L704.456 148.82l-.018-.02-.012-.015c-.092-.109-.203-.19-.302-.29-.156-.158-.301-.325-.48-.466l-.024-.02c-.002 0-.003-.002-.005-.003L576.225 47.074c-.061-.049-.13-.079-.193-.124a5.34 5.34 0 0 0-.492-.315 5.396 5.396 0 0 0-.476-.25 5.551 5.551 0 0 0-.478-.185 5.491 5.491 0 0 0-.583-.169c-.073-.016-.14-.048-.213-.061L430.02 19.547c-.026-.006-.054-.009-.08-.015l-.143-.026c-.09-.017-.179-.01-.27-.023a5.375 5.375 0 0 0-.739-.061c-.225 0-.444.03-.664.056-.11.014-.217.007-.328.028l-.17.032c-.015.003-.03.004-.045.008L283.805 45.97c-.074.013-.14.045-.212.06a5.56 5.56 0 0 0-.581.17 5.58 5.58 0 0 0-.484.186c-.16.073-.315.157-.47.247a5.44 5.44 0 0 0-.496.317c-.063.045-.132.075-.193.124l-127.39 100.933c-.002 0-.004.003-.005.004l-.024.019c-.174.138-.315.3-.468.454-.103.103-.218.189-.313.302l-.014.015-.015.02L53.987 265.61c-.006.007-.01.014-.017.02l-.11.129c-.065.078-.108.166-.169.246a5.51 5.51 0 0 0-.407.59c-.085.15-.148.305-.218.46-.078.17-.16.336-.22.516-.068.2-.108.404-.152.61-.027.123-.073.239-.091.366l-23.24 160.46c-.013.088-.003.174-.011.262a5.544 5.544 0 0 0 .01 1.152c.01.086 0 .17.015.257l23.24 144.414c.005.036.02.069.026.105.027.15.074.297.114.446.052.196.105.39.177.576.048.124.11.243.168.365.098.206.202.404.323.594.032.05.05.105.085.155l94.063 137.774c.046.069.111.116.16.182.179.238.376.463.597.674.109.105.216.206.332.3.074.06.133.132.21.19l123.943 90.743c.008.006.017.01.025.015.059.042.125.074.186.114.224.15.453.284.69.397.091.043.187.078.282.116.235.096.472.176.713.238.055.014.104.04.16.053l152.713 34.305c.032.008.064.005.097.011.362.075.732.126 1.11.126h.011c.379 0 .748-.05 1.11-.126.033-.006.065-.003.098-.01l152.714-34.306c.056-.013.105-.04.16-.053.241-.063.477-.142.71-.237.096-.04.193-.074.285-.117.237-.113.466-.248.69-.397.06-.04.127-.072.185-.114.008-.006.017-.01.025-.015l123.942-90.744c.078-.056.137-.128.21-.189a5.629 5.629 0 0 0 .93-.974c.05-.066.114-.113.16-.182l94.064-137.774c.034-.05.052-.105.084-.155a5.31 5.31 0 0 0 .323-.594c.058-.122.12-.24.169-.365a5.58 5.58 0 0 0 .176-.576c.04-.15.087-.296.115-.446.006-.036.02-.069.026-.105l23.239-144.414c.014-.087.005-.17.015-.257a5.544 5.544 0 0 0 .01-1.152zm-33.993 142.845-92.83 135.968-122.249 89.503-150.373 33.78-150.373-33.78-122.249-89.503-92.83-135.968-22.908-142.36 22.89-158.048 97.922-115.341 125.914-99.763 141.634-26.031 141.634 26.03 125.914 99.764 97.922 115.341 22.89 158.048-22.908 142.36z"/><path d="m268.227 599.101-104.199-49.57v150.7l154.764 6.068zm160.71 64.725-98.174 47.568 98.174 108.295 98.175-108.295zM287.276 68.62 176.741 156.2l136.894-6.803zM161.418 170.881 74.744 272.973l82.096 45.395zm-2.484 159.959L50.41 431.173l.51 3.165 108.076 102.979 42.48-102.152zm-87.031-51.009L51.598 420.027l102.489-94.753zM52.857 446.375l19.14 118.942 81.144-23.389zM563.92 65.305l-124.5-22.882 98.23 103.392zM418.456 42.423 293.954 65.305l26.272 80.51zm282.767 649.408 81.712-119.684-81.712-23.553zM698.94 330.84 656.4 435.165l42.478 102.151 108.077-102.979.51-3.164zM156.651 691.831V548.594l-81.712 23.553zm629.227-126.513 19.14-118.943-100.284 95.553zM681.133 156.2 570.598 68.62l-26.358 80.776zM286.228 789.344l132.153 29.687-92.89-102.467zm-113.966-81.409L279.435 786.4l39.232-72.724zM578.44 786.4l107.171-78.465-146.404 5.74zm-138.946 32.63 132.152-29.686-39.262-72.78zm99.589-112.73 154.763-6.07V549.532l-104.198 49.57zm267.193-286.274-20.304-140.194-82.184 45.442zM783.13 272.974 696.457 170.88l4.577 147.488zM652.448 444.876l-58.58 144.048 98.914-47.055zM277.74 266.96l142.25-63.719-99.344-45.425zm301.788 336.3L438.05 660.044l93.356 45.234zm-159.705 56.784L278.346 603.26l48.122 102.018zM165.092 326.403l40.368 98.995 58.629-144.168zm98.914 262.521-58.58-144.047-40.334 96.992zm329.78-307.694 58.629 144.17 40.367-98.998zm-4.026-9.945 103.903 47.411-4.802-154.728-144.103-7.16zm58.668 163.894-64.415-158.397-155.076-69.465-155.075 69.465-64.415 158.397 64.383 158.317 155.107 62.255 155.109-62.255zM428.937 199.218l104.065-47.584L428.937 42.103 324.873 151.634zm-115.821-42.41-144.102 7.16-4.803 154.728 103.904-47.412zm124.768 46.433 142.25 63.72-42.906-109.146z"/></g>',
    '<path d="M563.54 178.808C493.874 76.513 423.202 11.877 422.497 11.237a4.766 4.766 0 0 0-6.406 0c-.706.64-71.377 65.276-141.042 167.57-40.937 60.112-73.56 121.313-96.966 181.907-29.307 75.867-44.167 150.993-44.167 223.293 0 151.11 128.021 274.046 285.378 274.046s285.377-122.936 285.377-274.046c0-72.3-14.86-147.426-44.166-223.293-23.407-60.594-56.03-121.795-96.967-181.906zM419.294 848.524c-152.103 0-275.848-118.663-275.848-264.517 0-161.105 75.777-306.247 139.344-399.636 60.64-89.086 122-149.317 136.504-163.082 14.49 13.747 75.737 73.854 136.368 162.883 63.63 93.435 139.48 238.646 139.48 399.835 0 145.854-123.746 264.517-275.848 264.517z"/><path d="M424.67 260.756c9.075 9.062 40.434 41.676 71.404 89.066.426.653.857 1.33 1.285 1.99-2.287-47.001-10.268-98.12-23.784-152.295-13.402 18.8-29.15 38.515-48.904 61.24zm-59.366-61.24c-13.516 54.17-21.496 105.29-23.782 152.294.427-.66.858-1.336 1.284-1.988 30.97-47.39 62.33-80.004 71.404-89.066-19.752-22.723-35.503-42.438-48.906-61.24zm204.185 352.513c13.023-25.381 24.541-50.239 35.73-77.058l-85.841-86.013c24.09 44.658 46.161 101.27 50.11 163.07z"/><path d="M419.44 266.303c-9.013 9.016-39.862 41.153-70.358 87.852-33.174 50.798-72.718 129.735-72.718 217.313 0 78.89 64.184 143.074 143.077 143.074 78.89 0 143.074-64.183 143.074-143.074 0-87.647-39.601-166.642-72.822-217.477-30.484-46.647-61.248-78.687-70.252-87.688z"/><path d="m269.019 580.28-39.47 69.413c26.311 8.822 50.798 14.906 74.368 18.41-20.17-24.073-32.966-54.51-34.898-87.823zm265.942 87.823c23.572-3.504 48.058-9.588 74.371-18.41l-39.472-69.416c-1.931 33.315-14.728 63.753-34.899 87.826zM516.756 686.4c-22.866 19.391-51.556 32.1-83.051 35.072l60.218 31.293 22.833-66.365zm-111.58 35.072c-31.496-2.972-60.185-15.68-83.052-35.072l22.832 66.365 60.22-31.293zM319.5 388.961l-85.841 86.01c11.192 26.82 22.71 51.677 35.731 77.054 3.95-61.798 26.02-118.407 50.11-163.064zm181.614 366.341c32.658 6.698 66.18 10.083 102.195 10.311 3.34-30.561 5.832-66.122 7.596-108.411-29.37 9.797-56.534 16.207-82.753 19.51l-27.038 78.59zM410.768 40.566c-16.941 16.75-51.124 52.316-89.12 101.725l40.381 41.145 48.739-142.87zM236.494 272.793c-24.451 45.23-47.25 96.811-63.171 152.676l51.513 40.393c-3.214-56.732.613-120.177 11.658-193.07zm-65.358 160.651c-11.974 44.15-19.54 90.853-20.221 139.097l72.955-97.746-52.734-41.35zm145.838-285.028a1038.485 1038.485 0 0 0-30.712 42.706 959.406 959.406 0 0 0-32.642 51.398l103.667-53.033-40.313-41.071zm15.661 675.012c24.58 8.072 50.758 12.805 77.944 13.655l-65.608-70.926-12.336 57.271zm-90.29-50.277c24.226 20.414 52.3 36.719 83.03 47.773l12.464-57.862c-30.643 6.188-62.045 9.511-95.494 10.09zm185.957 63.932c27.185-.85 53.363-5.583 77.944-13.655l-12.338-57.271-65.606 70.926zm85.203-16.159c30.73-11.054 58.803-27.359 83.03-47.773-33.45-.578-64.852-3.901-95.496-10.089l12.466 57.862zM177.736 691.963c12.686 25.002 29.475 47.746 49.512 67.442-2.94-28.674-5.182-61.594-6.814-100.081l-42.698 32.639zm-26.456-97.326c1.93 32.016 9.974 62.485 23.042 90.339l43.153-32.986c-25.88-18.145-47.657-37.009-66.194-57.353zm470.126 57.353 43.15 32.986c13.069-27.853 21.112-58.32 23.042-90.337-18.537 20.344-40.314 39.206-66.192 57.351zm65.534-68.08-76.285-102.203c-12.35 29.31-25.164 56.419-39.988 84.57l45.522 80.055c28.153-19.654 51.356-40.127 70.75-62.421zm1.024-11.372c-.681-48.242-8.247-94.944-20.22-139.094l-52.735 41.35 72.955 97.744zM521.906 148.415l-40.314 41.073 103.666 53.033a959.107 959.107 0 0 0-32.75-51.557 1039.268 1039.268 0 0 0-30.602-42.549zm-4.672-6.125c-38.007-49.426-72.183-84.983-89.122-101.727l48.737 142.873 40.385-41.145zm96.809 323.572 51.513-40.393c-15.919-55.859-38.716-107.438-63.169-152.672 11.044 72.892 14.871 136.335 11.656 193.065zm-2.41 293.541c20.035-19.695 36.823-42.438 49.51-67.44l-42.698-32.64c-1.63 38.488-3.872 71.407-6.812 100.08zM151.94 583.91c19.395 22.296 42.598 42.768 70.752 62.422l45.521-80.055c-14.823-28.148-27.638-55.257-39.99-84.57L151.94 583.91zm267.5-328.757c21.163-24.375 37.653-45.235 51.569-65.231l-51.57-151.17-51.568 151.17c13.918 19.997 30.408 40.858 51.57 65.231zm-186.995 210.24 100.968-101.167c1.385-50.956 9.621-106.918 24.477-166.484l-110.776 56.67c-13.328 80.643-18.132 149.79-14.67 210.981zm273.023-101.167 100.966 101.168c3.465-61.19-1.339-130.335-14.667-210.981l-110.778-56.671c14.858 59.571 23.093 115.532 24.479 166.484zM419.44 722.649l-70.461 36.615 70.462 76.173 70.46-76.173zm-108.712-45.937c-26.218-3.303-53.382-9.713-82.753-19.51 1.764 42.29 4.256 77.85 7.596 108.411 36.014-.228 69.536-3.613 102.194-10.311l-27.037-78.59z"/></g>',
    '<path d="M849.137 772.486a3.935 3.935 0 0 0-.044-.441 3.841 3.841 0 0 0-.088-.384 4.18 4.18 0 0 0-.115-.37 3.963 3.963 0 0 0-.185-.41c-.034-.067-.054-.138-.092-.203L436.57 59.48c-.037-.065-.088-.116-.128-.178a4.144 4.144 0 0 0-.26-.36 4.132 4.132 0 0 0-.267-.29 4.112 4.112 0 0 0-.283-.26 4 4 0 0 0-.365-.264c-.061-.04-.112-.09-.175-.127-.04-.023-.083-.034-.123-.055a3.96 3.96 0 0 0-.406-.183c-.114-.046-.227-.093-.344-.128-.127-.038-.257-.063-.388-.089-.129-.025-.256-.051-.386-.063-.128-.013-.258-.012-.388-.012s-.259-.001-.388.012c-.13.012-.258.038-.387.064-.13.025-.259.05-.386.087-.119.036-.234.084-.351.131a4.05 4.05 0 0 0-.395.178c-.043.023-.088.034-.13.058-.066.04-.12.09-.183.133-.121.08-.239.161-.352.254a4.011 4.011 0 0 0-.292.27c-.09.09-.179.182-.261.282a4.24 4.24 0 0 0-.263.363c-.04.062-.09.113-.127.177L17.498 770.678c-.039.066-.059.137-.093.204a3.92 3.92 0 0 0-.185.41 4.032 4.032 0 0 0-.115.37 4.069 4.069 0 0 0-.087.383 3.936 3.936 0 0 0-.045.44c-.004.078-.023.15-.023.228 0 .044.012.085.013.129.005.148.024.292.044.438.018.124.033.247.062.366.03.129.073.252.116.377s.083.25.137.368c.054.118.12.228.185.34.065.114.128.228.204.334.075.105.161.201.246.3.088.1.175.202.273.294.087.083.184.156.28.232.118.093.236.183.363.262.037.023.066.053.103.074.047.027.098.035.144.06.222.117.453.213.696.288.084.026.164.057.248.077.3.072.61.12.934.121l.01.002h824.095l.01-.002c.324 0 .634-.049.935-.121.083-.02.164-.05.247-.077.243-.075.475-.17.696-.288.047-.025.098-.033.144-.06.037-.021.067-.051.103-.074.128-.08.245-.17.363-.262.096-.076.193-.15.281-.232.098-.092.183-.193.272-.295.085-.098.172-.194.246-.299.076-.106.14-.22.205-.334.064-.112.13-.222.184-.34.055-.119.094-.244.137-.37.043-.124.087-.247.117-.375.028-.12.043-.242.06-.366.022-.146.04-.29.045-.438.001-.044.013-.085.013-.129 0-.078-.018-.15-.023-.227zM433.056 69.618l404.996 699.034H28.059L433.056 69.618z"/><path d="M459.217 762.333H815.5L672.81 708.18zm-408.359 0H407.14L193.546 708.18zm113.42-105.413 58.984-213.017-178.675 308.4zM427.425 91.514 248.608 400.156 404.66 242.87zm41.662 591.47 198.591 18.048-16.125-34.63zm-270.408 18.048 198.591-18.048L214.804 666.4zm419.07-300.877L438.933 91.514l22.764 151.356zm37.765 259.36 37.825-3.438-116.612-165.77zM326.386 426.766l102.82-146.165-20.917-29.734zM437.15 280.6l102.821 146.164-81.903-175.897zM210.843 659.515 289.63 490.31 173.02 656.077zm222.336-384.561 22.056-31.354L433.18 96.945 411.122 243.6zm381.758 480.213L698.225 662.16l-39.795 3.616 16.964 36.434zM217.72 660.14l215.459 19.58 215.459-19.58-93.113-199.97L433.18 286.247 310.83 460.17zm343.453-203.236 129.919 184.685-60.797-219.563-160.851-162.122zM433.179 686.247l-220.621 20.05 220.62 55.933L653.8 706.297zm-381.758 68.92 139.542-52.957 16.964-36.434-39.794-3.616zm253.763-298.262 91.73-197.001-160.851 162.122-60.796 219.563zM821.77 752.303 643.097 443.905 702.08 656.92z"/></g>',
    '<path d="M719.974 124.504c-.028-.139-.078-.268-.118-.402-.044-.149-.078-.299-.138-.443-.062-.151-.146-.288-.224-.43-.063-.117-.116-.238-.19-.35a4.544 4.544 0 0 0-.448-.552c-.04-.043-.067-.093-.11-.135L631.79 34.6l-.008-.007a4.542 4.542 0 0 0-.683-.562c-.126-.085-.262-.143-.394-.214-.128-.07-.25-.148-.386-.205-.163-.068-.333-.108-.502-.155-.116-.034-.226-.08-.345-.104a4.588 4.588 0 0 0-.885-.09h-397.39a4.702 4.702 0 0 0-.885.09c-.119.024-.228.07-.344.103-.169.048-.34.088-.503.156-.135.057-.256.135-.384.204-.132.07-.27.13-.396.215a4.542 4.542 0 0 0-.683.562l-.008.007-86.958 87.592c-.042.042-.07.092-.11.135-.16.174-.315.354-.447.552-.075.113-.127.234-.191.352-.077.141-.162.277-.223.427-.06.146-.095.297-.139.447-.04.133-.09.261-.117.4-.045.23-.06.462-.07.696-.002.061-.018.12-.018.181v620.806c0 .062.016.12.018.182.01.233.025.466.07.696.028.139.078.267.117.4.044.15.08.3.139.446.061.15.146.286.223.427.064.118.116.24.19.353.133.198.288.377.449.552.04.043.067.093.109.135l86.958 87.591.008.007c.21.21.44.398.686.564.117.078.244.132.366.199.138.075.27.159.416.22.15.062.308.098.463.143.129.038.252.089.386.115.293.059.59.09.888.09h397.369c.298 0 .595-.031.888-.09.134-.027.258-.077.387-.115.155-.046.312-.081.462-.143.147-.062.28-.146.418-.221.121-.066.247-.12.364-.198.247-.166.477-.354.686-.564l.008-.007 86.958-87.591c.041-.042.07-.092.11-.135.16-.175.315-.354.447-.552.074-.113.127-.234.19-.35.078-.143.162-.28.224-.43.06-.145.094-.295.138-.444.04-.133.09-.263.118-.402.045-.23.06-.463.07-.696.002-.062.018-.12.018-.182V125.382c0-.062-.016-.12-.018-.181a4.54 4.54 0 0 0-.07-.697zM626.69 829.252H233.093l-84.316-84.931V127.249l84.316-84.93H626.69l84.316 84.93v617.072l-84.316 84.93z"/><path d="m584.07 757.862 38.403 58.565 77.693-78.675-56.573-36.439zm-154.041 3.079H282.633l-37.77 57.598h370.332l-37.77-57.598zm216.755-584.173V694.75l55.473 35.73V141.04zM216.465 701.313l-56.573 36.439 77.693 78.675 38.404-58.565zm59.525-587.655L237.584 55.09l-77.693 78.677 56.574 36.437zM213.274 435.76V176.767l-55.473-35.728v589.44l55.473-35.73zm430.319-265.555 56.573-36.437-77.693-78.677-38.404 58.567zm-213.564-59.626h147.396l37.77-57.6H244.864l37.77 57.6zm-147.899 7.245-61.611 58.47v518.81l61.645 58.593H577.88l61.645-58.593v-518.81l-61.61-58.47z"/></g>',
    '<path d="M851.98 341.406c.09-.15.17-.306.246-.466.057-.123.114-.244.16-.371.057-.152.099-.31.14-.468.037-.143.075-.284.097-.429.009-.048.026-.09.033-.138.013-.101.003-.198.01-.299a4.76 4.76 0 0 0 .017-.52 5.036 5.036 0 0 0-.044-.467 4.805 4.805 0 0 0-.078-.463 4.506 4.506 0 0 0-.137-.461 4.78 4.78 0 0 0-.164-.432 4.843 4.843 0 0 0-.228-.432 4.91 4.91 0 0 0-.237-.383 4.722 4.722 0 0 0-.34-.415c-.065-.073-.113-.155-.183-.224-.031-.032-.068-.052-.1-.083-.133-.126-.279-.235-.425-.346-.113-.085-.222-.175-.34-.25-.138-.085-.285-.154-.432-.226-.143-.07-.283-.145-.43-.2-.135-.051-.277-.085-.418-.124-.172-.048-.343-.096-.519-.124-.044-.007-.084-.025-.13-.031l-282.652-38.06L439.408 36.831c-.025-.05-.06-.09-.086-.138a4.694 4.694 0 0 0-.274-.443c-.085-.125-.167-.251-.261-.366-.1-.122-.211-.232-.324-.344-.116-.116-.23-.232-.355-.334-.113-.093-.236-.174-.358-.256a4.894 4.894 0 0 0-.447-.276c-.048-.026-.09-.062-.14-.087-.086-.042-.177-.06-.265-.098a5.057 5.057 0 0 0-.474-.174 4.923 4.923 0 0 0-.458-.11 4.905 4.905 0 0 0-.464-.072c-.16-.015-.315-.02-.473-.02s-.314.005-.473.02a5.098 5.098 0 0 0-.462.071c-.156.03-.31.066-.464.112a4.902 4.902 0 0 0-.459.168c-.092.039-.187.059-.279.103-.053.026-.096.064-.147.091a4.795 4.795 0 0 0-.42.26c-.131.089-.264.175-.384.274-.117.096-.224.205-.333.313a4.37 4.37 0 0 0-.343.365c-.09.11-.17.231-.251.35a5.5 5.5 0 0 0-.281.454c-.026.049-.061.088-.085.137L304.23 295.994l-282.652 38.06c-.046.006-.086.024-.13.031-.177.028-.347.076-.52.124-.14.039-.282.073-.417.124-.148.055-.287.13-.43.2-.147.072-.294.14-.431.226-.12.075-.229.165-.342.25-.146.11-.291.22-.423.346-.033.03-.07.051-.101.083-.07.069-.118.15-.183.224-.12.134-.236.269-.34.415a4.916 4.916 0 0 0-.238.383c-.082.141-.16.283-.227.432a4.752 4.752 0 0 0-.165.433c-.051.151-.1.302-.136.46a5.112 5.112 0 0 0-.078.464c-.02.154-.039.307-.045.465a5.03 5.03 0 0 0 .018.521c.007.1-.003.198.01.299.007.047.024.09.032.138.023.145.061.286.098.429.041.159.083.316.14.468.046.127.103.248.16.37.075.161.155.317.246.467a4.903 4.903 0 0 0 .573.758c.049.052.083.113.135.164l203.072 203.05-46.758 277.97c-.006.034-.002.067-.007.102-.024.168-.026.337-.033.507-.007.153-.022.306-.014.455.007.146.038.29.059.436.024.173.043.346.085.512.032.123.083.242.125.363.063.184.124.369.208.543.013.027.019.056.032.083.025.05.066.085.093.134.168.305.366.588.593.851.065.074.123.151.191.221.276.282.58.537.922.746.052.033.11.053.163.083a4.826 4.826 0 0 0 1.266.492c.107.025.205.068.314.086.26.044.52.062.776.064.012 0 .024.005.037.005.02 0 .043-.007.064-.008a4.76 4.76 0 0 0 .935-.109c.098-.02.192-.052.29-.078.252-.07.494-.158.73-.267.055-.025.114-.034.17-.062L435.027 701.1 687.96 828.507c.055.028.114.037.17.062.236.109.478.197.73.267.097.026.192.058.29.078.304.065.615.105.934.11.022 0 .044.007.065.007.012 0 .025-.005.037-.005.256-.002.515-.02.776-.064.11-.018.207-.06.314-.086a4.826 4.826 0 0 0 1.266-.492c.053-.03.11-.05.163-.083.34-.21.645-.463.92-.745.069-.07.129-.148.194-.222.226-.263.425-.546.592-.85.026-.05.068-.085.093-.135.013-.027.019-.056.031-.083.085-.174.146-.359.209-.543.042-.121.093-.24.124-.363.043-.166.06-.338.086-.51.021-.146.051-.291.06-.438.007-.15-.009-.301-.015-.454-.007-.17-.009-.34-.034-.508-.004-.035 0-.068-.006-.103L648.2 545.377l203.072-203.05c.051-.05.086-.11.134-.163a4.788 4.788 0 0 0 .574-.758zM639.532 540.265c-.076.075-.128.163-.197.24-.13.149-.261.294-.372.456-.087.126-.154.26-.227.393-.08.142-.163.282-.227.433-.062.143-.104.292-.152.44-.05.153-.102.303-.137.46-.032.154-.044.307-.063.462-.018.16-.042.316-.045.478-.003.176.019.35.034.525.011.122.004.243.025.367l45.579 270.957-246.53-124.182c-.094-.048-.193-.07-.289-.111-.17-.072-.337-.144-.513-.197-.143-.043-.287-.069-.433-.098-.163-.033-.324-.066-.49-.082-.153-.015-.303-.014-.455-.014a4.66 4.66 0 0 0-.489.015c-.154.015-.304.046-.455.076-.157.03-.312.06-.467.106-.167.05-.324.118-.484.186-.102.043-.209.068-.31.119L186.306 815.476l45.579-270.957c.02-.124.013-.245.025-.367.015-.175.037-.35.034-.525-.003-.162-.028-.319-.046-.478-.018-.155-.03-.308-.062-.461-.035-.158-.088-.308-.138-.461-.047-.148-.089-.297-.15-.44-.066-.151-.148-.29-.228-.433-.074-.133-.14-.267-.227-.393-.111-.162-.242-.307-.372-.455-.07-.078-.122-.166-.197-.241L32.634 342.398l275.483-37.095c.157-.02.302-.072.453-.108.111-.026.22-.045.33-.079a4.774 4.774 0 0 0 1.085-.475c.042-.025.077-.06.119-.086a4.837 4.837 0 0 0 1.041-.915c.27-.314.513-.65.696-1.023 0-.003.004-.005.005-.007L435.028 50.08 558.21 302.61l.005.007c.183.373.425.71.696 1.024a4.862 4.862 0 0 0 1.041.914c.04.026.077.061.119.087.335.202.7.356 1.086.474.108.034.218.053.329.079.151.036.296.087.453.108l275.482 37.095-197.89 197.867z"/><path d="m283.89 534.056-82.413 253.642L318.37 622.745zm40.77 93.3-117.912 166.39 217.637-158.124zm309.502-90.736L794.3 376.5 594.862 521.4zM439.07 80.455v192.392l82.328 60.988zm-7.796 192.392V80.455l-82.328 253.38zm-188.713 140.97L60.205 355.354l215.72 156.73zm86.452-65.695-265.835-.001 181.802 58.286zm444.92-7.798-214.415-28.872-22.637 28.872zm-463.108-28.872L96.41 340.325h237.053zm242.43-4.645L456.1 107.636l74.22 228.425zM275.484 521.4 76.044 376.5l160.139 160.12zm138.761-413.764-97.156 199.171 22.936 29.252zm24.828 577.227L639.27 785.707 439.073 640.256zM238.698 544.007l-36.241 215.444 74.862-230.4zM431.276 684.86v-44.607l-200.2 145.454zm161.75-155.81 74.862 230.401-36.242-215.444zM445.959 635.622l217.638 158.123-117.91-166.39zm185.376-223.481-36.492 99.635 215.448-156.531zM283.48 510.087l50.711-156.07-83.934 58.217zm233.581-169.763-81.888-60.662-81.89 60.662zm8.979 7.796H344.304l-56.16 172.844 147.03 106.822 147.024-106.822zm102.872 56.61 178.055-56.61H542zm-50.569 128.672L448.737 627.57l96.094-7.965zm-156.732 94.167-129.609-94.167 33.514 86.202zm165.392-117.054 36.602-99.936-87.616-57.068zm-35.028 112.23 116.893 164.954-82.415-253.643z"/></g>',
    '<path d="M584.131 273.864c-.019-.162-.061-.314-.096-.47-.032-.143-.055-.286-.101-.427-.063-.192-.15-.37-.236-.55-.041-.09-.066-.181-.114-.268l-.046-.084L442.057 15.738c-.05-.093-.12-.167-.176-.255-.1-.155-.197-.311-.315-.455-.098-.119-.207-.22-.314-.328-.11-.108-.212-.22-.333-.32-.143-.116-.298-.213-.452-.311-.089-.057-.164-.126-.257-.178-.02-.01-.042-.016-.062-.027-.16-.084-.327-.146-.494-.212-.125-.05-.248-.11-.375-.148-.137-.041-.28-.058-.42-.087-.159-.032-.315-.074-.474-.089-.15-.014-.3-.002-.45-.003-.15 0-.299-.011-.447.003-.162.015-.32.058-.481.09-.138.028-.278.045-.413.086-.133.04-.261.102-.392.155-.16.064-.322.122-.474.203-.022.012-.046.017-.068.03-.1.054-.182.129-.277.19-.145.095-.292.185-.428.296-.126.103-.234.22-.347.333-.103.104-.21.2-.302.315-.12.145-.219.303-.32.46-.054.087-.122.16-.173.252L292.332 272.065l-.046.084c-.048.087-.073.179-.114.267-.087.18-.173.36-.236.551-.046.14-.069.284-.1.426-.036.157-.078.31-.097.47-.023.185-.018.367-.018.55 0 .113-.018.221-.01.335l27.585 401.204c.006.09.032.171.043.259.02.155.041.308.076.462.036.155.082.304.133.452.044.134.089.265.147.395.071.163.156.316.244.468.046.078.075.161.125.238l113.942 172.36.002.003c.198.298.44.57.707.82.09.085.186.154.28.23.115.092.217.196.343.28.057.037.123.049.181.084.258.154.526.273.805.375.128.046.249.108.379.143.388.106.786.168 1.19.172.013 0 .025.005.038.005h.008c.012 0 .025-.005.038-.005a4.707 4.707 0 0 0 1.19-.172c.13-.035.251-.097.38-.143.278-.102.546-.22.804-.375.058-.035.124-.047.181-.085.126-.083.228-.187.343-.28.094-.075.19-.144.28-.228a4.712 4.712 0 0 0 .709-.823l113.941-172.361c.052-.078.081-.163.127-.242a4.5 4.5 0 0 0 .242-.462c.058-.131.104-.264.15-.399a4.84 4.84 0 0 0 .13-.45c.036-.154.058-.307.077-.462.011-.088.037-.17.043-.259l27.586-401.204c.007-.114-.01-.222-.011-.334 0-.184.004-.366-.018-.55zm-36.866 400.202L437.935 839.45l-109.33-165.384-27.404-398.582L437.935 27.756l136.734 247.728-27.404 398.582z"/><path d="m541.02 261.939-17.67 390.423 18.778 10.562 25.47-381.493zM335.986 670.462l78.175 121.788-59.248-132.435zm57.395-548.424-77.562 144.72 19.72-14.46zm68.606 670.213 78.175-121.789-18.927-10.647zM335.13 261.939l-26.58 19.492 25.47 381.493 18.777-10.561zm225.2 4.819-77.563-144.72 57.843 130.26zm-188.7-32.756 44.368-144.333-69.722 157.01zm-9.928 422.541 65.374 146.127-33.595-158.895zm168.17-409.863L460.151 89.668l44.368 144.333zM400.886 642.375l37.189 175.892 37.188-175.892zm81.781 1.4-33.594 158.894 65.373-146.126zm-6.327-8.933 21.08-394.425H378.73l21.08 394.425zm57.36-377.826-28.853-14.427-21.032 393.529 32.182 12.107zm-191.251 0 17.703 391.21 32.183-12.108L371.3 242.589zm104.671-24.132h49.174l-58.22-189.391-58.22 189.39z"/></g>',
    '<path d="M850.919 295.125c.05-.105.107-.208.146-.316.04-.11.06-.222.089-.334.027-.11.063-.218.08-.33.017-.113.016-.226.022-.34.007-.113.02-.226.016-.34-.005-.111-.027-.221-.042-.333-.016-.114-.024-.228-.05-.34-.026-.11-.069-.214-.105-.32-.037-.11-.067-.222-.115-.329-.048-.104-.113-.201-.171-.302-.058-.101-.109-.205-.178-.3-.069-.097-.155-.182-.235-.272-.072-.081-.132-.169-.212-.245L717.746 166.2c-.06-.057-.13-.097-.194-.15-.105-.086-.208-.173-.323-.247-.098-.063-.2-.11-.303-.163-.103-.054-.203-.11-.312-.153-.125-.05-.254-.08-.382-.115-.082-.023-.158-.056-.242-.073l-161.504-31.383c-.057-.01-.112-.007-.17-.015-.06-.009-.114-.03-.175-.035l-73.48-6.888c-.055-.005-.107.004-.162.002-.057-.003-.111-.017-.17-.017h-77.307c-.049 0-.094.012-.142.014-.05.002-.097-.006-.147-.002l-84.196 6.889c-.055.004-.105.022-.16.029-.058.008-.116.003-.176.013l-175.261 31.38a.334.334 0 0 0-.019.003c-.006 0-.01.003-.015.004a3.59 3.59 0 0 0-.66.188c-.097.038-.184.093-.276.14-.115.056-.232.105-.34.175a3.53 3.53 0 0 0-.473.373c-.024.021-.051.036-.075.058l-.005.006-.005.005-129.44 124.815c-.073.07-.127.15-.192.225-.081.094-.168.183-.238.282-.066.093-.116.192-.172.29-.06.104-.124.205-.172.314-.046.104-.076.211-.112.318-.037.11-.08.218-.105.33-.025.11-.034.222-.049.334-.015.113-.035.226-.039.34-.004.112.009.223.015.335.007.115.009.23.027.344.018.111.051.22.08.329.028.111.052.223.092.333.04.109.096.212.147.317.05.104.094.21.155.309.063.102.142.196.216.293.06.08.109.165.177.241l416.516 460.719c.038.042.085.071.125.111.044.045.078.097.126.14.058.052.124.09.184.137.08.064.16.127.245.183.118.078.24.143.364.206.083.042.164.087.25.122.146.06.295.102.445.14.071.02.14.045.211.06.225.043.452.069.68.069h.003c.228 0 .456-.026.681-.07.068-.013.132-.038.2-.055.154-.04.308-.084.458-.145.081-.033.158-.076.236-.115.13-.065.256-.133.379-.214.081-.054.158-.115.235-.176.062-.049.13-.087.19-.141.047-.043.082-.096.127-.14.04-.04.085-.07.123-.111l417.12-460.719c.073-.08.125-.171.19-.256.073-.098.154-.191.216-.294.06-.1.103-.207.153-.312zM430.612 749.036 19.03 293.776l126.201-121.693 174.06-31.164 83.866-6.861h77.003l73.145 6.857 160.32 31.153 129.14 121.735-412.154 455.233z"/><path d="m443.794 723.718 384.556-424.75-172.888 24zm-15.906 7.245v-398.35l-215.986-9.21zm-3.445-404.179L330.81 214.371l-116.6 103.448zm-87.268-113.642 93.544 112.305 92.785-112.305zm-12.195-1.189-168.495-34.258 51.795 137.798zm504.46 81.131L708.326 178.912 657.92 316.894zm-177.044 22.383 50.33-137.774-167.068 34.251zm-215.42 11.317 209.52-8.964-116.65-103.443zM150.885 178.931 32.51 293.078l170.229 23.806zm378.359 28.534 163.398-33.5-142.704-27.728-71.072-6.664h-74.81l-81.487 6.668-155.428 27.827 164.261 33.397zM33.688 298.974l383.856 424.593-212.298-400.6zm399.877 33.639V730.93l215.248-407.527z"/></g>',
    '<path d="M854.802 321.595a3.347 3.347 0 0 0-.044-.327 3.133 3.133 0 0 0-.066-.3 3.331 3.331 0 0 0-.107-.314c-.039-.1-.08-.198-.128-.294a3.378 3.378 0 0 0-.363-.565c-.031-.04-.053-.085-.086-.124-.036-.04-.079-.07-.116-.108a3.277 3.277 0 0 0-.534-.454c-.041-.029-.075-.064-.118-.091L651.417 194.147c-.061-.038-.126-.06-.188-.093-.115-.06-.228-.122-.35-.17-.103-.041-.208-.068-.313-.097-.102-.03-.202-.061-.308-.08-.13-.024-.26-.031-.39-.04-.07-.004-.137-.02-.208-.02H213.85c-.075 0-.146.017-.22.021-.126.009-.25.016-.376.039-.11.02-.212.052-.317.082-.103.03-.205.055-.306.094-.122.049-.236.11-.35.172-.063.033-.129.055-.19.093L10.54 319.019c-.044.027-.077.063-.119.091a3.364 3.364 0 0 0-.534.454c-.036.038-.078.067-.113.107-.034.04-.055.084-.087.124a3.328 3.328 0 0 0-.362.565 3.54 3.54 0 0 0-.235.609 3.593 3.593 0 0 0-.111.627c-.008.105-.01.21-.008.316a3.3 3.3 0 0 0 .019.32c.012.106.03.21.053.316.023.108.05.215.084.321a3.256 3.256 0 0 0 .268.614c.024.044.038.091.065.134.021.034.052.058.074.092.11.163.237.317.379.462.05.053.096.11.15.16.018.016.03.036.05.052l419.59 363.416c.038.032.08.053.118.084a3.324 3.324 0 0 0 .574.364c.076.039.151.077.23.109.138.057.28.1.423.137.066.018.13.04.198.053.213.042.427.068.643.068h.002c.216 0 .43-.026.644-.068.067-.013.131-.035.197-.053a3.27 3.27 0 0 0 .424-.137c.078-.032.153-.07.23-.108a3.307 3.307 0 0 0 .573-.365c.038-.03.08-.052.118-.084l419.591-363.416c.019-.017.032-.036.05-.053.054-.049.1-.107.151-.16.142-.146.269-.3.379-.464.022-.033.053-.057.074-.09.026-.043.04-.089.064-.132.06-.109.114-.218.161-.332a3.035 3.035 0 0 0 .191-.606 3.31 3.31 0 0 0 .053-.315c.012-.107.016-.213.018-.32a3.03 3.03 0 0 0-.008-.316zm-422.91 359.26L17.917 322.306 214.8 200.326h433.911l197.15 121.982-413.97 358.547z"/><path d="m664.973 321.404-124.599-65.057 20.951 65.057zm-103.709 4.453L490.2 521.851l178.802-195.994zm-76.595 198.189 71.858-198.189H434.832zM431.976 320.93l100.134-68.698-100.134-46.574-100.134 46.574zm-240.965-.39 132.812-69.344-39.579-45.233-117.019 58.51zm481.929 0 23.787-56.068-117.018-58.509-39.58 45.233zm-524.877-47.686-112.79 48.55h48.059zm495.807-67.425h-55.271l101.328 50.663zM812.7 309.677l-155.524-96.232 43.741 48.116zM421.908 205.429H289.694l38.244 43.707zm-146.555 0h-55.27l-46.058 50.663zM82.188 370.653 398.703 644.65 288.157 528.435zm124.589-157.208L51.248 309.68l111.787-48.118zm367.481-8.016H442.045l93.97 43.707zm-491.1 120.428H31.036L262.93 503.5zM465.25 644.65l316.52-274.003-205.974 157.788zm199.913-307.976-178.936 196.14-48.55 134.36 134.775-141.687zm115.632-10.817L601.023 503.5l231.893-177.642zm-582.007 10.817L291.5 525.487l134.775 141.687-48.55-134.36zm129.778-81.287-21.26 66.017h117.487zm110.593 66.017h117.488l-21.26-66.017zm-7.183 11.356-49.982 198.764 49.982 138.322 49.982-138.322zm-129.348-11.356 20.95-65.057-124.6 65.057zm71.123 200.446-71.062-195.993h-107.74zm55.369-195.993H307.425l71.859 198.189zm-338.367-4.453h95.787l-23.12-54.5zm586.658 0H773.2l-72.666-54.5zm103.211 0h48.057l-112.789-48.55zM582.105 515.932l192.353-190.075h-99.023zm-300.258-.001-93.33-190.074H89.494z"/></g>'];
  uint8[] private gemcut_w =[250, 250, 180, 180, 120, 120, 120, 75, 50];
  string[] private gemcutMap = ['Oval', 'Round' ,'Teardrop', 'Trilliant', 'Emerald', 'Star', 'Wand', 'Diamond', 'Pure Diamond'];
  string[] private gemtype = ['<g fill="#a553ea">', '<g fill="#9fdf2e">' ,'<g fill="#59f5eb">', '<g fill="#f5e163">', '<g fill="#ffa8c4">', '<g fill="#009e53">', '<g fill="#9e0003">', '<g fill="#1d35c6">', '<g fill="#f1f1f1">', '<g fill="#000000">'];
  string[] private gemtypeMap = ['Amethyst', 'Peridot' ,'Aquamarine', 'Topaz', 'Rose Quartz', 'Emerald', 'Ruby', 'Sapphire', 'Diamond', 'Black Diamond'];
  uint8[] private gemtype_w = [250, 246, 223, 180, 150, 140, 120, 100, 80, 40];
  string[] private carat = ["1","2","3","4","5","6","7","8","9","10"];
  uint8[] private carat_w = [250, 246, 223, 180, 150, 140, 120, 100, 80, 50];
  string[] private z = ['<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 864 864" style="enable-background:new 0 0 864 864;" stroke="black">', '</svg>'];
  string private zz='"/>';
  string private tr1='", "attributes": [{"trait_type": "Clarity","value": "';
  string private tr2='"},{"trait_type": "Gem Cut","value": "';
  string private tr3='"},{"trait_type": "Gem Type","value": "';
  string private tr4='"},{"trait_type": "Carat","value": "';
  string private tr5='"}],"image": "data:image/svg+xml;base64,';
  string private ra1='A';
  string private ra2='C';
  string private ra3='D';
  string private ra4='E';
  string private co1=', ';
  string private rl1='{"name": "Pixelgem #';
  string private rl3='"}';
  string private rl4='data:application/json;base64,';

  struct Gem {
    uint8 clarity;
    uint8 gemcut;
	uint8 gemtype;
    uint8 carat;
  }

  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function usew(uint8[] memory w,uint256 i) internal pure returns (uint8) {
    uint8 ind=0;
    uint256 j=uint256(w[0]);
    while (j<=i) {
      ind++;
      j+=uint256(w[ind]);
    }
    return ind;
  }

  function randomOne(uint256 tokenId) internal view returns (Gem memory) {
    tokenId=42069-tokenId;
    Gem memory gem;
    gem.clarity = usew(clarity_w,random(string(abi.encodePacked(ra1,tokenId.toString())))%1338);
    gem.gemcut = usew(gemcut_w,random(string(abi.encodePacked(ra2,tokenId.toString())))%1345);
	gem.gemtype = usew(gemtype_w,random(string(abi.encodePacked(ra3,tokenId.toString())))%1529);
    gem.carat = usew(carat_w,random(string(abi.encodePacked(ra4,tokenId.toString())))%1539);
    return gem;
  }

  function getTraits(Gem memory gem) internal view returns (string memory) {
    string memory o=string(abi.encodePacked(tr1,clarity[uint256(gem.clarity)],tr2,gemcutMap[uint256(gem.gemcut)]));
    return string(abi.encodePacked(o,tr3,gemtypeMap[uint256(gem.gemtype)],tr4,carat[uint256(gem.carat)],tr5));
  }

  function getAttributes(uint256 tokenId) public view returns (string memory) {
    Gem memory gem = randomOne(tokenId);
    string memory o = string(abi.encodePacked(clarity[uint256(gem.clarity)],co1,gemcutMap[uint256(gem.gemcut)],co1,gemtypeMap[uint256(gem.gemtype)],co1,carat[uint256(gem.carat)]));
    return o;
  }

  function genSVG(Gem memory gem) internal view returns (string memory) {
    string memory output = string(abi.encodePacked(z[0], gemtype[gem.gemtype], gemcut[gem.gemcut], z[1]));
    return output;
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    Gem memory gem = randomOne(tokenId);
    return string(abi.encodePacked(rl4,Base64.encode(bytes(string(abi.encodePacked(rl1,tokenId.toString(),getTraits(gem),Base64.encode(bytes(genSVG(gem))),rl3))))));
  }

  function claim() public payable nonReentrant {
    require(numClaimed >= 0 && numClaimed < 848, "Invalid claim index.");
    require(msg.value >= mintPrice, "You do not have enough ether.");
    _safeMint(_msgSender(), numClaimed + 1);
    numClaimed += 1;
  }

  function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
    require(tokenId > 848 && tokenId < maxSupply+1, "Invalid claim index.");
    _safeMint(owner(), tokenId);
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function withdrawAllToAddress(address addr) public onlyOwner {
      require(payable(addr).send(address(this).balance));
  }

  constructor() ERC721("Pixelgem", "PXLGEM") Ownable() {}
}