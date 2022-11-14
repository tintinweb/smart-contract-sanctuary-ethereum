/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;
// import 'hardhat/console.sol';

interface IUniswapV3Pair {
    function token0(
    ) external view returns (address);

    function token1(
    ) external view returns (address);

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
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
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

contract uniswap_flashswapV3 {

    // From openzeppelin ownable.sol
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Main contract

    // Fallback must be payable
    fallback() external payable {}
    receive() external payable  {}

    // @notice This function is used when either the tokenBorrow or tokenBase is WETH or ETH
    // @dev Since ~all tokens trade against WETH (if they trade at all), we can use a single UniswapV2 pair to
    //     flash-borrow and repay with the requested tokens.
    // @dev This initiates the flash borrow. See `simpleFlashSwapExecute` for the code that executes after the borrow.
    // @param pool1 is the dex that execute flash swap (cheaper token), pool2 is the dex that sells the token to weth
    // @param borrowAmount is the amount of token borrowed from flashswap, repayAmount is the amount repay to flashswap, swapoutAmount is the amount swap from the other DEX
    // @param pool1BorrowToken
    // @param pool1type
    function simpleFlashSwap(
        address tokenBorrow,
        address tokenBase,
        address pool1,
        address pool2,
        uint borrowAmount,
        uint repayAmount,
        uint swapOutAmount,
        bytes calldata data
    ) public onlyOwner {
        // decode data
        (
            uint pool1Type,
            uint pool2Type,
            uint pool1sqrtPriceLimitX96,
            uint pool2sqrtPriceLimitX96
        ) = abi.decode(data, (uint, uint, uint, uint));
        // console.log('calling simpleFlashSwap');
        // console.log('pooltype');
        // console.log(pool1Type);
        // console.log(pool2Type);

        bytes memory _data = abi.encode(
            tokenBorrow,
            tokenBase,
            pool1,
            pool2,
            pool2Type,
            pool2sqrtPriceLimitX96,
            borrowAmount,
            repayAmount,
            swapOutAmount
        );

        
        address _tokenBorrow = tokenBorrow;
        address _pool1 = pool1;
        uint _borrowAmount = borrowAmount;

        if(pool1Type==1){
            
            address token0 = IUniswapV3Pair(pool1).token0();

            // console.log('pool1 callingV3 swap');
            // console.log(pool1sqrtPriceLimitX96);
            IUniswapV3Pair(_pool1).swap(
                address(this),
                _tokenBorrow == token0?false:true,
                -int(_borrowAmount), 
                uint160(pool1sqrtPriceLimitX96), 
                _data
                );
        }else{
            // console.log('pool1 callingV2 swap');
            address token0 = IUniswapV2Pair(_pool1).token0();
            address token1 = IUniswapV2Pair(_pool1).token1();
            uint amount0Out = _tokenBorrow == token0 ? _borrowAmount : 0;
            uint amount1Out = _tokenBorrow == token1 ? _borrowAmount : 0;
            IUniswapV2Pair(_pool1).swap(amount0Out, amount1Out, address(this), _data);
        }
        
        
    }

    // @notice Function is called by the Uniswap V2 pair's `swap` function
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata data) external {
        // access control
        require(_sender == address(this), "only this contract may initiate");

        // decode data
        (,,address pool1,address pool2,,,,,) = abi.decode(data, (address, address, address, address, uint, uint, uint, uint, uint));


        simpleFlashSwapExecute(pool1,pool2,msg.sender,data);
       
        // NOOP to silence compiler "unused parameter" warning
        if (false) {
            _amount0;
            _amount1;
        }
        return;
    }

    // @notice Function is called by the Uniswap V3 pair's `swap` function
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        // access control
        // require(_sender == address(this), "only this contract may initiate");

        // console.log('uniswapV3 call');
        // console.log(msg.sender);
        // decode data
        (,,address pool1,address pool2,,,,,) = abi.decode(data, (address, address, address, address, uint, uint, uint, uint, uint));

        simpleFlashSwapExecute(pool1,pool2,msg.sender,data);   
       
        // NOOP to silence compiler "unused parameter" warning
        if (false) {
            amount0Delta;
            amount1Delta;
        }
        return;
    }

    function simpleFlashSwapExecute(
        address pool1,
        address pool2,
        address pairAddress,
        bytes calldata data
    ) private {
        require(pairAddress==pool1 || pairAddress==pool2,"Only LP pool can call this function");
        
        // console.log('calling simpleFlashSwapExecute');
        // console.log(msg.sender);

        (
            address tokenBorrow,
            address tokenBase,
            ,
            ,
            uint pool2Type,
            uint pool2sqrtPriceLimitX96,
            uint borrowAmount,
            uint repayAmount,
            uint swapOutAmount
        ) = abi.decode(data, (address, address, address, address, uint, uint, uint, uint, uint));

        
        address _pool2 = pool2;
        address _tokenBorrow = tokenBorrow;

        if (msg.sender==pool1){
            uint baseBalanceBefore = IERC20(tokenBase).balanceOf(address(this));
        
            
            address _pool1 = pool1;
            
            bytes memory _data = data;
            // swap on pool2
            // If pool2Type=1, pool2 is uniswapv3

            if (pool2Type==1){
                // console.log('Swap pool2 V3');
                IUniswapV3Pair(pool2).swap(
                    address(this),
                    _tokenBorrow == (IUniswapV3Pair(_pool2).token0())?true:false,
                    int(borrowAmount), 
                    uint160(pool2sqrtPriceLimitX96), 
                    _data
                    );
                // console.log('Swap pool2 V3 Done');
            }else{
                // swap on pool2
                // console.log('Swap pool2 V2');
                swapPool2_V2(_tokenBorrow, tokenBase, _pool2, borrowAmount, repayAmount, swapOutAmount);
                // console.log('Swap pool2 V2 Done');
            }
            uint baseBalanceAfter = IERC20(tokenBase).balanceOf(address(this));
            require(baseBalanceAfter>=baseBalanceBefore+swapOutAmount, "Pool 2 not returning enough token");
            // payback loan
            // console.log('Paying back loan');
            // console.log(repayAmount);
            IERC20(tokenBase).transfer(_pool1, repayAmount);
        }

        if (msg.sender==_pool2) {
            require(IERC20(_tokenBorrow).balanceOf(address(this)) >= borrowAmount, 'Pool 1 not returning enough token');
            // console.log('Transfer token to pool2');
            // console.log('Balance of tokenBorrow in wallet');
            IERC20(_tokenBorrow).transfer(_pool2, borrowAmount); // Transfer the borrow token to pool2
            // console.log('Transfer Done');
        }

    }

    // @notice This is where the user's custom logic goes
    // @dev When this function executes, this contract will hold _amount of _tokenBorrow
    // @dev It is important that, by the end of the execution of this function, this contract holds the necessary
    //     amount of the original _tokenBase needed to pay back the flash-loan.
    // @dev Paying back the flash-loan happens automatically by the calling function -- do not pay back the loan in this function
    // @dev If you entered `0x0` for _tokenBase when you called `flashSwap`, then make sure this contract hols _amount ETH before this
    //     finishes executing
    // @dev User will override this function on the inheriting contract
    function swapPool2_V2(
        address tokenBorrow, 
        address tokenBase,
        address pool2,
        uint borrowAmount, 
        uint repayAmount,
        uint swapoutAmount
        ) internal {
        
        IERC20(tokenBorrow).transfer(pool2, borrowAmount); // Transfer the borrow token first then swap
        
        require(swapoutAmount>repayAmount,"Not enough token to repay due to bad rate from pool2");

        address token0 = IUniswapV2Pair(pool2).token0();
        address token1 = IUniswapV2Pair(pool2).token1();
        uint amount0Out = tokenBase == token0 ? swapoutAmount : 0;
        uint amount1Out = tokenBase == token1 ? swapoutAmount : 0;
        
        IUniswapV2Pair(pool2).swap(amount0Out, amount1Out, address(this),"");

    }


    function withdraw(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint tokenBalance = IERC20(_tokenContract).balanceOf(address(this));
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, tokenBalance);
    }

}