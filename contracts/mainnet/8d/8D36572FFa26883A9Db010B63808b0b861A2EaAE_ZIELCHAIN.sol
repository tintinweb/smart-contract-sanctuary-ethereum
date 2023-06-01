/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT

/**
 * @title ERC1155 Token
 * @author 0xSumo @PBADAO
 */

pragma solidity ^0.8.0;

interface ERC1155TokenReceiver {
    function onERC1155Received(address operator_, address from_, uint256 id_, uint256 amount_, bytes calldata data_) external returns (bytes4);
    function onERC1155BatchReceived(address operator_, address from_, uint256[] calldata ids_, uint256[] calldata amounts_, bytes calldata data_) external returns (bytes4);
}

abstract contract ERC1155Enumerable {
    
    string public name;
    string public symbol;

    constructor(string memory name_, string memory symbol_) {
        name = name_; 
        symbol = symbol_; 
    }

    event TransferSingle(address indexed operator_, address indexed from_,  address indexed to_, uint256 id_, uint256 amount_);
    event TransferBatch(address indexed operator_, address indexed from_, address indexed to_, uint256[] ids_, uint256[] amounts_);
    event ApprovalForAll(address indexed owner_, address indexed operator_, bool approved_);
    event URI(string value_, uint256 indexed id_);

    mapping(address => mapping(uint256 => uint256)) public balanceOf;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    mapping(uint256 => address[]) public tokenToOwners;
    mapping(uint256 => mapping(address => uint256)) public tokenToOwnersToIndex;

    struct TokenBalances {
        address owner;
        uint256 balance;
    }

    function _addEnumerableData(address address_, uint256 id_) internal {
        if (balanceOf[address_][id_] == 0) {
            uint256 _nextIndex = tokenToOwners[id_].length;
            tokenToOwners[id_].push(address_);
            tokenToOwnersToIndex[id_][address_] = _nextIndex;
        }
    }

    function _removeEnumerableData(address address_, uint256 id_) internal {
        if (balanceOf[address_][id_] == 0) {
            uint256 _userIndex = tokenToOwnersToIndex[id_][address_];
            uint256 _lastIndex = tokenToOwners[id_].length - 1;
            if (_userIndex != _lastIndex) {
                address _userAtLastIndex = tokenToOwners[id_][_lastIndex];
                tokenToOwners[id_][_userIndex] = _userAtLastIndex;
                tokenToOwnersToIndex[id_][_userAtLastIndex] = _userIndex;
            }

            tokenToOwners[id_].pop();
            delete tokenToOwnersToIndex[id_][address_];
        }
    }

    function getOwnersOfTokenId(uint256 id_) public view returns (address[] memory) {
        return tokenToOwners[id_];
    }

    function getOwnersOfTokenIdAndBalance(uint256 id_) public view returns (TokenBalances[] memory) {
        address[] memory _owners = getOwnersOfTokenId(id_);
        uint256 _ownersLength = _owners.length;
        TokenBalances[] memory _TokenBalancesAll = new TokenBalances[] (_ownersLength);

        for (uint256 i = 0; i < _ownersLength; i++) {
            address _currentOwner = _owners[i];
            _TokenBalancesAll[i] = TokenBalances(
                _currentOwner,
                balanceOf[_currentOwner][id_]
            );
        }
        return _TokenBalancesAll;
    }

    function getTotalSupplyOfIds(uint256[] calldata ids_) public view returns (uint256) {
        uint256 _tokens;
        for (uint256 i = 0; i < ids_.length; i++) {
            _tokens += getOwnersOfTokenId(ids_[i]).length;
        }
        return _tokens;
    }

    function uri(uint256 id) public view virtual returns (string memory);

    function _isSameLength(uint256 a, uint256 b) internal pure returns (bool) {
        return a == b;
    }

    function _isApprovedOrOwner(address from_) internal view returns (bool) {
        return msg.sender == from_ || isApprovedForAll[from_][msg.sender];
    }

    function _ERC1155Supported(address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) :
            ERC1155TokenReceiver(to_).onERC1155Received(
                msg.sender, from_, id_, amount_, data_) ==
            ERC1155TokenReceiver.onERC1155Received.selector,
                "_ERC1155Supported(): Unsupported Recipient!"
        );
    }

    function _ERC1155BatchSupported(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) internal {
        require(to_.code.length == 0 ? to_ != address(0) :
            ERC1155TokenReceiver(to_).onERC1155BatchReceived(
                msg.sender, from_, ids_, amounts_, data_) ==
            ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                "_ERC1155BatchSupported(): Unsupported Recipient!"
        );
    }

    function setApprovalForAll(address operator_, bool approved_) public virtual {
        isApprovedForAll[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    function _transfer(address from_, address to_, uint256 id_, uint256 amount_) internal {
        _addEnumerableData(to_, id_);
        balanceOf[to_][id_] += amount_;
        balanceOf[from_][id_] -= amount_;
        _removeEnumerableData(from_, id_);
    }

    function safeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_) public virtual {
        require(_isApprovedOrOwner(from_));
        _transfer(from_, to_, id_, amount_);
        emit TransferSingle(msg.sender, from_, to_, id_, amount_);
        _ERC1155Supported(from_, to_, id_, amount_, data_);
    }

    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) public virtual {
        require(_isSameLength(ids_.length, amounts_.length));
        require(_isApprovedOrOwner(from_));

        for (uint256 i = 0; i < ids_.length; i++) {
            _transfer(from_, to_, ids_[i], amounts_[i]);
        }

        emit TransferBatch(msg.sender, from_, to_, ids_, amounts_);

        _ERC1155BatchSupported(from_, to_, ids_, amounts_, data_);
    }

    function _mintInternal(address to_, uint256 id_, uint256 amount_) internal {
        _addEnumerableData(to_, id_);
        balanceOf[to_][id_] += amount_;
    }

    function _mint(address to_, uint256 id_, uint256 amount_, bytes memory data_) internal {
        _mintInternal(to_, id_, amount_);

        emit TransferSingle(msg.sender, address(0), to_, id_, amount_);

        _ERC1155Supported(address(0), to_, id_, amount_, data_);
    }

    function _batchMint(address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) internal {
        require(_isSameLength(ids_.length, amounts_.length));

        for (uint256 i = 0; i < ids_.length; i++) {
            _mintInternal(to_, ids_[i], amounts_[i]);
        }

        emit TransferBatch(msg.sender, address(0), to_, ids_, amounts_);

        _ERC1155BatchSupported(address(0), to_, ids_, amounts_, data_);
    }

    function _burnInternal(address from_, uint256 id_, uint256 amount_) internal {
        balanceOf[from_][id_] -= amount_;
        _removeEnumerableData(from_, id_);
    }

    function _burn(address from_, uint256 id_, uint256 amount_) internal {
        _burnInternal(from_, id_, amount_);
        emit TransferSingle(msg.sender, from_, address(0), id_, amount_);
    }

    function _batchBurn(address from_, uint256[] memory ids_, uint256[] memory amounts_) internal {
        require(_isSameLength(ids_.length, amounts_.length));
        
        for (uint256 i = 0; i < ids_.length; i++) {
            _burnInternal(from_, ids_[i], amounts_[i]);
        }

        emit TransferBatch(msg.sender, from_, address(0), ids_, amounts_);
    }

    function supportsInterface(bytes4 interfaceId_) public pure virtual returns (bool) {
        return interfaceId_ == 0x01ffc9a7 || interfaceId_ == 0xd9b67a26 || interfaceId_ == 0x0e89341c;
    }

    function balanceOfBatch(address[] memory owners_, uint256[] memory ids_) public view virtual returns (uint256[] memory) {
        require(_isSameLength(owners_.length, ids_.length));

        uint256[] memory _balances = new uint256[](owners_.length);

        for (uint256 i = 0; i < owners_.length; i++) {
            _balances[i] = balanceOf[owners_[i]][ids_[i]];
        }
        return _balances;
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

abstract contract ERC721URIPerToken {
    mapping(uint256 => string) public tokenToURI;
    function _setTokenToURI(uint256 tokenId_, string memory uri_) internal virtual {
        tokenToURI[tokenId_] = uri_;
    }
}

interface IMetadata {
    function tokenURI(uint256 tokenId_) external view returns (string memory);
}

contract ZIELCHAIN is ERC1155Enumerable, OwnControll, ERC721URIPerToken {

    address public metadata;
    bool public useMetadata;
    mapping(uint256 => bool) public list;

    constructor() ERC1155Enumerable("ZIELCHAIN", "ZC_NAT3") {}

    function mint(address to_, uint256 id_, uint256 amount_, bytes memory data_) external onlyAdmin("MINTER") {
        _mint(to_, id_, amount_, data_);
    }

    function batchMint(address[] calldata to_, uint256 id_, uint256[] calldata amounts_, bytes memory data_) external onlyAdmin("MINTER") {
        require(to_.length == amounts_.length, "Input array length mismatch");
        uint256 l = to_.length;
        uint256 i; unchecked { do {
            _mint(to_[i], id_, amounts_[i], data_);
        } while (++i < l); }
    }

    function burn(address from_, uint256 id_, uint256 amount_) external onlyAdmin("BURNER") {
        _burn(from_, id_, amount_);
    }

    function setTokenToURI(uint256 tokenId_, string calldata uri_) external onlyAdmin("ADMIN") {
        _setTokenToURI(tokenId_, uri_);
    }

    function setMetadata(address address_) external onlyAdmin("ADMIN") { 
        metadata = address_; 
    }

    function setUseMetadata(bool bool_) external onlyAdmin("ADMIN") {
        useMetadata = bool_;
    }

    function toggleIdsTransferable(uint256[] calldata ids_) external onlyAdmin("TOGGLE") {
        uint256 l = ids_.length;
        uint256 i; unchecked { do {
            list[ids_[i]] = true;
        } while (++i < l); }
    }

    function toggleIdsUnTransferable(uint256[] calldata ids_) external onlyAdmin("TOGGLE") {
        uint256 l = ids_.length;
        uint256 i; unchecked { do {
            list[ids_[i]] = false;
        } while (++i < l); }
    }

    function isListed(uint256 id_) internal view returns (bool) {
        return list[id_];
    }

    function safeTransferFrom(address from_, address to_, uint256 id_, uint256 amount_, bytes memory data_) public virtual override {
        require(isListed(id_), "id selected untransferable");
        super.safeTransferFrom(from_, to_, id_, amount_, data_);
    }

    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) public virtual override {
        uint256 l = ids_.length;
        uint256 i; unchecked { do {
            require(isListed(ids_[i]), "id selected untransferable");
        } while (++i < l); }
        super.safeBatchTransferFrom(from_, to_, ids_, amounts_, data_);
    }

    function uri(uint256 id_) public view override returns (string memory) {
        if (!useMetadata) {
            return tokenToURI[id_];
        } else {
            return IMetadata(metadata).tokenURI(id_);
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}