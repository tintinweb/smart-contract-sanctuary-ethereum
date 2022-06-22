/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// File: contracts/BFF.sol

/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, amount);
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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Counters {
    struct Counter {
        uint256 _value;
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

contract Ownable {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
     
    function createPair(address tokenA, address tokenB) external returns (address pair);
 }

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountToken, uint amountETH); 
}

library Referrals {

    struct Data {
        uint256 tokensNeededForRefferalNumber;
        mapping(uint256 => address) registeredReferrersByCode;
        mapping(address => uint256) registeredReferrersByAddress;
        uint256 currentRefferralCode;
    }

    event RefferalCodeGenerated(address account, uint256 code, uint256 inc1, uint256 inc2);


    event UpdateTokensNeededForReferralNumber(uint256 value);


    function init(Data storage data) public {
        updateTokensNeededForReferralNumber(data, 10000 * (10**18)); //10000 tokens needed

        data.currentRefferralCode = 10000;
    }

    function updateTokensNeededForReferralNumber(Data storage data, uint256 value) public {
        data.tokensNeededForRefferalNumber = value;
        emit UpdateTokensNeededForReferralNumber(value);
    }

    function random(Data storage data, uint256 min, uint256 max) private view returns (uint256) {
        return min + uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, data.currentRefferralCode))) % (max - min + 1);
    }

    function handleNewBalance(Data storage data, address account, uint256 balance) public {
        //already registered
        if(data.registeredReferrersByAddress[account] != 0) {
            return;
        }
        //not enough tokens
        if(balance < data.tokensNeededForRefferalNumber) {
            return;
        }
        //randomly increment referral code 
        //cannot be guessed easily
        uint256 inc1 = random(data, 1, 7);
        uint256 inc2 = random(data, 1, 9);
        data.currentRefferralCode += inc1;

        //don't allow referral code to end in 0,
        //so that ambiguous codes do not exist (ie, 420 and 4200)
        if(data.currentRefferralCode % 10 == 0) {
            data.currentRefferralCode += inc2;
        }

        if(data.currentRefferralCode < 10000) {
            uint256 inc3 = random(data, 51, 35156);
            data.currentRefferralCode = 10000;
            data.currentRefferralCode += inc3;

            if(data.currentRefferralCode % 10 == 0) {
            data.currentRefferralCode += inc2;
        }
        }
        
        if(data.currentRefferralCode > 99999) {
            uint256 inc4 = random(data, 111, 65644);
            data.currentRefferralCode = 10000;
            data.currentRefferralCode += inc4;

            if(data.currentRefferralCode % 10 == 0) {
            data.currentRefferralCode += inc2;
        }
        }

        if(data.registeredReferrersByCode[data.currentRefferralCode] != address(0)) {
            data.currentRefferralCode += inc2;
        }
        
        data.registeredReferrersByCode[data.currentRefferralCode] = account;
        data.registeredReferrersByAddress[account] = data.currentRefferralCode;

        emit RefferalCodeGenerated(account, data.currentRefferralCode, inc1, inc2);
    }

    function getReferralCode(Data storage referrals, address account) public view returns (uint256) {
        return referrals.registeredReferrersByAddress[account];
    }

    function getReferrer(Data storage referrals, uint256 referralCode) public view returns (address) {
        return referrals.registeredReferrersByCode[referralCode];
    }

    function getReferralCodeFromTokenAmount(uint256 tokenAmount) private pure returns (uint256) {

        return (tokenAmount % (10**18))/(10**(13));

    }

    function getReferrerFromTokenAmount(Data storage referrals, uint256 tokenAmount) public view returns (address) {
        uint256 referralCode = getReferralCodeFromTokenAmount(tokenAmount);

        return referrals.registeredReferrersByCode[referralCode];
    }

    function isValidReferrer(Data storage referrals, address referrer, uint256 referrerBalance, address transferTo) public view returns (bool) {
        if(referrer == address(0)) {
            return false;
        }

        uint256 tokensNeeded = referrals.tokensNeededForRefferalNumber;

        return referrerBalance >= tokensNeeded && referrer != transferTo;
    }
}

library SignedSafeMath {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

library UniswapV2PriceImpactCalculator {
    function calculateSellPriceImpact(address tokenAddress, address pairAddress, uint256 value) public view returns (uint256) {
        value = value * 998 / 1000;

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        (uint256 r0, uint256 r1,) = pair.getReserves();

        IERC20Metadata token0 = IERC20Metadata(pair.token0());
        IERC20Metadata token1 = IERC20Metadata(pair.token1());

        if(address(token1) == tokenAddress) {
            IERC20Metadata tokenTemp = token0;
            token0 = token1;
            token1 = tokenTemp;

            uint256 rTemp = r0;
            r0 = r1;
            r1 = rTemp;
        }

        uint256 product = r0 * r1;

        uint256 r0After = r0 + value;
        uint256 r1After = product / r0After;

        return (10000 - (r1After * 10000 / r1)) * 998 / 1000;
    }
}

library SafeCast {
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(
            value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(
            value <= type(uint96).max,
            "SafeCast: value doesn't fit in 96 bits"
        );
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(
            value <= type(uint16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(
            value <= type(uint8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }
}

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);

    function distributeDividends() external payable;

    function withdrawDividend() external;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount,
        address received
    );
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner)
        external
        view
        returns (uint256);

    function withdrawnDividendOf(address _owner)
        external
        view
        returns (uint256);

    function accumulativeDividendOf(address _owner)
        external
        view
        returns (uint256);
}

abstract contract DividendPayingToken is
    ERC20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    uint256 internal constant magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    receive() external payable {
        distributeDividends();
    }

    function distributeDividends() public payable override {
        require(totalSupply() > 0);

        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (msg.value).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, msg.value);

            totalDividendsDistributed = totalDividendsDistributed.add(
                msg.value
            );
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender), payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user, address payable to)
        internal
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit DividendWithdrawn(user, _withdrawableDividend, to);
            (bool success, ) = to.call{value: _withdrawableDividend}("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner)
        public
        view
        override
        returns (uint256)
    {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256() / magnitude;
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }

    function getAccount(address _account)
        public
        view
        returns (uint256 _withdrawableDividends, uint256 _withdrawnDividends)
    {
        _withdrawableDividends = withdrawableDividendOf(_account);
        _withdrawnDividends = withdrawnDividends[_account];
    }
}

contract BFFDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private tokenHoldersCount;
    mapping(address => bool) private tokenHoldersMap;

    mapping(address => bool) public excludedFromDividends;

    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);

    constructor()
        DividendPayingToken(
            "BFF_Dividend_Tracker",
            "BFF_Dividend_Tracker"
        )
    {
        minimumTokenBalanceForDividends = 10000 * 10**18;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function _approve(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "BFF_Dividend_Tracker: No approvals allowed");
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "BFF_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(
            false,
            "BFF_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main BFF contract."
        );
    }

    function excludeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = true;

        _setBalance(account, 0);

        if (tokenHoldersMap[account] == true) {
            tokenHoldersMap[account] = false;
            tokenHoldersCount.decrement();
        }

        emit ExcludeFromDividends(account);
    }

    function includeFromDividends(address account, uint256 balance)
        external
        onlyOwner
    {
        excludedFromDividends[account] = false;

        if (balance >= minimumTokenBalanceForDividends) {
            _setBalance(account, balance);

            if (tokenHoldersMap[account] == false) {
                tokenHoldersMap[account] = true;
                tokenHoldersCount.increment();
            }
        }

        emit ExcludeFromDividends(account);
    }

    function isExcludeFromDividends(address account)
        external
        view
        onlyOwner
        returns (bool)
    {
        return excludedFromDividends[account];
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersCount.current();
    }

    function setBalance(address payable account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);

            if (tokenHoldersMap[account] == false) {
                tokenHoldersMap[account] = true;
                tokenHoldersCount.increment();
            }
        } else {
            _setBalance(account, 0);

            if (tokenHoldersMap[account] == true) {
                tokenHoldersMap[account] = false;
                tokenHoldersCount.decrement();
            }
        }
    }

    function processAccount(address account, address toAccount)
        public
        onlyOwner
        returns (uint256)
    {
        uint256 amount = _withdrawDividendOfUser(
            payable(account),
            payable(toAccount)
        );
        return amount;
    }
}

contract BFF is ERC20, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using Referrals for Referrals.Data;

    string private constant _name = "By Frens For Frens";
    string private constant _symbol = "BFF";
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1e12 * 10**18;

    IUniswapV2Router02 private uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    bool private tradingOpen = false;
    bool private allowClaims = false;
    uint256 private launchBlock = 0;
    address private uniswapV2Pair;

    IERC20 private PreSaleTokenAddress;
    uint256 private minimumPreSaleTokens;
    uint256 private preSaleTimestamp;
    uint256 private minutesForPreSale;
    uint256 private publicSaleTimestamp;
    bool private preSaleActive = false;

    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => bool) public isExcludeFromFee;
    mapping(address => bool) public isBlacklist;
    mapping(address => bool) public isAllowedToClaim;
    mapping(address => bool) public isBot;
    mapping(address => bool) public isExcludeFromMaxWalletAmount;

    uint256 public maxWalletAmount;

    uint256 public baseBuyTax = 10;
    uint256 public baseSellTax = 5;
    uint256 public referralBuyTax = 5;
    uint256 public referrerBonus = 25; // 2.5% division in tenths to support
    uint256 public referredBonus = 25; // 2.5% division in tenths to support

    uint256 private autoLP = 20;
    uint256 private devFee = 10;
    uint256 private marketingFee = 70;

    uint256 public minContractTokensToSwap = 2e9 * 10**18;

    struct PriceImpactRangeTax {
        uint256 from;
        uint256 to;
        uint256 tax;
    }

    mapping(address => uint256) public initialBuyTimestamp;
    mapping(uint256 => PriceImpactRangeTax) public priceImpactRangeTaxes;
    uint8 public maxIndexImpactRange;

    address private devWalletAddress;
    address private marketingWalletAddress;

    BFFDividendTracker public dividendTracker;
    uint256 minimumTokenBalanceForDividends = 1000 * 10**18;
    mapping(address => uint256) public lastTransfer;

    uint256 public pendingTokensForReward;
    uint256 public minRewardTokensToSwap = 10000 * 10**18;

    uint256 public pendingEthReward;

    struct ClaimedEth {
        uint256 ethAmount;
        uint256 tokenAmount;
        uint256 timestamp;
    }

    Counters.Counter private claimedHistoryIds;
    Referrals.Data private _storage;

    mapping(uint256 => ClaimedEth) private claimedEthMap;
    mapping(address => uint256[]) private userClaimedIds;

    event BuyFees(address from, address to, uint256 amountTokens);
    event SellFees(address from, address to, uint256 amountTokens);
    event AddLiquidity(uint256 amountTokens, uint256 amountEth);
    event SwapTokensForEth(uint256 sentTokens, uint256 receivedEth);
    event SwapEthForTokens(uint256 sentEth, uint256 receivedTokens);
    event DistributeFees(uint256 devEth, uint256 remarketingEth);
    event AddRewardPool(uint256 _ethAmount);

    event SendDividends(uint256 amount);

    event DividendClaimed(
        uint256 ethAmount,
        uint256 tokenAmount,
        address account
    );

    constructor(
        address _devWalletAddress,
        address _marketingWalletAddress
    ) ERC20(_name, _symbol) {
        devWalletAddress = _devWalletAddress;
        marketingWalletAddress = _marketingWalletAddress;

        maxWalletAmount = (_tTotal * 25) / 10000; // 0.25% maxWalletAmount (initial limit)

        dividendTracker = new BFFDividendTracker();
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(uniswapV2Router));

        isExcludeFromFee[owner()] = true;
        isExcludeFromFee[address(this)] = true;
        isExcludeFromFee[address(dividendTracker)] = true;
        isExcludeFromFee[devWalletAddress] = true;
        isExcludeFromFee[marketingWalletAddress] = true;
        isExcludeFromMaxWalletAmount[owner()] = true;
        isExcludeFromMaxWalletAmount[address(this)] = true;
        isExcludeFromMaxWalletAmount[address(uniswapV2Router)] = true;
        isExcludeFromMaxWalletAmount[devWalletAddress] = true;
        isExcludeFromMaxWalletAmount[marketingWalletAddress] = true;
        priceImpactRangeTaxes[1].from = 0;
        priceImpactRangeTaxes[1].to = 99;
        priceImpactRangeTaxes[1].tax = 5;
        priceImpactRangeTaxes[2].from = 100;
        priceImpactRangeTaxes[2].to = 149;
        priceImpactRangeTaxes[2].tax = 10;
        priceImpactRangeTaxes[3].from = 150;
        priceImpactRangeTaxes[3].to = 199;
        priceImpactRangeTaxes[3].tax = 15;
        priceImpactRangeTaxes[4].from = 200;
        priceImpactRangeTaxes[4].to = 249;
        priceImpactRangeTaxes[4].tax = 20;
        priceImpactRangeTaxes[5].from = 250;
        priceImpactRangeTaxes[5].to = 5000;
        priceImpactRangeTaxes[5].tax = 25;

        maxIndexImpactRange = 5;

        _mint(owner(), _tTotal);

        _storage.init();

    }

    // withdraw ETH if stuck before launch
    function withdrawStuckETH() external onlyOwner {
        require(!tradingOpen, "Can only withdraw if trading hasn't started");
        bool success;
        (success, ) = address(msg.sender).call{ value: address(this).balance }(
            ""
        );
    }

    function enablePreSale (uint256 _minutesForPreSale, address _preSaleTokenAddress, uint256 _minimumPreSaleTokens) external onlyOwner {
        require(!tradingOpen, "BFF: Can only enable PreSale before Trading has been opened.");
        minutesForPreSale = _minutesForPreSale;
        PreSaleTokenAddress = IERC20(_preSaleTokenAddress);
        minimumPreSaleTokens = _minimumPreSaleTokens * 10**18;
        preSaleActive = true;
    }

    function openTrading()
        external
        onlyOwner
    {
        require(!tradingOpen, "BFF: Trading is already open");
        
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        isExcludeFromMaxWalletAmount[address(uniswapV2Pair)] = true;

        automatedMarketMakerPairs[uniswapV2Pair] = true;
        dividendTracker.excludeFromDividends(uniswapV2Pair);

        addLiquidity(balanceOf(address(this)), address(this).balance);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        tradingOpen = true;
        if (preSaleActive) {
            uint256 _launchTime;
            _launchTime = block.timestamp;

            preSaleTimestamp = _launchTime;
            publicSaleTimestamp = _launchTime.add(
                minutesForPreSale.mul(1 minutes)
            );
        }
        launchBlock = block.number;
    }

    function alowClaims(bool _alowClaims) external onlyOwner{
        allowClaims = _alowClaims;
    }

    function updateReferrals(uint256 _referralBuyTax, uint256 _referrerBonus, uint256 _referredBonus, uint256 tokensNeeded) public onlyOwner {
        referralBuyTax = _referralBuyTax;
        referrerBonus = _referrerBonus;
        referredBonus = _referredBonus;
        _storage.updateTokensNeededForReferralNumber(tokensNeeded);
    }
    
    function getReferralCode(address account) public view returns (uint256 referralCode) {
        referralCode = _storage.getReferralCode(account);
    }

    function getReferralCodeAddress(uint256 referralCode) public view returns (address referrerAddress) {
        referrerAddress = _storage.getReferrer(referralCode);
    }

    function getReferralAddressByTokenAmount(uint256 _amount) public view returns (address referrerAddress) {
        referrerAddress = _storage.getReferrerFromTokenAmount(_amount);
    }

    function isReferralValid(address referrer, address _to) public view returns (bool) {
        if(referrer == address(0)) {
            return false;
        }
        uint256 neededTokens = _storage.tokensNeededForRefferalNumber;

        return balanceOf(referrer) >= neededTokens && referrer != _to;
    }

    function handleNewBalanceForReferrals(address account) private {
        if(isExcludeFromFee[account] || isBlacklist[account]) {
            return;
        }

        if(account == address(uniswapV2Pair)) {
            return;
        }

        _storage.handleNewBalance(account, balanceOf(account));
    }

    function manualSwap() external onlyOwner {
        uint256 totalTokens = balanceOf(address(this)).sub(
            pendingTokensForReward
        );

        swapTokensForEth(totalTokens);
    }

    function manualSend() external onlyOwner {
        uint256 totalEth = address(this).balance.sub(pendingEthReward);

        uint256 devFeesToSend = totalEth.mul(devFee).div(
            uint256(100).sub(autoLP)
        );
        uint256 marketingFeesToSend = totalEth.mul(marketingFee).div(
            uint256(100).sub(autoLP)
        );
        uint256 remainingEthForFees = totalEth.sub(devFeesToSend).sub(
            marketingFeesToSend);
        devFeesToSend = devFeesToSend.add(remainingEthForFees);

        sendEthToWallets(devFeesToSend, marketingFeesToSend);
    }

    function getPriceImpactTax(address _ad, uint256 _amount) public view returns (uint256) {
        uint256 tax = baseSellTax;

        uint256 priceImpact = UniswapV2PriceImpactCalculator.calculateSellPriceImpact(address(_ad), uniswapV2Pair, _amount);

        for (uint8 x =1; x <= maxIndexImpactRange; x++) {
            if (
                (priceImpact >= priceImpactRangeTaxes[x].from &&
                    priceImpact <= priceImpactRangeTaxes[x].to)
            ) {
                tax = priceImpactRangeTaxes[x].tax;
                return tax;
            }
        }
        return tax;
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address _account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(_account);
    }

    function dividendTokenBalanceOf(address _account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(_account);
    }

    function claim() external {
        _claim(payable(msg.sender), false);
    }

    function reinvest() external {
        _claim(payable(msg.sender), true);
    }

    function _claim(address payable _account, bool _reinvest) private {
        uint256 withdrawableAmount = dividendTracker.withdrawableDividendOf(
            _account
        );
        require(
            withdrawableAmount > 0,
            "BFF: Claimer has no withdrawable dividends"
        );
        uint256 ethAmount;
        uint256 tokenAmount;

        if (!_reinvest) {
            require(
                allowClaims || isAllowedToClaim[_account],
                "BFF: Claimer not allowed to claim dividends, can only re-invest."
            );
            ethAmount = dividendTracker.processAccount(_account, _account);
        } else if (_reinvest) {
            ethAmount = dividendTracker.processAccount(_account, address(this));
            if (ethAmount > 0) {
                tokenAmount = swapEthForTokens(ethAmount, _account);
            }
        }
        if (ethAmount > 0) {
            claimedHistoryIds.increment();
            uint256 hId = claimedHistoryIds.current();
            claimedEthMap[hId].ethAmount = ethAmount;
            claimedEthMap[hId].tokenAmount = tokenAmount;
            claimedEthMap[hId].timestamp = block.timestamp;

            userClaimedIds[_account].push(hId);

            emit DividendClaimed(ethAmount, tokenAmount, _account);
        }
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function getAccount(address _account)
        public
        view
        returns (
            uint256 withdrawableDividends,
            uint256 withdrawnDividends,
            uint256 balance
        )
    {
        (withdrawableDividends, withdrawnDividends) = dividendTracker
            .getAccount(_account);
        return (withdrawableDividends, withdrawnDividends, balanceOf(_account));
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        require(!isBot[_from] && !isBot[_to]);
        require(!isBlacklist[_from] && !isBlacklist[_to]);

        uint256 transferAmount = _amount;
        if (
            tradingOpen &&
            (automatedMarketMakerPairs[_from] ||
                automatedMarketMakerPairs[_to]) &&
            !isExcludeFromFee[_from] &&
            !isExcludeFromFee[_to]
        ) {
            if (preSaleActive &&
                preSaleTimestamp <= block.timestamp &&
                publicSaleTimestamp > block.timestamp
            ) {
                require(
                    PreSaleTokenAddress.balanceOf(_to) >= minimumPreSaleTokens,
                    "PreSale: Not enough PreSale token balance."
                );
            }

            address _referrer; 
            _referrer = _storage.getReferrerFromTokenAmount(_amount);

            if(!_storage.isValidReferrer(_referrer, balanceOf(_referrer), _to)) {
                _referrer = address(0);
            }
            
            transferAmount = takeFees(_from, _to, _amount, _referrer);
            
        }
        if (initialBuyTimestamp[_to] == 0) {
            initialBuyTimestamp[_to] = block.timestamp;
        }
        if (!automatedMarketMakerPairs[_to] && !isExcludeFromMaxWalletAmount[_to]) {
            require(balanceOf(_to) + transferAmount <= maxWalletAmount,
                "BFF: Wallet balance limit reached"
            );
        }

        super._transfer(_from, _to, transferAmount);

        handleNewBalanceForReferrals(_to);

        if (!dividendTracker.isExcludeFromDividends(_from)) {
            try
                dividendTracker.setBalance(payable(_from), balanceOf(_from))
            {} catch {}
        }
        if (!dividendTracker.isExcludeFromDividends(_to)) {
            try
                dividendTracker.setBalance(payable(_to), balanceOf(_to))
            {} catch {}
        }
    }

    function _setAutomatedMarketMakerPair(address _pair, bool _value) private {
        require(
            automatedMarketMakerPairs[_pair] != _value,
            "BFF: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[_pair] = _value;

        if (_value) {
            dividendTracker.excludeFromDividends(_pair);
        }
    }

    function setBlacklist(address _address, bool _isBlaklist)
        external onlyOwner {
        isBlacklist[_address] = _isBlaklist;
    }

    function isAlowedToClaim(address _address, bool _isAlowedToClaim)
        external onlyOwner {
        isAllowedToClaim[_address] = _isAlowedToClaim;
    }

    function setExcludeFromFee(address _address, bool _isExludeFromFee)
        external onlyOwner {
        isExcludeFromFee[_address] = _isExludeFromFee;
    }

    function setExcludeFromMaxWalletAmount(address _address, bool _isExludeFromMaxWalletAmount)
        external onlyOwner {
        isExcludeFromMaxWalletAmount[_address] = _isExludeFromMaxWalletAmount;
    }

    function setExludeFromDividends(address _address, bool _isExludeFromDividends)
        external onlyOwner {
        if (_isExludeFromDividends) {
            dividendTracker.excludeFromDividends(_address);
        } else {
            dividendTracker.includeFromDividends(_address, balanceOf(_address));
        }
    }

    function setMultipleExludeFromDividends(address[] calldata _isMultipleExludeFromDividends) public onlyOwner {
        for (uint256 i = 0; i < _isMultipleExludeFromDividends.length; i++) {
                dividendTracker.excludeFromDividends(_isMultipleExludeFromDividends[i]);
            }
    }

    function setMaxWallet(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= (totalSupply() * 1 / 1000)/1e18, "Cannot set maxWallet lower than 0.1%");
        maxWalletAmount = newMaxWallet * (10**18);
    }
    

    function setTaxes(
        uint256 _baseBuyTax,
        uint256 _baseSellTax,
        uint256 _autoLP,
        uint256 _devFee,
        uint256 _marketingFee
    ) external onlyOwner {
        require(_baseBuyTax <= 10 && baseSellTax <= 10);

        baseBuyTax = _baseBuyTax;
        baseSellTax = _baseSellTax;
        autoLP = _autoLP;
        devFee = _devFee;
        marketingFee = _marketingFee;
    }

    function setMinContractTokensToSwap(uint256 _numToken) public onlyOwner {
        minContractTokensToSwap = _numToken;
    }

    function setMinRewardTokensToSwap(uint256 _numToken) public onlyOwner {
        minRewardTokensToSwap = _numToken;
    }

    function setPriceImpactRangeTax(
        uint8 _index,
        uint256 _from,
        uint256 _to,
        uint256 _tax
    ) external onlyOwner {
        priceImpactRangeTaxes[_index].from = _from;
        priceImpactRangeTaxes[_index].to = _to;
        priceImpactRangeTaxes[_index].tax = _tax;
    }

    function setMaxIndexImpactRange(uint8 _maxIndex) external onlyOwner {
        maxIndexImpactRange = _maxIndex;
    }

    function setBots(address[] calldata _bots) public onlyOwner {
        for (uint256 i = 0; i < _bots.length; i++) {
            if (
                _bots[i] != uniswapV2Pair &&
                _bots[i] != address(uniswapV2Router)
            ) {
                isBot[_bots[i]] = true;
            }
        }
    }

    function setWalletAddress(address _devWallet, address _marketingWallet)
        external
        onlyOwner
    {
        devWalletAddress = _devWallet;
        marketingWalletAddress = _marketingWallet;
    }

    function takeFees(
        address _from,
        address _to,
        uint256 _amount,
        address _referrer
    ) private returns (uint256) {
        uint256 fees;
        uint256 remainingAmount;
        require(
            automatedMarketMakerPairs[_from] || automatedMarketMakerPairs[_to],
            "BFF: No market makers found"
        );

        if (automatedMarketMakerPairs[_from]) {
            uint256 totalBuyTax;
            uint256 referrerFees;
            uint256 referredFees;
            if (block.number == launchBlock && !preSaleActive) {
                totalBuyTax = 90;
            } else if (block.number == launchBlock + 1 && !preSaleActive) {
                totalBuyTax = 50;
            } else if (_referrer != address(0)) {
                totalBuyTax = referralBuyTax.add(referrerBonus.add(referredBonus).div(10));
            } else {
                totalBuyTax = baseBuyTax;
            }

            fees = _amount.mul(totalBuyTax).div(100);
            
            if(_referrer != address(0)) {
                fees = _amount.mul(referralBuyTax).div(100);

                referrerFees = _amount.mul(referrerBonus).div(1000);
                referredFees = _amount.mul(referredBonus).div(1000);

                uint256 totalReferralFees = referrerFees.add(referredFees);

                remainingAmount = _amount.sub(fees).sub(totalReferralFees).add(referredFees);

                super._transfer(_from, address(this), fees);

                super._transfer(_from, _referrer, referrerFees);

                emit BuyFees(_from, address(this), fees);

                emit BuyFees(_from, _referrer, referrerFees);

            } else {

            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);

            emit BuyFees(_from, address(this), fees);
            }
        } else {
            uint256 totalSellTax;
            if (block.number == launchBlock) {
                totalSellTax = 90;
            } else if (block.number == launchBlock + 1) {
                totalSellTax = 50;
            } else {
                uint256 increaseSellFee = getPriceImpactTax(address(this), _amount);

                totalSellTax = baseSellTax + increaseSellFee;

                if(totalSellTax >= 30) {
                    totalSellTax = 30;
                }
            }

            fees = _amount.mul(totalSellTax).div(100);
            uint256 rewardTokens = _amount
                .mul(totalSellTax.sub(baseSellTax))
                .div(100);
            pendingTokensForReward = pendingTokensForReward.add(rewardTokens);

            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);
            uint256 tokensToSwap = balanceOf(address(this)).sub(
                pendingTokensForReward);

            if (tokensToSwap > minContractTokensToSwap) {
                distributeTokensEth(tokensToSwap);
            }
            if (pendingTokensForReward > minRewardTokensToSwap) {
                swapAndSendDividends(pendingTokensForReward);
            }

            emit SellFees(_from, address(this), fees);
        }

        return remainingAmount;
    }

    function distributeTokensEth(uint256 _tokenAmount) private {
        uint256 tokensForLiquidity = _tokenAmount.mul(autoLP).div(100);

        uint256 halfLiquidity = tokensForLiquidity.div(2);
        uint256 tokensForSwap = _tokenAmount.sub(halfLiquidity);

        uint256 totalEth = swapTokensForEth(tokensForSwap);

        uint256 ethForAddLP = totalEth.mul(autoLP).div(100);
        uint256 devFeesToSend = totalEth.mul(devFee).div(100);
        uint256 marketingFeesToSend = totalEth.mul(marketingFee).div(100);
        uint256 remainingEthForFees = totalEth
            .sub(ethForAddLP)
            .sub(devFeesToSend)
            .sub(marketingFeesToSend);
        devFeesToSend = devFeesToSend.add(remainingEthForFees);

        sendEthToWallets(devFeesToSend, marketingFeesToSend);

        if (halfLiquidity > 0 && ethForAddLP > 0) {
            addLiquidity(halfLiquidity, ethForAddLP);
        }
    }

    function sendEthToWallets(uint256 _devFees, uint256 _marketingFees)
        private
    {
        if (_devFees > 0) {
            payable(devWalletAddress).transfer(_devFees);
        }
        if (_marketingFees > 0) {
            payable(marketingWalletAddress).transfer(_marketingFees);
        }
        emit DistributeFees(_devFees, _marketingFees);
    }

    function swapTokensForEth(uint256 _tokenAmount) private returns (uint256) {
        uint256 initialEthBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 receivedEth = address(this).balance.sub(initialEthBalance);

        emit SwapTokensForEth(_tokenAmount, receivedEth);
        return receivedEth;
    }

    function swapEthForTokens(uint256 _ethAmount, address _to)
        private
        returns (uint256)
    {
        uint256 initialTokenBalance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _ethAmount
        }(0, path, _to, block.timestamp);

        uint256 receivedTokens = balanceOf(address(this)).sub(
            initialTokenBalance
        );

        emit SwapEthForTokens(_ethAmount, receivedTokens);
        return receivedTokens;
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        emit AddLiquidity(_tokenAmount, _ethAmount);
    }

    function swapAndSendDividends(uint256 _tokenAmount) private {
        uint256 dividends = swapTokensForEth(_tokenAmount);

        pendingTokensForReward = pendingTokensForReward.sub(_tokenAmount);
        uint256 totalEthToSend = dividends.add(pendingEthReward);

        (bool success, ) = address(dividendTracker).call{value: totalEthToSend}(
            ""
        );

        if (success) {
            emit SendDividends(dividends);
        } else {
            pendingEthReward = pendingEthReward.add(dividends);
        }
    }

    function canHolderClaim(address _address) public view returns (uint256) {
        uint256 holderCanClaim;
        if(isAllowedToClaim[_address] || allowClaims) {
            holderCanClaim = 1000000;
        } else {
            holderCanClaim = 0;
        }

        return holderCanClaim;
    }

    function availableContractTokenBalance() public view returns (uint256) {
        return balanceOf(address(this)).sub(pendingTokensForReward);
    }

    function getHistory(
        address _account,
        uint256 _limit,
        uint256 _pageNumber
    ) external view returns (ClaimedEth[] memory) {
        require(_limit > 0 && _pageNumber > 0, "BFF: Invalid arguments");
        uint256 userClaimedCount = userClaimedIds[_account].length;
        uint256 end = _pageNumber * _limit;
        uint256 start = end - _limit;
        require(start < userClaimedCount, "BFF: Out of range");
        uint256 limit = _limit;
        if (end > userClaimedCount) {
            end = userClaimedCount;
            limit = userClaimedCount % _limit;
        }

        ClaimedEth[] memory myClaimedEth = new ClaimedEth[](limit);
        uint256 currentIndex = 0;
        for (uint256 i = start; i < end; i++) {
            uint256 hId = userClaimedIds[_account][i];
            myClaimedEth[currentIndex] = claimedEthMap[hId];
            currentIndex += 1;
        }
        return myClaimedEth;
    }

    function getHistoryCount(address _account) external view returns (uint256) {
        return userClaimedIds[_account].length;
    }

    receive() external payable {}
    
}