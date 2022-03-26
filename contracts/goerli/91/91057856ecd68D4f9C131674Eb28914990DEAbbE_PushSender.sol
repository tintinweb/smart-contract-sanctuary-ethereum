// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../FundsReceiver.sol";
import "../FeeChargeable.sol";
import "./Messages.sol";
import "./Gap.sol";

contract PushSender is Gap, FundsReceiver, FeeChargeable, Initializable, Messages {
  struct Recipient {
    address payable recipient;
    uint256 balance;
  }

  struct Change {
    uint256 amount;
    uint256 timestamp;
  }

  struct ChangeCleaner {
    address user;
    uint256[] indexes;
  }

  address public constant ETH_ADDRESS = 0x000000000000000000000000000000000000bEEF;

  mapping(address => Change[]) public changes;

  event Multisended(uint256 total, IERC20 tokenAddress);
  event RecordChange(address indexed sender, uint256 amount, uint256 index);
  event ClaimedChange(address indexed sender, uint256 change, uint256 index);

  /**
   * @notice initialize function for upgradeability
   * @dev this contract will be deployed behind a proxy and should not assign values at logic address,
   *      params left out because self explainable
   * */
  function initialize(
    address owner,
    uint256 _fee,
    uint256 _referralFee,
    VipTier[] calldata _tiers,
    uint256 _chainId
  ) external initializer {
    require(_fee >= _referralFee, "Referral fee can't be more than service fee");
    referralFee = _referralFee;
    fee = _fee;

    for (uint8 i = 0; i < _tiers.length; i++) {
      require(_tiers[i].price != 0, "Price can't be zero");
      require(_tiers[i].duration != 0, "Duration can't be zero");
      tiers.push(_tiers[i]);
    }

    chainId = _chainId;

    require(owner != address(0), "Empty owner address");
    _transferOwnership(owner);
  }

  // VALIDATION METHODS -------------------------------------------
  // --------------------------------------------------------------

  function validateToken(
    IERC20 token,
    uint256 total,
    Recipient[] calldata recipients
  )
    external
    payable
    returns (
      bool isDeflationary,
      uint256 gasLeft,
      Recipient[] memory badAddresses
    )
  {
    badAddresses = new Recipient[](recipients.length);

    uint256 balanceDiff = token.balanceOf(address(this));
    (bool successA, ) = _transferFrom(token, msg.sender, address(this), total);
    require(successA, "Bad token, transferFrom failed");
    balanceDiff = token.balanceOf(address(this)) - balanceDiff;
    if (balanceDiff != total) {
      // isDeflationary
      return (true, 0, badAddresses);
    }

    for (uint256 i = 0; i < recipients.length; i++) {
      balanceDiff = token.balanceOf(recipients[i].recipient);
      (bool success, ) = _transfer(token, recipients[i].recipient, recipients[i].balance);
      balanceDiff = success ? token.balanceOf(recipients[i].recipient) - balanceDiff : 0;

      if (success && balanceDiff != recipients[i].balance) {
        // isDeflationary
        return (true, 0, badAddresses);
      }

      if (!success) {
        badAddresses[i] = recipients[i];
      }
    }
    gasLeft = gasleft();
  }

  function validateDeflationaryToken(IERC20 _token, Recipient[] calldata _recipients)
    external
    payable
    returns (uint256 gasLeft, Recipient[] memory badAddresses)
  {
    badAddresses = new Recipient[](_recipients.length);

    for (uint256 i = 0; i < _recipients.length; i++) {
      (bool success, ) = _transferFrom(_token, msg.sender, _recipients[i].recipient, _recipients[i].balance);

      if (!success) {
        badAddresses[i] = _recipients[i];
      }
    }
    gasLeft = gasleft();
  }

  function validateEther(Recipient[] calldata _recipients)
    external
    payable
    returns (uint256 gasLeft, Recipient[] memory badAddresses)
  {
    badAddresses = new Recipient[](_recipients.length);

    uint256 contractBalanceBefore = address(this).balance - msg.value;
    uint256 contractFee = currentFee(msg.sender);
    uint256 total = msg.value - contractFee;

    for (uint256 i = 0; i < _recipients.length; i++) {
      bool success = _recipients[i].recipient.send(_recipients[i].balance);
      if (!success) {
        badAddresses[i] = _recipients[i];
      } else {
        total -= _recipients[i].balance;
      }
    }

    // assert. Just for sure
    require(address(this).balance >= contractBalanceBefore + contractFee, "Don't try to take the contract money");

    gasLeft = gasleft();
  }

  // MULTISEND METHODS --------------------------------------------
  // --------------------------------------------------------------

  function _multisendEther(Recipient[] calldata recipients, address payable etherHolder) internal returns (uint256 gasLeft) {
    uint256 contractBalanceBefore = address(this).balance - msg.value;

    uint256 contractFee = currentFee(etherHolder);
    require(msg.value > contractFee, "No fee");
    uint256 total = msg.value - contractFee;
    emit Multisended(total, IERC20(ETH_ADDRESS));

    for (uint256 i = 0; i < recipients.length; i++) {
      require(total >= recipients[i].balance, "Incorrect recipients amounts: sum more than total");
      bool success = recipients[i].recipient.send(recipients[i].balance);
      if (success) {
        total -= recipients[i].balance;
      }
    }
    if (total > 0) {
      etherHolder.transfer(total);
    }

    // assert: check final balance
    require(address(this).balance >= contractBalanceBefore + contractFee, "Don't try to take the contract money");

    return gasleft();
  }

  function multisendEther(Recipient[] calldata recipients) external payable returns (uint256 gasLeft) {
    return _multisendEther(recipients, payable(msg.sender));
  }

  function multisendEtherWithSignature(
    Recipient[] calldata recipients,
    bytes calldata signature,
    uint256 timestamp,
    bool isPersonalSignature
  ) external payable returns (uint256 gasLeft) {
    require(timestamp >= block.timestamp, "The signature has expired");
    address etherHolder = isPersonalSignature ? getPersonalApprover(timestamp, signature) : getApprover(timestamp, signature);

    return _multisendEther(recipients, payable(etherHolder));
  }

  function _multisendToken(
    IERC20 token,
    Recipient[] calldata recipients,
    uint256 total,
    address tokenHolder
  ) internal returns (uint256 gasLeft) {
    require(recipients.length > 0, "No contributors sent");
    (bool isGoodToken, bytes memory data) = _transferFrom(token, tokenHolder, address(this), total);
    require(isGoodToken, "transferFrom failed");
    if (data.length > 0) {
      bool success = abi.decode(data, (bool));
      require(success, "Not enough allowed tokens");
    }
    emit Multisended(total, token);

    for (uint256 i = 0; i < recipients.length; i++) {
      require(total >= recipients[i].balance, "Incorrect recipients amounts: sum more than total");
      (bool success, ) = _transfer(token, recipients[i].recipient, recipients[i].balance);
      if (success) {
        total -= recipients[i].balance;
      }
    }
    if (total > 0) {
      token.transfer(tokenHolder, total);
    }

    return gasleft();
  }

  function _checkFee(address user, address payable referral) internal {
    uint256 contractFee = currentFee(user);
    if (contractFee > 0) {
      require(msg.value >= contractFee, "No fee");
      if (referral != address(0)) {
        uint256 value = contractFee > referralFee ? referralFee : contractFee;
        referral.send(value);
      }
    }
  }

  function multisendToken(
    IERC20 token,
    Recipient[] calldata recipients,
    uint256 total,
    address payable referral
  ) external payable returns (uint256 gasLeft) {
    _checkFee(msg.sender, referral);
    return _multisendToken(token, recipients, total, msg.sender);
  }

  function multisendTokenWithSignature(
    IERC20 token,
    Recipient[] calldata recipients,
    uint256 total,
    address payable referral,
    bytes calldata signature,
    uint256 timestamp,
    bool isPersonalSignature
  ) external payable returns (uint256 gasLeft) {
    require(timestamp >= block.timestamp, "The signature has expired");
    address tokenHolder = isPersonalSignature ? getPersonalApprover(timestamp, signature) : getApprover(timestamp, signature);

    _checkFee(tokenHolder, referral);
    return _multisendToken(token, recipients, total, tokenHolder);
  }

  function _multisendTokenForBurners(
    IERC20 token,
    Recipient[] calldata recipients,
    address tokenHolder
  ) internal returns (uint256 gasLeft) {
    require(recipients.length > 0, "No contributors sent");
    uint256 total;
    for (uint256 i = 0; i < recipients.length; i++) {
      (bool success, ) = _transferFrom(token, tokenHolder, recipients[i].recipient, recipients[i].balance);
      if (success) {
        total += recipients[i].balance;
      }
    }
    emit Multisended(total, token);
    return gasleft();
  }

  function multisendTokenForBurners(
    IERC20 token,
    Recipient[] calldata recipients,
    address payable referral
  ) external payable returns (uint256 gasLeft) {
    _checkFee(msg.sender, referral);
    return _multisendTokenForBurners(token, recipients, msg.sender);
  }

  function multisendTokenForBurnersWithSignature(
    IERC20 token,
    Recipient[] calldata recipients,
    address payable referral,
    bytes calldata signature,
    uint256 timestamp,
    bool isPersonalSignature
  ) external payable returns (uint256 gasLeft) {
    require(timestamp >= block.timestamp, "the signature has expired");
    address tokenHolder = isPersonalSignature ? getPersonalApprover(timestamp, signature) : getApprover(timestamp, signature);

    _checkFee(tokenHolder, referral);
    return _multisendTokenForBurners(token, recipients, tokenHolder);
  }

  function recordChangeForMultisender(address user) external payable {
    changes[user].push(Change({ amount: msg.value, timestamp: block.timestamp }));
    emit RecordChange(user, msg.value, changes[user].length - 1);
  }

  function claimBatchChangeForMultisender(uint256[] memory indexes) external {
    for (uint256 i = 0; i < indexes.length; i++) {
      claimChangeForMultisender(indexes[i]);
    }
  }

  function claimChangeForMultisender(uint256 index) public {
    uint256 change = changes[msg.sender][index].amount;
    require(change > 0, "you dont have change");
    delete changes[msg.sender][index];
    payable(msg.sender).transfer(change);
    emit ClaimedChange(msg.sender, change, index);
  }

  function cleanChanges(ChangeCleaner[] calldata cleaners) external onlyOwner {
    for (uint256 i = 0; i < cleaners.length; i++) {
      for (uint256 j = 0; j < cleaners[i].indexes.length; j++) {
        delete changes[cleaners[i].user][cleaners[i].indexes[j]];
      }
    }
  }

  function currentChanges(address user) external view returns (Change[] memory) {
    return changes[user];
  }

  // INTERNAL METHODS ---------------------------------------------
  // --------------------------------------------------------------

  function _transferFrom(
    IERC20 _token,
    address _from,
    address _to,
    uint256 _amount
  ) private returns (bool success, bytes memory data) {
    (success, data) = address(_token).call(abi.encodeWithSelector(_token.transferFrom.selector, _from, _to, _amount));
  }

  function _transfer(
    IERC20 _token,
    address _to,
    uint256 _amount
  ) private returns (bool success, bytes memory data) {
    (success, data) = address(_token).call(abi.encodeWithSelector(_token.transfer.selector, _to, _amount));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FundsReceiver is Ownable {
  event ClaimedTokens(address token, address owner, uint256 amount);

  function claimTokens(address token, uint256 amount) external onlyOwner {
    address payable ownerPayable = payable(owner());
    if (token == address(0)) {
      if (amount == 0) {
        amount = address(this).balance;
      }
      ownerPayable.transfer(amount);
      emit ClaimedTokens(address(0), ownerPayable, amount);
      return;
    }

    if (amount == 0) {
      amount = IERC20(token).balanceOf(address(this));
    }
    IERC20(token).transfer(ownerPayable, amount);

    emit ClaimedTokens(token, ownerPayable, amount);
  }

  function tokenFallback(
    address _from,
    uint256 _value,
    bytes memory _data
  ) public {}

  fallback() external payable {}

  receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FeeChargeable is Ownable {
  struct VipTier {
    uint256 duration;
    uint256 price;
  }

  uint256 public fee;
  uint256 public referralFee;
  VipTier[] public tiers;
  mapping(address => bool) public moderators;
  mapping(address => uint256) public customFee;
  mapping(address => uint256) public hasVipUntil;

  event PurchaseVIP(address customer, uint256 tier);
  event FeeUpdated(uint256 newFee);

  modifier onlyModerator() {
    require(moderators[msg.sender], "not moderator");
    _;
  }

  // USERS METHODS --------------------------------------------------
  // ----------------------------------------------------------------

  function buyVip(uint256 tier) external payable {
    require(msg.value >= tiers[tier].price, "Not enough ETH value for VIP status purchase");

    uint256 start = hasVipUntil[msg.sender] > block.timestamp ? hasVipUntil[msg.sender] : block.timestamp;
    hasVipUntil[msg.sender] = start + tiers[tier].duration;

    emit PurchaseVIP(msg.sender, tier);
  }

  function currentFee(address customer) public view returns (uint256) {
    if (hasVipUntil[customer] >= block.timestamp) {
      return 0;
    }
    if (customFee[customer] > 0) {
      return customFee[customer];
    }
    return fee;
  }

  // ADMIN METHODS --------------------------------------------------
  // ----------------------------------------------------------------

  function addModerator(address moder) public onlyOwner {
    require(!moderators[moder], "Moderator already exist");
    moderators[moder] = true;
  }

  function deleteModerator(address moder) public onlyOwner {
    require(moderators[moder], "Moderator already moved");
    moderators[moder] = false;
  }

  function setCustomFee(address customer, uint256 _fee) public onlyModerator {
    require(_fee > 0, "Custom fee can't be zero");
    customFee[customer] = _fee;
  }

  function revokeCustomFee(address customer) public onlyModerator {
    require(customFee[customer] > 0, "Customer hasn't custom fee");
    customFee[customer] = 0;
  }

  function setVip(address customer, uint256 timestamp) public onlyModerator {
    require(hasVipUntil[customer] < timestamp, "Don't try to decrease customer VIP period");
    hasVipUntil[customer] = timestamp;
  }

  function setFee(uint256 _fee) public onlyOwner {
    require(_fee != 0, "Fee can't be zero");
    require(_fee >= referralFee, "Referral fee can't be more service fee");
    fee = _fee;
    emit FeeUpdated(_fee);
  }

  function setReferralFee(uint256 _fee) external onlyOwner {
    require(_fee <= fee, "Referral fee can't be more service fee");
    referralFee = _fee;
  }

  function changeTiersPrice(uint256[] calldata prices) public onlyOwner {
    require(prices.length == tiers.length, "Inccorect number of prices");
    for (uint8 i = 0; i < prices.length; i++) {
      require(prices[i] != 0, "Price can't be zero");
      tiers[i].price = prices[i];
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract Messages {
  uint256 public chainId;

  struct Authorization {
    address authorizedSigner;
    uint256 expiration;
  }
  /**
   * Domain separator encoding per EIP 712.
   * keccak256(
   *     "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
   * )
   */
  bytes32 public constant EIP712_DOMAIN_TYPEHASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

  /**
   * Validator struct type encoding per EIP 712
   * keccak256(
   *     "Authorization(address authorizedSigner,uint256 expiration)"
   * )
   */
  bytes32 private constant AUTHORIZATION_TYPEHASH = 0xe419504a688f0e6ea59c2708f49b2bbc10a2da71770bd6e1b324e39c73e7dc25;

  /**
   * Domain separator per EIP 712
   */
  // bytes32 public DOMAIN_SEPARATOR;
  function DOMAIN_SEPARATOR() public view returns (bytes32) {
    bytes32 salt = 0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558;
    return
      keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256("Multisender"), keccak256("3.0"), chainId, address(this), salt));
  }

  /**
   * @notice Calculates authorizationHash according to EIP 712.
   * @param _authorizedSigner address of trustee
   * @param _expiration expiration date
   * @return bytes32 EIP 712 hash of _authorization.
   */
  function hash(address _authorizedSigner, uint256 _expiration) public pure returns (bytes32) {
    return keccak256(abi.encode(AUTHORIZATION_TYPEHASH, _authorizedSigner, _expiration));
  }

  /**
   * @return the recovered address from the signature
   */
  function recoverAddress(bytes32 messageHash, bytes memory signature) public view returns (address) {
    bytes32 r;
    bytes32 s;
    bytes1 v;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := mload(add(signature, 0x60))
    }
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), messageHash));
    return ecrecover(digest, uint8(v), r, s);
  }

  function getApprover(uint256 timestamp, bytes memory signature) public view returns (address) {
    bytes32 messageHash = hash(msg.sender, timestamp);
    address signer = recoverAddress(messageHash, signature);
    require(signer != address(0), "the signature is invalid");
    return signer;
  }

  function getPersonalApprover(uint256 timestamp, bytes memory signature) public view returns (address) {
    bytes32 r;
    bytes32 s;
    bytes1 v;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := mload(add(signature, 0x60))
    }

    bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", "64", abi.encode(msg.sender, timestamp)));
    address signer = ecrecover(digest, uint8(v), r, s);
    require(signer != address(0), "the signature is invalid");
    return signer;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract Gap {
  uint256 internal __gap00; // storage padding to prevent storage collision
  uint256 internal __gap01; // storage padding to prevent storage collision
  uint256 internal __gap02; // storage padding to prevent storage collision
  uint256 internal __gap03; // storage padding to prevent storage collision
  uint256 internal __gap04; // storage padding to prevent storage collision
  uint256 internal __gap05; // storage padding to prevent storage collision
  uint256 internal __gap06; // storage padding to prevent storage collision
  uint256 internal __gap07; // storage padding to prevent storage collision
  uint256 internal __gap08; // storage padding to prevent storage collision
  uint256 internal __gap09; // storage padding to prevent storage collision
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}