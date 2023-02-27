/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

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
        uint8 presaleMintsAllowedPerAddress;
        uint8 publicMintsAllowedPerAddress;
        uint16 maxSupply;
        uint16 presaleMaxSupply;
        uint16 publicPrice;
        uint16 presalePrice;
        uint16 royaltyBps;
        uint24 projectId;
        uint32 publicSaleStartTime;
        uint32 publicSaleEndTime;
        uint32 presaleStartTime;
        uint32 presaleEndTime;
        uint8 fundingDuration;
        uint24 fundingTarget;
        string uriBase;
    }

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    struct AdvancedConfig {
        bool payoutAddressesFrozen;
        bool metadataFrozen;
        bool soulbindAdminTransfersPermanentlyDisabled;
        bool stakingActive;
        bool loaningActive;
        uint8 refundDuration;
        uint16 refundPrice;
        bool freeClaimActive;
        uint8 mintsPerFreeClaim;
        address freeClaimContractAddress;
        bool burnClaimActive;
        uint8 mintsPerBurn;
        bytes32 depositMerkleRoot;
        bool depositClaimActive;
        uint16 remainingDepositPayment;
        address depositContractAddress;
    }

    struct AddressConfig {
        uint16[] payoutBasisPoints;
        address[] payoutAddresses;
        address royaltyPayoutAddress;
        address soulboundAdminAddress;
        address refundAddress;
        address presaleSignerAddress;
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

    function gift(
        address[] memory _receivers,
        uint256[] memory _mintNumber
    ) external {}

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

    function mint(uint256 _numTokens) external payable {}

    function name() external view returns (string memory) {}

    function numberMinted(address _owner) external view returns (uint256) {}

    function owner() external view returns (address) {}

    function ownerOf(uint256 tokenId) external view returns (address) {}

    function pause() external {}

    function paused() external view returns (bool) {}

    function publicSaleTimeIsActive() external view returns (bool) {}

    function reduceMaxSupply(uint16 _newMaxSupply) external {}

    function refundGuaranteeActive() external view returns (bool) {}

    function renounceOwnership() external {}

    function revokeOperatorFilterRegistry() external {}

    function royaltyInfo(
        uint256,
        uint256 _salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {}

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

    function setPublicPrice(uint16 _publicPrice) external {}

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

    function burnAddress() external view returns (address) {}

    function burnToMint(
        address[] memory _contracts,
        uint256[][] memory _tokenIds,
        uint256 _timesToBurn
    ) external {}

    function freezePayoutAddresses() external {}

    function initializeAdvancedConfig(
        AdvancedConfig memory _advancedConfig
    ) external {}

    function presaleMint(
        bytes32 _messageHash,
        bytes memory _signature,
        uint256 _numTokens,
        uint256 _maximumAllowedMints
    ) external payable {}

    function presaleTimeIsActive() external view returns (bool) {}

    function reducePresaleMaxSupply(uint16 _newPresaleMaxSupply) external {}

    function setBurnClaimState(bool _burnClaimActive) external {}

    function setPresaleEndTime(uint32 _presaleEndTime) external {}

    function setPresaleMintsAllowedPerAddress(uint8 _mintsAllowed) external {}

    function setPresalePrice(uint16 _presalePrice) external {}

    function setPresaleSignerAddress(address _presaleSignerAddress) external {}

    function setPresaleStartTime(uint32 _presaleStartTime) external {}

    function setPresaleState(bool _saleActiveState) external {}

    function setRoyaltyBasisPoints(uint16 _royaltyBps) external {}

    function setRoyaltyPayoutAddress(address _royaltyPayoutAddress) external {}

    function setUsePresaleTimes(bool _usePresaleTimes) external {}

    function updateAddressConfig(
        AddressConfig memory _addressConfig
    ) external {}

    function updateBurnTokens(BurnToken[] memory _burnTokens) external {}

    function updateMintsPerBurn(uint8 _mintsPerBurn) external {}

    function updatePayoutAddressesAndBasisPoints(
        address[] memory _payoutAddresses,
        uint16[] memory _payoutBasisPoints
    ) external {}

    function adminRetrieveLoan(uint256 _tokenId) external {}

    function adminUnstake(uint256 _tokenId) external {}

    function burnDepositTokensToMint(
        uint256[] memory _tokenIds,
        bytes32[][] memory _merkleProofs
    ) external payable {}

    function burnToRefund(uint256[] memory _tokenIds) external {}

    function currentTokenStakeTime(
        uint256 _tokenId
    ) external view returns (uint256) {}

    function determineFundingSuccess() external {}

    function disableSoulbindAdminTransfersPermanently() external {}

    function freeClaim(uint256[] memory _tokenIDs) external {}

    function increaseRefundDuration(uint8 _refundDurationIncrease) external {}

    function loan(uint256 _tokenId, address _receiver) external {}

    function loanedBalanceOf(address _owner) external view returns (uint256) {}

    function loanedTokensByAddress(
        address _owner
    ) external view returns (uint256[] memory) {}

    function refund(uint256 _tokenId) external {}

    function retrieveLoan(uint256 _tokenId) external {}

    function setDepositClaimState(bool _depositClaimActive) external {}

    function setDepositContractAddress(
        address _depositContractAddress
    ) external {}

    function setDepositMerkleRoot(bytes32 _depositMerkleRoot) external {}

    function setFreeClaimContractAddress(
        address _freeClaimContractAddress
    ) external {}

    function setFreeClaimState(bool _freeClaimActive) external {}

    function setGenerateRandomHashState(bool _randomHashActive) external {}

    function setLoaningActive(bool _loaningActive) external {}

    function setRefundAddress(address _refundAddress) external {}

    function setRemainingDepositPayment(
        uint16 _remainingDepositPayment
    ) external {}

    function setSoulbindingState(bool _soulbindingActive) external {}

    function setSoulboundAdminAddress(address _adminAddress) external {}

    function setStakingState(bool _stakingState) external {}

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

    function totalLoaned() external view returns (uint256) {}

    function totalTokenStakeTime(
        uint256 _tokenId
    ) external view returns (uint256) {}

    function unstakeTokens(uint256[] memory _tokenIds) external {}

    function updateMintsPerFreeClaim(uint8 _mintsPerFreeClaim) external {}
}