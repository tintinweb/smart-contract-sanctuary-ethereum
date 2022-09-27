/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// File: contracts/Owner.sol


pragma solidity >=0.8.14;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {
  address private owner;

  // event for EVM logging
  event OwnerSet(address indexed oldOwner, address indexed newOwner);

  // modifier to check if caller is owner
  modifier isOwner() {
    // If the first argument of 'require' evaluates to 'false', execution terminates and all
    // changes to the state and to Ether balances are reverted.
    // This used to consume all gas in old EVM versions, but not anymore.
    // It is often a good idea to use 'require' to check if functions are called correctly.
    // As a second argument, you can also provide an explanation about what went wrong.
    require(msg.sender == owner, "Caller is not owner");
    _;
  }

  /**
   * @dev Set contract deployer as owner
   */
  constructor() {
    owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    emit OwnerSet(address(0), owner);
  }

  /**
   * @dev Change owner
   * @param newOwner address of new owner
   */
  function changeOwner(address newOwner) public isOwner {
    emit OwnerSet(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Return owner address
   * @return address of owner
   */
  function getOwner() external view returns (address) {
    return owner;
  }
}

// File: contracts/WalletManagement.sol


pragma solidity >=0.8.14;


contract WalletManagement is Owner {
  // ========= STRUCT ========= //
  struct WalletConfig {
    address wallet;
    string roundId;
  }
  struct WalletConfigInput {
    string key;
    WalletConfig config;
  }

  // ========= STATE VARIABLE ========= //
  mapping(string => WalletConfig) public wallets;

  // ========= EVENT ========= //
  event WalletAdded(address wallet, string roundId, string key);
  event WalletRemoved(address wallet, string roundId, string key);
  event WalletUpdated(address wallet, string roundId, string key);

  function addWallets(WalletConfigInput[] calldata _walletConfigs)
    external
    isOwner
  {
    for (uint256 i = 0; i < _walletConfigs.length; i++) {
      WalletConfigInput memory walletConfig = _walletConfigs[i];
      wallets[walletConfig.key] = walletConfig.config;
      emit WalletAdded(walletConfig.config.wallet, walletConfig.config.roundId, walletConfig.key);
    }
  }

  function removeWallets(string[] calldata _keys, string calldata roundId) external isOwner {
    for (uint256 i = 0; i < _keys.length; i++) {
      WalletConfig memory walletConfig = wallets[_keys[i]];
      delete wallets[_keys[i]];
      emit WalletRemoved(walletConfig.wallet, roundId, _keys[i]);
    }
  }

  function updateWallet(string calldata _key, WalletConfig calldata _config)
    external
    isOwner
  {
    wallets[_key] = _config;
    emit WalletUpdated(_config.wallet, _config.roundId, _key);
  }
}