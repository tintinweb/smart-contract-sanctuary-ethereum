// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title LibSigUtils
 * @author Fujidao Labs
 * @notice Helper library for permit signing of the vault 'permitWithdraw' and
 * 'permitBorrow'.
 */

library LibSigUtils {
  // solhint-disable-next-line var-name-mixedcase
  bytes32 public constant PERMIT_WITHDRAW_TYPEHASH = keccak256(
    "PermitWithdraw(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)"
  );
  // solhint-disable-next-line var-name-mixedcase
  bytes32 public constant _PERMIT_BORROW_TYPEHASH = keccak256(
    "PermitBorrow(address owner,address spender,uint256 amount,uint256 nonce,uint256 deadline)"
  );

  struct Permit {
    address owner;
    address spender;
    uint256 amount;
    uint256 nonce;
    uint256 deadline;
  }

  function getStruct(
    address owner,
    address spender,
    uint256 amount,
    uint256 nonce,
    uint256 deadline,
    bytes32 hash
  ) public pure returns (bytes32) {
    return keccak256(
      abi.encode(
        hash,
        owner,
        spender,
        amount,
        nonce,
        deadline
      )
    );
  }

  // computes the hash of a permit-asset
  function getStructHashAsset(Permit memory permit) public pure returns (bytes32) {
    return keccak256(
      abi.encode(
        PERMIT_WITHDRAW_TYPEHASH,
        permit.owner,
        permit.spender,
        permit.amount,
        permit.nonce,
        permit.deadline
      )
    );
  }

  // computes the hash of a permit-borrow
  function getStructHashBorrow(Permit memory permit) public pure returns (bytes32) {
    return keccak256(
      abi.encode(
        _PERMIT_BORROW_TYPEHASH,
        permit.owner,
        permit.spender,
        permit.amount,
        permit.nonce,
        permit.deadline
      )
    );
  }

  // computes the digest
  function getHashTypedDataV4Digest(bytes32 domainSeperator, bytes32 structHash)
    external
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked("\x19\x01", domainSeperator, structHash));
  }
}