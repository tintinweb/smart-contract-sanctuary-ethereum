/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// https://opensea.io/collection/loot-familiars
// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

// File: @openzeppelin/contracts/access/Ownable.sol

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * Minimal ERC-721 interface Familiars implement
 */
interface ERC721Interface {
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

/**
 * Minimal ERC-20 interface Familiars implement
 */
interface ERC20Interface {
  function balanceOf(address owner) external view returns (uint256 balance);
  function transfer(address recipient, uint256 amount) external returns (bool);
}

/**
 * @title Familiars (For Adventurers) contract. All revenue from Familiars will
 * be used to purchase floor Loots, which will then be fractionalized to Familiars
 * owners.
 */
contract FlootClaim is Ownable {
    // Amount of FLOOT each familiar can claim
    uint256 constant public FLOOT_PER_FAMILIAR = 10000 * 10**18; // 10k FLOOT per familiar

    // Familiar contracts
    ERC721Interface immutable v1FamiliarContract; // V1 familiars
    ERC721Interface immutable familiarContract;   // Real familiars
    address public immutable FAMILIAR_ADDRESS;

    // FLOOT contract
    ERC20Interface immutable flootContract;
    address public immutable FLOOT_ADDRESS;

    // When FLOOTs will be withdrawable by owner
    // This is to ensure that FLOOTs aren't forever locked in this contract,
    // which could prevent buyouts on Fractional art, but could also prevent
    // all ETH from being distributed to FLOOT owners in case of a buyout.
    uint256 public immutable UNLOCK_TIME;

    // Tracks which familiar has claimed their FLOOT
    mapping (uint256 => bool) public claimed;
    mapping (uint256 => bool) public allowedV1;
 
    // Store contract addresses and register unlock time to be in 1 year
    constructor(address _v1FamiliarAddress, address _familiarAddress,  address _flootAddress) {
      // Familiar contracts
      v1FamiliarContract = ERC721Interface(_v1FamiliarAddress);
      familiarContract = ERC721Interface(_familiarAddress);
      FAMILIAR_ADDRESS = _familiarAddress;

      // Floot contract
      flootContract = ERC20Interface(_flootAddress);
      FLOOT_ADDRESS = _flootAddress;

      // Owner can withdraw remaining FLOOTs 1 year after contract creation
      UNLOCK_TIME = block.timestamp + 365 days;
    }

    // Sets a V2 familiar minted from V1 as being eligible
    function enableV1Claim(uint256[] calldata _ids) external onlyOwner {
      for (uint256 i = 0; i < _ids.length; i++) {
        allowedV1[_ids[i]] = true;
      }
    }

    // Sets a V2 familiar from V1 as NOT eligible
    function disableV1Claim(uint256[] calldata _ids) external onlyOwner {
      for (uint256 i = 0; i < _ids.length; i++) {
        allowedV1[_ids[i]] = false;
      }
    }

    // Sends FLOOT to owner of _id, if FLOOT hasn't been claimed yet
    function claim(uint256 _id) external {
      _claim(_id);
    }
    
    // Sends FLOOT to respective owner of all familiars in _ids, if FLOOT hasn't been claimed yet
    function multiClaim(uint256[] memory _ids) external {
      for (uint256 i = 0; i < _ids.length; i++) {
        _claim(_ids[i]);
      }
    }
  
    function _claim(uint256 _id) private {
      require(isClaimable(_id), "Familiar cannot claim FLOOT");

      // Transfer floot to familiar owner
      address familiarOwner = familiarContract.ownerOf(_id);
      (bool success, bytes memory data) = address(flootContract).call(abi.encodeWithSelector(0xa9059cbb, familiarOwner, FLOOT_PER_FAMILIAR));
      require(success && (data.length == 0 || abi.decode(data, (bool))), 'Floot transfer failed');
      claimed[_id] = true;
    }

    // Check if you can claim a given familiar
    function isClaimable(uint256 _id) public view returns (bool claimable) {
      return !claimed[_id] && isAllowed(_id);
    }

    // Check if a familiar is not eligible for claiming FLOOT
    function isAllowed(uint256 _id) public view returns (bool allowed) {
      // ID must be within valid range
      if (_id == 0 || _id > 8000) { return false; }

      // Verify whether the V1 familiar exists for this ID
      try v1FamiliarContract.ownerOf(_id) {
        if (!allowedV1[_id]) {
          // V1 exists but is not allowed
          return false;
        }
        // V1 exists and is allowed
        return true;

      } catch {
        // V1 familiar does not exist, so familiar must be allowed
        return true;
      }
    }

    // Allow owner of this contract to withdraw FLOOT 1 year after deployment
    // This is to ensure that FLOOTs aren't forever locked in this contract,
    // which could prevent buyouts on Fractional art, but could also prevent
    // all ETH from being distributed to FLOOT owners in case of a buyout.
    function withdrawFloot() external onlyOwner {
      require(block.timestamp >= UNLOCK_TIME, "Cannot withdraw FLOOT yet");
      uint256 balance = flootContract.balanceOf(address(this));
      flootContract.transfer(owner(), balance);
    }
}