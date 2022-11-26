/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: CC BY-ND-NC-4.0

/// @title Cash
/// @author TCSenpai (https://github.com/thecookingsenpai)
/// @notice ERC20 compatible token with advanced features tought for BSC network

/* INFO Features 

- Triple list of users (normal, greenlisted, bluelisted)
- Antibot features
- Antisnipe features
- Whitelist and Blacklist system
- Supported transfers tax free for specific receivers (ex. for payments)
- Supported tax free payment to the contract itself
- Retrieving tokens from the contract
- Burn & Mint
- Auto burn tax 
- Auto liquidity injection tax
- Flexible tax system with antirug features
- Antiwhale features
- Flexible ownership and authorization system
- Optional NFT modifier to execute specific functions

*/


pragma solidity ^0.8.17;

// SECTION Needed interfaces
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
}


interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721 is ERC165 {
  
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


// !SECTION Needed interfaces

// SECTION ERC20 Implementation
interface ERC20 {
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
// !SECTION ERC20 Implementation

// SECTION Pancakeswap interfaces
interface IPancakeswapFactory {
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

interface IPancakeswapRouter01 {
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

    function addLiquidityBNB(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountBNB,
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

    function removeLiquidityBNB(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountBNB);

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

    function removeLiquidityBNBWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountBNB);

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

    function swapExactBNBForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactBNB(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForBNB(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapBNBForExactTokens(
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

interface IPancakeswapRouter02 is IPancakeswapRouter01 {
    function removeLiquidityBNBSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountBNB);

    function removeLiquidityBNBWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountBNBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountBNB);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactBNBForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForBNBSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
// !SECTION Pancakeswap interfaces

// SECTION Ownable and reentrancy protection
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
    modifier onlyowner() {
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

    // NFT Requirement mechanism

    address public NFT_NEEDED;
    bool public isNFTNeeded;

    function change_nft(address nft) public onlyAuth {
        NFT_NEEDED = nft;
    }

    function toggle_nft_needed(bool needed) public onlyAuth {
        isNFTNeeded = needed;
    }

    modifier hasNFT() {
        if (!isNFTNeeded) return;
        ERC721 nft = ERC721(NFT_NEEDED);
        require (nft.balanceOf(msg.sender) != 0, "NFT Not Owned");
        _;
    }

    fallback() external {}
}
// !SECTION Ownable and reentrancy protection

// ANCHOR Actual token contract
contract Cash is ERC20, protected {

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => uint256) public _sellLock;

    mapping(address => bool) public _excludedFromSellLock;

    mapping(address => bool) public _whitelisted;
    mapping(address => bool) public _greenlisted;
    mapping(address => bool) public _bluelisted;
    mapping(address => bool) public _blacklist;
    mapping(address => bool) public _freeReceiver;
    bool isBlacklist = true;



    string public constant _name = "Cash";
    string public constant _symbol = "SH";
    uint8 public constant _decimals = 18;
    uint256 public constant InitialSupply = 100 * 10**6 * 10**_decimals;

    uint256 feeSwapLimit = InitialSupply * 1 / 1000; // 0.1%

    bool isSwapPegged = true;

    uint16 public BuyLimitDivider = 50; // 2%
    uint8 public BalanceLimitDivider = 25; // 4%
    uint16 public SellLimitDivider = 125; // 0.75%

    uint16 public MaxSellLockTime = 10 seconds;

    bool public manualConversion;

    mapping(address => bool) isAuth;

    address public constant PancakeswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
       // 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant Dead = 0x000000000000000000000000000000000000dEaD;

    uint256 public _circulatingSupply = InitialSupply;
    uint256 public balanceLimit = _circulatingSupply / BalanceLimitDivider;
    uint256 public sellLimit = _circulatingSupply / SellLimitDivider;
    uint256 public buyLimit = _circulatingSupply / BuyLimitDivider;

    uint8 public _buyTax = 1;
    uint8 public _blueBuyTax = 1;
    uint8 public _greenBuyTax = 1;
    uint8 public _sellTax = 9;
    uint8 public _blueSellTax = 1;
    uint8 public _greenSellTax = 3;
    uint8 public _transferTax = 1;
    uint8 public _blueTransferTax = 1;
    uint8 public _greenTransferTax = 1;

    // NOTE Distribution of the taxes is as follows (bluelist has all taxes going to company):
    uint8 public _liquidityTax = 34;
    uint8 public _greenLiquidityTax = 34;
    uint8 public _companyTax = 33;
    uint8 public _greenCompanyTax = 33;
    uint8 public _burnTax = 33;
    uint8 public _greenBurnTax = 33;

    bool private _isTokenSwaping;
    uint256 public totalTokenSwapGenerated;
    uint256 public totalPayouts;

    // NOTE Excluding liquidity, the generated taxes are redistributed as:
    uint8 public companyShare = 50;
    uint8 public burnShare = 50;

    uint256 public companyBalance;
    uint256 public burnBalance;

    bool isTokenSwapManual = false;

    address public _PancakeswapPairAddress;
    IPancakeswapRouter02 public _PancakeswapRouter;

    // NOTE Cooldown controls
    bool public sellLockDisabled;
    uint256 public sellLockTime;

    /// @notice The constructor distributes the initial supply to the owner and to the contract
    constructor() {
        
        owner = msg.sender;
        is_auth[owner] = true;

        uint256 deployerBalance = (_circulatingSupply * 9) / 10;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        uint256 injectBalance = _circulatingSupply - deployerBalance;
        _balances[address(this)] = injectBalance;
        emit Transfer(address(0), address(this), injectBalance);
        _PancakeswapRouter = IPancakeswapRouter02(PancakeswapRouter);

        _PancakeswapPairAddress = IPancakeswapFactory(_PancakeswapRouter.factory())
            .createPair(address(this), _PancakeswapRouter.WETH());

        sellLockTime = 2 seconds;

        _whitelisted[msg.sender] = true;
        _excludedFromSellLock[PancakeswapRouter] = true;
        _excludedFromSellLock[_PancakeswapPairAddress] = true;
        _excludedFromSellLock[address(this)] = true;
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

        bool isExcluded = (_whitelisted[sender] ||
            _whitelisted[recipient] ||
            isAuth[sender] ||
            isAuth[recipient]);

        bool isContractTransfer = (sender == address(this) ||
            recipient == address(this));

        bool isLiquidityTransfer = ((sender == _PancakeswapPairAddress &&
            recipient == PancakeswapRouter) ||
            (recipient == _PancakeswapPairAddress && sender == PancakeswapRouter));

        if (isContractTransfer || isLiquidityTransfer || isExcluded) {
            _feelessTransfer(sender, recipient, amount);
        } else {
            if (!tradingEnabled) {
                if (!is_auth[sender] && !is_auth[recipient]) {
                    require(tradingEnabled, "trading not yet enabled");
                }
            }

            bool isBuy = sender == _PancakeswapPairAddress ||
                sender == PancakeswapRouter;
            bool isSell = recipient == _PancakeswapPairAddress ||
                recipient == PancakeswapRouter;
            // Free transfers to certain addresses
            if((!isBuy && !isSell) && _freeReceiver[recipient]) {
                _feelessTransfer(sender, recipient, amount);
            } else {
                _taxedTransfer(sender, recipient, amount, isBuy, isSell);
            }
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

        feeSwapLimit = sellLimit / 2;

        // NOTE This variable will simply hold the taxes to use in this swap
        uint8 tax;

        // ANCHOR sells
        if (isSell) {
            // Green and Blue list are excluded from limits and have their taxes
            if (_greenlisted[sender]) {
                tax = _greenSellTax;
            } else if (_bluelisted[sender]) {
                tax = _blueSellTax;
            } else {
                // Unlisted accounts have their taxes and limits
                if (!_excludedFromSellLock[sender]) {
                    require(
                        _sellLock[sender] <= block.timestamp || sellLockDisabled,
                        "Seller in sellLock"
                    );
                    _sellLock[sender] = block.timestamp + sellLockTime;
                }

                require(amount <= sellLimit, "Dump protection");
                tax = _sellTax;
            }
        } 
        // ANCHOR Buys
        else if (isBuy) {    
            // Green and Blue list are excluded from limits and have their taxes
            if (_greenlisted[sender]) {
                tax = _greenBuyTax;
            } else if (_bluelisted[sender]) {
                tax = _blueBuyTax;
            } else {
                // Unlisted accounts have their taxes and limits
                require(
                    recipientBalance + amount <= balanceLimit,
                    "whale protection"
                );
                require(amount <= buyLimit, "whale protection");
                tax = _buyTax;
            }
        } 
        // ANCHOR Transfers
        else {
            // If is freeReceiver, is a whitelist
            if(_freeReceiver[recipient]) {

            }    
            // Green and Blue list are excluded from limits and have their taxes
            if (_greenlisted[sender]) {
                tax = _greenTransferTax;
            } else if (_bluelisted[sender]) {
                tax = _blueTransferTax;
            } else {
                // Unlisted accounts have their taxes and limits
                require(
                recipientBalance + amount <= balanceLimit,
                "whale protection"
                );
                if (!_excludedFromSellLock[sender])
                    require(
                        _sellLock[sender] <= block.timestamp || sellLockDisabled,
                        "Sender in Lock"
                    );
                tax = _transferTax;
            }
        }
        // Blue and Green list custom divisions
        uint8 _actualCompanyTax;
        uint8 _actualBurnTax;
        uint8 _actualLiquidityTax;
        if (_greenlisted[sender]) {
            _actualCompanyTax = _greenCompanyTax;
            _actualBurnTax = _greenBurnTax;
            _actualLiquidityTax = _greenLiquidityTax;
        } else if (_bluelisted[sender]) {
            // Bluelist has its own rules due to _actualCompanyTax being 100
            _actualCompanyTax = 100;
            _actualBurnTax = 0;
            _actualLiquidityTax = 0;
        } else {
            _actualCompanyTax = _companyTax;
            _actualBurnTax = _burnTax;
            _actualLiquidityTax = _liquidityTax;
        }
        // Check if is swap time
        if (
            (sender != _PancakeswapPairAddress) &&
            (!manualConversion) &&
            (!_isSwappingContractModifier)
        ) _swapContractToken(amount, _actualCompanyTax, _actualBurnTax, _actualLiquidityTax);
        uint256 contractToken = _calculateFee(
            amount,
            tax,
            _actualCompanyTax + _actualLiquidityTax + _actualBurnTax
        );
        uint256 taxedAmount = amount - (contractToken);

        _removeToken(sender, amount);

        _balances[address(this)] += contractToken;

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

    function _distributeFeesBNB(uint256 BNBamount) private {
        uint256 companySplit = (BNBamount * companyShare) / 100;
        companyBalance += companySplit;    
    }

    uint256 public totalLPBNB;

    /// @dev This modifier is used to apply a custom reentrancy guard to the _swapContractToken function
    bool private _isSwappingContractModifier;
    modifier lockTheSwap() {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    /// @dev This function is used to swap the contract token for BNB and distribute the BNB to the company and burn wallets
    function _swapContractToken(uint256 totalMax,
                                uint8 liqTax,
                                uint8 burnTax,
                                uint8 compTax) private lockTheSwap {
        uint256 contractBalance = _balances[address(this)];
        uint16 totalTax = liqTax + compTax;
        uint256 tokenToSwap = feeSwapLimit;
        if (tokenToSwap > totalMax) {
            if (isSwapPegged) {
                tokenToSwap = totalMax;
            }
        }
        if (contractBalance < tokenToSwap || totalTax == 0) {
            return;
        }
        // Bluelist stopcode
        if (compTax == 100) {
            _bluelistSwapTokenForBNB(totalMax);
            return;
        }
        uint256 tokenForLiquidity = (tokenToSwap * liqTax) / totalTax;
        uint256 tokenForCompany = (tokenToSwap * compTax) / totalTax;
        uint256 tokenForburn = (tokenToSwap * burnTax) / totalTax;

        uint256 liqToken = tokenForLiquidity / 2;
        uint256 liqBNBToken = tokenForLiquidity - liqToken;
        // Burn tokens
        _burn_tokens(tokenForburn);
        uint256 swapToken = liqBNBToken + tokenForCompany;
        uint256 initialBNBBalance = address(this).balance;
        _swapTokenForBNB(swapToken);
        uint256 newETH = (address(this).balance - initialBNBBalance);
        uint256 liqBNB = (newETH * liqBNBToken) / swapToken;
        _addLiquidity(liqToken, liqBNB);
        uint256 generatedBNB = (address(this).balance - initialBNBBalance);
        _distributeFeesBNB(generatedBNB);
    }

    function _swapTokenForBNB(uint256 amount) private {
        _approve(address(this), address(_PancakeswapRouter), amount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _PancakeswapRouter.WETH();

        _PancakeswapRouter.swapExactTokensForBNBSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    // Direct 100% company balance for bluelisted
    function _bluelistSwapTokenForBNB(uint256 amount) private {
        uint preBal = address(this).balance;
        _swapTokenForBNB(amount);
        uint postBal = address(this).balance;
        uint generatedBNB = postBal - preBal;
        companyBalance += generatedBNB;
    }

    function _addLiquidity(uint256 tokenamount, uint256 BNBamount) private {
        totalLPBNB += BNBamount;
        _approve(address(this), address(_PancakeswapRouter), tokenamount);
        _PancakeswapRouter.addLiquidityBNB{value: BNBamount}(
            address(this),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    /// @notice Utilities

    /// @notice Returns the current limits for buy and sell transactions (in wei)
    function getLimits() public view returns (uint256 balance, uint256 sell) {
        return (balanceLimit, sellLimit);
    }

    /// @notice Returns the current tax rates for buy, sell and transfer transactions, as well as the distributions for liquidity, company and burn
    function getTaxes()
        public
        view
        returns (
            uint256 burnTax,
            uint256 liquidityTax,
            uint256 companyTax,
            uint256 buyTax,
            uint256 sellTax,
            uint256 transferTax
        )
    {
        return (
            _burnTax,
            _liquidityTax,
            _companyTax,
            _buyTax,
            _sellTax,
            _transferTax
        );
    }

    /// @notice Returns the actual cooldown time for a specific address
    function getAddressSellLockTimeInSeconds(address AddressToCheck)
        public
        view
        returns (uint256)
    {
        uint256 lockTime = _sellLock[AddressToCheck];
        if (lockTime <= block.timestamp) {
            return 0;
        }
        return lockTime - block.timestamp;
    }

    /// @notice Returns the cooldown default time
    function getSellLockTimeInSeconds() public view returns (uint256) {
        return sellLockTime;
    }

    /// @notice Enable or disable the limit for the contract's swaps to be pegged to the tx value at max
    function SetPeggedSwap(bool isPegged) public onlyAuth {
        isSwapPegged = isPegged;
    }

    /// @notice Sets the limits to the contract swaps
    function SetMaxSwap(uint256 max) public onlyAuth {
        feeSwapLimit = max;
    }

    /// @notice Prevents from honeypotting by setting a max cooldown value
    function SetMaxLockTime(uint16 max) public onlyAuth {
        MaxSellLockTime = max;
    }

    /// @notice ACL Functions

    /// @notice Adds an address to the admin list
    function SetAuth(address addy, bool booly) public onlyAuth {
        isAuth[addy] = booly;
    }

    /// @notice Adds an address to the permanently cooled down list
    function AddressStop() public onlyAuth {
        _sellLock[msg.sender] = block.timestamp + (365 days);
    }


    /// @notice Returns if an address is blacklisted or not
    function isAddressInBlackList(address addy, bool booly) public onlyAuth {
        _blacklist[addy] = booly;
    }

    /// @notice Returns if an address is whitelisted or not
    function isAccountInFees(address account, bool isIn) public onlyAuth {
        if(isIn){
            _whitelisted[account] = true;
        } else {
            _whitelisted[account] = false;
        }
    }

    /// @notice Returns if an address is limited by cooldown or not
    function isAccountInSellLock(address account, bool isIn) public onlyAuth {
        if(isIn){
            _excludedFromSellLock[account] = true;
        } else {
            _excludedFromSellLock[account] = false;
        }
    }

    /// @notice Gets the company balance BNB
    function WithdrawCompanyBNB() public onlyAuth {
        uint256 amount = companyBalance;
        companyBalance = 0;
        address sender = msg.sender;
        (bool sent, ) = sender.call{value: (amount)}("");
        require(sent, "withdraw failed");
    }

    /// @notice Set the swap of tokens to be manual or automatic
    function SwitchManualBNBConversion(bool manual) public onlyAuth {
        manualConversion = manual;
    }

    /// @notice Disable cooldown
    function DisableSellLock(bool disabled) public onlyAuth {
        sellLockDisabled = disabled;
    }

    /// @notice Estabilish the cooldown default time
    function SetSellLockTime(uint256 sellLockSeconds) public onlyAuth {
        sellLockTime = sellLockSeconds;
    }

    /// @notice Set taxes and distributions for buy, sell and transfer transactions
    function SetTaxes(
        uint8 burnTaxes,
        uint8 liquidityTaxes,
        uint8 companyTaxes,
        uint8 buyTax,
        uint8 sellTax,
        uint8 transferTax
    ) public onlyAuth {
        // Antirug
        require((buyTax <= 10) && (sellTax <= 10) && (transferTax <= 10), "Antirug protection");
        uint8 totalTax = 
            burnTaxes +
            liquidityTaxes +
            companyTaxes;
        require(totalTax == 100, "Totalt axes needs to equal 100%");
        _burnTax = burnTaxes;
        _liquidityTax = liquidityTaxes;
        _companyTax = companyTaxes;

        _buyTax = buyTax;
        _sellTax = sellTax;
        _transferTax = transferTax;
    }

    function SetBlueTaxes(
        uint8 buyTax,
        uint8 sellTax,
        uint8 transferTax
    ) public onlyAuth {
        // Antirug
        require((buyTax <= 10) && (sellTax <= 10) && (transferTax <= 10), "Antirug protection");

        _blueBuyTax = buyTax;
        _blueSellTax = sellTax;
        _blueTransferTax = transferTax;
    }

    function setGreenTaxes(
        uint8 burnTaxes,
        uint8 liquidityTaxes,
        uint8 companyTaxes,
        uint8 buyTax,
        uint8 sellTax,
        uint8 transferTax
    ) public onlyAuth {
        // Antirug
        require((buyTax <= 10) && (sellTax <= 10) && (transferTax <= 10), "Antirug protection");
        uint8 totalTax = 
            burnTaxes +
            liquidityTaxes +
            companyTaxes;
        require(totalTax == 100, "Totalt axes needs to equal 100%");
        _greenBurnTax = burnTaxes;
        _greenLiquidityTax = liquidityTaxes;
        _greenCompanyTax = companyTaxes;

        _greenBuyTax = buyTax;
        _greenSellTax = sellTax;
        _greenTransferTax = transferTax;
    }

    /// @notice Change the company share of the fees
    function ChangeCompanyShare(uint8 newShare) public onlyAuth {
        companyShare = newShare;
    }

    /// @notice Change the burn share of the fees
    function ChangeBurnShare(uint8 newShare) public onlyAuth {
        burnShare = newShare;
    }

    /// @notice Manually swap some tokens from the contract
    function ManualGenerateTokenSwapBalance(uint256 _qty) public onlyAuth {
        _swapContractToken((_qty * 10**9), _liquidityTax, _companyTax, _burnTax);
    }

    function UpdateLimits(uint256 newBalanceLimit, uint256 newSellLimit)
        public
        onlyAuth
    {
        // Antirug - avoid sell limit to be < 0,1%
        uint lowerLimit = _circulatingSupply / 1000;
        require(newSellLimit >= lowerLimit);

        balanceLimit = newBalanceLimit ;
        sellLimit = newSellLimit;
    }

    bool public tradingEnabled;
    address private _liquidityTokenAddress;

    function EnableTrading(bool booly) public onlyAuth {
        tradingEnabled = booly;
    }

    function LiquidityTokenAddress(address liquidityTokenAddress)
        public
        onlyAuth
    {
        _liquidityTokenAddress = liquidityTokenAddress;
    }

    function RescueTokens(address tknAddress) public onlyAuth {
        ERC20 token = ERC20(tknAddress);
        uint256 ourBalance = token.balanceOf(address(this));
        require(ourBalance > 0, "No tokens in our balance");
        token.transfer(msg.sender, ourBalance);
    }

    function setBlacklistEnabled(bool isBlacklistEnabled) public onlyAuth {
        isBlacklist = isBlacklistEnabled;
    }

    function setContractTokenSwapManual(bool manual) public onlyAuth {
        isTokenSwapManual = manual;
    }

    // Setting and removing from lists (non blacklisted lists are exclusive)

    function setBlacklistedAddress(address toBlacklist) public onlyAuth {
        _blacklist[toBlacklist] = true;
    }

    function removeBlacklistedAddress(address toRemove) public onlyAuth {
        _blacklist[toRemove] = false;
    }

    function setWhitelistedAddress(address toWhitelist) public onlyAuth {
        if(_greenlisted[toWhitelist] == true){
            _greenlisted[toWhitelist] = false;
        }
        if(_bluelisted[toWhitelist] == true){
            _bluelisted[toWhitelist] = false;
        }
        _whitelisted[toWhitelist] = true;
    }

    function removeWhitelistedAddress(address toRemove) public onlyAuth {
        _whitelisted[toRemove] = false;
    }

    function setBluelistedAddress(address toWhitelist) public onlyAuth {
        if(_greenlisted[toWhitelist] == true){
            _greenlisted[toWhitelist] = false;
        }
        if(_whitelisted[toWhitelist] == true){
            _whitelisted[toWhitelist] = false;
        }
        _bluelisted[toWhitelist] = true;
    }

    function removeBluelistedAddress(address toRemove) public onlyAuth {
        _bluelisted[toRemove] = false;
    }

    function setGreenlistedAddress(address toWhitelist) public onlyAuth {
        if(_bluelisted[toWhitelist] == true){
            _bluelisted[toWhitelist] = false;
        }
        if(_whitelisted[toWhitelist] == true){
            _whitelisted[toWhitelist] = false;
        }
        _greenlisted[toWhitelist] = true;
    }

    function removeGreenlistedAddress(address toRemove) public onlyAuth {
        _greenlisted[toRemove] = false;
    }

    // Other utilities

    function AvoidLocks() public onlyAuth {
        (bool sent, ) = msg.sender.call{value: (address(this).balance)}("");
        require(sent);
    }

    // SECTION Burn and Mint

    function mint_tokens(uint qty) external onlyAuth {
        _circulatingSupply += qty;
        _balances[address(this)] += qty;
    }

    function burn_tokens(uint qty) public onlyAuth {
        _burn_tokens(qty);
    }

    function _burn_tokens(uint qty) internal {
        require(_balances[address(this)] >= qty, "Not enough tokens to burn");
        require(_circulatingSupply >= qty, "Not enough tokens to burn");
        _circulatingSupply -= qty;
        _balances[address(this)] -= qty;
    }

    // !SECTION Burn and Mint

    // SECTION Custom whitelistes and payment system

    function setFreeAddress(address toFree) public onlyAuth {
        _freeReceiver[toFree] = true;
    }

    function removeFreeAddress(address toRemove) public onlyAuth {
        _freeReceiver[toRemove] = false;
    }

    // Money received is added to company balance
    receive() external payable {
        companyBalance += msg.value;
    }

    // !SECTION Custom whitelistes and payment system

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
}