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

pragma solidity ^0.8.0;

interface ITokenSeikyu {
    function init(
        address _client,
        address _provider,
        address _token,
        uint256 _price,
        uint256 _terminationTime, // exact termination date in seconds since epoch
        address _wrappedNativeToken,
        bool _requireVerification
    ) external;

    function release() external;

    function releaseTokens(address _token) external;

    function withdraw() external;

    function withdrawTokens(address _token) external;

    function lock() external payable;

    function payByClient(uint256 _providerAward) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenSeikyuFactory {
    function create(
        address _client,
        address _provider,
        address _token,
        uint256 _price,
        uint256 _terminationTime,
        bool _requireVerification
    ) external returns (address);

    function createDeterministic(
        address _client,
        address _provider,
        address _token,
        uint256 _price,
        uint256 _terminationTime,
        bytes32 _salt,
        bool _requireVerification
    ) external returns (address);

    function predictDeterministicAddress(bytes32 _salt)
        external
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./interfaces/ITokenSeikyuFactory.sol";
import "./interfaces/ITokenSeikyu.sol";

contract TokenSeikyuFactory is ITokenSeikyuFactory {
    uint256 public invoiceCount = 0;
    mapping(uint256 => address) internal _invoices;

    event LogNewInvoice(uint256 indexed index, address invoice, uint256 price);

    address public immutable implementation;
    address public immutable wrappedNativeToken;

    constructor(address _implementation, address _wrappedNativeToken) {
        require(_implementation != address(0), "invalid implementation");
        require(
            _wrappedNativeToken != address(0),
            "invalid wrappedNativeToken"
        );
        implementation = _implementation;
        wrappedNativeToken = _wrappedNativeToken;
    }

    function _init(
        address _invoiceAddress,
        address _client,
        address _provider,
        address _token,
        uint256 _price,
        uint256 _terminationTime,
        bool _requireVerification
    ) internal {
        ITokenSeikyu(_invoiceAddress).init(
            _client,
            _provider,
            _token,
            _price,
            _terminationTime,
            wrappedNativeToken,
            _requireVerification
        );

        uint256 invoiceId = invoiceCount;
        _invoices[invoiceId] = _invoiceAddress;
        invoiceCount = invoiceCount + 1;

        emit LogNewInvoice(invoiceId, _invoiceAddress, _price);
    }

    function create(
        address _client,
        address _provider,
        address _token,
        uint256 _price,
        uint256 _terminationTime,
        bool _requireVerification
    ) external override returns (address) {
        address invoiceAddress = Clones.clone(implementation);

        _init(
            invoiceAddress,
            _client,
            _provider,
            _token,
            _price,
            _terminationTime,
            _requireVerification
        );

        return invoiceAddress;
    }

    function predictDeterministicAddress(bytes32 _salt)
        external
        view
        override
        returns (address)
    {
        return Clones.predictDeterministicAddress(implementation, _salt);
    }

    function createDeterministic(
        address _client,
        address _provider,
        address _token,
        uint256 _price,
        uint256 _terminationTime,
        bytes32 _salt,
        bool _requireVerification
    ) external override returns (address) {
        address invoiceAddress = Clones.cloneDeterministic(
            implementation,
            _salt
        );

        _init(
            invoiceAddress,
            _client,
            _provider,
            _token,
            _price,
            _terminationTime,
            _requireVerification
        );

        return invoiceAddress;
    }

    function getInvoiceAddress(uint256 _index) public view returns (address) {
        return _invoices[_index];
    }
}