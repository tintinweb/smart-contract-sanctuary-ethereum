/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* ERC721IM - ERC721IM (ERC721 0xInuarashi Edition), Modifiable - Gas Optimized
    Open Source: with the efforts of the [0x Collective] <3 */

contract ERC721IM {

    string public name; string public symbol;
    string internal baseTokenURI; string internal baseTokenURI_EXT;
    constructor(string memory name_, string memory symbol_) { name = name_; symbol = symbol_; }

    uint256 public totalSupply; 

    struct ownerAndStake {
        address owner; // 20 | 12
        uint40 timestamp; // 5 | 7
    }

    mapping(uint256 => ownerAndStake) public _ownerOf;

    mapping(address => uint256) public balanceOf; 

    mapping(uint256 => address) public getApproved; 
    mapping(address => mapping(address => bool)) public isApprovedForAll; 

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function ownerOf(uint256 tokenId_) public virtual view returns (address) {
        return _ownerOf[tokenId_].owner;
    }

    function isStaked(uint256 tokenId_) public view returns (bool) {
        return _ownerOf[tokenId_].timestamp > 0;
    }

    function getTimestampOfToken(uint256 tokenId_) public view returns (uint40) {
        return _ownerOf[tokenId_].timestamp;
    }

    function _stake(uint256 tokenId_) internal virtual {
        require(ownerOf(tokenId_) != address(0),
            "_stake(): Token doesn't exist!");
        require(!isStaked(tokenId_),
            "_stake(): Token is already staked!");

        _ownerOf[tokenId_].timestamp = uint40(block.timestamp);
    }

    function _update(uint256 tokenId_) internal virtual {
        require(ownerOf(tokenId_) != address(0),
            "_update(): Token doesn't exist!");
        require(isStaked(tokenId_),
            "_update(): Token is not staked!");

        _ownerOf[tokenId_].timestamp = uint40(block.timestamp);
    }
    
    function _unstake(uint256 tokenId_) internal virtual {
        require(ownerOf(tokenId_) != address(0),
            "_unstake(): Token doesn't exist!");
        require(isStaked(tokenId_),
            "_unstake(): Token is not staked!");
        
        _ownerOf[tokenId_].timestamp = 0;
    }

    // // internal write functions
    // mint
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0x0), "ERC721I: _mint() Mint to Zero Address");
        require(ownerOf(tokenId_) == address(0x0), "ERC721I: _mint() Token to Mint Already Exists!");

        balanceOf[to_]++;
        _ownerOf[tokenId_].owner = to_;

        emit Transfer(address(0x0), to_, tokenId_);
    }

    // transfer
    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        require(from_ == ownerOf(tokenId_), "ERC721I: _transfer() Transfer Not Owner of Token!");
        require(to_ != address(0x0), "ERC721I: _transfer() Transfer to Zero Address!");

        if (getApproved[tokenId_] != address(0x0)) { 
            _approve(address(0x0), tokenId_); 
        } 

        _ownerOf[tokenId_].owner = to_; 
        balanceOf[from_]--;
        balanceOf[to_]++;

        emit Transfer(from_, to_, tokenId_);
    }

    // approve
    function _approve(address to_, uint256 tokenId_) internal virtual {
        if (getApproved[tokenId_] != to_) {
            getApproved[tokenId_] = to_;
            emit Approval(ownerOf(tokenId_), to_, tokenId_);
        }
    }
    function _setApprovalForAll(address owner_, address operator_, bool approved_) internal virtual {
        require(owner_ != operator_, "ERC721I: _setApprovalForAll() Owner must not be the Operator!");
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
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }

    // Functional Views
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view virtual returns (bool) {
        require(ownerOf(tokenId_) != address(0x0), "ERC721I: _isApprovedOrOwner() Owner is Zero Address!");
        address _owner = ownerOf(tokenId_);
        return (spender_ == _owner || spender_ == getApproved[tokenId_] || isApprovedForAll[_owner][spender_]);
    }
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return ownerOf(tokenId_) != address(0x0);
    }

    // // public write functions
    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(to_ != _owner, "ERC721I: approve() Cannot approve yourself!");
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender], "ERC721I: Caller not owner or Approved!");
        _approve(to_, tokenId_);
    }
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }
    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721I: transferFrom() _isApprovedOrOwner = false!");
        require(!isStaked(tokenId_), "ERC721I: transferFrom() Token is staked!");
        _transfer(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.staticcall(abi.encodeWithSelector(0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02, "ERC721I: safeTransferFrom() to_ not ERC721Receivable!");
        }
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    // 0xInuarashi Custom Functions
    function multiTransferFrom(address from_, address to_, uint256[] memory tokenIds_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            transferFrom(from_, to_, tokenIds_[i]);
        }
    }
    function multiSafeTransferFrom(address from_, address to_, uint256[] memory tokenIds_, bytes memory data_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            safeTransferFrom(from_, to_, tokenIds_[i], data_);
        }
    }

    // OZ Standard Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }

    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        require(ownerOf(tokenId_) != address(0x0), "ERC721I: tokenURI() Token does not exist!");
        return string(abi.encodePacked(baseTokenURI, _toString(tokenId_), baseTokenURI_EXT));
    }

    function tokenIdStartsAt() public virtual view returns (uint256) {
        uint256 _loopThrough = totalSupply;
        uint256 _tokenIdStartAt;

        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf(i) != address(0x0)) { _tokenIdStartAt = i; break; }
        }

        return _tokenIdStartAt;        
    }

    function balanceOfStaked(address address_) public virtual view returns (uint256) {
        uint256 _balance;
        uint256 _loopThrough = totalSupply;
        uint256 _tokenIdStartAt = tokenIdStartsAt();

        for (uint256 i = _tokenIdStartAt; i <= _loopThrough + _tokenIdStartAt; i++) {
            if (_ownerOf[i].owner == address_ && isStaked(i)) {
                _balance++;
            }
        }

        return _balance;
    }
    function balanceOfUnstaked(address address_) public virtual view 
    returns (uint256) {
        uint256 _balance;
        uint256 _loopThrough = totalSupply;
        uint256 _tokenIdStartAt = tokenIdStartsAt();

        for (uint256 i = _tokenIdStartAt; i <= _loopThrough + _tokenIdStartAt; i++) {
            if (_ownerOf[i].owner == address_ && !isStaked(i)) {
                _balance++;
            }
        }

        return _balance;
    }

    // // public view functions
    // never use these for functions ever, they are expensive af and for view only (this will be an issue in the future for interfaces)
    function walletOfOwner(address address_) public virtual view 
    returns (uint256[] memory) {
        uint256 _balance = balanceOf[address_];
        if (_balance == 0) return new uint256[](0);

        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf(i) == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++; 
            }
            if (_ownerOf[i].owner == address_) { 
                _tokens[_index] = i; _index++; 
            }
        }
        return _tokens;
    }

    function walletOfOwnerUnstaked(address address_) public virtual view 
    returns (uint256[] memory) {
        uint256 _balance = balanceOfUnstaked(address_);
        if (_balance == 0) return new uint256[](0);

        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf(i) == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++; 
            }
            if (_ownerOf[i].owner == address_ && !isStaked(i)) { 
                _tokens[_index] = i; _index++; 
            }
        }
        return _tokens;
    }

    function walletOfOwnerStaked(address address_) public virtual view 
    returns (uint256[] memory) {
        uint256 _balance = balanceOfStaked(address_);
        if (_balance == 0) return new uint256[](0);

        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf(i) == address(0x0) && _tokens[_balance - 1] == 0) { 
                _loopThrough++; 
            }
            // if (ownerOf(i) == address_) { _tokens[_index] = i; _index++; }
            if (_ownerOf[i].owner == address_ && isStaked(i)) { 
                _tokens[_index] = i; _index++; 
            }
        }
        return _tokens;
    }

    // so not sure when this will ever be really needed but it conforms to erc721 enumerable
    function tokenOfOwnerByIndex(address address_, uint256 index_) public virtual view returns (uint256) {
        uint256[] memory _wallet = walletOfOwner(address_);
        return _wallet[index_];
    }
}

/*
    administrative functions marked as internal because you should have
    owner access in order to use them. so, write them in your contract yourself!
*/

abstract contract MerkleWhitelist {
    bytes32 internal _merkleRoot = 0xa67a6c6810aaf3dec2d76d522ab50128c8a08e7e5574456aa3c4b0c6f3eb9732;
    function _setMerkleRoot(bytes32 merkleRoot_) internal virtual {
        _merkleRoot = merkleRoot_;
    }
    function isWhitelisted(address address_, bytes32[] memory proof_) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i] ? keccak256(abi.encodePacked(_leaf, proof_[i])) 
                : keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == _merkleRoot;
    }
}

// Open0x Ownable (by 0xInuarashi)
abstract contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed oldOwner_, address indexed newOwner_);
    constructor() { owner = msg.sender; }
    modifier onlyOwner {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function _transferOwnership(address newOwner_) internal virtual {
        address _oldOwner = owner;
        owner = newOwner_;
        emit OwnershipTransferred(_oldOwner, newOwner_);    
    }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        require(newOwner_ != address(0x0), "Ownable: new owner is the zero address!");
        _transferOwnership(newOwner_);
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0x0));
    }
}


// Open0x Payable Governance Module by 0xInuarashi
// This abstract contract utilizes for loops in order to iterate things in order to be modular
// It is not the most gas-effective implementation. 
// We sacrified gas-effectiveness for Modularity instead.
abstract contract PayableGovernance is Ownable {
    // Special Access
    address _payableGovernanceSetter;
    constructor() payable { _payableGovernanceSetter = msg.sender; }
    modifier onlyPayableGovernanceSetter {
        require(msg.sender == _payableGovernanceSetter, "PayableGovernance: Caller is not Setter!"); _; }
    function reouncePayableGovernancePermissions() public onlyPayableGovernanceSetter {
        _payableGovernanceSetter = address(0x0); }

    // Receivable Fallback
    event Received(address from, uint amount);
    receive() external payable { emit Received(msg.sender, msg.value); }

    // Required Variables
    address payable[] internal _payableGovernanceAddresses;
    uint256[] internal _payableGovernanceShares;    
    mapping(address => bool) public addressToEmergencyUnlocked;

    // Withdraw Functionality
    function _withdraw(address payable address_, uint256 amount_) internal {
        (bool success, ) = payable(address_).call{value: amount_}("");
        require(success, "Transfer failed");
    }

    // Governance Functions
    function setPayableGovernanceShareholders(address payable[] memory addresses_, uint256[] memory shares_) public onlyPayableGovernanceSetter {
        require(_payableGovernanceAddresses.length == 0 && _payableGovernanceShares.length == 0, "Payable Governance already set! To set again, reset first!");
        require(addresses_.length == shares_.length, "Address and Shares length mismatch!");
        uint256 _totalShares;
        for (uint256 i = 0; i < addresses_.length; i++) {
            _totalShares += shares_[i];
            _payableGovernanceAddresses.push(addresses_[i]);
            _payableGovernanceShares.push(shares_[i]);
        }
        require(_totalShares == 1000, "Total Shares is not 1000!");
    }
    function resetPayableGovernanceShareholders() public onlyPayableGovernanceSetter {
        while (_payableGovernanceAddresses.length != 0) {
            _payableGovernanceAddresses.pop(); }
        while (_payableGovernanceShares.length != 0) {
            _payableGovernanceShares.pop(); }
    }

    // Governance View Functions
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
    function payableGovernanceAddresses() public view returns (address payable[] memory) {
        return _payableGovernanceAddresses;
    }
    function payableGovernanceShares() public view returns (uint256[] memory) {
        return _payableGovernanceShares;
    }

    // Withdraw Functions
    function withdrawEther() public onlyOwner {
        // require that there has been payable governance set.
        require(_payableGovernanceAddresses.length > 0 && _payableGovernanceShares.length > 0, "Payable governance not set yet!");
         // this should never happen
        require(_payableGovernanceAddresses.length == _payableGovernanceShares.length, "Payable governance length mismatch!");
        
        // now, we check that the governance shares equal to 1000.
        uint256 _totalPayableShares;
        for (uint256 i = 0; i < _payableGovernanceShares.length; i++) {
            _totalPayableShares += _payableGovernanceShares[i]; }
        require(_totalPayableShares == 1000, "Payable Governance Shares is not 1000!");
        
        // // now, we start the withdrawal process if all conditionals pass
        // store current balance in local memory
        uint256 _totalETH = address(this).balance; 

        // withdraw loop for payable governance
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            uint256 _ethToWithdraw = ((_totalETH * _payableGovernanceShares[i]) / 1000);
            _withdraw(_payableGovernanceAddresses[i], _ethToWithdraw);
        }
    }

    function viewWithdrawAmounts() public view onlyOwner returns (uint256[] memory) {
        // require that there has been payable governance set.
        require(_payableGovernanceAddresses.length > 0 && _payableGovernanceShares.length > 0, "Payable governance not set yet!");
         // this should never happen
        require(_payableGovernanceAddresses.length == _payableGovernanceShares.length, "Payable governance length mismatch!");
        
        // now, we check that the governance shares equal to 1000.
        uint256 _totalPayableShares;
        for (uint256 i = 0; i < _payableGovernanceShares.length; i++) {
            _totalPayableShares += _payableGovernanceShares[i]; }
        require(_totalPayableShares == 1000, "Payable Governance Shares is not 1000!");
        
        // // now, we start the array creation process if all conditionals pass
        // store current balance in local memory and instantiate array for input
        uint256 _totalETH = address(this).balance; 
        uint256[] memory _withdrawals = new uint256[] (_payableGovernanceAddresses.length + 2);

        // array creation loop for payable governance values 
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            _withdrawals[i] = ( (_totalETH * _payableGovernanceShares[i]) / 1000 );
        }
        
        // push two last array spots as total eth and added eths of withdrawals
        _withdrawals[_payableGovernanceAddresses.length] = _totalETH;
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            _withdrawals[_payableGovernanceAddresses.length + 1] += _withdrawals[i]; }

        // return the final array data
        return _withdrawals;
    }

    // Shareholder Governance
    modifier onlyShareholder {
        bool _isShareholder;
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            if (msg.sender == _payableGovernanceAddresses[i]) {
                _isShareholder = true;
            }
        }
        require(_isShareholder, "You are not a shareholder!");
        _;
    }
    function unlockEmergencyFunctionsAsShareholder() public onlyShareholder {
        addressToEmergencyUnlocked[msg.sender] = true;
    }

    // Emergency Functions
    modifier onlyEmergency {
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            require(addressToEmergencyUnlocked[_payableGovernanceAddresses[i]], "Emergency Functions are not unlocked!");
        }
        _;
    }
    function emergencyWithdrawEther() public onlyOwner onlyEmergency {
        _withdraw(payable(msg.sender), address(this).balance);
    }
}

// Open0x Security by 0xInuarashi
abstract contract Security {
    // Prevent Smart Contracts
    modifier onlySender {
        require(msg.sender == tx.origin, "No Smart Contracts!"); _; }
}

abstract contract WhitelistMint {
    // Whitelist Minting
    bool internal _whitelistMintEnabled; uint256 public _whitelistMintTime;
    function _setWhitelistMint(bool bool_, uint256 time_) internal {
        _whitelistMintEnabled = bool_; _whitelistMintTime = time_; }
    modifier whitelistMintEnabled {
        require(_whitelistMintEnabled && _whitelistMintTime <= block.timestamp, 
            "Whitelist Mint is not enabled yet!"); _; } 
    function whitelistMintStatus() external view returns (bool) {
        return _whitelistMintEnabled && _whitelistMintTime <= block.timestamp; }
}

abstract contract PublicMint {
    // Public Minting
    bool public _publicMintEnabled; uint256 public _publicMintTime;
    function _setPublicMint(bool bool_, uint256 time_) internal {
        _publicMintEnabled = bool_; _publicMintTime = time_; }
    modifier publicMintEnabled { 
        require(_publicMintEnabled && _publicMintTime <= block.timestamp, 
            "Public Mint is not enabled yet!"); _; }
    function publicMintStatus() external view returns (bool) {
        return _publicMintEnabled && _publicMintTime <= block.timestamp; }
}

interface isCT {
    function mintStakedTokenAsCyberTurtles(address to_, uint256 tokenId_) external;
}

contract CyberTurtles is ERC721IM, MerkleWhitelist, Ownable, PayableGovernance,
Security, WhitelistMint, PublicMint {
    constructor() payable ERC721IM("CyberTurtles", "CYBERT") {}

    /*
        CyberTurtles 
        Staking with Proof-of-Stake-Token Phantom Minting
        Yield $SHELL
        Whitelist Mint (MerkleWhitelist)
        Public Mint
    */

    ////// Project Contraints //////
    uint256 public maxTokens = 5555; 
    uint256 public mintPrice = 0.07 ether; 
    uint256 public maxMintsPerTx = 10;

    uint256 public maxMintsPerWl = 2;
    mapping(address => uint256) public addressToWlMints;

    ///// Interfaces /////
    isCT public sCT;
    function setsCT(address address_) external onlyOwner {
        sCT = isCT(address_);
    }
    modifier onlyStaker {
        require(msg.sender == address(sCT), "You are not staker!"); _;
    }

    ///// Ownable /////
    // Constraints
    function setMaxTokens(uint256 maxTokens_) external onlyOwner {
        maxTokens = maxTokens_;
    }
    function setMintPrice(uint256 mintPrice_) external onlyOwner {
        mintPrice = mintPrice_;
    }

    function setMaxMintsPerTx(uint256 maxMints_) external onlyOwner {
        maxMintsPerTx = maxMints_;
    }
    function setMaxMintsPerWl(uint256 maxMints_) external onlyOwner {
        maxMintsPerWl = maxMints_;
    }

    // Token URI
    function setBaseTokenURI(string calldata uri_) external onlyOwner { 
        _setBaseTokenURI(uri_);
    }
    function setBaseTokenURI_EXT(string calldata ext_) external onlyOwner {
        _setBaseTokenURI_EXT(ext_);
    }

    // MerkleRoot
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        _setMerkleRoot(merkleRoot_);
    }

    // Public Mint
    function setPublicMint(bool bool_, uint256 time_) external onlyOwner {
        _setPublicMint(bool_, time_);
    }
    
    // Whitelist Mint
    function setWhitelistMint(bool bool_, uint256 time_) external onlyOwner {
        _setWhitelistMint(bool_, time_);
    }

    // (Withdrawals Handled by PayableGovernance)

    ///// OwnerOf Override /////
    function ownerOf(uint256 tokenId_) public view override returns (address) {
        if (_ownerOf[tokenId_].timestamp == 0) {
            return _ownerOf[tokenId_].owner;
        } else {
            return address(sCT);
        }
    }

    // OG Functionality
    bytes32 internal _merkleRootOG = 0x29480e5ce297f9137e60d028b74252fa6019a4334d601f58b2bb4d07cc5c2b55;
    function setMerkleRootOG(bytes32 merkleRoot_) external onlyOwner {
        _merkleRootOG = merkleRoot_;
    }
    function isOG(address address_, bytes32[] memory proof_) 
    public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i] ? keccak256(abi.encodePacked(_leaf, proof_[i])) 
                : keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == _merkleRootOG;
    }
    mapping(address => uint256) public addressToOgMinted;

    ///// Internal Mint /////
    function _mintMany(address to_, uint256 amount_) internal {
        require(maxTokens >= totalSupply + amount_,
            "Not enough tokens remaining!");
            
        uint256 _startId = totalSupply + 1; // iterate from 1

        for (uint256 i = 0; i < amount_; i++) {
            _mint(to_, _startId + i);
        }
        totalSupply += amount_;
    }
    function _mintAndStakeMany(address to_, uint256 amount_) internal {
        require(maxTokens >= totalSupply + amount_,
            "Not enough tokens remaining!");
        
        uint256 _startId = totalSupply + 1; // iterate from 1

        for (uint256 i = 0; i < amount_; i++) {
            _mint(to_, _startId + i);
            _stake(_startId + i);
            
            emit Transfer(to_, address(sCT), _startId + i);
            sCT.mintStakedTokenAsCyberTurtles(to_, _startId + i);
        }
        totalSupply += amount_;
    }

    ///// Magic Stake Code /////
    // Turtle Staker / Unstaker -- The validation logic is handled by sCyberTurtles
    function validateOwnershipOfTokens(address owner_, uint256[] calldata tokenIds_)
    external view returns (bool) {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if (owner_ != ownerOf(tokenIds_[i])) return false;
        }
        return true;
    }
    function validateOwnershipOfStakedTokens(address owner_,
    uint256[] calldata tokenIds_) external view returns (bool) {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            ownerAndStake memory _ownerAndStake = _ownerOf[tokenIds_[i]];
            if (owner_ != _ownerAndStake.owner 
                || _ownerAndStake.timestamp == 0) return false;
        }
        return true;
    }
    
    function stakeTurtles(uint256[] calldata tokenIds_) external onlyStaker {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _stake(tokenIds_[i]);
            emit Transfer(ownerOf(tokenIds_[i]), address(sCT), tokenIds_[i]);
        }
    }
    function updateTurtles(uint256[] calldata tokenIds_) external onlyStaker {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _update(tokenIds_[i]);
        }
    }
    function unstakeTurtles(uint256[] calldata tokenIds_) external onlyStaker {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _unstake(tokenIds_[i]);
            emit Transfer(address(sCT), _ownerOf[tokenIds_[i]].owner, tokenIds_[i]);
        }
    }

    ///// Minting Functions /////
    function ownerMint(address[] calldata tos_, uint256[] calldata amounts_,
    bool stakeOnMint_) external onlyOwner {
        require(tos_.length == amounts_.length,
            "Array lengths mismatch!");
            
        if (stakeOnMint_) {
            for (uint256 i = 0; i < tos_.length; i++) {
                _mintAndStakeMany(tos_[i], amounts_[i]);
            }
        } else {
            for (uint256 i = 0; i < tos_.length; i++) {
                _mintMany(tos_[i], amounts_[i]);
            }
        }
    }

    // OG Claim Function (we reused whitelistMint modifier)
    function ogClaim(bytes32[] calldata proof_, bool stakeOnMint_) 
    public onlySender whitelistMintEnabled {
        require(isOG(msg.sender, proof_),
            "You are not OG!");
        require(addressToOgMinted[msg.sender] == 0, 
            "You have already minted!");

        addressToOgMinted[msg.sender]++;

        if (stakeOnMint_) {
            _mintAndStakeMany(msg.sender, 1);
        } else {
            _mintMany(msg.sender, 1);
        }
    }

    // Whitelist Mint Functions
    function whitelistMint(bytes32[] calldata proof_, uint256 amount_,
    bool stakeOnMint_) public payable onlySender whitelistMintEnabled {
        require(isWhitelisted(msg.sender, proof_),
            "You are not whitelisted!");
        require(maxMintsPerWl >= addressToWlMints[msg.sender] + amount_,
            "You dont have enough whitelist mints!");
        require(msg.value == mintPrice * amount_,
            "Invalid value sent!");
        
        // Add address to WL minted
        addressToWlMints[msg.sender] += amount_;

        if (stakeOnMint_) {
            _mintAndStakeMany(msg.sender, amount_);
        } else {
            _mintMany(msg.sender, amount_);
        }
    }

    // Public Mint Functions
    function publicMint(uint256 amount_, bool stakeOnMint_) external payable
    onlySender publicMintEnabled {
        require(maxMintsPerTx >= amount_,
            "Over maximum mints per TX!");
        require(msg.value == mintPrice * amount_,
            "Invalid value sent!");
        
        if (stakeOnMint_) {
            _mintAndStakeMany(msg.sender, amount_);
        } else {
            _mintMany(msg.sender, amount_);
        }
    }
}