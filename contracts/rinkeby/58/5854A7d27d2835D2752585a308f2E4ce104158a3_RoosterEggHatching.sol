// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import {Auth} from "./Auth.sol";

interface IEgg {
  function burnBatch(uint24[] memory eggIds) external;

  function ownerOf(uint256 tokenId) external view returns (address);
}

interface INft {
  function batchMint(address to, uint256[] memory types) external;
}

contract RoosterEggHatching is Auth {
  //Address of RoosterEgg contract
  address public immutable egg;
  //Address of Rooster contract
  address public immutable rooster;
  //Address of Gaff contract
  address public immutable gaff;
  //Address of Gem contract
  address public immutable gem;

  //Fires when eggs are hatched
  event EggsHatched(address indexed user, uint24[] eggIds);

  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  constructor(
    address signer_,
    address egg_,
    address rooster_,
    address gaff_,
    address gem_
  ) {
    egg = egg_;
    rooster = rooster_;
    gaff = gaff_;
    gem = gem_;
    _grantRole("SIGNER", signer_);
  }

  /**
   * @param eggIds Array of rooster egg ids to burn
   * @param breeds Array of rooster breeds to mint
   * @param gaffTypes Array of gaff amounts to mint (Index number corresponds to gaff id)
   * @param gemTypes Array of gem ids to mint
   */
  function hatch(
    address to,
    uint24[] calldata eggIds,
    uint256[] calldata breeds,
    uint256[] calldata gaffTypes,
    uint256[] calldata gemTypes,
    Sig calldata sig
  ) external whenNotPaused {
    //Check if parameters are valid
    require(_isParamValid(breeds, gaffTypes, gemTypes, sig), "Invalid parameter");
    //Check if egg owner
    require(_isOwnerCorrect(eggIds), "Invalid owner");

    //Burn eggs
    IEgg(egg).burnBatch(eggIds);
    //Mint roosters
    INft(rooster).batchMint(to, breeds);
    //Mint gaffs
    INft(gaff).batchMint(to, gaffTypes);
    //Mint gems
    INft(gem).batchMint(to, gemTypes);

    emit EggsHatched(msg.sender, eggIds);
  }

  function _isParamValid(
    uint256[] calldata breeds,
    uint256[] calldata gaffTypes,
    uint256[] calldata gemTypes,
    Sig calldata sig
  ) private view returns (bool) {
    bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, breeds, gaffTypes, gemTypes));
    bytes32 ethSignedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    return hasRole("SIGNER", ecrecover(ethSignedMessageHash, sig.v, sig.r, sig.s));
  }

  function _isOwnerCorrect(uint24[] calldata eggIds) private view returns (bool) {
    unchecked {
      for (uint256 i = 0; i < eggIds.length; i++) {
        if (IEgg(egg).ownerOf(eggIds[i]) != msg.sender) {
          return false;
        }
      }
    }
    return true;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

library Strings {
  function toBytes32(string memory text) internal pure returns (bytes32) {
    return bytes32(bytes(text));
  }

  function toString(bytes32 text) internal pure returns (string memory) {
    return string(abi.encodePacked(text));
  }
}

contract Auth {
  //Address of current owner
  address public owner;
  //Address of new owner (Note: new owner must pull to be an owner)
  address public newOwner;
  //If paused or not
  uint256 private _paused;
  //Roles mapping (role => address => has role)
  mapping(bytes32 => mapping(address => bool)) private _roles;

  //Fires when a new owner is pushed
  event OwnerPushed(address indexed pushedOwner);
  //Fires when new owner pulled
  event OwnerPulled(address indexed previousOwner, address indexed newOwner);
  //Fires when account is granted role
  event RoleGranted(string indexed role, address indexed account, address indexed sender);
  //Fires when accoount is revoked role
  event RoleRevoked(string indexed role, address indexed account, address indexed sender);
  //Fires when pause is triggered by account
  event Paused(address account);
  //Fires when pause is lifted by account
  event Unpaused(address account);

  error Unauthorized(string role, address user);
  error IsPaused();
  error NotPaused();

  constructor() {
    owner = msg.sender;
    emit OwnerPulled(address(0), msg.sender);
  }

  modifier whenNotPaused() {
    if (paused()) revert IsPaused();
    _;
  }

  modifier whenPaused() {
    if (!paused()) revert NotPaused();
    _;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized("OWNER", msg.sender);
    _;
  }

  modifier onlyRole(string memory role) {
    if (!hasRole(role, msg.sender)) revert Unauthorized(role, msg.sender);
    _;
  }

  function hasRole(string memory role, address account) public view virtual returns (bool) {
    return _roles[Strings.toBytes32(role)][account];
  }

  function paused() public view virtual returns (bool) {
    return _paused == 1 ? true : false;
  }

  function pushOwner(address account) public virtual onlyOwner {
    require(account != address(0), "No address(0)");
    require(account != owner, "Only new owner");
    newOwner = account;
    emit OwnerPushed(account);
  }

  function pullOwner() public virtual {
    if (msg.sender != newOwner) revert Unauthorized("NEW_OWNER", msg.sender);
    address oldOwner = owner;
    owner = msg.sender;
    emit OwnerPulled(oldOwner, msg.sender);
  }

  function grantRole(string memory role, address account) public virtual onlyOwner {
    require(bytes(role).length > 0, "Role not given");
    require(account != address(0), "No address(0)");
    _grantRole(role, account);
  }

  function revokeRole(string memory role, address account) public virtual onlyOwner {
    require(hasRole(role, account), "Role not granted");
    _revokeRole(role, account);
  }

  function renounceRole(string memory role) public virtual {
    require(hasRole(role, msg.sender), "Role not granted");
    _revokeRole(role, msg.sender);
  }

  function pause() public virtual onlyRole("PAUSER") whenNotPaused {
    _paused = 1;
    emit Paused(msg.sender);
  }

  function unpause() public virtual onlyRole("PAUSER") whenPaused {
    _paused = 0;
    emit Unpaused(msg.sender);
  }

  function _grantRole(string memory role, address account) internal virtual {
    if (!hasRole(role, account)) {
      bytes32 encodedRole = Strings.toBytes32(role);
      _roles[encodedRole][account] = true;
      emit RoleGranted(role, account, msg.sender);
    }
  }

  function _revokeRole(string memory role, address account) internal virtual {
    bytes32 encodedRole = Strings.toBytes32(role);
    _roles[encodedRole][account] = false;
    emit RoleRevoked(role, account, msg.sender);
  }
}