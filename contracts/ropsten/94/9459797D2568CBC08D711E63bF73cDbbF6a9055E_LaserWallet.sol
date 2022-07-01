// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "./core/Singleton.sol";
import "./handlers/Handler.sol";
import "./interfaces/ILaserWallet.sol";
import "./ssr/SSR.sol";

/**
 * @title LaserWallet - EVM based smart contract wallet. Implementes "smart social recovery" mechanism.
 * @author Rodrigo Herrera I.
 */
contract LaserWallet is Singleton, SSR, Handler, ILaserWallet {
    string public constant VERSION = "1.0.0";

    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    bytes32 private constant LASER_TYPE_STRUCTURE =
        keccak256(
            "LaserOperation(address to,uint256 value,bytes callData,uint256 nonce,uint256 maxFeePerGas,uint256 maxPriorityFeePerGas,uint256 gasTip)"
        );
    bytes4 private constant EIP1271_MAGIC_VALUE =
        bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    uint256 public nonce;

    constructor() {
        // This makes the singleton unusable. e.g. (parity wallet hack).
        owner = address(this);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @dev Setup function, sets initial storage of contract.
     * @param _owner The owner of the wallet.
     * @param _recoveryOwner Recovery owner in case the owner looses the main device. Implementation of Sovereign Social Recovery.
     * @param _guardians Addresses that can activate the social recovery mechanism.
     * @notice It can't be called after initialization.
     */
    function init(
        address _owner,
        address _recoveryOwner,
        address[] calldata _guardians
    ) external {
        // initOwner() requires that the current owner is address 0.
        // This is enough to protect init() from being called after initialization.
        initOwners(_owner, _recoveryOwner);
        initGuardians(_guardians);
        emit Setup(owner, _recoveryOwner, _guardians);
    }

    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasTip,
        bytes calldata signatures
    ) external {
        // This is just for a quick trial, the userOp needs to change.
        uint256 initialGas = gasleft();
        // We immediately increase the nonce to avoid replay attacks.
        if (nonce++ != _nonce) revert LW__validateUserOp__invalidNonce();

        // We verify that the signatures are correct ...
        verifyTransaction(
            to,
            value,
            callData,
            _nonce,
            maxFeePerGas,
            maxPriorityFeePerGas,
            gasTip,
            signatures
        );

        // We execute the main transaction ...
        bool success = _call(to, value, callData, gasleft());

        if (success) emit ExecSuccess(to, value, nonce);
        else emit ExecFailure(to, value, nonce);

        // We calculate the gas price, as per the user's request ...
        uint256 gasPrice = calculateGasPrice(
            maxFeePerGas,
            maxPriorityFeePerGas
        );

        // We refund the relayer for sending the transaction + tip.
        // The gasTip can be the amount of gas used for the initial callData call. (In theory no real tip).
        uint256 refundAmount = (initialGas - gasleft() + gasTip) * gasPrice;

        // We refund the relayer ...
        success = _call(msg.sender, refundAmount, new bytes(0), gasleft());

        // If the transaction returns false, we revert ..
        if (!success) revert LW__exec__refundFailure();
    }

    /**
     * @dev Simulates a transaction to have a rough estimate for UserOp.callGas.
     * @notice Needs to be called off-chain from the address zero.
     */
    function simulateTransaction(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasTip,
        bytes calldata signatures
    ) external returns (uint256 totalGas) {
        uint256 initialGas = gasleft();
        if (nonce++ != _nonce) revert LW__validateUserOp__invalidNonce();
        verifyTransaction(
            to,
            value,
            callData,
            _nonce,
            maxFeePerGas,
            maxPriorityFeePerGas,
            gasTip,
            signatures
        );
        bool success = _call(to, value, callData, gasleft());
        if (!success) revert LW__simulateTransaction__mainCallError();
        uint256 gasPrice = calculateGasPrice(
            maxFeePerGas,
            maxPriorityFeePerGas
        );
        uint256 gasUsed = initialGas - gasleft();
        uint256 refundAmount = (gasUsed + gasTip) * gasPrice;
        success = _call(msg.sender, refundAmount, new bytes(0), gasleft());
        if (!success) revert LW__simulateTransaction__refundFailure();
        totalGas = initialGas - gasleft();
        require(
            msg.sender == address(0),
            "Must be called off-chain from address zero."
        );
    }

    function operationHash(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasTip
    ) public view returns (bytes32) {
        return
            keccak256(
                encodeOperation(
                    to,
                    value,
                    callData,
                    _nonce,
                    maxFeePerGas,
                    maxPriorityFeePerGas,
                    gasTip
                )
            );
    }

    /**
     * @dev Implementation of EIP 1271: https://eips.ethereum.org/EIPS/eip-1271.
     * @param hash Hash of a message signed on behalf of address(this).
     * @param signature Signature byte array associated with _msgHash.
     * @return Magic value  or reverts with an error message.
     */
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (r, s, v) = splitSigs(signature, 0);
        address recovered = returnSigner(hash, r, s, v);
        if (recovered != owner) revert LW__isValidSignature__invalidSigner();
        else return EIP1271_MAGIC_VALUE;
    }

    /**
     * @return chainId The chain id of this.
     */
    function getChainId() public view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }

    function domainSeparator() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    DOMAIN_SEPARATOR_TYPEHASH,
                    getChainId(),
                    address(this)
                )
            );
    }

    function verifyTransaction(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasTip,
        bytes calldata signatures
    ) internal view {
        // We encode the transaction data.
        bytes memory encodedData = encodeOperation(
            to,
            value,
            callData,
            _nonce,
            maxFeePerGas,
            maxPriorityFeePerGas,
            gasTip
        );

        // Now we hash it ...
        bytes32 dataHash = keccak256(encodedData);

        // We get the actual function selector to determine access ...
        bytes4 funcSelector = bytes4(callData);

        // access() checks if the wallet is locked for the owner or guardians ...
        Access _access = access(funcSelector);

        // We verify that the signatures are correct depending on the transaction type ...
        verifySignatures(_access, dataHash, signatures);
    }

    /**
     * @dev Verifies that the signature(s) match the transaction type and sender.
     * @param _access Who has permission to invoke this transaction.
     * @param dataHash The keccak256 has of the transaction's data playload.
     * @param signatures The signatures sent by the UserOp.
     */
    function verifySignatures(
        Access _access,
        bytes32 dataHash,
        bytes calldata signatures
    ) internal view {
        if (_access == Access.Owner) {
            verifyOwner(dataHash, signatures);
        } else if (_access == Access.Guardian) {
            verifyGuardian(dataHash, signatures);
        } else if (_access == Access.OwnerAndGuardian) {
            verifyOwnerAndGuardian(dataHash, signatures);
        } else if (_access == Access.RecoveryOwnerAndGuardian) {
            verifyRecoveryOwnerAndGurdian(dataHash, signatures);
        } else if (_access == Access.OwnerAndRecoveryOwner) {
            verifyOwnerAndRecoveryOwner(dataHash, signatures);
        } else {
            revert();
        }
    }

    function encodeOperation(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasTip
    ) internal view returns (bytes memory) {
        bytes32 userOperationHash = keccak256(
            abi.encode(
                LASER_TYPE_STRUCTURE,
                to,
                value,
                keccak256(callData),
                _nonce,
                maxFeePerGas,
                maxPriorityFeePerGas,
                gasTip
            )
        );

        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator(),
                userOperationHash
            );
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../interfaces/IERC165.sol";
import "../interfaces/ISingleton.sol";
import "./SelfAuthorized.sol";

/**
 * @title Singleton - Base for singleton contracts (should always be first super contract).
 * This contract is tightly coupled to our proxy contract (see `proxies/LaserProxy.sol`).
 */
contract Singleton is SelfAuthorized, ISingleton {
    // Singleton always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address public singleton;

    /**
     * @dev Migrates to a new singleton (implementation).
     * @param _singleton New implementation address.
     */
    function upgradeSingleton(address _singleton) external authorized {
        if (_singleton == address(this))
            revert Singleton__upgradeSingleton__incorrectAddress();

        if (!IERC165(_singleton).supportsInterface(0xae029e0b)) {
            //bytes4(keccak256("I_AM_LASER")))
            revert Singleton__upgradeSingleton__notLaser();
        } else {
            singleton = _singleton;
            emit SingletonChanged(_singleton);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "../interfaces/IHandler.sol";
import "../interfaces/IERC165.sol";

/**
 * @title TokenHandler - Supports token callbacks.
 */
contract Handler is IHandler, IERC165 {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4 result) {
        return 0xbc197c81;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure {}

    function supportsInterface(bytes4 _interfaceId)
        external
        pure
        returns (bool)
    {
        return
            _interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165
            _interfaceId == 0x1626ba7e || // EIP 1271
            _interfaceId == 0xd9b67a26 || // ERC165 interface ID for ERC1155
            _interfaceId == 0x4e2312e0 || // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
            _interfaceId == 0xae029e0b || // Laser Wallet contract: bytes4(keccak256("I_AM_LASER"))
            _interfaceId == 0x150b7a02; // ERC721 onErc721Received
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
 * @title ILaserWallet
 * @author Rodrigo Herrera I.
 * @notice Has all the external functions, structs, events and errors for LaserWallet.sol.
 */
interface ILaserWallet {
    event Received(address indexed sender, uint256 amount);
    event Setup(address owner, address recoveryOwner, address[] guardians);
    event ExecSuccess(address to, uint256 value, uint256 nonce);
    event ExecFailure(address to, uint256 value, uint256 nonce);

    ///@dev validateUserOp custom error.
    error LW__validateUserOp__invalidNonce();

    ///@dev exec() custom errors.
    error LW__exec__refundFailure();

    ///@dev simulateTransaction() custom errors.
    error LW__simulateTransaction__mainCallError();
    error LW__simulateTransaction__refundFailure();

    ///@dev isValidSignature() custom error.
    error LW__isValidSignature__invalidSigner();

    /**
     * @dev Setup function, sets initial storage of contract.
     * @param owner The owner of the wallet.
     * @param recoveryOwner Recovery owner in case the owner looses the main device. Implementation of Sovereign Social Recovery.
     * @param guardians Addresses that can activate the social recovery mechanism.
     * @notice It can't be called after initialization.
     */
    function init(
        address owner,
        address recoveryOwner,
        address[] calldata guardians
    ) external;

    function exec(
        address to,
        uint256 value,
        bytes calldata callData,
        uint256 _nonce,
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas,
        uint256 gasTip,
        bytes calldata signatures
    ) external;

    /**
     * @dev Implementation of EIP 1271: https://eips.ethereum.org/EIPS/eip-1271.
     * @param hash Hash of a message signed on behalf of address(this).
     * @param signature Signature byte array associated with _msgHash.
     * @return Magic value  or reverts with an error message.
     */
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        returns (bytes4);

    /**
     * @dev Returns the chain id of this.
     */
    function getChainId() external view returns (uint256);

    /**
     * @dev Returns the domain separator of this.
     * @notice This is done to avoid replay attacks.
     */
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../core/SelfAuthorized.sol";
import "../core/Owner.sol";
import "../interfaces/IEIP1271.sol";
import "../interfaces/IERC165.sol";
import "../interfaces/ISSR.sol";
import "../utils/Utils.sol";

/**
 * @title SSR - Sovereign Social Recovery
 * @notice New wallet recovery mechanism.
 * @author Rodrigo Herrera I.
 */
contract SSR is ISSR, SelfAuthorized, Owner, Utils {
    ///@dev pointer address for the nested mapping.
    address internal constant pointer = address(0x1);

    uint256 internal guardianCount;

    bool public isLocked;

    ///@dev If guardians are blocked, they cannot do any transaction.
    ///This is to completely prevent from guardians misbehaving.
    bool public guardiansBlocked;

    mapping(address => address) internal guardians;

    /**
     * @dev Locks the wallet. Can only be called by a guardian.
     */
    function lock() external authorized {
        isLocked = true;
        emit WalletLocked();
    }

    /**
     * @dev Unlocks the wallet. Can only be called by a guardian + the owner.
     */
    function unlock() external authorized {
        isLocked = false;
        emit WalletUnlocked();
    }

    /**
     * @dev Unlocks the wallet. Can only be called by the recovery owner + the owner.
     * This is to avoid the wallet being locked forever if a guardian misbehaves.
     * The guardians will be locked until the owner decides otherwise.
     */
    function recoveryUnlock() external authorized {
        isLocked = false;
        guardiansBlocked = true;
        emit RecoveryUnlocked();
    }

    /**
     * @dev Unlocks the guardians. This can only be called by the owner.
     */
    function unlockGuardians() external authorized {
        guardiansBlocked = false;
    }

    /**
     * @dev Can only recover with the signature of 1 guardian and the recovery owner.
     * @param newOwner The new owner address. This is generated instantaneously.
     * @param newRecoveryOwner The new recovery owner address. This is generated instantaneously.
     * @notice The newOwner and newRecoveryOwner key pair should be generated from the mobile device.
     * The main reason of this is to restart the generation process in case an attacker has the current recoveryOwner.
     */
    function recover(address newOwner, address newRecoveryOwner)
        external
        authorized
    {
        checkParams(newOwner, newRecoveryOwner);
        owner = newOwner;
        recoveryOwner = newRecoveryOwner;
        emit WalletRecovered(newOwner, newRecoveryOwner);
    }

    /**
     * @dev Adds a guardian to the wallet.
     * @param newGuardian Address of the new guardian.
     * @notice Can only be called by the owner.
     */
    function addGuardian(address newGuardian) external authorized {
        if (
            newGuardian == address(0) ||
            newGuardian == owner ||
            guardians[newGuardian] != address(0)
        ) revert SSR__addGuardian__invalidAddress();
        if (!IERC165(newGuardian).supportsInterface(0x1626ba7e))
            revert SSR__addGuardian__invalidAddress();

        guardians[newGuardian] = guardians[pointer];
        guardians[pointer] = newGuardian;

        unchecked {
            // Won't overflow...
            ++guardianCount;
        }
        emit NewGuardian(newGuardian);
    }

    /**
     * @dev Removes a guardian to the wallet.
     * @param prevGuardian Address of the previous guardian in the linked list.
     * @param guardianToRemove Address of the guardian to be removed.
     * @notice Can only be called by the owner.
     */
    function removeGuardian(address prevGuardian, address guardianToRemove)
        external
        authorized
    {
        if (guardianToRemove == pointer) {
            revert SSR__removeGuardian__invalidAddress();
        }

        if (guardians[prevGuardian] != guardianToRemove) {
            revert SSR__removeGuardian__incorrectPreviousGuardian();
        }

        // There needs to be at least 1 guardian ..
        if (guardianCount - 1 < 1) revert SSR__removeGuardian__underflow();

        guardians[prevGuardian] = guardians[guardianToRemove];
        guardians[guardianToRemove] = address(0);
        unchecked {
            //Won't underflow...
            --guardianCount;
        }
        emit GuardianRemoved(guardianToRemove);
    }

    /**
     * @param guardian Requested address.
     * @return Boolean if the address is a guardian of the current wallet.
     */
    function isGuardian(address guardian) external view returns (bool) {
        return guardian != pointer && guardians[guardian] != address(0);
    }

    /**
     * @return Array of guardians of this.
     */
    function getGuardians() public view returns (address[] memory) {
        address[] memory guardiansArray = new address[](guardianCount);
        address currentGuardian = guardians[pointer];

        uint256 index = 0;
        while (currentGuardian != pointer) {
            guardiansArray[index] = currentGuardian;
            currentGuardian = guardians[currentGuardian];
            index++;
        }
        return guardiansArray;
    }

    /**
     * @dev Sets up the initial guardian configuration. Can only be called from the init function.
     * @param _guardians Array of guardians.
     */
    function initGuardians(address[] calldata _guardians) internal {
        uint256 guardiansLength = _guardians.length;
        if (guardiansLength < 1) revert SSR__initGuardians__zeroGuardians();

        address currentGuardian = pointer;

        for (uint256 i = 0; i < guardiansLength; ) {
            address guardian = _guardians[i];
            if (
                guardian == owner ||
                guardian == address(0) ||
                guardian == pointer ||
                guardian == currentGuardian ||
                guardians[guardian] != address(0)
            ) revert SSR__initGuardians__invalidAddress();

            if (guardian.code.length > 0) {
                // If the guardian is a smart contract wallet, it needs to support EIP1271.
                if (!IERC165(guardian).supportsInterface(0x1626ba7e))
                    revert SSR__initGuardians__invalidAddress();
            }

            unchecked {
                // Won't overflow...
                ++i;
            }
            guardians[currentGuardian] = guardian;
            currentGuardian = guardian;
        }

        guardians[currentGuardian] = pointer;
        guardianCount = guardiansLength;
    }

    /**
     * @dev Returns who has access to call a specific function.
     * @param funcSelector The function selector: bytes4(keccak256(...)).
     */
    function access(bytes4 funcSelector) internal view returns (Access) {
        if (funcSelector == this.lock.selector) {
            // Only a guardian can lock the wallet ...
            // If  guardians are locked, we revert ...
            if (guardiansBlocked) revert SSR__access__guardiansBlocked();
            else return Access.Guardian;
        } else if (funcSelector == this.unlock.selector) {
            // Only a guardian + the owner can unlock the wallet ...
            return Access.OwnerAndGuardian;
        } else if (funcSelector == this.recoveryUnlock.selector) {
            // This is in case a guardian is misbehaving ...
            return Access.OwnerAndRecoveryOwner;
        } else if (funcSelector == this.recover.selector) {
            // Only the recovery owner + the guardian can recover the wallet (change the owner keys) ...
            return Access.RecoveryOwnerAndGuardian;
        } else {
            // Else is the owner ... If the the wallet is locked, we revert ...
            if (isLocked) revert SSR__access__walletLocked();
            else return Access.Owner;
        }
    }

    /**
     * @dev Verifies that the signature matches the owner.
     */
    function verifyOwner(bytes32 dataHash, bytes memory signature)
        internal
        view
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length < 65)
            revert SSR__verifyGuardian__invalidSignature();

        (r, s, v) = splitSigs(signature, 0);
        address recovered = returnSigner(dataHash, r, s, v);
        if (recovered != owner) revert SSR__verifyOwner__notOwner();
    }

    /**
     * @dev Verifies that the signature matches a guardian.
     */
    function verifyGuardian(bytes32 dataHash, bytes memory signature)
        internal
        view
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        bool _isGuardian;

        if (signature.length < 65)
            revert SSR__verifyGuardian__invalidSignature();

        (r, s, v) = splitSigs(signature, 0);

        // We first check if the guardian is a regular EOA ...
        address recovered = returnSigner(dataHash, r, s, v);

        if (guardians[recovered] != address(0)) {
            _isGuardian = true;
        } else {
            // Else, the guardian can be a smart contract wallet ...
            // Each wallet can pack their signatures in different ways,
            // so we need to send the payload ...
            address[] memory _guardians = getGuardians();

            for (uint256 i = 0; i < guardianCount; ) {
                address guardian = _guardians[i];
                // We check if the guardian is a smart contract wallet ...
                if (guardian.code.length > 0) {
                    if (
                        IEIP1271(guardian).isValidSignature(
                            dataHash,
                            signature
                        ) == 0x1626ba7e
                    ) _isGuardian = true;
                }
                unchecked {
                    // Won't overflow ...
                    ++i;
                }
            }
        }
        if (!_isGuardian) revert SSR__verifyGurdian__notGuardian();
    }

    /**
     * @dev Verifies that the signatures correspond to the owner and guardian.
     * The first signature needs to match the owner.
     */
    function verifyOwnerAndGuardian(bytes32 dataHash, bytes calldata signatures)
        internal
        view
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // The guardian can be an EOA or smart contract wallet ...
        if (signatures.length < 130)
            revert SSR__verifyOwnerAndGuardian__invalidSignature();

        // The first signer needs to be the owner ...
        (r, s, v) = splitSigs(signatures, 0);
        address _isOwner = returnSigner(dataHash, r, s, v);
        if (_isOwner != owner) revert SSR__verifyOwnerAndGuardian__notOwner();

        // The second signer needs to be the guardian ...
        // We first check if the guardian is a regular EOA ...
        address recoveredGuardian;
        bool _isGuardian;
        recoveredGuardian = returnSigner(dataHash, r, s, v);
        if (guardians[recoveredGuardian] != address(0)) {
            _isGuardian = true;
        } else {
            // Else, the guardian can be a smart contract wallet ...
            // Each wallet can pack their signatures in different ways,
            // so we need to send the payload ...
            address[] memory _guardians = getGuardians();

            for (uint256 i = 0; i < guardianCount; ) {
                address guardian = _guardians[i];
                // We check if the guardian is a smart contract wallet ...
                if (guardian.code.length > 0) {
                    if (
                        IEIP1271(guardian).isValidSignature(
                            dataHash,
                            signatures
                        ) == 0x1626ba7e
                    ) _isGuardian = true;
                }
                unchecked {
                    // Won't overflow ...
                    ++i;
                }
            }
        }
        if (!_isGuardian) revert SSR__verifyOwnerAndGuardian__notGuardian();
    }

    /**
     * @dev Verifies that the signatures correspond to the recovery owner and guardian.
     * The first signature needs to match the recovery owner.
     */
    function verifyRecoveryOwnerAndGurdian(
        bytes32 dataHash,
        bytes calldata signatures
    ) internal view {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // The guardian can be an EOA or smart contract wallet ...
        if (signatures.length < 130)
            revert SSR__verifyRecoveryOwnerAndGurdian__invalidSignature();

        // The first signer needs to be the recovery owner ...
        (r, s, v) = splitSigs(signatures, 0);
        address _isRecoveryOwner = returnSigner(dataHash, r, s, v);
        if (_isRecoveryOwner != recoveryOwner)
            revert SSR__verifyRecoveryOwnerAndGurdian__notRecoveryOwner();

        // The second signer needs to be the guardian ...
        // We first check if the guardian is a regular EOA ...
        bool _isGuardian;
        address recoveredGuardian = returnSigner(dataHash, r, s, v);
        if (guardians[recoveredGuardian] != address(0)) {
            _isGuardian = true;
        } else {
            // Else, the guardian can be a smart contract wallet ...
            // Each wallet can pack their signatures in different ways,
            // so we need to send the payload ...
            address[] memory _guardians = getGuardians();

            for (uint256 i = 0; i < guardianCount; ) {
                address guardian = _guardians[i];
                // We check if the guardian is a smart contract wallet ...
                if (guardian.code.length > 0) {
                    if (
                        IEIP1271(guardian).isValidSignature(
                            dataHash,
                            signatures
                        ) == 0x1626ba7e
                    ) _isGuardian = true;
                }
                unchecked {
                    // Won't overflow ...
                    ++i;
                }
            }
        }
        if (!_isGuardian)
            revert SSR__verifyRecoveryOwnerAndGurdian__notGuardian();
    }

    /**
     * @dev Verifies that the signatures correspond to the owner and recovery owner.
     * The first signature needs to match the owner.
     */
    function verifyOwnerAndRecoveryOwner(
        bytes32 dataHash,
        bytes memory signatures
    ) internal view {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Both, the owner and recovery owner must be EOA's ....
        if (signatures.length != 130)
            revert SSR__verifyOwnerAndRecoveryOwner__invalidSignature();

        // The first signer needs to be the owner ...
        (r, s, v) = splitSigs(signatures, 0);
        address _isOwner = returnSigner(dataHash, r, s, v);
        if (_isOwner != owner)
            revert SSR__verifyOwnerAndRecoveryOwner__notOwner();

        // The second signer needs to be the recovery owner ...
        (r, s, v) = splitSigs(signatures, 1);
        address _isRecoveryOwner = returnSigner(dataHash, r, s, v);
        if (_isRecoveryOwner != recoveryOwner)
            revert SSR__verifyOwnerAndRecoveryOwner__notRecoveryOwner();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

/**
 * @title IERC165
 * @notice Support of ERC165.
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceID The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     * @return `true` if the contract implements `interfaceID` and
     * interfaceID` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title ISingleton
 * @notice Has all the external functions, events and errors for Singleton.sol.
 */

interface ISingleton {
    event SingletonChanged(address indexed newSingleton);

    ///@dev upgradeSingleton() custom errors.
    error Singleton__upgradeSingleton__incorrectAddress();
    error Singleton__upgradeSingleton__notLaser();

    /**
     * @dev Migrates to a new singleton (implementation).
     * @param singleton New implementation address.
     */
    function upgradeSingleton(address singleton) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title SelfAuthorized - authorizes current contract to perform actions.
 */
contract SelfAuthorized {
    error SelfAuthorized__notWallet();

    modifier authorized() {
        if (msg.sender != address(this)) revert SelfAuthorized__notWallet();

        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title IHandler
 * @notice Has all the external functions for Handler.sol.
 */
interface IHandler {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4);

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4 result);

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4 result);

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

import "../interfaces/IOwner.sol";
import "./SelfAuthorized.sol";

/**
 * @title Owner
 * @notice Handles the owners addresses.
 */
contract Owner is IOwner, SelfAuthorized {
    ///@dev owner should always bet at storage slot 2.
    address public owner;

    ///@dev recovery owner should always be at storage slot 3.
    address public recoveryOwner;

    /**
     * @dev Changes the owner of the wallet.
     * @param newOwner The address of the new owner.
     */
    function changeOwner(address newOwner) external authorized {
        if (newOwner.code.length != 0 || newOwner == address(0))
            revert Owner__changeOwner__invalidOwnerAddress();
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }

    /**
     * @dev Changes the recoveryOwner address. Only the owner can call this function.
     * @param newRecoveryOwner The new recovery owner address.
     */
    function changeRecoveryOwner(address newRecoveryOwner) external authorized {
        recoveryOwner = newRecoveryOwner;
        if (newRecoveryOwner.code.length != 0 || newRecoveryOwner == address(0))
            revert Owner__changeRecoveryOwner__invalidRecoveryOwnerAddress();
        emit NewRecoveryOwner(recoveryOwner);
    }

    /**
     * @dev Inits the owner. This can only be called at creation.
     * @param _owner The owner of the wallet.
     * @param _recoveryOwner Recovery owner in case the owner looses the main device. Implementation of Sovereign Social Recovery.
     */
    function initOwners(address _owner, address _recoveryOwner) internal {
        // If owner is not address0, the wallet was already initialized...
        if (owner != address(0)) revert Owner__initOwner__walletInitialized();
        checkParams(_owner, _recoveryOwner);
        owner = _owner;
        recoveryOwner = _recoveryOwner;
    }

    /**
     * @dev Checks that the parameters are in bounds.
     * @param _owner The owner of the wallet.
     * @param _recoveryOwner Recovery owner in case the owner looses the main device. Implementation of Sovereign Social Recovery.
     */
    function checkParams(address _owner, address _recoveryOwner) internal view {
        if (_owner.code.length != 0 || _owner == address(0))
            revert Owner__initOwner__invalidOwnerAddress();

        if (_recoveryOwner.code.length != 0 || _recoveryOwner == address(0))
            revert Owner__initOwner__invalidRecoveryOwnerAddress();
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title IEIP1271
 * @notice Interface to call external contracts to validate signature.
 */
interface IEIP1271 {
    /**
     * @dev Implementation of EIP 1271: https://eips.ethereum.org/EIPS/eip-1271.
     * @param hash Hash of a message signed on behalf of address(this).
     * @param signature Signature byte array associated with _msgHash.
     * @return Magic value  or reverts with an error message.
     */
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4);
}

pragma solidity 0.8.15;

/**
 * @title ISSR
 * @notice Has all the external functions, structs, events and errors for SSR.sol.
 */
interface ISSR {
    ///@dev Determines who has access to call a specific function.
    enum Access {
        Owner,
        Guardian,
        OwnerAndGuardian,
        RecoveryOwnerAndGuardian,
        OwnerAndRecoveryOwner
    }

    event WalletLocked();
    event WalletUnlocked();
    event RecoveryUnlocked();
    event NewGuardian(address newGuardian);
    event GuardianRemoved(address removedGuardian);
    event WalletRecovered(address newOwner, address newRecoveryOwner);

    ///@dev addGuardian() custom errors.
    error SSR__addGuardian__invalidAddress();

    ///@dev removeGuardian() custom errors.
    error SSR__removeGuardian__invalidAddress();
    error SSR__removeGuardian__incorrectPreviousGuardian();
    error SSR__removeGuardian__underflow();

    ///@dev initGuardians() custom errors.
    error SSR__initGuardians__zeroGuardians();
    error SSR__initGuardians__invalidAddress();

    ///@dev access() custom errors.
    error SSR__access__guardiansBlocked();
    error SSR__access__walletLocked();

    ///@dev verifyOwner() custom errors.
    error SSR__verifyOwner__invalidSignature();
    error SSR__verifyOwner__notOwner();

    ///@dev verifyGuardian() custom errors.
    error SSR__verifyGuardian__invalidSignature();
    error SSR__verifyGurdian__notGuardian();

    ///@dev verifyOwnerAndGuardian() custom errors.
    error SSR__verifyOwnerAndGuardian__invalidSignature();
    error SSR__verifyOwnerAndGuardian__notOwner();
    error SSR__verifyOwnerAndGuardian__notGuardian();

    ///@dev verifyRecoveryOwnerAndGurdian() custom errors.
    error SSR__verifyRecoveryOwnerAndGurdian__invalidSignature();
    error SSR__verifyRecoveryOwnerAndGurdian__notRecoveryOwner();
    error SSR__verifyRecoveryOwnerAndGurdian__notGuardian();

    ///@dev verifyOwnerAndRecoveryOwner() custom errors.
    error SSR__verifyOwnerAndRecoveryOwner__invalidSignature();
    error SSR__verifyOwnerAndRecoveryOwner__notOwner();
    error SSR__verifyOwnerAndRecoveryOwner__notRecoveryOwner();

    /**
     * @dev Locks the wallet. Can only be called by a guardian.
     */
    function lock() external;

    /**
     * @dev Unlocks the wallet. Can only be called by a guardian + the owner.
     */
    function unlock() external;

    /**
     * @dev Unlocks the wallet. Can only be called by the recovery owner + the owner.
     * This is to avoid the wallet being locked forever if a guardian misbehaves.
     * The guardians will be locked until the owner decides otherwise.
     */
    function recoveryUnlock() external;

    /**
     * @dev Unlocks the guardians. This can only be called by the owner.
     */
    function unlockGuardians() external;

    /**
     * @dev Can only recover with the signature of the recovery owner and guardian.
     * @param newOwner The new owner address. This is generated instantaneously.
     * @param newRecoveryOwner The new recovery owner address. This is generated instantaneously.
     * @notice The newOwner and newRecoveryOwner key pair should be generated from the mobile device.
     * The main reason of this is to restart the generation process in case an attacker has the current recoveryOwner.
     */
    function recover(address newOwner, address newRecoveryOwner) external;

    /**
     * @dev Adds a guardian to the wallet.
     * @param newGuardian Address of the new guardian.
     * @notice Can only be called by the owner.
     */
    function addGuardian(address newGuardian) external;

    /**
     * @dev Removes a guardian to the wallet.
     * @param prevGuardian Address of the previous guardian in the linked list.
     * @param guardianToRemove Address of the guardian to be removed.
     * @notice Can only be called by the owner.
     */
    function removeGuardian(address prevGuardian, address guardianToRemove)
        external;

    /**
     * @param guardian Requested address.
     * @return Boolean if the address is a guardian of the current wallet.
     */
    function isGuardian(address guardian) external view returns (bool);

    /**
     * @return Array of guardians of this.
     */
    function getGuardians() external view returns (address[] memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title Utils - Helper functions for LaserWallet.
 */
contract Utils {
    error Utils__InvalidSignature();

    /**
     * @dev Returns the signer of the hash.
     * @param dataHash The hash that was signed.
     */
    function returnSigner(
        bytes32 dataHash,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) public pure returns (address signer) {
        if (v > 30) {
            signer = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        dataHash
                    )
                ),
                v - 4,
                r,
                s
            );
        } else {
            signer = ecrecover(dataHash, v, r, s);
        }
        if (signer == address(0)) revert Utils__InvalidSignature();
    }

    /**
     * @dev Returns the r, s and v of the signature.
     * @param signature Signature.
     * @param pos Which signature to read.
     */
    function splitSigs(bytes memory signature, uint256 pos)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        assembly {
            let sigPos := mul(0x41, pos)
            r := mload(add(signature, add(sigPos, 0x20)))
            s := mload(add(signature, add(sigPos, 0x40)))
            v := byte(0, mload(add(signature, add(sigPos, 0x60))))
        }
    }

    /**
     * @dev Calls a target address, sends value and / or data payload.
     * @param to Destination address.
     * @param value Amount to send in ETH.
     * @param data Data payload.
     * @param txGas Amount of gas to forward.
     */
    function _call(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            // We execute a call to the target address and return boolean...
            success := call(
                txGas,
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
    }

    /**
     * @dev Calculates the gas price.
     */
    function calculateGasPrice(
        uint256 maxFeePerGas,
        uint256 maxPriorityFeePerGas
    ) internal view returns (uint256 gasPrice) {
        if (maxFeePerGas == maxPriorityFeePerGas) {
            // Legacy mode.
            gasPrice = maxFeePerGas;
        } else {
            gasPrice = min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.15;

/**
 * @title IOwner
 * @notice Has all the external functions, events and errors for Owner.sol.
 */
interface IOwner {
    event OwnerChanged(address newOwner);

    ///@dev changeOwner() custom error.
    error Owner__changeOwner__invalidOwnerAddress();

    ///@dev changeRecoveryOwner() custom error.
    error Owner__changeRecoveryOwner__invalidRecoveryOwnerAddress();

    ///@dev initOwner() custom errors.
    error Owner__initOwner__walletInitialized();
    error Owner__initOwner__invalidOwnerAddress();
    error Owner__initOwner__invalidRecoveryOwnerAddress();
    event NewRecoveryOwner(address recoveryOwner);

    /**
     * @dev Changes the owner of the wallet.
     * @param newOwner The address of the new owner.
     */
    function changeOwner(address newOwner) external;

    /**
     * @dev Changes the recoveryOwner address. Only the owner can call this function.
     * @param newRecoveryOwner The new recovery owner address.
     */
    function changeRecoveryOwner(address newRecoveryOwner) external;
}