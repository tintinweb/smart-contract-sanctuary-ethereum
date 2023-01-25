// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Inspired by https://github.com/ZeframLou/trustus
abstract contract ReservoirOracle {
    // --- Structs ---

    struct Message {
        bytes32 id;
        bytes payload;
        // The UNIX timestamp when the message was signed by the oracle
        uint256 timestamp;
        // ECDSA signature or EIP-2098 compact signature
        bytes signature;
    }

    // --- Errors ---

    error InvalidMessage();

    // --- Fields ---

    address public RESERVOIR_ORACLE_ADDRESS;

    // --- Constructor ---

    constructor(address reservoirOracleAddress) {
        RESERVOIR_ORACLE_ADDRESS = reservoirOracleAddress;
    }

    // --- Public methods ---

    function updateReservoirOracleAddress(address newReservoirOracleAddress)
        public
        virtual;

    // --- Internal methods ---

    function _verifyMessage(
        bytes32 id,
        uint256 validFor,
        Message memory message
    ) internal view virtual returns (bool success) {
        // Ensure the message matches the requested id
        if (id != message.id) {
            return false;
        }

        // Ensure the message timestamp is valid
        if (
            message.timestamp > block.timestamp ||
            message.timestamp + validFor < block.timestamp
        ) {
            return false;
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract the individual signature fields from the signature
        bytes memory signature = message.signature;
        if (signature.length == 64) {
            // EIP-2098 compact signature
            bytes32 vs;
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
                s := and(
                    vs,
                    0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                v := add(shr(255, vs), 27)
            }
        } else if (signature.length == 65) {
            // ECDSA signature
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else {
            return false;
        }

        address signerAddress = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    // EIP-712 structured-data hash
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Message(bytes32 id,bytes payload,uint256 timestamp)"
                            ),
                            message.id,
                            keccak256(message.payload),
                            message.timestamp
                        )
                    )
                )
            ),
            v,
            r,
            s
        );

        // Ensure the signer matches the designated oracle address
        return signerAddress == RESERVOIR_ORACLE_ADDRESS;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/auth/Owned.sol";
import "reservoir-oracle/ReservoirOracle.sol";

/// @title StolenNftFilterOracle
/// @author out.eth (@outdoteth)
/// @notice A contract to check that a set of NFTs are not stolen.
contract StolenNftFilterOracle is ReservoirOracle, Owned {
    bytes32 private constant TOKEN_TYPE_HASH = keccak256("Token(address contract,uint256 tokenId)");
    uint256 public cooldownPeriod = 0;
    uint256 public validFor = 60 minutes;

    constructor() Owned(msg.sender) ReservoirOracle(0xAeB1D03929bF87F69888f381e73FBf75753d75AF) {}

    /// @notice Sets the cooldown period.
    /// @param _cooldownPeriod The cooldown period.
    function setCooldownPeriod(uint256 _cooldownPeriod) public onlyOwner {
        cooldownPeriod = _cooldownPeriod;
    }

    /// @notice Sets the valid for period.
    /// @param _validFor The valid for period.
    function setValidFor(uint256 _validFor) public onlyOwner {
        validFor = _validFor;
    }

    function updateReservoirOracleAddress(address newReservoirOracleAddress) public override onlyOwner {
        RESERVOIR_ORACLE_ADDRESS = newReservoirOracleAddress;
    }

    /// @notice Checks that a set of NFTs are not stolen.
    /// @param tokenAddress The address of the NFT contract.
    /// @param tokenIds The ids of the NFTs.
    /// @param messages The messages signed by the reservoir oracle.
    function validateTokensAreNotStolen(address tokenAddress, uint256[] calldata tokenIds, Message[] calldata messages)
        public
        view
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            Message calldata message = messages[i];

            // check that the signer is correct and message id matches token id + token address
            bytes32 expectedMessageId = keccak256(abi.encode(TOKEN_TYPE_HASH, tokenAddress, tokenIds[i]));
            require(_verifyMessage(expectedMessageId, validFor, message), "Message has invalid signature");

            (bool isFlagged, uint256 lastTransferTime) = abi.decode(message.payload, (bool, uint256));

            // check that the NFT is not stolen
            require(!isFlagged, "NFT is flagged as suspicious");

            // check that the NFT was not transferred too recently
            require(lastTransferTime + cooldownPeriod < block.timestamp, "NFT was transferred too recently");
        }
    }
}