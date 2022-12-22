/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

/*
                  *                                                  █                              
                *****                                               ▓▓▓                             
                  *                                               ▓▓▓▓▓▓▓                         
                                   *            ///.           ▓▓▓▓▓▓▓▓▓▓▓▓▓                       
                                 *****        ////////            ▓▓▓▓▓▓▓                          
                                   *       /////////////            ▓▓▓                             
                     ▓▓                  //////////////////          █         ▓▓                   
                   ▓▓  ▓▓             ///////////////////////                ▓▓   ▓▓                
                ▓▓       ▓▓        ////////////////////////////           ▓▓        ▓▓              
              ▓▓            ▓▓    /////////▓▓▓///////▓▓▓/////////       ▓▓             ▓▓            
           ▓▓                 ,////////////////////////////////////// ▓▓                 ▓▓         
        ▓▓                  //////////////////////////////////////////                     ▓▓      
      ▓▓                  //////////////////////▓▓▓▓/////////////////////                          
                       ,////////////////////////////////////////////////////                        
                    .//////////////////////////////////////////////////////////                     
                     .//////////////////////////██.,//////////////////////////█                     
                       .//////////////////////████..,./////////////////////██                       
                        ...////////////////███████.....,.////////////////███                        
                          ,.,////////////████████ ........,///////////████                          
                            .,.,//////█████████      ,.......///////████                            
                               ,..//████████           ........./████                               
                                 ..,██████                .....,███                                 
                                    .██                     ,.,█                                    
                                                                                                    
                                                                                                    
                                                                                                    
               ▓▓            ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓               ▓▓▓▓▓▓▓▓▓▓          
             ▓▓▓▓▓▓          ▓▓▓    ▓▓▓       ▓▓▓               ▓▓               ▓▓   ▓▓▓▓         
           ▓▓▓    ▓▓▓        ▓▓▓    ▓▓▓       ▓▓▓    ▓▓▓        ▓▓               ▓▓▓▓▓             
          ▓▓▓        ▓▓      ▓▓▓    ▓▓▓       ▓▓▓▓▓▓▓▓▓▓        ▓▓▓▓▓▓▓▓▓▓       ▓▓▓▓▓▓▓▓▓▓          
*/

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

/// @title IAgToken
/// @author Angle Labs, Inc.
/// @notice Interface for the stablecoins `AgToken` contracts
/// @dev This interface only contains functions of the `AgToken` contract which are called by other contracts
/// of this module or of the first module of the Angle Protocol
interface IAgToken is IERC20Upgradeable {
    // ======================= Minter Role Only Functions ===========================

    /// @notice Lets the `StableMaster` contract or another whitelisted contract mint agTokens
    /// @param account Address to mint to
    /// @param amount Amount to mint
    /// @dev The contracts allowed to issue agTokens are the `StableMaster` contract, `VaultManager` contracts
    /// associated to this stablecoin as well as the flash loan module (if activated) and potentially contracts
    /// whitelisted by governance
    function mint(address account, uint256 amount) external;

    /// @notice Burns `amount` tokens from a `burner` address after being asked to by `sender`
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @param sender Address which requested the burn from `burner`
    /// @dev This method is to be called by a contract with the minter right after being requested
    /// to do so by a `sender` address willing to burn tokens from another `burner` address
    /// @dev The method checks the allowance between the `sender` and the `burner`
    function burnFrom(
        uint256 amount,
        address burner,
        address sender
    ) external;

    /// @notice Burns `amount` tokens from a `burner` address
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @dev This method is to be called by a contract with a minter right on the AgToken after being
    /// requested to do so by an address willing to burn tokens from its address
    function burnSelf(uint256 amount, address burner) external;

    // ========================= Treasury Only Functions ===========================

    /// @notice Adds a minter in the contract
    /// @param minter Minter address to add
    /// @dev Zero address checks are performed directly in the `Treasury` contract
    function addMinter(address minter) external;

    /// @notice Removes a minter from the contract
    /// @param minter Minter address to remove
    /// @dev This function can also be called by a minter wishing to revoke itself
    function removeMinter(address minter) external;

    /// @notice Sets a new treasury contract
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external;

    // ========================= External functions ================================

    /// @notice Checks whether an address has the right to mint agTokens
    /// @param minter Address for which the minting right should be checked
    /// @return Whether the address has the right to mint agTokens or not
    function isMinter(address minter) external view returns (bool);
}

/// @title ICoreBorrow
/// @author Angle Labs, Inc.
/// @notice Interface for the `CoreBorrow` contract
/// @dev This interface only contains functions of the `CoreBorrow` contract which are called by other contracts
/// of this module
interface ICoreBorrow {
    /// @notice Checks if an address corresponds to a treasury of a stablecoin with a flash loan
    /// module initialized on it
    /// @param treasury Address to check
    /// @return Whether the address has the `FLASHLOANER_TREASURY_ROLE` or not
    function isFlashLoanerTreasury(address treasury) external view returns (bool);

    /// @notice Checks whether an address is governor of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GOVERNOR_ROLE` or not
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether an address is governor or a guardian of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GUARDIAN_ROLE` or not
    /// @dev Governance should make sure when adding a governor to also give this governor the guardian
    /// role by calling the `addGovernor` function
    function isGovernorOrGuardian(address admin) external view returns (bool);
}

/// @title IFlashAngle
/// @author Angle Labs, Inc.
/// @notice Interface for the `FlashAngle` contract
/// @dev This interface only contains functions of the contract which are called by other contracts
/// of this module
interface IFlashAngle {
    /// @notice Reference to the `CoreBorrow` contract managing the FlashLoan module
    function core() external view returns (ICoreBorrow);

    /// @notice Sends the fees taken from flash loans to the treasury contract associated to the stablecoin
    /// @param stablecoin Stablecoin from which profits should be sent
    /// @return balance Amount of profits sent
    /// @dev This function can only be called by the treasury contract
    function accrueInterestToTreasury(IAgToken stablecoin) external returns (uint256 balance);

    /// @notice Adds support for a stablecoin
    /// @param _treasury Treasury associated to the stablecoin to add support for
    /// @dev This function can only be called by the `CoreBorrow` contract
    function addStablecoinSupport(address _treasury) external;

    /// @notice Removes support for a stablecoin
    /// @param _treasury Treasury associated to the stablecoin to remove support for
    /// @dev This function can only be called by the `CoreBorrow` contract
    function removeStablecoinSupport(address _treasury) external;

    /// @notice Sets a new core contract
    /// @param _core Core contract address to set
    /// @dev This function can only be called by the `CoreBorrow` contract
    function setCore(address _core) external;
}

/// @title ITreasury
/// @author Angle Labs, Inc.
/// @notice Interface for the `Treasury` contract
/// @dev This interface only contains functions of the `Treasury` which are called by other contracts
/// of this module
interface ITreasury {
    /// @notice Stablecoin handled by this `treasury` contract
    function stablecoin() external view returns (IAgToken);

    /// @notice Checks whether a given address has the  governor role
    /// @param admin Address to check
    /// @return Whether the address has the governor role
    /// @dev Access control is only kept in the `CoreBorrow` contract
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether a given address has the guardian or the governor role
    /// @param admin Address to check
    /// @return Whether the address has the guardian or the governor role
    /// @dev Access control is only kept in the `CoreBorrow` contract which means that this function
    /// queries the `CoreBorrow` contract
    function isGovernorOrGuardian(address admin) external view returns (bool);

    /// @notice Checks whether a given address has well been initialized in this contract
    /// as a `VaultManager`
    /// @param _vaultManager Address to check
    /// @return Whether the address has been initialized or not
    function isVaultManager(address _vaultManager) external view returns (bool);

    /// @notice Sets a new flash loan module for this stablecoin
    /// @param _flashLoanModule Reference to the new flash loan module
    /// @dev This function removes the minting right to the old flash loan module and grants
    /// it to the new module
    function setFlashLoanModule(address _flashLoanModule) external;
}

/// @title IOracle
/// @author Angle Labs, Inc.
/// @notice Interface for the `Oracle` contract
/// @dev This interface only contains functions of the contract which are called by other contracts
/// of this module
interface IOracle {
    /// @notice Reads the rate from the Chainlink circuit and other data provided
    /// @return quoteAmount The current rate between the in-currency and out-currency in the base
    /// of the out currency
    /// @dev For instance if the out currency is EUR (and hence agEUR), then the base of the returned
    /// value is 10**18
    function read() external view returns (uint256);

    /// @notice Changes the treasury contract
    /// @param _treasury Address of the new treasury contract
    /// @dev This function can be called by an approved `VaultManager` contract which can call
    /// this function after being requested to do so by a `treasury` contract
    /// @dev In some situations (like reactor contracts), the `VaultManager` may not directly be linked
    /// to the `oracle` contract and as such we may need governors to be able to call this function as well
    function setTreasury(address _treasury) external;

    /// @notice Reference to the `treasury` contract handling this `VaultManager`
    function treasury() external view returns (ITreasury treasury);

    /// @notice Array with the list of Chainlink feeds in the order in which they are read
    function circuitChainlink() external view returns (AggregatorV3Interface[] memory);
}

/// @title BaseOracleChainlinkMulti
/// @author Angle Labs, Inc.
/// @notice Base Contract to be overriden by all contracts of the protocol
/// @dev This base contract concerns an oracle that uses Chainlink with multiple pools to read from
/// @dev All gas-efficient implementation of the `OracleChainlinkMulti` contract should inherit from this
abstract contract BaseOracleChainlinkMulti is IOracle {
    // ========================= Parameters and References =========================

    /// @inheritdoc IOracle
    ITreasury public override treasury;
    /// @notice Represent the maximum amount of time (in seconds) between each Chainlink update
    /// before the price feed is considered stale
    uint32 public stalePeriod;

    // =================================== Event ===================================

    event StalePeriodUpdated(uint32 _stalePeriod);

    // =================================== Errors ===================================

    error InvalidChainlinkRate();
    error NotGovernorOrGuardian();
    error NotVaultManagerOrGovernor();

    /// @notice Constructor for an oracle using Chainlink with multiple pools to read from
    /// @param _stalePeriod Minimum feed update frequency for the oracle to not revert
    /// @param _treasury Treasury associated to the VaultManager which reads from this feed
    constructor(uint32 _stalePeriod, address _treasury) {
        stalePeriod = _stalePeriod;
        treasury = ITreasury(_treasury);
    }

    // ============================= Reading Oracles ===============================

    /// @inheritdoc IOracle
    function read() external view virtual override returns (uint256 quoteAmount);

    /// @inheritdoc IOracle
    function circuitChainlink() public view virtual returns (AggregatorV3Interface[] memory);

    /// @notice Reads a Chainlink feed using a quote amount and converts the quote amount to
    /// the out-currency
    /// @param quoteAmount The amount for which to compute the price expressed with base decimal
    /// @param feed Chainlink feed to query
    /// @param multiplied Whether the ratio outputted by Chainlink should be multiplied or divided
    /// to the `quoteAmount`
    /// @param decimals Number of decimals of the corresponding Chainlink pair
    /// @return The `quoteAmount` converted in out-currency
    function _readChainlinkFeed(
        uint256 quoteAmount,
        AggregatorV3Interface feed,
        uint8 multiplied,
        uint256 decimals
    ) internal view returns (uint256) {
        (uint80 roundId, int256 ratio, , uint256 updatedAt, uint80 answeredInRound) = feed.latestRoundData();
        if (ratio <= 0 || roundId > answeredInRound || block.timestamp - updatedAt > stalePeriod)
            revert InvalidChainlinkRate();
        uint256 castedRatio = uint256(ratio);
        // Checking whether we should multiply or divide by the ratio computed
        if (multiplied == 1) return (quoteAmount * castedRatio) / (10**decimals);
        else return (quoteAmount * (10**decimals)) / castedRatio;
    }

    // ======================= Governance Related Functions ========================

    /// @notice Changes the stale period
    /// @param _stalePeriod New stale period (in seconds)
    function changeStalePeriod(uint32 _stalePeriod) external {
        if (!treasury.isGovernorOrGuardian(msg.sender)) revert NotGovernorOrGuardian();
        stalePeriod = _stalePeriod;
        emit StalePeriodUpdated(_stalePeriod);
    }

    /// @inheritdoc IOracle
    function setTreasury(address _treasury) external override {
        if (!treasury.isVaultManager(msg.sender) && !treasury.isGovernor(msg.sender))
            revert NotVaultManagerOrGovernor();
        treasury = ITreasury(_treasury);
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

//solhint-disable
interface ICurveCryptoSwapPool is IERC20 {
    function A() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_fee(uint256[3] memory amounts, uint256[3] memory xp) external view returns (uint256);

    function calc_token_amount(uint256[3] memory amounts, bool deposit) external view returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;

    function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount) external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}

/// @title OracleFRAXBPEURChainlink
/// @author Angle Labs, Inc.
/// @notice Gives a lower bound of the price of Curve FRAXBP in Euro in base 18
contract OracleFRAXBPEURChainlink is BaseOracleChainlinkMulti {
    string public constant DESCRIPTION = "crvFRAX/EUR Oracle";
    ICurveCryptoSwapPool public constant FRAXBP = ICurveCryptoSwapPool(0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2);

    /// @notice Constructor of the contract
    /// @param _stalePeriod Minimum feed update frequency for the oracle to not revert
    /// @param _treasury Treasury associated to the `VaultManager` which reads from this feed
    constructor(uint32 _stalePeriod, address _treasury) BaseOracleChainlinkMulti(_stalePeriod, _treasury) {}

    function circuitChainlink() public pure override returns (AggregatorV3Interface[] memory) {
        AggregatorV3Interface[] memory _circuitChainlink = new AggregatorV3Interface[](3);
        // Chainlink FRAX/USD address
        _circuitChainlink[0] = AggregatorV3Interface(0xB9E1E3A9feFf48998E45Fa90847ed4D467E8BcfD);
        // Chainlink USDC/USD address
        _circuitChainlink[1] = AggregatorV3Interface(0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6);
        // Chainlink EUR/USD address
        _circuitChainlink[2] = AggregatorV3Interface(0xb49f677943BC038e9857d61E7d053CaA2C1734C1);
        return _circuitChainlink;
    }

    /// @inheritdoc IOracle
    function read() external view override returns (uint256 quoteAmount) {
        AggregatorV3Interface[] memory _circuitChainlink = circuitChainlink();
        // We use 0 decimals when reading fees through `readChainlinkFeed` since all feeds have 8 decimals
        // and the virtual price of the Curve pool is given in 18 decimals, just like the amount of decimals
        // of the FRAXBP token
        uint256 fraxPrice = _readChainlinkFeed(1, _circuitChainlink[0], 1, 0);
        uint256 usdcPrice = _readChainlinkFeed(1, _circuitChainlink[1], 1, 0);
        // Picking the minimum price between FRAX and USDC, multiplying it by the pool's virtual price
        usdcPrice = usdcPrice >= fraxPrice ? fraxPrice : usdcPrice;
        quoteAmount = _readChainlinkFeed((FRAXBP.get_virtual_price() * usdcPrice), _circuitChainlink[2], 0, 0);
    }
}