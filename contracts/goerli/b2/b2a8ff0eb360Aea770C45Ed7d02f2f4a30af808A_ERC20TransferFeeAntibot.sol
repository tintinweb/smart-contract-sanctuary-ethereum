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

interface IAntibot {
    function assureCanTransfer(
        address from,
        address to,
        uint256 amount
    ) external returns (bool response);

    function setAuthority(address target, address user, bool authorized) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IAntibotUser {
    event AntibotEnabled(bool isEnabled);

    event AntibotAddressUpdated(address antibotAddress);

    function updateAntibotEnabled(bool isEnabled) external;

    function updateAntibotContractAddress(address antibotAddress) external;
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

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC20TransferFee {
    event ExcludedFromFee(address indexed account, bool isExcluded);
    event FeeUpdated(uint256 feeBasisPoints);
    event FeeRecipientUpdated(address feeContract);

    function updateExcludedFromFee(address account, bool isExcluded) external;

    function updateTransferFee(uint256 fee) external;

    function updateFeeRecipient(address feeRecipient_) external;
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

import "../interfaces/IERC20TransferFee.sol";
import "./ERC20.sol";

contract ERC20TransferFee is ERC20, IERC20TransferFee {
    uint256 public transferFee;
    address public feeRecipient;

    uint256 private constant MAX_TRANSFER_FEE = 2500;
    uint256 private constant BPS_MULTIPLIER = 10000;

    mapping(address => bool) public excludedFromFee;

    function updateExcludedFromFee(address account, bool isExcluded) external override onlyOwner {
        excludedFromFee[account] = isExcluded;
        emit ExcludedFromFee(account, isExcluded);
    }

    function updateTransferFee(uint256 fee) external override onlyOwner {
        require(fee <= MAX_TRANSFER_FEE, "Maximum fee exceeded");
        transferFee = fee;
        emit FeeUpdated(fee);
    }

    function updateFeeRecipient(address feeRecipient_) external override onlyOwner {
        feeRecipient = feeRecipient_;
        emit FeeRecipientUpdated(feeRecipient_);
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

        uint256 transferFee_ = transferFee;
        address feeRecipient_ = feeRecipient;
        uint256 fee;

        if (feeRecipient_ != address(0) && transferFee_ > 0 && !excludedFromFee[from] && !excludedFromFee[to]) {
            fee = (amount * transferFee_) / BPS_MULTIPLIER;

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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "../interfaces/IERC20TransferFee.sol";
import "../interfaces/IAntibot.sol";
import "../interfaces/IAntibotUser.sol";
import "./ERC20TransferFee.sol";

contract ERC20TransferFeeAntibot is ERC20TransferFee, IAntibotUser {
    IAntibot public antibot;
    bool public antibotEnabled;

    function updateAntibotEnabled(bool isEnabled) external onlyOwner {
        antibotEnabled = isEnabled;

        emit AntibotEnabled(isEnabled);
    }

    function updateAntibotContractAddress(address antibotAddress) external onlyOwner {
        antibot = IAntibot(antibotAddress);

        emit AntibotAddressUpdated(antibotAddress);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._transfer(from, to, amount);

        if(antibotEnabled && address(antibot) != address(0)) {
            require(antibot.assureCanTransfer(from, to, amount), "Antibot: call protected");
        }
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