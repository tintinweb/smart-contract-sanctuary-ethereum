// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../libs/LibPosition.sol";
import "../interfaces/IRegistry.sol";
import "../interfaces/IOpiumProxyFactory.sol";
import "../interfaces/IOpiumPositionToken.sol";

interface IERC20Extended is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

struct PositionData {
    address positionAddress;
    string name;
    string symbol;
    uint256 totalSupply;
    LibDerivative.Derivative derivative;
    bool isLong;
}

contract OnChainPositionsLens {
    using LibDerivative for LibDerivative.Derivative;
    using LibPosition for bytes32;

    IRegistry public immutable registry;

    constructor(address _registry) {
        registry = IRegistry(_registry);
    }

    function predictPositionsAddressesByDerivative(LibDerivative.Derivative calldata _derivative)
        external
        view
        returns (address, address)
    {
        bytes32 derivativeHash = _derivative.getDerivativeHash();
        return _predictPositionsAddressesByDerivativeHash(derivativeHash);
    }

    function predictPositionsAddressesByDerivativeHash(bytes32 _derivativeHash)
        external
        view
        returns (address, address)
    {
        return _predictPositionsAddressesByDerivativeHash(_derivativeHash);
    }

    function getDerivativePositionsData(bytes32 _derivativeHash) external view returns (PositionData[2] memory) {
        return _getDerivativePositionsData(_derivativeHash);
    }

    function getDerivativesPositionsData(bytes32[] calldata _derivativesHash)
        external
        view
        returns (PositionData[2][] memory)
    {
        PositionData[2][] memory positionsData = new PositionData[2][](_derivativesHash.length);
        for (uint256 i = 0; i < _derivativesHash.length; i++) {
            positionsData[i] = _getDerivativePositionsData(_derivativesHash[i]);
        }
        return positionsData;
    }

    function _getDerivativePositionsData(bytes32 _derivativeHash) private view returns (PositionData[2] memory) {
        IOpiumProxyFactory opiumProxyFactory = IOpiumProxyFactory(registry.getProtocolAddresses().opiumProxyFactory);

        address longPositionAddress = _derivativeHash.predictDeterministicAddress(
            true,
            opiumProxyFactory.getImplementationAddress(),
            address(opiumProxyFactory)
        );
        address shortPositionAddress = _derivativeHash.predictDeterministicAddress(
            false,
            opiumProxyFactory.getImplementationAddress(),
            address(opiumProxyFactory)
        );

        return [
            PositionData({
                positionAddress: longPositionAddress,
                name: IERC20Extended(longPositionAddress).name(),
                symbol: IERC20Extended(longPositionAddress).symbol(),
                totalSupply: IERC20Extended(longPositionAddress).totalSupply(),
                derivative: IOpiumPositionToken(longPositionAddress).getPositionTokenData().derivative,
                isLong: true
            }),
            PositionData({
                positionAddress: shortPositionAddress,
                name: IERC20Extended(shortPositionAddress).name(),
                symbol: IERC20Extended(shortPositionAddress).symbol(),
                totalSupply: IERC20Extended(shortPositionAddress).totalSupply(),
                derivative: IOpiumPositionToken(shortPositionAddress).getPositionTokenData().derivative,
                isLong: false
            })
        ];
    }

    function _predictPositionsAddressesByDerivativeHash(bytes32 _derivativeHash)
        private
        view
        returns (address, address)
    {
        address longPositionAddress = _derivativeHash.predictDeterministicAddress(
            true,
            IOpiumProxyFactory(registry.getProtocolAddresses().opiumProxyFactory).getImplementationAddress(),
            registry.getProtocolAddresses().opiumProxyFactory
        );
        (
            true,
            IOpiumProxyFactory(registry.getProtocolAddresses().opiumProxyFactory).getImplementationAddress(),
            registry.getProtocolAddresses().opiumProxyFactory
        );
        address shortPositionAddress = _derivativeHash.predictDeterministicAddress(
            false,
            IOpiumProxyFactory(registry.getProtocolAddresses().opiumProxyFactory).getImplementationAddress(),
            registry.getProtocolAddresses().opiumProxyFactory
        );
        return (longPositionAddress, shortPositionAddress);
    }
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.5;

import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";

library LibPosition {
    function predictDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) internal pure returns (address) {
        return _predictDeterministicAddress(_derivativeHash, _isLong, _positionImplementationAddress, _factoryAddress);
    }

    function predictAndCheckDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) internal view returns (address, bool) {
        address predicted = _predictDeterministicAddress(
            _derivativeHash,
            _isLong,
            _positionImplementationAddress,
            _factoryAddress
        );
        bool isDeployed = _isContract(predicted);
        return (predicted, isDeployed);
    }

    function deployOpiumPosition(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress
    ) internal returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_derivativeHash, _isLong ? "L" : "S"));
        return ClonesUpgradeable.cloneDeterministic(_positionImplementationAddress, salt);
    }

    function _predictDeterministicAddress(
        bytes32 _derivativeHash,
        bool _isLong,
        address _positionImplementationAddress,
        address _factoryAddress
    ) private pure returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_derivativeHash, _isLong ? "L" : "S"));
        return ClonesUpgradeable.predictDeterministicAddress(_positionImplementationAddress, salt, _factoryAddress);
    }

    /// @notice checks whether a contract has already been deployed at a specific address
    /// @return bool true if a contract has been deployed at a specific address and false otherwise
    function _isContract(address _address) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;
import "../core/registry/RegistryEntities.sol";

interface IRegistry {
    function initialize(address _governor) external;

    function setProtocolAddresses(
        address _opiumProxyFactory,
        address _core,
        address _oracleAggregator,
        address _syntheticAggregator,
        address _tokenSpender
    ) external;

    function setNoDataCancellationPeriod(uint32 _noDataCancellationPeriod) external;

    function addToWhitelist(address _whitelisted) external;

    function removeFromWhitelist(address _whitelisted) external;

    function setProtocolExecutionReserveClaimer(address _protocolExecutionReserveClaimer) external;

    function setProtocolRedemptionReserveClaimer(address _protocolRedemptionReserveClaimer) external;

    function setProtocolExecutionReservePart(uint32 _protocolExecutionReservePart) external;

    function setDerivativeAuthorExecutionFeeCap(uint32 _derivativeAuthorExecutionFeeCap) external;

    function setProtocolRedemptionReservePart(uint32 _protocolRedemptionReservePart) external;

    function setDerivativeAuthorRedemptionReservePart(uint32 _derivativeAuthorRedemptionReservePart) external;

    function pause() external;

    function pauseProtocolPositionCreation() external;

    function pauseProtocolPositionMinting() external;

    function pauseProtocolPositionRedemption() external;

    function pauseProtocolPositionExecution() external;

    function pauseProtocolPositionCancellation() external;

    function pauseProtocolReserveClaim() external;

    function unpause() external;

    function getProtocolParameters() external view returns (RegistryEntities.ProtocolParametersArgs memory);

    function getProtocolAddresses() external view returns (RegistryEntities.ProtocolAddressesArgs memory);

    function isRegistryManager(address _address) external view returns (bool);

    function isCoreConfigurationUpdater(address _address) external view returns (bool);

    function getCore() external view returns (address);

    function isCoreSpenderWhitelisted(address _address) external view returns (bool);

    function isProtocolPaused() external view returns (bool);

    function isProtocolPositionCreationPaused() external view returns (bool);

    function isProtocolPositionMintingPaused() external view returns (bool);

    function isProtocolPositionRedemptionPaused() external view returns (bool);

    function isProtocolPositionExecutionPaused() external view returns (bool);

    function isProtocolPositionCancellationPaused() external view returns (bool);

    function isProtocolReserveClaimPaused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;
import "../libs/LibDerivative.sol";

interface IOpiumProxyFactory {
    function getImplementationAddress() external view returns (address);

    function initialize(address _registry) external;

    function create(
        address _buyer,
        address _seller,
        uint256 _amount,
        bytes32 _derivativeHash,
        LibDerivative.Derivative calldata _derivative
    ) external;

    function mintPair(
        address _buyer,
        address _seller,
        address _longPositionAddress,
        address _shortPositionAddress,
        uint256 _amount
    ) external;

    function burn(
        address _positionOwner,
        address _positionAddress,
        uint256 _amount
    ) external;

    function burnPair(
        address _positionOwner,
        address _longPositionAddress,
        address _shortPositionAddress,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-IERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../libs/LibDerivative.sol";

interface IOpiumPositionToken is IERC20PermitUpgradeable, IERC20Upgradeable {
    struct OpiumPositionTokenParams {
        LibDerivative.Derivative derivative;
        LibDerivative.PositionType positionType;
        bytes32 derivativeHash;
    }

    function initialize(
        bytes32 _derivativeHash,
        LibDerivative.PositionType _positionType,
        LibDerivative.Derivative calldata _derivative
    ) external;

    function mint(address _positionOwner, uint256 _amount) external;

    function burn(address _positionOwner, uint256 _amount) external;

    function getFactoryAddress() external view returns (address);

    function getPositionTokenData() external view returns (OpiumPositionTokenParams memory opiumPositionTokenParams);

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) external;

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
library ClonesUpgradeable {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

library RegistryEntities {
    struct ProtocolParametersArgs {
        // Period of time after which ticker could be canceled if no data was provided to the `oracleId`
        uint32 noDataCancellationPeriod;
        // Max fee that derivative author can set
        // it works as an upper bound for when the derivative authors set their synthetic's fee
        uint32 derivativeAuthorExecutionFeeCap;
        // Fixed part (percentage) that the derivative author receives for each redemption of market neutral positions
        // It is not set by the derivative authors themselves
        uint32 derivativeAuthorRedemptionReservePart;
        // Represents which part of derivative author reserves originated from derivative executions go to the protocol reserves
        uint32 protocolExecutionReservePart;
        // Represents which part of derivative author reserves originated from redemption of market neutral positions go to the protocol reserves
        uint32 protocolRedemptionReservePart;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        uint32 __gapOne;
        uint32 __gapTwo;
        uint32 __gapThree;
    }

    struct ProtocolAddressesArgs {
        // Address of Opium.Core contract
        address core;
        // Address of Opium.OpiumProxyFactory contract
        address opiumProxyFactory;
        // Address of Opium.OracleAggregator contract
        address oracleAggregator;
        // Address of Opium.SyntheticAggregator contract
        address syntheticAggregator;
        // Address of Opium.TokenSpender contract
        address tokenSpender;
        // Address of the recipient of execution protocol reserves
        address protocolExecutionReserveClaimer;
        // Address of the recipient of redemption protocol reserves
        address protocolRedemptionReserveClaimer;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        uint32 __gapOne;
        uint32 __gapTwo;
    }

    struct ProtocolPausabilityArgs {
        // if true, all the protocol's entry-points are paused
        bool protocolGlobal;
        // if true, no new positions can be created
        bool protocolPositionCreation;
        // if true, no new positions can be minted
        bool protocolPositionMinting;
        // if true, no new positions can be redeemed
        bool protocolPositionRedemption;
        // if true, no new positions can be executed
        bool protocolPositionExecution;
        // if true, no new positions can be cancelled
        bool protocolPositionCancellation;
        // if true, no reserves can be claimed
        bool protocolReserveClaim;
        /// Initially uninitialized variables to allow some flexibility in case of future changes and upgradeability
        bool __gapOne;
        bool __gapTwo;
        bool __gapThree;
        bool __gapFour;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.5;

/// @title Opium.Lib.LibDerivative contract should be inherited by contracts that use Derivative structure and calculate derivativeHash
library LibDerivative {
    enum PositionType {
        SHORT,
        LONG
    }

    // Opium derivative structure (ticker) definition
    struct Derivative {
        // Margin parameter for syntheticId
        uint256 margin;
        // Maturity of derivative
        uint256 endTime;
        // Additional parameters for syntheticId
        uint256[] params;
        // oracleId of derivative
        address oracleId;
        // Margin token address of derivative
        address token;
        // syntheticId of derivative
        address syntheticId;
    }

    /// @notice Calculates hash of provided Derivative
    /// @param _derivative Derivative Instance of derivative to hash
    /// @return derivativeHash bytes32 Derivative hash
    function getDerivativeHash(Derivative memory _derivative) internal pure returns (bytes32 derivativeHash) {
        derivativeHash = keccak256(
            abi.encodePacked(
                _derivative.margin,
                _derivative.endTime,
                _derivative.params,
                _derivative.oracleId,
                _derivative.token,
                _derivative.syntheticId
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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