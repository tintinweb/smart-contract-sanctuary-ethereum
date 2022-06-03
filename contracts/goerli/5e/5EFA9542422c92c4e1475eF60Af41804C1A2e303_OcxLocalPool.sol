// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // openzeppelin 4.5 (for solidity 0.8.x)
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./OcxAdmin.sol";
import "./interface/IOcxERC20.sol";
import "./common/OcxCommon.sol";

contract OcxLocalPool is OcxAdmin {
    struct Pool {
        address[2] tokenPair;
        mapping(address => uint256) amounts;
        uint256 k;
        uint256 prevK;
        address[2] quoteOrder;
        uint256 prevQuote;
        uint256 quoteOrig;
        uint256 quote;
    }

    // struct PoolShare {
    //     uint8 poolIndex;
    //     uint256[2] amounts;
    // }

    mapping(uint256 => Pool) public poolList;
    uint256 public poolCount;

    // mapping(address => PoolShare[]) public poolShare;

    receive() external payable {}

    constructor() {}

    function _getPoolIndex(address[2] memory tokenPair)
        internal
        view
        returns (
            bool bFound,
            uint8 poolIndex,
            bool isInTurn
        )
    {
        bFound = false;
        poolIndex = 0;
        isInTurn = true;
        for (uint8 i = 0; i < poolCount; i++) {
            if (
                (poolList[i].tokenPair[0] == tokenPair[0] &&
                    poolList[i].tokenPair[1] == tokenPair[1]) ||
                (poolList[i].tokenPair[1] == tokenPair[0] &&
                    poolList[i].tokenPair[0] == tokenPair[1])
            ) {
                bFound = true;
                poolIndex = i;
                if (poolList[i].tokenPair[1] == tokenPair[0]) {
                    isInTurn = false;
                }
                break;
            }
        }
    }

    function _updateK(uint256 poolIndex) internal {
        address[2] memory tkAddress = poolList[poolIndex].tokenPair;
        poolList[poolIndex].k =
            (poolList[poolIndex].amounts[tkAddress[0]] /
                (10**(IOcxERC20(tkAddress[0]).decimals()))) *
            (poolList[poolIndex].amounts[tkAddress[1]] /
                (10**(IOcxERC20(tkAddress[1]).decimals())));
    }

    /*
     * Error:
     *      -1: OcxLocalPool.swap(): Invalid ETH amount
     *      -2: OcxLocalPool.swap(): No pool for ETH-OCAT
     *      -3: OcxLocalPool.swap(): No balance for OCAT in the pool
     *      -4: OcxLocalPool.swap(): Insufficient balance for output of path[1]
     *      -5: OcxLocalPool.swap(): Insufficient allowance for path[0]
     */
    function swap(
        address[2] memory path,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256
    ) public payable onlyValidAddress(path[0]) onlyValidAddress(path[1]) {
        require(amountIn > 0, "-1");
        // Find the ETH/OCAT pool
        (bool bFound, uint8 poolIndex, ) = _getPoolIndex(path);
        // Check if the pool exists
        require(bFound, "-2");
        // Get ETH balance in the pool
        // Ensure that OCAT balance is more than 0
        require(amountOutMin >= 0, "-3");
        // Ensure that OCAT balance >= amountOutMin
        uint256 amountOut = getAmountOutWithExactAmountIn(path, amountIn);
        require(amountOut >= amountOutMin, "-4");

        // Transfer ETH from the sender
        // First check allowance of ETH amount from the sender
        uint256 allowance = IERC20(path[0]).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= amountIn, "-5");
        // Transfer ETH from the sender
        TransferHelper.safeTransferFrom(
            path[0],
            msg.sender,
            address(this),
            amountIn
        );
        // // Transfer OCAT to the sender
        IERC20(path[1]).transfer(msg.sender, amountOut);

        // Update the quote for the pool
        poolList[poolIndex].amounts[path[0]] += amountIn;
        poolList[poolIndex].amounts[path[1]] -= amountOut;
        poolList[poolIndex].prevQuote = poolList[poolIndex].quote;
        poolList[poolIndex].quote =
            (poolList[poolIndex].amounts[poolList[poolIndex].quoteOrder[0]] *
                (10**QUOTE_DECIMALS)) /
            poolList[poolIndex].amounts[poolList[poolIndex].quoteOrder[1]];
        // Update the K for the pool
        _updateK(poolIndex);
    }

    function getQuote(address[2] memory path)
        public
        view
        returns (uint256 value, uint256 decimals)
    {
        (bool bExist, uint8 poolIndex, bool isInTurn) = _getPoolIndex(path);
        require(bExist, "Not exist such a token pair");
        value = poolList[poolIndex].quote;
        if (!isInTurn) {
            value = (QUOTE_MULTIPLIER**2) / poolList[poolIndex].quote;
        }
        decimals = QUOTE_DECIMALS;
    }

    function getAmountOutWithExactAmountIn(
        address[2] memory path,
        uint256 amountIn
    ) public view returns (uint256 amountOut) {
        require(amountIn > 0, "amountIn must be larger than 0");
        (bool bExist, uint8 poolIndex, bool isInTurn) = _getPoolIndex(path);
        require(bExist, "Not exist such a token pair");
        uint256 newToken0Balance = poolList[poolIndex].amounts[path[0]] +
            amountIn;
        amountOut =
            (poolList[poolIndex].amounts[path[1]] * amountIn) /
            newToken0Balance;
    }

    function getAmountInWithExactAmountOut(
        address[2] memory path,
        uint256 amountOut
    ) public view returns (uint256 amountIn) {
        require(amountOut > 0, "amountOut must be larger than 0");
        (bool bExist, uint8 poolIndex, bool isInTurn) = _getPoolIndex(path);
        require(bExist, "Not exist such a token pair");
        uint256 newToken1Balance = poolList[poolIndex].amounts[path[1]] +
            amountOut;
        amountIn =
            (poolList[poolIndex].amounts[path[0]] * amountOut) /
            newToken1Balance;
    }

    /*
     * Error:
     *      -1: OcxLocalPool.addLiquidity(): Same tokenPair
     *      -2: OcxLocalPool.addLiquidity(): Invalid amount for first token
     *      -3: OcxLocalPool.addLiquidity(): Invalid amount for second token
     *      -4: OcxLocalPool.addLiquidity(): Invalid quote
     *      -5: OcxLocalPool.swap(): Insufficient allowance for first token
     *      -6: OcxLocalPool.swap(): Insufficient allowance for second token
     */
    function addLiquidity(
        address[2] memory tokenPair,
        uint256[2] memory amounts
    )
        public
        onlyCreator
        onlyValidAddress(tokenPair[0])
        onlyValidAddress(tokenPair[1])
    {
        require(tokenPair[0] != tokenPair[1], "-1");
        require(amounts[0] > 0, "-2");
        require(amounts[1] > 0, "-3");

        (bool bExist, uint8 poolIndex, bool isInTurn) = _getPoolIndex(
            tokenPair
        );
        if (!bExist) {
            address[2] memory quoteOrder = tokenPair;
            if (amounts[0] < amounts[1]) {
                quoteOrder = [tokenPair[1], tokenPair[0]];
            }
            poolList[poolCount].tokenPair = tokenPair;
            poolList[poolCount].amounts[tokenPair[0]] = amounts[0];
            poolList[poolCount].amounts[tokenPair[1]] = amounts[1];
            _updateK(poolCount);
            poolList[poolCount].prevK = 0;
            poolList[poolCount].quoteOrder = quoteOrder;
            poolList[poolCount].quoteOrig = uint256(
                (poolList[poolCount].amounts[quoteOrder[0]] *
                    QUOTE_MULTIPLIER) /
                    poolList[poolCount].amounts[quoteOrder[1]]
            );
            poolList[poolCount].quote = poolList[poolCount].quoteOrig;
            poolList[poolCount].prevQuote = 0;
            poolCount += 1;
        } else {
            // If order for token in parameter in against pool is revered, swap
            if (!isInTurn) {
                address tmpToken = tokenPair[0];
                tokenPair[0] = tokenPair[1];
                tokenPair[1] = tmpToken;
                uint256 tmpAmount = amounts[0];
                amounts[0] = amounts[1];
                amounts[1] = tmpAmount;
            }
            // Check quote
            uint256 quote = uint256(
                (poolList[poolIndex].amounts[
                    poolList[poolIndex].quoteOrder[0]
                ] * QUOTE_MULTIPLIER) /
                    poolList[poolIndex].amounts[
                        poolList[poolIndex].quoteOrder[1]
                    ]
            );
            uint256 quoteRate = uint256(
                (quote * QUOTE_MULTIPLIER) / poolList[poolIndex].quoteOrig
            );
            // Check if new quote >= 98% and <= 102%
            require(
                quoteRate > 980 * (10**(QUOTE_DECIMALS)) &&
                    quoteRate < 1020 * (10**(QUOTE_DECIMALS)),
                "-4"
            );
            // Update pool
            poolList[poolIndex].amounts[tokenPair[0]] += amounts[0];
            poolList[poolIndex].amounts[tokenPair[1]] += amounts[1];
            poolList[poolIndex].prevK = poolList[poolIndex].k;
            _updateK(poolIndex);
            poolList[poolIndex].prevQuote = poolList[poolIndex].quote;
            poolList[poolIndex].quote = uint256(
                (poolList[poolIndex].amounts[
                    poolList[poolIndex].quoteOrder[0]
                ] * QUOTE_MULTIPLIER) /
                    poolList[poolIndex].amounts[
                        poolList[poolIndex].quoteOrder[1]
                    ]
            );
        }
        // Receive path[0] as amount
        uint256 allowance = IERC20(tokenPair[0]).allowance(
            msg.sender,
            address(this)
        );
        require(allowance >= amounts[0], "-5");
        // Transfer path[0] from the sender
        TransferHelper.safeTransferFrom(
            tokenPair[0],
            msg.sender,
            address(this),
            amounts[0]
        );
        // Receive path[1] as amount
        allowance = IERC20(tokenPair[1]).allowance(msg.sender, address(this));
        require(allowance >= amounts[1], "-6");
        // Transfer path[1] from the sender
        TransferHelper.safeTransferFrom(
            tokenPair[1],
            msg.sender,
            address(this),
            amounts[1]
        );
        // // Update pool share
        // bExist = false;
        // for (uint i = 0; i < poolShare[msg.sender].length; i++) {
        //     if (poolIndex == poolShare[msg.sender][i].poolIndex) {
        //         poolShare[msg.sender][i].amounts[0] += amounts[0];
        //         poolShare[msg.sender][i].amounts[1] += amounts[1];
        //         bExist = true;
        //         break;
        //     }
        // }
        // if (!bExist) {
        //     poolShare[msg.sender].push(PoolShare(poolIndex, amounts));
        // }

        // Mint LP token to return
        // ...
        // Transfer ETH and OCAT amounts from the sender
        // ...
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OcxAdmin {
    mapping(address => bool) internal adminGroup;
    uint8                    internal adminCount;
    address payable          internal creator;

    constructor() {
        creator = payable(msg.sender);
        addAdmin(msg.sender);
	}

    modifier onlyCreator virtual {
        require(creator != address(0), "Invalid creator address");
        require(msg.sender == creator, "For caller expected be creator");
        _;
    }
    modifier onlyValidAddress(address _address) virtual {
        require(_address != address(0), "Expected non-zero address");
        _;
    }
    modifier onlyAdmin virtual {
        require(msg.sender != address(0), "Invalid creator address");
        require(adminGroup[msg.sender], "Must be admin");
        _;
    }

    function addAdmin(address _admin) public virtual
    onlyCreator onlyValidAddress(_admin) {
        adminGroup[_admin] = true;
        adminCount = adminCount + 1;
    }

    function isAdmin(address _address) public view virtual 
    returns(bool yes) {
        yes = adminGroup[_address];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IOcxERC20 {
    function decimals() external view returns (uint8);
    function mint(uint256 amount) external payable;
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum FeeType {
    PNFT_MINT_FEE,
    PNFT_OCAT_SWAP_FEE,
    OCAT_PNFT_SWAP_FEE,
    FEE_TYPE_SIZE
}

enum CommonContracts {
    WETH,               // 0
    OCAT,               // 1
    OCX,                // 2
    PNFT,               // 3
    UNI,                // 4
    DAI,                // 5
    PRICE_ORACLE,       // 6
    EXCHANGE,           // 7
    BALANCER,           // 8
    CONRACT_COUNT       // 9
}

enum CurrencyIndex {
    ETH,                // 0
    OCAT,               // 1
    OCX,                // 2
    USD,                // 3
    AUD,                // 4
    UNI,                // 5
    DAI,                // 6
    CURRENCY_COUNT      // 7
}

struct OcxPrice {
    uint256     value;
    uint8       decimals;
}

struct CurrencyPriceInfo {
    mapping(string => OcxPrice)  vs;
}

// v2
// address constant UNISWAP_V3_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
// v3
address constant UNISWAP_V3_ROUTER_ADDRESS = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
address constant UNISWAP_V3_QUOTER_ADDRESS = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;

uint24  constant POOL_FEE = 3000;
uint8   constant QUOTE_DECIMALS = 6; // Must be more than 3 at least
uint256 constant QUOTE_MULTIPLIER = 10 ** QUOTE_DECIMALS;