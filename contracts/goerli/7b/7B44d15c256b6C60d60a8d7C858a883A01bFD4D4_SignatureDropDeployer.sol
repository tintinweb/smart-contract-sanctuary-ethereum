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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

interface IOwnableEvents {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

interface IOwnable {
    function transferOwnership(address nextOwner_) external;

    function cancelOwnershipTransfer() external;

    function acceptOwnership() external;

    function renounceOwnership() external;

    function isOwner() external view returns (bool);

    function isNextOwner() external view returns (bool);
}

contract Ownable is IOwnable, IOwnableEvents {
    address public owner;
    address private nextOwner;

    /// > [[[[[[[[[[[ Modifiers ]]]]]]]]]]]

    modifier onlyOwner() {
        require(isOwner(), "caller is not the owner.");
        _;
    }

    modifier onlyNextOwner() {
        require(isNextOwner(), "current owner must set caller as next owner.");
        _;
    }

    /// @notice Initialize contract by setting the initial owner.
    constructor(address owner_) {
        _setInitialOwner(owner_);
    }

    /// @notice Initiate ownership transfer by setting nextOwner.
    function transferOwnership(address nextOwner_) external override onlyOwner {
        require(nextOwner_ != address(0), "Next owner is the zero address.");

        nextOwner = nextOwner_;
    }

    /// @notice Cancel ownership transfer by deleting nextOwner.
    function cancelOwnershipTransfer() external override onlyOwner {
        delete nextOwner;
    }

    /// @notice Accepts ownership transfer by setting owner.
    function acceptOwnership() external override onlyNextOwner {
        delete nextOwner;

        owner = msg.sender;

        emit OwnershipTransferred(owner, msg.sender);
    }

    /// @notice Renounce ownership by setting owner to zero address.
    function renounceOwnership() external override onlyOwner {
        _renounceOwnership();
    }

    /// @notice Returns true if the caller is the current owner.
    function isOwner() public view override returns (bool) {
        return msg.sender == owner;
    }

    /// @notice Returns true if the caller is the next owner.
    function isNextOwner() public view override returns (bool) {
        return msg.sender == nextOwner;
    }

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function _setOwner(address previousOwner, address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, owner);
    }

    function _setInitialOwner(address newOwner) internal {
        owner = newOwner;
        emit OwnershipTransferred(address(0), newOwner);
    }

    function _renounceOwnership() internal {
        emit OwnershipTransferred(owner, address(0));

        owner = address(0);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/proxy/Clones.sol";

import "./Ownable.sol";

interface ITWFactory {
    function deployProxyByImplementation(
        address _implementation,
        bytes memory _data,
        bytes32 _salt
    ) external returns (address);
}

interface ITWTokenERC1155 {
    function initialize(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address[] memory _trustedForwarders,
        address _primarySaleRecipient,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        uint128 _platformFeeBps,
        address _platformFeeRecipient
    ) external;

    function mintTo(
        address to,
        uint256 tokenId,
        string calldata uri,
        uint256 amount
    ) external;

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function setOwner(address _newOwner) external;

    function setFlatPlatformFeeInfo(
        address _platformFeeRecipient,
        uint256 _flatFee
    ) external;

    enum PlatformFeeType {
        Bps,
        FLAT
    }

    function setPlatformFeeType(PlatformFeeType _feeType) external;
}

interface ISignatureDropDeployer {
    event ProxyDeployed(
        address indexed proxyAddress,
        address indexed admin,
        bytes32 salt
    );

    event NewMinter(address indexed oldMinter, address indexed newMinter);

    struct DeployParams {
        address admin;
        string _name;
        string _symbol;
        string _contractURI;
        string _uri;
        address[] _trustedForwarders;
        address _primarySaleRecipient;
        address _royaltyRecipient;
        uint128 _royaltyBps;
        uint256 _platformFee;
        address _platformFeeRecipient;
        bytes32 salt;
    }

    function setMinter(address _newMinter) external;

    function deploy(DeployParams memory params) external returns (address);

    function predictDeterministicAddress(bytes32 _salt)
        external
        view
        returns (address);
}

contract SignatureDropDeployer is ISignatureDropDeployer, Ownable {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    address public immutable TWFactoryAddress;

    address public immutable TWEditionImplementationAddress;

    address public minter;

    constructor(
        address _owner,
        address _minter,
        address _factory,
        address _implementation
    ) Ownable(_owner) {
        _setMinter(_minter);

        TWFactoryAddress = _factory;
        TWEditionImplementationAddress = _implementation;
    }

    function setMinter(address _newMinter) public override onlyOwner {
        _setMinter(_newMinter);
    }

    function deploy(DeployParams memory params)
        public
        override
        returns (address)
    {
        bytes memory callData = abi.encodeWithSelector(
            ITWTokenERC1155.initialize.selector,
            address(this),
            params._name,
            params._symbol,
            params._contractURI,
            params._trustedForwarders,
            params._primarySaleRecipient,
            params._royaltyRecipient,
            params._royaltyBps,
            0, // no bps fee for platform
            params._platformFeeRecipient
        );

        // Deploy proxy.
        address proxyAddress = _deployProxy(callData, params.salt);

        // Mint token to admin.
        ITWTokenERC1155(proxyAddress).mintTo(
            params.admin,
            type(uint256).max,
            params._uri,
            0
        );

        // Set fees.
        _setFees(
            proxyAddress,
            params._platformFeeRecipient,
            params._platformFee
        );

        // Set roles.
        _setRoles(proxyAddress, params.admin);

        emit ProxyDeployed(proxyAddress, params.admin, params.salt);

        return proxyAddress;
    }

    function predictDeterministicAddress(bytes32 _salt)
        public
        view
        override
        returns (address)
    {
        return
            Clones.predictDeterministicAddress(
                TWEditionImplementationAddress,
                keccak256(abi.encodePacked(address(this), _salt)),
                TWFactoryAddress
            );
    }

    function _setMinter(address _newMinter) internal {
        emit NewMinter(minter, _newMinter);

        minter = _newMinter;
    }

    function _deployProxy(bytes memory callData, bytes32 salt)
        internal
        returns (address)
    {
        return
            ITWFactory(TWFactoryAddress).deployProxyByImplementation(
                TWEditionImplementationAddress,
                callData,
                salt
            );
    }

    function _setFees(
        address proxyAddress,
        address _platformFeeRecipient,
        uint256 _platformFee
    ) internal {
        ITWTokenERC1155(proxyAddress).setFlatPlatformFeeInfo(
            _platformFeeRecipient,
            _platformFee
        );
        ITWTokenERC1155(proxyAddress).setPlatformFeeType(
            ITWTokenERC1155.PlatformFeeType.FLAT
        );
    }

    function _setRoles(address proxyAddress, address admin) internal {
        // Grant minter role to Mirror wallet.
        ITWTokenERC1155(proxyAddress).grantRole(MINTER_ROLE, minter);

        // Set roles for admin.
        ITWTokenERC1155(proxyAddress).grantRole(DEFAULT_ADMIN_ROLE, admin);
        ITWTokenERC1155(proxyAddress).grantRole(MINTER_ROLE, admin);
        ITWTokenERC1155(proxyAddress).grantRole(TRANSFER_ROLE, admin);

        // Remove roles for deployer.
        ITWTokenERC1155(proxyAddress).revokeRole(MINTER_ROLE, address(this));
        ITWTokenERC1155(proxyAddress).revokeRole(TRANSFER_ROLE, address(this));

        // Transfer ownership to admin.
        ITWTokenERC1155(proxyAddress).setOwner(admin);

        ITWTokenERC1155(proxyAddress).revokeRole(
            DEFAULT_ADMIN_ROLE,
            address(this)
        );
    }
}