// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/ISubFactory.sol";
import "../interfaces/IHeliosGlobals.sol";

contract HeliosGlobals is IHeliosGlobals {
    address public override globalAdmin;
    bool    public override protocolPaused;
    address public override governor;

    mapping(address => bool) public override isValidPoolDelegate;
    mapping(address => bool) public override isValidPoolFactory;
    mapping(address => bool) public override isValidLiquidityAsset;
    mapping(address => mapping(address => bool)) public override validSubFactories;

    event ProtocolPaused(bool pause);
    event Initialized();
    event GlobalAdminSet(address indexed newGlobalAdmin);
    event PoolDelegateSet(address indexed delegate, bool valid);
    event LiquidityAssetSet(address asset, uint256 decimals, string symbol, bool valid);

    modifier isGovernor() {
        require(msg.sender == governor, "MG:NOT_GOV");
        _;
    }

    constructor(address _governor, address _globalAdmin) {
        require(_governor != address(0), "HG:ZERO_GOV");
        require(_globalAdmin != address(0), "HG:ZERO_ADM");
        governor = _governor;
        globalAdmin = _globalAdmin;
        emit Initialized();
    }

    function setGlobalAdmin(address newGlobalAdmin) external {
        require(msg.sender == governor && newGlobalAdmin != address(0), "HG:NOT_GOV_OR_ADM");
        require(!protocolPaused, "HG:PROTO_PAUSED");
        globalAdmin = newGlobalAdmin;
        emit GlobalAdminSet(newGlobalAdmin);
    }

    function setProtocolPause(bool pause) external {
        require(msg.sender == globalAdmin, "HG:NOT_ADM");
        protocolPaused = pause;
        emit ProtocolPaused(pause);
    }

    function setValidPoolFactory(address poolFactory, bool valid) external isGovernor {
        isValidPoolFactory[poolFactory] = valid;
    }

    function setPoolDelegateAllowList(address delegate, bool valid) external isGovernor {
        isValidPoolDelegate[delegate] = valid;
        emit PoolDelegateSet(delegate, valid);
    }

    function setValidSubFactory(address superFactory, address subFactory, bool valid) external isGovernor {
        require(isValidPoolFactory[superFactory], "HG:INV_SUPER_F");
        validSubFactories[superFactory][subFactory] = valid;
    }

    function setLiquidityAsset(address asset, bool valid) external isGovernor {
        isValidLiquidityAsset[asset] = valid;
        emit LiquidityAssetSet(asset, IERC20Metadata(asset).decimals(), IERC20Metadata(asset).symbol(), valid);
    }

    function isValidSubFactory(address superFactory, address subFactory, uint8 factoryType) external view returns (bool) {
        return validSubFactories[superFactory][subFactory] && ISubFactory(subFactory).factoryType() == factoryType;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHeliosGlobals {
    function globalAdmin() external view returns (address);

    function protocolPaused() external view returns (bool);

    function governor() external view returns (address);

    function isValidPoolDelegate(address delegate) external view returns (bool);

    function isValidPoolFactory(address poolFactory) external view returns (bool);

    function isValidLiquidityAsset(address asset) external view returns (bool);

    function validSubFactories(address superFactory, address subFactory) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISubFactory {
    function factoryType() external pure returns (uint8);
}