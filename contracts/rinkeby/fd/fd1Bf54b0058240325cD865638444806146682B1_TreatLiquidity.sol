// Contract that saves your lock and you can add or remove lp
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/IBabyDogeRouter.sol";
import "./utils/IBabyDogeFactory.sol";
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TreatLiquidity is Ownable {
    event LiquidityAdded(address account, address tokenB, uint256 liquidity);
    event LiquidityRemoved(address account, address tokenB, uint256 liquidity);

    address public treatToken;
    address public router;

    /*
     * @param TreatToken address
     * @param Router address
     */
    constructor(address _token, address _router) {
        treatToken = _token;
        router = _router;
    }

    //user => tokenB => LP tokens deposited
    mapping(address => mapping(address => uint256)) public liquidityDeposits;
    mapping(address => mapping(address => address)) private depositedPairTokens;
    mapping(address => uint256) public withdrawnPercent;

    // Receive ETH
    receive() external payable {}

    /*
     * @title Adds TreatToken<>Token liquidity
     * @param TokenB address
     * @param Desired amount of TreatToken to add to liquidity
     * @param Desired amount of TokenB to add to liquidity
     * @param Minimum amount of TreatToken to add to liquidity
     * @param Minimum amount of TokenB to add to liquidity
     * @param Deadline
     * @return Amount of TreatToken, that was added to liquidity
     * @return Amount of TokenB, that was added to liquidity
     * @return Amount of liquidity received
     */
    function addLiquidity(
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        IERC20(treatToken).transferFrom(
            msg.sender,
            address(this),
            amountADesired
        );
        IERC20(tokenB).transferFrom(
            msg.sender,
            address(this),
            amountBDesired
        );
        IERC20(treatToken).approve(router, amountADesired);
        IERC20(tokenB).approve(router, amountBDesired);

        (amountA, amountB, liquidity) = IBabyDogeRouter(router)
            .addLiquidity(
                treatToken,
                tokenB,
                amountADesired,
                amountBDesired,
                amountAMin,
                amountBMin,
                msg.sender,
                deadline
            );

        _addToken(msg.sender, tokenB);
        liquidityDeposits[msg.sender][tokenB] += liquidity;
        emit LiquidityAdded(msg.sender, tokenB, liquidity);
    }

    /*
     * @title Adds TreatToken<>ETH liquidity
     * @param Desired amount of TreatToken to add to liquidity
     * @param Minimum amount of TreatToken to add to liquidity
     * @param Minimum amount of ETH to add to liquidity
     * @param Deadline
     * @return Amount of TreatToken, that was added to liquidity
     * @return Amount of ETH, that was added to liquidity
     * @return Amount of liquidity received
     */
    function addLiquidityETH(
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        )
    {
        IERC20(treatToken).transferFrom(
            msg.sender,
            address(this),
            amountTokenDesired
        );
        IERC20(treatToken).approve(router, amountTokenDesired);
        (amountToken, amountETH, liquidity) = IBabyDogeRouter(router)
            .addLiquidityETH{value: msg.value}(
            treatToken,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            msg.sender,
            deadline
        );
        address WETH = IBabyDogeRouter(router).WETH();
        _addToken(msg.sender, WETH);

        liquidityDeposits[msg.sender][WETH] += liquidity;
        emit LiquidityAdded(msg.sender, WETH, liquidity);
    }

    /*
     * @title Removes TreatToken<>Token liquidity
     * @param TokenB address
     * @param Liquidity amount
     * @param Minimum amount of TreatToken to receive
     * @param Minimum amount of TokenB to receive
     * @param Deadline
     * @return Amount of TreatToken, that was received
     * @return Amount of TokenB, that was received
     */
    function removeLiquidity(
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(
            liquidityDeposits[msg.sender][tokenB] >= liquidity,
            "Can only withdraw your liquidity"
        );
        withdrawnPercent[msg.sender] = _getPercent(msg.sender, tokenB, liquidity);
        liquidityDeposits[msg.sender][tokenB] -= liquidity;
        address pair = IBabyDogeFactory(IBabyDogeRouter(router).factory())
            .getPair(treatToken, tokenB);
        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).approve(router, liquidity);
        (amountA, amountB) = IBabyDogeRouter(router).removeLiquidity(
            treatToken,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );
        IERC20(treatToken).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);
        withdrawnPercent[msg.sender] = 0;
        emit LiquidityAdded(msg.sender, tokenB, liquidity);
    }

    /*
     * @title Removes TreatToken<>ETH liquidity
     * @param Liquidity amount
     * @param Minimum amount of TreatToken to receive
     * @param Minimum amount of ETH to receive
     * @param Deadline
     * @return Amount of TreatToken, that was received
     * @return Amount of ETH, that was received
     */
    function removeLiquidityETH(
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH) {
        address WETH = IBabyDogeRouter(router).WETH();
        require(
            liquidityDeposits[msg.sender][WETH] >= liquidity,
            "Can only withdraw your liquidity"
        );
        withdrawnPercent[msg.sender] = _getPercent(msg.sender, WETH, liquidity);
        liquidityDeposits[msg.sender][WETH] -= liquidity;

        address pair = IBabyDogeFactory(IBabyDogeRouter(router).factory())
            .getPair(treatToken, WETH);
        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).approve(router, liquidity);
        (amountToken, amountETH) = IBabyDogeRouter(router)
            .removeLiquidityETH(
                treatToken,
                liquidity,
                amountTokenMin,
                amountETHMin,
                address(this),
                deadline
            );
        payable(msg.sender).transfer(amountETH);
        IERC20(treatToken).transfer(msg.sender, amountToken);
        withdrawnPercent[msg.sender] = 0;
        emit LiquidityAdded(msg.sender, WETH, liquidity);
    }

    /*
     * @title Adds token to the linked list of tokens, which were added by liquidity by the user
     * @param User address
     * @param Token address
     */
    function _addToken(address account, address token) private {
        if(depositedPairTokens[account][token] == address(0)) {
            if(depositedPairTokens[account][address(0x1)] == address(0)) {
                depositedPairTokens[account][address(0x1)] = token;
                depositedPairTokens[account][token] = address(0x1);
            } else {
                depositedPairTokens[account][token]
                    = depositedPairTokens[account][address(0x1)];
                depositedPairTokens[account][address(0x1)] = token;
            }
        }
    }

    /*
     * @title Calculates TreatToken percent, that is being withdrawn
     * @param User account address
     * @param TokenB address
     * @param Liquidity amount being withdrawn
     * @return TreatToken percent, that is being withdrawn
     */
    function _getPercent(
        address account,
        address tokenB,
        uint256 liquidity
    ) private view returns(uint256){
        uint256 withdrawnTreatTokens;
        uint256 ownedTreatTokens;

        address factory = IBabyDogeRouter(router).factory();

        address token = depositedPairTokens[msg.sender][address(0x1)];
        while(token != address(0x1)) {
            if(liquidityDeposits[account][token] > 0) {
                address pair = IBabyDogeFactory(factory)
                    .getPair(treatToken, token);
                uint256 ownedInPool = IERC20(treatToken).balanceOf(pair)
                    * IERC20(pair).balanceOf(account) / IERC20(pair).totalSupply();
                ownedTreatTokens += ownedInPool;
                if(tokenB == token) {
                    withdrawnTreatTokens = ownedInPool
                        * liquidity / IERC20(pair).balanceOf(account);
                }
            }
            token = depositedPairTokens[msg.sender][token];
        }

        return withdrawnTreatTokens * 10000 / ownedTreatTokens;
    }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IBabyDogeRouter  {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IBabyDogeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

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