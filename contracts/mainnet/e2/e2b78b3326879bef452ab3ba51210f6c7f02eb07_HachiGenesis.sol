/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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
        uint256 tokenId,
        bytes calldata data
    ) external;

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

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
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

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

contract HachiGenesis is Ownable, ERC721Enumerable {
    uint airdropCount;
    string public jsonUrl = "https://ipfs.io/ipfs/bafkreidzf27gmlqxm6vpcvmezxpl7w27damsxgfggqdlbin2a7fnn4ek4m";

    constructor() ERC721("Hachi Genesis", "Hachi Genesis")
    {
    }

    // Public functions
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return jsonUrl;
    }

    // Admin functions
    function setJsonUrl(string memory _jsonURL) public onlyOwner
    {
        jsonUrl = _jsonURL;
    }

    // Internal functions
    function airdropWallet(address tookenHolder) internal onlyOwner
    {
        _mint(tookenHolder, airdropCount);
        airdropCount += 1;
    }

    
    bool hasAirdroped1;
    function airdriop1() public onlyOwner
    {
        require(!hasAirdroped1, "Already airdroped");
        hasAirdroped1 = true;
        airdropWallet(0x0002b5Ca4Da0bF9b22480A39C32145159388BAeD);
        airdropWallet(0x00054C092e873CFE0BFaEEc69537A4Fc3da4F7F0);
        airdropWallet(0x002b0C31daF1002B438881a28F2023830314688C);
        airdropWallet(0x00B81C48d7820d1AC0668eFc77a336811516463c);
        airdropWallet(0x00E484DA1156202e9Dd341aD7Ea9c908bB919E96);
        airdropWallet(0x018d88b7ceE0b46BcB6B2C7703D6525C4D3eEC7E);
        airdropWallet(0x02652E0b2ddc2adB1e8d8d6E001DCb851c1017b4);
        airdropWallet(0x03f138f78c0AB07dF2b7ED45FCA883c72e35D6c1);
        airdropWallet(0x0608Ed9cb30695C931595be6Be36dad7c472F64e);
        airdropWallet(0x076164Cd19f8195E1F48B852CCcf2967995C3F5D);
        airdropWallet(0x07b8E708Db091892A897E87C57aed0A74404c986);
        airdropWallet(0x07d7F25597068D3307DB6b918Cd54f79ADcF75f6);
        airdropWallet(0x07De51F88a817F3646c3fd9CDCAE690A58157759);
        airdropWallet(0x08B750f138a4CdbA655ee5D137dEd9c466edDbC6);
        airdropWallet(0x0bAA57514DB4a4b29ed6e134f394BAb2b6D3C57d);
        airdropWallet(0x0ddfc4F6ff2A5256964DB3A687E854152B454fcb);
        airdropWallet(0x0E1C29CA6d943B69cD7eC94D1bf7f7c675824F73);
        airdropWallet(0x0ef8751a701D8f759BCC7c54D8e5901775b8628F);
        airdropWallet(0x0f223aAd80340131Df5Dc203704ac4Cc2368e328);
        airdropWallet(0x0feb7C0e1B1dA2D1Da6D835Fa314A3B7dC39A925);
        airdropWallet(0x131e0a48c34128a9dD7Bf298c5517481196E18dF);
        airdropWallet(0x145C389Fe337c45B1574313B5A6cB37C78121E78);
        airdropWallet(0x150eAE15731B23d7c670C8FeE964b44a15fb5F41);
        airdropWallet(0x168F19f96e1a12223a74FB6d89A281F16D8a734d);
        airdropWallet(0x1747d7a17a686D1Ba0298ebe8ac61d7b930e8756);
        airdropWallet(0x179Dea89D9071EEf3EA258ADB6AE8cEF03f8fE0F);
        airdropWallet(0x17Fe950d179270CeF668f5FFA5a2B4638278A4a7);
        airdropWallet(0x197dFea49c88554dBdAAcBc0DBF7AF425e150E79);
    }

    bool hasAirdroped2;
    function airdriop2() public onlyOwner
    {
        require(!hasAirdroped2, "Already airdroped");
        hasAirdroped2 = true;
        airdropWallet(0x1BF0051d2d535cd942e520a74b2eB1F1d33e16b9);
        airdropWallet(0x1E6fC9cA1aeA9A0a033D6CB1cE17604E8E1FE70C);
        airdropWallet(0x1eb06e7EA91D88677EacF33d6a397A25EEA96E59);
        airdropWallet(0x1F685EE91Ec2cd4441e8b866B34DE4d55aC5e84E);
        airdropWallet(0x2130D266a7012d09df3663A3eAcE40434e50838B);
        airdropWallet(0x21795DE36050ea88373Fa4a7C6D29c75163D78BA);
        airdropWallet(0x21AaCf8fa411eEffa1Eef72dbcF7870c58563868);
        airdropWallet(0x230ca8e5E11165A95a37BA2CbEbE670Fa78cDDe5);
        airdropWallet(0x249a3B30d21a539E4d1dAc23B5a0A213D2C1A4d1);
        airdropWallet(0x27C3440d432B0430b2d4d4Af73AEddf12fBb0F73);
        airdropWallet(0x280dDf1E307D05170880691F9811e3B96201B060);
        airdropWallet(0x2876185c43ee53f6eA5D77ca9aCf91Ca1D092693);
        airdropWallet(0x290AbF9D5AF63216f253cb53F092A658494eD2F9);
        airdropWallet(0x2A3A14aB391036321468A9A8b9D313bA6BB3aC18);
        airdropWallet(0x2b8272d1408B0869F7c2d545c07ead4B45De729A);
        airdropWallet(0x2c37eD29Aeaa0988933536992D2Bb4a8c77E33b2);
        airdropWallet(0x2cB2E8EF96E367D685d8114c180308c046b90b34);
        airdropWallet(0x2DAbea4AF8d0A28D81EB07B63F4A8B3e96bC2D39);
        airdropWallet(0x2e9Ef0a73FC87C30D2d0530510D2200C7e6d47F5);
        airdropWallet(0x30fbC361c36A7453EeEfd8c26a1A877D05d34f07);
        airdropWallet(0x3124F27f5083561091DAfbe088D339f1d26f97AF);
        airdropWallet(0x34D49C33141789274420eE840749EDC294d72c0F);
        airdropWallet(0x37c0597b932220237B7D40609CD8cb7Ed52D2ee4);
        airdropWallet(0x38f275d726E35B04aC84050F01c36787413C44f4);
        airdropWallet(0x3A1c8F2438a5787098D4414856165e6B5aa367BD);
        airdropWallet(0x3ca6B72964EB1397C05655fAAb6684c8C6E5B5c9);
        airdropWallet(0x3ec787D3F7749996C41605ED840059271Dc4F746);
        airdropWallet(0x3FcE01CbB97de2252669115f8F4Cc185005c94a6);
        airdropWallet(0x3FDd8F1829378972BD7770983551855Ce27027Fb);
        airdropWallet(0x3FED5d0F3963f4077Bc354c984a08205E10dad08);
        airdropWallet(0x40539417192d83145a57C6EdF598C70A51B628D5);
        airdropWallet(0x4056D26c77B3523c965a59035718250864C79F12);
        airdropWallet(0x41251778ad11de2B805a9324FFc43088c23BE5a5);
        airdropWallet(0x412542fd7507Ef937B1d8a7a1cDEe79d32697A60);
        airdropWallet(0x4354270E07a2451f3CF817b249e8306A11C9EC7D);
        airdropWallet(0x43c2741555923663F6f9a44CF618295FB26b546c);
    }

    bool hasAirdroped3;
    function airdrop3() public onlyOwner
    {
        require(!hasAirdroped3, "Already airdroped");
        hasAirdroped3 = true;
        airdropWallet(0x47a3EEF73Cc7e451D87CB88B93b19b42145B6dd9);
        airdropWallet(0x47Ab348FB8919639cD8206CA06feaF8B32fFdF9F);
        airdropWallet(0x480c63C1bA5171401877294fFc36A587D2828117);
        airdropWallet(0x4909f0A535323e5Af4dfF495508FdEAAEBaFe005);
        airdropWallet(0x4bBDEc9fBbaEFc56b3b12d60605766552a8B35eF);
        airdropWallet(0x4C29342d3D7121da87109e9bB444451984DE7386);
        airdropWallet(0x4dA997ae2fB22F6193378b8D1c778e013B83B0Cc);
        airdropWallet(0x4F5fE30f1bC11e44EaD9D6ce84d9E6c4518a97AC);
        airdropWallet(0x5132FDe5C8Ce41A4CCf6770b896396fEa5CD73D7);
        airdropWallet(0x5331C00399937Ca2e8A37378ad50Ee4d7A13Da12);
        airdropWallet(0x547854B13119De7da0C40Dd60ee59ABf519cd4F9);
        airdropWallet(0x54e19eEe4a2043Cf1CF26A4282Baa2e5EBEED0C6);
        airdropWallet(0x557031FD99596C139B4575ff50548dcb0BDc9969);
        airdropWallet(0x58Fd10Cc35aDfCEB34676d06E6df2aAb24A211d2);
        airdropWallet(0x5aaF51511E17Ef2007aA4c3761ac1362f3E3b525);
        airdropWallet(0x5ac2BCa5166B8462d6e699C38D6eB7035257dDA0);
        airdropWallet(0x5c95e53a71D48dA4bF1490eB94ADd905D425998e);
        airdropWallet(0x5dcE05cC63c0F3694E833030d5FE5A5f12BD041d);
        airdropWallet(0x611ECf8ccDFF887F9f484cf0301a3DC9761Baa75);
        airdropWallet(0x6176482fB7D071C349189267E6E5Bc9A102fEAEb);
        airdropWallet(0x6316607061B1e7AFCed6CfDf4bE7fe4535E3f5Aa);
        airdropWallet(0x64b4626db1EEA881D42801b28C61B3FC99637a55);
        airdropWallet(0x65A916326dEBcC210406df892d96EbEB2e0e6d3e);
        airdropWallet(0x67A7260EB9B5987F26ebdF573466257A15E75516);
        airdropWallet(0x68dD454fb9aCee0348779Bc91562e60921188D4D);
        airdropWallet(0x6AAEFd3B20aC8beA99a884Ca031694aBF0084597);
        airdropWallet(0x6b3D6E0ee8b0203A22BE2573C90687A85bA22B2C);
        airdropWallet(0x6cd187D8F740563D60039eE4Cec7E23A46847C6d);
        airdropWallet(0x704E2179d8f8132379da9c4d80982a78D35EcD7D);
        airdropWallet(0x708F9144a8754A88e07493a1718Fcc9ECA3115E2);
        airdropWallet(0x7161b0519646080Cb243d725b3879489Efe978b7);
        airdropWallet(0x769cd3bE2dd0C46B0bAc39e5eA1Ab01618C3d0eB);
    }

    bool hasAirdroped4;
    function airdrop4() public onlyOwner
    {
        require(!hasAirdroped4, "Already airdroped");
        hasAirdroped4 = true;
        airdropWallet(0x76D136de35aC07c328bE0031Fb7fB11564a9a2c8);
        airdropWallet(0x775062ffAc636A4EA71BBB4dd24e8f9737A6e4aa);
        airdropWallet(0x777A9D40a8394E28BA7aE73169DD633C55FdeA70);
        airdropWallet(0x7a2BF3cc90f687A10f343F88B0A03d6D06373e55);
        airdropWallet(0x7a8CBFBd249eA1d5c55eE92aF8F0Bc7aBA0474b6);
        airdropWallet(0x7aB81279079bfF09acfcF02E09C85663e10dD526);
        airdropWallet(0x7BA908A79Ee7255345274CEdb0D20d7C20EaF4fd);
        airdropWallet(0x7DC1A46F77b1DEeCA190Cd7CA75892AB59A71020);
        airdropWallet(0x7E90505c0B9F6FfB0900F9456FCa115d928C2C65);
        airdropWallet(0x7Ed7778D10A22225Cf52D04CeB4AA83B5C5A6ED2);
        airdropWallet(0x7f22b8B09277FDe609356e5B4AEb85b843c40a98);
        airdropWallet(0x7F96bC079eb57309BEF57D430733D5C09e4e1C06);
        airdropWallet(0x8054b51b8bC4Bf030FADc559275bAf8dd8a4370B);
        airdropWallet(0x81bC934fd94EC8D2b5e893a6af45d4c177E585ab);
        airdropWallet(0x820132C2F6970167cC6892a79e8F35c68a0e549A);
        airdropWallet(0x8286B3Cf17FF234F09960ed1853AE80969107ab4);
        airdropWallet(0x841F03ee667B7C71e61dD7d1C720189751459558);
        airdropWallet(0x86A41524CB61edd8B115A72Ad9735F8068996688);
        airdropWallet(0x86E3C94b8a8dC524128b1E5e348002BEaE990D82);
        airdropWallet(0x87a47d43231b6b21EF9DeEBBEB4470AF3aFE1D0F);
        airdropWallet(0x886b2Ef4807936d1eF3D2d18632181f6a68C853d);
        airdropWallet(0x89ea038506eb6B73649189BFCB9c6eb374bB8D31);
        airdropWallet(0x8CaDa160EEE3Fc211932D6e20FE686132831DcA9);
        airdropWallet(0x8D672aBd1e33981Bd578c866bE49854F5DF70Fe1);
        airdropWallet(0x918dbe156d5B91EFb22f1baE1EE0fD28a89ce40c);
        airdropWallet(0x9309db22BA1BBDA70334126689de6e7EB0bdcA53);
        airdropWallet(0x95CD3D3376cF4725de11Fc28037686F37DC147E6);
        airdropWallet(0x9620Da3d1Cece0ac2B43d5012270B4036894DE4a);
        airdropWallet(0x96c23ef196E9cFD7d9F3ABAe91E5fAfC3C736c91);
    }

    bool hasAirdroped5;
    function airdrop5() public onlyOwner
    {
        require(!hasAirdroped5, "Already airdroped");
        hasAirdroped5 = true;
        airdropWallet(0x9987ab4a0c51f29C4c9D6988B760aC5e9FB51224);
        airdropWallet(0x9A36873C01263d3ac50b9Ab0d34D9B911F070777);
        airdropWallet(0x9B4435860ead4Ba77c674ce924BE8DE2Bf750B39);
        airdropWallet(0x9B8D03cf2451D6430E8F859e544F928cEAA7B806);
        airdropWallet(0x9Ba85A22d341bccBd486e0814eFfe6aA35BF5033);
        airdropWallet(0x9bAdE92C153C469061028B649ca33f25deBb78a7);
        airdropWallet(0x9C9530F27Bb5D285a04dE66E25b391Af1696A037);
        airdropWallet(0x9E9CDcFE2B3B7b9DE43f91205D49edB15A4e0b82);
        airdropWallet(0x9F5504dbE18c5415C733463187164aC1bEfBd0B1);
        airdropWallet(0xa0b4a0CCfb739Fe90f76B552E4e997eE20808DF5);
        airdropWallet(0xA1b78400775A3CA1AEcB6B5e924772508d70a69C);
        airdropWallet(0xa323096d3Fc2DE85BAbAD3e2f1dd4f2473915923);
        airdropWallet(0xa5aC76AD3D2Da07764Fc8d444ccF04deE606867e);
        airdropWallet(0xa6E7FDE35e631Fb846cDF923DD0447805B452649);
        airdropWallet(0xa80E2d8f4414aFe769C2d3706A88Ede2b737Cc17);
        airdropWallet(0xA8c625DceCd023e428244422CD1ee6370CEe904c);
        airdropWallet(0xa9bE90574238F299554b41c8Ab62DD443c24857a);
        airdropWallet(0xAA166fd6C5590DC5F421d2662599b75CD32106cC);
        airdropWallet(0xAa57b446b3bD438Ee9be9F9068511fcfBbbB9A4A);
        airdropWallet(0xaAa313393E79ea3454939e843E0AA8DEC66A9949);
        airdropWallet(0xaAB511A6BDc9c8080d4bc7Af1940245fEaB3D2A6);
        airdropWallet(0xAAE78f8fa7B3C0376552be90ad8eA031AA306125);
        airdropWallet(0xab06740998D996d3c298134b78F49EC92d0Aa524);
        airdropWallet(0xAD503B72FC36A699BF849bB2ed4c3dB1967A73da);
        airdropWallet(0xaeC6116da6050fC10cccB9243F7Bf10Ba69344D9);
        airdropWallet(0xaf69Cc8e59759F13fBf052a95e063579dF500896);
        airdropWallet(0xAF8e912e106bFD24dE57448A18483A4173dBd0AA);
        airdropWallet(0xAfD502dA9661C2BF8C2c7e6F1297ea52141e2915);
        airdropWallet(0xB07A4bcDBcD3E161D6eb07B093208a339C449958);
        airdropWallet(0xB14E0D405FD54426Fa18563efC02b27ee9A63058);
        airdropWallet(0xB42faecb1739907fC282c52A41a5A6026Fe473b9);
        airdropWallet(0xb4364F7c5984d83F96041E41fddfAfe07f71cC88);
        airdropWallet(0xb4A39749551D0b428cE1350c3AA40823b1487643);
    }

    bool hasAirdroped6;
    function airdrop6() public onlyOwner
    {
        require(!hasAirdroped6, "Already airdroped");
        hasAirdroped6 = true;
        airdropWallet(0xb7E6a7e7A5D8c1bC5B274Bd1c3AD9B46f6d3452D);
        airdropWallet(0xB9Cb00FeF9406211958BAc6073558290aed8C1c1);
        airdropWallet(0xBa0ACF8132F086e052d4F6137ffa7ddB9a061c4b);
        airdropWallet(0xBabaF36fdc964a4Cd044B6b116f0DE4896386Fe0);
        airdropWallet(0xBcFb75614Ce982dFF74A263B6FB9adF97d80006A);
        airdropWallet(0xBE08218CeB58516557e112CCa5400743E183F634);
        airdropWallet(0xBe582ef9625790Ef0af4aF6A29997d2b9680C1F6);
        airdropWallet(0xbF913d89a0802E4F9b62cf2Fe1Fa3bcEe81b4629);
        airdropWallet(0xC06c903C5C2330f3ebc6B3F9c7996ea3d838eFAe);
        airdropWallet(0xc1596A772A5127F293Ec19Ed892Dbab516D4c3c5);
        airdropWallet(0xc1Fb6342cc4ceC2e9d6b5934bBD4d250Ed58C6Fa);
        airdropWallet(0xC3EC5D29b2c89e4d574764a5020CE017f72883f3);
        airdropWallet(0xc3FD9C40521394c1DbcF57d6912baBCf394F33C0);
        airdropWallet(0xC5737DB4615CE4f2AA8309717F07a7893C0Dc0b1);
        airdropWallet(0xC5882F70e5E5cfD423f6783dB34a0F9C5d12fDf7);
        airdropWallet(0xC58A1Aa5b2F09ac1bc1b040bb7F5b6464420f042);
        airdropWallet(0xC6D468dAe414E88aAB629a853a0643Ba1089a6B0);
        airdropWallet(0xC7429d38ab2197b2Ab1d22685616b07F96739af0);
        airdropWallet(0xc7794C445b4Ac5A02A7fCa995D24Fe39dED5b5e6);
        airdropWallet(0xc802a11850eBfD8017a0Bc1E801ad020c33DA0A4);
        airdropWallet(0xCd57B34763ceF236505A505aD5e88133C23C3758);
        airdropWallet(0xCDCCB27E06Dc53832B4cc4fe8C47551ceca75b17);
        airdropWallet(0xD0e8b10222dcb4D7549CDdCB3441A15D7d6bB86d);
        airdropWallet(0xD3F269E947Fd40C2Ca1f627327c6C770ce488235);
        airdropWallet(0xD42B85640C30Ed0c3537dAf352BB917d4a836092);
        airdropWallet(0xd577df616cbfdA9C7d322E8cb5938CD9a47b837e);
        airdropWallet(0xd7D954FA8327f56ECcC98251B27F7e9A2045E39f);
        airdropWallet(0xD880B98c2d391447Fe498492042BB9B032c6E44A);
        airdropWallet(0xdBE7DB333Afc08D2B1FCbA4947b1d647916f2f08);
        airdropWallet(0xdC623e506a08aA6a68E550651f774D7C245Fca93);
        airdropWallet(0xde1b617d64A7b7ac7cf2CD50487c472b5632ce3c);
        airdropWallet(0xdEF769bcf57dF5a2400ab5f9DD3AaD5981079689);
        airdropWallet(0xDEFf2755BF2999b3226cab38d7B9c11a5C0b0766);
    }

    bool hasAirdroped7;
    function airdrop7() public onlyOwner
    {
        require(!hasAirdroped7, "Already airdroped");
        hasAirdroped7 = true;
        airdropWallet(0xE196987A49d1b3B0BcA9fdC919229019A4bA0837);
        airdropWallet(0xE3fd37D5D06b05385Bca54a9601bB1b0a0F705C1);
        airdropWallet(0xE55e052e0Fe0EA6893381F32CAAfAc7ADC6A7DF9);
        airdropWallet(0xe6B67036b1a14FF7126717aA4fd0AfC6BEE4D797);
        airdropWallet(0xE831B2c8E348f3ED76deC45456280A1E1536Ad78);
        airdropWallet(0xe8926d5a5ae59383c41CEeEf2E987F42b71daAa5);
        airdropWallet(0xe8Cc0cc3b6F12734a9db32c858Dd2FD75B2aBdD8);
        airdropWallet(0xe8Cc0cc3b6F12734a9db32c858Dd2FD75B2aBdD8);
        airdropWallet(0xe9714eF41C529A42881245a0C86156A8Fa70A89e);
        airdropWallet(0xEA75dCD8cBf7383226882B2Edd133422969D2d02);
        airdropWallet(0xEb52df098228f09f71a1279C3195428223624E99);
        airdropWallet(0xEF26F07b4De8609aB18DAe0015C0918397205658);
        airdropWallet(0xf13ED8c0b4F92E169CEC411Bf6cC65D18BCad8f1);
        airdropWallet(0xf339cEe9b698433BB8b3dF5e3862dAC4C72830Be);
        airdropWallet(0xf3d2BB908629d180d03b4eea72646c06749b9B32);
        airdropWallet(0xF451fEdE392804265Fb290541e41B7d4D7325a34);
        airdropWallet(0xf674e8D99A946E982bABF4d3bCB6244bb51fb30F);
        airdropWallet(0xF67581AFac314D2B27d0cFE15F19aA9377Cd4A53);
        airdropWallet(0xf69C0fAb505C0Fe572161D27D2AFe09A9Ab6199D);
        airdropWallet(0xF7882327fB43971950260f37723Cd71d33faACDe);
        airdropWallet(0xF94233EB72E8769a5Ea4327108b5dd14CaCFbbb4);
        airdropWallet(0xF94D2b145E9371c59845Feb98EC68112506f6683);
        airdropWallet(0xFD1750CB16A96755EE979DDaf00Ebb2FA1613F53);
        airdropWallet(0xFD29d71cA52B456B3207144C5Bd88184a735cc8C);
        airdropWallet(0xfdd927EA8250cac2Fbcb7DF08D518ca2B0BDf486);
        airdropWallet(0xFF7Cf0ACF90Fe5dD76a46e5a767d7374C63fB147);
    }
}