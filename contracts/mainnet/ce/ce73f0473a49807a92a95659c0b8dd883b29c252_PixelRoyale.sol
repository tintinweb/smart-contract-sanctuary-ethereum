// SPDX-License-Identifier: MIT
// This is no CC0
// www.PixelRoyal.xyz
// The Pixel Royale will start after mint out
pragma solidity 0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import './PixelTag.sol';

contract PixelRoyale is ERC721A, Ownable {
    //---------- Addies ----------//
    address public contractCreator;
    address public lastPlayer;
    address public mostAttacks;
    address public randomPlayer;
    address public randomTag;
    address public abashoCollective; // ---> Needs to be set
    address public pixelTagContract; // ---> Interface for Tags
    //---------- Mint Vars ----------//
    bool public started;
    bool public claimed;
    uint256 public constant MAXPIXELS = 4444;
    uint256 public constant WALLETLIMIT = 2;
    uint256 public constant CREATORCLAIMAMOUNT = 3;
    mapping(address => uint) public addressClaimed; // ---> keeps track of wallet limit
    // MetadataURI
    string private baseURI;
    //---------- PixelRoyale Vars ----------//
    bool public pixelWarStarted;
    bool public pixelWarConcluded;
    uint256 public timeLimit = 1671667200; // Thursday, 22. December 2022 00:00:00 GMT
    uint constant ITEM_PRICE = 0.005 ether;
    mapping(address => uint) public walletHighscore; // ---> keeps track of each wallet highscore
    uint256 public currentHighscore;
    string private salt;
    bool public payout;
    //---------- Mini Jackpot Vars ----------//
    uint256[] public jackpot;
    //---------- Player Vars ----------//
    struct Pixel {
        int256 health;
        bool status;
    }
    mapping(uint256 => Pixel) public pixelList; // ---> maps ID to a Player Struct

    //---------- Events ----------//
    event ItemBought(address from,address currentMA,uint tokenId,int256 amount);
    event DropOut(address from,uint tokenId);
    event MiniJackpotWin(address winner, uint256 jackpotAmount);
    event MiniJackpotAmount(uint256 jackpotAmount);

    //---------- Construct ERC721A TOKEN ----------//
    constructor() ERC721A("PixelRoyale BATTLE GAME", "PRBG") {
        contractCreator = msg.sender;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    //---------------------------------------------------------------------------------------------
    //---------- MINT FUNCTIONS ----------//
    //---------- Start Minting -----------//
    function startMint() external onlyOwner {
        require(!started, "mint has already started");
        started = true;
    }

    //---------- Free Mint Function ----------//
    function mint(uint256 _amount) external {
        uint256 total = totalSupply();
        if(_msgSender() != contractCreator) {
            require(started, "Mint did not start yet");
            require(addressClaimed[_msgSender()] + _amount <= WALLETLIMIT, "Wallet limit reached, don't be greedy");
        }
        require(_amount > 0, "You need to mint at least 1");
        require(total + _amount <= MAXPIXELS, "Not that many NFTs left, try to mint less");
        require(total <= MAXPIXELS, "Mint out");

        // create structs for minted amount
        for (uint j; j < _amount; j++) {
            Pixel memory newPixel = Pixel(0,true);
            pixelList[total+j+1] = newPixel;
        }
        addressClaimed[_msgSender()] += _amount;
        _safeMint(_msgSender(), _amount);

        // immediately starts PixelRoyale GAME on mint out
        if(totalSupply() >= MAXPIXELS){
            pixelWarStarted = true;
        }
    }

    //---------- Team Claim ----------//
    function teamClaim() external onlyOwner {
        uint256 total = totalSupply();
        require(!claimed, "already claimed");
        for (uint j; j < CREATORCLAIMAMOUNT; j++) {
            // struct creation for mint amount
            Pixel memory newPixel = Pixel(0,true);
            pixelList[total+j+1] = newPixel;
        }
        _safeMint(contractCreator, CREATORCLAIMAMOUNT);
        claimed = true;
    }

    //---------------------------------------------------------------------------------------------
    //---------- BATTLE ROYALE GAME ----------//
    //---------- Manually Start PixelRoyale ----------//
    function startPixelWar() external onlyOwner {
        require(!pixelWarStarted, "The war has already been started");
        pixelWarStarted = true;
    }

    //---------- Calculate Amount Of "Alive" Players ----------//
    function getPopulation() public view returns(uint256 _population) {
        for (uint j=1; j <= totalSupply(); j++) {
            if(isAlive(j)){
                _population++;
            }
        }
    }

    //---------- Returns Last Player ID ----------//
    function checkLastSurvivor() public view returns(uint256 _winner) {
        for (uint j; j <= totalSupply(); j++) {
            if(pixelList[j].health > -1){
                _winner = j;
            }
        }
    }

    //---------- Checks If Specified TokenID Is "Alive" ----------//
    function isAlive(uint256 _tokenId) public view returns(bool _alive) {
        pixelList[_tokenId].health < 0 ? _alive = false : _alive = true;
    }

    //---------- Returns Random "Alive" TokenID ----------//
    function returnRandomId() public view returns(uint256 _tokenId) {
        for (uint256 j = pseudoRandom(totalSupply(),"Q"); j <= totalSupply() + 1; j++) {
            if(pixelList[j].health > -1) {
                return j;
            }
            if(j == totalSupply()) {
                j = 0;
            }
        }
    }

    //---------- Pseudo Random Number Generator From Range ----------//
    function pseudoRandom(uint256 _number, string memory _specialSalt) public view returns(uint number) {
        number = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender,salt,_specialSalt))) % _number;
        number == 0 ? number++: number;
    }

    //---------- Change Salt Value Pseudo Randomness ----------//
    function changeSalt(string memory _newSalt) public onlyOwner {
        salt = _newSalt;
    }

    //---------- Set HP For Players | Protect/Attack ----------//
    function setHP(uint256 _tokenId, int256 _amount) external payable {
        require(!pixelWarConcluded, "PixelRoyale has concluded!");
        require(pixelWarStarted, "PixelRoyale hasn't started!");
        require(getPopulation() > 1, "We already have a winner!");
        require(_amount != 0, "Value needs to be > or < than 0");
        require(pixelList[_tokenId].health > -1, "Player already out of the Game");

        uint priceMod = 10; // ---> 0%
        uint256 amount;

        // turn _amount into a positive amount value
        _amount < 0 ? amount = uint256(_amount*-1) : amount = uint256(_amount);

        // bulk pricing:
        if(amount>6) {
            priceMod = 8; // ---> 20%
            if(amount>12) {
                priceMod = 7; // ---> 30%
                if(amount>18) {
                    priceMod = 6; // ---> 40%
                    if(amount>24) { priceMod = 5; } // ---> 50%
                }
            }
        }

        // calculate purchase
        uint256 currentPrice = ITEM_PRICE / 10 * priceMod * amount;
        require((currentPrice) <= msg.value, "Not enough ETH");

        // checks on attack purchase
        if(_amount < 0) {
            require(pixelList[_tokenId].health+_amount>-2,"Try less attacks - warrior overkill");
            walletHighscore[_msgSender()] += amount;
            if(walletHighscore[_msgSender()] > currentHighscore) {
                currentHighscore = walletHighscore[_msgSender()];
                mostAttacks = _msgSender();
            }
        }

        // change health value in player struct
        (pixelList[_tokenId].health+_amount) < 0 ? pixelList[_tokenId].health = -1 : pixelList[_tokenId].health = pixelList[_tokenId].health + _amount;

        //emit event for item buy
        emit ItemBought(_msgSender(),mostAttacks,_tokenId,_amount); // ---> buyer, current Highscore Leader, Interacted token, amount of protections/attacks

        // add to mini jackpot array
        addToPot(msg.value);

        // try jackpot
        if(jackpot.length>0){
            tryJackpot();
        }

        // check if token is alive | Check if player has dropped out of Game
        InterfacePixelTags pixelTag = InterfacePixelTags(pixelTagContract); // ---> Interface to Tags NFT
        if ( !isAlive(_tokenId) ) {
            pixelTag.mintPixelTag(_msgSender()); // ---> MINT DogTag FROM ERC721A
            pixelList[_tokenId].status = false;

            //emit DropOut event
            emit DropOut(_msgSender(),_tokenId); // ---> Killer, Killed Token
        }
        // check if population is smaller than 2 | check if PixelRoyale has concluded
        if ( getPopulation() < 2 ) {
            pixelWarConcluded = true;
            lastPlayer = ownerOf(checkLastSurvivor());
            randomPlayer = ownerOf(pseudoRandom(MAXPIXELS,"Warrior"));
            randomTag = pixelTag.ownerOf(pseudoRandom(MAXPIXELS-1,"Tag"));
        }
    }

    //---------------------------------------------------------------------------------------------
    //---------- BATTLE ROYALE GAME ----------//
    //---------- Add 49% Of Bet To Mini Jackpot ----------//
    function addToPot(uint256 _amount) internal {
        jackpot.push(_amount/100*49);
    }

    //---------- Calculate Current Mini Jackpot Size ----------//
    function currentPot() internal view returns(uint256 _result) {
        for (uint j; j < jackpot.length; j++) {
            _result += jackpot[j];
        }
    }

    //---------- Win Mini Jackpot Function ----------//
    function tryJackpot() internal {
        if(pseudoRandom(8,"") == 4) { // ---> 12,5% winning chance
            payable(_msgSender()).transfer(currentPot());
            emit MiniJackpotWin(_msgSender(), currentPot()); // ---> emits jackpot amount and winner when hit
            delete jackpot; // ---> purge mini jackpot array after it has been paid out
        }
        else {
            emit MiniJackpotAmount(currentPot()); // ---> emits jackpot amount when not hit
        }
    }

    //---------- Set PixelTag Contract Address For Interactions/Interface ----------//
    function setTagContract(address _addr) external onlyOwner {
        pixelTagContract = _addr;
    }
    //---------------------------------------------------------------------------------------------
    //---------- WITHDRAW FUNCTIONS ----------//

    //---------- Distribute Balance if Game Has Not Concluded Prior To Time Limit ----------//
    function withdraw() public {
        require(block.timestamp >= timeLimit, "Play fair, wait until the time limit runs out");
        require(contractCreator == _msgSender(), "Only Owner can withdraw after time limit runs out");
        uint256 balance = address(this).balance;
        payable(abashoCollective).transfer(balance/100*15);
        payable(contractCreator).transfer(address(this).balance);
    }

    //---------- Distribute Balance if Game Has Concluded Prior To Time Limit ----------//
    function distributeToWinners() public {
        require(pixelWarConcluded, "The game has not concluded yet!");
        require(!payout, "The prize pool has already been paid out!");
        uint256 balance = address(this).balance;
        // 25% to Last player and most attacks
        payable(lastPlayer).transfer(balance/100*25);
        payable(mostAttacks).transfer(balance/100*25);
        // 15% to random holder of Player and Dog Tag NFTs
        payable(randomPlayer).transfer(balance/100*10);
        payable(randomTag).transfer(balance/100*10);
        // 15% to abasho collective and remainder to Contract Creator
        payable(abashoCollective).transfer(balance/100*15);
        payable(contractCreator).transfer(address(this).balance);
        payout = true;
    }
    //---------------------------------------------------------------------------------------------
    //----------SET LATE ABASHO COLLECTIVE ADDRESS ----

    function setAbashoADDR(address _addr) external onlyOwner {
        abashoCollective = _addr;
    }

    //---------------------------------------------------------------------------------------------
    //---------- METADATA & BASEURI ----

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "There is no token with that ID");
        string memory currentBaseURI = _baseURI();
        if(isAlive(_tokenId)) {
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), '.json')) : '';
        }
        else {
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI,'d', _toString(_tokenId), '.json')) : '';
        }

        
    }
}

// SPDX-License-Identifier: MIT
// www.PixelRoyale.xyz
/*
 ____ ____ ____ ____ ____ ____ ____ ____ ____ 
||P |||i |||x |||e |||l |||T |||a |||g |||s ||
||__|||__|||__|||__|||__|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|/__\|
 
 */

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import {Base64} from "base64-sol/base64.sol";
import {TraitAssembly} from "./TraitAssembly.sol";

contract PixelTags is ERC721A, Ownable {
    //---------- Vars ----------//
    address public contractCreator;
    address public pixelRoyale;
    uint256 public constant MAXTAGS = 4443;
    string private baseURI;
    //---------- On-Chain Gen Art ----------//
    uint16 private pixelIndex = 1;
    mapping(uint256 => uint32) private pixelTags;
    //---------- Metadata Snippets ----------//
    string private comb1 = '","description": "4443 On-Chain PixelTags given out for confirmed kills in the PixelRoyale BATTLE GAME. Collect the PixelTags for a chance to win 10% of the PixelRoyale prize pool!","external_url": "https://pixelroyale.xyz/","attributes": [{"trait_type": "Background","value": "';
    string private comb2 = '"},{"trait_type": "Base","value": "';
    string private comb3 = '"},{"trait_type": "Soul","value": "';
    string private comb4 = '"},{"trait_type": "Accessoire","value": "';
    string private comb5 = '"},{"trait_type": "Mouth","value": "';
    string private comb6 = '"},{"trait_type": "Eyes","value": "';
    string private comb7 = '"}],"image": "data:image/svg+xml;base64,';
    string private comb8 = '"}';
    //---------- Trait Names ----------//
    string[4] maTrait = ["Ag", "Au", "Pt", "Rn"];

    //---------- Construct ERC721A TOKEN ----------//
    constructor() ERC721A("PixelTags BATTLE GAME", "PTBG") {
      contractCreator = msg.sender;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
      return 1;
    }

    //---------------------------------------------------------------------------------------------
    //---------- MINT FUNCTIONS ----------//
    //---------- Set Origin Contract ----------//
    function setMintContract(address _addr) external onlyOwner {
      pixelRoyale = _addr;
    }

    //---------- Mint PixelTag ----------//
    function mintPixelTag(address _receiver) external {
        require(msg.sender == pixelRoyale, "Only Contract can mint");
        uint256 total = totalSupply();
        require(total < MAXTAGS, "The GAME has most likely concluded");
        // Mint
        _safeMint(_receiver, 1);
        pixelTags[pixelIndex] = uint32(bytes4(keccak256(abi.encodePacked(block.timestamp, pixelIndex, msg.sender))));
        pixelIndex++;
    }

    //---------------------------------------------------------------------------------------------
    //---------- METADATA GENERATION ----------//

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'There is no Token with that ID');
        //Start JSON and SVG Generation by creating file headers
        bytes memory json = abi.encodePacked('{"name": "Pixel Tag #',Strings.toString(_tokenId)); // --> JSON HEADER
        bytes memory img = abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" witdh="640" height="640" viewBox="0 0 16 16">'); // --> SVG HEADER
        uint32 seed = pixelTags[_tokenId];
        //Init Trait Strings
        string memory trait1;
        string memory trait2;
        string memory svg2;
        string memory trait3;
        string memory svg3;
        string memory trait4;
        string memory svg4;
        //Init Color Strings 
        string memory basePrimeCol;
        string memory baseSecondCol;
        string memory backgroundColor = Strings.toString((seed%36)*10); 
        string memory soulColor =  Strings.toString((seed%72)*5);

        // ------ BASE COLOR TRAIT ----- //
        if(seed%99==0) { //--> 1%
            trait1 = maTrait[3];
            basePrimeCol ="179,24%,61%";
            baseSecondCol = "179,100%,86%";
        }
        else if(seed%99>=1 && seed%99<=5) { //--> 5%
            trait1 = maTrait[2];
            basePrimeCol ="180,6%,57%";
            baseSecondCol = "178,53%,88%";
        }
        else if(seed%99>=6 && seed%99<=20) { //--> 15%
            trait1 = maTrait[1];
            basePrimeCol ="46,67%,48%";
            baseSecondCol = "46,100%,70%";
        }
        else { //--> 79%
            trait1 = maTrait[0];
            basePrimeCol ="180,2%,40%";
            baseSecondCol = "180,2%,80%";
        }

        // ------ ACCESSORY TRAIT ----- //
        if(seed%99>=75) { //--> 24%
            (svg2,trait2) = ("","None");
        }
        else { //--> 76%
            (svg2,trait2) = TraitAssembly.choseA(seed);
        }

        // ------ MOUTH TRAIT ----- //
        (svg3,trait3) = TraitAssembly.choseM(seed);

        // ------ EYE TRAIT ----- //
        (svg4,trait4) = TraitAssembly.choseE(seed);

        // ----- JSON ASSEMBLY ------//
        json = abi.encodePacked(json,comb1,backgroundColor);
        json = abi.encodePacked(json,comb2,trait1);
        json = abi.encodePacked(json,comb3,soulColor);
        json = abi.encodePacked(json,comb4,trait2);
        json = abi.encodePacked(json,comb5,trait3);
        json = abi.encodePacked(json,comb6,trait4);

        // ----- SVG ASSEMBLY ------//
        //BACKGROUND//
        img = abi.encodePacked(img, '<rect x="0" y="0" width="16" height="16" fill="hsl(',backgroundColor,',100%,90%)"/>');
        //BASE// 
        img = abi.encodePacked(img, '<polygon points="5,1 5,2 4,2 4,3 3,3 3,4 3,13 4,13 4,14 5,14 5,15 11,15 11,14 12,14 12,13 13,13 13,3 12,3 12,2 11,2 11,1" fill="hsl(',basePrimeCol,')"/>');  // --> Outline
        img = abi.encodePacked(img, '<polygon points="5,2 5,3 4,3 4,3 4,3 4,4 4,13 5,13 5,14 6,14 6,14 11,14 11,13 11,13 12,13 12,3 11,3 11,2 11,2" fill="hsl(',baseSecondCol,')"/>'); //--> Inner
        //ACCESSORY
        img = abi.encodePacked(img, svg2);
        //MOUTH
        img = abi.encodePacked(img, svg3);
        //EYES
        img = abi.encodePacked(img, svg4);
        // ----- CLOSE OFF SVG AND JSON ASSEMBLY ------//
        img = abi.encodePacked(img, '</svg>');
        json = abi.encodePacked(json,comb7,Base64.encode(img),comb8);
        // ----- RETURN BASE64 ENCODED METADATA ------//
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(json)));
    }
}
//---------------------------------------------------------------------------------------------
//---------- LAY OUT INTERFACE ----------//
interface InterfacePixelTags {
    function mintPixelTag(address _receiver) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;
    
    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID. 
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count. 
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        assembly { // Cast aux without masking.
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
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
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
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
     * @dev Casts the address to uint256 without masking.
     */
    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev Casts the boolean to uint256 without branching.
     */
    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = address(uint160(_packedOwnershipOf(tokenId)));
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
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
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
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
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
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
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.code.length != 0) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
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
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the balance and number minted.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
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
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
            isApprovedForAll(from, _msgSenderERC721A()) ||
            getApproved(tokenId) == _msgSenderERC721A());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
                isApprovedForAll(from, _msgSenderERC721A()) ||
                getApproved(tokenId) == _msgSenderERC721A());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        delete _tokenApprovals[tokenId];

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] =
                _addressToUint256(from) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_BURNED | 
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
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

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), 
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length, 
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for { 
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp { 
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } { // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            
            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
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
// ERC721A Contracts v4.0.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // ==============================
    //        IERC721Metadata
    // ==============================

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
// www.PixelRoyale.xyz
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

library TraitAssembly {
    
    //---------- ACCESSORY ASSEMBLY - WITH ACCESSORY SVGs ----------//
    function choseA(uint32 _seed) public pure returns (string memory _aString, string memory _aJson) {
        string[13] memory _traitArray = ["Flower Crown", "Night Vision", "Trauma", "Sleek Curl", "Twin Tails", "Red Rag", "Blue Rag", "Snapback", "Crown", "One Peace", "Red Oni", "Blue Oni", "Clown"];
        string memory _trait = _traitArray[_seed%12];
        string memory soulCol =  Strings.toString((_seed%72)*5);
        string memory inverseCol = Strings.toString((((_seed%72)*5)+180)%360);
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[0]))) {
            _aString = '<polygon points="3,3 8,3 8,4 9,4 9,3 13,3 13,4 14,4 14,5 13,5 13,6 8,6 8,5 7,5 7,6 3,6 3,5 2,5 2,4 3,4" fill="hsl(102, 75%, 58%)"/><polygon points="5,3 11,3 11,4 12,4 12,5 11,5 11,6 10,6 10,5 9,5 9,4 10,4 10,3 6,3 6,4 7,4 7,5 6,5 6,6 5,6 5,5 4,5 4,4 5,4" fill="hsl(0, 100%, 100%)"/><polygon points="5,4 11,4 11,5 10,5 10,4 6,4 6,5 5,5 5,4" fill="hsl(48, 100%, 57%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[1]))) {
            _aString = '<polygon points="4,2 6,2 6,3 7,3 7,2 9,2 9,3 10,3 10,2 12,2 12,3 13,3 13,5 14,5 14,6 10,6 10,5 6,5 6,6 2,6 2,5 3,5 3,3 4,3" fill="hsl(0,0%,0%)"/><polygon points="4,3 12,3 12,5 10,5 10,3 9,3 9,4 7,4 7,3 6,3 6,5 4,5" fill="hsl(102, 73%, 64%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[2]))) {
            _aString = '<polygon points="9,2 11,2 11,5 10,5 10,3 9,3" fill="hsl(352, 100%, 41%)"/>'; 
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[3]))) {
            _aString = string(abi.encodePacked('<polygon points="4,1 12,1 12,2 13,2 13,7 12,7 12,6 11,6 11,4 8,4 8,5 9,5 9,6 7,6 7,4 5,4 5,6 4,6 4,7 3,7 3,2 4,2" fill="hsl(',inverseCol,', 80%, 60%)"/>')); 
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[4]))) {
            _aString = string(abi.encodePacked('<polygon points="5,1 11,1 11,2 12,2 12,3 13,3 13,4 14,4 14,5 15,5 15,6 16,6 16,10 15,10 15,9 14,9 14,6 13,6 13,7 12,7 12,6 11,6 11,5 10,5 10,6 9,6 9,5 8,5 8,6 6,6 6,5 5,5 5,6 4,6 4,7 3,7 3,6 2,6 2,9 1,9 1,10 0,10 0,6 1,6 1,5 2,5 2,4 3,4 3,3 4,3 4,2 5,2" fill="hsl(',inverseCol,', 80%, 60%)"/><polygon points="2,4 3,4 14,4 14,6 13,6 13,4 3,4 3,6 2,6 " fill="hsl(',soulCol,', 40%, 60%)"/>'));
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[5]))) {
            _aString = '<polygon points="3,2 4,2 4,1 12,1 12,2 13,2 13,5 2,5 2,6 1,6 1,5 2,5 2,4 1,4 1,3 2,3 2,4 3,4" fill="hsl(0, 75%, 50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[6]))) {
            _aString = '<polygon points="3,2 4,2 4,1 12,1 12,2 13,2 13,5 2,5 2,6 1,6 1,5 2,5 2,4 1,4 1,3 2,3 2,4 3,4" fill="hsl(225, 75%, 50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[7]))) {
            _aString = string(abi.encodePacked('<polygon points="3,4 3,2 4,2 4,1 12,1 12,2 13,2 13,5 2,5 1,5 1,4" fill="hsl(',soulCol,', 75%, 50%)"/><polygon points="7,4 7,3 8,3 8,2 10,2 10,3 11,3 11,4" fill="hsl(',soulCol,', 75%, 25%)"/>'));
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[8]))) {
            _aString = '<polygon points="3,4 4,4 4,3 5,3 5,4 6,4 6,3 7,3 7,2 9,2 9,3 10,3 10,4 11,4 11,3 12,3 12,4 13,4 13,5 3,5 " fill="hsl(45, 100%, 50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[9]))) {
            _aString = '<polygon points="1,4 3,4 3,2 4,2 4,1 12,1 12,2 13,2 13,4 15,4 15,5 1,5" fill="hsl(45, 100%, 50%)"/><rect x="3" y="3" width="10" height="1" fill="hsl(0,100%,50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[10]))) {
            _aString = '<polygon points="12,5 12,3 13,3 13,2 14,2 14,1 15,1 15,4 14,4 14,5" fill="hsl(0,100%,50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[11]))) {
            _aString = '<polygon points="4,5 4,3 3,3 3,2 2,2 2,1 1,1 1,4 2,4 2,5" fill="hsl(225,100%,50%)"/>';
        }
        else if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[12]))) {
            _aString = string(abi.encodePacked('<polygon points="1,1 2,1 2,2 6,2 6,1 7,1 7,0 9,0 9,1 10,1 10,2 14,2 14,1 15,1 15,4 14,4 14,5 12,5 12,3 11,3 11,2 5,2 5,3 4,3 4,5 2,5 2,4 1,4" fill="hsl(',soulCol,',75%,45%)"/>'));
        }
        return(_aString,_aJson = _trait);
    }
    
    //---------- EYES ASSEMBLY - WITH EYE SVGs ----------//
    function choseE(uint32 _seed) public pure returns (string memory _eString, string memory _eJson) {
        string[17] memory _traitArray = ["Passive", "Sane", "Wary", "Fine", "Shut", "Glee", "Cool", "Tough", "Archaic", "Sly", "Sharp", "Sad", "Indifferent", "Focused", "Gloomy", "Abnormal", "Gem"];
        string memory _trait = _traitArray[_seed%16];
        string memory soulCol =  Strings.toString((_seed%72)*5);
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[0]))) {
            _eString = string(abi.encodePacked('<polygon points="5,7 11,7 11,9 9,9 9,7 7,7 7,9 5,9" fill="hsl(180,100%,100%)"/><polygon points="6,7 11,7 11,9 10,9 10,7 7,7 7,9 6,9" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[1]))) {
            _eString = string(abi.encodePacked('<polygon points="5,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9" fill="hsl(180,100%,100%)"/><polygon points="5,8 10,8 10,9 9,9 9,8 6,8 6,9 5,9" fill="hsl(',soulCol,',40%,60%)"/><polygon points="5,6 11,6 11,7 9,7 9,6 7,6 7,7 5,7" fill="hsl(180,0%,0%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[2]))) {
            _eString = string(abi.encodePacked('<polygon points="5,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9" fill="hsl(180,100%,100%)"/><polygon points="6,8 11,8 11,9 10,9 10,8 7,8 7,9 6,9" fill="hsl(',soulCol,',40%,60%)"/><polygon points="5,5 6,5 6,6 11,6 11,7 9,7 9,6 7,6 7,7 6,7 6,6 5,6" fill="hsl(180,0%,0%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[3]))) {
            _eString = string(abi.encodePacked('<polygon points="4,8 5,8 5,7 11,7 11,8 12,8 12,9 9,9 9,7 7,7 7,9 4,9" fill="hsl(180,0%,0%)"/><polygon points="5,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9" fill="hsl(',soulCol,',40%,60%)"/><polygon points="6,8 11,8 11,9 10,9 10,8 7,8 7,9 6,9" fill="hsl(180,0%,0%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[4]))) {
            _eString = '<polygon points="4,7 5,7 5,8 6,8 6,7 10,7 10,8 11,8 11,7 12,7 12,8 11,8 11,9 10,9 10,8 9,8 9,7 7,7 7,8 6,8 6,9 5,9 5,8 4,8" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[5]))) {
            _eString = '<polygon points="4,8 5,8 5,7 6,7 6,8 10,8 10,7 11,7 11,8 12,8 12,9 11,9 11,8 10,8 10,9 9,9 9,8 7,8 7,9 6,9 6,8 5,8 5,9 4,9" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[6]))) {
            _eString = '<polygon points="4,7 12,7 12,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9 5,8 4,8" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[7]))) {
            _eString = string(abi.encodePacked('<rect x="5" y="8" width="2" height="1" fill="hsl(180,100%,100%)"/><rect x="5" y="8" width="1" height="1" fill="hsl(',soulCol,',40%,60%)"/><polygon points="5,3 6,3 6,4 7,4 7,5 8,5 8,6 9,6 9,7 11,7 11,9 12,9 12,10 11,10 11,9 9,9 9,8 5,8 5,7 7,7 7,8 9,8 9,7 8,7 8,6 7,6 7,5 6,5 6,4 5,4" fill="hsl(180,0%,0%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[8]))) {
            _eString = string(abi.encodePacked('<polygon points="5,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9" fill="hsl(180,100%,100%)"/><polygon points="5,8 10,8 10,9 9,9 9,8 6,8 6,9 5,9" fill="hsl(',soulCol,',40%,60%)"/><rect x="4" y="7" width="8" height="1" fill="hsl(180,0%,0%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[9]))) {
            _eString = string(abi.encodePacked('<rect x="4" y="6" width="8" height="3" fill="hsl(180,0%,0%)"/><polygon points="5,7 11,7 11,8 9,8 9,7 7,7 7,8 5,8" fill="hsl(180,100%,100%)"/><polygon points="6,7 11,7 11,8 10,8 10,7 7,7 7,8 6,8" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[10]))) {
            _eString = string(abi.encodePacked('<polygon points="5,7 5,6 7,6 7,7 9,7 9,6 11,6 11,7 12,7 12,8 11,8 11,9 9,9 9,8 7,8 7,9 5,9 5,8 4,8 4,7" fill="hsl(180,0%,0%)"/><polygon points="5,7 11,7 11,8 9,8 9,7 7,7 7,8 5,8" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[11]))) {
            _eString = '<polygon points="11,8 11,10 10,10 10,8 6,8 6,12 5,12 5,8" fill="hsl(188, 39%, 58%)"/><polygon points="5,7 11,7 11,8 9,8 9,7 7,7 7,8 5,8" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[12]))) {
            _eString = string(abi.encodePacked('<polygon points="5,6 6,6 6,9 10,9 10,6 11,6 11,9 5,9" fill="hsl(180,0%,0%)"/><polygon points="4,7 12,7 12,8 9,8 9,7 7,7 7,8 4,8" fill="hsl(180,100%,100%)"/><polygon points="5,7 6,7 6,8 10,8 10,7 11,7 11,8 5,8" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[13]))) {
            _eString = string(abi.encodePacked('<polygon points="4,7 12,7 12,8 9,8 9,7 7,7 7,8 4,8" fill="hsl(180,0%,0%)"/><polygon points="4,8 12,8 12,9 9,9 9,8 7,8 7,9 4,9" fill="hsl(180,100%,100%)"/><polygon points="5,8 6,8 6,9 10,9 10,8 11,8 11,9 5,9" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[14]))) {
            _eString = string(abi.encodePacked('<polygon points="4,5 5,5 5,6 6,6 6,7 10,7 10,6 11,6 11,5 12,5 12,7 13,7 13,8 12,8 12,10 11,10 11,9 10,9 10,8 9,8 9,7 7,7 7,8 6,8 6,9 5,9 5,10 4,10 4,8 3,8 3,7 4,7 " fill="hsl(180,0%,0%)"/><polygon points="4,7 12,7 12,8 10,8 10,7 6,7 6,8 4,8" fill="hsl(180,100%,100%)"/><polygon points="5,7 6,7 6,8 11,8 11,7 12,7 12,8 5,8" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[15]))) {
            _eString = '<polygon points="5,8 6,8 6,9 10,9 10,7 11,7 11,9 10,9 5,9" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[16]))) {
            _eString = string(abi.encodePacked('<polygon points="5,7 11,7 11,9 9,9 9,7 7,7 7,9 5,9 " fill="hsl(180,100%,100%)"/><polygon points="5,8 6,8 6,7 7,7 7,8  10,8 10,7 11,7 11,8 10,8 10,9 9,9 9,8 6,8 6,9 5,9" fill="hsl(',soulCol,',40%,60%)"/>'));
        }
        return(_eString,_eJson = _trait);
    }

    //---------- MOUTH ASSEMBLY - WITH MOUTH SVGs ----------//
    function choseM(uint32 seed) public pure returns (string memory _mString, string memory _mJson) {
        string[18] memory _traitArray = ["Smile", "Rabbit", "Frown", "Jeez", "Deez", "Grin", "Hungry", "Hillbilly", "Yikes", "Dumber", "Cigarette", "Puke", "Raw", "Tongue", "Surprised", "Stunned", "Chew", "Respirator"]; 
        string memory _trait = _traitArray[seed%17];
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[0]))) {
            _mString = '<polygon points="6,11 5,11 5,10 6,10 6,11 10,11 10,10 11,10 11,11 10,11 10,12 6,12" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[1]))) {
            _mString = '<polygon points="6,11 5,11 5,10 6,10 6,11 10,11 10,10 11,10 11,11 10,11 10,12 6,12" fill="hsl(180,0%,0%)"/><polygon points="7,13 7,12 9,12 9,13" fill="hsl(180,100%,100%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[2]))) {
            _mString = '<polygon points="6,12 5,12 5,11 6,11 6,10 10,10 10,12 11,12 11,11 10,11 10,11 6,11 " fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[3]))) {
            _mString = '<rect x="7" y="10" width="2" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[4]))) {
            _mString = '<rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/><rect x="6" y="10" width="1" height="1" fill="hsl(180,100%,100%)"/><rect x="9" y="10" width="1" height="1" fill="hsl(180,100%,100%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[5]))) {
            _mString = '<polygon points="7,11 6,11 6,10 7,10 7,11 9,11 9,10 10,10 10,11 9,11 9,12 7,12" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[6]))) {
            _mString = '<polygon points="7,11 7,12 6,12 6,10 10,10 10,13 9,13 9,12 8,12 8,11" fill="hsl(188, 39%, 58%)"/><rect x="6" y="10" width="4" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[7]))) {
            _mString = '<polygon points="7,11 7,12 6,12 6,10 10,10 10,12 9,12 9,11" fill="hsl(180, 100%, 100%)"/><rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[8]))) {
            _mString = '<rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/><rect x="6" y="10" width="4" height="1" fill="hsl(180,100%,100%)"/> ';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[9]))) {
            _mString = '<rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/><rect x="6" y="10" width="4" height="1" fill="hsl(180,100%,100%)"/><rect x="7" y="10" width="1" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[10]))) {
            _mString = '<polygon points="6,12 6,11 5,11 5,10 6,10 6,11 10,11 10,12" fill="hsl(180,0%,0%)"/><rect x="9" y="11" width="2" height="1" fill="hsl(180,100%,100%)"/><rect x="11" y="11" width="1" height="1" fill="hsl(358, 100%, 51%)"/><polygon points="13,11 12,11 12,10 13,10 13,7 12,7 12,8 13,8 13,9 14,9 14,10 13,10 " fill="hsl(0, 0%, 90%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[11]))) {
            _mString = '<polygon points="9,10 11,10 11,14 10,14 10,13 9,13" fill="hsl(119, 100%, 41%)"/><rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[12]))) {
            _mString = '<polygon points="7,11 7,12 6,12 6,10 9,10 11,10 11,14 10,14 10,13 9,13 9,11" fill="hsl(352, 100%, 41%)"/><rect x="5" y="10" width="6" height="1" fill="hsl(180,0%,0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[13]))) {
            _mString = '<polygon points="5,10 11,10 11,11 10,11 10,13 9,13 9,14 8,14 7,14 7,13 6,13 6,11 5,11," fill="hsl(180, 0%, 0%)"/><rect x="7" y="11" width="2" height="2" fill="hsl(4, 74%, 50%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[14]))) {
            _mString = '<polygon points=" 7,10 6,10 6,9 10,9 10,10 11,10 11,12 10,12 10,13 6,13 6,12 5,12 5,10" fill="hsl(180, 0%, 0%)"/><rect x="6" y="10" width="4" height="2" fill="hsl(4, 74%, 50%)"/><rect x="9" y="10" width="1" height="1" fill="hsl(180, 100%, 100%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[15]))) {
             _mString = '<rect x="7" y="10" width="2" height="2" fill="hsl(4, 74%, 50%)"/><rect x="8" y="10" width="1" height="1" fill="hsl(180, 100%, 100%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[16]))) {
            _mString = '<polygon points="6,10 11,10 11,9 10,9 10,12 11,12 11,11 6,11" fill="hsl(180, 0%, 0%)"/>';
        }
        if (keccak256(abi.encodePacked(_trait)) == keccak256(abi.encodePacked(_traitArray[17]))) {
            _mString = '<polygon points="3,8 4,8 4,9 5,9 5,10 6,10 6,9 10,9 10,10 11,10 11,9 12,9 12,8 13,8 13,9 12,9 12,10 11,10 11,12 13,12 13,13 3,13 3,12 5,12 5,10 4,10 4,9 3,9 " fill="hsl(0, 0%, 20%)"/><rect x="6" y="10" width="4" height="2" fill="hsl(53, 12%, 85%)"/>';
        }
        return(_mString,_mJson = _trait);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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