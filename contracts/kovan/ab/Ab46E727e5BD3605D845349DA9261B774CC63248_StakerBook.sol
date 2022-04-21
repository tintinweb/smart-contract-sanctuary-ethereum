// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICeresFactory {
    
    struct TokenInfo {
        address tokenAddress;
        uint256 tokenType; // 1: asc, 2: crs, 3: col, 4: vol;
        address stakingAddress;
        address oracleAddress;
        bool isStakingRewards;
        bool isStakingMineable;
    }

    /* ---------- Views ---------- */
    function getBank() external view returns (address);
    function getReward() external view returns (address);
    function getTokenInfo(address token) external returns(TokenInfo memory);
    function getStaking(address token) external view returns (address);
    function getOracle(address token) external view returns (address);
    function isValidStaking(address sender) external view returns (bool);
    function volTokens(uint256 index) external view returns (address);

    function getTokens() external view returns (address[] memory);
    function getTokensLength() external view returns (uint256);
    function getVolTokensLength() external view returns (uint256);
    function getValidStakings() external view returns (address[] memory);
    function getTokenPrice(address token) external view returns(uint256);
    function isStakingRewards(address staking) external view returns (bool);
    function isStakingMineable(address staking) external view returns (bool);

    /* ---------- Functions ---------- */
    function setBank(address newAddress) external;
    function setReward(address newReward) external;
    function setCreator(address creator) external;
    function setTokenType(address token, uint256 tokenType) external;
    function setStaking(address token, address staking) external;
    function setOracle(address token, address oracle) external;
    function setIsStakingRewards(address token, bool _isStakingRewards) external;
    function setIsStakingMineable(address token, bool _isStakingMineable) external;
    function updateOracles(address[] memory tokens) external;
    function updateOracle(address token) external;
    function addStaking(address token, uint256 tokenType, address staking, address oracle, bool _isStakingRewards, bool _isStakingMineable) external;
    function removeStaking(address token, address staking) external;

    /* ---------- RRA ---------- */
    function createStaking(address token, bool ifCreateOracle) external returns (address staking, address oracle);
    function createStakingWithLiquidity(address token, uint256 tokenAmount, uint256 quoteAmount, bool ifCreateOracle) external returns (address staking, address oracle);
    function createOracle(address token) external returns (address);

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

import "../../interface/ICeresFactory.sol";
import "../../interface/IStakerBook.sol";

contract StakerBook is IStakerBook {
    
    address[] public stakers;
    mapping(address => bool) public staked;
    mapping(address => address) public referers;
    
    ICeresFactory public factory;

    modifier onlyStakings() {
        require(factory.isValidStaking(msg.sender) == true, "Only Staking!");
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
    function stake(address staker) external override onlyStakings {
        if (!staked[staker]) {
            // staked
            staked[staker] = true;
            stakers.push(staker);
        }
    }

    function refer(address staker, address referer) external override onlyStakings {
        if (!staked[staker]) {
            // staked
            staked[staker] = true;
            stakers.push(staker);
            if (referer != address(0))
                referers[staker] = referer;
        }
    }
    
}