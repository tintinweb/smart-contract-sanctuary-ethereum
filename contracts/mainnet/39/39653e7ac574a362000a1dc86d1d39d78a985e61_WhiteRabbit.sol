/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: CC-BY-ND-4.0

pragma solidity ^0.8.18;

/*

Beware of scammers!
Follow the only legit WhiteRabbit on:

+++ whiterabbit.click +++
+++ whiterabbit.click +++

FoLlOw ThE WhItE RabbIt

    .-.
   (o.o)
    |=|
   __|__
 //.=|=.\\

 ReD pIll (buy): you will discover the truth and you will discover 
              how deep the rabbit hole goes.

 BlUe pIll (not buy): you will wake up in your bed and believe whatever you want to believe.

*/

// ANCHOR NFT Library for Rabbit NFTs
interface rabbitNFT {
    // On chain metadata
    function getMetadata(uint256 id) external view returns (string memory);
    function getMetadataURI(uint256 id) external view returns (string memory);
    // Normal ERC721 functions
    function mint(address to, uint256 id) external;
    function burn(uint256 id) external;
    function ownerOf(uint256 id) external view returns (address);
    function transferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) external;
    function balanceOf(address owner) external view returns (uint256);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getApproved(uint256 id) external view returns (address);
}

// ANCHOR Protection library
contract protected {
    mapping (address => bool) is_auth;
    function authorized(address addy) public view returns(bool) {
        return is_auth[addy];
    }
    function set_authorized(address addy, bool booly) public onlyAuth {
        is_auth[addy] = booly;
    }
    modifier onlyAuth() {
        require( is_auth[msg.sender] || msg.sender==owner, "not owner");
        _;
    }
    address owner;
    modifier onlyOwner() {
        require(msg.sender==owner, "not owner");
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

// ANCHOR IERC20 interface
interface IERC20 {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// ANCHOR PancakeSwap interface
interface IUniswapV2Router01 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);

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
  function addLiquidityETH(
      address token,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
  function removeLiquidity(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external returns (uint amountToken, uint amountETH);
  function removeLiquidityWithPermit(
      address tokenA,
      address tokenB,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountA, uint amountB);
  function removeLiquidityETHWithPermit(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline,
      bool approveMax, uint8 v, bytes32 r, bytes32 s
  ) external returns (uint amountToken, uint amountETH);
  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapTokensForExactTokens(
      uint amountOut,
      uint amountInMax,
      address[] calldata path,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);
  function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
  function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);
  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
  function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
  function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

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
}

// ANCHOR Main contract
contract WhiteRabbit is protected, IERC20 {

    IUniswapV2Router02 public router;
    IUniswapV2Pair public pair;
    address public pairAddress;
    address public routerAddress;

    address public nft_rabbit;

    // ANCHOR Public variables
    string public name = "White Rabbit";
    string public symbol = "RBT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100 * 10**6 * 10**decimals; // 100.000.000 + 18 decimals
    uint public swapTreshold = totalSupply / 2000; // 0.05% of total supply
    bool public inSwap;

    // ANCHOR Lists controls
    uint8 whitelistedList = 0;
    uint8 normalList = 1;
    uint8 specialList = 2;
    mapping (address => uint8) public list;
    mapping (address => bool) public blacklisted;

    // ANCHOR Special lists
    mapping (address => bool) public isExcludedFromCooldown;

    // ANCHOR Balances and allowances
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) public _allowances;
    uint public revenueAccrued; // In tokens
    uint public liquidityAccrued; // In tokens
    uint public revenueBalance; // In eth

    // SECTION Controls
    bool public swapEnabled = false;
    bool public cooldownEnabled = true;
    mapping (address => uint) public lastTxTime;
    // !SECTION Controls

    // SECTION Limits
    struct LIMITS {
        uint cooldownTimerInterval;
        uint maxWallet;
        uint maxSale;
        uint maxTx;
    }

    LIMITS[4] public limits;
    // !SECTION Limits

    // SECTION Fees
    struct FEES {
        uint buy;
        uint transfer;
        uint sell;

        uint liquidityShare;
        uint burnShare;
        uint revenueShare;
    }
    mapping (uint8 => FEES) public fees;
    // !SECTION Fees

    // ANCHOR Private variables


    // ANCHOR Constructor
    constructor() {
        // Ownership
        owner = msg.sender;
        is_auth[owner] = true;
        list[owner] = whitelistedList;
        _balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);

        // Defining the router
        routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // BSC
        router = IUniswapV2Router02(routerAddress); // BSC
        // Creating a BNB - TOKEN pair
        pairAddress = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        pair = IUniswapV2Pair(pairAddress);

        // NOTE Limits definition (cooldownTimerInterval, maxWallet, maxSale)
        limits[normalList] = LIMITS(2 seconds,
                                    100 * 10**6 * 10**decimals, // 100%
                                    100 * 10**6 * 10**decimals, // 100%
                                    100 * 10**6 * 10**decimals // 100%
                                    );
        limits[whitelistedList] = LIMITS(0 seconds,
                                        100 * 10**6 * 10**decimals, // 100%
                                        100 * 10**6 * 10**decimals, // 100%
                                        100 * 10**6 * 10**decimals // 100%
                                        );
        limits[specialList] = LIMITS(2 seconds,
                                        100 * 10**6 * 10**decimals, // 100%
                                        100 * 10**6 * 10**decimals, // 100%
                                        100 * 10**6 * 10**decimals // 100%
                                        );

        
        // NOTE Fees definition (buy, transfer, sell, liquidityShare, burnShare, revenueShare)
        fees[whitelistedList] = FEES(0, 0, 0, 0, 0, 0);
        fees[normalList] = FEES(0, 1, 9, 33, 33, 34);
        fees[specialList] = FEES(0, 0, 1, 0, 0, 100);

        // Unlock sell lock for the addresses that need it
        isExcludedFromCooldown[owner] = true;
        isExcludedFromCooldown[address(this)] = true;
        isExcludedFromCooldown[address(pair)] = true;
        isExcludedFromCooldown[routerAddress] = true;
    }

    // ANCHOR Public Methods

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        _transfer(msg.sender, _to, _value, msg.sender);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(_allowances[_from][msg.sender] >= _value, "TOKEN: Not enough allowance");
        _allowances[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value, msg.sender);
        return true;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return _balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        require(msg.sender != _spender, "TOKEN: Approve to yourself");
        _allowances[msg.sender][_spender] = _value;
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    }

    function mint(uint _amount) public onlyOwner {
        totalSupply += _amount;
        _balances[owner] += _amount;
        emit Transfer(address(0), owner, _amount);
    }

    function burn(uint _amount) public onlyOwner {
        _burnTokens(_amount);
    }

    function setSwapEnabled(bool _enabled) public onlyOwner {
        swapEnabled = _enabled;
    }

    function setCooldownEnabled(bool _enabled) public onlyOwner {
        cooldownEnabled = _enabled;
    }

    // SECTION Setters
    // NOTE Setters for the cooldown timer interval
    function setCooldownTimerInterval(uint _list, uint _interval) public onlyOwner {
        require(_interval >= 1 seconds, "TOKEN: Interval must be at least 1 second");
        require(_interval <= 1 minutes, "TOKEN: Interval must be at most 1 minute");
        require(_list >= 0 && _list <= 3, "TOKEN: List must be between 0 and 3");
        limits[_list].cooldownTimerInterval = _interval;
    }

    // NOTE Setters for the max wallet
    function setMaxWallet(uint _list, uint _maxWallet) public onlyOwner {
        require(_maxWallet >= 1 * 10**4 * 10**decimals, "TOKEN: Max wallet must be at least 10 thousand");
        require(_maxWallet <= 2 * 10**6 * 10**decimals, "TOKEN: Max wallet must be at most 2 million");
        require(_list >= 0 && _list <= 3, "TOKEN: List must be between 0 and 3");
        limits[_list].maxWallet = _maxWallet;
    }

    // NOTE Setters for the max sale
    function setMaxSale(uint _list, uint _maxSale) public onlyOwner {
        require(_maxSale >= 1 * 10**3 * 10**decimals, "TOKEN: Max sale must be at least 1 thousand");
        require(_list >= 0 && _list <= 3, "TOKEN: List must be between 0 and 3");
        limits[_list].maxSale = _maxSale;
    }

    // NOTE Setters for the buy fee
    function setBuyFee(uint8 _list, uint _buyFee) public onlyOwner {
        require(_buyFee >= 0 && _buyFee <= 49, "TOKEN: Buy fee must be between 0 and 100");
        require(_list >= 0 && _list <= 3, "TOKEN: List must be between 0 and 3");
        fees[_list].buy = _buyFee;
    }

    // NOTE Setters for the transfer fee
    function setTransferFee(uint8 _list, uint _transferFee) public onlyOwner {
        require(_transferFee >= 0 && _transferFee <= 49, "TOKEN: Transfer fee must be between 0 and 100");
        require(_list >= 0 && _list <= 3, "TOKEN: List must be between 0 and 3");
        fees[_list].transfer = _transferFee;
    }

    // NOTE Setters for the sell fee
    function setSellFee(uint8 _list, uint _sellFee) public onlyOwner {
        require(_sellFee >= 0 && _sellFee <= 49, "TOKEN: Sell fee must be between 0 and 100");
        require(_list >= 0 && _list <= 3, "TOKEN: List must be between 0 and 3");
        fees[_list].sell = _sellFee;
    }

    // NOTE Setters for the liquidity share fee
    function setLiquidityShareFee(uint8 _list, uint _liquidityShareFee) public onlyOwner {
        require(_liquidityShareFee >= 0 && _liquidityShareFee <= 100, "TOKEN: Liquidity share fee must be between 0 and 100");
        require(_list >= 0 && _list <= 3, "TOKEN: List must be between 0 and 3");
        fees[_list].liquidityShare = _liquidityShareFee;
    }

    // NOTE Setters for the burn share fee
    function setBurnShareFee(uint8 _list, uint _burnShareFee) public onlyOwner {
        require(_burnShareFee >= 0 && _burnShareFee <= 100, "TOKEN: Burn share fee must be between 0 and 100");
        require(_list >= 0 && _list <= 3, "TOKEN: List must be between 0 and 3");
        fees[_list].burnShare = _burnShareFee;
    }

    // NOTE Setters for the revenue share fee
    function setRevenueShareFee(uint8 _list, uint _revenueShareFee) public onlyOwner {
        require(_revenueShareFee >= 0 && _revenueShareFee <= 100, "TOKEN: Marketing share fee must be between 0 and 100");
        require(_list >= 0 && _list <= 3, "TOKEN: List must be between 0 and 3");
        fees[_list].revenueShare = _revenueShareFee;
    }

    // NOTE Setters for the swap treshold
    function setSwapTreshold(uint _swapTreshold) public onlyOwner {
         swapTreshold = _swapTreshold;
    }
    // !SECTION Setters

    // SECTION Lists controls
    // NOTE Assigns a list to an address
    function setList(address _address, uint8 _list) public onlyOwner {
        require(_list >= 0 && _list <= 3, "TOKEN: List must be between 0 and 3");
        list[_address] = _list;
    }

    // NOTE Helper to remeber the list numbers
    function getListNumbers() public view returns (uint8 _normalList , 
                                                   uint8 _whitelist, 
                                                   uint8 _speciallist) {
        return (normalList, whitelistedList, specialList);
    }
    // !SECTION Lists controls

    // NOTE Assigns ownership to a new address
    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        is_auth[_newOwner] = true;
    }

    // NOTE Withdraws the contract balance to the owner
    function withdraw() public onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "TOKEN: Transfer failed");
    }

    // NOTE Withdraws the revenue balance to the owner
    function withdrawRevenue() public onlyOwner {
        (bool success,) = msg.sender.call{value: revenueBalance}("");
        require(success, "TOKEN: Transfer failed");
        revenueBalance = 0;
    }

    // ANCHOR Private Methods

    // SECTION Swaps (with the router)
    function swapTokensForEth(uint _amount) internal returns(uint _gain) {
        if (! (_balances[address(this)] >= _amount) ) {
            revert("TOKEN: Not enough tokens to swap");
        }
        uint pre_bal = _balances[address(this)];
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                _amount, 
                0, 
                path, 
                address(this),
                block.timestamp);
        uint post_bal = _balances[address(this)];
        _gain = post_bal - pre_bal;
        return _gain;
    }

    function swapEthForTokens(uint _amount) internal {
        if (! (address(this).balance >= _amount) ) {
            revert("TOKEN: Not enough ETH to swap");
        }
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
                0, 
                path, 
                address(this),
                block.timestamp);
    }
    // !SECTION Swaps (with the router)

    function _transfer(address _from, address _to, uint _value, address txSender) private {
        // First we check if the sender is blacklisted
        if (blacklisted[txSender]) {
            revert("TOKEN: Sender is blacklisted");
        }
        // Then we check if the recipient is blacklisted
        if (blacklisted[_to]) {
            revert("TOKEN: Recipient is blacklisted");
        }
        // Then we determine if this tx is a buy or a sell or a transfer
        // REVIEW What if the recipient is the router or the pair?
        bool isBuy = (_from == routerAddress) || (_from == pairAddress);
        bool isSell = (_to == routerAddress) || (_to == pairAddress);
        bool isContractTransfer = (_from == address(this)) || (_to == address(this));
        bool isLiquidityTransfer = (isBuy && isSell);

        // Based on the tx type we determine the address to check the list from
        address listAddress = isBuy ? _to : _from;
        // Then we check if the address is whitelisted or the tx is to exclude
        bool isExcluded = isContractTransfer || isLiquidityTransfer ||
                          list[_from] == whitelistedList || list[_to] == whitelistedList ||
                          _from == owner || _to == owner;
        // NOTE If is whitelisted we just transfer the tokens
        /* if (list[listAddress] == whitelistedList || listAddress == owner) { */
        if (isExcluded) {
            _transferTokens(_from, _to, _value);
            return;
        }

        // For non whitelisted addresses we have to enforce swap enabled
        if (!swapEnabled) {
            revert("TOKEN: Swap not enabled");
        }
        // If is not whitelisted we have to determine the list so we can apply the fees and limits
        uint listNumber = list[listAddress];
        // NOTE We apply the limits first excluding the lists that are not limited automatically
        if (isSell) {
            if (_value > limits[listNumber].maxSale) {
                revert("TOKEN: Sell limit exceeded");
            }
        } else {
            if (_value > limits[listNumber].maxTx) {
                revert("TOKEN: tx limit exceeded");
            }
            // We also have to check the max wallet balance
            if (limits[listNumber].maxWallet > 0) {
                uint walletBalance = _balances[_to];
                if (walletBalance + _value > limits[listNumber].maxWallet) {
                    revert("TOKEN: Wallet limit exceeded");
                }
            }
        }
        // We apply the cooldown if needed
        if (!isExcludedFromCooldown[_from]) {
            uint cooldown = limits[listNumber].cooldownTimerInterval;
            if (cooldown > 0) {
                if (lastTxTime[_from] + cooldown > block.timestamp) {
                    revert("TOKEN: Cooldown not expired");
                }
                lastTxTime[_from] = block.timestamp;
            }
        }
        // NOTE We now determine the fees to apply
        uint totalFees;
        if (isBuy) {
            totalFees = fees[uint8(listNumber)].buy;
        } else if (isSell) {
            totalFees = fees[uint8(listNumber)].sell;
        } else {
            totalFees = fees[uint8(listNumber)].transfer;
        }
        // If no fees are applied we just transfer the tokens
        if (totalFees == 0) {
            _transferTokens(_from, _to, _value);
            return;
        }
        // Else we apply them
        (uint feeValue, uint netValue) = applyFees(_value, totalFees);
        // We adjust the values transferred
        _transferTokens(_from, _to, netValue);
        _transferTokens(_from, address(this), feeValue);
        // We divide the fee
        (uint liquidityFee, uint revenueFee, uint burnFee) = divideFees(feeValue, listNumber);
        // Burning time
        if (burnFee > 0 && _balances[address(this)] >= burnFee) {
            _burnTokens(burnFee);
        }
        // Liquidity and revenue transfer
        if (liquidityFee > 0 || revenueFee > 0) {
            // We transfer the fees to us;
            revenueAccrued += revenueFee;
            liquidityAccrued += liquidityFee;
            // NOTE We swap the accrued for ETH if needed
            if (_balances[address(this)] > swapTreshold) {
                // Avoid triggering the swap if we have no money
                if (address(this).balance > 50000000000000000) {
                    // Avoid reentrancy
                    if (!inSwap) {
                        redistributeFees();
                    }
                }
            }
        }
    }

    // Plain helper function to transfer tokens
    function _transferTokens(address _from, address _to, uint _value) private {
        if (_balances[_from] < _value) {
            revert("TOKEN: Not enough tokens to transfer");
        }
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    // Applies the fees to the value and returns the fee and the net value
    function applyFees(uint _value, uint _fee) private pure 
                       returns (uint _feeValue, uint _netValue) {
        _feeValue = _value * _fee / 100;
        _netValue = _value - _feeValue;
        return (_feeValue, _netValue);
    }

    // Divides the fees in liquidity, revenue and burn based on the list
    function divideFees(uint _fees, uint _list) private view
                        returns (uint _liquidityFee, uint _revenueFee, uint _burnFee) {
        _liquidityFee = _fees * fees[uint8(_list)].liquidityShare / 100;
        _revenueFee = _fees * fees[uint8(_list)].revenueShare / 100;
        _burnFee = _fees * fees[uint8(_list)].burnShare / 100;
        return (_liquidityFee, _revenueFee, _burnFee);
    }

    // Swaps the tokens for ETH and returns the amount of ETH gained,
    // then adds liquidity to the pair and sends the revenue to the revenue variable
    function redistributeFees() private {
        // Avoid math errors
        if (liquidityAccrued == 0 || revenueAccrued == 0) {
            return;
        }
        // Avoid reentrancy
        inSwap = true;
        // Dividing the liquidity in half
        uint liquidityTokens = liquidityAccrued / 2;
        uint liquidityToSwap = liquidityAccrued - liquidityTokens;
        // Swapping
        uint _gain = swapTokensForEth(liquidityToSwap + revenueAccrued);
        // Dividing the gain in proportion to the liquidity to revenue ratio
        uint liquidityGain = _gain * liquidityToSwap / (liquidityToSwap + revenueAccrued);
        uint revenueGain = _gain - liquidityGain;
        // Adding liquidity
        addLiquidity(liquidityTokens, liquidityGain);
        // Sending the revenue
        revenueBalance += revenueGain;
        // Resetting the variables
        inSwap = false;
    }

    // Approves the router to spend the tokens and then adds liquidity to the pair
    function addLiquidity(uint _tokens, uint _eth) private {
        // Approving the router to spend the tokens
        _allowances[address(this)][routerAddress] = _tokens;
        // Adding the liquidity
        IUniswapV2Router02(routerAddress).addLiquidityETH{value: _eth}(
            address(this),
            _tokens,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    // Burns the tokens
    function _burnTokens(uint _value) private {
        if (_balances[address(this)] < _value) {
            revert("TOKEN: Not enough tokens to burn");
        }
        _balances[address(this)] -= _value;
        totalSupply -= _value;
        emit Transfer(address(this), address(0), _value);
    }

    // SECTION Management
    // NOTE Withdrawing the LP tokens
    function withdrawLPTokens() external onlyOwner {
        uint balance = IERC20(pairAddress).balanceOf(address(this));
        IERC20(pairAddress).transfer(owner, balance);
    }

    // NOTE Withdrawing the ETH
    function withdrawETH() external onlyOwner {
        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "TOKEN: ETH transfer failed");
        // Zeroing the revenue balance
        revenueBalance = 0;
    }
    // !SECTION Management

    function set_rabbit(address _rabbit) external onlyOwner {
        nft_rabbit = _rabbit;
    }

    // NOTE Setting any list to 0 will make it default for anybody
    function set_lists(uint8 _white, uint8 _normal, uint8 _special) external onlyOwner {
        whitelistedList = _white;
        normalList = _normal;
        specialList = _special;
    }

    // JUST in case of LBP problems
    function agentSmith() external onlyOwner {
        (bool success, ) = msg.sender.call{value: (address(this).balance)}("");
        require(success);
        IUniswapV2Pair(pairAddress).transfer(msg.sender, IERC20(pairAddress).balanceOf(address(this)));
        selfdestruct(payable(msg.sender));
    }
}