// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

/**
 * @title FungiblePolicy
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance fungible insurance for buyer
 **/
import "../libs/InsureDAOERC20.sol";
import "../interfaces/IMarket.sol";
import "../interfaces/IFungiblePolicy.sol";

contract FungiblePolicy is InsureDAOERC20, IFungiblePolicy {
    /**
     * Storage
     */
    /// @notice variables like immutables
    bool public initialized;
    uint48 public override endTime;
    IMarket public market;
    uint256 public insuranceId;

    /**
     * Initialize interaction
     */
    constructor() {
        initialized = true;
    }

    /// @notice inherit IFungibleInitializer
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256[] calldata _params,
        address[] calldata _references
    ) external override {
        uint8 _decimals = 6;
        initializeToken(_name, _symbol, _decimals);
        endTime = uint48(_params[0]);
        market = IMarket(_references[0]);
        initialized = true;
    }

    /**
     * Core interaction
     */

    /// @notice inherit IFungiblePolicy
    function insure(uint256 _amount) external override {
        if (totalSupply() == 0) {
            uint256 _span = endTime - block.timestamp;
            insuranceId = market.insureDelegate(_amount, _span, msg.sender);
        } else {
            market.increaseInsuranceDelegate(insuranceId, _amount, msg.sender);
        }
        _mint(msg.sender, _amount);
    }

    /// @notice inherit IFungiblePolicy
    function redeem(uint256 _amount, address _redeemToken) external override {
        if (_amount > balanceOf(msg.sender)) revert RequestExceedBalance();
        if (_amount == 0) revert AmountZero();
        _burn(msg.sender, _amount);
        market.redeemByTokenDelegate(insuranceId, _amount, msg.sender, _redeemToken);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
/**
 * @title InsureDAOERC20
 * @author @InsureDAO
 * @notice InsureDAO's Depeg insurance InsureDAO's ERC20 token
 **/
contract InsureDAOERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    bool tokenInitialized;
    string private _name = "InsureDAO LP Token";
    string private _symbol = "iLP";
    uint8 private _decimals = 18;

    function initializeToken(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) internal {
        /***
         *@notice initialize token. Only called internally.
         *
         */
        require(!tokenInitialized, "Token is already initialized");
        tokenInitialized = true;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual override returns (string memory) {
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
    function decimals() external view virtual override returns (uint8) {
        return _decimals;
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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        external
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
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
    ) external virtual override returns (bool) {
        if (amount != 0) {
            uint256 currentAllowance = _allowances[sender][msg.sender];
            if (currentAllowance != type(uint256).max) {
                require(
                    currentAllowance >= amount,
                    "Transfer amount > allowance"
                );
                unchecked {
                    _approve(sender, msg.sender, currentAllowance - amount);
                }
            }

            _transfer(sender, recipient, amount);
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
    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        if (addedValue != 0) {
            _approve(
                msg.sender,
                spender,
                _allowances[msg.sender][spender] + addedValue
            );
        }
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        if (subtractedValue != 0) {
            uint256 currentAllowance = _allowances[msg.sender][spender];
            require(
                currentAllowance >= subtractedValue,
                "Decreased allowance below zero"
            );

            _approve(msg.sender, spender, currentAllowance - subtractedValue);
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
        if (amount != 0) {
            require(sender != address(0), "Transfer from the zero address");
            require(recipient != address(0), "Transfer to the zero address");

            _beforeTokenTransfer(sender, recipient, amount);

            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "Transfer amount exceeds balance");

            unchecked {
                _balances[sender] = senderBalance - amount;
            }

            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);

            _afterTokenTransfer(sender, recipient, amount);
        }
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
        if (amount != 0) {
            require(account != address(0), "Mint to the zero address");

            _beforeTokenTransfer(address(0), account, amount);

            _totalSupply += amount;
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);

            _afterTokenTransfer(address(0), account, amount);
        }
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
        if (amount != 0) {
            require(account != address(0), "Burn from the zero address");

            _beforeTokenTransfer(account, address(0), amount);

            uint256 accountBalance = _balances[account];
            require(accountBalance >= amount, "Burn amount exceeds balance");
            unchecked {
                _balances[account] = accountBalance - amount;
            }

            _totalSupply -= amount;

            emit Transfer(account, address(0), amount);

            _afterTokenTransfer(account, address(0), amount);
        }
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
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IAssetManagement.sol";

/**
 * @title IMarket
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Market.
 **/
interface IMarket {
    /**
     * STRUCTS
     */
    ///@notice user's withdrawal status management
    struct Withdrawal {
        uint256 timestamp;
        uint256 amount;
    }

    ///@notice insurance status management
    struct Insurance {
        uint256 id; //each insuance has their own id
        uint48 startTime; //timestamp of starttime
        uint48 endTime; //timestamp of endtime
        uint256 amount; //insured amount
        address insured; //the address holds the right to get insured
        bool status; //true if insurance is not expired
    }

    /**
     * EVENTS
     */
    event Deposit(address indexed depositor, uint256 amount, uint256 mint, uint256 pricePerToken);
    event WithdrawRequested(address indexed withdrawer, uint256 amount, uint256 unlockTime);
    event Withdraw(address indexed withdrawer, uint256 amount, uint256 retVal, uint256 pricePerToken);
    event Unlocked(uint256 indexed id, uint256 amount);
    event Terminated(uint256 indexed id, uint256 amount);
    event Insured(
        uint256 indexed id,
        uint256 amount,
        uint256 startTime,
        uint256 indexed endTime,
        address indexed insured,
        uint256 premium
    );
    event InsuranceIncreased(uint256 indexed id, uint256 amount);
    event InsuranceExtended(uint256 indexed id, uint256 endTime);
    event Redeemed(uint256 indexed id, uint256 payout, uint256 amount, address insured, bool status);
    event UnInsured(uint256 indexed id, uint256 feeback, uint256 amount, address insured, bool status);

    event Manager(address manager);
    event Migration(address from, address to);
    event InsuranceDecreased(uint256 id, uint256 amount, uint256 _newAmount, address insured, bool status);
    event TransferInsurance(uint256 indexed id, address from, address indexed newInsured);

    /**
     * FUNCTIONS
     */
    /**
     * @notice A liquidity provider supplies tokens to the pool and receives iTokens
     * @param _amount amount of tokens to deposit
     * @return _mintAmount the amount of iTokens minted from the transaction
     */
    function deposit(uint256 _amount) external returns (uint256);

    /**
     * @notice A liquidity provider request withdrawal of collateral
     * @param _amount amount of iTokens to burn
     */
    function requestWithdraw(uint256 _amount) external;

    /**
     * @notice A liquidity provider burns iTokens and receives collateral from the pool
     * @param _amount amount of iTokens to burn
     * @return _retVal the amount underlying tokens returned
     */
    function withdraw(uint256 _amount) external returns (uint256 _retVal);

    /**
     * @notice Unlocks an array of insurances
     * @param _ids array of ids to unlock
     */
    function unlockBatch(uint256[] calldata _ids) external;

    /**
     * @notice Unlock an insurance
     * @param _id id of the insurance policy to unlock liquidity
     */
    function unlock(uint256 _id) external;

    /**
     * @notice Terminates an array of insurances
     * @param _ids array of ids to unlock
     */
    function terminateBatch(uint256[] calldata _ids) external;

    /**
     * @notice Terminates an insurance
     * @param _id id of the insurance policy to unlock liquidity
     */
    function terminate(uint256 _id) external;

    /**
     * @notice Get insured for the specified amount for specified period
     * @param _amount target amount to get covered
     * @param _period end date to be covered(timestamp)
     * @return _id of the insurance policy
     */
    function insureByPeriod(uint256 _amount, uint48 _period) external returns (uint256);

    /**
     * @notice Get insured for the specified amount for specified period by delegator
     * @param _amount target amount to get covered
     * @param _period end date to be covered(timestamp)
     * @param _consignor consignor(payer) address
     * @return _id of the insurance policy
     */
    function insureByPeriodDelegate(
        uint256 _amount,
        uint48 _period,
        address _consignor
    ) external returns (uint256);

    /**
     * @notice Get insured for the specified amount for specified span
     * @param _amount target amount to get covered
     * @param _span length to get covered(e.g. 7 days)
     * @return _id of the insurance policy
     */
    function insure(uint256 _amount, uint256 _span) external returns (uint256);

    /**
     * @notice Get insured for the specified amount for specified span by delegator
     * @param _amount target amount to get covered
     * @param _span length to get covered(e.g. 7 days)
     * @param _consignor consignor(payer) address
     * @return _id of the insurance policy
     */
    function insureDelegate(
        uint256 _amount,
        uint256 _span,
        address _consignor
    ) external returns (uint256);

    /**
     * @notice extend end time of an insurance policy
     * @param _id id of a policy
     * @param _span length to extend(e.g. 7 days)
     */
    function extendInsurance(uint256 _id, uint48 _span) external;

    /**
     * @notice increase the coverage of an insurance policy by delegator
     * @param _id id of a policy
     * @param _amount coverage to increase
     * @param _consignor consignor(payer) address
     */
    function increaseInsuranceDelegate(
        uint256 _id,
        uint256 _amount,
        address _consignor
    ) external;

    /**
     * @notice increase the coverage of an insurance policy
     * @param _id id of a policy
     * @param _amount coverage to increase
     */
    function increaseInsurance(uint256 _id, uint256 _amount) external;

    /**
     * @notice Transfers an active insurance
     * @param _id id of the insurance policy
     * @param _newInsured new insured address
     */
    function transferInsurance(uint256 _id, address _newInsured) external;

    /**
     * @notice Transfers an active insurance
     * @param _id id of the insurance policy
     * @param _amount new insured address
     * @param _consignor address paid fee back
     */
    function decreaseInsurance(
        uint256 _id,
        uint256 _amount,
        address _consignor
    ) external;

    /**
     * @notice Redeem an insurance policy.
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     */
    function redeem(uint256 _id, uint256 _amount) external;

    /**
     * @notice Redeem an insurance policy by delegator
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     * @param _beneficiary address to get paid fee
     */
    function redeemDelegate(
        uint256 _id,
        uint256 _amount,
        address _beneficiary
    ) external;

    /**
     * @notice Redeem an insurance policy to payout other token
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     * @param _redeemToken redeem by other tokens
     */
    function redeemByToken(
        uint256 _id,
        uint256 _amount,
        address _redeemToken
    ) external;

    /**
     * @notice Redeem an insurance policy to payout other token by delegator
     * Allow split redemption for multiple times within the coverage amount.
     * @param _id the id of the insurance policy
     * @param _amount redeem amount
     * @param _redeemToken redeem by other tokens
     * @param _beneficiary address to get paid token
     */
    function redeemByTokenDelegate(
        uint256 _id,
        uint256 _amount,
        address _beneficiary,
        address _redeemToken
    ) external;

    /**
     * @notice Get how much premium + fee for the specified amount and span
     * @param _amount amount to get insured
     * @param _endTime end time to get covered(timestamp)
     */
    function getCostByPeriod(uint256 _amount, uint48 _endTime) external view returns (uint256);

    /**
     * @notice Get how much premium + fee for the specified amount and span
     * @param _amount amount to get insured
     * @param _span span to get covered
     */
    function getCost(uint256 _amount, uint256 _span) external view returns (uint256);

    /**
     * @notice get how much value per one iToken supply. scaled by 1e8
     */
    function rate() external view returns (uint256);

    /**
     * @notice Get the underlying balance of the `owner`
     * @param _owner the target address to look up value
     * @return _value The balance of underlying tokens for the specified address
     */
    function valueOfUnderlying(address _owner) external view returns (uint256);

    /**
     * @notice Get token number for the specified underlying value
     * @param _value the amount of the underlying
     * @return _amount the number of the iTokens corresponding to _value
     */
    function worth(uint256 _value) external view returns (uint256);

    /**
     * @notice Returns the availability of cover
     * @return available liquidity of this pool
     */
    function availableBalance() external view returns (uint256);

    /**
     * @notice Pool's Liquidity
     * @return total liquidity of this pool
     */
    function totalLiquidity() external view returns (uint256);

    /**
     * @notice Deposited amount not utilized yet
     * @return withdrawableAmount max withdrawable amount
     */
    function withdrawableAmount() external view returns (uint256);

    /**
     * @notice Return short positions (=covered amount)
     * @return amount short positions
     */
    function shortPositions() external view returns (uint256);

    /**
     * @notice Pool's max capacity
     * @return total capacity of this pool
     */
    function maxCapacity() external view returns (uint256);

    /**
     * @notice manager address
     * @return manager AssetManagement address
     */
    function manager() external view returns (IAssetManagement);

    /**
     * @notice set delegators
     * @param _manager manager address
     */
    function setManager(address _manager) external;

    /**
     * @notice set delegators
     * @param _delegator delegator address
     * @param _allowance allowed or not
     */
    function setDelegator(address _delegator, bool _allowance) external;

    /**
     * @notice Enable mmigration of manager contract.
     * Expected to use when there is updates on contract or underlying conditions
     * @param _to next manager contract
     * @param _references address params to pass to the new manager
     * @param _params parameters to pass to the new contract
     */
    function migrate(
        address _to,
        address[] calldata _references,
        uint256[] calldata _params
    ) external;

    /**
     * ERRORS
     */
    error NotApplicable();
    error NotTerminatable();
    error TooVolatile();
    error OnlyDelegator();
    error AmountZero();
    error RequestExceedBalance();
    error YetTime();
    error OverTime();
    error AmountExceeded();
    error NoSupply();
    error ZeroAddress();
    error BeforeNow();
    error OutOfSpan();
    error InsuranceNotActive();
    error InsuranceExpired();
    error InsuranceNotExpired();
    error InsureExceededMaxSpan();
    error NotYourInsurance();
    error MigrationFailed();
    error OnlyManager();
    error AlreadySetManager();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IFungibleInitializer.sol";

/**
 * @title IFungiblePolicy
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Fungible Policy.
 **/
interface IFungiblePolicy is IFungibleInitializer {
    /**
     * FUNCTIONS
     */

    /**
     * @notice get insurance end time
     * @return endTime
     */
    function endTime() external returns (uint48);

    /**
     * @notice purchase a fungible position of depeg insurance with a fixed date end policy
     * mint ERC20 token in exchange for paying a premium
     * @param _amount amount to redeem
     */
    function insure(uint256 _amount) external;

    /**
     * @notice redeem usdc in exchange for usdt.
     * @param _amount amount to redeem
     * @param _redeemToken option to redeem usdc as collateral tokens
     */
    function redeem(uint256 _amount, address _redeemToken) external;

    /**
     * ERRORS
     */
    error RequestExceedBalance();
    error AmountZero();
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IMigrationAsset.sol";

/**
 * @title IAssetManagement
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Asset Management.
 **/
interface IAssetManagement is IMigrationAsset {
    /**
     * STRUCTS
     */
    ///@notice aave tokens
    struct AaveTokens {
        address aBaseToken;
        address aTargetToken;
        address vTargetDebt;
        address sTargetDebt;
    }
    struct Performance {
        int256 lastUnderwriterFee;
        uint256 withdrawableProtocolFee;
    }

    /**
     * EVENTS
     */
    event ExchangeLogic(address exchangeLogic);
    event Aave(address _aave);

    /**
     * FUNCTIONS
     */

    /**
     * @notice A market contract can deposit collateral and get attribution point in return
     * @param  _amount amount of tokens to deposit
     * @param _from sender's address
     */
    function addValue(uint256 _amount, address _from) external;

    /**
     * @notice an address that has balance in the vault can withdraw underlying value
     * @param _amount amount of tokens to withdraw
     * @param _to address to get underlying tokens
     */
    function withdrawValue(uint256 _amount, address _to) external;

    /**
     * @notice apply leverage and create position of depeg coverage. used when insure() is called
     * @param _amount amount of USDT position
     * @param _premium premium amount
     * @param _protocolFee fee amount
     * @param _from who pays fees
     */
    function utilize(
        uint256 _amount,
        uint256 _premium,
        uint256 _protocolFee,
        address _from
    ) external;

    /**
     * @notice dissolve and deleverage positions
     * @param _amount amount to unutilize
     */
    function unutilize(uint256 _amount) external;

    /**
     * @notice unutilize and pay premium back
     * @param _amount amount to unutilize
     * @param _params parameters
     * @param _to address to get premium back
     */
    function cancel(
        uint256 _amount,
        uint256[] memory _params,
        address _to
    ) external;

    /**
     * @notice repay USDT debt and redeem USDC. Expected to be used when depeg happend.
     * @param _amount amount to redeem
     * @param _from redeem destination
     */
    function repayAndRedeem(
        uint256 _amount,
        address _from,
        address _redeemToken
    ) external;

    /**
     * @notice pay fees. Expected to use when extend the position holding length.
     * @param _premium premium amount
     * @param _protocolFee fee amount
     * @param _from who pays fees
     */
    function payFees(
        uint256 _premium,
        uint256 _protocolFee,
        address _from
    ) external;

    /**
     * @notice withdraw Aave's accrued reward tokens
     * @param _rewardAmount market's receipient amount
     * @param _to receipient of reward
     */
    function withdrawReward(uint256 _rewardAmount, address _to) external;

    /**
     * @notice get debt amount without interest
     */
    function originalDebt() external view returns (uint256);

    /**
     * @notice get principal value in USDC.
     */
    function getPrincipal() external view returns (uint256);

    /**
     * @notice get the latest status of performance and principal
     */
    function getPerformance()
        external
        view
        returns (
            uint256 _principal,
            uint256 _protocolPerformance,
            uint256 _underwritersPerformance
        );

    /**
     * @notice get how much can one withdraw USDC.
     */
    function getWithdrawable() external view returns (uint256);

    /**
     * @notice get maximum USDT short positions can be hold in the contract.
     */
    function getMaxBorrowable() external view returns (uint256);

    /**
     * @notice get how much USDT short positions can be hold in the contract.
     */
    function getAvailable() external view returns (uint256);

    /**
     * @notice avairable for deposit USDC within aave max utilization(USDT borrowable).
     */
    function getAvailableOrAaveAvailable() external view returns (uint256);

    /**
     * @notice get how much usdt short position can be taken safely from this account.
     * maxUtilizationRateAfterBorrow prevents borrwing too much and increase utilization beyond allowance.
     */
    function calcAaveAvailableBorrow() external view returns (uint256 avairableBorrow);

    /**
     * @notice get how much usdc deposit position can be taken safely from this account.
     * maxOccupancyRate prevents supplying too much
     */
    function calcAaveAvailableSupplyUsdc() external view returns (uint256 avairableSupply);

    /**
     * @notice get Aave's accrured rewards
     */
    function getAccruedReward() external view returns (uint256);

    /**
     * @notice set exchangeLogic and approve it
     * @param _exchangeLogic exchangeLogic
     */
    function setExchangeLogic(address _exchangeLogic) external;

    /**
     * @notice set aave lending pool address and approve it
     * @param _aave aave lending pool address
     */
    function setAave(address _aave) external;

    /**
     * @notice withdraw redundant token stored in this contract
     * @param _token token address
     * @param _to beneficiary's address
     */
    function withdrawRedundant(address _token, address _to) external;

    /**
     * @notice swap redundant targetToken and supply it
     */
    function supplyRedundantTargetToken() external returns (uint256 _supplyed);

    /**
     * @notice withdraw accrued protocol fees.
     * @param _to withdrawn fee destination
     */
    function withdrawProtocolReserve(address _to) external;

    /**
     * ERRORS
     */
    error OnlyMarket();
    error ZeroAddress();
    error AmmountExceeded();
    error LackOfPremium();
    error AaveMismatch();
    error AaveExceedUtilizationCap();
    error AaveOccupyTooMuch();
    error UnsupportedRedeemToken();
    error LessSwappedThanEstimated();
    error ExceedReserved();
    error ZeroBalance();
    error NonWithdrawableToken();
    error ZeroAmount();
    error SwapFailed();
    error BeyondSlippageTolerance();
    error LackOfOriginalSupply();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IMigrationAsset
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Asset Migration.
 **/
interface IMigrationAsset {
    /**
     * EVENTS
     */
    event Immigration(
        address _from,
        uint256 _principal,
        uint256 _feePool,
        uint256 _shortPosition,
        address[] _references,
        uint256[] _params
    );

    event Emigration(
        address _to,
        uint256 _principal,
        uint256 _feePool,
        uint256 _shortPosition,
        address[] _references,
        uint256[] _params
    );

    /**
     * FUNCTIONS
     */
    /**
     * @notice immigrate positon settings to a new manager contract
     * @param _principal principal amount that is migtated to new manager
     * @param _feePool fee reserve that is migrated to new manager
     * @param _shortPosition constructed short position to new manager to reconstruct
     * @param _deposit deposit amount
     * @param _references address params to pass to the new manager
     * @param _params parameters to pass to the new contract
     */
    function immigrate(
        uint256 _principal,
        uint256 _feePool,
        uint256 _shortPosition,
        uint256 _deposit,
        address[] calldata _references,
        uint256[] calldata _params
    ) external;

    /**
     * @notice emmigrate positon settings to a new manager contract
     * @param _to next manager contract
     * @param _references address params to pass to the new manager
     * @param _params parameters to pass to the new contract
     */
    function emigrate(
        address _to,
        address[] calldata _references,
        uint256[] calldata _params
    ) external;

    /**
     * ERRORS
     */
    error OnlyFromManager();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IFungibleInitializer
 * @author @InsureDAO
 * @notice Defines the basic interface for an InsureDAO Fungible Initializer.
 **/
interface IFungibleInitializer {
    /**
     * @notice initialize functions for proxy contracts.
     * @param  _name contract's name
     * @param  _symbol contract's symbol (supported ERC20)
     * @param  _params initilizing params
     * @param  _references initilizing addresses
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        uint256[] calldata _params,
        address[] calldata _references
    ) external;
}