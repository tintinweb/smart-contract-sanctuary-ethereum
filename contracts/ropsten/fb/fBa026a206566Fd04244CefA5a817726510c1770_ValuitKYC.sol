// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import './Ownable.sol';
import './interfaces/IKYC.sol';

contract ValuitKYC is IKYC, Ownable {
  
  mapping(bytes32 => address[]) internal userWallets;
  mapping(bytes32 => bool) public override kycApproved;
  mapping(address => bytes32) internal whitelisted;

  event Register(bytes32 indexed userid, address indexed wallet);
  event Approve(bytes32 indexed userid);
  event Revoke(bytes32 indexed userid);
  /**
   * @dev get list of registered wallet for an user
   * @param userid User's IPFS hash
   */
  function getUserWallets(bytes32 userid) external view override returns (address[] memory) {
    address[] memory wallets = userWallets[userid];
    return wallets;
  }
  /**
   * @dev Get Owner IPFS hash for a whitelisted wallet
   * @param wallet User's Wallet Address
   */
  function getWalletOwner(address wallet) external view override returns (bytes32) {
    return whitelisted[wallet];
  }
  /**
   * @dev Register a new user
   * @param userIpfsHash User's IPFS hash
   * @param wallet User's Wallet Address
   */
  function registerUser(bytes32 userIpfsHash, address wallet) public override {
    addUserWallet(userIpfsHash, wallet);
    emit Register(userIpfsHash, wallet);
  }
  /**
   * @dev Add a wallet for a user
   * @param userIpfsHash User's IPFS hash
   * @param wallet User's Wallet Address
   */
  function addUserWallet(bytes32 userIpfsHash, address wallet) public {
    require(wallet != address(0), 'ZERO Wallet address');
    require(userIpfsHash != "", 'IPFS hash empty');
    userWallets[userIpfsHash].push(wallet);
    if(kycApproved[userIpfsHash]) {
      whitelisted[wallet] = userIpfsHash;
    }
  }
  /**
   * @dev Approve KYC of an user
   * @param userid User's IPFS hash
   */
  function approveKyc(bytes32 userid) public override onlyOwner {
    require(userid != "", 'Approve: IPFS hash empty');
    kycApproved[userid] = true;
    address[] memory wallets = userWallets[userid];
    for(uint16 i=0; i < wallets.length; i++) {
      whitelisted[wallets[i]] = userid;
    }
    emit Approve(userid);
  }
  /**
   * @dev Revoke KYC of an user
   * @param userid User's IPFS hash
   */
  function revokeKyc(bytes32 userid) external override onlyOwner {
    require(userid != "", 'Revoke: IPFS hash empty');
    require(kycApproved[userid], 'User not KYC Approved');
    kycApproved[userid] = false;
    address[] memory wallets = userWallets[userid];
    for(uint16 i=0; i < wallets.length; i++) {
      whitelisted[wallets[i]] = "";
    }
    emit Revoke(userid);
  }
  /**
   * @dev Check if wallet address is whitelisted or not
   * @param wallet User's Wallet Address
   */
  function isWhitelisted(address wallet) external view override returns (bool) {
    if(whitelisted[wallet] != "") return true;
    return false;
  }
  /**
   * @dev Add wallet address to Whitelist for a User
   * @param userid User's IPFS hash
   * @param wallet User's Wallet Address
   */
  function addWalletToWhitelist(bytes32 userid, address wallet) external onlyOwner {
    require(wallet != address(0), 'Invalid wallet address');
    require(kycApproved[userid], 'User KYC not Approved');
    addUserWallet(userid, wallet);
  }
  /**
   * @dev Add wallet addresses to Whitelist for a User
   * @param userid User's IPFS hash
   * @param wallets User's Wallet Addresses
   */
  function addWalletsToWhitelist(bytes32 userid, address[] memory wallets) external onlyOwner {
    require(kycApproved[userid], 'User KYC not Approved');
    for(uint16 i=0; i < wallets.length; i++) {
      addUserWallet(userid, wallets[i]);
    }
  }
  /**
   * @dev Remove wallet address from Whitelist
   * @param wallet User's Wallet Address
   */
  function removeWalletFromWhitelist(address wallet) external override onlyOwner {
    require(wallet != address(0), 'Invalid wallet address');
    whitelisted[wallet] = "";
  }
  /**
   * @dev Remove wallet addresses from Whitelist
   * @param wallets User's Wallet Addresses
   */
  function removeWalletsFromWhitelist(address[] memory wallets) external onlyOwner {
    for(uint16 i=0; i < wallets.length; i++) {
      whitelisted[wallets[i]] = "";
    }
  }
  /**
   * @dev Register a new user & auto approve user wallet. Created while KYC process is there
   * @param userIpfsHash User's IPFS hash
   * @param wallet User's Wallet Addresses
   */
  function registerUserWithAutoApproval(bytes32 userIpfsHash, address wallet) external onlyOwner {
    registerUser(userIpfsHash, wallet);
    approveKyc(userIpfsHash);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

interface IKYC {
  function kycApproved(bytes32 userid) external view returns (bool);
  function getUserWallets(bytes32 userid) external view returns (address[] memory);
  function isWhitelisted(address wallet) external view returns (bool);
  function getWalletOwner(address wallet) external view returns (bytes32);
  function removeWalletFromWhitelist(address wallet) external;
  function registerUser(bytes32 userIpfsHash, address wallet) external;
  function approveKyc(bytes32 userid) external;
  function revokeKyc(bytes32 userid) external;
}