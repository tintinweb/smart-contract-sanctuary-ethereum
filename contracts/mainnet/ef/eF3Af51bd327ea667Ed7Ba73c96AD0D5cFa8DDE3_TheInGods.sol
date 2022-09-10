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

pragma solidity ^0.8.4;

interface IERC721A {
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

    function totalSupply() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

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
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.0;

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

pragma solidity 0.8.7;

contract TheInGods is IERC721A { 

    address private _owner;
    modifier onlyOwner() { 
        require(_owner==msg.sender, "only owner is allowed"); 
        _; 
    }

    bool public saleIsActive = false;

    uint256 public constant MAX_SUPPLY = 4421;
    uint256 public constant MAX_FREE_PER_WALLET = 2;
    uint256 public constant MAX_BUY_PER_TX = 20;
    uint256 public constant COST = 0.002 ether;

    string private _name = "The In Gods";
    string private _symbol = "INGODS";
    string private _baseURI = "ipfs://bafybeifbklbabuktufdtz3mmvr7lr7gnxp4kksjlaztd5hfm3h74wrhlna/";
    string private _contractURI = "ipfs://bafybeifbklbabuktufdtz3mmvr7lr7gnxp4kksjlaztd5hfm3h74wrhlna/";

    constructor() {
        _owner = msg.sender;
    }

    function mint(uint256 _amount) external payable{
        address _caller = _msgSenderERC721A();

        require(saleIsActive, "Mint is not active right now.");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Sold out");
        require(_amount <= MAX_BUY_PER_TX, "Max Tx Limit reached");
        require(msg.value >= _amount*COST, "Not enought Cash provided");
        
        _safeMint(_caller, _amount);
    }

    function mintFree(uint256 _amount) external{
        address _caller = _msgSenderERC721A();

        require(saleIsActive, "Mint is not active right now.");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Sold out");

        uint magicTokenNum;
        uint count = totalSupply();

        if(count <= 10){
            magicTokenNum = 5;
        } else if (count <= 2000) {
            magicTokenNum = 3; 
        } else if (count <= 4000) {
            magicTokenNum = 2; 
        } else {
            magicTokenNum = 1; 
        }

        require(_amount <= magicTokenNum, "Tx limit exceeded");
        require(_amount + _numberMinted(msg.sender) <= magicTokenNum, "Acc has token limit");

        _safeMint(_caller, _amount);
    }   

    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
    uint256 private constant BITPOS_NUMBER_MINTED = 64;
    uint256 private constant BITPOS_NUMBER_BURNED = 128;
    uint256 private constant BITPOS_AUX = 192;
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;
    uint256 private constant BITPOS_START_TIMESTAMP = 160;
    uint256 private constant BITMASK_BURNED = 1 << 224;
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;
    uint256 private _currentIndex = 0;

    mapping(uint256 => uint256) private _packedOwnerships;
    mapping(address => uint256) private _packedAddressData;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    // SETTER
    function setName(string memory _newName, string memory _newSymbol) external onlyOwner {
        _name = _newName;
        _symbol = _newSymbol;
    }

    function setSale(bool _saleIsActive) external onlyOwner{
        saleIsActive = _saleIsActive;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner{
        _baseURI = _newBaseURI;
    }

    function setContractURI(string memory _new_contractURI) external onlyOwner{
        _contractURI = _new_contractURI;
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    function totalSupply() public view override returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }
    function _totalMinted() internal view returns (uint256) {
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }
    function balanceOf(address owner) public view override returns (uint256) {
        if (_addressToUint256(owner) == 0) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }


    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly { // Cast aux without masking.
auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
    }
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI;

        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
result := value
        }
    }
    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
result := value
        }
    }
    function approve(address to, uint256 tokenId) public override {
        address owner = address(uint160(_packedOwnershipOf(tokenId)));
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(
            address from,
            address to,
            uint256 tokenId
            ) public virtual override {
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId
            ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }
    function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId,
            bytes memory //_data
            ) public virtual override {
        _transfer(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex;
    }
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    function _safeMint(
            address to,
            uint256 quantity,
            bytes memory //_data
            ) internal {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        unchecked {
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.code.length != 0) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (_addressToUint256(to) == 0) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        unchecked {
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _transfer(
            address from,
            address to,
            uint256 tokenId
            ) private {

        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();
        address approvedAddress = _tokenApprovals[tokenId];
        bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
                isApprovedForAll(from, _msgSenderERC721A()) ||
                approvedAddress == _msgSenderERC721A());
        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        //X if (_addressToUint256(to) == 0) revert TransferToZeroAddress();

        if (_addressToUint256(approvedAddress) != 0) {
            delete _tokenApprovals[tokenId];
        }

        unchecked {
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            _packedOwnerships[tokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_NEXT_INITIALIZED;

            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                if (_packedOwnerships[nextTokenId] == 0) {
                    if (nextTokenId != _currentIndex) {
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _afterTokenTransfers(
            address from,
            address to,
            uint256 startTokenId,
            uint256 quantity
            ) internal virtual {}

    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
ptr := add(mload(0x40), 128)

         mstore(0x40, ptr)

         let end := ptr
         for { 
             let temp := value
                 ptr := sub(ptr, 1)
                 mstore8(ptr, add(48, mod(temp, 10)))
                 temp := div(temp, 10)
         } temp { 
        temp := div(temp, 10)
         } { 
        ptr := sub(ptr, 1)
         mstore8(ptr, add(48, mod(temp, 10)))
         }

     let length := sub(end, ptr)
         ptr := sub(ptr, 32)
         mstore(ptr, length)
        }
    }

    function WhitelistMint(address _to, uint256 _amount) external onlyOwner{
        require(totalSupply()+_amount<MAX_SUPPLY, 'max supply reached');
        _safeMint(_to, _amount);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function treasuryMint(uint256 quantity) public onlyOwner {
        require(quantity > 0, "Invalid mint amount");
      require(totalSupply()+ quantity<MAX_SUPPLY, 'max supply reached');
        _safeMint(msg.sender, quantity);
    }

}