/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

/* alfa.society:

- https://www.alfasociety.io/
- https://twitter.com/alfasocietyERC
- https://t.me/AlfaSociety

*/

pragma solidity ^0.8.17;

// ANCHOR alfa.society methods
abstract contract alfaSpecials {
    // alfa.society Innovations

    string internal _website = "https://www.alfasociety.io/";
    event Message (string message);
    event answerThePhone (string message);

    // NOTE Communications from the the society to the users
    function _answerThePhone(string memory message) internal {
        emit Message(message);
        emit answerThePhone(message);
    }

    // NOTE Antiphishing Method: you can check the website address of the contract 
    // and compare it with the one on the website
    function getWebsiteAddress() public view returns (string memory) {
        return _website;
    }

    function _changeWebsite(string memory newWebsite) internal {
        _website = newWebsite;
    }
}

abstract contract safetyFirst {
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

// SECTION Interfaces
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721 is ERC165 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external payable;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    function approve(address _approved, uint256 _tokenId) external payable;

    function setApprovalForAll(address _operator, bool _approved) external;

    function getApproved(uint256 _tokenId) external view returns (address);

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

interface IERC20 {
    function getOwner() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

// !SECTION Interfaces
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

library Listables {
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
            "Listables: index out of bounds"
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

    struct ActorSet {
        Set _inner;
    }

    function add(ActorSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(ActorSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(ActorSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(ActorSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(ActorSet storage set, uint256 index)
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

contract alfav3 is IERC20, safetyFirst, alfaSpecials {
    using Listables for Listables.ActorSet;

    string public constant _name = "alfa.society";
    string public constant _symbol = "ALFA";
    uint8 public constant _decimals = 18;
    uint256 public constant InitialSupply = 100 * 10**6 * 10**_decimals;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => uint256) public _coolDown;
    Listables.ActorSet private _excluded;
    Listables.ActorSet private _excludedFromCoolDown;

    mapping(address => bool) public _botlist;
    bool isBotlist = true;

    uint256 swapTreshold = InitialSupply / 200; // 0.5%

    bool isSwapPegged = true;

    uint16 public BuyLimitDivider = 50; // 2%

    uint8 public BalanceLimitDivider = 25; // 4%

    uint16 public SellLimitDivider = 125; // 0.75%

    uint16 public MaxCoolDownTime = 10 seconds;
    bool public coolDownDisabled;
    uint256 public coolDownTime = 2 seconds;
    bool public manualConversion;

    address public constant UniswapRouter =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant Dead = 0x000000000000000000000000000000000000dEaD;

    uint256 public _circulatingSupply = InitialSupply;
    uint256 public balanceLimit = _circulatingSupply;
    uint256 public sellLimit = _circulatingSupply;
    uint256 public buyLimit = _circulatingSupply;

    uint8 public _buyTax = 10;
    uint8 public _sellTax = 20; // INITIAL amount decreasing after 1 day to avoid dumpers
    uint8 public _transferTax = 10;

    // Shares
    uint8 public _liquidityTax = 10;
    uint8 public _projectTax = 90;

    bool isTokenSwapManual;
    bool public antiSnipe;
    bool public tradingEnabled;

    address public _UniswapPairAddress;

    IUniswapRouter02 public _UniswapRouter;

    uint256 public projectBalance;

    bool private _isSwappingContractModifier;
    
    modifier lockTheSwap() {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    constructor() {
        // Ownership
        owner = msg.sender;
        is_auth[msg.sender] = true;
        _balances[msg.sender] = _circulatingSupply;
        emit Transfer(address(0), msg.sender, _circulatingSupply);
        // Defining the Uniswap Router and the Uniswap Pair
        _UniswapRouter = IUniswapRouter02(UniswapRouter);
        _UniswapPairAddress = IUniswapFactory(_UniswapRouter.factory())
            .createPair(address(this), _UniswapRouter.WETH());

        // SECTION Limits, Taxes and Locks
        // Limits
        balanceLimit = InitialSupply / BalanceLimitDivider;
        sellLimit = InitialSupply / SellLimitDivider;
        buyLimit = InitialSupply / BuyLimitDivider;
        // !SECTION Limits, Taxes and Locks

        // SECTION Exclusions
        _excluded.add(msg.sender);
        _excludedFromCoolDown.add(UniswapRouter);
        _excludedFromCoolDown.add(_UniswapPairAddress);
        _excludedFromCoolDown.add(address(this));
        // !SECTION Exclusions
    }

    // NOTE Public transfer method
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "Transfer from zero");

        // Botlist check
        if (isBotlist) {
            require(
                !_botlist[sender] && !_botlist[recipient],
                "Botlisted!"
            );
        }

        // Check if the transfer is to be excluded from cooldown and taxes
        bool isExcluded = (_excluded.contains(sender) ||
            _excluded.contains(recipient) ||
            is_auth[sender] ||
            is_auth[recipient]);

        bool isContractTransfer = (sender == address(this) ||
            recipient == address(this));

        bool isLiquidityTransfer = ((sender == _UniswapPairAddress &&
            recipient == UniswapRouter) ||
            (recipient == _UniswapPairAddress && sender == UniswapRouter));
        if (
            isContractTransfer || isLiquidityTransfer || isExcluded
        ) {
            _whitelistTransfer(sender, recipient, amount);
        } else {
            // If not, check if trading is enabled
            if (!tradingEnabled) {
                // except for the owner
                if (sender != owner && recipient != owner) {
                    // and apply anti-snipe if enabled
                    if (antiSnipe) {
                        emit Transfer(sender, recipient, 0);
                        return;
                    } else {
                        // or revert if not
                        require(tradingEnabled, "trading not yet enabled");
                    }
                }
            }

            // If trading is enabled, check if the transfer is a buy or a sell
            bool isBuy = sender == _UniswapPairAddress ||
                sender == UniswapRouter;
            bool isSell = recipient == _UniswapPairAddress ||
                recipient == UniswapRouter;
            // and initiate the transfer accordingly
            _normalTransfer(sender, recipient, amount, isBuy, isSell);

        }
    }

    // NOTE Transfer method for everyone
    function _normalTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool isBuy,
        bool isSell
    ) private {
        // Read the balances of the recipient locally to save gas as is used twice
        uint256 recipientBalance = _balances[recipient];
        // Apply the requirements
        require(_balances[sender] >= amount, "Transfer exceeds balance");
        // Prepare the tax variable
        uint8 tax;
        // Apply the cooldown for sells
        if (isSell) {
            if (!_excludedFromCoolDown.contains(sender)) {
                require(
                    _coolDown[sender] <= block.timestamp || coolDownDisabled,
                    "Seller in coolDown"
                );
                _coolDown[sender] = block.timestamp + coolDownTime;
            }
            // Sell limit check
            require(amount <= sellLimit, "Dump protection");
            tax = _sellTax;
        } else if (isBuy) {
            // Balance limit check
            require(
                recipientBalance + amount <= balanceLimit,
                "whale protection"
            );
            // Buy limit check
            require(amount <= buyLimit, "whale protection");
            tax = _buyTax;
        } else {
            require(
                // Balance limit check for transfers
                recipientBalance + amount <= balanceLimit,
                "whale protection"
            );
            // Update the cooldown for the sender if not excluded
            if (!_excludedFromCoolDown.contains(sender))
                require(
                    _coolDown[sender] <= block.timestamp || coolDownDisabled,
                    "Sender in Lock"
                );
            tax = _transferTax;
        }

        // Check if the transaction is fit for token swapping
        if (
            (sender != _UniswapPairAddress) &&
            (!manualConversion) &&
            (!_isSwappingContractModifier)
        ) _swapContractToken(amount);

        // Calculating the taxed amount
        uint256 contractToken = _calculateFee(
            amount,
            tax,
            _liquidityTax + _projectTax 
        );
        // Refactoring the various amounts
        uint256 taxedAmount = amount - (contractToken);
        _removeToken(sender, amount);
        _balances[address(this)] += contractToken;
        _addToken(recipient, taxedAmount);
        // Emitting the transfer event
        emit Transfer(sender, recipient, taxedAmount);
    }

    function _whitelistTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        // Basic checks
        require(_balances[sender] >= amount, "Transfer exceeds balance");
        // Plain transfer
        _removeToken(sender, amount);
        _addToken(recipient, amount);
        // Emitting the transfer event
        emit Transfer(sender, recipient, amount);
    }

    // NOTE To fully support decimal operations, we custom calculate the fees
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

    // SECTION Swapping taxes and adding liquidity

    // NOTE Swap tokens on sells to create liquidity
    function _swapContractToken(uint256 totalMax) private lockTheSwap {
        uint256 contractBalance = _balances[address(this)];
        // Do not swap if the contract balance is lower than the swap treshold
        if (contractBalance < swapTreshold) {
            return;
        }

        // Calculate the amount of tokens to swap
        uint16 totalTax = _liquidityTax;
        uint256 tokenToSwap = swapTreshold;
        // Avoid swapping more than the total max of the transaction
        if (swapTreshold > totalMax) {
            if (isSwapPegged) {
                tokenToSwap = totalMax;
            }
        }
        // Avoid swapping if there are no liquidity fees to generate
        if (totalTax == 0) {
            return;
        }

        // Calculate the amount of tokens to work on for liquidity and project
        uint256 tokenForLiquidity = (tokenToSwap * _liquidityTax) / totalTax;
        uint256 tokenForProject = (tokenToSwap * _projectTax) / totalTax;
        // Divide the liquidity tokens in half to add liquidity
        uint256 liqToken = tokenForLiquidity / 2;
        uint256 liqETHToken = tokenForLiquidity - liqToken;
        // Calculate the amount of ETH to swap
        uint256 swapToken = liqETHToken +
            tokenForProject;
        // Swap the tokens for ETH
        uint256 initialETHBalance = address(this).balance;
        _swapTokenForETH(swapToken);
        // Calculate the amount of ETH generated and the amount of ETH to add liquidity with
        uint256 newETH = (address(this).balance - initialETHBalance);
        uint256 liqETH = (newETH * liqETHToken) / swapToken;
        // Add liquidity
        _addLiquidity(liqToken, liqETH);
        // Add the project ETH to the project balance
        uint256 generatedETH = (address(this).balance - initialETHBalance);
        projectBalance += generatedETH;
    }

    // NOTE Basic swap function for swapping tokens on Uniswap-v2 compatible routers
    function _swapTokenForETH(uint256 amount) private {
        // Preapprove the router to spend the tokens
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

    // NOTE Basic add liquidity function for adding liquidity on Uniswap-v2 compatible routers
    function _addLiquidity(uint256 tokenamount, uint256 ETHamount) private {
        // Approve the router to spend the tokens
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
    // !SECTION Swapping taxes and adding liquidity

    /// SECTION Utility functions

    function getLimits()
        public
        view
        returns (uint256 balance, uint256 sell)
    {
        return (balanceLimit, sellLimit);
    }

    function getTaxes()
        public
        view
        returns (
            uint256 projectShare,
            uint256 liquidityShare,
            uint256 buyTax,
            uint256 sellTax,
            uint256 transferTax
        )
    {
        return (
            _projectTax,
            _liquidityTax,
            _buyTax,
            _sellTax,
            _transferTax
        );
    }

    // NOTE The actual cooldown time
    function getCoolDownTimeInSeconds() public view returns (uint256) {
        return coolDownTime;
    }

    // NOTE Pegged swap means that the contract won't dump when the swap treshold is reached
    function SetPeggedSwap(bool isPegged) public onlyAuth {
        isSwapPegged = isPegged;
    }

    // NOTE The token amount that triggers swap on sells
    function SetSwapTreshold(uint256 max) public onlyAuth {
        swapTreshold = max;
    }
    // !SECTION Utility functions

    function BotlistAddress(address addy, bool booly) public onlyAuth {
        _botlist[addy] = booly;
    }

    function ExcludeAccountFromFees(address account) public onlyAuth {
        _excluded.add(account);
    }

    function IncludeAccountToFees(address account) public onlyAuth {
        _excluded.remove(account);
    }

    function ExcludeAccountFromCoolDown(address account) public onlyAuth {
        _excludedFromCoolDown.add(account);
    }

    function IncludeAccountToCoolDown(address account) public onlyAuth {
        _excludedFromCoolDown.remove(account);
    }

    function WithdrawProjectETH() public onlyAuth {
        uint256 amount = projectBalance;
        projectBalance = 0;
        address sender = msg.sender;
        (bool sent, ) = sender.call{value: (amount)}("");
        require(sent, "withdraw failed");
    }

    function SwitchManualETHConversion(bool manual) public onlyAuth {
        manualConversion = manual;
    }

    function DisableCoolDown(bool disabled) public onlyAuth {
        coolDownDisabled = disabled;
    }

    function SetCoolDownTime(uint256 coolDownSeconds) public onlyAuth {
        coolDownTime = coolDownSeconds;
    }

    function SetTaxes(
        uint8 projectTaxes,
        uint8 liquidityTaxes,
        uint8 buyTax,
        uint8 sellTax,
        uint8 transferTax
    ) public onlyAuth {
        uint8 totalTax =
            projectTaxes +
            liquidityTaxes;
        require(totalTax == 100, "Project + Liquidity taxes needs to equal 100%");
        _projectTax = projectTaxes;
        _liquidityTax = liquidityTaxes;

        _buyTax = buyTax;
        _sellTax = sellTax;
        _transferTax = transferTax;
    }

    function ManualGenerateTokenSwapBalance(uint256 _qty)
        public
        onlyAuth
    {
        _swapContractToken(_qty * 10**9);
    }

    function UpdateLimits(uint256 newBalanceLimit, uint256 newSellLimit)
        public
        onlyAuth
    {
        newBalanceLimit = newBalanceLimit * 10**_decimals;
        newSellLimit = newSellLimit * 10**_decimals;
        balanceLimit = newBalanceLimit;
        sellLimit = newSellLimit;
    }

    function EnableTrading(bool booly) public onlyAuth {
        tradingEnabled = booly;
    }

    function LiquidityTokenAddress(address liquidityTokenAddress)
        public
        onlyAuth
    {
        _UniswapPairAddress = liquidityTokenAddress;
    }

    function RescueTokens(address tknAddress) public onlyAuth {
        IERC20 token = IERC20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance > 0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    function setBotlistEnabled(bool isBotlistEnabled)
        public
        onlyAuth
    {
        isBotlist = isBotlistEnabled;
    }

    function setContractTokenSwapManual(bool manual) public onlyAuth {
        isTokenSwapManual = manual;
    }

    function setBotlistedAddress(address toBotlist)
        public
        onlyAuth
    {
        _botlist[toBotlist] = true;
    }

    function removeBotlistedAddress(address toRemove)
        public
        onlyAuth
    {
        _botlist[toRemove] = false;
    }

    function AvoidLocks() public onlyAuth {
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

    // alfa.society Derivations

    function messageFromTeam(string memory message) public onlyAuth {
        _answerThePhone(message);
    }

    function changeWebsite(string memory newWebsite) public onlyAuth {
        _changeWebsite(newWebsite);
    }

}