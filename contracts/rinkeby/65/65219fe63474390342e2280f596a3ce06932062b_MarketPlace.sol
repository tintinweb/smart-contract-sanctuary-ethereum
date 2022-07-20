// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.4;

import './Interfaces.sol';
import './ZcToken.sol';
import './VaultTracker.sol';

contract MarketPlace {
  struct Market {
    address cTokenAddr;
    address zcTokenAddr;
    address vaultAddr;
    uint256 maturityRate;
  }

  mapping (address => mapping (uint256 => Market)) public markets;

  address public admin;
  address public swivel;
  bool public paused;

  event Create(address indexed underlying, uint256 indexed maturity, address cToken, address zcToken, address vaultTracker);
  event Mature(address indexed underlying, uint256 indexed maturity, uint256 maturityRate, uint256 matured);
  event RedeemZcToken(address indexed underlying, uint256 indexed maturity, address indexed sender, uint256 amount);
  event RedeemVaultInterest(address indexed underlying, uint256 indexed maturity, address indexed sender);
  event CustodialInitiate(address indexed underlying, uint256 indexed maturity, address zcTarget, address nTarget, uint256 amount);
  event CustodialExit(address indexed underlying, uint256 indexed maturity, address zcTarget, address nTarget, uint256 amount);
  event P2pZcTokenExchange(address indexed underlying, uint256 indexed maturity, address from, address to, uint256 amount);
  event P2pVaultExchange(address indexed underlying, uint256 indexed maturity, address from, address to, uint256 amount);
  event TransferVaultNotional(address indexed underlying, uint256 indexed maturity, address from, address to, uint256 amount);

  constructor() {
    admin = msg.sender;
  }

  /// @param s Address of the deployed swivel contract
  /// @notice We only allow this to be set once
  function setSwivelAddress(address s) external authorized(admin) returns (bool) {
    require(swivel == address(0), 'swivel contract address already set');
    swivel = s;
    return true;
  }

  /// @param a Address of a new admin
  function transferAdmin(address a) external authorized(admin) returns (bool) {
    admin = a;
    return true;
  }

  /// @notice Allows the owner to create new markets
  /// @param m Maturity timestamp of the new market
  /// @param c cToken address associated with underlying for the new market
  /// @param n Name of the new zcToken market
  /// @param s Symbol of the new zcToken market
  function createMarket(
    uint256 m,
    address c,
    string memory n,
    string memory s
  ) external authorized(admin) unpaused() returns (bool) {
    address swivelAddr = swivel;
    require(swivelAddr != address(0), 'swivel contract address not set');

    address underAddr = CErc20(c).underlying();
    require(markets[underAddr][m].vaultAddr == address(0), 'market already exists');

    uint8 decimals = Erc20(underAddr).decimals();
    address zcTokenAddr = address(new ZcToken(underAddr, m, n, s, decimals));
    address vaultAddr = address(new VaultTracker(m, c, swivelAddr));
    markets[underAddr][m] = Market(c, zcTokenAddr, vaultAddr, 0);

    emit Create(underAddr, m, c, zcTokenAddr, vaultAddr);

    return true;
  }

  /// @notice Can be called after maturity, allowing all of the zcTokens to earn floating interest on Compound until they release their funds
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  function matureMarket(address u, uint256 m) public unpaused() returns (bool) {
    Market memory mkt = markets[u][m];

    require(mkt.maturityRate == 0, 'market already matured');
    require(block.timestamp >= m, "maturity not reached");

    // set the base maturity cToken exchange rate at maturity to the current cToken exchange rate
    uint256 currentExchangeRate = CErc20(mkt.cTokenAddr).exchangeRateCurrent();
    markets[u][m].maturityRate = currentExchangeRate;

    require(VaultTracker(mkt.vaultAddr).matureVault(currentExchangeRate), 'mature vault failed');

    emit Mature(u, m, currentExchangeRate, block.timestamp);

    return true;
  }

  /// @notice Allows Swivel caller to deposit their underlying, in the process splitting it - minting both zcTokens and vault notional.
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param t Address of the depositing user
  /// @param a Amount of notional being added
  function mintZcTokenAddingNotional(address u, uint256 m, address t, uint256 a) external authorized(swivel) unpaused() returns (bool) {
    Market memory mkt = markets[u][m];
    require(ZcToken(mkt.zcTokenAddr).mint(t, a), 'mint zcToken failed');
    require(VaultTracker(mkt.vaultAddr).addNotional(t, a), 'add notional failed');
    
    return true;
  }

  /// @notice Allows Swivel caller to deposit/burn both zcTokens + vault notional. This process is "combining" the two and redeeming underlying.
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param t Address of the combining/redeeming user
  /// @param a Amount of zcTokens being burned
  function burnZcTokenRemovingNotional(address u, uint256 m, address t, uint256 a) external authorized(swivel) unpaused() returns(bool) {
    Market memory mkt = markets[u][m];
    require(ZcToken(mkt.zcTokenAddr).burn(t, a), 'burn failed');
    require(VaultTracker(mkt.vaultAddr).removeNotional(t, a), 'remove notional failed');
    
    return true;
  }

  /// @notice Allows (via swivel) zcToken holders to redeem their tokens for underlying tokens after maturity has been reached.
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param t Address of the redeeming user
  /// @param a Amount of zcTokens being redeemed
  function redeemZcToken(address u, uint256 m, address t, uint256 a) external authorized(swivel) unpaused() returns (uint256) {
    Market memory mkt = markets[u][m];

    // if the market has not matured, mature it and redeem exactly the amount
    if (mkt.maturityRate == 0) {
      require(matureMarket(u, m), 'failed to mature the market');
    }

    // burn user's zcTokens
    require(ZcToken(mkt.zcTokenAddr).burn(t, a), 'could not burn');

    emit RedeemZcToken(u, m, t, a);

    if (mkt.maturityRate == 0) {
      return a;
    } else { 
      // if the market was already mature the return should include the amount + marginal floating interest generated on Compound since maturity
      return calculateReturn(u, m, a);
    }
  }

  /// @notice Allows Vault owners (via Swivel) to redeem any currently accrued interest
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param t Address of the redeeming user
  function redeemVaultInterest(address u, uint256 m, address t) external authorized(swivel) unpaused() returns (uint256) {
    // call to the floating market contract to release the position and calculate the interest generated
    uint256 interest = VaultTracker(markets[u][m].vaultAddr).redeemInterest(t);

    emit RedeemVaultInterest(u, m, t);

    return interest;
  }

  /// @notice Calculates the total amount of underlying returned including interest generated since the `matureMarket` function has been called
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param a Amount of zcTokens being redeemed
  function calculateReturn(address u, uint256 m, uint256 a) internal returns (uint256) {
    Market memory mkt = markets[u][m];
    uint256 rate = CErc20(mkt.cTokenAddr).exchangeRateCurrent();

    return (a * rate) / mkt.maturityRate;
  }

  /// @notice Return the ctoken address for a given market
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  function cTokenAddress(address u, uint256 m) external view returns (address) {
    return markets[u][m].cTokenAddr;
  }

  /// @notice Called by swivel IVFZI && IZFVI
  /// @dev Call with underlying, maturity, mint-target, add-notional-target and an amount
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param z Recipient of the minted zcToken
  /// @param n Recipient of the added notional
  /// @param a Amount of zcToken minted and notional added
  function custodialInitiate(address u, uint256 m, address z, address n, uint256 a) external authorized(swivel) unpaused() returns (bool) {
    Market memory mkt = markets[u][m];
    require(ZcToken(mkt.zcTokenAddr).mint(z, a), 'mint failed');
    require(VaultTracker(mkt.vaultAddr).addNotional(n, a), 'add notional failed');
    emit CustodialInitiate(u, m, z, n, a);
    return true;
  }

  /// @notice Called by swivel EVFZE FF EZFVE
  /// @dev Call with underlying, maturity, burn-target, remove-notional-target and an amount
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param z Owner of the zcToken to be burned
  /// @param n Target to remove notional from
  /// @param a Amount of zcToken burned and notional removed
  function custodialExit(address u, uint256 m, address z, address n, uint256 a) external authorized(swivel) unpaused() returns (bool) {
    Market memory mkt = markets[u][m];
    require(ZcToken(mkt.zcTokenAddr).burn(z, a), 'burn failed');
    require(VaultTracker(mkt.vaultAddr).removeNotional(n, a), 'remove notional failed');
    emit CustodialExit(u, m, z, n, a);
    return true;
  }

  /// @notice Called by swivel IZFZE, EZFZI
  /// @dev Call with underlying, maturity, transfer-from, transfer-to, amount
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param f Owner of the zcToken to be burned
  /// @param t Target to be minted to
  /// @param a Amount of zcToken transfer
  function p2pZcTokenExchange(address u, uint256 m, address f, address t, uint256 a) external authorized(swivel) unpaused() returns (bool) {
    Market memory mkt = markets[u][m];
    require(ZcToken(mkt.zcTokenAddr).burn(f, a), 'zcToken burn failed');
    require(ZcToken(mkt.zcTokenAddr).mint(t, a), 'zcToken mint failed');
    emit P2pZcTokenExchange(u, m, f, t, a);
    return true;
  }

  /// @notice Called by swivel IVFVE, EVFVI
  /// @dev Call with underlying, maturity, remove-from, add-to, amount
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param f Owner of the notional to be transferred
  /// @param t Target to be transferred to
  /// @param a Amount of notional transfer
  function p2pVaultExchange(address u, uint256 m, address f, address t, uint256 a) external authorized(swivel) unpaused() returns (bool) {
    require(VaultTracker(markets[u][m].vaultAddr).transferNotionalFrom(f, t, a), 'transfer notional failed');
    emit P2pVaultExchange(u, m, f, t, a);
    return true;
  }

  /// @notice External method giving access to this functionality within a given vault
  /// @dev Note that this method calculates yield and interest as well
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param t Target to be transferred to
  /// @param a Amount of notional to be transferred
  function transferVaultNotional(address u, uint256 m, address t, uint256 a) external unpaused() returns (bool) {
    require(VaultTracker(markets[u][m].vaultAddr).transferNotionalFrom(msg.sender, t, a), 'vault transfer failed');
    emit TransferVaultNotional(u, m, msg.sender, t, a);
    return true;
  }

  /// @notice Transfers notional fee to the Swivel contract without recalculating marginal interest for from
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param f Owner of the amount
  /// @param a Amount to transfer
  function transferVaultNotionalFee(address u, uint256 m, address f, uint256 a) external authorized(swivel) returns (bool) {
    VaultTracker(markets[u][m].vaultAddr).transferNotionalFee(f, a);
    return true;
  }

  /// @notice Called by admin at any point to pause / unpause market transactions
  /// @param b Boolean which indicates the markets paused status
  function pause(bool b) external authorized(admin) returns (bool) {
    paused = b;
    return true;
  }

  modifier authorized(address a) {
    require(msg.sender == a, 'sender must be authorized');
    _;
  }

  modifier unpaused() {
    require(!paused, 'markets are paused');
    _;
  }
}