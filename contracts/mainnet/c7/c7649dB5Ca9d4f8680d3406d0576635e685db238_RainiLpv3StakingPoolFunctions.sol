// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IRainiLpv3StakingPoolv2.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract RainiLpv3StakingPoolFunctions is AccessControl {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using SafeERC20 for IERC20; 

    IRainiLpv3StakingPoolv2 public lpStakingPool;

    uint256 public constant REWARD_DECIMALS = 1000000;
    uint256 public constant BONUS_DECIMALS = 1000000000;
    uint256 public constant PHOTON_REWARD_DECIMALS = 10000000000000;

    uint256 public fullBonusCutoff;
    uint256 public xphotonCutoff;

    // Events
    event PhotonWithdrawn(uint256 amount);

    event TokensStaked(address payer, uint256 amount, uint256 timestamp);
    event TokensWithdrawn(address owner, uint256 amount, uint256 timestamp);

    event UnicornPointsBurned(address owner, uint256 amount);
    event UnicornPointsMinted(address owner, uint256 amount);

    event RewardWithdrawn(address owner, uint256 amount, uint256 timestamp);

    constructor(address _lpStakingPoolAddress, uint256 _fullBonusCutoff) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        lpStakingPool = IRainiLpv3StakingPoolv2(_lpStakingPoolAddress);
        fullBonusCutoff = _fullBonusCutoff;
        xphotonCutoff = 2147483647;
    }

    modifier onlyOwner() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "not owner"
        );
        _;
    }

    modifier onlyBurner() {
        require(
            hasRole(BURNER_ROLE, _msgSender()),
            "not burner"
        );
        _;
    }

    modifier onlyMinter() {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "not minter"
        );
        _;
    }

    function balanceUpdate(address _owner) internal {
        IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = lpStakingPool.accountRewardVars(_owner);
        IRainiLpv3StakingPoolv2.AccountVars memory _accountVars = lpStakingPool.accountVars(_owner);
        IRainiLpv3StakingPoolv2.GeneralRewardVars memory _generalRewardVars = lpStakingPool.generalRewardVars();

        // Photon rewards
        _generalRewardVars.photonRewardPerTokenStored = uint64(
            photonRewardPerToken()
        );
        _generalRewardVars.lastUpdateTime = uint32(lastTimeRewardApplicable());

        if (_owner != address(0)) {
            uint32 duration = uint32(block.timestamp) -
                _accountRewardVars.lastUpdated;
            uint128 unicornReward = calculateReward(
                _owner,
                lpStakingPool.staked(_owner),
                duration,
                lpStakingPool.rewardRate(),
                true
            );
            uint32 xphotonDuration = uint32(Math.min(block.timestamp, xphotonCutoff)) - _accountRewardVars.lastUpdated;
            uint128 xphotonReward = calculateReward(
                _owner,
                lpStakingPool.staked(_owner),
                xphotonDuration,
                lpStakingPool.xphotonRewardRate(),
                false
            );

            _accountVars.unicornBalance = _accountVars.unicornBalance + unicornReward;
            _accountVars.xphotonBalance = _accountVars.xphotonBalance + xphotonReward;
            
            _accountRewardVars.lastUpdated = uint32(block.timestamp);
            _accountRewardVars.lastBonus = uint64(
                Math.min(
                    lpStakingPool.maxBonus(),
                    _accountRewardVars.lastBonus + lpStakingPool.bonusRate() * duration
                )
            );

            _accountRewardVars.photonRewards = uint96(photonEarned(_owner));
            _accountRewardVars.photonRewardPerTokenPaid = _generalRewardVars
                .photonRewardPerTokenStored;
        }

        lpStakingPool.setAccountRewardVars(_owner, _accountRewardVars);
        lpStakingPool.setAccountVars(_owner, _accountVars);
        lpStakingPool.setGeneralRewardVars(_generalRewardVars);
    }

    function setFullBonusCutoff(uint256 _fullBonusCutoff)
        external
        onlyOwner 
    {
        fullBonusCutoff = _fullBonusCutoff;
    }

    function setXphotonCutoff(uint256 _xphotonCutoff)
        external
        onlyOwner 
    {
        xphotonCutoff = _xphotonCutoff;
    }

    function setReward(uint256 _rewardRate, uint256 _xphotonRewardRate, uint256 _minRewardStake)
        external
        onlyOwner
    {
        lpStakingPool.setRewardRate(_rewardRate);
        lpStakingPool.setXphotonRewardRate(_xphotonRewardRate);
        lpStakingPool.setMinRewardStake(_minRewardStake);
    }

    function setBonus(uint256 _maxBonus, uint256 _bonusDuration)
        external
        onlyOwner
    {
        lpStakingPool.setMaxBonus(_maxBonus * BONUS_DECIMALS);
        lpStakingPool.setBonusDuration(_bonusDuration);
        lpStakingPool.setBonusRate(lpStakingPool.maxBonus() / _bonusDuration);
    }

    function setTickRange(int24 _maxTickLower, int24 _minTickUpper)
        external
        onlyOwner
    {
        lpStakingPool.setMinTickUpper(_minTickUpper);
        lpStakingPool.setMaxTickLower(_maxTickLower);
    }

    function setFeeRequired(uint24 _feeRequired) external onlyOwner {
        lpStakingPool.setFeeRequired(_feeRequired);
    }

    function stake(uint32 _tokenId)
        external        
    {
        balanceUpdate(_msgSender());

        (
            ,
            ,
            //uint96 nonce,
            //address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity, //uint256 feeGrowthInside0LastX128, //uint256 feeGrowthInside1LastX128, //uint128 tokensOwed0,
            ,
            ,
            ,

        ) = //uint128 tokensOwed1
            lpStakingPool.rainiLpNft().positions(_tokenId);

        require(
            tickUpper > lpStakingPool.minTickUpper(),
            "nft bad"
        );
        require(
            tickLower < lpStakingPool.maxTickLower(),
            "nft bad"
        );
        require(
            (token0 == lpStakingPool.exchangeTokenAddress() && token1 == lpStakingPool.rainiTokenAddress()) ||
                (token1 == lpStakingPool.exchangeTokenAddress() &&
                    token0 == lpStakingPool.rainiTokenAddress()),
            "nft bad"
        );
        require(fee ==lpStakingPool.feeRequired(), "fee bad");

        lpStakingPool.stakeLpNft(_msgSender(), _tokenId);

        lpStakingPool.setTotalSupply(lpStakingPool.totalSupply() + liquidity);

        uint256 currentStake = lpStakingPool.staked(_msgSender());    
        lpStakingPool.setStaked(_msgSender(), currentStake + liquidity);

        IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = lpStakingPool.accountRewardVars(_msgSender());

        if (block.timestamp <= fullBonusCutoff) {
            _accountRewardVars.lastBonus = uint64(lpStakingPool.maxBonus());
        } else {
            _accountRewardVars.lastBonus = uint64(
                (_accountRewardVars.lastBonus * currentStake) /
                    (currentStake + liquidity)
            );
        }

        lpStakingPool.setAccountRewardVars(_msgSender(), _accountRewardVars);

        emit TokensStaked(_msgSender(), liquidity, block.timestamp);
    }

    function withdraw(uint32 _tokenId)
        external
        
    {
        balanceUpdate(_msgSender());
        lpStakingPool.withdrawLpNft(_msgSender(), _tokenId);

        (
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            //uint96 nonce,
            //address operator,
            //address token0,
            //address token1,
            //uint24 fee,
            //int24 tickLower,
            //int24 tickUpper,
            uint128 liquidity,
            ,
            ,
            ,

        ) = lpStakingPool.rainiLpNft().positions(_tokenId);

        uint256 currentStake = lpStakingPool.staked(_msgSender());
        lpStakingPool.setStaked(_msgSender(), currentStake - liquidity);
        lpStakingPool.setTotalSupply(lpStakingPool.totalSupply() - liquidity);

        emit TokensWithdrawn(_msgSender(), liquidity, block.timestamp);
    }

    function mint(address[] calldata _addresses, uint256[] calldata _points)
        external
        onlyMinter
    {
        IRainiLpv3StakingPoolv2.AccountVars memory _accountVars;

        for (uint256 i = 0; i < _addresses.length; i++) {
            _accountVars = lpStakingPool.accountVars(_addresses[i]);
            _accountVars.unicornBalance = uint128(
                _accountVars.unicornBalance + _points[i]
            );
            lpStakingPool.setAccountVars(_addresses[i], _accountVars);
            emit UnicornPointsMinted(_addresses[i], _points[i]);
        }
    }

    function burn(address _owner, uint256 _amount)
        external
        onlyBurner        
    {
        balanceUpdate(_owner);
        IRainiLpv3StakingPoolv2.AccountVars memory _accountVars = lpStakingPool.accountVars(_owner);
        _accountVars.unicornBalance = uint128(
            _accountVars.unicornBalance - _amount
        );
        lpStakingPool.setAccountVars(_owner, _accountVars);

        emit UnicornPointsBurned(_owner, _amount);
    }

    function addPhotonRewardPool(uint256 _amount, uint256 _duration)
        external
        onlyOwner
    {
        balanceUpdate(address(0));
        IRainiLpv3StakingPoolv2.GeneralRewardVars memory _generalRewardVars = lpStakingPool.generalRewardVars();

        if (_generalRewardVars.periodFinish > block.timestamp) {
            uint256 timeRemaining = _generalRewardVars.periodFinish -
                block.timestamp;
            _amount += timeRemaining * _generalRewardVars.photonRewardRate;
        }

        lpStakingPool.photonToken().safeTransferFrom(_msgSender(), address(lpStakingPool), _amount);
        _generalRewardVars.photonRewardRate = uint128(_amount / _duration);
        _generalRewardVars.periodFinish = uint32(block.timestamp + _duration);
        _generalRewardVars.lastUpdateTime = uint32(block.timestamp);
        lpStakingPool.setGeneralRewardVars(_generalRewardVars);
    }

    function abortPhotonRewardPool()
        external
        onlyOwner
    {
        balanceUpdate(address(0));
        IRainiLpv3StakingPoolv2.GeneralRewardVars memory _generalRewardVars = lpStakingPool.generalRewardVars();

        require(
            _generalRewardVars.periodFinish > block.timestamp,
            "pool not active"
        );

        uint256 timeRemaining = _generalRewardVars.periodFinish -
            block.timestamp;
        uint256 remainingAmount = timeRemaining *
            _generalRewardVars.photonRewardRate;
        lpStakingPool.withdrawPhoton(_msgSender(), remainingAmount);

        _generalRewardVars.photonRewardRate = 0;
        _generalRewardVars.periodFinish = uint32(block.timestamp);
        _generalRewardVars.lastUpdateTime = uint32(block.timestamp);
        lpStakingPool.setGeneralRewardVars(_generalRewardVars);
    }

    function withdrawReward()
        external
    {
        balanceUpdate(_msgSender());
        uint256 reward = photonEarned(_msgSender());
        require(reward > 1, "no reward");
        if (reward > 1) {
            IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = 
                lpStakingPool.accountRewardVars(_msgSender());
            _accountRewardVars.photonRewards = 0;
            lpStakingPool.setAccountRewardVars(_msgSender(), _accountRewardVars);
            lpStakingPool.withdrawPhoton(_msgSender(), reward);
        }

        emit RewardWithdrawn(_msgSender(), reward, block.timestamp);
    }

    function withdrawXphoton(uint256 _amount) 
        external
    {
        balanceUpdate(_msgSender());     
        IRainiLpv3StakingPoolv2.AccountVars memory _accountVars = lpStakingPool.accountVars(_msgSender());
        _accountVars.xphotonBalance -= uint128(_amount);
        lpStakingPool.xphotonToken().mint(_msgSender(), _amount);
        lpStakingPool.setAccountVars(_msgSender(), _accountVars);
    }



    // Views
    
    function getRewardByDuration(
        address _owner,
        uint256 _amount,
        uint256 _duration
    ) public view returns (uint256) {
        return calculateReward(_owner, _amount, _duration, lpStakingPool.rewardRate(), true);
    }

    function getStaked(address _owner) public view returns (uint256) {
        return lpStakingPool.staked(_owner);
    }

    function getStakedPositions(address _owner)
        public
        view
        returns (uint32[] memory)
    {
        return lpStakingPool.getStakedPositions(_owner);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        uint256 reward = calculateReward(
            _owner,
            lpStakingPool.staked(_owner),
            block.timestamp - lpStakingPool.accountRewardVars(_owner).lastUpdated,
            lpStakingPool.rewardRate(),
            true
        );
        return lpStakingPool.accountVars(_owner).unicornBalance + reward;
    }

    function getCurrentBonus(address _owner) public view returns (uint256) {
        IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = lpStakingPool.accountRewardVars(_owner);

        if (lpStakingPool.staked(_owner) == 0) {
            return 0;
        }
        uint256 duration = block.timestamp - _accountRewardVars.lastUpdated;
        return
            Math.min(
                lpStakingPool.maxBonus(),
                _accountRewardVars.lastBonus + lpStakingPool.bonusRate() * duration
            );
    }

    function getCurrentAvgBonus(address _owner, uint256 _duration)
        public
        view
        returns (uint256)
    {
        IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = lpStakingPool.accountRewardVars(_owner);

        if (lpStakingPool.staked(_owner) == 0) {
            return 0;
        }
        uint256 avgBonus;
        if (_accountRewardVars.lastBonus < lpStakingPool.maxBonus()) {
            uint256 durationTillMax = (lpStakingPool.maxBonus() -
                _accountRewardVars.lastBonus) / lpStakingPool.bonusRate();
            if (_duration > durationTillMax) {
                uint256 avgWeightedBonusTillMax = ((_accountRewardVars
                    .lastBonus + lpStakingPool.maxBonus()) * durationTillMax) / 2;
                uint256 weightedMaxBonus = lpStakingPool.maxBonus() *
                    (_duration - durationTillMax);

                avgBonus =
                    (avgWeightedBonusTillMax + weightedMaxBonus) /
                    _duration;
            } else {
                avgBonus =
                    (_accountRewardVars.lastBonus +
                        lpStakingPool.bonusRate() *
                        _duration +
                        _accountRewardVars.lastBonus) /
                    2;
            }
        } else {
            avgBonus = lpStakingPool.maxBonus();
        }
        return avgBonus;
    }

    function calculateReward(
        address _owner,
        uint256 _amount,
        uint256 _duration,
        uint256 _rewardRate,
        bool _addBonus
    ) public view returns (uint128) {
        uint256 reward = (_duration * _rewardRate * _amount) /
            (REWARD_DECIMALS * lpStakingPool.minRewardStake());

        return _addBonus ? calculateBonus(_owner, reward, _duration) : uint128(reward);
    }

    function calculateBonus(
        address _owner,
        uint256 _amount,
        uint256 _duration
    ) public view returns (uint128) {
        uint256 avgBonus = getCurrentAvgBonus(_owner, _duration);
        return uint128(_amount + (_amount * avgBonus) / BONUS_DECIMALS / 100);
    }

    // PHOTON rewards

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, lpStakingPool.generalRewardVars().periodFinish);
    }

    function photonRewardPerToken() public view returns (uint256) {
        IRainiLpv3StakingPoolv2.GeneralRewardVars memory _generalRewardVars = lpStakingPool.generalRewardVars();

        if (lpStakingPool.totalSupply() == 0) {
            return _generalRewardVars.photonRewardPerTokenStored;
        }

        return
            _generalRewardVars.photonRewardPerTokenStored +
            (uint256(
                lastTimeRewardApplicable() - _generalRewardVars.lastUpdateTime
            ) *
                _generalRewardVars.photonRewardRate *
                PHOTON_REWARD_DECIMALS) /
            lpStakingPool.totalSupply();
    }

    function photonEarned(address account) public view returns (uint256) {
        IRainiLpv3StakingPoolv2.AccountRewardVars memory _accountRewardVars = lpStakingPool.accountRewardVars(account);

        uint256 calculatedEarned = (uint256(lpStakingPool.staked(account)) *
            (photonRewardPerToken() -
                _accountRewardVars.photonRewardPerTokenPaid)) /
            PHOTON_REWARD_DECIMALS +
            _accountRewardVars.photonRewards;
        uint256 poolBalance = address(lpStakingPool.photonToken()) != address(0) ? lpStakingPool.photonToken().balanceOf(address(lpStakingPool)) : 0;
        // some rare case the reward can be slightly bigger than real number, we need to check against how much we have left in pool
        if (calculatedEarned > poolBalance) return poolBalance;
        return calculatedEarned;
    }


    function balanceOfXphoton(address _owner) public view returns (uint256) {
        uint256 reward = calculateReward(
            _owner,
            lpStakingPool.staked(_owner),
            uint32(Math.min(block.timestamp, xphotonCutoff)) - lpStakingPool.accountRewardVars(_owner).lastUpdated,
            lpStakingPool.xphotonRewardRate(),
            false
        );
        return lpStakingPool.accountVars(_owner).xphotonBalance + reward;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20UtilityToken is IERC20 {
    function mint(address, uint256) external;
}

interface INonfungiblePositionManager is IERC721 {
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

interface IRainiLpv3StakingPoolv2 {

    struct GeneralRewardVars {
        uint32 lastUpdateTime;
        uint32 periodFinish;
        uint128 photonRewardPerTokenStored;
        uint128 photonRewardRate;
    }

    struct AccountRewardVars {
        uint64 lastBonus;
        uint32 lastUpdated;
        uint96 photonRewards;
        uint128 photonRewardPerTokenPaid;
    }

    struct AccountVars {
        uint128 xphotonBalance;
        uint128 unicornBalance;
    }

    function rewardRate() external view returns (uint256);
    function xphotonRewardRate() external view returns (uint256);
    function minRewardStake() external view returns (uint256);

    function maxBonus() external view returns (uint256);
    function bonusDuration() external view returns (uint256);
    function bonusRate() external view returns (uint256);

    function rainiLpNft() external view returns (INonfungiblePositionManager);
    function photonToken() external view returns (IERC20);
    function xphotonToken() external view returns (IERC20UtilityToken);
    function exchangeTokenAddress() external view returns (address);
    function rainiTokenAddress() external view returns (address);    

    function totalSupply() external view returns (uint256);
    function generalRewardVars() external view returns (GeneralRewardVars memory);

    function accountRewardVars(address) external view returns (AccountRewardVars memory);
    function accountVars(address) external view returns (AccountVars memory);
    function staked(address) external view returns (uint256);
    function getStakedPositions(address) external view returns (uint32[] memory);

    function minTickUpper() external view returns (int24);
    function maxTickLower() external view returns (int24);
    function feeRequired() external view returns (uint24);


    function setRewardRate(uint256) external;
    function setXphotonRewardRate(uint256) external;
    function setMinRewardStake(uint256) external;

    function setMaxBonus(uint256) external;
    function setBonusDuration(uint256) external;
    function setBonusRate(uint256) external;

    function setPhotonToken(address) external;

    function setGeneralRewardVars(GeneralRewardVars memory) external;

    function setAccountRewardVars(address, AccountRewardVars memory) external;
    function setAccountVars(address, AccountVars memory) external;

    function setStaked(address, uint256 _staked) external;
    function setTotalSupply(uint256 _totalSupply) external;

    function withdrawPhoton(address, uint256 _amount) external;

    function stakeLpNft(address, uint32 _tokenId) external;
    function withdrawLpNft(address, uint32 _tokenId) external;


    function setMinTickUpper(int24) external;
    function setMaxTickLower(int24) external;
    function setFeeRequired(uint24) external;


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}