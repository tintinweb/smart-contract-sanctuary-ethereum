// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract EnigmaV4 is ERC721 {
    event Mint(address indexed from, uint256 indexed tokenId);

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyCollaborator() {
        bool isCollaborator = false;
        for (uint256 i; i < collaborators.length; i++) {
            if (collaborators[i].addr == msg.sender) {
                isCollaborator = true;

                break;
            }
        }

        require(
            owner() == _msgSender() || isCollaborator,
            "Ownable: caller is not the owner nor a collaborator"
        );

        _;
    }

    modifier claimStarted() {
        require(
            startPublicClaimDate != 0 && startPublicClaimDate <= block.timestamp,
            "Public sale is not open"
        );

        _;
    }

    modifier holderPresaleStarted() {
        require(
            startHolderPresaleDate != 0 && startHolderPresaleDate <= block.timestamp,
            "Holder presale is not open"
        );

        _;
    }

    modifier partnerPresaleStarted() {
        require(
            startPartnerPresaleDate != 0 && startPartnerPresaleDate <= block.timestamp,
            "Partner presale is not open"
        );

        _;
    }

    modifier onlyHolderWhitelisted() {
        require(holderPresaleWhitelistedAddresses[msg.sender] > 0, "You are either not whitelisted for holder presale or have claimed all tokens");

        _;
    }

    modifier onlyPartnerWhitelisted() {
        require(partnerPresaleWhitelistedAddresses[msg.sender] > 0, "You are either not whitelisted for partner presale or have claimed all tokens");

        _;
    }

    struct Collaborators {
        address addr;
        uint256 cut;
    }

    struct Whitelist {
        address addr;
        uint256 count;
    }

    uint256 private startPartnerPresaleDate = 1649077140;
    uint256 private startPublicClaimDate = 1649206740;
    uint256 private startHolderPresaleDate = 1648990740;

    uint256 private tier1Price = 150000000000000000;
    uint256 private tier2Price = 145000000000000000;
    uint256 private tier3Price = 140000000000000000;
    uint256 private tier4Price = 135000000000000000;
    uint256 private tier5Price = 130000000000000000;

    uint256 private tier1Count = 1;
    uint256 private tier2Count = 3;
    uint256 private tier3Count = 5;
    uint256 private tier4Count = 10;
    uint256 private tier5Count = 20;

    uint256 public partnerPresaleMintedTokens = 0;
    uint256 public holderPresaleMintedTokens = 0;
    uint256 public totalMintedTokens = 0;

    uint128 private basisPoints = 10000;

    uint256 private maxTokensPerTransaction = 50;
    
    string private baseURI = "";
    
    uint256 public giveawayCount = 0;

    mapping(address => uint256) private claimedEnigmaV4TokenPerWallet;

    uint16[] availableEnigmaV4Tokens;
    Collaborators[] private collaborators;

    mapping (address => uint256) holderPresaleWhitelistedAddresses;
    mapping (address => uint256) partnerPresaleWhitelistedAddresses;

    constructor() ERC721("TheEnigmaEconomyV4", "ENGv4") {}

    // ONLY OWNER

    /**
     * Sets the collaborators of the project with their cuts
     */
    function addCollaborators(Collaborators[] memory _collaborators)
        external
        onlyOwner
    {
        require(collaborators.length == 0, "Collaborators were already set");

        uint128 totalCut;
        for (uint256 i; i < _collaborators.length; i++) {
            collaborators.push(_collaborators[i]);
            totalCut += uint128(_collaborators[i].cut);
        }

        require(totalCut == basisPoints, "Total cut does not add to 100%");
    }

    function getMintPricePerToken(uint256 quantity) internal view returns (uint256) {
        uint256 mintPricePerToken = tier1Price;
        if (quantity >= tier2Count) {
            mintPricePerToken = tier2Price;
        }
        if (quantity >= tier3Count) {
            mintPricePerToken = tier3Price;
        }
        if (quantity >= tier4Count) {
            mintPricePerToken = tier4Price;
        }
        if (quantity >= tier5Count) {
            mintPricePerToken = tier5Price;
        }
        return mintPricePerToken;
    }

    // ONLY COLLABORATORS

    /**
     * @dev Allows to withdraw the Ether in the contract and split it among the collaborators
     */
    function withdraw() external onlyCollaborator {
        uint256 totalBalance = address(this).balance;

        for (uint256 i; i < collaborators.length; i++) {
            payable(collaborators[i].addr).transfer(
                mulScale(totalBalance, collaborators[i].cut, basisPoints)
            );
        }
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyCollaborator {
        baseURI = _uri;
    }

     /**
     * @dev Sets the date that users can start claiming enigmaV4 tokens
     */
    function setStartPublicClaimDate(uint256 _startPublicClaimDate)
        external
        onlyCollaborator
    {
        startPublicClaimDate = _startPublicClaimDate;
    }

    /**
     * @dev Sets the date that users can start claiming enigmaV4 tokens for holder presale
     */
    function setHolderPresaleStartDate(uint256 _startHolderPresaleDate)
        external
        onlyCollaborator
    {
        startHolderPresaleDate = _startHolderPresaleDate;
    }

    /**
     * @dev Sets the date that users can start claiming enigmaV4 tokens for partner sale
     */
    function setPartnerPresaleStartDate(uint256 _startPartnerPresaleDate)
        external
        onlyCollaborator
    {
        startPartnerPresaleDate = _startPartnerPresaleDate;
    }

    /**
     * @dev Sets the giveaway count 
     */
    function setGiveawayCount(uint256 _giveawayCount)
        external
        onlyCollaborator
    {
        giveawayCount = _giveawayCount;
    }


    /**
     * @dev Populates the available enigmaV4 tokens
     */
    function addAvailableEnigmaV4Tokens(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availableEnigmaV4Tokens.push(i);
        }
    }

    /**
     * @dev Removes a chosen enigmaV4 token from the available list, only a utility function
     */
    function removeEnigmaV4TokenFromAvailableEnigmaV4Tokens(uint16 tokenId)
        external
        onlyCollaborator
    {
        for (uint16 i; i <= availableEnigmaV4Tokens.length; i++) {
            if (availableEnigmaV4Tokens[i] != tokenId) {
                continue;
            }

            availableEnigmaV4Tokens[i] = availableEnigmaV4Tokens[availableEnigmaV4Tokens.length - 1];
            availableEnigmaV4Tokens.pop();

            break;
        }
    }

    /**
     * @dev Checks if a enigmaV4 token is in the available list
     */
    function isEnigmaV4TokenAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availableEnigmaV4Tokens.length; i++) {
            if (availableEnigmaV4Tokens[i] == tokenId) {
                return true;
            }
        }

        return false;
    }


    /**
     * @dev Give random giveaway enigmaV4 tokens to the provided address
     */
    function reserveGiveawayEnigmaV4Tokens(address _address)
        external
        onlyCollaborator
    {
        require(availableEnigmaV4Tokens.length >= giveawayCount, "No enigmaV4 tokens left to be claimed");
        
        totalMintedTokens += giveawayCount;

        uint256[] memory tokenIds = new uint256[](giveawayCount);

        for (uint256 i; i < giveawayCount; i++) {
            tokenIds[i] = getEnigmaV4TokenToBeClaimed();
        }

        _batchMint(_address, tokenIds);
        giveawayCount = 0;
    }

    /**
    * @dev Whitelist addresses for holder presale
     */
    function whitelistAddressForHolderPresale (Whitelist[] memory users) external onlyCollaborator {
        for (uint i = 0; i < users.length; i++) {
            holderPresaleWhitelistedAddresses[users[i].addr] = users[i].count;
        }
    }

    /**
    * @dev Whitelist addresses for partner sale
     */
    function whitelistAddressForPartnerPresale (Whitelist[] memory users) external onlyCollaborator {
        for (uint i = 0; i < users.length; i++) {
            partnerPresaleWhitelistedAddresses[users[i].addr] = users[i].count;
        }
    }

    /**
    * @dev Sets max tokens per transaction
     */
    function setMaxTokensPerTransaction(uint256 _maxTokensPerTransaction)
        external
        onlyCollaborator
    {
        maxTokensPerTransaction = _maxTokensPerTransaction;
    }

    function setTier1Price(uint256 newPrice) external onlyCollaborator {
        tier1Price = newPrice;
    }

    function setTier2Price(uint256 newPrice) external onlyCollaborator {
        tier2Price = newPrice;
    }

    function setTier3Price(uint256 newPrice) external onlyCollaborator {
        tier3Price = newPrice;
    }

    function setTier4Price(uint256 newPrice) external onlyCollaborator {
        tier4Price = newPrice;
    }

    function setTier5Price(uint256 newPrice) external onlyCollaborator {
        tier5Price = newPrice;
    }

    function setTier1Count(uint256 newCount) external onlyCollaborator {
        tier1Count = newCount;
    }

    function setTier2Count(uint256 newCount) external onlyCollaborator {
        tier2Count = newCount;
    }

    function setTier3Count(uint256 newCount) external onlyCollaborator {
        tier3Count = newCount;
    }

    function setTier4Count(uint256 newCount) external onlyCollaborator {
        tier4Count = newCount;
    }

    function setTier5Count(uint256 newCount) external onlyCollaborator {
        tier5Count = newCount;
    }

    // END ONLY COLLABORATORS

    /**
     * @dev Claim upto 50 enigmaV4 tokens in public sale
     */
    function claimEnigmaV4Tokens(uint256 quantity)
        external
        payable
        callerIsUser
        claimStarted
        returns (uint256[] memory)
    {
        require(
            msg.value >= getMintPricePerToken(quantity) * quantity,
            "Not enough Ether to claim the EnigmaV4Tokens"
        );
        require(quantity <= maxTokensPerTransaction, "Max tokens per transaction can be 50");
        require(availableEnigmaV4Tokens.length >= quantity, "Not enough enigmaV4 tokens left");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedEnigmaV4TokenPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getEnigmaV4TokenToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
        return tokenIds;
    }

    /**
     * @dev Claim up to 50 enigmaV4 tokens at once in holder presale
     */
    function holderPresaleMintEnigmaV4Tokens(uint256 quantity)
        external
        payable
        callerIsUser
        holderPresaleStarted
        onlyHolderWhitelisted
        returns (uint256[] memory)
    {
        require(
            msg.value >= getMintPricePerToken(quantity) * quantity,
            "Not enough Ether to claim the EnigmaV4Tokens"
        );
        
        require(availableEnigmaV4Tokens.length >= quantity, "Not enough enigmaV4 tokens left");

        require(quantity <= maxTokensPerTransaction, "Max tokens per transaction can be 50");
        
        require(quantity <= holderPresaleWhitelistedAddresses[msg.sender], "Token count exceeds remaining whitelisted count for you");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedEnigmaV4TokenPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;
        holderPresaleMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getEnigmaV4TokenToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
        holderPresaleWhitelistedAddresses[msg.sender] = holderPresaleWhitelistedAddresses[msg.sender] - quantity;
        return tokenIds;
    }

    /**
     * @dev Claim up to 50 enigmaV4 tokens at once in partner sale
     */
    function partnerPresaleMintEnigmaV4Tokens(uint256 quantity)
        external
        payable
        callerIsUser
        partnerPresaleStarted
        onlyPartnerWhitelisted
        returns (uint256[] memory)
    {
        require(
            msg.value >= getMintPricePerToken(quantity) * quantity,
            "Not enough Ether to claim the EnigmaV4Tokens"
        );
        
        require(availableEnigmaV4Tokens.length >= quantity, "Not enough enigmaV4 tokens left");

        require(quantity <= maxTokensPerTransaction, "Max tokens per transaction can be 50");

        require(quantity <= partnerPresaleWhitelistedAddresses[msg.sender], "Token count exceeds remaining whitelisted count for you");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedEnigmaV4TokenPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;
        partnerPresaleMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getEnigmaV4TokenToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
        partnerPresaleWhitelistedAddresses[msg.sender] = partnerPresaleWhitelistedAddresses[msg.sender] - quantity;
        return tokenIds;
    }

    /**
     * @dev Returns the tokenId by index
     */
    function tokenByIndex(uint256 tokenId) external view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        return tokenId;
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns how many EnigmaV4Tokens are still available to be claimed
     */
    function getAvailableEnigmaV4Tokens() external view returns (uint256) {
        return availableEnigmaV4Tokens.length;
    }

    /**
     * @dev Returns the whitelisted token count for an address in holder presale
     */
    function getHolderWhitelistedTokenCountForAddress(address _address) external view returns (uint256) {
        return holderPresaleWhitelistedAddresses[_address];
    }

    /**
     * @dev Returns the whitelisted token count for an address in partner presale
     */
    function getPartnerWhitelistedTokenCountForAddress(address _address) external view returns (uint256) {
        return partnerPresaleWhitelistedAddresses[_address];
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return totalMintedTokens;
    }

    /**
     * @dev Returns the total minted tokens in presale
     */
    function totalHolderPresaleMintCount() external view virtual returns (uint256) {
        return holderPresaleMintedTokens;
    }

    function totalPartnerPresaleMintCount() external view virtual returns (uint256) {
        return partnerPresaleMintedTokens;
    }
    
    function getMintPriceForTokens(uint256 quantity) external view virtual returns (uint256) {
        return getMintPricePerToken(quantity)*quantity;
    } 
    
    function viewTier1Details() external view virtual returns (uint256, uint256) {
        return (tier1Price, tier1Count);
    }

    function viewTier2Details() external view virtual returns (uint256, uint256) {
        return (tier2Price, tier2Count);
    }

    function viewTier3Details() external view virtual returns (uint256, uint256) {
        return (tier3Price, tier3Count);
    }

    function viewTier4Details() external view virtual returns (uint256, uint256) {
        return (tier4Price, tier4Count);
    }

    function viewTier5Details() external view virtual returns (uint256, uint256) {
        return (tier5Price, tier5Count);
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available EnigmaV4Token to be claimed
     */
    function getEnigmaV4TokenToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableEnigmaV4Tokens.length);
        uint256 tokenId = uint256(availableEnigmaV4Tokens[random]);

        availableEnigmaV4Tokens[random] = availableEnigmaV4Tokens[availableEnigmaV4Tokens.length - 1];
        availableEnigmaV4Tokens.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableEnigmaV4Tokens.length,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return random % _upper;
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }
}