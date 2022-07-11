/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
1. Cost 50 $AURA per mint
2. Dont need to hold ascended
3. Yes is random
4. No yield from VX
*/

/* ERC721I - ERC721I (ERC721 0xInuarashi Edition) - Gas Optimized
    Open Source: with the efforts of the [0x Collective] <3 */

contract ERC721I {

    string public name; string public symbol;
    string internal baseTokenURI; string internal baseTokenURI_EXT;
    constructor(string memory name_, string memory symbol_) {
        name = name_; symbol = symbol_; 
    }

    uint256 public totalSupply; 
    mapping(uint256 => address) public ownerOf; 
    mapping(address => uint256) public balanceOf; 

    mapping(uint256 => address) public getApproved; 
    mapping(address => mapping(address => bool)) public isApprovedForAll; 

    // Events
    event Transfer(address indexed from, address indexed to, 
    uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, 
    uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, 
    bool approved);

    // // internal write functions
    // mint
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0x0), 
            "ERC721I: _mint() Mint to Zero Address");
        require(ownerOf[tokenId_] == address(0x0), 
            "ERC721I: _mint() Token to Mint Already Exists!");

        balanceOf[to_]++;
        ownerOf[tokenId_] = to_;

        emit Transfer(address(0x0), to_, tokenId_);
    }

    // transfer
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        require(from_ == ownerOf[tokenId_], 
            "ERC721I: _transfer() Transfer Not Owner of Token!");
        require(to_ != address(0x0), 
            "ERC721I: _transfer() Transfer to Zero Address!");

        // checks if there is an approved address clears it if there is
        if (getApproved[tokenId_] != address(0x0)) { 
            _approve(address(0x0), tokenId_); 
        } 

        ownerOf[tokenId_] = to_; 
        balanceOf[from_]--;
        balanceOf[to_]++;

        emit Transfer(from_, to_, tokenId_);
    }

    // approve
    function _approve(address to_, uint256 tokenId_) internal virtual {
        if (getApproved[tokenId_] != to_) {
            getApproved[tokenId_] = to_;
            emit Approval(ownerOf[tokenId_], to_, tokenId_);
        }
    }
    function _setApprovalForAll(address owner_, address operator_, bool approved_)
    internal virtual {
        require(owner_ != operator_, 
            "ERC721I: _setApprovalForAll() Owner must not be the Operator!");
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    // token uri
    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }
    function _setBaseTokenURI_EXT(string memory ext_) internal virtual {
        baseTokenURI_EXT = ext_;
    }

    // // Internal View Functions
    // Embedded Libraries
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
            48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    // Functional Views
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal 
    view virtual returns (bool) {
        require(ownerOf[tokenId_] != address(0x0), 
            "ERC721I: _isApprovedOrOwner() Owner is Zero Address!");
        address _owner = ownerOf[tokenId_];
        return (spender_ == _owner 
            || spender_ == getApproved[tokenId_] 
            || isApprovedForAll[_owner][spender_]);
    }
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return ownerOf[tokenId_] != address(0x0);
    }

    // // public write functions
    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf[tokenId_];
        require(to_ != _owner, 
            "ERC721I: approve() Cannot approve yourself!");
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender],
            "ERC721I: Caller not owner or Approved!");
        _approve(to_, tokenId_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), 
            "ERC721I: transferFrom() _isApprovedOrOwner = false!");
        _transfer(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, 
    bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.staticcall(abi.encodeWithSelector(
                0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02, 
                "ERC721I: safeTransferFrom() to_ not ERC721Receivable!");
        }
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) 
    public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    // 0xInuarashi Custom Functions
    function multiTransferFrom(address from_, address to_, 
    uint256[] memory tokenIds_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            transferFrom(from_, to_, tokenIds_[i]);
        }
    }
    function multiSafeTransferFrom(address from_, address to_, 
    uint256[] memory tokenIds_, bytes memory data_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            safeTransferFrom(from_, to_, tokenIds_[i], data_);
        }
    }

    // OZ Standard Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }

    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        require(ownerOf[tokenId_] != address(0x0), 
            "ERC721I: tokenURI() Token does not exist!");
        return string(abi.encodePacked(
            baseTokenURI, _toString(tokenId_), baseTokenURI_EXT));
    }
    // // public view functions
    // never use these for functions ever, they are expensive af and for view only 
    function walletOfOwner(address address_) public virtual view 
    returns (uint256[] memory) {
        uint256 _balance = balanceOf[address_];
        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf[i] == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++; 
            }
            if (ownerOf[i] == address_) { 
                _tokens[_index] = i; _index++; 
            }
        }
        return _tokens;
    }

    // not sure when this will ever be needed but it conforms to erc721 enumerable
    function tokenOfOwnerByIndex(address address_, uint256 index_) public 
    virtual view returns (uint256) {
        uint256[] memory _wallet = walletOfOwner(address_);
        return _wallet[index_];
    }
}

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface iERC20 {
    function balanceOf(address wallet_) external view returns (uint256);
    function transferFrom(address from_, address to_, uint256 amount_) external;
}

contract AscendedVX is ERC721I, Ownable {
    constructor() ERC721I("Ascended VX","AscendedVX") {}

    ///// Interfaces /////
    iERC20 public AURA = iERC20(0xBE6a20DAd94b377Af1EfaA229ed0E0B91eb54ac5);
    function setAURA(address aura_) external onlyOwner { AURA = iERC20(aura_); }

    ///// Project Constraints /////
    uint256 public maxTokens = 8888; 

    ///// Costs /////
    uint256 public auraToMint = 50 ether;
    function setAuraToMint(uint256 cost_) external onlyOwner { auraToMint = cost_; }
    address public auraReceiver = 0x000000000000000000000000000000000000dEaD;
    function setAuraReceiver(address receiver_) external onlyOwner { 
        auraReceiver = receiver_; }

    ///// Ownable Administration //////
    function setBaseTokenURI(string calldata uri_) external onlyOwner { 
        _setBaseTokenURI(uri_);
    }
    function setBaseTokenURI_EXT(string calldata ext_) external onlyOwner {
        _setBaseTokenURI_EXT(ext_);
    }

    ///// Pausable Administration (Ownable) /////
    bool public vxMintingPaused; 
    modifier onlyMinting { require(!vxMintingPaused, "VX Minting is Paused!"); _; }
    function setMintingPaused(bool bool_) external onlyOwner {
        vxMintingPaused = bool_; 
    }

    ///// Internal Functions /////
    function _mintMany(address to_, uint256 amount_) internal {
        require(maxTokens >= totalSupply + amount_,
            "Not enough supply remaining!");

        // TokenId starts at 1
        uint256 _startId = totalSupply + 1;

        for (uint256 i = 0; i < amount_; i++) {
            _mint(to_, _startId + i);
        }
        totalSupply += amount_;
    }

    ///// Owner Mint Functions /////
    function ownerMint(address[] calldata tos_, uint256[] calldata amounts_) 
    external onlyOwner {
        require(tos_.length == amounts_.length,
            "Array Length Mismatch!");
        
        for (uint256 i = 0; i < tos_.length; i++) {
            _mintMany(tos_[i], amounts_[i]);
        }
    }

    ///// Aura Mint Functions /////
    function mint(uint256 amount_) external onlyMinting {
        // Maximum amount_ per mint is 20. Hardcode to save 2100 SLOAD gas
        require(amount_ <= 20,
            "You can only mint 20 per tx!");

        // calculate the total AURA cost
        uint256 _totalAuraCost = auraToMint * amount_;

        // msg.sender requires to have >= AURA than cost
        require(AURA.balanceOf(msg.sender) >= _totalAuraCost,
            "You don't have enough $AURA!");

        // transfer it to receiver address
        AURA.transferFrom(msg.sender, auraReceiver, _totalAuraCost);

        // after that, mint the amount to the msg.sender
        _mintMany(msg.sender, amount_);
    }
}