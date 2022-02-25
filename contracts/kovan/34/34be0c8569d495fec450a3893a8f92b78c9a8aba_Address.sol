/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

pragma solidity 0.6.0;

contract Love_Swap_V1 {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using address_make_payable for address;
    
    address superMan;
    address cofixRouter;
    address uniRouter;
    address USDTAddress = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address cofiAddress = 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1;
    uint256 nestPrice = 0.01 ether;
    
    constructor (address _cofixRouter, address _uniRouter) public {
        superMan = address(tx.origin);
        cofixRouter = _cofixRouter;
        uniRouter =_uniRouter;
        ERC20(USDTAddress).safeApprove(cofixRouter, 1000000000000000);
        ERC20(USDTAddress).safeApprove(uniRouter, 1000000000000000);
    }
    
    function getCofixRouter() public view returns(address) {
        return cofixRouter;
    }
    
    function getUniRouter() public view returns(address) {
        return uniRouter;
    }
    
    function getNestPrice() public view returns(uint256) {
        return nestPrice;
    }
    
    function getSuperMan() public view returns(address) {
        return superMan;
    }
    
    function setCofixRouter(address _cofixRouter) public onlyOwner {
        cofixRouter = _cofixRouter;
    }
    
    function setUniRouter(address _uniRouter) public onlyOwner {
        uniRouter = _uniRouter;
    }
    
    function setNestPrice(uint256 _amount) public onlyOwner {
        nestPrice = _amount;
    }
    
    function setSuperMan(address _newMan) public onlyOwner {
        superMan = _newMan;
    }
    // cofix:ETH->USDT,uni:USDT->ETH
    function doitForUni(uint256 ethAmount,uint256 deadline) public payable onlyOwner{
        uint256 ethBefore = address(this).balance;
        uint256 tokenBefore = ERC20(USDTAddress).balanceOf(address(this));
        CoFiXRouter(cofixRouter).swapExactETHForTokens.value(ethAmount.add(nestPrice))(USDTAddress,ethAmount,1,address(this), address(this), deadline);
        uint256 tokenMiddle = ERC20(USDTAddress).balanceOf(address(this)).sub(tokenBefore);
        address[] memory data = new address[](2);
        data[0] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        data[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        UniswapV2Router(uniRouter).swapExactTokensForETH(tokenMiddle,1,data,address(this),deadline);
        require(address(this).balance >= ethBefore, "ETH not enough");
        require(ERC20(USDTAddress).balanceOf(address(this)) >= tokenBefore, "token not enough");
    }
    // uni:USDT->ETH,cofix:ETH->USDT
    function doitForCofix(uint256 ethAmount,uint256 deadline) public payable onlyOwner{
        uint256 ethBefore = address(this).balance;
        uint256 tokenBefore = ERC20(USDTAddress).balanceOf(address(this));
        address[] memory data = new address[](2);
        data[0] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        data[1] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        UniswapV2Router(uniRouter).swapExactETHForTokens.value(ethAmount)(0,data,address(this),deadline);
        uint256 tokenMiddle = ERC20(USDTAddress).balanceOf(address(this)).sub(tokenBefore);
        CoFiXRouter(cofixRouter).swapExactTokensForETH.value(nestPrice)(USDTAddress,tokenMiddle,1,address(this), address(this), deadline);
        require(address(this).balance >= ethBefore, "ETH not enough");
        require(ERC20(USDTAddress).balanceOf(address(this)) >= tokenBefore, "token not enough");
    }
    // cofix:ETH->USDT,uni:USDT->ETH,包含cofi价值
    function doitForUniGetCofi(uint256 ethAmount,uint256 deadline,uint256 cofiPrice) public payable onlyOwner{
        uint256 ethBefore = address(this).balance;
        uint256 tokenBefore = ERC20(USDTAddress).balanceOf(address(this));
        uint256 cofiBefore = ERC20(cofiAddress).balanceOf(address(this));
        CoFiXRouter(cofixRouter).swapExactETHForTokens.value(ethAmount.add(nestPrice))(USDTAddress,ethAmount,1,address(this), address(this), deadline);
        uint256 tokenMiddle = ERC20(USDTAddress).balanceOf(address(this)).sub(tokenBefore);
        address[] memory data = new address[](2);
        data[0] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        data[1] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        UniswapV2Router(uniRouter).swapExactTokensForETH(tokenMiddle,1,data,address(this),deadline);
        uint256 cofiCost = ethBefore.sub(address(this).balance);
        require(ERC20(cofiAddress).balanceOf(address(this)).sub(cofiBefore).mul(cofiPrice).div(1 ether) > cofiCost, "cofi not enough");
        require(ERC20(USDTAddress).balanceOf(address(this)) >= tokenBefore, "token not enough");
    }
    // uni:USDT->ETH,cofix:ETH->USDT,包含cofi价值
    function doitForCofixGetCofi(uint256 ethAmount,uint256 deadline,uint256 cofiPrice) public payable onlyOwner{
        uint256 ethBefore = address(this).balance;
        uint256 tokenBefore = ERC20(USDTAddress).balanceOf(address(this));
        uint256 cofiBefore = ERC20(cofiAddress).balanceOf(address(this));
        address[] memory data = new address[](2);
        data[0] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        data[1] = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        UniswapV2Router(uniRouter).swapExactETHForTokens.value(ethAmount)(0,data,address(this),deadline);
        uint256 tokenMiddle = ERC20(USDTAddress).balanceOf(address(this)).sub(tokenBefore);
        CoFiXRouter(cofixRouter).swapExactTokensForETH.value(nestPrice)(USDTAddress,tokenMiddle,1,address(this), address(this), deadline);
        uint256 cofiCost = ethBefore.sub(address(this).balance);
        require(ERC20(cofiAddress).balanceOf(address(this)).sub(cofiBefore).mul(cofiPrice).div(1 ether) > cofiCost, "cofi not enough");
        require(ERC20(USDTAddress).balanceOf(address(this)) >= tokenBefore, "token not enough");
    }
    
    function moreETH() public payable {
        
    }
    
    function turnOutToken(address token, uint256 amount) public onlyOwner{
        ERC20(token).safeTransfer(superMan, amount);
    }
    
    function turnOutETH(uint256 amount) public onlyOwner {
        address payable addr = superMan.make_payable();
        addr.transfer(amount);
    }
    
    function getGasFee(uint256 gasLimit) public view returns(uint256){
        return gasLimit.mul(tx.gasprice);
    }
    
    function getTokenBalance(address token) public view returns(uint256) {
        return ERC20(token).balanceOf(address(this));
    }
    
    function getETHBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    modifier onlyOwner(){
        require(address(msg.sender) == superMan, "No authority");
        _;
    }
    
    receive() external payable{}
}

interface CoFiXRouter {
    function swapExactETHForTokens(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);
    function swapExactTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);
    function swapExactTokensForETH(
        address token,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint _amountIn, uint _amountOut);
}

interface UniswapV2Router {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
     function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
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
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library address_make_payable {
   function make_payable(address x) internal pure returns (address payable) {
      return address(uint160(x));
   }
}

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}