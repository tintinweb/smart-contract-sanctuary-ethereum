//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './interfaces/IStaking.sol';

contract DepositHelper {
    IERC20Upgradeable public immutable ufoToken;
    IERC20Upgradeable public immutable lpToken;

    address[] public allUfoPools;
    address[] public allLpPools;

    constructor(
        address[] memory _allUfoPools,
        address[] memory _allLpPools,
        IERC20Upgradeable _ufoToken,
        IERC20Upgradeable _lpToken
    ) {
        for (uint256 index = 0; index < _allLpPools.length; index++) {
            address pool = _allLpPools[index];
            _lpToken.approve(pool, type(uint256).max);
        }

        for (uint256 index = 0; index < _allUfoPools.length; index++) {
            address pool = _allUfoPools[index];
            _ufoToken.approve(pool, type(uint256).max);
        }

        ufoToken = _ufoToken;
        lpToken = _lpToken;

        allLpPools = _allLpPools;
        allUfoPools = _allUfoPools;
    }

    function depositUfoToPool(address pool, uint256 amount) external {
        ufoToken.transferFrom(msg.sender, address(this), amount);
        IStaking(pool).depositTo(msg.sender, amount);
    }

    function depositLpToPool(address pool, uint256 amount) external {
        lpToken.transferFrom(msg.sender, address(this), amount);
        IStaking(pool).depositTo(msg.sender, amount);
    }

    function resetAllowanes() external {
        for (uint256 index = 0; index < allLpPools.length; index++) {
            address pool = allLpPools[index];
            lpToken.approve(pool, type(uint256).max);
        }

        for (uint256 index = 0; index < allUfoPools.length; index++) {
            address pool = allUfoPools[index];
            ufoToken.approve(pool, type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IStaking {
    function initialize(
        address _stakingToken,
        uint256 _lockinBlocks,
        address _operator,
        bool _isFlexiPool
    ) external;

    function claimPlasmaFromFactory(uint256[] calldata depositNumbers, address depositor) external;

    function deposit(uint256 amount) external;

    function depositTo(address _to, uint256 amount) external;
}