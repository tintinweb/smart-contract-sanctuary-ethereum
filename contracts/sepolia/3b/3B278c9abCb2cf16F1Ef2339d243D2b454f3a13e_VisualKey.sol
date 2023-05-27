/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.0;

contract VisualKey {
    //#region Extensions
    using Address for address;
    using Strings for uint256;
    //#endregion

    //#region State
    address private _contractOwner;
    address private _mintingSigner;
    string private _tokenMetadataUri;

    mapping(uint256 => address) private _tokenOwnerMap;
    mapping(uint256 => address) private _tokenDelegateMap;
    mapping(address => uint256) private _ownerTokenCountMap;
    mapping(address => mapping(address => bool)) private _ownerOperatorApprovalMap;

    uint256[] private _allTokens;
    mapping(address => mapping(uint256 => uint256)) private _ownerIndexTokenMap;

    mapping(uint256 => uint256) private _tokenIndexMap;
    mapping(uint256 => uint256) private _ownedTokenIndexMap;

    mapping(uint256 => TokenLock) private _tokenLockMap;
    //#endregion

    //#region Constructor
    constructor(
        address contractOwner_,
        address mintingSigner_,
        string memory tokenMetadataUri
    ) {
        if (contractOwner_ == address(0)) {
            revert OwnerInvalid();
        }

        if (mintingSigner_ == address(0)) {
            revert SignerInvalid();
        }

        _contractOwner = contractOwner_;
        _mintingSigner = mintingSigner_;
        _tokenMetadataUri = tokenMetadataUri;
    }
    //#endregion

    //#region Public API
    //#region Token Identity
    function name() external pure returns (string memory) {
        return "VisualKey";
    }

    function symbol() external pure returns (string memory) {
        return "VKEY";
    }
    //#endregion

    //#region Token URI Management
    function tokenURI(uint256 token) external view returns (string memory) {
        _requireMinted(token);
        return string(abi.encodePacked(_tokenMetadataUri, token.toHexString(32)));
    }

    function changeTokenMetadataURI(string memory tokenMetadataUri) external onlyOwner {
        _tokenMetadataUri = tokenMetadataUri;
    }
    //#endregion

    //#region Token Information
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) {
            revert OwnerInvalid();
        }

        return _ownerTokenCountMap[owner];
    }

    function ownerOf(uint256 token) public view returns (address) {
        _requireTokenValid(token);

        address owner = _tokenOwnerMap[token];

        if (owner == address(0)) {
            revert TokenDoesNotExist(token);
        }

        return owner;
    }

    function tokenByIndex(uint256 index) external view returns (uint256) {
        uint256 allTokensCount = totalSupply();

        if (index >= allTokensCount) {
            revert IndexOutOfBounds(index, allTokensCount);
        }

        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
        uint256 ownerTokensCount = balanceOf(owner);

        if (index >= ownerTokensCount) {
            revert IndexOutOfBounds(index, ownerTokensCount);
        }

        return _ownerIndexTokenMap[owner][index];
    }
    //#endregion

    //#region Delegate Approval
    function approve(address delegate, uint256 token) external {
        address owner = ownerOf(token);

        if (owner == delegate) {
            revert DelegateInvalid();
        }

        if (msg.sender != owner && _ownerOperatorApprovalMap[owner][msg.sender] == false) {
            revert Unauthorized();
        }

        _tokenDelegateMap[token] = delegate;

        emit Approval(owner, delegate, token);
    }

    function getApproved(uint256 token) external view returns (address) {
        _requireMinted(token);
        return _tokenDelegateMap[token];
    }
    //#endregion

    //#region Operator Approval
    function setApprovalForAll(address operator, bool approved) external {
        if (msg.sender == operator) {
            revert OperatorInvalid();
        }

        _ownerOperatorApprovalMap[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _ownerOperatorApprovalMap[owner][operator];
    }
    //#endregion

    //#region Token Transfer
    function transferFrom(address from, address to, uint256 token) public {
        address owner = ownerOf(token);

        if (
            from != owner ||
            msg.sender != owner &&
            _ownerOperatorApprovalMap[owner][msg.sender] == false &&
            msg.sender != _tokenDelegateMap[token]
        ) {
            revert Unauthorized();
        }

        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        _beforeTokenTransfer(from, to, token);

        unchecked {
            _ownerTokenCountMap[from] -= 1;
            _ownerTokenCountMap[to] += 1;
        }

        _tokenOwnerMap[token] = to;
        delete _tokenDelegateMap[token];

        emit Transfer(from, to, token);
    }

    function safeTransferFrom(address from, address to, uint256 token) external {
        safeTransferFrom(from, to, token, "");
    }

    function safeTransferFrom(address from, address to, uint256 token, bytes memory data) public {
        transferFrom(from, to, token);

        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, token, data) returns (bytes4 returnCode) {
                if (returnCode != IERC721Receiver.onERC721Received.selector) {
                    revert TransferRejected();
                }
            } catch {
                revert TransferRejected();
            }
        }
    }
    //#endregion

    //#region Contract Owner
    function contractOwner() external view returns (address) {
        return _contractOwner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) {
            revert OwnerInvalid();
        }

        _contractOwner = newOwner;
    }
    //#endregion

    //#region Minting Signer
    function mintingSigner() external view returns (address) {
        return _mintingSigner;
    }

    function changeMintingSigner(address newMintingSigner) external onlyOwner {
        if (newMintingSigner == address(0)) {
            revert SignerInvalid();
        }

        _mintingSigner = newMintingSigner;
    }
    //#endregion

    //#region Token Minting
    function mint(
        uint256 token,
        uint256 price,
        address receiver,
        uint256 deadline,
        bytes memory signature
    ) external payable {
        if (block.timestamp > deadline) {
            revert SignatureExpired(block.timestamp, deadline);
        }

        if (msg.value < price) {
            revert InsufficientFunds(msg.value, price);
        }

        if (receiver == address(0)) {
            revert ReceiverInvalid();
        }

        _requireTokenValid(token);
        _requireNotMinted(token);

        bytes32 hash = keccak256(abi.encodePacked(block.chainid, address(this), receiver, token, price, deadline));

        if (!_mintingSigner.hasSigned(hash, signature)) {
            revert SignatureInvalid(signature);
        }

        _mint(receiver, token);
    }
    //#endregion

    //#region Token Locking
    function lock(uint256 token) external {
        address owner = ownerOf(token);

        if (msg.sender != owner) {
            revert Unauthorized();
        }

        _beforeTokenTransfer(owner, address(0), token);

        unchecked {
            _ownerTokenCountMap[owner] -= 1;
        }

        _tokenLockMap[token] = TokenLock(owner, block.timestamp);

        delete _tokenOwnerMap[token];
        delete _tokenDelegateMap[token];

        emit Transfer(owner, address(0), token);
    }

    function getLock(uint256 token) external view returns (TokenLock memory) {
        return _tokenLockMap[token];
    }
    //#endregion

    //#region Contract Balance Management
    function withdraw(address payable receiver, uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        amount = amount > balance ? balance : amount;
        receiver.transfer(amount);
        emit TokenWithdrawal(receiver, amount);
    }

    function withdrawErc20Token(address receiver, IERC20 tokenContract, uint256 amount) external onlyOwner {
        uint256 balance = tokenContract.balanceOf(address(this));
        amount = amount > balance ? balance : amount;
        tokenContract.transfer(receiver, amount);
        emit Erc20TokenWithdrawal(receiver, address(tokenContract), amount);
    }

    function withdrawErc721Token(address receiver, IERC721 tokenContract, uint256 token) external onlyOwner {
        tokenContract.transferFrom(address(this), receiver, token);
        emit Erc721TokenWithdrawal(receiver, address(tokenContract), token);
    }
    //#endregion

    //#region Other
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        interfaceId == type(IERC721Enumerable).interfaceId ||
        interfaceId == type(IERC721Receiver).interfaceId ||
        interfaceId == type(IERC165).interfaceId;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {
        if (msg.value > 0) {
            emit Donation(msg.sender, msg.value);
        }
    }
    //#endregion
    //#endregion

    //#region Private Functions
    function _requireMinted(uint256 token) private view {
        if (_tokenOwnerMap[token] == address(0)) {
            revert TokenDoesNotExist(token);
        }
    }

    function _requireNotMinted(uint256 token) private view {
        if (_tokenOwnerMap[token] != address(0)) {
            revert TokenExists(token);
        }
    }

    function _requireTokenValid(uint256 token) private pure {
        if (token == 0 || token > 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140) {
            revert TokenInvalid(token);
        }
    }

    function _mint(address owner, uint256 token) private {
        _beforeTokenTransfer(address(0), owner, token);

        unchecked {
            _ownerTokenCountMap[owner] += 1;
        }

        _tokenOwnerMap[token] = owner;
        delete _tokenLockMap[token];

        emit Transfer(address(0), owner, token);
    }

    function _beforeTokenTransfer(address from, address to, uint256 token) private {
        if (from == address(0)) {
            _tokenIndexMap[token] = _allTokens.length;
            _allTokens.push(token);
        } else if (from != to) {
            uint256 lastTokenIndex = _ownerTokenCountMap[from] - 1;
            uint256 tokenIndex = _ownedTokenIndexMap[token];

            if (tokenIndex != lastTokenIndex) {
                uint256 lastToken = _ownerIndexTokenMap[from][lastTokenIndex];
                _ownerIndexTokenMap[from][tokenIndex] = lastToken;
                _ownedTokenIndexMap[lastToken] = tokenIndex;
            }

            delete _ownedTokenIndexMap[token];
            delete _ownerIndexTokenMap[from][lastTokenIndex];
        }

        if (to == address(0)) {
            uint256 tokenIndex = _tokenIndexMap[token];
            uint256 lastTokenIndex = _allTokens.length - 1;
            uint256 lastToken = _allTokens[lastTokenIndex];

            _allTokens[tokenIndex] = lastToken;
            _tokenIndexMap[lastToken] = tokenIndex;

            _allTokens.pop();
            delete _tokenIndexMap[token];
        } else if (to != from) {
            uint256 length = _ownerTokenCountMap[to];
            _ownerIndexTokenMap[to][length] = token;
            _ownedTokenIndexMap[token] = length;
        }
    }
    //#endregion

    //#region Structs
    struct TokenLock {
        address lockedBy;
        uint256 lockedWhen;
    }
    //#endregion

    //#region Modifiers
    modifier onlyOwner() {
        if (msg.sender != _contractOwner) {
            revert Unauthorized();
        }
        _;
    }
    //#endregion

    //#region Events
    event Transfer(address indexed from, address indexed to, uint256 indexed token);
    event Approval(address indexed owner, address indexed delegate, uint256 indexed token);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Donation(address indexed supporter, uint256 amount);
    event TokenWithdrawal(address indexed receiver, uint256 amount);
    event Erc20TokenWithdrawal(address indexed receiver, address indexed token, uint256 amount);
    event Erc721TokenWithdrawal(address indexed receiver, address indexed token, uint256 tokenId);
    //#endregion

    //#region Errors
    error Unauthorized();
    error OwnerInvalid();
    error SignerInvalid();
    error DelegateInvalid();
    error OperatorInvalid();
    error ReceiverInvalid();
    error TransferRejected();
    error TokenInvalid(uint256 token);
    error TokenExists(uint256 token);
    error TokenDoesNotExist(uint256 token);
    error InsufficientFunds(uint256 actual, uint256 expected);
    error IndexOutOfBounds(uint256 index, uint256 length);
    error SignatureInvalid(bytes signature);
    error SignatureExpired(uint256 blockTimestamp, uint256 expirationTimestamp);
    //#endregion
}

//#region Interfaces
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 token) external view returns (address);
    function transferFrom(address from, address to, uint256 token) external;
    function safeTransferFrom(address from, address to, uint256 token) external;
    function safeTransferFrom(address from, address to, uint256 token, bytes calldata data) external;
    function approve(address to, uint256 token) external;
    function getApproved(uint256 token) external view returns (address);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 token) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 token, bytes calldata data) external returns (bytes4);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}
//#endregion

//#region Libraries
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function hasSigned(address signer, bytes32 message, bytes memory signature) internal pure returns (bool) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return signer == ecrecover(message, v, r, s);
    }
}

library Strings {
    //#region Constants
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    //#endregion

    //#region Errors
    error HexLengthInsufficient();
    //#endregion

    //#region Functions
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);

        buffer[0] = "0";
        buffer[1] = "x";

        for (uint256 i = 2 * length + 1; i > 1; i--) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }

        if (value != 0) {
            revert HexLengthInsufficient();
        }

        return string(buffer);
    }
    //#endregion
}
//#endregion