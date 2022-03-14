// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
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

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
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
    address private _previousOwner;
    uint256 private _lockTime;

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

// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;

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

contract ODC is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    address payable private treasuryWallet = payable(0xBbD5358D15eEcd098e49Fed583ad5C368bc43E24); // team  Wallet

    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isSniper;
    mapping (address => uint256) _balances;

    uint256 public deadBlocks = 2;
    uint256 public launchedAt;


    uint256 public thresholdPercent = 20;
    uint256 public thresholdDivisor = 1000;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isMaxWalletExempt;
    mapping (address => bool) private _isTrusted;
    mapping (address => uint256) public nonces;
    address[] private _excluded;
    
   
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    uint8 private _decimals = 9;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private _totalSupply = 2 * 10 ** 9 * 10 ** _decimals;


    string private _name = "New Frontier Presents";
    string private _symbol = "NFP";
    string private _version = "1";
    

    uint256 public _maxWalletToken = _totalSupply.div(1000).mul(6); //0.6% for first hour
    uint256 public maxTx = _totalSupply.div(1000).mul(3); //0.3 for first hour

    uint256 public _buyLiquidityFee = 40;
    uint256 public _buytreasuryFee = 40;      

    uint256 public _sellLiquidityFee = 100;
    uint256 public _selltreasuryFee = 100;  


    uint256 private sellTotalFee =
        _sellLiquidityFee.add(_selltreasuryFee);
    //uint256 private currenttotalFee = sellTotalFee;
   
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwap;
    
    bool public tradingOpen = false;
    bool public zeroBuyTaxmode = false;
    bool private antiBotmode = true;
    bool public maxTXEnabled = true;


    //eip 712
    uint256 public immutable deploymentChainId;
    bytes32 private immutable _DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    event AddLiquidity(
        uint256 tokenAmount,
        uint256 amountEth
    );
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }  

    constructor () {

       _balances[msg.sender] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isMaxWalletExempt[owner()] = true;
        _isMaxWalletExempt[address(this)] = true;
        _isMaxWalletExempt[uniswapV2Pair] = true;
        _isMaxWalletExempt[DEAD] = true;
        _isTrusted[owner()] = true;
        _isTrusted[uniswapV2Pair] = true;
        uint256 chainId;
        assembly {chainId := chainid()}
        deploymentChainId = chainId;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId);

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    // 712
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return
        keccak256(
            abi.encode(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ),
            keccak256(bytes(_name)),
            keccak256(bytes(_version)),
            chainId,
            address(this)
            )
        );
    }

    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        uint256 chainId;
        assembly {
        chainId := chainid()
        }
        return chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "Permit-expired");

        uint256 chainId;
        assembly {chainId := chainid()}

        bytes32 digest =
        keccak256(abi.encodePacked(
            "\x19\x01",
            chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId),
            keccak256(abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline
            ))
        ));
        require(owner != address(0) && owner == ecrecover(digest, v, r, s), "Invalid-permit");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isSniper[to], "Sorry no Snippers");
        require(!_isSniper[from], "Sorry no Snippers");
        if (from!= owner() && to!= owner()){
          require(tradingOpen, "Trading not enabled."); //transfers disabled before openTrading
          if(maxTXEnabled){
              require(amount <= maxTx,"over max transaction");
          }
        } 

        uint256 currenttotalFee;
        //take fee on swaps

        if(launchedAt>0 && (!_isMaxWalletExempt[to] && from!= owner()) && ((launchedAt + 240) >= block.number) && antiBotmode){
                require(amount+ balanceOf(to) <= _maxWalletToken,
                    "Total Holding is currently limited");
        }

        if(tradingOpen && to == uniswapV2Pair){//sell
            currenttotalFee = sellTotalFee;
        }

        if(tradingOpen && from == uniswapV2Pair) { //buy
            currenttotalFee= _buyLiquidityFee.add(_buytreasuryFee);
        }
        
        //antibot - first X blocks
        if(launchedAt>0 && (launchedAt + deadBlocks) > block.number){
                _isSniper[to]=true;
        }
        
        //high slippage bot txns go through here
        if(launchedAt>0 && from!= owner() && block.number <= (launchedAt + deadBlocks)  && antiBotmode){
                currenttotalFee=900;    //90%
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || from == owner()){//privileged
            currenttotalFee = 0;
        }

        if(zeroBuyTaxmode){
             if(tradingOpen && from == uniswapV2Pair) { //buys
                    currenttotalFee=0;
             }
        }

        //sell
        if (!inSwap && tradingOpen && to == uniswapV2Pair) {
      
            uint256 contractTokenBalance = balanceOf(address(this));
            
            if(contractTokenBalance >= curentSwapThreshold()){
                    swapAndsendEth();
            }
          
        }
        
        _transferStandard(from, to, amount, currenttotalFee);
    }

    function swapAndsendEth() private lockTheSwap{
        uint256 amountToLiquify;
        if ( _sellLiquidityFee > 0 ){
            amountToLiquify = curentSwapThreshold()
                .mul(_sellLiquidityFee)
                .div(sellTotalFee)
                .div(2);
        }

        swapTokensForEth(amountToLiquify);

        uint256 amountETH = address(this).balance;

        uint256 totalETHFee = sellTotalFee.sub(_sellLiquidityFee.div(2));

        if (sellTotalFee > 0){
            uint256 amountETHLiquidity = amountETH
                .mul(_sellLiquidityFee)
                .div(sellTotalFee)
                .div(2);

            //Send to treasury wallet and liquidity
            if(amountETH > 0) {

                uint256 marketingDevETHAllocation = amountETH
                    .mul(_selltreasuryFee)
                    .div(totalETHFee);

                (bool mSuccess,) = address(treasuryWallet).call{value: marketingDevETHAllocation}("");
                require(mSuccess);
                emit Transfer(address(this),treasuryWallet, marketingDevETHAllocation);
                
                }
            if (amountToLiquify > 0) {
                addLiquidity(amountToLiquify,amountETHLiquidity);
            }
        }
        else{
            if(amountETH > 0){
                (bool mSuccess,) = address(treasuryWallet).call{value: amountETH}("");
                require(mSuccess);
                emit Transfer(address(this),treasuryWallet, amountETH);
            }
        }
    }
   
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

        emit AddLiquidity(tokenAmount, ethAmount);
    }

    function _sendTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
         emit Transfer(sender, recipient, amount);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 curentTotalFee
        ) private {

        if (curentTotalFee == 0) {
            _sendTransfer(sender, recipient, tAmount);
        } 
        else {
            uint256 calcualatedFee = tAmount.mul(curentTotalFee).div(10**3);
            uint256 amountForRecipient = tAmount.sub(calcualatedFee);
            _sendTransfer(sender, recipient, amountForRecipient);
            _sendTransfer(sender, address(this), calcualatedFee);
        }
    }

    function curentSwapThreshold() public view returns(uint256){
        return (balanceOf(uniswapV2Pair).mul(thresholdPercent).div(thresholdDivisor));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function setMaxTx(uint256 amount) external onlyOwner{
      maxTx = amount;
    }
    
    function toggleMaxTx(bool _state) external onlyOwner{
      maxTXEnabled = _state;
    }

    function openTrading(bool _status,uint256 _deadBlocks) external onlyOwner() {
        tradingOpen = _status;
        if(tradingOpen && launchedAt == 0){
            launchedAt = block.number;
            deadBlocks = _deadBlocks;
        }
    }
    
    function setZeroBuyTaxmode(bool _status) external onlyOwner() {
       zeroBuyTaxmode=_status;
    }

    function setAntiBotmode(bool _status) external onlyOwner() {
       antiBotmode=_status;
    }
    
    function setNewRouter(address newRouter) external onlyOwner() {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            uniswapV2Pair = get_pair;
        }
        uniswapV2Router = _newRouter;
    }
    
    function manage_Snipers(address[] calldata addresses, bool status, bool _override) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            if(!_isTrusted[addresses[i]] || _override){
                _isSniper[addresses[i]] = status;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function excludeMultiple(address[] calldata addresses) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isExcludedFromFee[addresses[i]] = true;
        }
    } 
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setTeamWallet(address _wallet) external onlyOwner() {
        treasuryWallet = payable(_wallet);
    }
    
    function manage_trusted(address[] calldata addresses) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isTrusted[addresses[i]]=true;
        }
    }
   
    function withDrawLeftoverETH(address payable receipient) public onlyOwner {
        receipient.transfer(address(this).balance);
    }

    function withdrawStuckTokens(IERC20 token, address to) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(to, balance);
    }

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner() {
        _maxWalletToken = _totalSupply.div(1000).mul(maxWallPercent_base1000);
    }

    function setMaxWalletExempt(address _addr) external onlyOwner {
        _isMaxWalletExempt[_addr] = true;
    }

    function setSwapSettings(uint256 _thresholdPercent, uint256 _thresholdDivisor) external onlyOwner {
        thresholdPercent = _thresholdPercent;
        thresholdDivisor = _thresholdDivisor;
    }

    function manualSwapAndSend() public onlyOwner {
        swapTokensForEth(balanceOf(address(this)));
        (bool mSuccess,) = address(treasuryWallet).call{value: address(this).balance}("");
        require(mSuccess);
    }

    function setTaxesBuy( uint256 _liquidityFee, uint256 _teamFee) external onlyOwner {
       
        _buyLiquidityFee = _liquidityFee;
        _buytreasuryFee = _teamFee;
    
    }

    function setTaxesSell(uint256 _liquidityFee, uint256 _devFee) external onlyOwner {

        _sellLiquidityFee = _liquidityFee;
        _selltreasuryFee = _devFee;
        
        sellTotalFee = _sellLiquidityFee.add(_selltreasuryFee);

    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}