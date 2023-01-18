// SPDX-License-Identifier: GPL-2.0-or-later
// https://docs.soliditylang.org/en/v0.8.17/assembly.html
pragma solidity >=0.8.0;
import "../IUniswapV2Pair.sol"; 
import "../IERC20.sol"; 

contract V2V3FalshV2V3loan_Bancor 
{
    bool public trig = false;
    address constant ethBancor=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; 
    mapping(address => bool) public LegalUsers; 

    //goerli
    address constant weth  =0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;  
    address public constant owner = payable(0x1dD215B383595b55159f62e965A055A26f90e906);      
    
    modifier onlyAdmin {
        require(
            msg.sender == owner  ,
            "Only owner can call this function."
        );
        _;
    } 
    
    receive() external payable {}
    
    function setUsers(address[] memory _addrsAdd,address[] memory _addrskill) public onlyAdmin{
        // Update the value at this address
        if(_addrsAdd.length>0){ 
            for (uint256 i = 0; i <= _addrsAdd.length - 1; i++) {
                LegalUsers[_addrsAdd[i]] =true;
            }
        }
        if(_addrskill.length>0){ 
            for (uint256 i = 0; i <= _addrskill.length - 1; i++) {
                delete LegalUsers[_addrskill[i]];
            }
        }
    }    

    modifier onlyOwner {
        require(
            LegalUsers[msg.sender] || msg.sender == owner,
            "Only User can call this function."
        );
        _;
    }
 
    function DrawBack(
        address token,
        uint256 amount,
        uint256 amoutETH
    ) public payable onlyOwner {
        if (amoutETH > 0) {
            (bool sent,) = payable(msg.sender).call{value:amoutETH}("");
            require(sent, "Failed to send Ether");
        }
        if (amount > 0)IERC20(token).transfer(msg.sender, amount);         
    }

    function uniSwapByOut(
        uint256 trueAmountOut,
        address tokenOut,
        address poolAdd,
        address to
    ) private {
        IUniswapV2Pair pair = IUniswapV2Pair(poolAdd);
        address token1 = pair.token1();
        uint256 amount0Out ;
        uint256 amount1Out ;
        // if (tokenOut < token1) amount0Out = trueAmountOut;
        // else amount1Out = trueAmountOut;
        assembly { 
            switch lt(tokenOut , token1) 
            case true { amount0Out := trueAmountOut }
            default { amount1Out := trueAmountOut } 
        }
        pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address poolAdd
    ) public view returns (uint256 amountOut, address tokenOut) {
        IUniswapV2Pair pair = IUniswapV2Pair(poolAdd);
        address token0 = pair.token0();
        uint256 reserveOut;
        uint256 reserveIn;
        if (tokenIn == token0) {
            (reserveIn, reserveOut, ) = pair.getReserves();
            tokenOut = pair.token1();
        } else {
            (reserveOut, reserveIn, ) = pair.getReserves();
            tokenOut = token0;
        }
        assembly { 
            let amountInWithFee := mul(amountIn , 997)
            let numerator := mul(amountInWithFee , reserveOut)
            let denominator := add(mul(reserveIn , 1000), amountInWithFee)
            amountOut := div(numerator, denominator)    
        }
        // uint256 amountInWithFee = amountIn * (997);
        // uint256 numerator = amountInWithFee * (reserveOut);
        // uint256 denominator = reserveIn * (1000) + (amountInWithFee);
        // amountOut = numerator / denominator;
    }


    function noFlashTrade1026994(
        uint8 judge,
        address tokenIn0,
        uint256 tokenUsed_AsGas,
        uint256 amountIn,
        uint8[] memory exchanges,
        address[] memory pools,
        bytes32 expectedParentHash
    ) public payable onlyOwner {         
        if(judge>=3)require(blockhash(block.number - 1) == expectedParentHash, "block was uncled");
        trig = true;
        if (exchanges[0] <= 2) IERC20(tokenIn0).transfer(pools[0], amountIn); //第一次从钱包转账到pool
        (uint256 amountOut, address tokenOut) = TradeFrom2(
            amountIn,
            tokenIn0,
            exchanges,
            pools
        );
        if (judge >= 1)
            require(amountOut >= amountIn, "000no profit: amountOut<amountIn");
        if (judge > 1)
            require( amountOut >tokenUsed_AsGas + amountIn, "0000000no profit: profit<Gascost" );
        trig = false;
    }

    function TradeFrom2(
        uint256 amountIn,
        address tokenIn,
        uint8[] memory exchanges,
        address[] memory pools
    ) private returns (uint256 amountOut, address tokenOut) {
        amountOut = amountIn;
        bytes memory data;
        uint256 poolLen = pools.length;
        uint8 exchange;
        for (uint256 i = 0; i <= poolLen - 1; i++) {
            exchange = exchanges[i];
            address thisPool = pools[i];
            if (i == 0) {
                //如果exchange<=2 已经把钱打给了pool
                if (exchange == 203) {
                    //从钱包打给V3
                    data = abi.encode(255, tokenIn, address(0), abi.encode(0));
                }
            } else tokenIn = tokenOut;

            if (i + 1 <= poolLen - 1) {
                //下一个swap的情况
                address nextPool = pools[i + 1];
                    //如果下一个所是V2类型的,直接打进去
                (amountOut, tokenOut) = getAmountOut( 
                    amountOut,
                    tokenIn,
                    thisPool
                );
                uniSwapByOut(amountOut, tokenOut, thisPool, nextPool);
            }else if (i + 1 == poolLen) {
                //最后一步给回钱包
                (amountOut, tokenOut) = getAmountOut( 
                    amountOut,
                    tokenIn,
                    thisPool
                );
                uniSwapByOut(amountOut, tokenOut, thisPool, address(this));
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
 
 
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
     
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */ 
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0; 
interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}