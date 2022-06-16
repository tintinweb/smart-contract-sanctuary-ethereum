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

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
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
contract FarmingContract is Ownable {
    
    struct Farmer {
        uint256 amount;
        uint256 lastClaimed;
        uint256 depositDate;
        bool tokenType;
    }

    IPancakeSwapRouter public router;
    mapping(address => Farmer) user;
    address public lpUSDC;
    address public lpUSCT;
    IERC20 lpUSDCContract;
    IERC20 lpUSCTContract;
    IERC20 _stbContract;
    IERC20 _usctContract;
    IERC20 _usdcContract;  

    address public usdc = 0x30a3F21C57595dd807EABCb396AC81D1aeFFf6c2;
    address public stb = 0x4ba73FD60167e817d4C129d29eAc5d0b1C402f2a;
    address public usct = 0x077cb854f5dcA95D3B485784697dc9F4e791E6bC;
    uint128 apyFee;

    constructor() {
        apyFee = 30;

        _usctContract = IERC20(usct);
        _stbContract  = IERC20(stb);
        _usdcContract = IERC20(usdc);
        router = IPancakeSwapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // bsc testnet

        lpUSDC = IPancakeSwapFactory(router.factory()).getPair(usdc, stb);
        if (lpUSDC == address(0)) {
            lpUSDC = IPancakeSwapFactory(router.factory()).createPair(
                stb, // stb on testnet without balance
                usdc // usdc on testnet without balance
            );
        }
        lpUSCT = IPancakeSwapFactory(router.factory()).getPair(usct, stb);
        if (lpUSCT == address(0)) {
            lpUSCT = IPancakeSwapFactory(router.factory()).createPair(
                usct, // usct on testnet without balance
                stb // stb on testnet without balance
            );
        }
        lpUSDCContract = IERC20(lpUSDC);
        lpUSCTContract = IERC20(lpUSCT);
    }

    function initLiquidity() public onlyOwner {
        _usctContract.approve(address(router), 999999999999999999999);
        _usdcContract.approve(address(router), 999999999999999999999);
        _stbContract.approve(address(router), 999999999999999999999);
        router.addLiquidity(
            usdc,
            stb,
            100 * 10 ** 18,
            100 * 10 ** 18,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        router.addLiquidity(
            usct,
            stb,
            100 * 10 ** 18,
            100 * 10 ** 18,
            0,
            0,
            msg.sender,
            block.timestamp
        );
        router.addLiquidity(
            usdc,
            stb,
            100 * 10 ** 18,
            100 * 10 ** 18,
            0,
            0,
            address(this),
            block.timestamp
        );
        router.addLiquidity(
            usct,
            stb,
            100 * 10 ** 18,
            100 * 10 ** 18,
            0,
            0,
            address(this),
            block.timestamp
        );
        // lpUSCTContract.transfer(msg.sender, 50 * 10 ** 18);
        // lpUSDCContract.transfer(msg.sender, 50 * 10 ** 18);
    }
    
    function setAPYFee(uint128 _apyFee) public onlyOwner {
        apyFee = _apyFee;
    }
    function deposit(bool tokenType, uint256 amount) public {
        require(user[msg.sender].amount == 0, "exist");
        Farmer storage value = user[msg.sender];
        value.depositDate = block.timestamp;
        value.lastClaimed = block.timestamp;
        value.tokenType = tokenType;
        if(tokenType)
        {
            require(lpUSCTContract.balanceOf(msg.sender) >= amount, "usctsmall");
            value.amount = amount;
            lpUSCTContract.transferFrom(msg.sender, address(this), value.amount);
            // tokenType == 1 lp : usct-stb
        } else {
            require(lpUSDCContract.balanceOf(msg.sender) >= amount, "usdcsmall");
            value.amount = amount;
            lpUSDCContract.transferFrom(msg.sender, address(this), value.amount);
            // tokenType == 0 lp : usdc-stb
        }
    } 

    function claimedRequest() public {
        require(user[msg.sender].amount != 0, "exist");
        user[msg.sender].lastClaimed = block.timestamp;
    }

    function claimed(bool rewardType) public {
        require(block.timestamp - user[msg.sender].lastClaimed >= 5, "locktime");
        uint256 _reward = calcReward();
        if(rewardType){
            address[] memory path = new address[](2);
            path[0] = stb;
            path[1] = usct;
            uint256[] memory usctAmount = new uint256[](2);
            _usctContract.approve(address(router), _reward);
            _stbContract.approve(address(router), _reward);
            usctAmount = router.swapExactTokensForTokens(_reward, 0, path, address(this), block.timestamp);
            _usctContract.transfer(msg.sender, usctAmount[1]);
            // rewardType ture ->reward : usct
        } else {
            _stbContract.transfer(msg.sender, _reward);
            // rewardType false ->reward : stb
        }
        user[msg.sender].depositDate = block.timestamp;
    }

    function withDraw(bool rewardType) public {
        require(block.timestamp - user[msg.sender].lastClaimed >= 5, "locktime");
        claimed(rewardType);
        if(user[msg.sender].tokenType){
            lpUSCTContract.transfer(msg.sender, user[msg.sender].amount);
        } else {
            lpUSDCContract.transfer(msg.sender, user[msg.sender].amount);
        }
        user[msg.sender].amount = 0;
    }

    function calcReward() public view returns(uint256 _reward) {
        _reward = (user[msg.sender].lastClaimed - user[msg.sender].depositDate) * user[msg.sender].amount * apyFee / 100 / 365 days / 1 days;
        return _reward;    
    }
}