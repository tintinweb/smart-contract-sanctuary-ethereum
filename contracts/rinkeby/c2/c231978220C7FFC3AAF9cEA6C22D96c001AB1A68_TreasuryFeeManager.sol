//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./utils/IBabyDogeV2Pair.sol";
import "./utils/IBabyDogeV2Router02.sol";

contract TreasuryFeeManager is AccessControl {
    event PairFailure(address pair, bytes err);
    event RemoveLiquidityFailure(bytes);
    event SwapFailure(bytes err, address[] path);

    event TransferredToTreasury(uint256);
    event NewLpBatchNumber(uint256);

    event NewLP(
        address LPTokenAddress,
        address[] LPTokenPath1,
        address[] LPTokenPath2
    );

    event ReplacedLP(
        address LPTokenAddress,
        address[] LPTokenPath1,
        address[] LPTokenPath2
    );

    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 internal constant OWNER_ROLE = keccak256("OWNER_ROLE");

    address public router;
    address public WETH;
    address public stableCoin;
    address public treasuryAddress;
    uint256 public lpBatchNumber = 100;
    uint256 public lpUnwrapStartingIndex;

    bool public instantSwapToStable = true;

    // LP => TokenA <- True / TokenB <- False => Path to WETH
    mapping(address => mapping(bool => address[])) public lpTokenUnwrapPath;
    address[] public lpTokenToUnwrap;

    /*
     * Params
     * address _WETH - WETH/WBNB address
     * address _router - Uniswap/Pancakeswap router address
     * address _stableCoin - Address of stablecoin to which will be swapped part of WETH/WBNB
     * address _treasuryAddress - Address of treasury, which will receive stablecoins
     * uint256 _toTreasuryPercent - Share of WETH/WBNB that will be converted to stablecoins
     * in basis points (75% == 7500)
     */
    constructor(
        address _WETH,
        address _router,
        address _stableCoin,
        address _treasuryAddress
    ) {
        WETH = _WETH;
        router = _router;
        stableCoin = _stableCoin;
        treasuryAddress = _treasuryAddress;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MANAGER_ROLE, _msgSender());
        _setupRole(OWNER_ROLE, _msgSender());
    }

    //allows contract to receive ETH
    receive() external payable {}

    /*
     * Params
     * address _lpAddress - Address of lp token contract
     * address[] calldata _pathTokenA - Path for swapping tokenA to WETH/WBNB
     * address[] calldata _pathTokenB - Path for swapping tokenB to WETH/WBNB
     *
     * Function checks paths and adds them to internal storage
     */
    function addLP(
        address _lpAddress,
        address[] calldata _pathTokenA,
        address[] calldata _pathTokenB
    ) external onlyRole(MANAGER_ROLE) {
        require(
            lpTokenUnwrapPath[_lpAddress][true].length == 0 &&
                lpTokenUnwrapPath[_lpAddress][false].length == 0,
            "LP already added"
        );
        lpTokenToUnwrap.push(_lpAddress);
        if (_pathTokenA.length > 0) {
            lpTokenUnwrapPath[_lpAddress][true] = _pathTokenA;
        }
        if (_pathTokenB.length > 0) {
            lpTokenUnwrapPath[_lpAddress][false] = _pathTokenB;
        }

        emit NewLP(_lpAddress, _pathTokenA, _pathTokenB);
    }

    /*
     * Params
     * address _treasuryAddress - Address of treasury
     *
     * Function updates treasury address
     */
    function setTreasuryAddress(address _treasuryAddress)
        external
        onlyRole(OWNER_ROLE)
    {
        require(_treasuryAddress != address(0), "Cant set 0 address");
        treasuryAddress = _treasuryAddress;
    }

    /*
     * Params
     * uint256 _lpTokenIndex - Array index of the token you want to replace
     * address _lpAddress - Address of lp token contract
     * address[] calldata _pathTokenA - Path for swapping tokenA to WETH/WBNB
     * address[] calldata _pathTokenB - Path for swapping tokenB to WETH/WBNB
     *
     * Function checks paths and replaces lp token info in internal storage
     */
    function replaceLP(
        uint256 _lpTokenIndex,
        address _lpAddress,
        address[] calldata _pathTokenA,
        address[] calldata _pathTokenB
    ) external onlyRole(MANAGER_ROLE) {
        require(
            lpTokenUnwrapPath[_lpAddress][true].length != 0 ||
                lpTokenUnwrapPath[_lpAddress][false].length != 0,
            "LP is not added"
        );

        address oldLpTokenAddress = lpTokenToUnwrap[_lpTokenIndex];
        if (oldLpTokenAddress != _lpAddress) {
            delete lpTokenUnwrapPath[oldLpTokenAddress][true];
            delete lpTokenUnwrapPath[oldLpTokenAddress][false];
        }

        lpTokenToUnwrap[_lpTokenIndex] = _lpAddress;
        if (_pathTokenA.length > 0) {
            lpTokenUnwrapPath[_lpAddress][true] = _pathTokenA;
        }
        if (_pathTokenB.length > 0) {
            lpTokenUnwrapPath[_lpAddress][false] = _pathTokenB;
        }

        emit ReplacedLP(_lpAddress, _pathTokenA, _pathTokenB);
    }

    /*
     * Params
     * uint256 _lpBatchNumber - Maximum number of LP tokens
     *** allowed during single unwrapTokens function execution
     *
     * Function sets different lpBatchNumber
     */
    function setLpBatchNumber(uint256 _lpBatchNumber)
        external
        onlyRole(OWNER_ROLE)
    {
        require(
            _lpBatchNumber > 0 && _lpBatchNumber != lpBatchNumber,
            "Invalid value"
        );
        lpBatchNumber = _lpBatchNumber;

        emit NewLpBatchNumber(_lpBatchNumber);
    }

    /*
     * Function unwraps LP tokens in batches of 100 (lpBatchNumber).
     * Function removes liquidity in exchange for lp tokens and swaps both tokens for WETH/WBNB
     */
    function unwrapTokens() external onlyRole(MANAGER_ROLE) {
        //gas saving
        address[] memory _lpTokenToUnwrap = lpTokenToUnwrap;
        uint256 _startingIndex = lpUnwrapStartingIndex;
        uint256 _endingIndex = _startingIndex + lpBatchNumber;
        if (_endingIndex >= _lpTokenToUnwrap.length) {
            _endingIndex = _lpTokenToUnwrap.length;
            lpUnwrapStartingIndex = 0;
        } else {
            lpUnwrapStartingIndex = _endingIndex;
        }

        require(msg.sender == tx.origin, "Only Wallet");
        for (
            uint256 current = _startingIndex;
            current < _endingIndex;
            current++
        ) {
            uint256 liquidity = IBabyDogeV2Pair(_lpTokenToUnwrap[current])
                .balanceOf(address(this));
            if (liquidity > 0) {
                // LP token is Stable coin of choice or WETH unwrap and swap
                address tokenA;
                try
                    IBabyDogeV2Pair(_lpTokenToUnwrap[current]).token0()
                returns (address _token) {
                    tokenA = _token;
                } catch (bytes memory _err) {
                    emit PairFailure(_lpTokenToUnwrap[current], _err);
                }

                address tokenB;
                try
                    IBabyDogeV2Pair(_lpTokenToUnwrap[current]).token1()
                returns (address _token) {
                    tokenB = _token;
                } catch (bytes memory _err) {
                    emit PairFailure(_lpTokenToUnwrap[current], _err);
                }

                if (tokenA == address(0) || tokenB == address(0)) {
                    continue;
                }

                IBabyDogeV2Pair(_lpTokenToUnwrap[current]).approve(
                    router,
                    liquidity
                );
                try
                    IBabyDogeV2Router02(router).removeLiquidity(
                        tokenA,
                        tokenB,
                        liquidity,
                        0,
                        0,
                        address(this),
                        block.timestamp + 120
                    )
                {} catch (bytes memory _err) {
                    emit RemoveLiquidityFailure(_err);
                }

                if (
                    lpTokenUnwrapPath[_lpTokenToUnwrap[current]][true].length >
                    0
                ) {
                    swapTokens(
                        lpTokenUnwrapPath[_lpTokenToUnwrap[current]][true]
                    );
                }
                if (
                    lpTokenUnwrapPath[_lpTokenToUnwrap[current]][false].length >
                    0
                ) {
                    swapTokens(
                        lpTokenUnwrapPath[_lpTokenToUnwrap[current]][false]
                    );
                }
            }
        }

        if (instantSwapToStable == true) {
            swapToStable();
        }
    }

    /*
     * Params
     * address[] storage path - Path for swapping token to WETH/WBNB
     *
     * Function swaps full balance of token to WETH/WBNB
     * The first element of path is the input token, the last is the output token,
     * and any intermediate elements represent intermediate pairs to trade
     */
    function swapTokens(address[] storage path) internal {
        uint256 amountIn = IERC20(path[0]).balanceOf(address(this));
        IERC20(path[0]).approve(router, amountIn);

        try IBabyDogeV2Router02(router).getAmountsOut(amountIn, path) returns (
            uint256[] memory amounts
        ) {
            address to = address(this);
            uint256 deadline = block.timestamp + 120; //2 minutes to complete transaction
            try
                IBabyDogeV2Router02(router)
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        amountIn,
                        amounts[path.length - 1],
                        path,
                        to,
                        deadline
                    )
            {} catch (bytes memory _err) {
                emit SwapFailure(_err, path);
            }
        } catch (bytes memory _err) {
            emit SwapFailure(_err, path);
        }
    }

    /*
     * Function swaps correct percent of WETH/WBNB balance
     * to stablecoins and sends them to treasury
     */
    function swapToStable() internal {
        // Swap a portion and send to treasury
        uint256 amountToStable = IERC20(WETH).balanceOf(address(this));
        //swap to stable
        IERC20(WETH).approve(router, amountToStable);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = stableCoin;

        uint256[] memory amountOutMin = IBabyDogeV2Router02(router)
            .getAmountsOut(amountToStable, path);
        try
            IBabyDogeV2Router02(router).swapExactTokensForTokens(
                amountToStable,
                amountOutMin[1],
                path,
                treasuryAddress,
                block.timestamp + 1200
            )
        returns (uint256[] memory amounts) {
            emit TransferredToTreasury(amounts[1]);
        } catch (bytes memory _err) {
            emit SwapFailure(_err, path);
        }
    }

    /*
     * Params
     * address payable _address - Address that will receive WETH/WBNB
     * uint256 amount - Amount of WETH/WBNB to receive
     *
     * Function withdraws any WETH/WBNB to specific address
     */
    function withdrawETH(address payable _address, uint256 amount)
        external
        onlyRole(OWNER_ROLE)
    {
        require(address(this).balance >= amount, "Not enough ETH");
        _address.transfer(amount);
    }

    /*
     * Params
     * address _address - Address that will receive ERC20
     * address tokenAddress - Address of ERC20 token contract
     * uint256 amount - Amount of ERC20 to receive
     *
     * Function withdraws any ERC20 tokens to specific address
     * Can't withdraw active LP tokens
     */
    function withdrawERC20(
        address _address,
        address tokenAddress,
        uint256 amount
    ) external onlyRole(OWNER_ROLE) {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= amount,
            "Not enough ERC20"
        );

        require(
            lpTokenUnwrapPath[tokenAddress][true].length == 0 &&
                lpTokenUnwrapPath[tokenAddress][false].length == 0,
            "Can't withdraw LP tokens"
        );

        IERC20(tokenAddress).transfer(_address, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IBabyDogeV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later
import "./IBabyDogeV2Router01.sol";
pragma solidity ^0.8.0;

interface IBabyDogeV2Router02 is IBabyDogeV2Router01 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IBabyDogeV2Router01 {
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
}