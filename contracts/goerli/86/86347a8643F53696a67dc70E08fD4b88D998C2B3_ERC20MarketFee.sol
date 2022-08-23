// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

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

pragma solidity 0.8.15;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC20Initializable {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address creator
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC20MarketFee {
    event FeesUpdated(uint256 feeSell, uint256 feeBuy, uint256 feeTransfer);
    event ExcludedFromFees(address account, bool excluded);
    event ForcedToFee(address account, bool forced);
    event FeeRecipientChanged(address feeRecipient);

    function updateExcludedFromFees(address account, bool isExcluded) external;

    function updateForcedToFee(address account, bool forced) external;

    function updateFeeRecipient(address feeRecipient_) external;

    function updateFees(uint256 feeSell_, uint256 feeBuy_, uint256 feeTransfer_) external;

    function getFees() external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20Initializable.sol";
import "../external/openzeppelin/standard/Context.sol";
import "../utils/Ownable.sol";
import "../utils/Initializable.sol";

contract ERC20 is Context, Initializable, Ownable, IERC20, IERC20Metadata, IERC20Initializable {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    uint256 private _totalSupply;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        setInitialized();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 totalSupply_,
        address creator
    ) external initializer override {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        _mint(creator, totalSupply_);
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

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

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../interfaces/IERC20MarketFee.sol";
import "./ERC20.sol";

contract ERC20MarketFee is ERC20, IERC20MarketFee {
    uint256 public feeSell;
    uint256 public feeBuy;
    uint256 public feeTransfer;
    address public feeRecipient;

    uint256 private constant MAX_FEE = 2500;
    uint256 private constant BPS_MULTIPLIER = 10000;

    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public forcedToFee;

    function updateExcludedFromFees(address account, bool isExcluded) external override onlyOwner {
        excludedFromFees[account] = isExcluded;
        emit ExcludedFromFees(account, isExcluded);
    }

    function updateForcedToFee(address account, bool forced) external override onlyOwner {
        forcedToFee[account] = forced;
        emit ForcedToFee(account, forced);
    }

    function updateFeeRecipient(address feeRecipient_) external override onlyOwner {
        feeRecipient = feeRecipient_;
        emit FeeRecipientChanged(feeRecipient_);
    }

    function updateFees(
        uint256 feeSell_,
        uint256 feeBuy_,
        uint256 feeTransfer_
    ) external override onlyOwner {
        require(feeSell_ <= MAX_FEE && feeBuy_ <= MAX_FEE && feeTransfer_ <= MAX_FEE, "Maximum fee exceeded");
        feeSell = feeSell_;
        feeBuy = feeBuy_;
        feeTransfer = feeTransfer_;
        emit FeesUpdated(feeSell_, feeBuy_, feeTransfer_);
    }

    function getFees()
        external
        override
        view
        returns (uint256, uint256, uint256)
    {
        return (feeSell, feeBuy, feeTransfer);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        address feeRecipient_ = feeRecipient;

        uint256 fee = feeRecipient != address(0) ? calcFee(from, to, amount) : 0;

        if (fee > 0) {
            unchecked {
                _balances[feeRecipient_] += fee;
            }

            emit Transfer(from, feeRecipient_, fee);
        }

        uint256 sentAmount = amount - fee;

        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += sentAmount;
        }

        emit Transfer(from, to, sentAmount);
    }

    function calcFee(
        address from,
        address to,
        uint256 amount
    ) private view returns (uint256 fee) {
        if (from != address(0) && to != address(0) && !excludedFromFees[from] && !excludedFromFees[to]) {
            if (forcedToFee[to]) {
                fee = calcBPS(amount, feeSell);
            } else if (forcedToFee[from]) {
                fee = calcBPS(amount, feeBuy);
            } else {
                fee = calcBPS(amount, feeTransfer);
            }
        }
    }

    function calcBPS(uint256 amount, uint256 feeBPS) private pure returns (uint256) {
        return (amount * feeBPS) / BPS_MULTIPLIER;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

abstract contract Initializable {
    bool private _initialized;

    modifier initializer() {
        require(!_initialized, "Contract initialized");

        _;

        _initialized = true;
    }

    function setInitialized() internal {
        _initialized = true;
    }

    function isInitialized() internal view returns (bool) {
        return _initialized;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../external/openzeppelin/standard/Context.sol";

abstract contract Ownable is Context {
    address private _owner;
    bool private _initialOwnershipTransferred;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function initialTransferOwnership(address newOwner) external {
        require(!_initialOwnershipTransferred, "Initial ownership transferred");

        _transferOwnership(newOwner);

        _initialOwnershipTransferred = true;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}