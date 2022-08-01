// SPDX-License-Identifier: MIT LICENSE
/*
     $BCT & BioApes NFT Staking Contract
     Stake BioApes Earn $BCT token!

    Visit our Website at www.mandoxglobal.com
    and $BCT page www.BananaClubToken.com
    Keep up to date with our socials!
    t.me/officialmandox - twitter.com/officialmandox - discord.gg/mandox

    Rewards are paid out per tier, per lockup, Use at your own Risk, Mandox LLC is not liable
    for any lost, stolen or misplaced funds/tokens.
    Built By and For Mandox, with Openzeppelin Libraries - Happy Staking!
*/

pragma solidity 0.8.2;

import "./Context.sol";
import "./Ownable.sol";
import "./BananaClubToken.sol";
import "./Bioapes.sol";
import "./Pausable.sol";

contract BioApesStaking is Ownable, IERC721Receiver, Pausable {

    struct NftInfo {
        uint256 tokenId;
        address owner;
        uint256 stakeTime;
        uint256 lockTime;
        uint16  tier;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 lastClaimed);
    event BCTClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the BioApes NFT contract
    BioApes bioapes;
    // reference to the $BCT contract for $BCT earnings
    BananaClubToken bct;


    // maps tokenId to stake
    mapping(uint256 => NftInfo) public register;

    mapping(address => NftInfo[]) public stakedTokens;

    address public rewardingWallet;

    uint256 public rewardPerDay30 = 500; // Values in $BCT tokens for Payout
    uint256 public rewardPerDay60 = 1000;  
    uint256 public rewardPerDay90 = 2000;

    // amount of $BCT earned so far
    uint256 public totalBctEarned;
    // number of Nft staked in the register
    uint256 public totalNFTStaked;
    // the last time $BCT was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $BCT
    bool public rescueEnabled = false;

    constructor(address _bioapes, address payable _bct, address _rewardingWallet) {
        bioapes = BioApes(_bioapes);
        bct = BananaClubToken(_bct);
        rewardingWallet = _rewardingWallet;
        totalNFTStaked = 0;
    }

    function addManyToRegister(uint256[] calldata tokenIds, uint16 tier) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(bioapes.ownerOf(tokenIds[i]) == _msgSender(), "BIOAPES: IS NOT OWNER");
            bioapes.transferFrom(_msgSender(), address(this), tokenIds[i]);
            _addNftToRegister(_msgSender(), tokenIds[i], tier);
        }
    }

    function _addNftToRegister(address account, uint256 tokenId, uint16 tier) internal whenNotPaused {
        NftInfo storage _nftInfo = register[tokenId];
        require(_nftInfo.tokenId == 0, "Already Staked!");
        require(_nftInfo.tier == 0, "Already in some tier");
        _nftInfo.tokenId = tokenId;
        _nftInfo.owner = account;
        _nftInfo.stakeTime = block.timestamp;
        uint256 lockTime = 0;
        if (tier == 30) {
            lockTime = block.timestamp + 30 days;
        } else if (tier == 60) {
            lockTime = block.timestamp + 60 days;
        } else if (tier == 90) {
            lockTime = block.timestamp + 90 days;
        } else {
            require(false, "Invalid tier");
        }
        _nftInfo.lockTime = lockTime;
        _nftInfo.tier = tier;
        stakedTokens[account].push(_nftInfo);
        totalNFTStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
    * @param tokenIds the IDs of the tokens to claim earnings from
    * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
    */
    function claimManyFromRegister(uint256[] calldata tokenIds, bool unstake) external whenNotPaused {
        uint256 rewards = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            rewards += _claimNftFromRegister(tokenIds[i], unstake);
        }
        if (rewards == 0) return;
        uint256 _allowance = pendingRewards();
        require(_allowance >= rewards, "Pending Rewards Not Allocated");
        bct.transferFrom(rewardingWallet, _msgSender(), rewards);
    }

    /**
    * @param tokenId the ID of the NFT to claim earnings from
    * @param unstake whether or not to unstake the NFT
    * @return rewards - the amount of $BCT earned
    */
    function _claimNftFromRegister(uint256 tokenId, bool unstake) internal returns (uint256 rewards) {
        NftInfo storage stake = register[tokenId];
        require(stake.owner == _msgSender(), "BIOAPES: SHOULD BE OWNER");
        require(block.timestamp >= stake.lockTime, "BIOAPES: CAN NOT CLAIM YET");
        require(stake.tokenId == tokenId, "Not Staked");

        if (stake.tier == 30) {
            rewards = uint256((block.timestamp - stake.stakeTime) * rewardPerDay30 / 1 days * (10 ** 9));
        } else if (stake.tier == 60) {
            rewards = uint256((block.timestamp - stake.stakeTime) * rewardPerDay60 / 1 days * (10 ** 9));
        } else if (stake.tier == 90) {
            rewards = uint256((block.timestamp - stake.stakeTime) * rewardPerDay90 / 1 days * (10 ** 9));
        } else {
            require(false, "Invalid Tier");
        }

        if (unstake) {
            bioapes.safeTransferFrom(address(this), _msgSender(), tokenId); // send back NFT
            delete register[tokenId];
            for (uint i = 0; i < stakedTokens[_msgSender()].length; i++) {
                if (stakedTokens[_msgSender()][i].tokenId == tokenId) {
                    for (uint j = i; j < stakedTokens[_msgSender()].length - 1; j++) {
                        stakedTokens[_msgSender()][j] = stakedTokens[_msgSender()][j + 1];
                    }
                    stakedTokens[_msgSender()].pop();
                }
            }
            totalNFTStaked -= 1;
        } else {
            stake.stakeTime = block.timestamp;
            stake.lockTime = block.timestamp + register[tokenId].tier * 1 days;
            // reset stake
        }
        emit BCTClaimed(tokenId, rewards, unstake);
    }

    function getStaked(address _owner) public view returns (NftInfo[] memory) {
        return stakedTokens[_owner];
    }


    /**
    * emergency unstake tokens
    * @param tokenIds the IDs of the tokens to claim earnings from
    */
    function rescue(uint256[] calldata tokenIds) external {
        require(rescueEnabled, "BIOAPES: RESCUE DISABLED");
        uint256 tokenId;
        NftInfo memory stake;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            stake = register[tokenId];
            require(stake.owner == _msgSender(), "BIOAPES: SHOULD BE OWNER");
            bioapes.safeTransferFrom(address(this), _msgSender(), tokenId); // send back Apes
            delete register[tokenId];
            for (uint j = 0; j < stakedTokens[_msgSender()].length; j++) {
                if (stakedTokens[_msgSender()][j].tokenId == tokenId) {
                    for (uint k = j; j < stakedTokens[_msgSender()].length - 1; k++) {
                        stakedTokens[_msgSender()][k] = stakedTokens[_msgSender()][k + 1];
                    }
                    stakedTokens[_msgSender()].pop();
                }
            }
            totalNFTStaked -= 1;
            emit BCTClaimed(tokenId, 0, true);
        }
    }

    function setRewardPerDay30(uint256 value) public onlyOwner{
        rewardPerDay30 = value;
    }

    function setRewardPerDay60(uint256 value) public onlyOwner{
        rewardPerDay60 = value;
    }

    function setRewardPerDay90(uint256 value) public onlyOwner{
        rewardPerDay90= value;
    }

    function setRewardingWallet(address _rewardingWallet) public onlyOwner{
        rewardingWallet= _rewardingWallet;
    }

    /**
    * allows owner to enable "rescue mode"
    * simplifies accounting, prioritizes tokens out in emergency
    */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }
    /**
    * enables owner to pause / unpause claiming
    */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function pendingRewards() public view returns (uint256){
        return bct.allowance(rewardingWallet , address(this));
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "BIOAPES: CAN NOT STAKE DIRECTLY");
        return IERC721Receiver.onERC721Received.selector;
    }
}