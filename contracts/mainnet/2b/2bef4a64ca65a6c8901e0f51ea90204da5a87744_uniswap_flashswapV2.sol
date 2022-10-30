/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

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

contract uniswap_flashswapV2 {

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

    // @notice This function is used when either the _tokenBorrow or _tokenBase is WETH or ETH
    // @dev Since ~all tokens trade against WETH (if they trade at all), we can use a single UniswapV2 pair to
    //     flash-borrow and repay with the requested tokens.
    // @dev This initiates the flash borrow. See `simpleFlashSwapExecute` for the code that executes after the borrow.
    // @param _pool1 is the dex that execute flash swap (cheaper token), _pool2 is the dex that sells the token to weth
    // @param _borrowAmount is the amount of token borrowed from flashswap, _repayAmount is the amount repay to flashswap, _swapoutAmount is the amount swap from the other DEX
    // @param _pool1BorrowToken
    function simpleFlashSwap(
        address _tokenBorrow,
        address _tokenBase,
        address _pool1,
        address _pool2,
        uint _borrowAmount,
        uint _repayAmount,
        uint _swapoutAmount
    ) public onlyOwner {
        address token0 = IUniswapV2Pair(_pool1).token0();
        address token1 = IUniswapV2Pair(_pool1).token1();
        uint amount0Out = _tokenBorrow == token0 ? _borrowAmount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _borrowAmount : 0;
        bytes memory data = abi.encode(
            _tokenBorrow,
            _tokenBase,
            _pool1,
            _pool2,
            _borrowAmount,
            _repayAmount,
            _swapoutAmount
        );
        IUniswapV2Pair(_pool1).swap(amount0Out, amount1Out, address(this), data);
    }

    // @notice Function is called by the Uniswap V2 pair's `swap` function
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        // access control
        require(_sender == address(this), "only this contract may initiate");

        // decode data
        (
            address _tokenBorrow,
            address _tokenBase,
            address _pool1,
            address _pool2,
            uint _borrowAmount,
            uint _repayAmount,
            uint _swapoutAmount
        ) = abi.decode(_data, (address, address, address, address, uint, uint, uint));

        simpleFlashSwapExecute(_tokenBorrow, _tokenBase, _pool1, _pool2, _borrowAmount, _repayAmount, _swapoutAmount, msg.sender);   
       
        // NOOP to silence compiler "unused parameter" warning
        if (false) {
            _amount0;
            _amount1;
        }
        return;
    }

    function simpleFlashSwapExecute(
        address _tokenBorrow,
        address _tokenBase,
        address _pool1,
        address _pool2,
        uint _borrowAmount,
        uint _repayAmount,
        uint _swapoutAmount,
        address _pairAddress
    ) private {
        require(_pairAddress==_pool1,"Only LP pool can call this function");

        // swap on pool2
        swapPool2(_tokenBorrow, _tokenBase, _pool2, _borrowAmount, _repayAmount, _swapoutAmount);

        // payback loan
        IERC20(_tokenBase).transfer(_pool1, _repayAmount);
    }

    // @notice This is where the user's custom logic goes
    // @dev When this function executes, this contract will hold _amount of _tokenBorrow
    // @dev It is important that, by the end of the execution of this function, this contract holds the necessary
    //     amount of the original _tokenBase needed to pay back the flash-loan.
    // @dev Paying back the flash-loan happens automatically by the calling function -- do not pay back the loan in this function
    // @dev If you entered `0x0` for _tokenBase when you called `flashSwap`, then make sure this contract hols _amount ETH before this
    //     finishes executing
    // @dev User will override this function on the inheriting contract
    function swapPool2(
        address _tokenBorrow, 
        address _tokenBase,
        address _pool2,
        uint _borrowAmount, 
        uint _repayAmount,
        uint _swapoutAmount
        ) internal {
        
        IERC20(_tokenBorrow).transfer(_pool2, _borrowAmount); // Transfer the borrow token first then swap
        
        require(_swapoutAmount>_repayAmount,"Not enough token to repay due to bad rate from pool2");

        address token0 = IUniswapV2Pair(_pool2).token0();
        address token1 = IUniswapV2Pair(_pool2).token1();
        uint amount0Out = _tokenBase == token0 ? _swapoutAmount : 0;
        uint amount1Out = _tokenBase == token1 ? _swapoutAmount : 0;
        
        IUniswapV2Pair(_pool2).swap(amount0Out, amount1Out, address(this),"");


    }

    function withdraw(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }

}