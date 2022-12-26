/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.0;
interface IERC20 {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Ownable is Context, Pausable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner whenNotPaused {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner whenNotPaused {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {
   
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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
 contract Create is Context, IERC20, IERC20Metadata, Pausable, Ownable{
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromDexFee;
    mapping (address => bool) public _isIncludedinFee;
    //address[] private _excluded;
    // mapping (address => bool) private _isExcluded;
    // mapping (address => uint256) private _rOwned; //
    // uint256 private _rTotal = (MAX - (MAX % _tTotal)); 
    //   uint256 public totaltranactionfee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private totalsupply = 100000000 * 10 ** 18; // intially 550000000000 
    uint256 public totaltradefee;
    string private constant _name = "Indie Creator Token";
    string private constant _symbol = "CREATE";
    uint8 private constant _decimals = 18;
    address public createProductionsWallet;  
    address public cryptoTokenWallet;  
    address public nftWallet;
    address public shortVideoWallet; 
    address public musicWallet; 
    address public eventsWallet;
    //address public developmentWallet;
    address public marketingWallet;
    address public staffWageWallet;

//fee percentages
    uint256 public createProductionsFee = 150;
    uint256 public cryptoTokenFee = 150;
    uint256 public nftFee = 150;
    uint256 public shortVideoFee = 150;
    uint256 public musicFee = 150;
    uint256 public eventsFee = 150;
    //uint256 public developmentFee = 150;
    uint256 public marketingFee = 150;
    uint256 public staffFee = 150;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    address UNISWAPV2ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public usdccontractaddress=0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C;
    address public BuyETH= 0xE9462C3f94541154A1C6bD19AAfBC24FeaB0A808;

    bool public enableFee = true;
    bool public swapFeeToEth;

    bool public createProductionsSwapEnabled = true;
    bool public cryptoTokenSwapEnabled = true;
    bool public nftSwapEnabled = true;
    bool public shortVideoSwapEnabled = true;
    bool public musicSwapEnabled = true;
    bool public eventsSwapEnabled = true;
    //bool public developmentSwapEnabled = true;
    bool public marketingSwapEnabled = true;
    bool public staffWageSwapEnabled = true;

    uint256 public maxSellLimit = 1000000000 * 10 ** 18;
                                
    uint256 public minimumTokensBeforeSwap = 1000000000 * 10 ** 18;

    event FeeEnabled(bool enableFee);

    event SetMaxTxPercent(uint256 maxPercent);
    event SetTaxFeePercent(uint256 taxFeePercent);

    event SetCreateProductionsFeePercent(uint256 fee);
    event SetCryptoTokenFeePercent(uint256 fee);                              
    event SetNftFeePercent(uint256 fee);
    event SetShortVideoFeePercent(uint256 fee);
    event SetMusicFeePercent(uint256 fee);
    event SetEventsFeePercent(uint256 fee);
    event SetMarketingFeePercent(uint256 fee);
    event SetStaffFeePercent(uint256 fee);
    //event SetDevelopmentFeePercent(uint256 fee);

    event SetMaximumSellLimitUniswap(uint256 sellLimit);
    event SetMinimumTokensBeforeSwap(uint256 minimumTokensBeforeSwap);

    event SetCreateProductionsSwapEnabled(bool enabled);
    event SetCryptoTokenSwapEnabled(bool enabled);
    event SetNftSwapEnabled(bool enabled);
    event SetShortVideoSwapEnabled(bool enabled);
    event SetMusicSwapEnabled(bool enabled);
    event SetEventsSwapEnabled(bool enabled);
    //event SetDevelopmentSwapEnabled(bool enabled);
    event SetStaffSwapEnabled(bool enabled);
    event SetMarketingSwapEnabled(bool enabled);

    event TokenFromContractTransfered(address externalAddress,address toAddress, uint256 amount);
    event ETHFromContractTransferred(uint256 amount);
    event BuyPowerVoteETH(uint256 value,uint256 VoteId,uint256 userId,uint256 eventid);
    event BuyPowerVoteERC20(uint256 value,uint256 id,address _tokenContract,uint256 userId,uint256 eventid);

    constructor (address _createProductionsWallet, 
        address _cryptoTokenWallet,
        address _nftWallet, 
        address _shortVideoWallet,
        address _musicWallet,
        address _eventsWallet,
       // address _developmentWallet,
        address _marketingWallet,
        address _staffWageWallet
        ) {
        balances[_msgSender()] = totalsupply; 
        createProductionsWallet = _createProductionsWallet;
        cryptoTokenWallet = _cryptoTokenWallet;
        nftWallet = _nftWallet;
        shortVideoWallet = _shortVideoWallet;
        musicWallet = _musicWallet;
        eventsWallet = _eventsWallet;
       // developmentWallet = _developmentWallet;
        marketingWallet = _marketingWallet;
        staffWageWallet = _staffWageWallet;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAPV2ROUTER);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
                    _isIncludedinFee[uniswapV2Pair]=true;

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        emit Transfer(address(0), _msgSender(), totalsupply);     
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return totalsupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return  balances[account];  //added
    }

    function gettotalSwapFee() public view returns(uint256){
            uint256 total = 0;
            if(createProductionsSwapEnabled)
            total = total.add(createProductionsFee);

            if(cryptoTokenSwapEnabled)
            total = total.add(cryptoTokenFee);

            if(nftSwapEnabled)
            total = total.add(nftFee);

            if(shortVideoSwapEnabled)
            total = total.add(shortVideoFee);

            if(musicSwapEnabled) 
            total = total.add(musicFee);

            if(eventsSwapEnabled) 
            total = total.add(eventsFee);

           //if(developmentSwapEnabled) 
           //total = total.add(developmentFee);

            if(marketingSwapEnabled)
            total = total.add(marketingFee);

            if(staffWageSwapEnabled) 
            total = total.add(staffFee);

        return total;
    }

    function transfer(address recipient, uint256 amount) external virtual override whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view virtual override whenNotPaused returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external virtual override whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external virtual override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    //Buypowervote for eth
    function buypowervoteETH(uint256 value,uint256 voteId,uint256 userId) public payable returns (uint256,uint256,uint256,uint256) {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        require(msg.value==value,"Value should be same");
        uint256 eventid= block.timestamp;
        (bool sent,) = BuyETH.call{value:msg.value}("");
        require(sent, "Failed to send Ether");
        emit BuyPowerVoteETH(value,voteId,userId,eventid);
        return (value,voteId,userId,eventid);
    }

 //Buypowervote for ERC20
  function buypowervoteERC20(uint256 value,uint256 voteId, address _tokenContract,uint256 userId) external onlyOwner returns(uint256,uint256,address,uint256,uint256) {
        uint256 eventid= block.timestamp;
        require(_tokenContract != address(0), "Address cant be zero address");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transferFrom(msg.sender, BuyETH,value);
        emit BuyPowerVoteERC20(value,voteId,_tokenContract,userId,eventid);
        return (value,voteId,_tokenContract,userId,eventid);
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function pauseContract() external virtual onlyOwner {
        _pause();
    }

    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

    function burn(uint256 amount) external virtual onlyOwner whenNotPaused override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    
    function excludeFromDexFee(address account,bool feestate) external onlyOwner whenNotPaused {
        _isExcludedFromDexFee[account] = feestate;
    }
    
    function includeInDexFee(address account,bool feestate) external onlyOwner whenNotPaused {
        _isIncludedinFee[account] = feestate;
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        require(_tokenContract != address(0), "Address cant be zero address");
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
        emit TokenFromContractTransfered(_tokenContract, msg.sender, _amount);
    }
    function withdrawETHFromContract(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance);        
        address payable _owner = payable(msg.sender);        
        _owner.transfer(amount);        
        emit ETHFromContractTransferred(amount);
    }
    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
  function _distributeFee() internal {
       // swap tokens in contract address to usdc
        IERC20 tokenContract = IERC20(usdccontractaddress);
        uint256 initialBalance = tokenContract.balanceOf(address(this));
        uint256 contractCreateBalance = balanceOf(address(this));
        uint256 totalSwapFee = gettotalSwapFee();  
        bool feevalue= enableFee;
        enableFee=false; 

          swapTokensForTokens(contractCreateBalance, address(this));
 
            uint256 ContractusdcBalance =tokenContract.balanceOf(address(this))-initialBalance;
            
            // Send ETH to createProductions address
            if(createProductionsSwapEnabled) tokenContract.transfer(payable(createProductionsWallet), ContractusdcBalance.mul(createProductionsFee).div(totalSwapFee));
            // Send ETH to cryptoToken address
            if(cryptoTokenSwapEnabled) tokenContract.transfer(payable(cryptoTokenWallet), ContractusdcBalance.mul(cryptoTokenFee).div(totalSwapFee));
            // Send ETH to nft address
            if(nftSwapEnabled) tokenContract.transfer(payable(nftWallet), ContractusdcBalance.mul(nftFee).div(totalSwapFee));
            // Send ETH to shortVideo address
            if(shortVideoSwapEnabled) tokenContract.transfer(payable(shortVideoWallet), ContractusdcBalance.mul(shortVideoFee).div(totalSwapFee));
            //send ETH to musicwallet address
            if(musicSwapEnabled) tokenContract.transfer(payable(musicWallet), ContractusdcBalance.mul(musicFee).div(totalSwapFee));

            //send ETH to events address
            if(eventsSwapEnabled) tokenContract.transfer(payable(eventsWallet), ContractusdcBalance.mul(eventsFee).div(totalSwapFee));

            //if(developmentSwapEnabled) tokenContract.transfer(payable(developmentWallet), ContractusdcBalance.mul(developmentFee).div(totalSwapFee));

            if(marketingSwapEnabled) tokenContract.transfer(payable(marketingWallet), ContractusdcBalance.mul(marketingFee).div(totalSwapFee));

            if(staffWageSwapEnabled) tokenContract.transfer(payable(staffWageWallet), ContractusdcBalance.mul(staffFee).div(totalSwapFee));

         enableFee=feevalue;
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 senderBalance = balanceOf(from);
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        if(_isIncludedinFee[to])
        {
          require(amount <=maxSellLimit, "ERC20: transfer amount exceeds sell limit");

        }
        bool takeFee = false ; 
        if(_isIncludedinFee[from] || _isIncludedinFee[to])
        {
        if(enableFee && (!_isExcludedFromDexFee[from] && !_isExcludedFromDexFee[to])){
            takeFee = true;     
            uint256 contractTokenBalance = balanceOf(address(this));

             if(contractTokenBalance >= minimumTokensBeforeSwap && _isIncludedinFee[to])
             {
                 _distributeFee();
             }          
        }else{
            takeFee = false;
        }
        }
        
        _tokenTransferTakeSwapFee(from, to, amount, takeFee);
       
    }
    function _tokenTransferTakeSwapFee(address sender, address recipient, uint256 amount, bool takeFee) internal {
        address from = sender;
        address to = recipient;
        uint256 totalSwapFee = gettotalSwapFee();
        if(takeFee){
            uint256 contractTokenBalance = balanceOf(address(this));
            balances[from]=balances[from].sub(amount);
            uint256 tax= totalSwapFee.mul(amount).div(10000);
            balances[to]= balances[to].add(amount).sub(tax);
            balances[address(this)]= contractTokenBalance.add(tax);
            emit Transfer(sender, recipient, amount.sub(tax));
        }
        else {
            balances[from]=balances[from].sub(amount);
            balances[to]= balances[to].add(amount);
            emit Transfer(sender, address(this), amount);
        }
       
    }
    function distributeFee() external onlyOwner {
       _distributeFee();
    }

    function transferETHToAddress(address payable recipient, uint256 amount) internal {
        recipient.transfer(amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        require(amount < balanceOf(account), "ERC20: burn amount exceeds balance");

        totalsupply = totalsupply.sub(amount);
        balances[account] = balances[account].sub(amount); 
        emit Transfer(account, address(0), amount);
    }
    function swapTokensForTokens(uint256 tokenAmount, address account) internal {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        path[2] = usdccontractaddress;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH   
            path,
            account,
            block.timestamp
        );
    }

    function setCreateProductionsFeePercent(address addr, uint256 fee) external onlyOwner{
        createProductionsFee = fee;
        createProductionsWallet=addr;
        emit SetCreateProductionsFeePercent(createProductionsFee);
    }

    function setCryptoTokenFeePercent(address addr, uint256 fee) external onlyOwner{
        cryptoTokenFee = fee;
      cryptoTokenWallet=addr;
        emit SetCryptoTokenFeePercent(cryptoTokenFee);
    }

    function setNftFeePercent(address addr, uint256 fee) external onlyOwner{
        nftFee = fee;
        nftWallet=addr;
        emit SetNftFeePercent(nftFee);
    }

    function setShortVideoFeePercent(address addr, uint256 fee) external onlyOwner{
        shortVideoFee = fee;
        shortVideoWallet=addr;
        emit SetShortVideoFeePercent(shortVideoFee);
    }

    function setMusicFeePercent(address addr, uint256 fee) external onlyOwner {
        musicFee = fee;
        musicWallet=addr;
        emit SetMusicFeePercent(musicFee);
    }

    function setEventsFeePercent(address addr, uint256 fee) external onlyOwner {
        eventsFee = fee;
        eventsWallet=addr;
        emit SetEventsFeePercent(eventsFee);
    }

   //function setDevelopmentFeePercent(address addr, uint256 fee) external onlyOwner {
    //    developmentFee = fee;
    //    developmentWallet=addr;
   //     emit SetDevelopmentFeePercent(fee);
   // }

    function setMarketingFeePercent(address addr, uint256 fee) external onlyOwner {
        marketingFee = fee;
        marketingWallet=addr;
        emit SetMarketingFeePercent(fee);
    }

    function setStaffFeePercent(address addr, uint256 fee) external onlyOwner {
        staffFee = fee;
        staffWageWallet=addr;
        emit SetStaffFeePercent(fee);
    }

    function setCreateProductionsSwapEnabled(bool enable) external onlyOwner {
        createProductionsSwapEnabled = enable;
        emit SetCreateProductionsSwapEnabled(createProductionsSwapEnabled);
    }

    function setCryptoTokenSwapEnabled(bool enable) external onlyOwner{
        cryptoTokenSwapEnabled = enable;
        emit SetCryptoTokenSwapEnabled(cryptoTokenSwapEnabled);
    }

    function setNftSwapEnabled(bool enable) external onlyOwner {
        nftSwapEnabled = enable;
        emit SetNftSwapEnabled(nftSwapEnabled);
    }

    function setShortVideoSwapEnabled(bool enable) external onlyOwner  {
       shortVideoSwapEnabled = enable;
        emit SetShortVideoSwapEnabled(shortVideoSwapEnabled);
    }

    function setMusicSwapEnabled(bool enable) external onlyOwner  {
       musicSwapEnabled = enable;
        emit SetMusicSwapEnabled(musicSwapEnabled);
    }

    function setEventsSwapEnabled(bool enable) external onlyOwner  {
        eventsSwapEnabled = enable;
        emit SetEventsSwapEnabled(eventsSwapEnabled);
    }

   // function setDevelopmentSwapEnabled(bool enable) external onlyOwner  {
   //     developmentSwapEnabled = enable;
   //     emit SetDevelopmentSwapEnabled(enable);
   // }
    function setMarketingSwapEnabled(bool enable) external onlyOwner  {
        marketingSwapEnabled = enable;
        emit SetMarketingSwapEnabled(enable);
    }

    function setStaffSwapEnabled(bool enable) external onlyOwner  {
        staffWageSwapEnabled = enable;
        emit SetStaffSwapEnabled(enable);
    }

    function setMaximumSellLimitUniswap(uint256 sellLimit) external onlyOwner {
        maxSellLimit = sellLimit;
        emit SetMaximumSellLimitUniswap(maxSellLimit);
    }
    
    function setMinimumTokensBeforeSwap(uint256 swapLimit) external onlyOwner  {
        minimumTokensBeforeSwap = swapLimit;
        emit SetMinimumTokensBeforeSwap(minimumTokensBeforeSwap);
    }

    function setEnableFee(bool enableTax) external onlyOwner {
        enableFee = enableTax;
        emit FeeEnabled(enableTax);
    }

}