//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "TransferHelper.sol";
import "AggregatorV3Interface.sol";
import "KeeperCompatibleInterface.sol";
//import "IERC20.sol";
import "Ownable.sol";

import "DataTypes.sol";
import "ILendingPoolAddressesProvider.sol";
import "ILendingPool.sol";

import {IERC20} from "IERC20.sol";

import "IRedirect.sol";
import "IGovernanceToken.sol";

import "IHandler.sol";


//make it a super app to allow using superfluid flows and instant distribution
contract MoonSquares is KeeperCompatibleInterface, Ownable {

    string[] public allowedAssets;//All assets that are predicted on the platform
    
    address[] private assetPriceAggregators;

    address[] public contracts;

    mapping(string => address) public assetToAggregator;

    mapping(string => uint256) public coinRound;
    //uint128 public coinRound;

    uint128 public monthCount;

    uint public payroundStartTime;

    uint128 constant payDayDuration = 30 days;

    uint public totalPaid;

    //IUniswapV2Router02 public sushiRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    ILendingPoolAddressesProvider private provider = ILendingPoolAddressesProvider(
        address(0x88757f2f99175387aB4C6a4b3067c77A695b0349)
    ); 
    ILendingPool private lendingPool = ILendingPool(provider.getLendingPool());

    //ISwapRouter public immutable swapRouter;
    //uint24 public constant poolFee = 3000;
    
    IRedirect private flowDistrubuter;
    IGovernanceToken private governanceToken;
    IHandler private handler;

    address private Dai = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD;
    address private _aaveToken = 0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8;
    address private Daix = 0x43F54B13A0b17F67E61C9f0e41C3348B3a2BDa09;
    
    mapping (uint256 => uint256) public roundInterestEarned;
//
    mapping(uint256 => mapping(string => RoundInfo)) public roundCoinInfo;
    struct RoundInfo {
        int256 moonPrice;
        uint256 winnings;
        int256 startPrice;
        uint256 totalStaked;
        uint256 startTime;
        uint256 winningTime;
        uint256 totalBets;
        uint256 numberOfWinners;
    }

    uint public totalStaked;
    //sample bet
    //structure of the bet
    struct Bet {
        uint256 timePlaced;//make sure to include this in next deployment
        uint256 squareStartTime;
        uint256 squareEndTime;
        address owner;
        bool isWinner;
        bool paid;
    }
    
    struct Charity {
        bytes8 name;
        bytes32 link; //sends people to the charity's official site
    }

    mapping (address => Charity) public presentCharities;

    bytes8[] charities;
    address[] charityAddress;
    
    mapping(uint128 => mapping(bytes8 => uint128)) public roundCharityVotes;
    
    mapping(uint128 => address) public roundVoteResults;

    mapping (uint256 => mapping( string => mapping (uint256 => Bet))) public roundCoinAddressBetsPlaced;

    mapping (uint256 => mapping( string => mapping (address => uint256[]))) public roundCoinAddressBetIds;


    mapping (address => uint256) totalAmountPlayed;//shows how much every player has placed

    event Predicted(address indexed _placer, uint256 indexed _betId, uint256 _start, uint _end);

    event CharityThisMonth(address indexed charityAddress_, bytes8 indexed name_);
    

    constructor() {
        payroundStartTime = block.timestamp;
    }

    modifier isAllowedContract() {
        for (uint i =0; i< contracts.length; i++) {
            require(contracts[i] == msg.sender);
        }
        _;
    }

    function _updateStorage(
        uint _start,
        string memory market
    ) internal {
        uint betId = roundCoinInfo[coinRound[market]][market].totalBets;
        roundCoinAddressBetsPlaced[coinRound[market]][market][betId].timePlaced = getTime();
        roundCoinAddressBetsPlaced[coinRound[market]][market][betId].squareStartTime = _start;
        roundCoinAddressBetIds[coinRound[market]][market][msg.sender].push(betId);
        roundCoinAddressBetsPlaced[coinRound[market]][market][betId].squareEndTime  = (_start + 300 seconds);
        roundCoinAddressBetsPlaced[coinRound[market]][market][betId].owner = msg.sender;
        roundCoinInfo[coinRound[market]][market].totalBets +=1;
        emit Predicted(msg.sender, betId, _start, (_start + 1800 seconds));

    } 
    //predicts an asset
   function predictAsset(
        uint256 _start, 
        string memory market
    ) external
    {   
        uint amount = 10000000000000000000;
        //uint duration = 300 seconds;
        require(_start > block.timestamp);
        require(IERC20(Dai).allowance(msg.sender, address(this)) >= amount);
        IERC20(Dai).transferFrom(msg.sender, address(this), amount);
        //update the total value played
        roundCoinInfo[coinRound[market]][market].totalStaked += amount;
        roundCoinInfo[coinRound[market]][market].winnings += 9000000000000000;
        totalStaked += amount;
        aaveDeposit(amount);
        _updateStorage(_start, market);
        
    }



    function aaveDeposit(uint amount) internal {
        IERC20(Dai).approve(address(lendingPool), amount);
        lendingPool.deposit(
            Dai,
            amount,
            address(this),
            0
        );
    }

    //gets the price of the asset denoted by market
    function getPrice(string memory market) public view returns(int256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(assetToAggregator[market]); 
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return int256(answer/100000000);
    }

    //gets the current time
    function getTime() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x6135b13325bfC4B00278B4abC5e20bbce2D6580e);
        //Matic network
        (,,,uint256 answer,) = priceFeed.latestRoundData();
         return uint256(answer);
    }

    //it 
    function _checkIndexes(string memory market, uint p) internal view returns(bool){
        if (
            roundCoinAddressBetsPlaced[coinRound[market]][market][p].squareStartTime >= roundCoinInfo[coinRound[market]][market].winningTime
            &&
            roundCoinAddressBetsPlaced[coinRound[market]][market][p].squareEndTime <= roundCoinInfo[coinRound[market]][market].winningTime
        ) {
            return true;
        } else {
            return false;
        }
    }
    function setWinningBets(string memory market) internal {

        for (uint256 p =0; p <= roundCoinInfo[coinRound[market]][market].totalBets; p++) {
            if (_checkIndexes(market, p) == true){
                roundCoinAddressBetsPlaced[coinRound[market]][market][p].isWinner = true;
                roundCoinInfo[coinRound[market]][market].numberOfWinners += 1;
            }
        }
    }

    function isAwiner(
        uint256 _round,
        string memory market,
        uint256 checkedId
    )public view returns(bool) {
        return roundCoinAddressBetsPlaced[coinRound[market]][market][checkedId].isWinner;

    }

     function takePrize(
         uint round,
         string memory market,
         uint256 betId,
         bytes8 charity
    ) external {
        require(roundCoinInfo[round][market].numberOfWinners != 0);
        require(
            roundCoinAddressBetsPlaced[round][market][betId].isWinner == true
            &&
            roundCoinAddressBetsPlaced[round][market][betId].paid == false
        );
        uint paids = roundCoinInfo[coinRound[market]][market].winnings/roundCoinInfo[coinRound[market]][market].numberOfWinners;
        IERC20(Dai).transfer(
            roundCoinAddressBetsPlaced[round][market][betId].owner,
            (roundCoinInfo[coinRound[market]][market].winnings/paids)
        );
        totalPaid += paids;
        roundCoinAddressBetsPlaced[round][market][betId].paid = true;
        roundCharityVotes[monthCount][charity] += 1;
    }

    function setTime(string memory market) public {
        roundCoinInfo[coinRound[market]][market].winningTime = getTime();
        setWinningBets(market);
        withdrawRoundFundsFromIba(market);
    }

    function checkUpkeep(
        bytes calldata /*checkData*/
    ) external view override returns (
        bool upkeepNeeded, bytes memory performData
    ) {
        for (uint256 p = 0; p < allowedAssets.length; p++) {
        
            if (
                getPrice(allowedAssets[p])
                ==
                roundCoinInfo[coinRound[allowedAssets[p]]][allowedAssets[p]].moonPrice
            ) {
                upkeepNeeded = true;
                performData = abi.encodePacked(uint256(p));
                return (true, performData);
            }
        }
        if (block.timestamp >= payroundStartTime + 30 days) {
            upkeepNeeded = true;
            performData = abi.encodePacked(uint256(1000));
            return (true, performData);
        }
        
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 decodedValue = abi.decode(performData, (uint256));
        if(decodedValue < allowedAssets.length){
            setTime(allowedAssets[decodedValue]);
        }
        if (decodedValue ==1000) {
            payroundStartTime +=30 days;
            withdrawInterest(_aaveToken);
            flowToPaymentDistributer();
            distributeToMembers();
        }
    }

    function setwinningCharity() public {
        uint128 winning_votes = 0;
        uint index = 0;
        for (uint i =0; i < charities.length; i++) {
            if (roundCharityVotes[monthCount][charities[i]] > winning_votes){
                winning_votes == roundCharityVotes[monthCount][charities[i]];
            }
            if (roundCharityVotes[monthCount][charities[i]] == winning_votes) {
                roundVoteResults[monthCount] = charityAddress[i];
                index = i;
            }
        }
        flowDistrubuter.changeReceiverAdress(roundVoteResults[monthCount]);
        emit CharityThisMonth(roundVoteResults[monthCount], charities[index]);
    }

    //withdraws the total Amount after the moonpice gets hit
    function withdrawRoundFundsFromIba(string memory market) private {
        require(roundCoinInfo[coinRound[market]][market].numberOfWinners != 0);
        lendingPool.withdraw(
            Dai,
            roundCoinInfo[coinRound[market]][market].winnings,
            address(this)
        );
        
        //Withdraws Funds from the predictions
    }

    function distributeToMembers() private {
        require(monthCount != 0);
        uint256 cashAmount = IERC20(Daix).balanceOf(address(governanceToken));
        governanceToken.distribute(
            cashAmount
        );
    }

    function withdrawInterest(address aaveToken) private returns(uint) {
        uint aaveBalance = IERC20(aaveToken).balanceOf(address(this));
        uint interest = aaveBalance - (totalStaked - totalPaid);
        lendingPool.withdraw(
            Dai,
            interest,
            address(handler)
        );
        handler.upgradeToken(interest);
        roundInterestEarned[monthCount] = interest;
        return(interest);
        //remember to upgrade the dai for flow
        //verify which token is getting upgraded

    }
    //distributes the Interest Earned on the round to members of the Dao
    function flowToPaymentDistributer() private {
        //Flows interest earned from the protocal to the redirectAll contract that handles distribution
            //Flow Winnings
        int256 toInt = int256(roundInterestEarned[monthCount]);
        handler.createFlow(int96(toInt / 30 days));
        monthCount += 1;
    }

    function addAssetsAndAggregators(
        string memory _asset,
        address _aggregator
    ) external onlyOwner {
        require(allowedAssets.length < 100);
        assetToAggregator[_asset] = _aggregator;
        allowedAssets.push(_asset);
        assetPriceAggregators.push(_aggregator);
    }

    function addCharity(
        bytes8 _charityName,
        address _charityAddress,
        bytes32 _link
    ) external onlyOwner {
        presentCharities[_charityAddress].name = _charityName;
        presentCharities[_charityAddress].link = _link;
        charities.push(_charityName);
        charityAddress.push(_charityAddress);
    }

    function setMoonPrice(
        int price,
        string memory market
    ) external onlyOwner {
        roundCoinInfo[coinRound[market]][market] = RoundInfo(
            price,
            0,
            getPrice(market),
            0,
            getTime(),
            0,
            0,
            0
        );

    }
    //puts the 10% from daily rocket into account
    function acountForDRfnds(uint amount) external isAllowedContract {
        totalStaked += amount;
    }
    function voteForCharity(bytes8 charity) external isAllowedContract {
        roundCharityVotes[monthCount][charity] += 1;
    }

    //adds contracts that call core funtions
    function addContract(address _conAddress) external onlyOwner{
        contracts.push(_conAddress);
    }

    function addGovernanceToken(IGovernanceToken _gtAdress) external isAllowedContract {
        governanceToken = _gtAdress;
    }
    //adds the flow distributor
    function addFlowDistributor(IRedirect addr) external onlyOwner {
        flowDistrubuter = addr;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity >=0.6.0;

import "IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity >=0.6.12;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256[2] data; // size is _maxReserves / 128 + ((_maxReserves % 128 > 0) ? 1 : 0), but need to be literal
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(bytes32 id, address impl) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "ILendingPoolAddressesProvider.sol";
import "DataTypes.sol";

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and depositors are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts amounts being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external;

  function setConfiguration(address reserve, uint256 configuration) external;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external;

  function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRedirect {

    function changeReceiverAdress(address _newReceiver) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGovernanceToken {

     function distribute(uint256 cashAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IHandler {
    function upgradeToken(uint256 amount) external;
    
    function createFlow(int96 flowRate) external;
}