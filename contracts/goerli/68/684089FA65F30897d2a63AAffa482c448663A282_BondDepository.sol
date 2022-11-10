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

    function requestMint(uint256 _mintAmount, uint256 _payout, bool _distribute) external ;
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

    modifier nonZeroPayout(uint256 id_) {
        require(
            markets[id_].maxPayout > 0,
            "BondDepository: non-exist market"
        );
        _;
    }
    constructor() {

    }

    ///////////////////////////////////////
    /// onlyPolicyOwner
    //////////////////////////////////////

    function setCalculator(
        address _calculator
    )
        external nonZeroAddress(_calculator) onlyProxyOwner
    {
        require(calculator != _calculator, "same address");
        calculator = _calculator;

        emit SetCalculator(_calculator);
    }

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
        require(_market[0] > 100 ether, "need the totalSaleAmount > 100");
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
    function changeCapacity(
        uint256 _marketId,
        uint256 _amount
    )   external override onlyPolicyOwner
        nonZero(_amount)
        nonZeroPayout(_marketId)
    {
        LibBondDepository.Market storage _info = markets[_marketId];
        require(_info.capacity != _amount, "same capacity");

        if (_info.capacity < _amount)  _info.capacity += (_amount - _info.capacity);
        else _info.capacity -= (_info.capacity - _amount);

        emit ChangedCapacity(_marketId, _amount);
    }

    /// @inheritdoc IBondDepository
    function changeCloseTime(
        uint256 _marketId,
        uint256 closeTime
    )   external override onlyPolicyOwner
        //nonEndMarket(_marketId)
        //nonZero(closeTime)
        nonZeroPayout(_marketId)
    {
        require(closeTime > block.timestamp, "past closeTime");

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

        uint256 stakeId = staking.stakeByBond(msg.sender, payout_, _id, _tosPrice);

        payable(treasury).transfer(msg.value);

        emit ETHDeposited(msg.sender, _id, stakeId, _amount, payout_);
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
        require(_lockWeeks > 1, "_lockWeeks must be greater than 1 week.");
        uint256 _tosPrice = 0;
        (payout_, _tosPrice) = _deposit(msg.sender, _amount, _id);

        uint256 stakeId = staking.stakeGetStosByBond(msg.sender, payout_, _id, _lockWeeks, _tosPrice);

        payable(treasury).transfer(msg.value);

        emit ETHDepositedWithSTOS(msg.sender, _id, stakeId, _amount, _lockWeeks, payout_);
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

        IITreasury(treasury).requestMint(mrAmount, _payout, true);

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
    function viewMarket(uint256 _marketId) external override view
        returns (
            address quoteToken,
            uint256 capacity,
            uint256 endSaleTime,
            uint256 maxPayout,
            uint256 tosPrice
            )
    {
        return (
            markets[_marketId].quoteToken,
            markets[_marketId].capacity,
            markets[_marketId].endSaleTime,
            markets[_marketId].maxPayout,
            markets[_marketId].tosPrice
        );
    }

    /// @inheritdoc IBondDepository
    function isOpened(uint256 _marketId) external override view returns (bool closedBool)
    {
        return block.timestamp < markets[_marketId].endSaleTime && markets[_marketId].capacity > 0;
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

    bool private _entered;

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
        require(_entered != true, "ReentrancyGuard: reentrant call");

        _entered = true;

        _;

        _entered = false;
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
        grantRole(ADMIN_ROLE, account);
    }

    /// @dev remove admin
    function removeAdmin() public virtual onlyOwner {
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(ADMIN_ROLE, newAdmin);
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    function addPolicy(address _account) public virtual onlyProxyOwner {
        grantRole(POLICY_ROLE, _account);
    }

    function removePolicy() public virtual onlyPolicyOwner {
        renounceRole(POLICY_ROLE, msg.sender);
    }

    function deletePolicy(address _account) public virtual onlyProxyOwner {
        revokeRole(POLICY_ROLE, _account);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
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
     * @param _token       token address of deposit asset. For ETH, the address is address(0). Will be used in Phase 2 and 3
     * @param _market      [capacity of the market, market closing time, return on the deposit in TOS, maximum purchasable bond in TOS]
     * @return id_         returns ID of new bond market
     */
    function create(
        address _token,
        uint256[4] calldata _market
    ) external returns (uint256 id_);


    /**
     * @dev                change the market capacity
     * @param _marketId    marketId
     * @param amount       the capacity amount
     */
    function changeCapacity(
        uint256 _marketId,
        uint256 amount
    )   external;


    /**
     * @dev                changes the market closeTime
     * @param _marketId    marketId
     * @param closeTime    closeTime
     */
    function changeCloseTime(
        uint256 _marketId,
        uint256 closeTime
    )   external ;

    /**
     * @dev                changes the maxPayout (maximum purchasable bond in TOS)
     * @param _marketId    marketId
     * @param _amount      maxPayout amount
     */
    function changeMaxPayout(
        uint256 _marketId,
        uint256 _amount
    )   external;

    /**
     * @dev                changes the market price
     * @param _marketId    marketId
     * @param _tosPrice    tosPrice
     */
    function changePrice(
        uint256 _marketId,
        uint256 _tosPrice
    )   external ;

    /**
     * @dev        closes the market
     * @param _id  market id
     */
    function close(uint256 _id) external;

    ///////////////////////////////////////
    /// Anyone can use.
    //////////////////////////////////////

    /// @dev             deposit with ether that does not earn sTOS
    /// @param _id       market id
    /// @param _amount   amount of deposit in ETH
    /// @return payout_  returns amount of TOS earned by the user
    function ETHDeposit(
        uint256 _id,
        uint256 _amount
    ) external payable returns (uint256 payout_ );


    /// @dev              deposit with ether that earns sTOS
    /// @param _id        market id
    /// @param _amount    amount of deposit in ETH
    /// @param _lockWeeks number of weeks for lock
    /// @return payout_   returns amount of TOS earned by the user
    function ETHDepositWithSTOS(
        uint256 _id,
        uint256 _amount,
        uint256 _lockWeeks
    ) external payable returns (uint256 payout_);


    ///////////////////////////////////////
    /// VIEW
    //////////////////////////////////////

    /// @dev              how much is ETH worth in TOS?
    /// @param _tosPrice  amount of TOS per 1 ETH
    /// @param _amount    amount of ETH
    /// @return payout    returns amount of TOS to be earned by the user
    function calculateTosAmountForAsset(
        uint256 _tosPrice,
        uint256 _amount
    )
        external
        pure
        returns (uint256 payout);


    /// @dev               maximum purchasable bond amount in TOS
    /// @param _tosPrice   amount of TOS per 1 ETH
    /// @param _maxPayout  maximum purchasable bond amount in TOS
    /// @return maxPayout_ returns maximum amount of ETH that can be used
    function purchasableAssetAmountAtOneTime(
        uint256 _tosPrice,
        uint256 _maxPayout
    ) external pure returns (uint256 maxPayout_);

    /// @dev                 returns information from active markets
    /// @return marketIds    array of total marketIds
    /// @return quoteTokens  array of total market's quoteTokens
    /// @return capacities   array of total market's capacities
    /// @return endSaleTimes array of total market's endSaleTimes
    /// @return pricesTos    array of total market's pricesTos
    function getBonds() external view
        returns (
            uint256[] memory marketIds,
            address[] memory quoteTokens,
            uint256[] memory capacities,
            uint256[] memory endSaleTimes,
            uint256[] memory pricesTos
        );

    /// @dev              returns all generated marketIDs
    /// @return memory[]  returns marketList
    function getMarketList() external view returns (uint256[] memory) ;

    /// @dev          returns the number of created markets
    /// @return Total number of markets
    function totalMarketCount() external view returns (uint256) ;

    /// @dev                returns information about the market
    /// @param _marketId    market id
    /// @return quoteToken  saleToken Address
    /// @return capacity    tokenSaleAmount
    /// @return endSaleTime market endTime
    /// @return maxPayout   maximum purchasable bond in TOS
    /// @return tosPrice    amount of TOS per 1 ETH
    function viewMarket(uint256 _marketId) external view
        returns (
            address quoteToken,
            uint256 capacity,
            uint256 endSaleTime,
            uint256 maxPayout,
            uint256 tosPrice
            );

    /// @dev               checks whether a market is opened or not
    /// @param _marketId   market id
    /// @return closedBool true if market is open, false if market is closed
    function isOpened(uint256 _marketId) external view returns (bool closedBool);



}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IBondDepositoryEvent{

    /// @dev                        this event occurs when set the calculator address
    /// @param calculatorAddress    calculator address
    event SetCalculator(address calculatorAddress);

    /// @dev               this event occurs when a specific market product is purchased
    /// @param user        user address
    /// @param marketId    market id
    /// @param amount      bond amount in ETH
    /// @param payout      amount of TOS earned by the user from bonding
    /// @param isEth       whether ether was used for bonding
    /// @param mintAmount  number of minted TOS from this deposit
    event Deposited(address user, uint256 marketId, uint256 amount, uint256 payout, bool isEth, uint256 mintAmount);

    /// @dev            this event occurs when a specific market product is created
    /// @param marketId market id
    /// @param token    token address of deposit asset. For ETH, the address is address(0). Will be used in Phase 2 and 3
    /// @param market   [capacity of the market, market closing time, return on the deposit in TOS, maximum purchasable bond in TOS]
    event CreatedMarket(uint256 marketId, address token, uint256[4] market);

    /// @dev            this event occurs when a specific market product is closed
    /// @param marketId market id
    event ClosedMarket(uint256 marketId);

    /// @dev                  this event occurs when a user bonds with ETH
    /// @param user           user account
    /// @param marketId       market id
    /// @param stakeId        stake id
    /// @param amount         amount of deposit in ETH
    /// @param tosValuation   amount of TOS earned by the user
    event ETHDeposited(address user, uint256 marketId, uint256 stakeId, uint256 amount, uint256 tosValuation);

    /// @dev                  this event occurs when a user bonds with ETH and earns sTOS
    /// @param user           user account
    /// @param marketId       market id
    /// @param stakeId        stake id
    /// @param amount         amount of deposit in ETH
    /// @param lockWeeks      number of weeks to locking
    /// @param tosValuation   amount of TOS earned by the user
    event ETHDepositedWithSTOS(address user, uint256 marketId, uint256 stakeId, uint256 amount, uint256 lockWeeks, uint256 tosValuation);

    /// @dev                  this event occurs when the market capacity is changed
    /// @param _marketId      market id
    /// @param _amount        the capacity amount
    event ChangedCapacity(uint256 _marketId, uint256  _amount);

    /// @dev             this event occurs when the closeTime is updated
    /// @param _marketId market id
    /// @param closeTime new close time
    event ChangedCloseTime(uint256 _marketId, uint256 closeTime);

    /// @dev             this event occurs when the maxPayout is updated
    /// @param _marketId market id
    /// @param _amount   maxPayout
    event ChangedMaxPayout(uint256 _marketId, uint256 _amount);

    /// @dev             this event occurs when the maxPayout is updated
    /// @param _marketId market id
    /// @param _tosPrice amount of TOS per 1 ETH
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

    function burn(address account, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IStaking {


    /* ========== onlyPolicyOwner ========== */

    /// @dev              modify epoch data
    /// @param _length    epoch's length (sec)
    /// @param _end       epoch's end time (sec)
    function setEpochInfo(
        uint256 _length,
        uint256 _end
    ) external;

    /// @dev              set tosAddress, lockTOS, treasuryAddress
    /// @param _tos       tosAddress
    /// @param _lockTOS   lockTOSAddress
    /// @param _treasury  treausryAddress
    function setAddressInfos(
        address _tos,
        address _lockTOS,
        address _treasury
    ) external;

    /// @dev                    set setRebasePerEpoch
    /// @param _rebasePerEpoch  rate for rebase per epoch (eth uint)
    ///                         If input the 0.9 -> 900000000000000000
    function setRebasePerEpoch(
        uint256 _rebasePerEpoch
    ) external;


    /// @dev            set minimum bonding period
    /// @param _period  _period (seconds)
    function setBasicBondPeriod(uint256 _period) external ;


    /* ========== onlyOwner ========== */

    /// @dev             migration of existing lockTOS contract data
    /// @param accounts  array of account for sync
    /// @param balances  array of tos amount for sync
    /// @param period    array of end time for sync
    /// @param tokenId   array of locktos id for sync
    function syncStos(
        address[] memory accounts,
        uint256[] memory balances,
        uint256[] memory period,
        uint256[] memory tokenId
    ) external ;



    /* ========== onlyBonder ========== */


    /// @dev Increment and returns the market ID.
    function generateMarketId() external returns (uint256);

    /// @dev             TOS minted from bonding is automatically staked for the user, and user receives LTOS. Lock-up period is based on the basicBondPeriod
    /// @param to        user address
    /// @param _amount   TOS amount
    /// @param _marketId market id
    /// @param tosPrice  amount of TOS per 1 ETH
    /// @return stakeId  stake id
    function stakeByBond(
        address to,
        uint256 _amount,
        uint256 _marketId,
        uint256 tosPrice
    ) external returns (uint256 stakeId);



    /// @dev                TOS minted from bonding is automatically staked for the user, and user receives LTOS and sTOS.
    /// @param _to          user address
    /// @param _amount      TOS amount
    /// @param _marketId    market id
    /// @param _periodWeeks number of lockup weeks
    /// @param tosPrice     amount of TOS per 1 ETH
    /// @return stakeId     stake id
    function stakeGetStosByBond(
        address _to,
        uint256 _amount,
        uint256 _marketId,
        uint256 _periodWeeks,
        uint256 tosPrice
    ) external returns (uint256 stakeId);


    /* ========== Anyone can execute ========== */


    /// @dev            user can stake TOS for LTOS without lockup period
    /// @param _amount  TOS amount
    /// @return stakeId stake id
    function stake(
        uint256 _amount
    ) external  returns (uint256 stakeId);


    /// @dev                user can stake TOS for LTOS and sTOS with lockup period
    /// @param _amount      TOS amount
    /// @param _periodWeeks number of lockup weeks
    /// @return stakeId     stake id
    function stakeGetStos(
        uint256 _amount,
        uint256 _periodWeeks
    ) external  returns (uint256 stakeId);


    /// @dev            increase the tos amount in stakeId of the simple stake product (without lock, without marketId)
    /// @param _stakeId stake id
    /// @param _amount  TOS amount
    function increaseAmountForSimpleStake(
        uint256 _stakeId,
        uint256 _amount
    )   external;

    /// @dev                used to update the amount of staking after the lockup period is passed
    /// @param _stakeId     stake id
    /// @param _addTosAmount   additional TOS to be staked
    /// @param _relockLtosAmount amount of LTOS to relock
    /// @param _periodWeeks lockup period
    function resetStakeGetStosAfterLock(
        uint256 _stakeId,
        uint256 _addTosAmount,
        uint256 _relockLtosAmount,
        uint256 _periodWeeks
    ) external;

    /// @dev                used to update the amount of staking after the lockup period is passed
    /// @param _stakeId     stake id
    /// @param _addTosAmount   additional TOS to be staked
    /// @param _periodWeeks lockup period
    function resetStakeGetStosAfterLock(
        uint256 _stakeId,
        uint256 _addTosAmount,
        uint256 _periodWeeks
    ) external;


    /// @dev             used to update the amount of staking before the lockup period is not passed
    /// @param _stakeId  stake id
    /// @param _amount   additional TOS to be staked
    function increaseBeforeEndOrNonEnd(
        uint256 _stakeId,
        uint256 _amount
    ) external;


    /// @dev                used to update the amount of staking before the lockup period is not passed
    /// @param _stakeId     stake id
    /// @param _amount      additional TOS to be staked
    /// @param _unlockWeeks additional lockup period
    function increaseBeforeEndOrNonEnd(
        uint256 _stakeId,
        uint256 _amount,
        uint256 _unlockWeeks
    ) external;


    /// @dev             claiming LTOS from stakeId without sTOS
    /// @param _stakeId  stake id
    /// @param claimLtos amount of LTOS to claim
    function claimForSimpleType(
        uint256 _stakeId,
        uint256 claimLtos
    ) external;


    /// @dev             used to unstake a specific staking ID
    /// @param _stakeId  stake id
    function unstake(
        uint256 _stakeId
    ) external;

    /// @dev             used to unstake multiple staking IDs
    /// @param _stakeIds stake id
    function multiUnstake(
        uint256[] calldata _stakeIds
    ) external;


    /// @dev LTOS index adjustment. Apply compound interest to the LTOS index
    function rebaseIndex() external;

    /* ========== VIEW ========== */


    /// @dev             returns the amount of LTOS for a specific stakingId.
    /// @param _stakeId  stake id
    /// @return return   LTOS balance of stakingId
    function remainedLtos(uint256 _stakeId) external view returns (uint256) ;

    /// @dev             returns the claimable amount of LTOS for a specific staking ID.
    /// @param _stakeId  stake id
    /// @return return   claimable amount of LTOS
    function claimableLtos(uint256 _stakeId) external view returns (uint256);

    /// @dev returns the current LTOS index value
    function getIndex() external view returns(uint256) ;

    /// @dev returns the LTOS index value if rebase() is called
    function possibleIndex() external view returns (uint256);

    /// @dev           returns a list of stakingIds owned by a specific account
    /// @param _addr   user account
    /// @return return list of stakingIds owned by account
    function stakingOf(address _addr)
        external
        view
        returns (uint256[] memory);

    /// @dev            returns the staked LTOS amount of the user in TOS
    /// @param _addr    user account
    /// @return balance staked LTOS amount of the user in TOS
    function balanceOf(address _addr) external view returns (uint256 balance);

    /// @dev returns the time left until next rebase
    /// @return time
    function secondsToNextEpoch() external view returns (uint256);

    /// @dev        returns amount of TOS owned by Treasury that can be used for staking interest in the future (if rebase() is not called)
    /// @return TOS returns number of TOS owned by the treasury that is not owned by the foundation nor for LTOS
    function runwayTos() external view returns (uint256);


    /// @dev        returns amount of TOS owned by Treasury that can be used for staking interest in the future (if rebase() is called)
    /// @return TOS returns number of TOS owned by the treasury that is not owned by the foundation nor for LTOS
    function runwayTosPossibleIndex() external view returns (uint256);

    /// @dev           converts TOS amount to LTOS (if rebase() is not called)
    /// @param amount  TOS amount
    /// @return return LTOS amount
    function getTosToLtos(uint256 amount) external view returns (uint256);

    /// @dev           converts LTOS to TOS (if rebase() is not called)
    /// @param ltos    LTOS Amount
    /// @return return TOS Amount
    function getLtosToTos(uint256 ltos) external view returns (uint256);


    /// @dev           converts TOS amount to LTOS (if rebase() is called)
    /// @param amount  TOS Amount
    /// @return return LTOS Amount
    function getTosToLtosPossibleIndex(uint256 amount) external view returns (uint256);

    /// @dev           converts LTOS to TOS (if rebase() is called)
    /// @param ltos    LTOS Amount
    /// @return return TOS Amount
    function getLtosToTosPossibleIndex(uint256 ltos) external view returns (uint256);

    /// @dev           returns number of LTOS staked (converted to TOS) in stakeId
    /// @param stakeId stakeId
    function stakedOf(uint256 stakeId) external view returns (uint256);

    /// @dev returns the total number of LTOS staked (converted to TOS) by users
    function stakedOfAll() external view returns (uint256) ;

    /// @dev            detailed information of specific staking ID
    /// @param stakeId  stakeId
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