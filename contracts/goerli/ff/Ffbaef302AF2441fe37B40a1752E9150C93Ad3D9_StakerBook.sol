// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresFactory {
    
    struct TokenInfo {
        address token;
        address staking;
        address priceFeed;
        bool isChainlinkFeed;
        bool isVolatile;
        bool isStakingRewards;
        bool isStakingMineable;
    }

    /* ---------- Views ---------- */
    function ceresBank() external view returns (address);
    function ceresReward() external view returns (address);
    function ceresMiner() external view returns (address);
    function ceresSwap() external view returns (address);
    function getTokenInfo(address token) external returns(TokenInfo memory);
    function getStaking(address token) external view returns (address);
    function getPriceFeed(address token) external view returns (address);
    function isStaking(address sender) external view returns (bool);
    function tokens(uint256 index) external view returns (address);
    function owner() external view returns (address);
    function governorTimelock() external view returns (address);

    function getTokens() external view returns (address[] memory);
    function getTokensLength() external view returns (uint256);
    function getTokenPrice(address token) external view returns(uint256);
    function isChainlinkFeed(address token) external view returns (bool);
    function isVolatile(address token) external view returns (bool);
    function isStakingRewards(address staking) external view returns (bool);
    function isStakingMineable(address staking) external view returns (bool);
    function oraclePeriod() external view returns (uint256);
    
    /* ---------- Public Functions ---------- */
    function updateOracles(address[] memory _tokens) external;
    function updateOracle(address token) external;
    function addStaking(address token, address staking, address oracle, bool _isStakingRewards, bool _isStakingMineable) external;
    function removeStaking(address token, address staking) external;
    /* ---------- RRA ---------- */
    function createStaking(address token, address chainlinkFeed, address quoteToken) external returns (address staking);
    function createOracle(address token, address quoteToken) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IStakerBook {
    /* ---------- Functions ---------- */
    function stake(address staker) external;
    function refer(address staker, address referer) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../interfaces/ICeresFactory.sol";
import "../../interfaces/IStakerBook.sol";

contract StakerBook is IStakerBook {

    address[] public stakers;
    mapping(address => bool) public staked;
    mapping(address => address) public referers;
    ICeresFactory public factory;
    modifier onlyCeresStaking() {
        require(factory.isStaking(msg.sender) == true, "StakerBook: Only Staking!");
        _;
    }
    constructor(address _factory){
        factory = ICeresFactory(_factory);
    }

    /* ---------- Views ---------- */
    function getStakersLength() external view returns (uint256){
        return stakers.length;
    }

    function getStakers() external view returns (address[] memory){
        return stakers;
    }

    function getStakersLimit(uint256 start, uint256 end) external view returns (address[] memory values){
        uint256 _length = stakers.length;
        end = end > _length ? _length : end;
        values = new address[](end - start);

        uint256 index = 0;
        for (uint256 i = start; i < end; i++) {
            values[index] = stakers[i];
            index++;
        }
    }

    /* ---------- Functions ---------- */
    function stake(address staker) external override onlyCeresStaking {
        if (!staked[staker]) {
            // staked
            staked[staker] = true;
            stakers.push(staker);
        }
    }

    function refer(address staker, address referer) external override onlyCeresStaking {
        if (!staked[staker])
            referers[staker] = referer;
    }

}