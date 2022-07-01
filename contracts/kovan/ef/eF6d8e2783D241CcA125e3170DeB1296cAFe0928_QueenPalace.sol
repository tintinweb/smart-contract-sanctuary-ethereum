// SPDX-License-Identifier: MIT

/// @title Contract that handles all of Queen's Staff

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC165Storage} from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import {RoyalLibrary} from "./lib/RoyalLibrary.sol";
import {IQueenPalace} from "../interfaces/IQueenPalace.sol";
import {IQueenLab} from "../interfaces/IQueenLab.sol";
import {IQueenTraits} from "../interfaces/IQueenTraits.sol";
import {IQueenE} from "../interfaces/IQueenE.sol";
import {IQueenAuctionHouse} from "../interfaces/IQueenAuctionHouse.sol";
import {IBaseContractController} from "../interfaces/IBaseContractController.sol";
import {IRoyalTower} from "../interfaces/IRoyalTower.sol";
import {QueenAuctionHouseProxy} from "./proxy/QueenAuctionHouseProxy.sol";
import {QueenAuctionHouseProxyAdmin} from "./proxy/QueenAuctionHouseProxyAdmin.sol";

contract QueenPalace is
  IQueenPalace,
  Pausable,
  ReentrancyGuard,
  Ownable,
  ERC165Storage
{
  using EnumerableSet for EnumerableSet.AddressSet;

  event ArtistSet(address indexed artistAddress);
  event ArtistAllowed(address indexed artistAddress);
  event ArtistDisallowed(address indexed artistAddress);
  event DeveloperAllowed(address indexed artistAddress);
  event DeveloperDisallowed(address indexed artistAddress);
  event DeveloperSet(address indexed developerAddress);
  event DAOSet(address indexed addressDAO);
  event DAOExecutorSet(address indexed addressDAOExecutor);
  event LabSet(IQueenLab queenLab);
  event StorageSet(IQueenTraits queenStorage);
  event QueenESet(IQueenE _queenE);
  event RoyalTowerSet(address indexed _royalTower);
  event AuctionHouseProxySet(QueenAuctionHouseProxy queenAuctionHouseProxy);
  event ImplementationEnded(address indexed _address);
  event MinterUpdate(address indexed _address);

  event WhiteList(address addr);
  event ClearedWhiteList(address sender);

  address public _minter;
  address public override royalMuseum;
  address payable internal _artist;
  address payable internal _developer;
  address payable internal queeneDAO;
  address payable internal queeneDAOExecutor;
  address internal _royalTower;
  EnumerableSet.AddressSet internal _allowedArtists;
  EnumerableSet.AddressSet internal _allowedDevelopers;
  EnumerableSet.AddressSet internal whiteList;

  uint256 public override whiteListed;

  IQueenTraits internal queenStorage;
  IQueenLab internal queenLab;
  IQueenE internal queenE;
  QueenAuctionHouseProxyAdmin internal royalAuctionHouseProxyAdmin;
  QueenAuctionHouseProxy internal royalAuctionHouseProxy;

  bool internal onImplementation;

  constructor(
    address _artistAddress,
    address _developerAddress,
    address _royalMuseum
  ) {
    onImplementation = true;
    _artist = payable(_artistAddress);
    _developer = payable(_developerAddress);
    royalMuseum = _royalMuseum;

    _registerInterface(type(IQueenPalace).interfaceId);
  }

  /**
   *IN
   *OUT
   */
  function implementationEnded() external onlyOwner {
    onImplementation = false;

    emit ImplementationEnded(msg.sender);
  }

  /**
   *IN
   *OUT
   *status: current implementation status
   */
  function isOnImplementation() public view override returns (bool) {
    return onImplementation;
  }

  /**
   * @notice Require that message sender is either owner or artist chief.
   */
  modifier onlyOwnerOrChiefArtist() {
    isOwnerOrChiefArtist();
    _;
  }
  /**
   * @notice Require that message sender is either owner or artist/allowed.
   */
  modifier onlyOwnerOrArtist() {
    isOwnerOrArtist();

    _;
  }

  /**
   * @notice Require that message sender is either owner or developer/allowed.
   */
  modifier onlyOwnerOrDeveloper() {
    isOwnerOrDeveloper();

    _;
  }

  /**
   * @notice Require that message sender is either owner or developer/allowed or DAO Executor.
   */
  modifier onlyOwnerOrDeveloperOrDAO() {
    isOwnerOrDeveloperOrDAO();

    _;
  }

  /**
   * @notice Require that message sender is either owner or chief developer.
   */
  modifier onlyOwnerOrChiefDeveloper() {
    isOwnerOrChiefDeveloper();

    _;
  }

  /**
   * @notice Require that message sender is either owner or DAO contract.
   */
  modifier onlyOwnerOrDAO() {
    isOwnerOrDAO();

    _;
  }

  /**
   * @notice Require that message sender is either owner or DAO contract.
   */
  modifier onlyOwnerOrAuctionHouse() {
    isOwnerOrAuctionHouseProxy();

    _;
  }

  /**
   * @notice Require that message sender is either DAO or Contract On Implementation.
   */
  modifier onlyOnImplementationOrDAO() {
    isOnImplementationOrDAO();

    _;
  }

  function isOnImplementationOrDAO() internal view {
    require(
      isOnImplementation() || msg.sender == queeneDAOExecutor,
      "Not Implementation, DAO"
    );
  }

  function isOwnerOrAuctionHouseProxy() internal view {
    require(
      msg.sender == owner() || msg.sender == address(royalAuctionHouseProxy),
      "Not Owner, Auction House"
    );
  }

  function isOwnerOrDAO() internal view {
    require(
      msg.sender == owner() || msg.sender == queeneDAOExecutor,
      "Not Owner, DAO"
    );
  }

  function isOwnerOrChiefDeveloper() internal view {
    require(
      msg.sender == owner() || msg.sender == _developer,
      "Not Owner, Chief Developer"
    );
  }

  function isOwnerOrDeveloper() internal view {
    require(
      msg.sender == owner() || isDeveloper(msg.sender),
      "Not Owner, Developer"
    );
  }

  function isOwnerOrChiefArtist() internal view {
    require(
      msg.sender == owner() || msg.sender == _artist,
      "Not Owner, Chief Artist"
    );
  }

  function isOwnerOrArtist() internal view {
    require(msg.sender == owner() || isArtist(msg.sender), "Not Owner, Artist");
  }

  function isOwnerOrDeveloperOrDAO() internal view {
    require(
      msg.sender == owner() ||
        isDeveloper(msg.sender) ||
        msg.sender == queeneDAOExecutor,
      "Not Owner, Developer, DAO"
    );
  }

  /************************** vARTIST REGION ******************************************************** */

  /**
   *IN
   *OUT
   *currentArtit: current artist address allowed on contract
   */
  function artist() external view override returns (address) {
    return _artist;
  }

  /**
   *IN
   *OUT
   *bool: if address is artist chief or allowed artist
   */
  function isArtist(address addr) public view override returns (bool) {
    return _artist == addr || _allowedArtists.contains(addr);
  }

  /**
   *IN
   *_newArtist: address of artist tha will upload arts to contract
   *OUT
   */
  function setArtist(address _newArtist)
    external
    nonReentrant
    whenNotPaused
    onlyOwnerOrArtist
    returns (address newArtist)
  {
    require(
      _newArtist != RoyalLibrary.burnAddress,
      "Invalid artist address! Burn address!"
    );

    require(!Address.isContract(_newArtist), "Must be a wallet address!");

    _artist = payable(_newArtist);

    emit ArtistSet(_newArtist);

    return _artist;
  }

  /**
   *IN
   *_newArtist: address of artists allowed to upload arts to contract
   *OUT
   */
  function allowArtist(address _allowedArtist)
    external
    whenNotPaused
    onlyOwnerOrChiefArtist
    returns (address newArtist)
  {
    require(
      _allowedArtist != RoyalLibrary.burnAddress,
      "Invalid artist address! Burn address!"
    );

    require(!Address.isContract(_allowedArtist), "Must be a wallet address!");
    require(
      !_allowedArtists.contains(_allowedArtist),
      "Wallet already allowed!"
    );

    _allowedArtists.add(payable(_allowedArtist));

    emit ArtistAllowed(_allowedArtist);

    return _allowedArtist;
  }

  /**
   *IN
   *_newArtist: address of artists allowed to upload arts to contract
   *OUT
   */
  function disallowArtist(address _disallowedArtist)
    external
    whenNotPaused
    onlyOwnerOrChiefArtist
    returns (address newArtist)
  {
    require(
      _disallowedArtist != RoyalLibrary.burnAddress,
      "Invalid artist address! Burn address!"
    );

    require(
      !Address.isContract(_disallowedArtist),
      "Must be a wallet address!"
    );
    require(
      _allowedArtists.contains(_disallowedArtist),
      "Wallet not allowed allowed!"
    );

    _allowedArtists.remove(payable(_disallowedArtist));

    emit ArtistDisallowed(_disallowedArtist);

    return _disallowedArtist;
  }

  /************************** ^ARTIST REGION ******************************************************** */
  /************************** vDEV REGION *********************************************************** */

  /**
   *IN
   *OUT
   *currentDev: current dev address allowed on contract
   */
  function developer() external view override returns (address) {
    return _developer;
  }

  /**
   *IN
   *OUT
   *bool: if address is developer chief or allowed developer
   */
  function isDeveloper(address devAddr) public view override returns (bool) {
    return _developer == devAddr || _allowedDevelopers.contains(devAddr);
  }

  /**
     *IN
     *_developer: address of developer team responsable for contract updates propositions
     and implementation end
     *OUT
     */
  function setDeveloper(address _dev)
    external
    whenNotPaused
    onlyOwnerOrChiefDeveloper
    returns (address newDeveloper)
  {
    require(
      _dev != RoyalLibrary.burnAddress,
      "Invalid dev address! Burn address!"
    );

    require(!Address.isContract(_dev), "Must be a wallet address!");

    _developer = payable(_dev);

    emit DeveloperSet(_developer);

    return _developer;
  }

  /**
   *IN
   *_allowedDeveloper: address of developer allowed to interact with contract
   *OUT
   */
  function allowDeveloper(address _allowedDeveloper)
    external
    nonReentrant
    whenNotPaused
    onlyOwnerOrChiefDeveloper
    returns (address allowedDeveloper)
  {
    return _allowDeveloper(_allowedDeveloper);
  }

  /**
   *IN
   *_allowedDeveloper: address of artists allowed to upload arts to contract
   *OUT
   */
  function _allowDeveloper(address _allowedDeveloper)
    private
    returns (address)
  {
    require(
      _allowedDeveloper != RoyalLibrary.burnAddress,
      "Invalid developer address! Burn address!"
    );

    require(
      !Address.isContract(_allowedDeveloper),
      "Must be a wallet address!"
    );
    require(
      !_allowedDevelopers.contains(_allowedDeveloper),
      "Wallet already allowed!"
    );

    _allowedDevelopers.add(payable(_allowedDeveloper));

    emit DeveloperAllowed(_allowedDeveloper);

    return _allowedDeveloper;
  }

  /**
   *IN
   *_newArtist: address of artists allowed to upload arts to contract
   *OUT
   */
  function disallowDeveloper(address _disallowedDeveloper)
    external
    nonReentrant
    whenNotPaused
    onlyOwnerOrChiefDeveloper
    returns (address disallowedDeveloper)
  {
    return _disallowDeveloper(_disallowedDeveloper);
  }

  /**
   *IN
   *_newArtist: address of artists allowed to upload arts to contract
   *OUT
   */
  function _disallowDeveloper(address _disallowedDeveloper)
    private
    returns (address)
  {
    require(
      _disallowedDeveloper != RoyalLibrary.burnAddress,
      "Invalid developer address! Burn address!"
    );

    require(
      !Address.isContract(_disallowedDeveloper),
      "Must be a wallet address!"
    );
    require(
      _allowedDevelopers.contains(_disallowedDeveloper),
      "Wallet not allowed allowed!"
    );

    _allowedDevelopers.remove(payable(_disallowedDeveloper));

    emit DeveloperDisallowed(_disallowedDeveloper);

    return _disallowedDeveloper;
  }

  /************************** ^DEV REGION *********************************************************** */

  /************************** vDAO REGION *********************************************************** */

  /**
   *IN
   *_addressDAO: address of DAO contract
   *OUT
   */
  function setDAO(address payable _addressDAO)
    external
    whenNotPaused
    onlyOwnerOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _addressDAO != RoyalLibrary.burnAddress,
      "Invalid DAO address! Burn address!"
    );

    require(Address.isContract(_addressDAO), "Invalid DAO Contract!");

    queeneDAO = _addressDAO;

    emit DAOSet(_addressDAO);
  }

  /**
   *IN
   *OUT
   *currentDAO: current DAO contract address
   */
  function dao() external view override returns (address) {
    return queeneDAO;
  }

  /**
   *IN
   *_addressDAO: address of Royal Executor contract
   *OUT
   */
  function setDAOExecutor(address payable _addressDAOExecutor)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _addressDAOExecutor != RoyalLibrary.burnAddress,
      "Invalid Royal Executor!"
    );

    require(
      Address.isContract(_addressDAOExecutor),
      "Invalid Executor Contract!"
    );

    queeneDAOExecutor = _addressDAOExecutor;

    emit DAOExecutorSet(_addressDAOExecutor);
  }

  /**
   *IN
   *OUT
   *currentDAO: current DAO contract address
   */
  function daoExecutor() external view override returns (address) {
    return queeneDAOExecutor;
  }

  /************************** ^DAO REGION *********************************************************** */

  /************************** vROYAL TOWER REGION *************************************************** */

  /**
   *IN
   *_addressRoyalTower: address of Royal Tower contract
   *OUT
   */
  function setRoyalTower(address payable _addressRoyalTower)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _addressRoyalTower != RoyalLibrary.burnAddress,
      "Invalid Royal Tower address! Burn address!"
    );
    require(
      Address.isContract(_addressRoyalTower),
      "Invalid Royal Tower Contract!"
    );
    require(
      IRoyalTower(_addressRoyalTower).supportsInterface(
        type(IRoyalTower).interfaceId
      ),
      "Dont implement IRoyalTower interface!"
    );

    _royalTower = _addressRoyalTower;

    emit RoyalTowerSet(_royalTower);
  }

  /**
   *IN
   *OUT
   *currentRoyalTower: current Royal Tower contract address
   */
  function RoyalTowerAddr() external view override returns (address) {
    return _royalTower;
  }

  /************************** ^ROYAL TOWER REGION *************************************************** */

  /************************** vMINTER REGION ******************************************************** */

  /**
   * @notice Set the token minter.
   * @dev Only callable by the owner when not locked.
   */
  function setMinter(address _minterAddress)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    _minter = _minterAddress;

    emit MinterUpdate(_minterAddress);
  }

  /**
   *IN
   *OUT
   *currentDAO: current DAO contract address
   */
  function minter() external view override returns (address) {
    return _minter;
  }

  /************************** ^MINTER REGION ******************************************************** */

  /************************** vQUEENLAB REGION *********************************************************** */

  /**
   *IN
   *OUT
   *returns: current lab Contract
   */
  function QueenLab() external view override returns (IQueenLab) {
    return queenLab;
  }

  /**
   *IN
   *_labContract: queens lab contract
   *OUT
   */
  function setQueenLab(IQueenLab _labContract)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _labContract.supportsInterface(type(IQueenLab).interfaceId),
      "Dont implement IQueenLab interface!"
    );

    queenLab = _labContract;

    emit LabSet(_labContract);
  }

  /************************** ^QUEENLAB REGION *********************************************************** */

  /************************** vQUEENTRAITS REGION *********************************************************** */

  /**
   *IN
   *OUT
   *returns: current queens trait storage Contract
   */
  function QueenTraits() external view override returns (IQueenTraits) {
    return queenStorage;
  }

  /**
   *IN
   *_storageAddress: address of queens trait storage contract
   *OUT
   */
  function setQueenStorage(IQueenTraits _storageContract)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _storageContract.supportsInterface(type(IQueenTraits).interfaceId),
      "Dont implement correct interface!"
    );

    queenStorage = _storageContract;

    emit StorageSet(_storageContract);
  }

  /************************** ^QUEENTRAITS REGION *********************************************************** */

  /************************** vROYALAUCTIONHOUSE REGION ***************************************************** */

  /**
   *IN
   *OUT
   *returns: current queens auction house Contract through proxy
   */
  function QueenAuctionHouse()
    public
    view
    override
    returns (IQueenAuctionHouse)
  {
    return
      IQueenAuctionHouse(
        royalAuctionHouseProxyAdmin.getProxyImplementation(
          royalAuctionHouseProxy
        )
      );
  }

  /**
   *IN
   *OUT
   *returns: current queens auction house proxy address
   */
  function QueenAuctionHouseProxyAddr() public view override returns (address) {
    return address(royalAuctionHouseProxy);
  }

  /**
   *IN
   *_auctionHouseContract: queens auction house contract
   *OUT
   */
  function setQueenAuctionHouseProxy(
    QueenAuctionHouseProxy _auctionHouseContractProxy,
    QueenAuctionHouseProxyAdmin _auctionHouseContractProxyAdmin
  ) external whenNotPaused onlyOwnerOrDeveloperOrDAO onlyOnImplementationOrDAO {
    royalAuctionHouseProxy = _auctionHouseContractProxy;
    royalAuctionHouseProxyAdmin = _auctionHouseContractProxyAdmin;

    emit AuctionHouseProxySet(_auctionHouseContractProxy);
  }

  /************************** ^ROYALAUCTIONHOUSE REGION ***************************************************** */

  /************************** vQUEENE REGION **************************************************************** */

  /**
   *IN
   *OUT
   *returns: current queene Contract
   */
  function QueenE() external view override returns (IQueenE) {
    return queenE;
  }

  /**
   *IN
   *_queenE: queene contract
   *OUT
   */
  function setQueenE(IQueenE _queenE)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(
      _queenE.supportsInterface(type(IQueenE).interfaceId),
      "QueenE Dont implement correct interface!"
    );

    queenE = _queenE;

    emit QueenESet(_queenE);
  }

  /************************** ^QUEENE REGION **************************************************************** */

  /************************** vWHITELIST REGION ************************************************************* */

  /**
   * @notice WHITELIST ADDRESS.
   */
  function whiteListAddress(address[] calldata _whiteListed)
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    require(_whiteListed.length > 0, "Empty List");
    //add address to whitelist
    for (uint256 idx = 0; idx < _whiteListed.length; idx++) {
      if (!whiteList.contains(_whiteListed[idx])) {
        whiteList.add(_whiteListed[idx]);
        whiteListed++;
        emit WhiteList(_whiteListed[idx]);
      }
    }
  }

  /**
   * @notice Clear whitelist address.
   */
  function clearWhiteList()
    external
    whenNotPaused
    onlyOwnerOrDeveloperOrDAO
    onlyOnImplementationOrDAO
  {
    //add address to whitelist
    for (uint256 idx = 0; idx < whiteList.length(); idx++) {
      whiteList.remove(whiteList.at(idx));
    }
    emit ClearedWhiteList(msg.sender);
  }

  /**
   * @notice return true if address is permited to bid (whitelist empty or address on whitelist).
   */
  function isWhiteListed(address _addr) external view returns (bool) {
    //add address to whitelist
    return whiteList.length() == 0 ? true : whiteList.contains(_addr);
  }

  /**
   * @notice return true if address is on whitelist.
   */
  function whiteListContains(address _addr) external view returns (bool) {
    return whiteList.contains(_addr);
  }
  /************************** ^WHITELIST REGION ************************************************************* */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

/// @title A library to hold our Queen's Royal Knowledge

pragma solidity 0.8.9;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library RoyalLibrary {
    struct sTRAIT {
        uint256 id;
        string traitName;
        uint8 enabled; //0 - disabled; 1 - enabled;
    }

    struct sRARITY {
        uint256 id;
        string rarityName;
        uint256 percentage; //1 ~ 100
    }

    struct sART {
        uint256 traitId;
        uint256 rarityId;
        bytes artName;
        bytes uri;
    }

    struct sDNA {
        uint256 traitId;
        uint256 rarityId;
        uint256 trace;
    }

    struct sBLOOD {
        uint256 traitId;
        uint256 rarityId;
        string artName;
        string artUri;
    }

    struct sQUEEN {
        uint256 queeneId;
        uint256 description; //index of the description
        string finalArt;
        sDNA[] dna;
        uint8 queenesGallery;
        uint8 sirAward;
    }

    struct sSIR {
        address sirAddress;
        uint256 queene;
    }

    struct sAUCTION {
        uint256 queeneId;
        uint256 lastBidAmount;
        uint256 auctionStartTime;
        uint256 auctionEndTime;
        uint256 initialBidPrice;
        address payable bidder;
        bool ended;
    }

    enum queeneRarity {
        COMMON,
        RARE,
        SUPER_RARE,
        LEGENDARY
    }

    address constant burnAddress = 0x0000000000000000000000000000000000000000;
    uint8 constant houseOfLords = 1;
    uint8 constant houseOfCommons = 2;
    uint8 constant houseOfBanned = 3;

    error InvalidAddressError(string _caller, string _msg, address _address);
    error AuthorizationError(string _caller, string _msg, address _address);
    error MinterLockedError(
        string _caller,
        string _msg,
        address _minterAddress
    );
    error StorageLockedError(
        string _caller,
        string _msg,
        address _storageAddress
    );
    error LabLockedError(string _caller, string _msg, address _labAddress);
    error InvalidParametersError(
        string _caller,
        string _msg,
        string _arg1,
        string _arg2,
        string _arg3
    );

    function concat(string memory self, string memory part2)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(self, part2));
    }

    function stringEquals(string storage self, string memory b)
        public
        view
        returns (bool)
    {
        if (bytes(self).length != bytes(b).length) {
            return false;
        } else {
            return
                keccak256(abi.encodePacked(self)) ==
                keccak256(abi.encodePacked(b));
        }
    }

    function extractRevertReason(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Queen Staff Contract

pragma solidity ^0.8.9;

import {IQueenLab} from "../interfaces/IQueenLab.sol";
import {IQueenTraits} from "../interfaces/IQueenTraits.sol";
import {IQueenE} from "../interfaces/IQueenE.sol";
import {IQueenAuctionHouse} from "../interfaces/IQueenAuctionHouse.sol";

interface IQueenPalace {
    function royalMuseum() external view returns (address);

    function isOnImplementation() external view returns (bool status);

    function artist() external view returns (address);

    function isArtist(address addr) external view returns (bool);

    function dao() external view returns (address);

    function daoExecutor() external view returns (address);

    function RoyalTowerAddr() external view returns (address);

    function developer() external view returns (address);

    function isDeveloper(address devAddr) external view returns (bool);

    function minter() external view returns (address);

    function QueenLab() external view returns (IQueenLab);

    function QueenTraits() external view returns (IQueenTraits);

    function QueenAuctionHouse() external view returns (IQueenAuctionHouse);

    function QueenE() external view returns (IQueenE);

    function whiteListed() external view returns (uint256);

    function isWhiteListed(address _addr) external view returns (bool);

    function QueenAuctionHouseProxyAddr() external view returns (address);
}

// SPDX-License-Identifier: MIT

/// @title Interface for Noun Auction Houses

pragma solidity ^0.8.9;

import {IRoyalContractBase} from "./IRoyalContractBase.sol";
import {RoyalLibrary} from "../contracts/lib//RoyalLibrary.sol";
import {IQueenTraits} from "./IQueenTraits.sol";
import {IQueenE} from "./IQueenE.sol";

interface IQueenLab is IRoyalContractBase {
    function buildDna(uint256 queeneId, bool isSir)
        external
        view
        returns (RoyalLibrary.sDNA[] memory dna);

    function produceBlueBlood(RoyalLibrary.sDNA[] memory dna)
        external
        view
        returns (RoyalLibrary.sBLOOD[] memory blood);

    function generateQueen(uint256 _queenId, bool isSir)
        external
        view
        returns (RoyalLibrary.sQUEEN memory);

    function getQueenRarity(RoyalLibrary.sDNA[] memory _dna)
        external
        pure
        returns (RoyalLibrary.queeneRarity finalRarity);

    function getQueenRarityBidIncrement(
        RoyalLibrary.sDNA[] memory _dna,
        uint256[] calldata map
    ) external pure returns (uint256 value);

    function getQueenRarityName(RoyalLibrary.sDNA[] memory _dna)
        external
        pure
        returns (string memory rarityName);

    function constructTokenUri(
        RoyalLibrary.sQUEEN memory _queene,
        string memory _ipfsUri
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE Traits contract

pragma solidity ^0.8.9;

//import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IRoyalContractBase} from "../interfaces/IRoyalContractBase.sol";
import {RoyalLibrary} from "../contracts/lib/RoyalLibrary.sol";

interface IQueenTraits is IRoyalContractBase {
  event RarityCreated(
    uint256 indexed rarityId,
    string rarityName,
    uint256 _percentage
  );
  event RarityUpdated(
    uint256 indexed rarityId,
    string rarityName,
    uint256 _percentage
  );

  event TraitCreated(
    uint256 indexed traitId,
    string _traitName,
    uint8 _enabled
  );

  event TraitEnabled(uint256 indexed traitId, string _traitName);
  event TraitDisabled(uint256 indexed traitId, string _traitName);

  event ArtCreated(
    uint256 traitId,
    uint256 rarityId,
    bytes artName,
    bytes artUri
  );
  event ArtRemoved(uint256 traitId, uint256 rarityId, bytes artUri);

  function rarityPool() external view returns (uint256[] memory);

  function getRarityById(uint256 _rarityId)
    external
    view
    returns (RoyalLibrary.sRARITY memory rarity);

  function getRarityByName(string memory _rarityName)
    external
    returns (RoyalLibrary.sRARITY memory rarity);

  function getRarities(bool onlyWithArt, uint256 _traitId)
    external
    view
    returns (RoyalLibrary.sRARITY[] memory raritiesList);

  function getTrait(uint256 _id)
    external
    view
    returns (RoyalLibrary.sTRAIT memory trait);

  function getTraitByName(string memory _traitName)
    external
    returns (RoyalLibrary.sTRAIT memory trait);

  function getTraits(bool _onlyEnabled)
    external
    view
    returns (RoyalLibrary.sTRAIT[] memory _traits);

  function getDescriptionByIdx(uint256 _rarityId, uint256 _index)
    external
    view
    returns (bytes memory description);

  function getDescriptionsCount(uint256 _rarityId)
    external
    view
    returns (uint256);

  function getArtByUri(
    uint256 _traitId,
    uint256 _rarityId,
    bytes memory _artUri
  ) external returns (RoyalLibrary.sART memory art);

  function getArtCount(uint256 _traitId, uint256 _rarityId)
    external
    view
    returns (uint256 quantity);

  function getArt(
    uint256 _traitId,
    uint256 _rarityId,
    uint256 _artIdx
  ) external view returns (RoyalLibrary.sART memory art);

  function getArts(uint256 _traitId, uint256 _rarityId)
    external
    returns (RoyalLibrary.sART[] memory artsList);
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";

import {IQueenTraits} from "./IQueenTraits.sol";
import {IQueenLab} from "./IQueenLab.sol";
import {RoyalLibrary} from "../contracts/lib/RoyalLibrary.sol";
import {IRoyalContractBase} from "./IRoyalContractBase.sol";
import {IERC721} from "./IERC721.sol";

interface IQueenE is IRoyalContractBase, IERC721 {
    function _currentAuctionQueenE() external view returns (uint256);

    function contractURI() external view returns (string memory);

    function mint() external returns (uint256);

    function getQueenE(uint256 _queeneId)
        external
        view
        returns (RoyalLibrary.sQUEEN memory);

    function burn(uint256 queeneId) external;

    function lockMinter() external;

    function lockQueenTraitStorage() external;

    function lockQueenLab() external;

    function nominateSir(address _sir) external returns (bool);

    function getHouseSeats(uint8 _seatType) external view returns (uint256);

    function getHouseSeat(address addr) external view returns (uint256);

    function IsSir(address _address) external view returns (bool);

    function isSirReward(uint256 queeneId) external view returns (bool);

    function isMuseum(uint256 queeneId) external view returns (bool);

    function dnaMapped(uint256 dnaHash) external view returns (bool);

    function isHouseOfLordsFull() external view returns (bool);
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.9;

import {IBaseContractControllerUpgradeable} from "./IBaseContractControllerUpgradeable.sol";

interface IQueenAuctionHouse is IBaseContractControllerUpgradeable {
  event WithdrawnFallbackFunds(address withdrawer, uint256 amount);
  event AuctionSettled(
    uint256 indexed queeneId,
    address settler,
    uint256 amount
  );

  event AuctionStarted(
    uint256 indexed queeneId,
    uint256 startTime,
    uint256 endTime,
    uint256 initialBid
  );
  event AuctionExtended(uint256 indexed queeneId, uint256 endTime);

  event AuctionBid(
    uint256 indexed queeneId,
    address sender,
    uint256 value,
    bool extended
  );

  event AuctionEnded(uint256 indexed queeneId, address winner, uint256 amount);

  event AuctionTimeToleranceUpdated(uint256 timeBuffer);

  event AuctionInitialBidUpdated(uint256 initialBid);

  event AuctionDurationUpdated(uint256 duration);

  event AuctionMinBidIncrementPercentageUpdated(
    uint256 minBidIncrementPercentage
  );

  function endAuction() external;

  function bid(uint256 queeneId) external payable;

  function pause() external;

  function unpause() external;

  function setTimeTolerance(uint256 _timeTolerance) external;

  function setBidRaiseRate(uint8 _bidRaiseRate) external;

  function setInitialBid(uint256 _initialBid) external;

  function setDuration(uint256 _duration) external;
}

// SPDX-License-Identifier: MIT

/// @title Interface for Base Contract Controller

pragma solidity ^0.8.9;
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IBaseContractController is IERC165 {
    //function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOwner(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

/// @title Interface for QueenE NFT Token

pragma solidity ^0.8.9;

import {IBaseContractController} from "./IBaseContractController.sol";

interface IRoyalTower is IBaseContractController {
    event DAOTreasureDeposit(
        address indexed sender,
        uint256 queeneAuctionId,
        uint256 value
    );

    event DAOTreasureWithdraw(
        address indexed payed,
        uint256 withdrawId,
        uint256 value
    );

    function depositToDAOTreasure(uint256 _queeneAuctionId) external payable;

    function retrieveAuctionFallbackFunds() external;
}

// SPDX-License-Identifier: GPL-3.0

/// @title The Queens auction house proxy

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract QueenAuctionHouseProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) TransparentUpgradeableProxy(logic, admin, data) {}
}

// SPDX-License-Identifier: GPL-3.0

/// @title The Queens auction house proxy admin

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

import {ProxyAdmin} from "../base/ProxyAdmin.sol";
import {IQueenPalace} from "../../interfaces/IQueenPalace.sol";

contract QueenAuctionHouseProxyAdmin is ProxyAdmin {
    constructor(IQueenPalace _queenPalace) {
        queenPalace = _queenPalace;
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

// SPDX-License-Identifier: MIT

/// @title Interface for Base Contract Controller

pragma solidity ^0.8.9;
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IRoyalContractBase is IERC165 {
    //function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOwner(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
/// @title IERC721 Interface

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

// LICENSE
// IERC721.sol modifies OpenZeppelin's interface IERC721.sol to user our own ERC165 standard:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/IERC721.sol
//
// MODIFICATIONS:
// Its the latest `IERC721` interface from OpenZeppelin (v4.4.5) using our own ERC165 controller.

pragma solidity ^0.8.9;

import {IRoyalContractBase} from "../interfaces/IRoyalContractBase.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IRoyalContractBase {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

/// @title Interface for Base Contract Controller

pragma solidity ^0.8.9;
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC165Upgradeable.sol";

interface IBaseContractControllerUpgradeable is IERC165Upgradeable {
    //function supportsInterface(bytes4 interfaceID) external view returns (bool);

    function isOwner(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

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
// OpenZeppelin Contracts v4.4.1 (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// QueenE DAO ProxyAdmin base contract

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

// LICENSE
// ProxyAdmin.sol modifies OpenZeppelin's ProxyAdmin.sol:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/transparent/ProxyAdmin.sol
//
// ProxyAdmin.sol source code copyright OpenZeppelin licensed under the MIT License.
// Modified by QueenE DAO.
//
//
// CHANGES:
// inherits from our own interface controller (BaseContractController) instead of only Ownable Contract.
// deliver control of upgrade to governance after implementation ends

pragma solidity ^0.8.9;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BaseContractController} from "./BaseContractController.sol";
import {RoyalLibrary} from "../lib/RoyalLibrary.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is BaseContractController {
    event UpgradeAllowed(address indexed approver);
    event Upgraded(address indexed upgrader, address implementation);

    modifier onlyImplementationOrDAO() {
        require(
            msg.sender == queenPalace.daoExecutor() ||
                queenPalace.isOnImplementation()
        );
        _;
    }

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"5c60da1b"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy)
        public
        view
        virtual
        returns (address)
    {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(
            hex"f851a440"
        );
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(
        TransparentUpgradeableProxy proxy,
        address newAdmin
    ) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation)
        public
        virtual
        onlyOwnerOrDAO
        onlyImplementationOrDAO
        whenNotPaused
    {
        proxy.upgradeTo(implementation);

        emit Upgraded(msg.sender, implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    )
        public
        payable
        virtual
        onlyOwnerOrDAO
        onlyImplementationOrDAO
        whenNotPaused
    {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);

        emit Upgraded(msg.sender, implementation);
    }
}

// SPDX-License-Identifier: MIT

/// @title A base contract with implementation control

/************************************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░██░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░██░░░░░░░░░░░░████░░░░░░░░░░░░██░░░░░░░ *
 * ░░░░░████░░░░░░░░░░██░░██░░░░░░░░░░████░░░░░░ *
 * ░░░░██████░░░░░░░░██░░░░██░░░░░░░░██████░░░░░ *
 * ░░░███░░███░░░░░░████░░████░░░░░░███░░███░░░░ *
 * ░░██████████░░░░████████████░░░░██████████░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░███░░░░███████████░░░░███████████░░░░███░░░ *
 * ░░████░░█████████████░░█████████████░░████░░░ *
 * ░░████████████████████████████████████████░░░ *
 *************************************************/

pragma solidity ^0.8.9;

//import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC165Storage} from "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import {RoyalLibrary} from "../lib/RoyalLibrary.sol";
import {IBaseContractController} from "../../interfaces/IBaseContractController.sol";
import {IQueenPalace} from "../../interfaces/IQueenPalace.sol";

contract BaseContractController is
    ERC165Storage,
    IBaseContractController,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    IQueenPalace internal queenPalace;

    /************************** vCONTROLLER REGION *************************************************** */

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external virtual onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external virtual onlyOwner whenPaused {
        _unpause();
    }

    /**
     *IN
     *_queenPalace: address of queen palace contract
     *OUT
     */
    function setQueenPalace(IQueenPalace _queenPalace)
        external
        nonReentrant
        whenPaused
        onlyOwnerOrDAO
        onlyOnImplementationOrDAO
    {
        _setQueenPalace(_queenPalace);
    }

    /**
     *IN
     *_queenPalace: address of queen palace contract
     *OUT
     */
    function _setQueenPalace(IQueenPalace _queenPalace) internal {
        queenPalace = _queenPalace;
    }

    /************************** ^vCONTROLLER REGION *************************************************** */

    /************************** vMODIFIERS REGION ***************************************************** */

    modifier onlyDAO() {
        isDAO();
        _;
    }
    modifier onlyChiefArtist() {
        isChiefArtist();
        _;
    }
    modifier onlyArtist() {
        isArtist();
        _;
    }

    modifier onlyChiefDeveloper() {
        isChiefDeveloper();
        _;
    }

    modifier onlyDeveloper() {
        isDeveloper();
        _;
    }

    modifier onlyMinter() {
        isMinter();
        _;
    }

    modifier onlyActor() {
        isActor();
        _;
    }

    modifier onlyActorOrDAO() {
        isActorOrDAO();
        _;
    }

    modifier onlyOwnerOrChiefArtist() {
        isOwnerOrChiefArtist();
        _;
    }

    modifier onlyOwnerOrArtist() {
        isOwnerOrArtist();
        _;
    }

    modifier onlyOwnerOrChiefDeveloper() {
        isOwnerOrChiefDeveloper();
        _;
    }

    modifier onlyOwnerOrDeveloper() {
        isOwnerOrDeveloper();
        _;
    }
    modifier onlyOwnerOrChiefDeveloperOrDAO() {
        isOwnerOrChiefDeveloperOrDAO();
        _;
    }

    modifier onlyOwnerOrDeveloperOrDAO() {
        isOwnerOrDeveloperOrDAO();
        _;
    }

    modifier onlyOwnerOrChiefArtistOrDAO() {
        isOwnerOrChiefArtistOrDAO();
        _;
    }

    modifier onlyOwnerOrArtistOrDAO() {
        isOwnerOrArtistOrDAO();
        _;
    }
    modifier onlyOwnerOrDAO() {
        isOwnerOrDAO();
        _;
    }

    modifier onlyOwnerOrMinter() {
        isOwnerOrMinter();
        _;
    }

    modifier onlyOwnerOrAuctionHouse() {
        isOwnerOrAuctionHouse();
        _;
    }

    modifier onlyOwnerOrAuctionHouseProxy() {
        isOwnerOrAuctionHouseProxy();
        _;
    }

    modifier onlyOwnerOrQueenPalace() {
        isOwnerOrQueenPalace();
        _;
    }

    modifier onlyOnImplementation() {
        isOnImplementation();
        _;
    }

    modifier onlyOnImplementationOrDAO() {
        isOnImplementationOrDAO();
        _;
    }

    modifier onlyOnImplementationOrPaused() {
        isOnImplementationOrPaused();
        _;
    }

    /************************** ^MODIFIERS REGION ***************************************************** */

    /**
     *IN
     *OUT
     *if given address is owner
     */
    function isOwner(address _address) external view override returns (bool) {
        return owner() == _address;
    }

    function isOwnerOrChiefArtistOrDAO() internal view {
        require(
            msg.sender == owner() ||
                msg.sender == queenPalace.artist() ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Artist, DAO"
        );
    }

    function isChiefArtist() internal view {
        require(msg.sender == queenPalace.artist(), "Not Chief Artist");
    }

    function isArtist() internal view {
        require(queenPalace.isArtist(msg.sender), "Not Artist");
    }

    function isChiefDeveloper() internal view {
        require(msg.sender == queenPalace.developer(), "Not Chief Dev");
    }

    function isDeveloper() internal view {
        require(queenPalace.isDeveloper(msg.sender), "Not Dev");
    }

    function isMinter() internal view {
        require(msg.sender == queenPalace.minter(), "Not Minter");
    }

    function isActor() internal view {
        require(
            msg.sender == owner() ||
                queenPalace.isArtist(msg.sender) ||
                queenPalace.isDeveloper(msg.sender),
            "Invalid Actor"
        );
    }

    function isActorOrDAO() internal view {
        require(
            msg.sender == owner() ||
                queenPalace.isArtist(msg.sender) ||
                queenPalace.isDeveloper(msg.sender) ||
                msg.sender == queenPalace.daoExecutor(),
            "Invalid Actor, DAO"
        );
    }

    function isOwnerOrChiefArtist() internal view {
        require(
            msg.sender == owner() || msg.sender == queenPalace.artist(),
            "Not Owner, Chief Artist"
        );
    }

    function isOwnerOrArtist() internal view {
        require(
            msg.sender == owner() || queenPalace.isArtist(msg.sender),
            "Not Owner, Artist"
        );
    }

    function isOwnerOrChiefDeveloper() internal view {
        require(
            msg.sender == owner() || msg.sender == queenPalace.developer(),
            "Not Owner, Chief Developer"
        );
    }

    function isOwnerOrDeveloper() internal view {
        require(
            msg.sender == owner() || queenPalace.isDeveloper(msg.sender),
            "Not Owner, Developer"
        );
    }

    function isOwnerOrChiefDeveloperOrDAO() internal view {
        require(
            msg.sender == owner() ||
                msg.sender == queenPalace.developer() ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Chief Developer, DAO"
        );
    }

    function isOwnerOrDeveloperOrDAO() internal view {
        require(
            msg.sender == owner() ||
                queenPalace.isDeveloper(msg.sender) ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Developer, DAO"
        );
    }

    function isOwnerOrArtistOrDAO() internal view {
        require(
            msg.sender == owner() ||
                queenPalace.isArtist(msg.sender) ||
                msg.sender == queenPalace.daoExecutor(),
            "Not Owner, Artist, DAO"
        );
    }

    function isOwnerOrDAO() internal view {
        require(
            msg.sender == owner() || msg.sender == queenPalace.daoExecutor(),
            "Not Owner, DAO"
        );
    }

    function isDAO() internal view {
        require(msg.sender == queenPalace.daoExecutor(), "Not DAO");
    }

    function isOwnerOrMinter() internal view {
        require(
            msg.sender == owner() || msg.sender == queenPalace.minter(),
            "Not Owner, Minter"
        );
    }

    function isOwnerOrAuctionHouse() internal view {
        require(
            msg.sender == owner() ||
                msg.sender == address(queenPalace.QueenAuctionHouse()),
            "Not Owner, Auction House"
        );
    }

    function isOwnerOrAuctionHouseProxy() internal view {
        require(
            msg.sender == owner() ||
                msg.sender == address(queenPalace.QueenAuctionHouseProxyAddr()),
            "Not Owner, Auction House"
        );
    }

    function isOwnerOrQueenPalace() internal view {
        require(
            msg.sender == owner() || msg.sender == address(queenPalace),
            "Not Owner,Queen Palace"
        );
    }

    function isOnImplementation() internal view {
        require(queenPalace.isOnImplementation(), "Not On Implementation");
    }

    function isOnImplementationOrDAO() internal view {
        require(
            queenPalace.isOnImplementation() ||
                msg.sender == queenPalace.daoExecutor(),
            "Not On Implementation sender not DAO"
        );
    }

    function isOnImplementationOrPaused() internal view {
        require(
            queenPalace.isOnImplementation() || paused(),
            "Not On Implementation,Paused"
        );
    }
}