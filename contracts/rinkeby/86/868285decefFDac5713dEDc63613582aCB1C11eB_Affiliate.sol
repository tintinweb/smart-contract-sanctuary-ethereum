// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Auth} from "../utils/Auth.sol";
import {TrackableProxy} from "../utils/proxy/TrackableProxy.sol";

contract Affiliate is TrackableProxy, Auth {
  // redeem token address
  address public erc20token;
  // shows redeemed if true => redeemed else not redeemed
  mapping(uint256 => bool) public rewardsRedeem;
  // reward distributor
  address public rewardsDistributor;

  event Redeem(address indexed redeemer, uint256[] redeem_codes, uint256 redeemed_value);
  event EggPurcharsed(address indexed affiliate, uint256 amount);

  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  // constructor
  constructor(address _erc20token, address _rewardsDistributor) {
    erc20token = _erc20token;
    rewardsDistributor = _rewardsDistributor;
  }

  // redeem parameter validate function
  function _validRedeemParam(
    address redeemer,
    uint256[] calldata redeem_codes,
    uint256 totalValue,
    Sig calldata signature
  ) private view returns (bool) {
    bytes32 messageHash = keccak256(
      abi.encodePacked(msg.sender, redeemer, redeem_codes, totalValue)
    );
    bytes32 ethSignedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    return
      hasRole(
        "DISTRIBUTOR",
        ecrecover(ethSignedMessageHash, signature.v, signature.r, signature.s)
      );
  }

  // funciton
  // @param   redeemer: affiliates receiving rewards.
  // @param   redeem_codes: array of redeem code
  // @param   values: array of reward value
  // @param   signature: signature of distributor
  function redeemCode(
    address redeemer,
    uint256[] calldata redeem_codes,
    uint256 totalValue,
    Sig calldata signature
  ) public {
    //  keccak256(abi.encodePacked(address, redeem_codes, values)) and make sure that the result of ECRECOVER is rewardsDistributor
    require(
      _validRedeemParam(redeemer, redeem_codes, totalValue, signature),
      "Affiliate:SIGNER_NOT_VALID"
    );

    for (uint256 i = 0; i < redeem_codes.length; i++) {
      require(!rewardsRedeem[redeem_codes[i]], "Affiliate:ALREADY_REDEEMED");
      rewardsRedeem[redeem_codes[i]] = true;
    }

    IERC20(erc20token).transferFrom(rewardsDistributor, redeemer, totalValue);
    emit Redeem(redeemer, redeem_codes, totalValue);
  }

  // function
  // @param   code: redeem code
  // @return  if redeemed return true else return false
  function redeemed(uint256 code) public view returns (bool) {
    return rewardsRedeem[code];
  }

  function setDistributor(address _address) public onlyOwner {
    rewardsDistributor = _address;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

library Strings {
  function toBytes32(string memory text) internal pure returns (bytes32) {
    return bytes32(bytes(text));
  }

  function toString(bytes32 text) internal pure returns (string memory) {
    return string(abi.encodePacked(text));
  }
}

contract Auth {
  //Address of current owner
  address public owner;
  //Address of new owner (Note: new owner must pull to be an owner)
  address public newOwner;
  //If paused or not
  uint256 private _paused;
  //Roles mapping (role => address => has role)
  mapping(bytes32 => mapping(address => bool)) private _roles;

  //Fires when a new owner is pushed
  event OwnerPushed(address indexed pushedOwner);
  //Fires when new owner pulled
  event OwnerPulled(address indexed previousOwner, address indexed newOwner);
  //Fires when account is granted role
  event RoleGranted(string indexed role, address indexed account, address indexed sender);
  //Fires when accoount is revoked role
  event RoleRevoked(string indexed role, address indexed account, address indexed sender);
  //Fires when pause is triggered by account
  event Paused(address account);
  //Fires when pause is lifted by account
  event Unpaused(address account);

  error Unauthorized(string role, address user);
  error IsPaused();
  error NotPaused();

  constructor() {
    owner = msg.sender;
    emit OwnerPulled(address(0), msg.sender);
  }

  modifier whenNotPaused() {
    if (paused()) revert IsPaused();
    _;
  }

  modifier whenPaused() {
    if (!paused()) revert NotPaused();
    _;
  }

  modifier onlyOwner() {
    if (msg.sender != owner) revert Unauthorized("OWNER", msg.sender);
    _;
  }

  modifier onlyRole(string memory role) {
    if (!hasRole(role, msg.sender)) revert Unauthorized(role, msg.sender);
    _;
  }

  function hasRole(string memory role, address account) public view virtual returns (bool) {
    return _roles[Strings.toBytes32(role)][account];
  }

  function paused() public view virtual returns (bool) {
    return _paused == 1 ? true : false;
  }

  function pushOwner(address account) public virtual onlyOwner {
    require(account != address(0), "No address(0)");
    require(account != owner, "Only new owner");
    newOwner = account;
    emit OwnerPushed(account);
  }

  function pullOwner() public virtual {
    if (msg.sender != newOwner) revert Unauthorized("NEW_OWNER", msg.sender);
    address oldOwner = owner;
    owner = msg.sender;
    emit OwnerPulled(oldOwner, msg.sender);
  }

  function grantRole(string memory role, address account) public virtual onlyOwner {
    require(bytes(role).length > 0, "Role not given");
    require(account != address(0), "No address(0)");
    _grantRole(role, account);
  }

  function revokeRole(string memory role, address account) public virtual onlyOwner {
    require(hasRole(role, account), "Role not granted");
    _revokeRole(role, account);
  }

  function renounceRole(string memory role) public virtual {
    require(hasRole(role, msg.sender), "Role not granted");
    _revokeRole(role, msg.sender);
  }

  function pause() public virtual onlyRole("PAUSER") whenNotPaused {
    _paused = 1;
    emit Paused(msg.sender);
  }

  function unpause() public virtual onlyRole("PAUSER") whenPaused {
    _paused = 0;
    emit Unpaused(msg.sender);
  }

  function _grantRole(string memory role, address account) internal virtual {
    if (!hasRole(role, account)) {
      bytes32 encodedRole = Strings.toBytes32(role);
      _roles[encodedRole][account] = true;
      emit RoleGranted(role, account, msg.sender);
    }
  }

  function _revokeRole(string memory role, address account) internal virtual {
    bytes32 encodedRole = Strings.toBytes32(role);
    _roles[encodedRole][account] = false;
    emit RoleRevoked(role, account, msg.sender);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.9;

contract TrackableProxy {
  event AffiliateCall(
    uint256 indexed affiliate,
    address indexed implement,
    address indexed from,
    bytes data
  );

  constructor() {}

  function _fallback() internal {
    bytes32 _id = keccak256(abi.encode("AffiliateCall(uint256, address, address, bytes)"));
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      let dataPtr := 0xc0 // next call data pointer
      let paramNumber := div(sub(calldatasize(), 0x64), 0x20) // get reall call parameter number
      calldatacopy(add(dataPtr, 0x24), 0x04, mul(paramNumber, 0x20)) // copy call params
      calldatacopy(0x60, add(mul(paramNumber, 0x20), 0x04), 0x40) // capy distination and affiliate address
      calldatacopy(dataPtr, add(mul(paramNumber, 0x20), 0x60), 0x04) // copy function selector
      mstore(add(dataPtr, 0x04), caller()) // sent msg.sender to first param
      let to := mload(0x60) // load distination address
      let affiliate := mload(0x80) // load affiliate address

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := call(gas(), to, callvalue(), dataPtr, add(mul(paramNumber, 0x20), 0x24), 0, 0)

      // emit log
      log4(add(dataPtr, 0x24), mul(paramNumber, 0x20), _id, affiliate, to, caller())
      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
   * function in the contract matches the call data.
   */
  fallback() external payable {
    _fallback();
  }

  /**
   * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
   * is empty.
   */
  receive() external payable {
    _fallback();
  }
}