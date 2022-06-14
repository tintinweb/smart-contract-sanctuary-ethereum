/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: None
pragma solidity ^0.8.14;

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract BubblehouseNFT3 is IERC165, IERC721, IERC721Metadata {
    // Contract metadata
    string private _baseURI;
    address private _owner;
    string private _name;

    // Contract moderation
    bool public isOpenSeaEnabled = true;
    address public openSeaProxyRegistryAddress;
    mapping(address => bool) private _isMinter;
    
    // Token moderation
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Modifiers
    modifier onlyOwner() {
        require(_owner == msg.sender, "MUST_BE_OWNER");
        _;
    }

    modifier onlyMinter() {
        require(_isMinter[msg.sender], "MUST_BE_MINTER");
        _;
    }

    /* Functions */
    constructor(string memory name_, address openSeaProxyRegistryAddress_, string memory baseURI_, address sharedWallet_) {
        _name = name_;
        _owner = msg.sender;
        openSeaProxyRegistryAddress = openSeaProxyRegistryAddress_;
        isOpenSeaEnabled = (openSeaProxyRegistryAddress_ != address(0));
        _baseURI = baseURI_;
        if (sharedWallet_ != address(0)) {
            _isMinter[sharedWallet_] = true;
        }
    }

    /* ERC-721 Standard */
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return "BUBBLENFT3";
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "INVALID_ZERO_ADDRESS");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "INVALID_TOKEN");
        return owner;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "Forbidden");
        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "INVALID_TOKEN");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator] || isOpenSeaOperator(owner, operator);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _clearApproval(uint256 tokenId) internal {
        _approve(address(0), tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _owners[tokenId];
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }    function mint(address to, uint256 tokenId) public onlyMinter {
        _mint(to, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "INVALID_ZERO_ADDRESS");

        address owner = _owners[tokenId];
        if (owner != address(0)) {
            if (owner == to) {
                revert("ALREADY_MINTED");
            }
            revert("TOKEN_EXISTS");
        }

        _beforeTokenTransfer(address(0), to, tokenId);

        unchecked { _balances[to] += 1; }
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "FORBIDDEN");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory /*data*/) public override {
        transferFrom(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_owners[tokenId] == from, "FORBIDDEN");
        require(to != address(0), "INVALID_ZERO_ADDRESS");

        _beforeTokenTransfer(from, to, tokenId);

        _clearApproval(tokenId);

        unchecked {
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function burn(uint256 tokenId) public {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
            revert("ALREADY_BURNED");
        }
        require(_isApprovedOrOwner(_msgSender(), tokenId), "FORBIDDEN");
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        _clearApproval(tokenId);

        unchecked {
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "INVALID_TOKEN");
        return string(abi.encodePacked(_baseURI, intToString(tokenId)));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal {}

    /* ERC-165 Standard */
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /* Context */
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    /* Strings */
    function intToString(uint256 value) internal pure returns (string memory) {
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

    /* Custom */
    function isOpenSeaOperator(address owner, address operator) internal view returns (bool) {
        if (!isOpenSeaEnabled) {
            return false;
        }
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(openSeaProxyRegistryAddress);
        return (address(proxyRegistry.proxies(owner)) == operator);
    }

    function setOpenSeaEnabled(bool enabled) external onlyOwner {
        isOpenSeaEnabled = enabled;
    }

    function setOpenSeaProxyRegistryAddress(address addr) external onlyOwner {
        openSeaProxyRegistryAddress = addr;
    }


    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseURI = newBaseURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseURI;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "INVALID_ZERO_ADDRESS");
        _owner = newOwner;
    }

    function setMinter(address addr, bool authorized) external onlyOwner {
        require(addr != address(0), "INVALID_ZERO_ADDRESS");
        _isMinter[addr] = authorized;
    }
}