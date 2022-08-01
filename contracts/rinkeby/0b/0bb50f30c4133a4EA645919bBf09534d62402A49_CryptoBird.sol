// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";

contract CryptoBird is ERC721Enumerable {

    uint MAX_SUPPLY = 11;

    constructor() ERC721Enumerable("Crypto Bird", "BIRD", "ipfs://QmNnmMZX5mxgA15h61A75nJyLTV63ZMyhsg738UVeqx7aX/"){
    }

    function maxSupply() public view returns(uint) {
        return MAX_SUPPLY;
    }

    function mint() public {
        require(totalSupply() < MAX_SUPPLY, 'MAX_SUPPLY reached');
        _mint(msg.sender, 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Utils {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IERC721Metadata {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract ERC721Enumerable is ERC721 {

    uint[] private _allTokens;
    mapping(uint => uint) private _tokenIdIndex;
    mapping(address => uint[]) private _ownedTokens;
    mapping(uint => uint) private _ownedTokensIndex;

    constructor(string memory _name, string memory _symbol, string memory _baseURI) ERC721(_name, _symbol, _baseURI){
    }

    // @return uint Total supply
    function totalSupply() public view virtual override returns (uint) {
        return _allTokens.length;
    }

    function tokenByIndex(uint index) public view returns (uint) {
        require(index < _allTokens.length, 'Index out of bounds');
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint index) public view returns (uint) {
        require(index < _ownedTokens[owner].length, 'Index out of bounds');
        return _ownedTokens[owner][index];
    }

    // @param to address
    // @param uint quantity to mint
    function _mint(address to, uint quantity) internal override(ERC721) {
        super._mint(to, quantity);
        uint tokenId = super.currentTokenId();
        _updateEnumerations(tokenId);
        _updateOwnedToken(to, tokenId);
    }

    // @param uint tokenId
    function _updateEnumerations(uint tokenId) private {
        _allTokens.push(tokenId);
        _tokenIdIndex[tokenId] = _allTokens.length - 1;
    }

    // @oaram to address
    // @param uint tokenId
    function _updateOwnedToken(address to, uint tokenId) private {
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length - 1;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Utils.sol";
import "./ERC165.sol";
import "./IERC721.sol";
import "./Context.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";

contract ERC721 is Context, IERC721, IERC721Metadata, ERC165 {
    using Utils for address;
    using Utils for uint256;

    string private _name;
    string private _symbol;
    string private _baseTokenURI;
    uint private _totalSupply = 0;
    uint private _currentIndex = 0;
    mapping(uint => string) private _tokenURIs;
    mapping(uint => address) private _tokenOwner;
    mapping(address => uint) private _ownedTokenCount;
    mapping(uint => address) private _tokenIdApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) {
        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseURI_;
    }

    function balanceOf(address _owner) public view virtual override returns (uint256){
        require(_owner != address(0));
        return _ownedTokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public virtual override view returns (address){
        address owner = _tokenOwner[_tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public virtual override view returns (string memory) {
        return _name;
    }

    function symbol() public virtual override view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721: Token doesn\'t exists');
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function approve(address to, uint256 _tokenId) public virtual override  {
        address owner = ERC721.ownerOf(_tokenId);
        require(owner != to, 'ERC721: cannot approve for self');
        require(owner == _msgSender() || isApprovedForAll(owner, _msgSender()), 'ERC721: approve caller is not owner nor approved for all');
        _approve(to, _tokenId);
    }

    function getApproved(uint256 _tokenId) public virtual override view returns (address) {
        require(_exists(_tokenId));
        return _tokenIdApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public virtual override  {
        require(_operator != _msgSender());
        _operatorApprovals[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public virtual override view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
        _transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual override  {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function _isApprovedOrOwner(address _spender, uint _tokenId) internal view virtual returns(bool){
        address _owner = ERC721.ownerOf(_tokenId);
        return _owner == _spender ||
        getApproved(_tokenId) == _spender ||
        isApprovedForAll(_owner, _spender);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenIdApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function _exists(uint tokenId) internal view virtual returns (bool) {
        return _tokenOwner[tokenId] != address(0);
    }

    function currentTokenId() internal view virtual returns (uint) {
        return _currentIndex;
    }

    function totalSupply() external view virtual returns (uint) {
        return _totalSupply;
    }

    function _mint(address to, uint quantity) internal virtual {
        require(quantity == 1, 'ERC721: Can only mint 1 at a time');
        uint tokenId = _totalSupply == 0 ? 0 : _currentIndex + 1;
        require(to != address(0), 'ERC721: Token can only be minted to real address');
        require(!_exists(tokenId), 'ERC721: Token already minted');
        _tokenOwner[tokenId] = to;
        _ownedTokenCount[to]++;
        _currentIndex = tokenId;
        _totalSupply++;
        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);
        require(
            _checkOnERC721Received(address(0), to, _currentIndex, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _transferFrom(address from, address to, uint tokenId) internal virtual {
        require(to != address(0), 'ERC721: null address not allowed');
        require(from == ERC721.ownerOf(tokenId), 'ERC721: owner mismatch');

        _approve(address(0), tokenId); // clear approvals

        _tokenOwner[tokenId] = to;
        _ownedTokenCount[to]++;
        _ownedTokenCount[from]--;

        emit Transfer(from, to, tokenId);
    }

    function _safeTransfer(address from, address to, uint tokenId, bytes memory _data) internal virtual {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}