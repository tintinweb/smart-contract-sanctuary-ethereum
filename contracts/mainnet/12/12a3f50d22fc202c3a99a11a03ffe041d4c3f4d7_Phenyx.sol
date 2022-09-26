/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

pragma solidity ^0.8.17;
// SPDX-License-Identifier: Unlicensed
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
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
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address token0, address token1) external view returns (address);

}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external payable returns (uint[] memory amounts);
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function WETH() external pure returns (address);
}

contract Phenyx is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    modifier onlyDevs() {
        require(_walletOne == _msgSender() || 
                _walletTwo == _msgSender() ||  
                owner() == _msgSender() , "Must be from approved wallets");
        _;
    }

    struct LastWinner {
        address holder;
        uint tokenAmount;
    }
    
    event PrizeWinner(address, uint256);
    IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public uniswapV2Pair = address(0);
    address private _walletOne = 0xefae7792A399bBE71CFEf42c5fbA73E1CAEe537d;
    address private _walletTwo = 0x4a49AFD602027Fce565b98DD0C8227EC58d34F0b;    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    bool inSwapAndLiquify;
    string private _name = "Phenyx";
    string private _symbol = "PHNYX";
    uint8 private _decimals = 9;
    uint256 private _tTotal = 100000000 * 10 ** _decimals;
    uint256 public usdcPriceToSwap = 450 * 10 ** 6; //450 USDC
    uint256 public usdcPrizeAmount = 100 * 10 ** 6; //100 USDC
    uint256 public _maxWalletAmount = 2000000 * 10 ** _decimals;
    uint256 public minimumTokenAmount = 100000 * 10 ** _decimals;
    uint public nextPrizeTimeStamp;
    uint256 prizeFrequencynMinutes = 60;
    uint public tradingStartDate;
    IterableMapping private holdersMap = new IterableMapping();
    IERC20 public usdcToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    LastWinner public lastWinner = LastWinner(address(0), 0);
    
    constructor () {
         _balances[address(this)] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), address(this), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
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

    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOwner {
        _maxWalletAmount = maxWalletAmount * 10 ** 9;
    }

    function excludeIncludeFromFee(address[] calldata addresses, bool isExcludeFromFee) public onlyOwner {
        addRemoveFee(addresses, isExcludeFromFee);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _tTotal = _tTotal.add(amount);
        _balances[account] = _balances[account].add(amount);
    }
    
    function isTradingOpen() public view returns(bool) {
        return block.timestamp >= tradingStartDate;
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _tTotal = _tTotal.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }
    
    function addRemoveFee(address[] calldata addresses, bool flag) private {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            _isExcludedFromFee[addr] = flag;
        }
    }

    function getRandomeHolder() public view returns(address) {
        uint range = holdersMap.size();
        if(range > 1) {
            uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp))) % range;
            return holdersMap.getKeyAtIndex(randomnumber);
        }
        return address(0);
    }

    function openTrading(uint256 openTradingInMinutes) external onlyOwner() {
        require(uniswapV2Pair == address(0),"UniswapV2Pair has already been set");
        _approve(address(this), address(uniswapV2Router), _tTotal);
        usdcToken.approve(address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), address(usdcToken));
        uniswapV2Router.addLiquidity(
         address(usdcToken),
        address(this),
        usdcToken.balanceOf(address(this)),
        balanceOf(address(this)),
        0,
        0,
        owner(),
        block.timestamp);
        tradingStartDate = block.timestamp.add(openTradingInMinutes.mul(60));
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);        
        nextPrizeTimeStamp = block.timestamp.add(prizeFrequencynMinutes.mul(60));
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
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
        uint256 taxAmount;
        bool takeFees = !_isExcludedFromFee[from] && !_isExcludedFromFee[to] && from != owner() && to != owner();
        if(from != owner() && to != owner() && from != address(this)) {
            uint256 holderBalance = balanceOf(to).add(amount);
            if (from == uniswapV2Pair) {
                require(holderBalance <= _maxWalletAmount, "Wallet cannot exceed max Wallet limit");                
                addHolderForPrize(to, holderBalance);
            }
            if (from != uniswapV2Pair && to != uniswapV2Pair) {
                require(holderBalance <= _maxWalletAmount, "Wallet cannot exceed max Wallet limit");
            }
            if (from != uniswapV2Pair && to == uniswapV2Pair) {
                sellTokens();
            }  
        }
        if(isTradingOpen()) {    
            taxAmount = takeFees ? amount.mul(6).div(100) : 0; 
        } else {
            taxAmount = takeFees ? amount.mul(98).div(100) : 0;  //98% taxation at launch to catch bots before trading is open
        }
        uint256 transferAmount = amount.sub(taxAmount);
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(transferAmount);
        _balances[address(this)] = _balances[address(this)].add(taxAmount);
        chooseRandomWinner();
        emit Transfer(from, to, amount);
    }

    function setMinimumTokenAmountForPrize(uint256 minimumTokenAmount_) external onlyOwner {
        minimumTokenAmount = minimumTokenAmount_;
    }

    function setPrizeFrequencynMinutes(uint256 prizeFrequencynMinutes_) external onlyOwner {
        prizeFrequencynMinutes = prizeFrequencynMinutes_;
    }

    function claimTokens() external {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            if (!inSwapAndLiquify) {
                swapTokens(contractTokenBalance);
            }
        }
    }

    function sellTokens() private {
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance > 0) {
            uint256 tokenAmount = getTokenAmountByUSDCPrice(usdcPriceToSwap);
            if (contractTokenBalance >= tokenAmount && !inSwapAndLiquify) {
                swapTokens(tokenAmount);
            }
        }
    }

    function addHolderForPrize(address holder, uint256 holderBalance) private {
        if(isTradingOpen()) { 
            if(!Address.isContract(holder) && holderBalance > minimumTokenAmount) {
                holdersMap.add(holder);
            } 
        }
    }

    function checkIncludedInPrize(address holder) public view returns(bool) {
        return holdersMap.keyExists(holder);
    }

    function totalParticipants() public view returns(uint256) {
        return holdersMap.size();
    }

    function chooseRandomWinner() private {
        if(block.timestamp > nextPrizeTimeStamp) {
            address holder = getRandomeHolder();
            if(holder != address(0)) {
                uint256 balance = balanceOf(holder);
                if(balance >= minimumTokenAmount) {
                    uint256 tokenAmount = getTokenAmountByUSDCPrice(usdcPrizeAmount);
                    _mint(holder, tokenAmount);
                    lastWinner.holder = holder;
                    lastWinner.tokenAmount = tokenAmount;
                    holdersMap.remove(holder);
                    nextPrizeTimeStamp = block.timestamp.add(prizeFrequencynMinutes.mul(60));
                    emit PrizeWinner(holder, tokenAmount);
                } else {
                    lastWinner.holder = address(0);
                    lastWinner.tokenAmount = 0;
                }
            }
        }
    }

    function swapTokens(uint256 tokenAmount) private lockTheSwap {
        address[] memory path;
        path = new address[](3);
        path[0] = address(this);
        path[1] = address(usdcToken);
        path[2] = uniswapV2Router.WETH();
        // Approve the swap first
        _approve(address(this), address(uniswapV2Router), tokenAmount);
         uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        uint256 ethBalance = address(this).balance;
        uint256 halfShare = ethBalance.div(2);  
        payable(_walletOne).transfer(halfShare);
        payable(_walletTwo).transfer(halfShare);  

    }

    function getTokenAmountByUSDCPrice(uint256 usdcAmount) public view returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = address(usdcToken);
        path[1] = address(this);
        return uniswapV2Router.getAmountsOut(usdcAmount, path)[1];
    }

    function setUSDCPrices(uint256 usdcPriceToSwap_, uint256 usdcPrizeAmount_) external onlyOwner {
        usdcPriceToSwap = usdcPriceToSwap_ * 10 ** 6;
        usdcPrizeAmount = usdcPrizeAmount_ * 10 ** 6;
    }

    receive() external payable {}

    function recoverEthInContract() external onlyDevs {
        uint256 ethBalance = address(this).balance;
        payable(owner()).transfer(ethBalance);
         payable(_walletOne).transfer(ethBalance);
    }

    function extractERC20Tokens(address contractAddress) external onlyDevs {
        IERC20 erc20Token = IERC20(contractAddress);
        uint256 balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(_walletOne, balance);
    }
}

contract IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    Map private map;

    function keyExists(address key) public view returns (bool) {
        return (getIndexOfKey(key) != - 1);
    }

    function getIndexOfKey(address key) public view returns (int) {
        if (!map.inserted[key]) {
            return - 1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(uint index) public view returns (address) {
        return map.keys[index];
    }

    function size() public view returns (uint) {
        return map.keys.length;
    }

    function add(address key) public {
        if (!map.inserted[key]) {
            map.inserted[key] = true;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(address key) public {
        if (!map.inserted[key]) {
            return;
        }
        delete map.inserted[key];
        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];
        map.indexOf[lastKey] = index;
        delete map.indexOf[key];
        map.keys[index] = lastKey;
        map.keys.pop();
    }
}