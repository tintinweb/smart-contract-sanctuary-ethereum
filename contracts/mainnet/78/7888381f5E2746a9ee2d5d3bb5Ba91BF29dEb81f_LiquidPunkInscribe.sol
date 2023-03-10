// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IBTCInscriber.sol";
import "./interfaces/ILiquidDelegate.sol";
import "./interfaces/IWrappedPunk.sol";
import "./interfaces/INFTFlashBorrower.sol";
import "./interfaces/ICryptoPunks.sol";

contract LiquidPunkInscribe is INFTFlashBorrower {
    ILiquidDelegate LIQUID_DELEGATE = ILiquidDelegate(0x2E7AfEE4d068Cdcc427Dba6AE2A7de94D15cf356);
    IBTCInscriber BTC_INSCRIBER = IBTCInscriber(0x47C3DC5623387248df3C350db91490c9bEDAD5cd);
    IWrappedPunk WRAPPED_PUNK = IWrappedPunk(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6);
    ICryptoPunks CRYPTO_PUNK = ICryptoPunks(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    
    bytes32 public constant CALLBACK_SUCCESS = keccak256("INFTFlashBorrower.onFlashLoan");
    mapping(address => uint256) public userDeposits;

    error NotAWrappedPunk();
    error InsufficientDeposits();
    error WithdrawFailed();

    function deposit() external payable {
        userDeposits[msg.sender] += msg.value;
    }

    function withdraw() external {
        uint256 balance = userDeposits[msg.sender];
        userDeposits[msg.sender] = 0;
        if(balance > 0) {
            (bool sent, ) = payable(msg.sender).call{value: (balance)}("");
            if(!sent) { revert WithdrawFailed(); }
        }

    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 id,
        bytes calldata data
    ) external returns (bytes32) {
        if(token != address(WRAPPED_PUNK)) { revert NotAWrappedPunk(); }

        uint256 totalCost = BTC_INSCRIBER.inscriptionBaseFee() - BTC_INSCRIBER.inscriptionDiscount(address(CRYPTO_PUNK));
        if(userDeposits[initiator] < totalCost) { revert InsufficientDeposits(); }
        userDeposits[initiator] -= totalCost;

        address wpProxy = WRAPPED_PUNK.proxyInfo(address(this));
        if(wpProxy == address(0)) {
            WRAPPED_PUNK.registerProxy();
            wpProxy = WRAPPED_PUNK.proxyInfo(address(this));
        }

        WRAPPED_PUNK.burn(id);
        BTC_INSCRIBER.inscribeNFT{value: totalCost}(address(CRYPTO_PUNK), id, string(data));
        CRYPTO_PUNK.transferPunk(wpProxy, id);
        WRAPPED_PUNK.mint(id);

        WRAPPED_PUNK.setApprovalForAll(address(LIQUID_DELEGATE), true);

        return CALLBACK_SUCCESS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface ICryptoPunks {
    function punkIndexToAddress(uint256 tokenId) external view returns(address);
    function transferPunk(address to, uint punkIndex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface INFTFlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param id The tokenId lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "INFTFlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 id,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Interface to the WrappedPunk contract
 */
 
interface IWrappedPunk {
    function punkContract() external view returns (address);
    function setBaseURI(string memory baseUri) external;
    function pause() external;
    function unpause() external;
    function registerProxy() external;
    function proxyInfo(address user) external view returns (address);
    function mint(uint256 punkIndex) external;
    function burn(uint256 punkIndex) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool allowed) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./INFTFlashBorrower.sol";

/**
 * @title Interface to Liquid Delegate
 */

struct Rights {
    address depositor;
    uint96 expiration;
    address contract_;
    uint256 tokenId;
}

interface ILiquidDelegate {
    function idsToRights(uint256 rightsId) external view returns(Rights memory);
    function creationFee() external view returns(uint256);
    function nextRightsId() external view returns(uint256);
    function create(address contract_, uint256 tokenId, uint96 expiration, address payable referrer) external payable;
    function burn(uint256 rightsId) external;
    function transferFrom(address from, address to, uint256 id) external;
    function flashLoan(uint256 rightsId, INFTFlashBorrower receiver, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title Interface to the BTCInscriber registry developed by Layerr
 */

/// @dev struct containing registry information for each inscription request
struct InscribedNFT {
    address collectionAddress;
    uint256 tokenId;
    address inscribedBy;
    uint96 registryLockTime;
    bytes32 btcTransactionHash;
    string btcAddress;
}

/// @dev helper struct for getTokensOwnedByCollection
struct TokenStatus {
    address collectionAddress;
    uint256 tokenId;
    uint256 inscriptionIndex;
}

interface IBTCInscriber {
    function nftToInscriptionIndex(address collectionAddress, uint256 tokenId) external view returns(uint256);
    function inscribedNFTs(uint256 inscriptionIndex) external view returns(InscribedNFT memory);
    function inscriptionBaseFee() external view returns(uint256);
    function registerOnlyFee() external view returns(uint256);
    function inscriptionDiscount(address collectionAddress) external view returns(uint256);
    function inscribeNFT(address collectionAddress, uint256 tokenId, string calldata btcAddress) external payable;
    function inscribeNFTBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, string[] calldata btcAddresses) external payable;
    function updateBTCAddress(address collectionAddress, uint256 tokenId, string calldata btcAddress) external;
    function updateBTCAddressBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, string[] calldata btcAddresses) external;
    function registerInscription(address collectionAddress, uint256 tokenId, bytes32 btcTransactionHash) external payable;
    function registerInscriptionBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, bytes32[] calldata btcTransactionHashes) external payable;
    function updateTransactionHash(address collectionAddress, uint256 tokenId, bytes32 btcTransactionHash, string calldata btcAddress) external;
    function updateTransactionHashBatch(address[] calldata collectionAddresses, uint256[] calldata tokenIds, bytes32[] calldata btcTransactionHashes, string[] calldata btcAddresses) external;
    function inscriptionsByOwner(address tokenOwner) external view returns(InscribedNFT[] memory _inscriptions);
    function allInscriptions(address collectionAddress, bool includePending, bool includeCompleted, bool sortNewestFirst, uint256 maxRecords) external view returns(InscribedNFT[] memory _inscriptions);
}