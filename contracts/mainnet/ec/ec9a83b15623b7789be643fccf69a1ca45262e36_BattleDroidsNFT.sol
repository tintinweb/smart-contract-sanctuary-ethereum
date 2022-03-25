// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract BattleDroidsNFT is ERC721 {
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

    modifier WLSaleStarted() {
        require(
            startWhitelistSaleDate != 0 && startWhitelistSaleDate <= block.timestamp,
            "Whitelist sale is not open"
        );

        _;
    }

    modifier saleIsActive() {
        require(isSaleActive, "Sale is currently not active");
        _;
    }

    struct Collaborators {
        address addr;
        uint256 cut;
    }

    enum SaleType {
        WHITELIST,
        PRESALE,
        PUBLIC
    }

    SaleType currentSaleType = SaleType.WHITELIST;

    bool isSaleActive = true;

    uint256 private startWhitelistSaleDate = 1648159200;
    uint256 private startPublicClaimDate = 1648508400;
    uint256 private startPresaleDate = 1648504800;

    uint256 private whitelistSaleMintPrice = 100000000000000000;
    uint256 private presaleMintPrice = 150000000000000000;
    uint256 private publicMintPrice = 200000000000000000;

    uint256 public whitelistMintedTokens = 0;
    uint256 public totalMintedTokens = 0;
    uint256 public presaleMintedTokens = 0;

    uint256 private maxBDTokensPerTransaction = 3;

    uint128 private basisPoints = 10000;
    
    string private baseURI = "";
    
    uint256 public giveawayCount = 250;
    
    uint256 public whitelistSaleLimit = 3000;
    uint256 public presaleLimit = 4500;

    mapping(address => uint256) private claimedBDTokenPerWallet;

    uint16[] availableBDTokens;
    Collaborators[] private collaborators;

    mapping (address => bool) presaleWhitelistedAddresses;
    mapping (address => bool) whitelistAddresses;

    constructor() ERC721(" Battle Droids NFT Collection", "BDN") {
    }

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
     * @dev Sets the claim price for each BD token
     */
    function setPublicMintPrice(uint256 _publicMintPrice) external onlyCollaborator {
        publicMintPrice = _publicMintPrice;
    }

    /**
     * @dev Sets the presale claim price for each BD token
     */
    function setPresaleMintPrice(uint256 _presaleMintPrice) external onlyCollaborator {
        presaleMintPrice = _presaleMintPrice;
    }

    /**
     * @dev Sets the whitelist sale claim price for each BD token
     */
    function setWhitelistSaleMintPrice(uint256 _whitelistSaleMintPrice) external onlyCollaborator {
        whitelistSaleMintPrice = _whitelistSaleMintPrice;
    }

     /**
     * @dev Sets the date that users can start claiming BD tokens
     */
    function setStartPublicClaimDate(uint256 _startPublicClaimDate)
        external
        onlyCollaborator
    {
        startPublicClaimDate = _startPublicClaimDate;
    }

    /**
     * @dev Sets the date that users can start claiming BD tokens for presale
     */
    function setStartPresaleDate(uint256 _startPresaleDate)
        external
        onlyCollaborator
    {
        startPresaleDate = _startPresaleDate;
    }

    /**
     * @dev Sets the date that users can start claiming BD tokens for whitelist sale
     */
    function setStartWhitelistSaleDate(uint256 _startWhitelistSaleDate)
        external
        onlyCollaborator
    {
        startWhitelistSaleDate = _startWhitelistSaleDate;
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
     * @dev Sets the whitelist sale limit for whitelistSale
     */
    function setWhitelistSaleLimit(uint256 _whitelistSaleLimit)
        external
        onlyCollaborator
    {
        whitelistSaleLimit = _whitelistSaleLimit;
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
    function setMaxBDTokensPerTransaction(uint256 _maxBDTokensPerTransaction)
        external
        onlyCollaborator
    {
        maxBDTokensPerTransaction = _maxBDTokensPerTransaction;
    }

    /**
     * @dev Populates the available BD tokens
     */
    function addAvailableBDTokens(uint16 from, uint16 to)
        external
        onlyCollaborator
    {
        for (uint16 i = from; i <= to; i++) {
            availableBDTokens.push(i);
        }
    }

    /**
     * @dev Removes a chosen BD token from the available list, only a utility function
     */
    function removeBDTokenFromAvailableBDTokens(uint16 tokenId)
        private
    {
        for (uint16 i; i <= availableBDTokens.length; i++) {
            if (availableBDTokens[i] != tokenId) {
                continue;
            }

            availableBDTokens[i] = availableBDTokens[availableBDTokens.length - 1];
            availableBDTokens.pop();

            break;
        }
    }

    function burnBDTokens(uint16[] memory tokenIDs) external onlyCollaborator {
        for (uint16 i; i < tokenIDs.length; i++) {
            removeBDTokenFromAvailableBDTokens(tokenIDs[i]);
        }
    }

    /**
     * @dev Checks if a BD token is in the available list
     */
    function isBDTokenAvailable(uint16 tokenId)
        external
        view
        onlyCollaborator
        returns (bool)
    {
        for (uint16 i; i < availableBDTokens.length; i++) {
            if (availableBDTokens[i] == tokenId) {
                return true;
            }
        }

        return false;
    }


    /**
     * @dev Give random giveaway BD tokens to the provided address
     */
    function reserveGiveawayBDTokens(address _address)
        external
        onlyCollaborator
    {
        require(availableBDTokens.length >= giveawayCount, "No BD tokens left to be claimed");
        
        totalMintedTokens += giveawayCount;

        uint256[] memory tokenIds = new uint256[](giveawayCount);

        for (uint256 i; i < giveawayCount; i++) {
            tokenIds[i] = getBDTokenToBeClaimed();
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
    * @dev Whitelist addresses for whitelist sale
     */
    function whitelistAddressForWhitelistSale (address[] memory users) external onlyCollaborator {
        for (uint i = 0; i < users.length; i++) {
            whitelistAddresses[users[i]] = true;
        }
    }

    // END ONLY COLLABORATORS

    /**
     * @dev Claim up to 25 BD tokens at once in public sale
     */
    function claimBDTokens(uint256 quantity)
        internal
        callerIsUser
        claimStarted
        returns (uint256[] memory)
    {
        require(availableBDTokens.length >= quantity, "Not enough BD tokens left");

        require(quantity <= maxBDTokensPerTransaction, "Max tokens per transaction can be 25");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedBDTokenPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getBDTokenToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
        return tokenIds;
    }

    /**
     * @dev Claim up to 25 BD tokens at once in presale
     */
    function presaleMintBDTokens(uint256 quantity)
        internal
        callerIsUser
        presaleStarted
        returns (uint256[] memory)
    {
        
        require(availableBDTokens.length >= quantity, "Not enough BD tokens left");

        require(quantity + presaleMintedTokens <= presaleLimit, "No more BD tokens left for presale");

        require(quantity <= maxBDTokensPerTransaction, "Max tokens per transaction can be 25");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedBDTokenPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;
        presaleMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getBDTokenToBeClaimed();
        }

        _batchMint(msg.sender, tokenIds);
        return tokenIds;
    }

    /**
     * @dev Claim up to 25 BD tokens at once in whitelist sale
     */
    function whitelistSaleMintBDTokens(uint256 quantity)
        internal
        callerIsUser
        WLSaleStarted
        returns (uint256[] memory)
    {
        
        require(availableBDTokens.length >= quantity, "Not enough BD tokens left");

        require(quantity + whitelistMintedTokens <= whitelistSaleLimit, "No more BD tokens left for whitelist sale");

        require(quantity <= maxBDTokensPerTransaction, "Max tokens per transaction can be 25");

        uint256[] memory tokenIds = new uint256[](quantity);

        claimedBDTokenPerWallet[msg.sender] += quantity;
        totalMintedTokens += quantity;
        whitelistMintedTokens += quantity;

        for (uint256 i; i < quantity; i++) {
            tokenIds[i] = getBDTokenToBeClaimed();
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
     * @dev Returns how many BDTokens are still available to be claimed
     */
    function getAvailableBDTokens() external view returns (uint256) {
        return availableBDTokens.length;
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

    function totalWhitelistMintCount() external view virtual returns (uint256) {
        return whitelistMintedTokens;
    }

    function getCurrentSaleType() external view virtual returns (string memory) {
        if (currentSaleType == SaleType.WHITELIST) {
            return "Whitelist";
        }
        else if (currentSaleType == SaleType.PRESALE) {
            return "Presale";
        }
        else {
            return "Public sale";
        }
    }

    function setCurrentSaleType(SaleType _type) external virtual returns (string memory) {
        currentSaleType = _type;
        if (currentSaleType == SaleType.WHITELIST) {
            return "Whitelist";
        }
        else if (currentSaleType == SaleType.PRESALE) {
            return "Presale";
        }
        else {
            return "Public sale";
        }
    }

    function currentSalePrice() external view virtual returns (uint256) {
        if (currentSaleType == SaleType.WHITELIST) {
            return whitelistSaleMintPrice;
        }
        else if (currentSaleType == SaleType.PRESALE) {
            return presaleMintPrice;
        }
        else {
            return publicMintPrice;
        }
    }

    function toggleSale(bool _value)
    external
    onlyCollaborator
    returns (bool) {
        isSaleActive = _value;
        return _value;
    }

    function saleStatus() external view returns (bool) {
        return isSaleActive;
    }

    function mintBDToken(uint256 quantity) 
        external
        payable
        callerIsUser
        saleIsActive
        returns (uint256[] memory) {
            if (currentSaleType == SaleType.WHITELIST) {
                require(
            msg.value >= whitelistSaleMintPrice * quantity,
            "Not enough Ether to claim the BDTokens"
        );
            return whitelistSaleMintBDTokens(quantity);
        }
        else if (currentSaleType == SaleType.PRESALE) {

        require(
            msg.value >= presaleMintPrice * quantity,
            "Not enough Ether to claim the BDTokens"
        );
            return presaleMintBDTokens(quantity);
        }
        else {

        require(
            msg.value >= publicMintPrice * quantity,
            "Not enough Ether to claim the BDTokens"
        );

            return claimBDTokens(quantity);
        }
        }

    // Private and Internal functions

    /**
     * @dev Returns a random available BDToken to be claimed
     */
    function getBDTokenToBeClaimed() private returns (uint256) {
        uint256 random = _getRandomNumber(availableBDTokens.length);
        uint256 tokenId = uint256(availableBDTokens[random]);

        availableBDTokens[random] = availableBDTokens[availableBDTokens.length - 1];
        availableBDTokens.pop();

        return tokenId;
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableBDTokens.length,
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