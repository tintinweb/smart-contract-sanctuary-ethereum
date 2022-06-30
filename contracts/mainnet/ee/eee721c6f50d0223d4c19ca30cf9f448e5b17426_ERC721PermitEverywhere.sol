// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

/// @title ERC721PermitEverywhere
/// @notice Enables permit-style approvals for all ERC721 tokens.
contract ERC721PermitEverywhere {
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable TRANSFER_PERMIT_TYPEHASH;

    // Permit message to be consumed by executePermitTransferFrom() or
    // executePermitSafeTransferFrom().
    struct PermitTransferFrom {
        // The token being spent.
        IERC721 token;
        // Who is allowed to execute/burn the permit message.
        address spender;
        // The token ID of `token` `spender` can transfer.
        uint256 tokenId;
        // If true, `spender` may transfer any token ID and `tokenId` is ignored.
        bool allowAnyTokenId;
        // The timestamp beyond which this permit is no longer valid.
        uint256 deadline;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /// @notice The current nonce for a signer. This value will be incremented
    ///         for each executed permit message.
    /// @dev Owner -> current nonce.
    mapping(address => uint256) public currentNonce;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
            keccak256(bytes('ERC721PermitEverywhere')),
            keccak256('1.0.0'),
            block.chainid,
            address(this)
        ));
        TRANSFER_PERMIT_TYPEHASH =
            keccak256('PermitTransferFrom(address token,address spender,uint256 tokenId,bool allowAnyTokenId,uint256 deadline,uint256 nonce)');
    }

    /// @notice Increase sender's nonce by `increaseAmount`. This will effectively
    ///         cancel any outstanding permits signed with a nonce lower than the
    ///         final value.
    function increaseNonce(uint256 increaseAmount) external {
        currentNonce[msg.sender] += increaseAmount;
    }

    /// @notice Execute a signed permit message to transfer ERC721 tokens
    ///         on behalf of the signer using IERC721.transferFrom().
    ///         The signer's nonce will be incremented during execution,
    ///         preventing the message from being used again.
    /// @param from Permit signer.
    /// @param to Recipient of the token.
    /// @param tokenId ID of the token to transfer.
    /// @param permit Permit message.
    /// @param sig Signature for permit message, signed by `from`.
    function executePermitTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        PermitTransferFrom calldata permit,
        Signature calldata sig
    )
        external
    {
        _consumePermit(from, tokenId, permit, sig);
        permit.token.transferFrom(from, to, tokenId);
    }

    /// @notice Execute a signed permit message to transfer ERC721 tokens
    ///         on behalf of the signer using IERC721.safeTransferFrom().
    ///         The signer's nonce will be incremented during execution,
    ///         preventing the message from being used again.
    /// @param from Permit signer.
    /// @param to Recipient of the token.
    /// @param tokenId ID of the token to transfer.
    /// @param permit Permit message.
    /// @param sig Signature for permit message, signed by `from`.
    function executePermitSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data,
        PermitTransferFrom calldata permit,
        Signature calldata sig
    )
        external
    {
        _consumePermit(from, tokenId, permit, sig);
        permit.token.safeTransferFrom(from, to, tokenId, data);
    }

    /// @notice Compute the EIP712 hash of a permit message.
    function hashPermit(PermitTransferFrom memory permit, uint256 nonce)
        public
        view
        returns (bytes32 hash)
    {
        bytes32 domainSeparator = DOMAIN_SEPARATOR;
        bytes32 typeHash = TRANSFER_PERMIT_TYPEHASH;
        assembly {
            // Hash the permit message in-place to compute the struct hash.
            if lt(permit, 0x20)  {
                invalid()
            }
            // Overwrite the words above and below the permit object temporarily.
            let wordAbove := mload(sub(permit, 0x20))
            let wordBelow := mload(add(permit, 0xA0))
            mstore(sub(permit, 0x20), typeHash)
            mstore(add(permit, 0xA0), nonce)
            let structHash := keccak256(sub(permit, 0x20), 0xE0)
            // Restore overwritten words.
            mstore(sub(permit, 0x20), wordAbove)
            mstore(add(permit, 0xA0), wordBelow)

            // 0x40 will be overwritten temporarily.
            let memPointer := mload(0x40)
            // Hash the domain separator and struct hash to compute the final EIP712 hash.
            mstore(0x00, 0x1901000000000000000000000000000000000000000000000000000000000000)
            mstore(0x02, domainSeparator)
            mstore(0x22, structHash)
            hash := keccak256(0x00, 0x42)
            // Restore 0x40.
            mstore(0x40, memPointer)
        }
    }

    // Validate and burn a permit message.
    function _consumePermit(
        address from,
        uint256 tokenId,
        PermitTransferFrom calldata permit,
        Signature calldata sig
    )
        private
    {
        require(msg.sender == permit.spender, 'SPENDER_NOT_PERMITTED');
        require(permit.allowAnyTokenId || permit.tokenId == tokenId, 'TOKEN_ID_NOT_PERMITTED');
        require(permit.deadline >= block.timestamp, 'PERMIT_EXPIRED');

        require(
            from == _getSigner(hashPermit(permit, currentNonce[from]++), sig),
            'INVALID_SIGNER'
        );
    }

    function _getSigner(bytes32 hash, Signature memory sig) private pure returns (address signer) {
        signer = ecrecover(hash, sig.v, sig.r, sig.s);
        require(signer != address(0), 'INVALID_SIGNATURE');
    }
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
}