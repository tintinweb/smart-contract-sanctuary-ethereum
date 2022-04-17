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

//*~~~> SPDX-License-Identifier: MIT make it better, stronger, faster

/*~~~>
    Thank you Phunks for your inspiration and phriendship.
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
%%%%%((((((((((((((((((((@PhunkyJON was here programming trustless, unstoppable [email protected](((((((((((((((((((((((((%%%%%
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

pragma solidity  0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IRoleProvider.sol";
import "./interfaces/IRewardsController.sol";

///@notice
/*~~~>
Interface declarations for upgradable contracts accessibility
<~~~*/
interface NFT {
  function grantRole(bytes32 role, address account) external;
  function revokeRole(bytes32 role, address account) external;
}
interface MarketMint {
  function setDeployAmnt(uint deplyAmnt) external;
  function setNewRedemption(uint redeemAmount, address contractAdd) external;
  function resetRedemptionToken(uint64 redeemAmount, address contractAdd) external;
}
interface RoleProvider is IRoleProvider {
  function setMarketMintAdd(address newmintAdd) external returns(bool);
  function setNftAdd(address newnftAdd) external returns(bool);
  function setOffersAdd(address newoffAdd) external returns(bool);
  function setTradesAdd(address newtradAdd) external returns(bool);
  function setBidsAdd(address newbidsAdd) external returns(bool);
  function setRwdsAdd(address newrwdsAdd) external returns(bool);
  function setProxyRoleAddress(address newrole) external returns(bool);
  function setOwnerProxyAdd(address newproxyAdd) external returns(bool);
  function setPhunkyAdd(address newphunky) external returns(bool);
  function setDevSigAddress(address newsig) external returns(bool);
  function setMarketAdd(address newmrktAdd) external returns(bool);
}

contract OwnerProxy is ReentrancyGuard {
  /*~~~>
    State Address Variables
  <~~~*/
  //*~~~> Global address variable from Role Provider contract
  bytes32 public constant REWARDS = keccak256("REWARDS");
  
  bytes32 public constant BIDS = keccak256("BIDS");
  
  bytes32 public constant OFFERS = keccak256("OFFERS");
  
  bytes32 public constant TRADES = keccak256("TRADES");

  bytes32 public constant NFTADD = keccak256("NFT");

  bytes32 public constant MINT = keccak256("MINT");

  bytes32 public constant MARKET = keccak256("MARKET");

  bytes32 public constant PROXY = keccak256("PROXY");

  address public roleAdd;

  //*~~~> Roles for designated accessibility
  bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE"); 
  bytes32 public constant DEV = keccak256("DEV");
  modifier hasAdmin(){
    require(RoleProvider(roleAdd).hasTheRole(PROXY_ROLE, msg.sender), "DOES NOT HAVE ADMIN ROLE");
    _;
  }
  modifier hasDevAdmin(){
    require(RoleProvider(roleAdd).hasTheRole(DEV, msg.sender), "DOES NOT HAVE DEV ROLE");
    _;
  }

  constructor(address role){
    roleAdd = role;
  }

  /// @notice
  /*~~~>
    For setting the platform fees on RewardsController.sol
    Base fee set at 2% (i.e. value * 200 / 10,000) 
    Future fees can be set by the controlling DAO 
  <~~~*/
  function setFee(uint newFee) public hasAdmin returns (bool) {
    address rewardsAdd = RoleProvider(roleAdd).fetchAddress(REWARDS);
    IRewardsController(rewardsAdd).setFee(newFee);
    return true;
  }

  ///@notice
  /*~~~>
    For setting the state address variables
  <~~~*/
  function setMarketAdd(address mrktAdd) hasDevAdmin public returns(bool){
    RoleProvider(roleAdd).setMarketAdd(mrktAdd);
    return true;
  }
  function setNftAdd(address nft) hasDevAdmin public returns(bool){
    RoleProvider(roleAdd).setNftAdd(nft);
    return true;
  }
  function setMarketMintAdd(address mintAdd) hasDevAdmin public returns(bool){
    RoleProvider(roleAdd).setMarketMintAdd(mintAdd);
    return true;
  }
  function setOffersAdd(address offAdd) hasDevAdmin public returns(bool){
    RoleProvider(roleAdd).setOffersAdd(offAdd);
    return true;
  }
  function setTradesAdd(address tradAdd) hasDevAdmin public returns(bool){
    RoleProvider(roleAdd).setTradesAdd(tradAdd);
    return true;
  }
  function setBidsAdd(address bidsAdd) hasDevAdmin public returns(bool){
    RoleProvider(roleAdd).setBidsAdd(bidsAdd);
    return true;
  }
  function setRwdsAdd(address rwdsAdd) hasDevAdmin public returns(bool){
    RoleProvider(roleAdd).setRwdsAdd(rwdsAdd);
    return true;
  }
  function setRoleAdd(address role) hasDevAdmin public returns(bool){
    roleAdd = role;
    return true;
  }

  ///@notice
  /*~~~>
    For setting the proxy role in the role provider contract
  <~~~*/
  function setProxyRole(address sig) hasDevAdmin public returns(bool){
    RoleProvider(roleAdd).setProxyRoleAddress(sig);
    return true;
  }
  
  ///@notice
  /*~~~>
  For controlling MarketMint contract
  <~~~*/
  function setNewMintRedemption(uint redeemAmount, address contractAdd) hasAdmin public returns(bool){
    address marketMintAdd = RoleProvider(roleAdd).fetchAddress(MINT);
    MarketMint(marketMintAdd).setNewRedemption(redeemAmount, contractAdd);
    return true;
  }
  function resetMintRedemptionToken(uint64 redeemAmount, address contractAdd) hasAdmin public returns(bool){
    address marketMintAdd = RoleProvider(roleAdd).fetchAddress(MINT);
    MarketMint(marketMintAdd).resetRedemptionToken(redeemAmount, contractAdd);
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
  function grantNFTRoles(bytes32 role, address account) hasDevAdmin public returns(bool) {
    address nftAdd = RoleProvider(roleAdd).fetchAddress(NFTADD);
    NFT(nftAdd).grantRole(role, account);
    return true;
  }
  function revokeNFTRoles(bytes32 role, address account) hasDevAdmin public returns(bool) {
    address nftAdd = RoleProvider(roleAdd).fetchAddress(NFTADD);
    NFT(nftAdd).revokeRole(role, account);
    return true;
  }

  /// @notice
  /*~~~> 
    Internal function for sending ether
  <~~~*/
  /// @return Bool
  function sendEther(address recipient, uint ethvalue) internal returns (bool){
    (bool success, bytes memory data) = address(recipient).call{value: ethvalue}("");
    return(success);
  }

  /*~~~>
  Fallback functions
  <~~~*/
  /*~~~> External ETH transfer forwarded to role provider contract <~~~*/
  event FundsForwarded(uint value, address from, address to);
  receive() external payable {
    require(sendEther(roleAdd, msg.value));
      emit FundsForwarded(msg.value, msg.sender, roleAdd);
  }
}

//*~~~> SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRewardsController {
  function createNftHodler(uint tokenId) external returns (bool);
  function depositERC20Rewards(uint amount, address tokenAddress) external returns(bool);
  function getFee() external view returns(uint);
  function setFee(uint fee) external returns (bool);
  function depositEthRewards(uint reward) external payable returns(bool);
  function createUser(address userAddress) external returns(bool);
  function setUser(bool canClaim, address userAddress) external returns(bool);
}

//*~~~> SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRoleProvider {
  function hasTheRole(bytes32 role, address theaddress) external returns(bool);
  function fetchAddress(bytes32 thevar) external returns(address);
  function hasContractRole(address theaddress) external view returns(bool);
}