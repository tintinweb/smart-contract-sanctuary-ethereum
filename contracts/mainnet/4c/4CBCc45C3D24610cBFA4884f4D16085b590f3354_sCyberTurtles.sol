/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

interface iCT {

    struct ownerAndStake {
        address owner;
        uint40 timestamp;
    }
    
    function totalSupply() external view returns (uint256);
    function _ownerOf(uint256 tokenId_) external view returns (ownerAndStake memory);
    function ownerOf(uint256 tokenId_) external view returns (address);
    function isStaked(uint256 tokenId_) external view returns (bool);
    function tokenIdStartsAt() external view returns (uint256);

    function validateOwnershipOfTokens(address owner_, uint256[] calldata tokenIds_) 
    external view returns (bool);
    function validateOwnershipOfStakedTokens(address owner_,
    uint256[] calldata tokenIds_) external view returns (bool);

    function stakeTurtles(uint256[] calldata tokenIds_) external;
    function updateTurtles(uint256[] calldata tokenIds_) external;
    function unstakeTurtles(uint256[] calldata tokenIds_) external;

    function tokenURI(uint256 tokenId_) external view returns (string memory);
}

interface iShell {
    function mint(address to_, uint256 amount_) external;
}

// This is a proof-of-stake (token represents stake) contract
// Custom made with love by 0xInuarashi.eth
contract sCyberTurtles is Ownable {
    string public name = "Staked Cyber Turtles";
    string public symbol = "sCyber";

    // We largely interface with CyberTurtles
    iCT public CT = iCT(0x81BC389D02c3054649643E590ce57fAAAB3BF38B); // note: change
    function setCT(address address_) external onlyOwner {
        CT = iCT(address_);
    }

    iShell public SHELL = iShell(0x81BC389D02c3054649643E590ce57fAAAB3BF38B); // note: c
    function setShell(address address_) external onlyOwner {
        SHELL = iShell(address_);
    }

    // Yield Info
    uint256 public yieldStartTime = 1643670000; // 2021-01-31_18-00_EST
    uint256 public yieldEndTime = 1959202800; // 10 years
    uint256 public yieldRate = 100 ether;

    // Magic Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    // Magic Logic
    function totalSupply() public view returns (uint256) {
        uint256 _totalSupply;
        uint256 _startId = CT.tokenIdStartsAt();
        for (uint256 i = _startId; i <= CT.totalSupply() + _startId; i++) {
            if (CT.isStaked(i)) { _totalSupply++; }
        }
        return _totalSupply;
    }

    function ownerOf(uint256 tokenId_) public view returns (address) {
        iCT.ownerAndStake memory _ownerAndStake = CT._ownerOf(tokenId_);
        address _owner = _ownerAndStake.timestamp > 0 ?
             _ownerAndStake.owner : address(0);
        return _owner;
    }

    function balanceOf(address address_) public view returns (uint256) {
        uint256 _startId = CT.tokenIdStartsAt();
        uint256 _balance;
        for (uint256 i = _startId; i <= CT.totalSupply() + _startId; i++) {
            if (ownerOf(i) == address_) { _balance++; }
        }
        return _balance;
    }

    // Internal Claim Function
    function _getPendingTokens(uint256 tokenId_) internal view returns (uint256) {
        uint256 _timestamp = uint256(CT._ownerOf(tokenId_).timestamp);
        if (_timestamp == 0 || _timestamp > yieldEndTime) return 0;

        uint256 _timeCurrentOrEnded = yieldEndTime > block.timestamp ? 
            block.timestamp : yieldEndTime;
        uint256 _timeElapsed = _timeCurrentOrEnded - _timestamp;

        return (_timeElapsed * yieldRate) / 1 days;
    }
    function _getPendingTokensMany(uint256[] memory tokenIds_) internal view
    returns (uint256) {
        uint256 _pendingTokens;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _pendingTokens += _getPendingTokens(tokenIds_[i]);
        }
        return _pendingTokens;
    }

    function getPendingTokens(uint256 tokenId_) public view returns (uint256) {
        return _getPendingTokens(tokenId_);
    }
    function getPendingTokensMany(uint256[] calldata tokenIds_) public view 
    returns (uint256) {
        return _getPendingTokensMany(tokenIds_);
    }
    function getPendingTokensOfAddress(address address_) public view 
    returns (uint256) {
        uint256[] memory _tokensOfAddress = walletOfOwner(address_);
        return _getPendingTokensMany(_tokensOfAddress);
    }

    function _claim(address to_, uint256[] memory tokenIds_) internal {
        uint256 _pendingTokens;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _pendingTokens += _getPendingTokens(tokenIds_[i]);
        }
        SHELL.mint(to_, _pendingTokens);
    }

    function claim(uint256[] calldata tokenIds_) external {
        require(CT.validateOwnershipOfStakedTokens(msg.sender, tokenIds_),
            "You are not the owner or token is unstaked!");

        _claim(msg.sender, tokenIds_);
        CT.updateTurtles(tokenIds_); // This updates the timestamp
    }
    function stakeTurtles(uint256[] calldata tokenIds_) external {
        require(CT.validateOwnershipOfTokens(msg.sender, tokenIds_),
            "You are not the owner or token is already staked!");

        CT.stakeTurtles(tokenIds_); // Set timestamp to block.timestamp

        for (uint256 i = 0; i < tokenIds_.length; i++) {
            emit Transfer(address(0), msg.sender, tokenIds_[i]); // Mint sToken
        }
    }   
    function unstakeTurtles(uint256[] calldata tokenIds_) external {
        require(CT.validateOwnershipOfStakedTokens(msg.sender, tokenIds_),
            "You are not the owner or token is unstaked!");

        _claim(msg.sender, tokenIds_);
        CT.unstakeTurtles(tokenIds_); // Set timestamp to 0

        for (uint256 i = 0; i < tokenIds_.length; i++) {
            emit Transfer(msg.sender, address(0), tokenIds_[i]); // Burn sToken
        }
    }

    function mintStakedTokenAsCyberTurtles(address to_, uint256 tokenId_) external {
        require(msg.sender == address(CT), "You are not CT!");
        emit Transfer(address(0), to_, tokenId_);
    }

    function walletOfOwner(address address_) public virtual view 
    returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        if (_balance == 0) return new uint256[](0);

        uint256[] memory _tokens = new uint256[] (_balance);
        uint256 _index;
        uint256 _loopThrough = CT.totalSupply() + 1;
        for (uint256 i = 0; i < _loopThrough; i++) {
            if (ownerOf(i) == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++; 
            }
            if (ownerOf(i) == address_) { 
                _tokens[_index] = i; _index++; 
            }
        }
        return _tokens;
    }

    // TokenURI Stuff
    string internal baseTokenURI; string internal baseTokenURI_EXT;
    function _toString(uint256 value_) internal pure returns (string memory) {
        if (value_ == 0) { return "0"; }
        uint256 _iterate = value_; uint256 _digits;
        while (_iterate != 0) { _digits++; _iterate /= 10; } // get digits in value_
        bytes memory _buffer = new bytes(_digits);
        while (value_ != 0) { _digits--; _buffer[_digits] = bytes1(uint8(
            48 + uint256(value_ % 10 ))); value_ /= 10; } // create bytes of value_
        return string(_buffer); // return string converted bytes of value_
    }
    function setBaseTokenURI(string memory uri_) external onlyOwner {
        baseTokenURI = uri_;
    }
    function setBaseTokenURI_EXT(string memory ext_) external onlyOwner {
        baseTokenURI_EXT = ext_;
    }
    function tokenURI(uint256 tokenId_) public view virtual returns (string memory) {
        require(ownerOf(tokenId_) != address(0), 
            "ERC721I: tokenURI() Token does not exist!");

        return string(abi.encodePacked(baseTokenURI, 
            _toString(tokenId_), baseTokenURI_EXT));
    }

    // OZ ERC721 Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }
}