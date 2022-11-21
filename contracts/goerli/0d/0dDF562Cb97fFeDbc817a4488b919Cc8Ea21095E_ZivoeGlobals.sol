// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

import "../lib/OpenZeppelin/Ownable.sol";
import "../lib/OpenZeppelin/IERC20Metadata.sol";

import "./libraries/ZivoeMath.sol";

/// @dev    This contract handles the global variables for the Zivoe protocol.
contract ZivoeGlobals is Ownable {
    using ZivoeMath for uint256;

    // ---------------------
    //    State Variables
    // ---------------------

    address public DAO; /// @dev The ZivoeDAO.sol contract.
    address public ITO; /// @dev The ZivoeITO.sol contract.
    address public stJTT; /// @dev The ZivoeRewards.sol ($zJTT) contract.
    address public stSTT; /// @dev The ZivoeRewards.sol ($zSTT) contract.
    address public stZVE; /// @dev The ZivoeRewards.sol ($ZVE) contract.
    address public vestZVE; /// @dev The ZivoeRewardsVesting.sol ($ZVE) vesting contract.
    address public YDL; /// @dev The ZivoeYDL.sol contract.
    address public zJTT; /// @dev The ZivoeTrancheToken.sol ($zJTT) contract.
    address public zSTT; /// @dev The ZivoeTrancheToken.sol ($zSTT) contract.
    address public ZVE; /// @dev The ZivoeToken.sol contract.
    address public ZVL; /// @dev The Zivoe Laboratory.
    address public ZVT; /// @dev The ZivoeTranches.sol contract.
    address public GOV; /// @dev The Governor contract.
    address public TLC; /// @dev The Timelock contract.

    /// @dev This ratio represents the maximum size allowed for junior tranche, relative to senior tranche.
    ///      A value of 2,000 represent 20%, thus junior tranche at maximum can be 30% the size of senior tranche.
    uint256 public maxTrancheRatioBIPS = 2000;

    /// @dev These two values control the min/max $ZVE minted per stablecoin deposited to ZivoeTranches.sol.
    uint256 public minZVEPerJTTMint = 0;
    uint256 public maxZVEPerJTTMint = 0;

    /// @dev These values represent basis points ratio between zJTT.totalSupply():zSTT.totalSupply() for maximum rewards (affects above slope).
    uint256 public lowerRatioIncentive = 1000;
    uint256 public upperRatioIncentive = 2000;

    /// @dev Tracks net defaults in system.
    uint256 public defaults;

    mapping(address => bool) public isKeeper; /// @dev Whitelist for keepers, responsible for pre-initiating actions.
    mapping(address => bool) public isLocker; /// @dev Whitelist for lockers, for DAO interactions and accounting accessibility.
    mapping(address => bool) public stablecoinWhitelist; /// @dev Whitelist for acceptable stablecoins throughout system (ZVE, YDL).

    // -----------------
    //    Constructor
    // -----------------

    /// @notice Initializes the ZivoeGlobals.sol contract.
    constructor() {}

    // ------------
    //    Events
    // ------------

    /// @notice This event is emitted during initialize when setting ZVL() variable.
    /// @param controller The address representing Zivoe Labs / Dev entity.
    event AccessControlSetZVL(address indexed controller);

    /// @notice This event is emitted when decreaseNetDefaults() is called.
    /// @param amount Amount of defaults decreased.
    /// @param updatedDefaults Total defaults funds after event.
    event DefaultsDecreased(uint256 amount, uint256 updatedDefaults);

    /// @notice This event is emitted when increaseNetDefaults() is called.
    /// @param amount Amount of defaults increased.
    /// @param updatedDefaults Total defaults after event.
    event DefaultsIncreased(uint256 amount, uint256 updatedDefaults);

    /// @notice Emitted during updateIsLocker().
    /// @param  locker  The locker whose status as a locker is being modified.
    /// @param  allowed The boolean value to assign.
    event UpdatedLockerStatus(address indexed locker, bool allowed);

    /// @notice This event is emitted when updateIsKeeper() is called.
    /// @param  account The address whose status as a keeper is being modified.
    /// @param  status The new status of "account".
    event UpdatedKeeperStatus(address indexed account, bool status);

    /// @notice This event is emitted when updateMaxTrancheRatio() is called.
    /// @param  oldValue The old value of maxTrancheRatioBIPS.
    /// @param  newValue The new value of maxTrancheRatioBIPS.
    event UpdatedMaxTrancheRatioBIPS(uint256 oldValue, uint256 newValue);

    /// @notice This event is emitted when updateMinZVEPerJTTMint() is called.
    /// @param  oldValue The old value of minZVEPerJTTMint.
    /// @param  newValue The new value of minZVEPerJTTMint.
    event UpdatedMinZVEPerJTTMint(uint256 oldValue, uint256 newValue);

    /// @notice This event is emitted when updateMaxZVEPerJTTMint() is called.
    /// @param  oldValue The old value of maxZVEPerJTTMint.
    /// @param  newValue The new value of maxZVEPerJTTMint.
    event UpdatedMaxZVEPerJTTMint(uint256 oldValue, uint256 newValue);

    /// @notice This event is emitted when updateLowerRatioIncentive() is called.
    /// @param  oldValue The old value of lowerRatioJTT.
    /// @param  newValue The new value of lowerRatioJTT.
    event UpdatedLowerRatioIncentive(uint256 oldValue, uint256 newValue);

    /// @notice This event is emitted when updateUpperRatioIncentive() is called.
    /// @param  oldValue The old value of upperRatioJTT.
    /// @param  newValue The new value of upperRatioJTT.
    event UpdatedUpperRatioIncentive(uint256 oldValue, uint256 newValue);

    /// @notice This event is emitted when updateStablecoinWhitelist() is called.
    /// @param  asset The stablecoin to update.
    /// @param  allowed The boolean value to assign.
    event UpdatedStablecoinWhitelist(address indexed asset, bool allowed);

    // ---------------
    //    Modifiers
    // ---------------

    modifier onlyZVL() {
        require(
            _msgSender() == ZVL,
            "ZivoeGlobals::onlyZVL() _msgSender() != ZVL"
        );
        _;
    }

    // ---------------
    //    Functions
    // ---------------

    /// @notice Call when a default is resolved, decreases net defaults system-wide.
    /// @dev    The value "amount" should be standardized to WEI.
    function decreaseDefaults(uint256 amount) external {
        require(
            isLocker[_msgSender()],
            "ZivoeGlobals::decreaseDefaults() !isLocker[_msgSender()]"
        );
        defaults -= amount;
        emit DefaultsDecreased(amount, defaults);
    }

    /// @notice Call when a default occurs, increases net defaults system-wide.
    /// @dev    The value "amount" should be standardized to WEI.
    function increaseDefaults(uint256 amount) external {
        require(
            isLocker[_msgSender()],
            "ZivoeGlobals::increaseDefaults() !isLocker[_msgSender()]"
        );
        defaults += amount;
        emit DefaultsIncreased(amount, defaults);
    }

    /// @notice Initialze the variables within this contract (after all contracts have been deployed).
    /// @dev    This function should only be called once.
    /// @param  globals Array of addresses representing all core system contracts.
    function initializeGlobals(address[] calldata globals) external onlyOwner {
        // require(
        //     DAO == address(0),
        //     "ZivoeGlobals::initializeGlobals() DAO != address(0)"
        // );

        emit AccessControlSetZVL(globals[10]);

        DAO = globals[0];
        ITO = globals[1];
        stJTT = globals[2];
        stSTT = globals[3];
        stZVE = globals[4];
        vestZVE = globals[5];
        YDL = globals[6];
        zJTT = globals[7];
        zSTT = globals[8];
        ZVE = globals[9];
        ZVL = globals[10];
        GOV = globals[11];
        TLC = globals[12];
        ZVT = globals[13];

        stablecoinWhitelist[0x3C65405E55BF261f24Ea4dc9F69c655fe53064BE] = true; // DAI
        stablecoinWhitelist[0x2158A127E35c2249942c094266e6b13fe6871823] = true; // USDC
        stablecoinWhitelist[0xBbf536367EE558470823d483F13FD2263977497d] = true; // USDT
    }

    /// @notice Updates the keeper whitelist.
    /// @param  keeper The address of the keeper.
    /// @param  status The status to assign to the "keeper" (true = allowed, false = restricted).
    function updateIsKeeper(address keeper, bool status) external onlyZVL {
        emit UpdatedKeeperStatus(keeper, status);
        isKeeper[keeper] = status;
    }

    /// @notice Modifies the locker whitelist.
    /// @param  locker  The locker to update.
    /// @param  allowed The value to assign (true = permitted, false = prohibited).
    function updateIsLocker(address locker, bool allowed) external onlyZVL {
        emit UpdatedLockerStatus(locker, allowed);
        isLocker[locker] = allowed;
    }

    /// @notice Modifies the stablecoin whitelist.
    /// @param  stablecoin The stablecoin to update.
    /// @param  allowed The value to assign (true = permitted, false = prohibited).
    function updateStablecoinWhitelist(address stablecoin, bool allowed)
        external
        onlyZVL
    {
        emit UpdatedStablecoinWhitelist(stablecoin, allowed);
        stablecoinWhitelist[stablecoin] = allowed;
    }

    /// @notice Updates the maximum size of junior tranche, relative to senior tranche.
    /// @dev    A value of 2,000 represent 20% (basis points), meaning the junior tranche
    ///         at maximum can be 20% the size of senior tranche.
    /// @param  ratio The new ratio value.
    function updateMaxTrancheRatio(uint256 ratio) external onlyOwner {
        require(
            ratio <= 3500,
            "ZivoeGlobals::updateMaxTrancheRatio() ratio > 3500"
        );
        emit UpdatedMaxTrancheRatioBIPS(maxTrancheRatioBIPS, ratio);
        maxTrancheRatioBIPS = ratio;
    }

    /// @notice Updates the min $ZVE minted per stablecoin deposited to ZivoeTranches.sol.
    /// @param  min Minimum $ZVE minted per stablecoin.
    function updateMinZVEPerJTTMint(uint256 min) external onlyOwner {
        require(
            min < maxZVEPerJTTMint,
            "ZivoeGlobals::updateMinZVEPerJTTMint() min >= maxZVEPerJTTMint"
        );
        emit UpdatedMinZVEPerJTTMint(minZVEPerJTTMint, min);
        minZVEPerJTTMint = min;
    }

    /// @notice Updates the max $ZVE minted per stablecoin deposited to ZivoeTranches.sol.
    /// @param  max Maximum $ZVE minted per stablecoin.
    function updateMaxZVEPerJTTMint(uint256 max) external onlyOwner {
        require(
            max < 0.1 * 10**18,
            "ZivoeGlobals::updateMaxZVEPerJTTMint() max >= 0.1 * 10**18"
        );
        emit UpdatedMaxZVEPerJTTMint(maxZVEPerJTTMint, max);
        maxZVEPerJTTMint = max;
    }

    /// @notice Updates the lower ratio between tranches for minting incentivization model.
    /// @param  lowerRatio The lower ratio to handle incentivize thresholds.
    function updateLowerRatioIncentive(uint256 lowerRatio) external onlyOwner {
        require(
            lowerRatio >= 1000,
            "ZivoeGlobals::updateLowerRatioIncentive() lowerRatio < 1000"
        );
        require(
            lowerRatio < upperRatioIncentive,
            "ZivoeGlobals::updateLowerRatioIncentive() lowerRatio >= upperRatioIncentive"
        );
        emit UpdatedLowerRatioIncentive(lowerRatioIncentive, lowerRatio);
        lowerRatioIncentive = lowerRatio;
    }

    /// @notice Updates the upper ratio between tranches for minting incentivization model.
    /// @param  upperRatio The upper ratio to handle incentivize thresholds.
    function updateUpperRatioIncentives(uint256 upperRatio) external onlyOwner {
        require(
            upperRatio <= 2500,
            "ZivoeGlobals::updateUpperRatioIncentive() upperRatio > 2500"
        );
        emit UpdatedUpperRatioIncentive(upperRatioIncentive, upperRatio);
        upperRatioIncentive = upperRatio;
    }

    /// @notice Handles WEI standardization of a given asset amount (i.e. 6 decimal precision => 18 decimal precision).
    /// @param amount The amount of a given "asset".
    /// @param asset The asset (ERC-20) from which to standardize the amount to WEI.
    function standardize(uint256 amount, address asset)
        external
        view
        returns (uint256 standardizedAmount)
    {
        standardizedAmount = amount;

        if (IERC20Metadata(asset).decimals() < 18) {
            standardizedAmount *= 10**(18 - IERC20Metadata(asset).decimals());
        } else if (IERC20Metadata(asset).decimals() > 18) {
            standardizedAmount /= 10**(IERC20Metadata(asset).decimals() - 18);
        }
    }

    /// @notice Returns total circulating supply of zSTT and zJTT, accounting for defaults via markdowns.
    /// @return zSTTSupply zSTT.totalSupply() adjusted for defaults.
    /// @return zJTTSupply zJTT.totalSupply() adjusted for defaults.
    function adjustedSupplies()
        external
        view
        returns (uint256 zSTTSupply, uint256 zJTTSupply)
    {
        // Junior tranche decrease by amount of defaults, to a floor of zero.
        uint256 zJTTSupply_unadjusted = IERC20(zJTT).totalSupply();
        zJTTSupply = zJTTSupply_unadjusted.zSub(defaults);

        uint256 zSTTSupply_unadjusted = IERC20(zSTT).totalSupply();
        // Senior tranche decreases if excess defaults exist beyond junior tranche size.
        if (defaults > zJTTSupply_unadjusted) {
            zSTTSupply = zSTTSupply_unadjusted.zSub(
                defaults.zSub(zJTTSupply_unadjusted)
            );
        } else {
            zSTTSupply = zSTTSupply_unadjusted;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.16;

import "./Context.sol";

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
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

/// @dev specialized math functions that always return uint and never revert. 
///      using these make some of the codes shorter. trySub etc from openzeppelin 
///      would have been okay but these tryX math functions return tupples to include information 
///      about the success of the function, which would have resulted in significant waste for our purposes. 
library ZivoeMath {
    
    /// @dev return 0 of div would result in val < 1 or divide by 0
    function zDiv(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;
            if (y > x) return 0;
            return (x / y);
        }
    }

    /// @dev  Subtraction routine that does not revert and returns a singleton, 
    ///         making it cheaper and more suitable for composition and use as an attribute. 
    ///         It returns the closest uint to the actual answer if the answer is not in uint256. 
    ///         IE it gives you 0 instead of reverting. It was made to be a cheaper version of openZepelins trySub.
    function zSub(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y > x) return 0;
            return (x - y);
        }
    }
    
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.16;

import "./IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.16;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.16;

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