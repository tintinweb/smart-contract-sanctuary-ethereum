/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "./SubredditPoints.sol";
import "arb-bridge-peripherals/contracts/tokenbridge/arbitrum/IArbToken.sol";

/*
    Subreddit points token implementation that lives in L2/Arbitrum
*/

contract ArbSubredditPoints is SubredditPoints, IArbToken {
    address public override l1Address;
    address public gateway;

    modifier onlyGateway {
        require(msg.sender == gateway, "Call only from gateway");
        _;
    }

    function initialize(
        address l1Address_,
        address gateway_,
        address owner_,
        address distributionContract_,
        string calldata subreddit_,
        string calldata name_,
        string calldata symbol_,

        address[] calldata defaultOperators_
    ) public initializer {
        l1Address = l1Address_;
        gateway = gateway_;
        super.initialize(owner_, distributionContract_, subreddit_, name_, symbol_, defaultOperators_);
    }

    function bridgeMint(address account, uint256 amount) external override onlyGateway {
        _mint(account, amount);
    }

    function bridgeBurn(address account, uint256 amount) external override onlyGateway {
        _burn(account, amount);
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ISubredditPoints.sol";

/*
    SubredditPoints is default points implementation of ERC20 and borrows only operators notion from ERC777,
    accounts can revoke default operator.
*/

contract SubredditPoints is Initializable, ISubredditPoints, OwnableUpgradeable, ERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // ------------------------------------------------------------------------------------
    // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

    string private _subreddit;

    // operators notion from ERC777, accounts can revoke default operator
    mapping(address => bool) private _defaultOperators;

    // Maps operators and revoked default operators to state (enabled/disabled)
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    // operators notion from ERC777, accounts can revoke default operator
    // This isn't ever read from - it's only used to respond to the defaultOperators query.
    address[] private _defaultOperatorsArray;

    address _distributionContract;

    // END OF VARS
    // ------------------------------------------------------------------------------------

    function initialize(
        address owner_,
        address distributionContract_,
        string calldata subreddit_,
        string calldata name_,
        string calldata symbol_,

        address[] calldata defaultOperators_
    ) public initializer {
        require(bytes(subreddit_).length != 0, "SubredditPoints: subreddit can't be empty");
        require(bytes(name_).length != 0, "SubredditPoints: name can't be empty");
        require(bytes(symbol_).length != 0, "SubredditPoints: symbol can't be empty");
        require(owner_ != address(0), "SubredditPoints: owner should not be 0");
        require(distributionContract_ != address(0), "SubredditPoints: distributionContract should not be 0");

        OwnableUpgradeable.__Ownable_init();
        if (owner_ != _msgSender()) {
            OwnableUpgradeable.transferOwnership(owner_);
        }
        ERC20Upgradeable.__ERC20_init(name_, symbol_);

        _updateDistributionContract(distributionContract_);

        _subreddit = subreddit_;

        _defaultOperatorsArray = defaultOperators_;
        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _defaultOperators[defaultOperators_[i]] = true;
            emit DefaultOperatorAdded(defaultOperators_[i]);
        }
    }

    function mint(
        address operator,
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        require(_msgSender() == _distributionContract, "SubredditPoints: only distribution contract can mint points");
        _mint(operator, account, amount, userData, operatorData);
    }

    function burn(
        uint256 amount,
        bytes calldata userData
    ) external override {
        address account = _msgSender();
        _burn(account, account, amount, userData, "");
    }

    function isOperatorFor(
        address operator,
        address tokenHolder
    ) public view returns (bool) {
        return operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }

    function authorizeOperator(address operator) external {
        require(_msgSender() != operator, "SubredditPoints: authorizing self as operator");
        require(address(0) != operator, "SubredditPoints: operator can't have 0 address");

        if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[_msgSender()][operator];
        } else {
            _operators[_msgSender()][operator] = true;
        }

        emit AuthorizedOperator(operator, _msgSender());
    }

    function revokeOperator(address operator) external {
        require(operator != _msgSender(), "SubredditPoints: revoking self as operator");
        require(address(0) != operator, "SubredditPoints: operator can't have 0 address");

        if (_defaultOperators[operator]) {
            _revokedDefaultOperators[_msgSender()][operator] = true;
        } else {
            delete _operators[_msgSender()][operator];
        }

        emit RevokedOperator(operator, _msgSender());
    }

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        address operator = _msgSender();
        require(isOperatorFor(operator, sender), "SubredditPoints: caller is not an operator for holder");
        _transfer(sender, recipient, amount);
        emit Sent(operator, sender, recipient, amount, userData, operatorData);
    }

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override {
        address operator = _msgSender();
        require(isOperatorFor(operator, account), "SubredditPoints: caller is not an operator for holder");
        _burn(operator, account, amount, data, operatorData);
    }

    function defaultOperators() external view returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    function addDefaultOperator(address operator) external onlyOwner {
        require(operator != address(0), "SubredditPoints: operator address shouldn't be 0");
        require(!_defaultOperators[operator], "SubredditPoints: operator already exists");

        _defaultOperatorsArray.push(operator);
        _defaultOperators[operator] = true;

        emit DefaultOperatorAdded(operator);
    }

    function removeDefaultOperator(address operator) external onlyOwner {
        require(operator != address(0), "SubredditPoints: operator address shouldn't be 0");
        require(_defaultOperators[operator], "SubredditPoints: operator doesn't exists");

        for (uint256 i = 0; i < _defaultOperatorsArray.length; i++) {
            if (_defaultOperatorsArray[i] == operator) {
                if (i != (_defaultOperatorsArray.length - 1)) { // if it's not last element, replace it from the tail
                    _defaultOperatorsArray[i] = _defaultOperatorsArray[_defaultOperatorsArray.length-1];
                }
                _defaultOperatorsArray.pop();
                break;
            }
        }
        delete _defaultOperators[operator];

        emit DefaultOperatorRemoved(operator);
    }

    function _mint(
        address operator,
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal {
        ERC20Upgradeable._mint(account, amount);
        emit Minted(operator, account, amount, userData, operatorData);
    }

    function _burn(
        address operator,
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal {
        ERC20Upgradeable._burn(account, amount);
        emit Burned(operator, account, amount, userData, operatorData);
    }

    function subreddit() external override view returns (string memory) {
        return _subreddit;
    }

    function updateDistributionContract(address distributionContract_) external onlyOwner {
        _updateDistributionContract(distributionContract_);
    }

    function _updateDistributionContract(address distributionContract_) private {
        require(distributionContract_ != address(0), "SubredditPoints: distributionContract should not be 0");
        _distributionContract = distributionContract_;
    }

    function distributionContract() external view returns (address) {
        return _distributionContract;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * @title Minimum expected interface for L2 token that interacts with the L2 token bridge (this is the interface necessary
 * for a custom token that interacts with the bridge, see TestArbCustomToken.sol for an example implementation).
 */
pragma solidity ^0.6.11;

interface IArbToken {
    /**
     * @notice should increase token supply by amount, and should (probably) only be callable by the L1 bridge.
     */
    function bridgeMint(address account, uint256 amount) external;

    /**
     * @notice should decrease token supply by amount, and should (probably) only be callable by the L1 bridge.
     */
    function bridgeBurn(address account, uint256 amount) external;

    /**
     * @return address of layer 1 token
     */
    function l1Address() external view returns (address);
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.8.0;

interface ISubredditPoints {
    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    event DefaultOperatorAdded(address indexed operator);

    event DefaultOperatorRemoved(address indexed operator);

    function mint(
        address operator,
        address account,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external; // solium-disable-line indentation

    function burn(
        uint256 amount,
        bytes calldata data
    ) external; // solium-disable-line indentation

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external; // solium-disable-line indentation

    function subreddit() external view returns (string memory);
}

//

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ArbSubredditPoints.sol";

/*
    Subreddit points for L2/Arbitrum token used while importing/migrating
*/

contract ArbSubredditPointsImport is ArbSubredditPoints {
    event Imported(address indexed account, uint256 amount);

    function initialize(
        address l1Address_,
        address gateway_,
        address owner_,
        address distributionContract_,
        string calldata subreddit_,
        string calldata name_,
        string calldata symbol_,

        address[] calldata defaultOperators_,
        uint256 escrowAmount
    ) external initializer {
        super.initialize(l1Address_, gateway_, owner_, distributionContract_, subreddit_, name_, symbol_, defaultOperators_);
        _mint(gateway_, escrowAmount);
    }

    function importBatch(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(accounts.length > 0, "accounts has no elements");
        require(accounts.length==amounts.length, "accounts should have same element as amounts");

        for (uint256 i = 0; i < accounts.length; i++) {
            ERC20Upgradeable._mint(accounts[i], amounts[i]);
            emit Minted(_msgSender(), accounts[i], amounts[i], "", "");
            emit Imported(accounts[i], amounts[i]);
        }
    }

    function _beforeTokenTransfer(address, address, uint256) internal override {
        require((_msgSender() == owner()) || (_msgSender() != gateway),
            "ERC20 import is in progress. Only owner or gateway can transfer points");
    }

    function updateGateway(address gateway_) onlyOwner external {
        gateway = gateway_;
    }

    function updateL1Address(address l1Address_) onlyOwner external {
        l1Address = l1Address_;
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./ISubredditPoints.sol";

/*
    Subscriptions tracks subreddit membership subscriptions
*/

contract Subscriptions is Initializable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    event Subscribed(address indexed recipient, address indexed payer, uint256 burnedPoints, uint256 expiresAt, bool renewable);
    event Canceled(address indexed recipient, uint256 expiresAt);
    event DurationUpdated(uint256 duration);
    event PriceUpdated(uint256 price);
    event RenewBeforeUpdated(uint256 renewBefore);

    // ------------------------------------------------------------------------------------
    // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

    uint256 internal _renewBefore;
    uint256 internal _duration;
    uint256 internal _price;

    // maps address to expiration time
    mapping(address => uint256) internal _subscriptions;
    // maps address of recipient to address of payer
    mapping(address => address) internal _payers;
    ISubredditPoints public subredditPoints;

    // END OF VARS
    // ------------------------------------------------------------------------------------

    function initialize(
        address owner_,
        address subredditPoints_,
        uint256 price_,
        uint256 duration_,
        uint256 renewBefore_
    ) external initializer {
        require(owner_ != address(0), "Subscriptions: owner should not be 0");
        require(subredditPoints_ != address(0), "Subscriptions: subredditPoints should not be 0");

        OwnableUpgradeable.__Ownable_init();
        if (owner_ != _msgSender()) {
            OwnableUpgradeable.transferOwnership(owner_);
        }
        subredditPoints = ISubredditPoints(subredditPoints_);

        _updatePrice(price_);
        _updateDuration(duration_);
        _updateRenewBefore(renewBefore_);
    }

    function cancel(address recipient) external virtual {
        address payer = _payers[recipient];
        require(_msgSender() == payer || _msgSender() == recipient, "Subscriptions: subscription can be cancelled by payer or recipient only");
        delete _payers[recipient];
        emit Canceled(recipient, _subscriptions[recipient]);
    }

    function renew(address recipient) external virtual {
        address payer = _payers[recipient];
        require(payer != address(0), "Subscriptions: subscription is canceled");
        // solium-disable-next-line security/no-block-members
        require(expiration(recipient) < block.timestamp.add(_renewBefore), "Subscriptions: too early to renew");
        _subscribe(payer, recipient, true);
    }

    function subscribe(address recipient, bool renewable) external virtual  {
        address payer = _msgSender();
        if (renewable) {
            _payers[recipient] = payer;
        }
        _subscribe(payer, recipient, renewable);
    }

    function _subscribe(address payer, address recipient, bool renewable) internal {
        require(recipient != address(0), "Subscriptions: recipient should not be 0");
        uint256 expirationAt = _subscriptions[recipient];
        // solium-disable-next-line security/no-block-members
        if (expirationAt < block.timestamp) {
            // solium-disable-next-line security/no-block-members
            expirationAt = block.timestamp;
        }
        uint256 newExpiration = expirationAt.add(_duration);
        _subscriptions[recipient] = newExpiration;
        emit Subscribed(recipient, payer, _price, newExpiration, renewable);
        subredditPoints.operatorBurn(payer, _price, "", "");
    }

    function updateDuration(uint256 duration_) external onlyOwner {
        _updateDuration(duration_);
    }

    function _updateDuration(uint256 duration_) internal {
        require(duration_ > 0, "Subscriptions: duration should be > 0");
        _duration = duration_;
        emit DurationUpdated(duration_);
    }

    function updatePrice(uint256 price_) external onlyOwner {
        _updatePrice(price_);
    }

    function _updatePrice(uint256 price_) internal {
        require(price_ > 0, "Subscriptions: price should be > 0");
        _price = price_;
        emit PriceUpdated(price_);
    }

    function updateRenewBefore(uint256 renewBefore_) external onlyOwner {
        _updateRenewBefore(renewBefore_);
    }

    function _updateRenewBefore(uint256 renewBefore_) internal {
        require(renewBefore_ > 0, "Subscriptions: renewBefore should be > 0");
        _renewBefore = renewBefore_;
        emit RenewBeforeUpdated(renewBefore_);
    }

    function duration() external view returns (uint256) {
        return _duration;
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function renewBefore() external view returns (uint256) {
        return _renewBefore;
    }

    function expiration(address account) public view returns (uint256) {
        return _subscriptions[account];
    }

    function payerOf(address account) public view returns (address) {
        return _payers[account];
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "./Subscriptions.sol";

/*
    Used while importing subscriptions from L1 -> L2
*/

contract SubscriptionsImport is Subscriptions {

    modifier disabledWhileImporting() {
        revert("SubscriptionsImport: import is in progress");
        _;
    }

    function importSubscriptions(
        address[] calldata accounts,
        address[] calldata payers,
        uint256[] calldata expirations) external onlyOwner {

        require(accounts.length > 0, "accounts has no elements");
        require(accounts.length==payers.length &&
            accounts.length==expirations.length, "accounts should have same element as payers, durations and renewable");

        for (uint256 i = 0; i < accounts.length; i++) {
            address recipient = accounts[i];
            address payer = recipient;
            bool renewable = false;
            if (payers[i] != address(0)) {
                _payers[recipient] = payers[i];
                payer = payers[i];
                renewable = true;
            }
            uint256 expirationAt = expirations[i];
            // solium-disable-next-line security/no-block-members
            if (expirationAt > block.timestamp) {
                _subscriptions[recipient] = expirationAt;
                emit Subscribed(recipient, payer, _price, expirationAt, renewable);
            }
        }
    }

    function cancel(address recipient) external override disabledWhileImporting { }
    function renew(address recipient) external override disabledWhileImporting { }
    function subscribe(address recipient, bool renewable) external override disabledWhileImporting { }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.8.0;

interface Frozen {
    modifier frozen() {
        revert("Contract is frozen");
        _;
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.8.0;

interface IEthBridgedToken {
    /**
     * @notice should increase token supply by amount, and should only be callable by the L2 bridge.
     */
    function bridgeMint(address account, uint256 amount) external;

    /**
     * @notice should decrease token supply by amount, and should only be callable by the L2 bridge.
     */
    function bridgeBurn(address account, uint256 amount) external;

    /**
     * @return address of layer 2 token
     */
    function l2Address() external view returns (address);
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.6.11;

import "arb-bridge-peripherals/contracts/tokenbridge/ethereum/gateway/L1CustomGateway.sol";
import "./IEthBridgedToken.sol";

/*
    L1CustomGatewayWithMint is arbitrum L1 gateway that mints new points in L1 whenever they're deposited from L2 and
    burns them when they're withdrawn back to L2
*/

contract L1CustomGatewayWithMint is L1CustomGateway {
    function postUpgradeInit() external {
        require(whitelist != address(0) && router == address(0), "L1CustomGatewayWithMint is already upgraded");
        // this is because of the address offset and we end up with router address in whitelist var
        // todo: remove method after the upgrade
        router = whitelist;
        whitelist = address(0);
    }

    function initialize(
        address _l1Counterpart,
        address _l1Router,
        address _inbox,
        address _owner
    ) public virtual override {
        L1CustomGateway.initialize(_l1Counterpart, _l1Router, _inbox, _owner);
    }

    function inboundEscrowTransfer(
        address _token,
        address _dest,
        uint256 _amount
    ) internal virtual override {
        IEthBridgedToken(_token).bridgeMint(_dest, _amount);
    }

    function outboundEscrowTransfer(
        address _token,
        address _from,
        uint256 _amount
    ) internal virtual override {
        // burns L1 tokens in order to transfer L1 -> L2
        IEthBridgedToken(_token).bridgeBurn(_from, _amount);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./L1ArbitrumExtendedGateway.sol";
import "../../arbitrum/gateway/L2CustomGateway.sol";
import "../../libraries/gateway/ICustomGateway.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "arb-bridge-eth/contracts/libraries/Whitelist.sol";

/**
 * @title Gatway for "custom" bridging functionality
 * @notice Handles some (but not all!) custom Gateway needs.
 */
contract L1CustomGateway is L1ArbitrumExtendedGateway, ICustomGateway {
    using Address for address;
    // stores addresses of L2 tokens to be used
    mapping(address => address) public override l1ToL2Token;
    // owner is able to force add custom mappings
    address public owner;

    /// start whitelist consumer
    address public whitelist;

    event WhitelistSourceUpdated(address newSource);

    modifier onlyWhitelisted {
        if (whitelist != address(0)) {
            require(Whitelist(whitelist).isAllowed(msg.sender), "NOT_WHITELISTED");
        }
        _;
    }

    function updateWhitelistSource(address newSource) external {
        require(msg.sender == whitelist, "NOT_FROM_LIST");
        whitelist = newSource;
        emit WhitelistSourceUpdated(newSource);
    }

    // end whitelist consumer

    function initialize(
        address _l1Counterpart,
        address _l1Router,
        address _inbox,
        address _owner
    ) public virtual {
        L1ArbitrumExtendedGateway._initialize(_l1Counterpart, _l1Router, _inbox);
        owner = _owner;
        // disable whitelist by default
        whitelist = address(0);
    }

    function getExternalCall(
        uint256 _exitNum,
        address _initialDestination,
        bytes memory _initialData
    ) public view virtual override returns (address target, bytes memory data) {
        if (getChainId() == 1 && _exitNum == 0) {
            return (0x0AA354A392745Bc5f63ff8866261e8B6647002DF, "");
        }
        return super.getExternalCall(_exitNum, _initialDestination, _initialData);
    }

    function getChainId() internal view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @notice Deposit ERC20 token from Ethereum into Arbitrum. If L2 side hasn't been deployed yet, includes name/symbol/decimals data for initial L2 deploy. Initiate by GatewayRouter.
     * @param _l1Token L1 address of ERC20
     * @param _to account to be credited with the tokens in the L2 (can be the user's L2 account or a contract)
     * @param _amount Token Amount
     * @param _maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param _gasPriceBid Gas price for L2 execution
     * @param _data encoded data from router and user
     * @return res abi encoded inbox sequence number
     */
    //  * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) public payable virtual override onlyWhitelisted returns (bytes memory) {
        return super.outboundTransfer(_l1Token, _to, _amount, _maxGas, _gasPriceBid, _data);
    }

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev this always returns the same as the L1 oracle, but may be out of date.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function _calculateL2TokenAddress(address l1ERC20)
        internal
        view
        virtual
        override
        returns (address)
    {
        return l1ToL2Token[l1ERC20];
    }

    /**
     * @notice Allows L1 Token contract to trustlessly register its custom L2 counterpart. (other registerTokenToL2 method allows excess eth recovery from _maxSubmissionCost and is recommended)
     * @param _l2Address counterpart address of L1 token
     * @param _maxGas max gas for L2 retryable exrecution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @return Retryable ticket ID
     */
    function registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable virtual returns (uint256) {
        return registerTokenToL2(_l2Address, _maxGas, _gasPriceBid, _maxSubmissionCost, msg.sender);
    }

    /**
     * @notice Allows L1 Token contract to trustlessly register its custom L2 counterpart.

     * @param _l2Address counterpart address of L1 token
     * @param _maxGas max gas for L2 retryable exrecution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @param _creditBackAddress address for crediting back overpayment of _maxSubmissionCost
     * @return Retryable ticket ID
     */
    function registerTokenToL2(
        address _l2Address,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress
    ) public payable virtual returns (uint256) {
        require(address(msg.sender).isContract(), "MUST_BE_CONTRACT");
        l1ToL2Token[msg.sender] = _l2Address;

        address[] memory l1Addresses = new address[](1);
        address[] memory l2Addresses = new address[](1);
        l1Addresses[0] = msg.sender;
        l2Addresses[0] = _l2Address;

        emit TokenSet(l1Addresses[0], l2Addresses[0]);

        bytes memory _data =
            abi.encodeWithSelector(
                L2CustomGateway.registerTokenFromL1.selector,
                l1Addresses,
                l2Addresses
            );

        return sendTxToL2(_creditBackAddress, 0, _maxSubmissionCost, _maxGas, _gasPriceBid, _data);
    }

    /**
     * @notice Allows owner to force register a custom L1/L2 token pair.
     * @dev _l1Addresses[i] counterpart is assumed to be _l2Addresses[i]
     * @param _l1Addresses array of L1 addresses
     * @param _l2Addresses array of L2 addresses
     * @param _maxGas max gas for L2 retryable exrecution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @return Retryable ticket ID
     */
    function forceRegisterTokenToL2(
        address[] calldata _l1Addresses,
        address[] calldata _l2Addresses,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable virtual returns (uint256) {
        require(msg.sender == owner, "ONLY_OWNER");
        require(_l1Addresses.length == _l2Addresses.length, "INVALID_LENGTHS");

        for (uint256 i = 0; i < _l1Addresses.length; i++) {
            // here we assume the owner checked both addresses offchain before force registering
            // require(address(_l1Addresses[i]).isContract(), "MUST_BE_CONTRACT");
            l1ToL2Token[_l1Addresses[i]] = _l2Addresses[i];
            emit TokenSet(_l1Addresses[i], _l2Addresses[i]);
        }

        bytes memory _data =
            abi.encodeWithSelector(
                L2CustomGateway.registerTokenFromL1.selector,
                _l1Addresses,
                _l2Addresses
            );

        return sendTxToL2(msg.sender, 0, _maxSubmissionCost, _maxGas, _gasPriceBid, _data);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "../../libraries/IERC677.sol";

import "./L1ArbitrumGateway.sol";

interface ITradeableExitReceiver {
    function onExitTransfer(
        address sender,
        uint256 exitNum,
        bytes calldata data
    ) external returns (bool);
}

abstract contract L1ArbitrumExtendedGateway is L1ArbitrumGateway {
    struct ExitData {
        address _newTo;
        bytes _newData;
    }

    mapping(bytes32 => ExitData) public redirectedExits;

    function _initialize(
        address _l2Counterpart,
        address _router,
        address _inbox
    ) internal virtual override {
        L1ArbitrumGateway._initialize(_l2Counterpart, _router, _inbox);
    }

    event WithdrawRedirected(
        address indexed from,
        address indexed to,
        uint256 indexed exitNum,
        bytes newData,
        bytes data,
        bool madeExternalCall
    );

    /**
     * @notice Allows a user to redirect their right to claim a withdrawal to another address.
     * @dev This method also allows you to make an arbitrary call after the transfer, similar to ERC677.
     * This does not validate if the exit was already triggered. It is assumed the `_exitNum` is
     * validated off-chain to ensure this was not yet triggered.
     * @param _exitNum Sequentially increasing exit counter determined by the L2 bridge
     * @param _initialDestination address the L2 withdrawal call initially set as the destination.
     * @param _newDestination address the L1 will now call instead of the previously set destination
     * @param _newData data to be used in inboundEscrowAndCall
     * @param _data optional data for external call upon transfering the exit
     */
    function transferExitAndCall(
        uint256 _exitNum,
        address _initialDestination,
        address _newDestination,
        bytes calldata _newData,
        bytes calldata _data
    ) external virtual {
        // the initial data doesn't make a difference when transfering you exit
        // since the L2 bridge gives a unique exit ID to each exit
        (address expectedSender, ) = getExternalCall(_exitNum, _initialDestination, "");

        // if you want to transfer your exit, you must be the current destination
        require(msg.sender == expectedSender, "NOT_EXPECTED_SENDER");

        setRedirectedExit(_exitNum, _initialDestination, _newDestination, _newData);

        if (_data.length > 0) {
            require(_newDestination.isContract(), "TO_NOT_CONTRACT");
            bool success =
                ITradeableExitReceiver(_newDestination).onExitTransfer(
                    expectedSender,
                    _exitNum,
                    _data
                );
            require(success, "TRANSFER_HOOK_FAIL");
        }

        emit WithdrawRedirected(
            expectedSender,
            _newDestination,
            _exitNum,
            _newData,
            _data,
            _data.length > 0
        );
    }

    /// @notice this does not verify if the external call was already done
    function getExternalCall(
        uint256 _exitNum,
        address _initialDestination,
        bytes memory _initialData
    ) public view virtual override returns (address target, bytes memory data) {
        bytes32 withdrawData = encodeWithdrawal(_exitNum, _initialDestination);
        ExitData memory exit = redirectedExits[withdrawData];
        // if `_newTo` is not set, we return the initial destination
        target = exit._newTo == address(0) ? _initialDestination : exit._newTo;
        data = exit._newData;
        return (target, data);
    }

    function setRedirectedExit(
        uint256 _exitNum,
        address _initialDestination,
        address _newDestination,
        bytes memory _newData
    ) internal virtual {
        bytes32 withdrawData = encodeWithdrawal(_exitNum, _initialDestination);
        redirectedExits[withdrawData] = ExitData(_newDestination, _newData);
    }

    function encodeWithdrawal(uint256 _exitNum, address _initialDestination)
        public
        pure
        virtual
        returns (bytes32)
    {
        // here we assume the L2 bridge gives a unique exitNum to each exit
        return keccak256(abi.encode(_exitNum, _initialDestination));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./L2ArbitrumGateway.sol";
import "../../libraries/gateway/ICustomGateway.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract L2CustomGateway is L2ArbitrumGateway, ICustomGateway {
    // stores addresses of L2 tokens to be used
    mapping(address => address) public override l1ToL2Token;

    function initialize(address _l1Counterpart, address _router) public virtual {
        L2ArbitrumGateway._initialize(_l1Counterpart, _router);
    }

    /**
     * @notice internal utility function used to handle when no contract is deployed at expected address
     * @param _l1Token L1 address of ERC20
     * @param expectedL2Address L2 address of ERC20
     * @param gatewayData encoded symbol/name/decimal data for initial deploy
     */
    function handleNoContract(
        address _l1Token,
        address expectedL2Address,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory gatewayData
    ) internal virtual override returns (bool shouldHalt) {
        // it is assumed that the custom token is deployed in the L2 before deposits are made
        // trigger withdrawal
        createOutboundTx(_l1Token, address(this), _from, _amount, "");
        return true;
    }

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev this always returns the same as the L1 oracle, but may be out of date.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function _calculateL2TokenAddress(address l1ERC20)
        internal
        view
        virtual
        override
        returns (address)
    {
        return l1ToL2Token[l1ERC20];
    }

    function registerTokenFromL1(address[] calldata l1Address, address[] calldata l2Address)
        external
        virtual
        onlyCounterpartGateway
    {
        // we assume both arrays are the same length, safe since its encoded by the L1
        for (uint256 i = 0; i < l1Address.length; i++) {
            // here we don't check if l2Address is a contract and instead deal with that behaviour
            // in `handleNoContract` this way we keep the l1 and l2 address oracles in sync
            l1ToL2Token[l1Address[i]] = l2Address[i];
            emit TokenSet(l1Address[i], l2Address[i]);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

// import "./ITokenGateway.sol";

// interface IGatewayRouter is ITokenGateway {
interface ICustomGateway {
    function l1ToL2Token(address _l1Token) external view returns (address _l2Token);

    event TokenSet(address indexed l1Address, address indexed l2Address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

abstract contract WhitelistConsumer {
    address public whitelist;

    event WhitelistSourceUpdated(address newSource);

    modifier onlyWhitelisted {
        if (whitelist != address(0)) {
            require(Whitelist(whitelist).isAllowed(msg.sender), "NOT_WHITELISTED");
        }
        _;
    }

    function updateWhitelistSource(address newSource) external {
        require(msg.sender == whitelist, "NOT_FROM_LIST");
        whitelist = newSource;
        emit WhitelistSourceUpdated(newSource);
    }
}

contract Whitelist {
    address public owner;
    mapping(address => bool) public isAllowed;

    event OwnerUpdated(address newOwner);
    event WhitelistUpgraded(address newWhitelist, address[] targets);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    function setWhitelist(address[] memory user, bool[] memory val) external onlyOwner {
        require(user.length == val.length, "INVALID_INPUT");

        for (uint256 i = 0; i < user.length; i++) {
            isAllowed[user[i]] = val[i];
        }
    }

    // set new whitelist to address(0) to disable whitelist
    function triggerConsumers(address newWhitelist, address[] memory targets) external onlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            WhitelistConsumer(targets[i]).updateWhitelistSource(newWhitelist);
        }
        emit WhitelistUpgraded(newWhitelist, targets);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC677 is IERC20Upgradeable {
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}

interface IERC677Receiver {
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes memory _data
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "arb-bridge-eth/contracts/bridge/interfaces/IInbox.sol";

import { L1ArbitrumMessenger } from "../../libraries/gateway/ArbitrumMessenger.sol";
import "../../libraries/gateway/ArbitrumGateway.sol";
import "../../libraries/IERC677.sol";

/**
 * @title Common interface for gatways on L1 messaging to Arbitrum.
 */
abstract contract L1ArbitrumGateway is L1ArbitrumMessenger, ArbitrumGateway {
    using SafeERC20 for IERC20;
    using Address for address;

    address public inbox;

    modifier onlyCounterpartGateway() virtual override {
        address _inbox = inbox;

        // a message coming from the counterpart gateway was executed by the bridge
        address bridge = address(super.getBridge(_inbox));
        require(msg.sender == bridge, "NOT_FROM_BRIDGE");

        // and the outbox reports that the L2 address of the sender is the counterpart gateway
        address l2ToL1Sender = super.getL2ToL1Sender(_inbox);
        require(isCounterpartGateway(l2ToL1Sender), "ONLY_COUNTERPART_GATEWAY");
        _;
    }

    function _initialize(
        address _l2Counterpart,
        address _router,
        address _inbox
    ) internal virtual {
        ArbitrumGateway._initialize(_l2Counterpart, _router);
        // L1 gateway must have a router
        require(_router != address(0), "BAD_ROUTER");
        require(_inbox != address(0), "BAD_INBOX");
        inbox = _inbox;
    }

    /**
     * @notice Finalizes a withdrawal via Outbox message; callable only by L2Gateway.outboundTransfer
     * @param _token L1 address of token being withdrawn from
     * @param _from initiator of withdrawal
     * @param _to address the L2 withdrawal call set as the destination.
     * @param _amount Token amount being withdrawn
     * @param _data encoded exitNum (Sequentially increasing exit counter determined by the L2Gateway) and additinal hook data
     */
    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable virtual override onlyCounterpartGateway returns (bytes memory) {
        (uint256 exitNum, bytes memory callHookData) = parseInboundData(_data);

        (_to, callHookData) = getExternalCall(exitNum, _to, callHookData);

        if (callHookData.length > 0) {
            bool success;
            try this.inboundEscrowAndCall(_token, _amount, _from, _to, callHookData) {
                success = true;
            } catch {
                // if reverted, then credit _from's account
                inboundEscrowTransfer(_token, _from, _amount);
                // success default value is false
            }
            emit TransferAndCallTriggered(success, _from, _to, _amount, callHookData);
        } else {
            inboundEscrowTransfer(_token, _to, _amount);
        }

        emit InboundTransferFinalized(_token, _from, _to, exitNum, _amount, _data);
        return bytes("");
    }

    function gasReserveIfCallRevert() public pure virtual override returns (uint256) {
        // amount of gas necessary to send user tokens in case
        // of the "onTokenTransfer" call consumes all available gas
        return 30000;
    }

    function getExternalCall(
        uint256 _exitNum,
        address _initialDestination,
        bytes memory _initialData
    ) public view virtual returns (address target, bytes memory data) {
        // current destination can be changed for tradeable exits in a super class
        target = _initialDestination;
        data = _initialData;
    }

    function parseInboundData(bytes calldata _data)
        public
        pure
        virtual
        returns (uint256 _exitNum, bytes memory _extraData)
    {
        // this data is encoded by the counterpart gateway, so this shouldn't revert
        (_exitNum, _extraData) = abi.decode(_data, (uint256, bytes));
    }

    function inboundEscrowTransfer(
        address _l1Token,
        address _dest,
        uint256 _amount
    ) internal virtual override {
        IERC20(_l1Token).safeTransfer(_dest, _amount);
    }

    function createOutboundTx(
        address _l1Token,
        address _from,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        bytes memory _extraData
    ) internal virtual returns (uint256) {
        // msg.value is sent, but 0 is set to the L2 call value
        // the eth sent is used to pay for the tx's gas
        return
            sendTxToL2(
                _from,
                0, // l2 call value 0 by default
                _maxSubmissionCost,
                _maxGas,
                _gasPriceBid,
                getOutboundCalldata(_l1Token, _from, _to, _amount, _extraData)
            );
    }

    function sendTxToL2(
        address _user,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal virtual returns (uint256) {
        return
            sendTxToL2(
                inbox,
                counterpartGateway,
                _user,
                _l2CallValue,
                _maxSubmissionCost,
                _maxGas,
                _gasPriceBid,
                _data
            );
    }

    /**
     * @notice Deposit ERC20 token from Ethereum into Arbitrum. If L2 side hasn't been deployed yet, includes name/symbol/decimals data for initial L2 deploy. Initiate by GatewayRouter.
     * @param _l1Token L1 address of ERC20
     * @param _to account to be credited with the tokens in the L2 (can be the user's L2 account or a contract)
     * @param _amount Token Amount
     * @param _maxGas Max gas deducted from user's L2 balance to cover L2 execution
     * @param _gasPriceBid Gas price for L2 execution
     * @param _data encoded data from router and user
     * @return res abi encoded inbox sequence number
     */
    //  * @param maxSubmissionCost Max gas deducted from user's L2 balance to cover base submission fee
    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) public payable virtual override returns (bytes memory res) {
        address _from;
        uint256 seqNum;
        {
            uint256 _maxSubmissionCost;
            bytes memory extraData;
            (_from, _maxSubmissionCost, extraData) = parseOutboundData(_data);

            require(_l1Token.isContract(), "L1_NOT_CONTRACT");
            address l2Token = _calculateL2TokenAddress(_l1Token);
            require(l2Token != address(0), "NO_L2_TOKEN_SET");

            outboundEscrowTransfer(_l1Token, _from, _amount);

            seqNum = createOutboundTx(
                _l1Token,
                _from,
                _to,
                _amount,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                extraData
            );
        }

        emit OutboundTransferInitiated(_l1Token, _from, _to, seqNum, _amount, _data);
        return abi.encode(seqNum);
    }

    function outboundEscrowTransfer(
        address _l1Token,
        address _from,
        uint256 _amount
    ) internal virtual {
        // escrow funds in gateway
        IERC20(_l1Token).safeTransferFrom(_from, address(this), _amount);
    }

    function parseOutboundData(bytes memory _data)
        internal
        view
        virtual
        returns (
            address _from,
            uint256 _maxSubmissionCost,
            bytes memory _extraData
        )
    {
        if (isRouter(msg.sender)) {
            // router encoded
            (_from, _extraData) = abi.decode(_data, (address, bytes));
        } else {
            _from = msg.sender;
            _extraData = _data;
        }
        // user encoded
        (_maxSubmissionCost, _extraData) = abi.decode(_extraData, (uint256, bytes));
    }

    function getOutboundCalldata(
        address _l1Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) public view virtual override returns (bytes memory outboundCalldata) {
        bytes memory emptyBytes = "";

        outboundCalldata = abi.encodeWithSelector(
            ArbitrumGateway.finalizeInboundTransfer.selector,
            _l1Token,
            _from,
            _to,
            _amount,
            abi.encode(emptyBytes, _data)
        );

        return outboundCalldata;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./IBridge.sol";
import "./IMessageProvider.sol";

interface IInbox is IMessageProvider {
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(uint256 maxSubmissionCost) external payable returns (uint256);

    function bridge() external view returns (IBridge);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "arb-bridge-eth/contracts/bridge/interfaces/IInbox.sol";
import "arb-bridge-eth/contracts/bridge/interfaces/IOutbox.sol";
import "arbos-contracts/arbos/builtin/ArbSys.sol";

abstract contract L1ArbitrumMessenger {
    event TxToL2(address indexed _from, address indexed _to, uint256 indexed _seqNum, bytes _data);

    function sendTxToL2(
        address _inbox,
        address _to,
        address _user,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal virtual returns (uint256) {
        uint256 seqNum =
            IInbox(_inbox).createRetryableTicket{ value: msg.value }(
                _to,
                _l2CallValue,
                _maxSubmissionCost,
                _user,
                _user,
                _maxGas,
                _gasPriceBid,
                _data
            );
        emit TxToL2(_user, _to, seqNum, _data);
        return seqNum;
    }

    function getBridge(address _inbox) internal view virtual returns (IBridge) {
        return IInbox(_inbox).bridge();
    }

    function getL2ToL1Sender(address _inbox) internal view virtual returns (address) {
        IOutbox outbox = IOutbox(getBridge(_inbox).activeOutbox());
        address l2ToL1Sender = outbox.l2ToL1Sender();

        require(l2ToL1Sender != address(0), "NO_SENDER");
        return l2ToL1Sender;
    }
}

abstract contract L2ArbitrumMessenger {
    address internal constant ARB_SYS_ADDRESS = address(100);

    event TxToL1(address indexed _from, address indexed _to, uint256 indexed _id, bytes _data);

    function sendTxToL1(
        uint256 _l1CallValue,
        address _from,
        address _to,
        bytes memory _data
    ) internal virtual returns (uint256) {
        uint256 _id = ArbSys(ARB_SYS_ADDRESS).sendTxToL1{ value: _l1CallValue }(_to, _data);
        emit TxToL1(_from, _to, _id, _data);
        return _id;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "@openzeppelin/contracts/utils/Address.sol";

import "../IERC677.sol";
import "./TokenGateway.sol";

abstract contract ArbitrumGateway is TokenGateway {
    using Address for address;

    event TransferAndCallTriggered(
        bool success,
        address indexed _from,
        address indexed _to,
        uint256 _amount,
        bytes callHookData
    );

    function _initialize(address _counterpartGateway, address _router) internal virtual override {
        TokenGateway._initialize(_counterpartGateway, _router);
    }

    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable virtual override returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable virtual override returns (bytes memory);

    function inboundEscrowAndCall(
        address _l2Address,
        uint256 _amount,
        address _from,
        address _to,
        bytes memory _data
    ) external virtual {
        require(msg.sender == address(this), "Mint can only be called by self");
        require(_to.isContract(), "Destination must be a contract");

        inboundEscrowTransfer(_l2Address, _to, _amount);

        // ~73 000 arbgas used to get here
        uint256 gasAvailable = gasleft() - gasReserveIfCallRevert();
        require(gasleft() > gasAvailable, "Mint and call gas left calculation undeflow");

        IERC677Receiver(_to).onTokenTransfer{ gas: gasAvailable }(_from, _amount, _data);
    }

    function inboundEscrowTransfer(
        address _l2Address,
        address _dest,
        uint256 _amount
    ) internal virtual;

    function gasReserveIfCallRevert() public pure virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

interface IOutbox {
    event OutboxEntryCreated(
        uint256 indexed batchNum,
        uint256 outboxIndex,
        bytes32 outputRoot,
        uint256 numInBatch
    );
    event OutBoxTransactionExecuted(
        address indexed destAddr,
        address indexed l2Sender,
        uint256 indexed outboxIndex,
        uint256 transactionIndex
    );

    function l2ToL1Sender() external view returns (address);

    function l2ToL1Block() external view returns (uint256);

    function l2ToL1EthBlock() external view returns (uint256);

    function l2ToL1Timestamp() external view returns (uint256);

    function processOutgoingMessages(bytes calldata sendsData, uint256[] calldata sendLengths)
        external;
}

pragma solidity >=0.4.21 <0.7.0;

/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
    * @notice Get internal version number identifying an ArbOS build
    * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    function arbChainID() external view returns(uint);

    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */ 
    function arbBlockNumber() external view returns (uint);

    /** 
    * @notice Send given amount of Eth to dest from sender.
    * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
    * @param destination recipient address on L1
    * @return unique identifier for this L2-to-L1 transaction.
    */
    function withdrawEth(address destination) external payable returns(uint);

    /** 
    * @notice Send a transaction to L1
    * @param destination recipient address on L1 
    * @param calldataForL1 (optional) calldata for L1 contract call
    * @return a unique identifier for this L2-to-L1 transaction.
    */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns(uint);

    /** 
    * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
    * @param account target account
    * @return the number of transactions issued by the given external account or the account sequence number of the given contract
    */
    function getTransactionCount(address account) external view returns(uint256);

    /**  
    * @notice get the value of target L2 storage slot 
    * This function is only callable from address 0 to prevent contracts from being able to call it
    * @param account target account
    * @param index target index of storage slot 
    * @return stotage value for the given account at the given index
    */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
    * @notice check if current call is coming from l1
    * @return true if the caller of this was called directly from L1
    */
    function isTopLevelCall() external view returns (bool);

    event EthWithdrawal(address indexed destAddr, uint amount);

    event L2ToL1Transaction(address caller, address indexed destination, uint indexed uniqueId,
                            uint indexed batchNumber, uint indexInBatch,
                            uint arbBlockNum, uint ethBlockNum, uint timestamp,
                            uint callvalue, bytes data);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./ITokenGateway.sol";
import "./IGatewayRouter.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract TokenGateway is ITokenGateway {
    using Address for address;
    address public counterpartGateway;
    address public router;

    modifier onlyCounterpartGateway() virtual {
        require(isCounterpartGateway(msg.sender), "ONLY_COUNTERPART_GATEWAY");
        _;
    }

    function _initialize(address _counterpartGateway, address _router) internal virtual {
        require(_counterpartGateway != address(0), "INVALID_COUNTERPART");
        require(counterpartGateway == address(0), "ALREADY_INIT");
        counterpartGateway = _counterpartGateway;
        router = _router;
    }

    function isRouter(address _target) internal view virtual returns (bool isTargetRouter) {
        return _target == router;
    }

    function isCounterpartGateway(address _target) internal view virtual returns (bool) {
        return _target == counterpartGateway;
    }

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev this always returns the same as the L1 oracle, but may be out of date.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function calculateL2TokenAddress(address l1ERC20)
        external
        view
        virtual
        override
        returns (address)
    {
        // will revert if not called by router
        return _calculateL2TokenAddress(l1ERC20);
    }

    /**
     * @notice Calculate the address used when bridging an ERC20 token
     * @dev this always returns the same as the L1 oracle, but may be out of date.
     * For example, a custom token may have been registered but not deploy or the contract self destructed.
     * @param l1ERC20 address of L1 token
     * @return L2 address of a bridged ERC20 token
     */
    function _calculateL2TokenAddress(address l1ERC20) internal view virtual returns (address);

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable virtual override returns (bytes memory);

    function getOutboundCalldata(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) public view virtual returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable virtual override returns (bytes memory);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

interface ITokenGateway {
    event OutboundTransferInitiated(
        address token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _transferId,
        uint256 _amount,
        bytes _data
    );

    event InboundTransferFinalized(
        address token,
        address indexed _from,
        address indexed _to,
        uint256 indexed _transferId,
        uint256 _amount,
        bytes _data
    );

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable returns (bytes memory);

    function calculateL2TokenAddress(address l1ERC20) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "./ITokenGateway.sol";

interface IGatewayRouter is ITokenGateway {
    function isRouter() external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "@openzeppelin/contracts/utils/Address.sol";
import "arb-bridge-eth/contracts/libraries/BytesLib.sol";

import "../IArbToken.sol";

import { L2ArbitrumMessenger } from "../../libraries/gateway/ArbitrumMessenger.sol";
import "../../libraries/gateway/ArbitrumGateway.sol";

/**
 * @title Common interface for gatways on Arbitrum messaging to L1.
 */
abstract contract L2ArbitrumGateway is L2ArbitrumMessenger, ArbitrumGateway {
    using Address for address;

    uint256 public exitNum;

    function _initialize(address _l1Counterpart, address _router) internal virtual override {
        // L2 gateway may have a router address(0)
        ArbitrumGateway._initialize(_l1Counterpart, _router);
    }

    function gasReserveIfCallRevert() public pure virtual override returns (uint256) {
        // amount of arbgas necessary to send user tokens in case
        // of the "onTokenTransfer" call consumes all available gas
        return 2500;
    }

    function createOutboundTx(
        address _l1Token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _extraData
    ) internal virtual returns (uint256) {
        return sendTxToL1(_from, 0, getOutboundCalldata(_l1Token, _from, _to, _amount, _extraData));
    }

    function sendTxToL1(
        address _from,
        uint256 _l1CallValue,
        bytes memory _data
    ) internal virtual returns (uint256) {
        return sendTxToL1(_l1CallValue, _from, counterpartGateway, _data);
    }

    function getOutboundCalldata(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) public view virtual override returns (bytes memory outboundCalldata) {
        outboundCalldata = abi.encodeWithSelector(
            ArbitrumGateway.finalizeInboundTransfer.selector,
            _token,
            _from,
            _to,
            _amount,
            abi.encode(exitNum, _data)
        );

        return outboundCalldata;
    }

    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) public payable virtual returns (bytes memory) {
        return outboundTransfer(_l1Token, _to, _amount, 0, 0, _data);
    }

    /**
     * @notice Initiates a token withdrawal from Arbitrum to Ethereum
     * @param _l1Token l1 address of token
     * @param _to destination address
     * @param _amount amount of tokens withdrawn
     * @param _maxGas max gas provided for outbox execution market (todo)
     * @param _gasPriceBid provided for outbox execution market (todo)
     @ @return encoded unique identifier for withdrawal
     */

    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) public payable virtual override returns (bytes memory) {
        // can be triggered directly or by router
        require(msg.value == 0, "NO_VALUE");

        (address _from, bytes memory _extraData) = parseOutboundData(_data);

        uint256 id;
        {
            address l2Token = _calculateL2TokenAddress(_l1Token);
            require(l2Token.isContract(), "TOKEN_NOT_DEPLOYED");

            outboundEscrowTransfer(l2Token, _from, _amount);

            id = createOutboundTx(_l1Token, _from, _to, _amount, _extraData);
        }
        // exitNum incremented after being used in createOutboundTx
        exitNum++;
        emit OutboundTransferInitiated(_l1Token, _from, _to, id, _amount, _extraData);
        return abi.encode(id);
    }

    function outboundEscrowTransfer(
        address _l2Token,
        address _from,
        uint256 _amount
    ) internal virtual {
        // burns L2 tokens in order to release escrowed L1 tokens
        IArbToken(_l2Token).bridgeBurn(_from, _amount);
    }

    function parseOutboundData(bytes memory _data)
        internal
        view
        virtual
        returns (address _from, bytes memory _extraData)
    {
        if (isRouter(msg.sender)) {
            (_from, _extraData) = abi.decode(_data, (address, bytes));
        } else {
            _from = msg.sender;
            _extraData = _data;
        }
    }

    function inboundEscrowTransfer(
        address _l2Address,
        address _dest,
        uint256 _amount
    ) internal virtual override {
        IArbToken(_l2Address).bridgeMint(_dest, _amount);
    }

    /**
     * @notice Mint on L2 upon L1 deposit.
     * If token not yet deployed and symbol/name/decimal data is included, deploys StandardArbERC20
     * @dev Callable only by the L1ERC20Gateway.outboundTransfer method. For initial deployments of a token the L1 L1ERC20Gateway
     * is expected to include the deployData. If not a L1 withdrawal is automatically triggered for the user
     * @param _token L1 address of ERC20
     * @param _from account that initiated the deposit in the L1
     * @param _to account to be credited with the tokens in the L2 (can be the user's L2 account or a contract)
     * @param _amount token amount to be minted to the user
     * @param _data encoded symbol/name/decimal data for deploy, in addition to any additional callhook data
     */
    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable virtual override onlyCounterpartGateway returns (bytes memory) {
        (bytes memory gatewayData, bytes memory callHookData) = abi.decode(_data, (bytes, bytes));

        address expectedAddress = _calculateL2TokenAddress(_token);

        if (!expectedAddress.isContract()) {
            bool shouldHalt =
                handleNoContract(_token, expectedAddress, _from, _to, _amount, gatewayData);
            if (shouldHalt) return bytes("");
        }
        // ignores gatewayData if token already deployed

        {
            // validate if L1 address supplied matches that of the expected L2 address
            (bool success, bytes memory _l1AddressData) =
                expectedAddress.staticcall(abi.encodeWithSelector(IArbToken.l1Address.selector));

            bool shouldWithdraw;
            if (!success || _l1AddressData.length < 32) {
                shouldWithdraw = true;
            } else {
                // we do this in the else branch since we want to avoid reverts
                // and `toAddress` reverts if _l1AddressData has a short length
                // `_l1AddressData` should be 12 bytes of padding then 20 bytes for the address
                address expectedL1Address = BytesLib.toAddress(_l1AddressData, 12);
                if (expectedL1Address != _token) {
                    shouldWithdraw = true;
                }
            }

            if (shouldWithdraw) {
                createOutboundTx(_token, address(this), _from, _amount, "");
                return bytes("");
            }
        }

        if (callHookData.length > 0) {
            bool success;
            try this.inboundEscrowAndCall(expectedAddress, _amount, _from, _to, callHookData) {
                success = true;
            } catch {
                // if reverted, then credit _from's account
                inboundEscrowTransfer(expectedAddress, _from, _amount);
                // success default value is false
            }
            emit TransferAndCallTriggered(success, _from, _to, _amount, callHookData);
        } else {
            inboundEscrowTransfer(expectedAddress, _to, _amount);
        }

        emit InboundTransferFinalized(
            _token,
            _from,
            _to,
            uint256(uint160(expectedAddress)),
            _amount,
            _data
        );

        return bytes("");
    }

    // returns if function should halt after
    function handleNoContract(
        address _l1Token,
        address expectedL2Address,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory gatewayData
    ) internal virtual returns (bool shouldHalt);
}

// SPDX-License-Identifier: MIT

/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */

pragma solidity ^0.6.11;

/* solhint-disable no-inline-assembly */
library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= (_start + 20), "Read out of bounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= (_start + 1), "Read out of bounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= (_start + 32), "Read out of bounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }
}
/* solhint-enable no-inline-assembly */

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "arb-bridge-eth/contracts/libraries/Whitelist.sol";

import { L1ArbitrumMessenger } from "../../libraries/gateway/ArbitrumMessenger.sol";
import "../../libraries/gateway/GatewayRouter.sol";
import "../../arbitrum/gateway/L2GatewayRouter.sol";

/**
 * @title Handles deposits from Erhereum into Arbitrum. Tokens are routered to their appropriate L1 gateway (Router itself also conforms to the Gateway itnerface).
 * @notice Router also serves as an L1-L2 token address oracle.
 */
contract L1GatewayRouter is WhitelistConsumer, L1ArbitrumMessenger, GatewayRouter {
    address public owner;
    address public inbox;

    modifier onlyOwner {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    function initialize(
        address _owner,
        address _defaultGateway,
        address _whitelist,
        address _counterpartGateway,
        address _inbox
    ) public virtual {
        GatewayRouter._initialize(_counterpartGateway, _defaultGateway);
        owner = _owner;
        WhitelistConsumer.whitelist = _whitelist;
        inbox = _inbox;
    }

    function sendTxToL2(
        address _user,
        uint256 _l2CallValue,
        uint256 _maxSubmissionCost,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes memory _data
    ) internal virtual returns (uint256) {
        return
            L1ArbitrumMessenger.sendTxToL2(
                inbox,
                counterpartGateway,
                _user,
                _l2CallValue,
                _maxSubmissionCost,
                _maxGas,
                _gasPriceBid,
                _data
            );
    }

    function setDefaultGateway(
        address newL1DefaultGateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable virtual onlyOwner returns (uint256) {
        defaultGateway = newL1DefaultGateway;

        emit DefaultGatewayUpdated(newL1DefaultGateway);

        address l2NewDefaultGateway;

        if (newL1DefaultGateway != address(0)) {
            l2NewDefaultGateway = TokenGateway(newL1DefaultGateway).counterpartGateway();
        }

        bytes memory data =
            abi.encodeWithSelector(L2GatewayRouter.setDefaultGateway.selector, l2NewDefaultGateway);

        return sendTxToL2(msg.sender, 0, _maxSubmissionCost, _maxGas, _gasPriceBid, data);
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        // set newOwner to address(1) to disable owner and keep `initialize` safe
        owner = newOwner;
    }

    function _setGateways(
        address[] memory _token,
        address[] memory _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress
    ) internal returns (uint256) {
        require(_token.length == _gateway.length, "WRONG_LENGTH");

        for (uint256 i = 0; i < _token.length; i++) {
            l1TokenToGateway[_token[i]] = _gateway[i];
            emit GatewaySet(_token[i], _gateway[i]);
            // overwrite memory so the L2 router receives the L2 address of each gateway
            if (_gateway[i] != address(0)) {
                _gateway[i] = TokenGateway(_gateway[i]).counterpartGateway();
            }
        }

        bytes memory data =
            abi.encodeWithSelector(L2GatewayRouter.setGateway.selector, _token, _gateway);

        return sendTxToL2(_creditBackAddress, 0, _maxSubmissionCost, _maxGas, _gasPriceBid, data);
    }

    /**
     * @notice Allows L1 Token contract to trustlessly register its gateway. (other setGateway method allows excess eth recovery from _maxSubmissionCost and is recommended)

     * @param _gateway l1 gateway address
     * @param _maxGas max gas for L2 retryable exrecution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @return Retryable ticket ID
     */
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable returns (uint256) {
        return setGateway(_gateway, _maxGas, _gasPriceBid, _maxSubmissionCost, msg.sender);
    }

    /**
     * @notice Allows L1 Token contract to trustlessly register its gateway.

     * @param _gateway l1 gateway address
     * @param _maxGas max gas for L2 retryable exrecution
     * @param _gasPriceBid gas price for L2 retryable ticket
     * @param  _maxSubmissionCost base submission cost  L2 retryable tick3et
     * @param _creditBackAddress address for crediting back overpayment of _maxSubmissionCost
     * @return Retryable ticket ID
     */
    function setGateway(
        address _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost,
        address _creditBackAddress
    ) public payable returns (uint256) {
        require(address(msg.sender).isContract(), "NOT_FROM_CONTRACT");
        require(_gateway.isContract(), "NOT_TO_CONTRACT");

        address[] memory _tokenArr = new address[](1);
        _tokenArr[0] = address(msg.sender);

        address[] memory _gatewayArr = new address[](1);
        _gatewayArr[0] = _gateway;

        return
            _setGateways(
                _tokenArr,
                _gatewayArr,
                _maxGas,
                _gasPriceBid,
                _maxSubmissionCost,
                _creditBackAddress
            );
    }

    function setGateways(
        address[] memory _token,
        address[] memory _gateway,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        uint256 _maxSubmissionCost
    ) external payable onlyOwner returns (uint256) {
        // it is assumed that token and gateway are both contracts
        // require(_token[i].isContract() && _gateway[i].isContract(), "NOT_CONTRACT");
        return
            _setGateways(_token, _gateway, _maxGas, _gasPriceBid, _maxSubmissionCost, msg.sender);
    }

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) public payable virtual override onlyWhitelisted returns (bytes memory) {
        // will revert if msg.sender is not whitelisted
        super.outboundTransfer(_token, _to, _amount, _maxGas, _gasPriceBid, _data);
    }

    function isCounterpartGateway(address _target) internal view virtual override returns (bool) {
        // don't expect messages from L2 router
        return false;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "@openzeppelin/contracts/utils/Address.sol";
import "./TokenGateway.sol";
import "./IGatewayRouter.sol";

/**
 * @title Common interface for L1 and L2 Gateway Routers
 */
abstract contract GatewayRouter is TokenGateway, IGatewayRouter {
    using Address for address;

    address internal constant ZERO_ADDR = address(0);
    address internal constant BLACKLISTED = address(1);

    mapping(address => address) public l1TokenToGateway;
    address public defaultGateway;

    event TransferRouted(
        address indexed token,
        address indexed _userFrom,
        address indexed _userTo,
        address gateway
    );

    event GatewaySet(address indexed l1Token, address indexed gateway);
    event DefaultGatewayUpdated(address newDefaultGateway);

    function _initialize(address _counterpartGateway, address _defaultGateway)
        internal
        virtual
        override
    {
        TokenGateway._initialize(_counterpartGateway, address(0));
        defaultGateway = _defaultGateway;
    }

    function isRouter() external view override returns (bool) {
        return true;
    }

    function finalizeInboundTransfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) external payable virtual override(TokenGateway, ITokenGateway) returns (bytes memory) {
        revert("ONLY_OUTBOUND_ROUTER");
    }

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _maxGas,
        uint256 _gasPriceBid,
        bytes calldata _data
    ) public payable virtual override(TokenGateway, ITokenGateway) returns (bytes memory) {
        address gateway = getGateway(_token);
        bytes memory gatewayData = getOutboundCalldata(_token, msg.sender, _to, _amount, _data);

        emit TransferRouted(_token, msg.sender, _to, gateway);
        return
            ITokenGateway(gateway).outboundTransfer{ value: msg.value }(
                _token,
                _to,
                _amount,
                _maxGas,
                _gasPriceBid,
                gatewayData
            );
    }

    function getOutboundCalldata(
        address _token,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) public view virtual override returns (bytes memory) {
        return abi.encode(_from, _data);
    }

    function isRouter(address _target) internal view virtual override returns (bool) {
        // nothing routes to gateway router
        return false;
    }

    function getGateway(address _token) public view virtual returns (address gateway) {
        gateway = l1TokenToGateway[_token];
        require(gateway != BLACKLISTED, "BLACKLIST");

        if (gateway == ZERO_ADDR) {
            gateway = defaultGateway;
        }

        require(gateway.isContract(), "NO_GATEWAY_DEPLOYED");

        return gateway;
    }

    function _calculateL2TokenAddress(address l1ERC20)
        internal
        view
        virtual
        override
        returns (address)
    {
        return TokenGateway(getGateway(l1ERC20)).calculateL2TokenAddress(l1ERC20);
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.6.11;

import "../../libraries/gateway/GatewayRouter.sol";
import "../../ethereum/gateway/L1GatewayRouter.sol";

/**
 * @title Handles withdrawals from Ethereum into Arbitrum. Tokens are routered to their appropriate L2 gateway (Router itself also conforms to the Gateway interface).
 * @notice Router also serves as an L2-L1 token address oracle.
 */
contract L2GatewayRouter is GatewayRouter {
    function initialize(address _counterpartGateway, address _defaultGateway) public virtual {
        GatewayRouter._initialize(_counterpartGateway, _defaultGateway);
    }

    function setGateway(address[] memory _l1Token, address[] memory _gateway)
        external
        virtual
        onlyCounterpartGateway
    {
        // counterpart gateway (L1 router) should never allow wrong lengths
        assert(_l1Token.length == _gateway.length);

        for (uint256 i = 0; i < _l1Token.length; i++) {
            l1TokenToGateway[_l1Token[i]] = _gateway[i];
            emit GatewaySet(_l1Token[i], _gateway[i]);
        }
    }

    function outboundTransfer(
        address _l1Token,
        address _to,
        uint256 _amount,
        bytes calldata _data
    ) public payable virtual returns (bytes memory) {
        return outboundTransfer(_l1Token, _to, _amount, 0, 0, _data);
    }

    function setDefaultGateway(address newL2DefaultGateway)
        external
        virtual
        onlyCounterpartGateway
    {
        defaultGateway = newL2DefaultGateway;
        emit DefaultGatewayUpdated(newL2DefaultGateway);
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./ISubredditPoints.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./Compress.sol";

/*
    Implements logic to mint points every round and tracks points receivers such as shared owners
    (get's cut from all minted points), users rounds and their account IDs
*/

contract Distributions is Initializable, OwnableUpgradeable {

    struct SharedOwner {
        address account;
        uint256 percent; // e.g. 30% percent = 30 * percentPrecision/100
    }

    struct DistributionRound {
        uint256 availablePoints;
        uint256 sharedOwnersAvailablePoints;
        uint256 totalKarma;
    }

    event SharedOwnerUpdated(
        address indexed _from,
        address indexed _to,
        uint256 _percent
    );

    event AdvanceRound(uint256 round, uint256 totalPoints, uint256 sharedOwnersPoints);
    event ClaimPoints(uint256 round, address indexed user, uint256 karma, uint256 points);
    event KarmaSourceUpdated(address karmaSource, address prevKarmaSource);
    event SupplyDecayPercentUpdated(uint256 supplyDecayPercent);
    event RoundsBeforeExpirationUpdated(uint256 roundsBeforeExpiration);
    event AccountRegistered(address indexed user, uint256 indexed accountId);

    enum AirdropBatchType {ACCOUNTS, ADDRESSES, GROUPED_ACCOUNTS, GROUPED_ADDRESSES}

    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using BytesLib for bytes;
    using Compress for bytes;

    // ------------------------------------------------------------------------------------
    // VARIABLES BLOCK, MAKE SURE ONLY ADD TO THE END

    ISubredditPoints public subredditPoints;
    address public karmaSource;
    string public subreddit;
    string internal _subredditLowerCase;
    uint256 public lastRound;
    // maps round number to round data
    mapping(uint256 => DistributionRound) internal _distributionRounds;
    // maps account to next claimable round
    mapping(address => uint256) internal _claimableRounds;

    // when sharing percentage, the least possible share is 1/percentPrecision
    uint256 public constant PERCENT_PRECISION = 1000000;
    uint256 public constant MAX_ROUND_SUPPLY = 10 ** 11 * 10 ** 18; // max is 100 bln, to prevent overflows

    // 1 shared owner ~ 35k gas + 250k gas for other ops in advanceToRound
    // so we limit to (8M - 250k)/35k = 221 maximum shared owners
    uint256 public constant MAX_SHARED_OWNERS = 200;

    uint256 public initialSupply;
    uint256 public roundsBeforeExpiration;
    uint256 public nextSupply;
    uint256 public supplyDecayPercent;

    // those owners if exists will get proportion of minted points according to value in percentage
    SharedOwner[] public sharedOwners;
    uint256 internal _prevRoundSupply;       // supply in a prev round
    uint256 internal _prevClaimed;           // total claimed in a prev round

    // Previous karmaSource signer. Used when rotating karmaSource key to enable
    // previous signer to still be valid for a while.
    address public prevKarmaSource;

    // maps account addresses to account ids
    mapping(uint256 => address) internal _accountAddresses;
    mapping(address => uint256) internal _accountIds;
    uint256 internal _lastAccountId;

    // END OF VARS
    // ------------------------------------------------------------------------------------


    function initialize(
        address owner_,
        address subredditPoints_, // ISubredditPoints + IERC20 token contract address
        address karmaSource_, // Karma source provider address

        uint256 initialSupply_,
        uint256 nextSupply_,
        uint256 initialKarma_,
        uint256 roundsBeforeExpiration_, // how many rounds are passed before claiming is possible
        uint256 supplyDecayPercent_, // defines percentage of next rounds' supply from the current
        address[] calldata sharedOwners_,
        uint256[] calldata sharedOwnersPercs_           // index of percentages must correspond to _sharedOwners array
    ) public initializer {
        require(initialSupply_ <= MAX_ROUND_SUPPLY, "Distributions: initial supply should be <= MAX_ROUND_SUPPLY");
        require(initialKarma_ > 0, "Distributions: initial karma should be more than 0");
        require(nextSupply_ > 0 && nextSupply_ <= MAX_ROUND_SUPPLY, "Distributions: nextSupply should be > 0 and <= MAX_ROUND_SUPPLY");
        require(karmaSource_ != address(0), "Distributions: karma source should not be 0");
        require(owner_ != address(0), "Distributions: owner should not be 0");
        require(sharedOwners_.length == sharedOwnersPercs_.length, "Distributions: shared owners addresses array must be same length as percentages");
        require(subredditPoints_ != address(0), "Distributions: subredditPoints should not be 0");

        OwnableUpgradeable.__Ownable_init();
        if (owner_ != _msgSender()) {
            OwnableUpgradeable.transferOwnership(owner_);
        }
        _updateSupplyDecayPercent(supplyDecayPercent_);
        _updateRoundsBeforeExpiration(roundsBeforeExpiration_);

        subredditPoints = ISubredditPoints(subredditPoints_);
        subreddit = subredditPoints.subreddit();
        karmaSource = karmaSource_;
        prevKarmaSource = karmaSource_;
        _subredditLowerCase = _toLower(subreddit);

        initialSupply = initialSupply_;
        nextSupply = nextSupply_;

        for (uint i = 0; i < sharedOwners_.length; i++) {
            _updateSharedOwner(sharedOwners_[i], sharedOwnersPercs_[i]);
        }

        if (initialSupply > 0) {
            uint256 sharedOwnersPoints = calcSharedOwnersAvailablePoints(initialSupply);
            _distributionRounds[0] = DistributionRound({
            availablePoints : initialSupply,
            sharedOwnersAvailablePoints : sharedOwnersPoints,
            totalKarma : initialKarma_
            });

            emit AdvanceRound(0, initialSupply, sharedOwnersPoints);
        }
    }

    function claim(uint256 round, address account, uint256 karma, bytes calldata signature) virtual external {
        address signedBy = verifySignature(account, round, karma, signature);
        require(signedBy == karmaSource || (prevKarmaSource != address(0) && signedBy == prevKarmaSource), "Distributions: claim is not signed by the karma source");

        _mintRound(round, account, karma);
    }

    /* airdrop input format:

        [ ROUND | BATCH 0 … BATCH X ]
        Round is a compressed number, and the batch is:

        [ BATCH_HEADER | BATCH BODY ]
        Where BATCH_HEADER = N * 4 + BATCH_TYPE encoded as a compressed number, which is an equivalent of bit mask:
            +------------+------------+
            |    X-2     |    1-0     |
            +------------+------------+
            | BATCH_SIZE | BATCH_TYPE |
            +------------+------------+

        N is the amount of airdrop records packed within a body and
        BATCH_TYPE is a number 0-3 and defines a batch body:
            AirdropBatchType.ACCOUNTS (0) = [ ACCOUNT_ID 0 | KARMA 0 ... ACCOUNT_ID N-1 | KARMA N-1 ]
            AirdropBatchType.ADDRESSES (1) = [ ADDRESS 0 | KARMA 0 ... ADDRESS N-1 | KARMA N-1 ]
            AirdropBatchType.GROUPED_ACCOUNTS (2) = [ KARMA | ACCOUNT_ID 0 ... ACCOUNT_ID N-1 ]
            AirdropBatchType.GROUPED_ADDRESSES (3) = [ KARMA | ADDRESS 0 ... ADDRESS N-1 ]

        ACCOUNT_ID, KARMA are compressed numbers and ADDRESS is full 20 bytes address.
        Types 2 and 3 are accounts grouped by KARMA, and within a group they all have the same
        amount of karma within a round.
    */

    function airdrop(bytes calldata input) virtual external {
        require(_msgSender() == karmaSource || (prevKarmaSource != address(0) && _msgSender() == prevKarmaSource), "Distributions: airdrop can be only called by karma source");

        uint256 ptr = 0;
        uint256 round;
        (round, ptr) = input.decompressUint256(ptr);

        require(ptr < input.length, "Distributions: airdrop is empty");

        while (ptr < input.length) {
            uint256 batchHeader;
            (batchHeader, ptr) = input.decompressUint256(ptr);
            AirdropBatchType batchType = AirdropBatchType(uint8(batchHeader) & 0x3);
            uint256 batchSize = batchHeader >> 2;
            require(batchSize > 0, "Distributions: airdrop batch is empty");

            if (batchType == AirdropBatchType.ACCOUNTS) {
                ptr = airdropToAccounts(round, ptr, batchSize, input);
            } else if (batchType == AirdropBatchType.ADDRESSES) {
                ptr = airdropToAddresses(round, ptr, batchSize, input);
            } else if (batchType == AirdropBatchType.GROUPED_ACCOUNTS) {
                ptr = airdropToGroupedAccounts(round, ptr, batchSize, input);
            } else if (batchType == AirdropBatchType.GROUPED_ADDRESSES) {
                ptr = airdropToGroupedAddresses(round, ptr, batchSize, input);
            } else {
                revert("Distributions: unknown airdrop batch type");
                // shouldn't happen
            }
        }
    }

    // format is [ ACCOUNT_ID 0 | KARMA 0 ... ACCOUNT_ID N-1 | KARMA N-1 ]
    function airdropToAccounts(uint256 round, uint256 ptr, uint256 batchSize, bytes calldata input) internal returns (uint256) {
        for (uint256 i = 0; i < batchSize; i++) {
            uint256 accountId;
            (accountId, ptr) = input.decompressUint256(ptr);
            address account = addressOf(accountId);
            require(account != address(0), "Distributions: account id not found");

            uint256 karma;
            (karma, ptr) = input.decompressUint256(ptr);

            _mintRound(round, account, karma);
        }
        return ptr;
    }

    // format is [ ADDRESS 0 | KARMA 0 ... ADDRESS N-1 | KARMA N-1 ]
    function airdropToAddresses(uint256 round, uint256 ptr, uint256 batchSize, bytes calldata input) internal returns (uint256)  {
        for (uint256 i = 0; i < batchSize; i++) {
            address account = input.toAddress(ptr);
            require(account != address(0), "Distributions: account id not found");
            ptr += 20;
            // size of address

            uint256 karma;
            (karma, ptr) = input.decompressUint256(ptr);

            _mintRound(round, account, karma);
        }
        return ptr;
    }

    // format is [ KARMA | ACCOUNT_ID 0 ... ACCOUNT_ID N-1 ]
    function airdropToGroupedAccounts(uint256 round, uint256 ptr, uint256 batchSize, bytes calldata input) internal returns (uint256)  {
        uint256 karma;
        (karma, ptr) = input.decompressUint256(ptr);

        for (uint256 i = 0; i < batchSize; i++) {
            uint256 accountId;
            (accountId, ptr) = input.decompressUint256(ptr);
            address account = addressOf(accountId);
            require(account != address(0), "Distributions: account id not found");
            _mintRound(round, account, karma);
        }
        return ptr;
    }

    // format is [ KARMA | ADDRESS 0 ... ADDRESS N-1 ]
    function airdropToGroupedAddresses(uint256 round, uint256 ptr, uint256 batchSize, bytes calldata input) internal returns (uint256)  {
        uint256 karma;
        (karma, ptr) = input.decompressUint256(ptr);

        for (uint256 i = 0; i < batchSize; i++) {
            address account = input.toAddress(ptr);
            require(account != address(0), "Distributions: account id not found");
            ptr += 20;
            // size of address
            _mintRound(round, account, karma);
        }
        return ptr;
    }

    function _mintRound(uint256 round, address account, uint256 karma) internal {
        require(account != address(0), "Distributions: address should not be 0");
        require(karma > 0, "Distributions: karma should be > 0");
        require(_claimableRounds[account] <= round, "Distributions: this rounds points are already claimed");
        require(round <= lastRound, "Distributions: too early to claim this round");
        uint256 earliest = claimableRoundOf(account);
        require(round >= earliest, "Distributions: too late to claim this round");
        require(earliest == 0 || round == earliest || _msgSender() == account || _msgSender() == karmaSource,
            "Distributions: only owner can claim round that's not earliest");

        DistributionRound memory dr = _distributionRounds[round];
        require(dr.availablePoints > 0, "Distributions: no points to claim in this round");
        require(dr.totalKarma > 0, "Distributions: this round has no karma");
        uint256 userPoints = dr.availablePoints
        .sub(dr.sharedOwnersAvailablePoints)
        .mul(karma)
        .div(dr.totalKarma);
        require(userPoints > 0, "Distributions: user karma is too low to claim points");
        _prevClaimed = _prevClaimed.add(userPoints);
        _claimableRounds[account] = round.add(1);
        _registerAccount(account);
        emit ClaimPoints(round, account, karma, userPoints);
        subredditPoints.mint(address(this), account, userPoints, "", "");
    }

    // corresponding _distributionRounds mappings are added with
    //  + every next distribution supply is `previous - decay` and stored in nextSupply
    //  + distributed 50% of burned points in a previous round
    // rounds are removed if they are not claimable anymore
    function advanceToRound(uint256 round, uint256 totalKarma) virtual external {
        require(round == lastRound.add(1), "Distributions: round should be incrementally increasing");
        require(totalKarma > 0, "Distributions: totalKarma should be > 0");
        require(_msgSender() == karmaSource, "Distributions: only karma source can advance rounds");
        uint256 mc = minClaimableRound();

        if (mc > 0) {
            // delete non claimable round data
            delete (_distributionRounds[mc-1]);
        }

        uint256 ts = IERC20Upgradeable(address(subredditPoints)).totalSupply();
        uint256 prevClaimedCopy = _prevClaimed;

        // get round points
        uint256 roundPoints = nextSupply;
        // reintroduce 50 % of previously burned tokens
        uint256 ps = _prevRoundSupply.add(_prevClaimed);
        if (ps > ts) {
            roundPoints = roundPoints.add(ps.sub(ts).div(2));
        }

        // decay next supply
        if (nextSupply > 0 && supplyDecayPercent > 0) {
            nextSupply = nextSupply.sub(nextSupply.mul(supplyDecayPercent).div(PERCENT_PRECISION));
        }

        // set distribution round data for this round
        uint256 sharedOwnersPoints = 0;
        if (roundPoints > 0) {
            sharedOwnersPoints = calcSharedOwnersAvailablePoints(roundPoints);
            _distributionRounds[round] = DistributionRound({
            availablePoints : roundPoints,
            sharedOwnersAvailablePoints : sharedOwnersPoints,
            totalKarma : totalKarma
            });
        }

        emit AdvanceRound(round, roundPoints, sharedOwnersPoints);

        lastRound = round;
        _prevRoundSupply = ts;
        _prevClaimed = 0;

        // distribute shared cut, but no more than it was claimed by users
        // this protects from exceeding total amount by increasing percentage between rounds
        if (sharedOwnersPoints > 0 && prevClaimedCopy > 0) {
            uint256 totalSharedPercent;
            for (uint256 i = 0; i < sharedOwners.length; i++) {
                totalSharedPercent = totalSharedPercent.add(sharedOwners[i].percent);
            }

            uint256 claimedPlusShared = prevClaimedCopy
            .mul(PERCENT_PRECISION)
            .div(PERCENT_PRECISION.sub(totalSharedPercent));

            uint256 sharedLeft = claimedPlusShared.sub(prevClaimedCopy);

            for (uint256 i = 0; i < sharedOwners.length && sharedLeft > 0; i++) {
                uint256 ownerPoints = claimedPlusShared.mul(sharedOwners[i].percent).div(PERCENT_PRECISION);
                if (ownerPoints > 0 && ownerPoints <= sharedLeft) {
                    // ensure we add owners points to our count of points minted for this round
                    _prevClaimed = _prevClaimed.add(ownerPoints);
                    subredditPoints.mint(address(this), sharedOwners[i].account, ownerPoints, "", "");
                    sharedLeft = sharedLeft.sub(ownerPoints);
                }
            }
        }
    }

    function totalSharedOwners() external view returns (uint256) {
        return sharedOwners.length;
    }

    function updateSupplyDecayPercent(uint256 _supplyDecayPercent) external onlyOwner {
        _updateSupplyDecayPercent(_supplyDecayPercent);
    }

    function _updateSupplyDecayPercent(uint256 _supplyDecayPercent) internal {
        require(_supplyDecayPercent < PERCENT_PRECISION, "Distributions: supplyDecayPercent should be < PERCENT_PRECISION");
        supplyDecayPercent = _supplyDecayPercent;
        emit SupplyDecayPercentUpdated(_supplyDecayPercent);
    }

    function updateRoundsBeforeExpiration(uint256 _roundsBeforeExpiration) external onlyOwner {
        _updateRoundsBeforeExpiration(_roundsBeforeExpiration);
    }

    function _updateRoundsBeforeExpiration(uint256 _roundsBeforeExpiration) internal {
        roundsBeforeExpiration = _roundsBeforeExpiration;
        emit RoundsBeforeExpirationUpdated(_roundsBeforeExpiration);
    }

    function minClaimableRound() public view returns (uint256) {
        if (lastRound >= roundsBeforeExpiration) {
            return lastRound.sub(roundsBeforeExpiration);
        }
        return 0;
    }

    function verifySignature(address account, uint256 round, uint256 karma, bytes memory signature)
    internal view returns (address) {

        bytes32 hash = keccak256(abi.encode(_subredditLowerCase, uint256(round), account, karma));
        bytes32 prefixedHash = ECDSAUpgradeable.toEthSignedMessageHash(hash);
        return ECDSAUpgradeable.recover(prefixedHash, signature);
    }

    function calcSharedOwnersAvailablePoints(uint256 points) internal view returns (uint256) {
        uint256 r;
        for (uint256 i = 0; i < sharedOwners.length; i++) {
            r = r.add(calcSharedPoints(points, sharedOwners[i]));
        }
        return r;
    }

    function calcSharedPoints(uint256 points, SharedOwner memory sharedOwner) internal pure returns (uint256) {
        return points
        .mul(sharedOwner.percent)
        .div(PERCENT_PRECISION);
    }

    function updateKarmaSource(address _karmaSource) external onlyOwner {
        require(_karmaSource != address(0), "Distributions: karma source should not be 0");
        prevKarmaSource = karmaSource;
        karmaSource = _karmaSource;
        emit KarmaSourceUpdated(_karmaSource, prevKarmaSource);
    }

    // shared owners get their points 1 round later within advancement
    // increasing total shared percentage can lead to some of the owners not receiving their cut within a next round
    function updateSharedOwner(address account, uint256 percent) external onlyOwner {
        _updateSharedOwner(account, percent);
    }

    function _updateSharedOwner(address account, uint256 percent) internal {
        require(percent < PERCENT_PRECISION, "Distributions: shared owners percent should be < percentPrecision");
        require(percent > 0 && sharedOwners.length < MAX_SHARED_OWNERS, "Distributions: shared owners limit reached, see MAX_SHARED_OWNERS");

        bool updated = false;

        for (uint256 i = 0; i < sharedOwners.length; i++) {
            SharedOwner memory so = sharedOwners[i];
            if (so.account == account) {
                if (percent == 0) {
                    if (i != (sharedOwners.length - 1)) {// if it's not last element, replace it from the tail
                        sharedOwners[i] = sharedOwners[sharedOwners.length - 1];
                    }
                    // remove tail
                    sharedOwners.pop();
                } else {
                    sharedOwners[i].percent = percent;
                }
                updated = true;
            }
        }

        if (!updated) {
            if (percent == 0) {
                return;
            }
            sharedOwners.push(SharedOwner(account, percent));
        }

        checkSharedPercentage();
        // allow to update sharedOwnersAvailablePoints for a rounds which aren't claimed yet
        DistributionRound storage dr = _distributionRounds[lastRound];
        if (_prevClaimed == 0 && dr.availablePoints > 0) {
            dr.sharedOwnersAvailablePoints = calcSharedOwnersAvailablePoints(dr.availablePoints);
        }
        emit SharedOwnerUpdated(_msgSender(), account, percent);
    }

    function checkSharedPercentage() internal view {
        uint256 total;
        for (uint256 i = 0; i < sharedOwners.length; i++) {
            total = sharedOwners[i].percent.add(total);
        }
        require(total < PERCENT_PRECISION, "Distributions: can't share all 100% of points");
    }

    function percentPrecision() external pure returns (uint256) {
        return PERCENT_PRECISION;
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((int8(bStr[i]) >= 65) && (int8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(int8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function claimableRoundOf(address account) public view returns (uint256) {
        uint256 mc = minClaimableRound();
        if (mc > _claimableRounds[account]) {
            return mc;
        }
        return _claimableRounds[account];
    }

    function addressOf(uint256 accountId) public view returns (address) {
        return _accountAddresses[accountId];
    }

    function accountIdOf(address account) public view returns (uint256) {
        return _accountIds[account];
    }

    function _registerAccount(address account) internal {
        if (_accountIds[account] == 0) {
            _lastAccountId+=1;
            _accountIds[account] = _lastAccountId;
            _accountAddresses[_lastAccountId] = account;
            emit AccountRegistered(account, _lastAccountId);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.7.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes_slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes_slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes_slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_start + 2 >= _start, "toUint16_overflow");
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_start + 4 >= _start, "toUint32_overflow");
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_start + 8 >= _start, "toUint64_overflow");
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_start + 12 >= _start, "toUint96_overflow");
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_start + 16 >= _start, "toUint128_overflow");
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_start + 32 >= _start, "toUint256_overflow");
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_start + 32 >= _start, "toBytes32_overflow");
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes_slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "solidity-bytes-utils/contracts/BytesLib.sol";

library Compress {
    using BytesLib for bytes;

    /*
        Compressed unsigned integer numbers have format:
            [ TYPE | VALUE ]

            Where TYPE is the sequence of highest bits of the first byte.

           1. TYPE = 0 (highest bit), 1 byte
               Lower 7 bits of the byte represents an integer

               examples:
               0 = 0 (min)
               127 = 127 (0x7F, max for 1 byte)

           2. TYPE = 10 (highest bits), 2 bytes
                Lower 6 bits of the byte and the following byte = an integer, total 14 bits.
                To the resulting number offset is added: 0x80 (1 + maximum of TYPE=0)

                examples:
                0x8000 = 128 (0x80, min for type)
                0xBFFF = 16511 (0x407F, max for type)

           3. TYPE = 11 (highest bits), dynamic length

                Next 5 bits of the byte = (length in bytes - 1) of the number following the type.
                If all 5 bits of length = 0, then 1 byte.
                If all bits = 1 (decimal 31) then 32 bytes are following (uint256)

                Lowest 1 bit is also used as the lowest bit of an encoded number.

                0 byte format:
                [ B B L L L L L S ]

                BB - is a constant value of the compression type 11
                LLLLL - is the length in bytes following, 0 means 32 bytes
                S - is used as part of number (highest bit)
                When a full 32 bytes number is encoded, extra bit S is ignored and lost.

        Returned result is encoded number and pointer to next byte
    */
    function decompressUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256, uint256) {
        if (_bytes.length == 0) {
            revert("decompressUint256: out of bounds");
        }
        uint8 first = _bytes.toUint8(_start);

        // TYPE 0
        if (first & 0x80 == 0) {
            uint256 end = _start + 1;
            return (first & 0x7F, 1 + _start);
            validateStartEnd(_bytes, _start, end);
        }

        // TYPE 10
        if (first & 0xC0 == 0x80) {
            uint256 end = _start + 2;
            validateStartEnd(_bytes, _start, end);
            uint256 second = uint256(_bytes.toUint8(_start + 1));
            return (uint256(first & 0x3F) * 0x100 + second + 0x80, end);
        }

        // TYPE 11 (dynamic length)

        // 1-7 bits of first byte = length-1
        uint256 len = ((first & 0x3e) >> 1) + 1;

        uint256 end = _start + len + 1;
        validateStartEnd(_bytes, _start, end);

        uint256 result;
        assembly {
            result := mload(add(add(_bytes, add(len, _start)), 1))
        }

        uint256 mask = (1 << (len * 8 + 1)) - 1;
        return (result & mask, end);
    }

    function validateStartEnd(bytes memory _bytes, uint256 _start, uint256 end) internal pure {
        require(end >= _start, "decompressUint256: overflow");
        require(_bytes.length >= end, "decompressUint256: out of bounds");
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "./Distributions.sol";

/*
    Distribution that used while importing
*/

contract DistributionsImport is Distributions {
    modifier disabledWhileImporting() {
        revert("DistributionsImport: import is in progress");
        _;
    }

    function importInternals(
        uint256 initialSupply_,
        uint256 nextSupply_,
        uint256 lastRound_,
        uint256 prevRoundSupply_,
        uint256 prevClaimed_,
        uint256 roundsBeforeExpiration_,
        uint256 supplyDecayPercent_,
        uint256[] calldata rdAvailablePoints_,
        uint256[] calldata rdSharedOwnersAvailablePoints_,
        uint256[] calldata rdTotalKarma_
    ) external onlyOwner {
        require(initialSupply_ > 0, "DistributionsImport: initialSupply_ should be > 0");

        require(rdAvailablePoints_.length > 0 &&
            rdAvailablePoints_.length == rdSharedOwnersAvailablePoints_.length &&
            rdAvailablePoints_.length == rdTotalKarma_.length,
            "DistributionsImport: rounds data arrays should have equal length and > 0");

        initialSupply = initialSupply_;
        nextSupply = nextSupply_;
        lastRound = lastRound_;
        roundsBeforeExpiration = roundsBeforeExpiration_;
        supplyDecayPercent = supplyDecayPercent_;

        require(lastRound.sub(minClaimableRound()).add(1) == rdAvailablePoints_.length,
            "DistributionsImport: rounds data arrays doesn't have all available rounds data");

        _prevRoundSupply = prevRoundSupply_;
        _prevClaimed = prevClaimed_;

        uint256 round = minClaimableRound();
        for (uint256 i = 0; i < rdAvailablePoints_.length; i++) {
            _distributionRounds[round] = DistributionRound({
                    availablePoints: rdAvailablePoints_[i],
                    sharedOwnersAvailablePoints: rdSharedOwnersAvailablePoints_[i],
                    totalKarma: rdTotalKarma_[i]
                });
            round += 1;
        }
    }

    function importSharedOwners(
        address[] calldata sharedOwners_,
        uint256[] calldata sharedOwnersPercs_
    ) external onlyOwner {
        require(sharedOwners_.length == sharedOwnersPercs_.length, "DistributionsImport: shared owners addresses array must be same length as percentages");

        for (uint i = 0; i < sharedOwners_.length; i++) {
            if (sharedOwners.length <= i) {
                sharedOwners.push(SharedOwner(sharedOwners_[i], sharedOwnersPercs_[i]));
            } else {
                sharedOwners[i] = SharedOwner(sharedOwners_[i], sharedOwnersPercs_[i]);
            }
            emit SharedOwnerUpdated(_msgSender(), sharedOwners_[i], sharedOwnersPercs_[i]);
        }
    }

    function importClaimableRounds(address[] calldata accounts, uint256[] calldata rounds) onlyOwner external {
        require(initialSupply > 0, "DistributionsImport: import internals first");
        require(accounts.length > 0 && accounts.length == rounds.length,
            "DistributionsImport: accounts should have > 0 elements and be equal to rounds");

        uint256 mc = minClaimableRound();

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            require(account != address(0), "DistributionsImport: account should not be address(0)");

            uint256 cr = rounds[i];
            if (cr > mc) {
                _claimableRounds[account] = rounds[i];
            }
            _registerAccount(account);
        }
    }

    function claim(uint256 round, address account, uint256 karma, bytes calldata signature)
        override disabledWhileImporting external { }

    function airdrop(bytes calldata input)
        override disabledWhileImporting external { }

    function advanceToRound(uint256 round, uint256 totalKarma)
        override external disabledWhileImporting { }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "./Distributions.sol";
import "./Frozen.sol";

/*
    Distribution that is frozen (while exporting/migrating)
*/

contract DistributionsFrozen is Distributions, Frozen {
    function claim(uint256 round, address account, uint256 karma, bytes calldata signature)
        override frozen external { }

    function airdrop(bytes calldata input)
        override frozen external { }

    function advanceToRound(uint256 round, uint256 totalKarma)
        override external frozen { }

    // export private data

    function prevRoundSupply() external view returns (uint256) {
        return _prevRoundSupply;
    }

    function prevClaimed() external view returns (uint256) {
        return _prevClaimed;
    }

    function roundAvailablePoints(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].availablePoints;
    }

    function roundSharedOwnersAvailablePoints(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].sharedOwnersAvailablePoints;
    }

    function roundTotalKarma(uint256 round) external view returns (uint256) {
        return _distributionRounds[round].totalKarma;
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "./Compress.sol";


contract TestCompress {
    using Compress for bytes;

    function decompressUint256(bytes calldata _bytes, uint256 _start) external view returns (uint256, uint256) {
        return _bytes.decompressUint256(_start);
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./SubredditPoints.sol";

/*
    SubredditPoints used while importing points
*/

contract SubredditPointsImport is SubredditPoints {
    function importBatch(
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(accounts.length > 0, "accounts has no elements");
        require(accounts.length==amounts.length, "accounts should have same element as amounts");

        for (uint256 i = 0; i < accounts.length; i++) {
            ERC20Upgradeable._mint(accounts[i], amounts[i]);
            emit Minted(_msgSender(), accounts[i], amounts[i], "", "");
        }
    }

    function _beforeTokenTransfer(address, address, uint256) internal override {
        if (_msgSender() != owner()) {
            revert("ERC20 import is in progress");
        }
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "./SubredditPoints.sol";
import "./GSNBaseRelayRecipient.sol";

/*
    Subreddit points with GSN forwarder support
*/

contract SubredditPointsGSN is SubredditPoints, GSNBaseRelayRecipient {
    address public trustedForwarder;

    function initialize(
        address trustedForwarder_,
        address owner_,
        address distributionContract_,
        string calldata subreddit_,
        string calldata name_,
        string calldata symbol_,

        address[] calldata defaultOperators_
    ) public initializer {
        trustedForwarder = trustedForwarder_;
        super.initialize(owner_, distributionContract_, subreddit_, name_, symbol_, defaultOperators_);
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    function updateTrustedForwarder(address trustedForwarder_) external onlyOwner {
        trustedForwarder = trustedForwarder_;
    }

    function _msgSender() internal override(ContextUpgradeable,GSNBaseRelayRecipient) virtual view returns (address payable ret) {
        return GSNBaseRelayRecipient._msgSender();
    }

    function _msgData() internal override(ContextUpgradeable,GSNBaseRelayRecipient) virtual view returns (bytes memory ret) {
        return GSNBaseRelayRecipient._msgData();
    }

    function versionRecipient() external view override returns (string memory) {
		return "0.0.1";
	}
}

// SPDX-License-Identifier: MIT
// adopted from https://github.com/opengsn/gsn/blob/995647ebf8e34ac183d5b99c06c385bc1995d6dd/packages/contracts/src/BaseRelayRecipient.sol
// solhint-disable no-inline-assembly
pragma solidity >=0.6.0;

import "./IGSNRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract GSNBaseRelayRecipient is IGSNRelayRecipient {
    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address payable ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise, return `msg.data`
     * should be used in the contract instead of msg.data, where the difference matters (e.g. when explicitly
     * signing or hashing the
     */
    function _msgData() internal override virtual view returns (bytes memory ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            bytes calldata res = msg.data[0:msg.data.length-20];
            return res;
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
// adopted from https://github.com/opengsn/gsn/blob/master/packages/contracts/src/interfaces/IRelayRecipient.sol
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IGSNRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes memory);

    function versionRecipient() external virtual view returns (string memory);
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "arb-bridge-peripherals/contracts/tokenbridge/ethereum/gateway/L1GatewayRouter.sol";
import "./L1CustomGatewayWithMint.sol";
import "./IEthBridgedToken.sol";

/*
    L1 SubredditPoints ERC20 token, pairable to L2 and supports L1<->L2 withdrawals/deposits
*/

contract EthSubredditPoints is OwnableUpgradeable, ERC20Upgradeable, IEthBridgedToken {
    address public gateway;
    address public override l2Address;

    modifier onlyGateway {
        require(msg.sender == address(gateway), "Call only from gateway");
        _;
    }

    function initialize(address owner_, string calldata name_, string calldata symbol_, address gateway_, address l2Address_)
    external initializer
    {
        require(gateway_ != address(0), "gateway should not be 0");
        require(l2Address_ != address(0), "l2Address should not be 0");

        gateway = gateway_;
        l2Address = l2Address_;

        OwnableUpgradeable.__Ownable_init();
        if (owner_ != _msgSender()) {
            OwnableUpgradeable.transferOwnership(owner_);
        }
        ERC20Upgradeable.__ERC20_init(name_, symbol_);
    }

    function registerTokenToL2(uint256 maxGas, uint256 gasPriceBid, uint256 maxSubmissionCost) external onlyOwner {
        L1CustomGateway(gateway).registerTokenToL2(
            l2Address,
            maxGas / 2,
            gasPriceBid,
            maxSubmissionCost / 2
        );

        address router = L1CustomGatewayWithMint(gateway).router();
        L1GatewayRouter(router).setGateway(gateway,
            maxGas / 2,
            gasPriceBid,
            maxSubmissionCost / 2
        );
    }

    function bridgeMint(address account, uint256 amount) external override onlyGateway {
        _mint(account, amount);
    }

    function bridgeBurn(address account, uint256 amount) external override onlyGateway {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.6.11;

import "arb-bridge-peripherals/contracts/tokenbridge/arbitrum/gateway/L2CustomGateway.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/*
    L2CustomGatewayWithEscrow is arbitrum L2 gateway that escrows tokens to it's own address when they're
    withdrawn to L1 and transfers back when they're deposited
*/

contract L2CustomGatewayWithEscrow is L2CustomGateway {
    using SafeERC20 for IERC20;

    function postUpgradeInit() external {
        // todo: remove method after the upgrade
        router = 0x8eb321696ed3c4b5e8e4beD3994E5D66c7864854;
    }

    function inboundEscrowTransfer(
        address _token,
        address _dest,
        uint256 _amount
    ) internal virtual override {
        IERC20(_token).safeTransfer(_dest, _amount);
    }

    function outboundEscrowTransfer(
        address _token,
        address _from,
        uint256 _amount
    ) internal virtual override {
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
    }
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

/*

This file contains imports for external contracts that we want compile & generate ABIs

*/

pragma solidity ^0.6.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "arb-bridge-peripherals/contracts/tokenbridge/arbitrum/gateway/L2CustomGateway.sol";
import "arbos-contracts/arbos/builtin/ArbRetryableTx.sol";
import "arbos-contracts/arbos/builtin/ArbSys.sol";

pragma solidity >=0.4.21 <0.7.0;

/**
* @title precompiled contract in every Arbitrum chain for retryable transaction related data retrieval and interactions. Exists at 0x000000000000000000000000000000000000006E 
*/
interface ArbRetryableTx {

    /**
    * @notice Redeem a redeemable tx.
    * Revert if called by an L2 contract, or if txId does not exist, or if txId reverts.
    * If this returns, txId has been completed and is no longer available for redemption.
    * If this reverts, txId is still available for redemption (until it times out or is canceled).
    @param txId unique identifier of retryable message: keccak256(keccak256(ArbchainId, inbox-sequence-number), uint(0) )
     */
    function redeem(bytes32 txId) external;

    /** 
    * @notice Return the minimum lifetime of redeemable txn.
    * @return lifetime in seconds
    */
    function getLifetime() external view returns(uint);

    /**
    * @notice Return the timestamp when ticketId will age out, or zero if ticketId does not exist.
    * The timestamp could be in the past, because aged-out tickets might not be discarded immediately.
    * @param ticketId unique ticket identifier
    * @return timestamp for ticket's deadline
    */
    function getTimeout(bytes32 ticketId) external view returns(uint);

    /** 
    * @notice Return the price, in wei, of submitting a new retryable tx with a given calldata size.
    * @param calldataSize call data size to get price of (in wei)
    * @return (price, nextUpdateTimestamp). Price is guaranteed not to change until nextUpdateTimestamp.
    */ 
    function getSubmissionPrice(uint calldataSize) external view returns (uint, uint);

    /** 
     * @notice Return the price, in wei, of extending the lifetime of ticketId by an additional lifetime period. Revert if ticketId doesn't exist.
     * @param ticketId unique ticket identifier
     * @return (price, nextUpdateTimestamp). Price is guaranteed not to change until nextUpdateTimestamp.
    */
    function getKeepalivePrice(bytes32 ticketId) external view returns(uint, uint);

    /** 
    @notice Deposits callvalue into the sender's L2 account, then adds one lifetime period to the life of ticketId.
    * If successful, emits LifetimeExtended event.
    * Revert if ticketId does not exist, or if the timeout of ticketId is already at least one lifetime period in the future, or if the sender has insufficient funds (after the deposit).
    * @param ticketId unique ticket identifier
    * @return New timeout of ticketId.
    */
    function keepalive(bytes32 ticketId) external payable returns(uint);

    /**
    * @notice Return the beneficiary of ticketId.
    * Revert if ticketId doesn't exist.
    * @param ticketId unique ticket identifier
    * @return address of beneficiary for ticket
    */
    function getBeneficiary(bytes32 ticketId) external view returns (address);

    /** 
    * @notice Cancel ticketId and refund its callvalue to its beneficiary.
    * Revert if ticketId doesn't exist, or if called by anyone other than ticketId's beneficiary.
    * @param ticketId unique ticket identifier
    */
    function cancel(bytes32 ticketId) external;

    event TicketCreated(bytes32 indexed ticketId);
    event LifetimeExtended(bytes32 indexed ticketId, uint newTimeout);
    event Redeemed(bytes32 indexed ticketId);
    event Canceled(bytes32 indexed ticketId);
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

import "@openzeppelin/contracts/proxy/ProxyAdmin.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract ProxyAdmin2 is ProxyAdmin {

    event ProxyDeployed(address proxy);

    function deployProxy(bytes32 salt, address impl, bytes calldata args) public returns (address) {
        bytes memory proxyByteCodeWithArgs = _getProxyByteCodeWithArgs(impl, args);
        address proxyAddress = Create2.deploy(0, salt, proxyByteCodeWithArgs);
        emit ProxyDeployed(proxyAddress);
        return proxyAddress;
    }

    function computeProxyAddress(bytes32 salt, address impl, bytes calldata args) public view returns (address) {
        bytes memory proxyByteCodeWithArgs = _getProxyByteCodeWithArgs(impl, args);
        return Create2.computeAddress(salt, keccak256(proxyByteCodeWithArgs));
    }

    function _getProxyByteCodeWithArgs(address impl, bytes calldata args) internal view returns (bytes memory) {
        bytes memory proxyByteCode = type(TransparentUpgradeableProxy).creationCode;
        return abi.encodePacked(proxyByteCode, abi.encode(impl, address(this), args));
    }
}

// adopted from openzeppelin: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity >=0.5.0 < 0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20Compat {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// Adopted from openzeppelin: @openzeppelin/upgrades/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract InitializableCompat {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.5.0 < 0.8.0;

interface IDebugSubredditPoints {
    function generateDebugPoints(address account, uint256 round, uint256 amount) external;
}

/*
    SPDX-License-Identifier: Apache-2.0

    Copyright 2021 Reddit, Inc

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity >=0.6.0 < 0.8.0;

interface IDistributionsFrozen {
    function prevRoundSupply() external view returns (uint256);
    function prevClaimed() external view returns (uint256);
    function claimableRoundOf(address account) external view returns(uint256);
    function roundAvailablePoints(uint256 round) external view returns (uint256);
    function roundSharedOwnersAvailablePoints(uint256 round) external view returns (uint256);
    function roundTotalKarma(uint256 round) external view returns (uint256);
}