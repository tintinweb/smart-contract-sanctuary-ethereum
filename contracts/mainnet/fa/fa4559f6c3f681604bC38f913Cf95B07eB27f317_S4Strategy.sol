pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function decimals() external view returns (uint256);
}

pragma solidity >=0.8.17;

// SPDX-License-Identifier: MIT

interface IFees {
    struct FeeTokenData {
        uint256 minBalance;
        uint256 fee;
    }

    //read functions

    function defaultFee() external view returns (uint256);

    function feeCollector(uint256 strategyId) external view returns (address);

    function feeTokenMap(uint256 strategyId, address feeToken)
        external
        view
        returns (FeeTokenData memory);    

    function depositStatus(uint256 strategyId) external view returns (bool);

    function whitelistedDepositCurrencies(uint256, address)
        external
        view
        returns (bool);

    function calcFee(
        uint256 strategyId,
        address user,
        address feeToken
    ) external view returns (uint256);

    //write functions    

    function setTokenFee(
        uint256 strategyId,
        address feeToken,
        uint256 minBalance,
        uint256 fee
    ) external;

    function setTokenMulti(
        uint256 strategyId,
        address[] calldata feeTokens,
        uint256[] calldata minBalance,
        uint256[] calldata fee) external;

    function setDepositStatus(uint256 strategyId, bool status) external;

    function setFeeCollector(address newFeeCollector) external;

    function setDefaultFee(uint newDefaultFee) external;

    function toggleWhitelistTokens(
        uint256 strategyId,
        address[] calldata tokens,
        bool state
    ) external;
}

pragma solidity >=0.8.17;
// SPDX-License-Identifier: GPL-2.0-or-later

interface INonfungiblePositionManagerProxy
    {
    function ownerOf(uint tokenId) external view returns(address);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

pragma solidity >=0.8.17;
// SPDX-License-Identifier: GPL-2.0-or-later

interface INonfungiblePositionManagerStrategy{
    function ownerOf(uint tokenId) external view returns(address);
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function safeTransferFrom(address from, address to, uint tokenId, bytes memory data) external;
       
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

pragma solidity >=0.8.17;
// SPDX-License-Identifier: MIT

interface ISwapRouter {
    function swapTokenForToken(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);
    function swapTokenForETH(address _tokenIn, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);
    function swapETHForToken(address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external payable returns(uint256);
    // function swap(address tokenIn, address tokenOut, uint amount, uint minAmountOut, address to) external;
}

pragma solidity >=0.5.0;
// SPDX-License-Identifier: MIT
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

pragma solidity >=0.5.0;
// SPDX-License-Identifier: MIT
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

    function initialize(address, address) external;
}

pragma solidity >=0.6.6;
//Uniswap V2 Router 02
// SPDX-License-Identifier: MIT
interface IUniswapV2Router{
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

}

pragma solidity >=0.5.0;
// SPDX-License-Identifier: GPL-2.0-or-later

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
   
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

}

pragma solidity >=0.8.17;
// SPDX-License-Identifier: GPL-2.0-or-later
interface IUniswapV3Pool {
    function token0() external view returns(address);
    function token1() external view returns(address);
    function fee() external view returns(uint24);
    function tickSpacing() external view returns(int24);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT
interface IWETH {
    function withdraw(uint wad) external;
}

import "../interfaces/IUniswapV2Router.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/INonfungiblePositionManagerProxy.sol";

pragma solidity ^0.8.17;
// SPDX-License-Identifier: MIT

contract S4Proxy {

    address deployer;
    address user;
    address nfpm = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address uniV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address factory=0x1F98431c8aD98523631AE4a59f267346ea31F984;

    struct V3NftData {
        uint24 poolFee;
        uint128 liquidity;        
        address token0;
        address token1;

    }

    //map of nftId to NftData
    mapping(uint => V3NftData) public nftDataMap;

    constructor(address user_){
        deployer=msg.sender;
        user=user_;
    }

    modifier onlyDeployer(){
        require(msg.sender == deployer, "onlyDeployer: Unauthorized");
        _;
    }

    bytes32 constant onERC721ReceivedResponse = keccak256("onERC721Received(address,address,uint256,bytes)");

    //@dev assumes token has already been transferred to contract
    function depositV3(address token0, address token1, uint amount0, uint amount1, int24 tickLower, int24 tickUpper, uint24 poolFee, uint nftId) public onlyDeployer returns(uint) {
        _approve(token0, nfpm);
        _approve(token1, nfpm);
        uint128 liquidity;
        uint amountA;
        uint amountB;
        if(nftId==0){
            //mint
            INonfungiblePositionManagerProxy.MintParams memory params =
                INonfungiblePositionManagerProxy.MintParams({
                    token0: token0,
                    token1: token1,
                    fee: poolFee,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    amount0Desired: amount0,
                    amount1Desired: amount1,
                    //Forced slippage of 2%
                    amount0Min: amount0*980/1000,
                    amount1Min: amount1*980/1000,
                    recipient: address(this),
                    deadline: block.timestamp
            });
            (nftId, liquidity, amountA, amountB) = INonfungiblePositionManagerProxy(nfpm).mint(params);
            //update mapping
            nftDataMap[nftId]=V3NftData({
                poolFee: poolFee,
                liquidity: liquidity,
                token0: token0,
                token1: token1
            });
        }else{
            //increase position
            INonfungiblePositionManagerProxy.IncreaseLiquidityParams memory params =
            INonfungiblePositionManagerProxy.IncreaseLiquidityParams({
                tokenId: nftId,
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: amount0*980/1000,
                amount1Min: amount1*980/1000,
                deadline: block.timestamp
            });
            ( liquidity, amountA, amountB)= INonfungiblePositionManagerProxy(nfpm).increaseLiquidity(params);
            nftDataMap[nftId].liquidity=liquidity;
            nftId=0;
        }   
        //any change will be left in this contract and swept in withdrawal   
        return nftId;
    }

    function withdrawV3(uint nftId, uint128 amount, address to ) public onlyDeployer returns(uint, uint){
        uint amount0;
        uint amount1;
        INonfungiblePositionManagerProxy.DecreaseLiquidityParams memory params =
            INonfungiblePositionManagerProxy.DecreaseLiquidityParams({
                tokenId: nftId,
                liquidity: amount,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });
        (amount0, amount1) = INonfungiblePositionManagerProxy(nfpm).decreaseLiquidity(params);
        claimV3(nftId, address(this));
        //We withdraw everything including any dust left in the proxy contract
        if(to!=address(this) && amount0>0){
            address token0=nftDataMap[nftId].token0;
            amount0=IERC20(token0).balanceOf(address(this));
            IERC20(token0).transfer(to, amount0);
        }
        if(to!=address(this) && amount1>0){
            address token1=nftDataMap[nftId].token1;
            amount1=IERC20(token1).balanceOf(address(this));
            IERC20(token1).transfer(to, amount1);
        }
        return(amount0, amount1);
    }

    function claimV3(uint nftId, address to) public onlyDeployer returns(uint, uint){
        //it is expected that the nft is sitting on the proxy contract
        INonfungiblePositionManagerProxy.CollectParams memory params =
            INonfungiblePositionManagerProxy.CollectParams({
                tokenId: nftId,
                //we send the fees direct to user
                recipient: to,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            });
        return (INonfungiblePositionManagerProxy(nfpm).collect(params));        
    }

    function updateV3(uint nftId, int24 newTickLower, int24 newTickUpper) external onlyDeployer returns (uint){        
        //withdraw liquidity from current nft
        (uint amount0, uint amount1) = withdrawV3(nftId, nftDataMap[nftId].liquidity, address(this));
        //deposit with new tick parameters        
        uint newNftId=depositV3(nftDataMap[nftId].token0, nftDataMap[nftId].token1, amount0, amount1, newTickLower, newTickUpper, nftDataMap[nftId].poolFee, 0);
        //burn existing nft
        INonfungiblePositionManagerProxy(nfpm).burn(nftId);
        //remove nft from mapping
        delete nftDataMap[nftId];
        //nft mapping will be updated by deposit function
        return newNftId;
    }

    function withdrawV3Nft(uint nftId) external onlyDeployer returns(uint){
        INonfungiblePositionManagerProxy(nfpm).safeTransferFrom(address(this), user, nftId);
        return nftId;
    }

    //V2 functions
    function depositV2(address token0, address token1, uint token0Amt, uint token1Amt) external onlyDeployer {
        _approve(token0, uniV2Router);
        _approve(token1, uniV2Router);
        IUniswapV2Router(uniV2Router).addLiquidity(token0, token1, token0Amt, token1Amt, token0Amt*970/1000, token1Amt*970/1000, address(this), block.timestamp);        
        //any change will be left in this contract and swept in withdrawal
    }

    function withdrawV2(address token0, address token1, address poolAddress, uint amount) external onlyDeployer returns(uint, uint){
        _approve(poolAddress, uniV2Router);
        //minAmountOut is enforced by strategy contract
        (uint amountA, uint amountB) =  (IUniswapV2Router(uniV2Router).removeLiquidity(token0, token1, amount, 0, 0, msg.sender, block.timestamp));
        //Sweep dust
        uint balanceA=IERC20(token0).balanceOf(address(this));
        uint balanceB=IERC20(token1).balanceOf(address(this));
        if(balanceA>0){
            IERC20(token0).transfer(msg.sender, balanceA);
            amountA+=balanceA;
        }
        if(balanceB>0){
            IERC20(token1).transfer(msg.sender, balanceB);
            amountB+=balanceB;
        }
        return(amountA, amountB);
    }
    
    //Used to withdraw any token to user
    function withdrawToUser(address token, uint amount) external onlyDeployer {
        IERC20(token).transfer(user, amount);
    }

    function _approve(address token, address spender) internal {
        if(IERC20(token).allowance(address(this), spender)==0){
            IERC20(token).approve(spender, 2**256-1);
        }
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        require(msg.sender==nfpm && from==deployer, "S4Proxy: Invalid sender");
        (uint24 poolFee, uint128 liquidity, address token0, address token1)=abi.decode(data,(uint24, uint128, address, address));
        nftDataMap[tokenId]=V3NftData({
            poolFee:poolFee,
            liquidity: liquidity,
            token0:token0,
            token1:token1
        });
        return bytes4(onERC721ReceivedResponse);
    }
}

import "./interfaces/IUniswapV3Factory.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/INonfungiblePositionManagerStrategy.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IFees.sol";
import "./interfaces/IERC20.sol";

import "./proxies/S4Proxy.sol";

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

contract S4Strategy {
    address immutable swapRouter;
    address immutable feeContract;
    address constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant uniV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address constant uniV3Factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant nfpm = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    constructor(address swapRouter_, address feeContract_) {
        swapRouter = swapRouter_;
        feeContract = feeContract_;
    }

    uint256 public constant strategyId = 13;

    bytes32 constant onERC721ReceivedResponse =
        keccak256("onERC721Received(address,address,uint256,bytes)");

    //TICK MATH constants
    //https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol
    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    //mappings

    //mapping of user address to proxy contract
    //user address => proxy contract
    mapping(address => address) public depositors;

    //mapping of user's v3PositionNft
    //assumption is made that nftId 0 will never exist
    //user => token0 => token1 => poolFee => nftId
    mapping(address => mapping(address => mapping(address => mapping(uint24 => uint256))))
        public v3PositionNft;

    //events
    event Deposit(
        address depositor,
        address poolAddress,
        address tokenIn,
        uint256 amount
    );
    event Withdraw(
        address depositor,
        address poolAddress,
        address tokenOut,
        uint256 amount,
        uint256 fee
    );

    event v3Deposit(
        address depositor,
        address poolAddress,
        uint256 nftId,
        uint256 token0Amt,
        uint256 token1Amt
    );
    event v3Withdraw(
        address depositor,
        address poolAddress,
        uint256 nftId,
        uint256 token0Amt,
        uint256 token1Amt
    );

    event v2Deposit(
        address depositor,
        address poolAddress,
        uint256 token0Amt,
        uint256 token1Amt
    );
    event v2Withdraw(
        address depositor,
        address poolAddress,
        uint256 token0Amt,
        uint256 token1Amt
    );

    event Claim(
        address depositor,
        uint256 nftId,
        address tokenOut,
        uint256 amount
    );

    event v3Update(
        address token0,
        uint256 nftId,
        int24 tickLower,
        int24 tickUpper
    );
    event v3NftWithdraw(address depositor, uint256 nftId);

    event ProxyCreation(address user, address proxy);

    //modifiers
    modifier whitelistedToken(address token) {
        require(
            IFees(feeContract).whitelistedDepositCurrencies(strategyId, token),
            "whitelistedToken: invalid token"
        );
        _;
    }

    //V3 functions
    //getter for v3 position
    function getV3Position(uint256 nftId)
        public
        view
        returns (
            //0: nonce
            uint96,
            //1: operator
            address,
            //2: token0
            address,
            //3: token1
            address,
            //4: fee
            uint24,
            //5:tickLower
            int24,
            //6:tickUpper
            int24,
            //7:liquidity (@dev current deposit)
            uint128,
            //8:feeGrowthInside0LastX128
            uint256,
            //9:feeGrowthInside1LastX128
            uint256,
            //10:tokensOwed0 (@dev avaliable to claim)
            uint128,
            //11:tokensOwed1 (@dev avaliable to claim)
            uint128
        )
    {
        return INonfungiblePositionManagerStrategy(nfpm).positions(nftId);
    }

    //getter for v3 pool data given poolAddress
    function getV3PoolData(address poolAddress)
        public
        view
        returns (
            address,
            address,
            uint24
        )
    {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);
        return (pool.token0(), pool.token1(), pool.fee());
    }

    //getter for v3 PoolAddress give tokens and fees
    function getV3PoolAddress(
        address token0,
        address token1,
        uint24 fee
    ) public view returns (address) {
        return IUniswapV3Factory(uniV3Factory).getPool(token0, token1, fee);
    }

    //getter for v3 position NFTs
    function getV3PositionNft(
        address user,
        address token0,
        address token1,
        uint24 poolFee
    )
        public
        view
        returns (
            address,
            address,
            uint256
        )
    {
        address _token0 = token0;
        address _token1 = token1;
        uint256 nftId = v3PositionNft[user][token0][token1][poolFee];
        if (nftId == 0) {
            _token0 = token1;
            _token1 = token0;
            nftId = v3PositionNft[user][token1][token0][poolFee];
        }
        return (_token0, _token1, nftId);
    }

    //updates the liquidity band
    //@dev this call is extremely expensive
    //the position is withdrawn, nft burnt and reminted with redefined liquidity band
    function updateV3Position(
        address token0,
        address token1,
        uint24 poolFee,
        int24 tickLower,
        int24 tickUpper
    ) external {
        uint256 nftId;
        (token0, token1, nftId) = getV3PositionNft(
            msg.sender,
            token0,
            token1,
            poolFee
        );
        nftId = S4Proxy(depositors[msg.sender]).updateV3(
            nftId,
            tickLower,
            tickUpper
        );
        //update mapping with new nft
        v3PositionNft[msg.sender][token0][token1][poolFee] = nftId;
        emit v3Update(msg.sender, nftId, tickLower, tickUpper);
    }

    //allows user to claim fees
    //pass in address(0) to receive ETH
    //claim only avaliable on uniV3
    //we force claim the maximum possible amount for both tokens
    function claimV3(
        address token0,
        address token1,
        uint256 nftId,
        address tokenOut,
        uint256 amountOutMin
    ) external whitelistedToken(tokenOut) {
        uint256 result;
        address _tokenOut = tokenOut == address(0) ? wethAddress : tokenOut;
        (uint256 amountA, uint256 amountB) = S4Proxy(depositors[msg.sender])
            .claimV3(nftId, address(this));
        result = _swapTwoToOne(token0, token1, amountA, amountB, _tokenOut);
        require(result >= amountOutMin, "claim: amountOutMin not met");
        _sendToken(tokenOut, msg.sender, result);
        emit Claim(msg.sender, nftId, tokenOut, result);
    }

    //V2 Functions
    //getter for v2 pools
    function getV2PoolData(address poolAddress)
        public
        view
        returns (address, address)
    {
        IUniswapV2Pair pool = IUniswapV2Pair(poolAddress);
        return (pool.token0(), pool.token1());
    }

    function getV2PoolAddress(address token0, address token1)
        public
        view
        returns (address)
    {
        return IUniswapV2Factory(uniV2Factory).getPair(token0, token1);
    }

    //@dev pass address(0) for eth
    function depositToken(
        address tokenIn,
        address poolAddress,
        uint256 amount,
        uint256 token0MinOut,
        uint256 token1MinOut,
        bytes calldata params
    ) public payable whitelistedToken(tokenIn) {
        require(_depositStatus(), "depositToken: depositsStopped");
        address proxy;
        address _tokenIn = tokenIn;
        if (msg.value > 0) {
            (bool success, ) = payable(wethAddress).call{value: msg.value}("");
            require(success);
            amount = msg.value;
            _tokenIn = wethAddress;
        } else {
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
        }
        //Check if proxy exists, else mint
        if (depositors[msg.sender] == address(0)) {
            proxy = _mintProxy(msg.sender);
        } else {
            proxy = depositors[msg.sender];
        }
        IUniswapV2Pair pool = IUniswapV2Pair(poolAddress);
        address token0 = pool.token0();
        address token1 = pool.token1();
        address factory = pool.factory();
        uint256 token0Amt = amount / 2;
        uint256 token1Amt = amount - token0Amt;
        //tickLower & tickUpper ignored for v2
        //tickLower & tickUpper will be the full range if 0 is passed
        if (_tokenIn != token0) {
            //swap half for token0 to proxy
            _approve(_tokenIn, swapRouter);
            token0Amt = ISwapRouter(swapRouter).swapTokenForToken(
                _tokenIn,
                token0,
                token0Amt,
                token0MinOut,
                address(this)
            );
        }
        if (_tokenIn != token1) {
            //swap half for token1 to proxy
            _approve(_tokenIn, swapRouter);
            token1Amt = ISwapRouter(swapRouter).swapTokenForToken(
                _tokenIn,
                token1,
                token1Amt,
                token1MinOut,
                address(this)
            );
        }
        IERC20(token0).transfer(proxy, token0Amt);
        IERC20(token1).transfer(proxy, token1Amt);
        if (factory == uniV3Factory) {
            //v3 deposit
            (int24 tickLower, int24 tickUpper) = abi.decode(
                params,
                (int24, int24)
            );
            //check if user has existing nft
            //returns 0 if no existing nft
            uint24 poolFee = IUniswapV3Pool(poolAddress).fee();

            //verify pool
            require(
                IUniswapV3Factory(uniV3Factory).getPool(
                    token0,
                    token1,
                    poolFee
                ) == poolAddress,
                "depositToken: Invalid V3 pool"
            );

            //get tick spacing
            int24 tickSpacing = IUniswapV3Pool(poolAddress).tickSpacing();

            //check and assign default value to tick if required
            tickLower = tickLower == 0 ? MIN_TICK : tickLower;
            tickUpper = tickUpper == 0 ? MAX_TICK : tickUpper;

            //ensure ticks are divisible by tick spacing
            tickLower = tickLower < 0
                ? -((-tickLower / tickSpacing) * tickSpacing)
                : (tickLower / tickSpacing) * tickSpacing;
            tickUpper = tickUpper < 0
                ? -((-tickUpper / tickSpacing) * tickSpacing)
                : (tickUpper / tickSpacing) * tickSpacing;

            uint256 nftId = v3PositionNft[msg.sender][token0][token1][poolFee];
            emit v3Deposit(
                msg.sender,
                poolAddress,
                nftId,
                token0Amt,
                token1Amt
            );
            //minting returns nftId > 0
            //increaseLiquidityPosition returns nftId 0
            nftId = S4Proxy(depositors[msg.sender]).depositV3(
                token0,
                token1,
                token0Amt,
                token1Amt,
                tickLower,
                tickUpper,
                poolFee,
                nftId
            );
            if (nftId > 0) {
                v3PositionNft[msg.sender][token0][token1][poolFee] = nftId;
            }
        } else {
            //verify pool
            require(
                IUniswapV2Factory(uniV2Factory).getPair(token0, token1) ==
                    poolAddress,
                "depositToken: Invalid V2 pair"
            );
            //v2 deposit
            S4Proxy(depositors[msg.sender]).depositV2(
                token0,
                token1,
                token0Amt,
                token1Amt
            );
            emit v2Deposit(msg.sender, poolAddress, token0Amt, token1Amt);
        }
        emit Deposit(msg.sender, poolAddress, tokenIn, amount);
    }

    //@dev pass address(0) for ETH
    function withdrawToken(
        address tokenOut,
        address poolAddress,
        uint128 amount,
        uint256 minAmountOut,
        address feeToken
    ) public whitelistedToken(tokenOut) {
        IUniswapV2Pair pool = IUniswapV2Pair(poolAddress);
        address token0 = pool.token0();
        address token1 = pool.token1();
        address factory = pool.factory();
        address proxy = depositors[msg.sender];
        //amount of token0 received
        uint256 amountA;
        //amount of token1 received
        uint256 amountB;

        uint256 result;

        address _tokenOut = tokenOut == address(0) ? wethAddress : tokenOut;

        if (factory == uniV3Factory) {
            //We ignore the nft transfer to save gas
            //The proxy contract will hold the position NFT by default unless withdraw requested by user
            uint24 poolFee = IUniswapV3Pool(poolAddress).fee();
            (, , uint256 nftId) = getV3PositionNft(
                msg.sender,
                token0,
                token1,
                poolFee
            );
            (amountA, amountB) = S4Proxy(proxy).withdrawV3(
                nftId,
                amount,
                address(this)
            );
            emit v3Withdraw(msg.sender, poolAddress, nftId, amountA, amountB);
        } else {
            (amountA, amountB) = S4Proxy(proxy).withdrawV2(
                token0,
                token1,
                poolAddress,
                amount
            );
            emit v2Withdraw(msg.sender, poolAddress, amountA, amountB);
        }
        result = _swapTwoToOne(token0, token1, amountA, amountB, _tokenOut);
        require(result >= minAmountOut, "withdrawToken: minAmountOut not met");
        //transfer fee to feeCollector
        uint256 fee = ((
            IFees(feeContract).calcFee(
                strategyId,
                msg.sender,
                feeToken == address(0) ? tokenOut : feeToken
            )
        ) * result) / 1000;
        IERC20(_tokenOut).transfer(
            IFees(feeContract).feeCollector(strategyId),
            fee
        );
        //Return token to sender
        _sendToken(tokenOut, msg.sender, result - fee);
        emit Withdraw(msg.sender, poolAddress, tokenOut, result-fee, fee);
    }

    //swap multiple tokens to one
    function _swapTwoToOne(
        address token0,
        address token1,
        uint256 amountA,
        uint256 amountB,
        address _tokenOut
    ) internal returns (uint256) {
        ISwapRouter router = ISwapRouter(swapRouter);
        //optimistically assume result
        uint256 result = amountA + amountB;
        if (_tokenOut != token0 && amountA > 0) {
            //deduct incorrect amount
            result -= amountA;
            _approve(token0, swapRouter);
            //swap and add correct amount to result
            result += router.swapTokenForToken(
                token0,
                _tokenOut,
                amountA,
                1,
                address(this)
            );
        }
        if (_tokenOut != token1 && amountB > 0) {
            //deduct incorrect amount
            result -= amountB;
            _approve(token1, swapRouter);
            //swap and add correct amount to result
            result += router.swapTokenForToken(
                token1,
                _tokenOut,
                amountB,
                1,
                address(this)
            );
        }
        return result;
    }

    //withdraw position NFT to user
    function withdrawV3PositionNft(
        address token0,
        address token1,
        uint24 poolFee,
        uint256 nftId
    ) external {
        require(!_depositStatus());
        require(
            v3PositionNft[msg.sender][token0][token1][poolFee] > 0,
            "No NFT"
        );
        //delete nft form mapping
        v3PositionNft[msg.sender][token0][token1][poolFee] = 0;
        //we use the proxy map to gatekeep the rightful nft owner
        S4Proxy(depositors[msg.sender]).withdrawV3Nft(nftId);
        emit v3NftWithdraw(msg.sender, nftId);
    }

    //withdraw any token to user
    function emergencyWithdraw(address token, uint256 amount) external {
        require(!_depositStatus());
        S4Proxy(depositors[msg.sender]).withdrawToUser(token, amount);
    }

    function _depositStatus() internal view returns (bool) {
        return IFees(feeContract).depositStatus(strategyId);
    }

    // internal functions
    function _approve(address token, address spender) internal {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).approve(spender, 2**256 - 1);
        }
    }

    function _sendToken(
        address tokenOut,
        address to,
        uint256 amount
    ) internal {
        if (tokenOut != address(0)) {
            IERC20(tokenOut).transfer(to, amount);
        } else {
            //unwrap eth
            IWETH(wethAddress).withdraw(amount);
            (bool sent, ) = payable(to).call{value: amount}("");
            require(sent, "_sendToken: send ETH fail");
        }
    }

    function _mintProxy(address user) internal returns (address) {
        require(
            depositors[user] == address(0),
            "_mintProxy: proxy already exists"
        );
        S4Proxy newProxy = new S4Proxy(user);
        address proxy = address(newProxy);
        depositors[user] = proxy;
        emit ProxyCreation(user, proxy);
        return proxy;
    }

    //hook called when nft is transferred to contract
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        require(_depositStatus());
        require(msg.sender == nfpm, "Unauthorized");
        require(
            INonfungiblePositionManagerStrategy(nfpm).ownerOf(tokenId) ==
                address(this),
            "S4Strategy: Invalid NFT"
        );
        if (depositors[from] == address(0)) {
            _mintProxy(depositors[from]);
        }
        //add position nft to mapping
        (
            ,
            ,
            address token0,
            address token1,
            uint24 poolFee,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,

        ) = getV3Position(tokenId);
        require(
            v3PositionNft[from][token0][token1][poolFee] == 0,
            "S4Strategy: Position already exists"
        );
        v3PositionNft[from][token0][token1][poolFee] = tokenId;
        bytes memory tokenData = abi.encode(poolFee, liquidity, token0, token1);
        INonfungiblePositionManagerStrategy(nfpm).safeTransferFrom(
            address(this),
            depositors[from],
            tokenId,
            tokenData
        );
        return bytes4(onERC721ReceivedResponse);
    }

    receive() external payable {}
}