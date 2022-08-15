// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interface/ILightClient.sol";
import "./common/EcdsaSignatureVerification.sol";
import "./common/BytesUtil.sol";
import "./interface/IRelayerHub.sol";

contract LightClient is
    ILightClient,
    EcdsaSignatureVerification,
    BytesUtil,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    IRelayerHub public relayerHub;
    uint256 constant LEN_OF_LEN = 4;
    uint256 constant LEN_OF_SIG = 20 + 32 + 32 + 1;

    function initialize(address _relayerHub) public initializer {
        __Ownable_init();
        __Pausable_init();

        require(
            _relayerHub != address(0),
            "Invalid address"
        );
        relayerHub = IRelayerHub(_relayerHub);
    }

    function decodeAndVerifyEvent(
        uint256, /*_blockchainId*/
        bytes32, /* _eventSig */
        bytes calldata _payload,
        bytes calldata _signature,
        address _relayer
    ) external view {
        require(
            relayerHub.isRelayer(_relayer),
            "Signer isn't relayer"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ILightClient {
    /**
     * Decode and verify event information. Use require to fail the transaction
     * if any of the information is invalid.
     *
     * @param _blockchainId The blockchain that emitted the event. This could be
     *    used to determine which sets of signing keys are valid.
     * @param _eventSig The event function selector. This will be for a Start event,
     *    a Segment event, or a Root event. Not all implementations will need to
     *    use this value. Others may need this to allow then to find the event in a
     *    transaction receipt.
     * @param _payload The abi.encodePacked of the blockchain id, the Crosschain
     *    Control contract's address, the event function selector, and the event data.
     * @param _signature Signatures or proof information that an implementation can
     *    use to check that _signedEventInfo is valid.
     */
    function decodeAndVerifyEvent(
        uint256 _blockchainId,
        bytes32 _eventSig,
        bytes calldata _payload,
        bytes calldata _signature,
        address _relayer
    ) external view;
}

/*
 * Copyright 2020 ConsenSys Software Inc
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity >=0.7.1;

/**
 * Signature verification for ECDSA / KECCAK256 using secp256k1 curve.
 */
contract EcdsaSignatureVerification {
    /**
     * Verify a signature.
     *
     * @param _signer Address that corresponds to the public key of the signer.
     * @param _message Message to be verified.
     * @param _signature Signature to be verified.
     *
     */
    function verify(
        address _signer,
        bytes calldata _message,
        bytes calldata _signature
    ) internal pure returns (bool) {
        // Check the signature length
        if (_signature.length != 65) {
            return false;
        }

        bytes memory sig = _signature;
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Split the signature into components r, s and v variables with inline assembly.
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }

        return verifySigComponents(_signer, _message, r, s, v);
    }

    /**
     * Verify a signature.
     *
     * @param _signer Address that corresponds to the public key of the signer.
     * @param _message Message to be verified.
     * @param _sigR Component of the signature to be verified.
     * @param _sigS Component of the signature to be verified.
     * @param _sigV Component of the signature to be verified.
     *
     */
    function verifySigComponents(
        address _signer,
        bytes calldata _message,
        bytes32 _sigR,
        bytes32 _sigS,
        uint8 _sigV
    ) internal pure returns (bool) {
        bytes32 digest = keccak256(_message);

        if (_sigV != 27 && _sigV != 28) {
            return false;
        } else {
            // The signature is verified if the address recovered from the signature matches
            // the signer address (which maps to the public key).
            return _signer == ecrecover(digest, _sigV, _sigR, _sigS);
        }
    }
}

/*
 * Copyright 2020 ConsenSys Software Inc
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity >=0.7.1;

abstract contract BytesUtil {
    // Based on stack overflow here: https://ethereum.stackexchange.com/questions/15350/how-to-convert-an-bytes-to-address-in-solidity
    function bytesToAddress1(bytes memory _b, uint256 _startOffset)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(_b, add(32, _startOffset)))
        }
    }

    function bytesToAddress2(bytes memory _b, uint256 _startOffset)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(_b, add(20, _startOffset)))
        }
    }

    function bytesToAddress(bytes memory _b)
        internal
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(_b, 20))
        }
    }

    // TODO find something faster than this.
    // From stack overflow here: https://ethereum.stackexchange.com/questions/7702/how-to-convert-byte-array-to-bytes32-in-solidity
    function bytesToBytes32CallData(bytes calldata b, uint256 offset)
        internal
        pure
        returns (bytes32)
    {
        bytes32 out;

        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function bytesToBytes32(bytes memory b, uint256 offset)
        internal
        pure
        returns (bytes32)
    {
        bytes32 out;

        for (uint256 i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    // Starting point was this, but with some modifications.
    // https://ethereum.stackexchange.com/questions/49185/solidity-conversion-bytes-memory-to-uint
    function bytesToUint256(bytes memory _b, uint256 _startOffset)
        internal
        pure
        returns (uint256)
    {
        require(
            _b.length >= _startOffset + 32,
            "slicing out of range (uint256)"
        );
        uint256 x;
        assembly {
            x := mload(add(_b, add(32, _startOffset)))
        }
        return x;
    }

    function bytesToUint64(bytes memory _b, uint256 _startOffset)
        internal
        pure
        returns (uint64)
    {
        require(_b.length >= _startOffset + 8, "slicing out of range (uint64)");
        uint256 x;
        assembly {
            x := mload(add(_b, add(8, _startOffset)))
        }
        return uint64(x);
    }

    function bytesToUint32(bytes memory _b, uint256 _startOffset)
        internal
        pure
        returns (uint32)
    {
        require(_b.length >= _startOffset + 4, "slicing out of range (uint32)");
        uint256 x;
        assembly {
            x := mload(add(_b, add(4, _startOffset)))
        }
        return uint32(x);
    }

    function bytesToUint16(bytes memory _b, uint256 _startOffset)
        internal
        pure
        returns (uint16)
    {
        require(_b.length >= _startOffset + 2, "slicing out of range (uint16)");
        uint256 x;
        assembly {
            x := mload(add(_b, add(2, _startOffset)))
        }
        return uint16(x);
    }

    function bytesToUint8(bytes memory _b, uint256 _startOffset)
        internal
        pure
        returns (uint8)
    {
        require(_b.length >= _startOffset + 1, "slicing out of range (uint8)");
        uint256 x;
        assembly {
            x := mload(add(_b, add(1, _startOffset)))
        }
        return uint8(x);
    }

    // From https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function sliceAsm(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Read out of bounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    // https://ethereum.stackexchange.com/questions/78559/how-can-i-slice-bytes-strings-and-arrays-in-solidity
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        bytes memory a = new bytes(_length);
        for (uint256 i = 0; i < _length; i++) {
            a[i] = _bytes[_start + i];
        }
        return a;
    }

    function slice(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes memory)
    {
        return slice(_bytes, _start, (_bytes.length - _start));
    }

    function compare(bytes memory _a, bytes memory _b)
        internal
        pure
        returns (bool)
    {
        if (_a.length != _b.length) {
            return false;
        } else {
            return keccak256(_a) == keccak256(_b);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IRelayerHub {
    /**
     * Verify relayer is signer for a blockchain
     *
     * @param _address The relayer address
     */
    function isRelayer(address _address) external view returns (bool);

    /**
     * Register relayer for a blockchain
     */
    function register() external;

    /**
     * Unregister relayer for a blockchain
     */
    function unregister() external;

    /**
     * Register relayer for a blockchain use only for owner
     *
     * @param _address The relayer address
     */
    function adminRegister(address _address) external;

    /**
     * Unregister relayer for a blockchain use only for owner
     *
     * @param _address The relayer address
     */
    function adminUnregister(address _address) external;

    /**
     * Update registration status public
     */
    function enablePublicRegistration() external;

    /**
     * Update registration status private
     */
    function disablePublicRegistration() external;

    /**
     * Update required deposit amount
     *
     * @param _requiredDeposit Required deposit amount
     */
    function updateRequiredDeposit(uint256 _requiredDeposit) external;

    /**
     * Update dues amount
     *
     * @param _dues Registration dues amount
     */
    function updateDues(uint256 _dues) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}