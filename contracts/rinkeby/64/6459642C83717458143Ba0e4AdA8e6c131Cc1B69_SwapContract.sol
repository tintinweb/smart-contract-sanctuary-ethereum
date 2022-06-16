// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 value) external ;
    function burn(address to, uint256 value) external ;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPancakeSwapPair {
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

    function initialize(address, address) external;
}

interface IPancakeSwapRouter{
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

interface IPancakeSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract SwapContract is Ownable {
    IPancakeSwapRouter public router;
    IPancakeSwapPair public pairContract;
    address public pair;
    address public pair1;
    address public pair2;
    address public usdc = 0x30a3F21C57595dd807EABCb396AC81D1aeFFf6c2;
    address public stb = 0x4ba73FD60167e817d4C129d29eAc5d0b1C402f2a;
    address public usct = 0x077cb854f5dcA95D3B485784697dc9F4e791E6bC;
    uint128 public tax ;
    IERC20 _usdcContract;
    IERC20 _usctContract;
    IERC20 _stbContract;
    uint256 public amountAToken;
    uint256 public amountBToken;
   	constructor() {

        _usdcContract = IERC20(usdc);
        _usctContract = IERC20(usct);
        _stbContract  = IERC20(stb);
        tax = 15;
        // router = IPancakeSwapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // rinkeby mainnet
        router = IPancakeSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // rinkeby testnet
        pair = IPancakeSwapFactory(router.factory()).getPair(usct, usdc);
        if (pair == address(0)) {
            pair = IPancakeSwapFactory(router.factory()).createPair(
                usct, // usct on testnet without balance
                usdc // usdc on testnet without balance
            );
        }
        pair1 = IPancakeSwapFactory(router.factory()).getPair(usct, stb);
        if (pair1 == address(0)) {
            pair1 = IPancakeSwapFactory(router.factory()).createPair(
                usct, // usct on testnet without balance
                stb // stb on testnet without balance
            );
        }
        pair2 = IPancakeSwapFactory(router.factory()).getPair(usdc, stb);
        if (pair2 == address(0)) {
            pair2 = IPancakeSwapFactory(router.factory()).createPair(
                stb, // stb on testnet without balance
                usdc // usdc on testnet without balance
            );
        }
   	}

    function buyUSCT(uint256 amount) public {
        require(amount > 0, "zero");
        _usctContract.mint(address(this), amount * 2);
        _usdcContract.transferFrom(msg.sender, address(this), amount);
        createLiquidity(amount);
        _usctContract.transfer(msg.sender, amount); 
    }  

    function sellUSCT(uint256 amount) public {
        require(amount > 0, "zero");
        _usctContract.burn(msg.sender, amount);
        uint256 usdcAmount;
        uint256 usctAmount;
        (usctAmount, usdcAmount) = removeLiquidity(amount);
        _usdcContract.transfer(msg.sender, usdcAmount);
        _usctContract.burn(address(this), usctAmount); 
    }

    function setTax(uint128 _tax) public onlyOwner{
        tax = _tax;
    }

    function createLiquidity(uint256 amount) private {
        _usctContract.approve(address(router), amount);
        _usdcContract.approve(address(router), amount);
        router.addLiquidity(
            usct,
            usdc,
            amount,
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function initLiquidity() public onlyOwner {
        _usctContract.approve(address(router), 999999999999999999999);
        _usdcContract.approve(address(router), 999999999999999999999);
        _stbContract.approve(address(router), 999999999999999999999);
        router.addLiquidity(
            usct,
            usdc,
            1000000000000000000,
            1000000000000000000,
            0,
            0,
            address(this),
            block.timestamp
        );
        router.addLiquidity(
            usdc,
            stb,
            1000000000000000000,
            1000000000000000000,
            0,
            0,
            address(this),
            block.timestamp
        );
        router.addLiquidity(
            usct,
            stb,
            1000000000000000000,
            1000000000000000000,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function removeLiquidity(uint256 amount) private returns (uint256, uint256){
        IPancakeSwapPair(pair).approve(address(router), amount);
        return router.removeLiquidity(
            usct,
            usdc,
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function buySTB(uint256 amount) public {
        require(amount > 0, "zero");
        _usdcContract.transferFrom(msg.sender, address(this), amount);

        address[] memory path = new address[](2);
        path[0] = usdc;
        path[1] = stb;
        uint256[] memory stbAmount = new uint256[](2);
        _usdcContract.approve(address(router), amount);
        _stbContract.approve(address(router), amount);
        stbAmount = router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
        _stbContract.transfer(msg.sender, amount * (100 - tax) / 100);
        _usctContract.mint(msg.sender, amount * tax / 100);

        _stbContract.transfer(msg.sender, stbAmount[1] * (100 - tax) / 100);
        _usctContract.mint(msg.sender, stbAmount[1] * tax / 100);
        createLiquidity(amount * tax / 100);
    }

    function sellSTB(uint256 amount) public {
        require(amount > 0, "zero");

        _stbContract.transferFrom(msg.sender, address(this), amount);

        address[] memory path = new address[](2);
        path[0] = stb;
        path[1] = usdc;
        uint256[] memory usdcAmount = new uint256[](2);
        _usdcContract.approve(address(router), amount);
        _stbContract.approve(address(router), amount);
        usdcAmount = router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);

        _usdcContract.transfer(msg.sender, usdcAmount[1] * (100 - tax) / 100);
        _usctContract.mint(msg.sender, usdcAmount[1] * tax / 100);
        createLiquidity(usdcAmount[1] * tax / 100);
    }
}