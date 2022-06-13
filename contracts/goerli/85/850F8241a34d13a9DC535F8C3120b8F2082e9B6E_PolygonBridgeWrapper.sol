//SPDX-License-Identifier: Unlicense

//For Test
//need to rewrite with higher version.
//need to rewrite with safeERC20

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface BridgeManager {
    function depositFor(
        address _user,
        address _root_token,
        bytes calldata _deposit_data
    ) external;
}

contract PolygonBridgeWrapper {
    uint256 private constant MAX_UINT256 = 2**256 - 1;
    address public constant INSURE = 0xd9F8A187f9C3e4de34283C52C8E0b852074bB846;

    address public constant POLYGON_BRIDGE_MANAGER =
        0xBbD7cBFA79faee899Eaf900F13C9065bF03B1A74; //RootChainManagerProxy

    address public constant POLYGON_BRIDGE_RECEIVER =
        0xdD6596F2029e6233DEFfaCa316e6A95217d4Dc34; //ERC20PredicateProxy

    mapping(address => bool) public isApproved;

    constructor() public {
        require(
            IERC20(INSURE).approve(POLYGON_BRIDGE_RECEIVER, MAX_UINT256),
            "failed to approve"
        );

        isApproved[INSURE] = true;
    }

    function bridge(
        address _token,
        address _to,
        uint256 _amount
    ) public {
        require(
            IERC20(_token).transferFrom(msg.sender, address(this), _amount)
        );

        if (_token != INSURE && !isApproved[_token]) {
            require(
                IERC20(INSURE).approve(POLYGON_BRIDGE_RECEIVER, MAX_UINT256),
                "failed to approve"
            );

            isApproved[_token] = true;
        }

        BridgeManager(POLYGON_BRIDGE_MANAGER).depositFor(
            _to,
            _token,
            abi.encode(_amount)
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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