// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './libraries/ERC721A.sol';
import "./interfaces/IWord.sol";
import "./interfaces/IMintverseWord.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
 * ███╗   ███╗██╗███╗   ██╗████████╗██╗   ██╗███████╗██████╗ ███████╗███████╗    ██╗    ██╗ ██████╗ ██████╗ ██████╗ 
 * ████╗ ████║██║████╗  ██║╚══██╔══╝██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    ██║    ██║██╔═══██╗██╔══██╗██╔══██╗
 * ██╔████╔██║██║██╔██╗ ██║   ██║   ██║   ██║█████╗  ██████╔╝███████╗█████╗      ██║ █╗ ██║██║   ██║██████╔╝██║  ██║
 * ██║╚██╔╝██║██║██║╚██╗██║   ██║   ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      ██║███╗██║██║   ██║██╔══██╗██║  ██║
 * ██║ ╚═╝ ██║██║██║ ╚████║   ██║    ╚████╔╝ ███████╗██║  ██║███████║███████╗    ╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝
 * ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝     ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝     ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ 
 *                                                                                                        @ryanycw                                                                                                             
 *                                                                                                                                                                                     
 *      第二宇宙辭典 鑄造宣言
 *   1. 即使舊世界的文明已經滅亡，我們仍相信文字保存了曾有的宇宙。
 *   2. 我們不排斥嶄新的當代文明，只是相信古老的符號裡，仍含有舊世界人類獨得之奧秘。
 *   3. 我們不相信新世界與舊世界之間，是毫無關聯的兩個文明。
 *   4. 我們相信在最簡單的線條裡，有最豐滿的形象、顏色與場景。
 *   5. 我們確知一切最複雜的思想，必以最單純的音節組成。
 *   6. 我們相信文字永不衰亡，只是沉睡。喚醒文字的方式，便是釋義、辨析、定義、區分⋯⋯。
 *   7. 我們不執著於「正確」，我們更信任「想像」。因為，從線條聯想物象，音節捕捉概念，正是人類文明的輝煌起點。
 *   8. 它是什麼意思；它不是什麼意思——這些都很重要。但最重要的是：它「還可以」是什麼意思？
 *   9. 我們熱愛衝突，擁抱矛盾，因為激烈碰撞所能引出的奧秘，遠勝於眾口一聲的意見。   
 *  10. 我們堅決相信：在我們降生群聚的第一宇宙之外、之間、之前、之後，還有一個值得我們窮盡想像力去探索的第二宇宙。
 */ 

contract IMintverseWordStorage is IWord {
    // Metadata Variables
    mapping(uint256 => TokenInfo) public tokenItem;
    // Mint Record Variables
    mapping(address => bool) public mintedByAddress;
    mapping(address => bool) public purchaseDictionaryCheckByAddress;
    mapping(address => uint256) public whitelistMintAmount;
    // Phase Limitation Variables
    bool public mintWhitelistEnable;
    bool public mintPublicEnable;
    uint256 public mintWhitelistTimestamp;
    uint256 public mintPublicTimestamp;
    uint48 public revealTimestamp;
    // Mint Record Variables
    uint16 public totalDictionary;
	uint16 public totalWordGiveaway;
    uint16 public totalWordWhitelist;
    // Mint Limitation Variables
    uint256 public MAX_MINTVERSE_RANDOM_WORD;
    uint256 public MAX_MINTVERSE_GIVEAWAY_WORD;
    uint256 public MAX_MINTVERSE_DICTIONARY;
    uint256 public DICT_ADDON_PRICE;
    uint48 public WORD_EXPIRATION_TIME;
    uint16 public HEAD_RANDOM_WORDID;
    uint16 public TAIL_RANDOM_WORDID;
    uint16 public SETTLE_HEAD_TOKENID;
    uint16 public DESIGNATED_WORDID_OFFSET;
    // Governance Variables
	address public treasury;
    string public baseTokenURI;
    // Mapping Off-Chain Storage
    string public legalDocumentURI;
    string public systemMechanismDocumentURI;
    string public animationCodeDocumentURI;
    string public visualRebuildDocumentURI;
    string public ERC721ATechinalDocumentURI;
    string public wordIdMappingDocumnetURI;
    string public partOfSpeechIdMappingDocumentURI;
    string public categoryIdMappingDocumentURI;
    string public metadataMappingDocumentURI;
}

contract MintverseWord is IMintverseWord, IMintverseWordStorage, Ownable, EIP712, ERC721A {

    using SafeMath for uint16;
    using SafeMath for uint48;
    using SafeMath for uint256;
	using Strings for uint256;

    constructor()
    EIP712("MintverseWord", "1.0.0")
    ERC721A("MintverseWord", "MVW")     
    {
        mintWhitelistEnable = true;
        mintPublicEnable = true;
        mintWhitelistTimestamp = 1651752000;
        mintPublicTimestamp = 1652155200;
        revealTimestamp = 1652068800;

        MAX_MINTVERSE_RANDOM_WORD = 1900;
        MAX_MINTVERSE_GIVEAWAY_WORD = 200;
        MAX_MINTVERSE_DICTIONARY = 185;
        DICT_ADDON_PRICE = 0.15 ether;
        WORD_EXPIRATION_TIME = 42 hours;
        TAIL_RANDOM_WORDID = 1900;
        SETTLE_HEAD_TOKENID = TAIL_RANDOM_WORDID;
        DESIGNATED_WORDID_OFFSET = uint16(TAIL_RANDOM_WORDID.mul(2));

        treasury = 0xbA53C6831B496c8a40c02A3c2d1366DfC6503F4e;
        baseTokenURI = "https://api.mintverse.world/word/metadata/";
        legalDocumentURI = "";
        systemMechanismDocumentURI = "";
        animationCodeDocumentURI = "";
        visualRebuildDocumentURI = "";
        ERC721ATechinalDocumentURI = "";
        wordIdMappingDocumnetURI = "";
        partOfSpeechIdMappingDocumentURI = "";
        categoryIdMappingDocumentURI = "";
        metadataMappingDocumentURI = "";
    }

    /**
     * Modifiers
     */
    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownershipOf(tokenId).addr == msg.sender, "Can't define - Not the word owner");
        _;
    }

    modifier mintWhitelistActive() {
		require(mintWhitelistEnable == true, "Can't mint - WL mint phase hasn't enable");
        require(block.timestamp >= mintWhitelistTimestamp, "Can't mint - WL mint phase hasn't started");
        _;
    }

    modifier mintPublicActive() {
		require(mintPublicEnable == true, "Can't mint - Public mint phase hasn't enable");
        require(block.timestamp >= mintPublicTimestamp, "Can't mint - Public mint phase hasn't started");
        _;
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Invalid caller - Caller is a Contract");
        _;
    }

    modifier wordNotExpired(uint256 tokenId){
        require((block.timestamp > tokenItem[tokenId].mintTime) || tokenItem[tokenId].defined, "Invalid Block Time - Mint time shouldn't be larger than current time");
        require((block.timestamp <= (tokenItem[tokenId].mintTime + WORD_EXPIRATION_TIME)) || tokenItem[tokenId].defined, "Invalid Block Time - This token is expired");
        _;
    }

    /**
     * Verify Functions
     */
    /** @dev Verify if a address is eligible to mint a specific amount
     * @param SIGNATURE Signature used to verify the minter address and amount of claimable tokens
     */
    function verify(
        uint256 maxQuantity,
        bytes calldata SIGNATURE
    ) 
        public 
        override
        view 
        returns(bool)
    {
        address recoveredAddr = ECDSA.recover(_hashTypedDataV4(keccak256(abi.encode(keccak256("NFT(address addressForClaim,uint256 maxQuantity)"), _msgSender(), maxQuantity))), SIGNATURE);
        return owner() == recoveredAddr;
    }

    /**
     * Mint Functions
     */
    /** @dev Record dictionary addon for a an address as owner
     * @param to Address to record dictionary addon
     * @param addon True if recording giveaway dictionary to the "to" address, otherwise false
     */
    function mintGiveawayDictionary(
        address to, 
        bool addon
    ) 
        external
        override
        onlyOwner
    {   
        _mintGiveawayDictionary(to, addon);
    }

    /** @dev Mint word token to an address with specific amount of tokens as owner
     * @param to Address to transfer the tokens
     * @param wordId Designated wordId of the giveaway tokens
     * @param mintTimestamp Timestamp to start the countdown for expiration
     */
    function mintGiveawayWord(
        address to, 
        uint16 wordId,
        uint48 mintTimestamp
    ) 
        external
        override
        onlyOwner
    {   
        require(totalWordGiveaway.add(1) <= MAX_MINTVERSE_GIVEAWAY_WORD, "Exceed maximum word amount");
        totalWordGiveaway = uint16(totalWordGiveaway.add(1));
        _mintDesignatedWord(to, wordId, mintTimestamp);

		emit mintWordEvent(to, 1, totalSupply());
    }

    /** @dev Mint word token as Whitelisted Address
     * @param quantity Amount of tokens the address wants to mint
     * @param maxClaimNum Maximum amount of word tokens the address can mint
     * @param addon True if recording giveaway dictionary to the "to" address, otherwise false
     * @param SIGNATURE Signature used to verify the minter address and amount of claimable tokens
     */
    function mintWhitelistWord(
        uint256 quantity,
        uint256 maxClaimNum, 
        bool addon,
        bytes calldata SIGNATURE
    ) 
        external 
        payable
        override
        mintWhitelistActive
        callerIsUser
    {
        require(verify(maxClaimNum, SIGNATURE), "Can't claim - Not eligible");
        require(_getRandomWordMintCnt().add(quantity) <= MAX_MINTVERSE_RANDOM_WORD, "Exceed maximum word amount");
        require(quantity > 0 && whitelistMintAmount[msg.sender].add(quantity) <= maxClaimNum, "Exceed maximum mintable whitelist amount");
        
        mintedByAddress[msg.sender] = true;
        whitelistMintAmount[msg.sender] = whitelistMintAmount[msg.sender].add(quantity);
        totalWordWhitelist = uint16(totalWordWhitelist.add(quantity));
        _mintPublicDictionary(msg.sender, addon);

        for(uint16 index=0; index < quantity; index++) {
            _mintRandomWord(msg.sender);
        }
        
        emit mintWordEvent(msg.sender, quantity, totalSupply());
    }

    /** @dev Mint word token as Public Address
     * @param addon True if recording giveaway dictionary to the "to" address, otherwise false
     */
    function mintPublicWord(
        bool addon
    )
        external
        payable 
        override
        mintPublicActive
        callerIsUser
    {
        require(mintedByAddress[msg.sender]==false, "Already minted you naughty, leave some word for others");
        require(_getRandomWordMintCnt().add(1) <= MAX_MINTVERSE_RANDOM_WORD, "Exceed maximum word amount");
            
        mintedByAddress[msg.sender] = true;
        _mintPublicDictionary(msg.sender, addon);
        _mintRandomWord(msg.sender);

        emit mintWordEvent(msg.sender, 1, totalSupply());
    }

    /** @dev Calculate the token counts for random words, which is total supply substract the giveaway amount
     */
    function _getRandomWordMintCnt()
        private
        view
        returns(uint16 randomWordMintCnt)
    {
        return uint16(totalSupply().sub(totalWordGiveaway));
    }

    /** @dev Calculate the token timestamp for expiration calculation
     *       If the mint timestamp is before reveal, then set at reveal
     *       If the mint timestamp is after reveal, then set at mint current time
     */
    function _getCurWordTimestamp()
        private
        view
        returns(uint48 curWordTimestamp)
    {
        if(block.timestamp <= revealTimestamp) return revealTimestamp;
        else return uint48(block.timestamp);
    }

    /** @dev Calculate the token's corresponding wordId
     *       If the random token count is smaller than the initial maximum random count, then circulate with the maximum random count - (0 - 1899)
     *       If the token is minted after some tokens are dead, then start from the end of the maximum random count - (1900 - 3799)
     */
    function _getCurWordId()
        private
        view
        returns(uint16 curWordId)
    {
        if(_getRandomWordMintCnt() < TAIL_RANDOM_WORDID) return HEAD_RANDOM_WORDID % TAIL_RANDOM_WORDID;
        else return uint16(_getRandomWordMintCnt());
    }

    /** @dev Set the initial point of the random wordId mapping, using the 1st minter's address and the timestamp
     */
    function _setHeadWordId()
        private
    {
        HEAD_RANDOM_WORDID = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)))) % TAIL_RANDOM_WORDID;
    }

    /** @dev Called by #mintWhitelistWord and #mintPublicWord to mint random words
     * @param to Address to mint the tokens to
     */
    function _mintRandomWord(address to)
        private
    {
        if((totalSupply() - totalWordGiveaway) == 0) _setHeadWordId();

        HEAD_RANDOM_WORDID = uint16(HEAD_RANDOM_WORDID.add(1));
        _mintWord(to, _getCurWordId(), _getCurWordTimestamp());
    }

    /** @dev Called by #mintGiveawayWord to mint the designated words
     * @param to Address to mint the tokens to
     * @param designatedWordId Designated wordId of the giveaway tokens
     * @param mintTimestamp Timestamp to start the countdown for expiration, since the receiver might not be able to start 
     */
    function _mintDesignatedWord(
        address to, 
        uint16 designatedWordId,
        uint48 mintTimestamp
    )
        private
    {
        require(designatedWordId >= DESIGNATED_WORDID_OFFSET, "Invalid wordId - This Id belongs to random Id");
        _mintWord(to, designatedWordId, mintTimestamp);
    }

    /** @dev Called by #_mintDesignatedWord and #_mintRandomWord to mint tokens
     * @param to Address to mint the tokens to
     * @param wordId wordId of the tokens
     * @param mintTimestamp Timestamp to start the countdown for expiration, since the receiver might not be able to start 
     */
    function _mintWord(
        address to,
        uint16 wordId,
        uint48 mintTimestamp
    )
        private
    {
        string memory nullString;

        _safeMint(to, 1);

        tokenItem[totalSupply().sub(1)] = TokenInfo(nullString, nullString, nullString, wordId, 1, 1, 1, mintTimestamp, false);
    }
    
    /** @dev Called by #mintGiveawayWord to record dictionary addon of an address
     * @param to Address to record dictionary addon
     * @param addon True or False, of whether the address wants to purchase the addon
     */
    function _mintPublicDictionary(
        address to,
        bool addon
    )
        private
    {
        _mintDictionary(to, addon, false);
    }

    /** @dev Called by #mintPublicWord and #mintWhitelistWord to record giveaway dictionary addon of an address
     * @param to Address to record dictionary addon
     * @param addon True or False, of whether the address wants to purchase the addon
     */
    function _mintGiveawayDictionary(
        address to,
        bool addon
    )
        private
    {
        _mintDictionary(to, addon, true);
    }

    /** @dev Called by #_mintPublicDictionary and #_mintGiveawayDictionary to record dictionary addon of an address
     * @param to Address to record dictionary addon
     * @param addon True or False, whether the address wants to purchase the addon
     * @param giveaway True or False, whether to check the msg.value 
     *
     * A = Purchase addon dictionary
     * B = Check addon status if caller address purchased already
     * T_A, T_B => No need msg.value, No modification of addon status
     * F_A, T_B => No need msg.value, No modification of addon status
     * T_A, F_B => Need msg.value, Modification of addon status
     * F_A, F_B => No need msg.value, No modification of addon status
     *
     */
    function _mintDictionary(
        address to,
        bool addon,
        bool giveaway
    )
        private
    {
        require(totalDictionary.add(1) <= MAX_MINTVERSE_DICTIONARY, "Exceed maximum dictionary amount");
        if((addon == true) && !(purchaseDictionaryCheckByAddress[to])) {
            if(giveaway == false) require(msg.value == DICT_ADDON_PRICE, "Not the right amount of ether");
            totalDictionary = uint16(totalDictionary.add(1));
            purchaseDictionaryCheckByAddress[to] = addon;
        }
    }

    /**
     * Define Functions
     */
    /** @dev Define word token as token owner wants
     * @param tokenId TokenId that the token owner wants to define
     * @param definer 鑄造者
     * @param partOfSpeech1 詞性1
     * @param partOfSpeech2 詞性2
     * @param relatedWord 同義詞
     * @param description 詮釋
     */
    function defineWord(
        uint256 tokenId, 
        string calldata definer, 
        uint8 partOfSpeech1,
        uint8 partOfSpeech2,
        string calldata relatedWord, 
        string calldata description
    )
        external 
        override
        onlyTokenOwner(tokenId)
        wordNotExpired(tokenId)
    {
        tokenItem[tokenId].definerPart = definer;
        tokenItem[tokenId].relatedWordPart = relatedWord;
        tokenItem[tokenId].descriptionPart = description;
        tokenItem[tokenId].partOfSpeechPart1 = partOfSpeech1;
        tokenItem[tokenId].partOfSpeechPart2 = partOfSpeech2;
        tokenItem[tokenId].defined = true;
        if (tokenItem[tokenId].categoryPart == 2) tokenItem[tokenId].categoryPart = 1;

        emit wordDefinedEvent(tokenId);
    }

    /**
     * Getter Functions
     */
    /** @dev Retrieve word definition metadata by tokenId
     * @param tokenId TokenId which caller wants to get its metadata
     */
    function getTokenProperties(uint256 tokenId)
        public
        view
        override
        returns (
            string memory definer, 
            uint256 wordId,
            uint256 categoryId,
            uint256 partOfSpeechId1,
            uint256 partOfSpeechId2,
            string memory relatedWord,
            string memory description
        )
    {   
        return (
            tokenItem[tokenId].definerPart,
            tokenItem[tokenId].wordPart,
            tokenItem[tokenId].categoryPart,
            tokenItem[tokenId].partOfSpeechPart1,
            tokenItem[tokenId].partOfSpeechPart2,
            tokenItem[tokenId].relatedWordPart,
            tokenItem[tokenId].descriptionPart
        );
    }

    /** @dev Retrieve expiration timestamp of a token by tokenId
     * @param tokenId TokenId which caller wants to get its expiration timestamp
     */
    function getTokenExpirationTime(uint256 tokenId)
        public
        view
        override
        returns(uint256 expirationTime)
    {
        return tokenItem[tokenId].mintTime.add(WORD_EXPIRATION_TIME);
    }

    /** @dev Retrieve the status whether a token has been written by tokenId
     * @param tokenId TokenId which caller wants to get its status of written or not
     */
    function getTokenStatus(uint256 tokenId)
        public
        view
        override
        returns(bool writtenOrNot)
    {
        return tokenItem[tokenId].defined;
    }

    /** @dev Retrieve all word definition metadatas by owner address
     * @param owner Address which caller wants to get all of its metadatas of tokens
     */
    function getTokenPropertiesByOwner(address owner) 
        public 
        view 
        override
        returns (TokenInfo[] memory tokenInfos)
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new TokenInfo[](0);
        } else {
            TokenInfo[] memory result = new TokenInfo[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                uint256 tokenId = tokenOfOwnerByIndex(owner, index);
                result[index] = tokenItem[tokenId];
            }
            return result;
        }
    }

    /** @dev Retrieve all expiration timestamps by owner address
     * @param owner Address which caller wants to get all of its expiration timestamps of tokens
     */
    function getTokenExpirationTimeByOwner(address owner) 
        public 
        view 
        override
        returns (uint256[] memory expirationTimes)
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                uint256 tokenId = tokenOfOwnerByIndex(owner, index);
                result[index] = tokenItem[tokenId].mintTime.add(WORD_EXPIRATION_TIME);
            }
            return result;
        }
    }

    /** @dev Retrieve all defined status of the word tokens by owner address
     * @param owner Address which caller wants to get all its word token defined statuses
     */
    function getTokenStatusByOwner(address owner) 
        public 
        view 
        override
        returns (bool[] memory writtenOrNot)
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new bool[](0);
        } else {
            bool[] memory result = new bool[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                uint256 tokenId = tokenOfOwnerByIndex(owner, index);
                result[index] = tokenItem[tokenId].defined;
            }
            return result;
        }
    }

    /** @dev Retrieve if a address has purchased the dictionary
     * @param owner Address which caller wants to get if it has purchased the dictionary
     */
    function getAddonStatusByOwner(address owner) 
        public 
        view 
        override
        returns (bool addon)
    {
        return purchaseDictionaryCheckByAddress[owner];
    }

    /**
     * Token Functions
     */
    /** @dev Retrieve token URI to get the metadata of a token
     * @param tokenId TokenId which caller wants to get the metadata of
     */
	function tokenURI(uint256 tokenId) 
        public 
        view 
        override 
        returns (string memory curTokenURI) 
    {
		require(_exists(tokenId), "Token doesn't exist");
		return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
	}

    /** @dev Retrieve all tokenIds of a given address
     * @param owner Address which caller wants to get all of its tokenIds
     */
    function tokensOfOwner(address owner) 
        external 
        view 
        override
        returns(uint256[] memory) 
    {
        uint256 tokenCount = balanceOf(owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(owner, index);
            }
            return result;
        }
    }

    /** @dev Retrieve dictionary tokens supply amount
     */
    function getTotalDictionary() 
        public
        view
        override 
        returns (uint256 amount)
    {
        return uint256(totalDictionary);
    }

    /** @dev Retrieve all tokenIds of a given address
     * @param startTokenId Address which caller wants to get all of its tokenIds
     * @param endTokenId test
     * If the token is undefined & have passed 42 hours after mint time, then we settle the token
     */
    function settleExpiredWord(
        uint256 startTokenId, 
        uint256 endTokenId
    )
        override
        external
        onlyOwner
    {
        for(uint256 index = startTokenId; index <= endTokenId; index++) {
            if(!(tokenItem[index].defined) && (block.timestamp > (tokenItem[index].mintTime + WORD_EXPIRATION_TIME))) {
                emit moveWordToTheBack(SETTLE_HEAD_TOKENID, tokenItem[index].wordPart);
                SETTLE_HEAD_TOKENID = uint16(SETTLE_HEAD_TOKENID.add(1));
                MAX_MINTVERSE_RANDOM_WORD = MAX_MINTVERSE_RANDOM_WORD.add(1);
            }
        }
    }

    /** @dev Set the status of whitelist mint phase and its starting time
     * @param _hasWLMintStarted True if the whitelist mint phase have started, otherwise false
     * @param _wlMintTimestamp After this timestamp the whitelist mint phase will be enabled
     */
    function setWLMintPhase(
        bool _hasWLMintStarted, 
        uint256 _wlMintTimestamp
    ) 
        override 
        external 
        onlyOwner 
    {
        mintWhitelistEnable = _hasWLMintStarted;
        mintWhitelistTimestamp = _wlMintTimestamp;
    }

    /** @dev Set the status of public mint phase and its starting time
     * @param _hasPublicMintStarted True if the public mint phase have started, otherwise false
     * @param _publicMintTimestamp After this timestamp the public mint phase will be enabled
     */
    function setPublicMintPhase(
        bool _hasPublicMintStarted, 
        uint256 _publicMintTimestamp
    ) 
        override 
        external 
        onlyOwner 
    {
        mintPublicEnable = _hasPublicMintStarted;
        mintPublicTimestamp = _publicMintTimestamp;
    }

    /** @dev Set the price to purchase dictionary tokens.
     * @param price New price that caller wants to set as the price of dictionary tokens
     */
    function setDictPrice(uint256 price) 
        override 
        external 
        onlyOwner 
    {
        DICT_ADDON_PRICE = price;
    }

    /** @dev Set the timestamp to start the expiration countdown
     * @param newRevealTimestamp Timestamp to set as the new reveal timestamp
     */
    function setRevealTimestamp(uint48 newRevealTimestamp)
        override
        external
        onlyOwner
    {
        revealTimestamp = newRevealTimestamp;
    }

    /** @dev Set the timestamp period use to calculate if a token is expired
     * @param newExpirationPeriod Timestamp to set as the new expiration period
     */
    function setExpirationTime(uint48 newExpirationPeriod)
        override
        external
        onlyOwner
    {
        WORD_EXPIRATION_TIME = newExpirationPeriod;
    }

    /** @dev Set the categoryId of a specific token
     * @param tokenId TokenId that owner wants to set categoryId
     * @param categoryId CategoryId that owner wants to set the token to
     */
    function setCategoryByTokenId(
        uint256 tokenId, 
        uint8 categoryId
    ) 
        override
        external
        onlyOwner
    {
        tokenItem[tokenId].categoryPart = categoryId;
    }

    /** @dev Set the maximum supply of random word tokens.
     * @param amount Maximum amount of random word tokens
     */
    function setMaxRandomWordTokenAmt(uint256 amount) 
        override 
        external 
        onlyOwner 
    {
        MAX_MINTVERSE_RANDOM_WORD = amount;
    }

    /** @dev Set the maximum supply of giveaway word tokens.
     * @param amount Maximum amount of giveaway word tokens
     */
    function setMaxGiveawayWordTokenAmt(uint256 amount)
        override 
        external 
        onlyOwner 
    {
        MAX_MINTVERSE_GIVEAWAY_WORD = amount;
    }

    /** @dev Set the maximum supply of dictionary tokens.
     * @param amount Maximum amount of dictionary tokens
     */
    function setMaxDictAmt(uint256 amount) 
        override 
        external 
        onlyOwner 
    {
        MAX_MINTVERSE_DICTIONARY = amount;
    }

    /** @dev Set the index of the head of random word token
     * @param index New index to set as the head index
     */
    function setHeadRandomWordId(uint16 index) 
        override 
        external 
        onlyOwner
    {
        HEAD_RANDOM_WORDID = index;
    }

    /** @dev Set the index of the tail of random word token
     * @param index New index to set as the tail index
     */
    function setTailRandomWordId(uint16 index)
        override 
        external 
        onlyOwner
    {
        TAIL_RANDOM_WORDID = index;
    }

    /** @dev Set the index of the head of settle word token
     * @param index New index to set as the settle head index
     */
    function setSettleHeadRandomWordId(uint16 index)
        override 
        external 
        onlyOwner
    {
        SETTLE_HEAD_TOKENID = index;
    }   

    /** @dev Set the offset amount of the designated wordId
     * @param offsetAmount Amount to set as the new offset amount
     */
    function setWordIdOffset(uint16 offsetAmount)
        override 
        external 
        onlyOwner
    {
        DESIGNATED_WORDID_OFFSET = offsetAmount;
    }

    /** @dev Set the wordId of a specific token
     * @param tokenId TokenId that owner wants to set its wordId
     * @param wordId WordId that owner wants to set its tokens to
     */
    function setTokenWordIdByTokenId(
        uint256 tokenId, 
        uint16 wordId
    )
        override 
        external 
        onlyOwner
    {
        tokenItem[tokenId].wordPart = wordId;
    }

    /** @dev Set the timestamp of a specific token
     * @param tokenId TokenId that owner wants to set its mint timestamp
     * @param mintTimestamp Mint timestamp that owner wants to set its tokens to
     */
    function setTokenMintTimeByTokenId(
        uint256 tokenId, 
        uint48 mintTimestamp
    ) 
        override 
        external 
        onlyOwner
    {
        tokenItem[tokenId].mintTime = mintTimestamp;
    }

    /** @dev Set the defined status of a specific token
     * @param tokenId TokenId that owner wants to set its defined status
     * @param definedOrNot Defined status that owner wants to set its tokens to
     */
    function setTokenDefineStatusByTokenId(
        uint256 tokenId, 
        bool definedOrNot
    )
        override 
        external 
        onlyOwner
    {
        tokenItem[tokenId].defined = definedOrNot;
    }

    /** @dev Set the URI for tokenURI, which returns the metadata of token.
     * @param newBaseTokenURI New URI that caller wants to set as tokenURI
     */
    function setBaseTokenURI(string calldata newBaseTokenURI) 
        override 
        external 
        onlyOwner 
    {
		baseTokenURI = newBaseTokenURI;
	}

    /** @dev Set the URI for legalDocumentURI, which returns the URI of legal document.
     * @param newLegalDocumentURI New URI that caller wants to set as legalDocumentURI
     */
    function setLegalDocumentURI(string calldata newLegalDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		legalDocumentURI = newLegalDocumentURI;
	}

    /** @dev Set the URI for systemMechanismDocumentURI, which returns the URI of system mechanicsm document.
     * @param newSystemMechanismDocumentURI New URI that caller wants to set as systemMechanismDocumentURI
     */
    function setSystemMechanismDocumentURI(string calldata newSystemMechanismDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		systemMechanismDocumentURI = newSystemMechanismDocumentURI;
	}

    /** @dev Set the URI for animationCodeDocumentURI, which returns the URI of animation code.
     * @param newAnimationCodeDocumentURI New URI that caller wants to set as animationCodeDocumentURI
     */
    function setAnimationCodeDocumentURI(string calldata newAnimationCodeDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		animationCodeDocumentURI = newAnimationCodeDocumentURI;
	}

    /** @dev Set the URI for visualRebuildDocumentURI, which returns the URI of visual rebuild document.
     * @param newVisualRebuildDocumentURI New URI that caller wants to set as visualRebuildDocumentURI
     */
    function setVisualRebuildDocumentURI(string calldata newVisualRebuildDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		visualRebuildDocumentURI = newVisualRebuildDocumentURI;
	}

    /** @dev Set the URI for ERC721ATechinalDocumentURI, which returns the URI of ERC721A technical document.
     * @param newERC721ATechinalDocumentURI New URI that caller wants to set as ERC721ATechinalDocumentURI
     */
    function setERC721ATechinalDocumentURI(string calldata newERC721ATechinalDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		ERC721ATechinalDocumentURI = newERC721ATechinalDocumentURI;
	}

    /** @dev Set the URI for wordIdMappingDocumnetURI, which returns the URI of wordId mapping document.
     * @param newWordIdMappingDocumnetURI New URI that caller wants to set as wordIdMappingDocumnetURI
     */
    function setWordIdMappingDocumnetURI(string calldata newWordIdMappingDocumnetURI) 
        override 
        external 
        onlyOwner 
    {
		wordIdMappingDocumnetURI = newWordIdMappingDocumnetURI;
	}

    /** @dev Set the URI for partOfSpeechIdMappingDocumentURI, which returns the URI of partOfSpeechId mapping document.
     * @param newPartOfSpeechIdMappingDocumentURI New URI that caller wants to set as partOfSpeechIdMappingDocumentURI
     */
    function setPartOfSpeechIdMappingDocumentURI(string calldata newPartOfSpeechIdMappingDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		partOfSpeechIdMappingDocumentURI = newPartOfSpeechIdMappingDocumentURI;
	}

    /** @dev Set the URI for categoryIdMappingDocumentURI, which returns the URI of categoryId mapping document.
     * @param newCategoryIdMappingDocumentURI New URI that caller wants to set as categoryIdMappingDocumentURI
     */
    function setCategoryIdMappingDocumentURI(string calldata newCategoryIdMappingDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		categoryIdMappingDocumentURI = newCategoryIdMappingDocumentURI;
	}

    /** @dev Set the URI for metadataMappingDocumentURI, which returns the URI of metadata mapping document.
     * @param newMetadataMappingDocumentURI New URI that caller wants to set as metadataMappingDocumentURI
     */
    function setMetadataMappingDocumentURI(string calldata newMetadataMappingDocumentURI) 
        override 
        external 
        onlyOwner 
    {
		metadataMappingDocumentURI = newMetadataMappingDocumentURI;
	}

    /** @dev Set the address that act as treasury and recieve all the fund from token contract.
     * @param _treasury New address that caller wants to set as the treasury address
     */
    function setTreasury(address _treasury) 
        override 
        external 
        onlyOwner 
    {
        require(_treasury != address(0), "Invalid address - Zero address");
        treasury = _treasury;
    }

    /**
     * Withdrawal Functions
     */
    /** @dev Set the maximum supply of dictionary tokens.
     */
	function withdrawAll() 
        override 
        external 
        payable 
        onlyOwner 
    {
		payable(treasury).transfer(address(this).balance);
	}
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**128 - 1 (max value of uint128).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
    }

    // Compiler will pack the following 
    // _currentIndex and _burnCounter into a single 256bit word.
    
    // The tokenId of the next token to be minted.
    uint128 internal _currentIndex;

    // The number of tokens burned.
    uint128 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex times
        unchecked {
            return _currentIndex - _burnCounter;    
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (!ownership.burned) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        revert TokenIndexOutOfBounds();
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     * This read function is O(totalSupply). If calling from a separate contract, be sure to test gas first.
     * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        if (index >= balanceOf(owner)) revert OwnerIndexOutOfBounds();
        uint256 numMintedSoFar = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        // Counter overflow is impossible as the loop breaks when
        // uint256 i is equal to another uint256 numMintedSoFar.
        unchecked {
            for (uint256 i; i < numMintedSoFar; i++) {
                TokenOwnership memory ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }

        // Execution should never reach this point.
        revert();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(_addressData[owner].numberMinted);
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant: 
                    // There will always be an ownership that has an address and is not burned 
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 3.4e38 (2**128) - 1
        // updatedIndex overflows if _currentIndex + quantity > 3.4e38 (2**128) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(address(0), to, updatedIndex, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
                updatedIndex++;
            }

            _currentIndex = uint128(updatedIndex);
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            _ownerships[tokenId].addr = to;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        _beforeTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**128.
        unchecked {
            _addressData[prevOwnership.addr].balance -= 1;
            _addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            _ownerships[tokenId].addr = prevOwnership.addr;
            _ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            _ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (_ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < _currentIndex) {
                    _ownerships[nextTokenId].addr = prevOwnership.addr;
                    _ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked { 
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWord {
    struct TokenInfo {
        string definerPart;
        string relatedWordPart;
        string descriptionPart;

        uint16 wordPart;
        uint8 categoryPart; // 1: Genesis Card, 2: Special Card, 3. Censored Card
        uint8 partOfSpeechPart1;
        uint8 partOfSpeechPart2;

        uint48 mintTime;
        bool defined;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IWord.sol";

interface IMintverseWord is IWord {
    // Return true if the minter is eligible to claim the given amount word token with the signature.
    function verify(uint256 maxQuantity, bytes calldata SIGNATURE) external view returns(bool);
    // Changes the addon status of an address by owner.
    function mintGiveawayDictionary(address to, bool addon) external;
    // Mints tokens to an address with specific wordId by owner. 
    function mintGiveawayWord(address to, uint16 wordId, uint48 mintTimestamp) external;
    // Whitelisted addresses mint specific amount of tokens with signature & maximum mintable amount to verify.
    function mintWhitelistWord(uint256 quantity, uint256 maxClaimNum, bool addon, bytes calldata SIGNATURE) external payable;
    // Public addresses mint specific amount of tokens.
    function mintPublicWord(bool addon) external payable;
    // Word token owners send five parameters to define the word.
    function defineWord(uint256 tokenId, string calldata definer, uint8 partOfSpeech1, uint8 partOfSpeech2, string calldata relatedWord, string calldata description) external;

    // Add the wordId to the end of random word bank.
    function settleExpiredWord(uint256 startTokenId, uint256 endTokenId) external;

    // View function to get the metadata of a specific token with tokenId.
    function getTokenProperties(uint256 tokenId) external view returns(string memory definer, uint256 wordId, uint256 categoryId, uint256 partOfSpeechId1, uint256 partOfSpeechId2, string memory relatedWord, string memory description);
    // View function to get the expired timestamp of a specific token with tokenId.
    function getTokenExpirationTime(uint256 tokenId) external view returns(uint256 expirationTime);
    // View function to get the status(dead or alive) of a specific token with tokenId.
    function getTokenStatus(uint256 tokenId) external view returns(bool writtenOrNot);
    // View function to get all the metadatas of the word tokens of the given address.
    function getTokenPropertiesByOwner(address owner) external view returns(TokenInfo[] memory tokenInfos);
    // View function to get all the expired timestamps of the word tokens of the given address.
    function getTokenExpirationTimeByOwner(address owner) external view returns(uint256[] memory expirationTimes);
    // View function to get all the status(dead or alive) of the word tokens of the given address.
    function getTokenStatusByOwner(address owner) external view returns(bool[] memory writtenOrNot);
    // View function to check if the given address has purchased the addon dictionary.
    function getAddonStatusByOwner(address owner) external view returns(bool addon);
    // View function to get all the token Id that a address owns.
    function tokensOfOwner(address owner) external view returns(uint256[] memory);
    // View function to get all the dictionary supply for dictionary contract.
    function getTotalDictionary() external view returns (uint256 amount);

    // Set the variables to enable the whitelist mint phase by owner.
    function setWLMintPhase(bool hasWLMintStarted, uint256 wlMintTimestamp) external;
    // Set the variables to enable the public mint phase by owner.
    function setPublicMintPhase(bool hasPublicMintStarted, uint256 publicMintTimestamp) external;

    // Set the price for minter to purchase addon dictionary.
    function setDictPrice(uint256 price) external;
    // Set the expiration time period of the token.
    function setExpirationTime(uint48 expirationPeriod) external;
    // Set the reveal timestamp to adjust tokens mint time.
    function setRevealTimestamp(uint48 newRevealTimestamp) external;
    // Set the categoryId of a specific token by tokenId.
    function setCategoryByTokenId(uint256 tokenId, uint8 categoryId) external;

    // **SYSTEM EMERGENCY CALLS**
    // Set the maximum supply of the random tokens by owner.
    function setMaxRandomWordTokenAmt(uint256 amount) external;
    // Set the maximum supply of the giveaway tokens by owner.
    function setMaxGiveawayWordTokenAmt(uint256 amount) external;
    // Set the maximum supply of the dictionary by owner.
    function setMaxDictAmt(uint256 amount) external;
    // Set the index for head of random word.
    function setHeadRandomWordId(uint16 index) external;
    // Set the index for tail of random word.
    function setTailRandomWordId(uint16 index) external;
    // Set the index for tail of random word.
    function setSettleHeadRandomWordId(uint16 index) external;
    // Set the offset of the designated word id.
    function setWordIdOffset(uint16 offsetAmount) external;

    // **TOKEN EMERGENCY CALLS**
    // Set the wordId of a specific token by tokenId.
    function setTokenWordIdByTokenId(uint256 tokenId, uint16 wordId) external;
    // Set the mint time of a specific token by tokenId.
    function setTokenMintTimeByTokenId(uint256 tokenId, uint48 mintTimestamp) external;
    // Set the defined status of a specific token by tokenId.
    function setTokenDefineStatusByTokenId(uint256 tokenId, bool definedOrNot) external;

    // Set the URI to return the tokens metadata.
    function setBaseTokenURI(string calldata newBaseTokenURI) external;
    // Set the URI for the legal document.
    function setLegalDocumentURI(string calldata newLegalDocumentURI) external;
    // Set the URI for the system mechanism document.
    function setSystemMechanismDocumentURI(string calldata newSystemMechanismDocumentURI) external;
    // Set the URI for the animation code document.
    function setAnimationCodeDocumentURI(string calldata newAnimationCodeDocumentURI) external;
    // Set the URI for the visual rebuild method document.
    function setVisualRebuildDocumentURI(string calldata newVisualRebuildDocumentURI) external;
    // Set the URI for the erc721 technical document.
    function setERC721ATechinalDocumentURI(string calldata newERC721ATechinalDocumentURI) external;
    // Set the URI for the wordId mapping document.
    function setWordIdMappingDocumnetURI(string calldata newWordIdMappingDocumnetURI) external;
    // Set the URI for the partOfSpeechId mapping document.
    function setPartOfSpeechIdMappingDocumentURI(string calldata newPartOfSpeechIdMappingDocumentURI) external;
    // Set the URI for the categoryId mapping document.
    function setCategoryIdMappingDocumentURI(string calldata newCategoryIdMappingDocumentURI) external;
    // Set the URI for the metadata mapping document.
    function setMetadataMappingDocumentURI(string calldata newMetadataMappingDocumentURI) external;
    // Set the address to transfer the contract fund to.
    function setTreasury(address treasury) external;
    // Withdraw all the fund inside the contract to the treasury address.
    function withdrawAll() external payable;
    // This event is triggered whenever a call to #mintGiveawayWord, #mintWhitelistWord, and #mintPublicWord succeeds.
    event mintWordEvent(address owner, uint256 quantity, uint256 totalSupply);
    // This event is triggered whenever a call to #defineWord succeeds.
    event wordDefinedEvent(uint256 tokenId);
    // This event is triggered whenever a call to #settleExpiredWord succeeds.
    event moveWordToTheBack(uint256 oriWordId, uint256 newWordId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}