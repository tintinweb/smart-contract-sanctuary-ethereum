/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
// File: contracts/ValidatorPool.sol


pragma solidity ^0.8.4;

/**
 * @title Validator Pool
 * @author Ape Toshi
 * @notice Initial validators are managed by the DAO.
 * @custom:security-contact [email protected]
 */
abstract contract ValidatorPool {
    // ========== Events ==========
    event MinBlocksUpdate(uint256 newMinBlocks);
    event MinSignaturesUpdate(uint256 newMinSignatures);
    event ValidatorsUpdate(address[] newValidators);

    uint256 public minBlocks;
    uint256 public minSignatures;

    // Trusted oracle network
    address[] public validators;

    constructor(
        uint256 _minBlocks,
        uint256 _minSignatures,
        address[] memory _validators
    ) {
        _configMinBlocks(_minBlocks);
        _configMinSignatures(_minSignatures);
        _configValidators(_validators);
    }

    /// @dev Only trusted addresses can be validators.
    function _configValidators(address[] memory newValidators)
        internal
        virtual
    {
        require(newValidators.length >= minSignatures);
        validators = newValidators;
        emit ValidatorsUpdate(newValidators);
    }

    /// @dev For security purposes, should be at least 50%.
    function _configMinSignatures(uint256 newMinSignatures) internal {
        minSignatures = newMinSignatures;
        emit MinSignaturesUpdate(newMinSignatures);
    }

    /// @dev This is a trade-off between safety and UX. Default to 32.
    function _configMinBlocks(uint256 newMinBlocks) internal {
        minBlocks = newMinBlocks;
        emit MinBlocksUpdate((newMinBlocks));
    }

    // ========== Can be called by any address ==========

    /**
     * @dev Verify if a cross-chain token bridge request is valid.
     * @param txnHash The bytes32 hash of the transaction.
     * @param fromChainId The origin EVM chain ID.
     * @param toChainId The destination EVM chain ID.
     * @param fromTokenAddress The address of the token on the home chain.
     * @param toTokenAddress The address of the token on the foreign chain.
     * @param account The address of the account.
     * @param amount The amount of tokens to bridge.
     * @param ascendingValidatorIds Validator Id array in ascending order
     * @param validatorSignatures Array of validator signatures
     */
    function _isValid(
        bytes32 txnHash,
        uint256 fromChainId,
        uint256 toChainId,
        address fromTokenAddress,
        address toTokenAddress,
        address account,
        uint256 amount,
        uint256[] calldata ascendingValidatorIds,
        bytes[] memory validatorSignatures
    ) internal view returns (bool) {
        require(
            _checkAscendingValidatorIds(ascendingValidatorIds),
            "Invalid Validator ID array"
        );
        require(
            validatorSignatures.length >= minSignatures,
            "Not enough signatures"
        );
        require(
            validatorSignatures.length == ascendingValidatorIds.length,
            "Signature and validator arrays have to match"
        );
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                txnHash,
                fromChainId,
                toChainId,
                fromTokenAddress,
                toTokenAddress,
                account,
                amount
            )
        );
        bytes32 ethSignedMessageHash = _getEthSignedMessageHash(messageHash);

        address validator;
        uint256 id;
        for (uint256 i; i < minSignatures; ) {
            id = ascendingValidatorIds[i];
            validator = validators[id];
            if (
                !_verifySigner(
                    ethSignedMessageHash,
                    validatorSignatures[i],
                    validator
                )
            ) {
                return false;
            }

            unchecked {
                i++;
            }
        }
        return true;
    }

    // ========== Helper functions ==========

    /**
     * @notice Signature is produced by signing a keccak256 hash with the following format:
     * "\x19Ethereum Signed Message\n" + len(msg) + msg
     */
    function _getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /// @dev Recover the signer address from `ethSignedMessageHash`.
    function _recoverSigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);

        return ecrecover(ethSignedMessageHash, v, r, s);
    }

    /// @dev Split a `signature` into `r`, `s` and `v` values.
    function _splitSignature(bytes memory signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(signature.length == 65, "invalid signature length");

        assembly {
            /// @dev First 32 bytes stores the length of the signature

            /// @dev add(sig, 32) = pointer of sig + 32
            /// @dev Effectively, skips first 32 bytes of signature

            /// @dev mload(p) loads next 32 bytes starting at the memory address p into memory

            /// @dev First 32 bytes, after the length prefix
            r := mload(add(signature, 32))
            /// @dev Second 32 bytes
            s := mload(add(signature, 64))
            /// @dev Final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        }

        // Implicitly return (r, s, v)
    }

    /// @dev Verify if `signature` on `ethSignedMessageHash` was signed by `signer`.
    function _verifySigner(
        bytes32 ethSignedMessageHash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool) {
        return _recoverSigner(ethSignedMessageHash, signature) == signer;
    }

    /**
     * @dev Checks if array is sorted in ascending order such that
     * every element is unique and not greater than 5 (6th validator).
     */
    function _checkAscendingValidatorIds(
        uint256[] calldata ascendingValidatorIds
    ) internal view returns (bool) {
        uint256 first;
        uint256 second;
        for (uint256 i = 1; i < ascendingValidatorIds.length; ) {
            first = ascendingValidatorIds[i - 1];
            second = ascendingValidatorIds[i];
            /// Array has to be sorted in ascending order, 0 to last one
            if (second <= first || second > (validators.length - 1)) {
                return false;
            }

            unchecked {
                i++;
            }
        }
        return true;
    }
}

// File: contracts/DAOController.sol


pragma solidity ^0.8.4;

abstract contract DAOController {
    address public immutable DAO_MULTISIG;

    constructor(address _DAO_MULTISIG) {
        DAO_MULTISIG = _DAO_MULTISIG;
    }

    modifier onlyDAO() {
        require(msg.sender == DAO_MULTISIG, "Only DAO");
        _;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// File: contracts/DAOSafety.sol


pragma solidity ^0.8.4;





abstract contract DAOSafety is DAOController, Pausable {
    // ========== Events ==========
    event EmergencyTokenTransfer(
        address indexed tokenAddress,
        uint256 indexed amount
    );
    event EmergencyNftTransfer(
        address indexed tokenAddress,
        uint256 indexed tokenId
    );
    event EmergencyNativeTransfer(uint256 indexed amount);

    event DevsUpdate(address account, bool state);

    // ========== Public variables ==========

    mapping(address => bool) public devsAllowed;

    constructor(address _DAO_MULTISIG) DAOController(_DAO_MULTISIG) {}

    modifier onlyDevs() {
        require(
            msg.sender == DAO_MULTISIG || devsAllowed[msg.sender],
            "Only devs"
        );
        _;
    }

    function configDevs(address account, bool state) external onlyDAO {
        devsAllowed[account] = state;
        emit DevsUpdate(account, state);
    }

    // ========== Make room for potential human errors (made by others) ==========
    function emergencyTokenTransfer(address tokenAddress, uint256 amount)
        external
        onlyDAO
    {
        require(IERC20(tokenAddress).transfer(msg.sender, amount));
        emit EmergencyTokenTransfer(tokenAddress, amount);
    }

    function withdrawNative() external onlyDAO {
        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Unable to withdraw native token");
        emit EmergencyNativeTransfer(amount);
    }

    function withdrawNft(address tokenAddress, uint256 tokenId)
        external
        onlyDAO
    {
        IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
        emit EmergencyNftTransfer(tokenAddress, tokenId);
    }

    // ========== In case of other unforeseen events ==========

    // Dev wallets can hit the brakes faster than a multisig
    function pause() external onlyDevs {
        _pause();
    }

    function unpause() external onlyDAO {
        _unpause();
    }
}

// File: contracts/CentralHub.sol


pragma solidity ^0.8.4;






contract CentralHub is DAOSafety, ReentrancyGuard, ValidatorPool {
    // ========== Events ==========
    event ForeignTokenAddressesUpdate(
        address indexed homeTokenAddress,
        uint256 indexed chainId,
        address indexed foreignTokenAddress
    );
    event ForeignDeliveryRequest(
        address indexed account,
        address indexed homeTokenAddress,
        uint256 amount,
        uint256 indexed toChainId
    );
    event ForeignDeliveryFulfill(
        address indexed account,
        address indexed homeTokenAddress,
        uint256 amount,
        uint256 indexed fromChainId
    );
    // ========== Public variables ==========
    mapping(bytes32 => bool) public txnHashes;
    mapping(address => mapping(uint256 => address))
        public foreignTokenAddresses;

    // ========== Private/internal variables ==========
    uint256 internal immutable HOME_CHAIN_ID;

    constructor(
        uint256 _HOME_CHAIN_ID,
        address _DAO_MULTISIG,
        uint256 _minBlocks,
        uint256 _minSignatures,
        address[] memory _validators
    )
        DAOSafety(_DAO_MULTISIG)
        ValidatorPool(_minBlocks, _minSignatures, _validators)
    {
        HOME_CHAIN_ID = _HOME_CHAIN_ID;
    }

    // ========== External functions ==========

    // tokenAddress on this chain
    // ERC20 needs to be approved first!
    function exportToken(
        address account,
        address homeTokenAddress,
        uint256 amount,
        uint256 toChainId
    ) external whenNotPaused nonReentrant {
        address foreignTokenAddress = foreignTokenAddresses[homeTokenAddress][
            toChainId
        ];

        require(foreignTokenAddress != address(0), "Token not portable");
        require(
            IERC20(homeTokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Balance too low or not approved"
        );
        emit ForeignDeliveryRequest(
            account,
            homeTokenAddress,
            amount,
            toChainId
        );
    }

    // tokenAddress on this chain
    function importToken(
        bytes32 txnHash,
        uint256 fromChainId,
        address account,
        address homeTokenAddress,
        uint256 amount,
        uint256[] calldata ascendingValidatorIds,
        bytes[] memory validatorSignatures
    ) external whenNotPaused nonReentrant {
        require(!txnHashes[txnHash], "Already imported");
        txnHashes[txnHash] = true;
        // token address on bridged chain

        address foreignTokenAddress = foreignTokenAddresses[homeTokenAddress][
            fromChainId
        ];

        require(foreignTokenAddress != address(0), "Token not portable");

        bool valid = _isValid(
            txnHash,
            fromChainId,
            HOME_CHAIN_ID,
            foreignTokenAddress,
            homeTokenAddress,
            account,
            amount,
            ascendingValidatorIds,
            validatorSignatures
        );
        require(valid, "Validation failed");

        // Fulfill request
        require(
            IERC20(homeTokenAddress).transfer(account, amount),
            "Unable to fulfill request" // This should never happen
        );
        emit ForeignDeliveryFulfill(
            account,
            homeTokenAddress,
            amount,
            fromChainId
        );
    }

    // ========== Only DAO ==========

    function configForeignTokenAddress(
        address homeTokenAddress,
        uint256 chainId,
        address foreignTokenAddress
    ) external onlyDAO {
        foreignTokenAddresses[homeTokenAddress][chainId] = foreignTokenAddress;
        emit ForeignTokenAddressesUpdate(
            homeTokenAddress,
            chainId,
            foreignTokenAddress
        );
    }

    /// @dev Only trusted addresses can be validators.
    function configValidators(address[] memory newValidators) external onlyDAO {
        _configValidators(newValidators);
    }

    /// @dev For security purposes, has to be at least 3/6. Default to 4/6.
    function configMinSignatures(uint256 newMinSignatures) external onlyDAO {
        _configMinSignatures(newMinSignatures);
    }

    /// @dev This is a trade-off between safety and UX. Default to 32.
    function configMinBlocks(uint256 newMinBlocks) external onlyDAO {
        _configMinBlocks(newMinBlocks);
    }
}