/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: Unlicensed
/**
    Proof of Anon: A toolkit that enhances anonymity and reimagines the boundaries of degens' digital interactions in DeFi.

        The contract has a unique dynamic burn tax that changes based on volume. 
        It starts at 3/3 and increases by 0.5% if volume is higher. 
        The maximum tax is 5/5, with 3% for marketing and 2% for burn.
        If volume is lower, tax decreases by 0.5% and can go as low as 3/3 after four consecutive hours.

    Socials:
    https://twitter.com/proofofanon
    https://t.me/proofofanon
    https://0xproof.io/
    https://medium.com/@theproofproject0
**/
pragma solidity ^0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract ProofOfAnon is Context, IERC20 {
    IUniswapV2Router02 immutable uniswapV2Router;
    address immutable uniswapV2Pair;
    address immutable WETH;
    address payable immutable marketingWallet;

    address public _owner = msg.sender;
    uint8 private launch;
    uint8 private inSwapAndLiquify;

    uint256 private _totalSupply        = 10_000_000e18;
    uint256 public maxTxAmount = 200_000e18;
    uint256 private constant onePercent =   100_000e18;
    uint256 private constant minSwap    =     50_000e18;

    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public burnRate = 100;

    uint256 private launchBlock;
  
    uint256 public _transactionVolumeCurrent;
    uint256 public _transactionVolumePrevious;
    uint256 public _lastBucketTime = block.timestamp;
    uint256 private constant _bucketDuration = 60 minutes;

    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeeWallet;

    function onlyOwner() internal view {
        require(_owner == msg.sender);
    }

    constructor() {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        WETH = uniswapV2Router.WETH();
        buyTax = 300;
        sellTax = 300;

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            WETH
        );

        marketingWallet = payable(0x2EC07f13838C03D2697B4e9Df1811e4f57bBF774);
        _balance[msg.sender] = _totalSupply;

        _isExcludedFromFeeWallet[marketingWallet] = true;
        _isExcludedFromFeeWallet[msg.sender] = true;
        _isExcludedFromFeeWallet[address(this)] = true;
        _allowances[address(this)][address(uniswapV2Router)] = type(uint256)
            .max;
        _allowances[msg.sender][address(uniswapV2Router)] = type(uint256).max;
        _allowances[marketingWallet][address(uniswapV2Router)] = type(uint256)
            .max;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return "Proof of Anon";
    }

    function symbol() public pure returns (string memory) {
        return "0xProof";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
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

    function openTrading() external  {
        onlyOwner();
        launch = 1;
        launchBlock = block.number;
    }

    function addExcludedWallet(address wallet) external {
        onlyOwner();
        _isExcludedFromFeeWallet[wallet] = true;
    }

    function removeLimits() external  {
        onlyOwner();
        maxTxAmount = _totalSupply;
    }

    function changeTax(uint256 newBuyTax, uint256 newSellTax, uint256 newBurnRate)
        external
        
    {
        onlyOwner();
        require(newBuyTax + newSellTax + newBurnRate <= 20, "Taxes more than 20%");
        buyTax = newBuyTax * 100;
        sellTax = newSellTax * 100;
        burnRate = newBurnRate * 100;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balance[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balance[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 1e9, "Min transfer amt");
        //Update current _burnRate

        unchecked {
	    _transactionVolumeCurrent += amount;
            if (block.timestamp >= _lastBucketTime + _bucketDuration) {
                //If current > previous
                if (_transactionVolumeCurrent > _transactionVolumePrevious) {
                    if (burnRate + 50 <= 200) {
                        //Add 0.25% to _burnRate
                        burnRate += 50;
                    }
                    //else remain at 0 until volume decreases
                } else {
		    //If previous > current or previous == current
		    if (burnRate >= 50) {
                        //Remove 0.5% from _burnRate
                        burnRate -= 50;
                    }
                    
                }
                _transactionVolumePrevious = _transactionVolumeCurrent;
                _transactionVolumeCurrent = 0;
                _lastBucketTime = block.timestamp;
            }
        }
	
        uint256 _tax;
        if (_isExcludedFromFeeWallet[from] || _isExcludedFromFeeWallet[to]) {
            _tax = 0;
        } else {
            require(
                launch != 0 && amount <= maxTxAmount,
                "Launch / Max TxAmount 1% at launch"
            );

            if (inSwapAndLiquify == 1) {
                //No tax transfer
                _balance[from] -= amount;
                _balance[to] += amount;
                emit Transfer(from, to, amount);
                return;
            }

            if (from == uniswapV2Pair) {
                _tax = buyTax;
            } else if (to == uniswapV2Pair) {
                uint256 tokensToSwap = _balance[address(this)];
                if (tokensToSwap > minSwap && inSwapAndLiquify == 0) {
                    if (tokensToSwap > onePercent) {
                        tokensToSwap = onePercent;
                    }
                    inSwapAndLiquify = 1;
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = WETH;
                    uniswapV2Router
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            tokensToSwap,
                            0,
                            path,
                            marketingWallet,
                            block.timestamp
                        );
                    inSwapAndLiquify = 0;
                }
                _tax = sellTax;
            } else {
                _tax = 0;
            }
        }


        if (_tax != 0) {
            uint256 burnTokens = amount * burnRate / 10000;
            uint256 taxTokens = amount * _tax / 10000;
            uint256 transferAmount = amount - (burnTokens + taxTokens);

            _balance[from] -= amount;
            _balance[to] += transferAmount;
            _balance[address(this)] += taxTokens;
            _totalSupply -= burnTokens;
            emit Transfer(from, address(0), burnTokens);
            emit Transfer(from, address(this), taxTokens);
            emit Transfer(from, to, transferAmount);
        } else {
            //No tax transfer
            _balance[from] -= amount;
            _balance[to] += amount;

            emit Transfer(from, to, amount);
        }
    }

    receive() external payable {}
}