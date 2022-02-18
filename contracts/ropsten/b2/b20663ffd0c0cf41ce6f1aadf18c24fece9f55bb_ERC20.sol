/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Address {
 
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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


contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "NFTEYE";
    string private _symbol = "NFTE";
    uint8 private _decimals = 18;

    // pancakeswap v2router
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapPair;

    bool lock;

    // 市值地址
    address marketAddress = 0x4548943a228f401366e5F7F7ACfcCb1372cBcCc2;
    // 营销地址
    address marketingAddress = 0x039CBda625Fd93d25365D24235DE864A7e926917;

    // 存储推荐关系
    mapping(address => address) public recommenderMap;
    // 特殊地址不存储推荐关系
    mapping(address => bool) private recommendSpecialAddresses;
    uint8 private lpRate = 10;
    uint8 private lpShareRate = 20;
    uint8 private marketRate = 10;
    uint8 private marketingRate = 10;
    uint8 private burnRate = 10;
    // 推荐奖励比例
    uint8[] private levelBonusRate = [20, 5, 5, 4, 4, 4, 4, 4];
    uint private levelBonusMinLP = 10 * 10 ** 18;
    // 特殊账号不扣手续费
    mapping(address => bool) private specialAddresses;

    uint private minToLPToken = 10 ** _decimals;

    modifier lockSwap() {
        require(!lock, "ERC20: locked");
        lock = true;
        _;
        lock = false;
    }

    constructor() {
        _mint(_msgSender(), 6000000 * 10 ** _decimals);

        // 创建交易对：本币<=>WETH
        uniswapPair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        specialAddresses[address(this)] = true;
        specialAddresses[marketAddress] = true;
        specialAddresses[marketingAddress] = true;
        specialAddresses[_msgSender()] = true;
    }

    /// 设置不存储推荐关系的特殊地址
    function setRecommendSpecialAddresses(address _addr, bool state) public onlyOwner {
        recommendSpecialAddresses[_addr] = state;
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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;

        // 记录推荐关系
        _saveRecommend(sender, recipient);
    
        // 计算税费
        uint finalAmount = _countFee(sender, recipient, amount);

        // lp处理
        if (balanceOf(address(this)) >= minToLPToken) {
            _swapForLiquidity();
        }

        _balances[recipient] += finalAmount;
        emit Transfer(sender, recipient, finalAmount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;

        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // 计算税费
    function _countFee(address _sender, address _recipient, uint _amount) private returns(uint finalAmount) {
        // 买入或卖出
        if (_sender == uniswapPair || _recipient == uniswapPair) {
            if (_amount < 1000 || specialAddresses[_sender] || specialAddresses[_recipient]) {
                finalAmount = _amount;
            } else {
                uint lpFee = _amount * lpRate / 1000;
                uint lpShareFee = _amount * lpShareRate / 1000;
                uint marketFee = _amount * marketRate / 1000;
                uint marketingFee = _amount * marketingRate / 1000;
                uint burnFee = _amount * burnRate / 1000;

                (uint level, uint totalRate) = _countLevel();
                uint bonusFee = _amount * totalRate / 1000;
                finalAmount = _amount - lpFee - lpShareFee - marketFee - marketingFee - burnFee - bonusFee;
                if (level > 0) {
                    bonusFee -= _countBonus(level, _sender, _recipient, _amount);
                }
                
                // 市值
                _addBalance(_sender, marketAddress, marketFee + bonusFee);

                // 营销
                _addBalance(_sender, marketingAddress, marketingFee);

                // lp
                _addBalance(_sender, address(this), lpFee + lpShareFee);

                // burn
                 _addBalance(_sender, address(0), burnFee);
            }
        } else {
            finalAmount = _amount;
        }

        return finalAmount;
    }

    function _countBonus(uint level, address _sender, address _recipient, uint _amount) private returns(uint finalBonusFee) {
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapPair);
        address recipient = _recipient;
        for (uint i = 0 ; i < level ; i++) {
            address recommender = recommenderMap[recipient];
            if (recommender == address(0)) {
                break;
            }

            if (levelBonusMinLP != 0 && pair.balanceOf(recommender) < levelBonusMinLP) {
                continue;
            }

            uint bonus = _amount * levelBonusRate[i] / 1000;
            _addBalance(_sender, recommender, bonus);
            finalBonusFee += bonus;
        }
    }

    function _addBalance(address _from, address _to, uint _amount) private {
        _balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }

    function _swapForLiquidity() private lockSwap {
        uint256 tokens = balanceOf(address(this));
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialEthBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half);

        uint256 newEthBalance = address(this).balance - (initialEthBalance);

        uint256 lpToken = otherHalf * lpRate / (lpRate + lpShareRate);
        uint256 lpEth = newEthBalance * lpRate / (lpRate + lpShareRate);
        uint256 lpShareToken = otherHalf - lpToken;
        uint256 lpShareEth = newEthBalance - lpEth;

        _addLiquidity(lpToken, lpEth);
        _liquidityShare(lpShareToken, lpShareEth);
    }

    // 自动添加流动池
    function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        if (_tokenAmount == 0 || _ethAmount == 0) {
            return;
        }
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), _tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value : _ethAmount}(
            address(this),
            _tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    // 流动池分红
    function _liquidityShare(uint _tokenAmount, uint _ethAmount) private {
        if (_tokenAmount == 0 || _ethAmount == 0) {
            return;
        }
        // 直接转入pair
        _baseTransfer(address(this), uniswapPair, _tokenAmount);
        // 将ETH兑换成WETH，它调用了WETH合约的兑换接口，这些接口在IWETH.sol中定义
        IWETH(uniswapV2Router.WETH()).deposit{value: _ethAmount}();
        // 将刚刚兑换的WETH转移至交易对合约，注意它直接调用的WETH合约，因此不是授权交易，不需要授权
        assert(IWETH(uniswapV2Router.WETH()).transfer(uniswapPair, _ethAmount));

        IUniswapV2Pair pair = IUniswapV2Pair(uniswapPair);
        pair.sync();
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        // 卖出指定数量的初始TOKEN，最后得到一定数量的ETH，同时支持使用转移的代币支付手续费
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }

    function _countLevel() private view returns(uint level, uint totalRate) {
        uint t;
        for (uint i ; i < levelBonusRate.length ; i++) {
            if (levelBonusRate[i] > 0) {
                totalRate += levelBonusRate[i];
                t = 0;
            } else {
                t++;
            }
        }

        level = levelBonusRate.length - t;
    }


    function _saveRecommend(address _sender, address _recipient) private {
        // 接收者地址余额不为0
        // 接收者地址已经了存储推荐者地址
        if (_balances[_recipient] != 0 || recommenderMap[_recipient] != address(0)) {
            return;
        }

        // 如果用户直接从交易所买入，推荐者默认为市值账号
        if (_sender == uniswapPair) {
            _sender = marketAddress;
        }

        // 判断是否为合约地址和0地址
        if (Address.isContract(_sender) 
            || Address.isContract(_recipient)
            || _sender == address(0)
            || _recipient == address(0)) {
            return;
        }

        // 判断特殊账号
        if (recommendSpecialAddresses[_sender]
            || recommendSpecialAddresses[_recipient]) {
            return;
        }

        recommenderMap[_recipient] = _sender;
    }

    function _baseTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
         _balances[sender] = senderBalance - amount;
        
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
}