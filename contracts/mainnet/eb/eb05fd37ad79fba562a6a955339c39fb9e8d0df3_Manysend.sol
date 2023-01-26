/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

pragma solidity =0.8.12;
pragma abicoder v2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

    
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address to, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

library TransferHelper {
    
    
    
    
    
    
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    
    
    
    
    
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    
    
    
    
    
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    
    
    
    
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

interface IUniswapV3SwapCallback {
    
    
    
    
    
    
    
    
    
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    
    
    
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    
    
    
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    
    
    
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    
    
    
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    
    
    
    
    
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    
    
    
    
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

interface IUniswapV3Factory {
    
    
    
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    
    
    
    
    
    
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    
    
    
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    
    
    
    function owner() external view returns (address);

    
    
    
    
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    
    
    
    
    
    
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    
    
    
    
    
    
    
    
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    
    
    
    function setOwner(address _owner) external;

    
    
    
    
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

contract WETH9 {
    string public name     = "Wrapped Ether";
    string public symbol   = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    receive() external payable {
        deposit();
    }
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}

contract Manysend is Context, Ownable {
    ISwapRouter public immutable swapRouter;
    IUniswapV3Factory public immutable swapFactory;
    WETH9 public immutable weth9;

    
    uint24 public poolFee = 3000; 
    uint8 public feePercentMul100 = 30; 
    uint8 public priceRangePercent = 5;
    uint256 public deadlineSwap = 75;
    address payable feeReceiver;

    event ETHToTokenConverted(address indexed sender, uint256 amountIn, IERC20 indexed tokenOut, uint256 indexed amountOut);
    event ETHToTokenConvertedFeeSent(address indexed sender, address indexed feeReceiver, uint256 indexed amountInFee);
    event TokenToTokenConverted(address indexed sender, IERC20 indexed tokenTo, uint256 amountIn, IERC20 indexed tokenOut, uint256 amountOut);
    event TokenToTokenConvertedFeeSent(address indexed sender, address indexed feeReceiver, IERC20 indexed tokenTo, uint256 amountInFeet);
    event TokenTransfered(address indexed sender, address indexed recipient, IERC20 indexed transferToken, uint256 amount);
    event BatchTransferedFeeSent(address indexed sender, address indexed feeReceiver, IERC20 indexed transferToken, uint256 feeAmount);

    constructor(
        ISwapRouter _swapRouter, 
        IUniswapV3Factory _swapFactory,
        WETH9 _weth9,
        address payable _feeReceiver
    )  {
        swapRouter = _swapRouter;
        swapFactory = _swapFactory;
        weth9 = _weth9;
        feeReceiver = _feeReceiver;
    }

    function setDeadline(uint256 deadlineNew) external onlyOwner {
            deadlineSwap = deadlineNew;
    }

    function setPoolFee(uint24 _poolFee) external onlyOwner {
            poolFee = _poolFee;
    }

    function setPriceRangePercent(uint8 _priceRangePercent) external onlyOwner {
            priceRangePercent = _priceRangePercent;
    }

    function setFeePercent(uint8 _feePercentMul100) external onlyOwner {
            feePercentMul100 = _feePercentMul100;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
            feeReceiver = payable(_feeReceiver);
    }

    
    function getPairTokenAmount(uint256 amountOut, IERC20 tokenOut, IERC20 tokenIn) external view returns (uint256) {
        PoolAddress.PoolKey memory poolkey = PoolAddress.getPoolKey(address(tokenOut), address(tokenIn), poolFee);

        address pool = PoolAddress.computeAddress(address(swapFactory), poolkey);

        uint256 reserve0 = IERC20(tokenOut).balanceOf(pool);
        uint256 reserve1 = IERC20(tokenIn).balanceOf(pool);

        require(reserve0 != 0 && reserve1 != 0 , "MassPayments: Tokens pair hasn't balance.");

        
        
        uint256 amountIn = reserve0 * amountOut * (10000 + feePercentMul100) * (100 + priceRangePercent) / 100 / (10000 * reserve1);

        return amountIn;
    }

    
    function convertETHToExactToken(uint256 amountOut, IERC20 tokenOut, uint256 amountInCalculated) external payable {
        require(amountOut > 0, "MassPayments: Must pass non 0 token amount.");
        require(msg.value >= amountInCalculated, "MassPayments: ETH amount not enough.");

        
        uint256 amountInFee = amountInCalculated * feePercentMul100 / 10000;
        uint256 amountInMaximum = (amountInCalculated - amountInFee);

        
        ISwapRouter.ExactOutputSingleParams memory paramsUser = ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(weth9),
            tokenOut: address(tokenOut),
            fee: poolFee,
            recipient: _msgSender(),
            deadline: block.timestamp + deadlineSwap,
            amountOut: amountOut,
            
            amountInMaximum: amountInMaximum,
            sqrtPriceLimitX96: 0
        });

        uint256 amountIn = swapRouter.exactOutputSingle{ value: amountInMaximum }(paramsUser);

        
        (bool sent,) = feeReceiver.call{ value: amountInFee }("");
        require(sent, "Failed to send Ether");
    
        
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "refund failed.");

        emit ETHToTokenConverted(msg.sender, amountIn, tokenOut, amountOut);
        emit ETHToTokenConvertedFeeSent(msg.sender, feeReceiver, amountInFee);
    }

    
    function convertTokenToExactToken(uint256 amountOut, IERC20 tokenTo, IERC20 tokenOut, uint256 amountInCalculated) external {
        require(amountOut > 0, "MassPayments: Must convert non 0 amount token out.");

        
        uint256 amountInFee = amountInCalculated * feePercentMul100 / 10000;
        uint256 amountInMaximum = (amountInCalculated - amountInFee);

        
        TransferHelper.safeTransferFrom(address(tokenTo), _msgSender(), address(this), amountInMaximum);

        
        
        TransferHelper.safeApprove(address(tokenTo), address(swapRouter), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(tokenTo),
            tokenOut: address(tokenOut),
            fee: poolFee,
            recipient: _msgSender(),
            deadline: block.timestamp,
            amountOut: amountOut,
            amountInMaximum: amountInMaximum,
            sqrtPriceLimitX96: 0
        });

        
        uint256 amountIn = swapRouter.exactOutputSingle(params);
        
        TransferHelper.safeTransferFrom(address(tokenTo), _msgSender(), feeReceiver, amountInFee);

        
        
        
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(address(tokenTo), address(swapRouter), 0);
            TransferHelper.safeTransfer(address(tokenTo), _msgSender(), amountInMaximum - amountIn);
        }

        emit TokenToTokenConverted(msg.sender, tokenTo, amountIn, tokenOut, amountOut);
        emit TokenToTokenConvertedFeeSent(msg.sender, feeReceiver, tokenTo, amountInFee);
    }

    function transferBatch(
        IERC20 transferToken, 
        address[] memory recipients, 
        uint256[] memory amounts
    ) external {
        require(recipients.length != 0, "MassPayments: Address array must not be empty.");
        require(recipients.length == amounts.length, "MassPayments: Transfer details should be of equal size.");

        uint256 totalAmount;        
        
        for (uint256 i = 0; i < amounts.length; i++) {
            require(recipients[i] !=  address(0x0), "MassPayments: Address must not be zero.");
            require(amounts[i] !=  0, "MassPayments: Transfer tokens amount should not be zero.");
            totalAmount += amounts[i];
        }

        
        uint256 feeAmount = totalAmount * feePercentMul100 / 10000;

        require(transferToken.balanceOf(_msgSender()) >= totalAmount + feeAmount, "MassPayments: Tokens amoumt not enough for transfer.");

        for (uint256 i = 0; i < amounts.length; i++) {
            transferToken.transferFrom(_msgSender(), recipients[i], amounts[i]);

            emit TokenTransfered(_msgSender(), recipients[i], transferToken, amounts[i]);
        }

         transferToken.transferFrom(_msgSender(), feeReceiver, feeAmount);

         emit BatchTransferedFeeSent(_msgSender(), feeReceiver, transferToken, feeAmount);
    }
}