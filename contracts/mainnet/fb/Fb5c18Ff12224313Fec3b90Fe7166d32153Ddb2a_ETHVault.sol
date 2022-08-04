// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import {IWETH} from '../interfaces/IWETH.sol';
import {IETHVault} from "../interfaces/IETHVault.sol";
import {IICHIVault} from "../interfaces/IICHIVault.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 @notice wrapper contract around ICHI vault with wETH being a base token. Allows users to deposit ETH instead of wETH
 */
contract ETHVault is ReentrancyGuard, IETHVault {

    // WETH address
    address public immutable override wETH;

    // Vault address
    address public immutable override vault;

    // Flag that indicates whether the vault is inverted or not
    bool private immutable isInverted;

    address constant NULL_ADDRESS = address(0);

    /**
     @notice creates an instance of ETHVault (wrapped around an existing ICHI vault)
     @param _wETH wETH address
     @param _vault underlying vault
     */
    constructor(
        address _wETH,
        address _vault
    ) {
        require(_wETH != NULL_ADDRESS && _vault != NULL_ADDRESS, "EV.constructor: zero address");

        wETH = _wETH;
        vault = _vault;

        bool _isInverted = _wETH == IICHIVault(_vault).token0();

        require(_isInverted || _wETH == IICHIVault(_vault).token1(), "EV.constructor: one of the tokens must be wETH");
        isInverted = _isInverted;
        IERC20(_wETH).approve(_vault, uint256(-1));

        emit DeployETHVault(
            msg.sender,
            _vault,
            _wETH,
            _isInverted
        );
    }

    /**
     @notice Distributes shares to depositor equal to the ETH value of his deposit multiplied by the ratio of total liquidity shares issued divided by the pool's AUM measured in ETH value. 
     @param to Address to which liquidity tokens are minted
     @param shares Quantity of liquidity tokens minted as a result of deposit
     */
    function depositETH(
        address to
    ) external payable override nonReentrant returns (uint256 shares) {
        require(msg.value > 0, "EV.depositETH: can't deposit 0");

        IWETH(wETH).deposit{ value: msg.value }();
        shares = isInverted ? IICHIVault(vault).deposit(msg.value, 0, to) : IICHIVault(vault).deposit(0, msg.value, to);
    }

}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

import "./IICHIVault.sol";

interface IETHVault {

    // WETH address
    function wETH() external view returns(address);

    // Vault address
    function vault() external view returns(address);
    
    function depositETH(
        address
    ) external payable returns (uint256);

    event DeployETHVault(
        address indexed sender, 
        address indexed vault, 
        address wETH,
        bool isInverted);

}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IICHIVault{

    function ichiVaultFactory() external view returns(address);

    function pool() external view returns(address);
    function token0() external view returns(address);
    function allowToken0() external view returns(bool);
    function token1() external view returns(address);
    function allowToken1() external view returns(bool);
    function fee() external view returns(uint24);
    function tickSpacing() external view returns(int24);
    function affiliate() external view returns(address);

    function baseLower() external view returns(int24);
    function baseUpper() external view returns(int24);
    function limitLower() external view returns(int24);
    function limitUpper() external view returns(int24);

    function deposit0Max() external view returns(uint256);
    function deposit1Max() external view returns(uint256);
    function maxTotalSupply() external view returns(uint256);
    function hysteresis() external view returns(uint256);

    function getTotalAmounts() external view returns (uint256, uint256);

    function deposit(
        uint256,
        uint256,
        address
    ) external returns (uint256);

    function withdraw(
        uint256,
        address
    ) external returns (uint256, uint256);

    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        int256 swapQuantity
    ) external;

    function setDepositMax(
        uint256 _deposit0Max, 
        uint256 _deposit1Max) external;

    function setAffiliate(
        address _affiliate) external;

    event DeployICHIVault(
        address indexed sender, 
        address indexed pool, 
        bool allowToken0,
        bool allowToken1,
        address owner,
        uint256 twapPeriod);

    event SetTwapPeriod(
        address sender, 
        uint32 newTwapPeriod
    );

    event Deposit(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Withdraw(
        address indexed sender,
        address indexed to,
        uint256 shares,
        uint256 amount0,
        uint256 amount1
    );

    event Rebalance(
        int24 tick,
        uint256 totalAmount0,
        uint256 totalAmount1,
        uint256 feeAmount0,
        uint256 feeAmount1,
        uint256 totalSupply
    );

    event MaxTotalSupply(
        address indexed sender, 
        uint256 maxTotalSupply);

    event Hysteresis(
        address indexed sender, 
        uint256 hysteresis);

    event DepositMax(
        address indexed sender, 
        uint256 deposit0Max, 
        uint256 deposit1Max);
        
    event Affiliate(
        address indexed sender, 
        address affiliate);    
}

// SPDX-License-Identifier: Unlicense

pragma solidity 0.7.6;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}