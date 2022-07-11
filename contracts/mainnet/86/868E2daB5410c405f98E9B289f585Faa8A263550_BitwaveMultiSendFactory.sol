// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./BitwaveMultiSend.sol";


/// @title A factory contract for Multi-Send contracts.
/// @author Bitwave
/// @author Inish Crisson
/// @notice Now with support for fallback functions.
contract BitwaveMultiSendFactory {

    mapping(address => address) public multiSendAddressMap;
    event newMultiSend(address owner, address multiPayChild);
    uint8 public bwChainId;

    constructor(uint8 _bwChainId) {
        bwChainId = _bwChainId;
    }

/// @notice Deploys a new Bitwave Multi-Send Contract
/// @return newBitwaveMultiSend The address of the deployed contract.
    function deployNewMultiSend() public returns (address) {
        require (multiSendAddressMap[msg.sender] == address(0x0));
        BitwaveMultiSend newBitwaveMultiSend = new BitwaveMultiSend(msg.sender, bwChainId);
        multiSendAddressMap[msg.sender] = address(newBitwaveMultiSend);
        emit newMultiSend(msg.sender, address(newBitwaveMultiSend));
        return (address(newBitwaveMultiSend));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title A multi-send contract for ERC-20 tokens and ETH.
/// @author Bitwave
/// @author Pat White
/// @author Inish Crisson
/// @notice Now with support for fallback functions. 
/// @notice This is intended to be deployed by a factory contract, hence why "owner" has been paramaterised. 
contract BitwaveMultiSend is ReentrancyGuard {
  
  address public owner;

  // A uint to produce a unique ID for each transaction.
  uint32 public paymentCount;
  uint8 public bwChainId;

  constructor(address _owner, uint8 _bwChainId) {
    owner = _owner;
    bwChainId = _bwChainId;
  }

  modifier restrictedToOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        _;
  }

  event multiSendPaymentExecuted(bytes id);

/// @notice Sends Eth to an array of addresses according to the values in a uint array.
/// @param _to An array of addresses to be paid.
/// @param _value An array of values to be paid to "_to" addresses.
/// @return _success A bool to indicate transaction success.
  function sendEth(address payable [] memory _to, uint256[] memory _value) public restrictedToOwner nonReentrant payable returns (bool _success) {
        // input validation
        require(_to.length == _value.length);
        require(_to.length <= 255);

        // count values for refunding sender
        uint256 beforeValue = msg.value;
        uint256 afterValue = 0;

        // Generate a unique ID for this transaction.
        emit multiSendPaymentExecuted(abi.encodePacked(address(this), paymentCount++, uint8(_value.length), bwChainId));

        // loop through to addresses and send value
        for (uint8 i = 0; i < _to.length; i++) {
            afterValue = afterValue + (_value[i]);
            (bool sent, ) = _to[i].call{value: _value[i]}("");
            require(sent, "Failed to send Ether");
        }

        // send back remaining value to sender
        uint256 remainingValue = beforeValue - afterValue;
        if (remainingValue > 0) {
            (bool sent, ) = owner.call{value: remainingValue}("");
            require(sent, "Failed to send Ether");
        }
        return true;
  }

/// @notice Sends *ONE TYPE OF* ERC-20 token to an array of addresses according to the values in a uint array.
/// @param _tokenAddress The ERC-20 token address.
/// @param _to An array of addresses to be paid.
/// @param _value An array of values to be paid to "_to" addresses.
/// @return _success A bool to indicate transaction success.
  function sendErc20(address _tokenAddress, address[] memory _to, uint256[] memory _value) public restrictedToOwner nonReentrant returns (bool _success) {
      // input validation
      require(_to.length == _value.length);
      require(_to.length <= 255);

      // use the erc20 abi
      IERC20 token = IERC20(_tokenAddress);

      // Generate a unique ID for this transaction.
      emit multiSendPaymentExecuted(abi.encodePacked(address(this), paymentCount++, uint8(_value.length), bwChainId));

      // loop through to addresses and send value
      for (uint8 i = 0; i < _to.length; i++) {
          assert(token.transferFrom(msg.sender, _to[i], _value[i]) == true);
      }
      return true;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}