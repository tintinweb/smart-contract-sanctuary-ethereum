/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/* Welcome to GameTime Inu, the ultimate sports hub. Please grab a front row seat, sit back and relax, while 
investing your hard-earned money, earning the best of the best sports tickets and an unheard amount of ETH jackpots.

Twitter : https://twitter.com/GameTimeInu
Website : https://GameTimeInu.com/
Telegram : https://t.me/GameTimeInu */

interface IDEX_PAIR{
    function sync() external;
}

interface IDEX_FACTORY{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEX_ROUTER{
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address pTo,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address pTo, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address pTo, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

contract GameTime{
    
    IDEX_ROUTER private _router;
    IDEX_PAIR private _liquidity;
    address private _creator;
    string private _name = "GameTime";
    string private _symbol = "GameTime";
    uint8 private _decimals = 2;
    uint256 private _maxSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping (address => uint256)) private _allowances;
    mapping(address => bool) private _excluded;
    bool private _enabled;
    bool private _swapping;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Error(string message);
    event ErrorBytes(bytes message);
    event Tax(address indexed wallet, uint256 amount);

    modifier swapping(){
        _swapping = true;
        _;
        _swapping = false;
    }

    struct Taxes{
        uint8[4] percent;
        uint256[4] tokens;
        address[4] wallets;
        uint8 total;
    }

    struct Limits{
        uint16 buy;
        uint16 sell;
        uint16 wallet;
    }

    struct Blacklist{
        bool active;
        address[] wallets;
        mapping(address => bool) map;
        mapping(address => uint256) index;
        uint256 burn;
    }

    mapping(uint8 => Taxes) private _taxes;
    Limits private _limits;
    mapping(address => bool) public BLACKLIST;
    Blacklist private _blacklist;

    receive() external payable{
        if(msg.sender == _creator){
            if(_balances[address(this)] > 0 && address(this).balance > 0){
                _liquidity = IDEX_PAIR(IDEX_FACTORY(_router.factory()).createPair(address(this), _router.WETH()));
                _router.addLiquidityETH{value:address(this).balance}(
                    address(this),
                    _balances[address(this)],
                    0,
                    0,
                    _creator,
                    block.timestamp
                );
                _blacklist.active = true;
                _enabled = true;
            }
        }
    }

    constructor(){
        _creator = msg.sender;
        _router = IDEX_ROUTER(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _allowances[address(this)][address(_router)] = 2**256 - 1;

        uint256 supply = 2*10**6 * (10**_decimals);
        _update(address(0), msg.sender, supply / 100 * 50);
        _update(address(0), address(this), supply / 100 * 40);

        address[10] memory airdrop = [
            0x43200ee65cC2Be47940850e790e70e232A21673D,
            0xCE74965748540339377DBf22398438d23579655a,
            0x13A4FaE710B1CA3A35677eB455B97EAFE8b0267D,
            0xefDe2f4C3d1FEa040ef173441De88E3A188dFB6a,
            0x738F52e4cd8Ad38B1A006979D8D4baf3688489eC,
            0x3cEA26a8ABa2EC3Bba499f05C0c42345908168CE,
            0x45f8d9B14215fb1C7975b1EBDb81132f6313eBF5,
            0x0DE88e808f193ba3282B6FC0222E59c835a47B64,
            0x19283D17dE3ABa353b1ebE8e709cd22A796F9b39,
            0xDeAd07B2ccd1Ef6fC2de6d074C5B843e81f61853
        ];

        for(uint8 i=0; i<airdrop.length; i++){
            _update(address(0), airdrop[i], supply / 100 * 1);
        }

        _taxes[0].wallets = [address(0), 0xa5891C6A99c1B4eCE68aB4B339Dc6116a56C4B99, 0x7d172463Fe7E37e68979376D496C8969868FdFc7, address(this)];
        _taxes[1].percent = [1, 1, 1, 1];
        _taxes[1].total = 3;
        _taxes[2].percent = [1, 2, 2, 1];
        _taxes[2].total = 5;

        _limits = Limits(10, 0, 20);

        _excluded[address(this)] = true;
        _excluded[msg.sender] = true;
        _excluded[address(_router)] = true;
    }

    function creator() external view returns(address){
        return(_creator);
    }

    function owner() external pure returns(address){
        return(address(0));
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

    function setTaxes(uint8 burn, uint8 jackpot, uint8 marketing, uint8 liquidity, uint8 direction) external{
        require(msg.sender == _creator);
        require((burn + jackpot + marketing + liquidity) <= 10);
        _taxes[direction].percent = [burn, jackpot, marketing, liquidity];
        _taxes[direction].total = jackpot + marketing + liquidity;
    }

    function setTaxWallets(address jackpot, address marketing) external{
        require(msg.sender == _creator);
        _taxes[0].wallets = [address(0), jackpot, marketing, address(this)];
    }

    function setLimits(uint16 buy, uint16 sell, uint16 wallet) external{
        require(msg.sender == _creator);
        _limits = Limits(buy, sell, wallet);
    }

    function stopBlacklist() external{
        require(msg.sender == _creator);
        _blacklist.active = false;
    }

    function removeWalletFromBlacklist(address wallet) external{
        require(msg.sender == _creator);
        BLACKLIST[wallet] = false;
        if(_blacklist.map[wallet]){
            _blacklist.map[wallet] = false;
        }
    }

    function removeWalletsFromBlacklist(address[] memory wallet) external{
        require(msg.sender == _creator);
        for(uint256 i=0; i<wallet.length; i++){
            BLACKLIST[wallet[i]] = false;
            if(_blacklist.map[wallet[i]]){
                _blacklist.map[wallet[i]] = false;
            }
        }
    }

    function burnBlacklistTokens() external{
        require(msg.sender == _creator);
        for(uint256 i=_blacklist.burn; i<((_blacklist.wallets.length > 50) ? 50 : _blacklist.wallets.length); i++){
            address wallet = _blacklist.wallets[i];
            if(BLACKLIST[wallet] && _balances[wallet] > 0) _update(wallet, address(0), _balances[wallet]);
            if(_blacklist.burn < _blacklist.wallets.length) _blacklist.burn++;
        }
    }

    function _update(address from, address to, uint256 amount) private{
        if(from != address(0)){_balances[from] -= amount;}else{_maxSupply += amount;}
        if(to == address(0)){_maxSupply -= amount;}else{_balances[to] += amount;}
        emit Transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) private{
        if(_excluded[from] || _excluded[to]){
            _update(from, to, amount);
        }else{
            require(_enabled);
            if(from == address(_liquidity)){
                _transferTaxes(from, to, amount, 1);
            }else if(to == address(_liquidity)){
                _transferTaxes(from, to, amount, 2);
            }else{
                _transferTaxes(from, to, amount, 0);
            }
        }
    }

    function _transferLimits(address wallet, uint256 amount, uint8 direction) private{
        if(!_excluded[wallet] && wallet != address(_liquidity)){
            if(_blacklist.active){
                BLACKLIST[wallet] = true;
                if(!_blacklist.map[wallet]){
                    _blacklist.wallets.push(wallet);
                    _blacklist.index[wallet] = _blacklist.wallets.length;
                }
            }else{
                require(!BLACKLIST[wallet]);
            }
        }
        uint256 limit = _maxSupply / 1000;
        if(direction == 1){
            if(_limits.buy > 0) require(amount <= (limit * _limits.buy));
            if(_limits.wallet > 0) require((_balances[wallet] + amount) <= (limit * _limits.wallet));
        }else if(direction == 2){
            if(_limits.sell > 0) require(amount <= (limit * _limits.sell));
        }else{
            if(_limits.wallet > 0) require((_balances[wallet] + amount) <= (limit * _limits.wallet));
        }
    }

    function _transferTaxes(address from, address to, uint256 amount, uint8 direction) private{
        uint256 tax = (amount * _taxes[direction].total)/100;
        uint256 pit = (amount * _taxes[direction].percent[0])/100;
        if(pit > 0) _update(from, address(0), pit);
        _update(from, address(this), tax);
        
        uint256 total = tax;
        uint256 n = total / _taxes[direction].total;
        uint256 share;
        for(uint8 i=1; i<_taxes[direction].percent.length; i++){
            if(_taxes[direction].percent[i] > 0){
                share = n * _taxes[direction].percent[i];
                if(share > total) share = total;
                _taxes[direction].tokens[i] += share;
                total -= share;
            }
            if(total <= 0) break;
        }
        if(total > 0) _taxes[direction].tokens[_taxes[direction].percent.length - 1] += total;

        if(from != address(_liquidity) && !_swapping){
            _swap();
        }

        if(direction != 2){
            _transferLimits(to, amount - (tax + pit), direction);
        }else{
            _transferLimits(from, amount - (tax + pit), direction);
        }

        _update(from, to, amount - (tax + pit));
    }

    function _swap() private swapping{
        address[] memory path = new address[](2); path[0] = address(this); path[1] = _router.WETH();
        for(uint8 i=1; i<_taxes[0].percent.length; i++){
            if((_taxes[0].tokens[i] + _taxes[1].tokens[i]  + _taxes[2].tokens[i]) > 0){
                try _router.swapExactTokensForETH(_taxes[0].tokens[i] + _taxes[1].tokens[i]  + _taxes[2].tokens[i], 0, path, _taxes[0].wallets[i], block.timestamp) returns (uint256[] memory amounts){
                    _taxes[0].tokens[i] = 0;  _taxes[1].tokens[i] = 0; _taxes[2].tokens[i] = 0;
                    emit Tax(_taxes[0].wallets[i], amounts[amounts.length - 1]);
                }catch Error(string memory error){
                    emit Error(error);
                }catch(bytes memory error){
                    emit ErrorBytes(error);
                }
            }
        }

        if(address(this).balance > 0){
            path = new address[](2); path[1] = address(this); path[0] = _router.WETH();
            uint256[] memory amountsOut = _router.getAmountsOut(address(this).balance, path);
            uint256 tokens = amountsOut[amountsOut.length - 1];
            if(tokens > 0){
                _update(address(0), address(this), tokens);
                try _router.addLiquidityETH{value:address(this).balance}(address(this), tokens, 0, 0, _creator, block.timestamp){
                    _update(address(_liquidity), address(0), tokens);
                    _liquidity.sync();
                }catch Error(string memory error){
                    _update(address(this), address(0), tokens);
                    emit Error(error);
                }catch(bytes memory error){
                    _update(address(this), address(0), tokens);
                    emit ErrorBytes(error);
                }
            }
        }
    }
}