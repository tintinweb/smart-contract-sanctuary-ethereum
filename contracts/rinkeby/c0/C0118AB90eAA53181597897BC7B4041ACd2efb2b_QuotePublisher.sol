// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IERC20.sol";
import "./libraries/QVerifier.sol";

contract QuotePublisher {
  
  /// @notice Emitted when a Quoter posts a Quote
  event Quote(
              address marketAddress,
              address quoter,
              uint8 quoteType,
              uint8 side,
              uint64 quoteExpiryTime, //if 0, then quote never expires
              uint64 APR,
              uint cashflow,
              uint nonce,
              bytes signature              
              );


  /// @notice Allows Quoter to publish a Quote onchain as an event
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR In decimal form scaled by 1e4 (ex. 10.52% = 1052)
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @param signature Signed hash of the Quote message
  function createQuote(
                       address marketAddress,
                       address quoter,
                       uint8 quoteType,
                       uint8 side,
                       uint64 quoteExpiryTime,
                       uint64 APR,
                       uint cashflow,
                       uint nonce,
                       bytes memory signature
                       ) external {

    address signer = QVerifier.getSigner(
                                         marketAddress,
                                         quoter,
                                         quoteType,
                                         side,
                                         quoteExpiryTime,
                                         APR,
                                         cashflow,
                                         nonce,
                                         signature
                                         );

    // Author of the signature must match the address of the quoter
    require(signer == quoter, "signature mismatch");

    // `cashflow` must be positive
    require(cashflow > 0, "invalid cashflow size");

    // Only {0,1} are valid `quoteType`s. 0 for PV+APR, for FV+APR
    require(quoteType <= 1, "invalid type");
    
    // Only {0,1} are valid `side`s. 0 if Quoter is borrower, 1 if Quoter is lender
    require(side <= 1, "invalid side");
    
    // Quote must not be expired. `quoteExpiryTime` of 0 indicates never expiring
    require(quoteExpiryTime == 0 || quoteExpiryTime > block.timestamp, "invalid expiry time");

    //TODO checks on user balance / collatera / allowances before being able to publish quote
    
    emit Quote(
               marketAddress,
               quoter,
               quoteType,
               side,
               quoteExpiryTime,
               APR,
               cashflow,
               nonce,
               signature
               );                  
  }
  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QVerifier {

  /// @notice Recover the signer of a Quote given the plaintext inputs and signature
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR Annualized simple interest, scaled by 1e2
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @param signature Signed hash of the Quote message
  /// @return address Signer of the message
  function getSigner(
                     address marketAddress,
                     address quoter,
                     uint8 quoteType,
                     uint8 side,
                     uint64 quoteExpiryTime,
                     uint64 APR,
                     uint cashflow,
                     uint nonce,
                     bytes memory signature
                     ) internal pure returns(address){
    bytes32 messageHash = getMessageHash(
                                         marketAddress,
                                         quoter,
                                         quoteType,
                                         side,
                                         quoteExpiryTime,
                                         APR,
                                         cashflow,
                                         nonce
                                         );
    return  _recoverSigner(messageHash, signature);    
  }

  /// @notice Hashes the fields of a Quote into an Ethereum message hash
  /// @param marketAddress Address of `FixedRateLoanMarket` contract
  /// @param quoter Account of the Quoter
  /// @param quoteType 0 for PV+APR, 1 for FV+APR
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param APR Annualized simple interest, scaled by 1e2
  /// @param cashflow Can be PV or FV depending on `quoteType`
  /// @param nonce For uniqueness of signature
  /// @return bytes32 Message hash
  function getMessageHash(
                          address marketAddress,
                          address quoter,
                          uint8 quoteType,
                          uint8 side,
                          uint64 quoteExpiryTime,
                          uint64 APR,
                          uint cashflow,
                          uint nonce
                          ) internal pure returns(bytes32) {
    bytes32 unprefixedHash = keccak256(abi.encodePacked(
                                                        marketAddress,
                                                        quoter,
                                                        quoteType,
                                                        side,
                                                        quoteExpiryTime,
                                                        APR,
                                                        cashflow,
                                                        nonce
                                                        ));
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", unprefixedHash)); 
  }

  /// @notice Recovers the address of the signer of the `messageHash` from the
  /// signature. It should be used to check versus the cleartext address given
  /// to verify the message is indeed signed by the owner.
  /// @param messageHash Hash of the loan fields
  /// @param signature The candidate signature to recover the signer from
  /// @return address This is the recovered signer of the `messageHash` using the signature
  function _recoverSigner(
                         bytes32 messageHash,
                         bytes memory signature
                         ) private pure returns(address) {
    (bytes32 r, bytes32 s, uint8 v) = _splitSignature(signature);
    
    //built-in solidity function to recover the signer address using
    // the messageHash and signature
    return ecrecover(messageHash, v, r, s);
  }

  
  /// @notice Helper function that splits the signature into r,s,v components
  /// @param signature The candidate signature to recover the signer from
  /// @return r bytes32, s bytes32, v uint8
  function _splitSignature(bytes memory signature) private pure returns(
                                                                      bytes32 r,
                                                                      bytes32 s,
                                                                      uint8 v) {
    require(signature.length == 65, "invalid signature length");
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }
  }
}