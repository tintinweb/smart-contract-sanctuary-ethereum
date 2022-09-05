// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

import {IERC20} from './interfaces/IERC20.sol';
import {ICollectorController} from './interfaces/ICollectorController.sol';
import {IProposalGenericExecutor} from './IProposalGenericExecutor.sol';

contract EthereumProposalPayload is IProposalGenericExecutor {
  address public constant AAVE_COMPANIES_ADDRESS = 0x1c037b3C22240048807cC9d7111be5d455F640bd;

  ICollectorController public constant CONTROLLER_OF_COLLECTOR =
    ICollectorController(0x3d569673dAa0575c936c7c67c4E6AedA69CC630C);

  address public constant COLLECTOR_ADDRESS = 0x464C71f6c2F760DdA6093dCB91C24c39e5d6e18c;
  address public constant ECOSYSTEM_RESERVE_ADDRESS = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;

  IERC20 public constant AAVE = IERC20(0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9);
  uint256 public constant AAVE_AMOUNT = 76196367343821000000000; // 76196.367343821000000000 AAVE

  function execute() external override {
    address[3] memory STABLES = [
      0xBcca60bB61934080951369a648Fb03DF4F96263C, // aUSDC
      0x3Ed3B47Dd13EC9a98b44e6204A523E766B225811, // aUSDT
      0x028171bCA77440897B824Ca71D1c56caC55b68A3 // aDAI
    ];

    uint256[] memory STABLES_AMOUNTS = new uint256[](3);
    STABLES_AMOUNTS[0] = 2783066720000; // 2783066.720000 aUSDC
    STABLES_AMOUNTS[1] = 1036828780000; // 1036828.780000 aUSDT
    STABLES_AMOUNTS[2] = 1637098070000000000000000; // 1637098.070000000000000000 aDAI

    address[8] memory ALT_STABLES = [
      0x6C5024Cd4F8A59110119C56f8933403A539555EB, // aSUSD
      0x101cc05f4A51C0319f570d5E146a8C625198e636, // aTUSD
      0x0000000000085d4780B73119b644AE5ecd22b376, // TUSD
      0xd4937682df3C8aEF4FE912A96A74121C0829E664, // aFRAX
      0xA361718326c15715591c299427c62086F69923D9, // aBUSD
      0x4Fabb145d64652a948d72533023f6E7A623C7C53, // BUSD
      0xD37EE7e4f452C6638c96536e68090De8cBcdb583, // aGUSD
      0x2e8F4bdbE3d47d7d7DE490437AeA9915D930F1A3 // aUSDP
    ];

    uint256[] memory ALT_STABLES_AMOUNTS = new uint256[](8);
    ALT_STABLES_AMOUNTS[0] = 463358329101236000000000; // 463358.329101236000000000 aSUSD
    ALT_STABLES_AMOUNTS[1] = 292927660000000000000000; // 292927.660000000000000000 aTUSD
    ALT_STABLES_AMOUNTS[2] = 88141398944950200000; // 88.141398944950200000 TUSD
    ALT_STABLES_AMOUNTS[3] = 154992100000000000000000; // 154992.100000000000000000 aFRAX
    ALT_STABLES_AMOUNTS[4] = 130399257102886000000000; // 130399.257102886000000000 aBUSD
    ALT_STABLES_AMOUNTS[5] = 350362897113999000000; // 350.362897113999000000 BUSD
    ALT_STABLES_AMOUNTS[6] = 8635430; // 86354.30 aGUSD
    ALT_STABLES_AMOUNTS[7] = 26871320000000000000000; // 26871.320000000000000000 aPAX

    address[19] memory VOLATILE_ASSETS = [
      0x8dAE6Cb04688C62d939ed9B68d32Bc62e49970b1, // aCRV
      0x030bA81f1c18d280636F32af80b9AAd02Cf0854e, // aWETH
      0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656, // aWBTC
      0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, // WBTC
      0x35f6B052C598d933D69A4EEC4D04c73A191fE6c2, // aSNX
      0xc9BC48c72154ef3e5425641a3c747242112a46AF, // aRAI
      0xa685a61171bb30d4072B338c80Cb7b2c865c873E, // aMANA
      0xa06bC25B5805d5F8d82847D191Cb4Af5A3e873E0, // aLINK
      0x5165d24277cD063F5ac44Efd447B27025e888f37, // aYFI
      0x952749E07d7157bb9644A894dFAF3Bad5eF6D918, // aCVX
      0xc713e5E149D5D0715DcD1c156a020976e7E56B88, // aMKR
      0x39C6b3e42d6A679d7D776778Fe880BC9487C2EDA, // aKNC
      0xdd974D5C2e2928deA5F71b9825b8b646686BD200, // KNC
      0xB9D7CB55f463405CDfBe4E90a6D2Df01C2B92BF1, // aUNI
      0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, // UNI
      0xaC6Df26a590F08dcC95D5a4705ae8abbc88509Ef, // aENJ
      0xF256CC7847E919FAc9B808cC216cAc87CCF2f47a, // aXSUSHI
      0x05Ec93c0365baAeAbF7AefFb0972ea7ECdD39CF1, // aBAT
      0xCC12AbE4ff81c9378D670De1b57F8e0Dd228D77a // aREN
    ];

    uint256[] memory VOLATILE_ASSETS_AMOUNTS = new uint256[](19);
    VOLATILE_ASSETS_AMOUNTS[0] = 509732680000000000000000; // 509732.680000000000000000 aCRV
    VOLATILE_ASSETS_AMOUNTS[1] = 350000000000000000000; // 350.000000000000000000 aWETH
    VOLATILE_ASSETS_AMOUNTS[2] = 338855085; // 3.38855085 aWBTC
    VOLATILE_ASSETS_AMOUNTS[3] = 44577014; // 0.44577014 WBTC
    VOLATILE_ASSETS_AMOUNTS[4] = 96251920000000000000000; // 96251.920000000000000000 aSNX
    VOLATILE_ASSETS_AMOUNTS[5] = 66094610000000000000000; // 66094.610000000000000000 aRAI
    VOLATILE_ASSETS_AMOUNTS[6] = 103234630000000000000000; // 103234.630000000000000000 aMANA
    VOLATILE_ASSETS_AMOUNTS[7] = 12053480000000000000000; // 12053.480000000000000000 aLINK
    VOLATILE_ASSETS_AMOUNTS[8] = 7080000000000000000; // 7.080000000000000000 aYFI
    VOLATILE_ASSETS_AMOUNTS[9] = 5137260000000000000000; // 5137.260000000000000000 aCVX
    VOLATILE_ASSETS_AMOUNTS[10] = 30360000000000000000; // 30.360000000000000000 aMKR
    VOLATILE_ASSETS_AMOUNTS[11] = 11236269638020000000000; // 11236.269638020000000000 aKNC
    VOLATILE_ASSETS_AMOUNTS[12] = 795220361980000000000; // 795.220361980000000000 KNC
    VOLATILE_ASSETS_AMOUNTS[13] = 1681265487372400000000; // 1681.265487372400000000 aUNI
    VOLATILE_ASSETS_AMOUNTS[14] = 4394512627600080000; // 4.394512627600080000 UNI
    VOLATILE_ASSETS_AMOUNTS[15] = 7242480000000000000000; // 7242.480000000000000000 aENJ
    VOLATILE_ASSETS_AMOUNTS[16] = 2331216007307700000000; // 2331.216007307700000000 aXSUSHI
    VOLATILE_ASSETS_AMOUNTS[17] = 6395160000000000000000; // 6395.160000000000000000 aBAT
    VOLATILE_ASSETS_AMOUNTS[18] = 15300170000000000000000; // 15300.170000000000000000 aREN

    // 1. Transfer AAVE
    CONTROLLER_OF_COLLECTOR.transfer(
      ECOSYSTEM_RESERVE_ADDRESS,
      AAVE,
      AAVE_COMPANIES_ADDRESS,
      AAVE_AMOUNT
    );

    // 2. Transfer stables
    for (uint256 i = 0; i < STABLES.length; i++) {
      CONTROLLER_OF_COLLECTOR.transfer(
        COLLECTOR_ADDRESS,
        IERC20(STABLES[i]),
        AAVE_COMPANIES_ADDRESS,
        STABLES_AMOUNTS[i]
      );
    }

    // 3. Transfer alternative stables
    for (uint256 i = 0; i < ALT_STABLES.length; i++) {
      CONTROLLER_OF_COLLECTOR.transfer(
        COLLECTOR_ADDRESS,
        IERC20(ALT_STABLES[i]),
        AAVE_COMPANIES_ADDRESS,
        ALT_STABLES_AMOUNTS[i]
      );
    }

    // 4. Transfer volatile assets
    for (uint256 i = 0; i < VOLATILE_ASSETS.length; i++) {
      CONTROLLER_OF_COLLECTOR.transfer(
        COLLECTOR_ADDRESS,
        IERC20(VOLATILE_ASSETS[i]),
        AAVE_COMPANIES_ADDRESS,
        VOLATILE_ASSETS_AMOUNTS[i]
      );
    }

    emit ProposalExecuted();
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from './IERC20.sol';

interface ICollectorController {
  /**
   * @dev Transfer an amount of tokens to the recipient.
   * @param collector The address of the collector contract to retrieve funds from (e.g. Aave ecosystem reserve)
   * @param token The address of the asset
   * @param recipient The address of the entity to transfer the tokens.
   * @param amount The amount to be transferred.
   */
  function transfer(
    address collector,
    IERC20 token,
    address recipient,
    uint256 amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IProposalGenericExecutor {
  function execute() external;

  event ProposalExecuted();
}