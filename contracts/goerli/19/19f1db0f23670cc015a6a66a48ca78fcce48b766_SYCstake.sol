// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC721Holder.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract SYCstake is ERC721Holder, Ownable {
    uint256 public goldReturnFull = 315 ether;
    uint256 public goldReturnHalf = 135 ether;
    uint256 public silverReturnFull = 7.2 ether;
    uint256 public silverReturnHalf = 2.7 ether;
    uint256 public constant endStakeTimestamp = 1733011200;
    uint256 public constant endClaimTimestamp = 1764547200;

    IERC721 public SYCNYGOLD = IERC721(0x6768bd9ABC69b44D40107F745C0970A5604EF204);
    IERC20 public USDC = IERC20(0x7B553da285F1A5120624Fd181F64fdD80b082363);

    uint256 internal halfTimestamp = 15778463;
    uint256 internal fullTimestamp = 31556926;

    mapping(address => uint256) public stakedForUser;    

    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public stakeTimestamp;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public lockedTime;

    // require block.timestamp + stake time < 2024 1 dec. voor gold en silver
    // tm 2025 1 jaar, tijd om geld terug tijdens burn

    function stake(address user, uint256 tokenId, uint256 tokenNumber, uint256 timestamp) public {
        require(timestamp == halfTimestamp || timestamp == fullTimestamp);
        require(block.timestamp + timestamp <= endStakeTimestamp, "You can not stake for this peroid anymore.");
        require(stakeTimestamp[user][tokenNumber][tokenId] == 0);
        if(tokenNumber == 1) {
            require(SYCNYGOLD.balanceOf(user) >= 1);
            SYCNYGOLD.transferFrom(msg.sender, address(this), tokenId);
        }

        stakedForUser[msg.sender] = tokenId;
        stakeTimestamp[user][tokenNumber][tokenId] = block.timestamp;
        lockedTime[user][tokenNumber][tokenId] = timestamp;
    }

    function unStake(address user, uint256 tokenId, uint256 tokenNumber) public {
        require(block.timestamp <= endClaimTimestamp);
        uint256 allowedTimestamp = getUnstakeTimestamp(user, tokenId, tokenNumber);
        require(stakeTimestamp[user][tokenNumber][tokenId] >= allowedTimestamp);
        if(tokenNumber == 1) {
            SYCNYGOLD.transferFrom(address(this), user, tokenId);
            stakeTimestamp[user][tokenNumber][tokenId] = 0;
            USDC.transferFrom(address(this), user, goldReturnFull);
            
        }
    }

    function getUnstakeTimestamp(address user, uint256 tokenId, uint256 tokenNumber) public view returns(uint256) {
        return stakeTimestamp[user][tokenNumber][tokenId] + lockedTime[user][tokenNumber][tokenId];
    }

    function withdrawalTokens() public onlyOwner {
        USDC.transferFrom(address(this), msg.sender, USDC.balanceOf(address(this)));
    }
}