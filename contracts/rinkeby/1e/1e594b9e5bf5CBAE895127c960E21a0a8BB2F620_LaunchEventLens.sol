// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./interfaces/ILaunchEvent.sol";
import "./interfaces/IRocketJoeFactory.sol";

/// @title Launch Event Lens
/// @author Trader Joe
/// @notice Helper contract to fetch launch event data
contract LaunchEventLens {
    struct LaunchEventData {
        uint256 auctionStart;
        uint256 avaxAllocated;
        uint256 avaxReserve;
        uint256 floorPrice;
        uint256 incentives;
        uint256 issuerTimelock;
        uint256 maxAllocation;
        uint256 maxWithdrawPenalty;
        uint256 pairBalance;
        uint256 penalty;
        uint256 phaseOneDuration;
        uint256 phaseOneNoFeeDuration;
        uint256 phaseTwoDuration;
        uint256 rJoePerAvax;
        uint256 tokenAllocated;
        uint256 tokenDecimals;
        uint256 tokenIncentivesPercent;
        uint256 tokenReserve;
        uint256 userTimelock;
        address id;
        address token;
        address pair;
        ILaunchEvent.UserInfo userInfo;
    }

    IRocketJoeFactory public rocketJoeFactory;

    /// @notice Create a new instance with required parameters
    /// @param _rocketJoeFactory Address of the RocketJoeFactory
    constructor(address _rocketJoeFactory) {
        rocketJoeFactory = IRocketJoeFactory(_rocketJoeFactory);
    }

    /// @notice Get all launch event datas
    /// @param _offset Index to start at when looking up launch events
    /// @param _limit Maximum number of launch event datas to return
    /// @return Array of all launch event datas
    function getAllLaunchEvents(uint256 _offset, uint256 _limit)
        external
        view
        returns (LaunchEventData[] memory)
    {
        LaunchEventData[] memory launchEventDatas;
        uint256 numLaunchEvents = rocketJoeFactory.numLaunchEvents();

        if (_offset >= numLaunchEvents || _limit == 0) {
            return launchEventDatas;
        }

        uint256 end = _offset + _limit > numLaunchEvents
            ? numLaunchEvents
            : _offset + _limit;
        launchEventDatas = new LaunchEventData[](end - _offset);

        for (uint256 i = _offset; i < end; i++) {
            address launchEventAddr = rocketJoeFactory.allRJLaunchEvents(i);
            ILaunchEvent launchEvent = ILaunchEvent(launchEventAddr);
            launchEventDatas[i] = getLaunchEventData(launchEvent);
        }

        return launchEventDatas;
    }

    /// @notice Get all launch event datas with a given `_user`
    /// @param _offset Index to start at when looking up launch events
    /// @param _limit Maximum number of launch event datas to return
    /// @param _user User to lookup
    /// @return Array of all launch event datas with user info
    function getAllLaunchEventsWithUser(
        uint256 _offset,
        uint256 _limit,
        address _user
    ) external view returns (LaunchEventData[] memory) {
        LaunchEventData[] memory launchEventDatas;
        uint256 numLaunchEvents = rocketJoeFactory.numLaunchEvents();

        if (_offset >= numLaunchEvents || _limit == 0) {
            return launchEventDatas;
        }

        uint256 end = _offset + _limit > numLaunchEvents
            ? numLaunchEvents
            : _offset + _limit;
        launchEventDatas = new LaunchEventData[](end - _offset);

        for (uint256 i = _offset; i < end; i++) {
            address launchEventAddr = rocketJoeFactory.allRJLaunchEvents(i);
            ILaunchEvent launchEvent = ILaunchEvent(launchEventAddr);
            launchEventDatas[i] = getUserLaunchEventData(launchEvent, _user);
        }

        return launchEventDatas;
    }

    /// @notice Get launch event data for a given launch event and user
    /// @param _launchEvent Launch event to lookup
    /// @param _user User to look up
    /// @return Launch event data for the given `_launchEvent` and `_user`
    function getUserLaunchEventData(ILaunchEvent _launchEvent, address _user)
        public
        view
        returns (LaunchEventData memory)
    {
        LaunchEventData memory launchEventData = getLaunchEventData(
            _launchEvent
        );
        launchEventData.incentives = _launchEvent.getIncentives(_user);
        launchEventData.pairBalance = _launchEvent.pairBalance(_user);
        launchEventData.userInfo = _launchEvent.getUserInfo(_user);
        return launchEventData;
    }

    /// @notice Get launch event data for a given launch event
    /// @param _launchEvent Launch event to lookup
    /// @return Launch event data for the given `_launchEvent`
    function getLaunchEventData(ILaunchEvent _launchEvent)
        public
        view
        returns (LaunchEventData memory)
    {
        (uint256 avaxReserve, uint256 tokenReserve) = _launchEvent
            .getReserves();
        IERC20Metadata token = _launchEvent.token();

        return
            LaunchEventData({
                auctionStart: _launchEvent.auctionStart(),
                avaxAllocated: _launchEvent.avaxAllocated(),
                avaxReserve: avaxReserve,
                floorPrice: _launchEvent.floorPrice(),
                incentives: 0,
                issuerTimelock: _launchEvent.issuerTimelock(),
                maxAllocation: _launchEvent.maxAllocation(),
                maxWithdrawPenalty: _launchEvent.maxWithdrawPenalty(),
                penalty: _launchEvent.getPenalty(),
                pairBalance: 0,
                phaseOneDuration: _launchEvent.phaseOneDuration(),
                phaseOneNoFeeDuration: _launchEvent.phaseOneNoFeeDuration(),
                phaseTwoDuration: _launchEvent.phaseTwoDuration(),
                rJoePerAvax: _launchEvent.rJoePerAvax(),
                tokenAllocated: _launchEvent.tokenAllocated(),
                tokenDecimals: token.decimals(),
                tokenIncentivesPercent: _launchEvent.tokenIncentivesPercent(),
                tokenReserve: tokenReserve,
                userTimelock: _launchEvent.userTimelock(),
                id: address(_launchEvent),
                token: address(token),
                pair: address(_launchEvent.pair()),
                userInfo: ILaunchEvent.UserInfo({
                    allocation: 0,
                    balance: 0,
                    hasWithdrawnPair: false,
                    hasWithdrawnIncentives: false
                })
            });
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IJoePair.sol";

interface ILaunchEvent {
    struct UserInfo {
        uint256 allocation;
        uint256 balance;
        bool hasWithdrawnPair;
        bool hasWithdrawnIncentives;
    }

    function initialize(
        address _issuer,
        uint256 _phaseOne,
        address _token,
        uint256 _tokenIncentivesPercent,
        uint256 _floorPrice,
        uint256 _maxWithdrawPenalty,
        uint256 _fixedWithdrawPenalty,
        uint256 _maxAllocation,
        uint256 _userTimelock,
        uint256 _issuerTimelock
    ) external;

    function auctionStart() external view returns (uint256);

    function phaseOneDuration() external view returns (uint256);

    function phaseOneNoFeeDuration() external view returns (uint256);

    function phaseTwoDuration() external view returns (uint256);

    function tokenIncentivesPercent() external view returns (uint256);

    function floorPrice() external view returns (uint256);

    function userTimelock() external view returns (uint256);

    function issuerTimelock() external view returns (uint256);

    function maxAllocation() external view returns (uint256);

    function maxWithdrawPenalty() external view returns (uint256);

    function fixedWithdrawPenalty() external view returns (uint256);

    function rJoePerAvax() external view returns (uint256);

    function getReserves() external view returns (uint256, uint256);

    function token() external view returns (IERC20Metadata);

    function pair() external view returns (IJoePair);

    function avaxAllocated() external view returns (uint256);

    function tokenAllocated() external view returns (uint256);

    function pairBalance(address) external view returns (uint256);

    function getUserInfo(address) external view returns (UserInfo memory);

    function getPenalty() external view returns (uint256);

    function getIncentives(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IRocketJoeFactory {
    event RJLaunchEventCreated(
        address indexed launchEvent,
        address indexed issuer,
        address indexed token,
        uint256 phaseOneStartTime,
        uint256 phaseTwoStartTime,
        uint256 phaseThreeStartTime,
        address rJoe,
        uint256 rJoePerAvax
    );
    event SetRJoe(address indexed token);
    event SetPenaltyCollector(address indexed collector);
    event SetRouter(address indexed router);
    event SetFactory(address indexed factory);
    event SetRJoePerAvax(uint256 rJoePerAvax);
    event SetEventImplementation(address indexed implementation);
    event IssuingTokenDeposited(address indexed token, uint256 amount);
    event PhaseDurationChanged(uint256 phase, uint256 duration);
    event NoFeeDurationChanged(uint256 duration);

    function eventImplementation() external view returns (address);

    function penaltyCollector() external view returns (address);

    function wavax() external view returns (address);

    function rJoePerAvax() external view returns (uint256);

    function router() external view returns (address);

    function factory() external view returns (address);

    function rJoe() external view returns (address);

    function phaseOneDuration() external view returns (uint256);

    function phaseOneNoFeeDuration() external view returns (uint256);

    function phaseTwoDuration() external view returns (uint256);

    function getRJLaunchEvent(address token)
        external
        view
        returns (address launchEvent);

    function isRJLaunchEvent(address token) external view returns (bool);

    function allRJLaunchEvents(uint256) external view returns (address pair);

    function numLaunchEvents() external view returns (uint256);

    function createRJLaunchEvent(
        address _issuer,
        uint256 _phaseOneStartTime,
        address _token,
        uint256 _tokenAmount,
        uint256 _tokenIncentivesPercent,
        uint256 _floorPrice,
        uint256 _maxWithdrawPenalty,
        uint256 _fixedWithdrawPenalty,
        uint256 _maxAllocation,
        uint256 _userTimelock,
        uint256 _issuerTimelock
    ) external returns (address pair);

    function setPenaltyCollector(address) external;

    function setRouter(address) external;

    function setFactory(address) external;

    function setRJoePerAvax(uint256) external;

    function setPhaseDuration(uint256, uint256) external;

    function setPhaseOneNoFeeDuration(uint256) external;

    function setEventImplementation(address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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