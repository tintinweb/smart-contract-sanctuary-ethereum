// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.13;

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Clones} from "lib/openzeppelin-contracts/contracts/proxy/Clones.sol";
import {IVesting} from "src/interfaces/IVesting.sol";

/*//////////////////////////////////////////////////////////////
                        CUSTOM ERROR
//////////////////////////////////////////////////////////////*/

error NoAccess();
error ZeroAddress();
error ZeroAmount();
error StartLessThanNow();
error AmountMoreThanBalance();
error AlreadyExists();

/*//////////////////////////////////////////////////////////////
                          CONTRACT
//////////////////////////////////////////////////////////////*/

/// @title Vesting Factory Contract
contract VestingFactory {
    // Address of the treasury contract
    address public treasury;

    // Vesting implementation
    address public vesting;

    // Interface of token contract
    IERC20 public token;

    // A mapping between the recipient address and the corresponding vesting contract address
    mapping(address => address) public recipientVesting;
    // List of all the vesting addresses created
    address[] public vestingAddresses;

    constructor(address _treasury, address _vesting, address _token) {
        treasury = _treasury;
        vesting = _vesting;
        token = IERC20(_token);
    }

    modifier onlyTreasury() {
        if (msg.sender != treasury) revert NoAccess();
        _;
    }

    /// @notice Create a new vesting to a receipient starting from now with the duration and amount of tokens.
    /// @dev Can only be called by the treasury.
    /// @param _recipient Address of the recipient.
    /// @param _duration Duration of the vesting period.
    /// @param _amount Total amount of tokens which are going to be vested.
    function createVestingFromNow(address _recipient, uint40 _duration, uint256 _amount, bool _isCancellable)
        external
        onlyTreasury
        returns (address vestingAddress)
    {
        if (_recipient == address(0)) revert ZeroAddress();
        if (_amount < 1) revert ZeroAmount();
        if (_amount > token.balanceOf(address(this))) revert AmountMoreThanBalance();
        if (recipientVesting[_recipient] != address(0)) revert AlreadyExists();

        vestingAddress = Clones.clone(vesting);
        recipientVesting[_recipient] = vestingAddress;
        vestingAddresses.push(vestingAddress);

        IVesting(vestingAddress).initialise(_recipient, uint40(block.timestamp), _duration, _amount, _isCancellable);
        token.transfer(vestingAddress, _amount);
    }

    /// @notice Create a new vesting to a recipient starting from a particular time with the duration and amount of tokens.
    /// @dev Can only be called by the treasury.
    /// @param _recipient Address of the recipient.
    /// @param _start Starting time of the vesting.
    /// @param _duration Duration of the vesting period.
    /// @param _amount Total amount of tokens which are going to be vested.
    function createVestingStartingFrom(
        address _recipient,
        uint40 _start,
        uint40 _duration,
        uint256 _amount,
        bool _isCancellable
    ) external onlyTreasury returns (address vestingAddress) {
        if (_recipient == address(0)) revert ZeroAddress();
        if (_start < block.timestamp) revert StartLessThanNow();
        if (_amount < 1) revert ZeroAmount();
        if (_amount > token.balanceOf(address(this))) revert AmountMoreThanBalance();
        if (recipientVesting[_recipient] != address(0)) revert AlreadyExists();

        vestingAddress = Clones.clone(vesting);
        recipientVesting[_recipient] = vestingAddress;
        vestingAddresses.push(vestingAddress);

        IVesting(vestingAddress).initialise(_recipient, _start, _duration, _amount, _isCancellable);
        token.transfer(vestingAddress, _amount);
    }

    /// @notice Changes the address of the treasury.
    /// @dev Can only be called by the treasury.
    /// @param _newTreasury Address of the new treasury.
    function changeTreasury(address _newTreasury) external onlyTreasury {
        if (_newTreasury == address(0)) revert ZeroAddress();
        treasury = _newTreasury;
    }

    function withdraw(address _token) external onlyTreasury {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        if (balance > 0) IERC20(_token).transfer(treasury, balance);
    }

    function changeRecipient(address _oldRecipient, address _newRecipient) external {
        if ((_oldRecipient == address(0)) || (_newRecipient == address(0))) revert ZeroAddress();
        if (recipientVesting[_oldRecipient] != msg.sender) revert NoAccess();
        if (recipientVesting[_newRecipient] != address(0)) revert AlreadyExists();
        recipientVesting[_oldRecipient] = address(0);
        recipientVesting[_newRecipient] = msg.sender;
    }

    function claim() external {
        for (uint256 i = 0; i < vestingAddresses.length;) {
            address v = vestingAddresses[i];
            if (!IVesting(v).cancelled()) {
                if (IVesting(v).totalClaimedAmount() < IVesting(v).amount()) {
                    IVesting(v).claim();
                }
            }
            unchecked {++i;}
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IVesting {
    function cancelled() external returns (bool);

    function totalClaimedAmount() external returns (uint256);
    
    function amount() external returns (uint256);

    function initialise(address _recipient, uint40 _start, uint40 _duration, uint256 _amount, bool _isCancellable)
        external;

    function claim() external;
}