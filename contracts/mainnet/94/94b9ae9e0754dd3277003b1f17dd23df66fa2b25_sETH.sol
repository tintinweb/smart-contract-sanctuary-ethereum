/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;

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
    
    function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

//import the uniswap router
//the contract needs to use swapExactTokensForTokens
//this will allow us to import swapExactTokensForTokens into our contract

interface IUniswapV2Router {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

}

interface IUniswapV2Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external returns (address);
}



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

contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "ERC20: sending to the zero address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

contract sETH is Owned, ReentrancyGuard {
    string public name     = "SHIBNOBI ETH";
    string public symbol   = "sETH";
    uint8  public decimals = 18;
    
     using SafeMath for uint256;

    event  Approval(address indexed src, address indexed guy, uint256 wad);
    event  Transfer(address indexed src, address indexed dst, uint256 wad);
    event  Deposit(address indexed dst, uint256 wad);
    event  Withdrawal(address indexed src, uint256 wad);

    mapping (address => uint256)                       public  balanceOf;
    mapping (address => mapping (address => uint256))  public  allowance;
    
    address public Oogway = 0x9859045b1821cc19c1df6CbfA367959e349131DF;
    address public Dev   = 0x05071Cd7D2EcFd235380B7424B2E418098336886;
    address public Market = 0xb8F9d14060e7e73eed1e98c23a732BE11345a2dB;

    uint256 private tax = 990; //for 1% set it 990
    uint256 private Oogwaytax = 500; //
    uint256 private Devtax = 25; // Oogway tax, dev tax, burn tax and markettax sum must be 1000
    uint256 private Markettax = 225; //
    uint256 private Burntax = 250; //
    
    uint256 public adminVal = 0; // mantaining count of total fees taken
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant SHINJA = 0xab167E816E4d76089119900e941BEfdfA37d6b32;
    

    receive() external payable {
        deposit();
    }

    function setAllTax(uint256 _admintax, uint256 _devtax, uint256 _Markettax, uint256 _Burntax) external onlyOwner {
        Oogwaytax = _admintax;
        Devtax = _devtax;
        Markettax = _Markettax;
        Burntax = _Burntax;
    }
    //-------------------------------

    function setTax(uint256 _tax) external onlyOwner {
        require(_tax > 0, "Error: Please Set a positve value");
        tax = _tax;
    }
    
    function getTax() public view returns(uint256) {
        return tax;
    }

    //----------------------------------
    
    function setBurnTax(uint256 _tax) external onlyOwner {
        require(_tax > 0, "Error: Please Set a positve value");
        Burntax = _tax;
    }
    
    function getBurnTax() public view returns(uint256) {
        return Burntax;
    }
    
    
    function setOogwayAddress(address _Oogway) external onlyOwner {
        require(_Oogway != address(0), "Error: Please Set valid address");
        Oogway = _Oogway;
    }

    //----------------------------------
    
    function setDevTax(uint256 _tax) external onlyOwner {
        require(_tax > 0, "Error: Please Set a positve value");
        Devtax = _tax;
    }
    
    function getDevTax() public view returns(uint256) {
        return Devtax;
    }
    
    
    function setDevAddress(address _Oogway) external onlyOwner {
        require(_Oogway != address(0), "Error: Please Set valid address");
        Dev = _Oogway;
    }
    

    //-------------------------------

    function setMarketTax(uint256 _tax) external onlyOwner {
        require(_tax > 0, "Error: Please Set a positve value");
        Markettax = _tax;
    }
    
    function getMarketTax() public view returns(uint256) {
        return Markettax;
    }
    
    
    function setMarketAddress(address _Oogway) external onlyOwner {
        require(_Oogway != address(0), "Error: Please Set valid address");
        Market = _Oogway;
    }
    
     //-------------------------------

    function setOogwayTax(uint256 _tax) external onlyOwner {
        require(_tax > 0, "Error: Please Set a positve value");
        Oogwaytax = _tax;
    }
    
    function getOogwayTax() public view returns(uint256) {
        return Oogwaytax;
    }
    
    

    //-------------------------------------------

    function deposit() public nonReentrant payable {
        uint256 value = msg.value;
        uint256 final_value = value.mul(tax).div(1000);
        
        uint256 totalTax = (value - final_value);
        
        uint256 adminPart = totalTax.mul(Oogwaytax).div(1000);
        uint256 Dev_value = totalTax.mul(Devtax).div(1000);
        uint256 Market_value = totalTax.mul(Markettax).div(1000);
        uint256 burn_value = totalTax.mul(Burntax).div(1000);

        balanceOf[Dev] += Dev_value;
        balanceOf[Market] += Market_value;

        adminVal += (totalTax);

        balanceOf[Oogway] += adminPart;

        /// burn start here

         //IWETH(WETH).deposit{value: burn_value}();
         if(burn_value > 0){
         swap(WETH, SHINJA, burn_value, address(0x000000000000000000000000000000000000dEaD));
         }
        ///-------------------------

        balanceOf[msg.sender] += final_value;
        emit Deposit(msg.sender, value);
    }

    function withdraw(uint256 wad) public nonReentrant {
        require(balanceOf[msg.sender] >= wad, "ERROR: Insufficient BALANCE");
        
        uint256 final_value = wad.mul(tax).div(1000); //98
        
        uint256 totalTax = (wad - final_value); //2

        uint256 adminPart = totalTax.mul(Oogwaytax).div(1000);
        uint256 Dev_value = totalTax.mul(Devtax).div(1000);
        uint256 Market_value = totalTax.mul(Markettax).div(1000);
        uint256 burn_value = totalTax.mul(Burntax).div(1000);


        balanceOf[Dev] += Dev_value;
        balanceOf[Market] += Market_value;

        adminVal += totalTax;
        
        balanceOf[Oogway] += adminPart;

        /// burn start here

         //IWETH(WETH).deposit{value: burn_value}();
         if(burn_value > 0){
         swap(WETH, SHINJA, burn_value, address(0x000000000000000000000000000000000000dEaD));
         }
        ///-------------------------
        
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(final_value);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad)
    public
    returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        Transfer(src, dst, wad);

        return true;
    }


        //address of the uniswap v2 router
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    //address of WETH token.  This is needed because some times it is better to trade through WETH.  
    //you might get a better price using WETH.  
    //example trading from token A to WETH then WETH to token B might result in a better price
    

    //this swap function is used to trade from one token to another
    //the inputs are self explainatory
    //token in = the token address you want to trade out of
    //token out = the token address you want as the output of this trade
    //amount in = the amount of tokens you are sending in
    //amount out Min = the minimum amount of tokens you want out of the trade
    //to = the address you want the tokens to be sent to
    
   function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, address _to) internal {
      //function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    //first we need to transfer the amount in tokens from the msg.sender to this contract
    //this contract will have the amount of in tokens
        //IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn*1000000000000);
        
        //next we need to allow the uniswapv2 router to spend the token we just sent to this contract
        //by calling IERC20 approve you allow the uniswap contract to spend the tokens in this contract 
        IERC20(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn*1000000000000);

        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
        path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        } else {
        path = new address[](3);
        path[0] = _tokenIn;
        path[1] = WETH;
        path[2] = _tokenOut;
        }
        //then we will call swapExactTokensForTokens
        //for the deadline we will pass in block.timestamp
        //the deadline is the latest time the trade is valid for
        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactETHForTokens{value: _amountIn}(1, path, _to, block.timestamp + 777777777);
    }
    
    
}