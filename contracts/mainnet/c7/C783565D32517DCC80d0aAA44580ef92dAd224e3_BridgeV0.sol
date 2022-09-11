// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "Pausable.sol";
import "IERC20ElasticSupply.sol";
import "IGeminonOracle.sol";


/**
* @title BridgeV0
* @author Geminon Protocol
* @notice Private bridge for interchain arbitrage.
* This bridge can only be used by one address (the arbitrageur).
* It has a limit of 10.000$ per day of mintable GEX value. This
* value can't be modified: the bridge is designed to deprecate itself as
* the protocol grows and other ways of arbitrage are available.
*/
contract BridgeV0 is Ownable, Pausable {

    IERC20ElasticSupply private immutable GEX;
    IGeminonOracle private immutable oracle;

    address public arbitrageur;
    address public validator;

    uint256 public immutable valueLimit;
    int256 public balanceVirtualGEX;
    
    uint64 private _timestampLastMint;
    int256 private _meanMintRatio;

    mapping(address => uint256) public claims;


    modifier onlyArbitrageur {
        require(msg.sender == arbitrageur);
        _;
    }

    modifier onlyValidator {
        require(msg.sender == validator);
        _;
    }



    constructor(address gexToken, address arbitrageur_, address validator_, address oracle_) {
        GEX = IERC20ElasticSupply(gexToken);
        arbitrageur = arbitrageur_;
        validator = validator_;
        oracle = IGeminonOracle(oracle_);

        _timestampLastMint = uint64(block.timestamp);

        valueLimit = 10000 * 1e18;
    }


    /// @dev Owner can set the arbitrageur address
    function setArbitrageur(address arbitrageur_) external onlyOwner {
        claims[arbitrageur] = 0;
        arbitrageur = arbitrageur_;
    }

    /// @dev Owner can set the validator address
    function setValidator(address validator_) external onlyOwner {
        validator = validator_;
    }


    /// @dev Arbitrageur sends GEX through the bridge
    function sendGEX(uint256 amount) external onlyArbitrageur {
        _meanDailyAmount(-_toInt256(amount));

        balanceVirtualGEX += int256(amount);
        GEX.burn(msg.sender, amount);
    }

    /// @dev Arbitrageur claims GEX sent from other chain
    function claimGEX(uint256 amount) external onlyArbitrageur {
        require(claims[msg.sender] >= amount); // dev: Invalid claim
        _requireMaxMint(amount);

        balanceVirtualGEX -= int256(amount);
        claims[msg.sender] -= amount;
        GEX.mint(msg.sender, amount);
    }


    /// @dev Validator validates the bridge transaction
    function validateClaim(address claimer, uint256 amount) external onlyValidator {
        require(claimer == arbitrageur); // dev: claimer is not the arbitrageur
        claims[claimer] += amount;
    }

    /// @dev Calculates max amount that can be minted by the bridge to not pass the daily limit
    function getMaxMintable() external view onlyArbitrageur returns(uint256) {
        int256 maxAmount = _toInt256((valueLimit*1e18) / oracle.getSafePrice());
        (int256 w, int256 w2) = _weightsMean();

        int256 amount = (1e6*maxAmount - w2*_meanMintRatio)/w;
        amount = amount > maxAmount ? maxAmount : amount;
        return amount > 0 ? uint256(amount) : 0;
    }


    /// @dev Checks that the amount minted is not higher than the max allowed
    function _requireMaxMint(uint256 amount) private {
        uint256 price = oracle.getSafePrice();
        require((price * amount)/1e18 <= valueLimit);

        int256 meanValue = (_toInt256(price) * _meanDailyAmount(_toInt256(amount))) / 1e18;
        require(meanValue <= _toInt256(valueLimit)); // dev: Max mint rate
    }


    /// @dev Calculates an exponential moving average that tracks the amount 
    /// of tokens minted in the last 24 hours.
    function _meanDailyAmount(int256 amount) private returns(int256) {
        (int256 w, int256 w2) = _weightsMean();
        _meanMintRatio = (w*amount + w2*_meanMintRatio) / 1e6;
        return _meanMintRatio;
    }

    /// @dev Calculates the weights of the mean of the mint ratio
    function _weightsMean() private view returns(int256 w, int256 w2) {
        int256 elapsed = _toInt256(block.timestamp - _timestampLastMint);
        
        if (elapsed > 0) {
            int256 timeWeight = (24 hours * 1e6) / elapsed;
            int256 alpha = 2*1e12 / (1e6+timeWeight);
            w = (alpha*timeWeight)/1e6;
            w2 = 1e6 - alpha;
        } else {
            w = 1e6;
            w2 = 1e6;
        }
    }

    /// @dev safe casting of integer to avoid overflow
    function _toInt256(uint256 value) private pure returns(int256) {
        require(value <= uint256(type(int256).max)); // dev: Unsafe casting
        return int256(value);
    } 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";



/**
* @title IERC20ElasticSupply
* @author Geminon Protocol
* @dev Interface for the ERC20ElasticSupply contract
*/
interface IERC20ElasticSupply is IERC20 {

    event TokenMinted(address indexed from, address indexed to, uint256 amount);

    event TokenBurned(address indexed from, address indexed to, uint256 amount);

    event MinterAdded(address minter_address);

    event MinterRemoved(address minter_address);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function addMinter(address newMinter) external;

    function removeMinter(address minter) external;
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
pragma solidity ^0.8.0;


interface IGeminonOracle {

    // +++++++++++++++++++  PUBLIC STATE VARIABLES  +++++++++++++++++++++++++

    function isAnyPoolMigrating() external view returns(bool);
    
    function isAnyPoolRemoving() external view returns(bool);

    function scMinter() external view returns(address);

    function treasuryLender() external view returns(address);
    
    function feesCollector() external view returns(address);

    function ageSCMinter() external view returns(uint64);

    function ageTreasuryLender() external view returns(uint64);
    
    function ageFeesCollector() external view returns(uint64);
    
    function isMigratingPool(address) external view returns(bool);
    
    function isRemovingPool(address) external view returns(bool);

    function isMigratingMinter() external view returns(bool);

    function isPool(address) external view returns(bool);

    function poolAge(address) external view returns(uint64);


    // ++++++++++++++++++++++++++  MIGRATIONS  ++++++++++++++++++++++++++++++

    function requestMigratePool(address newPool) external;

    function setMigrationDone() external;

    function cancelMigration() external;

    function requestRemovePool() external;

    function setRemoveDone() external;

    function cancelRemove() external;

    
    function requestMigrateMinter(address newMinter) external;

    function setMinterMigrationDone() external;

    function cancelMinterMigration() external;


    // ++++++++++++++++++++  INFORMATIVE FUNCTIONS  +++++++++++++++++++++++++

    function getSafePrice() external view returns(uint256);
    
    function getLastPrice() external view returns(uint256);

    function getMeanVolume() external view returns(uint256);

    function getLastVolume() external view returns(uint256);

    function getLockedAmountGEX() external view returns(uint256);

    function getTotalMintedGEX() external view returns(uint256);

    function getTotalCollatValue() external view returns(uint256);

    function getPoolCollatWeight(address pool) external view returns(uint256);

    function getHighestGEXPool() external view returns(address);
}