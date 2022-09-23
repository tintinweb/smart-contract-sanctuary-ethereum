// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./interfaces/IERC20.sol";
import "./interfaces/IMultiToken.sol";
import "./interfaces/IForwarderFactory.sol";
import "./libraries/Errors.sol";

// This ERC20 forwarder forwards calls through an ERC20-compliant interface
// to move the sub tokens in our multi-token contract. This enables our
// multi-token which are 'ERC1150' like to behave like ERC20 in integrating
// protocols.
// It is a permissionless deployed bridge that is linked to the main contract
// by a create2 deployment validation so MUST be deployed by the right factory.
contract ERC20Forwarder is IERC20 {
    // The contract which contains the actual state for this 'ERC20'
    IMultiToken public immutable token;
    // The ID for this contract's 'ERC20' as a sub token of the main token
    uint256 public immutable tokenId;
    // A mapping to track the permit signature nonces
    mapping(address => uint256) public nonces;
    // EIP712
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /// @notice Constructs this contract by initializing the immutables
    /// @dev To give the contract a constant deploy code hash we call back
    ///      into the factory to load info instead of using calldata.
    constructor() {
        // The deployer is the factory
        IForwarderFactory factory = IForwarderFactory(msg.sender);
        // We load the data we need to init
        (token, tokenId) = factory.getDeployDetails();

        // Computes the EIP 712 domain separator which prevents user signed messages for
        // this contract to be replayed in other contracts.
        // https://eips.ethereum.org/EIPS/eip-712
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(token.name(tokenId))),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @notice Returns the decimals for this 'ERC20', we are opinionated
    ///         so we just return 18 in all cases
    /// @return Always 18
    function decimals() external pure override returns (uint8) {
        return (18);
    }

    /// @notice Returns the name of this sub token by calling into the
    ///         main token to load it.
    /// @return Returns the name of this token
    function name() external view override returns (string memory) {
        return (token.name(tokenId));
    }

    /// @notice Returns the symbol of this sub token by calling into the
    ///         main token to load it.
    /// @return Returns the symbol of this token
    function symbol() external view override returns (string memory) {
        return (token.symbol(tokenId));
    }

    /// @notice Returns the balance of this sub token through an ERC20 compliant
    ///         interface.
    /// @return The balance of the queried account.
    function balanceOf(address who) external view override returns (uint256) {
        return (token.balanceOf(tokenId, who));
    }

    /// @notice Loads the allowance information for an owner spender pair.
    ///         If spender is approved for all tokens in the main contract
    ///         it will return Max(uint256) otherwise it returns the allowance
    ///         the allowance for just this asset.
    /// @param owner The account who's tokens would be spent
    /// @param spender The account who might be able to spend tokens
    /// @return The amount of the owner's tokens the spender can spend
    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        // If the owner is approved for all they can spend an unlimited amount
        if (token.isApprovedForAll(owner, spender)) {
            return type(uint256).max;
        } else {
            // otherwise they can only spend up the their per token approval for
            // the owner
            return token.perTokenApprovals(tokenId, owner, spender);
        }
    }

    /// @notice Sets an approval for just this sub-token for the caller in the main token
    /// @param spender The address which can spend tokens of the caller
    /// @param amount The amount which the spender is allowed to spend, if it is
    ///               set to uint256.max it is infinite and will not be reduced by transfer.
    /// @return True if approval successful, false if not. The contract also reverts
    ///         on failure so only true is possible.
    function approve(address spender, uint256 amount) external returns (bool) {
        // The main token handles the internal approval logic
        token.setApprovalBridge(tokenId, spender, amount, msg.sender);
        // Emit a ERC20 compliant approval event
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Forwards a call to transfer from the msg.sender to the recipient.
    /// @param recipient The recipient of the token transfer
    /// @param amount The amount of token to transfer
    /// @return True if transfer successful, false if not. The contract also reverts
    ///         on failed transfer so only true is possible.
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        token.transferFromBridge(
            tokenId,
            msg.sender,
            recipient,
            amount,
            msg.sender
        );
        // Emits an ERC20 compliant transfer event
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Forwards a call to transferFrom to move funds from an owner to a recipient
    /// @param source The source of the tokens to be transferred
    /// @param recipient The recipient of the tokens
    /// @param amount The amount of tokens to be transferred
    /// @return Returns true for success false for failure, also reverts on fail, so will
    ///         always return true.
    function transferFrom(
        address source,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        // The token handles the approval logic checking and transfer
        token.transferFromBridge(
            tokenId,
            source,
            recipient,
            amount,
            msg.sender
        );
        // Emits an ERC20 compliant transfer event
        emit Transfer(source, recipient, amount);
        return true;
    }

    /// @notice This function allows a caller who is not the owner of an account to execute the functionality of 'approve' with the owners signature.
    /// @param owner the owner of the account which is having the new approval set
    /// @param spender the address which will be allowed to spend owner's tokens
    /// @param value the new allowance value
    /// @param deadline the timestamp which the signature must be submitted by to be valid
    /// @param v Extra ECDSA data which allows public key recovery from signature assumed to be 27 or 28
    /// @param r The r component of the ECDSA signature
    /// @param s The s component of the ECDSA signature
    /// @dev The signature for this function follows EIP 712 standard and should be generated with the
    ///      eth_signTypedData JSON RPC call instead of the eth_sign JSON RPC call. If using out of date
    ///      parity signing libraries the v component may need to be adjusted. Also it is very rare but possible
    ///      for v to be other values, those values are not supported.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Require that the signature is not expired
        if (block.timestamp > deadline) revert ElementError.ExpiredDeadline();
        // Require that the owner is not zero
        if (owner == address(0)) revert ElementError.RestrictedZeroAddress();

        bytes32 structHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner],
                        deadline
                    )
                )
            )
        );

        // Check that the signature is valid
        address signer = ecrecover(structHash, v, r, s);
        if (signer != owner) revert ElementError.InvalidSignature();

        // Increment the signature nonce
        nonces[owner]++;
        // Set the approval to the new value
        token.setApprovalBridge(tokenId, spender, value, owner);
        emit Approval(owner, spender, value);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    // Note this is non standard but nearly all ERC20 have exposed decimal functions
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

interface IMultiToken {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    function name(uint256 id) external view returns (string memory);

    function symbol(uint256 id) external view returns (string memory);

    function isApprovedForAll(address owner, address spender)
        external
        view
        returns (bool);

    function perTokenApprovals(
        uint256 tokenId,
        address owner,
        address spender
    ) external view returns (uint256);

    function balanceOf(uint256 tokenId, address owner)
        external
        view
        returns (uint256);

    function transferFrom(
        uint256 tokenID,
        address from,
        address to,
        uint256 amount
    ) external;

    function transferFromBridge(
        uint256 tokenID,
        address from,
        address to,
        uint256 amount,
        address caller
    ) external;

    function setApproval(
        uint256 tokenID,
        address operator,
        uint256 amount
    ) external;

    function setApprovalBridge(
        uint256 tokenID,
        address operator,
        uint256 amount,
        address caller
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "./IMultiToken.sol";

interface IForwarderFactory {
    function getDeployDetails() external returns (IMultiToken, uint256);
}

/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

library ElementError {
    /// ###############
    /// ### General ###
    /// ###############
    error TermExpired();
    error TermNotExpired();
    error TermNotInitialized();
    error PoolInitialized();
    error PoolNotInitialized();
    error ExceededSlippageLimit();
    error RestrictedZeroAddress();
    error ExpiredDeadline();
    error InvalidSignature();

    /// ##################
    /// ### MultiToken ###
    /// ##################
    error InvalidERC20Bridge();
    error BatchInputLengthMismatch();

    /// ############
    /// ### Term ###
    /// ############
    error UnsortedAssetIds();
    error NotAYieldTokenId();
    error ExpirationDateMustBeNonZero();
    error StartDateMustBeNonZero();
    error InvalidYieldTokenCreation();
    error IncongruentPrincipalAndYieldTokenIds();
    error VaultShareReserveTooLow();

    /// ############
    /// ### Pool ###
    /// ############
    error TimeStretchMustBeNonZero();
    error UnderlyingInMustBeNonZero();
    error InaccurateUnlockShareTrade();

    /// ##################
    /// ### TWAROracle ###
    /// ##################
    error TWAROracle_IncorrectBufferLength();
    error TWAROracle_BufferAlreadyInitialized();
    error TWAROracle_MinTimeStepMustBeNonZero();
    error TWAROracle_IndexOutOfBounds();
    error TWAROracle_NotEnoughElements();

    /// ######################
    /// ### FixedPointMath ###
    /// ######################
    error FixedPointMath_AddOverflow();
    error FixedPointMath_SubOverflow();
    error FixedPointMath_InvalidExponent();
    error FixedPointMath_NegativeOrZeroInput();
    error FixedPointMath_NegativeInput();

    /// #####################
    /// ### Authorizable ####
    /// #####################
    error Authorizable_SenderMustBeOwner();
    error Authorizable_SenderMustBeAuthorized();
}