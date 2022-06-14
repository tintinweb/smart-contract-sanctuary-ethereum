// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface InitializablePool {
  function initialize(address uniBurn, address uniswapPair) external;
}

interface IUniBurn {
  function burnWETH() external;
}

contract Redistributor {
  // Calldata
  uint256 internal constant ERC20_transferFrom_signature = (
    0x23b872dd00000000000000000000000000000000000000000000000000000000
  );
  uint256 internal constant ERC20_transferFrom_sig_ptr = 0x0;
  uint256 internal constant ERC20_transferFrom_from_ptr = 0x04;
  uint256 internal constant ERC20_transferFrom_to_ptr = 0x24;
  uint256 internal constant ERC20_transferFrom_amount_ptr = 0x44;
  uint256 internal constant ERC20_transferFrom_length = 0x64;

  uint256 internal constant ERC20_transferFrom_returndata_ptr = 0x44;
  uint256 internal constant ERC20_transferFrom_returndata_length = 0x20;

  // Treasury
  address internal constant Treasury = 0x78a3eF33cF033381FEB43ba4212f2Af5A5A0a2EA;

  // Machine state
  uint256 internal constant FreeMemoryPointerSlot = 0x40;
  uint256 internal constant ZeroSlot = 0x60;

  // LP burn contract
  address internal immutable uniBurn;

  // Pool addresses
  address internal constant defi5 = 0xfa6de2697D59E88Ed7Fc4dFE5A33daC43565ea41;
  address internal constant cc10 = 0x17aC188e09A7890a1844E5E65471fE8b0CcFadF3;
  address internal constant fff = 0xaBAfA52D3d5A2c18A4C1Ae24480D22B831fC0413;

  // Token addresses
  address internal constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address internal constant uni = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
  address internal constant aave = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
  address internal constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
  address internal constant snx = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
  address internal constant crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
  address internal constant mkr = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
  address internal constant sushi = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
  address internal constant yfi = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
  address internal constant uma = 0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828;
  address internal constant bat = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
  address internal constant omg = 0xd26114cd6EE289AccF82350c8d8487fedB8A0C07;
  address internal constant wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address internal constant degen = 0x126c121f99e1E211dF2e5f8De2d96Fa36647c855;

  constructor(address _uniBurn) {
    uniBurn = _uniBurn;
  }

  function restoreBalances() external {
    address _uniBurn = uniBurn;
    assembly {
      // Cache free memory pointer to restore after assembly block
      let memPointer := mload(FreeMemoryPointerSlot)
      // Write function selector and from address for ERC20.transferFrom
      // to calldata buffer in scratch space
      mstore(ERC20_transferFrom_sig_ptr, ERC20_transferFrom_signature)
      mstore(ERC20_transferFrom_from_ptr, Treasury)
      // Function to execute token transfer with current recipient
      function executeTransfer(token, amount) {
        // Write token amount to calldata buffer
        mstore(ERC20_transferFrom_amount_ptr, amount)
        // Make call & copy up to 32 bytes of return data
        let callStatus := call(
          gas(),
          token,
          0,
          ERC20_transferFrom_sig_ptr,
          ERC20_transferFrom_length,
          ERC20_transferFrom_returndata_ptr,
          ERC20_transferFrom_returndata_length
        )

        // Determine whether transfer was successful using status & result.
        if iszero(
          and(
            // Set success to whether the call reverted, if not check it
            // either returned exactly 1 (can't just be non-zero data), or
            // had no return data.
            or(
              and(
                eq(mload(ERC20_transferFrom_returndata_ptr), 1),
                gt(returndatasize(), 31)
              ),
              iszero(returndatasize())
            ),
            callStatus
          )
        ) {
          returndatacopy(0, 0, returndatasize())
          revert(0, returndatasize())
        }
      }

      // Restore defi5 underlying balances
      mstore(ERC20_transferFrom_to_ptr, defi5)
      executeTransfer(uni, 0x016369e53540bcbc1e27)
      executeTransfer(aave, 0x0d2be1248bae9513d2)
      executeTransfer(comp, 0x0833f5897bb9eeb379)
      executeTransfer(snx, 0x1df7abd4ddbeae7c57)
      executeTransfer(crv, 0x0272e24ba836f5cb4b03)
      executeTransfer(mkr, 0x996c11a09f7388a0)
      executeTransfer(sushi, 0x17eb5d4665b98343a481)

      // Restore cc10 underlying balances
      mstore(ERC20_transferFrom_to_ptr, cc10)
      executeTransfer(uni, 0x193dc30b99de3c32)
      executeTransfer(comp, 0x05c74d1abfdc801e)
      executeTransfer(snx, 0x8a09b419e2bd9491)
      executeTransfer(crv, 0x01ad44f2827f4b9718)
      executeTransfer(yfi, 0x090e17a411a7e8)
      executeTransfer(uma, 0x6f6919019e481bc7)
      executeTransfer(mkr, 0x8b693ab24d6315)
      executeTransfer(bat, 0x04d1be9d73c4c3d1fe)
      executeTransfer(sushi, 0xa0f2c9bc6835a4ca)
      executeTransfer(omg, 0x1c5b46af431169a51a)

      // Restore fff underlying balances
      mstore(ERC20_transferFrom_to_ptr, fff)
      executeTransfer(weth, 0x65c6f3c00d3dd975)
      executeTransfer(wbtc, 0x02daefe8)
      executeTransfer(degen, 0x010c0d3cd7a1f3ab127a)

      // Transfer WETH to UniBurn
      mstore(ERC20_transferFrom_to_ptr, _uniBurn)
      executeTransfer(weth, 0xee62d13a63f52d33)

      // Restore free memory pointer and zero slot
      mstore(FreeMemoryPointerSlot, memPointer)
      mstore(ZeroSlot, 0x0)
    }
    // Initialize pools
    InitializablePool(defi5).initialize(
      _uniBurn,
      0x8dCBa0B75c1038c4BaBBdc0Ff3bD9a8f6979Dd13
    );
    InitializablePool(cc10).initialize(
      _uniBurn,
      0x2701eA55b8B4f0FE46C15a0F560e9cf0C430f833
    );
    InitializablePool(fff).initialize(
      _uniBurn,
      0x9A60F0A46C1485D4BDA7750AdB0dB1b17Aa48A33
    );
    IUniBurn(_uniBurn).burnWETH();
  }
}