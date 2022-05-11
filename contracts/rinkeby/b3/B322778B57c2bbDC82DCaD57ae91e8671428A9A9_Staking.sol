// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./IERC721.sol";

contract Staking is Ownable, ReentrancyGuard {
    mapping(address => uint256) private _stakes;
    mapping(address => uint256) private _rewards;
    mapping(address => mapping(uint256 => bool)) _nfts;
    mapping(address => uint256) private _lastTime;
    mapping(uint256 => uint256) private _lastPrice;

    IERC20 private _token; // Deposit token
    IERC721 private _nft; // Deposit NFT

    uint256 private _rewardRate = 100;

    event DepositToken(address indexed staker, uint256 amount);

    event DepositPair(address indexed staker, uint256 amount, uint256 indexed tokenId, uint256 lastPrice);

    event ClaimReward(address indexed account, uint256 amount);

    event WithdrawToken(address indexed account, uint256 amount);

    event WithdrawNFT(address indexed account, uint256 indexed tokenId);

    constructor(address tokenAddress, address nftAddress) {
        _token = IERC20(tokenAddress);
        _nft = IERC721(nftAddress);
    }

    function isStakeholder(address account) external view returns (bool) {
        if(_stakes[account] > 0)
            return true;
        else
            return false;
    }

    function stakeOf(address account) external view returns (uint256) {
        return _stakes[account];
    }

    function rewardOf(address account) external view returns (uint256) {
        uint256 reward = _rewardRate * (block.timestamp - _lastTime[account]) + _rewards[account];
        return reward;
    }

    function depositToken(uint256 amount) external nonReentrant {
        require(amount > 0, "Staking: deposit amount is zero");

        if(_lastTime[_msgSender()] > 0) {
            _distributeReward(_msgSender());
        } else {
            _lastTime[_msgSender()] = block.timestamp;
        }

        _stakes[_msgSender()] += amount;

        emit DepositToken(_msgSender(), amount);
    }

    function depositPair(uint256 amount, uint256 tokenId, uint256 lastPrice) external nonReentrant {
        require(amount > 0, "Staking: deposit amount is zero");
        require(_token.allowance(_msgSender(), address(this)) >= amount, "Staking: insufficient allowance for token deposit");
        require(_nft.ownerOf(tokenId) == _msgSender(), "Staking: the NFT is not caller's");
        require(_nft.getApproved(tokenId) == address(this) || _nft.isApprovedForAll(_msgSender(), address(this)), "Staking: the NFT is not allowed for deposit");

        if(_lastTime[_msgSender()] > 0) {
            _distributeReward(_msgSender());
        } else {
            _lastTime[_msgSender()] = block.timestamp;
        }

        _stakes[_msgSender()] += amount;
        _stakes[_msgSender()] += lastPrice;
        _lastPrice[tokenId] = lastPrice;

        emit DepositPair(_msgSender(), amount, tokenId, lastPrice);
    }

    function _distributeReward(address staker) internal {
        _rewards[staker] += _rewardRate * (block.timestamp - _lastTime[staker]);
        _lastTime[staker] = block.timestamp;
    }

    function withdrawToken(uint256 amount) external nonReentrant {
        require(_lastTime[_msgSender()] > 0, "Staking: caller is not stakeholder");
        require(_stakes[_msgSender()] >= amount, "Staking: insufficient amount for withdraw");
        
        _distributeReward(_msgSender());
        require(_token.transfer(_msgSender(), amount), "Staking: failed to transfer withdraw token");
        _stakes[_msgSender()] -= amount;

        emit WithdrawToken(_msgSender(), amount);
    }

    function withdrawNFT(uint256 tokenId) external nonReentrant {
        require(_nfts[_msgSender()][tokenId], "Staking: the NFT is not caller's");

        _distributeReward(_msgSender());
        _nft.safeTransferFrom(address(this), _msgSender(), tokenId);

        _stakes[_msgSender()] -= _lastPrice[tokenId];

        emit WithdrawNFT(_msgSender(), tokenId);
    }

    function claimReward() external nonReentrant {
        require(_lastTime[_msgSender()] > 0, "Staking: caller is not stakeholder");

        _distributeReward(_msgSender());
        require(_token.transfer(_msgSender(), _rewards[_msgSender()]), "Staking: failed to transfer reward token");

        emit ClaimReward(_msgSender(), _rewards[_msgSender()]);
        
        _rewards[_msgSender()] = 0;
    }

    function modifyRewardRate(uint256 newRate) external onlyOwner {
        _rewardRate = newRate;
    }
}