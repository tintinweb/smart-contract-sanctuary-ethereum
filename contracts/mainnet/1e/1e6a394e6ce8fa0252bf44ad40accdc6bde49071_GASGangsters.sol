/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external { 
        address _oldOwner = owner;
        require(_oldOwner == msg.sender, "Not Owner!");
        owner = new_; 
        emit OwnershipTransferred(_oldOwner, new_);
    }

    // Proxy Padding
    bytes32[50] private proxyPadding;
}
abstract contract Minterable is Ownable {
    event MinterableSet(address indexed operator, address indexed minter, bool isMinter);
    mapping(address => bool) public minters;
    modifier onlyMinter { require(minters[msg.sender], "Not Minter!"); _; }
    function setMinter(address address_, bool bool_) external onlyOwner {
        minters[address_] = bool_;
        emit MinterableSet(msg.sender, address_, bool_);
    }

    // Proxy Padding
    bytes32[50] private proxyPadding;
}

// The GSM version of G
contract ERC721GSM {

    // ERC721-Standard Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, 
        uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // ERC721-Standard Token Info
    string public name;
    string public symbol;

    // ERC721-Standard Constructor
    constructor(string memory name_, string memory symbol_) { 
        name = name_;
        symbol = symbol_;
    }

    // ERC721G Data Structures
    struct OwnerStruct { 
        address owner;
        uint32 lastTransfer;
        uint32 stakeTimestamp;
        uint32 totalTimeStaked;
    }
    struct BalanceStruct { 
        uint32 balance;
        uint32 mintedAmount;
        // Free Bytes
    }

    // ERC721G Data Mappings
    mapping(uint256 => OwnerStruct) public _tokenData;
    mapping(address => BalanceStruct) public _balanceData;

    // ERC721-Standard Approval Mappings
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // Time Tools by 0xInuarashi
    function _getBlockTimestampCompressed() internal view returns (uint32) {
        return uint32(block.timestamp / 10);
    }

    // ERC721-Compliant Standard Reads
    function ownerOf(uint256 tokenId_) public virtual view returns (address) {
        return _tokenData[tokenId_].owner;
    }
    function balanceOf(address address_) public view returns (uint256) {
        return _balanceData[address_].balance;
    }

    // ERC721-Style Internal Functions
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0), "_mint: target == 0x0");
        require(_tokenData[tokenId_].owner == address(0), "_mint: token exists");

        uint32 _currentTime = _getBlockTimestampCompressed();
        _tokenData[tokenId_] = OwnerStruct(to_, _currentTime, 0, 0);

        unchecked {
            _balanceData[to_].balance++;
            _balanceData[to_].mintedAmount++;
        }

        emit Transfer(address(0), to_, tokenId_);
    }
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        require(from_ == ownerOf(tokenId_), "_transfer from_ != ownerOf");
        require(to_ != address(0), "_transfer to_ == 0x0");
        
        delete getApproved[tokenId_];

        _tokenData[tokenId_].owner = to_;
        _tokenData[tokenId_].lastTransfer = _getBlockTimestampCompressed();

        unchecked {
            _balanceData[from_].balance--;
            _balanceData[to_].balance++;
        }

        emit Transfer(from_, to_, tokenId_);
    }

    // ERC721-Standard Non-Modified Functions
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal 
    view virtual returns (bool) {
        address _owner = ownerOf(tokenId_);
        return (_owner == spender_
                || getApproved[tokenId_] == spender_
                || isApprovedForAll[_owner][spender_]);
    }
    function _approve(address to_, uint256 tokenId_) internal virtual {
        getApproved[tokenId_] = to_;
        emit Approval(ownerOf(tokenId_), to_, tokenId_);
    }
    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(_owner == msg.sender 
                || isApprovedForAll[_owner][msg.sender],
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
    
    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_),
            "ERC721G: transferFrom unauthorized");
        _transfer(from_, to_, tokenId_);
    }
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

    // Proxy Padding
    bytes32[50] private proxyPadding;
}

contract ERC721GSMStake is ERC721GSM {
    // First, we do constructor-compliant to ERC721GSM
    constructor(string memory name_, string memory symbol_) ERC721GSM(name_, symbol_) {} 

    // Then, we create some additional helper functions for staking
    function stakingAddress() public view returns (address) {
        return address(this);
    }
    function _compressTimestamp(uint256 timestamp_) internal pure returns (uint32) {
        return uint32(timestamp_ / 10);
    }
    function _expandTimestamp(uint32 timestamp_) internal pure returns (uint256) {
        return uint256(timestamp_ * 10);
    }
    function _getTokenDataOf(uint256 tokenId_) internal view 
    returns (OwnerStruct memory) {
        return _tokenData[tokenId_];
    }
    function _trueOwnerOf(uint256 tokenId_) internal view returns (address) {
        return _getTokenDataOf(tokenId_).owner;
    }

    // Next, we override the required functions for Staking functionality
    function ownerOf(uint256 tokenId_) public view override returns (address) {
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        return _OwnerStruct.stakeTimestamp == 0 ? _OwnerStruct.owner : stakingAddress();
    }

    // Finally, we add additional functions to enable staking
    function _mintAndStake(address to_, uint256 tokenId_) internal {
        require(to_ != address(0), "_mint: target == 0x0");
        require(_tokenData[tokenId_].owner == address(0), "_mint: token exists");

        uint32 _currentTime = _getBlockTimestampCompressed();
        _tokenData[tokenId_] = OwnerStruct(to_, _currentTime, _currentTime, 0);
        
        unchecked {
            _balanceData[stakingAddress()].balance++;
            _balanceData[to_].mintedAmount++;
        }

        emit Transfer(address(0), to_, tokenId_);
        emit Transfer(to_, stakingAddress(), tokenId_);
    }
    function _setStakeTimestamp(uint256 tokenId_, uint256 timestamp_) internal 
    returns (address) {
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        address _owner = _OwnerStruct.owner;
        uint32 _stakeTimestamp = _OwnerStruct.stakeTimestamp;

        require(_owner != address(0), "_setStakeTimestamp: token does not exist");

        if (timestamp_ > 0) {
            require(_stakeTimestamp == 0, "_setStakeTimestamp: already staked");
            unchecked { 
                // Rebalance the balances of owner and stakingAddress
                _balanceData[_owner].balance--;
                _balanceData[stakingAddress()].balance++;
            }
            emit Transfer(_owner, stakingAddress(), tokenId_);
        }

        else { 
            require(_stakeTimestamp != 0, "_setStakeTimestamp: already unstaked");
            uint32 _timeStaked = _getBlockTimestampCompressed() - _stakeTimestamp;
            _tokenData[tokenId_].totalTimeStaked += _timeStaked;
            unchecked { 
                _balanceData[stakingAddress()].balance--;
                _balanceData[_owner].balance++;
            }
            emit Transfer(stakingAddress(), _owner, tokenId_);
        }

        _tokenData[tokenId_].stakeTimestamp = _compressTimestamp(timestamp_);

        return _owner;
    }

    function _stake(uint256 tokenId_) internal virtual returns (address) {
        return _setStakeTimestamp(tokenId_, block.timestamp);
    }
    function _unstake(uint256 tokenId_) internal virtual returns (address) {
        return _setStakeTimestamp(tokenId_, 0);
    }

    // Proxy Padding
    bytes32[50] private proxyPadding;
}

contract GASGangsters is ERC721GSMStake, Minterable {
    constructor() ERC721GSMStake("Gangster All Star: Gangsters Evolution", "GAS:GANG") {}

    // Proxy Initializer Logic
    bool proxyIsInitialized;
    function proxyInitialize(address newOwner) external {
        require(!proxyIsInitialized);
        proxyIsInitialized = true;
        
        // Hardcode
        owner = newOwner;
        name = "Gangster All Star: Gangsters Evolution";
        symbol = "GAS:GANG";
    }

    function mintAsController(address to_, uint256 tokenId_) external onlyMinter {
        _mint(to_, tokenId_);
    }

    // Proxy Padding
    bytes32[50] private proxyPadding;
}