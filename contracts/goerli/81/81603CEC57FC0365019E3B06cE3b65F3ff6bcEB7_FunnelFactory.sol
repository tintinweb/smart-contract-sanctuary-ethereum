// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IFunnelFactory } from "./interfaces/IFunnelFactory.sol";
import { IERC5827Proxy } from "./interfaces/IERC5827Proxy.sol";
import { IFunnelErrors } from "./interfaces/IFunnelErrors.sol";
import { IFunnel } from "./interfaces/IFunnel.sol";
import { Clones } from "openzeppelin-contracts/proxy/Clones.sol";

/// @title Factory for all the funnel contracts
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
contract FunnelFactory is IFunnelFactory, IFunnelErrors {
    using Clones for address;

    /// Stores the mapping between tokenAddress => funnelAddress
    mapping(address => address) private deployments;

    /// address of the implementation. This is immutable due to security as implementation is not
    /// supposed to change after deployment
    address public immutable funnelImplementation;

    /// @notice Deploys the FunnelFactory contract
    /// @dev requires a valid funnelImplementation address
    /// @param _funnelImplementation The address of the implementation
    constructor(address _funnelImplementation) {
        if (_funnelImplementation == address(0)) {
            revert InvalidAddress({ _input: _funnelImplementation });
        }
        funnelImplementation = _funnelImplementation;
    }

    /// @inheritdoc IFunnelFactory
    function deployFunnelForToken(address _tokenAddress) external returns (address _funnelAddress) {
        if (deployments[_tokenAddress] != address(0)) {
            revert FunnelAlreadyDeployed();
        }

        if (_tokenAddress.code.length == 0) {
            revert InvalidToken();
        }

        _funnelAddress = funnelImplementation.cloneDeterministic(bytes32(uint256(uint160(_tokenAddress))));

        deployments[_tokenAddress] = _funnelAddress;
        emit DeployedFunnel(_tokenAddress, _funnelAddress);
        IFunnel(_funnelAddress).initialize(_tokenAddress);
    }

    /// @inheritdoc IFunnelFactory
    function getFunnelForToken(address _tokenAddress) public view returns (address _funnelAddress) {
        if (deployments[_tokenAddress] == address(0)) {
            revert FunnelNotDeployed();
        }

        return deployments[_tokenAddress];
    }

    /// @inheritdoc IFunnelFactory
    function isFunnel(address _funnelAddress) external view returns (bool) {
        // Not a deployed contract
        if (_funnelAddress.code.length == 0) {
            return false;
        }

        try IERC5827Proxy(_funnelAddress).baseToken() returns (address baseToken) {
            if (baseToken == address(0)) {
                return false;
            }
            return _funnelAddress == getFunnelForToken(baseToken);
        } catch {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/interfaces/IERC20.sol";
import "openzeppelin-contracts/interfaces/IERC165.sol";

/// @title Interface for IERC5827 contracts
/// @notice Please see https://eips.ethereum.org/EIPS/eip-5827 for more details on the goals of this interface
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IERC5827 is IERC20, IERC165 {
    /// Note: the ERC-165 identifier for this interface is 0x93cd7af6.
    /// 0x93cd7af6 ===
    ///   bytes4(keccak256('approveRenewable(address,uint256,uint256)')) ^
    ///   bytes4(keccak256('renewableAllowance(address,address)')) ^
    ///   bytes4(keccak256('approve(address,uint256)') ^
    ///   bytes4(keccak256('transferFrom(address,address,uint256)') ^
    ///   bytes4(keccak256('allowance(address,address)') ^

    ///   @dev Thrown when there available allowance is lesser than transfer amount
    ///   @param available Allowance available, 0 if unset
    error InsufficientRenewableAllowance(uint256 available);

    /// @notice Emitted when a new renewable allowance is set.
    /// @param _owner owner of token
    /// @param _spender allowed spender of token
    /// @param _value   initial and maximum allowance given to spender
    /// @param _recoveryRate recovery amount per second
    event RenewableApproval(address indexed _owner, address indexed _spender, uint256 _value, uint256 _recoveryRate);

    /// @notice Grants an allowance of `_value` to `_spender` initially, which recovers over time based on `_recoveryRate` up to a limit of `_value`.
    /// SHOULD throw when `_recoveryRate` is larger than `_value`.
    /// MUST emit `RenewableApproval` event.
    /// @param _spender allowed spender of token
    /// @param _value   initial and maximum allowance given to spender
    /// @param _recoveryRate recovery amount per second
    function approveRenewable(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate
    ) external returns (bool success);

    /// @notice Returns approved max amount and recovery rate.
    /// @return amount initial and maximum allowance given to spender
    /// @return recoveryRate recovery amount per second
    function renewableAllowance(address _owner, address _spender)
        external
        view
        returns (uint256 amount, uint256 recoveryRate);

    /// Overridden EIP-20 functions

    /// @notice Grants a (non-increasing) allowance of _value to _spender.
    /// MUST clear set _recoveryRate to 0 on the corresponding renewable allowance, if any.
    /// @param _spender allowed spender of token
    /// @param _value   allowance given to spender
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// @notice Moves `amount` tokens from `from` to `to` using the
    /// allowance mechanism. `amount` is then deducted from the caller's
    /// allowance factoring in recovery rate logic.
    /// SHOULD throw when there is insufficient allowance
    /// @param from token owner address
    /// @param to token recipient
    /// @param amount amount of token to transfer
    /// @return success True if the function is successful, false if otherwise
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);

    /// @notice Returns amounts spendable by `_spender`.
    /// @param _owner Address of the owner
    /// @param _spender spender of token
    /// @return remaining allowance at the current point in time
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts/interfaces/IERC165.sol";

/// @title IERC5827Payable interface
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IERC5827Payable is IERC165 {
    /// Note: the ERC-165 identifier for this interface is 0x3717806a
    /// 0x3717806a ===
    ///   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
    ///   bytes4(keccak256('approveRenewableAndCall(address,uint256,uint256,bytes)')) ^

    /// @dev Transfer tokens from one address to another and then call IERC1363Receiver `onTransferReceived` on receiver
    /// @param from address The address which you want to send tokens from
    /// @param to address The address which you want to transfer to
    /// @param value uint256 The amount of tokens to be transferred
    /// @param data bytes Additional data with no specified format, sent in call to `to`
    /// @return success true unless throwing
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool success);

    /// @notice Approve renewable allowance for spender and then call `onRenewableApprovalReceived` on IERC5827Spender
    /// @param _spender address The address which will spend the funds
    /// @param _value uint256 The amount of tokens to be spent
    /// @param _recoveryRate period duration in minutes
    /// @param data bytes Additional data with no specified format, sent in call to `spender`
    /// @return true unless throwing
    function approveRenewableAndCall(
        address _spender,
        uint256 _value,
        uint256 _recoveryRate,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title IERC5827Proxy interface
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IERC5827Proxy {
    /// Note: the ERC-165 identifier for this interface is 0xc55dae63.
    /// 0xc55dae63 ===
    ///   bytes4(keccak256('baseToken()')

    /// @notice Get the underlying base token being proxied.
    /// @return address address of the base token
    function baseToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC5827 } from "./IERC5827.sol";
import { IERC5827Payable } from "./IERC5827Payable.sol";
import { IERC5827Proxy } from "./IERC5827Proxy.sol";

/// @title Interface for Funnel contracts for ERC20
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IFunnel is IERC5827, IERC5827Proxy, IERC5827Payable {
    /// @dev Invalid selector returned
    error InvalidReturnSelector();

    /// @dev Error thrown when attempting to transfer to a non IERC1363Receiver
    error NotIERC1363Receiver();

    /// @dev Error thrown when attempting to transfer to a non IERC5827Spender
    error NotIERC5827Spender();

    /// @dev Error thrown if the Recovery Rate exceeds the max allowance
    error RecoveryRateExceeded();

    /// @notice Called when the contract is being initialised.
    /// @param _token contract address of the underlying ERC20 token
    /// @dev Sets the INITIAL_CHAIN_ID and INITIAL_DOMAIN_SEPARATOR that might be used in future permit calls
    function initialize(address _token) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Shared errors for Funnel Contracts and FunnelFactory
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IFunnelErrors {
    /// @dev Invalid address, could be due to zero address
    /// @param _input address that caused the error.
    error InvalidAddress(address _input);

    /// Error thrown when the token is invalid
    error InvalidToken();

    /// @dev Thrown when attempting to interact with a non-contract.
    error NotContractError();

    /// @dev Error thrown when the permit deadline expires
    error PermitExpired();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title Interface for Funnel Factory
/// @author Zac (zlace0x), zhongfu (zhongfu), Edison (edison0xyz)
interface IFunnelFactory {
    /// ==== Factory Errors =====

    /// Error thrown when funnel is not deployed
    error FunnelNotDeployed();

    /// Error thrown when funnel is already deployed.
    error FunnelAlreadyDeployed();

    /// @notice Event emitted when the funnel contract is deployed
    /// @param tokenAddress of the base token (indexed)
    /// @param funnelAddress of the deployed funnel contract (indexed)
    event DeployedFunnel(address indexed tokenAddress, address indexed funnelAddress);

    /// @notice Deploys a new Funnel contract
    /// @param _tokenAddress The address of the token
    /// @return _funnelAddress The address of the deployed Funnel contract
    /// @dev Throws if `_tokenAddress` has already been deployed
    function deployFunnelForToken(address _tokenAddress) external returns (address _funnelAddress);

    /// @notice Retrieves the Funnel contract address for a given token address
    /// @param _tokenAddress The address of the token
    /// @return _funnelAddress The address of the deployed Funnel contract
    /// @dev Reverts with FunnelNotDeployed if `_tokenAddress` has not been deployed
    function getFunnelForToken(address _tokenAddress) external view returns (address _funnelAddress);

    /// @notice Checks if a given address is a deployed Funnel contract
    /// @param _funnelAddress The address that you want to query
    /// @return true if contract address is a deployed Funnel contract
    function isFunnel(address _funnelAddress) external view returns (bool);
}