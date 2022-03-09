// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Crypto Barter - All rights reserved
// cryptobarter.io
// @title StakedShare
// @notice Provides functions to stake ERC20 and get NFT in order to claim passive income
// @author Anibal Catalan <[email protected]>

pragma solidity = 0.8.9;

import "./NFT.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";

//solhint-disable-line
contract StakedShare is NFT, ReentrancyGuard {

    //Max Loked Period;
    //uint32 internal constant MAX_LOKED_TIME = 60 * 60 * 24 * 365; // 1 year
    uint32 internal constant MAX_LOKED_TIME = 60 * 3; // 3 minutes

    //Min Locked Period;
    //uint32 internal constant MIN_LOKED_TIME = 60 * 60 * 24 * 7; // 1 week
    uint32 internal constant MIN_LOKED_TIME = 30; // 30 sec

    //ERC20 Project Token
    address internal _projectToken;

    // Project Loco
    string internal _logo;

    struct RSToken {
        uint64 created;
        uint64 locked;
        uint128 amount;   
    }
    // token id ==> token parameters
    mapping(uint256 => RSToken) public revToken; 

    // token id as counter
    uint256 public rsId;

    //total amount staked;
    uint256 internal tlv;

    constructor() {}

    // Initializer
    function initialize(address projectToken_, string memory name, string memory symbol, string memory logo_) external {   
        require(!initialized, "contract already initialized");
        NFT(address(this)).initialize(name, symbol);
        _projectToken = projectToken_;
        _logo = logo_;
        _name = name;
        _symbol = symbol;
    }

    // Main Functions

    function stake(uint128 amount, uint128 lock) external virtual nonReentrant isInitialized {
        require(amount > 0, "you should send something");
        uint64 lockedTime = uint32(lock) * MIN_LOKED_TIME;
        require(lockedTime <= MAX_LOKED_TIME, "you should lock less than 1 year");
        require(IERC20(_projectToken).allowance(msg.sender, address(this)) >= uint256(amount), "token not allowed");
        
        require(_transferFrom(msg.sender, amount), "transfer from fails");
        rsId = ++rsId;
        _safeMint(msg.sender, rsId, "new revenue share token");
        revToken[rsId] = RSToken({created: uint64(block.timestamp), locked: uint64(lockedTime), amount: amount});
        tlv += amount;
        emit Staked(msg.sender, amount, rsId);
    }

    function withdraw(uint256 tokenId) external virtual nonReentrant isInitialized {
        require(ownerOf(tokenId) == msg.sender, "you are not the owner of the token");
        RSToken memory rs = revToken[tokenId];
        uint256 lockedTime = uint256(rs.created + rs.locked);
        require(block.timestamp >= lockedTime, "your token it is locked");
        
        _burn(tokenId);
        delete revToken[tokenId];
        require(_transferToken(msg.sender, uint256(rs.amount)), "transfer reward token fail");
        tlv -= rs.amount;
        emit Withdrawn(msg.sender, rs.amount, tokenId);
    }

    function increaseStake(uint256 tokenId, uint128 amount) external virtual nonReentrant isInitialized {
        require(amount > 0, "you should send something");
        require(ownerOf(tokenId) == msg.sender, "you are not the owner of the token");
        require(IERC20(_projectToken).allowance(msg.sender, address(this)) >= uint256(amount), "token not allowed");
        
        require(_transferFrom(msg.sender, amount), "transfer from fails");
        RSToken memory rs = revToken[tokenId];
        rs.amount += amount;
        emit IncreaseStaked(msg.sender, rs.amount, tokenId);
    }

    function increaseTime(uint256 tokenId, uint128 lock) external virtual nonReentrant isInitialized {
        require(lock > 0, "you should send something");
        require(ownerOf(tokenId) == msg.sender, "you are not the owner of the token");
        RSToken memory rs = revToken[tokenId];
        uint64 lockedTime = (uint32(lock) * MIN_LOKED_TIME) + rs.locked;
        require(lockedTime <= MAX_LOKED_TIME, "you should lock less than 1 year");

        rs.locked = lockedTime;
        emit IncreaseTime(msg.sender, rs.locked, tokenId);
    }

    function redeem(uint256 tokenId, uint128 amount) external virtual nonReentrant isInitialized {
        require(amount > 0, "you should send something");
        require(ownerOf(tokenId) == msg.sender, "you are not the owner of the token");
        RSToken memory rs = revToken[tokenId];
        require(amount <= rs.amount, "do not have enough amount staked");
        uint64 lockedTime = rs.created + rs.locked;
        uint64 currentTime = uint64(block.timestamp);
        require(currentTime < lockedTime, "you can do regular withdraw");

        uint128 taxPercentage = (currentTime * 10000)/lockedTime;
        uint128 tax = (amount * taxPercentage) /10000;
        rs.amount -= amount;
        require(_transferToken(msg.sender, (amount - tax)), "transfer reward token fail");

        if (rs.amount == 0) {
            _burn(tokenId);
            delete revToken[tokenId];
        }

        tlv -= amount;
        emit Redeemed(msg.sender, amount, tax);
    }


    // Getters

    function totalVolumenLoad() public view virtual isInitialized returns (uint256) {
        return tlv;
    }

    function projectToken() public view virtual isInitialized returns (address) {
        return _projectToken;
    }

    function logo() public view virtual isInitialized returns (string memory) {
        return _logo;
    }

    function rsToken(uint256 tokenId) public view virtual isInitialized returns (uint64, uint64, uint128) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        RSToken memory rs = revToken[tokenId];
        return (rs.created, rs.locked, rs.amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override isInitialized returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        RSToken memory rs = revToken[tokenId];
        return
        _tokenURI(
            tokenId,
            rs.amount,
            rs.created,
            rs.locked
        );
    }

    // Internal Functions

    function _tokenURI(uint256 _tokenId, uint128 _amount, uint64 _created, uint64 _locked) internal pure returns (string memory output) {
        output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        output = string(abi.encodePacked(output, "token: ", toString(_tokenId), '</text><text x="10" y="40" class="base">'));
        output = string(abi.encodePacked(output, "amount: ", toString(uint256(_amount)), '</text><text x="10" y="60" class="base">'));
        output = string(abi.encodePacked(output, "created_time: ", toString(uint256(_created)), '</text><text x="10" y="80" class="base">'));
        output = string(abi.encodePacked(output, "locked_time: ", toString(uint256(_locked)), '</text></svg>'));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "lock #', toString(_tokenId), '", "description": "NFT Revenue share, can be used to receive passive income", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    function _transferFrom(address from, uint256 amount) internal virtual returns (bool) {
        require(from != address(0), "must be valid address");
        require(amount > 0, "you must send something");
        SafeERC20.safeTransferFrom(IERC20(_projectToken), from, address(this), amount);
        return true;
    }

    function _transferToken(address to, uint256 amount) internal virtual returns (bool) {
        require(to != address(0), "must be valid address");
        require(amount > 0, "you must send something");
        SafeERC20.safeTransfer(IERC20(_projectToken), to, amount);
        return true;
    }

    // Events

    event Staked(address indexed staker, uint128 indexed amount, uint256 indexed NFTId);
    event Withdrawn(address indexed withdrawer, uint128 indexed amount, uint256 indexed NFTId);
    event IncreaseStaked(address indexed staker, uint128 indexed amount, uint256 indexed NFTId);
    event IncreaseTime(address indexed staker, uint64 indexed time, uint256 indexed NFTId);
    event Redeemed(address indexed staker, uint128 indexed amount, uint128 tax);

}