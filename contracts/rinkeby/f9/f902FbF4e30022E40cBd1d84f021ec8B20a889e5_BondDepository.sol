// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./BondDepositoryStorage.sol";
import "./common/ProxyAccessCommon.sol";

import "./libraries/SafeERC20.sol";

import "./interfaces/IBondDepository.sol";
import "./interfaces/IBondDepositoryEvent.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
// import "hardhat/console.sol";

interface IIIERC20 {
    function decimals() external view returns (uint256);
}

interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IITOSValueCalculator {
    function convertAssetBalanceToWethOrTos(address _asset, uint256 _amount)
        external view
        returns (bool existedWethPool, bool existedTosPool,  uint256 priceWethOrTosPerAsset, uint256 convertedAmount);
}

interface IITreasury {

    function getETHPricePerTOS() external view returns (uint256 price);
    function getMintRate() external view returns (uint256);
    function mintRateDenominator() external view returns (uint256);

    function requestMint(uint256 _mintAmount, bool _distribute) external ;
    function addBondAsset(address _address) external;
}

contract BondDepository is
    BondDepositoryStorage,
    ProxyAccessCommon,
    IBondDepository,
    IBondDepositoryEvent
{
    using SafeERC20 for IERC20;

    modifier nonEndMarket(uint256 id_) {
        require(markets[id_].endSaleTime > block.timestamp, "BondDepository: closed market");
        require(markets[id_].capacity > 0 , "BondDepository: zero capacity" );
        _;
    }

    modifier isEthMarket(uint256 id_) {
        require(markets[id_].quoteToken == address(0) && markets[id_].endSaleTime > 0,
            "BondDepository: not ETH market"
        );
        _;
    }

    modifier nonEthMarket(uint256 id_) {
        require(
            markets[id_].quoteToken != address(0) && markets[id_].endSaleTime > 0,
            "BondDepository: ETH market"
        );
        _;
    }

    constructor() {

    }

    ///////////////////////////////////////
    /// onlyPolicyOwner
    //////////////////////////////////////

    /// @inheritdoc IBondDepository
    function create(
        address _token,
        uint256[4] calldata _market
    )
        external
        override
        onlyPolicyOwner
        nonZero(_market[0])
        nonZero(_market[2])
        nonZero(_market[3])
        returns (uint256 id_)
    {
        require(_market[0] >= 100 ether, "need the totalSaleAmount > 100");
        id_ = staking.generateMarketId();
        require(markets[id_].endSaleTime == 0, "already registered market");
        require(_market[1] > block.timestamp, "endSaleTime has passed");

        markets[id_] = LibBondDepository.Market({
                            quoteToken: _token,
                            capacity: _market[0],
                            endSaleTime: _market[1],
                            maxPayout: _market[3],
                            tosPrice: _market[2]
                        });

        marketList.push(id_);
        if (_token != address(0)) IITreasury(treasury).addBondAsset(_token);

        emit CreatedMarket(id_, _token, _market);
    }

    /// @inheritdoc IBondDepository
    function increaseCapacity(
        uint256 _marketId,
        uint256 _amount
    )   external override onlyPolicyOwner
        nonZero(_amount)
    {
        require(markets[_marketId].maxPayout > 0, "non-exist market");

        LibBondDepository.Market storage _info = markets[_marketId];
        _info.capacity += _amount;

        emit IncreasedCapacity(_marketId, _amount);
    }

    /// @inheritdoc IBondDepository
    function decreaseCapacity(
        uint256 _marketId,
        uint256 _amount
    ) external override onlyPolicyOwner
        nonZero(_amount)
    {
        require(markets[_marketId].capacity > _amount, "not enough capacity");
        require(markets[_marketId].maxPayout > 0, "non-exist market");

        LibBondDepository.Market storage _info = markets[_marketId];
        _info.capacity -= _amount;

        emit DecreasedCapacity(_marketId, _amount);
    }

    /// @inheritdoc IBondDepository
    function changeCloseTime(
        uint256 _marketId,
        uint256 closeTime
    )   external override onlyPolicyOwner
        //nonEndMarket(_marketId)
        //nonZero(closeTime)
    {
        require(closeTime > block.timestamp, "past closeTime");
        require(markets[_marketId].maxPayout > 0, "non-exist market");

        LibBondDepository.Market storage _info = markets[_marketId];
        _info.endSaleTime = closeTime;

        emit ChangedCloseTime(_marketId, closeTime);
    }

    /// @inheritdoc IBondDepository
    function changeMaxPayout(
        uint256 _marketId,
        uint256 _amount
    )   external override onlyPolicyOwner
        nonEndMarket(_marketId)
        nonZero(_amount)
    {
        LibBondDepository.Market storage _info = markets[_marketId];
        _info.maxPayout = _amount;

        emit ChangedMaxPayout(_marketId, _amount);
    }

    /// @inheritdoc IBondDepository
    function changePrice(
        uint256 _marketId,
        uint256 _tosPrice
    )   external override onlyPolicyOwner
        nonEndMarket(_marketId)
        nonZero(_tosPrice)
    {
        LibBondDepository.Market storage _info = markets[_marketId];
        _info.tosPrice = _tosPrice;

        emit ChangedPrice(_marketId, _tosPrice);
    }

    /// @inheritdoc IBondDepository
    function close(uint256 _id) external override onlyPolicyOwner {
        require(markets[_id].endSaleTime > 0, "empty market");
        require(markets[_id].endSaleTime > block.timestamp || markets[_id].capacity == 0, "already closed");
        LibBondDepository.Market storage _info = markets[_id];
        _info.endSaleTime = block.timestamp;
        _info.capacity = 0;
        emit ClosedMarket(_id);
    }

    ///////////////////////////////////////
    /// Anyone can use.
    //////////////////////////////////////

    /// @inheritdoc IBondDepository
    function ETHDeposit(
        uint256 _id,
        uint256 _amount
    )
        external payable override
        nonEndMarket(_id)
        isEthMarket(_id)
        nonZero(_amount)
        returns (uint256 payout_)
    {
        require(msg.value == _amount, "Depository: ETH amounts do not match");

        uint256 _tosPrice = 0;

        (payout_, _tosPrice) = _deposit(msg.sender, _amount, _id);

        uint256 id = _id;
        uint256 stakeId = staking.stakeByBond(msg.sender, payout_, id, _tosPrice);

        payable(treasury).transfer(msg.value);

        emit ETHDeposited(msg.sender, id, stakeId, _amount, payout_);
    }


    /// @inheritdoc IBondDepository
    function ETHDepositWithSTOS(
        uint256 _id,
        uint256 _amount,
        uint256 _lockWeeks
    )
        external payable override
        nonEndMarket(_id)
        isEthMarket(_id)
        nonZero(_amount)
        nonZero(_lockWeeks)
        returns (uint256 payout_)
    {
        require(msg.value == _amount, "Depository: ETH amounts do not match");
        uint256 _tosPrice = 0;
        (payout_, _tosPrice) = _deposit(msg.sender, _amount, _id);

        uint256 id = _id;
        uint256 stakeId = staking.stakeGetStosByBond(msg.sender, payout_, id, _lockWeeks, _tosPrice);

        payable(treasury).transfer(msg.value);

        emit ETHDepositedWithSTOS(msg.sender, id, stakeId, _amount, _lockWeeks, payout_);
    }


    function _deposit(
        address user,
        uint256 _amount,
        uint256 _marketId
    ) internal nonReentrant returns (uint256 _payout, uint256 _tosPrice) {

        LibBondDepository.Market storage market = markets[_marketId];
        _tosPrice = market.tosPrice;
        require(_amount <= purchasableAssetAmountAtOneTime(_tosPrice, market.maxPayout), "Depository : over maxPay");

        _payout = calculateTosAmountForAsset(_tosPrice, _amount);
        require(_payout > 0, "zero staking amount");

        uint256 mrAmount = _amount * IITreasury(treasury).getMintRate() / 1e18;
        require(mrAmount >= _payout, "mintableAmount is less than staking amount.");
        require(_payout <= market.capacity, "Depository: sold out");

        market.capacity -= _payout;

        //check closing
        if (market.capacity <= 100 ether) {
           market.capacity = 0;
           emit ClosedMarket(_marketId);
        }

        IITreasury(treasury).requestMint(mrAmount, true);

        emit Deposited(user, _marketId, _amount, _payout, true, mrAmount);
    }

    ///////////////////////////////////////
    /// VIEW
    //////////////////////////////////////

    /// @inheritdoc IBondDepository
    function calculateTosAmountForAsset(
        uint256 _tosPrice,
        uint256 _amount
    )
        public override
        pure
        returns (uint256 payout)
    {
        return (_amount * _tosPrice / 1e18);
    }

    /// @inheritdoc IBondDepository
    function purchasableAssetAmountAtOneTime(
        uint256 _tosPrice,
        uint256 _maxPayout
    )
        public override pure returns (uint256 maxPayout_)
    {
        return ( _maxPayout *  1e18 / _tosPrice );
    }

    /// @inheritdoc IBondDepository
    function getBonds() external override view
        returns (
            uint256[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 len = marketList.length;
        uint256[] memory _marketIds = new uint256[](len);
        address[] memory _quoteTokens = new address[](len);
        uint256[] memory _capacities = new uint256[](len);
        uint256[] memory _endSaleTimes = new uint256[](len);
        uint256[] memory _pricesTos = new uint256[](len);

        for (uint256 i = 0; i < len; i++){
            _marketIds[i] = marketList[i];
            _quoteTokens[i] = markets[_marketIds[i]].quoteToken;
            _capacities[i] = markets[_marketIds[i]].capacity;
            _endSaleTimes[i] = markets[_marketIds[i]].endSaleTime;
            _pricesTos[i] = markets[_marketIds[i]].tosPrice;
        }
        return (_marketIds, _quoteTokens, _capacities, _endSaleTimes, _pricesTos);
    }

    /// @inheritdoc IBondDepository
    function getMarketList() external override view returns (uint256[] memory) {
        return marketList;
    }

    /// @inheritdoc IBondDepository
    function totalMarketCount() external override view returns (uint256) {
        return marketList.length;
    }

    /// @inheritdoc IBondDepository
    function viewMarket(uint256 _index) external override view
        returns (
            address quoteToken,
            uint256 capacity,
            uint256 endSaleTime,
            uint256 maxPayout,
            uint256 tosPrice
            )
    {
        return (
            markets[_index].quoteToken,
            markets[_index].capacity,
            markets[_index].endSaleTime,
            markets[_index].maxPayout,
            markets[_index].tosPrice
        );
    }

    /// @inheritdoc IBondDepository
    function isOpened(uint256 _index) external override view returns (bool closedBool)
    {
        if (block.timestamp < markets[_index].endSaleTime && markets[_index].capacity > 0) {
            return true;
        } else {
            return false;
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./libraries/LibBondDepository.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IStaking.sol";

contract BondDepositoryStorage {

    IERC20 public tos;
    IStaking public staking;
    address public treasury;
    address public calculator;
    address public uniswapV3Factory;
    address public dtos;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    uint256[] public marketList;
    mapping(uint256 => LibBondDepository.Market) public markets;


    modifier nonZero(uint256 tokenId) {
        require(tokenId != 0, "BondDepository: zero uint");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(
            account != address(0),
            "BondDepository:zero address"
        );
        _;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessRoleCommon.sol";

contract ProxyAccessCommon is AccessRoleCommon, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender) || isProxyAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    modifier onlyProxyOwner() {
        require(isProxyAdmin(msg.sender), "Accessible: Caller is not an proxy admin");
        _;
    }

    modifier onlyPolicyOwner() {
        require(isPolicy(msg.sender), "Accessible: Caller is not an policy admin");
        _;
    }

    function addProxyAdmin(address _owner)
        external
        onlyProxyOwner
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    function removeProxyAdmin()
        public virtual onlyProxyOwner
    {
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function transferProxyAdmin(address newAdmin)
        external virtual
        onlyProxyOwner
    {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyProxyOwner {
        grantRole(PROJECT_ADMIN_ROLE, account);
    }

    /// @dev remove admin
    function removeAdmin() public virtual onlyOwner {
        renounceRole(PROJECT_ADMIN_ROLE, msg.sender);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(PROJECT_ADMIN_ROLE, newAdmin);
        renounceRole(PROJECT_ADMIN_ROLE, msg.sender);
    }

    function addPolicy(address _account) public virtual onlyProxyOwner {
        grantRole(POLICY_ROLE, _account);
    }

    function removePolicy() public virtual onlyPolicyOwner {
        renounceRole(POLICY_ROLE, msg.sender);
    }

    function transferPolicyAdmin(address newAdmin)
        external virtual
        onlyPolicyOwner
    {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(POLICY_ROLE, newAdmin);
        renounceRole(POLICY_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(PROJECT_ADMIN_ROLE, account);
    }

    function isProxyAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function isPolicy(address account) public view virtual returns (bool) {
        return hasRole(POLICY_ROLE, account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IERC20.sol";

interface IBondDepository {

    ///////////////////////////////////////
    /// onlyPolicyOwner
    //////////////////////////////////////

    /**
     * @dev                creates a new market type
     * @param _token       토큰 주소
     * @param _market      [팔려고 하는 tos의 목표치, 판매 끝나는 시간, tos token의 가격, 한번에 구매 가능한 TOS물량]
     * @return id_         ID of new bond market
     */
    function create(
        address _token,
        uint256[4] calldata _market
    ) external returns (uint256 id_);

    /**
     * @dev                increase the market Capacity
     * @param _marketId    marketId
     * @param amount       increase amount
     */
    function increaseCapacity(
        uint256 _marketId,
        uint256 amount
    )   external;

    /**
     * @dev                decrease the market Capacity
     * @param _marketId    marketId
     * @param amount       decrease amount
     */
    function decreaseCapacity(
        uint256 _marketId,
        uint256 amount
    ) external;

    /**
     * @dev                change the market closeTime
     * @param _marketId    marketId
     * @param closeTime    closeTime
     */
    function changeCloseTime(
        uint256 _marketId,
        uint256 closeTime
    )   external ;

    /**
     * @dev                change the market maxpayout(Maximum amount that can be purchased at one time)
     * @param _marketId    marketId
     * @param _amount      maxPayout Amount
     */
    function changeMaxPayout(
        uint256 _marketId,
        uint256 _amount
    )   external;

    /**
     * @dev                change the market price
     * @param _marketId    marketId
     * @param _tosPrice  tosPrice
     */
    function changePrice(
        uint256 _marketId,
        uint256 _tosPrice
    )   external ;

    /**
     * @dev        close the market
     * @param _id  ID of market to close
     */
    function close(uint256 _id) external;

    ///////////////////////////////////////
    /// Anyone can use.
    //////////////////////////////////////

    /// @dev deposit with ether
    /// @param _id  the market id
    /// @param _amount  the amount of deposit
    /// @return payout_  the amount of staking
    function ETHDeposit(
        uint256 _id,
        uint256 _amount
    ) external payable returns (uint256 payout_ );


    /// @dev deposit with erc20 token
    /// @param _id  the market id
    /// @param _amount  the amount of deposit
    /// @param _lockWeeks  the number of weeks for lock
    /// @return payout_  the amount of staking
    function ETHDepositWithSTOS(
        uint256 _id,
        uint256 _amount,
        uint256 _lockWeeks
    ) external payable returns (uint256 payout_);


    ///////////////////////////////////////
    /// VIEW
    //////////////////////////////////////

    /// @dev How much tokens are valued as TOS
    /// @param _tosPrice  the tos price
    /// @param _amount the amount of asset
    /// @return payout  the amount evaluated as TOS
    function calculateTosAmountForAsset(
        uint256 _tosPrice,
        uint256 _amount
    )
        external
        pure
        returns (uint256 payout);


    /// @dev purchasable Asset amount At One Time
    /// @param _tosPrice  the tos price
    /// @param _maxPayout  the max payout
    /// @return maxPayout_  the asset amount
    function purchasableAssetAmountAtOneTime(
        uint256 _tosPrice,
        uint256 _maxPayout
    ) external pure returns (uint256 maxPayout_);

    /// @dev Return information from all markets
    /// @return marketIds Array of total MarketIDs
    /// @return quoteTokens Array of total market's quoteTokens
    /// @return capacities Array of total market's capacities
    /// @return endSaleTimes Array of total market's endSaleTimes
    /// @return pricesTos Array of total market's pricesTos
    function getBonds() external view
        returns (
            uint256[] memory marketIds,
            address[] memory quoteTokens,
            uint256[] memory capacities,
            uint256[] memory endSaleTimes,
            uint256[] memory pricesTos
        );

    /// @dev Returns all generated marketIDs.
    /// @return memory[]  marketList
    function getMarketList() external view returns (uint256[] memory) ;

    /// @dev Returns the number of created markets.
    /// @return Total number of markets
    function totalMarketCount() external view returns (uint256) ;

    /// @dev Returns information about the market.
    /// @param _index  the market id
    /// @return quoteToken  saleToken Address
    /// @return capacity  tokenSaleAmount
    /// @return endSaleTime  market endTime
    /// @return maxPayout  Amount of tokens that can be purchased for one tx in the market
    /// @return tosPrice  tos price
    function viewMarket(uint256 _index) external view
        returns (
            address quoteToken,
            uint256 capacity,
            uint256 endSaleTime,
            uint256 maxPayout,
            uint256 tosPrice
            );

    /// @dev Return Whether The index market Whether is closed
    /// @param _index  Index in the market
    /// @return closedBool Whether the market is closed
    function isOpened(uint256 _index) external view returns (bool closedBool);



}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IBondDepositoryEvent{

    /// @dev This event occurs when a specific market product is purchased.
    /// @param user  user address
    /// @param marketId  the market id
    /// @param amount the amount
    /// @param payout  Allocated TOS Amount
    /// @param isEth  Whether Ether is available
    /// @param mintAmount  the minting amount of TOS
    event Deposited(address user, uint256 marketId, uint256 amount, uint256 payout, bool isEth, uint256 mintAmount);

    /// @dev This event occurs when a specific market product is created.
    /// @param marketId the market id
    /// @param token  available token address
    /// @param market  [팔려고 하는 tos의 목표치, close time,  tos token의 가격, 한번에 구매 가능한 TOS물량]
    event CreatedMarket(uint256 marketId, address token, uint256[4] market);

    /// @dev This event occurs when a specific market product is closed.
    /// @param marketId the market id
    event ClosedMarket(uint256 marketId);

    /// @dev Events Emitted when Buying Bonding with Ether
    /// @param user the user account
    /// @param marketId the market id
    /// @param stakeId  the stake id
    /// @param amount  the amount of Ether
    /// @param tosValuation  the tos evaluate amount of sending
    event ETHDeposited(address user, uint256 marketId, uint256 stakeId, uint256 amount, uint256 tosValuation);

    /// @dev Event that gives a lockout period and is emitted when purchasing bonding with Ether
    /// @param user name
    /// @param marketId the market id
    /// @param stakeId  the stake id
    /// @param amount  the amount of Ether
    /// @param lockWeeks  the number of weeks to locking
    /// @param tosValuation  the tos evaluate amount of sending
    event ETHDepositedWithSTOS(address user, uint256 marketId, uint256 stakeId, uint256 amount, uint256 lockWeeks, uint256 tosValuation);

    /// @dev Event that occurs when the market capacity is increased
    /// @param _marketId the market id
    /// @param _amount increase capacity amount
    event IncreasedCapacity(uint256 _marketId, uint256  _amount);

    /// @dev Event that occurs when the market capacity is decreased
    /// @param _marketId the market id
    /// @param _amount decrease capacity amount
    event DecreasedCapacity(uint256 _marketId, uint256 _amount);

    /// @dev Event that occurs when the closeTime of the market is change
    /// @param _marketId the market id
    /// @param closeTime the close time
    event ChangedCloseTime(uint256 _marketId, uint256 closeTime);

    /// @dev Event that occurs when the market price changes
    /// @param _marketId the market id
    /// @param _amount maxPayout
    event ChangedMaxPayout(uint256 _marketId, uint256 _amount);

    /// @dev Event that gives a lockout period and is emitted when purchasing bonding with Ether
    /// @param _marketId the market id
    /// @param _tosPrice The price of the tos (price shown in uniswap)
    event ChangedPrice(uint256 _marketId, uint256 _tosPrice);

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

/// @title LibBondDepository
library LibBondDepository
{
     // Info about each type of market
    struct Market {
        address quoteToken;  //token to accept as payment
        uint256 capacity;   //remain sale volume
        uint256 endSaleTime;    //saleEndTime
        uint256 maxPayout;  // 한 tx에 살수 있는 물량
        uint256 tosPrice;
    }

    // struct Deposit {
    //     uint256 marketId;
    //     uint256 stakeId;
    // }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IStaking {


    /* ========== onlyPolicyOwner ========== */

    /// @dev set the tos, lockTOS, treasury Address
    /// @param _tos       tosAddress
    /// @param _lockTOS   lockTOSAddress
    /// @param _treasury  treausryAddress
    function setAddressInfos(
        address _tos,
        address _lockTOS,
        address _treasury
    ) external;

    /// @dev set setRebasePerEpoch
    /// @param _rebasePerEpoch  the rate for rebase per epoch (eth uint)
    ///                         If input the 0.9 -> 900000000000000000
    function setRebasePerEpoch(
        uint256 _rebasePerEpoch
    ) external;


    /// @dev set index
    /// @param _index  index (eth uint)
    function setIndex(
        uint256 _index
    ) external;

    /// @dev set bond staking
    /// @param _period  _period (seconds)
    function setBasicBondPeriod(uint256 _period) external ;


    /* ========== onlyOwner ========== */

    /// @dev set basic lock period
    /// @param accounts  the array of account for sync
    /// @param balances  the array of tos amount for sync
    /// @param period  the array of end time for sync
    /// @param tokenId  the array of locktos id for sync
    function syncStos(
        address[] memory accounts,
        uint256[] memory balances,
        uint256[] memory period,
        uint256[] memory tokenId
    ) external ;



    /* ========== onlyBonder ========== */


    /// @dev Increment and return the market ID.
    function generateMarketId() external returns (uint256);

    /// @dev bonder stake the tos mintted when user purchase the bond with asset.
    /// @param to  the user address
    /// @param _amount  the tos amount
    /// @param _marketId  the market id
    /// @param tosPrice  the tos price per Token
    /// @return stakeId  the stake id
    function stakeByBond(
        address to,
        uint256 _amount,
        uint256 _marketId,
        uint256 tosPrice
    ) external returns (uint256 stakeId);



    /// @dev bonder stake the tos mintted when user purchase the bond with asset.
    /// @param _to  the user address
    /// @param _amount  the tos amount
    /// @param _marketId  the market id
    /// @param _periodWeeks  the number of lockup weeks
    /// @param tosPrice  the tos price per Token
    /// @return stakeId  the stake id
    function stakeGetStosByBond(
        address _to,
        uint256 _amount,
        uint256 _marketId,
        uint256 _periodWeeks,
        uint256 tosPrice
    ) external returns (uint256 stakeId);


    /* ========== Anyone can execute ========== */


    /// @dev user can stake the tos amount.
    /// @param _amount  the tos amount
    /// @return stakeId  the stake id
    function stake(
        uint256 _amount
    ) external  returns (uint256 stakeId);


    /// @dev user can stake the tos amount and get stos.
    /// @param _amount  the tos amount
    /// @param _periodWeeks the number of lockup weeks
    /// @return stakeId  the stake id
    function stakeGetStos(
        uint256 _amount,
        uint256 _periodWeeks
    ) external  returns (uint256 stakeId);


    /// @dev increase the tos amount in stakeId of simple stake product (without lock, without maeketid)
    /// @param _stakeId  the stake id
    /// @param _amount the tos amount
    function increaseAmountForSimpleStake(
        uint256 _stakeId,
        uint256 _amount
    )   external;

    /// @dev Used to adjust the amount of staking after the lockout period ends
    /// @param _stakeId     the stake id
    /// @param _addAmount   addAmount
    /// @param _claimAmount claimAmount
    /// @param _periodWeeks add lock Weeks
    function resetStakeGetStosAfterLock(
        uint256 _stakeId,
        uint256 _addAmount,
        uint256 _claimAmount,
        uint256 _periodWeeks
    ) external;

    /// @dev Used to adjust the amount of staking after the lockout period ends
    /// @param _stakeId     the stake id
    /// @param _addAmount   addAmount
    /// @param _periodWeeks add lock Weeks
    function resetStakeGetStosAfterLock(
        uint256 _stakeId,
        uint256 _addAmount,
        uint256 _periodWeeks
    ) external;

    /// @dev Used to adjust the amount of staking after the lockout period ends
    /// @param _stakeId     the stake id
    /// @param _claimAmount claimAmount
    function resetStakeGetStosAfterLock(
        uint256 _stakeId,
        uint256 _claimAmount
    ) external;


    /// @dev Used to add a toss amount before the end of the lock period or to extend the period
    /// @param _stakeId  the stake id
    /// @param _amount   add amount
    function increaseBeforeEndOrNonEnd(
        uint256 _stakeId,
        uint256 _amount
    ) external;


    /// @dev Used to add a toss amount before the end of the lock period or to extend the period
    /// @param _stakeId  the stake id
    /// @param _amount   add amount
    /// @param _unlockWeeks add lock weeks
    function increaseBeforeEndOrNonEnd(
        uint256 _stakeId,
        uint256 _amount,
        uint256 _unlockWeeks
    ) external;


    /// @dev For staking items that are not locked up, use when claiming
    /// @param _stakeId  the stake id
    /// @param _claimAmount claimAmount
    function claimForSimpleType(
        uint256 _stakeId,
        uint256 _claimAmount
    ) external;


    /// @dev Used to unstake a specific staking ID
    /// @param _stakeId  the stake id
    function unstake(
        uint256 _stakeId
    ) external;

    /// @dev Used when unstaking multiple staking IDs
    /// @param _stakeIds  the stake id
    function multiUnstake(
        uint256[] calldata _stakeIds
    ) external;


    /// @dev Index adjustment, compound interest
    function rebaseIndex() external;

    /* ========== VIEW ========== */


    /// @dev Returns the remaining amount of LTOS for a specific staking ID.
    /// @param _stakeId  the stake id
    /// @return return Amount of LTOS remaining
    function remainedLtos(uint256 _stakeId) external view returns (uint256) ;


    /// @dev Returns the claimable amount of LTOS for a specific staking ID.
    /// @param _stakeId  the stake id
    /// @return return Claimable amount of LTOS
    function claimableLtos(uint256 _stakeId) external view returns (uint256);

    /// @dev Returns the claimable TOS amount of a specific staking ID.
    /// @param _stakeId  the stake id
    /// @return return Claimable amount of TOS
    function claimableTos(uint256 _stakeId) external view returns (uint256);


    /// @dev Returns the index when rebase is executed once in the current index.
    function nextIndex() external view returns (uint256);

    /// @dev Returns the current Index value
    function getIndex() external view returns(uint256) ;

    /// @dev Returns the possible Index value
    function possibleIndex() external view returns (uint256);

    /// @dev Returns a list of staking IDs owned by a specific account.
    /// @param _addr ownerAddress
    /// @return return List of staking IDs you have
    function stakingOf(address _addr)
        external
        view
        returns (uint256[] memory);


    /// @dev Returns the amount of remaining LTOS in _stakeId
    /// @param _stakeId stakeId
    /// @return return Amount of LTOS remaining
    function balanceOfId(uint256 _stakeId)
        external
        view
        returns (uint256);


    /// @dev Returns the amount of LTOS remaining on the account
    /// @param _addr address
    /// @return balance Returns the amount of LTOS remaining
    function balanceOf(address _addr)
        external
        view
        returns (uint256 balance);

    /// @dev Returns the time remaining until the next rebase time
    /// @return time
    function secondsToNextEpoch() external view returns (uint256);

    /// @dev  Compensation for LTOS with TOS and the remaining amount of TOS
    /// @return TOS with treasury - minus staking interest
    function runwayTos() external view returns (uint256);

    /// @dev Convert tos amount to LTOS (based on current index)
    /// @param amount  tosAmount
    /// @return return LTOS Amount
    function getTosToLtos(uint256 amount) external view returns (uint256);

    /// @dev Convert LTOS to TOS (based on current index)
    /// @param ltos  LTOS Amount
    /// @return return TOS Amount
    function getLtosToTos(uint256 ltos) external view returns (uint256);

    /// @dev Amount of TOS staked by users
    /// @param stakeId  the stakeId
    function stakedOf(uint256 stakeId) external view returns (uint256);

    /// @dev Total staked toss amount (principal + interest of all users)
    function stakedOfAll() external view returns (uint256) ;

    /// @dev Detailed information of specific staking ID
    /// @param stakeId  the stakeId
    function stakeInfo(uint256 stakeId) external view returns (
        address staker,
        uint256 deposit,
        uint256 LTOS,
        uint256 endTime,
        uint256 marketId
    );

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessRoleCommon {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
    bytes32 public constant PROJECT_ADMIN_ROLE = keccak256("PROJECT_ADMIN_ROLE");

    bytes32 public constant POLICY_ROLE = keccak256("POLICY_ROLE");
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