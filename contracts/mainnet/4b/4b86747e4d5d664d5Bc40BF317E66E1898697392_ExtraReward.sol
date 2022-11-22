pragma solidity ^0.8.0;

import "./Administrable.sol";
import "./Vault.sol";

interface IVE {
    function balanceOfNFT(uint256 _tokenId) external view returns (uint256);

    function ownerOf(uint256) external view returns (address);
}

interface IMultiPriceOracle {
    function getMultiPrice() external view returns (uint256 multiPrice);
}

contract ExtraReward is Administrable, Vault {
    struct RewardInfo {
        bool allowed;
        uint256 snapshotTime;
        uint256 power;
    }

    mapping(uint256 => RewardInfo) public rewardInfos;

    address public ve;
    address public multiPriceOracle;
    address public usdc;

    uint256 public apr = 5;
    uint256 public aprDenominator = 100;
    uint256 public priceDenominator = 1e18;
    uint256 public maxReward = 500 * 1e6;

    event SetReward(uint256 tokenId, RewardInfo rewardInfo);
    event CancelReward(uint256 tokenId);
    event ClaimReward(uint256 tokenId, address to, uint256 amount);

    constructor(
        address ve_,
        address multiPriceOracle_,
        address usdc_
    ) Vault(usdc_) {
        setAdmin(msg.sender);
        ve = ve_;
        multiPriceOracle = multiPriceOracle_;
        usdc = usdc_;
    }

    function setExtraReward(uint256 tokenId) public onlyAdmin {
        rewardInfos[tokenId].allowed = true;
        _updateRewardInfo(tokenId);
        emit SetReward(tokenId, rewardInfos[tokenId]);
    }

    function cancelExtraReward(uint256 tokenId) public onlyAdmin {
        rewardInfos[tokenId].allowed = false;
        emit CancelReward(tokenId);
    }

    function claimReward(uint256 tokenId, address to) public returns (bool) {
        require(IVE(ve).ownerOf(tokenId) == msg.sender);
        require(rewardInfos[tokenId].allowed);
        uint256 reward = getReward(tokenId);
        bool succ = IERC20(usdc).transfer(to, reward);

        _updateRewardInfo(tokenId);
        emit ClaimReward(tokenId, to, reward);
        return succ;
    }

    function getReward(uint256 tokenId) public view returns (uint256 reward) {
        uint256 time = block.timestamp - rewardInfos[tokenId].snapshotTime;
        uint256 multiPrice = IMultiPriceOracle(multiPriceOracle)
            .getMultiPrice();
        uint256 annual_reward = (((rewardInfos[tokenId].power * multiPrice) /
            priceDenominator) * apr) / aprDenominator;
        reward = (annual_reward * time) / 360 days;
        if (reward > maxReward) {
            reward = maxReward;
        }
        return reward;
    }

    function _updateRewardInfo(uint256 tokenId) internal {
        rewardInfos[tokenId].snapshotTime = block.timestamp;
        rewardInfos[tokenId].power = IVE(ve).balanceOfNFT(tokenId);
    }
}