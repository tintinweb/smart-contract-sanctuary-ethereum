/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

/**
 * SPDX-License-Identifier: MIT
 *
 * Tokenomics:
 *  Total Supply: 51,700,000
 *  Decimals: 18
 *  Token Name: The Slender Hedge
 *  Symbol: TSH
 * 
 * 
 * Buy Tax 10% (max 10%):            Sell Tax 12% (max 12%):
 *  Marketing/Hedge : 8%              Marketing/Hedge : 8% 
 *  LP :              2%              LP :              2%
 *  Development :     0%              Development :     2% 
 */

 pragma solidity 0.8.15;

 abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return (msg.sender);
    }
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256
            result = prod0 * inverse;
            return result;
        }
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 result = 1 << (log2(a) >> 1);

        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

library Arrays {
    using StorageSlot for bytes32;

    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (unsafeAccess(array, mid).value > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && unsafeAccess(array, low - 1).value == element) {
            return low - 1;
        } else {
            return low;
        }
    }

    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

abstract contract ERC20Snapshot is ERC20 {

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    Counters.Counter private _currentSnapshotId;

    event Snapshot(uint256 id);

    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


}

interface IFactory02 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IPair02 {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract Slender is Context, Ownable, ERC20Snapshot  {
    using Address for address payable;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromMaxSellTxLimit;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;

    address public developmentWallet = 0xFB56BeEE3D5feDb261912Fa408d6019D6F473E29;
    address payable public marketingWallet = payable(0xa8Cd1500094023b4e9d7735931A02f482de1617F);
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;

    // Buying fee
    uint8 public buyMarketingFee = 8;
    uint8 public buyLpFee = 2;
    uint8 public buyDevelopmentFee = 0;

    // Selling fee
    uint8 public sellMarketingFee = 8;
    uint8 public sellLpFee = 2;
    uint8 public sellDevelopmentFee = 2;

    uint8 public maxSellFees = 12;
    uint8 public maxBuyFees = 10;

    uint8 public totalSellFees;
    uint8 public totalBuyFees;

     // Allows to know the distribution of tokens collected from taxes
    uint256 private _lpCurrentAccumulatedFees;

    // Limits
    uint256 public maxSellLimit =  517_000 * 10**18; // 1%
    uint256 public maxWalletLimit = 1_034_000 * 10**18; // 2%
    
    // LP system
    IRouter02 public dexRouter02;
    address public dexPair02;
    uint256 public accumulatedTokensLimit = 12_925 * 10**18; // 0.025%
    bool private _isLiquefying;
    modifier lockTheSwap {
    if (!_isLiquefying) {
        _isLiquefying = true;
        _;
        _isLiquefying = false;
    }}

    address presaleAddress = address(0);

    // Any transfer to these addresses could be subject to some sell/buy taxes
    mapping (address => bool) public automatedMarketMakerPairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromMaxSellTxLimit(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletLimit(address indexed account, bool isExcluded);

    event AddAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event UniswapV2RouterUpdated(address indexed newAddress, address indexed oldAddress);
    event UniswapV2MainPairUpdated(address indexed newAddress, address indexed oldAddress);

    event DevelopmentWalletUpdated(address indexed newDevelopmentWallet, address indexed oldDevelopmentWallet);
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);

    event Burn(uint256 amount);

    event SellFeesUpdated(uint8 newMarketingFee, uint8 newLpFee, uint8 newDevelopmentFee);
    event BuyFeesUpdated(uint8 newMarketingFee, uint8 newLpFee, uint8 newDevelopmentFee);

    event MaxSellLimitUpdated(uint256 amount);
    event MaxWalletLimitUpdated(uint256 amount);

    event SwapAndDistribute(uint256 tokensSwapped,uint256 ethReceived);

    event AccumulatedTokensUpdated(uint256 amount);

    event NewHedgeStarted(uint256 snapshotId, address indexed newMarketingWallet);

    event PresaleAddressAdded(address indexed presaleAddress);

    /* - It’s not the question Why i have no face 
        You should ask yourselves where´s the frog ? 
                                    The Great Slenderman */
    constructor() ERC20("The Slender Hedge", "TSH") {
        // Create supply
        _mint(msg.sender, 51_700_000 * 10**18);

        totalSellFees = sellMarketingFee + sellLpFee + sellDevelopmentFee;
        totalBuyFees = buyMarketingFee + buyLpFee + buyDevelopmentFee;

        dexRouter02 = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
         // Create a uniswap pair for this new token
        dexPair02 = IFactory02(dexRouter02.factory())
            .createPair(address(this), dexRouter02.WETH());
        _setAutomatedMarketMakerPair(dexPair02, true);

        excludeFromAllFeesAndLimits(owner(),true);
        excludeFromAllFeesAndLimits(address(this),true);
    }

    function excludeFromAllFeesAndLimits(address account, bool excluded) public onlyOwner {
        excludeFromFees(account,excluded);
        excludeFromMaxSellLimit(account,excluded);
        excludeFromMaxWalletLimit(account,excluded);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "TSH: Account has already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxSellLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxSellTxLimit[account] != excluded, "TSH: Account has already the value of 'excluded'");
        _isExcludedFromMaxSellTxLimit[account] = excluded;

        emit ExcludeFromMaxSellTxLimit(account, excluded);
    }

    function excludeFromMaxWalletLimit(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromMaxWalletLimit[account] != excluded, "TSH: Account has already the value of 'excluded'");
        _isExcludedFromMaxWalletLimit[account] = excluded;

        emit ExcludeFromMaxWalletLimit(account, excluded);
    }

    function setPresaleAddress(address presaleAddress_) public onlyOwner {
        require(presaleAddress == address(0), "TSH: The presale address is already set");

        presaleAddress = presaleAddress_;
        emit PresaleAddressAdded(presaleAddress_);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != dexPair02, "TSH: The main pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "TSH: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        _isExcludedFromMaxWalletLimit[pair] = value;
        _isExcludedFromMaxSellTxLimit[pair] = value;

        emit AddAutomatedMarketMakerPair(pair, value);
    }

    function setNewRouter02(address newRouter_) public onlyOwner {
        require(address(dexRouter02) != newRouter_, "TSH: Router has already this address");
        IRouter02 newRouter = IRouter02(newRouter_);
        address newPair = IFactory02(newRouter.factory()).getPair(address(this), newRouter.WETH());
        if (newPair == address(0)) {
            newPair = IFactory02(newRouter.factory()).createPair(address(this), newRouter.WETH());
        }
        dexPair02 = newPair;
        dexRouter02 = IRouter02(newRouter);
    }

    function setBuyFees(uint8 newMarketingFee, uint8 newLpFee, uint8 newDevelopmentFee) external onlyOwner {
        uint8 newTotalBuyFees = newMarketingFee + newLpFee + newDevelopmentFee;
        require(newTotalBuyFees <= maxBuyFees ,"TSH: Total buy fees must be lower or equals to 10%");
        require(newMarketingFee <= 8 ,"TSH: Marketing fee  must be lower or equals to 8%");
        require(newDevelopmentFee <= 2 ,"TSH: Development fee must be lower or equals to 2%");

        buyMarketingFee = newMarketingFee;
        buyLpFee = newLpFee;
        buyDevelopmentFee = newDevelopmentFee;
        totalBuyFees = newTotalBuyFees;
        emit BuyFeesUpdated(newMarketingFee,newLpFee,newDevelopmentFee);
    }

    function setSellFees(uint8 newMarketingFee, uint8 newLpFee, uint8 newDevelopmentFee) external onlyOwner {
        uint8 newTotalSellFees = newMarketingFee + newLpFee + newDevelopmentFee;
        require(newTotalSellFees <= maxSellFees ,"TSH: Total sell fees must be lower or equals to 12%");
        require(newMarketingFee <= 8 ,"TSH: Marketing fee must be lower or equals to 8%");
        require(newDevelopmentFee <= 2 ,"TSH: Development fee must be lower or equals to 2%");

        sellMarketingFee = newMarketingFee;
        sellLpFee = newLpFee;
        sellDevelopmentFee = newDevelopmentFee;
        totalSellFees = newTotalSellFees;
        emit SellFeesUpdated(newMarketingFee,newLpFee,newDevelopmentFee);
    }

    function setMaxSellLimit(uint256 amount) external onlyOwner {
        require(amount >= 258_500 && amount <= 1_034_000, "TSH: Amount must be bewteen 258 500 and 1 034 000");
        maxSellLimit = amount *10**18;
        emit MaxSellLimitUpdated(amount);
    }

    function setMaxWalletLimit(uint256 amount) external onlyOwner {
        require(amount >= 517_000 && amount <= 2_068_000, "TSH: Amount must be bewteen 517 000 and 2 068 000");
        maxWalletLimit = amount *10**18;
        emit MaxWalletLimitUpdated(amount);
    }

    function setAccumulatedTokensLimit(uint256 amount) external onlyOwner {
        require(amount >= 1 && amount <= 517_000, "TSH: Amount must be bewteen 1 and 517 000");
        accumulatedTokensLimit = amount *10**18;
        emit AccumulatedTokensUpdated(amount);
    }

    function setDevelopmentWallet(address newWallet) external onlyOwner {
        require(newWallet != developmentWallet, "TSH: The team wallet has already this address");
        emit DevelopmentWalletUpdated(newWallet,developmentWallet);
        developmentWallet = newWallet;
    }

    function snapshot() external onlyOwner returns(uint256) {
        return super._snapshot();
    }

    function startNewHedge(address payable newMarketingWallet) external onlyOwner returns(uint256) {
        require(newMarketingWallet != marketingWallet, "TSH: The new marketing wallet must be different from the new one");
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance > 0) swapAndDistribute(contractTokenBalance);
        marketingWallet = newMarketingWallet;
        uint256 newSnapshotId = super._snapshot();
        emit NewHedgeStarted(newSnapshotId,newMarketingWallet);
        return newSnapshotId;
    }

    function burn(uint256 amount) external returns (bool) {
        _transfer(_msgSender(), DEAD, amount);
        emit Burn(amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "TSH: Transfer from the zero address");
        require(to != address(0), "TSH: Transfer to the zero address");
        require(amount >= 0, "TSH: Transfer amount must be greater or equals to zero");

        bool isBuyTransfer = automatedMarketMakerPairs[from];
        bool isSellTransfer = automatedMarketMakerPairs[to];

        if(!_isLiquefying) {
            if(isSellTransfer && from != address(dexRouter02) && !_isExcludedFromMaxSellTxLimit[from])
                require(amount <= maxSellLimit, "TSH: Amount exceeds the maxSellTxLimit");
            else if(!isSellTransfer && !isBuyTransfer && !_isExcludedFromMaxWalletLimit[to] && from != owner() && from != presaleAddress)
                require(balanceOf(to) + amount <= maxWalletLimit, "TSH: Amount exceeds the maxWalletLimit.");
            }


        bool takeFee = !_isLiquefying && (isBuyTransfer || isSellTransfer);
        // Remove fees if one of the address is excluded from fees
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) takeFee = false;

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= accumulatedTokensLimit;

        if(canSwap &&!_isLiquefying &&!automatedMarketMakerPairs[from] /* not during buying */) {
            swapAndDistribute(contractTokenBalance);
        }
        uint256 amountWithoutFees = amount;
        uint256 amountForSwap = 0;
        if(takeFee) {
            /* - Every buyer is a Slenderman disciple and every slenderman disciple is a buyer
                                                        The Great Slenderman */
            // Buy
            if(isBuyTransfer){
                amountWithoutFees = amount - amount * totalBuyFees / 100;
                if(!_isExcludedFromMaxWalletLimit[to]) require(balanceOf(to) + amountWithoutFees <= maxWalletLimit, "TSH: Amount exceeds the maxWalletLimit.");
                if(buyDevelopmentFee > 0) super._transfer(from,developmentWallet,amount *buyDevelopmentFee / 100);
                amountForSwap = amount * (buyMarketingFee + buyLpFee) / 100;
                _lpCurrentAccumulatedFees += amount * buyLpFee / 100;
            }
            // Sell 
            else if(isSellTransfer)  {
                amountWithoutFees = amount - amount * totalSellFees / 100;
                if(sellDevelopmentFee > 0) super._transfer(from,developmentWallet,amount *sellDevelopmentFee / 100);
                amountForSwap = amount * (sellMarketingFee + sellLpFee) / 100;
                _lpCurrentAccumulatedFees += amount * sellLpFee / 100;

            }
            if(amountForSwap > 0) super._transfer(from, address(this), amountForSwap);
        }
        super._transfer(from, to, amountWithoutFees);

    }

    function swapAndDistribute(uint256 tokenAmount) private lockTheSwap{

        uint256 initialBalance = address(this).balance;

        uint256 tokensToNotSwap = _lpCurrentAccumulatedFees / 2;
        uint256 tokensToSwap =  tokenAmount - tokensToNotSwap;
        // Swap tokens for BNB
        swapTokensForETH(tokensToSwap);
        uint256 newBalance = address(this).balance - initialBalance;

        uint256 lpAmount = newBalance * tokensToNotSwap / tokensToSwap;
        if(lpAmount > 0) addLiquidity(tokensToNotSwap,lpAmount);
        uint256 marketingAmount = address(this).balance - initialBalance;
        _lpCurrentAccumulatedFees = 0;
        marketingWallet.sendValue(marketingAmount);
        emit SwapAndDistribute(tokensToSwap, newBalance);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter02.WETH();

        _approve(address(this), address(dexRouter02), tokenAmount);

        // make the swap
        dexRouter02.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
        
    }

        function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter02), tokenAmount);

        // add the liquidity
        dexRouter02.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD,
            block.timestamp
        );
        
    }

    function tryToDistributeTokensManually() external payable onlyOwner {        
        if(
            !_isLiquefying
        ) {
            swapAndDistribute(balanceOf(address(this)));
        }
    } 
    // To distribute airdrops easily
    function batchTokensTransfer(address[] calldata _holders, uint256[] calldata _amounts) external onlyOwner {
        require(_holders.length <= 200);
        require(_holders.length == _amounts.length);
            for (uint i = 0; i < _holders.length; i++) {
              if (_holders[i] != address(0)) {
                super._transfer(_msgSender(), _holders[i], _amounts[i]);
            }
        }
    }

    function withdrawStuckETH(address payable to) external onlyOwner {
        require(address(this).balance > 0, "TSH: There are no ETHs in the contract");
        to.sendValue(address(this).balance);
    } 

    function withdrawStuckERC20Tokens(address token, address to) external onlyOwner {
        require(token != address(this), "TSH: You are not allowed to get TSH tokens from the contract");
        require(IERC20(token).balanceOf(address(this)) > 0, "TSH: There are no tokens in the contract");
        require(IERC20(token).transfer(to, IERC20(token).balanceOf(address(this))));
    }

    function getCirculatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(DEAD) - balanceOf(address(0));
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromMaxSellLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxSellTxLimit[account];
    }

    function isExcludedFromMaxWalletLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxWalletLimit[account];
    }

    /* - Believe in your dreams and nightmares,
         because if you don't believe in them your life will become a real nightmare.
                                                The Great Slenderman                */

    receive() external payable {
  	}

}