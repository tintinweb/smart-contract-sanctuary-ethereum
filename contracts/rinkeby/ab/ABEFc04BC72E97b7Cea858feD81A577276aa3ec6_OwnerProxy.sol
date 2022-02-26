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

//*~~~> SPDX-License-Identifier: MIT OR Apache-2.0
/*~~~>
    Thank you Phunks, your inspiration and phriendship meant the world to me and helped me through hard times.
      Never stop phighting, never surrender, always stand up for what is right and make the best of all situations towards all people.
      Phunks are phreedom phighters!
        "When the power of love overcomes the love of power the world will know peace." - Jimi Hendrix <3

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################%%%%%@@@@@((((((((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################%%%%%@@@@@((((((((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@########################################%%%%%@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@########################################%%%%%@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###############@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@###############@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@#PHUNKYJON///////////////#PHUNKYJON//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@#PHUNKYJON///////////////#PHUNKYJON//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////@EYES////////////////////@EYES///////////////@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////@EYES////////////////////@EYES///////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////////////////////////////////////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////////////////////////////////////////////[email protected]@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@/////////////////////////////////////////////@@@@@@@@@@((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////[email protected]@////////////////////#####@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((SMOKE((((((((((@@@@@//////////[email protected]@////////////////////#####@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@#####//////////////////////////////##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((@@@@@#####//////////////////////////////##########@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@###################################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@###################################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((EMBER(((((,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@MOUTH&&&&&####################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((EMBER(((((,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@MOUTH&&&&&####################@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@##############################/////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((@[email protected]@[email protected]@@##############################/////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%(((((((((((((((((((((((((((((((((((@@@@@##############################//////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((@@@@@@@@@@@@@@@@@@@@@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%((((((((((((((((((((((((((((((((((((((((((((((((((((((((((((@@@@@///////////////@@@@@(((((((((((((((((((((((((%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@///////////////@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@@@@@///////////////@@@@@%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 <~~~*/
pragma solidity  >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

///@notice
/*~~~>
Interface declarations for upgradable contracts accessibility
<~~~*/
interface Marketplace {
  function setRoleAdd(address _role) external;
  function setFee(uint _fee) external;
}
interface NFT {
  function grantRole(bytes32 role, address account) external;
  function revokeRole(bytes32 role, address account) external;
}
interface Offers {
  function setRoleAdd(address _role) external;
  function setFee(uint _fee) external;
}
interface Collections {
  function setControlAdd(address _contAdd) external;
  function setRoleAdd(address _role) external;
  function restrictMarketCollection(string[] calldata name, address[] calldata nftContract) external;
  function editMarketCollection(bool[] calldata isNotTradable, string[] calldata name,address[] calldata nftContract, uint[] calldata collectionId) external;
}
interface Bids {
  function setRoleAdd(address _role) external;
  function setFee(uint _fee) external;
}
interface MarketMint {
  function setDeployAmnt(uint _deplyAmnt) external;
  function setRoleAdd(address _role) external;
  function setNewRedemption(uint amount, address _toke) external;
  function resetRedemptionToken(uint64 _redeemAmount, address _contract) external;
}
interface RoleProvider {
  function fetchAddress(bytes32 _var) external returns(address);
  function setMarketAdd(address _mrktAdd) external returns(bool);
  function setMarketMintAdd(address _mintAdd) external returns(bool);
  function setNftAdd(address _nftAdd) external returns(bool);
  function setCollectionsAdd(address _collAdd) external returns(bool);
  function setOffersAdd(address _offAdd) external returns(bool);
  function setTradesAdd(address _tradAdd) external returns(bool);
  function setBidsAdd(address _bidsAdd) external returns(bool);
  function setRwdsAdd(address _rwdsAdd) external returns(bool);
  function setRoleAdd(address _role) external returns(bool);
  function setOwnerProxyAdd(address _proxyAdd) external returns(bool);
  function setPhunkyAdd(address _phunky) external returns(bool);
  function setDevSigAddress(address _sig) external returns(bool);
  function hasTheRole(bytes32 role, address _address) external returns(bool);
  function grantRole(bytes32 role, address _address) external;
  function revokeRole(bytes32 role, address account) external;
}
interface Rewards {
  function setRoleAdd(address _role) external;
  function setAccountRcv(address _recvr) external;
}

contract OwnerProxy is ReentrancyGuard, Pausable {
  /*~~~>
    State Address Variables
  <~~~*/
  //*~~~> global address variable from Role Provider contract
  bytes32 public constant REWARDS = keccak256("REWARDS");

  bytes32 public constant COLLECTION = keccak256("COLLECTION");
  
  bytes32 public constant BIDS = keccak256("BIDS");
  
  bytes32 public constant OFFERS = keccak256("OFFERS");
  
  bytes32 public constant TRADES = keccak256("TRADES");

  bytes32 public constant NFTADD = keccak256("NFT");

  bytes32 public constant MINT = keccak256("MINT");

  bytes32 public constant MARKET = keccak256("MARKET");

  bytes32 public constant PROXY = keccak256("PROXY");

  bytes32 public constant DEV = keccak256("DEV");

  address public roleAdd;

  //*~~~> Roles for designated accessibility
  bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE"); 
  bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");
  modifier hasAdmin(){
    require(RoleProvider(roleAdd).hasTheRole(PROXY_ROLE, msg.sender), "DOES NOT HAVE ADMIN ROLE");
    _;
  }
  modifier hasDevAdmin(){
    require(RoleProvider(roleAdd).hasTheRole(DEV_ROLE, msg.sender), "DOES NOT HAVE DEV ROLE");
    _;
  }

  constructor(address _role){
    roleAdd = _role;
  }

  /// @notice
  /*~~~>
    For setting fees on Bids, Offers, MarketMint and Marketplace contracts
  <~~~*/
  function setFees(uint _fee) hasAdmin public returns(bool){
    address marketPlaceAdd = RoleProvider(roleAdd).fetchAddress(MARKET);
    address offersAdd = RoleProvider(roleAdd).fetchAddress(OFFERS);
    address bidsAdd = RoleProvider(roleAdd).fetchAddress(BIDS);
    Offers(offersAdd).setFee(_fee);
    Bids(bidsAdd).setFee(_fee);
    Marketplace(marketPlaceAdd).setFee(_fee);
    return true;
  }

  ///@notice
  /*~~~>
    For setting the state address variables
  <~~~*/
  function setMarketAdd(address _mrktAdd) hasAdmin public returns(bool){
    RoleProvider(roleAdd).setMarketAdd(_mrktAdd);
    return true;
  }
  function setNftAdd(address _nft) hasAdmin public returns(bool){
    RoleProvider(roleAdd).setNftAdd(_nft);
    return true;
  }
  function setMarketMintAdd(address _mintAdd) hasAdmin public returns(bool){
    RoleProvider(roleAdd).setMarketMintAdd(_mintAdd);
    return true;
  }
   function setCollectionsAdd(address _collAdd) hasAdmin public returns(bool){
    RoleProvider(roleAdd).setCollectionsAdd(_collAdd);
    return true;
  }
  function setOffersAdd(address _offAdd) hasAdmin public returns(bool){
    RoleProvider(roleAdd).setOffersAdd(_offAdd);
    return true;
  }
  function setTradesAdd(address _tradAdd) hasAdmin public returns(bool){
    RoleProvider(roleAdd).setTradesAdd(_tradAdd);
    return true;
  }
  function setBidsAdd(address _bidsAdd) hasAdmin public returns(bool){
    RoleProvider(roleAdd).setBidsAdd(_bidsAdd);
    return true;
  }
  function setRwdsAdd(address _rwdsAdd) hasAdmin public returns(bool){
    RoleProvider(roleAdd).setRwdsAdd(_rwdsAdd);
    return true;
  }
  function setRoleAdd(address _role) public hasAdmin returns(bool){
      roleAdd = _role;
    return true;
  }
  function setDevAdd(address _devAdd) public hasDevAdmin returns(bool){
    RoleProvider(roleAdd).setDevSigAddress(_devAdd);
    return true;
  }

  ///@notice
  /*~~~>
    For setting the roles in the role provider contract
  <~~~*/
  function setProxyRoles(bytes32[] calldata role, address[] calldata account) hasAdmin public returns(bool){
    for (uint i; i<account.length; i++){
      RoleProvider(roleAdd).grantRole(role[i], account[i]);
    }
    return true;
  }
  function setProxyRole(bytes32 role, address account) hasAdmin public returns(bool){
    RoleProvider(roleAdd).grantRole(role, account);
    return true;
  }
  function revokeProxyRole(bytes32 role, address account) hasAdmin public returns(bool){
    RoleProvider(roleAdd).revokeRole(role, account);
    return true;
  }

  ///@notice
  /*~~~>
    For setting the DAO address to withdraw rewards
  <~~~*/
  function setRewardsAccountRcv(address _recvr) hasAdmin public returns(bool){
    address rewardsAdd = RoleProvider(roleAdd).fetchAddress(REWARDS);
    Rewards(rewardsAdd).setAccountRcv(_recvr);
    return true;
  }

  ///@notice
  /*~~~>
    For controlling the Collection contract
  <~~~*/
  function restrictMarketCollection(
  string[] calldata name,
  address[] calldata nftContract 
  ) hasAdmin public returns(bool){
    address collectionsAdd = RoleProvider(roleAdd).fetchAddress(COLLECTION);
    Collections(collectionsAdd).restrictMarketCollection(name, nftContract);
    return true;
  }

  function editMarketCollection(bool[] calldata isNotTradable, string[] calldata name, address[] calldata nftContract, uint[] calldata collectionId) hasAdmin public returns(bool){
    address collectionsAdd = RoleProvider(roleAdd).fetchAddress(COLLECTION);
    Collections(collectionsAdd).editMarketCollection(isNotTradable, name, nftContract, collectionId);
    return true;
  }

  ///@notice
  /*~~~>
  For controlling MarketMint contract
  <~~~*/
  function setNewMintRedemption(uint amount, address _toke) hasAdmin public returns(bool){
    address marketMintAdd = RoleProvider(roleAdd).fetchAddress(MINT);
    MarketMint(marketMintAdd).setNewRedemption(amount, _toke);
    return true;
  }
  function resetMintRedemptionToken(uint64 _redeemAmount, address _contract) hasAdmin public returns(bool){
    address marketMintAdd = RoleProvider(roleAdd).fetchAddress(MINT);
    MarketMint(marketMintAdd).resetRedemptionToken(_redeemAmount, _contract);
    return true;
  }
  function setMintDeployAmnt(uint dplyAmnt) hasAdmin public returns(bool){
    address marketMintAdd = RoleProvider(roleAdd).fetchAddress(MINT);
    MarketMint(marketMintAdd).setDeployAmnt(dplyAmnt);
    return true;
  }

  /// @notice
  /*~~~>
    For controlling the NFT contract accessibility roles after initial deployment
  <~~~*/
  function grantNFTRoles(bytes32 role, address account) hasAdmin public returns(bool) {
    address nftAdd = RoleProvider(roleAdd).fetchAddress(NFTADD);
    NFT(nftAdd).grantRole(role, account);
    return true;
  }
  function revokeNFTRoles(bytes32 role, address account) hasAdmin public returns(bool) {
    address nftAdd = RoleProvider(roleAdd).fetchAddress(NFTADD);
    NFT(nftAdd).revokeRole(role, account);
    return true;
  }

  ///@notice DEV operations for emergency functions
  function pause() public hasDevAdmin {
      _pause();
  }
  function unpause() public hasDevAdmin {
      _unpause();
  }

  /*~~~>
  Fallback functions
  <~~~*/
  /*~~~> External ETH transfer forwarded to role provider contract <~~~*/
  event FundsForwarded(uint value, address _from, address _to);
  receive() external payable {
    payable(roleAdd).transfer(msg.value);
      emit FundsForwarded(msg.value, msg.sender, roleAdd);
  }
  ///@notice
  //*~~~> Withdraw function for any stuck ETH sent
  function withdrawAmountFromContract(address _add) hasAdmin external {
      payable(_add).transfer(address(this).balance);
   }
}