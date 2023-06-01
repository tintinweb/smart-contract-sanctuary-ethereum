/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title DAAAMO
 * @author 0xSumo @PBADAO
 */

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) { return ERC721TokenReceiver.onERC721Received.selector; }
}

abstract contract ERC721 {
    
    event Transfer(address indexed from_, address indexed to_, uint256 indexed tokenId_);
    event Approval(address indexed owner_, address indexed spender_, uint256 indexed id_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, bool approved_);

    string public name; 
    string public symbol;

    uint256 public nextTokenId;
    uint256 public totalBurned;
    uint256 public constant maxBatchSize = 100;
    
    function startTokenId() public pure virtual returns (uint256) {
        return 0;
    }

    function totalSupply() public view virtual returns (uint256) {
        return nextTokenId - totalBurned - startTokenId();
    }

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        nextTokenId = startTokenId();
    }

    struct TokenData {
        address owner;
        uint40 lastTransfer;
        bool burned;
        bool nextInitialized;
    }
    struct BalanceData {
        uint32 balance;
        uint32 mintedAmount;
    }

    mapping(uint256 => TokenData) public _tokenData;
    mapping(address => BalanceData) public _balanceData;

    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function _getTokenDataOf(uint256 tokenId_) public view virtual returns (TokenData memory) {
        uint256 _lookupId = tokenId_;
        require(_lookupId >= startTokenId(), "_getTokenDataOf _lookupId < startTokenId");
        TokenData memory _TokenData = _tokenData[_lookupId];
        if (_TokenData.owner != address(0) && !_TokenData.burned) return _TokenData;
        require(!_TokenData.burned, "_getTokenDataOf burned token!");
        require(_lookupId < nextTokenId, "_getTokenDataOf _lookupId > _nextTokenId");
        unchecked { while(_tokenData[--_lookupId].owner == address(0)) {} }
        return _tokenData[_lookupId];
    }

    function balanceOf(address owner_) public virtual view returns (uint256) {
        require(owner_ != address(0), "balanceOf to 0x0");
        return _balanceData[owner_].balance;
    }

    function ownerOf(uint256 tokenId_) public view returns (address) {
        return _getTokenDataOf(tokenId_).owner;
    }

    function _mintInternal(address to_, uint256 amount_) internal virtual { unchecked {
        require(to_ != address(0), "_mint to 0x0");
        uint256 _startId = nextTokenId;
        uint256 _endId = _startId + amount_;
        _tokenData[_startId].owner = to_;
        _tokenData[_startId].lastTransfer = uint40(block.timestamp);
        _balanceData[to_].balance += uint32(amount_);
        _balanceData[to_].mintedAmount += uint32(amount_);
        do { emit Transfer(address(0), to_, _startId); } while (++_startId < _endId);
        nextTokenId = _endId;
    }}

    function _mint(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(to_, maxBatchSize);
        }
        _mintInternal(to_, _amountToMint);
    }

    function _burn(uint256 tokenId_, bool checkApproved_) internal virtual { unchecked {
        TokenData memory _TokenData = _getTokenDataOf(tokenId_);
        address _owner = _TokenData.owner;
        if (checkApproved_) require(_isApprovedOrOwner(_owner, msg.sender, tokenId_), "_burn not approved");
        delete getApproved[tokenId_];
        _tokenData[tokenId_].owner = _owner;
        _tokenData[tokenId_].lastTransfer = uint40(block.timestamp);
        _tokenData[tokenId_].burned = true;
        _tokenData[tokenId_].nextInitialized = true;

        if (!_TokenData.nextInitialized) {
            uint256 _tokenIdIncremented = tokenId_ + 1;
            if (_tokenData[_tokenIdIncremented].owner == address(0)) {
                if (tokenId_ < nextTokenId - 1) {
                    _tokenData[_tokenIdIncremented] = _TokenData;
                }
            }
        }
        
        _balanceData[_owner].balance--;
        emit Transfer(_owner, address(0), tokenId_);
        totalBurned++;
    }}

    function _transfer(address from_, address to_, uint256 tokenId_, bool checkApproved_) internal virtual { unchecked {
        require(to_ != address(0), "_transfer to 0x0");
        TokenData memory _TokenData = _getTokenDataOf(tokenId_);
        address _owner = _TokenData.owner;
        require(from_ == _owner, "_transfer not from owner");
        if (checkApproved_) require(_isApprovedOrOwner(_owner, msg.sender, tokenId_), "_transfer not approved");
        delete getApproved[tokenId_];
        _tokenData[tokenId_].owner = to_;
        _tokenData[tokenId_].lastTransfer = uint40(block.timestamp);
        _tokenData[tokenId_].nextInitialized = true;
        
        if (!_TokenData.nextInitialized) {
            uint256 _tokenIdIncremented = tokenId_ + 1;
            if (_tokenData[_tokenIdIncremented].owner == address(0)) {
                if (tokenId_ < nextTokenId - 1) {
                    _tokenData[_tokenIdIncremented] = _TokenData;
                }
            }
        }

        _balanceData[from_].balance--;
        _balanceData[to_].balance++;
        emit Transfer(from_, to_, tokenId_);
    }}

    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        _transfer(from_, to_, tokenId_, true);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        require(to_.code.length == 0 || ERC721TokenReceiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) ==
        ERC721TokenReceiver.onERC721Received.selector, "safeTransferFrom to unsafe address");
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function approve(address spender_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender], "approve not authorized!");
        getApproved[tokenId_] = spender_;
        emit Approval(_owner, spender_, tokenId_);
    }

    function setApprovalForAll(address operator_, bool approved_) public virtual {
        isApprovedForAll[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    function _isApprovedOrOwner(address owner_, address spender_, uint256 tokenId_) internal virtual view returns (bool) {
        return (owner_ == spender_ || getApproved[tokenId_] == spender_ || isApprovedForAll[owner_][spender_]);
    }

    function supportsInterface(bytes4 id_) public virtual view returns (bool) {
        return  id_ == 0x01ffc9a7 || id_ == 0x80ac58cd || id_ == 0x5b5e139f;
    }

    function tokenURI(uint256 tokenId_) public virtual view returns (string memory);
}

abstract contract ERC721URIPerToken {
    mapping(uint256 => string) public tokenToURI;
    function _setTokenToURI(uint256 tokenId_, string memory uri_) internal virtual { tokenToURI[tokenId_] = uri_; }
}

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);
    IOperatorFilterRegistry constant operatorFilterRegistry = IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }
    modifier onlyAllowedOperator(address from) virtual {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (from == msg.sender) { _; return ; }
            if (!(operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender) && operatorFilterRegistry.isOperatorAllowed(address(this), from))) {
                revert OperatorNotAllowed(msg.sender);
        }}_;
    }
}

abstract contract OwnControll {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminSet(bytes32 indexed controllerType, bytes32 indexed controllerSlot, address indexed controller, bool status);
    address public owner;
    mapping(bytes32 => mapping(address => bool)) internal admin;
    constructor() { owner = msg.sender; }
    modifier onlyOwner() { require(owner == msg.sender, "only owner");_; }
    modifier onlyAdmin(string memory type_) { require(isAdmin(type_, msg.sender), "only admin");_; }
    function transferOwnership(address newOwner) external onlyOwner { emit OwnershipTransferred(owner, newOwner); owner = newOwner; }
    function setAdmin(string calldata type_, address controller, bool status) external onlyOwner { bytes32 typeHash = keccak256(abi.encodePacked(type_)); admin[typeHash][controller] = status; emit AdminSet(typeHash, typeHash, controller, status); }
    function isAdmin(string memory type_, address controller) public view returns (bool) { bytes32 typeHash = keccak256(abi.encodePacked(type_)); return admin[typeHash][controller]; }
}

interface IMetadata {
    function tokenURI(uint256 tokenId_) external view returns (string memory);
}

contract DAAAMO is ERC721, OwnControll, ERC721URIPerToken, OperatorFilterer {

    address public metadata;
    bool public useMetadata;
    mapping(uint256 => uint256) public DNA;

    constructor() ERC721("DAAAMO", "DAAAMO") OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), true) {}

    function mint(address address_, uint256 amount_, uint256 dna_) external onlyAdmin("MINTER") {
        _mint(address_, amount_, dna_);
    }

    function _mintInternal(address to_, uint256 amount_, uint256 dna_) internal virtual { unchecked {
        require(to_ != address(0), "_mint to 0x0");
        uint256 _startId = nextTokenId;
        uint256 _endId = _startId + amount_;
        _tokenData[_startId].owner = to_;
        _tokenData[_startId].lastTransfer = uint40(block.timestamp);
        _balanceData[to_].balance += uint32(amount_);
        _balanceData[to_].mintedAmount += uint32(amount_);
        do {
            DNA[_startId] = dna_;
            emit Transfer(address(0), to_, _startId);
        } while (++_startId < _endId);
        nextTokenId = _endId;
    }}

    function _mint(address to_, uint256 amount_, uint256 dna_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(to_, maxBatchSize, dna_);
        }
        _mintInternal(to_, _amountToMint, dna_);
    }

    function burn(uint256 tokenId_, bool checkApproved_) external onlyAdmin("BURNER") {
        _burn(tokenId_, checkApproved_);
    }

    /// 1 Yellow, 2 LightBlue, 3 Green, 4 Purple, 5 Red, 6 DarkBlue, 7 White, 8 Black
    function setTokenToURI(uint256 type_, string calldata uri_) external onlyAdmin("ADMIN") {
        _setTokenToURI(type_, uri_);
    }

    function setMetadata(address address_) external onlyAdmin("ADMIN") {
        metadata = address_;
    }

    function setUseMetadata(bool bool_) external onlyAdmin("ADMIN") {
        useMetadata = bool_;
    }

    function setDNA(uint256 tokenId_, uint256 dna_) external onlyAdmin("DNA") {
        DNA[tokenId_] = dna_;
    }

    function startTokenId() public pure virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId_) public view override returns (string memory) {
        if (!useMetadata) {
            return tokenToURI[DNA[tokenId_]];
        } else {
            return IMetadata(metadata).tokenURI(tokenId_);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}