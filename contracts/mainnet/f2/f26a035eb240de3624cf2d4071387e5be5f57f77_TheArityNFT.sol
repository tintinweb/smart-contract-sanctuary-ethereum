// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract TheArityNFT is ERC721 {
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

    modifier presaleStarted() {
        require(
            startPresaleDate != 0 && startPresaleDate <= block.timestamp,
            "Presale is not open"
        );

        _;
    }

    modifier genesisSaleStarted() {
        require(
            startGenesisSaleDate != 0 && startGenesisSaleDate <= block.timestamp,
            "Genesis sale is not open"
        );

        _;
    }

    modifier onlyPresaleWhitelisted() {
        require(presaleWhitelistedAddresses[msg.sender] == true, "You are not whitelisted for presale");

        _;
    }

    modifier onlyGenesisWhitelisted() {
        require(genesisWhitelistedAddresses[msg.sender] == true, "You are not whitelisted for genesis sale");

        _;
    }

    struct Collaborators {
        address addr;
        uint256 cut;
    }

    uint256 private startGenesisSaleDate = 1646838000;
    uint256 private startPublicClaimDate = 1649516400;
    uint256 private startPresaleDate = 1649516400;

    uint256 private genesisSaleMintPrice = 277000000000000000;
    uint256 private publicMintPrice = 277000000000000000;
    uint256 private presaleMintPrice = 277000000000000000;

    uint256 public genesisMintedTokens = 0;
    uint256 public totalMintedTokens = 0;
    uint256 public presaleMintedTokens = 0;

    uint256 private maxArityTokensPerTransaction = 25;

    uint128 private basisPoints = 10000;
    
    string private baseURI = "";
    
    uint256 public giveawayCount = 0;
    
    uint256 public genesisSaleLimit = 1000;
    uint256 public presaleLimit = 2000;

    mapping(address => uint256) private claimedArityTokenPerWallet;

    uint16[] availableArityTokens;
    Collaborators[] private collaborators;

    mapping (address => bool) presaleWhitelistedAddresses;
    mapping (address => bool) genesisWhitelistedAddresses;

    constructor() ERC721("TheArityNFT", "ARIT") {}

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
     * @dev Sets the claim price for each arity token
     */
    function setPublicMintPrice(uint256 _publicMintPrice) external onlyCollaborator {
        publicMintPrice = _publicMintPrice;
    }

    /**
     * @dev Sets the presale claim price for each arity token
     */
    function setPresaleMintPrice(uint256 _presaleMintPrice) external onlyCollaborator {
        presaleMintPrice = _presaleMintPrice;
    }

    /**
     * @dev Sets the genesis sale claim price for each arity token
     */
    function setGenesisSaleMintPrice(uint256 _genesisSaleMintPrice) external onlyCollaborator {
        genesisSaleMintPrice = _genesisSaleMintPrice;
    }

     /**
     * @dev Sets the date that users can start claiming arity tokens
     */
    function setStartPublicClaimDate(uint256 _startPublicClaimDate)
        external
        onlyCollaborator
    {
        startPublicClaimDate = _startPublicClaimDate;
    }

    /**
     * @dev Sets the date that users can start claiming arity tokens for presale
     */
    function setStartPresaleDate(uint256 _startPresaleDate)
        external
        onlyCollaborator
    {
        startPresaleDate = _startPresaleDate;
    }

    /**
     * @dev Sets the date that users can start claiming arity tokens for genesis sale
     */
    function setStartGenesisSaleDate(uint256 _startGenesisSaleDate)
        external
        onlyCollaborator
    {
        startGenesisSaleDate = _startGenesisSaleDate;
    }

    /**
     * @dev Sets the presale limit for presale
     */
    function setPresaleLimit(uint256 _presaleLimit)
        external
        onlyCollaborator
    {
        presaleLimit = _presaleLimit;
    }

    /**
     * @dev Sets the genesis sale limit for genesisSale
     */
    function setGenesisSaleLimit(uint256 _genesisSaleLimit)
        external
        onlyCollaborator
    {
        genesisSaleLimit = _genesisSaleLimit;
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
     * @dev Sets the max tokens per transaction 
     */
    function setMaxArityTokensPerTransaction(uint256 _maxArityTokensPerTransaction)
        external
        onlyCollaborator
    {
        maxArityTokensPerTransaction = _maxArityTokensPerTransaction;
    }

    /**
     * @dev Populates the available arity tokens
     */
    function addAvailableArityTokens(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availableArityTokens.push(i);
        }
    }

    /**
     * @dev Removes a chosen arity token from the available list, only a utility function
     */
    function removeArityTokenFromAvailableArityTokens(uint16 tokenId)
        external
        onlyCollaborator
    {
        for (uint16 i; i <= availableArityTokens.length; i++) {
            if (availableArityTokens[i] != tokenId) {
                continue;
            }

            availableArityTokens[i] = availableArityTokens[availableArityTokens.length - 1];
            availableArityTokens.pop();

            break;
        }
    }

    /**
     * @dev Checks if a arity token is in the available list
     */
    function isArityTokenAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availableArityTokens.length; i++) {
            if (availableArityTokens[i] == tokenId) {
                return true;
            }
        }

        return false;
    }


    /**
     * @dev Give random giveaway arity tokens to the provided address
     */
    function reserveGiveawayArityTokens(address _address)
        external
        onlyCollaborator
    {
        require(availableArityTokens.length >= giveawayCount, "No arity tokens left to be claimed");
        
        totalMintedTokens += giveawayCount;

        uint256[] memory tokenIds = new uint256[](giveawayCount);

        for (uint256 i; i < giveawayCount; i++) {
            tokenIds[i] = getArityTokenToBeClaimed();
        }

        _batchMint(_address, tokenIds);
        giveawayCount = 0;
    }

    /**
    * @dev Whitelist addresses for presale
     */
    function whitelistAddressForPresale (address[] memory users) external onlyCollaborator {
        for (uint i = 0; i < users.length; i++) {
            presaleWhitelistedAddresses[users[i]] = true;
        }
    }

    /**
    * @dev Whitelist addresses for genesis sale
     */
    function whitelistAddressForGenesisSale (address[] memory users) external onlyCollaborator {
        for (uint i = 0; i < users.length; i++) {
            genesisWhitelistedAddresses[users[i]] = true;
        }
    }

    // END ONLY COLLABORATORS

    /**
     * @dev Claim up to 25 arity tokens at once in public sale
     */
    function claimArityTokens(uint256 quantity)
        external
        payable
        callerIsUser
        claimStarted
        returns (uint256[] memory)
    {
        require(
            msg.value >= publicMintPrice * quantity,
            "Not enough Ether to claim the ArityTokens"
        );

        require(availableArityTokens.length >= quantity, "Not enough arity tokens left");

        require(quantity <= maxArityTokensPerTransaction, "Max tokens per transaction can be 25");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedArityTokenPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getArityTokenToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
        return tokenIds;
    }

    /**
     * @dev Claim up to 25 arity tokens at once in presale
     */
    function presaleMintArityTokens(uint256 quantity)
        external
        payable
        callerIsUser
        presaleStarted
        onlyPresaleWhitelisted
        returns (uint256[] memory)
    {
        require(
            msg.value >= presaleMintPrice * quantity,
            "Not enough Ether to claim the ArityTokens"
        );
        
        require(availableArityTokens.length >= quantity, "Not enough arity tokens left");

        require(quantity + presaleMintedTokens <= presaleLimit, "No more arity tokens left for presale");

        require(quantity <= maxArityTokensPerTransaction, "Max tokens per transaction can be 25");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedArityTokenPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;
        presaleMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getArityTokenToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
        return tokenIds;
    }

    /**
     * @dev Claim up to 25 arity tokens at once in genesis sale
     */
    function genesisSaleMintArityTokens(uint256 quantity)
        external
        payable
        callerIsUser
        genesisSaleStarted
        onlyGenesisWhitelisted
        returns (uint256[] memory)
    {
        require(
            msg.value >= genesisSaleMintPrice * quantity,
            "Not enough Ether to claim the ArityTokens"
        );
        
        require(availableArityTokens.length >= quantity, "Not enough arity tokens left");

        require(quantity + genesisMintedTokens <= genesisSaleLimit, "No more arity tokens left for genesis sale");

        require(quantity <= maxArityTokensPerTransaction, "Max tokens per transaction can be 25");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedArityTokenPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;
        genesisMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getArityTokenToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
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
     * @dev Returns how many ArityTokens are still available to be claimed
     */
    function getAvailableArityTokens() external view returns (uint256) {
        return availableArityTokens.length;
    }

    /**
     * @dev Returns the claim price for public mint
     */
    function getPublicMintPrice() external view returns (uint256) {
        return publicMintPrice;
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
    function totalPresaleMintCount() external view virtual returns (uint256) {
        return presaleMintedTokens;
    }

    function totalGenesisMintCount() external view virtual returns (uint256) {
        return genesisMintedTokens;
    }

    // Private and Internal functions

    /**
     * @dev Returns a random available ArityToken to be claimed
     */
    function getArityTokenToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableArityTokens.length);
        uint256 tokenId = uint256(availableArityTokens[random]);

        availableArityTokens[random] = availableArityTokens[availableArityTokens.length - 1];
        availableArityTokens.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableArityTokens.length,
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