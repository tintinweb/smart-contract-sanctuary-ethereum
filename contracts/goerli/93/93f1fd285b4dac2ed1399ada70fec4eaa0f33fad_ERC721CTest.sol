/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// ERC721C (CypherLabz)
// Simple and Efficient

contract ERC721C {

    // ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved,
        uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator,
        bool approved);

    // ERC721 Global Variables
    string public name;
    string public symbol; 

    // ERC721 Constructor
    uint256 public immutable startTokenId; // @dev: We use immutable to save on SLOADs
    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        startTokenId = _nextTokenId();
    }

    // ERC721C Global Variables
    uint256 public totalSupply; 

    // ERC721C Structs
    struct OwnerStruct {
        address owner;
        uint40 lastTransfer;
        bool burned; // @dev: We store burned data here and revert on _getTokenDataOf()
        bool nextInitialized; // @dev: We use nextInitialized to save on N+1 lookup SLOAD
        // 6 Free Bytes
    }
    struct BalanceStruct { 
        uint32 balance;
        uint32 mintedAmount;
        // 24 Free Bytes
    }

    // ERC721C Mappings
    mapping(uint256 => OwnerStruct) public _tokenData;
    mapping(address => BalanceStruct) public _balanceData;

    // ERC721 Mappings
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    function _nextTokenId() internal view returns (uint256) {
        /** @dev: Do [totalSupply + N] on this to customize starting tokenId */
        return totalSupply;
    }

    // @gas: OK
    function _getTokenDataOf(uint256 tokenId_) public view 
    returns (OwnerStruct memory) {
        // Set the lookupId
        // @gas: MLOAD + MSTORE
        uint256 _lookupId = tokenId_;

        // The tokenId must be above startTokenId only
        // @gas: MLOAD + CONTRACTREAD
        require(_lookupId >= startTokenId, "TokenId below starting Id!");

        // @gas: SLOAD (2000)
        OwnerStruct storage _OwnerStruct = _tokenData[_lookupId];

        // If the _tokenData is initialized and not burned, return it
        // @gas: MLOAD + MLOAD
        if (_OwnerStruct.owner != address(0) && 
            !_OwnerStruct.burned) return _OwnerStruct;

        // The tokenId must not be burnt
        // @gas: MLOAD
        require(!_OwnerStruct.burned, "Token is burned!");

        // The tokenId must be below _nextTokenId()
        // @gas: MLOAD + SLOAD (2000)
        require(_lookupId < _nextTokenId(), "TokenId above current Index!");

        // If it's not, do a lookup-trace
        unchecked {
            while (_OwnerStruct.owner == address(0)) { 
                _OwnerStruct = _tokenData[--_lookupId];
            }
            return _OwnerStruct;
        }
    }

    // @gas: OK
    function ownerOf(uint256 tokenId_) public view returns (address) {
        return _getTokenDataOf(tokenId_).owner;
    }
    // @gas: OK
    function balanceOf(address address_) public view returns (uint256) {
        return _balanceData[address_].balance;
    }

    // @gas: OK
    function _mint(address to_, uint256 amount_) internal { unchecked {
        require(to_ != address(0), "ERC721C: _mint to 0x0!");
        
        uint256 _startId = _nextTokenId();
        uint256 _endId = _startId + amount_;

        // Store the mint to _tokenData at Index
        _tokenData[_startId].owner = to_;
        _tokenData[_startId].lastTransfer = uint40(block.timestamp);

        // Add the balance to _balanceData at to_
        _balanceData[to_].balance += uint32(amount_);
        _balanceData[to_].mintedAmount += uint32(amount_);

        // Phantom Mint the tokens
        do { emit Transfer(address(0), to_, _startId); } while (++_startId < _endId);

        // Increment the totalSupply by Amount 
        // Set the totalSupply to _endId (next Id) (more gas efficient)
        totalSupply = _endId;
    }}

    function transferFrom(address from_, address to_, uint256 tokenId_) public {
        // @gas: MLOAD + MLOAD
        require(to_ != address(0), "_transfer to 0x0!");
        // @gas: CALL
        OwnerStruct memory _CurrOwnerStruct = _getTokenDataOf(tokenId_);
        address _owner = _CurrOwnerStruct.owner;
        // @gas: MLOAD + MLOAD
        require(from_ == _owner, "_transfer not from owner!");

        // isApprovedOrOwner flow
        require(_owner == msg.sender ||
                getApproved[tokenId_] == msg.sender ||
                isApprovedForAll[_owner][msg.sender],
                "Ya'll aint approved");

        // @gas: OPCODE
        delete getApproved[tokenId_];

        // Store the transfer to _tokenData at Index
        _tokenData[tokenId_].owner = to_;
        _tokenData[tokenId_].lastTransfer = uint40(block.timestamp);
        _tokenData[tokenId_].nextInitialized = true;
        
        /** @dev: Bookmarking Logic */
        // First, we check N+1 if it's initialized
        if (!_CurrOwnerStruct.nextInitialized) { 
            if (tokenId_ < _nextTokenId() - 1) {
            _tokenData[tokenId_ + 1] = _CurrOwnerStruct;
            }
        }

        // Update Balance
        unchecked {
            _balanceData[from_].balance--;
            _balanceData[to_].balance++;
        }

        // Emit a standard Transfer
        emit Transfer(from_, to_, tokenId_);
    }

    // ERC721 Logic 
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal 
    view virtual returns (bool) {
        address _owner = ownerOf(tokenId_);
        return (_owner == spender_ ||
                getApproved[tokenId_] == spender_ ||
                isApprovedForAll[_owner][spender_]);
    }
    function _approve(address to_, uint256 tokenId_) internal virtual {
        getApproved[tokenId_] = to_;
        emit Approval(ownerOf(tokenId_), to_, tokenId_);
    }
    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(_owner == msg.sender || 
                isApprovedForAll[_owner][msg.sender],
                "ERC721G: approve not authorized");
        _approve(to_, tokenId_);
    }
    function _setApprovalForAll(address owner_, address operator_, bool approved_) 
    internal virtual {
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }
    function _exists(uint256 tokenId_) internal virtual view returns (bool) {
        return ownerOf(tokenId_) != address(0);
    }
    // function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
    //     require(_isApprovedOrOwner(msg.sender, tokenId_),
    //         "ERC721G: transferFrom unauthorized");
    //     _transfer(from_, to_, tokenId_);
    // }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_,
    bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.call(abi.encodeWithSelector(
                0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02, 
                "ERC721G: safeTransferFrom to_ non-ERC721Receivable!");
        }
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }
    function supportsInterface(bytes4 iid_) public virtual view returns (bool) {
        return  iid_ == 0x01ffc9a7 || 
                iid_ == 0x80ac58cd || 
                iid_ == 0x5b5e139f || 
                iid_ == 0x7f5828d0; 
    }
    function tokenURI(uint256 tokenId_) public virtual view returns (string memory) {}
}

contract ERC721CTest is ERC721C {
    constructor() ERC721C("Test", "Test") {}
    function mint(address to_, uint256 amount_) external {
        _mint(to_, amount_);
    }
}