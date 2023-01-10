/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-05
*/

/*##################     #############     #############     ###       ####
  ##################     ##         ##     ##         ##     ## ##      ##
	     ###             ##         ##     ##         ##     ##  ##     ##
	     ###             ##  #####  ##     ##  #####  ##     ##   ##    ##
	     ###             ##  #   #  ##     ##  #   #  ##     ##    ##   ##
	     ###             ##  #####  ##     ##  #####  ##     ##     ##  ##
	     ###             ##         ##     ##         ##     ##      ## ##
	     ###             ##         ##     ##         ##     ##       # ##
	     ###             #############     #############    ####       ###
		             
   ##########   ####   ###    ##       ##       ###    ##  #######  #######
	##           ##    ## #   ##      ## #      ## #   ##  ##       ##
	######       ##    ##  #  ##     ##   #     ##  #  ##  ##       #####
	##           ##    ##   # ##    ## # # #    ##   # ##  ##       ##
	##           ##    ##    ###   ##       #   ##    ###  ##       ##
	##          ####   ##     ##  ##         #  ##     ##  #######  #######
	*/

// SPDX-License-Identifier: MIT    

pragma solidity ^0.8.0;

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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;



contract OwnerWithdrawable is Ownable {
    using SafeMath for uint256;

    receive() external payable {}

    fallback() external payable {}

    function withdraw(address token, uint256 amt) public onlyOwner {
        IERC20(token).transfer(msg.sender, amt);
    }

    function withdrawAll(address token) public onlyOwner {
        uint256 amt = IERC20(token).balanceOf(address(this));
        withdraw(token, amt);
    }

    function withdrawCurrency(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }
}

pragma solidity ^0.8.0;

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {

        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity ^0.8.0;

contract ToonPresale is OwnerWithdrawable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    IRouter public router;

    uint256 public rate;

    address public saleToken;
    uint public saleTokenDec;

    uint256 public totalTokensforSale;

    mapping(address => bool) public tokenWL;

    mapping(address => uint256) public tokenPrices;

    uint256 public preSaleStartTime;

    uint256 public preSaleEndTime;

    uint256 public lockingPeriod1;

    uint256 public lockingPeriod2;

    uint256 public percentTokens1;

    address[] public buyers;

    mapping(address => BuyerTokenDetails) public buyersAmount;

    uint256 public totalTokensSold;

    struct BuyerTokenDetails {
        uint amount;
        bool lockingPeriod1Claimed;
    }

    constructor() {

    }

    modifier saleStarted(){
        if(preSaleStartTime != 0){
            require(block.timestamp < preSaleStartTime);
        }
        _;
    }

    modifier saleDuration(){
        require(block.timestamp > preSaleStartTime);
        require(block.timestamp < preSaleEndTime);
        _;
    }

    modifier saleValid(
        uint256 _preSaleStartTime, uint256 _preSaleEndTime,
        uint256 _lockingPeriod1, uint256 _lockingPeriod2
    ){
        require(block.timestamp < _preSaleStartTime);
        require(_preSaleStartTime < _preSaleEndTime);
        require(_preSaleEndTime < _lockingPeriod1);
        require(_lockingPeriod1 < _lockingPeriod2);
        _;
    }

    function setSaleTokenParams(
        address _saleToken, uint256 _totalTokensforSale, uint256 _rate
    )external onlyOwner saleStarted{
        require(_rate != 0);
        rate = _rate;
        saleToken = _saleToken;
        saleTokenDec = IERC20Metadata(saleToken).decimals();
        totalTokensforSale = _totalTokensforSale;
        IERC20(saleToken).safeTransferFrom(msg.sender, address(this), totalTokensforSale);
    }

    function setSalePeriodParams(
        uint256 _preSaleStartTime,
        uint256 _preSaleEndTime,
        uint256 _lockingPeriod1,
        uint256 _lockingPeriod2,
        uint256 _percentTokens1
    )external onlyOwner saleStarted saleValid(_preSaleStartTime, _preSaleEndTime, _lockingPeriod1, _lockingPeriod2){

        preSaleStartTime = _preSaleStartTime;
        preSaleEndTime = _preSaleEndTime;
        lockingPeriod1 = _lockingPeriod1;
        lockingPeriod2 = _lockingPeriod2;
        percentTokens1 = _percentTokens1;

    }

    function addWhiteListedToken(
        address[] memory _tokens,
        uint256[] memory _prices
    ) external onlyOwner saleStarted{
        require(
            _tokens.length == _prices.length,
            "Presale: tokens & prices arrays length mismatch"
            );

        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_prices[i] != 0);
            tokenWL[_tokens[i]] = true;
            tokenPrices[_tokens[i]] = _prices[i];
        }
    }

    function updateTokenRate(
        address[] memory _tokens,
        uint256[] memory _prices,
        uint256 _rate
    )external onlyOwner{
        require(
            _tokens.length == _prices.length,
            "Presale: tokens & prices arrays length mismatch"

        );

        if(_rate != 0){
            rate = _rate;
        }

        for(uint256 i = 0; i < _tokens.length; i+=1){
            require(tokenWL[_tokens[i]] == true);
            require(_prices[i] != 0);
            tokenPrices[_tokens[i]] = _prices[i];
        }
    }

    function stopSale() external onlyOwner {
        require(block.timestamp > preSaleStartTime);
        if(block.timestamp < preSaleEndTime){
            preSaleEndTime = block.timestamp;
        }
    }

    function getTokenAmount(address token, uint256 amount)
        public
        view
        returns (uint256)
    {
        uint256 amtOut;
        if(token != address(0)){
            require(tokenWL[token] == true);
            uint256 price = tokenPrices[token];
            amtOut = amount.mul(10**saleTokenDec).div(price);
        }
        else{
            amtOut = amount.mul(10**saleTokenDec).div(rate);
        }
        return amtOut;
    }

    function buyToken(address _token, uint256 _amount) external payable saleDuration{

        uint256 saleTokenAmt;
        if(_token != address(0)){
            require(_amount > 0);
            require(tokenWL[_token] == true);

            saleTokenAmt = getTokenAmount(_token, _amount);
            require((totalTokensSold + saleTokenAmt) < totalTokensforSale);
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        }
        else{
            saleTokenAmt = getTokenAmount(address(0), msg.value);
            require((totalTokensSold + saleTokenAmt) < totalTokensforSale);
        }
        totalTokensSold += saleTokenAmt;
        buyersAmount[msg.sender].amount += saleTokenAmt;
    }

    function withdrawToken()external {
        uint256 tokensforWithdraw;
        if(block.timestamp < lockingPeriod2){
            require(!buyersAmount[msg.sender].lockingPeriod1Claimed);
            require(block.timestamp > lockingPeriod1);
            tokensforWithdraw = buyersAmount[msg.sender].amount * percentTokens1 / 100;
            buyersAmount[msg.sender].lockingPeriod1Claimed = true;
        }
        else
        {
            tokensforWithdraw = buyersAmount[msg.sender].amount;
            buyersAmount[msg.sender].lockingPeriod1Claimed = true;
        }
        buyersAmount[msg.sender].amount -= tokensforWithdraw;
        IERC20(saleToken).safeTransfer(msg.sender, tokensforWithdraw);
    }

    function setUniSwapRouterAddress(address _router) external onlyOwner{
        require(_router != address(0));
        router = IRouter(_router);
    }

    function addLiquidity(uint256 amountSaleToken) external payable onlyOwner returns (uint256, uint256, uint256){
        IERC20(saleToken).safeTransferFrom(msg.sender, address(this), amountSaleToken);

        IERC20(saleToken).approve(address(router), amountSaleToken);

        (uint256 amountA , uint256 amountB ,uint256 amounts) = router.addLiquidityETH{ value: msg.value }(saleToken, amountSaleToken, 0, 0, msg.sender, 2 * block.timestamp);
        return(amountA, amountB, amounts);
    }
}