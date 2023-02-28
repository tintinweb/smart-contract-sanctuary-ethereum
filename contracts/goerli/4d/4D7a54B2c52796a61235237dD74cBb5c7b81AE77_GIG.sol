/**
 *Submitted for verification at Etherscan.io on 2023-02-28
*/

// SPDX-License-Identifier: CC BY-NC-ND 4.0

pragma solidity ^0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IUniswapERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IUniswapFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapRouter01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getamountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getamountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getamountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getamountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = valueIndex;

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}

contract protected {
    mapping(address => bool) is_auth;

    function authorized(address addy) public view returns (bool) {
        return is_auth[addy];
    }

    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }

    modifier onlyAuth() {
        require(is_auth[msg.sender] || msg.sender == owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }
    bool locked;
    modifier safe() {
        require(!locked, "reentrant");
        locked = true;
        _;
        locked = false;
    }

    function change_owner(address new_owner) public onlyAuth {
        owner = new_owner;
    }

    receive() external payable {}

    fallback() external payable {}
}

contract GIG is IERC20, protected {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => uint256) public _lastSell;

    mapping(address => bool) public _excluded; // AKA whitelist
    mapping(address => bool) public _excludedFromSellLock;

    bool public tradingEnabled;
    address private _liquidityTokenAddress;

    // Lists
    struct ListProperty {
        // Fees
        uint256 buy_tax;
        uint256 sell_tax;
        uint256 transfer_tax;
        // Fees shares
        uint256 in_liquidity;
        uint256 in_burn;
        uint256 in_revenue;
        // Limits
        uint256 buy_limit;
        uint256 sell_limit;
        uint256 balance_limit;
        // Cooldown
        uint256 cooldown_time;
    }
    mapping(uint256 => ListProperty) public _list; // 0 = default; 1 = bluelist; 2 = greenlist;
    mapping(address => uint256) public _listOf; // 0 = default; 1 = bluelist; 2 = greenlist;

    mapping(address => bool) public _blacklist;
    bool isBlacklist = true;

    string public constant _name = "Gigidy";
    string public constant _symbol = "GIG";
    uint8 public constant _decimals = 18;
    uint256 public constant InitialSupply = 100 * 10**6 * 10**_decimals;

    uint256 swapLimit = InitialSupply / 200; // 0.5% of total supply
    bool isSwapPegged = true;

    address public constant UniswapRouter =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant Dead = 0x000000000000000000000000000000000000dEaD;

    uint256 public _circulatingSupply = InitialSupply;

    bool isTokenSwapManual = false;
    bool public antiSnape = false;

    address public _UniswapPairAddress;
    IUniswapRouter02 public _UniswapRouter;

    constructor() {
        owner = msg.sender;
        is_auth[msg.sender] = true;

        uint256 deployerBalance = (_circulatingSupply * 9) / 10;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        uint256 injectBalance = _circulatingSupply - deployerBalance;
        _balances[address(this)] = injectBalance;
        emit Transfer(address(0), address(this), injectBalance);
        _UniswapRouter = IUniswapRouter02(UniswapRouter);

        _UniswapPairAddress = IUniswapFactory(_UniswapRouter.factory())
            .createPair(address(this), _UniswapRouter.WETH());

        // Whitelist addresses
        _excluded[msg.sender] = true;
        _excludedFromSellLock[UniswapRouter] = true;
        _excludedFromSellLock[_UniswapPairAddress] = true;
        _excludedFromSellLock[address(this)] = true;

        // Creating lists
        // Default
        _list[0] = ListProperty(1, 1, 9, 33, 33, 34, InitialSupply/100, InitialSupply/200, InitialSupply/50, 2 seconds);
        // Bluelist
        _list[1] = ListProperty(1, 1, 1, 0, 0, 100, 0, 0, 0, 1 seconds);
        // Greenlist
        _list[2] = ListProperty(1, 1, 3, 33, 33, 34, 0, 0, 0, 1 seconds);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");
        if (isBlacklist) {
            require(
                !_blacklist[sender] && !_blacklist[recipient],
                "Blacklisted!"
            );
        }

        bool isExcluded = (_excluded[sender] ||
            _excluded[recipient] ||
            is_auth[sender] ||
            is_auth[recipient]);

        bool isContractTransfer = (sender == address(this) ||
            recipient == address(this));

        bool isLiquidityTransfer = ((sender == _UniswapPairAddress &&
            recipient == UniswapRouter) ||
            (recipient == _UniswapPairAddress && sender == UniswapRouter));

        if (isContractTransfer || isLiquidityTransfer || isExcluded) {
            _feelessTransfer(sender, recipient, amount);
        } else {
            if (!tradingEnabled) {
                if (sender != owner && recipient != owner) {
                    if (antiSnape) {
                        emit Transfer(sender, recipient, 0);
                        return;
                    } else {
                        require(tradingEnabled, "trading not yet enabled");
                    }
                }
            }

            bool isBuy = sender == _UniswapPairAddress ||
                sender == UniswapRouter;
            bool isSell = recipient == _UniswapPairAddress ||
                recipient == UniswapRouter;
            _taxedTransfer(sender, recipient, amount, isBuy, isSell);
        }
    }

    function _taxedTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool isBuy,
        bool isSell
    ) private {
        uint256 recipientBalance = _balances[recipient];
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        // Set the swap limit for contract swaps
        swapLimit = _list[0].sell_limit / 2;

        // Get the list of the sender
        uint256 list = _listOf[sender];

        uint8 tax;
        // Sell operations
        if (isSell) {
            // If enabled and defined for the list, check the cooldown
            if (
                !_excludedFromSellLock[sender] &&
                (_list[list].cooldown_time > 0)
            ) {
                uint256 unlockTime = _lastSell[sender] +
                    _list[list].cooldown_time;
                require(
                    unlockTime <= block.timestamp || sellLockDisabled,
                    "Seller in sellLock"
                );
                _lastSell[sender] = block.timestamp + _list[list].cooldown_time;
            }
            // Check the sell limit for the list
            require(amount <= _list[list].sell_limit, "Dump protection");
            tax = uint8(_list[list].sell_tax);
        }
        // Buy operations
        else if (isBuy) {
            // Check the balance limit for the list if defined
            if (_list[list].balance_limit > 0) {
                require(
                    recipientBalance + amount <= _list[list].balance_limit,
                    "whale protection"
                );
            }
            // Check the buy limit for the list if defined
            if (_list[list].buy_limit > 0) {
                require(amount <= _list[list].buy_limit, "whale protection");
            }
            // Get the buy tax for the list
            tax = uint8(_list[list].buy_tax);
        }
        // Transfer operations
        else {
            // Check the balance limit for the list if defined (for the receiver)
            uint256 recipientList = _listOf[recipient];
            if (_list[recipientList].balance_limit > 0) {
                require(
                    recipientBalance + amount <=
                        _list[recipientList].balance_limit,
                    "whale protection"
                );
            }
            // As for the sell operations, check the cooldown if enabled and defined for the list
            if (
                !_excludedFromSellLock[sender] &&
                (_list[list].cooldown_time > 0)
            ) {
                uint256 unlockTime = _lastSell[sender] +
                    _list[list].cooldown_time;
                require(
                    unlockTime <= block.timestamp || sellLockDisabled,
                    "Seller in sellLock"
                );
                _lastSell[sender] = block.timestamp + _list[list].cooldown_time;
            }
            tax = uint8(_list[list].transfer_tax);
        }
        // Swap the tokens if the treshold is reached
        if (
            (sender != _UniswapPairAddress) &&
            (!manualConversion) &&
            (!_isSwappingContractModifier)
        ) _swapContractToken(amount, list);

        uint256 contractToken = _calculateFee(amount, tax, 100);
        uint256 taxedAmount = amount - (contractToken);

        // Taking the amount from the sender
        _removeToken(sender, amount);

        // Adds the taxed tokens to the contract balance
        _balances[address(this)] += contractToken;
        // Removes burned tokens from the total supply
        if (_list[list].in_burn > 0) {
            uint toBurn = contractToken * _list[list].in_burn / 100;
            Management_destroy(toBurn);
        }

        // Adds the remains to the recipient
        _addToken(recipient, taxedAmount);

        emit Transfer(sender, recipient, taxedAmount);
    }

    function _feelessTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _removeToken(sender, amount);
        _addToken(recipient, amount);

        emit Transfer(sender, recipient, amount);
    }

    function _calculateFee(
        uint256 amount,
        uint8 tax,
        uint8 taxPercent
    ) private pure returns (uint256) {
        return (amount * tax * taxPercent) / 10000;
    }

    function _addToken(address addr, uint256 amount) private {
        uint256 newAmount = _balances[addr] + amount;
        _balances[addr] = newAmount;
    }

    function _removeToken(address addr, uint256 amount) private {
        uint256 newAmount = _balances[addr] - amount;
        _balances[addr] = newAmount;
    }

    uint256 public revenueBalance;
    uint256 public totalLPETH;

    bool private _isSwappingContractModifier;
    modifier lockTheSwap() {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    function _swapContractToken(uint256 totalMax, uint256 list)
        private
        lockTheSwap
    {
        uint256 contractBalance = _balances[address(this)];
        // Adjust share percentages to 100
        uint unburnedTax = 100 - _list[list].in_burn;
        if (unburnedTax == 0) {
            // Nothing to swap
            return;
        }
        uint liqShare = _list[list].in_liquidity * 100 / unburnedTax;
        uint revenueShare = _list[list].in_revenue * 100 / unburnedTax;

        // Just to avoid math errors
        if (liqShare + revenueShare > 100) {
            revenueShare = 100 - liqShare;
        }

        // Limit contract swaps
        uint256 tokenToSwap = swapLimit;
        if (tokenToSwap > totalMax) {
            if (isSwapPegged) {
                tokenToSwap = totalMax;
            }
        }

        // Check if the contract has enough tokens to swap
        if (contractBalance < tokenToSwap) {
            return;
        }

        // Divide the tokens to swap between liquidity and revenue
        uint256 tokenForLiquidity = (tokenToSwap * _list[list].in_liquidity) /
            100;
        uint256 tokenForRevenue = (tokenToSwap * _list[list].in_revenue) /
            100;

        // Calculate the amount of ETH to add to liquidity
        uint256 liqToken = tokenForLiquidity / 2;
        uint256 liqETHToken = tokenForLiquidity - liqToken;
        // Swap the tokens
        uint256 swapToken = liqETHToken + tokenForRevenue;
        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        uint256 newETH = (address(this).balance - initialETHBalance);
        // Add liquidity
        uint256 liqETH = (newETH * liqETHToken) / swapToken;
        _addLiquidity(liqToken, liqETH);
        // Makes the rest available for revenue
        uint256 generatedETH = (address(this).balance - initialETHBalance);
        revenueBalance += generatedETH;
    }

    function _swapTokenForETH(uint256 amount) private {
        _approve(address(this), address(_UniswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _UniswapRouter.WETH();

        _UniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenamount, uint256 ETHamount) private {
        totalLPETH += ETHamount;
        _approve(address(this), address(_UniswapRouter), tokenamount);
        _UniswapRouter.addLiquidityETH{value: ETHamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    /// @notice Utilities

    function Management_destroy(uint256 amount) public onlyAuth {
        require(_balances[address(this)] >= amount);
        _balances[address(this)] -= amount;
        _circulatingSupply -= amount;
        emit Transfer(address(this), Dead, amount);
    }

    bool public sellLockDisabled;
    bool public manualConversion;

    function Management_SetPeggedSwap(bool isPegged) public onlyAuth {
        isSwapPegged = isPegged;
    }

    function Management_SetMaxSwap(uint256 max) public onlyAuth {
        swapLimit = max;
    }

    /// @notice ACL Functions

    function Controls_BlackListAddress(address addy, bool booly)
        public
        onlyAuth
    {
        _blacklist[addy] = booly;
    }

    function Controls_ExcludeAccountFromFees(address account, bool booly)
        public
        onlyAuth
    {
        _excluded[account] = booly;
    }

    function Controls_ExcludeAccountFromSellLock(address account, bool booly)
        public
        onlyAuth
    {
        _excludedFromSellLock[account] = booly;
    }

    function Administrative_WithdrawRevenueETH() public onlyAuth {
        uint256 amount = revenueBalance;
        revenueBalance = 0;
        address sender = msg.sender;
        (bool sent, ) = sender.call{value: (amount)}("");
        require(sent, "withdraw failed");
    }

    function Management_SwitchManualETHConversion(bool manual) public onlyAuth {
        manualConversion = manual;
    }

    function Management_DisableSellLock(bool disabled) public onlyAuth {
        sellLockDisabled = disabled;
    }

    function Management_ManualGenerateTokenSwapBalance(uint256 _qty)
        public
        onlyAuth
    {
        _swapContractToken(_qty, 0);
    }

    function Controls_EnableTrading(bool booly) public onlyAuth {
        tradingEnabled = booly;
    }

    function Controls_LiquidityTokenAddress(address liquidityTokenAddress)
        public
        onlyAuth
    {
        _liquidityTokenAddress = liquidityTokenAddress;
    }

    function Management_RescueTokens(address tknAddress) public onlyAuth {
        IERC20 token = IERC20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance > 0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    function Management_setBlacklistEnabled(bool isBlacklistEnabled)
        public
        onlyAuth
    {
        isBlacklist = isBlacklistEnabled;
    }

    function Management_setContractTokenSwapManual(bool manual)
        public
        onlyAuth
    {
        isTokenSwapManual = manual;
    }

    function Management_setBlacklistedAddress(address toBlacklist)
        public
        onlyAuth
    {
        _blacklist[toBlacklist] = true;
    }

    function Management_removeBlacklistedAddress(address toRemove)
        public
        onlyAuth
    {
        _blacklist[toRemove] = false;
    }

    function Management_AvoidLocks() public onlyAuth {
        (bool sent, ) = msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _circulatingSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address _owner,
        address spender,
        uint256 amount
    ) private {
        require(_owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
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
        external
        returns (bool)
    {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    // SECTION Setters for lists

    function setBuyTax_For_List(uint256 _tax, uint256 list) external onlyAuth {
        _list[list].buy_tax = _tax;
    }

    function setSellTax_For_List(uint256 _tax, uint256 list) external onlyAuth {
        _list[list].sell_tax = _tax;
    }

    function setTransferTax_For_List(uint256 _tax, uint256 list)
        external
        onlyAuth
    {
        _list[list].transfer_tax = _tax;
    }

    function setBalanceLimit_For_List(uint256 _limit, uint256 list)
        external
        onlyAuth
    {
        _list[list].balance_limit = _limit;
    }

    function setCooldown_For_List(uint256 _cooldown, uint256 list)
        external
        onlyAuth
    {
        _list[list].cooldown_time = _cooldown;
    }

    function setList(address account, uint256 list) external onlyAuth {
        _listOf[account] = list;
    }

    // Helpers
    function getListNumbers() external pure returns (uint _normalist, uint _bluelist, uint _greenlist) {
        return (0, 1, 2);
    }

    function getListProperties(uint list) external view returns (uint256 _buy_tax, uint256 _sell_tax, uint256 _transfer_tax, uint256 _balance_limit, uint256 _cooldown_time) {
        return (_list[list].buy_tax, _list[list].sell_tax, _list[list].transfer_tax, _list[list].balance_limit, _list[list].cooldown_time);
    }


    // !SECTION Setters for lists
}