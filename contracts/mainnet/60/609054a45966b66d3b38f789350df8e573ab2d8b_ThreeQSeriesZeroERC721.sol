//SPDX-License-Identifier: MIT

/*
    <__ / ___   ___  / __> ___  _ _ <_> ___  ___ |_  / ___  _ _  ___ 
     <_ \/ . | |___| \__ \/ ._>| '_>| |/ ._><_-<  / / / ._>| '_>/ . \
    <___/\_  |       <___/\___.|_|  |_|\___./__/ /___|\___.|_|  \___/ 
*/

pragma solidity 0.8.11;
pragma abicoder v2;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./Strings.sol";

contract ThreeQSeriesZeroERC721 is ERC721, AccessControl
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // ====================================================
    // ROLES
    // ====================================================
    bytes32 public constant PROJECT_ADMINS_ROLE = keccak256("PROJECT_ADMINS_ROLE");

    // ====================================================
    // EVENTS
    // ====================================================
    event TokenUriUpdated(uint256 tokenId, string uri);
    event TokenMinted(uint256 tokenIndex, address minter, TokenSaleState saleStatus);
    event SupremeMinted(uint256 omToken1, uint256 omToken2, uint256 onToken3, uint256 supremeToken);
    event MintPriceChanged(uint256 newPrice);

    // ====================================================
    // ENUMS & STRUCTS
    // ====================================================
    enum TokenSaleState { PAUSED, AUCTION, PRE_SALE, PUBLIC_SALE, OM_BURN }
    enum TokenType { OM, SUPREME }

    struct TokenDetails {
        uint256 tokenIndex;
        TokenType tokenType;
        uint256[3] burnedTokens;
    }

    // ====================================================
    // STATE
    // ====================================================
    // supply/reservation constants
    uint public constant MAX_PER_TX = 6;
    uint public constant MAX_COMPOSER_EDITIONS = 5;
    uint public constant MAX_RESERVED = 133;
    uint public constant MAX_OM_SUPPLY = 3338;

    // metadata
    string private _baseURIExtended;
    mapping (uint256 => string) private _tokenURIs;

    // general vars, counter, etc
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _composerEditionCounter;
    uint private _reservedTokensCounter;

    TokenSaleState public tokenSaleState = TokenSaleState.PAUSED;
    uint256 public mintPrice = 0.1 ether;
    string public provenanceHash;
    mapping (uint256 => TokenDetails) public tokenData;
    mapping(address => uint) public presaleParticipants;
    
    // ====================================================
    // CONSTRUCTOR
    // ====================================================
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri
    )
        ERC721(_name, _symbol)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PROJECT_ADMINS_ROLE, msg.sender);

        _baseURIExtended = _baseUri;
    }

    // ====================================================
    // OVERRIDES
    // ====================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ====================================================
    // ADMIN
    // ====================================================
    function setPresaleParticipants(address[] memory participants, uint allocation)
        public
        onlyRole(PROJECT_ADMINS_ROLE)
    {
        for (uint16 i = 0; i < participants.length; i++) {
            presaleParticipants[participants[i]] = allocation;
        }
    }

    function setProvenanceHash(string memory pHash)
        public
        onlyRole(PROJECT_ADMINS_ROLE)
    {
        // only allow provenance to be set once
        require(bytes(provenanceHash).length == 0, "Provenance hash already set");

        provenanceHash = pHash;
    }

    function toggleSaleState(uint8 state)
        public
        onlyRole(PROJECT_ADMINS_ROLE)
    {
        tokenSaleState = TokenSaleState(state);
    }

    function changeMintPrice(uint256 _newPrice)
        public
        onlyRole(PROJECT_ADMINS_ROLE)
    {
        mintPrice = _newPrice;
        emit MintPriceChanged(_newPrice);
    }

    function setBaseUri(string memory _newBaseUri)
        public
        onlyRole(PROJECT_ADMINS_ROLE)
    {
        _baseURIExtended = _newBaseUri;
    }

    function updateTokenURI(uint256 _tokenId, string memory _newTokenURI)
        public
        onlyRole(PROJECT_ADMINS_ROLE)
    {
        _tokenURIs[_tokenId] = _newTokenURI;
        emit TokenUriUpdated(_tokenId, _newTokenURI);
    }

    function mintComposerEdition()
        public
        onlyRole(PROJECT_ADMINS_ROLE)
    {
        require(_composerEditionCounter.current() < MAX_COMPOSER_EDITIONS, "Request will exceed composer editions max");

        internalOmMint(msg.sender, 1, TokenSaleState.AUCTION);
        _composerEditionCounter.increment();
    }

    function reserveTokens(address recipient, uint numTokens)
        public
        onlyRole(PROJECT_ADMINS_ROLE)
    {
        require(_reservedTokensCounter + numTokens <= MAX_RESERVED, "Request will exceed reserve max");

        internalOmMint(recipient, numTokens, TokenSaleState.PRE_SALE);
        _reservedTokensCounter += numTokens;
    }

    function withdrawFunds(address payable recipient, uint256 amount)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(recipient != address(0), "Invalid recipient address");
        recipient.transfer(amount);
    }
    
    // ====================================================
    // INTERNAL UTILS
    // ====================================================
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return _baseURIExtended;
    }

    function internalOmMint(address recipient, uint numTokens, TokenSaleState _tokenSaleState)
        internal
    {
        require(_tokenIdCounter.current() + numTokens <= MAX_OM_SUPPLY, "Purchase would exceed max supply");

        for (uint i = 0; i < numTokens; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(recipient, tokenId);

            tokenData[tokenId] = TokenDetails({
                tokenIndex: tokenId,
                tokenType: TokenType.OM,
                burnedTokens: [uint256(0) , uint256(0), uint256(0)]
            });

            emit TokenMinted(tokenId, recipient, _tokenSaleState);
        }
    }

    // ====================================================
    // PUBLIC API
    // ====================================================
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // if a custom tokenURI has not been set, return base + tokenId.json
        if(bytes(_tokenURI).length == 0) {
            return string(abi.encodePacked(base, tokenId.toString(), ".json"));
        }

        // a custom tokenURI has been set - likely after metadata IPFS migration
        return _tokenURI;
    }

    function getSupplyData()
        public
        view
        returns(
            uint256 _currentToken,
            uint256 _maxSupply,
            uint256 _mintPrice,
            TokenSaleState _tokenSaleState,
            bool _isTokenHolder)
    {
        _currentToken = _tokenIdCounter.current();
        _maxSupply = MAX_OM_SUPPLY;
        _mintPrice = mintPrice;
        _tokenSaleState = tokenSaleState;
        _isTokenHolder = balanceOf(msg.sender) > 0;
    }

    function validateTokenForBurn(uint256 tIndex)
        public
        view
        returns(bool burnable, string memory message)
    {
        if(_exists(tIndex)) {
            if(msg.sender == ownerOf(tIndex)) {
                if(tokenData[tIndex].tokenType == TokenType.SUPREME) {
                    burnable = false;
                    message = "SupremeToken";
                }
                else {
                    burnable = true;
                }
            }
            else {
                burnable = false;
                message = "NotOwned";
            }
        }
        else {
            burnable = false;
            message = "InvalidToken";
        }
    }

    function presaleMint(uint8 numTokens)
        public
        payable
    {
        // standard checks
        require(tokenSaleState == TokenSaleState.PRE_SALE, "Pre-Sale sale is not active");
        require(msg.value >= mintPrice * numTokens, "Insufficient ether sent");

        // check private mint allocation
        require(numTokens <= presaleParticipants[msg.sender], "Insufficient pre-sale allocation");

        // decrement pre-sale allocation
        presaleParticipants[msg.sender] -= numTokens;

        internalOmMint(msg.sender, numTokens, TokenSaleState.PRE_SALE);
    }

    function publicMint(uint numTokens)
        public
        payable
    {
        // standard checks
        require(tokenSaleState == TokenSaleState.PUBLIC_SALE, "Public sale is not active");
        require(numTokens <= MAX_PER_TX,"Max 6 per tx allowed");
        require(msg.value >= mintPrice * numTokens, "Insufficient ether sent");
        require(!Address.isContract(msg.sender), "Contracts forbidden from buying");

        internalOmMint(msg.sender, numTokens, TokenSaleState.PUBLIC_SALE);
    }

    function burnTokens(uint256 token1, uint256 token2, uint256 token3)
        public
    {
        require(tokenSaleState == TokenSaleState.OM_BURN, "Burn phase is not active");

        // ensure requested burn tokens are owned by sender
        require(msg.sender == ownerOf(token1), "1st provided token not owned");
        require(msg.sender == ownerOf(token2), "2nd provided token not owned");
        require(msg.sender == ownerOf(token3), "3rd provided token not owned");

        // ensure requested burn tokens are OM tokens
        require(tokenData[token1].tokenType == TokenType.OM, "1st provided token not of type OM");
        require(tokenData[token2].tokenType == TokenType.OM, "2nd provided token not of type OM");
        require(tokenData[token3].tokenType == TokenType.OM, "3rd provided token not of type OM");
        
        // burn OM tokens
        _burn(token1);
        _burn(token2);
        _burn(token3);

        // mint supreme token
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        tokenData[tokenId] = TokenDetails({
            tokenIndex: tokenId,
            tokenType: TokenType.SUPREME,
            burnedTokens: [token1, token2, token3]
        });

        emit SupremeMinted(token1, token2, token3, tokenId);
    }
}