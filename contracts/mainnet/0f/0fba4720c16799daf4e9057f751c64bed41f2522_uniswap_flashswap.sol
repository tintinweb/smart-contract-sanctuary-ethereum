/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

// interface IUniswapV2Factory {
//   event PairCreated(address indexed token0, address indexed token1, address pair, uint);
//   function getPair(address tokenA, address tokenB) external view returns (address pair);
//   function allPairs(uint) external view returns (address pair);
//   function allPairsLength() external view returns (uint);
//   function feeTo() external view returns (address);
//   function feeToSetter() external view returns (address);
//   function createPair(address tokenA, address tokenB) external returns (address pair);
// }

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

// interface IWETH {
//     function withdraw(uint) external;
//     function deposit() external payable;
// }

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

    

contract uniswap_flashswap {

    // From openzeppelin context.sol
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    // From openzeppelin ownable.sol
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
    }

    // Main contract
    uint256 deadline = 60; //60 seconds expiration for router swap
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Fallback must be payable
    fallback() external payable {}
    receive() external payable  {}

    // @notice This function is used when either the _tokenBorrow or _tokenPay is WETH or ETH
    // @dev Since ~all tokens trade against WETH (if they trade at all), we can use a single UniswapV2 pair to
    //     flash-borrow and repay with the requested tokens.
    // @dev This initiates the flash borrow. See `simpleFlashSwapExecute` for the code that executes after the borrow.
    // @param _pool1 is the dex that execute flash swap (cheaper token), _pool2 is the dex that sells the token to weth
    function simpleFlashSwap(
        address _tokenBorrow,
        uint _borrowAmount,
        address _tokenPay,
        address _pool1,
        address _pool2,
        bytes memory _userData
    ) public onlyOwner {
        address pool1 = _pool1; // gas efficiency
        address token0 = IUniswapV2Pair(pool1).token0();
        address token1 = IUniswapV2Pair(pool1).token1();
        uint amount0Out = _tokenBorrow == token0 ? _borrowAmount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _borrowAmount : 0;
        bytes memory data = abi.encode(
            _tokenBorrow,
            _borrowAmount,
            _tokenPay,
            _pool1,
            _pool2,
            _userData
        );
        IUniswapV2Pair(pool1).swap(amount0Out, amount1Out, address(this), data);
    }

    // @notice Function is called by the Uniswap V2 pair's `swap` function
    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        // access control
        require(_sender == address(this), "only this contract may initiate");

        // decode data
        (
            address _tokenBorrow,
            uint _borrowAmount,
            address _tokenPay,
            address _pool1,
            address _pool2,
            bytes memory _userData
        ) = abi.decode(_data, (address, uint, address, address, address, bytes));

        simpleFlashSwapExecute(_tokenBorrow, _borrowAmount, _tokenPay, _pool1, _pool2, msg.sender,_userData);   
       
        // NOOP to silence compiler "unused parameter" warning
        if (false) {
            _amount0;
            _amount1;
        }
        return;
    }

    function simpleFlashSwapExecute(
        address _tokenBorrow,
        uint _borrowAmount,
        address _tokenPay,
        address _pool1,
        address _pool2,
        address _pairAddress,
        bytes memory _userData
    ) private {
        require(_pairAddress==_pool1,"Only LP pool can call this function");
        // compute the amount of _tokenPay that needs to be repaid
        address pool1 = _pool1; // gas efficiency
        uint pairBalanceTokenBorrowP1 = IERC20(_tokenBorrow).balanceOf(pool1);
        uint pairBalanceTokenPayP1 = IERC20(_tokenPay).balanceOf(pool1);
        uint amountToRepay = ((1000 * pairBalanceTokenPayP1 * _borrowAmount) / (997 * pairBalanceTokenBorrowP1)) + 1;

        // get the orignal tokens the user requested
        address tokenBorrowed = _tokenBorrow;
        address tokenToRepay = _tokenPay;

        // do whatever the user wants
        execute(tokenBorrowed, _borrowAmount, tokenToRepay, amountToRepay,_pool2,_userData);

        // payback loan
        IERC20(_tokenPay).transfer(pool1, amountToRepay);
    }

    // @notice This is where the user's custom logic goes
    // @dev When this function executes, this contract will hold _amount of _tokenBorrow
    // @dev It is important that, by the end of the execution of this function, this contract holds the necessary
    //     amount of the original _tokenPay needed to pay back the flash-loan.
    // @dev Paying back the flash-loan happens automatically by the calling function -- do not pay back the loan in this function
    // @dev If you entered `0x0` for _tokenPay when you called `flashSwap`, then make sure this contract hols _amount ETH before this
    //     finishes executing
    // @dev User will override this function on the inheriting contract
    function execute(
        address _tokenBorrow, 
        uint _borrowAmount, 
        address _tokenPay, 
        uint _amountToRepay,
        address _pool2,
        bytes memory _userData
        ) internal {

        address pool2 = _pool2; // gas efficiency
        IERC20(_tokenBorrow).transfer(pool2, _borrowAmount); // Transfer the borrow token first then swap

        uint pairBalanceTokenBorrowP2 = IERC20(_tokenBorrow).balanceOf(pool2);
        uint pairBalanceTokenPayP2 = IERC20(_tokenPay).balanceOf(pool2);
        uint amountFromP2 = ((997 * pairBalanceTokenPayP2 * _borrowAmount) / (1000 * pairBalanceTokenBorrowP2)) + 1;

        require(amountFromP2>_amountToRepay,"Not enough token to repay due to bad rate from pool2");

        address token0 = IUniswapV2Pair(pool2).token0();
        address token1 = IUniswapV2Pair(pool2).token1();
        uint amount0Out = _tokenBorrow == token0 ? amountFromP2 : 0;
        uint amount1Out = _tokenBorrow == token1 ? amountFromP2 : 0;
        _userData = bytes("");

        IUniswapV2Pair(pool2).swap(amount0Out, amount1Out, address(this), _userData);
        

    }


    function withdraw(address _tokenContract, uint256 _amount) external {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }

}