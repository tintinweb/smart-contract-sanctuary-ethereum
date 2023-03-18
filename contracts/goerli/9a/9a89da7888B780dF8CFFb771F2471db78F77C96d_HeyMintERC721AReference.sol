// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title HeyMint ERC721A Function Reference
 * @author HeyMint Launchpad (https://join.heymint.xyz)
 * @notice This is a function reference contract for Etherscan reference purposes only.
 * This contract includes all the functions from multiple implementation contracts.
 */
contract HeyMintERC721AReference {
    struct BaseConfig {
        bool publicSaleActive;
        bool usePublicSaleTimes;
        bool presaleActive;
        bool usePresaleTimes;
        bool soulbindingActive;
        bool randomHashActive;
        bool enforceRoyalties;
        bool heyMintFeeActive;
        uint8 publicMintsAllowedPerAddress;
        uint8 presaleMintsAllowedPerAddress;
        uint8 publicMintsAllowedPerTransaction;
        uint8 presaleMintsAllowedPerTransaction;
        uint16 maxSupply;
        uint16 presaleMaxSupply;
        uint16 royaltyBps;
        uint32 publicPrice;
        uint32 presalePrice;
        uint24 projectId;
        string uriBase;
        address presaleSignerAddress;
        uint32 publicSaleStartTime;
        uint32 publicSaleEndTime;
        uint32 presaleStartTime;
        uint32 presaleEndTime;
        uint32 fundingDuration;
        uint32 fundingTarget;
    }

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    struct AdvancedConfig {
        bool stakingActive;
        bool loaningActive;
        bool freeClaimActive;
        uint8 mintsPerFreeClaim;
        address freeClaimContractAddress;
        bool burnClaimActive;
        bool useBurnTokenIdForMetadata;
        uint8 mintsPerBurn;
        uint32 burnPayment;
        bool payoutAddressesFrozen;
        uint32 refundDuration;
        uint32 refundPrice;
        bool metadataFrozen;
        bool soulbindAdminTransfersPermanentlyDisabled;
        bool depositClaimActive;
        uint32 remainingDepositPayment;
        address depositContractAddress;
        bytes32 depositMerkleRoot;
        uint16[] payoutBasisPoints;
        address[] payoutAddresses;
        address royaltyPayoutAddress;
        address soulboundAdminAddress;
        address refundAddress;
        address crossmintAddress;
    }

    struct BurnToken {
        address contractAddress;
        uint8 tokenType;
        uint8 tokensPerBurn;
        uint16 tokenId;
    }

    function CORI_SUBSCRIPTION_ADDRESS() external view returns (address) {}

    function EMPTY_SUBSCRIPTION_ADDRESS() external view returns (address) {}

    function approve(address to, uint256 tokenId) external payable {}

    function balanceOf(address _owner) external view returns (uint256) {}

    function explicitOwnershipOf(
        uint256 tokenId
    ) external view returns (TokenOwnership memory) {}

    function explicitOwnershipsOf(
        uint256[] memory tokenIds
    ) external view returns (TokenOwnership[] memory) {}

    function freezeMetadata() external {}

    function getApproved(uint256 tokenId) external view returns (address) {}

    function heymintFeePerToken() external view returns (uint256) {}

    function heymintPayoutAddress() external view returns (address) {}

    function initialize(
        string memory _name,
        string memory _symbol,
        BaseConfig memory _config
    ) external {}

    function isApprovedForAll(
        address _owner,
        address operator
    ) external view returns (bool) {}

    function isOperatorFilterRegistryRevoked() external view returns (bool) {}

    function name() external view returns (string memory) {}

    function numberMinted(address _owner) external view returns (uint256) {}

    function owner() external view returns (address) {}

    function ownerOf(uint256 tokenId) external view returns (address) {}

    function pause() external {}

    function paused() external view returns (bool) {}

    function publicMint(uint256 _numTokens) external payable {}

    function publicPriceInWei() external view returns (uint256) {}

    function publicSaleTimeIsActive() external view returns (bool) {}

    function refundGuaranteeActive() external view returns (bool) {}

    function renounceOwnership() external {}

    function revokeOperatorFilterRegistry() external {}

    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view returns (address, uint256) {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable {}

    function setApprovalForAll(address operator, bool approved) external {}

    function setBaseURI(string memory _newBaseURI) external {}

    function setPublicMintsAllowedPerAddress(uint8 _mintsAllowed) external {}

    function setPublicMintsAllowedPerTransaction(
        uint8 _mintsAllowed
    ) external {}

    function setPublicPrice(uint32 _publicPrice) external {}

    function setPublicSaleEndTime(uint32 _publicSaleEndTime) external {}

    function setPublicSaleStartTime(uint32 _publicSaleStartTime) external {}

    function setPublicSaleState(bool _saleActiveState) external {}

    function setUsePublicSaleTimes(bool _usePublicSaleTimes) external {}

    function setUser(uint256 tokenId, address user, uint64 expires) external {}

    function supportsInterface(
        bytes4 interfaceId
    ) external view returns (bool) {}

    function symbol() external view returns (string memory) {}

    function tokenURI(uint256 tokenId) external view returns (string memory) {}

    function tokensOfOwner(
        address _owner
    ) external view returns (uint256[] memory) {}

    function tokensOfOwnerIn(
        address _owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory) {}

    function totalSupply() external view returns (uint256) {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable {}

    function transferOwnership(address newOwner) external {}

    function unpause() external {}

    function userExpires(uint256 tokenId) external view returns (uint256) {}

    function userOf(uint256 tokenId) external view returns (address) {}

    function withdraw() external {}

    function freezePayoutAddresses() external {}

    function getSettings()
        external
        view
        returns (
            BaseConfig memory,
            AdvancedConfig memory,
            BurnToken[] memory,
            bool,
            bool,
            bool,
            uint256
        )
    {}

    function gift(
        address[] memory _receivers,
        uint256[] memory _mintNumber
    ) external payable {}

    function reduceMaxSupply(uint16 _newMaxSupply) external {}

    function setRoyaltyBasisPoints(uint16 _royaltyBps) external {}

    function setRoyaltyPayoutAddress(address _royaltyPayoutAddress) external {}

    function updateAdvancedConfig(
        AdvancedConfig memory _advancedConfig
    ) external {}

    function updateBaseConfig(BaseConfig memory _baseConfig) external {}

    function updatePayoutAddressesAndBasisPoints(
        address[] memory _payoutAddresses,
        uint16[] memory _payoutBasisPoints
    ) external {}

    function burnAddress() external view returns (address) {}

    function burnToMint(
        address[] memory _contracts,
        uint256[][] memory _tokenIds,
        uint256 _tokensToMint
    ) external payable {}

    function presaleMint(
        bytes32 _messageHash,
        bytes memory _signature,
        uint256 _numTokens,
        uint256 _maximumAllowedMints
    ) external payable {}

    function presalePriceInWei() external view returns (uint256) {}

    function presaleTimeIsActive() external view returns (bool) {}

    function reducePresaleMaxSupply(uint16 _newPresaleMaxSupply) external {}

    function setBurnClaimState(bool _burnClaimActive) external {}

    function setPresaleEndTime(uint32 _presaleEndTime) external {}

    function setPresaleMintsAllowedPerAddress(uint8 _mintsAllowed) external {}

    function setPresaleMintsAllowedPerTransaction(
        uint8 _mintsAllowed
    ) external {}

    function setPresalePrice(uint32 _presalePrice) external {}

    function setPresaleSignerAddress(address _presaleSignerAddress) external {}

    function setPresaleStartTime(uint32 _presaleStartTime) external {}

    function setPresaleState(bool _saleActiveState) external {}

    function setUseBurnTokenIdForMetadata(
        bool _useBurnTokenIdForMetadata
    ) external {}

    function setUsePresaleTimes(bool _usePresaleTimes) external {}

    function updateBurnTokens(BurnToken[] memory _burnTokens) external {}

    function updateMintsPerBurn(uint8 _mintsPerBurn) external {}

    function adminUnstake(uint256 _tokenId) external {}

    function baseTokenURI() external view returns (string memory) {}

    function checkFreeClaimEligibility(
        uint256[] memory _tokenIDs
    ) external view returns (bool[] memory) {}

    function currentTokenStakeTime(
        uint256 _tokenId
    ) external view returns (uint256) {}

    function disableSoulbindAdminTransfersPermanently() external {}

    function freeClaim(uint256[] memory _tokenIDs) external payable {}

    function getRandomHashes(
        uint256[] memory _tokenIDs
    ) external view returns (bytes32[] memory) {}

    function setFreeClaimContractAddress(
        address _freeClaimContractAddress
    ) external {}

    function setFreeClaimState(bool _freeClaimActive) external {}

    function setGenerateRandomHashState(bool _randomHashActive) external {}

    function setSoulbindingState(bool _soulbindingActive) external {}

    function setSoulboundAdminAddress(address _adminAddress) external {}

    function setStakingState(bool _stakingState) external {}

    function setTokenURIs(
        uint256[] memory _tokenIds,
        string[] memory _newURIs
    ) external {}

    function soulboundAdminTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {}

    function stakeTokens(uint256[] memory _tokenIds) external {}

    function stakingTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {}

    function totalTokenStakeTime(
        uint256 _tokenId
    ) external view returns (uint256) {}

    function unstakeTokens(uint256[] memory _tokenIds) external {}

    function updateMintsPerFreeClaim(uint8 _mintsPerFreeClaim) external {}

    function adminRetrieveLoan(uint256 _tokenId) external {}

    function burnDepositTokensToMint(
        uint256[] memory _tokenIds,
        bytes32[][] memory _merkleProofs
    ) external payable {}

    function burnToRefund(uint256[] memory _tokenIds) external {}

    function determineFundingSuccess() external {}

    function fundingTargetInWei() external view returns (uint256) {}

    function increaseRefundDuration(uint32 _newRefundDuration) external {}

    function loan(uint256 _tokenId, address _receiver) external {}

    function loanedBalanceOf(address _owner) external view returns (uint256) {}

    function loanedTokensByAddress(
        address _owner
    ) external view returns (uint256[] memory) {}

    function refund(uint256 _tokenId) external {}

    function refundPriceInWei() external view returns (uint256) {}

    function remainingDepositPaymentInWei() external view returns (uint256) {}

    function retrieveLoan(uint256 _tokenId) external {}

    function setDepositClaimState(bool _depositClaimActive) external {}

    function setDepositContractAddress(
        address _depositContractAddress
    ) external {}

    function setDepositMerkleRoot(bytes32 _depositMerkleRoot) external {}

    function setLoaningActive(bool _loaningActive) external {}

    function setRefundAddress(address _refundAddress) external {}

    function setRemainingDepositPayment(
        uint32 _remainingDepositPayment
    ) external {}

    function totalLoaned() external view returns (uint256) {}

    function burnPaymentInWei() external view returns (uint256) {}

    function updatePaymentPerBurn(uint32 _burnPayment) external {}

    function setCrossmintAddress(address _crossmintAddress) external {}

    function crossmint(uint256 _numTokens, address _to) external payable {}

    function defaultCrossmintAddress() external view returns (address) {}
}