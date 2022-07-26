// SPDX-License-Identifier: MIT
/***
 *  
 *  8""""8                      
 *  8      eeeee ee   e eeee    
 *  8eeeee 8   8 88   8 8       
 *      88 8eee8 88  e8 8eee    
 *  e   88 88  8  8  8  88      
 *  8eee88 88  8  8ee8  88ee    
 *  ""8""                       
 *    8   e   e eeee            
 *    8e  8   8 8               
 *    88  8eee8 8eee            
 *    88  88  8 88              
 *    88  88  8 88ee            
 *  8""""8                      
 *  8    8 eeeee eeeee eeee     
 *  8e   8 8   8   8   8        
 *  88   8 8eee8   8e  8eee     
 *  88   8 88  8   88  88       
 *  88eee8 88  8   88  88ee     
 *  
 */

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";
import "./Counters.sol";

/**
 * @title Save The Date
 * 
 * @notice Everyone has at least one day they hold dear. It may be a birthday, an anniversary, a moment, a memory.
 *         SAVE THE DATE is an NFT project that lets you hold your DATE and continue to celebrate it forever.
 *         Feel.
 *         By creating 1/1 NFT DATEs, each representing 1 day over the last 50 years, we only need to ask which DATE means the world to you?
 *         Celebrate.
 *         After you secure your DATE, in the first year, your DATE will unlock 4 FREE art pieces made by well known artists and all integrate your DATE.
 *         For our first drop, we are excited to announce a partnership with Amber Vittoria.
 *         In addition to the art, DATE holders receive a Celebration Package worth hundreds of dollars of exclusive promotions and benefits from partner 
 *         hotels, restaurants, and brands that would help you celebrate your cherished DATEs.
 * -------------------------------------------------
 * @custom:website https://whatisyourdate.xyz
 * @author Dariusz Tyszka (ArchXS)
 * @custom:security-contact [email protected]
 */
contract SaveTheDate is ERC721, Ownable {
    using Counters for Counters.Counter;

    /**
     * @dev Structure representing date to mint as NFT.
     */
    struct DateToMint {
        // Year in format: YYYY
        uint256 year;
        // Month in format: MM
        uint256 month;
        // Day in format: dd
        uint256 day;
        // Wheter the date is randomly selected
        bool isRandom;
        // Additional data veryfing the mint call
        bytes pass;
    }

    /**
     * @dev Structure used to track miniting occurances.
     */
    struct DateToken {
        uint256 tokenId;
        bool isReserved;
        address booker;
    }

    /**
     * @dev Structure used to track drop tiers.
     */
    struct DropTier {
        uint256 pieces;
        bool isRevealed;
        uint256 counter;
        uint256 regularPrice;
        uint256 discountedPrice;
    }

    /**
     * @dev Structure used to track drop tiers.
     */
    struct CommunityClaim {
        address tokenContract;
        uint256[] eligibleTokens;
        bool isExempt;
        uint256 maxMints;
    }

    /**
     * @dev Enum used to distinguish minting types.
     */
    enum MintType {
        Bestowal,
        Presale,
        Public
    }

    /**
     * @dev Enum used to distinguish sale phases.
     */
    enum SalesPhase {
        Locked,
        Presale,
        Public
    }

    enum DateStatus {
        Reserved,
        Minted
    }

    uint256 private constant DEFAULT_TOKEN_SUPPLY = 18250;
    uint256 private constant DEFAULT_WALLET_LIMIT = 4;
    uint256 private constant DEFAULT_INCLUSIVE_YEAR = 1972;
    uint256 private constant DEFAULT_EXCLUSIVE_YEAR = 2021;
    uint256 private constant DEFAULT_RELEASE_HOURS = 24;
    uint256 private constant DEFAULT_GIFTS_SUPPLY = 500;

    bytes32 public merkleRoot;
    mapping(address => uint256) public datesClaimed;
    mapping(string => DateStatus) public mintedDates;
    mapping(uint256 => string) private _tokenDateURIs;

    string public uriSuffix = ".json";
    uint256 public _price = 0.1 ether;
    uint256 public _randomDatePrice = 0.05 ether;

    bool public suspendedSale = false;
    bool public frozenMetadata = false;
    
    SalesPhase public salesPhase = SalesPhase.Locked;
    uint256 public tokenSupply;
    uint256 public donatedSupply;

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _donatedCounter;
    
    uint256 private _reservedCounter = 0;

    string private _baseTokenUri; 
    string private _contractUri;
    uint256 private _presaleStartTimestamp;
    uint256 private _releaseDatesHours;

    address payable private _donorWallet;
    
    mapping(address => string) private _occupiedDates;
    uint256 private _dropSeriesCount = 0;

    // collection contract => token Id => claimer wallet
    mapping(address => mapping(uint256 => address)) private _exepmtClaims;

    /**
     * @dev Initializes contract with: 
     *
     * @param contractUri Token contract URI for collection of dates.
     */
    constructor(string memory contractUri, address donorWallet) ERC721("SaveTheDate", "STDT") {
        _contractUri = contractUri;
        _releaseDatesHours = DEFAULT_RELEASE_HOURS;
        tokenSupply = DEFAULT_TOKEN_SUPPLY;
        donatedSupply = DEFAULT_GIFTS_SUPPLY;
        _donorWallet = payable(donorWallet);
    }


    /**
     * @dev Managing sale phases. 
     * @param phase The specific sale phase. Only subsequent Could be provided.
     */
    function beginPhase(SalesPhase phase) external onlyOwner {
		require(uint8(phase) > uint8(salesPhase), "Only next phase possible");

		salesPhase = phase;
        // Pre-sale timestamp
        if (phase == SalesPhase.Presale) {
            _presaleStartTimestamp = block.timestamp;
        }
	}

    /**
     * @dev Allows the metadata to be prevented from being changed.
     * @notice Irreversibly!
     */
    function freezeMetadata() external onlyOwner {
		require(!frozenMetadata, "Already frozen");
		frozenMetadata = true;
	}

    /**
     * @dev The address of donor wallet.
     */
    function setDonorWallet(address wallet) external onlyOwner {
        _donorWallet = payable(wallet);
    }

    /**
     * @notice Is used to set the base URI used after reveal.
     * @param tokenUri Base URI for all tokens after reveal.
     */
    function setBaseUri(string memory tokenUri) public onlyOwner {
        require(!frozenMetadata, "Has been frozen"); 
        _baseTokenUri = tokenUri;
    }

    /**
     * @notice Opensea related metadata of the smart contract.
     * @param contractUri Storefront-level metadata for contract.
     */
    function setContractUri(string memory contractUri) external onlyOwner {
        _contractUri = contractUri;
    }

    function setUriSuffix(string memory suffix) public onlyOwner {
        require(!frozenMetadata, "Has been frozen");
        uriSuffix = suffix;
    }

    function setMerkleRoot(bytes32 newRoot) public onlyOwner {
        merkleRoot = newRoot;
    }

    /**
     * @notice Allows an emergency stop of sale at any time.
     * @param suspended - true if sale is supposed to be suspended.
     */
    function setSuspendedSale(bool suspended) external onlyOwner {
        suspendedSale = suspended;
    }

    function tokenCount() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function donatedCount() public view returns (uint256) {
        return _donatedCounter.current();
    }

    function availableTokenCount() public view returns (uint256) {
        return tokenSupply - (donatedSupply - donatedCount()) - tokenCount();
    }

    function nextToken() internal virtual returns (uint256) {
        _tokenIdCounter.increment();
        uint256 token = _tokenIdCounter.current();
        return token;
    }

    /**
     * @notice Opensea related metadata of the smart contract.
     * @return Storefront-level metadata for contract.
     */
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override (ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenDateURIs[tokenId];

        string memory base = _baseURI();
        string memory _tokenDateURI = _tokenURI;

        if (bytes(base).length > 0) {
           _tokenDateURI =  string(abi.encodePacked(base, _tokenURI));
        }

        if (bytes(uriSuffix).length > 0) {
            return string(abi.encodePacked(_tokenDateURI, uriSuffix));
        }

        return _tokenURI;
    }

    /**
     * @notice Returns the string representing date for a given token ID.
     * @param tokenId The token ID.
     * @return The date minted with this token.
     */
    function dateByToken(uint256 tokenId) external view returns (string memory) {
        return _tokenDateURIs[tokenId];
    }


    function checkDateAvailability(string memory tokenDate) public view returns (bool) {
        return (mintedDates[tokenDate] != DateStatus.Reserved && mintedDates[tokenDate] != DateStatus.Minted);
    }

    /**
     * @notice Date reservations are held until the specified time period, 
     * after which they are cancelled.
     * @return true if reservations are still kept valid.
     */
    function checkReservationUpheld() public view returns (bool) {
        return (salesPhase == SalesPhase.Presale && block.timestamp <= (_presaleStartTimestamp + (_releaseDatesHours * 3600)));
    }

    /**
     * @notice Check if the caller is on the whitelist
     */
    function verifyWhitelist(bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    /**
     * @notice Check validity of the given date
     * @param date The object representing date by respectively year, month and day.
     * @return true if date is valid to mint.
     */
    function validateDate(DateToMint calldata date) public pure returns (bool) {
        return _verifyDate(date.year, date.month, date.day);
    }


    /**
     * @notice Date minting function
     * @param tokenDate The object representing the date by respectively year, month and day.
     * @param merkleProof Proof data for vverification against whitelist, empty for public sale.
     * @return Token ID.
     */
    function mintDate(DateToMint calldata tokenDate, bytes32[] calldata merkleProof) external payable ensureAvailability returns (uint256) {

        require(suspendedSale == false, "The sale is suspended");
       // require(salesPhase == SalesPhase.Presale || salesPhase == SalesPhase.Public, "Sale is not active");
        
        bool _eligibleCommunity = false;
        bool _communityExempt = false;

        uint256 tokenPrice = (_communityExempt ? 0 : _price);

        if (tokenDate.isRandom && !_communityExempt && _validateDiscount(tokenDate)) {
            tokenPrice = _randomDatePrice;
        } 

        require(msg.value >= tokenPrice, "Not enough ETH sent; check price!");
        require(datesClaimed[_msgSender()] + 1 <= DEFAULT_WALLET_LIMIT, "Dates already claimed");

        if (salesPhase == SalesPhase.Presale && !_eligibleCommunity && !_communityExempt) {
            require(merkleRoot.length > 0, "Presale forbidden");
            require(verifyWhitelist(merkleProof), "Not allowed at presale");
        } 

        require(_verifyDate(tokenDate.year, tokenDate.month, tokenDate.day), "Invalid date");

        string memory _tokenDate = _dateToString(tokenDate);
        require(checkDateAvailability(_tokenDate), "Date is unavailable");
        uint256 tokenId = nextToken();
        _safeMint(_msgSender(), tokenId);
        _setTokenDateURI(tokenId, _tokenDate);
        mintedDates[_tokenDate] = DateStatus.Minted;

        datesClaimed[_msgSender()]++;

        return tokenId;
    }

    /**
     * @dev Special minting function
     */
    function mintDonatedDate(DateToMint calldata tokenDate, address recipient) public ensureAvailability onlyOwner {
        require(donatedCount() + 1 <= donatedSupply, "Gifts run out");

        string memory _tokenDate = _dateToString(tokenDate);
        require(checkDateAvailability(_tokenDate), "Date is unavailable");
        uint256 tokenId = nextToken();

        _safeMint(recipient, tokenId);
        _setTokenDateURI(tokenId, _tokenDate);
        mintedDates[_tokenDate] = DateStatus.Minted;
        _donatedCounter.increment();   
    }

    /**
     * @dev Special batch date reservation function
     */
    function reserveDates(DateToMint[] calldata bookedDates, address[] calldata bookers) external onlyOwner {
        require(bookedDates.length == bookers.length, "Invalid call data");   
        for (uint i = 0; i < bookedDates.length; i++) {
            reserveDate(bookedDates[i]);
        }

         _reservedCounter = _reservedCounter + bookedDates.length;
    }

    /**
     * @dev Special date reservation function
     */
    function reserveDate(DateToMint calldata bookedDate) public onlyOwner {
        string memory _tokenDate = _dateToString(bookedDate);
        require(checkDateAvailability(_tokenDate), "Date is unavailable");
        require(_verifyDate(bookedDate.year, bookedDate.month, bookedDate.day), "Date is invalid");        
        mintedDates[_tokenDate] = DateStatus.Reserved; 
    }

    /**
     * @dev Special batch release date function
     */
    function releaseDates(DateToMint[] calldata bookedDates, address[] calldata bookers) external onlyOwner {
        require(bookedDates.length == bookers.length, "Invalid call data");
        
        for (uint i = 0; i < bookedDates.length; i++) {
            releaseDate(bookedDates[i]);
        }
        _reservedCounter = _reservedCounter - bookedDates.length;
    }

    /**
     * @dev Special release date function
     */
    function releaseDate(DateToMint calldata bookedDate) public onlyOwner {
        string memory _tokenDate = _dateToString(bookedDate);
        require(checkDateAvailability(_tokenDate), "Date is unavailable");
        delete mintedDates[_tokenDate];
    }

    // *******************
    // Internal functions
    // *******************
    /**
     * @dev Allows for validating if the token minting data orygins from official STD app.
     */
    function _validateDiscount(DateToMint calldata tokenDate) internal view returns (bool) {
        if (tokenDate.pass.length > 0) {
            string memory _date = _dateToString(tokenDate);
            bytes32 hash = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_date)));
            return (owner() == ECDSA.recover(hash, tokenDate.pass));
        } else {
            return false;
        }
    }

    function _setTokenDateURI(uint256 tokenId, string memory _tokenDate) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenDateURIs[tokenId] = _tokenDate;
    }

    function _baseURI() internal view virtual override (ERC721) returns (string memory) {
        return _baseTokenUri;
    }

    // *******************
    // Modifiers
    // *******************
    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "Tokens unavailable");
        _;
    }

    // *******************
    // Utilities
    // *******************

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "PCS: No ether left to withdraw");
        Address.sendValue(_donorWallet, balance);
    }

    /*
     * @dev Formating the date data to date string.
     */
    function _dateToString(DateToMint calldata date) internal pure returns (string memory tokenDate) {
        string memory monthSuffix = date.month < 10 ? "0" : "";
        string memory daySuffix = date.day < 10 ? "0" : "";
        tokenDate = string(abi.encodePacked(Strings.toString(date.year), monthSuffix, Strings.toString(date.month), daySuffix, Strings.toString(date.day)));
    }
    
    /*
     * @dev Checking the validity of the specific date data.
     */
    function _verifyDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
        if (month > 0 && month <= 12) {
            uint256 daysInMonth = _daysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function _isLeapYear(uint256 year) internal pure returns (bool) {
        return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function _daysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) { 
        if (month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }
}