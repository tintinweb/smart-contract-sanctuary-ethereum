/***
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMWXKXNWMMMMMMMMMMMMMMMMWNNXKKKKKKKKKKKKK0000000KNMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMW0:.,:d0NMMMMMMMMMMWXx:'......................dNMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.   .;xXMMMMMMMWx'         .'''''.        .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMx.      :KMMMMMMk.        .xXNNNNNO'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMx.      .dWMMMMWl         cNMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMx.       lWMMMMWl         lWMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMx.       lNMMMMWl         lWMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMx.       lNMMMMWl         lWMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMd.       lNMMMMWl         lNMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMd.       lNMMMMMO.        lNMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMd.       lNMMMMMWO,       lNMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMd.       lNMMMMMMMNkc'..  ;XMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMd.       lNMMMMMMMMMWNK0xoo0WMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       lNMMMMMMMMMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       lNMMMMMMMMMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       lNMMMMMMMMMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       lNMMMMMMMMMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMMMMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMWWMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMWkccokOKWMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMK,    .;dXMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX:       ,kWMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX:        '0MMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX:        .xMMMMMK,       .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX:        .dMMMMMK,       .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX:        .dMMMMMK,       .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX;        .dWMMMMK,       .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMK,        .xMMMMMNc       .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       ;k00000k:         :XMMMMMMK:      .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.                       .lKMMMMMMMMNk:.   .kWMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMXl'..'''''',,,,,,,,,,,;:cxKWMMMMMMMMMMMWXko::oXMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWNNNNNNNNNNWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMWNWMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 *
 * @title: LadyLlamas.sol
 * @author: MaxFlowO2 on Twitter/GitHub
 */

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <=0.9.0;

import "./token/ERC721/ERC721.sol";
import "./eip/2981/ERC2981Collection.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./lib/CountersV2.sol";
import "./utils/ContextV2.sol";
import "./modules/WhitelistV2.sol";
import "./access/MaxAccessControl.sol";
import "./modules/PaymentSplitterV2.sol";
import "./modules/Llamas.sol";
import "./modules/ContractURI.sol";

contract LadyLlamas is ERC721
                     , ERC2981Collection
                     , ContractURI
                     , Llamas
                     , WhitelistV2
                     , PaymentSplitterV2
                     , MaxAccess
                     , ReentrancyGuard {

  using CountersV2 for CountersV2.Counter;
  using Strings for uint256;

  CountersV2.Counter private _tokenIdCounter;
  uint private mintStartID;
  uint private constant MINT_FEE_ONE = 0.1 ether; // 5+ on day 1
  uint private constant MINT_FEE_TWO = 0.15 ether; // 3-4 on day 1 + whitelist day 2
  uint private constant MINT_FEE_THREE = 0.2 ether; // 1-2 on day 3
  uint private timeOneStart;
  uint private timeTwoStart;
  uint private timeThreeStart;
  uint private timeThreeEnd;
  uint private constant MINT_SIZE = 3000;
  string private unrevealedBase;
  string private base;
  bool private revealedNFT;
  bool private enableMinter;
  bool private lockedProvenance;
  bool private lockedPayees;
  bool private lockedAirdrop;
  mapping(uint => bool) private LBLUsed;
  mapping(address => bool) public oneToOne;
  mapping(address => bool) public threeToOne;
  IERC721 private LBLNFT; // don't forget to add this later

  error ToEarly(uint time, uint startTime);
  error ToLate(uint time, uint endTime);
  error AlreadyClaimed(uint tokenID);
  error NotEnoughETH(uint required, uint sent);
  error AlreadyMinted();
  error NotOnWhitelist();
  error OverMaximumMint();
  error CanNotMintThatMany(uint requested, uint allowed);
  error ProvenanceNotSet();
  error ProvenanceAlreadySet();
  error PayeesNotSet();
  error PayeesAlreadySet();
  error NFTsAlreadyRevealed();
  error NonMintedToken(uint token);
  error NullArray();
  error AirdropLocked();
  error NoTimesSet();

  event NFTReveal(bool status, uint time);
  event UpdatedUnrevealedBaseURI(string _old, string _new);
  event UpdatedBaseURI(string _old, string _new);
  event ProvenanceLocked(bool _status);
  event PayeesLocked(bool _status);
  event DayOneTimes(uint start, uint end);
  event DayTwoTimes(uint start, uint end);
  event DayThreeTimes(uint start, uint end);
  event LBLContractAddressUpdated(address _update);
  event AirdropIsLocked(bool _status);

  constructor() ERC721("Lady Llamas", "LL") {}

/***
 *    ███╗   ███╗██╗███╗   ██╗████████╗
 *    ████╗ ████║██║████╗  ██║╚══██╔══╝
 *    ██╔████╔██║██║██╔██╗ ██║   ██║   
 *    ██║╚██╔╝██║██║██║╚██╗██║   ██║   
 *    ██║ ╚═╝ ██║██║██║ ╚████║   ██║   
 *    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   
 */

  // @notice: this is the 5+ mint for the UX/UI team
  // @param ids: Array of LBL id's to mint off of
  // This will take ids, and lock them out of the mapping
  // so an id can not remint a LL. Cost will be .1 eth per
  // length.ids/5. Can mint multiple.
  function publicMintFiveToOne(
    uint256[] memory ids
    ) 
    public 
    payable
    nonReentrant() {
    // locals
    address user = _msgSender();

    // errors
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (block.timestamp < timeOneStart) {
      revert ToEarly({
        time: block.timestamp
      , startTime: timeOneStart
      });
    }
    if (block.timestamp >= timeTwoStart) {
      revert ToLate({
        time: block.timestamp
      , endTime: timeTwoStart
      });
    }
    // checks & effects
    uint length = ids.length;
    uint quant;
    for(uint x=0; x < length;) {
      if (LBLUsed[ids[x]]) {
        revert AlreadyClaimed({
          tokenID: ids[x]
        });
      }
      if (LBLNFT.ownerOf(ids[x]) == user){
        ++quant;
        LBLUsed[ids[x]] = true;
      }
      unchecked { ++x; }
    }
    quant = quant / 5; // 5:1 ratio for 0.1 eth
    if (_msgValue() != quant * MINT_FEE_ONE) {
      revert NotEnoughETH({
        required: quant * MINT_FEE_ONE
      , sent: _msgValue()
      });
    }

    // minting
    if (quant + _tokenIdCounter.current() >= MINT_SIZE) {
      revert OverMaximumMint();
    }
    for(uint x=0; x < quant;) {
      _safeMint(user, mintID());
      _tokenIdCounter.increment();
      unchecked { ++x; }
    }
  }

  // @notice: this is the 3/4 mint for the UX/UI team
  // @param ids: Array of LBL id's to mint off of
  // This will take ids, and lock them out of the mapping
  // so an id can not remint a LL. Cost will be .15 eth 
  // Can only mint one, locks out the mapping for threeToOne
  function publicMintThreeToOne(
    uint256[] memory ids
    ) 
    public 
    payable
    nonReentrant() {
    // locals
    address user = _msgSender();

    // errors
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (block.timestamp < timeOneStart) {
      revert ToEarly({
        time: block.timestamp
      , startTime: timeOneStart
      });
    }
    if (block.timestamp >= timeTwoStart) {
      revert ToLate({
        time: block.timestamp
      , endTime: timeTwoStart
      });
    }
    if (threeToOne[user]) {
      revert AlreadyMinted();
    }
    // checks & effects
    threeToOne[user] = true; // locks them out
    uint length = ids.length;
    uint quant = 0;
    for(uint x=0; x < length;) {
      if (LBLUsed[ids[x]]) {
        revert AlreadyClaimed({
          tokenID: ids[x]
        });
      }
      if (LBLNFT.ownerOf(ids[x]) == user){
        ++quant;
        LBLUsed[ids[x]] = true;
      }
      unchecked { ++x; }
    }
    if (quant == 0) {
      revert NullArray();
    }
    if (quant >= 3) {
      if (_msgValue() !=  MINT_FEE_TWO) {
        revert NotEnoughETH({
          required: MINT_FEE_TWO
        , sent: _msgValue()
        });
      }

      // minting
      if (1 + _tokenIdCounter.current() >= MINT_SIZE) {
        revert OverMaximumMint();
      }
      _safeMint(user, mintID());
      _tokenIdCounter.increment();
    }
  }

  // @notice: this is the whitelist mint funtion for UX/UI team
  // This will do the same checks, then set whitelist to false
  // then mint one LL for .15 eth.
  function whitelistMint()
    public
    payable
    nonReentrant() {
    // locals
    address user = _msgSender();

    // errors
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (block.timestamp < timeTwoStart) {
      revert ToEarly({
        time: block.timestamp
      , startTime: timeTwoStart
      });
    }
    if (block.timestamp >= timeThreeStart) {
      revert ToLate({
        time: block.timestamp
      , endTime: timeThreeStart
      });
    }
    // checks & effects
    bool check = _myWhitelistStatus(user);
    if (!check) {
      revert NotOnWhitelist();
    }
    removeWhitelist(user);
    if (_msgValue() != MINT_FEE_TWO) {
      revert NotEnoughETH({
        required: MINT_FEE_TWO
      , sent: _msgValue()
      });
    }

    // minting
    if (1 + _tokenIdCounter.current() >= MINT_SIZE) {
      revert OverMaximumMint();
    }
    _safeMint(user, mintID());
    _tokenIdCounter.increment();
  }

  // @notice: this is the 1/2 mint for the UX/UI team
  // @param ids: Array of LBL id's to mint off of
  // This will take ids, and lock them out of the mapping
  // so an id can not remint a LL. Cost will be .15 eth
  // Can only mint one, locks out the mapping for oneToOne
  function publicMintOneToOne(
    uint256 id
    )
    public
    payable
    nonReentrant() {
    // locals
    address user = _msgSender();

    // errors
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (block.timestamp < timeThreeStart) {
      revert ToEarly({
        time: block.timestamp
      , startTime: timeThreeStart
      });
    }
    if (block.timestamp >= timeThreeEnd) {
      revert ToLate({
        time: block.timestamp
      , endTime: timeThreeEnd
      });
    }
    if (oneToOne[user]) {
      revert AlreadyMinted();
    }
    if (_msgValue() != MINT_FEE_THREE) {
      revert NotEnoughETH({
        required: MINT_FEE_THREE
      , sent: _msgValue()
      });
    }
    if (LBLUsed[id]) {
      revert AlreadyClaimed({
        tokenID: id
      });
    }
    // checks & effects
    oneToOne[user] = true; // locks them out
    if (LBLNFT.ownerOf(id) == user){
      LBLUsed[id] = true;
    } // consumes id

    // minting
    if (1 + _tokenIdCounter.current() >= MINT_SIZE) {
      revert OverMaximumMint();
    }
    _safeMint(user, mintID());
    _tokenIdCounter.increment();
  }

  // @notice: this is the boss llama "airdrop" mint
  // @param ids: Array of address taken from snapshot
  // Will mint one token to each address in the array of 
  // addresses.
  function bossLlamaAirdrop(
    address [] memory addresses
    )
    public
    onlyOwner {
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (lockedAirdrop) {
      revert AirdropLocked();
    }
    uint length = addresses.length;
    if (length + _tokenIdCounter.current() >= MINT_SIZE) {
      revert OverMaximumMint();
    }
    for(uint x=0; x < length;) {
      _safeMint(addresses[x], mintID());
      _tokenIdCounter.increment();
      unchecked { ++x; }
    }
  }

  // @notice: this is the public mint funtion for UX/UI team
  // This will do the same checks then mint quant of LL for .2 eth.
  // @param quant: amount to be minted
  function publicMint(uint quant)
    public
    payable
    nonReentrant() {
    // locals
    address user = _msgSender();

    // errors
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (block.timestamp < timeThreeEnd) {
      revert ToEarly({
        time: block.timestamp
      , startTime: timeThreeEnd
      });
    }
    if (quant > 2) {
      revert CanNotMintThatMany({
        requested: quant
      , allowed: 2
      });
    }
    // checks & effects
    if (_msgValue() != quant * MINT_FEE_THREE) {
      revert NotEnoughETH({
        required: MINT_FEE_THREE * quant
      , sent: _msgValue()
      });
    }

    // minting
    if (quant + _tokenIdCounter.current() >= MINT_SIZE) {
      revert OverMaximumMint();
    }
    for(uint x=0; x < quant;) {
      _safeMint(user, mintID());
      _tokenIdCounter.increment();
      unchecked { ++x; }
    }
  }

  // @notice this shifts the _tokenIdCounter to proper mint number
  function mintID() internal view returns (uint) {
    return (mintStartID + _tokenIdCounter.current()) % MINT_SIZE;
  }

  // Function to receive ether, msg.data must be empty
  receive() external payable {
    // From PaymentSplitter.sol, 99% of the time won't register
    emit PaymentReceived(_msgSender(), _msgValue());
  }

  // Function to receive ether, msg.data is not empty
  fallback() external payable {
    // From PaymentSplitter.sol, 99% of the time won't register
    emit PaymentReceived(_msgSender(), _msgValue());
  }

  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

/***
 *     ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗ 
 *    ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗
 *    ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝
 *    ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗
 *    ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║
 *     ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
 * This section will have all the internals set to onlyOwner
 */

  // edit me...
  // @notice click this to start it up initally, for ease by onlyOwner
  // param timeOne: unix timestamp
  function startMinting(uint _start)
    public
    onlyOwner {
    timeOneStart = _start;
    timeTwoStart = _start + 1 days;
    timeThreeStart = _start + 2 days;
    timeThreeEnd = _start + 3 days;
    emit DayOneTimes(timeOneStart, timeTwoStart);
    emit DayTwoTimes(timeTwoStart, timeThreeStart);
    emit DayThreeTimes(timeThreeStart, timeThreeEnd);
  }

  // @notice external to the internal on WhitelistV2.sol
  // @param _addresses - array of addresses to add
  function addWhitelistBatch(
    address [] memory _addresses
    )
    public
    onlyOwner {
    _addBatchWhitelist(_addresses);
  }

  // @notice adding functions to mapping
  // @param _address - address to add
  function addWhitelist(
    address _address
    )
    public
    onlyOwner {
    _addWhitelist(_address);
  }

  // @notice removing functions to mapping
  // @param _addresses - array of addresses to remove
  function removeWhitelistBatch(
    address [] memory _addresses
    )
    public
    onlyOwner {
    _removeBatchWhitelist(_addresses);
  }

  // @notice removing functions to mapping
  // @param _address - address to remove
  function removeWhitelist(
    address _address
    )
    public
    onlyOwner {
    _removeWhitelist(_address);
  }

/***
 *    ██████╗ ███████╗██╗   ██╗
 *    ██╔══██╗██╔════╝██║   ██║
 *    ██║  ██║█████╗  ██║   ██║
 *    ██║  ██║██╔══╝  ╚██╗ ██╔╝
 *    ██████╔╝███████╗ ╚████╔╝ 
 *    ╚═════╝ ╚══════╝  ╚═══╝  
 * This section will have all the internals set to onlyDeveloper()
 * also contains all overrides required for funtionality
 */

  // @notice will add an address to PaymentSplitter by onlyDeveloper() role
  // @param newAddy: new address to add
  // @param newShares: amount of shares for newAddy
  function addPayee(
    address newAddy
  , uint newShares
    )
    public
    onlyDeveloper() {
    // error
    if(lockedPayees) {
      revert PayeesAlreadySet();
    }
    _addPayee(newAddy, newShares);
  }

  // @notice will lock payees on PaymentSplitter.sol
  function lockPayees()
    public
    onlyDeveloper() {
    // error
    if(lockedPayees) {
      revert PayeesAlreadySet();
    }
    lockedPayees = true;
    emit PayeesLocked(lockedPayees);
  }

  // @notice will set IERC721 for LBL
  // @param update: LBL CA
  function setLBLCA(
    address update
    )
    public
    onlyDeveloper() {
    LBLNFT = IERC721(update);
    emit LBLContractAddressUpdated(update);
  }

  // @notice will lock airdrop
  function lockAirdrop()
    public
    onlyDeveloper() {
    lockedAirdrop = true;
    emit AirdropIsLocked(lockedAirdrop);
  }

  // @notice will update _baseURI() by onlyDeveloper() role
  // @param _base: Base for NFT's
  function setBaseURI(
    string memory _base
    )
    public
    onlyDeveloper() {
    string memory old = base;
    base = _base;
    emit UpdatedBaseURI(old, base);
  }

  // @notice will update by onlyDeveloper() role
  // @param _base: Base for unrevealed NFT's
  function setUnrevealedBaseURI(
    string memory _base
    )
    public
    onlyDeveloper() {
    string memory old = base;
    unrevealedBase = _base;
    emit UpdatedUnrevealedBaseURI(old, unrevealedBase);
  }

  // @notice will reveal NFT's via tokenURI override
  function revealNFTs() public onlyDeveloper() {
    if (revealedNFT) {
      revert NFTsAlreadyRevealed();
    }
    revealedNFT = true;
    emit NFTReveal(revealedNFT, block.timestamp);
  }

  // @notice will set the ContractURI for OpenSea
  function setContractURI(string memory _contractURI) public onlyDeveloper() {
    _setContractURI(_contractURI);
  }

  // @notice this will set the Provenance Hashes
  // This will also set the starting order as well!
  // Only one shot to do this, otherwise it shows as invalid
  function setProvenance(string memory _images, string memory _json) public onlyDeveloper() {
    // errors
    if (!lockedPayees) {
      revert PayeesNotSet();
    }
    if (lockedProvenance) {
      revert ProvenanceAlreadySet();
    }
    // This is the initial setting
    _setProvenanceImages(_images);
    _setProvenanceJSON(_json);
    // Now to psuedo-random the starting number
    // Your API should be a random before this step!
    mintStartID = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), _images, _json, block.difficulty))) % MINT_SIZE;
    _setStartNumber(mintStartID);
    // @notice Locks sequence
    lockedProvenance = true;
    emit ProvenanceLocked(lockedProvenance);
  }

  ///
  /// Developer, these are the overrides
  ///

  // @notice solidity required override for _baseURI()
  function _baseURI() internal view override returns (string memory) {
    return base;
  }

  // @notice internal function for unrevealedBase
  function _unrevealedURI() internal view returns (string memory) {
    return unrevealedBase;
  }

  // @notice this is the toggle between revealed and non revealed NFT's
  function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
    if (ownerOf(tokenId) == address(0)) {
      revert NonMintedToken({
        token: tokenId
      });
    }
    if (!revealedNFT) {
      string memory baseURI = _unrevealedURI();
      return bytes(baseURI).length > 0 ? string(unrevealedBase) : "";
    } else {
      string memory baseURI = _baseURI();
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
  }

  // @notice solidity required override for supportsInterface(bytes4)
  // @param bytes4 interfaceId - bytes4 id per interface or contract
  //  calculated by ERC165 standards automatically
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return (
      interfaceId == type(ReentrancyGuard).interfaceId  ||
      interfaceId == type(WhitelistV2).interfaceId ||
      interfaceId == type(MaxAccess).interfaceId ||
      interfaceId == type(PaymentSplitterV2).interfaceId ||
      interfaceId == type(Llamas).interfaceId ||
      interfaceId == type(ContractURI).interfaceId ||
      super.supportsInterface(interfaceId)
    );
  }

  // @notice will return bool for isClaimed
  function isClaimed(uint _tokenId) external view returns (bool) {
    return LBLUsed[_tokenId];
  }

  // @notice will return epoch 1
  function epochOne() external view returns (uint, uint) {
    return (timeOneStart, timeTwoStart);
  }

 // @notice will return epoch 2
  function epochTwo() external view returns (uint, uint) {
    return (timeTwoStart, timeThreeStart);
  }

 // @notice will return epoch 3
  function epochThree() external view returns (uint, uint) {
    return (timeThreeStart, timeThreeEnd);
  }

  // @notice will return minting fees
  function minterFeesFivePlus() external view returns (uint) {
    return MINT_FEE_ONE;
  }

  // @notice will return minting fees
  function minterFeesThreePlusOrWL() external view returns (uint) {
    return MINT_FEE_TWO;
  }

  // @notice will return minting fees
  function minterFeesOnePlusDayThree() external view returns (uint) {
    return MINT_FEE_THREE;
  }

  // @notice will return maximum mint capacity
  function minterMaximumCapacity() external view returns (uint) {
    return MINT_SIZE;
  }

  // @notice will return current token count
  function totalSupply() external view returns (uint) {
    return _tokenIdCounter.current();
  }
}

/***
 *     ██████╗ ██████╗ ███╗   ██╗████████╗███████╗██╗  ██╗████████╗
 *    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔════╝╚██╗██╔╝╚══██╔══╝
 *    ██║     ██║   ██║██╔██╗ ██║   ██║   █████╗   ╚███╔╝    ██║   
 *    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══╝   ██╔██╗    ██║   
 *    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ███████╗██╔╝ ██╗   ██║   
 *     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝   ╚═╝   
 * This is a re-write of @openzeppelin/contracts/utils/Context.sol
 * Rewritten by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Upgraded with _msgValue() and _txOrigin() as ContextV2 on 31 Dec 2021
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
abstract contract ContextV2 {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint) {
        return msg.value;
    }

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }
}

/***
 *    ███████╗██████╗  ██████╗███████╗██████╗  ██╗
 *    ██╔════╝██╔══██╗██╔════╝╚════██║╚════██╗███║
 *    █████╗  ██████╔╝██║         ██╔╝ █████╔╝╚██║
 *    ██╔══╝  ██╔══██╗██║        ██╔╝ ██╔═══╝  ██║
 *    ███████╗██║  ██║╚██████╗   ██║  ███████╗ ██║
 *    ╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝  ╚══════╝ ╚═╝
 * This is a re-write of @openzeppelin/contracts/token/ERC721/ERC721.sol
 * Rewritten by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Updated to ContextV2, and removed ERC165 calculations on 31 Dec 2021
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../../utils/ContextV2.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is ContextV2, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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
}

/***
 *    ██╗    ██╗██╗  ██╗██╗████████╗███████╗
 *    ██║    ██║██║  ██║██║╚══██╔══╝██╔════╝
 *    ██║ █╗ ██║███████║██║   ██║   █████╗  
 *    ██║███╗██║██╔══██║██║   ██║   ██╔══╝  
 *    ╚███╔███╔╝██║  ██║██║   ██║   ███████╗
 *     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝
 *                                          
 *    ██╗     ██╗███████╗████████╗          
 *    ██║     ██║██╔════╝╚══██╔══╝          
 *    ██║     ██║███████╗   ██║             
 *    ██║     ██║╚════██║   ██║             
 *    ███████╗██║███████║   ██║             
 *    ╚══════╝╚═╝╚══════╝   ╚═╝             
 * @title Whitelist
 * @author @MaxFlowO2 (Twitter/GitHub)
 * @dev provides a use case of Library Whitelist use in v2.2
 *      Written on 22 Jan 2022, using LBL Tech!
 *
 * Can be used on all "Tokens" ERC-20, ERC-721, ERC-777, ERC-1155 or whatever
 * Solidity contract you can think of!
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../lib/Whitelist.sol";

abstract contract WhitelistV2 {
  using Whitelist for Whitelist.List;
  
  Whitelist.List private whitelist;

  function _addWhitelist(address newAddress) internal {
    whitelist.add(newAddress);
  }

  function _addBatchWhitelist(address[] memory newAddresses) internal {
    uint length = newAddresses.length;
    for(uint x = 0; x < length;) {
      whitelist.add(newAddresses[x]);
      unchecked { ++x; }
    }
  }

  function _removeWhitelist(address newAddress) internal {
    whitelist.remove(newAddress);
  }

  function _removeBatchWhitelist(address[] memory newAddresses) internal {
    uint length = newAddresses.length;
    for(uint x = 0; x < length;) {
      whitelist.remove(newAddresses[x]);
      unchecked { ++x; }
    }
  }

  function _enableWhitelist() internal {
    whitelist.enable();
  }

  function _disableWhitelist() internal {
    whitelist.disable();
  }

  // @notice rename this to whatever you want timestamp/quant of tokens sold
  // @dev will set the ending uint of whitelist
  // @param endNumber - uint for the end (quant or timestamp)
  function _setEndOfWhitelist(uint endNumber) internal {
    whitelist.setEnd(endNumber);
  }

  // @dev will return user status on whitelist
  // @return - bool if whitelist is enabled or not
  // @param myAddress - any user account address, EOA or contract
  function _myWhitelistStatus(address myAddress) internal view returns (bool) {
    return whitelist.onList(myAddress);
  }

  // @dev will return user status on whitelist
  // @return - bool if whitelist is enabled or not
  // @param myAddress - any user account address, EOA or contract
  function myWhitelistStatus(address myAddress) external view returns (bool) {
    return whitelist.onList(myAddress);
  }

  // @dev will return status of whitelist
  // @return - bool if whitelist is enabled or not
  function whitelistStatus() external view returns (bool) {
    return whitelist.status();
  }

  // @dev will return whitelist end (quantity or time)
  // @return - uint of either number of whitelist mints or
  //  a timestamp
  function whitelistEnd() external view returns (uint) {
    return whitelist.showEnd();
  }

  // @dev will return totat on whitelist
  // @return - uint from CountersV2.Count
  function TotalOnWhitelist() external view returns (uint) {
    return whitelist.totalAdded();
  }

  // @dev will return totat used on whitelist
  // @return - uint from CountersV2.Count
  function TotalWhiteListUsed() external view returns (uint) {
    return whitelist.totalRemoved();
  }

  // @dev will return totat used on whitelist
  // @return - uint aka xxxx = xx.xx%
  function WhitelistEfficiency() external view returns (uint) {
    if(whitelist.totalRemoved() == 0) {
      return 0;
    } else {
      return whitelist.totalRemoved() * 10000 / whitelist.totalAdded();
    }
  }
}

/***
 *    ██████╗  █████╗ ██╗   ██╗███╗   ███╗███████╗███╗   ██╗████████╗
 *    ██╔══██╗██╔══██╗╚██╗ ██╔╝████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
 *    ██████╔╝███████║ ╚████╔╝ ██╔████╔██║█████╗  ██╔██╗ ██║   ██║   
 *    ██╔═══╝ ██╔══██║  ╚██╔╝  ██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   
 *    ██║     ██║  ██║   ██║   ██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   
 *    ╚═╝     ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   
 *                                                                   
 *    ███████╗██████╗ ██╗     ██╗████████╗████████╗███████╗██████╗   
 *    ██╔════╝██╔══██╗██║     ██║╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗  
 *    ███████╗██████╔╝██║     ██║   ██║      ██║   █████╗  ██████╔╝  
 *    ╚════██║██╔═══╝ ██║     ██║   ██║      ██║   ██╔══╝  ██╔══██╗  
 *    ███████║██║     ███████╗██║   ██║      ██║   ███████╗██║  ██║  
 *    ╚══════╝╚═╝     ╚══════╝╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝  
 * This is a re-write of @openzeppelin/contracts/finance/PaymentSplitter.sol
 * Rewritten by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "../utils/ContextV2.sol";
// Removal of SafeMath due to ^0.8.0 standards, not needed

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */

abstract contract PaymentSplitterV2 is ContextV2 {

  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  uint256 private _totalShares;
  uint256 private _totalReleased;
  mapping(address => uint256) private _shares;
  mapping(address => uint256) private _released;
  address[] private _payees;

  /**
   * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
   * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
   * reliability of the events, and not the actual splitting of Ether.
   *
   * To learn more about this see the Solidity documentation for
   * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
   * functions].
   *
   *  receive() external payable virtual {
   *    emit PaymentReceived(_msgSender(), msg.value);
   *  }
   *
   *  // Fallback function is called when msg.data is not empty
   *  // Added to PaymentSplitter.sol
   *  fallback() external payable {
   *    emit PaymentReceived(_msgSender(), msg.value);
   *  }
   *
   * receive() and fallback() to be handled at final contract
   */

  /**
   * @dev Getter for the total shares held by payees.
   */
  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  /**
   * @dev Getter for the total amount of Ether already released.
   */
  function totalReleased() public view returns (uint256) {
    return _totalReleased;
  }

  /**
   * @dev Getter for the amount of shares held by an account.
   */
  function shares(address account) public view returns (uint256) {
    return _shares[account];
  }

  /**
   * @dev Getter for the amount of Ether already released to a payee.
   */
  function released(address account) public view returns (uint256) {
    return _released[account];
  }

  /**
   * @dev Getter for the address of the payee number `index`.
   */
  function payee(uint256 index) public view returns (address) {
    return _payees[index];
  }

  /**
   * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
   * total shares and their previous withdrawals.
   */
  // This function was updated from "account" to _msgSender()
  function claim() public virtual {
    address check = _msgSender();
    require(_shares[check] > 0, "PaymentSplitter: You have no shares");

    uint256 totalReceived = address(this).balance + _totalReleased;
    uint256 payment = (totalReceived * _shares[check]) / _totalShares - _released[check];

    require(payment != 0, "PaymentSplitter: You are not due payment");

    _released[check] = _released[check] + payment;
    _totalReleased = _totalReleased + payment;

    Address.sendValue(payable(check), payment);
    emit PaymentReleased(check, payment);
  }

  /**
   * @dev Add a new payee to the contract.
   * @param account The address of the payee to add.
   * @param shares_ The number of shares owned by the payee.
   */
  // This function was updated to internal
  function _addPayee(address account, uint256 shares_) internal {
    require(account != address(0), "PaymentSplitter: account is the zero address");
    require(shares_ > 0, "PaymentSplitter: shares are 0");
    require(_shares[account] == 0, "PaymentSplitter: account already has shares");

    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;

    emit PayeeAdded(account, shares_);
  }
}

/***
 *    ██╗     ██╗      █████╗ ███╗   ███╗ █████╗ ███████╗
 *    ██║     ██║     ██╔══██╗████╗ ████║██╔══██╗██╔════╝
 *    ██║     ██║     ███████║██╔████╔██║███████║███████╗
 *    ██║     ██║     ██╔══██║██║╚██╔╝██║██╔══██║╚════██║
 *    ███████╗███████╗██║  ██║██║ ╚═╝ ██║██║  ██║███████║
 *    ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝
 * Written by MaxFlowO2, Interim CEO and CTO of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Purpose: Insipired by BAYC on Ethereum, Sets Provenace Hashes and More
 * Source: https://etherscan.io/address/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d#code
 *
 * Updated: Does the Provenace Hashes for Iamges and JSONS.
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interface/ILlamas.sol";

abstract contract Llamas is Illamas {

  event SetProvenanceImages(string _new, string _old);
  event SetProvenanceJSON(string _new, string _old);
  event SetTimestamp(uint _new, uint _old);
  event SetStartNumber(uint _new, uint _old);

  uint256 private timestamp;
  uint256 private startNumber;
  string private ProvenanceImages;
  string private ProvenanceJSON;

  // @notice will set reveal timestamp
  function _setRevealTimestamp(uint256 _timestamp) internal {
    uint256 old = timestamp;
    timestamp = _timestamp;
    emit SetTimestamp(timestamp, old);
  }

  // @notice will set start number
  function _setStartNumber(uint256 _startNumber) internal {
    uint256 old = startNumber;
    startNumber = _startNumber;
    emit SetStartNumber(startNumber, old);
  }

  // @notice will set JSON Provenance
  function _setProvenanceJSON(string memory _ProvenanceJSON) internal {
    string memory old = ProvenanceJSON;
    ProvenanceJSON = _ProvenanceJSON;
    emit SetProvenanceJSON(ProvenanceJSON, old);
  }

  // @notice will set Images Provenance
  function _setProvenanceImages(string memory _ProvenanceImages) internal {
    string memory old = ProvenanceImages;
    ProvenanceImages = _ProvenanceImages;
    emit SetProvenanceImages(ProvenanceImages, old);
  }

  // @notice will return timestamp of reveal
  function RevealTimestamp() external view override(Illamas) returns (uint256) {
    return timestamp;
  }

  // @notice will return Provenance hash of images
  function RevealProvenanceImages() external view override(Illamas) returns (string memory) {
    return ProvenanceImages;
  }

  // @notice will return Provenance hash of metadata
  function RevealProvenanceJSON() external view override(Illamas) returns (string memory) {
    return ProvenanceJSON;
  }

  // @notice will return starting number for mint
  function RevealStartNumber() external view override(Illamas) returns (uint256) {
    return startNumber;
  }
}

/***
 *     ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  █████╗  ██████╗████████╗    ██╗   ██╗██████╗ ██╗
 *    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║
 *    ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝███████║██║        ██║       ██║   ██║██████╔╝██║
 *    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██╔══██║██║        ██║       ██║   ██║██╔══██╗██║
 *    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║  ██║╚██████╗   ██║       ╚██████╔╝██║  ██║██║
 *     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝        ╚═════╝ ╚═╝  ╚═╝╚═╝
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Purpose: OpenSea compliance on chain ID #1-5
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interface/IContractURI.sol";

abstract contract ContractURI is IContractURI {

  event ContractURIChange(string _new, string _old);

  string private thisContractURI;

  // @notice this sets the contractURI
  function _setContractURI(string memory newURI) internal {
    string memory old = thisContractURI;
    thisContractURI = newURI;
    emit ContractURIChange(thisContractURI, old);
  }

  // @notice will return string _ContractURI
  // contractURI() => 0xe8a3d485
  function contractURI() external view override(IContractURI) returns (string memory) {
    return thisContractURI;
  }

}

/***
 *    ██╗    ██╗██╗  ██╗██╗████████╗███████╗██╗     ██╗███████╗████████╗
 *    ██║    ██║██║  ██║██║╚══██╔══╝██╔════╝██║     ██║██╔════╝╚══██╔══╝
 *    ██║ █╗ ██║███████║██║   ██║   █████╗  ██║     ██║███████╗   ██║   
 *    ██║███╗██║██╔══██║██║   ██║   ██╔══╝  ██║     ██║╚════██║   ██║   
 *    ╚███╔███╔╝██║  ██║██║   ██║   ███████╗███████╗██║███████║   ██║   
 *     ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝╚══════╝╚═╝╚══════╝   ╚═╝   
 * @title Whitelist
 * @author @MaxFlowO2 on Twitter/GitHub
 *  Written on 12 Jan 2022, post Laid Back Llamas, aka LLAMA TECH!
 * @dev Provides a whitelist capability that can be added to and removed easily. With
 *  a modified version of Countes.sol from openzeppelin 4.4.1 you can track numbers of who's
 *  on the whitelist and who's been removed from the whitelist, showing clear statistics of
 *  your contract's whitelist usage.
 *
 * Include with 'using Whitelist for Whitelist.List;'
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./CountersV2.sol";

library Whitelist {
  using CountersV2 for CountersV2.Counter;

  event WhiteListEndChanged(uint _old, uint _new);
  event WhiteListChanged(bool _old, bool _new, address _address);
  event WhiteListStatus(bool _old, bool _new);

  struct List {
    // These variables should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    bool enabled; //default is false,
    CountersV2.Counter _added; // default 0, no need to _added.set(uint)
    CountersV2.Counter _removed; // default 0, no need to _removed.set(uint)
    uint end; // default 0, this can be time or quant
    mapping(address => bool) _list; // all values default to false
  }

  function add(List storage list, address _address) internal {
    require(!list._list[_address], "Whitelist: Address already whitelisted.");
    // since now all previous values are false no need for another variable
    // and add them to the list!
    list._list[_address] = true;
    // increment counter
    list._added.increment();
    // emit event
    emit WhiteListChanged(false, list._list[_address], _address);
  }

  function remove(List storage list, address _address) internal {
    require(list._list[_address], "Whitelist: Address already not whitelisted.");
    // since now all previous values are true no need for another variable
    // and remove them from the list!
    list._list[_address] = false;
    // increment counter
    list._removed.increment();
    // emit event
    emit WhiteListChanged(true, list._list[_address], _address);
  }

  function enable(List storage list) internal {
    require(!list.enabled, "Whitelist: Whitelist already enabled.");
    list.enabled = true;
    emit WhiteListStatus(false, list.enabled);
  }

  function disable(List storage list) internal {
    require(list.enabled, "Whitelist: Whitelist already enabled.");
    list.enabled = false;
    emit WhiteListStatus(true, list.enabled);
  }

  function setEnd(List storage list, uint newEnd) internal {
    require(list.end != newEnd, "Whitelist: End already set to that value.");
    uint old = list.end;
    list.end = newEnd;
    emit WhiteListEndChanged(old, list.end);
  }

  function status(List storage list) internal view returns (bool) {
    return list.enabled;
  }

  function totalAdded(List storage list) internal view returns (uint) {
    return list._added.current();
  }

  function totalRemoved(List storage list) internal view returns (uint) {
    return list._removed.current();
  }

  function onList(List storage list, address _address) internal view returns (bool) {
    return list._list[_address];
  }

  function showEnd(List storage list) internal view returns (uint) {
    return list.end;
  }
}

/***
 *     ██████╗ ██████╗ ██╗   ██╗███╗   ██╗████████╗███████╗██████╗ ███████╗
 *    ██╔════╝██╔═══██╗██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗██╔════╝
 *    ██║     ██║   ██║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝███████╗
 *    ██║     ██║   ██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗╚════██║
 *    ╚██████╗╚██████╔╝╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║███████║
 *     ╚═════╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝
 * @title CountersV2
 * @author Matt Condon (@shrugs), and @MaxFlowO2 (edits)
 * @dev Provides counters that can only be incremented, decremented, reset or set. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Edited by @MaxFlowO2 for more NFT functionality on 13 Jan 2022
 * added .set(uint) so if projects need to start at say 1 or some random number they can
 * and an event log for numbers being reset or set.
 *
 * Include with `using CountersV2 for CountersV2.Counter;`
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library CountersV2 {

  error NegativeNumber();

  event CounterNumberChangedTo(uint _number);

  struct Counter {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    unchecked {
      counter._value += 1;
    }
  }

  function decrement(Counter storage counter) internal {
    uint256 value = counter._value;
    if (value == 0) {
      revert NegativeNumber();
    }
    unchecked {
      counter._value = value - 1;
    }
  }

  function reset(Counter storage counter) internal {
    counter._value = 0;
    emit CounterNumberChangedTo(counter._value);
  }

  function set(Counter storage counter, uint number) internal {
    counter._value = number;
    emit CounterNumberChangedTo(counter._value);
  }  
}

/***
 *     █████╗  ██████╗ ██████╗███████╗███████╗███████╗
 *    ██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝
 *    ███████║██║     ██║     █████╗  ███████╗███████╗
 *    ██╔══██║██║     ██║     ██╔══╝  ╚════██║╚════██║
 *    ██║  ██║╚██████╗╚██████╗███████╗███████║███████║
 *    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝
 * @title Access
 * @author @MaxFlowO2
 * @dev Library function for EIP 173 Ownable standards in EVM, this is useful
 *  for granting role based modifiers, and by using this blah blah blah.
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Access {

  event AccessTransferred(address indexed newAddress, address indexed oldAddress);

  struct Role {
    // This variable should never be directly accessed by users of the library: interactions must be restricted to
    // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
    // this feature: see https://github.com/ethereum/solidity/issues/4637
    address _active; // who's the active role
    address _pending; // who's the pending role
    address[] _historical; // array of addresses with the role (useful for "reclaiming" roles)
  }

  function active(Role storage role) internal view returns (address) {
    return role._active;
  }

  function pending(Role storage role) internal view returns (address) {
    return role._pending;
  }

  function historical(Role storage role) internal view returns (address[] storage) {
    return role._historical;
  }

  function transfer(Role storage role, address newAddress) internal {
    role._pending = newAddress;
  }

  function modifyArray(Role storage role) internal {
    role._historical.push(role._active);
  }

  function accept(Role storage role) internal {
    address oldAddy = role._active;
    role._active = role._pending;
    role._pending = address(0);
    emit AccessTransferred(
      role._active
    , oldAddy
    );
  }

  function decline(Role storage role) internal {
    role._pending = address(0);
  }

  function push(Role storage role, address newAddress) internal {
    address oldAddy = role._active;
    role._active = newAddress;
    role._pending = address(0);
    emit AccessTransferred(
      role._active
    , oldAddy
    );
  }
}

/***
 *    ██╗██╗     ██╗      █████╗ ███╗   ███╗ █████╗ ███████╗
 *    ██║██║     ██║     ██╔══██╗████╗ ████║██╔══██╗██╔════╝
 *    ██║██║     ██║     ███████║██╔████╔██║███████║███████╗
 *    ██║██║     ██║     ██╔══██║██║╚██╔╝██║██╔══██║╚════██║
 *    ██║███████╗███████╗██║  ██║██║ ╚═╝ ██║██║  ██║███████║
 *    ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝
 * Written by MaxFlowO2, Interim CEO and CTO of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Purpose: Insipired by BAYC on Ethereum, Sets Provential Hashes and More
 * Source: https://etherscan.io/address/0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d#code
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface Illamas is IERC165{

  // @notice will return timestamp of reveal
  // RevealTimestamp() => 0x83ba7c1d
  function RevealTimestamp() external view returns (uint256);

  // @notice will return Provenance hash of images
  // RevealProvenanceImages() => 0xd792d2a0
  function RevealProvenanceImages() external view returns (string memory);

  // @notice will return Provenance hash of metadata
  // RevealProvenanceJSON() => 0x94352676
  function RevealProvenanceJSON() external view returns (string memory);

  // @notice will return starting number for mint
  // RevealStartNumber() => 0x1efb051a
  function RevealStartNumber() external view returns (uint256);
}

/***
 *    ██╗ ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  █████╗  ██████╗████████╗    ██╗   ██╗██████╗ ██╗
 *    ██║██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝    ██║   ██║██╔══██╗██║
 *    ██║██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝███████║██║        ██║       ██║   ██║██████╔╝██║
 *    ██║██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██╔══██║██║        ██║       ██║   ██║██╔══██╗██║
 *    ██║╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║██║  ██║╚██████╗   ██║       ╚██████╔╝██║  ██║██║
 *    ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝   ╚═╝        ╚═════╝ ╚═╝  ╚═╝╚═╝
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 *
 * Purpose: OpenSea compliance on chain ID #1-5
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IContractURI is IERC165{

  // @notice this is the contractURI() for OpeanSea compliance
  // contractURI() => 0xe8a3d485
  function contractURI() external view returns (string memory);
}

/***
 *    ███████╗██╗██████╗       ██████╗  █████╗  █████╗  ██╗
 *    ██╔════╝██║██╔══██╗      ╚════██╗██╔══██╗██╔══██╗███║
 *    █████╗  ██║██████╔╝█████╗ █████╔╝╚██████║╚█████╔╝╚██║
 *    ██╔══╝  ██║██╔═══╝ ╚════╝██╔═══╝  ╚═══██║██╔══██╗ ██║
 *    ███████╗██║██║           ███████╗ █████╔╝╚█████╔╝ ██║
 *    ╚══════╝╚═╝╚═╝           ╚══════╝ ╚════╝  ╚════╝  ╚═╝                                                        
 * Zach Burks, James Morgan, Blaine Malone, James Seibel,
 * "EIP-2981: NFT Royalty Standard,"
 * Ethereum Improvement Proposals, no. 2981, September 2020. [Online serial].
 * Available: https://eips.ethereum.org/EIPS/eip-2981.
 *
 * Minor edit on comments to mirror the rest of the interfaces
 * by @MaxFlowO2 on 29 Dec 2021 for v2.1
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///

interface IERC2981 is IERC165 {

  // ERC165
  // royaltyInfo(uint256,uint256) => 0x2a55205a
  // IERC2981 => 0x2a55205a

  // @notice Called with the sale price to determine how much royalty
  //  is owed and to whom.
  // @param _tokenId - the NFT asset queried for royalty information
  // @param _salePrice - the sale price of the NFT asset specified by _tokenId
  // @return receiver - address of who should be sent the royalty payment
  // @return royaltyAmount - the royalty payment amount for _salePrice
  // ERC165 datum royaltyInfo(uint256,uint256) => 0x2a55205a
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);

}

/***
 *    ███████╗██████╗  ██████╗██████╗  █████╗  █████╗  ██╗                            
 *    ██╔════╝██╔══██╗██╔════╝╚════██╗██╔══██╗██╔══██╗███║                            
 *    █████╗  ██████╔╝██║      █████╔╝╚██████║╚█████╔╝╚██║                            
 *    ██╔══╝  ██╔══██╗██║     ██╔═══╝  ╚═══██║██╔══██╗ ██║                            
 *    ███████╗██║  ██║╚██████╗███████╗ █████╔╝╚█████╔╝ ██║                            
 *    ╚══════╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚════╝  ╚════╝  ╚═╝                            
 *                                                                                    
 *     ██████╗ ██████╗ ██╗     ██╗     ███████╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗
 *    ██╔════╝██╔═══██╗██║     ██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║
 *    ██║     ██║   ██║██║     ██║     █████╗  ██║        ██║   ██║██║   ██║██╔██╗ ██║
 *    ██║     ██║   ██║██║     ██║     ██╔══╝  ██║        ██║   ██║██║   ██║██║╚██╗██║
 *    ╚██████╗╚██████╔╝███████╗███████╗███████╗╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║
 *     ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
 * Written by MaxFlowO2, Senior Developer and Partner of G&M² Labs
 * Follow me on https://github.com/MaxflowO2 or Twitter @MaxFlowO2
 * email: [email protected]
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC2981.sol";

abstract contract ERC2981Collection is IERC2981 {

  // ERC165
  // royaltyInfo(uint256,uint256) => 0x2a55205a
  // ERC2981Collection => 0x2a55205a

  address private royaltyAddress;
  uint256 private royaltyPercent;

  // Set to be internal function _setRoyalties
  function _setRoyalties(address _receiver, uint256 _percentage) internal {
    royaltyAddress = _receiver;
    royaltyPercent = _percentage;
  }

  // Override for royaltyInfo(uint256, uint256)
  // royaltyInfo(uint256,uint256) => 0x2a55205a
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external view override(IERC2981) returns (
    address receiver,
    uint256 royaltyAmount
  ) {
    receiver = royaltyAddress;

    // This sets permille by price * percentage / 1000
    royaltyAmount = _salePrice * royaltyPercent / 1000;
  }
}

/***
 *    ███╗   ███╗ █████╗ ██╗  ██╗███████╗██╗      ██████╗ ██╗    ██╗
 *    ████╗ ████║██╔══██╗╚██╗██╔╝██╔════╝██║     ██╔═══██╗██║    ██║
 *    ██╔████╔██║███████║ ╚███╔╝ █████╗  ██║     ██║   ██║██║ █╗ ██║
 *    ██║╚██╔╝██║██╔══██║ ██╔██╗ ██╔══╝  ██║     ██║   ██║██║███╗██║
 *    ██║ ╚═╝ ██║██║  ██║██╔╝ ██╗██║     ███████╗╚██████╔╝╚███╔███╔╝
 *    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝ 
 *                                                                  
 *     █████╗  ██████╗ ██████╗███████╗███████╗███████╗              
 *    ██╔══██╗██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝              
 *    ███████║██║     ██║     █████╗  ███████╗███████╗              
 *    ██╔══██║██║     ██║     ██╔══╝  ╚════██║╚════██║              
 *    ██║  ██║╚██████╗╚██████╗███████╗███████║███████║              
 *    ╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝              
 *                                                                  
 *     ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  ██████╗ ██╗      
 *    ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██║      
 *    ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██║      
 *    ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║      
 *    ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████╗ 
 *     ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝ 
 * @title MaxFlowO2 Access Control
 * @author @MaxFlowO2 on twitter/github
 * @dev this is an EIP 173 compliant ownable plus access control mechanism where you can 
 * copy/paste what access role(s) you need or want. This is due to Library Access, and 
 * using this line of 'using Role for Access.Role' after importing my library
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../lib/Access.sol";
import "../utils/ContextV2.sol";

abstract contract MaxAccess is ContextV2 {
  using Access for Access.Role;

  // events

  // Roles  
  Access.Role private _owner;
  Access.Role private _developer;

  // Constructor to init()
  constructor() {
    _owner.push(_msgSender());
    _developer.push(_msgSender());
  }

  // Modifiers
  modifier onlyOwner() {
    require(_owner.active() == _msgSender(), "EIP173: You are not Owner!");
    _;
  }

  modifier onlyNewOwner() {
    require(_owner.pending() == _msgSender(), "EIP173: You are not the Pending Owner!");
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner.active();
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "EIP173: Transfer can not be address(0)");
    _owner.transfer(newOwner);
  }

  function acceptOwnership() public virtual onlyNewOwner {
    _owner.accept();
  }

  function declineOwnership() public virtual onlyNewOwner {
    _owner.decline();
  }

  function pushOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "EIP173: Transfer can not be address(0)");
    _owner.push(newOwner);
  }

  function renounceOwnership() public virtual onlyOwner {
    _owner.push(address(0));
  }

  // Modifiers
  modifier onlyDeveloper() {
    require(_developer.active() == _msgSender(), "EIP173: You are not Developer!");
    _;
  }

  modifier onlyNewDeveloper() {
    require(_developer.pending() == _msgSender(), "EIP173: You are not the Pending Developer!");
    _;
  }

  function developer() public view virtual returns (address) {
    return _developer.active();
  }

  function transferDeveloper(address newDeveloper) public virtual onlyDeveloper {
    require(newDeveloper != address(0), "EIP173: Transfer can not be address(0)");
    _developer.transfer(newDeveloper);
  }

  function acceptDeveloper() public virtual onlyNewDeveloper {
    _developer.accept();
  }

  function declineDeveloper() public virtual onlyNewDeveloper {
    _developer.decline();
  }

  function pushDeveloper(address newDeveloper) public virtual onlyDeveloper {
    require(newDeveloper != address(0), "EIP173: Transfer can not be address(0)");
    _developer.push(newDeveloper);
  }

  function renounceDeveloper() public virtual onlyDeveloper {
    _developer.push(address(0));
  }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}