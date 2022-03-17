// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAKCCore.sol";
import "./interfaces/IAKCReserve.sol";
//import "./interfaces/ISwapRouter.sol";
//import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
//import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
//import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/**
 * @dev Interfaces between user and AKCCore
 * Allows for creation of tribes and redeeming
 * of rewards.
 */
contract AKCTribeManager is Ownable, ReentrancyGuard {

    /**
     * @dev EXTERNAL CONTRACTS
     */
    IERC20 public akcCoin;
    IAKCCore public akcCore;
    IAKCReserve public akcReserve;
    IUniswapV2Router02 public router;
    address private akcDistributor;

    /**
     * @dev PURCHASE TERMS
     */     
    uint256 public reserveAllocation;
    uint256 public liquidityAllocation;
    uint256 public distributorAllocation;
    bool public enforceTerms = true;
    uint256 public minimumEnforceBalance = 100;

    bool test_sendToReserve = true;
    bool test_swapLiquidity = true;
    bool test_liquidityUniswapSwap = true;
    bool test_liquidityAddLiquidity = false;
    bool test_swapRest = false;

    /**
     * @dev EVENTS
     */
    event PurchaseTribeEvent(address indexed purchaser, uint256 indexed spec, string indexed identifier);
    event LiquidityAdded(uint256 indexed akcCoin, uint256 indexed eth);
    event ClaimRewardOfTribeEvent(address indexed user, uint256 indexed tribeIndex, uint256 indexed amount);
    event ClaimAllRewardsOfUser(address indexed user, uint256 indexed amount);

    /// @dev Setters
    event SetAKCCoinEvent(address indexed akc);
    event SetAkcCoreEvent(address indexed akc);
    event SetAkcReserveEvent(address indexed akc);
    event SetRouterEvent(address indexed rtr);
    event SetAkcDistributorEvent(address indexed akc);
    event SetReserveAllocationEvent(uint256 indexed allocation);
    event SetLiquidityAllocationEvent(uint256 indexed allocation);
    event SetDistributorAllocationEvent(uint256 indexed allocation);
    event SetEnforceTermsEvent(bool indexed enforce);
    event SetMinimumEnforceBalanceEvent(uint256 indexed minBalance);

    constructor(
        address _akcCoin,
        address _akcCore,
        address _akcReserve,        
        address _distributor,
        address _router,
        uint256 _initialReserveAllocation,
        uint256 _initialLiquidityAllocation,
        uint256 _initialDistributorAllocation
    ) {
        akcCoin = IERC20(_akcCoin);
        akcCore = IAKCCore(_akcCore);
        akcReserve = IAKCReserve(_akcReserve);
        router = IUniswapV2Router02(_router);
        akcDistributor = _distributor;

        reserveAllocation = _initialReserveAllocation;
        liquidityAllocation = _initialLiquidityAllocation;
        distributorAllocation = _initialDistributorAllocation;
    }

    /** DEX HELPER METHODS */
    function swapTokensForEth(uint256 tokenAmount) public {
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        akcCoin.approve(address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) public {
        // approve token transfer to cover all possible scenarios
        akcCoin.approve(address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function sendToLiquidity(uint256 akcAmount) internal {
        uint256 toEth = akcAmount / 2;
        uint256 toAKC = akcAmount - toEth;
        uint256 contractBalance = address(this).balance;

        if (test_liquidityUniswapSwap)
            swapTokensForEth(toEth);
        uint256 ethAdded = address(this).balance - contractBalance;

        if (test_liquidityAddLiquidity)
            addLiquidity(toAKC, ethAdded);

        emit LiquidityAdded(toAKC, ethAdded);
    }

    /*function swapAkcToEth(uint256 akcAmount) internal {        
        uniswapV2Swap(akcAmount, address(this));
    }

    function uniswapV2Swap(uint256 akcAmount, address to) internal {
        address[] memory path = new address[](2);
        path[0] = address(akcCoin);
        path[1] = router.WETH();

        akcCoin.approve(address(router), akcAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(akcAmount, 0, path, to, block.timestamp);
    }

    function uniswapV2AddLiquidity(uint256 akcAmount, uint256 ethAmount) internal {
        akcCoin.approve(address(router), akcAmount);

        // add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(akcCoin),
            akcAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }*/

    /*function uniswapV3Swap(uint256 akcAmount) internal {
        address tokenIn = address(akcCoin);
        address tokenOut = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH9
        uint24 fee = 3000;
        address recipient = address(akcDistributor);
        uint256 deadline = block.timestamp + 15;
        uint256 amountIn = akcAmount;
        uint256 amountOutMinimum = 0;
        uint160 sqrtPriceLimitX96 = 0;

        TransferHelper.safeApprove(address(akcCoin), address(router), amountIn);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            tokenIn,
            tokenOut,
            fee,
            recipient,
            deadline,
            amountIn,
            amountOutMinimum,
            sqrtPriceLimitX96
        );

        router.exactInputSingle(params);
    }

    function uniswapV3AddLiquidity(uint256 akcAmount, uint256 ethAmount) internal {
        akcCoin.approve(address(router), akcAmount);
    }*/

    /** PURCHASING TRIBES */

    function purchaseTribe(uint256 spec, string calldata identifier)
        external
        nonReentrant { 
            require(spec < akcCore.getTribeSpecAmount(), "SPEC OUT OF BOUNDS");

            (uint256 price,,) = akcCore.tribeSpecs(spec);
            require(akcCoin.allowance(msg.sender, address(this)) >= price, "ALLOWANCE TOO LOW");
            require(akcCoin.balanceOf(msg.sender) >= price, "BALANCE TOO LOW");

            akcCoin.transferFrom(msg.sender, address(this), price);

            uint256 contractBalance = akcCoin.balanceOf(address(this));
            bool minimumReached = contractBalance >= minimumEnforceBalance;
            if (enforceTerms && minimumReached && msg.sender != owner()) {
                uint256 toReserve = contractBalance * reserveAllocation / 100;
                uint256 toLiquidity = contractBalance * liquidityAllocation / 100;

                if (test_sendToReserve)
                    akcCoin.transfer(address(akcReserve), toReserve);
                
                if (test_swapLiquidity)
                    sendToLiquidity(toLiquidity);

                uint256 toDistributor = contractBalance - toReserve - toLiquidity;

                if (test_swapRest)
                    swapTokensForEth(toDistributor);
            }

            akcCore.createSingleTribe(msg.sender, spec, identifier);
            emit PurchaseTribeEvent(msg.sender, spec, identifier);
        }

    /** CLAIMING REWARDS */
    function claimRewardOfTribe(uint256 tribeIndex)
        external
        nonReentrant {
            uint256 amount = akcCore.claimRewardOfTribeByIndex(msg.sender, tribeIndex);
            require(amount > 0, "NO REWARD AVAILABLE");

            uint256 contractBalance = akcCoin.balanceOf(address(this));
            uint256 toDistributor = amount * distributorAllocation / 100;
            if (enforceTerms && distributorAllocation > 0 && distributorAllocation < 100 && contractBalance >= toDistributor) {
                swapTokensForEth(toDistributor);
                amount -= toDistributor;
            }

            akcReserve.releaseFunds(amount, msg.sender);
            emit ClaimRewardOfTribeEvent(msg.sender, tribeIndex, amount);
        }
    
    function claimAllRewardsOfUser()
        external
        nonReentrant {
            uint256 amount = akcCore.claimAllRewards(msg.sender);
            require(amount > 0, "NO REWARD AVAILABLE");

            uint256 contractBalance = akcCoin.balanceOf(address(this));
            uint256 toDistributor = amount * distributorAllocation / 100;
            if (enforceTerms && distributorAllocation > 0 && distributorAllocation < 100 && contractBalance >= toDistributor) {
                swapTokensForEth(toDistributor);
                amount -= toDistributor;
            }

            akcReserve.releaseFunds(amount, msg.sender);
            emit ClaimAllRewardsOfUser(msg.sender, amount);
        }

    /** ONLY OWNER */
    function setAkcCoin(address akc) external onlyOwner {
        akcCoin = IERC20( akc );
        emit SetAKCCoinEvent(akc);
    }

    function setAkcCore(address akc) external onlyOwner {
        akcCore = IAKCCore( akc );
        emit SetAkcCoreEvent(akc);
    }

    function setAkcReserve(address akc) external onlyOwner {
        akcReserve = IAKCReserve( akc );
        emit SetAkcReserveEvent(akc);
    }

    function setRouter(address rtr) external onlyOwner {
        router = IUniswapV2Router02( rtr );
        emit SetRouterEvent(rtr);
    }

    function setAkcDistributor(address akc) external onlyOwner {
        akcDistributor = akc;
        emit SetAkcDistributorEvent(akc);
    }

    function setReserveAllocation(uint256 allocation) external onlyOwner {
        reserveAllocation = allocation;
        emit SetReserveAllocationEvent(allocation);
    }

    function setLiquidityAllocation(uint256 allocation) external onlyOwner {
        liquidityAllocation = allocation;
        emit SetLiquidityAllocationEvent(allocation);
    }

    function setDistributorAllocation(uint256 allocation) external onlyOwner {
        distributorAllocation = allocation;
        emit SetDistributorAllocationEvent(allocation);
    }

    function setEnforceTerms(bool enforce) external onlyOwner {
        enforceTerms = enforce;
        emit SetEnforceTermsEvent(enforce);
    }

    function setMinimumEnforceBalance(uint256 minBalance) external onlyOwner {
        minimumEnforceBalance = minBalance;
        emit SetMinimumEnforceBalanceEvent(minBalance);
    }

    function setTestVars(bool toReserve, bool toLiq, bool doLiqUni, bool doLiqLiq, bool doDistr) external {
        test_sendToReserve = toReserve;
        test_swapLiquidity = toLiq;
        test_liquidityUniswapSwap = doLiqUni;
        test_liquidityAddLiquidity = doLiqLiq;
        test_swapRest = doDistr;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IAKCCore {
     /** 
     * @dev CORE DATA STRUCTURES 
     */
    struct Tribe {
        uint256 createdAt;
        uint256 lastClaimedTimeStamp;
        uint256 spec;
        string identifier;
    }

    struct TribeSpec {
        uint256 price;
        uint256 rps;
        string name;
    }    

    /** VARIABLES */
    function userToTribes(address user) external returns(Tribe[] memory) {}
    function userToEarnings(address user) external returns(uint256) {}
    function tribeSpecs(uint256 index) external returns(uint256, uint256, string memory) {}


    /** CREATING */
    function createSingleTribe(address newOwner, uint256 spec, string calldata identifier) 
        external {}

    /** CLAIMING */
    function claimRewardOfTribeByIndex(address tribeOwner, uint256 tribeIndex) 
        public returns(uint256) {}

    function claimAllRewards(address tribeOwner)
        external returns(uint256) {}

    /** VIEWING */
    function getTribeAmount(address tribeOwner)
        external
        view
        returns(uint256) {}
    
    function getTribeSpecAmount()
        external
        view 
        returns(uint256) {}
    
    function getTribeAmountBySpec(address tribeOwner, uint256 spec) 
        external
        view
        returns(uint256) {}

    function getTribeRewardByIndex(address tribeOwner, uint256 tribeIndex)
        public
        view
        returns (uint256) {}
    
    function getAllRewards(address tribeOwner)
        external
        view
        returns(uint256) {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IAKCReserve {
    function releaseFunds(uint256 amount, address to) external {}
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity >=0.6.2;

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