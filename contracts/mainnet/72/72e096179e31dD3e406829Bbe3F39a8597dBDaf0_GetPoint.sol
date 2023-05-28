/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// OwnControll by 0xSumo
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

interface IPoint {
    function getPoints(address address_, uint256 amount_) external;
}

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function balanceOf(address address_) external view returns (uint256);
}

contract GetPoint is OwnControll {

    IERC721 public ERC721NTP = IERC721(0xA65bA71d653f62c64d97099b58D25a955Eb374a0);
    IERC721 public ERC721ROARS = IERC721(0x066b62EA211249925800eD8676f69eD506175714);
    IPoint public Point = IPoint(0x12f02f11661b0dd843101Da1F63708aaB157696F);

    uint256 public yieldStartTime = 1685275200; //28/05/2023 9pm JST
    uint256 public yieldEndTime = 2000894400; //28/05/2033 9pm JST (changable)

    uint256 public yieldRatePerPointNTP = 20;
    uint256 public yieldRatePerPointROARS = 1;

    mapping(address => mapping(uint256 => uint256)) public tokenToLastClaimedTimestamp;
    event Claim(address to_, uint256[] tokenIds_, uint256 totalClaimed_);

    /// owner setting
    function setPoint(address address_) external onlyOwner { Point = IPoint(address_); }
    function setERC721NTP(address address_) external onlyOwner { ERC721NTP = IERC721(address_); }
    function setERC721ROARS(address address_) external onlyOwner { ERC721ROARS = IERC721(address_); }
    function setYieldEndTime(uint256 yieldEndTime_) external onlyOwner { yieldEndTime = yieldEndTime_; }
    function setYieldRatePerPoint(uint256 yieldRatePerPointNTP_) external onlyOwner { yieldRatePerPointNTP = yieldRatePerPointNTP_; }
    function setYieldRatePerPointROARS(uint256 yieldRatePerPointROARS_) external onlyOwner { yieldRatePerPointROARS = yieldRatePerPointROARS_; }

    /// point claim
    function claimByCollection(address contractAddress, uint256[] calldata tokenIds_) external {
        IERC721 ERC721 = contractAddress == address(ERC721NTP) ? ERC721NTP : ERC721ROARS;
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(msg.sender == ERC721.ownerOf(tokenIds_[i]), "You are not the owner!");
        }
        uint256 _pendingPoints = getPendingPointsMany(contractAddress, tokenIds_);
        _updateTimestampOfPoints(contractAddress, tokenIds_);
        Point.getPoints(msg.sender, _pendingPoints);
        emit Claim(msg.sender, tokenIds_, _pendingPoints);
    }

    function claimAll(uint256[] calldata tokenIdsNTP, uint256[] calldata tokenIdsROARS) external {
        uint256 l = tokenIdsNTP.length;
        uint256 g = tokenIdsROARS.length;
        for (uint256 i = 0; i < l; i++) {
            require(msg.sender == ERC721NTP.ownerOf(tokenIdsNTP[i]), "You are not the owner of NTP tokenId!");
        }
        for (uint256 q = 0; q < g; q++) {
            require(msg.sender == ERC721ROARS.ownerOf(tokenIdsROARS[q]), "You are not the owner of ROARS tokenId!");
        }
        uint256 _pendingPointsNTP = getPendingPointsMany(address(ERC721NTP), tokenIdsNTP);
        uint256 _pendingPointsROARS = getPendingPointsMany(address(ERC721ROARS), tokenIdsROARS);
        _updateTimestampOfPoints(address(ERC721NTP), tokenIdsNTP);
        _updateTimestampOfPoints(address(ERC721ROARS), tokenIdsROARS);
        uint256 totalPendingPoints = _pendingPointsNTP + _pendingPointsROARS;
        Point.getPoints(msg.sender, totalPendingPoints);
        emit Claim(msg.sender, tokenIdsNTP, _pendingPointsNTP);
        emit Claim(msg.sender, tokenIdsROARS, _pendingPointsROARS);
    }

    /// claim helper function
    function _updateTimestampOfPoints(address contractAddress, uint256[] memory tokenIds_) internal { 
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        uint256 l = tokenIds_.length;
        for (uint256 i = 0; i < l; i++) {
            require(tokenToLastClaimedTimestamp[contractAddress][tokenIds_[i]] != _timeCurrentOrEnded, "Unable to set timestamp duplication in the same block");
            tokenToLastClaimedTimestamp[contractAddress][tokenIds_[i]] = _timeCurrentOrEnded;
        }
    }
    function _getTimeCurrentOrEnded() internal view returns (uint256) {
        return block.timestamp < yieldEndTime ? block.timestamp : yieldEndTime;
    }
    function _getTimestampOfPoint(address contractAddress, uint256 tokenId_) internal view returns (uint256) {
        return tokenToLastClaimedTimestamp[contractAddress][tokenId_] == 0 ? yieldStartTime : tokenToLastClaimedTimestamp[contractAddress][tokenId_];
    }
    function getPendingPoints(address contractAddress, uint256 tokenId_) public view returns (uint256) {
        uint256 _lastClaimedTimestamp = _getTimestampOfPoint(contractAddress, tokenId_);
        uint256 _timeCurrentOrEnded = _getTimeCurrentOrEnded();
        uint256 _timeElapsed = _timeCurrentOrEnded - _lastClaimedTimestamp;
        uint256 yieldRate = contractAddress == address(ERC721NTP) ? yieldRatePerPointNTP : yieldRatePerPointROARS;
        return (_timeElapsed * yieldRate) / 1 days;
    }
    function getPendingPointsMany(address contractAddress, uint256[] memory tokenIds_) public view returns (uint256) {
        uint256 _pendingPoints;
        uint256 l = tokenIds_.length;
        for (uint256 i = 0; i < l; i++) {
            _pendingPoints += getPendingPoints(contractAddress, tokenIds_[i]);
        }
        return _pendingPoints;
    }
}