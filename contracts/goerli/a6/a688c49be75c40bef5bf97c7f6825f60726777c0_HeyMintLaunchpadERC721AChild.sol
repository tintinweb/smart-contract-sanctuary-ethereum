/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// File: contracts/LaunchpadStorage.sol


pragma solidity ^0.8.17;

struct BaseConfig {
    // If true tokens can be minted in the public sale
    bool publicSaleActive;
    // If true tokens can be minted in the presale
    bool presaleActive;
    // If true, all tokens will be soulbound
    bool soulbindingActive;
    // The number of tokens that can be minted in the presale per address
    uint8 presaleMintsAllowedPerAddress;
    // The number of tokens that can be minted in the public sale per address
    uint8 publicMintsAllowedPerAddress;
    // If set, amount of days from contract deploy in which the fundingTarget must be met or funds are refundable
    uint8 fundingDuration;
    // Maximum supply of tokens that can be minted
    uint16 maxSupply;
    // Total number of tokens available for minting in the presale
    uint16 presaleMaxSupply;
    // The price of a token in the public sale in centiETH - e.g. 1 = 0.01 ETH, 100 = 1 ETH - multiply by 10^16 to get correct wei amount
    uint16 publicPrice;
    // The price of a token in the presale in centiETH - e.g. 1 = 0.01 ETH, 100 = 1 ETH - multiply by 10^16 to get correct wei amount
    uint16 presalePrice;
    // The royalty payout percentage in basis points
    uint16 royaltyBps;
    // Used to create a default HeyMint Launchpad URI for token metadata to save gas over setting a custom URI and increase fetch reliability
    uint24 projectId;
    // The amount of centiETH that must be raised in fundingDuration seconds since contract deploy or funds are refundable
    uint24 fundingTarget;
    // The base URI for all token metadata
    string uriBase;
}

// Ordered such that if only burning is enabled, the struct will be 32 bytes and save 20k units of gas
struct AdvancedConfig {
    // Permanently freezes payout addresses and basis points so they can never be updated
    bool payoutAddressesFrozen;
    // Permanently freezes metadata so it can never be changed
    bool metadataFrozen;
    // If true the soulbind admin address is permanently disabled
    bool soulbindAdminTransfersPermanentlyDisabled;
    // When false, tokens cannot be staked but can still be unstaked
    bool stakingActive;
    // When false, tokens cannot be loaned but can still be retrieved
    bool loaningActive;
    // If true tokens can be claimed for free
    bool freeClaimActive;
    // The number of tokens that can be minted per free claim
    uint8 mintsPerFreeClaim;
    // Optional address of an NFT that is eligible for free claim
    address freeClaimContractAddress;
    // Optional address of an NFT that can be burned in order to mint
    address burnToMintContractAddress;
    // If true tokens can be burned in order to mint
    bool burnClaimActive;
    // The number of tokens that can be minted per NFT burned
    uint8 mintsPerBurn;
    // 0 = no contract, 1 = ERC-721, 2 = ERC-1155
    uint8 burnToMintContractType;
    // The id of the NFT on an ERC-1155 contract that can be burned to mint
    uint16 burnToMintTokenId;
}

struct AddressConfig {
    // The respective share of funds to be sent to each address in payoutAddresses in basis points
    uint16[] payoutBasisPoints;
    // The addresses to which funds are sent when a token is sold. If empty, funds are sent to the contract owner.
    address[] payoutAddresses;
    // Optional address where royalties are paid out. If not set, royalties are paid to the contract owner.
    address royaltyPayoutAddress;
    // Used to allow transferring soulbound tokens with admin privileges. Defaults to the contract owner if not set.
    address soulboundAdminAddress;
    // If set, will override the defaultPresaleSignerAddress
    address presaleSignerAddress;
}

struct Data {
    // ============ EXCHANGE BLOCKLIST ============
    // If true, the exchange represented by a uint256 integer is blocklisted and cannot be used to transfer tokens
    mapping(uint256 => bool) isExchangeBlocklisted;
    // ============ CONDITIONAL FUNDING ============
    // Used in conjunction with fundingDuration and refundDuration to track time since contract deploy
    uint256 contractDeployTime;
    // If true, the funding target was reached and funds are not refundable
    bool fundingTargetReached;
    // If true, funding success has been determined and determineFundingSuccess() can no longer be called
    bool fundingSuccessDetermined;
    // A mapping of token ID to price paid for the token
    mapping(uint256 => uint256) pricePaid;
    // ============ SOULBINDING ============
    // Used to allow an admin to transfer soulbound tokens when necessary
    bool soulboundAdminTransferInProgress;
    // ============ STAKING ============
    // Used to allow direct transfers of staked tokens without unstaking first
    bool stakingTransferActive;
    // Returns the UNIX timestamp at which a token began staking if currently staked
    mapping(uint256 => uint256) currentTimeStaked;
    // Returns the total time a token has been staked in seconds, not counting the current staking time if any
    mapping(uint256 => uint256) totalTimeStaked;
    // ============ LOANING ============
    // Used to keep track of the total number of tokens on loan
    uint256 currentLoanIndex;
    // Returns the total number of tokens loaned by an address
    mapping(address => uint256) totalLoanedPerAddress;
    // Returns the address of the original token owner if a token is currently on loan
    mapping(uint256 => address) tokenOwnersOnLoan;
    // ============ FREE CLAIM ============
    // If true token has already been used to claim and cannot be used again
    mapping(uint256 => bool) freeClaimUsed;
}

library LaunchpadStorage {
    struct State {
        BaseConfig cfg;
        AdvancedConfig advCfg;
        AddressConfig addrCfg;
        Data data;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('heymint.launchpad.storage.erc721a');

    function state() internal pure returns (State storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// File: contracts/HeyMintLaunchpadERC721ADelegated.sol


pragma solidity ^0.8.17;



contract HeyMintLaunchpadERC721ADelegated {
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // Reference to base NFT implementation
    function implementation() public view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _initImplementation(address _nftImplementation) private {
        StorageSlotUpgradeable
        .getAddressSlot(_IMPLEMENTATION_SLOT)
        .value = _nftImplementation;
    }

    /**
     * @notice Initializes the child contract with the base implementation address and the configuration settings
     * @param _nftImplementation The address of the base implementation contract
     * @param _name The name of the NFT
     * @param _symbol The symbol of the NFT
     */
    constructor(
        address _nftImplementation,
        string memory _name,
        string memory _symbol,
        BaseConfig memory _baseConfig
    ) {
        _initImplementation(_nftImplementation);
        (bool success, ) = _nftImplementation.delegatecall(
            abi.encodeWithSignature(
                'initialize(address,string,string,(bool,bool,bool,uint8,uint8,uint8,uint16,uint16,uint16,uint16,uint16,uint24,uint24,string))',
                msg.sender,
                _name,
                _symbol,
                _baseConfig
            )
        );
        require(success);
    }

    /**
     * @dev Delegates the current call to nftImplementation
     *
     * This function does not return to its internal call site - it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        address impl = implementation();

        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }
}

// File: contracts/HeyMintLaunchpadERC721AChild.sol


pragma solidity ^0.8.17;


struct BasicInfo {
    address baseContract;
    string name;
    string symbol;
}

contract HeyMintLaunchpadERC721AChild is HeyMintLaunchpadERC721ADelegated {
    constructor(BasicInfo memory _basicInfo, BaseConfig memory _baseConfig)
        HeyMintLaunchpadERC721ADelegated(
            _basicInfo.baseContract,
            _basicInfo.name,
            _basicInfo.symbol,
            _baseConfig
        )
    {}
}