// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./EIP712Decoder.sol";

contract SigCheque is Ownable {
  struct Config {
    uint256 waitBlockNumForWithdraw;
    uint80 baseRelayFee;
    uint16 pctRelayFee;
  }

  struct Cheque {
    address from;
    address to;
    uint256 amount;
    address token;
    address withdrawContract;
    uint256 nonce;
  }

  struct SignedCheque {
    Cheque cheque;
    bytes signature;
  }

  bytes32 constant CHEQUE_TYPEHASH = keccak256("Cheque(address from,address to,uint256 amount,address token,address withdrawContract,uint256 nonce)");

  mapping(address => uint256) public ethBalances;
  mapping(address => mapping(address => uint256)) public erc20Balances;
  mapping(address => uint256) public relayProfitBalances;
  mapping(address => uint256) public withdrawalRequests;
  mapping(bytes32 => uint8) public cashedCheques;

  event Configured(Config config);
  event Deposit(address indexed account, uint256 amount);
  event DepositToken(address indexed account, address token, uint256 amount, string symbol);
  event WithdrawalRequested(address indexed account);
  event Withdrawal(address indexed account, uint256 value);
  event WithdrawalTokens(address indexed account, address[] tokens, uint256[] values);
  event WithdrawalRelayProfit(address indexed account, uint256 value);
  event ChequeCashed(address sender, Cheque cheque, uint256 profit);

  Config internal config;
  bytes32 public immutable domainHash;

  constructor(string memory contractName, string memory version) {
    domainHash = EIP712Decoder.getEIP712DomainHash(contractName, version, block.chainid, address(this));
    config = Config(1, 10000000000000, 10);
  }

  function GET_CHEQUE_PACKETHASH(Cheque calldata _input) public pure returns (bytes32){
    bytes memory encoded = abi.encode(
      CHEQUE_TYPEHASH,
      _input.from,
      _input.to,
      _input.amount,
      _input.token,
      _input.withdrawContract,
      _input.nonce
    );

    return keccak256(encoded);
  }

  function getConfiguration() public view returns (Config memory) {
    return config;
  }

  function setConfiguration(Config calldata _config) external onlyOwner {
    config = _config;
    emit Configured(_config);
  }

  // 质押 ETH
  receive() external payable {
    if (msg.value <= 0) {
      return;
    }
    ethBalances[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value);
  }

  // 质押 ETH
  function deposit() external payable {
    if (msg.value <= 0) {
      return;
    }
    ethBalances[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value);
  }

  // 质押 ERC20 Token
  function depositToken(address token, uint256 amount) external {
    require(token != address(0), "Address(0) is not allowed");
    require(amount > 0, "Amount must be greater than 0");
    bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
    require(success, "ERC20 Token transferFrom failed");
    erc20Balances[msg.sender][token] += amount;
    emit DepositToken(msg.sender, token, amount, IERC20Metadata(token).symbol());
  }

  // 提现申请
  function requestWithdrawal() external {
    withdrawalRequests[msg.sender] = block.number;
    emit WithdrawalRequested(msg.sender);
  }

  // 提现
  function withdraw(address[] calldata tokens) public {
    require(
      withdrawalRequests[msg.sender] > 0 &&
      block.number - withdrawalRequests[msg.sender] >=
      config.waitBlockNumForWithdraw,
      "Withdrawal not yet available"
    );
    delete withdrawalRequests[msg.sender];
    uint256 amount = ethBalances[msg.sender];
    if (amount > 0) {
      delete ethBalances[msg.sender];
      (bool success,) = msg.sender.call{value : amount}("");
      require(success, "ETH transfer failed");
      emit Withdrawal(msg.sender, amount);
    }

    if (tokens.length <= 0) {
      return;
    }
    uint256[] memory withdrawTokenValues = new uint256[](tokens.length);
    for (uint256 index = 0; index < tokens.length; index++) {
      address token = tokens[index];
      require(token != address(0), "Address(0) is not allowed");
      if (erc20Balances[token][msg.sender] <= 0) {
        withdrawTokenValues[index] = 0;
        continue;
      }
      amount = erc20Balances[token][msg.sender];
      delete erc20Balances[token][msg.sender];
      bool success = IERC20(token).transfer(msg.sender, amount);
      require(success, "ERC20 Token transfer failed");
      withdrawTokenValues[index] = amount;
    }
    emit WithdrawalTokens(msg.sender, tokens, withdrawTokenValues);
  }

  // 获取支票 hash
  function getChequeTypedDataHash(Cheque calldata cheque) public view returns (bytes32) {
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainHash, GET_CHEQUE_PACKETHASH(cheque)));
    return digest;
  }

  // 验证支票签名
  function verifyChequeSignature(SignedCheque calldata signedCheque) public view returns (address) {
    Cheque calldata cheque = signedCheque.cheque;
    bytes32 chequeHash = getChequeTypedDataHash(cheque);
    address recoveredSignatureSigner = EIP712Decoder.recover(chequeHash, signedCheque.signature);
    return recoveredSignatureSigner;
  }

  function preCashingCheque(SignedCheque calldata signedCheque) public view returns (bool) {
    Cheque calldata cheque = signedCheque.cheque;
    require(
      verifyChequeSignature(signedCheque) == cheque.from,
      "Signature verification failed"
    );
    bytes32 chequeHash = getChequeTypedDataHash(cheque);
    require(cashedCheques[chequeHash] == 0, "The cheque has been cashed");
    require(
      erc20Balances[cheque.from][cheque.token] >= cheque.amount,
      "token balance is not enough to cash the cheque"
    );
    // fixme check possible gas
    return true;
  }

  // 兑现支票
  function cashingCheque(SignedCheque calldata signedCheque) public returns (bool) {
    uint256 initialGasLeft = gasleft();
    require(preCashingCheque(signedCheque));
    Cheque calldata cheque = signedCheque.cheque;
    erc20Balances[cheque.from][cheque.token] -= cheque.amount;
    bytes32 chequeHash = getChequeTypedDataHash(cheque);
    // fixme 此处用的是整个支票的 hash 作为 key, 这样就无法单独校验 nonce 的有效性了
    cashedCheques[chequeHash] = 1;
    bool success = IERC20(cheque.token).transfer(cheque.to, cheque.amount);
    require(success, "ERC20 Token transfer failed");
    if (msg.sender == cheque.to) {
      emit ChequeCashed(msg.sender, cheque, 0);
      return true;
    }
    // 代提交兑付
    uint256 gasUsed = initialGasLeft - gasleft();
    // fixme + calldata cost + line204~206
    uint256 profit = config.baseRelayFee + (tx.gasprice * gasUsed * (config.pctRelayFee + 100)) / 100;
    relayProfitBalances[msg.sender] += profit;
    ethBalances[cheque.from] -= profit;
    emit ChequeCashed(msg.sender, cheque, profit);
    return true;
  }

  // 提现收益
  function withdrawRelayProfit() public returns (uint256) {
    uint256 amount = relayProfitBalances[msg.sender];
    if (amount > 0) {
      delete relayProfitBalances[msg.sender];
      (bool success,) = msg.sender.call{value : amount}("");
      require(success, "ETH transfer failed");
      emit WithdrawalRelayProfit(msg.sender, amount);
    }
    return amount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library EIP712Decoder {
  bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  function getEIP712DomainHash(string memory contractName, string memory version, uint256 chainId, address verifyingContract) internal pure returns (bytes32) {
    bytes memory encoded = abi.encode(EIP712DOMAIN_TYPEHASH, keccak256(bytes(contractName)), keccak256(bytes(version)), chainId, verifyingContract);
    return keccak256(encoded);
  }

  function recover(bytes32 hash, bytes memory sig) internal pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }
    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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