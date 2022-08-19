//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/proxy/Clones.sol';
import './interfaces/IChiselFactory.sol';
import './interfaces/IChisel.sol';

contract ChiselFactory is IChiselFactory {
    using Clones for address;

    /// @notice address of chisels
    address[] public allChisels;

    /// @notice address of chisel implementation
    address public chiselImpl;

    /// @notice address of admin
    address public admin;

    /// @notice modifier to allow only the owner to call a function
    modifier onlyAdmin() {
        require(msg.sender == admin, 'ChiselFactory: Not Admin');
        _;
    }

    constructor(address _chiselImpl, address _admin) {
        require(_chiselImpl != address(0), 'ChiselFactory: Invalid ChiselImpl');
        require(_admin != address(0), 'ChiselFactory: Invalid admin');

        chiselImpl = _chiselImpl;
        admin = _admin;
    }

    /// @dev update ChiselImpl address
    function updateChiselImpl(address _chiselImpl) external override onlyAdmin {
        require(_chiselImpl != address(0), 'ChiselFactory: Invalid ChiselImpl');
        chiselImpl = _chiselImpl;
    }

    /// @dev Create Chisel
    function createChisel(
        address _admin,
        address _vault,
        address _baseToken
    ) external override onlyAdmin returns (address newChisel) {
        bytes32 salt = keccak256(abi.encode(address(this), allChisels.length));
        newChisel = chiselImpl.cloneDeterministic(salt);
        IChisel(newChisel).initialize(_admin, _vault, _baseToken);
        allChisels.push(newChisel);

        emit NewChisel(newChisel);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IChiselFactory {
    event NewChisel(address newChisel);

    function updateChiselImpl(address _chiselImpl) external;

    function createChisel(
        address _admin,
        address _vault,
        address _baseToken
    ) external returns (address newChisel);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import './IWarpLendingPair.sol';

interface IChisel {
    /////////////////////////
    // Events
    /////////////////////////
    event Initialized(address _admin, address _vault, address _baseToken);
    event Deposited(address _depositor, uint256 _vaultShares, bool _isVaultShare);
    event Withdraw(IWarpLendingPair _pair, uint256 _vaultShares, address _recipient);
    event LiquidityAdded(IWarpLendingPair _pair, uint256 _amount);

    event Claim(address indexed account, uint256 amount);
    event NewIncome(uint256 addAmount, uint256 rewardRate);
    event FeeDistribution(uint256 income, uint256 amount);
    event NewCallIncentiveSet(uint256 value);
    event IncentiveCallerSet(address account, bool isIncentive);
    event Rebalance(IWarpLendingPair _from, IWarpLendingPair _to, uint256 _vaultShares);

    /////////////////////////
    // Functions
    /////////////////////////
    function initialize(
        address _admin,
        address _vault,
        address _baseToken
    ) external;

    function deposit(uint256 _amount, bool _isVaultShare) external;

    function withdraw(
        IWarpLendingPair _pair,
        uint256 _amount,
        address _recipient
    ) external;

    function addLiquidityToPair(IWarpLendingPair _pair, uint256 _vaultShares) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../external/library/DataTypes.sol';

interface IWarpLendingPair {
    function asset() external view returns (IERC20);

    function depositBorrowAsset(address _tokenReceipeint, uint256 _amount) external;

    function redeem(address _to, uint256 _amount) external;

    function exchangeRateCurrent() external returns (uint256);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

library DataTypes {
    struct PairBorrowConfig {
        uint256 exchangeRateMantissa;
    }
}