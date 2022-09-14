/**
 *Submitted for verification at Etherscan.io on 2022-09-14
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
    address public walletAddress = 0x2cdA25C0657d7622E6301bd93B7EC870a56fE500;

    address public USDT=0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02;
    address public wNative=0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public token=0x161F38612344175fde2BB73f004AE40F37BCC85e;  
    address public USDTxETH = 0xC4B5eF4745872E094F7076c74Be2B8de1d855e5A;
    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Router02 public immutable uniswapV2RouterUSDT;
    
    struct userDetails{        
        uint256 totalTokenAmount;
        uint256 withdrawStatus;
        uint256 withdrawTokenAmount;
        uint256 requestedAmount;
        uint256 withdrawableAmount;
        address withdrawRequestAddress;

        uint256 totalTokenAmount2;
        uint256 withdrawStatus2;
        uint256 withdrawTokenAmount2;
        uint256 requestedAmount2;
        uint256 withdrawableAmount2;
        address withdrawRequestAddress2;
    }

    address[] public stakeUsers;

    
    mapping(address => userDetails) internal users;

    uint256 TIME_STEP = 10 minutes;

    constructor() public Ownable(0x2cdA25C0657d7622E6301bd93B7EC870a56fE500){
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
        payable(walletAddress).transfer(msg.value);
        (depositeToken).mint(msg.sender, amountOut);
        users[msg.sender].totalTokenAmount += amountOut;
        users[msg.sender].withdrawStatus = 0;

        if(!checkExitsAddress(msg.sender)){
            stakeUsers.push(msg.sender);
        }
    }      


    function withdrawRequest(uint256 _amount,address _tokenAddress,address _withdrawRequestAddress) public{
        require(_tokenAddress != address(0),"Please provider a valid address");
        require(_amount>0,"Amount must be greater then zero");   
        if(_tokenAddress == token){
            require(users[msg.sender].totalTokenAmount>0,"You are not stake");   
            require(users[msg.sender].totalTokenAmount>=users[msg.sender].withdrawableAmount,"You already withdraw your funds");
            require(users[msg.sender].totalTokenAmount>=_amount,"Invalid amount request");         
            
            uint256 convertAmount = convertTokenToNative(_amount);
            (depositeToken).transferFrom(msg.sender,walletAddress,_amount);
            users[msg.sender].requestedAmount += convertAmount;
            users[msg.sender].withdrawableAmount += _amount;            
            users[msg.sender].withdrawStatus = 1;
            users[msg.sender].withdrawRequestAddress = _withdrawRequestAddress;            
            
        }else if(_tokenAddress == USDTxETH){
            uint256 convertAmount = convertTokenToUSDT(_amount);
            require(users[msg.sender].totalTokenAmount2>0,"You are not stake");
            require(users[msg.sender].totalTokenAmount2>=users[msg.sender].withdrawableAmount2,"You already withdraw your funds");
            require(users[msg.sender].totalTokenAmount2>=_amount,"Invalid amount request");

            (USDTxETHmaster).transferFrom(msg.sender,walletAddress,_amount);
            users[msg.sender].requestedAmount2 += convertAmount;
            users[msg.sender].withdrawableAmount2 += _amount; 
            users[msg.sender].withdrawStatus2 = 1;
            users[msg.sender].withdrawRequestAddress2 = _withdrawRequestAddress;            
        }else{
            revert("Wrong address");
        }
    }

    function acceptTokenRequest(address _useraddress, address _tokenAddress) public onlyOwner{
        
        require(_useraddress != address(0),"Please provider a valid address");
        require(walletAddress == msg.sender,"Address doesn't match with wallet address");

        if(_tokenAddress == token){
            require(users[_useraddress].requestedAmount>0,"Invalid user amount request");
            require(users[_useraddress].withdrawStatus == 1,"Invalid user request");
            users[_useraddress].withdrawStatus = 2;
            users[_useraddress].requestedAmount = 0;
            users[_useraddress].withdrawableAmount = 0;
            users[_useraddress].totalTokenAmount = 0;   

        }else if(_tokenAddress == USDTxETH){
            require(users[_useraddress].requestedAmount2 > 0,"Invalid user amount request");
            require(users[_useraddress].withdrawStatus2 == 1,"Invalid user request");
            users[_useraddress].withdrawStatus2 = 2;
            users[_useraddress].withdrawableAmount2 = 0;
            users[_useraddress].requestedAmount2 = 0;
            users[_useraddress].totalTokenAmount2 = 0;        
        }
    }

    // check address exists
    function checkExitsAddress(address _userAdd) private view returns (bool){
       bool found=false;
        for (uint i=0; i<stakeUsers.length; i++) {
            if(stakeUsers[i]==_userAdd){
                found=true;
                break;
            }
        }
        return found;
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
    *@dev GET USER WITHDRAW REQUEST
    *@param _useraddress
    **/
    function getUserRequestDetails(address _useraddress,address _tokenAddress) public view returns(uint256 totalTokenAmount,uint256 withdrawStatus,uint256 withdrawableAmount,uint256 requestedAmount,address withdrawRequestAddress) {
        if(_tokenAddress == token){
            totalTokenAmount = users[_useraddress].totalTokenAmount;
            withdrawStatus = users[_useraddress].withdrawStatus;
            withdrawableAmount = users[_useraddress].withdrawableAmount;        
            requestedAmount = users[_useraddress].requestedAmount;
            withdrawRequestAddress = users[_useraddress].withdrawRequestAddress;
        }else if(_tokenAddress == USDTxETH){
            totalTokenAmount = users[_useraddress].totalTokenAmount2;
            withdrawStatus = users[_useraddress].withdrawStatus2;
            withdrawableAmount = users[_useraddress].withdrawableAmount2;
            requestedAmount = users[_useraddress].requestedAmount2;
            withdrawRequestAddress = users[_useraddress].withdrawRequestAddress2;
        }
	}





    /**
    *@dev BUY USDT TO TOKEN
    **/
    function buyUSDTToToken(uint256 _amount) public {
        require(_amount>0,"Amount must be greater then zero");      
        require(hasStart==true,"Sale is not started"); 
        
        uint256 amountOut = convertUSDTToToken(_amount);
        USDTmaster.transferFrom(msg.sender,walletAddress,_amount);
        (USDTxETHmaster).mint(msg.sender, amountOut);    
        if(!checkExitsAddress(msg.sender)){
            stakeUsers.push(msg.sender);
        }    
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

    // SET WALLET ADDRESS
    function setWalletAddress(address _address) public onlyOwner{
        walletAddress=_address;
    }
  

    // receive() external payable {}
    // fallback() external payable {}
}