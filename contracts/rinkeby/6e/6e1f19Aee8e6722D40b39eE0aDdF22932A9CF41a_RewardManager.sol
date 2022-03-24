// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

import './Ownable.sol';
import './Pausable.sol';
import './ECDSA.sol';
import './IReward.sol';
import {IERC20} from "./IERC20.sol";
import './IFeeSharingManager.sol';

contract RewardManager is Ownable, Pausable {
   
    event SignerUpdate(address signer, bool isRemoval);

    event NewFeeSharingManager( address feeSharingManager,address user);
    event NewFeeAmountLimit( uint256 feeAmountLimit,address user);

    event ClaimForOneKey(address user,uint256 airDropTotal,uint256 tradingRewardTotal,uint256 socialRewardTotal,uint256 PlanetNftRewardairTotal);


    uint256 public  FEE_AMOUNT_LIMIT;

    uint256 public immutable startBlock;
    address public  AIRDROP;
    address public  TRADINGREWARD;
    address public  PLANETNFTRWEWARD;
    address public  SOCIALREWARD;

    address public  feeSharingManager;

    IERC20 public immutable wethToken;

    mapping(address => bool) public signers;

    constructor(
        address signer_,
        uint256 startBlock_,
        address airdrop_,
        address tradingReward_,
        address planetNFTReward_,
        address socialReward_,
        address weth_,
        uint256 feeAmountLimit_
    ) {

        wethToken = IERC20(weth_);
        startBlock = startBlock_;
        AIRDROP = airdrop_;
        TRADINGREWARD = tradingReward_;
        PLANETNFTRWEWARD = planetNFTReward_;
        SOCIALREWARD = socialReward_;
        FEE_AMOUNT_LIMIT = feeAmountLimit_;
        if (signer_ != address(0)) {
            signers[signer_] = true;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    function updateSigners(address[] memory toAdd, address[] memory toRemove) external onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            signers[toAdd[i]] = true;
            emit SignerUpdate(toAdd[i], false);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete signers[toRemove[i]];
            emit SignerUpdate(toRemove[i], true);
        }
    }

    function claimForOneKey(
        uint256 airDropTotal,
        uint256 tradingRewardTotal,
        uint256 socialRewardTotal,
        uint256 PlanetNftRewardTotal,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool staking
    ) external whenNotPaused {
        require(block.number >= startBlock, "Claim: wait for start");
        bytes32 hash = keccak256(abi.encode(msg.sender, airDropTotal,tradingRewardTotal,socialRewardTotal,PlanetNftRewardTotal));
        address signer = ECDSA.recover(hash, v, r, s);
        require(signers[signer], 'Claim: signature error');
        uint256 wethBalance = wethToken.balanceOf(feeSharingManager);
        if(wethBalance >= FEE_AMOUNT_LIMIT ){
            IFeeSharingManager(feeSharingManager).updateRewards();
        }
        if(airDropTotal > 0){
            IReward(AIRDROP).claimForOneKey(airDropTotal,msg.sender,staking);
        }
        if(tradingRewardTotal > 0){
            IReward(TRADINGREWARD).claimForOneKey(tradingRewardTotal,msg.sender,staking);
        }
        if(socialRewardTotal > 0){
            IReward(SOCIALREWARD).claimForOneKey(socialRewardTotal,msg.sender,staking);
        }
        if(PlanetNftRewardTotal > 0){
            IReward(PLANETNFTRWEWARD).claimForOneKey(PlanetNftRewardTotal,msg.sender,staking);
        }
        
        emit ClaimForOneKey(msg.sender, airDropTotal, tradingRewardTotal, socialRewardTotal, PlanetNftRewardTotal);
    }

    function updateFeeSharingManager(address _feeSharingManager) external onlyOwner {
        feeSharingManager = _feeSharingManager;
        emit NewFeeSharingManager( _feeSharingManager,msg.sender);
    }

    function updateFeeAmountLimit(uint256 _feeAmountLimit) external onlyOwner {
        FEE_AMOUNT_LIMIT = _feeAmountLimit;
        emit NewFeeAmountLimit( _feeAmountLimit,msg.sender);
    }
}