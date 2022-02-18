// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IWrappedEther.sol";
import "./interfaces/IExchangeAdapter.sol";

contract Exchange is ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    using Address for address;

    // struct size - 64 bytes, 2 slots
    struct RouteEdge {
        uint32 swapProtocol; // 0 - unknown edge, 1 - UniswapV2, 2 - Curve...
        address pool; // address of pool to call
        address fromCoin; // address of coin to deposit to pool
        address toCoin; // address of coin to get from pool
    }

    // struct size - 32 bytes, 1 slots
    struct LpToken {
        uint32 swapProtocol; // 0 - unknown edge, 1 - UniswapV2, 2 - Curve...
        address pool; // address of pool to call
    }

    // returns true if address is registered as major token, false otherwise
    mapping(address => bool) public isMajorCoin;

    // returns true if pool received approve of token. First address is pool,
    // second is token
    mapping(address => mapping(address => bool)) public approveCompleted;

    // Storage of routes between major coins. Normally, any major coin should
    // have route to any other major coin that is saved here
    mapping(address => mapping(address => RouteEdge[]))
        private internalMajorRoute;

    // Storage of single edges from minor coin to major
    mapping(address => RouteEdge) public minorCoins;

    // Storage of LP tokens that are registeres in exchange
    mapping(address => LpToken) public lpTokens;

    // Storage of swap execution method for different protocols
    mapping(uint32 => address) public adapters;

    // Wrapped ether token that is used for native ether swaps
    IWrappedEther public wrappedEther =
        IWrappedEther(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // bytes4(keccak256(bytes("executeSwap(address,address,address,uint256)")))
    bytes4 public constant executeSwapSigHash = 0x6012856e;

    // bytes4(keccak256(bytes("enterPool(address,address,uint256)")))
    bytes4 public constant enterPoolSigHash = 0x73ec962e;

    // bytes4(keccak256(bytes("exitPool(address,address,uint256)")))
    bytes4 public constant exitPoolSigHash = 0x660cb8d4;

    constructor(address gnosis, bool isTesting) {
        require(gnosis.isContract(), "Exchange: not contract");
        _grantRole(DEFAULT_ADMIN_ROLE, gnosis);
        if (isTesting) _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Execute exchange of coins through predefined routes
    /// @param from swap input token
    /// @param to swap output token
    /// @param amountIn amount of `from `tokens to be taken from caller
    /// @param minAmountOut minimum amount of output tokens, revert if less
    /// @return Amount of tokens that are returned
    function exchange(
        address from,
        address to,
        uint256 amountIn,
        uint256 minAmountOut
    ) external payable nonReentrant returns (uint256) {
        require(from != to, "Exchange: from == to");

        if (lpTokens[to].swapProtocol != 0) {
            IERC20(from).safeTransferFrom(msg.sender, address(this), amountIn);

            uint256 amountOut = _enterLiquidityPool(from, to, amountIn);
            require(amountOut >= minAmountOut, "Exchange: slippage");

            IERC20(to).safeTransfer(msg.sender, amountOut);

            return amountOut;
        }

        if (lpTokens[from].swapProtocol != 0) {
            IERC20(from).safeTransferFrom(msg.sender, address(this), amountIn);

            uint256 amountOut = _exitLiquidityPool(from, to, amountIn);
            require(amountOut >= minAmountOut, "Exchange: slippage");

            IERC20(to).safeTransfer(msg.sender, amountOut);

            return amountOut;
        }

        if (
            from == address(0) ||
            from == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ) {
            require(
                to != address(0) &&
                    to != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                "Exchange: ETH to ETH"
            );
            require(amountIn == msg.value, "Exchange: value/amount discrep");

            wrappedEther.deposit{value: msg.value}();

            uint256 amountOut = _exchange(address(wrappedEther), to, amountIn);
            require(amountOut >= minAmountOut, "Exchange: slippage");
            IERC20(to).safeTransfer(msg.sender, amountOut);

            return amountOut;
        }

        IERC20(from).safeTransferFrom(msg.sender, address(this), amountIn);

        if (
            to == address(0) || to == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
        ) {
            uint256 amountOut = _exchange(
                from,
                address(wrappedEther),
                amountIn
            );
            require(amountOut >= minAmountOut, "Exchange: slippage");

            wrappedEther.withdraw(amountOut);

            Address.sendValue(payable(msg.sender), amountOut);

            return amountOut;
        }
        uint256 amountOut_ = _exchange(from, to, amountIn);

        require(amountOut_ >= minAmountOut, "Exchange: slippage");

        IERC20(to).safeTransfer(msg.sender, amountOut_);

        return amountOut_;
    }

    /// @notice Register swap/lp token adapters
    /// @param protocolId protocol id of adapter to add
    function registerAdapters(
        address[] calldata adapters_,
        uint32[] calldata protocolId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = adapters_.length;
        require(
            adapters_.length == protocolId.length,
            "Exchange: length discrep"
        );
        for (uint256 i = 0; i < length; i++) {
            adapters[protocolId[i]] = adapters_[i];
        }
    }

    /// @notice Unregister swap/lp token adapters
    /// @param protocolId protocol id of adapter to remove
    function unregisterAdapters(uint32[] calldata protocolId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 length = protocolId.length;
        for (uint256 i = 0; i < length; i++) {
            delete adapters[protocolId[i]];
        }
    }

    /// @notice Create single edge of a route from minor coin to major
    /// @dev In order for swap from/to minor coin to be working, `toCoin` should
    /// be registered as major
    /// @param edges array of edges to store
    function createMinorCoinEdge(RouteEdge[] calldata edges)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 length = edges.length;
        for (uint256 i = 0; i < length; i++) {
            // validate protocol id - zero is interpreted as
            // non-existing route
            require(edges[i].swapProtocol != 0, "Exchange: protocol type !set");
            require(
                edges[i].fromCoin != edges[i].toCoin,
                "Exchange: edge is loop"
            );

            if (!approveCompleted[edges[i].pool][edges[i].fromCoin]) {
                IERC20(edges[i].fromCoin).safeApprove(
                    edges[i].pool,
                    type(uint256).max
                );
                approveCompleted[edges[i].pool][edges[i].fromCoin] = true;
            }

            if (!approveCompleted[edges[i].pool][edges[i].toCoin]) {
                IERC20(edges[i].toCoin).safeApprove(
                    edges[i].pool,
                    type(uint256).max
                );
                approveCompleted[edges[i].pool][edges[i].toCoin] = true;
            }

            minorCoins[edges[i].fromCoin] = edges[i];
        }
    }

    /// @notice Remove internal minor route piece
    /// @param edges source coin of route to delete
    function deleteMinorCoinEdge(address[] calldata edges)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < edges.length; i++) {
            delete minorCoins[edges[i]];
        }
    }

    /// @notice Create route between two tokens and set them as major
    /// @param routes array of routes
    function createInternalMajorRoutes(RouteEdge[][] calldata routes)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < routes.length; i++) {
            RouteEdge[] memory route = routes[i];

            // extract start and beginning of given route
            address start = route[0].fromCoin;
            address end = route[route.length - 1].toCoin;
            require(start != end, "Exchange: route is loop");

            if (internalMajorRoute[start][end].length != 0) {
                delete internalMajorRoute[start][end];
            }

            // validate protocol id - zero is interpreted as non-existing route
            require(route[0].swapProtocol != 0, "Exchange: protocol type !set");

            // set approve of the token to the pool
            if (!approveCompleted[route[0].pool][route[0].fromCoin]) {
                IERC20(route[0].fromCoin).safeApprove(
                    route[0].pool,
                    type(uint256).max
                );
                approveCompleted[route[0].pool][route[0].fromCoin] = true;
            }

            require(
                route[0].fromCoin != route[0].toCoin,
                "Exchange: edge is loop"
            );

            // starting to save this route
            internalMajorRoute[start][end].push(route[0]);

            // if route is simple, then we've done everything for it
            if (route.length == 1) {
                // as route between these coins is set, we consider them as major
                isMajorCoin[start] = true;
                isMajorCoin[end] = true;

                continue;
            }

            // loop through whole route to check its continuity
            address node = route[0].toCoin;
            for (uint256 j = 1; j < route.length; j++) {
                require(route[j].fromCoin == node, "Exchange: route broken");
                node = route[j].toCoin;

                // validate protocol id - zero is interpreted as
                // non-existing route
                require(
                    route[j].swapProtocol != 0,
                    "Exchange: protocol type !set"
                );

                require(
                    route[j].fromCoin != route[j].toCoin,
                    "Exchange: edge is loop"
                );

                // set approve of the token to the pool
                if (!approveCompleted[route[j].pool][route[j].fromCoin]) {
                    IERC20(route[j].fromCoin).safeApprove(
                        route[j].pool,
                        type(uint256).max
                    );
                    approveCompleted[route[j].pool][route[j].fromCoin] = true;
                }

                // continiuing to save this route
                internalMajorRoute[start][end].push(route[j]);
            }

            // as route between these coins is set, we consider them as major
            isMajorCoin[start] = true;
            isMajorCoin[end] = true;
        }
    }

    /// @notice Remove internal major routes and unregister them on demand
    /// @param from source coin of route to delete
    /// @param to destination coin of route to delete
    /// @param removeMajor true if need to no longer recognize source and destination coin as major
    function deleteInternalMajorRoutes(
        address[] calldata from,
        address[] calldata to,
        bool removeMajor
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(from.length == to.length, "Exchange: length discrep");
        for (uint256 i = 0; i < from.length; i++) {
            delete internalMajorRoute[from[i]][to[i]];
            if (removeMajor) {
                isMajorCoin[from[i]] = false;
                isMajorCoin[to[i]] = false;
            }
        }
    }

    /// @notice Force unapprove of some coin to any pool
    /// @param coins coins list
    /// @param spenders pools list
    function removeApproval(
        address[] calldata coins,
        address[] calldata spenders
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(coins.length == spenders.length, "Exchange: length discrep");
        for (uint256 i = 0; i < coins.length; i++) {
            IERC20(coins[i]).safeApprove(spenders[i], 0);
            approveCompleted[spenders[i]][coins[i]] = false;
        }
    }

    /// @notice Force approve of some coin to any pool
    /// @param coins coins list
    /// @param spenders pools list
    function createApproval(
        address[] calldata coins,
        address[] calldata spenders
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(coins.length == spenders.length, "Exchange: length discrep");
        for (uint256 i = 0; i < coins.length; i++) {
            IERC20(coins[i]).safeApprove(spenders[i], type(uint256).max);
            approveCompleted[spenders[i]][coins[i]] = true;
        }
    }

    /// @notice Add all info for enabling LP token swap and set up coin approval
    /// @param edges info about protocol type and pools
    /// @param lpTokensAddress coins that will be recognized as LP tokens
    /// @param entryCoins coins which require approval to pool
    function createLpToken(
        LpToken[] calldata edges,
        address[] calldata lpTokensAddress,
        address[][] calldata entryCoins
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            edges.length == entryCoins.length &&
                entryCoins.length == lpTokensAddress.length,
            "Exchange: length discrep"
        );
        for (uint256 i = 0; i < edges.length; i++) {
            LpToken memory edge = edges[i];
            require(edge.swapProtocol != 0, "Exchange: protocol type !set");

            for (uint256 j = 0; j < entryCoins[i].length; j++) {
                if (!approveCompleted[edge.pool][entryCoins[i][j]]) {
                    IERC20(entryCoins[i][j]).safeApprove(
                        edge.pool,
                        type(uint256).max
                    );
                    approveCompleted[edge.pool][entryCoins[i][j]] = true;
                }
            }

            lpTokens[lpTokensAddress[i]] = edge;
        }
    }

    /// @notice Set addresses to be no longer recognized as LP tokens
    /// @param edges list of LP tokens
    function deleteLpToken(address[] calldata edges)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < edges.length; i++) {
            delete lpTokens[edges[i]];
        }
    }

    /// @inheritdoc	AccessControl
    function grantRole(bytes32 role, address account)
        public
        override
        onlyRole(getRoleAdmin(role))
    {
        require(account.isContract(), "Exchange: not contract");
        _grantRole(role, account);
    }

    /// @notice Build highest liquidity swap route between two ERC20 coins
    /// @param from address of coin to start route from
    /// @param to address of route destination coin
    /// @return route containing liquidity pool addresses
    function buildRoute(address from, address to)
        public
        view
        returns (RouteEdge[] memory)
    {
        bool isFromMajorCoin = isMajorCoin[from];
        bool isToMajorCoin = isMajorCoin[to];

        if (isFromMajorCoin && isToMajorCoin) {
            // Moscow - Heathrow
            // in this case route of major coins is predefined
            RouteEdge[] memory majorToMajor = internalMajorRoute[from][to];

            // check if this part of route exists
            require(
                majorToMajor.length > 0,
                "Exchange: 1!path from major coin"
            );

            return majorToMajor;
        } else if (!isFromMajorCoin && isToMajorCoin) {
            // Tomsk - Heathrow
            // getting predefined route from minor coin to major coin
            RouteEdge memory minorToMajor = minorCoins[from];

            // revert if route is not predefined
            require(
                minorToMajor.swapProtocol != 0,
                "Exchange: 2!path from input coin"
            );

            // if predefined route from minor to major coin is what we wanted
            // to get, simply return it
            if (minorToMajor.toCoin == to) {
                RouteEdge[] memory result = new RouteEdge[](1);
                result[0] = minorToMajor;
                return result;
            }

            // find continuation of the route, if these major coins don't match
            RouteEdge[] memory majorToMajor = internalMajorRoute[
                minorToMajor.toCoin
            ][to];

            // check if this part of route exists
            require(
                majorToMajor.length > 0,
                "Exchange: 2!path from major coin"
            );

            // concatenate route and return it
            RouteEdge[] memory route = new RouteEdge[](majorToMajor.length + 1);
            route[0] = minorToMajor;

            for (uint256 i = 0; i < majorToMajor.length; i++) {
                route[i + 1] = majorToMajor[i];
            }

            return route;
        } else if (isFromMajorCoin && !isToMajorCoin) {
            // Heathrow - Sochi
            // getting predefined route from any major coin to target minor coin
            RouteEdge memory majorToMinor = reverseRouteEdge(minorCoins[to]);

            // revert if route is not predefined
            require(
                majorToMinor.swapProtocol != 0,
                "Exchange: 3!path from input coin"
            );

            // if predefined route from major to minor coin is what we wanted
            // to get, simply return it
            if (majorToMinor.fromCoin == from) {
                RouteEdge[] memory result = new RouteEdge[](1);
                result[0] = majorToMinor;
                return result;
            }

            // find beginning of route from start major coin to major coin
            // that is linked to destination
            RouteEdge[] memory majorToMajor = internalMajorRoute[from][
                majorToMinor.fromCoin
            ];

            // check if this part of route exists
            require(
                majorToMajor.length > 0,
                "Exchange: 3!path from major coin"
            );

            // concatenate route and return it
            RouteEdge[] memory route = new RouteEdge[](majorToMajor.length + 1);
            route[majorToMajor.length] = majorToMinor;

            for (uint256 i = 0; i < majorToMajor.length; i++) {
                route[i] = majorToMajor[i];
            }

            return route;
        } else {
            // Chelyabinsk - Glasgow
            //       minor - minor
            // get paths from source and target coin to
            // corresponding major coins
            RouteEdge memory minorToMajor = minorCoins[from];
            RouteEdge memory majorToMinor = reverseRouteEdge(minorCoins[to]);

            // revert if routes are not predefined
            require(
                minorToMajor.swapProtocol != 0,
                "Exchange: 4!path from input coin"
            );
            require(
                majorToMinor.swapProtocol != 0,
                "Exchange: 4!path from out coin"
            );

            // if these paths overlap on one coin, simply return it
            if (minorToMajor.toCoin == majorToMinor.fromCoin) {
                RouteEdge[] memory result = new RouteEdge[](2);
                result[0] = minorToMajor;
                result[1] = majorToMinor;
                return result;
            }

            // connect input and output coins with major coins
            RouteEdge[] memory majorToMajor = internalMajorRoute[
                minorToMajor.toCoin
            ][majorToMinor.fromCoin];

            // check if this part of route exists
            require(
                majorToMajor.length > 0,
                "Exchange: 4!path from major coin"
            );

            // concatenate route and return it
            RouteEdge[] memory route = new RouteEdge[](majorToMajor.length + 2);
            route[0] = minorToMajor;
            route[majorToMajor.length + 1] = majorToMinor;

            for (uint256 i = 0; i < majorToMajor.length; i++) {
                route[i + 1] = majorToMajor[i];
            }

            return route;
        }
    }

    /// @notice Get prebuilt route between two major coins
    /// @param from major coin to start route from
    /// @param to major coin that should be end of route
    /// @return Prebuilt route between major coins
    function getMajorRoute(address from, address to)
        external
        view
        returns (RouteEdge[] memory)
    {
        return internalMajorRoute[from][to];
    }

    function _exchange(
        address from,
        address to,
        uint256 amountIn
    ) private returns (uint256) {
        // this code was written at late evening of 14 Feb
        // i would like to say to solidity: i love you <3
        // you're naughty bitch, but anyway

        RouteEdge[] memory edges = buildRoute(from, to);

        uint256 swapAmount = amountIn;
        for (uint256 i = 0; i < edges.length; i++) {
            RouteEdge memory edge = edges[i];

            address adapter = adapters[edge.swapProtocol];
            require(adapter != address(0), "Exchange: adapter not found");

            // using delegatecall for gas savings (no need to transfer tokens
            // to/from adapter)
            bytes memory returnedData = adapter.functionDelegateCall(
                abi.encodeWithSelector(
                    executeSwapSigHash,
                    edge.pool,
                    edge.fromCoin,
                    edge.toCoin,
                    swapAmount
                )
            );
            // extract return value from delegatecall
            swapAmount = abi.decode(returnedData, (uint256));
        }

        return swapAmount;
    }

    function _enterLiquidityPool(
        address from,
        address to,
        uint256 amountIn
    ) private returns (uint256) {
        LpToken memory edge = lpTokens[to];
        address adapter = adapters[edge.swapProtocol];
        require(adapter != address(0), "Exchange: adapter not found");

        // using delegatecall for gas savings (no need to transfer tokens
        // to adapter)
        bytes memory returnedData = adapter.functionDelegateCall(
            abi.encodeWithSelector(enterPoolSigHash, edge.pool, from, amountIn)
        );
        // extract return value from delegatecall
        return abi.decode(returnedData, (uint256));
    }

    function _exitLiquidityPool(
        address from,
        address to,
        uint256 amountIn
    ) private returns (uint256) {
        LpToken memory edge = lpTokens[from];
        address adapter = adapters[edge.swapProtocol];
        require(adapter != address(0), "Exchange: adapter not found");

        // using delegatecall for gas savings (no need to transfer tokens
        // to adapter)
        bytes memory returnedData = adapter.functionDelegateCall(
            abi.encodeWithSelector(exitPoolSigHash, edge.pool, to, amountIn)
        );
        // extract return value from delegatecall
        return abi.decode(returnedData, (uint256));
    }

    function reverseRouteEdge(RouteEdge memory route)
        private
        pure
        returns (RouteEdge memory)
    {
        address cache = route.fromCoin;
        route.fromCoin = route.toCoin;
        route.toCoin = cache;

        return route;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IWrappedEther {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IExchangeAdapter {
    // 0x6012856e  =>  executeSwap(address,address,address,uint256)
    function executeSwap(
        address pool,
        address fromToken,
        address toToken,
        uint256 amount
    ) external payable returns (uint256);

    // 0x73ec962e  =>  enterPool(address,address,uint256)
    function enterPool(
        address pool,
        address fromToken,
        uint256 amount
    ) external payable returns (uint256);

    // 0x660cb8d4  =>  exitPool(address,address,uint256)
    function exitPool(
        address pool,
        address toToken,
        uint256 amount
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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