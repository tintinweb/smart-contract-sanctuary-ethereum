// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import { IFukuGetter } from "../interfaces/facets/IFukuGetter.sol";
import { FukuStorage, EIP712Domain, FukuOptionExchangeStorage, FukuTokenizedOptionsStorage } from "../libraries/FukuStorage.sol";

contract FukuGetterFacet is IFukuGetter {
    /**
     * @notice Gets the contract name used for the domain separator
     *
     * @return The contract name
     */
    function getContractName() external view override returns (string memory) {
        EIP712Domain storage domain = FukuStorage.eip712Domain();

        return domain.name;
    }

    /**
     * @notice Gets the contract version used for the domain separator
     *
     * @return The contract version
     */
    function getContractVersion() external view override returns (string memory) {
        EIP712Domain storage domain = FukuStorage.eip712Domain();

        return domain.version;
    }

    /**
     * @notice Gets the contract chain id used for the domain separator
     *
     * @return The contract chain id
     */
    function getContractChainId() external view override returns (uint256) {
        EIP712Domain storage domain = FukuStorage.eip712Domain();

        return domain.chainId;
    }

    /**
     * @notice Gets the tokenized options contract address
     *
     * @return The tokenized options contract address
     */
    function getTokenizedOptionsAddress() external view override returns (address) {
        FukuTokenizedOptionsStorage storage tokenizedOptionsStorage = FukuStorage.fukuTokenizedOptionsStorage();

        return tokenizedOptionsStorage.tokenizedOptions;
    }

    /**
     * @notice Gets the seller's minimum listing nonce
     *
     * @param seller The seller's address
     * @return The minimum listing nonce
     */
    function getSellerMinListingNonce(address seller) external view override returns (uint256) {
        FukuOptionExchangeStorage storage exchangeStorage = FukuStorage.fukuOptionExchangeStorage();

        return exchangeStorage.minListingNonce[seller];
    }

    /**
     * @notice Gets the status of a listing nonce for a seller
     *
     * @param seller The seller's address
     * @param nonce The listing nonce
     * @return True if listing nonce was cancelled or purchased, false otherwise
     */
    function isSellerListingNonceCancelledOrPurchased(address seller, uint256 nonce)
        external
        view
        override
        returns (bool)
    {
        FukuOptionExchangeStorage storage exchangeStorage = FukuStorage.fukuOptionExchangeStorage();

        return exchangeStorage.isListingNonceCancelledOrPurchased[seller][nonce];
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

interface IFukuGetter {
    function getContractName() external view returns (string memory);

    function getContractVersion() external view returns (string memory);

    function getContractChainId() external view returns (uint256);

    function getTokenizedOptionsAddress() external view returns (address);

    function getSellerMinListingNonce(address seller) external view returns (uint256);

    function isSellerListingNonceCancelledOrPurchased(address seller, uint256 nonce) external view returns (bool);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

struct EIP712Hashes {
    bytes32 domain;
    bytes32 optionListing;
}

struct FukuOptionExchangeStorage {
    mapping(address => uint256) minListingNonce;
    mapping(address => mapping(uint256 => bool)) isListingNonceCancelledOrPurchased;
}

struct FukuTokenizedOptionsStorage {
    address tokenizedOptions;
}

library FukuStorage {
    bytes32 constant EIP_712_DOMAIN_POSITION = keccak256("fuku.storage.eip.712.domain");
    bytes32 constant EIP_712_HASHES_POSITION = keccak256("fuku.storage.eip.712.hashes");
    bytes32 constant FUKU_OPTION_EXCHANGE_STORAGE_POSITION = keccak256("fuku.storage.fuku.option.exchange.storage");
    bytes32 constant FUKU_TOKENIZED_OPTIONS_STORAGE_POSITION = keccak256("fuku.storage.fuku.tokenized.options.storage");

    function eip712Domain() internal pure returns (EIP712Domain storage domain) {
        bytes32 position = EIP_712_DOMAIN_POSITION;
        assembly {
            domain.slot := position
        }
    }

    function eip712Hashes() internal pure returns (EIP712Hashes storage hashes) {
        bytes32 position = EIP_712_HASHES_POSITION;
        assembly {
            hashes.slot := position
        }
    }

    function fukuOptionExchangeStorage()
        internal
        pure
        returns (FukuOptionExchangeStorage storage optionExchangeStorage)
    {
        bytes32 position = FUKU_OPTION_EXCHANGE_STORAGE_POSITION;
        assembly {
            optionExchangeStorage.slot := position
        }
    }

    function fukuTokenizedOptionsStorage()
        internal
        pure
        returns (FukuTokenizedOptionsStorage storage tokenizedOptionsStorage)
    {
        bytes32 position = FUKU_TOKENIZED_OPTIONS_STORAGE_POSITION;
        assembly {
            tokenizedOptionsStorage.slot := position
        }
    }
}