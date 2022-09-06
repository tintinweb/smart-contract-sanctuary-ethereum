/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;



////////////////////////////////////////////////
//                                            //
//               STAKING                      //
//                                            //
////////////////////////////////////////////////
interface IERC20 {
  
    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external ;

    function burn(address to, uint256 amount) external ;

    event Transfer(address indexed from, address indexed to, uint256 value);

 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal  pure returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
     constructor ( address _ownernew) public {
        _setOwner(_ownernew);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

contract ethUsdtStaking is Ownable {
    IERC20 public depositeToken;
    IERC20 public USDTmaster;
    IERC20 public USDTxETHmaster;
    bool private hasStart=true;    
    address public USDT=0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public wNative=0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public token=0x61fc244e45f68E992e93312a081314c723cf7545;  
    address public USDTxETH = 0xa688db8f4A7088E2Ea9Ab825f7469C928Ea36C39;
    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Router02 public immutable uniswapV2RouterUSDT;

    struct Deposit{
        uint256 amountInNative;
        uint256 amountInToken;
        uint256 time;
        bool isStake;
        uint256 network;
    }
    struct userDetails{
        Deposit[] deposits;
    }
    mapping(address => userDetails) internal users;

    uint256 TIME_STEP = 10 minutes;

    constructor() public Ownable(0x9d76c8346f94CA80B1AF6AC54C1E2f451Df9f38F){
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;  
        uniswapV2RouterUSDT = _uniswapV2Router;  
        depositeToken=IERC20(token);  
        USDTxETHmaster = IERC20(USDTxETH);    
        USDTmaster=IERC20(USDT);      
    } 

    /**
    *@dev BUY NATIVE TO TOKEN
    **/
    function buyNativeToToken() public payable{
        require(msg.value>0,"Amount must be greater then zero");
        require(hasStart==true,"Sale is not started"); 
        
        uint256 amountOut = convertNativeToToken(msg.value);
        (depositeToken).mint(msg.sender, amountOut);
        users[msg.sender].deposits.push(Deposit(msg.value,amountOut,block.timestamp,true,0));
    }    

    /**
    *@dev BUY TOKEN TO NATIVE
    *@param _amount,_address
    **/
    function buyTokenToNative(uint256 _amount) public{   
        require(_amount>0,"Amount must be greater then zero");   
        require(hasStart==true,"Sale is not started"); 
       
        uint256 amountOut = convertTokenToNative(_amount);
        depositeToken.burn(msg.sender, _amount);
        (bool success, ) = msg.sender.call{value:  amountOut}("");
        require(success, "Address: unable to send value, recipient may have reverted");
        users[msg.sender].deposits.push(Deposit(amountOut,_amount,block.timestamp,false,0));
    }    

    /**
    *@dev convert TOKEN TO NATIVE
    *@param _amount,_address
    */
    function convertNativeToToken(uint256 _amount) public view returns(uint256  amounts){        
        address[] memory t = new address[](2);
        t[0] = token;
        t[1] = wNative;
        uint[] memory _amounts=uniswapV2Router.getAmountsIn(_amount,t);
        return _amounts[0];        
    }

    /**
    *@dev convert NATIVE TO TOKEN
    *@param _amount,_address
    **/
    function convertTokenToNative(uint256 _amount) public view returns(uint256  amounts){        
        address[] memory t = new address[](2);
        t[0] = wNative;
        t[1] = token;
        uint[] memory _amounts=uniswapV2Router.getAmountsIn(_amount,t);
        return _amounts[0];
    }      

    /**
    *@dev SET STAKING STATUS
    *@param _start
    **/
    function setStakingStatus(bool _start) public onlyOwner{
        hasStart=_start;
    }

    /**
    *@dev GET TOTAL NUMBER OF DEPOSITS OF USER
    *@param _useraddress
    **/
    function getUserAmountOfDeposits(address _useraddress) public view returns(uint256) {
		return users[_useraddress].deposits.length;
	}

    /**
    *@dev GET USER DEPOSIT INFORMATION
    *@param amountInNative,amountInToken,time,isStake
    **/
    function getUserDepositInfo(address _address,uint256 _index) public view returns(uint256 amountInNative,uint256 amountInToken,uint256 time,bool isStake,uint256 network){
        amountInNative = users[_address].deposits[_index].amountInNative;
        amountInToken = users[_address].deposits[_index].amountInToken;
        time = users[_address].deposits[_index].time;
        isStake = users[_address].deposits[_index].isStake;
        network = users[_address].deposits[_index].network;
    }




    /**
    *@dev BUY USDT TO TOKEN
    **/
    function buyUSDTToToken(uint256 _amount) public {
        require(_amount>0,"Amount must be greater then zero");      
        require(hasStart==true,"Sale is not started"); 
        
        uint256 amountOut = convertUSDTToToken(_amount);
        USDTmaster.transfer(address(this),_amount);
        (USDTxETHmaster).mint(msg.sender, amountOut);
        users[msg.sender].deposits.push(Deposit(_amount,amountOut,block.timestamp,true,1));
    }    

    /**
    *@dev BUY TOKEN TO USDT
    *@param _amount,_address
    **/
    function buyTokenToUSDT(uint256 _amount) public{   
        require(_amount>0,"Amount must be greater then zero");
        require(hasStart==true,"Sale is not started"); 
       
        uint256 amountOut = convertTokenToUSDT(_amount);
        USDTmaster.transfer(msg.sender,_amount);
        USDTxETHmaster.burn(msg.sender, _amount);
        users[msg.sender].deposits.push(Deposit(amountOut,_amount,block.timestamp,false,1));
    }      


    /**
    *@dev convert TOKEN TO USDT
    *@param _amount,_address
    */
    function convertUSDTToToken(uint256 _amount) public view returns(uint256  amounts){        
        address[] memory t = new address[](2);
        t[0] = USDTxETH;
        t[1] = USDT;
        uint[] memory _amounts=uniswapV2RouterUSDT.getAmountsIn(_amount,t);
        return _amounts[0];        
    }

    /**
    *@dev convert USDT TO TOKEN
    *@param _amount,_address
    **/
    function convertTokenToUSDT(uint256 _amount) public view returns(uint256  amounts){        
        address[] memory t = new address[](2);
        t[0] = USDT;
        t[1] = USDTxETH;
        uint[] memory _amounts=uniswapV2RouterUSDT.getAmountsIn(_amount,t);
        return _amounts[0];
    }      


    function withdrwal(address _token,uint256 value) public onlyOwner{
        if(_token==address(0)){
            payable(owner()).transfer(address(this).balance);
        }else if(_token == USDT){          
          USDTmaster.transfer(owner(), value);
        }else if(_token == token){          
          depositeToken.transfer(owner(), value);
        }else if(_token == USDTxETH){
          USDTxETHmaster.transfer(owner(),value);
        }
    }
    // update ETHx token address
    function updateETHxaddress(address _contractaddress) public onlyOwner {
        token = _contractaddress;
    }

    // update USDTxETH token address
    function updateUSDTxETHaddress(address _contractaddress) public onlyOwner {
        USDTxETH = _contractaddress;
    }
  

    receive() external payable {}
    fallback() external payable {}
}