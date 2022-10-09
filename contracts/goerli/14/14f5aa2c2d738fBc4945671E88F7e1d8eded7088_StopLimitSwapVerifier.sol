// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

interface ICallExecutor {
  function proxyCall(address to, bytes memory data) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;
pragma abicoder v1;

/// @title Bit replay protection library
/// @notice Handles storage and loads for replay protection bits
/// @dev Solution adapted from https://github.com/PISAresearch/metamask-comp/blob/77fa8295c168ee0b6bf801cbedab797d6f8cfd5d/src/contracts/BitFlipMetaTransaction/README.md
/// @dev This is a gas optimized technique that stores up to 256 replay protection bits per bytes32 slot
library Bit {
  /// @dev Revert when bit provided is not valid
  error InvalidBit();

  /// @dev Revert when bit provided is used
  error BitUsed();

  /// @dev Initial pointer for bitmap storage ptr computation
  /// @notice This is the uint256 representation of keccak("bmp")
  uint256 constant INITIAL_BMP_PTR = 
  48874093989078844336340380824760280705349075126087700760297816282162649029611;

  /// @dev Adds a bit to the uint256 bitmap at bitmapIndex
  /// @dev Value of bit cannot be zero and must represent a single bit
  /// @param bitmapIndex The index of the uint256 bitmap
  /// @param bit The value of the bit within the uint256 bitmap
  function useBit(uint256 bitmapIndex, uint256 bit) internal {
    if (!validBit(bit)) {
      revert InvalidBit();
    }
    bytes32 ptr = bitmapPtr(bitmapIndex);
    uint256 bitmap = loadUint(ptr);
    if (bitmap & bit != 0) {
      revert BitUsed();
    }
    uint256 updatedBitmap = bitmap | bit;
    assembly { sstore(ptr, updatedBitmap) }
  }

  /// @dev Check that a bit is valid
  /// @param bit The bit to check
  /// @return isValid True if bit is greater than zero and represents a single bit
  function validBit(uint256 bit) internal pure returns (bool isValid) {
    assembly {
      // equivalent to: isValid = (bit > 0 && bit & bit-1) == 0;
      isValid := and(
        iszero(iszero(bit)), 
        iszero(and(bit, sub(bit, 1)))
      )
    } 
  }

  /// @dev Get a bitmap storage pointer
  /// @return The bytes32 pointer to the storage location of the uint256 bitmap at bitmapIndex
  function bitmapPtr (uint256 bitmapIndex) internal pure returns (bytes32) {
    return bytes32(INITIAL_BMP_PTR + bitmapIndex);
  }

  /// @dev Returns the uint256 value at storage location ptr
  /// @param ptr The storage location pointer
  /// @return val The uint256 value at storage location ptr
  function loadUint(bytes32 ptr) internal view returns (uint256 val) {
    assembly { val := sload(ptr) }
  }
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Oracle {
  uint constant public ONE_HUNDRED_PERCENT = 100;

  mapping(address => uint) public testPrices;

  function setPriceOf(address _token, uint _price) external {
    testPrices[_token] = _price;
  }

  function _isPriceValid(IERC20 tokenIn, IERC20 tokenOut, uint256 tokenInAmount, uint256 tokenOutAmount) internal returns(bool){
    uint totalInUSD;
    totalInUSD += (tokenInAmount * _getChainlinkPriceOf(tokenIn));

    uint usdReqOut = _getChainlinkPriceOf(tokenOut) * tokenOutAmount;

    return(totalInUSD >= usdReqOut);
  }

  function _getChainlinkPriceOf(IERC20 _token) internal returns(uint){
    return testPrices[address(_token)];
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Interfaces/ICallExecutor.sol";
import "./Libraries/Bit.sol";
import {Oracle} from "./Oracle.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Verifier for ERC20 limit swaps
/// @notice These functions should be executed by metaPartialSignedDelegateCall() on Brink account proxy contracts
contract StopLimitSwapVerifier is Oracle{
  /// @dev Revert when limit swap is expired
  error Expired();

  /// @dev Revert when swap has not received enough of the output asset to be fulfilled
  error NotEnoughReceived(uint256 amountReceived);

  event InvalidData();

  ICallExecutor internal immutable CALL_EXECUTOR;

  constructor(ICallExecutor callExecutor) {
    CALL_EXECUTOR = callExecutor;
  }

  /// @dev Executes an ERC20 to ERC20 limit swap
  /// @notice This should be executed by metaDelegateCall() or metaDelegateCall_EIP1271() with the following signed and unsigned params
  /// @param bitmapIndex The index of the replay bit's bytes32 slot [signed]
  /// @param bit The value of the replay bit [signed]
  /// @param tokenIn The input token provided for the swap [signed]
  /// @param tokenOut The output token required to be received from the swap [signed]
  /// @param tokenInAmount Amount of tokenIn provided [signed]
  /// @param tokenOutAmount Amount of tokenOut required to be received [signed]
  /// @param expiryBlock The block when the swap expires [signed]
  /// @param to Address of the contract that will fulfill the swap [unsigned]
  /// @param data Data to execute on the `to` contract to fulfill the swap [unsigned]
  function tokenToToken(
    uint256 bitmapIndex, uint256 bit, IERC20 tokenIn, IERC20 tokenOut, uint256 tokenInAmount, uint256 tokenOutAmount,
    uint256 expiryBlock, address recipient, address to, bytes calldata data
  )
    external
  {
    // Oracle Check
    require(_isPriceValid(tokenIn, tokenOut, tokenInAmount, tokenOutAmount), "Price too high");

    if (expiryBlock <= block.number) {
      revert Expired();
    }
  
    Bit.useBit(bitmapIndex, bit);

    address owner = proxyOwner();

    uint256 tokenOutBalance = tokenOut.balanceOf(owner);

    tokenIn.transferFrom(owner, recipient, tokenInAmount);

    CALL_EXECUTOR.proxyCall(to, data);

    uint256 tokenOutAmountReceived = tokenOut.balanceOf(owner) - tokenOutBalance;

    // todo find out what this is all about
    if (tokenOutAmountReceived < tokenOutAmount) {
      revert NotEnoughReceived(tokenOutAmountReceived);
    }
  }

  /// @dev Returns the owner address for the proxy
  /// @return _proxyOwner The owner address for the proxy
  function proxyOwner() internal view returns (address _proxyOwner) {
    assembly {
      // copies to "scratch space" 0 memory pointer
      extcodecopy(address(), 0, 0x28, 0x14)
      _proxyOwner := shr(0x60, mload(0))
    }
  }

    fallback() external{
    emit InvalidData();
  }


}