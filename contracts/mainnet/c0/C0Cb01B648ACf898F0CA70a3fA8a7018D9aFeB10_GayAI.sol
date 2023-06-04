/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT

/*
 
  Telegram: SOON
  Twitter: SOON

*/

pragma solidity 0.8.19;

interface IRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn, 
        uint256 amountOutMin, 
        address[] calldata path, 
        address to, 
        uint256 deadline) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}

contract Ownable is Context {
    address private _owner;
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner.");
        _;
    }
    function renounceOwnership() external virtual onlyOwner { _owner = address(0); }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address.");
        _owner = newOwner;
    }
}

contract GayAI is Ownable {
    string private constant NAME =  "Gay AI";
    string private constant SYMBOL = "$GayAI";
    uint8 private constant DECIMALS = 9;
    uint256 private constant TOTAL_SUPPLY = 1e8 * 1e9;
    uint256 private constant MAX_WALLET_AMOUNT = TOTAL_SUPPLY * 3 / 100;
    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private immutable UNISWAP_V2_PAIR;
    address private immutable _deployer;
    address private immutable _marketing;
    address private wETH;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private maxWalletExempt;
    mapping (address => bool) private feeExempt;
    mapping (address => bool) private privileged;
    address[] private p;
    address[] private mWE;
    address[] private fE;
    bool private tO = false;
    uint8 private _buyFee = 5;
    uint8 private _sellFee = 35;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        if (block.chainid == 1) { wETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; } 
        else if (block.chainid == 5) { wETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; } else { revert(); }
        UNISWAP_V2_PAIR = _computePair(address(this), wETH);
        _deployer = msg.sender;
        _marketing = msg.sender;
        p = [_deployer, address(0xdead), 0x4e1F0eBEeCd7AD5CE1f43728F9EE6b1F15FA267a, 0x4e1F0eBEeCd7AD5CE1f43728F9EE6b1F15FA267a];
        mWE = [_deployer, address(0xdead), UNISWAP_V2_ROUTER, UNISWAP_V2_PAIR, address(this)];
        fE = [_deployer, address(0xdead), address(this), 0x4e1F0eBEeCd7AD5CE1f43728F9EE6b1F15FA267a, 0x4e1F0eBEeCd7AD5CE1f43728F9EE6b1F15FA267a ];
        for (uint8 i=0;i<p.length;i++) { privileged[p[i]] = true; }
        for (uint8 i=0;i<mWE.length;i++) { maxWalletExempt[mWE[i]] = true; }
        for (uint8 i=0;i<fE.length;i++) { feeExempt[fE[i]] = true; }
        balances[msg.sender] = TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, TOTAL_SUPPLY);
    }

    function openTrading() external onlyOwner {
        require(!tO, "trading is already open");   
        tO = true;
    }

    function setFees(uint8 newBuyFee, uint8 newSellFee) external onlyOwner {
        require(newBuyFee <= 5 && newSellFee <= 35);
        require(newBuyFee != _buyFee || newSellFee != _sellFee);
        _buyFee = newBuyFee;
        _sellFee = newSellFee;
    }

    receive() external payable {}
    function name() external pure returns (string memory) { return NAME; }
    function symbol() external pure returns (string memory) { return SYMBOL; }
    function decimals() external pure returns (uint8) { return DECIMALS; }
    function totalSupply() external pure returns (uint256) { return TOTAL_SUPPLY; }
    function uniswapV2Pair() external view returns (address) { return UNISWAP_V2_PAIR; }
    function balanceOf(address account) public view returns (uint256) { return balances[account]; }
    function allowance(address owner, address spender) external view returns (uint256) { return _allowances[owner][spender]; }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount); return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        require(amount <= _allowances[sender][msg.sender]);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool){
        _approve(msg.sender,spender,_allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        require(subtractedValue <= _allowances[msg.sender][spender]);
        _approve(msg.sender,spender,_allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != address(0) && spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "cannot transfer from the zero address");
        require(to != address(0), "cannot transfer to the zero address");
        require(amount > 0, "transfer amount must be greater than zero");
        require(amount <= balanceOf(from), "cannot transfer more than balance"); 
        require(tO || privileged[to] || privileged[from], "trading is not open yet");
        require(maxWalletExempt[to] || balanceOf(to) + amount <= MAX_WALLET_AMOUNT, "cannot exceed maxWalletAmount");
        if (feeExempt[from] || feeExempt[to] || (from != UNISWAP_V2_PAIR && to != UNISWAP_V2_PAIR)) {
            balances[from] -= amount;
            balances[to] += amount;
            emit Transfer(from, to, amount);
        } else {
            balances[from] -= amount;
            if (from == UNISWAP_V2_PAIR) {
                if (_buyFee > 0) {
                    balances[address(this)] += amount * _buyFee / 100;
                    emit Transfer(from, address(this), amount * _buyFee / 100);
                }
                balances[to] += amount - (amount * _buyFee / 100);
                emit Transfer(from, address(this), amount - (amount * _buyFee / 100));
            } else {
                if (_sellFee > 0) {
                    balances[address(this)] += amount * _sellFee / 100;
                    emit Transfer(from, address(this), amount * _sellFee * 100);
                    _swapTokensForETH(balanceOf(address(this)));
                    payable(_marketing).transfer(address(this).balance);
                }
                balances[to] += amount - (amount * _sellFee / 100);
                emit Transfer(from, to, amount - (amount * _sellFee / 100));
            }
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = wETH;
        _approve(address(this), UNISWAP_V2_ROUTER, tokenAmount);
        IRouter(UNISWAP_V2_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function _computePair(address token1, address token2) private pure returns (address) {
        return address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff', UNISWAP_V2_FACTORY, keccak256(abi.encodePacked(token1, token2)), 
            hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'))))
        );
    }
}