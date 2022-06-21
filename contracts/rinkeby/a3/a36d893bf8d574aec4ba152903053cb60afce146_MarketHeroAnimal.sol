//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./../contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "./../contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IOwnable.sol";
import "./interfaces/IMarketHeroAnimal.sol";
import "./MarketHeroUtils.sol";
import "./MarketHeroGame.sol";
import "./MarketHeroController.sol";

contract MarketHeroAnimal is Initializable, ERC721Upgradeable, IOwnable, IMarketHeroAnimal {
    // address of MarketHeroShop Contract
    address public marketHeroShopAddress; 
    // address of MarketHeroUtils Contract
    address public marketHeroUtilsAddress;
    // address of MarketHeroGame Contract
    address public marketHeroGameAddress;
    // address of MarketHeroController contract
    address public marketHeroControllerAddress;
    // Template for token 
    Hero public templateHero; 
    // Id of last minted token
    uint256 public lastMintedTokenID;

    // Limits for all types of heroes
    mapping(uint8 => uint256) public animalMaxAmount;
    // Number of already minted tokens divided by animals` types
    mapping(uint8 => uint256) public animalMintedAmount;
    // NFT Tokens
    mapping(uint256 => Hero) public heroes;


    // Emitted when the pause is triggered by `account`.
    event Paused(address account);
    // Emitted when the pause is lifted by `account`.
    event Unpaused(address account);
    // Emitted when Token was minted
    event Minted(address indexed to, uint256 indexed tokenID);
    // Emitted when Token was burnt
    event Burnt(address indexed from, uint256 indexed tokenID);

    
    function initialize(
        address _marketHeroUtils,
        address _marketHeroShop,
        address _marketHeroGame,
        address _marketHeroControllerAddress
    ) public initializer{
        __ERC721_init("MarketHero","MKH");
        marketHeroShopAddress = _marketHeroShop;
        marketHeroUtilsAddress = _marketHeroUtils;
        marketHeroGameAddress = _marketHeroGame;
        marketHeroControllerAddress = _marketHeroControllerAddress;

        // Default Configuration
        setDefaultHeroParameters();
        setMaxHeroesAmount(0,0); //Hamster
        setMaxHeroesAmount(3,1000); // Whale
        setMaxHeroesAmount(1,5000); //Bull
        setMaxHeroesAmount(2,5000); //Bear
    }

//  ***************MODIFIERS*********************************************
    /**
     * @dev Modifier to make a function callable only when the sender is MarketHeroShop contract.
     */
    modifier onlyShop() {
        require(_msgSender() == marketHeroShopAddress, "MarketHeroAnimal: call from outside the shop");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the sender is MarketHeroGame contract.
     */
    modifier onlyGame() {
        require(_msgSender() == marketHeroGameAddress, "MarketHeroAnimal: call from outside the game");
        _;
    }
    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused{
        require(MarketHeroController(marketHeroControllerAddress).paused(),"MarketHeroGame is not paused ");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused{
        require(!MarketHeroController(marketHeroControllerAddress).paused(),"MarketHeroGame ia paused");
        _;
    }
    modifier onlyAdmin{
        require(MarketHeroController(marketHeroControllerAddress).hasRole(MarketHeroController(marketHeroControllerAddress).DEFAULT_ADMIN_ROLE(),msg.sender),"MarketHeroAnimal: caller is not an admin ");
        _;
    }



//  ***************OWNER FUNCTIONS*********************************************


    /**
     * @notice Function Sets number of max heroes for definite animal type
     * @param _animalType type of hero
     * @param _maxAmount number of max amount
     */ 
    function setMaxHeroesAmount (
        uint8 _animalType,
        uint256 _maxAmount
    ) public onlyAdmin whenNotPaused{
        animalMaxAmount[_animalType] = _maxAmount;
    }
//  ***************PRIVATE FUNCTIONS*********************************************
    /**
    * @dev setting default meanings for hero parameters 
     */
    function setDefaultHeroParameters() public onlyAdmin whenNotPaused{
        templateHero.color_and_effects[0]=0;
        templateHero.color_and_effects[1]=0;
        templateHero.color_and_effects[2]=0;
        templateHero.color_and_effects[3]=0;
        templateHero.color_and_effects[4]=0;
        templateHero.color_and_effects[5]=0;
        templateHero.color_and_effects[6]=0;
        templateHero.color_and_effects[7]=0;
        
        templateHero.speed = 0;
        templateHero.lifesteal = 0;
        templateHero.endurence = 0;
        templateHero.fund = 0;
        templateHero.level = 0;
        templateHero.gamesPlayed = 0;
        templateHero.gamesWon = 0;
    }
//  ***************GAME FUNCTIONS*********************************************
    /**
     * @notice Function update statistics of specific hero when he won
     */ 
    function gameWon(uint256 _tokenID) external onlyGame{
        heroes[_tokenID].gamesPlayed +=1;
        heroes[_tokenID].gamesWon +=1;
    }

    /**
     * @notice Function update statistics of specific hero when he lost or tied
     */  
    function gameLostOrTied(uint256 _tokenID) external onlyGame{
        heroes[_tokenID].gamesPlayed +=1;
    }
//  ***************SHOP FUNCTIONS*********************************************
    /**
    * @dev Function allows to renew traits of specific Hero, may be used only by shop contract
        for upgrading traits and during minting(for basic random distribution)
    * @param _tokenID ID of an hero
    * @param _animalType 1 of 4 type of Hero (Hamster,Bull,Bear,Whale)
    * @param _speed 1 of 4 basic traits which affect result of the game
    * @param _lifesteal 1 of 4 basic traits which affect result of the game
    * @param _fund 1 of 4 basic traits which affect result of the game
    * @param _level summarizes points of above traits
     */
    function renewHeroParameters(
        uint256 _tokenID,
        uint8 _animalType,
        uint8 _speed,
        uint8 _lifesteal,
        uint8 _endurence,
        uint8 _fund,
        uint8 _level
        )external onlyShop{
            heroes[_tokenID].animal = AnimalType(_animalType);
            heroes[_tokenID].speed = _speed;
            heroes[_tokenID].lifesteal = _lifesteal;
            heroes[_tokenID].endurence = _endurence;
            heroes[_tokenID].fund = _fund;
            heroes[_tokenID].level = _level;
        }

    /**
     * @notice Function to mint Tokens, may be used only by shop contract
     * @dev emits "Minted" event
     * @param _animalType 1 of 4 types of animals
     * @param _to receiver address
     */
    function createHero(uint8 _animalType, address _to) external onlyShop{
        require(_animalType>=0  && _animalType<4, "MarketHeroAnimal: That type doesn`t exist");
        require(animalMaxAmount[_animalType] == 0 || animalMaxAmount[_animalType] >= animalMintedAmount[_animalType] + 1, "MarketHeroAnimal: Can't mint that much of animals");
        uint256 _tokenID = ++lastMintedTokenID;
        _safeMint(_to, _tokenID);
        heroes[_tokenID].animal = AnimalType(_animalType);
        heroes[_tokenID].color_and_effects[0]= templateHero.color_and_effects[0];
        heroes[_tokenID].color_and_effects[1]= templateHero.color_and_effects[1];
        heroes[_tokenID].color_and_effects[2]= templateHero.color_and_effects[2];
        heroes[_tokenID].color_and_effects[3]= templateHero.color_and_effects[3];
        heroes[_tokenID].color_and_effects[4]= templateHero.color_and_effects[4];
        heroes[_tokenID].color_and_effects[5]= templateHero.color_and_effects[5];
        heroes[_tokenID].color_and_effects[6]= templateHero.color_and_effects[6];
        heroes[_tokenID].color_and_effects[7]= templateHero.color_and_effects[7];
        heroes[_tokenID].speed = templateHero.speed;
        heroes[_tokenID].lifesteal = templateHero.lifesteal;
        heroes[_tokenID].endurence = templateHero.endurence;
        heroes[_tokenID].fund = templateHero.fund;
        heroes[_tokenID].level = templateHero.level;
        heroes[_tokenID].gamesPlayed = templateHero.gamesPlayed;
        heroes[_tokenID].gamesWon = templateHero.gamesWon;


        animalMintedAmount[_animalType]++;
        emit Minted(_to,_tokenID);
    }


    /** 
     * @notice functionfor users to burn their tokens (can be used only by owner)
     * @dev emits "Burnt" event
     * @param _tokenID NFT id 
     */
    function burn(uint256 _tokenID) public whenNotPaused{
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, _tokenID), "MarketHeroAnimal: caller is not owner nor approved");
        _burn(_tokenID);
        (uint8 _animalType,,,,,) = getHeroParameters(_tokenID);
        animalMintedAmount[_animalType] -= 1;
        emit Burnt(_msgSender(),_tokenID);
    }
//  ***************VIEW FUNCTIONS*********************************************
    
    function owner() external view returns(address){
        return MarketHeroController(marketHeroControllerAddress).initialAdmin();
    }
    /**
     * @notice Function returns number of max amount of definite type of animal(Hero)
     */ 
    function getMaxHeroesAmount(uint8 _animalType) public view returns(uint256){
        require(_animalType>=0  && _animalType<4, "MarketHeroAnimal: That type doesn`t exist");
        return animalMaxAmount[_animalType];
    }

    /**
     * @notice Function returns number of minted amount of definite type of animal(Hero)
     */ 
    function getMintedHeroesAmount(uint8 _animalType) public view returns(uint256){
        require(_animalType>=0  && _animalType<4, "MarketHeroAnimal: That type doesn`t exist");
        return animalMintedAmount[_animalType];
    }

    /**
     * @notice Function Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */ 
    function tokenURI(uint256 _tokenID) public view virtual override returns(string memory){
        require(_exists(_tokenID),"MarketHeroAnimal: That hero doesn`t exist");
        string memory _line = MarketHeroUtils(marketHeroUtilsAddress).convert( 
            name(),  
            uint8(heroes[_tokenID].animal),
            heroes[_tokenID].speed,
            heroes[_tokenID].lifesteal,
            heroes[_tokenID].endurence,
            heroes[_tokenID].fund
        ); 
        return _line;
    }

    /**
    * @notice function returns 6 basic characteristics 
        (Animal Type, 4 traits that affect result of the game, level of hero)
    * @param _tokenID ID of an hero 
     */
    function getHeroParameters(uint256 _tokenID) public view returns(
        uint8, uint8, uint8, uint8, uint8, uint8) {
        return(
            uint8(heroes[_tokenID].animal),
            heroes[_tokenID].speed,
            heroes[_tokenID].lifesteal,
            heroes[_tokenID].endurence,
            heroes[_tokenID].fund,
            heroes[_tokenID].level
        );
    }


    function getGameStatistic(uint256 _tokenID) public view returns(uint256, uint256){
        return(
            heroes[_tokenID].gamesPlayed,
            heroes[_tokenID].gamesWon
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(!MarketHeroController(marketHeroControllerAddress).paused(), "MarketHeroAnimal: Contract paused");
    }

    // function getHeroColorAndEffects(uint256 _tokenID) public view returns(
    //     uint16,
    //     uint16,
    //     uint16,
    //     uint16,
    //     uint16,
    //     uint16,
    //     uint16,
    //     uint16
    //     ){
    //     uint index = 0;
    //     uint16[8] memory colordata = heroes[_tokenID].color_and_effects;
    //     return(
    //         colordata[index++],
    //         colordata[index++],
    //         colordata[index++],
    //         colordata[index++],
    //         colordata[index++],
    //         colordata[index++],
    //         colordata[index++],
    //         colordata[index++]
    //     );
    // }


    // /**
    // * @dev Function allows to renew "color_and_effects" array of specific hero
    // * @param _tokenID ID of an hero
    //  */
    // function _renewHeroColorAndEffects(
    //     uint256 _tokenID
    //     )private{
    //         uint16[8] memory _color_and_effects;
    //         (
    //             _color_and_effects[0],
    //             _color_and_effects[1],
    //             _color_and_effects[2],
    //             _color_and_effects[3],
    //             _color_and_effects[4],
    //             _color_and_effects[5],
    //             _color_and_effects[6],
    //             _color_and_effects[7]) = getHeroColorAndEffects(_tokenID);
                
    //         heroes[_tokenID].color_and_effects[0]=_color_and_effects[0];
    //         heroes[_tokenID].color_and_effects[1]=_color_and_effects[1];
    //         heroes[_tokenID].color_and_effects[2]=_color_and_effects[2];
    //         heroes[_tokenID].color_and_effects[3]=_color_and_effects[3];
    //         heroes[_tokenID].color_and_effects[3]=_color_and_effects[3];
    //         heroes[_tokenID].color_and_effects[3]=_color_and_effects[3];
    //         heroes[_tokenID].color_and_effects[4]=_color_and_effects[4];
    //         heroes[_tokenID].color_and_effects[5]=_color_and_effects[5];
    //         heroes[_tokenID].color_and_effects[6]=_color_and_effects[6];
    //         heroes[_tokenID].color_and_effects[7]=_color_and_effects[7];
    // }
        



    // /**
    // * @dev Reading default meanings of animal traits
    //  */
    // function getDefaultHeroParameters() external view  returns(
    //     uint8,
    //     uint8,
    //     uint8,
    //     uint8,
    //     uint8
    //     ) {
    //     return(
    //         uint8(templateHero.animal),
    //         templateHero.speed,
    //         templateHero.lifesteal,
    //         templateHero.endurence,
    //         templateHero.fund
    //         );
    // }


    
    
        // /**
        // * @dev minting a certain amount of heroes for free(presale or airdrop)
        // * @param _animalType 1 of 4 types of animals
        // * @param _to receiver address
        //  */
        // function createHero(uint8 _animalType, address _to) public  {
        //     require((_msgSender() == marketHeroShopAddress)||(_msgSender()==owner()), "MarketHeroAnimal: not enough roots");
        //     _mintHero(_animalType, _to);  
        //     (uint8 _speed,
        //      uint8 _lifesteal,
        //      uint8 _endurence,
        //      uint8 _fund,
        //      uint8 _level) = MarketHeroURI(marketHeroURIAddress).multipleCase(_animalType);
        //     renewHeroParameters(
        //         lastMintedTokenID,
        //         _animalType,
        //         _speed,
        //         _lifesteal,
        //         _endurence,
        //         _fund,
        //         _level);
    // } 
        

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        safeTransferFrom(from, to, tokenId, "");
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
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
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable{
    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns(address);
    // function transferOwnership(address newOwner) external;
}

interface IMarketHeroAnimal{
    // Info about certain hero

    enum AnimalType{
        Hamster,
        Bull,
        Bear,
        Whale
    }
    struct Hero{
        AnimalType animal;
        uint16[8] color_and_effects;
        uint8 speed; 
        uint8 lifesteal;
        uint8 endurence;
        uint8 fund;
        uint8 level;
        uint256 gamesPlayed;
        uint256 gamesWon;
    }

    function gameWon(uint256 _tokenID) external ;

    function gameLostOrTied(uint256 _tokenID) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base64-sol/base64.sol";
import "./../contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../openzeppelin-contracts/utils/Strings.sol";
import "./MarketHeroAnimal.sol";
import "./MarketHeroController.sol";
import "./interfaces/IOwnable.sol";
contract MarketHeroUtils is Initializable, IOwnable {


    address public marketHeroAnimalAddress;
    address public marketHeroControllerAddress;
    // address public marketHeroShopAddress;

    function initialize(
        address _marketHeroControllerAddress
    ) public initializer{
        marketHeroControllerAddress = _marketHeroControllerAddress;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused{
        require(MarketHeroController(marketHeroControllerAddress).paused(),"MarketHeroGame is not paused ");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused{
        require(!MarketHeroController(marketHeroControllerAddress).paused(),"MarketHeroGame ia paused");
        _;
    }
    modifier onlyAdmin{
        require(MarketHeroController(marketHeroControllerAddress).hasRole(MarketHeroController(marketHeroControllerAddress).DEFAULT_ADMIN_ROLE(),msg.sender),"MarketHeroUtils: caller is not an admin ");
        _;
    }

    function setMarketHeroAnimalContract(address _marketHeroAnimalAddress) public onlyAdmin{
        marketHeroAnimalAddress = _marketHeroAnimalAddress;
    }
    /** 
     * @notice Function converts parameters of hero into string value
        */
    function convert(string memory _name, uint8 animal, uint8 speed, uint8 vampirism, uint8 endurence, uint32 fund) external view returns(string memory){
        require(msg.sender == marketHeroAnimalAddress, "MarketHeroTools: sender is not the MarketHeroAnimal" );
        string memory _link = getHeroPhoto(animal);
        // string memory _animal = Strings.toString(animal);
        string memory _speed = Strings.toString(speed);
        string memory _vampirism = Strings.toString(vampirism);
        string memory _endurence = Strings.toString(endurence);
        string memory _fund = Strings.toString(fund);
        bytes memory _result;
/////
        // if (animal==0){
        //     _result = bytes(abi.encodePacked(
        //                 '{"name":"',
        //                         _name,
        //                         '","description": "Hero for Market Hero ',  

        //                         '", "image": "',
        //                         _link,
                                
        //                         '", "attributes": [ ',
        //                             '{ "trait_type": "Type","value": "',
        //                             _animal,
        //                             '"},',
        //                             '{ "trait_type": "Speed",',
        //                             '"max_value" : "10"',
        //                             '"value": "',
        //                             _speed,
        //                             '"},',
        //                             '{ "trait_type": "Vampirism",',
        //                             '"max_value" : "10"',
        //                             '"value": "',
        //                             _vampirism,
        //                             '"},',
        //                             '{ "trait_type": "Endurence",',
        //                             '"max_value" : "10"',
        //                             '"value": "',
        //                             _endurence,
        //                             '"},',
        //                             '{ "trait_type": "Fund",',
        //                             '"max_value" : "10"',
        //                             '"value": "',
        //                             _fund,
        //                             '"} ]',
        //                         '}'));
        // }else if((animal == 1)||(animal ==2 )){
        //     _result = bytes(abi.encodePacked(
        //                 '{"name":"',
        //                         _name,
        //                         '","description": "Hero for Market Hero ',  

        //                         '", "image": "',
        //                         _link,
                                
        //                         '", "attributes": [ ',
        //                             '{ "trait_type": "Type","value": "',
        //                             _animal,
        //                             '"},',
        //                             '{ "trait_type": "Speed",',
        //                             '"max_value" : "15"',
        //                             '"value": "',
        //                             _speed,
        //                             '"},',
        //                             '{ "trait_type": "Vampirism",',
        //                             '"max_value" : "15"',
        //                             '"value": "',
        //                             _vampirism,
        //                             '"},',
        //                             '{ "trait_type": "Endurence",',
        //                             '"max_value" : "15"',
        //                             '"value": "',
        //                             _endurence,
        //                             '"},',
        //                             '{ "trait_type": "Fund",',
        //                             '"max_value" : "15"',
        //                             '"value": "',
        //                             _fund,
        //                             '"} ]',
        //                         '}'));
        // }else if(animal ==3){
        //     _result = bytes(abi.encodePacked(
        //                 '{"name":"',
        //                         _name,
        //                         '","description": "Hero for Market Hero ',  

        //                         '", "image": "',
        //                         _link,
                                
        //                         '", "attributes": [ ',
        //                             '{ "trait_type": "Type","value": "',
        //                             _animal,
        //                             '"},',
        //                             '{ "trait_type": "Speed",',
        //                             '"max_value" : "20"',
        //                             '"value": "',
        //                             _speed,
        //                             '"},',
        //                             '{ "trait_type": "Vampirism",',
        //                             '"max_value" : "20"',
        //                             '"value": "',
        //                             _vampirism,
        //                             '"},',
        //                             '{ "trait_type": "Endurence",',
        //                             '"max_value" : "20"',
        //                             '"value": "',
        //                             _endurence,
        //                             '"},',
        //                             '{ "trait_type": "Fund",',
        //                             '"max_value" : "20"',
        //                             '"value": "',
        //                             _fund,
        //                             '"} ]',
        //                         '}'));
        // }
////
        // return string(abi.encodePacked("data:application/json;base64, ", Base64.encode(_result)));
        return string(
                abi.encodePacked(
                    "data:application/json;base64, ",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name": "',
                                _name,
                                '","description": "Hero for Market Hero ',  

                                '", "image_url": "',
                                _link,
                                
                                '", "traits": [ ',
                                    '{ "trait_type": "Speed",',
                                    '"max_value" : "10"',
                                    '"value": "',
                                    _speed,
                                    '"},',
                                    '{ "trait_type": "Vampirism",',
                                    '"max_value" : "10"',
                                    '"value": "',
                                    _vampirism,
                                    '"},',
                                    '{ "trait_type": "Endurence",',
                                    '"max_value" : "10"',
                                    '"value": "',
                                    _endurence,
                                    '"},',
                                    '{ "trait_type": "Fund",',
                                    '"max_value" : "10"',
                                    '"value": "',
                                    _fund,
                                    '"} ]',
                                '}'
                            )
                        )
                    )   
                )
            );
 
 
    }

    /** 
     * @notice Function returns photo by type of animal
        */
    function getHeroPhoto(uint8 _animalType) public pure returns (string memory){
        string memory _link ="";
        if(_animalType==0){
            _link = "https://upload.wikimedia.org/wikipedia/commons/thumb/d/de/Pearl_Winter_White_Russian_Dwarf_Hamster_-_Front.jpg/1920px-Pearl_Winter_White_Russian_Dwarf_Hamster_-_Front.jpg";
        } else 
        if(_animalType==1){
            _link = "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e7/Alas_Purwo_banteng_close_up.jpg/550px-Alas_Purwo_banteng_close_up.jpg";
        } else 
        if(_animalType==2){
            _link = "https://xakep.ru/wp-content/uploads/2017/12/147134/bear.jpg";
        } else 
        if(_animalType==3){
            _link = "https://images.immediate.co.uk/production/volatile/sites/23/2019/10/GettyImages-1164887104_Craig-Lambert-2faf563.jpg?quality=90&resize=620%2C413";
        }
        return _link;
    }

    function owner() external view returns(address){
        return MarketHeroController(marketHeroControllerAddress).initialAdmin();
    }
    /** 
     * @dev Function returns random number in  boundaries of _min and _max (seed must be unique string)
        */
    function random(uint256 _min, uint256 _max, string memory seed) public view returns(uint256){
        require (_min < _max, "Random: invalid params");
        uint256 base =  uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.coinbase, seed)));
        return _min + base % (_max - _min);
    }

    /** 
     * @notice Function distribute randomly basic points of traits by animal type
        */
    function multipleCase(uint8 _animalType, uint256 id_number) external view returns(uint8,uint8,uint8,uint8, uint8){
        uint8 _freeLevelUp;
        string memory id = Strings.toString(id_number);
        if (_animalType == 0){
            _freeLevelUp = uint8(random(0,3,id));
        } else if((_animalType == 1)||(_animalType == 2)){
            _freeLevelUp = uint8(random(0,5,id));
        } else if(_animalType == 3){
            _freeLevelUp = uint8(random(0,6,id));
        }
        (   ,uint8 _speed,
            uint8 _vampirism,
            uint8 _endurence,
            uint8 _fund,) = MarketHeroAnimal(marketHeroAnimalAddress).getHeroParameters(id_number);
        uint8 _randomTrait;


        while(_freeLevelUp>0){
            string memory _random = Strings.toString(id_number + _freeLevelUp);
            _randomTrait = uint8(random(0,4, _random));
            if(_randomTrait == 0){
                _speed += 1;
            } else
            if(_randomTrait == 1){
                _vampirism += 1;
            } else 
            if(_randomTrait == 2){
                _endurence += 1;
            } else 
            if(_randomTrait == 3){
                _fund += 1;
            }
            _freeLevelUp -= 1;
        }
        return (_speed, _vampirism, _endurence, _fund, (_speed+ _vampirism+ _endurence+ _fund));
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./../contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./../contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./../openzeppelin-contracts/utils/Strings.sol";
import "./interfaces/IMarketHeroAnimal.sol";
import "./MarketHeroUtils.sol";
import "./MarketHeroController.sol";
import "./interfaces/IOwnable.sol";

contract MarketHeroGame is Initializable, IOwnable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    uint256 public constant PERCENT_DENOMINATOR = 100;
    // address of MarketHeroToken
    address public tokenMHT;
    // address of MarketHeroUtils Contract
    address public marketHeroUtilsAddress;
    // Id of last game started
    uint256 public lastGameID;
    // address of MarketHeroAnimal contract
    address public marketHeroAnimalAddress;
    // address of MarketHeroController contract
    address public marketHeroControllerAddress;



    // address public owner;
    uint16 public reward;

    // Enumeration of cities to play
    enum Cities {
        Dubai,
        Bali,
        London,
        NewYork,
        Sydney
    }
    // Enumeration of game statuses
    enum Result {
        Started,
        Hero1Won,
        Hero2Won,
        Draw
    }

    // Game info
    struct Game {
        uint256 hero1;
        uint256 hero2;
        uint256 bet;
        Result gameStatus;
    }

    // prices of entering location
    mapping(uint8 => uint256) entryFee;
    // game ids
    mapping(uint256 => Game) games;

    //  Emitted when game started
    event GameStarted(uint256 indexed gameID, uint256 indexed hero1, uint256 indexed hero2, uint256 bet, uint8 startPosition);
    //  Emitted when game finished
    event GameFinished(uint256 indexed gameID, uint8 result);

    function initialize(
        address _tokenMHT,
        address _marketHeroUtilsAddress,
        address _marketHeroControllerAddress
    ) public initializer {
        tokenMHT = _tokenMHT;
        marketHeroUtilsAddress = _marketHeroUtilsAddress;
        marketHeroControllerAddress = _marketHeroControllerAddress;

        // Default Configuration
        setEntryFee(0, 5); // Dubai
        setEntryFee(1, 10); // Bali
        setEntryFee(2, 25); // London
        setEntryFee(3, 50); // NewYork
        setEntryFee(4, 100); // Sydney
        setRewardPercentage(90);
    }

    modifier onlyAdmin{
        require(MarketHeroController(marketHeroControllerAddress).hasRole(MarketHeroController(marketHeroControllerAddress).DEFAULT_ADMIN_ROLE(),msg.sender),"MarketHeroGame: caller is not an admin ");
        _;
    }
    modifier onlyBackend{
        require(MarketHeroController(marketHeroControllerAddress).hasRole(MarketHeroController(marketHeroControllerAddress).BACKEND_ROLE(), msg.sender),"MarketHeroGame: caller has not a backend role ");
        _;
    }

    modifier whenPaused{
        require(MarketHeroController(marketHeroControllerAddress).paused(),"MarketHeroGame is not paused ");
        _;
    }
    modifier whenNotPaused{
        require(!MarketHeroController(marketHeroControllerAddress).paused(),"MarketHeroGame is paused");
        _;
    }

    function owner() external view returns(address){
        return MarketHeroController(marketHeroControllerAddress).initialAdmin();
    }

    function getEntryFee(uint8 _location ) public view returns(uint256){
        return(entryFee[_location]);
    }

    function setRewardPercentage(uint16 _reward) public onlyAdmin whenNotPaused{
        reward = _reward;
    }
    /**
     * @notice function sets prices of enterin location
     * @param _location city (enumeration)
     * @param _entryFee price in MHT Token
     */
    function setEntryFee(uint8 _location, uint256 _entryFee) public onlyAdmin whenNotPaused{

        entryFee[_location] = _entryFee;
    }


    /**
     * @notice function sets address of MArketHeroAnimal Contract
     */
    function setMarketHeroAnimalContract(address _marketHeroAnimalAddress)
        public
        onlyAdmin
        whenNotPaused
    {
        marketHeroAnimalAddress = _marketHeroAnimalAddress;
    }

   

    /** 
     * @notice function starts game and returns random value for start position of players
        also emits "gamestarted" event 
     * @param _tokenID1 token id of hero1
     * @param _tokenID2 token id of hero2
     * @param _location game location (enumeration) 
      */
    function startGame(
        uint256 _tokenID1,
        uint256 _tokenID2,
        uint8 _location
    ) external onlyBackend  whenNotPaused{        
        
        IERC20Upgradeable(tokenMHT).safeTransferFrom(
            IERC721Upgradeable(marketHeroAnimalAddress).ownerOf(_tokenID1),
            address(this),
            entryFee[_location]
        );
        IERC20Upgradeable(tokenMHT).safeTransferFrom(
            IERC721Upgradeable(marketHeroAnimalAddress).ownerOf(_tokenID2),
            address(this),
            entryFee[_location]
        );
        uint256 _gameID = ++lastGameID;
        uint8 _startPosition = uint8(
            MarketHeroUtils(marketHeroUtilsAddress).random(
                0,
                1,
                Strings.toString(_gameID)
            )
        );

        games[_gameID].hero1 = _tokenID1;
        games[_gameID].hero2 = _tokenID2;
        games[_gameID].bet = entryFee[_location];
        games[_gameID].gameStatus = Result.Started;

        emit GameStarted(_gameID, _tokenID1, _tokenID2, entryFee[_location], _startPosition );
    }

    /** 
     * @notice function finishes game with draw and updates heroes games` statistics
        also emits "gamefinished" event 
     * @param _gameID id of finished game
      */
    function endGameWithDraw(uint256 _gameID) external onlyBackend whenNotPaused{
        require(
            games[_gameID].gameStatus == Result.Started,
            "MarketHeroGame: This game is already over"
        );
        games[_gameID].gameStatus = Result.Draw;

        
        IERC20Upgradeable(tokenMHT).safeTransfer(
            // address(this),
            IERC721Upgradeable(marketHeroAnimalAddress).ownerOf(games[_gameID].hero1),
            games[_gameID].bet
        );
        IERC20Upgradeable(tokenMHT).safeTransfer(
            // address(this),
            IERC721Upgradeable(marketHeroAnimalAddress).ownerOf(games[_gameID].hero2),
            games[_gameID].bet
        );
        IMarketHeroAnimal(marketHeroAnimalAddress).gameLostOrTied(
            games[_gameID].hero1
        );
        IMarketHeroAnimal(marketHeroAnimalAddress).gameLostOrTied(
            games[_gameID].hero2
        );
        emit GameFinished(_gameID, uint8(games[_gameID].gameStatus));
    }

    /** 
     * @notice function finishes game with victory of entered player 
        updates heroes games` statistics
        also emits "gamefinished" event 
     * @param _gameID id of finished game
      */
    function endGameWithWinner(uint256 _gameID, uint256 _tokenID)
        external
        onlyBackend
        whenNotPaused
    {
        require(
            games[_gameID].gameStatus == Result.Started,
            "MarketHeroGame: This game is already over"
        );

        if (_tokenID == games[_gameID].hero1) {
            games[_gameID].gameStatus = Result.Hero1Won;
            IMarketHeroAnimal(marketHeroAnimalAddress).gameWon(games[_gameID].hero1);
            IMarketHeroAnimal(marketHeroAnimalAddress).gameLostOrTied(
                games[_gameID].hero2
            );
        } else if (_tokenID == games[_gameID].hero2) {
            games[_gameID].gameStatus = Result.Hero2Won;
            IMarketHeroAnimal(marketHeroAnimalAddress).gameWon(games[_gameID].hero2);
            IMarketHeroAnimal(marketHeroAnimalAddress).gameLostOrTied(
                games[_gameID].hero1
            );
        }
        IERC20Upgradeable(tokenMHT).safeTransfer(
            // address(this),
            IERC721Upgradeable(marketHeroAnimalAddress).ownerOf(_tokenID),
            games[_gameID].bet + games[_gameID].bet * reward / PERCENT_DENOMINATOR
        );

        emit GameFinished(_gameID, uint8(games[_gameID].gameStatus));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./../contracts-upgradeable/proxy/utils/Initializable.sol";
import "./../contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./../contracts-upgradeable/security/PausableUpgradeable.sol";


contract MarketHeroController is Initializable, AccessControlUpgradeable, PausableUpgradeable{

    // bool public paused;
    bytes32 public constant BACKEND_ROLE = keccak256("BACKEND_ROLE");
    // address public marketHeroAnimalAddress;
    // address public marketHeroShopAddress;
    // address public marketHeroGameAddress;
    // address public marketHeroUtilsAddress;
    address public initialAdmin;

    function initialize(
        address _admin
    )public initializer{
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        initialAdmin = _admin;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE){
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE){
        _unpause();
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}