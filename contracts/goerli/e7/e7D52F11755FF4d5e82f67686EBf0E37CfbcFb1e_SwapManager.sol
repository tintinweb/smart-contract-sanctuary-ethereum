//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ISwapManager
 * @author gotbit
 */

import './connectors/SwapConnector.sol';

interface ISwapManager {
    function connectors(address router) external view returns (SwapConnector);

    function setConnector(address dex, address connect) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SwapManager
 * @author gotbit
 */

import '../utils/HasRouter.sol';

import {ISwapManager, SwapConnector} from './ISwapManager.sol';

contract SwapManager is ISwapManager, HasRouter {
    mapping(address => SwapConnector) public connectors;

    constructor(address router_, address superAdmin_) HasRouter(router_, superAdmin_) {}

    function setConnector(address dex, address connector) external onlyRouter {
        connectors[dex] = SwapConnector(connector);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SwapConnector
 * @author gotbit
 */

abstract contract SwapConnector {
    function WETH(address dex) external view virtual returns (address) {}

    function addLiquidity(
        address dex,
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
        virtual
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {}

    function swapExactTokensForTokens(
        address dex,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory) {}

    function swapTokensForExactTokens(
        address dex,
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external virtual returns (uint256[] memory) {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title HasRouter
 * @author gotbit
 */

import {IHasRouter} from './IHasRouter.sol';

contract HasRouter is IHasRouter {
    address public router;
    address public superAdmin;

    modifier onlyRouter() {
        require(
            msg.sender == router || _isSuperAdmin(msg.sender),
            'Only Router function'
        );
        _;
    }

    modifier onlySuperAdmin() {
        require(_isSuperAdmin(msg.sender), 'Only Super Admin function');
        _;
    }

    constructor(address router_, address superAdmin_) {
        router = router_;
        superAdmin = superAdmin_;
    }

    function setRouter(address router_) external onlySuperAdmin {
        router = router_;
    }

    function _isSuperAdmin(address user) internal view returns (bool) {
        return user == superAdmin;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IHasRouter
 * @author gotbit
 */

interface IHasRouter {
    function router() external view returns (address);

    function superAdmin() external view returns (address);

    function setRouter(address router_) external;
}