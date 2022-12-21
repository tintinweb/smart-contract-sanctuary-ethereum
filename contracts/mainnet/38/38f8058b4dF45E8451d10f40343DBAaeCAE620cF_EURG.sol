// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";

import "ERC20ElasticSupply.sol";


/**
* @title EURG
* @author Geminon Protocol
* @notice Euro Stablecoin
*/
contract EURG is ERC20ElasticSupply {

    address public priceFeed;
    uint8 public priceFeedDecimals;
    bool public isInitialized;

    
    constructor(address priceFeed_) ERC20ElasticSupply("Geminon Euro", "EURG", 50, 1e24) {
        priceFeed = priceFeed_;
        priceFeedDecimals = AggregatorV3Interface(priceFeed).decimals();
        isInitialized = false;
        require(priceFeedDecimals <= 18); // dev: Too many decimals
    }


    /// @dev Initializes the EURG token adding the address of the stablecoin 
    /// minter contract. This function can only be called once
    /// after deployment. Owner can't be a minter.
    /// @param scMinter Stablecoin minter address. 
    function initialize(address scMinter) external onlyOwner {
        require(!isInitialized); // dev: Initialized
        require(scMinter != address(0)); // dev: Address 0
        require(scMinter != owner()); // dev: Minter is owner

        minters[scMinter] = true;
        isInitialized = true;
    }

    
    /// @dev Updates the address of the Chainlink oracle that provides the peg values. 7 days timelock.
    function updatePriceFeed(address priceFeed_) external onlyOwner {
        require(changeRequests[priceFeed].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[priceFeed].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[priceFeed].newAddressRequested == priceFeed_); // dev: Different address requested

        changeRequests[priceFeed].changeRequested = false;
        priceFeed = priceFeed_;
        priceFeedDecimals = AggregatorV3Interface(priceFeed).decimals();
        
        require(priceFeedDecimals <= 18, 'Oracle has too many decimals');
    }

    
    /// @dev Compatibility with ERC20Indexed tokens
    function getOrUpdatePegValue() public view returns(uint256) {
        return getPegValue();
    }

    /// @dev Get the current value of the peg in USD with 18 decimals
    function getPegValue() public view returns(uint256) {
        (, int256 answer, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        return uint256(answer) * 10**(18-priceFeedDecimals);
    }
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

import "ERC20.sol";
import "Ownable.sol";

import "TimeLocks.sol";


/**
* @title ERC20ElasticSupply
* @author Geminon Protocol
* @notice Base implementation for tokens that can be minted and burned by
* whitelisted addresses. New minters can only be added after a 7 days
* period after the request of the addition. The maximum amount that can be
* minted each day is limited for security. This limit varies depending on 
* the existing supply.
*/
contract ERC20ElasticSupply is ERC20, Ownable, TimeLocks {

    uint32 public baseMintRatio;
    uint256 public thresholdLimitMint;
    uint64 private _timestampLastMint;
    int256 private _meanMintRatio;

    mapping(address => bool) public minters;

    event TokenMinted(address indexed from, address indexed to, uint256 amount);
    event TokenBurned(address indexed from, address indexed to, uint256 amount);
    event MinterAdded(address minter_address);
    event MinterRemoved(address minter_address);

    modifier onlyMinter() {
       require(minters[msg.sender] == true); // dev: Only minter
        _;
    }


    /// @param baseMintRatio_ max percentage of the supply that can be minted per day, 3 decimals [1,1000]
    /// @param thresholdLimitMint_ Minimum supply minted to begin requiring the maxMintRatio limit. 18 decimals.
    constructor(string memory name, string memory symbol, uint32 baseMintRatio_, uint256 thresholdLimitMint_) 
        ERC20(name, symbol) 
    {
        baseMintRatio = baseMintRatio_;
        thresholdLimitMint = thresholdLimitMint_;
    }


    /// @dev Add minter address. It has a 7 days timelock.
    function addMinter(address newMinter) external onlyOwner {
        require(changeRequests[address(0)].changeRequested); // dev: Not requested
        require(block.timestamp - changeRequests[address(0)].timestampRequest > 7 days); // dev: Time elapsed
        require(newMinter == changeRequests[address(0)].newAddressRequested); // dev: Wrong address
        require(minters[newMinter] == false); // dev: Minter exists
        
        minters[newMinter] = true;
        changeRequests[address(0)].changeRequested = false;
        
        emit MinterAdded(newMinter);
    }

    /// @dev Removes minter address. Does not use timelock
    function removeMinter(address minter) external onlyOwner {
        require(changeRequests[minter].changeRequested); // dev: Not requested
        require(minters[minter] == true); // dev: Minter does not exist
        
        minters[minter] = false;
        changeRequests[minter].changeRequested = false;
        
        emit MinterRemoved(minter);
    }


    /// @dev Mints tokens. Amount is limited to a fraction of the supply per day
    function mint(address to, uint256 amount) external onlyMinter {
        _requireMaxMint(amount);
        
        _timestampLastMint = uint64(block.timestamp);
        _mint(to, amount);

        emit TokenMinted(msg.sender, to, amount);
    }

    /// @dev Burns tokens. Discounts burned amount from daily mint limit
    function burn(address from, uint256 amount) external onlyMinter {
        _meanDailyAmount(-_toInt256(amount));

        _timestampLastMint = uint64(block.timestamp);
        _burn(from, amount);

        emit TokenBurned(msg.sender, from, amount);
    }

    /// @notice Calculates the max amount of the token that can be minted
    function maxAmountMintable() public view returns(uint256) {
        int256 maxDailyMintable = _toInt256(_maxMintRatio()*totalSupply()) / 1e3;
        (int256 w, int256 w2) = _weightsMean();
        int256 maxAmount = (1e6*maxDailyMintable - w2*_meanMintRatio)/w;
        return maxAmount > 0 ? uint256(maxAmount) : 0;
    }
    
    /// @dev Checks that the amount minted is not higher than the max allowed
    /// only when a total supply level has been reached.
    function _requireMaxMint(uint256 amount) internal virtual {
        if (totalSupply() > thresholdLimitMint) {
            int256 maxDailyMintable = _toInt256(_maxMintRatio()*totalSupply()) / 1e3;
            require(_meanDailyAmount(_toInt256(amount)) <= maxDailyMintable, 'Max mint rate');
        }
    }

    /// @dev Calculates an exponential moving average that tracks the amount 
    /// of tokens minted in the last 24 hours.
    function _meanDailyAmount(int256 amount) internal returns(int256) {
        (int256 w, int256 w2) = _weightsMean();
        _meanMintRatio = (w*amount + w2*_meanMintRatio) / 1e6;
        return _meanMintRatio;
    }


    /// @dev Calculates the max percentage of supply that can be minted depending
    /// on the actual supply. Simulates a logarithmic curve. It is calibrated
    /// for stablecoins supply.
    function _maxMintRatio() internal view returns(uint256 mintRatio) {
        uint256 supply = totalSupply();
                
        if (supply < 1e5*1e18)
            mintRatio = (baseMintRatio * (1000*1e6 - 900*1e6 * supply / (1e5*1e18))) / 1e6;
        
        else if (supply < 1e6*1e18)
            mintRatio = (baseMintRatio * (100*1e6 - 80*1e6 * (supply-1e5*1e18) / (9*1e5*1e18))) / 1e6;
    
        else if (supply < 1e7*1e18)
            mintRatio = (baseMintRatio * (20*1e6 - 10*1e6 * (supply-1e6*1e18) / (9*1e6*1e18))) / 1e6;
        
        else if (supply < 1e8*1e18)
            mintRatio = (baseMintRatio * (10*1e6 - 6*1e6 * (supply-1e7*1e18) / (9*1e7*1e18))) / 1e6;
            
        else if (supply < 1e9*1e18)
            mintRatio = (baseMintRatio * (4*1e6 - 2*1e6 * (supply-1e8*1e18) / (9*1e8*1e18))) / 1e6;
            
        else if (supply < 1e10*1e18)
            mintRatio = (baseMintRatio * (2*1e6 - 1e6 * (supply-1e9*1e18) / (9*1e9*1e18))) / 1e6;
        
        else
            mintRatio = baseMintRatio;
    }

    /// @dev safe casting of integer to avoid overflow
    function _toInt256(uint256 value) internal pure returns(int256) {
        require(value <= uint256(type(int256).max)); // dev: Unsafe casting
        return int256(value);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
pragma solidity ^0.8.0;

import "Ownable.sol";


/**
* @title TimeLocks
* @author Geminon Protocol
* @dev Utility to protect smart contracts against instant changes
* on critical infrastructure. Sets a two step procedure to change
* the address of a smart contract that is used by another contract.
*/
contract TimeLocks is Ownable {

    struct ContractChangeRequest {
        bool changeRequested;
        uint64 timestampRequest;
        address newAddressRequested;
    }

    mapping(address => ContractChangeRequest) public changeRequests;

    
    /// @dev Creates a request to change the address of a smart contract.
    function requestAddressChange(address actualContract, address newContract) 
        external 
        onlyOwner 
    {
        require(newContract != address(0)); // dev: address 0
        
        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: newContract
            });
        
        changeRequests[actualContract] = changeRequest;
    }

    /// @dev Creates a request to add a new address of a smart contract.
    function requestAddAddress(address newContract) external onlyOwner {
        require(newContract != address(0)); // dev: address 0

        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: newContract
            });
        
        changeRequests[address(0)] = changeRequest;
    }

    /// @dev Creates a request to remove the address of a smart contract.
    function requestRemoveAddress(address oldContract) external onlyOwner {
        require(oldContract != address(0)); // dev: address zero
        
        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: address(0)
            });
        
        changeRequests[oldContract] = changeRequest;
    }
}