// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IAgent.sol";
import "./interfaces/ICharity.sol";

contract GreenWorld is ERC20, Ownable {
    IFactory public immutable factory;
    IAgent public immutable agent;
    ICharity public charity;
    address public immutable ecosystem;
    address public staking;

    uint256 public liquidityFeeSell;
    uint256 public charityFeeSell;
    uint256 public stakingRewardFeeSell;
    uint256 public ecosystemFeeSell;

    uint256 public liquidityFeeBuy;
    uint256 public charityFeeBuy;
    uint256 public stakingRewardFeeBuy;
    uint256 public ecosystemFeeBuy;

    uint256 private constant PERCENT = 1000;

    mapping(address => bool) public isExcludedFromFee;

    struct FeesAmount {
        uint256 liquidity;
        uint256 charity;
        uint256 ecosystem;
        uint256 stakingReward;
    }

    constructor(
        address[] memory addresses,
        uint256[] memory amounts,
        uint256[] memory feesSell,
        uint256[] memory feesBuy,
        IFactory _factory,
        IAgent _agent
    ) ERC20("GreenWorld", "GWD") {
        require(addresses.length == amounts.length, "Wrong inputs");
        for (uint256 i = 0; i < amounts.length; i++) {
            _mint(addresses[i], amounts[i] * 10**decimals());
        }

        liquidityFeeSell = feesSell[0];
        charityFeeSell = feesSell[1];
        stakingRewardFeeSell = feesSell[2];
        ecosystemFeeSell = feesSell[3];

        liquidityFeeBuy = feesBuy[0];
        charityFeeBuy = feesBuy[1];
        stakingRewardFeeBuy = feesBuy[2];
        ecosystemFeeBuy = feesBuy[3];

        factory = _factory;
        agent = _agent;
        ecosystem = addresses[6];
        isExcludedFromFee[address(agent)] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /** @dev Change isExcludedFromFee status
     *  @param _account an address of account to change
     */
    function changeExcludedFromFee(address _account) external onlyOwner {
        isExcludedFromFee[_account] = !isExcludedFromFee[_account];
    }

    /**
     @dev Change liquidity sell and buy fee. Onle for owner
     @param buy new liquidityFeeBuy. Enter as x * 10
     @param sell new liquidityFeeSell. Enter as x * 10 
     */
    function changeLiquidityFee(uint256 buy, uint256 sell) external onlyOwner {
        require(
            buy + charityFeeBuy + ecosystemFeeBuy + stakingRewardFeeBuy <=
                PERCENT &&
                sell +
                    charityFeeSell +
                    ecosystemFeeSell +
                    stakingRewardFeeSell <=
                PERCENT,
            "Fees > 100%!"
        );
        liquidityFeeBuy = buy;
        liquidityFeeSell = sell;
    }

    /**
     @dev Change charity sell and buy fee. Onle for owner
     @param buy new charityFeeBuy. Enter as x * 10
     @param sell new charityFeeSell. Enter as x * 10 
     */
    function changeCharityFee(uint256 buy, uint256 sell) external onlyOwner {
        require(
            buy + liquidityFeeBuy + ecosystemFeeBuy + stakingRewardFeeBuy <=
                PERCENT &&
                sell +
                    liquidityFeeSell +
                    ecosystemFeeSell +
                    stakingRewardFeeSell <=
                PERCENT,
            "Fees > 100%!"
        );
        charityFeeBuy = buy;
        charityFeeSell = sell;
    }

    /**
     @dev Change ecosystem sell and buy fee. Onle for owner
     @param buy new ecosystemFeeBuy. Enter as x * 10
     @param sell new ecosystemFeeSell. Enter as x * 10 
     */
    function changeEcosystemFee(uint256 buy, uint256 sell) external onlyOwner {
        require(
            buy + charityFeeBuy + liquidityFeeBuy + stakingRewardFeeBuy <=
                PERCENT &&
                sell +
                    charityFeeSell +
                    liquidityFeeSell +
                    stakingRewardFeeSell <=
                PERCENT,
            "Fees > 100%!"
        );
        ecosystemFeeBuy = buy;
        ecosystemFeeSell = sell;
    }

    /**
     @dev Change staking reward sell and buy fee. Onle for owner
     @param buy new stakingRewardFeeBuy. Enter as x * 10
     @param sell new stakingRewardFeeSell. Enter as x * 10 
     */
    function changeStakingRewardFee(uint256 buy, uint256 sell)
        external
        onlyOwner
    {
        require(
            buy + charityFeeBuy + ecosystemFeeBuy + liquidityFeeBuy <=
                PERCENT &&
                sell + charityFeeSell + ecosystemFeeSell + liquidityFeeSell <=
                PERCENT,
            "Fees > 100%!"
        );
        stakingRewardFeeBuy = buy;
        stakingRewardFeeSell = sell;
    }

    /**
     @dev Sets staking address for sending reward. Only for owner
     @param _staking staking address
     */
    function setStaking(address _staking) external onlyOwner {
        staking = _staking;
    }

    /**
     @dev Sets charity address for sending fee. Only for owner
     @param _charity charity address
     */
    function setCharity(ICharity _charity) external onlyOwner {
        charity = _charity;
        isExcludedFromFee[address(_charity)] = true;
    }

    /**
     @dev Overrided ERC20 transfer. If msg.sender address = pair => buy.
     If buy and 'to' address is not excluded from fee => takes fee
     */
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address _owner = _msgSender();
        bool isPair = _pairCheck(_owner);
        if (isPair && !isExcludedFromFee[to]) {
            FeesAmount memory fees;
            if (liquidityFeeBuy > 0) {
                fees.liquidity = (amount * liquidityFeeBuy) / PERCENT;
                _transfer(_owner, address(agent), fees.liquidity);
                agent.increaseStock(fees.liquidity);
            }
            if (charityFeeBuy > 0 && address(charity) != address(0)) {
                fees.charity = (amount * charityFeeBuy) / PERCENT;
                _transfer(_owner, address(charity), fees.charity);
                charity.addToCharity(fees.charity, to);
            }
            if (ecosystemFeeBuy > 0) {
                fees.ecosystem = (amount * ecosystemFeeBuy) / PERCENT;
                _transfer(_owner, ecosystem, fees.ecosystem);
            }
            if (stakingRewardFeeBuy > 0 && staking != address(0)) {
                fees.stakingReward = (amount * stakingRewardFeeBuy) / PERCENT;
                _transfer(_owner, staking, fees.stakingReward);
            }
            uint256 amountWithFee = amount -
                fees.liquidity -
                fees.charity -
                fees.ecosystem -
                fees.stakingReward;
            _transfer(_owner, to, amountWithFee);
        } else {
            _transfer(_owner, to, amount);
            if (!isPair) {
                charity.swapNow();
                if (
                    (agent.getStock() > agent.getThreshold()) &&
                    (_owner != address(agent))
                ) {
                    agent.autoLiquidity();
                }
            }
        }
        return true;
    }

    /**
     @dev Overrided ERC20 transferFrom. If 'to' address = pair => sell.
     If sell and 'from' address is not excluded from fee => takes fee
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        bool isPair = _pairCheck(to);
        if (isPair && !isExcludedFromFee[from]) {
            FeesAmount memory fees;
            if (liquidityFeeSell > 0) {
                fees.liquidity = (amount * liquidityFeeSell) / PERCENT;
                _transfer(from, address(agent), fees.liquidity);
                agent.increaseStock(fees.liquidity);
            }
            if (charityFeeSell > 0 && address(charity) != address(0)) {
                fees.charity = (amount * charityFeeSell) / PERCENT;
                _transfer(from, address(charity), fees.charity);
                charity.addToCharity(fees.charity, from);
            }
            if (ecosystemFeeSell > 0) {
                fees.ecosystem = (amount * ecosystemFeeSell) / PERCENT;
                _transfer(from, ecosystem, fees.ecosystem);
            }
            if (stakingRewardFeeSell > 0 && staking != address(0)) {
                fees.stakingReward = (amount * stakingRewardFeeSell) / PERCENT;
                _transfer(from, staking, fees.stakingReward);
            }
            uint256 amountWithFee = amount -
                fees.liquidity -
                fees.charity -
                fees.ecosystem -
                fees.stakingReward;
            _transfer(from, to, amountWithFee);
        } else {
            _transfer(from, to, amount);
            if (!isPair) {
                charity.swapNow();
                if (
                    (agent.getStock() > agent.getThreshold()) &&
                    (from != address(agent))
                ) {
                    agent.autoLiquidity();
                }
            }
        }
        return true;
    }

    function _pairCheck(address _token) internal view returns (bool) {
        address token0;
        address token1;

        if (isContract(_token)) {
            try IPair(_token).token0() returns (address _token0) {
                token0 = _token0;
            } catch {
                return false;
            }

            try IPair(_token).token1() returns (address _token1) {
                token1 = _token1;
            } catch {
                return false;
            }

            address goodPair = factory.getPair(token0, token1);
            if (goodPair != _token) {
                return false;
            }

            if (token0 == address(this) || token1 == address(this)) return true;
            else return false;
        } else return false;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAgent {
    function increaseStock(uint256 amount) external;

    function autoLiquidity() external;

    function getStock() external view returns (uint256);

    function getThreshold() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPair {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICharity {
    function addToCharity(uint256 amount, address user) external; 

    function swapNow() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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