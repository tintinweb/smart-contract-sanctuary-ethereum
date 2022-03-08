/**
 *Submitted for verification at Etherscan.io on 2022-03-08
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

//////////////////////////////////////////////////////////////////////////////////////////////
//'████████::'██::::::::::'███::::'████████:'████████:::::::'██::::::::::'███::::'████████:://
// ██.... ██: ██:::::::::'██ ██:::..... ██::..... ██:::::::: ██:::::::::'██ ██::: ██.... ██://
// ██:::: ██: ██::::::::'██:. ██:::::: ██::::::: ██::::::::: ██::::::::'██:. ██:: ██:::: ██://
// ████████:: ██:::::::'██:::. ██:::: ██::::::: ██:::::::::: ██:::::::'██:::. ██: ████████:://
// ██.... ██: ██::::::: █████████::: ██::::::: ██::::::::::: ██::::::: █████████: ██.... ██://
// ██:::: ██: ██::::::: ██.... ██:: ██::::::: ██:::::::::::: ██::::::: ██.... ██: ██:::: ██://
// ████████:: ████████: ██:::: ██: ████████: ████████::::::: ████████: ██:::: ██: ████████:://
//..........................................................................................//
//.......................................................................by Jr Casas........//
//////////////////////////////////////////////////////////////////////////////////////////////


 

 contract BlazzLab is ERC721Enumerable, ReentrancyGuard, Ownable {

    uint256 public maxSupply = 3333;
    uint256 public price = 0.01 ether;
    uint256 public maxMint = 8;
    uint256 public numTokensMinted;

    string[10] private thirdNames = ['Finger', 'Bitten Finger', 'Zombie Finger', 'Zombie Bitten Finger', 'Eye', 'Denture', 'Denture Gold', 'Nipple', 'Zombie Nipple', 'Satoshi Hair'];
    string[10] private thirdLayers = [
        '<path fill="#FFF" d="m20,13h2v1h-1v1h1v1h-2v-1h-1v-1h1z"/><path fill="#E7C2B3" d="m13,12h6v4h-6v-1h-1v-2h1zm1,1h-1v2h2v-2z"/><path fill="#FFEDEB" d="m13,13h2v2h-2z"/>',
        '<path fill="#E7C2B3" d="m13,12h1v1h-1v2h2v-1h1v-1h1v-1h2v4h-6v-1h-1v-2h1z"/><path fill="#FFEDEB" d="m13,13h1v1h1v1h-2z"/><path fill="#952A00" d="m16,12h1v1h-1v1h-2v-1h2z"/><path fill="#FFF" d="m20,13h2v1h-1v1h1v1h-2v-1h-1v-1h1z"/>',
        '<path fill="#91A58E" d="m13,13h2v2h-2z"/><path fill="#FFF" d="m20,13h2v1h-1v1h1v1h-2v-1h-1v-1h1z"/><path fill="#416E4A" d="m13,12h6v4h-6v-1h-1v-2h1zm1,1h-1v2h2v-2z"/>',
        '<path fill="#91A58E" d="m13,13h1v1h1v1h-2z"/><path fill="#416E4A" d="m13,12h1v1h-1v2h2v-1h1v-1h1v-1h2v4h-6v-1h-1v-2h1z"/><path fill="#FFF" d="m20,13h2v1h-1v1h1v1h-2v-1h-1v-1h1z"/><path fill="#952A00" d="m16,12h1v1h-1v1h-2v-1h2z"/>',
        '<path fill="#E8EBE5" d="m14,12h4v4h-4zm2,1h-1v2h2v-2z"/><path fill="#000" d="m16,13h1v2h-2v-1h1z"/><path fill="#CDCCC7" d="m18,12h1v4h-1v1h-4v-1h4z"/><path fill="#FFF" d="m14,11h4v1h-4v4h-1v-4h1zm1,2h1v1h-1z"/>',
        '<path fill="#FFF" d="m12,15h1v1h1v1h-1v-1h-1zm8,0h1v1h-1v1h-1v-1h1zm-5,1h1v1h-1zm2,0h1v1h-1z"/><path fill="#D5948B" d="m12,13h2v1h5v-1h2v1h-1v1h-7v-1h-1z"/><path fill="#CD6F6D" d="m12,14h1v1h7v-1h1v1h-1v1h-7v-1h-1z"/>',
        '<path fill="#FFF" d="m12,15h1v1h-1zm8,0h1v1h-1v1h-1v-1h1zm-5,1h1v1h-1zm2,0h1v1h-1z"/><path fill="#CD6F6D" d="m12,14h1v1h7v-1h1v1h-1v1h-7v-1h-1z"/><path fill="#D5948B" d="m12,13h2v1h5v-1h2v1h-1v1h-7v-1h-1z"/><path fill="#e6d309" d="m13,16h1v1h-1z"/>',
        '<path fill="#FCC4A6" d="m15,12h3v1h1v3h-1v1h-3v-1h-1v-3h1zm1,1h-1v3h3v-3z"/><path fill="#B14547" d="m16,14h1v1h-1z"/><path fill="#CC7E6A" d="m17,13h1v3h-3v-1h2z"/><path fill="#E7927C" d="m15,13h2v1h-1v1h-1z"/>',
        '<path fill="#837853" d="m17,13h1v3h-3v-1h2z"/><path fill="#416E4A" d="m15,12h3v1h1v3h-1v1h-3v-1h-1v-3h1zm1,1h-1v3h3v-3z"/><path fill="#94454E" d="m16,14h1v1h-1z"/><path fill="#AE9569" d="m15,13h2v1h-1v1h-1z"/>',
        '<path fill="#423F3D" d="m16,16h1v1h-1v1h1v1h-1v-1h-1v-1h1z"/><path fill="#272A2D" d="m17,14h1v2h-1z"/><path fill="#000" d="m15,11h1v1h1v2h-1v-2h-1z"/>'];
    string[12] private fourthNames = ['Blue','Evaporated blue','Green','Evaporated green','Yellow','Evaporated yellow','Purple','Evaporated purple','Radioactive','Evaporated Radioactive','Regular','Evaporated regular'];
    string[12] private fourthLayers = [
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#19546D" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#5FA7BE" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#195467" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#117E9C" d="m12,5h8v1h1v1h1v1h1v15h-14v-15h1v-1h1v-1h1zm0,2h-1v1h1zm-1,2h-1v3h1zm10,2h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />',
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#19546D" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#5FA7BE" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#195467" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#117E9C" d="m9,10h1v2h1v-2h12v13h-14zm12,1h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />',
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#145237" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#6dbf9b" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#275c49" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#22855a" d="m12,5h8v1h1v1h1v1h1v15h-14v-15h1v-1h1v-1h1zm0,2h-1v1h1zm-1,2h-1v3h1zm10,2h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />',
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#145237" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#6dbf9b" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#275c49" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#22855a" d="m9,10h1v2h1v-2h12v13h-14zm12,1h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />',
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#9c9114" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#ede69a" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#aba13a" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#d6c61e" d="m12,5h8v1h1v1h1v1h1v15h-14v-15h1v-1h1v-1h1zm0,2h-1v1h1zm-1,2h-1v3h1zm10,2h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />',
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#9c9114" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#ede69a" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#aba13a" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#d6c61e" d="m9,10h1v2h1v-2h12v13h-14zm12,1h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />',
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#611d46" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#f0c2de" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#613b52" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#db7db6" d="m12,5h8v1h1v1h1v1h1v15h-14v-15h1v-1h1v-1h1zm0,2h-1v1h1zm-1,2h-1v3h1zm10,2h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />',
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#611d46" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#f0c2de" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#613b52" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#db7db6" d="m9,10h1v2h1v-2h12v13h-14zm12,1h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />',
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#2a8a0c" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#87fa64" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#5aa343" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#3cff00" d="m12,5h8v1h1v1h1v1h1v15h-14v-15h1v-1h1v-1h1zm0,2h-1v1h1zm-1,2h-1v3h1zm10,2h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />',
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#2a8a0c" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#87fa64" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#5aa343" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#3cff00" d="m9,10h1v2h1v-2h12v13h-14zm12,1h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />',
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#629ba1" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#c4eef2" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#646d6e" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#a1e0e6" d="m12,5h8v1h1v1h1v1h1v15h-14v-15h1v-1h1v-1h1zm0,2h-1v1h1zm-1,2h-1v3h1zm10,2h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />',
        '<path fill="#FFF" d="m11,7h1v1h-1zm-1,2h1v3h-1zm0,4h1v6h-1z"/><path fill="#629ba1" d="m21,17h1v1h-1zm-9,1h1v1h-1zm8,2h1v1h-1z" fill-opacity="0.5" /><path fill="#c4eef2" d="m20,11h1v1h-1zm-2,7h1v1h-1zm-5,2h1v1h-1z" fill-opacity="0.5" /><path fill="#646d6e" d="m12,4h8v1h1v1h1v1h1v1h1v15h-1v-15h-1v-1h-1v-1h-1v-1h-8v1h-1v1h-1v1h-1v15h-1v-15h1v-1h1v-1h1v-1h1z"/><path fill="#a1e0e6" d="m9,10h1v2h1v-2h12v13h-14zm12,1h-1v1h1zm-10,2h-1v6h1zm11,4h-1v1h1zm-9,1h-1v1h1zm6,0h-1v1h1zm-5,2h-1v1h1zm7,0h-1v1h1z" fill-opacity="0.3" />']; 
    string[10] private fifthNames = ['ESP','CRJ','GLL6','PQL','EYJ','TER','NF','JOR','AC','KAI'];
    string[10] private fifthLayers = [
        '<path fill="#e3aa1b" d="m7,24h18v1h1v1h-6v-1h-9v1h-5v-1h1zm-1,3h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1z"/><path fill="#565C53" d="m11,25h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1z"/><path fill="#949393" d="m12,25h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1z"/><path fill="#000" d="m7,23h18v1h1v1h1v4h-22v-4h1v-1h1zm1,1h-1v1h-1v3h20v-3h-1v-1z"/><path fill="#997314" d="m6,26h20v2h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1z"/>',
        '<path fill="#315779" d="m7,24h2v1h-2zm3,0h2v1h-2zm3,0h2v1h-2zm3,0h2v1h-2zm3,0h2v1h-2zm3,0h2v1h-2zm-16,2h20v2h-16v-1h-2v1h-2z"/><path fill="#c22715" d="m8,27h1v1h-1z"/><path fill="#439C29" d="m9,27h1v1h-1z"/><path fill="#082B3E" d="m9,24h1v1h2v-1h1v1h2v-1h1v1h2v-1h1v1h2v-1h1v1h2v-1h1v1h1v1h-20v-1h3z"/><path fill="#000" d="m7,23h18v1h1v1h1v4h-22v-4h1v-1h1zm1,1h-1v1h-1v3h20v-3h-1v-1z"/>',
        '<path fill="#6e150b" d="m6,25h20v3h-20v-1h1v-1h-1zm3,1h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h1z"/><path fill="#952A00" d="m7,24h4v1h-4zm13,0h5v1h-5zm-14,2h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1z"/><path fill="#3F3E40" d="m12,24h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1z"/><path fill="#000" d="m7,23h18v1h1v1h1v4h-22v-4h1v-1h1zm1,1h-1v1h-1v3h20v-3h-1v-1z"/><path fill="#949393" d="m11,24h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1z"/> ',
        '<path fill="#8a7c11" d="m8,24h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm-17,2h3v2h-1v-1h-1v1h-1zm6,0h6v2h-1v-1h-4v1h-1zm9,0h3v2h-1v-1h-1v1h-1z"/><path fill="#d9c31c" d="m7,24h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v-1h1v1h2v3h-1v-2h-3v2h-3v-2h-6v2h-3v-2h-3v2h-1v-3h1zm1,3h1v1h-1zm6,0h4v1h-4zm9,0h1v1h-1z"/><path fill="#000" d="m7,23h18v1h1v1h1v4h-22v-4h1v-1h1zm1,1h-1v1h-1v3h20v-3h-1v-1z"/>',
        '<path fill="#929491" d="m7,24h18v1h1v1h-2v-1h-1v1h-2v-1h-1v1h-2v-1h-1v1h-2v-1h-1v1h-2v-1h-1v1h-2v-1h-1v1h-2v-1h1zm-1,3h20v1h-20z"/><path fill="#4A4E4D" d="m8,25h1v1h2v-1h1v1h2v-1h1v1h2v-1h1v1h2v-1h1v1h2v-1h1v1h2v1h-20v-1h2z"/><path fill="#000" d="m7,23h18v1h1v1h1v4h-22v-4h1v-1h1zm1,1h-1v1h-1v3h20v-3h-1v-1z"/>',
        '<path fill="#000" d="m7,23h18v1h1v1h1v4h-22v-4h1v-1h1zm1,1h-1v1h-1v3h20v-3h-1v-1z"/><path fill="#5C6F41" d="m7,24h18v1h1v3h-20v-3h1zm1,1h-1v2h1zm2,0h-1v2h1zm2,0h-1v2h1zm2,0h-1v2h1zm2,0h-1v2h2v-2zm3,0h-1v2h1zm2,0h-1v2h1zm2,0h-1v2h1zm2,0h-1v2h1z"/><path fill="#3B4A2C" d="m7,25h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1zm2,0h2v2h-2zm3,0h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1z"/>',
        '<path fill="#000" d="m7,23h18v1h1v1h1v4h-22v-4h1v-1h1zm1,1h-1v1h-1v3h20v-3h-1v-1z"/><path fill="#775e8a" d="m7,25h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h2v1h-2zm3,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm-18,2h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h8v1h-8zm9,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1z"/><path fill="#4b3859" d="m7,24h18v1h1v2h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-8v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v-2h1zm1,1h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h2v-1zm3,0h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h1zm2,0h-1v1h1z"/>',
        '<path fill="#9c6f00" d="m8,24h1v2h1v-2h1v2h1v-2h1v2h1v-2h1v2h1v-2h1v2h1v-2h1v2h1v-2h1v2h1v-2h1v2h1v-2h1v2h1v1h-20v-2h1v1h1z"/><path fill="#e6ba4e" d="m11,25h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm-12,2h1v1h-1zm17,0h1v1h-1z"/><path fill="#000" d="m7,23h18v1h1v1h1v4h-22v-4h1v-1h1zm1,1h-1v1h-1v3h20v-3h-1v-1z"/><path fill="#cf9400" d="m7,24h1v2h-1zm2,0h1v2h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v2h-1zm2,0h1v2h-1zm2,1h1v1h-1zm-19,2h1v1h-1zm2,0h16v1h-16zm17,0h1v1h-1z"/>',
        '<path fill="#2B5D6D" d="m6,26h1v1h-1zm2,0h3v1h-3zm4,0h3v1h-3zm4,0h3v1h-3zm4,0h3v1h-3zm4,0h2v1h-2z"/><path fill="#4a0700" d="m6,25h20v1h-2v1h2v1h-20v-1h1v-1h-1zm3,1h-1v1h3v-1zm4,0h-1v1h3v-1zm4,0h-1v1h3v-1zm4,0h-1v1h3v-1z"/><path fill="#000" d="m7,23h18v1h1v1h1v4h-22v-4h1v-1h1zm1,1h-1v1h-1v3h20v-3h-1v-1z"/><path fill="#952A00" d="m7,24h18v1h-18z"/>',
        '<path fill="#EDEADC" d="m6,25h20v1h-1v2h-1v-2h-1v2h-1v-2h-1v2h-1v-2h-1v2h-1v-2h-1v2h-1v-2h-1v2h-1v-2h-1v2h-1v-2h-1v2h-1v-2h-1v2h-1v-2h-1v2h-1z"/><path fill="#000" d="m7,23h18v1h1v1h1v4h-22v-4h1v-1h1zm1,1h-1v1h-1v3h20v-3h-1v-1z"/><path fill="#C5C7AF" d="m7,24h18v1h-18zm0,2h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1zm2,0h1v2h-1z"/>']; 
    string[13] private sixthNames = ['Plug','LAN','Hand crank','One Button','Ring','Caution','Wind up','Buttons','Lever','Load indicator','Verified','Handle','Winder'];
    string[13] private sixthLayers = [
        '<path fill="#631811" d="m24,12h1v1h1v3h-1v1h-1z"/><path fill="#9c2217" d="m27,25h1v3h-1z"/><path fill="#000" d="m26,14h2v1h1v2h-1v1h-1v1h1v1h1v4h1v2h-1v1h-1v-1h1v-2h-1v-4h-1v-1h-1v-1h1v-1h1v-2h-2z"/> ',
        '<path fill="#801e14" d="m5,9h1v1h-1z"/><path fill="#647377" d="m5,10h1v8h-1z"/><path fill="#4A4E4D" d="m7,16h1v4h-1v-1h-1v-2h1z"/> ',
        '<path fill="#6E491E" d="m2,17h2v1h-2z"/><path fill="#000000" d="m7,11h1v5h-1v-1h-1v-3h1z"/><path fill="#647377" d="m5,13h1v5h-2v-1h1z"/>',
        '<path fill="#e3a617" d="m25,12h1v2h-1z"/><path fill="#052B36" d="m24,11h1v4h-1z"/>',
        '<path fill="#3A4446" d="m6,20h2v1h-2zm4,0h1v1h-1zm3,0h1v1h-1zm3,0h1v1h-1zm3,0h1v1h-1zm3,0h1v1h-1zm2,0h2v1h-2z"/><path fill="#5D7272" d="m7,19h18v1h-1v1h1v1h-18v-1h1v-1h-1zm4,1h-1v1h1zm3,0h-1v1h1zm3,0h-1v1h1zm3,0h-1v1h1zm3,0h-1v1h1z"/>',
        '<path fill="#e3c817" d="m7,16h5v4h-1v1h-1v1h-3zm3,1h-1v2h1zm0,3h-1v1h1z"/><path fill="#000" d="m9,17h1v2h-1zm0,3h1v1h-1z"/><path fill="#EFA603" d="m11,20h1v1h-1v1h-1v-1h1z"/>',
        '<path fill="#a13115" d="m26,13h3v3h-1v1h1v3h-3v-3h-1v-1h1zm2,1h-1v1h1zm0,4h-1v1h1z"/><path fill="#263238" d="m24,14h1v5h-1z"/>',
        '<path fill="#ba200b" d="m6,14h1v1h-1z"/><path fill="#1f690f" d="m6,16h1v1h-1z"/><path fill="#263238" d="m7,11h1v7h-1z"/><path fill="#d9cf16" d="m6,12h1v1h-1z"/>',
        '<path fill="#112326" d="m24,14h1v7h-1z"/><path fill="#8a2c19" d="m27,14h2v2h-2z"/><path fill="#3A4D51" d="m26,16h1v1h-1v2h-1v-2h1z"/>',
        '<path fill="#26323A" d="m11,19h10v3h-10zm2,1h-1v1h8v-1z"/><path fill="#184831" d="m17,20h3v1h-3z"/><path fill="#56a81b" d="m12,20h5v1h-5z"/>',
        '<path fill="#117E9C" d="m19,17h6v5h-6zm5,1h-1v1h1zm-3,1h-1v1h1zm2,0h-1v1h1zm-1,1h-1v1h1z"/><path fill="#FFF" d="m23,18h1v1h-1v1h-1v1h-1v-1h-1v-1h1v1h1v-1h1z"/>',
        '<path fill="#3A4446" d="m25,10h2v3h-1v-2h-1zm1,8h1v3h-2v-1h1z"/><path fill="#102f3d" d="m24,9h1v3h-1zm0,10h1v3h-1z"/><path fill="#302919" d="m25,13h3v5h-3z"/>',
        '<path fill="#3A4446" d="m5,10h2v1h-2zm0,2h2v1h-2zm0,2h2v1h-2zm0,2h2v1h-2zm0,2h2v1h-2z"/><path fill="#5A6C6C" d="m5,11h2v1h-2zm0,2h2v1h-2zm0,2h2v1h-2zm0,2h2v1h-2z"/><path fill="#700909" d="m7,13h1v3h-1z"/>'];       
    string[11] private seventhNames = ['Button','Charge','Vernon','Broken','Weisz','Bamberg','Carroll','Kaufman','Clifton','Ascanio','None'];
    string[11] private seventhLayers = [
        '<path fill="#851515" d="m15,2h2v1h-2z"/><path fill="#51514D" d="m12,4h8v1h-8z"/><path fill="#34352B" d="m14,3h4v1h-4z"/>',
        '<path fill="#7fbf24" d="m11,4h4v1h-4z"/><path fill="#2A3B42" d="m10,3h12v1h1v1h-1v1h-12v-1h-1v-1h1zm2,1h-1v1h10v-1z"/><path fill="#E23E36" d="m20,4h1v1h-1z"/><path fill="#FFB31A" d="m18,4h2v1h-2z"/><path fill="#d6d12d" d="m15,4h3v1h-3z"/>',
        '<path fill="#455A60" d="m9,4h1v1h-1zm13,0h1v1h-1z"/><path fill="#364F38" d="m10,3h12v1h-12zm0,2h12v1h-12z"/><path fill="#e8a41c" d="m8,4h1v1h-1zm15,0h1v1h-1z"/><path fill="#1C3331" d="m10,4h12v1h-12z"/>',
        '<path fill="#FFF" d="m19,5h1v1h-1v2h1v1h1v1h-1v-1h-1v-1h-1v1h-1v1h-1v1h-1v-1h1v-1h1v-1h1v-2h1z"/>',
        '<path fill="#916c20" d="m12,3h8v1h-8z"/><path fill="#3F3E40" d="m11,5h10v1h-10z"/><path fill="#45595D" d="m10,4h12v1h-12zm0,2h12v1h-12z"/>',
        '<path fill="#E23E36" d="m11,3h1v1h-1z"/><path fill="#45595D" d="m10,3h1v1h-1zm3,0h9v1h-9zm-5,2h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1zm2,0h1v1h-1z"/><path fill="#439C29" d="m12,3h1v1h-1z"/><path fill="#2B3B41" d="m9,4h14v1h1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1v-1h-1v1h-1z"/>',
        '<path fill="#2A3B42" d="m15,2h2v1h2v1h1v-1h3v3h-3v-1h-3v1h-2v-1h-3v1h-3v-3h3v1h1v-1h2zm-4,2h-1v1h1zm11,0h-1v1h1z"/>',
        '<path fill="#313335" d="m12,4h8v1h-8z"/><path fill="#99242D" d="m11,3h10v1h-10z"/><path fill="#000" d="m11,5h10v1h-10z"/>',
        '<path fill="#FFF" d="m15,3h2v1h-2z"/><path fill="#99242D" d="m12,2h8v1h-8z"/><path fill="#252B20" d="m10,6h12v1h-12z"/><path fill="#4B4C3C" d="m9,4h14v2h-14z"/>',
        '<path fill="#117E9C" d="m9,6h14v1h-14z"/><path fill="#FFCC01" d="m19,4h1v1h-1z"/><path fill="#2D545A" d="m18,3h3v3h-3zm2,1h-1v1h1z"/><path fill="#082B3E" d="m10,3h8v3h-9v1h-1v-2h1v-1h1zm11,0h1v1h1v1h1v2h-1v-1h-2z"/>',
        ''];

  struct BlazzObject {
        uint256 layerThree;
        uint256 layerFour;
        uint256 layerFive;
        uint256 layerSix;
        uint256 layerSeven;
    }

function randomBlazzLab(uint256 tokenId) internal pure returns (BlazzObject memory) {
        
        BlazzObject memory blazzLab;

        blazzLab.layerThree = getLayerThree(tokenId);
        blazzLab.layerFour = getLayerFour(tokenId);
        blazzLab.layerFive = getLayerFive(tokenId);
        blazzLab.layerSix = getLayerSix(tokenId);
        blazzLab.layerSeven = getLayerSeven(tokenId);

        return blazzLab;
    }

function getTraits(BlazzObject memory blazzLab) internal view returns (string memory) {
        
        string[17] memory parts;
        
        parts[0] = ', "attributes": [{"trait_type": "Souvenir","value": "';
        parts[1] = thirdNames[blazzLab.layerThree]; 
        parts[2] = '"}, {"trait_type": "Jar","value": "';
        parts[3] = fourthNames[blazzLab.layerFour];
        parts[4] = '"}, {"trait_type": "Base","value": "';
        parts[5] = fifthNames[blazzLab.layerFive];
        parts[6] = '"}, {"trait_type": "Accessory","value": "';
        parts[7] = sixthNames[blazzLab.layerSix];
        parts[8] = '"}, {"trait_type": "Top","value": "';
        parts[9] = seventhNames[blazzLab.layerSeven];
        parts[10] = '"}], ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
                      output = string(abi.encodePacked(output, parts[3], parts[4], parts[5], parts[6], parts[7], parts[8], parts[9], parts[10]));
        return output;
    }    

function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

function getLayerThree(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER THREE", toString(tokenId))));

        uint256 rn3 = rand % 275;
        uint256 l3 = 0;

        if (rn3 >= 40 && rn3 < 75) { l3 = 1; }
        if (rn3 >= 75 && rn3 < 110) { l3 = 2; }
        if (rn3 >= 110 && rn3 < 140) { l3 = 3; }
        if (rn3 >= 140 && rn3 < 180) { l3 = 4; }
        if (rn3 >= 180 && rn3 < 220) { l3 = 5; }
        if (rn3 >= 220 && rn3 < 245) { l3 = 6; }
        if (rn3 >= 245 && rn3 < 260) { l3 = 7; }
        if (rn3 >= 260 && rn3 < 270) { l3 = 8; }
        if (rn3 >= 270) { l3 = 9; }
        
        return l3;
    }

    function getLayerFour(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER FOUR", toString(tokenId))));

        uint256 rn4 = rand % 310;
        uint256 l4 = 0;

        if (rn4 >= 35 && rn4 < 65) { l4 = 1; }
        if (rn4 >= 65 && rn4 < 100) { l4 = 2; }
        if (rn4 >= 100 && rn4 < 130) { l4 = 3; }
        if (rn4 >= 130 && rn4 < 155) { l4 = 4; }
        if (rn4 >= 155 && rn4 < 175) { l4 = 5; }
        if (rn4 >= 175 && rn4 < 200) { l4 = 6; }
        if (rn4 >= 200 && rn4 < 220) { l4 = 7; }
        if (rn4 >= 220 && rn4 < 235) { l4 = 8; }
        if (rn4 >= 235 && rn4 < 245) { l4 = 9; }
        if (rn4 >= 245 && rn4 < 280) { l4 = 10; }
        if (rn4 >= 280) { l4 = 11; }
        
        return l4;
    }

   function getLayerFive(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER FIVE", toString(tokenId))));

        uint256 rn5 = rand % 165;
        uint256 l5 = 0;

        if (rn5 >= 15 && rn5 < 27) { l5 = 1; }
        if (rn5 >= 27 && rn5 < 40) { l5 = 2; }
        if (rn5 >= 40 && rn5 < 60) { l5 = 3; }
        if (rn5 >= 60 && rn5 < 80) { l5 = 4; }
        if (rn5 >= 80 && rn5 < 100) { l5 = 5; }
        if (rn5 >= 100 && rn5 < 120) { l5 = 6; }
        if (rn5 >= 120 && rn5 < 140) { l5 = 7; }
        if (rn5 >= 140 && rn5 < 155) { l5 = 8; }
        if (rn5 >= 155) { l5 = 9; }
        
        
        return l5;
    }

   function getLayerSix(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER SIX", toString(tokenId))));

        uint256 rn6 = rand % 300;
        uint256 l6 = 0;

        if (rn6 >= 25 && rn6 < 55) { l6 = 1; }
        if (rn6 >= 55 && rn6 < 80) { l6 = 2; }
        if (rn6 >= 80 && rn6 < 110) { l6 = 3; }
        if (rn6 >= 110 && rn6 < 130) { l6 = 4; }
        if (rn6 >= 130 && rn6 < 145) { l6 = 5; }
        if (rn6 >= 145 && rn6 < 160) { l6 = 6; }
        if (rn6 >= 160 && rn6 < 190) { l6 = 7; }
        if (rn6 >= 190 && rn6 < 215) { l6 = 8; }
        if (rn6 >= 215 && rn6 < 245) { l6 = 9; }
        if (rn6 >= 245 && rn6 < 255) { l6 = 10; }
        if (rn6 >= 255 && rn6 < 280) { l6 = 11; }
        if (rn6 >= 280) { l6 = 12; }
        
        return l6;
    }

 function getLayerSeven(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("LAYER SEVEN", toString(tokenId))));

        uint256 rn7 = rand % 220;
        uint256 l7 = 0;

        if (rn7 >= 30 && rn7 < 60) { l7 = 1; }
        if (rn7 >= 60 && rn7 < 90) { l7 = 2; }
        if (rn7 >= 90 && rn7 < 110) { l7 = 3; }
        if (rn7 >= 110 && rn7 < 130) { l7 = 4; }
        if (rn7 >= 130 && rn7 < 150) { l7 = 5; }
        if (rn7 >= 150 && rn7 < 165) { l7 = 6; }
         if (rn7 >= 165 && rn7 < 180) { l7 = 7; }
        if (rn7 >= 180 && rn7 < 195) { l7 = 8; }
        if (rn7 >= 195 && rn7 < 205) { l7 = 9; }
        if (rn7 >= 205) { l7 = 10; }
        
        return l7;
    }

   function getSVG(BlazzObject memory blazzLab) internal view returns (string memory) {
        string[7] memory parts;

        parts[0] = '<svg id="x" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 32 32"><path fill="#94b5ae" d="m0,0h32v32h-32z"/>';
        parts[1] = thirdLayers[blazzLab.layerThree];
        parts[2] = fourthLayers[blazzLab.layerFour];
        parts[3] = fifthLayers[blazzLab.layerFive];
        parts[4] = sixthLayers[blazzLab.layerSix];
        parts[5] = seventhLayers[blazzLab.layerSeven];
        parts[6] = '<style>#x{shape-rendering: crispedges;}</style></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));

        return output;
    }

   function tokenURI(uint256 tokenId) override public view returns (string memory) {
        BlazzObject memory blazzLab = randomBlazzLab(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Blazz Lab Exp.No #', toString(tokenId), '", "description": "Blazz Lab is a laboratory full of experiments done by Dr Blazz, an illustrator alter ego. These experiments are completely on-chain and were randomly generated at mint."', getTraits(blazzLab), '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(blazzLab))), '"}'))));
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
    
    constructor() ERC721("Blazz Lab", "BLAZZ") Ownable() {}
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