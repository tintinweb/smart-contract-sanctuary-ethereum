/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
// File: contracts/BaseToken/interface/ITokenFactory.sol

pragma solidity ^0.8.7;

interface ITokenFactory {
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    event BridgeChanged(address indexed oldBridge, address indexed newBridge);

    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    event TokenCreated(
        string name,
        string indexed symbol,
        uint256 amount,
        uint8 decimal,
        uint256 cap,
        address indexed token
    );

    event TokenRemoved(address indexed token);

    event TokenDecimalChanged(
        address indexed token,
        uint8 oldDecimal,
        uint8 newDecimal
    );

    function owner() external view returns (address);

    function tokens() external view returns (address[] memory);

    function tokenExist(address token) external view returns (bool);

    function bridge() external view returns (address);

    function admin() external view returns (address);

    function setBridge(address bridge) external;

    function setAdmin(address admin) external;

    function createToken(
        string memory name,
        string memory symbol,
        uint256 amount,
        uint8 decimal,
        uint256 cap
    ) external returns (address token);

    function removeToken(address token) external;

    function setTokenDecimal(address token, uint8 decimal) external;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/BaseToken/interface/ITokenMintable.sol

pragma solidity ^0.8.7;

interface ITokenMintable is IERC20Upgradeable {
    function initialize(
        address factory,
        string memory name,
        string memory symbol,
        uint256 amount,
        uint8 decimal,
        uint256 cap
    ) external;

    function factory() external view returns (address);

    function decimals() external view returns (uint8);

    function cap() external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function increaseCap(uint256 cap) external;

    function setupDecimal(uint8 decimal) external;
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol

// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

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
}

// File: contracts/BaseToken/base/TokenMintableUpgradeable.sol

pragma solidity ^0.8.7;

contract TokenMintableUpgradeable is Initializable, ITokenMintable {
    address private _factory;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint256 private _cap;
    uint8 private _decimal;

    function factory() public view virtual override returns (address) {
        return _factory;
    }

    modifier onlyBridgeOwner() {
        require(ITokenFactory(factory()).bridge() == msg.sender, "OAO");
        _;
    }

    modifier onlyBridgeAdminOwner() {
        require(ITokenFactory(factory()).admin() == msg.sender, "OAO");
        _;
    }

    function initialize(
        address factory_,
        string memory name_,
        string memory symbol_,
        uint256 amount,
        uint8 decimal_,
        uint256 cap_
    ) external override initializer {
        __Token_init(factory_, name_, symbol_, amount, decimal_, cap_);
    }

    function __Token_init(
        address factory_,
        string memory name_,
        string memory symbol_,
        uint256 amount,
        uint8 decimal_,
        uint256 cap_
    ) private initializer {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _factory = factory_;
        _name = name_;
        _symbol = symbol_;
        _decimal = decimal_;
        _cap = cap_;
        _mint(ITokenFactory(factory()).owner(), amount);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimal > 0 ? _decimal : 18;
    }

    function cap() public view virtual override returns (uint256) {
        return _cap;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function increaseCap(uint256 cap_) external override onlyBridgeAdminOwner {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap += cap_;
    }

    function mint(address to, uint256 amount)
        external
        override
        onlyBridgeOwner
    {
        require(_cap > amount, "Daily cap limit reached");
        _mint(to, amount);
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        _cap -= amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(
            ITokenFactory(factory()).bridge() != address(0),
            "Bridge is zero address"
        );
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, ITokenFactory(factory()).bridge(), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function setupDecimal(uint8 decimal_) external virtual {
        require(msg.sender == _factory, "OF");
        require(decimal_ > 0, "ERC20: Invalid decimal");
        _decimal = decimal_;
    }
}

// File: contracts/Net-Ethereum/Token/EthereumTokenMintable.sol

pragma solidity ^0.8.7;

contract EthereumTokenMintable is TokenMintableUpgradeable {
    function initialize() public initializer {}
}