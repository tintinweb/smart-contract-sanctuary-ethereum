/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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

        _status = _ENTERED; _; _status = _NOT_ENTERED;

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
            if (returndata.length > 0) {
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
        //solhint-disable-next-line max-line-length
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


contract LarvaLads is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public maxSupply = 1000000;
    uint256 public price = 0.05 ether;
    uint256 public maxMint = 10;
    uint256 public numTokensMinted;

    // ATTRIBUTES START

    string[19] private skinToneNames = ['Pale Ivory', 'Warm Ivory', 'Sand','Rose Beige','Limestone','Beige','Sienna','Amber',
    'Honey','Band','Almond','Bronze','Umber','Golden','Espresso','Chocolate', 
    'Invisible', 'Alien', 'Zombie'];
    string[19] private skinToneLayers = [
        '#fee3c6','#fde7ad','#f8d998','#f9d4a0','#ecc091','#f2c280','#d49e7a','#bb6536',
        '#cf965f','#ad8a60','#935f37','#733f17','#b26644','#7f4422','#5f3310','#291709',
        '<path stroke="#000" d="M4 4.5h2m5 0h2m4 0h6m-19 1h1m20 0h1m-22 1h1m20 0h1m-22 1h1m20 0h1m-22 1h1m20 0h1m-22 1h1m-1 2h1m-1 1h1m20 0h1m-22 1h1m20 0h1m-22 1h1m20 0h1m-1 1h1m-22 1h1m20 0h1m-22 1h1m-1 2h1m20 1h1m-22 1h1m-1 1h1m20 0h1m-22 1h1m20 0h1m-22 1h1m0 1h3m7 0h3m1 0h1m1 0h1 M6 4.5h1m1 0h2m5 0h1m8 0h1m-16 21h1m4 0h1m9 0h1 M7 4.5h1m2 0h1m2 0h1m2 0h1m8 0h1m-1 5h1m-22 1h1m20 0h1m-1 1h1m-22 4h1m20 2h1m-22 1h1m20 0h1m-1 1h1m-22 1h1m20 1h1m-1 3h1m-22 1h1m5 0h1m2 0h1m8 0h1m2 0h1 M14 4.5h1m8 0h1m-16 21h1m2 0h2m5 0h1m1 0h1m2 0h1"/>',
        '<rect x="4" y="4" width="22" height="22" fill="#5a9349"/><path stroke="#5a9349" d="M7 1.5h1m0 0h1m12 0h2m-15 1h1m12 1h1m-1-1h1m-14 1h1"/>',
        '<rect x="4" y="4" width="22" height="22" fill="#698362"/><path stroke="#b61d1d" d="M14 4.5h1m0 1h1m4 0h1m2 1h1m-1 1h1m-7 1h1m-1 1h1m5 3h1m-13 8h1m2 0h1m2 3h1m-1 2h1"/><path stroke="#b71d1c" d="M15 4.5h1m1 0h1m0 1h1m5 1h1m-1 1h1m-1 2h1m-2 1h1m-1 1h1m-1 2h1m-6 7h1"/><path stroke="#b71d1d" d="M16 4.5h1m1 0h8m-9 1h1m3 0h1m1 0h2m-9 1h2m1 0h3m3 0h1m-9 1h1m1 0h1m1 0h1m1 1h2m-15 12h1m1 0h1m2 0h1m1 0h1m-3 3h1m1 1h1"/><path stroke="#b71c1d" d="M16 5.5h1m2 0h1m2 0h1m2 0h1m-4 1h1m-7 1h1m8 0h1m-13 13h1m2 0h1m2 0h1m-11 1h2m6 0h1m-2 2h1m-1 1h1"/><path stroke="#b61d1c" d="M23 9.5h1m-14 10h1m5 0h1m2 0h1m-7 2h1m5 0h1m-4 1h1"/><path stroke="#b61c1d" d="M9 19.5h1m8 0h1m-10 1h1m2 1h1m5 1h1"/><path stroke="#b61c1c" d="M11 19.5h3m1 0h1m-2 2h3m1 0h1m-2 1h1m-1 4h1"/><path stroke="#b71c1c" d="M14 19.5h1m2 0h1m2 0h1m-1 1h1m-10 1h1m8 0h1m-6 1h1"/>'
    ];

    string[16] private eyeColorNames = ['Black', 
    'Light Brown','Dark Brown', 
    'Prussian Blue','Blue Sapphire','Teal Blue','Rackley','Moonstone Blue','Beau Blue', 
    'Wageningen Green', 'Light Green','Green','Emerald Green','Traditional Forest Green',
    'Alien', 'Vampire'];
    string[16] private eyeColorLayers = [
        '#000000', // Black
        '#603101', '#451800', // Browns
        '#0f305b', '#1b5675','#357388','#528c9e','#7fb4be','#b8d8e1', // Blues
        '#25a22b','#03920c','#017101','#035104','#004200', // Greens
        '#0CFB8B', '#e70303'
    ];

    string[7] private glassesNames = ['None', 'Rectangular Glasses', 'Round Glasses', 'Sun Glasses', 'Futuristic Glasses', 'Eye Patch', 'Steampunk Glasses'];
    string[7] private glassesLayers = [
        '',
        '<path stroke="#010001" d="M6 8.5h1m4 0h2m7 0h1m-15 5h1m16 0h1m-13 1h1"/><path stroke="#000100" d="M7 8.5h1m14 0h1m-10 1h1m-4 5h1m8 0h1"/><path stroke="#000001" d="M8 8.5h2m13 2h1m0 1h1m-13 1h1"/><path stroke="#000" d="M10 8.5h1m7 0h2m1 0h1m1 0h1m-18 1h1m5 0h1m1 0h1m1 0h2m-6 1h1m4 0h1m-14 1h3m10 0h1m5 0h1m1 0h1m-20 1h1m16 0h1m-18 2h2m4 0h1m4 0h2m1 0h3"/><path stroke="#010000" d="M17 8.5h1m-3 1h1m7 0h1m-18 1h1m5 1h1m4 1h1m-6 1h1m4 0h1m-10 1h2m13 0h1"/>',
        '<path stroke="#010000" d="M8 8.5h1m11 0h1m-16 3h1m11 0h1m5 0h1m-7 1h1m5 0h1m-13 1h1m-4 1h1"/><path stroke="#000001" d="M9 8.5h1m1 1h1m6 0h1m-13 1h1m10 0h1m-12 1h1m5 0h1m-7 1h1"/><path stroke="#000" d="M10 8.5h1m10 0h1m-15 1h1m4 1h1m0 1h4m7 0h2m-14 1h1m-6 1h1m10 0h1m-10 1h1m10 0h1"/><path stroke="#000100" d="M19 8.5h1m2 1h1m-19 2h1m17 2h1m-13 1h1m8 0h1"/><path stroke="#010001" d="M23 10.5h1m-3 4h1"/>',
        '<path stroke="#9c1a00" d="M6 8.5h1m2 0h2m6 0h1m3 0h1m-10 2h2m3 0h1m5 0h1m-19 1h1m11 0h1m5 0h1m-18 1h1m-1 1h1m16 0h1m-18 1h3m1 0h3m9 0h2"/><path stroke="#9c1b00" d="M7 8.5h1m11 0h1m2 0h1m-7 2h1m-13 1h1m20 0h1m-7 3h1"/><path stroke="#9d1a01" d="M8 8.5h1m9 0h1m-13 1h1m5 0h1m-1 4h1m4 1h1"/><path stroke="#9d1a00" d="M11 8.5h1m8 0h1m-4 1h1m5 0h1m-10 1h1m-3 1h1m4 1h1m5 0h1m-7 1h1m0 1h1m1 0h1"/><path stroke="#9c1a01" d="M12 8.5h1m10 0h1m-18 2h1m8 0h1m-10 1h1m17 0h1m-13 1h1m-4 2h1m11 0h1"/><path stroke="#4f4f4f" d="M7 9.5h1m2 0h1m11 0h1m-16 1h1m2 0h1m11 0h1m-1 1h1m-13 1h1m-4 1h1m2 0h1m8 0h1m2 0h1"/><path stroke="#4e4e4e" d="M8 9.5h1m11 3h1"/><path stroke="#4f4e4f" d="M9 9.5h1m8 0h2m-11 1h1m1 0h1m7 0h1m-13 1h1m1 0h2m7 0h3m-14 1h1m1 0h1m1 0h1m6 0h2m1 0h2m-14 1h1m8 0h1m1 0h1"/><path stroke="#4e4e4f" d="M11 9.5h1m8 0h2m-14 1h1m11 0h1m-13 1h1m2 0h1m-4 1h1m2 1h1"/><path stroke="#4f4e4e" d="M18 10.5h1m2 0h1m-1 1h1m-14 2h1m12 0h1"/>',
        '<path stroke="#c0c1c0" d="M4 8.5h1m2 0h1m2 0h1m2 0h1m8 0h1m-19 6h1m2 0h1m8 0h1m5 0h1"/><path stroke="#c1c0c0" d="M5 8.5h1m2 0h1m3 0h1m4 0h1m2 0h1m2 0h1m-1 3h1m-7 1h1m5 0h1m-1 1h1m-4 1h1m2 0h1"/><path stroke="#c0c0c1" d="M6 8.5h1m2 0h1m8 0h1m-2 1h1m-12 5h1m1 0h1m3 0h1m11 0h1"/><path stroke="silver" d="M11 8.5h1m2 0h3m2 0h1m1 0h1m2 0h2m-3 1h1m-7 1h1m-1 1h1m-1 2h1m-13 1h1m3 0h2m2 0h3m1 0h3m1 0h1m3 0h1"/><path stroke="#6ac2e6" d="M4 9.5h1m5 0h1m2 0h1m-7 1h1m2 0h1m2 0h1m11 0h1m-22 1h1m2 0h1m2 0h1m2 0h1m-7 1h1m2 0h1m5 0h1m8 0h1m-16 1h1m14 0h1"/><path stroke="#6bc3e6" d="M5 9.5h2m1 0h1m2 0h1m2 0h1m-10 1h1m3 0h1m4 0h1m-10 1h1m2 0h1m0 1h1m5 0h1m-11 1h1"/><path stroke="#6ac3e6" d="M7 9.5h1m4 0h1m2 0h2m7 0h2m-22 1h1m1 0h1m1 0h1m2 0h2m3 0h1m-8 1h1m1 0h2m1 0h1m1 0h1m8 0h1m-22 1h1m3 0h1m3 0h3m9 0h1m-21 1h1m2 0h2m2 0h4m1 0h1"/><path stroke="#6ac3e7" d="M9 9.5h1m14 1h1m-19 1h1m8 0h1m8 0h1m-20 1h2m-1 1h1m2 0h1m5 0h1m8 0h1"/><path stroke="#6bc3e7" d="M15 10.5h1m-5 2h1"/><path stroke="#c1c0c1" d="M23 10.5h1m-13 4h1"/>',
        '<path stroke="#000100" d="M25 6.5h1m-1 1h1m-10 1h1m2 0h1m2 2h1m-4 1h1m2 0h1m-7 1h1m2 0h1m2 0h1m-4 1h1m-7 1h1m-4 1h1m-1 1h1m-7 3h1"/><path stroke="#000001" d="M24 7.5h1m-7 1h1m5 1h1m-7 1h1m4 0h1m-4 1h1m-3 1h1m-4 1h1m-2 1h1m-9 3h1"/><path stroke="#000" d="M17 8.5h1m2 0h1m1 0h3m-9 1h8m-7 1h1m1 0h3m-4 1h1m2 0h1m-5 1h1m3 0h1m-8 1h1m1 0h1m3 0h1m-1 1h1m-10 1h1m-5 2h1m-4 1h1"/><path stroke="#010000" d="M21 8.5h1m-2 4h1m-9 3h1m-5 1h1m-1 1h1m-4 1h2"/><path stroke="#010001" d="M21 13.5h1m-10 1h1m-4 2h1"/>',
        '<path stroke="#422616" d="M8 8.5h1m11 0h1m-9 3h1m10 1h1m-16 2h1m11 0h1"/><path stroke="#432616" d="M9 8.5h2m8 0h1m1 0h1m-11 1h1m5 1h1m5 0h1m-1 1h1m-18 1h1m10 0h1m-7 1h1m-2 1h1m8 0h1"/><path stroke="#432716" d="M7 9.5h1m14 0h1m-16 4h1m14 0h1"/><path stroke="#4f4f4f" d="M8 9.5h3m10 0h1m-14 1h1m1 0h2m7 0h1m1 0h2m-14 1h3m10 0h1m-14 1h1m1 0h1m7 0h1m1 0h1m-3 1h1"/><path stroke="#422617" d="M18 9.5h1m-7 1h1m-7 1h1m10 0h1"/><path stroke="#4f4e4f" d="M19 9.5h1m-13 1h1m-1 1h1m11 0h1m-13 1h1m2 0h1m11 0h1m-13 1h1"/><path stroke="#4f4f4e" d="M20 9.5h1m-3 2h1m-11 1h1m0 1h1m10 0h2"/><path stroke="#000" d="M4 10.5h1m9 0h3m8 0h1m-13 1h1m1 0h1m-1 1h2"/><path stroke="#010000" d="M5 10.5h1m18 0h1m-11 1h1m-1 1h1m9 0h1"/><path stroke="#432617" d="M6 10.5h1m5 2h1m5 1h1m-10 1h1m11 0h1"/><path stroke="#4e4f4f" d="M9 10.5h1m8 0h1m1 0h1m-13 1h1m11 0h2m-2 1h1m-13 1h1"/><path stroke="#000100" d="M13 10.5h1m2 1h1m-13 1h1m8 0h1m11 0h1"/><path stroke="#000001" d="M5 12.5h1"/><path stroke="#4e4f4e" d="M18 12.5h1"/>'
    ];

    string[5] private mouthNames = ['Normal', 'Smile', 'Unhappy', 'Ooo', 'Vampire'];
    string[5] private mouthLayers = [
        '<rect x="10" y="20" width="10" height="1" fill="#000000"/>',
        '<path stroke="#000001" d="M9 18.5h1m8 1h1m-7 1h1m4 0h1"/><path stroke="#000100" d="M10 18.5h1m8 0h1m-7 2h1m2 0h1"/><path stroke="#000" d="M20 18.5h1m-11 1h2m7 0h1m-2 1h1"/><path stroke="#010000" d="M11 20.5h1m2 0h1"/><path stroke="#010001" d="M15 20.5h1"/>',
        '<path fill="#0CFB8B" d="M8 10h3v3H8zm11 0h3v3h-3z"/><path stroke="#010000" d="M11 20.5h1m5 0h1"/><path stroke="#000001" d="M12 20.5h1m2 0h1m2 0h1m-1 1h1"/><path stroke="#000100" d="M13 20.5h1m2 0h1m2 1h1m-1 1h1"/><path stroke="#010001" d="M14 20.5h1"/><path stroke="#000" d="M10 21.5h2m-2 1h1"/>',
        '<path stroke="#000" d="M13 17.5h4m-5 1h1m4 0h1m-1 1h2m-1 1h1m-7 2h2m-1 1h1m1 0h1"/><path stroke="#000100" d="M13 18.5h1m2 0h1m-1 4h1m-1 1h1"/><path stroke="#010000" d="M11 19.5h1m-1 1h1m2 3h1"/><path stroke="#000001" d="M12 19.5h1m4 2h2"/><path stroke="#010001" d="M11 21.5h2m4 1h1"/>',
        '<path stroke="#000" d="M10 20.5h4m1 0h1m2 0h2"/><path stroke="#010000" d="M14 20.5h1m2 0h1"/><path stroke="#000100" d="M16 20.5h1"/><path stroke="#b61d1c" d="M10 21.5h1"/><path stroke="#b61c1c" d="M11 21.5h1m-1 1h1m-1 1h1m0 1h1m-1 2h1"/><path stroke="#bababa" d="M12 21.5h1"/><path stroke="#bbbabb" d="M17 21.5h1"/><path stroke="#b71c1c" d="M12 22.5h1m-1 1h1"/><path stroke="#bbbaba" d="M17 22.5h1"/><path stroke="#bbbbba" d="M17 23.5h1"/><path stroke="#b61c1d" d="M12 25.5h1"/>'
    ];
    // ATTRIBUTES END

    struct LarvaObject {
        uint256 skinTone;
        uint256 eyeColor;
        uint256 glasses;
        uint256 mouth;
    }

    function randomLarvaLad(uint256 tokenId) internal view returns (LarvaObject memory) {
        
        LarvaObject memory larvaLad;

        larvaLad.skinTone = getSkinTone(tokenId);
        larvaLad.eyeColor = getEyeColor(tokenId);
        larvaLad.glasses = getGlasses(tokenId);
        larvaLad.mouth = getMouth(tokenId, larvaLad.skinTone);

        return larvaLad;
    }
    
    function getTraits(LarvaObject memory larvaLad, uint256 tokenId) internal view returns (string memory) {
        
        string[20] memory parts;
        bool hasType;
        
        parts[0] = ', "attributes": [';
        parts[1] = '';
        parts[2] = '';
        parts[3] = '{"trait_type": "Skin Tone","value": "';
        parts[4] = skinToneNames[larvaLad.skinTone];
        parts[5] = '"}, {"trait_type": "Eye Color","value": "';
        parts[6] = eyeColorNames[larvaLad.eyeColor];
        parts[7] = '"}, {"trait_type": "Glasses","value": "';
        parts[8] = glassesNames[larvaLad.glasses];
        parts[9] = '"}, {"trait_type": "Mouth","value": "';
        parts[10] = mouthNames[larvaLad.mouth];
        // TYPES
        parts[11] = '"}, {"trait_type": "Type","value": "';
        // Skin Tone base types
        if(larvaLad.skinTone == 16) {
            parts[12] = "Invisible";
            hasType = true;
        } else if (larvaLad.skinTone == 17) {
            parts[12] = "Alien";
            hasType = true;
        } else if(larvaLad.skinTone == 18) {
            parts[12] = "Zombie";
            hasType = true;
        } else {
            parts[12] = '';
        }
        // Alien
        if(larvaLad.eyeColor == 14 && larvaLad.skinTone != 17) {
            if(hasType) {
                parts[13] = " | Alien";
            } else {
                parts[13] = "Alien";
                hasType = true;
            }
        }
        // Vampire
        if(larvaLad.eyeColor == 15 || larvaLad.mouth == 4) {
            if(hasType) {
                parts[14] = " | Vampire";
            } else {
                parts[14] = "Vampire";
                hasType = true;
            }
        }
        // Default Type (Human)
        if(!hasType) {
            parts[15] = "Human";
        } else {
            parts[15] = '';
        }


        // GENERATIONS
        parts[16] = '"}, {"trait_type": "Generation","value": "';
        if (tokenId < 100) {
            parts[17] = "Genesis";
            parts[18] = '';
        } else {
            parts[17] = "Gen-";
            parts[18] = toString(tokenId / 1000);
        }
        parts[19] = '"}], ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
                      output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13], parts[14]));
                      output = string(abi.encodePacked(output, parts[15], parts[16], parts[17], parts[18], parts[19]));
        return output;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getSkinTone(uint256 tokenId) internal pure returns (uint256) { // 5
        uint256 rand = random(string(abi.encodePacked("SKIN TONE", toString(tokenId))));

        uint256 rn = rand % 1000;
        // Specials (10% chance)
        if (rn>= 966) {return 18;}
        if(rn>=933) {return 17;}
        if(rn>=900) {return 16;}
        // Normal
        return rn % 16;
    }

    function getEyeColor(uint256 tokenId) internal pure returns (uint256) { //4
        uint256 rand = random(string(abi.encodePacked("LAYER FOUR", toString(tokenId))));

        uint256 rn = rand % 1000;
        // Specials (10% chance)
        if(rn >= 950) {return 15;}
        if(rn >=900) {return 14;}
        // Colored and Normal
        if(rn>=500) {
            return rn % 14; // Includes the colored ones
        } else {
            return rn % 3; // Black and Brown
        }
    }

    function getGlasses(uint256 tokenId) internal pure returns (uint256) { // 2
        uint256 rand = random(string(abi.encodePacked("LAYER FIVE", toString(tokenId))));

        uint256 rn = rand % 1000;

        if (rn >= 500) {
            return rn % 7; // Includes the glasses
        }
        return 0; // No glasses
    }

    function getMouth(uint256 tokenId, uint256 skinTone) internal pure returns (uint256) { // 4
        // Control for Zombie Mouth
        if(skinTone == 18) {return 0;}

        uint256 rand = random(string(abi.encodePacked("LAYER SIX", toString(tokenId))));

        uint256 rn = rand % 1000;
        // Special (10% chance)
        if (rn >= 900) {return 4;}
        // Normal
        return rn % 4;
    }

    function getSVG(LarvaObject memory larvaLad) internal view returns (string memory) {
        string[15] memory parts;

        parts[0] = '<svg id="x" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 30 30"><path fill="';
        parts[1] = '#FFFFFF';
        parts[2]= '" d="M0 0h30v30H0z"/>';

        // Skin Tone
        if(larvaLad.skinTone > 16) {
            parts[3] = skinToneLayers[larvaLad.skinTone];
            parts[4] = '';
            parts[5] = '';
        }
        else {
            parts[3] = '<rect x="4" y="4" width="22" height="22" fill="';
            parts[4] = skinToneLayers[larvaLad.skinTone];
            parts[5] = '"/>';
        }
        // Eye Color
        parts[6] = '<rect x="8" y="10" width="3" height="3" fill="';
        parts[7] = eyeColorLayers[larvaLad.eyeColor];
        parts[8] = '"/><rect x="19" y="10" width="3" height="3" fill="';
        parts[9] = eyeColorLayers[larvaLad.eyeColor];
        parts[10] = '"/>';
        // Pupil
        parts[11] = '<path fill="#000" d="M9 11h1v1H9zm11 0h1v1h-1z"/>';

        parts[12] = glassesLayers[larvaLad.glasses];
        parts[13] = mouthLayers[larvaLad.mouth];
        parts[14] = '<style>#x{shape-rendering: crispedges;}</style></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
                      output = string(abi.encodePacked(output, parts[8],parts[9],parts[10],parts[11],parts[12],parts[13],parts[14]));

        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        LarvaObject memory larvaLad = randomLarvaLad(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Larva Lad #', toString(tokenId), '", "description": "Larva Lads are a play on the CryptoPunks and their creators, Larva Labs. The artwork and metadata are fully on-chain and were randomly generated at mint."', getTraits(larvaLad, tokenId), '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(larvaLad))), '"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    function mint(address destination, uint256 amountOfTokens) private {
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");
        require(amountOfTokens <= maxMint, "Cannot purchase this many tokens in a transaction");
        require(amountOfTokens > 0, "Must mint at least one token");
        require(price * amountOfTokens == msg.value, "ETH amount is incorrect");

        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = numTokensMinted + 1;
            _safeMint(destination, tokenId);
            numTokensMinted += 1;
        }
    }

    function mintForSelf(uint256 amountOfTokens) public payable virtual {
        mint(_msgSender(),amountOfTokens);
    }

    function mintForFriend(address walletAddress, uint256 amountOfTokens) public payable virtual {
        mint(walletAddress,amountOfTokens);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setMaxMint(uint256 newMaxMint) public onlyOwner {
        maxMint = newMaxMint;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

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
    
    constructor() ERC721("Easy Avatars", "EASY") Ownable() {}
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

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