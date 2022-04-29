// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "./Context.sol";
import "./Ownable.sol";
import "./MandoX.sol";
import "./Lacedameon.sol";
import "./Pausable.sol";

contract MandoXStaking is Ownable, IERC721Receiver, Pausable {

    struct NftInfo {
        uint256 tokenId;
        address owner;
        uint256 stakeTime;
        uint256 lockTime;
        uint16  tier;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 lastClaimed);
    event MandoxClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the Lacedameon NFT contract
    Lacedameon lacedameon;
    // reference to the $Mandox contract for $MNX earnings
    MandoX mandox;

    // maps tokenId to stake
    mapping(uint256 => NftInfo) public register;

    mapping(address => NftInfo[]) public stakedTokens;

    address public rewardingWallet;

    // Nft earn 1 $Mandox per day
    uint256 public constant DAILY_MANDOX_RATE = 1 ether;
    // Nft must have 2 days worth of $Mandox to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;

    uint256 public rewardPerDay30 = 15000000000;
    uint256 public rewardPerDay45 = 30000000000;
    uint256 public rewardPerDay90 = 100000000000;

    // amount of $Mandox earned so far
    uint256 public totalMandoxEarned;
    // number of Nft staked in the register
    uint256 public totalNFTStaked;
    // the last time $Mandox was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $MANDOX
    bool public rescueEnabled = false;

    constructor(address _lacedameon, address payable _mandox, address _rewardingWallet) {
        lacedameon = Lacedameon(_lacedameon);
        mandox = MandoX(_mandox);
        rewardingWallet = _rewardingWallet;
        totalNFTStaked = 0;
    }

    function addManyToRegister(uint256[] calldata tokenIds, uint16 tier) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            require(lacedameon.ownerOf(tokenIds[i]) == _msgSender(), "MANDOX: IS NOT OWNER");
            lacedameon.transferFrom(_msgSender(), address(this), tokenIds[i]);
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
            lockTime = block.timestamp + 30 minutes;
        } else if (tier == 60) {
            lockTime = block.timestamp + 60 minutes;
        } else if (tier == 90) {
            lockTime = block.timestamp + 90 minutes;
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
    * realize $MANDOX earnings and optionally unstake tokens from the register
    * to unstake a Nft it will require it has 2 days worth of $MANDOX unclaimed
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
        mandox.transferFrom(rewardingWallet, _msgSender(), rewards);
    }

    /**
    * @param tokenId the ID of the NFT to claim earnings from
    * @param unstake whether or not to unstake the NFT
    * @return rewards - the amount of $MANDOX earned
    */
    function _claimNftFromRegister(uint256 tokenId, bool unstake) internal returns (uint256 rewards) {
        NftInfo storage stake = register[tokenId];
        require(stake.owner == _msgSender(), "MANDOX: SHOULD BE OWNER");
        require(block.timestamp >= stake.lockTime, "MANDOX: CAN NOT CLAIM YET");
        require(stake.tokenId == tokenId, "Not Staked");

        if (stake.tier == 30) {
            rewards = uint256((block.timestamp - stake.stakeTime) * rewardPerDay30 / 1 minutes);
        } else if (stake.tier == 45) {
            rewards = uint256((block.timestamp - stake.stakeTime) * rewardPerDay45 / 1 minutes);
        } else if (stake.tier == 90) {
            rewards = uint256((block.timestamp - stake.stakeTime) * rewardPerDay90 / 1 minutes);
        } else {
            require(false, "Invalid Tier");
        }

        if (unstake) {
            lacedameon.safeTransferFrom(address(this), _msgSender(), tokenId); // send back NFT
            delete register[tokenId];
            for (uint i = 0; i < stakedTokens[_msgSender()].length; i++) {
                if (stakedTokens[_msgSender()][i].tokenId == tokenId) {
                    delete stakedTokens[_msgSender()][i];
                }
            }
            totalNFTStaked -= 1;
        } else {
            stake.stakeTime = block.timestamp;
            stake.lockTime = block.timestamp + register[tokenId].tier * 1 minutes;
            // reset stake
        }
        emit MandoxClaimed(tokenId, rewards, unstake);
    }

    function getStaked(address _owner) public view returns (NftInfo[] memory) {
        return stakedTokens[_owner];
    }


    /**
    * emergency unstake tokens
    * @param tokenIds the IDs of the tokens to claim earnings from
    */
    function rescue(uint256[] calldata tokenIds) external {
        require(rescueEnabled, "MANDOX: RESCUE DISABLED");
        uint256 tokenId;
        NftInfo memory stake;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            stake = register[tokenId];
            require(stake.owner == _msgSender(), "MANDOX: SHOULD BE OWNER");
            lacedameon.safeTransferFrom(address(this), _msgSender(), tokenId); // send back Lacedameon
            delete register[tokenId];
            for (uint i = 0; i < stakedTokens[_msgSender()].length; i++) {
                if (stakedTokens[_msgSender()][i].tokenId == tokenId) {
                    delete stakedTokens[_msgSender()][i];
                }
            }
            totalNFTStaked -= 1;
            emit MandoxClaimed(tokenId, 0, true);
        }
    }

    function setRewardPerDay30(uint256 value) public onlyOwner{
        rewardPerDay30 = value;
    }

    function setRewardPerDay45(uint256 value) public onlyOwner{
        rewardPerDay45 = value;
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
        return mandox.allowance(rewardingWallet , address(this));
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "MANDOX: CAN NOT STAKE DIRECTLY");
        return IERC721Receiver.onERC721Received.selector;
    }
}