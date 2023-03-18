// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface ISCRYERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import './ISCRYERC20.sol';

interface ISCRYERC20Permit is ISCRYERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import './solidity-lib/libraries/TransferHelper.sol';
import './periphery/libraries/SafeMathSCRY.sol';
import './interfaces/IEEVFarmDelegate.sol';
import './interfaces/IEEVFarm.sol';
import './core/interfaces/ISCRYERC20Permit.sol';
 
/// This contract tracks LP contributions by a userAddress to a farm. This is not upgradeable and only the depositor is able to withdraw tokens.
contract EEVFarm is ReentrancyGuard, IEEVFarm {
    using SafeMathSCRY for uint;

    address public delegate;
    /// @notice Info of each user that stakes LP tokens.
    /// lpTokens => userAddress => amount staked
    mapping (address => mapping (address => uint)) public override userTokensStaked;

    event Deposit(address indexed user, address indexed lpToken, uint256 depositedAmount, uint256 newBalance);
    event Withdraw(address indexed user, address indexed lpToken, uint256 withdrawnAmount, address indexed to, uint256 newBalance);
    event EmergencyWithdraw(address indexed user, address indexed lpToken, uint256 amount, address indexed to);

    /// @param _delegate The delegate address 
    constructor(address _delegate) public {
        delegate = _delegate;
    }

    /// @notice Deposit LP tokens to Farm. Rewards go to msg.sender
    /// @param _lpToken The address of the pool.
    /// @param amount LP token amount to deposit.
    function deposit(address _lpToken, uint256 amount) public nonReentrant {
        // make safe for fee-transfer tokens
        uint256 balanceBefore = ISCRYERC20(_lpToken).balanceOf(address(this));
        TransferHelper.safeTransferFrom(_lpToken, msg.sender, address(this), amount);
        uint256 depositedAmount = ISCRYERC20(_lpToken).balanceOf(address(this)).sub(balanceBefore);
        userTokensStaked[_lpToken][msg.sender] = userTokensStaked[_lpToken][msg.sender].add(depositedAmount);

        IEEVFarmDelegate(delegate).userDepositedTokens(msg.sender, _lpToken, depositedAmount, userTokensStaked[_lpToken][msg.sender]);

        emit Deposit(msg.sender, _lpToken, amount, userTokensStaked[_lpToken][msg.sender]);
    }
    
    function depositWithPermit(address _lpToken, uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        ISCRYERC20Permit(_lpToken).permit(msg.sender, address(this), amount, deadline, v, r, s);
        deposit(_lpToken, amount);
    }

    /// @notice Withdraw LP tokens from the farm.
    /// @param _lpToken The address of the pool.
    /// @param amount LP token amount to withdraw.
    /// @param to Receiver of the LP tokens.
    function withdraw(address _lpToken, uint256 amount, address to) external nonReentrant {
        // cannot be negative
        userTokensStaked[_lpToken][msg.sender] = userTokensStaked[_lpToken][msg.sender].sub(amount);
        TransferHelper.safeTransfer(_lpToken, to, amount);
        IEEVFarmDelegate(delegate).userWithdrewTokens(msg.sender, _lpToken, amount, to, userTokensStaked[_lpToken][msg.sender]);
        
        emit Withdraw(msg.sender, _lpToken, amount, to, userTokensStaked[_lpToken][msg.sender]);
    }
    
    /// @notice Withdraw without caring about rewards. EMERGENCY ONLY in case rewards contract is broken, preventing normal withdrawal.
    /// @param _lpToken The address of the pool.
    /// @param to Receiver of the LP tokens.
    function emergencyWithdraw(address _lpToken, address to) external nonReentrant returns (uint256) {
        uint256 amount = userTokensStaked[_lpToken][msg.sender];
        userTokensStaked[_lpToken][msg.sender] = 0;
        // Note: transfer can fail or succeed if `amount` is zero.
        TransferHelper.safeTransfer(_lpToken, to, amount);
        emit EmergencyWithdraw(msg.sender, _lpToken, amount, to);
        return amount;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IEEVFarm {
    function userTokensStaked(address lpToken, address user) external view returns (uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface IEEVFarmDelegate {
    function userDepositedTokens(address sender, address lpToken, uint256 amount, uint256 newBalance) external;
    function userWithdrewTokens(address sender, address lpToken, uint256 amount, address to, uint256 newBalance) external;
}

pragma solidity >=0.5.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathSCRY {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
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