// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/interfaces/IERC2981.sol";
//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IERC2981.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC20.sol";

import "./wnft_interfaces.sol";

interface IHarvestStrategy {
    function canHarvest(uint256 _pid, address _forUser, uint256[] memory _wnfTokenIds) external view returns (bool);
}

interface INFTMasterChef {
    event AddPoolInfo(IERC721Metadata nft, IWrappedNFT wnft, uint256 startBlock, 
                    RewardInfo[] rewards, uint256 depositFee, IERC20 dividendToken, bool withUpdate);
    event SetStartBlock(uint256 pid, uint256 startBlock);
    event UpdatePoolReward(uint256 pid, uint256 rewardIndex, uint256 rewardBlock, uint256 rewardForEachBlock, uint256 rewardPerNFTForEachBlock);
    event SetPoolDepositFee(uint256 pid, uint256 depositFee);
    event SetHarvestStrategy(IHarvestStrategy harvestStrategy);
    event SetPoolDividendToken(uint256 pid, IERC20 dividendToken);

    event AddTokenRewardForPool(uint256 pid, uint256 addTokenPerPool, uint256 addTokenPerBlock, bool withTokenTransfer);
    event AddDividendForPool(uint256 pid, uint256 addDividend);

    event UpdateDevAddress(address payable devAddress);
    event EmergencyStop(address user, address to);
    event ClosePool(uint256 pid, address payable to);

    event Deposit(address indexed user, uint256 indexed pid, uint256[] tokenIds);
    event Withdraw(address indexed user, uint256 indexed pid, uint256[] wnfTokenIds);
    event WithdrawWithoutHarvest(address indexed user, uint256 indexed pid, uint256[] wnfTokenIds);
    event Harvest(address indexed user, uint256 indexed pid, uint256[] wnftTokenIds, 
                    uint256 mining, uint256 dividend);

    // Info of each NFT.
    struct NFTInfo {
        bool deposited;     // If the NFT is deposited.
        uint256 rewardDebt; // Reward debt.

        uint256 dividendDebt; // Dividend debt.
    }

    //Info of each Reward 
    struct RewardInfo {
        uint256 rewardBlock;
        uint256 rewardForEachBlock;    //Reward for each block, can only be set one with rewardPerNFTForEachBlock
        uint256 rewardPerNFTForEachBlock;    //Reward for each block for every NFT, can only be set one with rewardForEachBlock
    }

    // Info of each pool.
    struct PoolInfo {
        IWrappedNFT wnft;// Address of wnft contract.

        uint256 startBlock; // Reward start block.

        uint256 currentRewardIndex;// the current reward phase index for poolsRewardInfos
        uint256 currentRewardEndBlock;  // the current reward end block.

        uint256 amount;     // How many NFTs the pool has.
        
        uint256 lastRewardBlock;  // Last block number that token distribution occurs.
        uint256 accTokenPerShare; // Accumulated tokens per share, times 1e12.
        
        IERC20 dividendToken;
        uint256 accDividendPerShare;

        uint256 depositFee;// ETH charged when user deposit.
    }
    
    function poolLength() external view returns (uint256);
    function poolRewardLength(uint256 _pid) external view returns (uint256);

    function poolInfos(uint256 _pid) external view returns (PoolInfo memory poolInfo);
    function poolsRewardInfos(uint256 _pid, uint256 _rewardInfoId) external view returns (uint256 _rewardBlock, uint256 _rewardForEachBlock, uint256 _rewardPerNFTForEachBlock);
    function poolNFTInfos(uint256 _pid, uint256 _nftTokenId) external view returns (bool _deposited, uint256 _rewardDebt, uint256 _dividendDebt);

    function getPoolCurrentReward(uint256 _pid) external view returns (RewardInfo memory _rewardInfo, uint256 _currentRewardIndex);
    function getPoolEndBlock(uint256 _pid) external view returns (uint256 _poolEndBlock);
    function isPoolEnd(uint256 _pid) external view returns (bool);

    function pending(uint256 _pid, uint256[] memory _wnftTokenIds) external view returns (uint256 _mining, uint256 _dividend);
    function deposit(uint256 _pid, uint256[] memory _tokenIds) external payable;
    function withdraw(uint256 _pid, uint256[] memory _wnftTokenIds) external;
    function withdrawWithoutHarvest(uint256 _pid, uint256[] memory _wnftTokenIds) external;
    function harvest(uint256 _pid, address _forUser, uint256[] memory _wnftTokenIds) external returns (uint256 _mining, uint256 _dividend);
}

contract NFTUtils { 
    struct UserInfo {
        uint256 mining;
        uint256 dividend;
        uint256 nftQuantity;
        uint256 wnftQuantity;
        bool isNFTApproved;
        bool isWNFTApproved;
    }

    function getNFTMasterChefInfos(INFTMasterChef _nftMasterchef, uint256 _pid, address _owner, uint256 _fromTokenId, uint256 _toTokenId) external view
                returns (INFTMasterChef.PoolInfo memory _poolInfo, INFTMasterChef.RewardInfo memory _rewardInfo, UserInfo memory _userInfo, 
                        uint256 _currentRewardIndex, uint256 _endBlock, IERC721Metadata _nft)
     {
        require(address(_nftMasterchef) != address(0), "NFTUtils: nftMasterchef can not be zero");
        // INFTMasterChef nftMasterchef = _nftMasterchef; 
        _poolInfo = _nftMasterchef.poolInfos(_pid);
        (_rewardInfo, _currentRewardIndex)  = _nftMasterchef.getPoolCurrentReward(_pid);
        _endBlock = _nftMasterchef.getPoolEndBlock(_pid);

       if (_owner != address(0)) {
         uint256[] memory wnftTokenIds = ownedNFTTokens(_poolInfo.wnft, _owner, _fromTokenId, _toTokenId);
         _userInfo = UserInfo({mining: 0, dividend: 0, nftQuantity: 0, wnftQuantity: 0, isNFTApproved: false, isWNFTApproved: false});
         if (wnftTokenIds.length > 0) {
             (_userInfo.mining, _userInfo.dividend) = _nftMasterchef.pending(_pid, wnftTokenIds);
         }
    
         IWrappedNFT wnft = _poolInfo.wnft;
         _userInfo.nftQuantity = wnft.nft().balanceOf(_owner);
         _userInfo.wnftQuantity = wnft.balanceOf(_owner);
         _userInfo.isNFTApproved = wnft.nft().isApprovedForAll(_owner, address(wnft));
         _userInfo.isWNFTApproved = wnft.isApprovedForAll(_owner, address(_nftMasterchef));
         _nft = wnft.nft();
       }
    }

    function ownedNFTTokens(IERC721 _nft, address _owner, uint256 _fromTokenId, uint256 _toTokenId) public view returns (uint256[] memory _totalTokenIds) {
        if(address(_nft) == address(0) || _owner == address(0)){
            return _totalTokenIds;
        }
        if (_nft.supportsInterface(type(IERC721Enumerable).interfaceId)) {
            IERC721Enumerable nftEnumerable = IERC721Enumerable(address(_nft));
            _totalTokenIds = ownedNFTEnumerableTokens(nftEnumerable, _owner);
        }else{
            _totalTokenIds = ownedNFTNotEnumerableTokens(_nft, _owner, _fromTokenId, _toTokenId);
        }
    }
    
    function ownedNFTEnumerableTokens(IERC721Enumerable _nftEnumerable, address _owner) public view returns (uint256[] memory _totalTokenIds) {
        if(address(_nftEnumerable) == address(0) || _owner == address(0)){
            return _totalTokenIds;
        }
        uint256 balance = _nftEnumerable.balanceOf(_owner);
        if (balance > 0) {
            _totalTokenIds = new uint256[](balance);
            for (uint256 i = 0; i < balance; i++) {
                uint256 tokenId = _nftEnumerable.tokenOfOwnerByIndex(_owner, i);
                _totalTokenIds[i] = tokenId;
            }
        }
    }

    function ownedNFTNotEnumerableTokens(IERC721 _nft, address _owner, uint256 _fromTokenId, uint256 _toTokenId) public view returns (uint256[] memory _totalTokenIds) {
        if(address(_nft) == address(0) || _owner == address(0)){
            return _totalTokenIds;
        }
        uint256 number;
        for (uint256 tokenId = _fromTokenId; tokenId <= _toTokenId; tokenId ++) {
            if (_tokenIdExists(_nft, tokenId)) {
                address tokenOwner = _nft.ownerOf(tokenId);
                if (tokenOwner == _owner) {
                    number ++;
                }
            }
        }
        if(number > 0){
            _totalTokenIds = new uint256[](number);
            uint256 index;
            for (uint256 tokenId = _fromTokenId; tokenId <= _toTokenId; tokenId ++) {
                if (_tokenIdExists(_nft, tokenId)) {
                    address tokenOwner = _nft.ownerOf(tokenId);
                    if (tokenOwner == _owner) {
                        _totalTokenIds[index] = tokenId;
                        index ++;
                    }
                }
            }
        }
    }

    function _tokenIdExists(IERC721 _nft, uint256 _tokenId) internal view returns (bool){
        if(_nft.supportsInterface(type(IWrappedNFT).interfaceId)){
            IWrappedNFT wnft = IWrappedNFT(address(_nft));
            return wnft.exists(_tokenId);
        }
        return true;
    }

    function supportERC721(IERC721 _nft) external view returns (bool){
        return _nft.supportsInterface(type(IERC721).interfaceId);
    }

    function supportERC721Metadata(IERC721 _nft) external view returns (bool){
        return _nft.supportsInterface(type(IERC721Metadata).interfaceId);
    }

    function supportERC721Enumerable(IERC721 _nft) external view returns (bool){
        return _nft.supportsInterface(type(IERC721Enumerable).interfaceId);
    }

    function supportIWrappedNFT(IERC721 _nft) external view returns (bool){
        return _nft.supportsInterface(type(IWrappedNFT).interfaceId);
    }

    function supportIWrappedNFTEnumerable(IERC721 _nft) external view returns (bool){
        return _nft.supportsInterface(type(IWrappedNFTEnumerable).interfaceId);
    }
}