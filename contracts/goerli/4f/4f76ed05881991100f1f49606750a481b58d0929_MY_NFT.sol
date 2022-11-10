/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Counters {
    struct Counter {
        uint _value;
    }

    function current(Counter storage counter) internal view returns (uint) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint temp = value;
        uint digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint temp = value;
        uint length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint value, uint length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint(uint160(addr)), _ADDRESS_LENGTH);
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) external;

    function approve(address to, uint tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint tokenId)
        external
        view
        returns (address operator);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint tokenId) external view returns (string memory);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Strings for uint;

    string private _name;
    string private _symbol;
    mapping(uint => address) private _owners;
    mapping(address => uint) private _balances;
    mapping(uint => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint)
    {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    function ownerOf(uint tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        // require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string.concat(baseURI, tokenId.toString(), ".json")
                : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );
        _approve(to, tokenId);
    }

    function getApproved(uint tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        _requireMinted(tokenId);
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner nor approved"
        );
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _exists(uint tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint tokenId) internal virtual {
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

    function _requireMinted(uint tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.code.length > 0) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
        uint tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal virtual {}
}

contract MY_NFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;
    string public baseTokenURI;
    uint public maxSupply = 100;
    uint public price = 0.01 ether;
    address public Beneficiary = 0xDb4CE33fbD72aA160bE47Bc382e53038AD75aFDD; // constant
    uint public _numAvailableTokens;
    mapping(uint=>uint) private _availableTokens;

    modifier notOverMaxSupply(uint _amount) {
        require(_amount + totalSupply() <= maxSupply, "Max Supply Limit Exceeded");
        _;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _baseTokenURI
        ) ERC721(name_, symbol_) {
            setBaseTokenURI(_baseTokenURI);
            _numAvailableTokens = maxSupply;
        }
    // constructor() ERC721("MyToken", "MTK") {
    //     _numAvailableTokens = maxSupply;
    // }

    function mintRandom(uint _amount) external payable notOverMaxSupply(_amount)  {
        require(msg.value == price * _amount, "Pay Exact Amount");
        require(_amount > 0, "need to mint at least 1 NFT");
        uint updatedNumAvailableTokens = _numAvailableTokens;
        for (uint i = 0; i < _amount; i++) {
            uint tokenId = getRandomAvailableTokenId(_msgSender(), updatedNumAvailableTokens);
            super._mint(_msgSender(), tokenId);
            updatedNumAvailableTokens--;
            _tokenSupply.increment();
        }
        _numAvailableTokens = updatedNumAvailableTokens;
        (bool success, ) = payable(Beneficiary).call{value: msg.value}("");
        require(success);
    }

    function getRandomAvailableTokenId(address to, uint updatedNumAvailableTokens)
        internal
        returns (uint)
    {
        uint randomNum = uint(
            keccak256(
                abi.encode(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    blockhash(block.number - 1),
                    address(this),
                    updatedNumAvailableTokens
                )
            )
        );
        uint randomIndex = randomNum % updatedNumAvailableTokens;
        return getAvailableTokenAtIndex(randomIndex, updatedNumAvailableTokens);
    }

    function getAvailableTokenAtIndex(uint indexToUse, uint updatedNumAvailableTokens)
        internal
        returns (uint)
    {
        uint valAtIndex = _availableTokens[indexToUse];  
        uint result;
        if (valAtIndex == 0) {
            result = indexToUse; 
        } else {
            result = valAtIndex;
        }
        uint lastIndex = updatedNumAvailableTokens - 1; 
        if (indexToUse != lastIndex) { 
            uint lastValInArray = _availableTokens[lastIndex]; 
            if (lastValInArray == 0) {
                _availableTokens[indexToUse] = lastIndex; 
            } else {
                _availableTokens[indexToUse] = lastValInArray; 
                delete _availableTokens[lastIndex];
            }
        }
        return result;
    }

    //↓↓↓↓↓↓// SETTER //↓↓↓↓↓↓
    ////////////////////////////
    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        require(bytes(_baseTokenURI).length > 0, "Invalid base URI");
        baseTokenURI = _baseTokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    //↓↓↓↓↓↓// GETTER //↓↓↓↓↓↓
    ////////////////////////////
    function totalSupply() public view returns (uint) {
        return _tokenSupply.current();
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint[] memory)
    {
        uint ownerTokenCount = balanceOf(_owner); 
        uint[] memory ownedTokenIds = new uint[](ownerTokenCount); 
        uint currentTokenId = 1;
        uint ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount &&  
            currentTokenId < maxSupply 
        ) {
            if (ownerOf(currentTokenId) == _owner) { 
                ownedTokenIds[ownedTokenIndex] = currentTokenId; 
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    } //QmUEzVmEHhE2X3AkjY1L9sChdmmjGGuywdJcFd4LY4H5fu
    //https://ipfs.io/ipfs/QmUEzVmEHhE2X3AkjY1L9sChdmmjGGuywdJcFd4LY4H5fu/
    

    fallback() external payable {
        (bool success, ) = payable(Beneficiary).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send Ether");
    }

    receive() external payable {
        (bool success, ) = payable(Beneficiary).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send Ether");
    }   
}