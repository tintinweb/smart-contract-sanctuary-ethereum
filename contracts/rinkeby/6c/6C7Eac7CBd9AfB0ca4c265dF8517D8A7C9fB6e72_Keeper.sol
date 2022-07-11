// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LongToken is ERC20, Ownable {
    address[] private _holder_addresses;

    event Mint(address indexed mint_address, uint256 mint_amount);
    event Burn(address indexed burn_address, uint256 burn_amount);

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function allHolderAddresses()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return _holder_addresses;
    }

    function mint(address mint_address_, uint256 mint_amount_)
        external
        onlyOwner
    {
        uint256 curr_bal_ = balanceOf(mint_address_);
        _mint(mint_address_, mint_amount_);
        if (curr_bal_ == 0) {
            _holder_addresses.push(mint_address_);
        }
        emit Mint(mint_address_, mint_amount_);
    }

    function burn(address burn_address_, uint256 burn_amount_)
        external
        onlyOwner
    {
        _burn(burn_address_, burn_amount_);
        emit Burn(burn_address_, burn_amount_);
    }

    function transfer(address recipient_, uint256 amount_)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient_, amount_);
        _holder_addresses.push(recipient_);
        return true;
    }

    function transferFrom(
        address sender_,
        address recipient_,
        uint256 amount_
    ) public override returns (bool) {
        super.transferFrom(sender_, recipient_, amount_);
        _holder_addresses.push(recipient_);
        return true;
    }

    function fetchLastHolderAndPop()
        external
        onlyOwner
        returns (address holder_address_, uint256 holding_amount_)
    {
        holder_address_ = _holder_addresses[_holder_addresses.length - 1];
        holding_amount_ = balanceOf(holder_address_);
        _holder_addresses.pop();
        _burn(holder_address_, holding_amount_);
    }

    function runSettlement(uint256 adj_factor_) external onlyOwner {
        uint256 max_i_ = _holder_addresses.length;

        if (adj_factor_ > 1 ether) {
            uint256 mint_factor_;
            unchecked {
                mint_factor_ = (adj_factor_ - 1 ether);
            }

            for (uint256 i = max_i_; i > 0; ) {
                address holder_address_ = _holder_addresses[i - 1];
                uint256 bal_ = balanceOf(holder_address_);
                if (bal_ == 0) {
                    _holder_addresses[i - 1] = _holder_addresses[max_i_ - 1];
                    unchecked {
                        --max_i_;
                    }
                    _holder_addresses.pop();
                    continue;
                }

                uint256 mint_amount_;
                unchecked {
                    mint_amount_ = (bal_ * mint_factor_) / 1 ether;
                    --i;
                }
                _mint(holder_address_, mint_amount_);
            }
        } else if (adj_factor_ < 1 ether) {
            uint256 burn_factor_;
            unchecked {
                burn_factor_ = (1 ether - adj_factor_);
            }

            for (uint256 i = max_i_; i > 0; ) {
                address holder_address_ = _holder_addresses[i - 1];
                uint256 bal_ = balanceOf(holder_address_);
                if (bal_ == 0) {
                    _holder_addresses[i - 1] = _holder_addresses[max_i_ - 1];
                    unchecked {
                        --max_i_;
                    }
                    _holder_addresses.pop();
                    continue;
                }

                uint256 burn_amount_;
                unchecked {
                    burn_amount_ = (bal_ * burn_factor_) / 1 ether;
                    --i;
                }
                _burn(holder_address_, burn_amount_);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ProxyUSDC is ERC20, Ownable {
    uint256 private _per_address_limit = 1000 ether;
    mapping(address => uint256) private _addresswise_minted_amounts;

    event LimitChange(uint256 old_limit_, uint256 new_limit_);
    event Mint(address indexed sender, uint256 amount);
    event Burn(address indexed burner, uint256 amount);

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function changeLimit(uint256 new_limit_) public onlyOwner {
        emit LimitChange(_per_address_limit, new_limit_);
        _per_address_limit = new_limit_;
    }

    function selfDestruct() public onlyOwner {
        selfdestruct(payable(owner()));
    }

    function withdrawFunds() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function mint() public payable {
        uint256 mint_amount_ = msg.value * 1000;
        _addresswise_minted_amounts[msg.sender] =
            _addresswise_minted_amounts[msg.sender] +
            mint_amount_;
        require(
            _addresswise_minted_amounts[msg.sender] <= _per_address_limit,
            "You have hit the limit of number of USDC you can mint"
        );
        require(
            balanceOf(msg.sender) <= _per_address_limit,
            "You have hit the limit of number of USDC you can own"
        );
        _mint(msg.sender, mint_amount_);
        emit Mint(msg.sender, mint_amount_);
    }

    function burn(uint256 burn_amount_) public {
        _burn(msg.sender, burn_amount_);
        _addresswise_minted_amounts[msg.sender] =
            _addresswise_minted_amounts[msg.sender] -
            burn_amount_;
        emit Burn(msg.sender, burn_amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ShortToken is ERC20, Ownable {
    address[] private _holder_addresses;

    event Mint(address indexed mint_address, uint256 mint_amount);
    event Burn(address indexed burn_address, uint256 burn_amount);

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function allHolderAddresses()
        external
        view
        onlyOwner
        returns (address[] memory)
    {
        return _holder_addresses;
    }

    function mint(address mint_address_, uint256 mint_amount_)
        external
        onlyOwner
    {
        uint256 curr_bal_ = balanceOf(mint_address_);
        _mint(mint_address_, mint_amount_);
        if (curr_bal_ == 0) {
            _holder_addresses.push(mint_address_);
        }
        emit Mint(mint_address_, mint_amount_);
    }

    function burn(address burn_address_, uint256 burn_amount_)
        external
        onlyOwner
    {
        _burn(burn_address_, burn_amount_);
        emit Burn(burn_address_, burn_amount_);
    }

    function transfer(address recipient_, uint256 amount_)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient_, amount_);
        _holder_addresses.push(recipient_);
        return true;
    }

    function transferFrom(
        address sender_,
        address recipient_,
        uint256 amount_
    ) public override returns (bool) {
        super.transferFrom(sender_, recipient_, amount_);
        _holder_addresses.push(recipient_);
        return true;
    }

    function fetchLastHolderAndPop()
        external
        onlyOwner
        returns (address holder_address_, uint256 holding_amount_)
    {
        holder_address_ = _holder_addresses[_holder_addresses.length - 1];
        holding_amount_ = balanceOf(holder_address_);
        _holder_addresses.pop();
        _burn(holder_address_, holding_amount_);
    }

    function runSettlement(uint256 adj_factor_) external onlyOwner {
        uint256 max_i_ = _holder_addresses.length;

        if (adj_factor_ > 1 ether) {
            uint256 mint_factor_;
            unchecked {
                mint_factor_ = (adj_factor_ - 1 ether);
            }

            for (uint256 i = max_i_; i > 0; ) {
                address holder_address_ = _holder_addresses[i - 1];
                uint256 bal_ = balanceOf(holder_address_);
                if (bal_ == 0) {
                    _holder_addresses[i - 1] = _holder_addresses[max_i_ - 1];
                    unchecked {
                        --max_i_;
                    }
                    _holder_addresses.pop();
                    continue;
                }

                uint256 mint_amount_;
                unchecked {
                    mint_amount_ = (bal_ * mint_factor_) / 1 ether;
                    --i;
                }
                _mint(holder_address_, mint_amount_);
            }
        } else if (adj_factor_ < 1 ether) {
            uint256 burn_factor_;
            unchecked {
                burn_factor_ = (1 ether - adj_factor_);
            }

            for (uint256 i = max_i_; i > 0; ) {
                address holder_address_ = _holder_addresses[i - 1];
                uint256 bal_ = balanceOf(holder_address_);
                if (bal_ == 0) {
                    _holder_addresses[i - 1] = _holder_addresses[max_i_ - 1];
                    unchecked {
                        --max_i_;
                    }
                    _holder_addresses.pop();
                    continue;
                }

                uint256 burn_amount_;
                unchecked {
                    burn_amount_ = (bal_ * burn_factor_) / 1 ether;
                    --i;
                }
                _burn(holder_address_, burn_amount_);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UserInterface.sol";
import "../Utils/USDCAccountManager.sol";
import "../Utils/Design1/ChainlinkConsumer.sol";

contract UI2 is UserInterface {
    PriceConsumerV3 private _consumer;

    uint256 private _individual_switch_limit;
    uint256 private _vault_max_limit;

    mapping(address => bool) private _no_riskcheck;
    address[] private _no_riskcheck_addresses;

    constructor(
        uint256 m_,
        int8 opt_type_,
        address usdc_account_manager_,
        address price_oracle_address_
    ) UserInterface(m_, opt_type_, usdc_account_manager_) {
        _consumer = new PriceConsumerV3(price_oracle_address_);
        _individual_switch_limit = 1000000 ether;
        _vault_max_limit = 1000000 ether;
    }

    function setIndividualSwitchLimit(uint256 individual_switch_limit_)
        public
        onlyRoleHolder(0)
    {
        _individual_switch_limit = individual_switch_limit_;
    }

    function setVaultMaxLimit(uint256 vault_max_limit_)
        public
        onlyRoleHolder(0)
    {
        _vault_max_limit = vault_max_limit_;
    }

    function individualSwitchLimit() public view returns (uint256) {
        return _individual_switch_limit;
    }

    function vaultMaxLimit() public view returns (uint256) {
        return _vault_max_limit;
    }

    function setNoRiskcheck(address address_) public onlyRoleHolder(0) {
        if (!_no_riskcheck[address_]) {
            _no_riskcheck[address_] = true;
            _no_riskcheck_addresses.push(address_);
        }
    }

    function revokeNoRiskcheck(address address_) public onlyRoleHolder(0) {
        _no_riskcheck[address_] = false;
    }

    function riskCheck(address buyer_address_, uint256 buy_amount_usdc_)
        internal
        override
        returns (bool)
    {
        if (_no_riskcheck[buyer_address_]) {
            return true;
        }
        uint256 usr_total_ = buy_amount_usdc_ +
            longTokenBuyAmount(buyer_address_) +
            shortTokenBuyAmount(buyer_address_);

        uint256 tentative_tokens_to_mint_ = (usr_total_ * (1 ether)) /
            (tentativePricePerToken());

        bool usr_riskcheck_ = LongToken(longTokenAddress()).balanceOf(
            buyer_address_
        ) +
            ShortToken(shortTokenAddress()).balanceOf(buyer_address_) +
            tentative_tokens_to_mint_ <
            _individual_switch_limit;

        if (!usr_riskcheck_) {
            // emit IndividualMaxLimit(buyer_address_);
            return false;
        }

        uint256 max_i_ = _no_riskcheck_addresses.length;
        uint256 mm_bal_ = 0;
        for (uint256 i = max_i_; i > 0; ) {
            address mm_address_ = _no_riskcheck_addresses[i - 1];
            if (_no_riskcheck[mm_address_]) {
                mm_bal_ +=
                    ((LongToken(longTokenAddress()).balanceOf(mm_address_) +
                        ShortToken(shortTokenAddress()).balanceOf(
                            mm_address_
                        )) * (tentativePricePerToken())) /
                    (1 ether);
            } else {
                _no_riskcheck_addresses[i - 1] = _no_riskcheck_addresses[
                    max_i_ - 1
                ];
                --max_i_;
                _no_riskcheck_addresses.pop();
            }

            unchecked {
                --i;
            }
        }

        bool total_risk_check_ = (getUSDCValue() +
            totalLongTokenBuyAmount() +
            totalShortTokenBuyAmount() +
            buy_amount_usdc_ -
            mm_bal_) < _vault_max_limit;
        if (!total_risk_check_) {
            // emit VaultMaxLimitReached();
            return false;
        }

        return true;
    }

    function lastSettlementPricePerToken()
        public
        view
        override
        returns (uint256)
    {
        return defaultPricePerToken();
    }

    function tentativePricePerToken() public view override returns (uint256) {
        // the price will always be same and equal to the default px
        return defaultPricePerToken();
    }

    function thisCyclePremium() external view returns (uint256) {
        return calcM(block.timestamp);
    }

    function hourlyPremium() external view returns (uint256) {
        return _getM();
    }

    // Ratio of short token to overall supply
    function tentativeShortRatio() public view returns (uint256) {
        // current total tokens
        // uint256 total_existing_long_tokens_ = totalLongTokenSupply();
        uint256 total_existing_short_tokens_ = totalShortTokenSupply();
        uint256 total_existing_ = totalLongTokenSupply() +
            total_existing_short_tokens_;

        // pending buys
        // uint256 total_long_token_buy_amount_usdc_ = totalLongTokenBuyAmount();
        uint256 total_short_token_buy_amount_usdc_ = totalShortTokenBuyAmount();
        uint256 total_buy_amount_usdc_ = totalLongTokenBuyAmount() +
            total_short_token_buy_amount_usdc_;

        uint256 tentative_price_per_token_ = tentativePricePerToken();
        uint256 total_short_token_buy_amount_ = (total_short_token_buy_amount_usdc_ *
                1 ether) / tentative_price_per_token_;
        uint256 total_buy_amount_ = (total_buy_amount_usdc_ * 1 ether) /
            tentative_price_per_token_;

        // pending sell
        // uint256 total_long_token_sell_amount_ = totalLongTokenSellAmount();
        uint256 total_short_token_sell_amount_ = totalShortTokenSellAmount();
        uint256 total_sell_amount_ = totalLongTokenSellAmount() +
            total_short_token_sell_amount_;

        // pending switch
        // uint256 total_long_to_short_ = totalLongToShortAmount();
        // uint256 total_short_to_long_ = totalShortToLongAmount();

        uint256 total_tentative_tokens_ = total_existing_ +
            total_buy_amount_ -
            total_sell_amount_;

        if (total_tentative_tokens_ == 0) {
            return 0;
        }

        uint256 total_tentative_short_tokens_ = (total_existing_short_tokens_ +
            total_short_token_buy_amount_ +
            totalLongToShortAmount()) -
            (total_short_token_sell_amount_ + totalShortToLongAmount());

        uint256 tentative_short_token_ratio_ = (total_tentative_short_tokens_ *
            1 ether) / total_tentative_tokens_;

        // Assert that short ratio cannot be grater than 0
        assert(tentative_short_token_ratio_ < 1 ether);

        return tentative_short_token_ratio_;
    }

    function longTokenPayoff(int256 pct_price_change_, bool max_m_)
        external
        view
        override
        returns (int256)
    {
        uint256 tentative_short_token_ratio_ = tentativeShortRatio();
        if (
            tentative_short_token_ratio_ == 0 ||
            tentative_short_token_ratio_ == 1 ether
        ) {
            return 0;
        }

        uint256 m_;
        if (max_m_) {
            m_ = _getM();
        } else {
            m_ = calcM(block.timestamp);
        }

        uint256 x_ = calcX(pct_price_change_, tentative_short_token_ratio_, m_);

        return
            int256(
                longTokenAdjustmentFactor(
                    pct_price_change_,
                    tentative_short_token_ratio_,
                    m_,
                    x_
                )
            ) - 1 ether;
    }

    function longTokenMaxGain(bool max_m_)
        external
        view
        override
        returns (int256)
    {
        uint256 tentative_short_token_ratio_ = tentativeShortRatio();
        if (
            tentative_short_token_ratio_ == 0 ||
            tentative_short_token_ratio_ == 1 ether
        ) {
            return 0;
        }

        uint256 m_;
        if (max_m_) {
            m_ = _getM();
        } else {
            m_ = calcM(block.timestamp);
        }

        return
            int256(
                (tentative_short_token_ratio_ * (1 ether)) /
                    (1 ether - tentative_short_token_ratio_) -
                    m_
            );
    }

    function longTokenMaxLoss(bool max_m_)
        external
        view
        override
        returns (int256)
    {
        uint256 tentative_short_token_ratio_ = tentativeShortRatio();
        if (
            tentative_short_token_ratio_ == 0 ||
            tentative_short_token_ratio_ == 1 ether
        ) {
            return 0;
        }

        uint256 m_;
        if (max_m_) {
            m_ = _getM();
        } else {
            m_ = calcM(block.timestamp);
        }

        return int256(m_) * -1;
    }

    function shortTokenPayoff(int256 pct_price_change_, bool max_m_)
        external
        view
        override
        returns (int256)
    {
        uint256 tentative_short_token_ratio_ = tentativeShortRatio();
        if (
            tentative_short_token_ratio_ == 0 ||
            tentative_short_token_ratio_ == 1 ether
        ) {
            return 0;
        }

        uint256 m_;
        if (max_m_) {
            m_ = _getM();
        } else {
            m_ = calcM(block.timestamp);
        }

        uint256 x_ = calcX(pct_price_change_, tentative_short_token_ratio_, m_);

        return
            int256(
                shortTokenAdjustmentFactor(
                    pct_price_change_,
                    tentative_short_token_ratio_,
                    m_,
                    x_
                )
            ) - 1 ether;
    }

    function shortTokenMaxGain(bool max_m_)
        external
        view
        override
        returns (int256)
    {
        uint256 tentative_short_token_ratio_ = tentativeShortRatio();
        if (
            tentative_short_token_ratio_ == 0 ||
            tentative_short_token_ratio_ == 1 ether
        ) {
            return 0;
        }

        uint256 m_;
        if (max_m_) {
            m_ = _getM();
        } else {
            m_ = calcM(block.timestamp);
        }

        return
            int256(
                (m_ * (1 ether - tentative_short_token_ratio_)) /
                    tentative_short_token_ratio_
            );
    }

    function shortTokenMaxLoss(bool max_m_)
        external
        view
        override
        returns (int256)
    {
        uint256 tentative_short_token_ratio_ = tentativeShortRatio();
        if (
            tentative_short_token_ratio_ == 0 ||
            tentative_short_token_ratio_ == 1 ether
        ) {
            return 0;
        }

        uint256 m_;
        if (max_m_) {
            m_ = _getM();
        } else {
            m_ = calcM(block.timestamp);
        }

        return
            int256(
                (m_ * (1 ether - tentative_short_token_ratio_)) /
                    tentative_short_token_ratio_
            ) - 1 ether;
    }

    function longTokenAdjustmentFactor(
        int256 pct_price_change_,
        uint256 short_token_ratio_,
        uint256 m_,
        uint256 x_
    ) internal view override returns (uint256) {
        if (short_token_ratio_ == 0 || short_token_ratio_ == 1 ether) {
            return 1 ether;
        }
        return (1 ether -
            m_ +
            (x_ * short_token_ratio_) /
            (1 ether - short_token_ratio_));
    }

    function shortTokenAdjustmentFactor(
        int256 pct_price_change_,
        uint256 short_token_ratio_,
        uint256 m_,
        uint256 x_
    ) internal view override returns (uint256) {
        if (short_token_ratio_ == 0 || short_token_ratio_ == 1 ether) {
            return 1 ether;
        }
        return (1 ether -
            x_ +
            (m_ * (1 ether - short_token_ratio_)) /
            short_token_ratio_);
    }

    function calcM(uint256 timestamp_)
        internal
        view
        override
        returns (uint256 m_)
    {
        m_ = (_getM() * (timestamp_ - prevSettlementTime())) / (3600);
        console.log(
            "Settlement time - ",
            timestamp_,
            "Prev settlement time - ",
            prevSettlementTime()
        );
        console.log("m - ", m_);
    }

    function calcX(
        int256 pct_price_change_,
        uint256 short_token_ratio_,
        uint256 m_
    ) internal view override returns (uint256 x_) {
        if (optType() == -1) {
            if (pct_price_change_ >= 0) x_ = 0;
            else {
                x_ = uint256(pct_price_change_ * (-1));

                if (x_ > 1 ether) {
                    console.log("value of X is ", x_);
                    x_ = 1 ether;
                }
            }
        } else if (optType() == 1) {
            if (pct_price_change_ <= 0) x_ = 0;
            else {
                x_ = uint256(pct_price_change_);

                if (x_ > 1 ether) {
                    console.log("value of X is ", x_);
                    x_ = 1 ether;
                }
            }
        }
    }

    function getUSDCValue() public view override returns (uint256) {
        return USDCAccountManager(_usdc_account_manager).totalBalance();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Utils/RoleManager.sol";
import "../Tokens/LongToken.sol";
import "../Tokens/ShortToken.sol";
import "../Tokens/ProxyUSDC.sol";

import "../Utils/USDCAccountManager.sol";

import "hardhat/console.sol";

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev User interface related functions. Buy, sell, switch and cancellation of all of the above.

/* 
TODO 
1) Add functions for complete withdrawals of both, include in cancel functions too
2) Add functions for complete switch of both, include in cancel functions too
*/

abstract contract UserInterface is RoleManager {
    // Events
    event BuyLongTokenDone(
        address indexed buyer_address_,
        uint256 buy_amount_usdc_
    );
    event BuyShortTokenDone(
        address indexed buyer_address_,
        uint256 buy_amount_usdc_
    );
    event SellLongTokenDone(
        address indexed seller_address_,
        uint256 sell_amount_token_
    );
    event SellShortTokenDone(
        address indexed seller_address_,
        uint256 sell_amount_token_
    );
    event SwitchFromLongToShortDone(
        address indexed switcher_address_,
        uint256 switch_amount_token_
    );
    event SwitchFromShortToLongDone(
        address indexed switcher_address_,
        uint256 switch_amount_token_
    );
    event CancelBuyLongTokenDone(address indexed buyer_address_);
    event CancelBuyShortTokenDone(address indexed buyer_address_);
    event CancelSellLongTokenDone(address indexed seller_address_);
    event CancelSellShortTokenDone(address indexed seller_address_);
    event CancelSwitchFromLongToShortDone(address indexed switcher_address_);
    event CancelSwitchFromShortToLongDone(address indexed switcher_address_);
    event SettlementDone();
    event ResetAllDone();
    event RedemptionDone();

    //buy - usdc amount
    address[] private _long_token_buyers_addresses;
    mapping(address => uint256) private _long_token_buyers_map;
    uint256 private _total_long_token_buy_amount;

    address[] private _short_token_buyers_addresses;
    mapping(address => uint256) private _short_token_buyers_map;
    uint256 private _total_short_token_buy_amount;

    //sell - switch amount
    address[] private _long_token_sellers_addresses;
    mapping(address => uint256) private _long_token_sellers_map;
    uint256 private _total_long_token_sell_amount;

    address[] private _short_token_sellers_addresses;
    mapping(address => uint256) private _short_token_sellers_map;
    uint256 private _total_short_token_sell_amount;

    // address[] private _long_token_full_sellers_addresses;
    // mapping(address => uint256) private  _long_token_full_sellers_map;

    // address[] private _short_token_full_sellers_addresses;
    // mapping(address => uint256) private  _short_token_full_sellers_map;

    //switch from long to short - switch amount
    address[] private _long_to_short_addresses;
    mapping(address => uint256) private _long_to_short_map;
    uint256 private _total_long_to_short_amount;

    //switch from short to long - switch amount
    address[] private _short_to_long_addresses;
    mapping(address => uint256) private _short_to_long_map;
    uint256 private _total_short_to_long_amount;

    int8 private _opt_type;

    uint256 private _prev_settlement_price;
    uint256 private _prev_settlement_time;

    address private _long_token;
    address private _short_token;
    address private _usdc;

    address internal _usdc_account_manager;
    uint256 private _fees;
    address private _fee_collector;

    uint256 private constant _default_px_per_token = 10**15;
    uint256 private _m;

    constructor(
        uint256 m_,
        int8 opt_type_,
        address usdc_account_manager_
    ) RoleManager(2) {
        _m = m_;
        _opt_type = opt_type_;
        _usdc_account_manager = usdc_account_manager_;
        _prev_settlement_time = block.timestamp;
    }

    function optType() public view returns (int8) {
        return _opt_type;
    }

    function riskCheck(address buyer_address_, uint256 buy_amount_usdc_)
        internal
        virtual
        returns (bool);

    function tentativePricePerToken() public view virtual returns (uint256);

    function lastSettlementPricePerToken()
        public
        view
        virtual
        returns (uint256);

    function longTokenPayoff(int256 pct_price_change_, bool max_m_)
        external
        view
        virtual
        returns (int256);

    function longTokenMaxGain(bool max_m_)
        external
        view
        virtual
        returns (int256);

    function longTokenMaxLoss(bool max_m_)
        external
        view
        virtual
        returns (int256);

    function shortTokenPayoff(int256 pct_price_change_, bool max_m_)
        external
        view
        virtual
        returns (int256);

    function shortTokenMaxGain(bool max_m_)
        external
        view
        virtual
        returns (int256);

    function shortTokenMaxLoss(bool max_m_)
        external
        view
        virtual
        returns (int256);

    function calcM(uint256 settlement_time_)
        internal
        view
        virtual
        returns (uint256);

    function calcX(
        int256 pct_price_change_,
        uint256 short_token_ratio_,
        uint256 m_
    ) internal view virtual returns (uint256 x_);

    function longTokenAdjustmentFactor(
        int256 pct_price_change_,
        uint256 short_token_ratio_,
        uint256 m_,
        uint256 x_
    ) internal view virtual returns (uint256);

    function shortTokenAdjustmentFactor(
        int256 pct_price_change_,
        uint256 short_token_ratio_,
        uint256 m_,
        uint256 x_
    ) internal view virtual returns (uint256);

    function getUSDCValue() public view virtual returns (uint256);

    // =============== Admin block =================
    function setLongTokenAddress(address long_token_) public onlyRoleHolder(0) {
        _long_token = long_token_;
    }

    function setShortTokenAddress(address short_token_)
        public
        onlyRoleHolder(0)
    {
        _short_token = short_token_;
    }

    function setUSDCAddress(address usdc_) public onlyRoleHolder(0) {
        _usdc = usdc_;
    }

    function setFeesAmount(uint256 fees_) public onlyRoleHolder(0) {
        _fees = fees_;
    }

    function setFeeCollector(address fee_collector_) public onlyRoleHolder(0) {
        _fee_collector = fee_collector_;
    }

    function setVaultAddress(address vault_) public onlyRoleHolder(0) {
        _usdc_account_manager = vault_;
    }

    // ==============================================

    function _getM() internal view returns (uint256) {
        return _m;
    }

    function longTokenAddress() internal view returns (address) {
        return _long_token;
    }

    function shortTokenAddress() internal view returns (address) {
        return _short_token;
    }

    function longTokenBuyAmount(address long_token_buyer_address_)
        public
        view
        returns (uint256)
    {
        return _long_token_buyers_map[long_token_buyer_address_];
    }

    function shortTokenBuyAmount(address short_token_buyer_address_)
        public
        view
        returns (uint256)
    {
        return _short_token_buyers_map[short_token_buyer_address_];
    }

    function longTokenSellAmount(address long_token_seller_address_)
        external
        view
        returns (uint256)
    {
        return _long_token_sellers_map[long_token_seller_address_];
    }

    function shortTokenSellAmount(address short_token_seller_address_)
        external
        view
        returns (uint256)
    {
        return _short_token_sellers_map[short_token_seller_address_];
    }

    function longToShortSwitchAmount(address long_to_short_address_)
        external
        view
        returns (uint256)
    {
        return _long_to_short_map[long_to_short_address_];
    }

    function shortToLongSwitchAmount(address short_to_long_address_)
        external
        view
        returns (uint256)
    {
        return _short_to_long_map[short_to_long_address_];
    }

    function totalLongTokenSupply() public view returns (uint256) {
        return LongToken(_long_token).totalSupply();
    }

    function totalShortTokenSupply() public view returns (uint256) {
        return ShortToken(_short_token).totalSupply();
    }

    function totalLongTokenBuyAmount() public view returns (uint256) {
        return _total_long_token_buy_amount;
    }

    function totalShortTokenBuyAmount() public view returns (uint256) {
        return _total_short_token_buy_amount;
    }

    function totalLongTokenSellAmount() public view returns (uint256) {
        return _total_long_token_sell_amount;
    }

    function totalShortTokenSellAmount() public view returns (uint256) {
        return _total_short_token_sell_amount;
    }

    function totalLongToShortAmount() public view returns (uint256) {
        return _total_long_to_short_amount;
    }

    function totalShortToLongAmount() public view returns (uint256) {
        return _total_short_to_long_amount;
    }

    function prevSettlementPrice() public view returns (uint256) {
        return _prev_settlement_price;
    }

    function prevSettlementTime() public view returns (uint256) {
        return _prev_settlement_time;
    }

    function defaultPricePerToken() internal pure returns (uint256) {
        return _default_px_per_token;
    }

    function buyLongToken(uint256 buy_amount_usdc_) external {
        require(riskCheck(msg.sender, buy_amount_usdc_), "Risk check failed");

        uint256 bought_amount_ = _long_token_buyers_map[msg.sender];
        require(
            ProxyUSDC(_usdc).balanceOf(msg.sender) >=
                buy_amount_usdc_ +
                    bought_amount_ +
                    _short_token_buyers_map[msg.sender],
            "Not enough balance"
        );

        if (bought_amount_ == 0) {
            _long_token_buyers_addresses.push(msg.sender);
        }

        unchecked {
            bought_amount_ += buy_amount_usdc_;
            _total_long_token_buy_amount += buy_amount_usdc_;
        }

        _long_token_buyers_map[msg.sender] = bought_amount_;
        emit BuyLongTokenDone(msg.sender, buy_amount_usdc_);
    }

    function buyShortToken(uint256 buy_amount_usdc_) external {
        require(riskCheck(msg.sender, buy_amount_usdc_), "Risk check failed");

        uint256 bought_amount_ = _short_token_buyers_map[msg.sender];
        require(
            ProxyUSDC(_usdc).balanceOf(msg.sender) >=
                buy_amount_usdc_ +
                    bought_amount_ +
                    _long_token_buyers_map[msg.sender],
            "Not enough balance"
        );
        if (bought_amount_ == 0) {
            _short_token_buyers_addresses.push(msg.sender);
        }

        unchecked {
            bought_amount_ += buy_amount_usdc_;
            _total_short_token_buy_amount += buy_amount_usdc_;
        }

        _short_token_buyers_map[msg.sender] = bought_amount_;
        emit BuyShortTokenDone(msg.sender, buy_amount_usdc_);
    }

    function cancelLongTokenBuy() external {
        uint256 bought_amount_ = _long_token_buyers_map[msg.sender];
        if (bought_amount_ > 0) {
            unchecked {
                _total_long_token_buy_amount -= bought_amount_;
            }

            _long_token_buyers_map[msg.sender] = 0;
        }
        emit CancelBuyLongTokenDone(msg.sender);
    }

    function cancelShortTokenBuy() external {
        uint256 bought_amount_ = _short_token_buyers_map[msg.sender];
        if (bought_amount_ > 0) {
            unchecked {
                _total_short_token_buy_amount -= bought_amount_;
            }

            _short_token_buyers_map[msg.sender] = 0;
        }
        emit CancelBuyShortTokenDone(msg.sender);
    }

    function sellLongToken(uint256 sell_amount_token_) external {
        uint256 seller_balance_ = LongToken(_long_token).balanceOf(msg.sender);

        uint256 sold_amount_ = _long_token_sellers_map[msg.sender];
        require(
            sell_amount_token_ +
                sold_amount_ +
                _long_to_short_map[msg.sender] <=
                seller_balance_,
            "Not enough tokens to sell"
        );
        if (sold_amount_ == 0) {
            _long_token_sellers_addresses.push(msg.sender);
        }

        unchecked {
            sold_amount_ += sell_amount_token_;
            _total_long_token_sell_amount += sell_amount_token_;
        }

        _long_token_sellers_map[msg.sender] = sold_amount_;
        emit SellLongTokenDone(msg.sender, sell_amount_token_);
    }

    function sellShortToken(uint256 sell_amount_token_) external {
        uint256 seller_balance_ = ShortToken(_short_token).balanceOf(
            msg.sender
        );

        uint256 sold_amount_ = _short_token_sellers_map[msg.sender];
        require(
            sell_amount_token_ +
                sold_amount_ +
                _short_to_long_map[msg.sender] <=
                seller_balance_,
            "Not enough tokens to sell"
        );

        if (sold_amount_ == 0) {
            _short_token_sellers_addresses.push(msg.sender);
        }

        unchecked {
            sold_amount_ += sell_amount_token_;
            _total_short_token_sell_amount += sell_amount_token_;
        }

        _short_token_sellers_map[msg.sender] = sold_amount_;
        emit SellShortTokenDone(msg.sender, sell_amount_token_);
    }

    // function sellAllLongTokens() external {
    //     uint256 sold_amount_ = _long_token_full_sellers_map[msg.sender];
    //     if (sold_amount_ == 0) {
    //         _long_token_full_sellers_addresses.push(msg.sender);
    //     }

    // }

    // function sellAllShortTokens() external {

    // }

    function cancelLongTokenSell() external {
        uint256 sold_amount_ = _long_token_sellers_map[msg.sender];
        if (sold_amount_ > 0) {
            unchecked {
                _total_long_token_sell_amount -= sold_amount_;
            }

            _long_token_sellers_map[msg.sender] = 0;
        }
        emit CancelSellLongTokenDone(msg.sender);
    }

    function cancelShortTokenSell() external {
        uint256 sold_amount_ = _short_token_sellers_map[msg.sender];
        if (sold_amount_ > 0) {
            unchecked {
                _total_short_token_sell_amount -= sold_amount_;
            }

            _short_token_sellers_map[msg.sender] = 0;
        }
        emit CancelSellShortTokenDone(msg.sender);
    }

    // function cancelLongTokenSellAll() external {

    // }

    // function cancelShortTokenSellAll() external {

    // }

    function switchFromLongToShort(uint256 switch_amount_) external {
        uint256 long_balance_ = LongToken(_long_token).balanceOf(msg.sender);

        uint256 switched_amount_ = _long_to_short_map[msg.sender];
        require(
            switch_amount_ +
                switched_amount_ +
                _long_token_sellers_map[msg.sender] <=
                long_balance_,
            "Not enough tokens to switch"
        );
        if (switched_amount_ == 0) {
            _long_to_short_addresses.push(msg.sender);
        }

        unchecked {
            switched_amount_ += switch_amount_;
            _total_long_to_short_amount += switch_amount_;
        }

        _long_to_short_map[msg.sender] = switched_amount_;
        emit SwitchFromLongToShortDone(msg.sender, switch_amount_);
    }

    function switchFromShortToLong(uint256 switch_amount_) external {
        uint256 short_balance_ = ShortToken(_short_token).balanceOf(msg.sender);

        uint256 switched_amount_ = _short_to_long_map[msg.sender];
        require(
            switch_amount_ +
                switched_amount_ +
                _short_token_sellers_map[msg.sender] <=
                short_balance_,
            "Not enough tokens to switch"
        );

        if (switched_amount_ == 0) {
            _short_to_long_addresses.push(msg.sender);
        }

        unchecked {
            switched_amount_ += switch_amount_;
            _total_short_to_long_amount += switch_amount_;
        }

        _short_to_long_map[msg.sender] = switched_amount_;
        emit SwitchFromShortToLongDone(msg.sender, switch_amount_);
    }

    function cancelSwitchFromLongToShort() external {
        uint256 switched_amount_ = _long_to_short_map[msg.sender];
        if (switched_amount_ > 0) {
            unchecked {
                _total_long_to_short_amount -= switched_amount_;
            }

            _long_to_short_map[msg.sender] = 0;
        }
        emit CancelSwitchFromLongToShortDone(msg.sender);
    }

    function cancelSwitchFromShortToLong() external {
        uint256 switched_amount_ = _short_to_long_map[msg.sender];
        if (switched_amount_ > 0) {
            unchecked {
                _total_short_to_long_amount -= switched_amount_;
            }

            _short_to_long_map[msg.sender] = 0;
        }
        emit CancelSwitchFromShortToLongDone(msg.sender);
    }

    function adjustLongTokenHoldings(
        int256 pct_price_change_,
        uint256 short_token_ratio_,
        uint256 m_,
        uint256 x_
    ) internal {
        uint256 adj_factor_ = longTokenAdjustmentFactor(
            pct_price_change_,
            short_token_ratio_,
            m_,
            x_
        );
        LongToken(_long_token).runSettlement(adj_factor_);
    }

    function adjustShortTokenHoldings(
        int256 pct_price_change_,
        uint256 short_token_ratio_,
        uint256 m_,
        uint256 x_
    ) internal {
        uint256 adj_factor_ = shortTokenAdjustmentFactor(
            pct_price_change_,
            short_token_ratio_,
            m_,
            x_
        );
        ShortToken(_short_token).runSettlement(adj_factor_);
    }

    function executeSettlement(uint256 current_price_, uint256 timestamp_)
        external
        onlyRoleHolder(1)
    {
        int256 pct_price_change_;
        if (_prev_settlement_price == 0) {
            pct_price_change_ = 0;
        } else {
            unchecked {
                pct_price_change_ =
                    int256(
                        (current_price_ * 1 ether) / _prev_settlement_price
                    ) -
                    1 ether;
            }
        }

        uint256 long_tokens_ = LongToken(_long_token).totalSupply();
        uint256 short_tokens_ = ShortToken(_short_token).totalSupply();
        uint256 total_tokens_;
        uint256 short_token_ratio_;
        unchecked {
            total_tokens_ = long_tokens_ + short_tokens_;
        }

        if (total_tokens_ > 0) {
            uint256 m_ = calcM(timestamp_);
            uint256 x_ = calcX(pct_price_change_, short_token_ratio_, m_);
            unchecked {
                short_token_ratio_ = (short_tokens_ * 1 ether) / total_tokens_;
            }
            adjustLongTokenHoldings(
                pct_price_change_,
                short_token_ratio_,
                m_,
                x_
            );
            adjustShortTokenHoldings(
                pct_price_change_,
                short_token_ratio_,
                m_,
                x_
            );
        }
        _prev_settlement_price = current_price_;
        _prev_settlement_time = timestamp_;

        long_tokens_ = LongToken(_long_token).totalSupply();
        short_tokens_ = ShortToken(_short_token).totalSupply();

        uint256 total_usdc_value_ = getUSDCValue();
        uint256 price_per_token_ = _default_px_per_token;
        unchecked {
            total_tokens_ = long_tokens_ + short_tokens_;
            if (total_tokens_ > 0)
                price_per_token_ =
                    (total_usdc_value_ * 1 ether) /
                    total_tokens_;
        }

        // infusion
        uint256 max_i_ = _long_token_buyers_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            (
                address long_token_buyer_address_,
                uint256 long_token_buy_amount_usdc_
            ) = _longTokenBuyerReadAndPop();
            if (long_token_buy_amount_usdc_ > 0) {
                // Check balance and approval
                uint256 usr_bal_ = ProxyUSDC(_usdc).balanceOf(
                    long_token_buyer_address_
                );
                uint256 allowance_ = ProxyUSDC(_usdc).allowance(
                    long_token_buyer_address_,
                    address(this)
                );

                if (allowance_ < long_token_buy_amount_usdc_) {
                    console.log(
                        "Due to allowance constraint : Deposit amount changed from ",
                        long_token_buy_amount_usdc_,
                        " to ",
                        allowance_
                    );
                    long_token_buy_amount_usdc_ = allowance_;
                }

                if (usr_bal_ < long_token_buy_amount_usdc_) {
                    console.log(
                        "Due to insufficiant balance : Deposit amount changed from ",
                        long_token_buy_amount_usdc_,
                        " to ",
                        usr_bal_
                    );
                    long_token_buy_amount_usdc_ = usr_bal_;
                }

                uint256 fees_to_deduct_;

                unchecked {
                    fees_to_deduct_ =
                        (long_token_buy_amount_usdc_ * _fees) /
                        (1 ether);
                    long_token_buy_amount_usdc_ -= fees_to_deduct_;
                }

                console.log("Fees ", fees_to_deduct_);
                ProxyUSDC(_usdc).transferFrom(
                    address(long_token_buyer_address_),
                    address(_fee_collector),
                    fees_to_deduct_
                );
                ProxyUSDC(_usdc).transferFrom(
                    address(long_token_buyer_address_),
                    address(this),
                    long_token_buy_amount_usdc_
                );
                USDCAccountManager(_usdc_account_manager).addBalance(
                    long_token_buy_amount_usdc_
                );

                uint256 buy_amount_token_;
                unchecked {
                    buy_amount_token_ =
                        (long_token_buy_amount_usdc_ * 1 ether) /
                        price_per_token_;
                }

                LongToken(_long_token).mint(
                    long_token_buyer_address_,
                    buy_amount_token_
                );
            }

            unchecked {
                --i;
            }
        }

        max_i_ = _short_token_buyers_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            (
                address short_token_buyer_address_,
                uint256 short_token_buy_amount_usdc_
            ) = _shortTokenBuyerReadAndPop();
            if (short_token_buy_amount_usdc_ > 0) {
                uint256 usr_bal_ = ProxyUSDC(_usdc).balanceOf(
                    short_token_buyer_address_
                );
                uint256 allowance_ = ProxyUSDC(_usdc).allowance(
                    short_token_buyer_address_,
                    address(this)
                );

                if (allowance_ < short_token_buy_amount_usdc_) {
                    console.log(
                        "Due to allowance constraint : Deposit amount changed from ",
                        short_token_buy_amount_usdc_,
                        " to ",
                        allowance_
                    );
                    short_token_buy_amount_usdc_ = allowance_;
                }

                if (usr_bal_ < short_token_buy_amount_usdc_) {
                    console.log(
                        "Due to insufficiant balance : Deposit amount changed from ",
                        short_token_buy_amount_usdc_,
                        " to ",
                        usr_bal_
                    );
                    short_token_buy_amount_usdc_ = usr_bal_;
                }

                uint256 fees_to_deduct_;

                unchecked {
                    fees_to_deduct_ =
                        (short_token_buy_amount_usdc_ * _fees) /
                        (1 ether);
                    short_token_buy_amount_usdc_ -= fees_to_deduct_;
                }

                console.log("Fees ", fees_to_deduct_);
                ProxyUSDC(_usdc).transferFrom(
                    address(short_token_buyer_address_),
                    address(_fee_collector),
                    fees_to_deduct_
                );
                ProxyUSDC(_usdc).transferFrom(
                    address(short_token_buyer_address_),
                    address(this),
                    short_token_buy_amount_usdc_
                );
                USDCAccountManager(_usdc_account_manager).addBalance(
                    short_token_buy_amount_usdc_
                );

                uint256 buy_amount_token_;
                unchecked {
                    buy_amount_token_ =
                        (short_token_buy_amount_usdc_ * 1 ether) /
                        price_per_token_;
                }

                ShortToken(_short_token).mint(
                    short_token_buyer_address_,
                    buy_amount_token_
                );
            }

            unchecked {
                --i;
            }
        }

        // withdrawal
        max_i_ = _long_token_sellers_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            (
                address long_token_seller_address_,
                uint256 long_token_sell_amount_tokens_
            ) = _longTokenSellerReadAndPop();
            if (long_token_sell_amount_tokens_ > 0) {
                uint256 usr_bal_ = LongToken(_long_token).balanceOf(
                    long_token_seller_address_
                );
                if (usr_bal_ < long_token_sell_amount_tokens_) {
                    console.log(
                        "Due to insufficiant balance : Withdrawal balance changes from ",
                        long_token_sell_amount_tokens_,
                        " to ",
                        usr_bal_
                    );
                    long_token_sell_amount_tokens_ = usr_bal_;
                }

                LongToken(_long_token).burn(
                    long_token_seller_address_,
                    long_token_sell_amount_tokens_
                );

                uint256 settlement_amount_;
                uint256 fees_to_deduct_;
                unchecked {
                    settlement_amount_ =
                        (long_token_sell_amount_tokens_ * price_per_token_) /
                        (1 ether);
                    fees_to_deduct_ = (settlement_amount_ * _fees) / (1 ether);
                }

                USDCAccountManager(_usdc_account_manager).withdrawBalance(
                    settlement_amount_
                );
                unchecked {
                    settlement_amount_ -= fees_to_deduct_;
                }

                console.log("Fees ", fees_to_deduct_);
                ProxyUSDC(_usdc).transfer(
                    address(_fee_collector),
                    fees_to_deduct_
                );
                ProxyUSDC(_usdc).transfer(
                    address(long_token_seller_address_),
                    settlement_amount_
                );
            }

            unchecked {
                --i;
            }
        }

        max_i_ = _short_token_sellers_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            (
                address short_token_seller_address_,
                uint256 short_token_sell_amount_tokens_
            ) = _shortTokenSellerReadAndPop();
            if (short_token_sell_amount_tokens_ > 0) {
                uint256 usr_bal_ = ShortToken(_short_token).balanceOf(
                    short_token_seller_address_
                );
                if (usr_bal_ < short_token_sell_amount_tokens_) {
                    console.log(
                        "Due to insufficiant balance : Withdrawal balance changes from ",
                        short_token_sell_amount_tokens_,
                        " to ",
                        usr_bal_
                    );
                    short_token_sell_amount_tokens_ = usr_bal_;
                }

                ShortToken(_short_token).burn(
                    short_token_seller_address_,
                    short_token_sell_amount_tokens_
                );

                uint256 settlement_amount_;
                uint256 fees_to_deduct_;
                unchecked {
                    settlement_amount_ =
                        (short_token_sell_amount_tokens_ * price_per_token_) /
                        (1 ether);
                    fees_to_deduct_ = (settlement_amount_ * _fees) / (1 ether);
                }

                USDCAccountManager(_usdc_account_manager).withdrawBalance(
                    settlement_amount_
                );
                unchecked {
                    settlement_amount_ -= fees_to_deduct_;
                }

                console.log("Fees ", fees_to_deduct_);
                ProxyUSDC(_usdc).transfer(
                    address(_fee_collector),
                    fees_to_deduct_
                );
                ProxyUSDC(_usdc).transfer(
                    address(short_token_seller_address_),
                    settlement_amount_
                );
            }

            unchecked {
                --i;
            }
        }

        // switch
        max_i_ = _long_to_short_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            (
                address long_to_short_address_,
                uint256 long_to_short_amount_tokens_
            ) = _longToShortReadAndPop();
            if (long_to_short_amount_tokens_ > 0) {
                uint256 usr_bal_ = LongToken(_long_token).balanceOf(
                    long_to_short_address_
                );
                if (usr_bal_ < long_to_short_amount_tokens_) {
                    console.log(
                        "Due to insufficiant balance : Withdrawal balance changes from ",
                        long_to_short_amount_tokens_,
                        " to ",
                        usr_bal_
                    );
                    long_to_short_amount_tokens_ = usr_bal_;
                }

                LongToken(_long_token).burn(
                    long_to_short_address_,
                    long_to_short_amount_tokens_
                );
                ShortToken(_short_token).mint(
                    long_to_short_address_,
                    long_to_short_amount_tokens_
                );
            }

            unchecked {
                --i;
            }
        }

        max_i_ = _short_to_long_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            (
                address short_to_long_address_,
                uint256 short_to_long_amount_tokens_
            ) = _shortToLongReadAndPop();
            if (short_to_long_amount_tokens_ > 0) {
                uint256 usr_bal_ = ShortToken(_short_token).balanceOf(
                    short_to_long_address_
                );
                if (usr_bal_ < short_to_long_amount_tokens_) {
                    console.log(
                        "Due to insufficiant balance : Withdrawal balance changes from ",
                        short_to_long_amount_tokens_,
                        " to ",
                        usr_bal_
                    );
                    short_to_long_amount_tokens_ = usr_bal_;
                }

                ShortToken(_long_token).burn(
                    short_to_long_address_,
                    short_to_long_amount_tokens_
                );
                LongToken(_short_token).mint(
                    short_to_long_address_,
                    short_to_long_amount_tokens_
                );
            }

            unchecked {
                --i;
            }
        }
        emit SettlementDone();
    }

    function _longTokenBuyerReadAndPop()
        private
        returns (address last_address_, uint256 amount_)
    {
        last_address_ = _long_token_buyers_addresses[
            _long_token_buyers_addresses.length - 1
        ];
        uint256 deposit_value_ = _long_token_buyers_map[last_address_];

        unchecked {
            _total_long_token_buy_amount -= deposit_value_;
        }

        delete _long_token_buyers_map[last_address_];
        _long_token_buyers_addresses.pop();
        return (last_address_, deposit_value_);
    }

    function _shortTokenBuyerReadAndPop()
        private
        returns (address last_address_, uint256 amount_)
    {
        last_address_ = _short_token_buyers_addresses[
            _short_token_buyers_addresses.length - 1
        ];
        uint256 deposit_value_ = _short_token_buyers_map[last_address_];

        unchecked {
            _total_short_token_buy_amount -= deposit_value_;
        }

        delete _short_token_buyers_map[last_address_];
        _short_token_buyers_addresses.pop();
        return (last_address_, deposit_value_);
    }

    function _longTokenSellerReadAndPop()
        private
        returns (address last_address_, uint256 amount_)
    {
        last_address_ = _long_token_sellers_addresses[
            _long_token_sellers_addresses.length - 1
        ];
        uint256 deposit_value_ = _long_token_sellers_map[last_address_];

        unchecked {
            _total_long_token_sell_amount -= deposit_value_;
        }

        delete _long_token_sellers_map[last_address_];
        _long_token_sellers_addresses.pop();
        return (last_address_, deposit_value_);
    }

    function _shortTokenSellerReadAndPop()
        private
        returns (address last_address_, uint256 amount_)
    {
        last_address_ = _short_token_sellers_addresses[
            _short_token_sellers_addresses.length - 1
        ];
        uint256 deposit_value_ = _short_token_sellers_map[last_address_];

        unchecked {
            _total_short_token_sell_amount -= deposit_value_;
        }

        delete _short_token_sellers_map[last_address_];
        _short_token_sellers_addresses.pop();
        return (last_address_, deposit_value_);
    }

    function _longToShortReadAndPop()
        private
        returns (address last_address_, uint256 amount_)
    {
        last_address_ = _long_to_short_addresses[
            _long_to_short_addresses.length - 1
        ];
        uint256 deposit_value_ = _long_to_short_map[last_address_];

        unchecked {
            _total_long_to_short_amount -= deposit_value_;
        }

        delete _long_to_short_map[last_address_];
        _long_to_short_addresses.pop();
        return (last_address_, deposit_value_);
    }

    function _shortToLongReadAndPop()
        private
        returns (address last_address_, uint256 amount_)
    {
        last_address_ = _short_to_long_addresses[
            _short_to_long_addresses.length - 1
        ];
        uint256 deposit_value_ = _short_to_long_map[last_address_];

        unchecked {
            _total_short_to_long_amount -= deposit_value_;
        }

        delete _short_to_long_map[last_address_];
        _short_to_long_addresses.pop();
        return (last_address_, deposit_value_);
    }

    function resetAll(bool redeem_) public onlyRoleHolder(0) {
        uint256 max_i_ = _long_token_buyers_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            _longTokenBuyerReadAndPop();
            unchecked {
                --i;
            }
        }

        max_i_ = _short_token_buyers_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            _shortTokenBuyerReadAndPop();
            unchecked {
                --i;
            }
        }

        max_i_ = _long_token_sellers_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            _longTokenSellerReadAndPop();
            unchecked {
                --i;
            }
        }

        max_i_ = _short_token_sellers_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            _shortTokenSellerReadAndPop();
            unchecked {
                --i;
            }
        }

        max_i_ = _long_to_short_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            _longToShortReadAndPop();
            unchecked {
                --i;
            }
        }

        max_i_ = _short_to_long_addresses.length;
        for (uint256 i = max_i_; i > 0; ) {
            _shortToLongReadAndPop();
            unchecked {
                --i;
            }
        }

        emit ResetAllDone();

        if (redeem_) {
            uint256 long_tokens_ = LongToken(_long_token).totalSupply();
            uint256 short_tokens_ = ShortToken(_short_token).totalSupply();
            uint256 total_usdc_value_ = getUSDCValue();
            uint256 price_per_token_ = _default_px_per_token;
            uint256 total_tokens_;
            unchecked {
                total_tokens_ = long_tokens_ + short_tokens_;
                if (total_tokens_ > 0)
                    price_per_token_ =
                        (total_usdc_value_ * 1 ether) /
                        total_tokens_;
            }

            max_i_ = (LongToken(_long_token).allHolderAddresses()).length;
            for (uint256 i = max_i_; i > 0; ) {
                (
                    address long_token_seller_address_,
                    uint256 long_token_sell_amount_tokens_
                ) = LongToken(_long_token).fetchLastHolderAndPop();

                if (long_token_sell_amount_tokens_ > 0) {
                    uint256 settlement_amount_;
                    uint256 fees_to_deduct_;
                    unchecked {
                        settlement_amount_ =
                            (long_token_sell_amount_tokens_ *
                                price_per_token_) /
                            (1 ether);
                        fees_to_deduct_ =
                            (settlement_amount_ * _fees) /
                            (1 ether);
                    }

                    USDCAccountManager(_usdc_account_manager).withdrawBalance(
                        settlement_amount_
                    );
                    unchecked {
                        settlement_amount_ -= fees_to_deduct_;
                    }

                    ProxyUSDC(_usdc).transfer(
                        address(_fee_collector),
                        fees_to_deduct_
                    );
                    ProxyUSDC(_usdc).transfer(
                        address(long_token_seller_address_),
                        settlement_amount_
                    );
                }

                unchecked {
                    --i;
                }
            }

            max_i_ = (ShortToken(_short_token).allHolderAddresses()).length;
            for (uint256 i = max_i_; i > 0; ) {
                (
                    address short_token_seller_address_,
                    uint256 short_token_sell_amount_tokens_
                ) = ShortToken(_short_token).fetchLastHolderAndPop();

                if (short_token_sell_amount_tokens_ > 0) {
                    uint256 settlement_amount_;
                    uint256 fees_to_deduct_;
                    unchecked {
                        settlement_amount_ =
                            (short_token_sell_amount_tokens_ *
                                price_per_token_) /
                            (1 ether);
                        fees_to_deduct_ =
                            (settlement_amount_ * _fees) /
                            (1 ether);
                    }

                    USDCAccountManager(_usdc_account_manager).withdrawBalance(
                        settlement_amount_
                    );
                    unchecked {
                        settlement_amount_ -= fees_to_deduct_;
                    }

                    ProxyUSDC(_usdc).transfer(
                        address(_fee_collector),
                        fees_to_deduct_
                    );
                    ProxyUSDC(_usdc).transfer(
                        address(short_token_seller_address_),
                        settlement_amount_
                    );
                }

                unchecked {
                    --i;
                }
            }
            emit RedemptionDone();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Rinkeby
     * Aggregator: ETH/USD
     * Address vKOvan: 0x9326BFA02ADD2366b30bacB125260Af641031331
     * Address Rinkeby : 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
     * Params 1h, 1% 8Dec
     */
    constructor(address price_oracle_address_) {
        priceFeed = AggregatorV3Interface(price_oracle_address_);
    }

    /**
     * Returns the latest price
     */
    function getLatestRoundData()
        public
        view
        returns (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        )
    {
        (roundID, price, startedAt, timeStamp, answeredInRound) = priceFeed
            .latestRoundData();
        return (roundID, price, startedAt, timeStamp, answeredInRound);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./ChainlinkConsumer.sol";
import "../../UserInteraction/UI2.sol";

contract Keeper is KeeperCompatibleInterface, Ownable {
    /**
     * Public counter variable
     */
    uint256 public counter;

    /**
     * Use an _update_interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint256 public _update_interval;
    bool private _settle_every_block;
    uint256 public last_time_stamp;
    PriceConsumerV3 private _consumer;
    UI2 private _user_interface;

    uint256 private _last_settlement_px;
    uint256 private _last_settlement_time;

    address private _keeper;

    constructor(
        uint256 update_interval_,
        bool every_settlement,
        address user_interface_address_,
        address price_oracle_address_
    ) {
        _update_interval = update_interval_;
        last_time_stamp = block.timestamp;

        counter = 0;

        _consumer = new PriceConsumerV3(price_oracle_address_);
        _user_interface = UI2(user_interface_address_);
        _settle_every_block = every_settlement;
    }

    modifier onlyKeeper() {
        require(msg.sender == _keeper, "Only keeper can perform this task");
        _;
    }

    function setKeeper(address keeper_) public onlyOwner {
        _keeper = keeper_;
    }

    function setInterval(uint256 interval_) public onlyOwner {
        _update_interval = interval_;
    }

    function setEverySettlement(bool settle_every_block_) public onlyOwner {
        _settle_every_block = settle_every_block_;
    }

    function getLastSettlementPrice() public view returns (uint256) {
        return _last_settlement_px;
    }

    function getLastSettlementTime() public view returns (uint256) {
        return _last_settlement_time;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeep_needed_,
            bytes memory /* performData */
        )
    {
        upkeep_needed_ = (block.timestamp - last_time_stamp) > _update_interval;
    }

    function latestRoundPrice() external view returns (uint256) {
        (, int256 last_round_px_, , , ) = _consumer.getLatestRoundData();
        return uint256(last_round_px_);
    }

    function latestRoundTime() external view returns (uint256) {
        (, , , uint256 last_round_time_, ) = _consumer.getLatestRoundData();
        return last_round_time_;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override onlyKeeper {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - last_time_stamp) > _update_interval) {
            last_time_stamp = block.timestamp;
            counter = counter + 1;
            (, int256 last_round_px_, , uint256 last_round_time_, ) = _consumer
                .getLatestRoundData();
            _last_settlement_px = uint256(last_round_px_);

            // Ensuring that settlement happens only after the round happens
            if (
                _settle_every_block || last_round_time_ > _last_settlement_time
            ) {
                _last_settlement_time = _settle_every_block
                    ? block.timestamp
                    : last_round_time_;
                console.log(
                    "Price recorded - ",
                    _last_settlement_px,
                    " at ",
                    _last_settlement_time
                );
                _user_interface.executeSettlement(
                    uint256(_last_settlement_px),
                    _last_settlement_time
                );
            }
        }
    }

    // function upkeepAction(uint256 px_, uint256 time_) public onlyOwner {
    //     _user_interface.pxInput(px_, time_);
    // }

    function upkeepAction(uint256 px_) public onlyOwner {
        _last_settlement_time = block.timestamp;
        _last_settlement_px = px_;
        _user_interface.executeSettlement(px_, block.timestamp);
    }

    // function addNoRiskcheckAccount(address address_) public onlyOwner {
    //     _user_interface.addNoRiskcheckAccount(address_);
    // }

    // function resetAll() public onlyOwner {
    //     _user_interface.resetAll();
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "hardhat/console.sol";

abstract contract RoleManager {
    mapping(uint256 => address) private _role_map;

    event RoleTransferred(
        uint256 role,
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(uint256 roles_length_) {
        assert(roles_length_ > 0);
        uint256 i = roles_length_;
        for (; i > 0; ) {
            _transferRole(i - 1, msg.sender);
            console.log("transferred role", i - 1);
            unchecked {
                --i;
            }
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function roleHolder(uint256 role_) public view virtual returns (address) {
        return _role_map[role_];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyRoleHolder(uint256 role_) {
        require(
            roleHolder(role_) == msg.sender,
            "RoleManager: caller doesn't have access"
        );
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceRole(uint256 role_) public virtual onlyRoleHolder(role_) {
        _transferRole(role_, address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferRole(uint256 role_, address newOwner)
        public
        virtual
        onlyRoleHolder(role_)
    {
        require(
            newOwner != address(0),
            "RoleManager: new owner cannot be address(0)"
        );
        _transferRole(role_, newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferRole(uint256 role_, address newOwner) internal virtual {
        address oldOwner = roleHolder(role_);
        _role_map[role_] = newOwner;
        emit RoleTransferred(role_, oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract USDCAccountManager is Ownable {
    constructor() {}

    event BalanceAdded(uint256 deposit_amount_);
    event BalanceWithdrawn(uint256 withdraw_amount_);

    uint256 private _total_balance;

    function totalBalance() public view returns (uint256) {
        return _total_balance;
    }

    // function addBalance(uint256 deposit_amount_) public {
    function addBalance(uint256 deposit_amount_) public onlyOwner {
        unchecked {
            _total_balance += deposit_amount_;  
        }
        emit BalanceAdded(deposit_amount_);
    }

    // function withdrawBalance(uint256 withdraw_amount_) public {
    function withdrawBalance(uint256 withdraw_amount_) public onlyOwner {
        unchecked {
            _total_balance -= withdraw_amount_;
        }
        emit BalanceWithdrawn(withdraw_amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}