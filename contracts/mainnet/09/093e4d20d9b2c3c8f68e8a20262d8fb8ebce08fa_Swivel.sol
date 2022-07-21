// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.4;

import './Interfaces.sol';
import './Hash.sol';
import './Sig.sol';
import './Safe.sol';

contract Swivel {
  /// @dev maps the key of an order to a boolean indicating if an order was cancelled
  mapping (bytes32 => bool) public cancelled;
  /// @dev maps the key of an order to an amount representing its taken volume
  mapping (bytes32 => uint256) public filled;
  /// @dev maps a token address to a point in time, a hold, after which a withdrawal can be made
  mapping (address => uint256) public withdrawals;

  string constant public NAME = 'Swivel Finance';
  string constant public VERSION = '2.0.0';
  uint256 constant public HOLD = 3 days;
  bytes32 public immutable domain;
  address public immutable marketPlace;
  address public admin;
  uint16 constant public MIN_FEENOMINATOR = 33;
  /// @dev holds the fee demoninators for [zcTokenInitiate, zcTokenExit, vaultInitiate, vaultExit]
  uint16[4] public feenominators;

  /// @notice Emitted on order cancellation
  event Cancel (bytes32 indexed key, bytes32 hash);
  /// @notice Emitted on any initiate*
  /// @dev filled is 'principalFilled' when (vault:false, exit:false) && (vault:true, exit:true)
  /// @dev filled is 'premiumFilled' when (vault:true, exit:false) && (vault:false, exit:true)
  event Initiate(bytes32 indexed key, bytes32 hash, address indexed maker, bool vault, bool exit, address indexed sender, uint256 amount, uint256 filled);
  /// @notice Emitted on any exit*
  /// @dev filled is 'principalFilled' when (vault:false, exit:false) && (vault:true, exit:true)
  /// @dev filled is 'premiumFilled' when (vault:true, exit:false) && (vault:false, exit:true)
  event Exit(bytes32 indexed key, bytes32 hash, address indexed maker, bool vault, bool exit, address indexed sender, uint256 amount, uint256 filled);
  /// @notice Emitted on token withdrawal scheduling
  event ScheduleWithdrawal(address indexed token, uint256 hold);
  /// @notice Emitted on token withdrawal blocking
  event BlockWithdrawal(address indexed token);
  /// @notice Emitted on a change to the feenominators array
  event SetFee(uint256 indexed index, uint256 indexed feenominator);

  /// @param m deployed MarketPlace contract address
  /// @param v deployed contract address used as verifier
  constructor(address m, address v) {
    admin = msg.sender;
    domain = Hash.domain(NAME, VERSION, block.chainid, v);
    marketPlace = m;
    feenominators = [200, 600, 400, 200];
  }

  // ********* INITIATING *************

  /// @notice Allows a user to initiate a position
  /// @param o Array of offline Swivel.Orders
  /// @param a Array of order volume (principal) amounts relative to passed orders
  /// @param c Array of Components from valid ECDSA signatures
  function initiate(Hash.Order[] calldata o, uint256[] calldata a, Sig.Components[] calldata c) external returns (bool) {
    uint256 len = o.length;
    // for each order filled, routes the order to the right interaction depending on its params
    for (uint256 i; i < len; i++) {
      Hash.Order memory order = o[i];
      if (!order.exit) {
        if (!order.vault) {
          initiateVaultFillingZcTokenInitiate(o[i], a[i], c[i]);
        } else {
          initiateZcTokenFillingVaultInitiate(o[i], a[i], c[i]);
        }
      } else {
        if (!order.vault) {
          initiateZcTokenFillingZcTokenExit(o[i], a[i], c[i]);
        } else {
          initiateVaultFillingVaultExit(o[i], a[i], c[i]);
        }
      }
    }

    return true;
  }

  /// @notice Allows a user to initiate a Vault by filling an offline zcToken initiate order
  /// @dev This method should pass (underlying, maturity, maker, sender, principalFilled) to MarketPlace.custodialInitiate
  /// @param o Order being filled
  /// @param a Amount of volume (premium) being filled by the taker's initiate
  /// @param c Components of a valid ECDSA signature
  function initiateVaultFillingZcTokenInitiate(Hash.Order calldata o, uint256 a, Sig.Components calldata c) internal {
    // checks order signature, order cancellation and order expiry
    bytes32 hash = validOrderHash(o, c);

    // checks the side, and the amount compared to available
    require((a + filled[hash]) <= o.premium, 'taker amount > available volume');
    
    filled[hash] += a;

    // transfer underlying tokens
    Erc20 uToken = Erc20(o.underlying);
    Safe.transferFrom(uToken, msg.sender, o.maker, a);

    uint256 principalFilled = (a * o.principal) / o.premium;
    Safe.transferFrom(uToken, o.maker, address(this), principalFilled);

    MarketPlace mPlace = MarketPlace(marketPlace);
    // mint tokens
    require(CErc20(mPlace.cTokenAddress(o.underlying, o.maturity)).mint(principalFilled) == 0, 'minting CToken failed');
    // alert marketplace
    require(mPlace.custodialInitiate(o.underlying, o.maturity, o.maker, msg.sender, principalFilled), 'custodial initiate failed');

    // transfer fee in vault notional to swivel (from msg.sender)
    uint256 fee = principalFilled / feenominators[2];
    require(mPlace.transferVaultNotionalFee(o.underlying, o.maturity, msg.sender, fee), 'notional fee transfer failed');

    emit Initiate(o.key, hash, o.maker, o.vault, o.exit, msg.sender, a, principalFilled);
  }

  /// @notice Allows a user to initiate a zcToken by filling an offline vault initiate order
  /// @dev This method should pass (underlying, maturity, sender, maker, a) to MarketPlace.custodialInitiate
  /// @param o Order being filled
  /// @param a Amount of volume (principal) being filled by the taker's initiate
  /// @param c Components of a valid ECDSA signature
  function initiateZcTokenFillingVaultInitiate(Hash.Order calldata o, uint256 a, Sig.Components calldata c) internal {
    bytes32 hash = validOrderHash(o, c);

    require((a + filled[hash]) <= o.principal, 'taker amount > available volume');

    filled[hash] += a;

    Erc20 uToken = Erc20(o.underlying);

    uint256 premiumFilled = (a * o.premium) / o.principal;
    Safe.transferFrom(uToken, o.maker, msg.sender, premiumFilled);

    // transfer principal + fee in underlying to swivel (from sender)
    uint256 fee = premiumFilled / feenominators[0];
    Safe.transferFrom(uToken, msg.sender, address(this), (a + fee));

    MarketPlace mPlace = MarketPlace(marketPlace);
    // mint tokens
    require(CErc20(mPlace.cTokenAddress(o.underlying, o.maturity)).mint(a) == 0, 'minting CToken Failed');
    // alert marketplace 
    require(mPlace.custodialInitiate(o.underlying, o.maturity, msg.sender, o.maker, a), 'custodial initiate failed');

    emit Initiate(o.key, hash, o.maker, o.vault, o.exit, msg.sender, a, premiumFilled);
  }

  /// @notice Allows a user to initiate zcToken? by filling an offline zcToken exit order
  /// @dev This method should pass (underlying, maturity, maker, sender, a) to MarketPlace.p2pZcTokenExchange
  /// @param o Order being filled
  /// @param a Amount of volume (principal) being filled by the taker's initiate 
  /// @param c Components of a valid ECDSA signature
  function initiateZcTokenFillingZcTokenExit(Hash.Order calldata o, uint256 a, Sig.Components calldata c) internal {
    bytes32 hash = validOrderHash(o, c);

    require((a + filled[hash]) <= o.principal, 'taker amount > available volume');

    filled[hash] += a;

    uint256 premiumFilled = (a * o.premium) / o.principal;

    Erc20 uToken = Erc20(o.underlying);
    // transfer underlying tokens, then take fee
    Safe.transferFrom(uToken, msg.sender, o.maker, a - premiumFilled);

    uint256 fee = premiumFilled / feenominators[0];
    Safe.transferFrom(uToken, msg.sender, address(this), fee);

    // alert marketplace
    require(MarketPlace(marketPlace).p2pZcTokenExchange(o.underlying, o.maturity, o.maker, msg.sender, a), 'zcToken exchange failed');
            
    emit Initiate(o.key, hash, o.maker, o.vault, o.exit, msg.sender, a, premiumFilled);
  }

  /// @notice Allows a user to initiate a Vault by filling an offline vault exit order
  /// @dev This method should pass (underlying, maturity, maker, sender, principalFilled) to MarketPlace.p2pVaultExchange
  /// @param o Order being filled
  /// @param a Amount of volume (interest) being filled by the taker's exit
  /// @param c Components of a valid ECDSA signature
  function initiateVaultFillingVaultExit(Hash.Order calldata o, uint256 a, Sig.Components calldata c) internal {
    bytes32 hash = validOrderHash(o, c);

    require((a + filled[hash]) <= o.premium, 'taker amount > available volume');

    filled[hash] += a;

    Safe.transferFrom(Erc20(o.underlying), msg.sender, o.maker, a);

    MarketPlace mPlace = MarketPlace(marketPlace);
    uint256 principalFilled = (a * o.principal) / o.premium;
    // alert marketplace
    require(mPlace.p2pVaultExchange(o.underlying, o.maturity, o.maker, msg.sender, principalFilled), 'vault exchange failed');

    // transfer fee (in vault notional) to swivel
    uint256 fee = principalFilled / feenominators[2];
    require(mPlace.transferVaultNotionalFee(o.underlying, o.maturity, msg.sender, fee), "notional fee transfer failed");

    emit Initiate(o.key, hash, o.maker, o.vault, o.exit, msg.sender, a, principalFilled);
  }

  // ********* EXITING ***************

  /// @notice Allows a user to exit (sell) a currently held position to the marketplace.
  /// @param o Array of offline Swivel.Orders
  /// @param a Array of order volume (principal) amounts relative to passed orders
  /// @param c Components of a valid ECDSA signature
  function exit(Hash.Order[] calldata o, uint256[] calldata a, Sig.Components[] calldata c) external returns (bool) {
    uint256 len = o.length;
    // for each order filled, routes the order to the right interaction depending on its params
    for (uint256 i; i < len; i++) {
      Hash.Order memory order = o[i];
      // if the order being filled is not an exit
      if (!order.exit) {
        // if the order being filled is a vault initiate or a zcToken initiate
          if (!order.vault) {
            // if filling a zcToken initiate with an exit, one is exiting zcTokens
            exitZcTokenFillingZcTokenInitiate(o[i], a[i], c[i]);
          } else {
            // if filling a vault initiate with an exit, one is exiting vault notional
            exitVaultFillingVaultInitiate(o[i], a[i], c[i]);
          }
      } else {
        // if the order being filled is a vault exit or a zcToken exit
        if (!order.vault) {
          // if filling a zcToken exit with an exit, one is exiting vault
          exitVaultFillingZcTokenExit(o[i], a[i], c[i]);
        } else {
          // if filling a vault exit with an exit, one is exiting zcTokens
          exitZcTokenFillingVaultExit(o[i], a[i], c[i]);
        }   
      }   
    }

    return true;
  }

  /// @notice Allows a user to exit their zcTokens by filling an offline zcToken initiate order
  /// @dev This method should pass (underlying, maturity, sender, maker, principalFilled) to MarketPlace.p2pZcTokenExchange
  /// @param o Order being filled
  /// @param a Amount of volume (interest) being filled by the taker's exit
  /// @param c Components of a valid ECDSA signature
  function exitZcTokenFillingZcTokenInitiate(Hash.Order calldata o, uint256 a, Sig.Components calldata c) internal {
    bytes32 hash = validOrderHash(o, c);

    require((a + filled[hash]) <= o.premium, 'taker amount > available volume');

    filled[hash] += a;       

    Erc20 uToken = Erc20(o.underlying);

    uint256 principalFilled = (a * o.principal) / o.premium;
    // transfer underlying from initiating party to exiting party, minus the price the exit party pays for the exit (premium), and the fee.
    Safe.transferFrom(uToken, o.maker, msg.sender, principalFilled - a);

    // transfer fee in underlying to swivel
    uint256 fee = principalFilled / feenominators[1];
    Safe.transferFrom(uToken, msg.sender, address(this), fee);

    // alert marketplace
    require(MarketPlace(marketPlace).p2pZcTokenExchange(o.underlying, o.maturity, msg.sender, o.maker, principalFilled), 'zcToken exchange failed');

    emit Exit(o.key, hash, o.maker, o.vault, o.exit, msg.sender, a, principalFilled);
  }
  
  /// @notice Allows a user to exit their Vault by filling an offline vault initiate order
  /// @dev This method should pass (underlying, maturity, sender, maker, a) to MarketPlace.p2pVaultExchange
  /// @param o Order being filled
  /// @param a Amount of volume (principal) being filled by the taker's exit
  /// @param c Components of a valid ECDSA signature
  function exitVaultFillingVaultInitiate(Hash.Order calldata o, uint256 a, Sig.Components calldata c) internal {
    bytes32 hash = validOrderHash(o, c);

    require((a + filled[hash]) <= o.principal, 'taker amount > available volume');
    
    filled[hash] += a;
        
    Erc20 uToken = Erc20(o.underlying);

    // transfer premium from maker to sender
    uint256 premiumFilled = (a * o.premium) / o.principal;
    Safe.transferFrom(uToken, o.maker, msg.sender, premiumFilled);

    uint256 fee = premiumFilled / feenominators[3];
    // transfer fee in underlying to swivel from sender
    Safe.transferFrom(uToken, msg.sender, address(this), fee);

    // transfer <a> notional from sender to maker
    require(MarketPlace(marketPlace).p2pVaultExchange(o.underlying, o.maturity, msg.sender, o.maker, a), 'vault exchange failed');

    emit Exit(o.key, hash, o.maker, o.vault, o.exit, msg.sender, a, premiumFilled);
  }

  /// @notice Allows a user to exit their Vault filling an offline zcToken exit order
  /// @dev This method should pass (underlying, maturity, maker, sender, a) to MarketPlace.exitFillingExit
  /// @param o Order being filled
  /// @param a Amount of volume (principal) being filled by the taker's exit
  /// @param c Components of a valid ECDSA signature
  function exitVaultFillingZcTokenExit(Hash.Order calldata o, uint256 a, Sig.Components calldata c) internal {
    bytes32 hash = validOrderHash(o, c);

    require((a + filled[hash]) <= o.principal, 'taker amount > available volume');

    filled[hash] += a;

    // redeem underlying on Compound and burn cTokens
    MarketPlace mPlace = MarketPlace(marketPlace);
    address cTokenAddr = mPlace.cTokenAddress(o.underlying, o.maturity);
    require((CErc20(cTokenAddr).redeemUnderlying(a) == 0), "compound redemption error");

    Erc20 uToken = Erc20(o.underlying);
    // transfer principal-premium  back to fixed exit party now that the interest coupon and zcb have been redeemed
    uint256 premiumFilled = (a * o.premium) / o.principal;
    Safe.transfer(uToken, o.maker, a - premiumFilled);

    // transfer premium-fee to floating exit party
    uint256 fee = premiumFilled / feenominators[3];
    Safe.transfer(uToken, msg.sender, premiumFilled - fee);

    // burn zcTokens + nTokens from o.maker and msg.sender respectively
    require(mPlace.custodialExit(o.underlying, o.maturity, o.maker, msg.sender, a), 'custodial exit failed');

    emit Exit(o.key, hash, o.maker, o.vault, o.exit, msg.sender, a, premiumFilled);
  }

  /// @notice Allows a user to exit their zcTokens by filling an offline vault exit order
  /// @dev This method should pass (underlying, maturity, sender, maker, principalFilled) to MarketPlace.exitFillingExit
  /// @param o Order being filled
  /// @param a Amount of volume (interest) being filled by the taker's exit
  /// @param c Components of a valid ECDSA signature
  function exitZcTokenFillingVaultExit(Hash.Order calldata o, uint256 a, Sig.Components calldata c) internal {
    bytes32 hash = validOrderHash(o, c);

    require((a + filled[hash]) <= o.premium, 'taker amount > available volume');
    
    filled[hash] += a;

    // redeem underlying on Compound and burn cTokens
    MarketPlace mPlace = MarketPlace(marketPlace);

    address cTokenAddr = mPlace.cTokenAddress(o.underlying, o.maturity);
    uint256 principalFilled = (a * o.principal) / o.premium;
    require((CErc20(cTokenAddr).redeemUnderlying(principalFilled) == 0), "compound redemption error");

    Erc20 uToken = Erc20(o.underlying);
    // transfer principal-premium-fee back to fixed exit party now that the interest coupon and zcb have been redeemed
    uint256 fee = principalFilled / feenominators[1];
    Safe.transfer(uToken, msg.sender, principalFilled - a - fee);
    Safe.transfer(uToken, o.maker, a);

    // burn <principalFilled> zcTokens + nTokens from msg.sender and o.maker respectively
    require(mPlace.custodialExit(o.underlying, o.maturity, msg.sender, o.maker, principalFilled), 'custodial exit failed');

    emit Exit(o.key, hash, o.maker, o.vault, o.exit, msg.sender, a, principalFilled);
  }

  /// @notice Allows a user to cancel an order, preventing it from being filled in the future
  /// @param o Order being cancelled
  /// @param c Components of a valid ECDSA signature
  function cancel(Hash.Order calldata o, Sig.Components calldata c) external returns (bool) {
    bytes32 hash = validOrderHash(o, c);

    require(msg.sender == o.maker, 'sender must be maker');

    cancelled[hash] = true;

    emit Cancel(o.key, hash);

    return true;
  }

  // ********* ADMINISTRATIVE ***************

  /// @param a Address of a new admin
  function transferAdmin(address a) external authorized(admin) returns (bool) {
    admin = a;

    return true;
  }

  /// @notice Allows the admin to schedule the withdrawal of tokens
  /// @param e Address of (erc20) token to withdraw
  function scheduleWithdrawal(address e) external authorized(admin) returns (bool) {
    uint256 when = block.timestamp + HOLD;
    withdrawals[e] = when;

    emit ScheduleWithdrawal(e, when);

    return true;
  }

  /// @notice Emergency function to block unplanned withdrawals
  /// @param e Address of token withdrawal to block
  function blockWithdrawal(address e) external authorized(admin) returns (bool) {
      withdrawals[e] = 0;

      emit BlockWithdrawal(e);

      return true;
  }

  /// @notice Allows the admin to withdraw the given token, provided the holding period has been observed
  /// @param e Address of token to withdraw
  function withdraw(address e) external authorized(admin) returns (bool) {
    uint256 when = withdrawals[e];
    require (when != 0, 'no withdrawal scheduled');

    require (block.timestamp >= when, 'withdrawal still on hold');

    withdrawals[e] = 0;

    Erc20 token = Erc20(e);
    Safe.transfer(token, admin, token.balanceOf(address(this)));

    return true;
  }

  /// @notice Allows the admin to set a new fee denominator
  /// @param i The index of the new fee denominator
  /// @param d The new fee denominator
  function setFee(uint16 i, uint16 d) external authorized(admin) returns (bool) {
    require(d >= MIN_FEENOMINATOR, 'fee too high');

    feenominators[i] = d;

    emit SetFee(i, d);

    return true;
  }

  /// @notice Allows the admin to bulk approve given compound addresses at the underlying token, saving marginal approvals
  /// @param u array of underlying token addresses
  /// @param c array of compound token addresses
  function approveUnderlying(address[] calldata u, address[] calldata c) external authorized(admin) returns (bool) {
    uint256 len = u.length;
    require (len == c.length, 'array length mismatch');

    uint256 max = 2**256 - 1;

    for (uint256 i; i < len; i++) {
      Erc20 uToken = Erc20(u[i]);
      Safe.approve(uToken, c[i], max);
    }

    return true;
  }

  // ********* PROTOCOL UTILITY ***************

  /// @notice Allows users to deposit underlying and in the process split it into/mint 
  /// zcTokens and vault notional. Calls mPlace.mintZcTokenAddingNotional
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param a Amount of underlying being deposited
  function splitUnderlying(address u, uint256 m, uint256 a) external returns (bool) {
    Erc20 uToken = Erc20(u);
    Safe.transferFrom(uToken, msg.sender, address(this), a);
    MarketPlace mPlace = MarketPlace(marketPlace);
    require(CErc20(mPlace.cTokenAddress(u, m)).mint(a) == 0, 'minting CToken Failed');
    require(mPlace.mintZcTokenAddingNotional(u, m, msg.sender, a), 'mint ZcToken adding Notional failed');

    return true;
  }

  /// @notice Allows users deposit/burn 1-1 amounts of both zcTokens and vault notional,
  /// in the process "combining" the two, and redeeming underlying. Calls mPlace.burnZcTokenRemovingNotional.
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param a Amount of zcTokens being redeemed
  function combineTokens(address u, uint256 m, uint256 a) external returns (bool) {
    MarketPlace mPlace = MarketPlace(marketPlace);
    require(mPlace.burnZcTokenRemovingNotional(u, m, msg.sender, a), 'burn ZcToken removing Notional failed');
    address cTokenAddr = mPlace.cTokenAddress(u, m);
    require((CErc20(cTokenAddr).redeemUnderlying(a) == 0), "compound redemption error");
    Safe.transfer(Erc20(u), msg.sender, a);

    return true;
  }

  /// @notice Allows zcToken holders to redeem their tokens for underlying tokens after maturity has been reached (via MarketPlace).
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  /// @param a Amount of zcTokens being redeemed
  function redeemZcToken(address u, uint256 m, uint256 a) external returns (bool) {
    MarketPlace mPlace = MarketPlace(marketPlace);
    // call marketplace to determine the amount redeemed
    uint256 redeemed = mPlace.redeemZcToken(u, m, msg.sender, a);
    // redeem underlying from compound
    require(CErc20(mPlace.cTokenAddress(u, m)).redeemUnderlying(redeemed) == 0, 'compound redemption failed');
    // transfer underlying back to msg.sender
    Safe.transfer(Erc20(u), msg.sender, redeemed);

    return true;
  }

  /// @notice Allows Vault owners to redeem any currently accrued interest (via MarketPlace)
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  function redeemVaultInterest(address u, uint256 m) external returns (bool) {
    MarketPlace mPlace = MarketPlace(marketPlace);
    // call marketplace to determine the amount redeemed
    uint256 redeemed = mPlace.redeemVaultInterest(u, m, msg.sender);
    // redeem underlying from compound
    require(CErc20(mPlace.cTokenAddress(u, m)).redeemUnderlying(redeemed) == 0, 'compound redemption failed');
    // transfer underlying back to msg.sender
    Safe.transfer(Erc20(u), msg.sender, redeemed);

    return true;
  }

  /// @notice Allows Swivel to redeem any currently accrued interest (via MarketPlace)
  /// @param u Underlying token address associated with the market
  /// @param m Maturity timestamp of the market
  function redeemSwivelVaultInterest(address u, uint256 m) external returns (bool) {
    MarketPlace mPlace = MarketPlace(marketPlace);
    // call marketplace to determine the amount redeemed
    uint256 redeemed = mPlace.redeemVaultInterest(u, m, address(this));
    // redeem underlying from compound
    require(CErc20(mPlace.cTokenAddress(u, m)).redeemUnderlying(redeemed) == 0, 'compound redemption failed');
    // NOTE: for swivel redeem there is no transfer out as there is in redeemVaultInterest

    return true;
  }

  /// @notice Varifies the validity of an order and it's signature.
  /// @param o An offline Swivel.Order
  /// @param c Components of a valid ECDSA signature
  /// @return the hashed order.
  function validOrderHash(Hash.Order calldata o, Sig.Components calldata c) internal view returns (bytes32) {
    bytes32 hash = Hash.order(o);

    require(!cancelled[hash], 'order cancelled');
    require(o.expiry >= block.timestamp, 'order expired');
    require(o.maker == Sig.recover(Hash.message(domain, hash), c), 'invalid signature');

    return hash;
  }

  modifier authorized(address a) {
    require(msg.sender == a, 'sender must be authorized');
    _;
  }
}