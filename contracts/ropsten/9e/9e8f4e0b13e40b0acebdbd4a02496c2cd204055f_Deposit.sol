// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "forge-std/console.sol";
import "curve-merkle-oracle/StateProofVerifier.sol";
import { RLPReader } from "Solidity-RLP/RLPReader.sol";
import "../lightclient/LightClient.sol";

interface ILightClient {
  function getFinalizedStateRootBySlot(uint256 slot)
    external
    view
    returns (bytes32);
}

contract Bridge {
  mapping(address => address) public tokenAddressConverter;
  address public ETH_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public ETH_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public GNO_WETH = 0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1;
  address public GNO_USDC = 0xDDAfbb505ad214D7b80b1f830fcCc89B60fb7A83;

  constructor() {
    tokenAddressConverter[ETH_WETH] = GNO_WETH;
    tokenAddressConverter[ETH_USDC] = GNO_USDC;
  }

  function setMapping(address addr1, address addr2) public {
    tokenAddressConverter[addr1] = addr2;
  }

  function getNullifier(
    address recipient,
    uint256 amount,
    address tokenAddress,
    uint256 nonce
  ) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(recipient, amount, tokenAddress, nonce));
  }
}

contract Deposit is Bridge {
  mapping(bytes32 => bool) public deposits;
  mapping(address => uint256) public nonces;

  event DepositEvent(
    address indexed from,
    address indexed recipient,
    uint256 amount,
    address tokenAddress,
    uint256 nonce,
    bytes32 nullifier
  );

  function deposit(
    address recipient,
    uint256 amount,
    address tokenAddress
  ) external {
    require(
      tokenAddressConverter[tokenAddress] != address(0),
      "Invalid token address"
    );
    require(
      IERC20(tokenAddress).balanceOf(msg.sender) >= amount,
      "Insufficient balance"
    );
    IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
    uint256 nonce = nonces[recipient]++;
    bytes32 nullifier = getNullifier(recipient, amount, tokenAddress, nonce);
    deposits[nullifier] = true;
    emit DepositEvent(
      msg.sender,
      recipient,
      amount,
      tokenAddress,
      nonce,
      nullifier
    );
  }
}

contract Withdraw is Bridge {
  using RLPReader for RLPReader.RLPItem;
  using RLPReader for bytes;

  ILightClient lightClient;
  mapping(bytes32 => bool) public usedNullifiers;

  event WithdrawEvent(
    address indexed from,
    address indexed recipient,
    uint256 amount,
    address tokenAddress,
    uint256 nonce,
    bytes32 nullifier,
    address newTokenAddress
  );

  constructor(ILightClient _lightClient) {
    lightClient = _lightClient;
  }

  function verifyStorage(
    bytes32 slotHash,
    bytes32 storageRoot,
    bytes[] memory _stateProof
  ) internal view {
    RLPReader.RLPItem[] memory stateProof = new RLPReader.RLPItem[](
      _stateProof.length
    );
    for (uint256 i = 0; i < _stateProof.length; i++) {
      stateProof[i] = RLPReader.toRlpItem(_stateProof[i]);
    }
    // Verify existence of some nullifier
    StateProofVerifier.SlotValue memory slotValue = StateProofVerifier
      .extractSlotValueFromProof(slotHash, storageRoot, stateProof);
    require(slotValue.exists, "Slot value does not exist");
    // Check that the validated storage slot is present
    require(1 == slotValue.value, "Slot value is not 1");
  }

  function verifyAccount(
    bytes[] memory proof,
    address contractAddress,
    bytes32 stateRoot
  ) public view returns (bytes32) {
    RLPReader.RLPItem[] memory accountProof = new RLPReader.RLPItem[](
      proof.length
    );
    for (uint256 i = 0; i < proof.length; i++) {
      accountProof[i] = RLPReader.toRlpItem(proof[i]);
    }
    bytes32 addressHash = keccak256(abi.encodePacked(contractAddress));
    StateProofVerifier.Account memory account = StateProofVerifier
      .extractAccountFromProof(addressHash, stateRoot, accountProof);
    require(account.exists, "Account does not exist");
    return account.storageRoot;
  }

  function withdraw(
    bytes memory args,
    bytes[] memory accountProof,
    bytes[] memory stateProof,
    address depositContractAddress
  ) public {
    (
      address recipient,
      uint256 amount,
      address tokenAddress,
      uint256 nonce,
      uint256 slot
    ) = abi.decode(args, (address, uint256, address, uint256, uint256));

    bytes32 stateRoot = lightClient.getFinalizedStateRootBySlot(slot);
    bytes32 storageRoot = verifyAccount(
      accountProof,
      depositContractAddress,
      stateRoot
    );
    bytes32 nullifier = getNullifier(recipient, amount, tokenAddress, nonce);
    bytes32 slotHash = keccak256(
      abi.encodePacked(keccak256(abi.encode(nullifier, 5)))
    );
    verifyStorage(slotHash, storageRoot, stateProof);

    require(!usedNullifiers[nullifier], "Expired nullifier");
    usedNullifiers[nullifier] = true;

    address newTokenAddress = tokenAddressConverter[tokenAddress];
    require(newTokenAddress != address(0), "Invalid token address");

    IERC20(newTokenAddress).transfer(recipient, amount);

    emit WithdrawEvent(
      msg.sender,
      recipient,
      amount,
      tokenAddress,
      nonce,
      nullifier,
      newTokenAddress
    );
  }
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "forge-std/console.sol";
import { RLPReader } from "../../Solidity-RLP/contracts/RLPReader.sol";
import { MerklePatriciaProofVerifier } from "./MerklePatriciaProofVerifier.sol";

/**
 * @title A helper library for verification of Merkle Patricia account and state proofs.
 */
library StateProofVerifier {
  using RLPReader for RLPReader.RLPItem;
  using RLPReader for bytes;

  uint256 constant HEADER_STATE_ROOT_INDEX = 3;
  uint256 constant HEADER_NUMBER_INDEX = 8;
  uint256 constant HEADER_TIMESTAMP_INDEX = 11;

  struct BlockHeader {
    bytes32 hash;
    bytes32 stateRootHash;
    uint256 number;
    uint256 timestamp;
  }

  struct Account {
    bool exists;
    uint256 nonce;
    uint256 balance;
    bytes32 storageRoot;
    bytes32 codeHash;
  }

  struct SlotValue {
    bool exists;
    uint256 value;
  }

  /**
   * @notice Parses block header and verifies its presence onchain within the latest 256 blocks.
   * @param _headerRlpBytes RLP-encoded block header.
   */
  function verifyBlockHeader(bytes memory _headerRlpBytes)
    internal
    view
    returns (BlockHeader memory)
  {
    BlockHeader memory header = parseBlockHeader(_headerRlpBytes);
    // ensure that the block is actually in the blockchain
    require(header.hash == blockhash(header.number), "blockhash mismatch");
    return header;
  }

  /**
   * @notice Parses RLP-encoded block header.
   * @param _headerRlpBytes RLP-encoded block header.
   */
  function parseBlockHeader(bytes memory _headerRlpBytes)
    internal
    pure
    returns (BlockHeader memory)
  {
    BlockHeader memory result;
    RLPReader.RLPItem[] memory headerFields = _headerRlpBytes
      .toRlpItem()
      .toList();

    require(
      headerFields.length > HEADER_TIMESTAMP_INDEX,
      "headerFields length"
    );

    result.stateRootHash = bytes32(
      headerFields[HEADER_STATE_ROOT_INDEX].toUint()
    );
    result.number = headerFields[HEADER_NUMBER_INDEX].toUint();
    result.timestamp = headerFields[HEADER_TIMESTAMP_INDEX].toUint();
    result.hash = keccak256(_headerRlpBytes);

    return result;
  }

  /**
   * @notice Verifies Merkle Patricia proof of an account and extracts the account fields.
   *
   * @param _addressHash Keccak256 hash of the address corresponding to the account.
   * @param _stateRootHash MPT root hash of the Ethereum state trie.
   */
  function extractAccountFromProof(
    bytes32 _addressHash, // keccak256(abi.encodePacked(address))
    bytes32 _stateRootHash,
    RLPReader.RLPItem[] memory _proof
  ) internal view returns (Account memory) {
    // console.log("In extractAccountFromProof");
    // console.logBytes(_proof[0].toBytes());
    bytes memory acctRlpBytes = MerklePatriciaProofVerifier.extractProofValue(
      _stateRootHash,
      abi.encodePacked(_addressHash),
      _proof
    );

    Account memory account;

    if (acctRlpBytes.length == 0) {
      return account;
    }

    RLPReader.RLPItem[] memory acctFields = acctRlpBytes.toRlpItem().toList();
    require(acctFields.length == 4, "length is not 4");

    account.exists = true;
    account.nonce = acctFields[0].toUint();
    account.balance = acctFields[1].toUint();
    account.storageRoot = bytes32(acctFields[2].toUint());
    account.codeHash = bytes32(acctFields[3].toUint());

    return account;
  }

  /**
   * @notice Verifies Merkle Patricia proof of a slot and extracts the slot's value.
   *
   * @param _slotHash Keccak256 hash of the slot position.
   * @param _storageRootHash MPT root hash of the account's storage trie.
   */
  function extractSlotValueFromProof(
    bytes32 _slotHash,
    bytes32 _storageRootHash,
    RLPReader.RLPItem[] memory _proof
  ) internal view returns (SlotValue memory) {
    console.logBytes(_proof[0].toBytes());
    console.logBytes(_proof[1].toBytes());

    bytes memory valueRlpBytes = MerklePatriciaProofVerifier.extractProofValue(
      _storageRootHash,
      abi.encodePacked(_slotHash),
      _proof
    );

    console.log("valueRlpBytes");
    console.logBytes(valueRlpBytes);

    SlotValue memory value;

    if (valueRlpBytes.length != 0) {
      value.exists = true;
      value.value = valueRlpBytes.toRlpItem().toUint();
    }

    return value;
  }
}

// SPDX-License-Identifier: Apache-2.0

/*
* @author Hamdi Allam [email protected]
* Please reach out with any questions or concerns
*/
pragma solidity 0.8.10;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    struct Iterator {
        RLPItem item;   // Item that's being iterated over.
        uint nextPtr;   // Position of the next item in the list.
    }

    /*
    * @dev Returns the next element in the iteration. Reverts if it has not next element.
    * @param self The iterator.
    * @return The next element in the iteration.
    */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint ptr = self.nextPtr;
        uint itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
    * @dev Returns true if the iteration has more elements.
    * @param self The iterator.
    * @return true if the iteration has more elements.
    */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @dev Create an iterator. Reverts if item is not a list.
    * @param self The RLP item.
    * @return An 'Iterator' over the item.
    */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
    * @param the RLP item.
    */
    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint, uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint memPtr = item.memPtr + offset;
        uint len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
    * @param the RLP item.
    */
    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        (, uint len) = payloadLocation(item);
        return len;
    }

    /*
    * @param the RLP item containing the encoded list.
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint memPtr, uint len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33);

        (uint memPtr, uint len) = payloadLocation(item);

        uint result;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33);

        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint memPtr, uint len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    /*
    * Private Helpers
    */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr); // skip over an item
           count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            itemLen = 1;

        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        }

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint mask = 256 ** (WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "openzeppelin-contracts/access/Ownable.sol";

import "./Interfaces.sol";
import "./SimpleSerialize.sol";
import "./LightClientHelper.sol";
import "./ValidHeaderVerifier.sol";
import "./SyncCommitteeCommitmentVerifier.sol";

import "forge-std/console.sol";

struct BeaconBlockHeader {
  uint64 slot;
  uint64 proposerIndex;
  bytes32 parentRoot;
  bytes32 stateRoot;
  bytes32 bodyRoot;
}

struct LightClientUpdateStats {
  bool isFinalized;
  uint64 participation;
  uint64 slot;
}

struct ValidHeaderProof {
  uint256[2] a;
  uint256[2][2] b;
  uint256[2] c;
  uint256 bitsSum;
}

struct SyncCommitteeCommittmentsProof {
  uint256[2] a;
  uint256[2][2] b;
  uint256[2] c;
  uint256 syncCommitteePoseidon;
}

struct LightClientOptimisticUpdate {
  BeaconBlockHeader attestedHeader;
  ValidHeaderProof headerProof;
}

struct LightClientFinalizedUpdate {
  BeaconBlockHeader attestedHeader;
  BeaconBlockHeader finalizedHeader;
  bytes32[] finalityBranch;
  ValidHeaderProof headerProof;
}

struct LightClientUpdate {
  BeaconBlockHeader attestedHeader;
  bytes32 nextSyncCommitteeSSZ;
  bytes32[] nextSyncCommitteeBranch; // of length NEXT_SYNC_COMMITTEE_DEPTH
  BeaconBlockHeader finalizedHeader;
  bytes32[] finalityBranch; // of length FINALIZED_ROOT_DEPTH
  bytes32 forkVersion;
  ValidHeaderProof headerProof;
  SyncCommitteeCommittmentsProof syncCommitteeCommitmentsProof;
}

struct Head {
  uint64 participation;
  BeaconBlockHeader header;
  bytes32 blockRoot;
}

uint64 constant SAFETY_THRESHOLD_FACTOR = 2;
uint64 constant NEXT_SYNC_COMMITTEE_DEPTH = 5;
uint64 constant NEXT_SYNC_COMMITTEE_INDEX = 23;
uint64 constant FINALIZED_ROOT_DEPTH = 6;
uint64 constant FINALIZED_ROOT_INDEX = 41;
uint64 constant SYNC_COMMITTEE_SIZE = 64;

contract ETH2LightClient is Ownable {
  string public network;
  ISimpleSerialize public simpleSerialize;
  ISyncCommitteeCommittmentVerifier syncCommitteeCommitmentVerifier;
  IValidHeaderVerifier headerVerifier;

  mapping(uint64 => bytes32) public syncCommitteeSSZByPeriod;
  mapping(uint64 => uint256) public syncCommitteePoseidonByPeriod;
  mapping(uint64 => uint64) public maxParticipationByPeriod;
  mapping(uint256 => Head) public finalizedHeadBySlot;
  mapping(uint256 => bytes32) public eth1StateRootBySlot;
  bool onlyOnce;

  Head public head;
  Head public finalized;
  LightClientUpdateStats public nextSyncCommitteeStats;

  event OptimisticUpdate(address sender, uint256 slot);
  event FinalizedUpdate(address sender, uint256 slot);
  event CacheEth1BlockHeader(
    address sender,
    uint256 slot,
    bytes32 eth1StateRoot
  );
  event SyncCommitteeUpdate(address sender, uint256 slot);
  event SignedHeaderZKPVerified(
    address sender,
    uint256 bitsum,
    uint256 poseidon
  );
  event SyncCommitteeCommitmentZKPVerified(
    address sender,
    uint256 ssz,
    uint256 poseidon
  );

  constructor(
    ISimpleSerialize _simpleSerialize,
    IValidHeaderVerifier _headerVerifier,
    ISyncCommitteeCommittmentVerifier _syncCommitteeCommitmentVerifier,
    string memory _network
  ) {
    simpleSerialize = _simpleSerialize;
    headerVerifier = _headerVerifier;
    syncCommitteeCommitmentVerifier = _syncCommitteeCommitmentVerifier;
    network = _network;
  }

  function max(uint64 a, uint64 b) public pure returns (uint64) {
    return a >= b ? a : b;
  }

  function bytes32ToUint256Array(bytes32 b)
    public
    pure
    returns (uint256[32] memory)
  {
    uint256 bint = uint256(b);
    uint256[32] memory a;
    for (uint256 i = 0; i < 32; i++) {
      a[32 - 1 - i] = bint % 2**8;
      bint = bint / 2**8;
    }
    return a;
  }

  function assertValidSignedHeader(
    BeaconBlockHeader memory header,
    ValidHeaderProof memory proof,
    uint256 syncCommitteePoseidon
  ) public returns (bytes32) {
    (bytes32 headerBlockRoot, bytes32 signingRoot) = simpleSerialize
      .getSigningRoot(header, network);
    uint256[34] memory input; // input is [bitSum, syncCommitteePoseidon, signing_root[32]]
    input[0] = proof.bitsSum;
    input[1] = syncCommitteePoseidon;
    uint256[32] memory convertedSigningRoot = bytes32ToUint256Array(
      signingRoot
    );
    for (uint64 i = 0; i < 32; i++) {
      input[2 + i] = convertedSigningRoot[i];
    }
    bool verified = headerVerifier.verifyProof(
      proof.a,
      proof.b,
      proof.c,
      input
    );
    if (!verified) {
      revert("Invalid proof");
    }
    emit SignedHeaderZKPVerified(
      msg.sender,
      proof.bitsSum,
      syncCommitteePoseidon
    );
    return headerBlockRoot;
  }

  function setSyncCommitteePoseidon(uint64 period, uint256 poseidon)
    public
    onlyOwner
  {
    // Can only be called by deployer and initializes the sync committee poseidon
    // for a given period to a trusted but verifiable checkpoint.
    syncCommitteePoseidonByPeriod[period] = poseidon;
    renounceOwnership();
  }

  function processOptimisticUpdate(LightClientOptimisticUpdate memory update)
    public
    returns (uint64, bytes32)
  {
    // TODO Prevent registering updates for slots to far ahead
    /*
          if (header.slot > slotWithFutureTolerance(this.config, this.genesisTime, MAX_CLOCK_DISPARITY_SEC)) {
            throw Error(`header.slot ${header.slot} is too far in the future, currentSlot: ${this.currentSlot}`);
          }
        */
    BeaconBlockHeader memory header = update.attestedHeader;
    uint64 period = LightClientHelper.computeSyncPeriodAtSlot(header.slot);
    uint256 syncCommitteePoseidon = syncCommitteePoseidonByPeriod[period];
    bytes32 headerBlockRoot = assertValidSignedHeader(
      header,
      update.headerProof,
      syncCommitteePoseidon
    );
    uint64 participation = uint64(update.headerProof.bitsSum);

    uint64 currMaxParticipation = maxParticipationByPeriod[period];
    uint64 prevMaxParticipation = maxParticipationByPeriod[period - 1];
    uint64 maxParticipation = max(currMaxParticipation, prevMaxParticipation);
    uint64 minSafeParticipation = maxParticipation / SAFETY_THRESHOLD_FACTOR;

    if (participation < minSafeParticipation) {
      // TODO Throw error
    }

    if (participation > maxParticipation) {
      maxParticipationByPeriod[period] = participation;
      // TODO delete old period from maxParticipationByPeriod mapping
    }

    if (
      header.slot > head.header.slot ||
      (header.slot == head.header.slot && participation > head.participation)
    ) {
      Head memory prevHead = head;
      head = Head(participation, header, headerBlockRoot);
      if (
        header.slot == prevHead.header.slot &&
        prevHead.blockRoot != headerBlockRoot
      ) {
        // Emit Head update on same slot event, as a warning
      }
      // Emit Head Update event
    } else {
      // Emit Received valid head update did not update head event
    }

    emit OptimisticUpdate(msg.sender, header.slot);
    return (participation, headerBlockRoot);
  }

  function assertValidFinalityProof(
    LightClientFinalizedUpdate memory update,
    bytes32 finalizedBlockRoot
  ) public view {
    bool isValid = LightClientHelper.isValidMerkleBranch(
      finalizedBlockRoot,
      update.finalityBranch,
      FINALIZED_ROOT_DEPTH,
      FINALIZED_ROOT_INDEX,
      update.attestedHeader.stateRoot
    );
    if (!isValid) {
      revert("Invalid finality proof");
    }
  }

  function processFinalizedUpdate(LightClientFinalizedUpdate memory update)
    public
  {
    LightClientOptimisticUpdate memory castUpdate = LightClientOptimisticUpdate(
      update.attestedHeader,
      update.headerProof
    );
    (uint64 participation, ) = processOptimisticUpdate(castUpdate);
    BeaconBlockHeader memory finalizedHeader = update.finalizedHeader;
    (bytes32 finalizedBlockRoot, ) = simpleSerialize.getSigningRoot(
      finalizedHeader,
      network
    );
    assertValidFinalityProof(update, finalizedBlockRoot);

    if (
      finalizedHeader.slot > finalized.header.slot ||
      ((finalizedHeader.slot == finalized.header.slot) &&
        participation > head.participation)
    ) {
      Head memory prevFinalized = finalized;
      finalized = Head(participation, finalizedHeader, finalizedBlockRoot);
      finalizedHeadBySlot[finalizedHeader.slot] = finalized;

      if (
        finalized.header.slot == prevFinalized.header.slot &&
        prevFinalized.blockRoot != finalizedBlockRoot
      ) {
        // Emit Head update on same slot event, as a warning
      }
      // Emit Head Update event
    } else {
      // Emit Received valid head update did not update head event
    }
    emit FinalizedUpdate(msg.sender, finalizedHeader.slot);
  }

  function getFinalizedStateRootBySlot(uint256 slot)
    public
    view
    returns (bytes32)
  {
    return eth1StateRootBySlot[slot];
  }

  function isBetterUpdate(
    LightClientUpdateStats memory prev,
    LightClientUpdateStats memory next
  ) public pure returns (bool) {
    if (
      !prev.isFinalized &&
      next.isFinalized &&
      next.participation * 3 > SYNC_COMMITTEE_SIZE * 2
    ) {
      return true;
    }

    // Higher bit count
    if (prev.participation > next.participation) return false;
    if (prev.participation < next.participation) return true;

    // else keep the oldest, lowest chance or re-org and requires less updating
    return prev.slot > next.slot;
  }

  function assertValidSyncCommitteeCommittment(
    SyncCommitteeCommittmentsProof memory syncCommitteeCommitmentsProof,
    bytes32 nextSyncCommitteeSSZ
  ) public returns (bytes32, uint256) {
    uint256[33] memory inputs; // inputs = [syncCommitteeSSZ, syncCommitteePoseidon]
    uint256[32] memory convertedSSZ = bytes32ToUint256Array(
      nextSyncCommitteeSSZ
    );
    for (uint64 i = 0; i < 32; i++) {
      inputs[i] = convertedSSZ[i];
    }
    inputs[32] = syncCommitteeCommitmentsProof.syncCommitteePoseidon;
    // bool isValid = true;
    bool isValid = syncCommitteeCommitmentVerifier.verifyProof(
      syncCommitteeCommitmentsProof.a,
      syncCommitteeCommitmentsProof.b,
      syncCommitteeCommitmentsProof.c,
      inputs
    );
    if (!isValid) {
      revert("Invalid sync committee commitment proof");
    }
    emit SyncCommitteeCommitmentZKPVerified(msg.sender, inputs[0], inputs[1]);
    return (
      nextSyncCommitteeSSZ,
      syncCommitteeCommitmentsProof.syncCommitteePoseidon
    );
  }

  function assertValidSyncCommitteeInclusion(
    LightClientUpdate memory update,
    bytes32 activeStateRoot
  ) public view {
    bool isValid = LightClientHelper.isValidMerkleBranch(
      update.nextSyncCommitteeSSZ,
      update.nextSyncCommitteeBranch,
      NEXT_SYNC_COMMITTEE_DEPTH,
      NEXT_SYNC_COMMITTEE_INDEX,
      activeStateRoot
    );
    if (!isValid) {
      revert("Invalid sync committee proof");
    }
  }

  function assertValidLightClientUpdate(
    LightClientUpdate memory update,
    bool isFinalized
  )
    public
    returns (
      uint64,
      bytes32,
      uint256
    )
  {
    bytes32 activeStateRoot;
    if (isFinalized) {
      (bytes32 finalizedBlockRoot, ) = simpleSerialize.getSigningRoot(
        update.finalizedHeader,
        network
      );
      LightClientFinalizedUpdate
        memory finalizedUpdate = LightClientFinalizedUpdate(
          update.attestedHeader,
          update.finalizedHeader,
          update.finalityBranch,
          update.headerProof
        );
      assertValidFinalityProof(finalizedUpdate, finalizedBlockRoot);
      activeStateRoot = update.finalizedHeader.stateRoot;
    } else {
      // TODO assertZeroHashes
      activeStateRoot = update.attestedHeader.stateRoot;
    }

    assertValidSyncCommitteeInclusion(update, activeStateRoot);
    (
      bytes32 nextSyncCommitteeSSZ,
      uint256 nextSyncCommitteePoseidon
    ) = assertValidSyncCommitteeCommittment(
        update.syncCommitteeCommitmentsProof,
        update.nextSyncCommitteeSSZ
      );

    uint64 period = LightClientHelper.computeSyncPeriodAtSlot(
      update.attestedHeader.slot
    );
    uint256 syncCommitteePoseidon = syncCommitteePoseidonByPeriod[period];
    assertValidSignedHeader(
      update.attestedHeader,
      update.headerProof,
      syncCommitteePoseidon
    );

    uint64 participation = uint64(update.headerProof.bitsSum);
    return (participation, nextSyncCommitteeSSZ, nextSyncCommitteePoseidon);
  }

  function processSyncCommitteeUpdate(
    LightClientUpdate memory update,
    bool isFinalized
  ) public {
    // TODO
    uint64 updateSlot;
    if (isFinalized) {
      updateSlot = update.finalizedHeader.slot;
    } else {
      updateSlot = update.attestedHeader.slot;
    }
    // TODO check for updateSlot too far in the future
    uint64 period = LightClientHelper.computeSyncPeriodAtSlot(updateSlot);
    // TODO check for updatePeriod not overwriting past
    uint64 nextPeriod = period + 1;

    (
      uint64 participation,
      bytes32 nextSyncCommitteeSSZ,
      uint256 nextSyncCommitteePoseidon
    ) = assertValidLightClientUpdate(update, isFinalized);

    LightClientUpdateStats memory newCommitteeStats = LightClientUpdateStats(
      isFinalized,
      participation,
      updateSlot
    );
    if (isBetterUpdate(nextSyncCommitteeStats, newCommitteeStats)) {
      // TODO handle case where nextSyncCommitteeStats is not initialized
      nextSyncCommitteeStats = newCommitteeStats;
      syncCommitteeSSZByPeriod[nextPeriod] = nextSyncCommitteeSSZ;
      syncCommitteePoseidonByPeriod[nextPeriod] = nextSyncCommitteePoseidon;
    }
    emit SyncCommitteeUpdate(msg.sender, updateSlot);
  }

  function cacheEth1BlockHeader(
    uint64 slot,
    bytes32 blockHash,
    bytes32[] memory blockHashProof,
    bytes memory eth1BlockHeaderRLP
  ) public {
    bytes32 bodyRoot = finalizedHeadBySlot[slot].header.bodyRoot;
    require(
      LightClientHelper.isValidMerkleBranch(
        blockHash, // leaf
        blockHashProof,
        6,
        70,
        bodyRoot // root
      )
    );
    bytes32 stateRoot = LightClientHelper.getStateRootFromBlockHash(
      eth1BlockHeaderRLP,
      blockHash
    );
    eth1StateRootBySlot[slot] = stateRoot;
    emit CacheEth1BlockHeader(msg.sender, slot, stateRoot);
  }

  function cacheEth1StateRootBellatrix(
    uint64 slot,
    bytes32 stateRoot,
    bytes32[] memory stateRootProof
  ) public {
    bytes32 bodyRoot = finalizedHeadBySlot[slot].header.bodyRoot;
    require(
      LightClientHelper.isValidMerkleBranch(
        stateRoot, // leaf
        stateRootProof,
        8,
        402,
        bodyRoot // root
      )
    );
    eth1StateRootBySlot[slot] = stateRoot;
    emit CacheEth1BlockHeader(msg.sender, slot, stateRoot);
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

/**
 * Copied from https://github.com/lorenzb/proveth/blob/c74b20e/onchain/ProvethVerifier.sol
 * with minor performance and code style-related modifications.
 */
pragma solidity 0.8.10;

import { RLPReader } from "../../Solidity-RLP/contracts/RLPReader.sol";
import "forge-std/console.sol";

library MerklePatriciaProofVerifier {
  using RLPReader for RLPReader.RLPItem;
  using RLPReader for bytes;

  /// @dev Validates a Merkle-Patricia-Trie proof.
  ///      If the proof proves the inclusion of some key-value pair in the
  ///      trie, the value is returned. Otherwise, i.e. if the proof proves
  ///      the exclusion of a key from the trie, an empty byte array is
  ///      returned.
  /// @param rootHash is the Keccak-256 hash of the root node of the MPT.
  /// @param path is the key of the node whose inclusion/exclusion we are
  ///        proving.
  /// @param stack is the stack of MPT nodes (starting with the root) that
  ///        need to be traversed during verification.
  /// @return value whose inclusion is proved or an empty byte array for
  ///         a proof of exclusion
  function extractProofValue(
    bytes32 rootHash,
    bytes memory path,
    RLPReader.RLPItem[] memory stack
  ) internal view returns (bytes memory value) {
    // console.log("extractProofValue");
    // console.logBytes32(rootHash);
    // console.logBytes(path);
    // console.logBytes(stack[0].toBytes());
    // for (uint256 i = 0; i < stack.length; i++) {
    //   console.logUint(i);
    //   console.logBytes(stack[i].toBytes());
    // }
    bytes memory mptKey = _decodeNibbles(path, 0);
    uint256 mptKeyOffset = 0;

    bytes32 nodeHashHash;
    RLPReader.RLPItem[] memory node;

    RLPReader.RLPItem memory rlpValue;

    if (stack.length == 0) {
      // Root hash of empty Merkle-Patricia-Trie
      require(
        rootHash ==
          0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421,
        "invalid root hash"
      );
      return new bytes(0);
    }

    // Traverse stack of nodes starting at root.
    for (uint256 i = 0; i < stack.length; i++) {
      // We use the fact that an rlp encoded list consists of some
      // encoding of its length plus the concatenation of its
      // *rlp-encoded* items.

      // The root node is hashed with Keccak-256 ...
      // TODO is this okay to remove???
      if (i == 0 && rootHash != stack[i].rlpBytesKeccak256()) {
        revert("1");
      }

      // TODO: remove???????????
      // ... whereas all other nodes are hashed with the MPT
      // hash function.
      if (i != 0 && nodeHashHash != _mptHashHash(stack[i])) {
        console.logUint(i);
        revert("2");
      }

      // We verified that stack[i] has the correct hash, so we
      // may safely decode it.
      node = stack[i].toList();

      if (node.length == 2) {
        // Extension or Leaf node

        bool isLeaf;
        bytes memory nodeKey;
        (isLeaf, nodeKey) = _merklePatriciaCompactDecode(node[0].toBytes());

        uint256 prefixLength = _sharedPrefixLength(
          mptKeyOffset,
          mptKey,
          nodeKey
        );
        mptKeyOffset += prefixLength;

        if (prefixLength < nodeKey.length) {
          // Proof claims divergent extension or leaf. (Only
          // relevant for proofs of exclusion.)
          // An Extension/Leaf node is divergent iff it "skips" over
          // the point at which a Branch node should have been had the
          // excluded key been included in the trie.
          // Example: Imagine a proof of exclusion for path [1, 4],
          // where the current node is a Leaf node with
          // path [1, 3, 3, 7]. For [1, 4] to be included, there
          // should have been a Branch node at [1] with a child
          // at 3 and a child at 4.

          // Sanity check
          if (i < stack.length - 1) {
            // divergent node must come last in proof
            revert("3");
          }

          return new bytes(0);
        }

        if (isLeaf) {
          // Sanity check
          if (i < stack.length - 1) {
            // leaf node must come last in proof
            revert("4");
          }

          if (mptKeyOffset < mptKey.length) {
            return new bytes(0);
          }

          rlpValue = node[1];
          return rlpValue.toBytes();
        } else {
          // extension
          // Sanity check
          if (i == stack.length - 1) {
            // shouldn't be at last level
            revert("5");
          }

          if (!node[1].isList()) {
            // rlp(child) was at least 32 bytes. node[1] contains
            // Keccak256(rlp(child)).
            nodeHashHash = node[1].payloadKeccak256();
          } else {
            // rlp(child) was less than 32 bytes. node[1] contains
            // rlp(child).
            nodeHashHash = node[1].rlpBytesKeccak256();
          }
        }
      } else if (node.length == 17) {
        // Branch node

        if (mptKeyOffset != mptKey.length) {
          // we haven't consumed the entire path, so we need to look at a child
          uint8 nibble = uint8(mptKey[mptKeyOffset]);
          mptKeyOffset += 1;
          if (nibble >= 16) {
            // each element of the path has to be a nibble
            revert("6");
          }

          if (_isEmptyBytesequence(node[nibble])) {
            // Sanity
            if (i != stack.length - 1) {
              // leaf node should be at last level
              console.logUint(i);
              console.logUint(stack.length);
              revert("7");
            }

            return new bytes(0);
          } else if (!node[nibble].isList()) {
            nodeHashHash = node[nibble].payloadKeccak256();
          } else {
            nodeHashHash = node[nibble].rlpBytesKeccak256();
          }
        } else {
          // we have consumed the entire mptKey, so we need to look at what's contained in this node.

          // Sanity
          if (i != stack.length - 1) {
            // should be at last level
            revert("8");
          }

          return node[16].toBytes();
        }
      }
    }
  }

  /// @dev Computes the hash of the Merkle-Patricia-Trie hash of the RLP item.
  ///      Merkle-Patricia-Tries use a weird "hash function" that outputs
  ///      *variable-length* hashes: If the item is shorter than 32 bytes,
  ///      the MPT hash is the item. Otherwise, the MPT hash is the
  ///      Keccak-256 hash of the item.
  ///      The easiest way to compare variable-length byte sequences is
  ///      to compare their Keccak-256 hashes.
  /// @param item The RLP item to be hashed.
  /// @return Keccak-256(MPT-hash(item))
  function _mptHashHash(RLPReader.RLPItem memory item)
    private
    pure
    returns (bytes32)
  {
    if (item.len < 32) {
      return item.rlpBytesKeccak256();
    } else {
      return keccak256(abi.encodePacked(item.rlpBytesKeccak256()));
    }
  }

  function _isEmptyBytesequence(RLPReader.RLPItem memory item)
    private
    pure
    returns (bool)
  {
    if (item.len != 1) {
      return false;
    }
    uint8 b;
    uint256 memPtr = item.memPtr;
    assembly {
      b := byte(0, mload(memPtr))
    }
    return b == 0x80; /* empty byte string */
  }

  function _merklePatriciaCompactDecode(bytes memory compact)
    private
    pure
    returns (bool isLeaf, bytes memory nibbles)
  {
    require(compact.length > 0);
    uint256 first_nibble = (uint8(compact[0]) >> 4) & 0xF;
    uint256 skipNibbles;
    if (first_nibble == 0) {
      skipNibbles = 2;
      isLeaf = false;
    } else if (first_nibble == 1) {
      skipNibbles = 1;
      isLeaf = false;
    } else if (first_nibble == 2) {
      skipNibbles = 2;
      isLeaf = true;
    } else if (first_nibble == 3) {
      skipNibbles = 1;
      isLeaf = true;
    } else {
      // Not supposed to happen!
      revert("9");
    }
    return (isLeaf, _decodeNibbles(compact, skipNibbles));
  }

  function _decodeNibbles(bytes memory compact, uint256 skipNibbles)
    private
    pure
    returns (bytes memory nibbles)
  {
    require(compact.length > 0);

    uint256 length = compact.length * 2;
    require(skipNibbles <= length);
    length -= skipNibbles;

    nibbles = new bytes(length);
    uint256 nibblesLength = 0;

    for (uint256 i = skipNibbles; i < skipNibbles + length; i += 1) {
      if (i % 2 == 0) {
        nibbles[nibblesLength] = bytes1((uint8(compact[i / 2]) >> 4) & 0xF);
      } else {
        nibbles[nibblesLength] = bytes1((uint8(compact[i / 2]) >> 0) & 0xF);
      }
      nibblesLength += 1;
    }

    assert(nibblesLength == nibbles.length);
  }

  function _sharedPrefixLength(
    uint256 xsOffset,
    bytes memory xs,
    bytes memory ys
  ) private pure returns (uint256) {
    uint256 i;
    for (i = 0; i + xsOffset < xs.length && i < ys.length; i++) {
      if (xs[i + xsOffset] != ys[i]) {
        return i;
      }
    }
    return i;
  }
}

pragma solidity ^0.8.10;

import './LightClient.sol';

interface ISimpleSerialize {
    function sszPhase0BeaconBlockHeader(
        bytes32 slot, // big-endian encoded number, 64 bytes
        bytes32 proposerIndex, // big-endian encoded number, 64 bytes
        bytes32 parentRoot,
        bytes32 stateRoot,
        bytes32 bodyRoot
    ) external returns (bytes32);

    function sszPhase0SigningData(bytes32 objectRoot, bytes32 domain) external returns (bytes32);

    function getSigningRoot(BeaconBlockHeader memory header, string memory network) external returns (bytes32, bytes32);
}

interface ILightClientHelper {
    function isValidMerkleBranch(
        bytes32 leaf,
        bytes32[] memory branch,
        uint256 depth,
        uint256 index,
        bytes32 root
    ) external view returns (bool);

    function computeSyncPeriodAtSlot(uint64 slot) external pure returns (uint64);
}

interface IValidHeaderVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[34] memory input
    ) external view returns (bool);
}

interface ISyncCommitteeCommittmentVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[33] memory input
    ) external view returns (bool);
}

interface PatriciaTree {
    function verifyProof(
        bytes32 rootHash,
        bytes memory key,
        bytes memory value,
        uint256 branchMask,
        bytes32[] memory siblings
    ) external pure;
}

pragma solidity ^0.8.10;

import './LightClient.sol';
import './Interfaces.sol';
import 'forge-std/console.sol';

contract SimpleSerialize {
    function reverseBytes(uint256 input) public pure returns (uint256) {
        // swap bytes
        // https://ethereum.stackexchange.com/questions/83626/how-to-reverse-byte-order-in-uint256-or-bytes32
        uint256 v = input;
        // swap bytes
        v =
            ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v =
            ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v =
            ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v =
            ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
        return v;
    }

    function uint64ToSSZHex(uint64 value) public pure returns (bytes32) {
        return bytes32(reverseBytes(uint256(value)));
    }

    function hashArrayBytes32(bytes32[] calldata input) public pure returns (bytes32) {
        uint256 size = input.length;
        require(size > 0, 'Array cannot be empty.');
        uint256 sizeOver2 = size / 2;
        if (size == 2) {
            bytes memory res = abi.encodePacked(input[0], input[1]);
            return sha256(res);
        } else {
            bytes32 res1 = hashArrayBytes32(input[:sizeOver2]);
            bytes32 res2 = hashArrayBytes32(input[sizeOver2:]);
            bytes memory res = abi.encodePacked(res1, res2);
            return sha256(res);
        }
    }

    function sszPhase0SigningData(bytes32 objectRoot, bytes32 domain)
        public
        pure
        returns (bytes32)
    {
        // concat objectRoot and domain to get bytes64 object
        // return sha256 of bytes64
        bytes memory res = abi.encodePacked(objectRoot, domain);
        return sha256(res);
    }

    function sszPhase0BeaconBlockHeader(
        bytes32 slot, // big-endian encoded number, 64 bytes
        bytes32 proposerIndex, // big-endian encoded number, 64 bytes
        bytes32 parentRoot,
        bytes32 stateRoot,
        bytes32 bodyRoot
    ) public returns (bytes32) {
        bytes32 zeroNode = hex'0000000000000000000000000000000000000000000000000000000000000000';
        bytes32[] memory array = new bytes32[](8);
        array[0] = slot;
        array[1] = proposerIndex;
        array[2] = parentRoot;
        array[3] = stateRoot;
        array[4] = bodyRoot;
        for (uint256 i = 5; i < array.length; i++) {
            array[i] = zeroNode;
        }
        bytes memory executePayload = abi.encodeWithSignature('hashArrayBytes32(bytes32[])', array);
        (, bytes memory data) = address(this).call(executePayload);
        bytes32 rootHash;
        // Get 32 bytes from data
        assembly {
            rootHash := mload(add(data, 32))
        }
        return rootHash;
    }

    function getSigningRoot(BeaconBlockHeader memory header, string memory network) public returns (bytes32, bytes32) {
        bytes32 signedHeader = sszPhase0BeaconBlockHeader(
            uint64ToSSZHex(header.slot),
            uint64ToSSZHex(header.proposerIndex),
            header.parentRoot,
            header.stateRoot,
            header.bodyRoot
        );
        // TODO dynamically compute domain based on forkData and genesis validator root
        bytes32 domain;
        if (keccak256(bytes(network)) == keccak256(bytes("ropsten"))) {
            domain = hex'070000003cfa3bacace47d41ee4e3e7f989ed9c7e3e10904d2d67b36f1fda0b5';
        } else {
            // For mainnet
            domain = hex'07000000afcaaba0efab1ca832a15152469bb09bb84641c405171dfa2d3fb45f';
        }
        bytes32 signingRoot = sszPhase0SigningData(signedHeader, domain);
        return (signedHeader, signingRoot);
    }

    function sszPhase0SyncCommittee(bytes[] calldata pubkeys, bytes calldata aggregatePubkey)
        public
        returns (bytes32)
    {
        bytes32[] memory pubkeysWords = new bytes32[](1024);
        for (uint256 i = 0; i < 512; i++) {
            pubkeysWords[i * 2] = bytes32(pubkeys[i][:32]);
            pubkeysWords[i * 2 + 1] = bytes32(pubkeys[i][32:]);
        }
        bytes memory executePayload = abi.encodeWithSignature(
            'hashArrayBytes32(bytes32[])',
            pubkeysWords
        );
        (, bytes memory data) = address(this).call(executePayload);

        bytes32 pubkeysHash;
        assembly {
            pubkeysHash := mload(add(data, 32))
        }

        bytes32 aggregatePubkeyWord1 = bytes32(aggregatePubkey[:32]);
        bytes32 aggregatePubkeyWord2 = bytes32(aggregatePubkey[32:]);
        bytes32 aggregatePubkeyHash = sha256(
            abi.encodePacked(aggregatePubkeyWord1, aggregatePubkeyWord2)
        );

        return sha256(abi.encodePacked(pubkeysHash, aggregatePubkeyHash));
    }
}

pragma solidity ^0.8.10;

import "./Interfaces.sol";
import "forge-std/console.sol";
import { RLPReader } from "Solidity-RLP/RLPReader.sol";

library LightClientHelper {
  using RLPReader for RLPReader.RLPItem;
  using RLPReader for RLPReader.Iterator;
  using RLPReader for bytes;
  uint64 constant EPOCHS_PER_SYNC_COMMITTEE_PERIOD = 256;
  uint64 constant SLOTS_PER_EPOCH = 32;

  function computeEpochAtSlot(uint64 slot) public pure returns (uint64) {
    return slot / SLOTS_PER_EPOCH;
  }

  function computeSyncPeriodAtSlot(uint64 slot) public pure returns (uint64) {
    return computeEpochAtSlot(slot) / EPOCHS_PER_SYNC_COMMITTEE_PERIOD;
  }

  function floorLog2(uint256 n) public pure returns (uint8) {
    unchecked {
      uint8 res = 0;

      if (n < 256) {
        // at most 8 iterations
        while (n > 1) {
          n >>= 1;
          res += 1;
        }
      } else {
        // exactly 8 iterations
        for (uint8 s = 128; s > 0; s >>= 1) {
          if (n >= 1 << s) {
            n >>= s;
            res |= s;
          }
        }
      }

      return res;
    }
  }

  function isValidMerkleBranch(
    bytes32 leaf,
    bytes32[] memory branch,
    uint256 depth,
    uint256 index,
    bytes32 root
  ) public view returns (bool) {
    bytes32 value = leaf;
    for (uint256 i = 0; i < depth; i++) {
      console.logBytes32(value);
      if ((index / (2**i)) % 2 == 1) {
        value = sha256(bytes.concat(branch[i], value));
      } else {
        value = sha256(bytes.concat(value, branch[i]));
      }
    }
    return value == root;
  }

  function getSubtreeIndex(uint256 generalized_index)
    public
    pure
    returns (uint64)
  {
    return uint64(generalized_index % (2**(floorLog2(generalized_index))));
  }

  function getStateRootFromBlockHash(bytes memory rlpHeader, bytes32 blockHash)
    public pure
    returns (bytes32)
  {
    // First verify keccack256(rlpHeader) == blockHash
    // Then decode the rlpHeader to gt the stateRoot
    require(
      keccak256(rlpHeader) == blockHash,
      "rlpHeader and blockhash do not match"
    );
    RLPReader.RLPItem[] memory ls = rlpHeader.toRlpItem().toList(); // must convert to an rlpItem first!

    bytes memory stateRoot = ls[3].toBytes();
    bytes32 stateRootCast;
    assembly {
      stateRootCast := mload(add(stateRoot, 32))
    }
    return stateRootCast;
  }
}

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

library ValidHeaderPairing {
    struct G1Point {
        uint256 X;
        uint256 Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return
            G2Point(
                [
                    11559732032986387107991004021392285783925812861821192530917403151452391805634,
                    10857046999023057135944570762232829481370756359578518086990519993285655852781
                ],
                [
                    4082367875863433681332203403145435568316851327593401208105741076214120093531,
                    8495653923123431417604973247489272438418190587263600148770280649306958101930
                ]
            );

        /*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }

    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }

    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory r)
    {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'pairing-add-failed');
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'pairing-mul-failed');
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length, 'pairing-lengths-failed');
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(
                sub(gas(), 2000),
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'pairing-opcode-failed');
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract ValidHeaderVerifier {
    using ValidHeaderPairing for *;
    struct VerifyingKey {
        ValidHeaderPairing.G1Point alfa1;
        ValidHeaderPairing.G2Point beta2;
        ValidHeaderPairing.G2Point gamma2;
        ValidHeaderPairing.G2Point delta2;
        ValidHeaderPairing.G1Point[] IC;
    }
    struct Proof {
        ValidHeaderPairing.G1Point A;
        ValidHeaderPairing.G2Point B;
        ValidHeaderPairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = ValidHeaderPairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = ValidHeaderPairing.G2Point(
            [
                4252822878758300859123897981450591353533073413197771768651442665752259397132,
                6375614351688725206403948262868962793625744043794305715222011528459656738731
            ],
            [
                21847035105528745403288232691147584728191162732299865338377159692350059136679,
                10505242626370262277552901082094356697409835680220590971873171140371331206856
            ]
        );
        vk.gamma2 = ValidHeaderPairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = ValidHeaderPairing.G2Point(
            [
                19544391387317795908693780671452630021663160678150576511879734045746142668848,
                6917808035996032566040803443721470868926922971971642817023919900006732873381
            ],
            [
                6550171645782704964138654851739795195039536923577535566774725931353550994141,
                17393513049111511759089475614971590118089378704580429368956333521504553853058
            ]
        );
        vk.IC = new ValidHeaderPairing.G1Point[](35);

        vk.IC[0] = ValidHeaderPairing.G1Point(
            18634118167700065378232596069078433146864186665994201555961864106828086212743,
            14327951947179588742006969851213165520573615742149483260977723763469755404423
        );

        vk.IC[1] = ValidHeaderPairing.G1Point(
            15754604637577586343855596062581148391677160532391566684762128622210125145440,
            12029005404042902409069827689906205461731520076403261203730735303034406022756
        );

        vk.IC[2] = ValidHeaderPairing.G1Point(
            21032409925079266628115888414096993511961789777319711219129621190601000507660,
            13933503379131448514796295579902114318122487497247387979458794020094809911104
        );

        vk.IC[3] = ValidHeaderPairing.G1Point(
            1030042835797972600594323310675301872182264017081174020071332351641809409007,
            13035448255249303627598987990625684481866267923428463242624104913232400097513
        );

        vk.IC[4] = ValidHeaderPairing.G1Point(
            9205408164696378067540737009060653196285105141293830253413405594461158039458,
            10960004037751317217256013767425610585307403138124264170732581854842770608394
        );

        vk.IC[5] = ValidHeaderPairing.G1Point(
            12808276965221917931313922702084614292956235169298642905447261678538693982852,
            7558982779621560965367095688635585665399234927736610476959408220124011476536
        );

        vk.IC[6] = ValidHeaderPairing.G1Point(
            18459679565761478196250968176684853212804968504223381818968571428065944660110,
            2096872097952952095456973150379834398657109907224273419647237262157351917134
        );

        vk.IC[7] = ValidHeaderPairing.G1Point(
            3138634970732559227666222492437209244756011174974646917186607109713783603997,
            2192720049506924809734330479182806865555745249881019907648097710916397964924
        );

        vk.IC[8] = ValidHeaderPairing.G1Point(
            11758807484997752880168338308401891371043191265251735588003479561140014849990,
            21810430338761041127707001892904268719611411963024987167007850855735597382394
        );

        vk.IC[9] = ValidHeaderPairing.G1Point(
            1974624120621043205397758421918060884068257519777161751738543110058854398521,
            2783553824526800129095703199611940790520079941665351782403134784060633217309
        );

        vk.IC[10] = ValidHeaderPairing.G1Point(
            19629520579521668793841741321108003062626145416923320320789458631976956111306,
            11939015579457581504670694629719518980562993581930813873881590957854558784118
        );

        vk.IC[11] = ValidHeaderPairing.G1Point(
            10128850155763913966657962625702772086757857092065338369547276800748209908063,
            2002169034914114511176648818452803888796289976033686843507860377310828433437
        );

        vk.IC[12] = ValidHeaderPairing.G1Point(
            7411608744245654461426763572974876442832965660867744155395989970041029240691,
            11401425095998897302203923692141483276086130599787360499398565448821914182110
        );

        vk.IC[13] = ValidHeaderPairing.G1Point(
            20249353995817175849257990699025532537133900476695053074484720580718225039137,
            16711623145402519134601580685702628131430816485088038784262687383926529720585
        );

        vk.IC[14] = ValidHeaderPairing.G1Point(
            7053195556903729121230642915833823049269955000301071215370367588203935812806,
            4117472005341969771542436076061266968804131112741010298556066985810212750745
        );

        vk.IC[15] = ValidHeaderPairing.G1Point(
            14972684418861233751300276878366025217056036005346922814012935600279200063930,
            5797211998574235975937878193772694374837345350210831033732828769132449316066
        );

        vk.IC[16] = ValidHeaderPairing.G1Point(
            10168340555928315801741170296171140542152269035790061396969709710895364324983,
            6488881150283828286772764329336908350552099315886689612527165979847221522499
        );

        vk.IC[17] = ValidHeaderPairing.G1Point(
            8074655797691670906723779330378657589730354366433375563181562887616106120480,
            20838889069022180450380156714155140552946596984471337869034484276117659871005
        );

        vk.IC[18] = ValidHeaderPairing.G1Point(
            14062849752257633212930745337184610300442015336924223314210636872927737888225,
            13434495196738875479924221794803120031346464785369463508831640483069853026272
        );

        vk.IC[19] = ValidHeaderPairing.G1Point(
            8804037760022290100930246659214600158696635580696690969961635779306785613253,
            1024556133937631446000370551558136872691944464703396976713502173864823030608
        );

        vk.IC[20] = ValidHeaderPairing.G1Point(
            15021627748420420574213012835326190684214628192687383162295239494594309359855,
            19920734802489688371046120677543374795959321408501121592932228348239507449182
        );

        vk.IC[21] = ValidHeaderPairing.G1Point(
            5964698091228516413942524182792784660716925306912876145997607999348175273299,
            21308102562176866266731874074069237859894193860174870735409463074245666519273
        );

        vk.IC[22] = ValidHeaderPairing.G1Point(
            12595148632118443666232557615135356493193609110095429858714122965253086956522,
            13834396977073151542482231671203263742309765754852367709209354947738402536193
        );

        vk.IC[23] = ValidHeaderPairing.G1Point(
            6122189287921052333517287478292717410627060207736858731331616350897084949821,
            11865533243689375214111781184183839763778624644755858028210789249674682454801
        );

        vk.IC[24] = ValidHeaderPairing.G1Point(
            11505000294160917504974393086777044729344938621403397389074873577020997258033,
            14491961248708386718582811513697614399611771036273423753715524429941305787082
        );

        vk.IC[25] = ValidHeaderPairing.G1Point(
            4537557171882277471478608405426830033657501077057120423708775724582636889251,
            21007631822226332326199623899948648887454065853364008833318091203422106731095
        );

        vk.IC[26] = ValidHeaderPairing.G1Point(
            4277037076063313313215074776251925586419611120124122071691309806491084385899,
            8070708590466632492189009088744239574260015597265171400415923170205001896996
        );

        vk.IC[27] = ValidHeaderPairing.G1Point(
            16406421894802611332897660905273223718640561016301122555735411114606705677692,
            21655714962765883720020178971359192536419104812052655005152336320920605699103
        );

        vk.IC[28] = ValidHeaderPairing.G1Point(
            12332914946105198794018470917418954042192469977939229084155256020215049332432,
            8696770130392300711807863035052299921839591486978712475628536084325694658224
        );

        vk.IC[29] = ValidHeaderPairing.G1Point(
            5777645844124992644782183274971501298359745088661023005413737193098258297370,
            10441067234645698583104980147672297261027649043149667565146311980468317275956
        );

        vk.IC[30] = ValidHeaderPairing.G1Point(
            8405762912527403184358535390807982299030192026167858927777843968719513809381,
            7206465999602998544668690435579211071227472979759299983575201549199854579197
        );

        vk.IC[31] = ValidHeaderPairing.G1Point(
            8154264974309719802897575848020350300005429085920656115492064898085867204501,
            7403361736707208656607041290602933317451704762234760706498987825908338573106
        );

        vk.IC[32] = ValidHeaderPairing.G1Point(
            10832832700931865768319939320548036799950876081126688079535066133906784379562,
            9032441146586796702012724845856317465299885120859242382077037837627029696141
        );

        vk.IC[33] = ValidHeaderPairing.G1Point(
            7420412349928460424224271501279427587593184527274247631661643404636290694605,
            8755422471860050901282671888724467836819037886030296119243594912440714964682
        );

        vk.IC[34] = ValidHeaderPairing.G1Point(
            21569503585394963453826230750080951990529479102265079599755899322888881100183,
            21087999959798467502651314027194564802514325116126249964252540211016684992085
        );
    }

    function verify(uint256[] memory input, Proof memory proof) internal view returns (uint256) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, 'verifier-bad-input');
        // Compute the linear combination vk_x
        ValidHeaderPairing.G1Point memory vk_x = ValidHeaderPairing.G1Point(0, 0);
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field, 'verifier-gte-snark-scalar-field');
            vk_x = ValidHeaderPairing.addition(
                vk_x,
                ValidHeaderPairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = ValidHeaderPairing.addition(vk_x, vk.IC[0]);
        if (
            !ValidHeaderPairing.pairingProd4(
                ValidHeaderPairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[34] memory input
    ) public view returns (bool r) {
        Proof memory proof;
        proof.A = ValidHeaderPairing.G1Point(a[0], a[1]);
        proof.B = ValidHeaderPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = ValidHeaderPairing.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

library SyncCommitteeCommitmentPairing {
    struct G1Point {
        uint256 X;
        uint256 Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return
            G2Point(
                [
                    11559732032986387107991004021392285783925812861821192530917403151452391805634,
                    10857046999023057135944570762232829481370756359578518086990519993285655852781
                ],
                [
                    4082367875863433681332203403145435568316851327593401208105741076214120093531,
                    8495653923123431417604973247489272438418190587263600148770280649306958101930
                ]
            );

        /*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }

    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }

    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2)
        internal
        view
        returns (G1Point memory r)
    {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'pairing-add-failed');
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'pairing-mul-failed');
    }

    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length, 'pairing-lengths-failed');
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(
                sub(gas(), 2000),
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'pairing-opcode-failed');
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }

    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

contract SyncCommitteeCommitmentVerifier {
    using SyncCommitteeCommitmentPairing for *;
    struct VerifyingKey {
        SyncCommitteeCommitmentPairing.G1Point alfa1;
        SyncCommitteeCommitmentPairing.G2Point beta2;
        SyncCommitteeCommitmentPairing.G2Point gamma2;
        SyncCommitteeCommitmentPairing.G2Point delta2;
        SyncCommitteeCommitmentPairing.G1Point[] IC;
    }
    struct Proof {
        SyncCommitteeCommitmentPairing.G1Point A;
        SyncCommitteeCommitmentPairing.G2Point B;
        SyncCommitteeCommitmentPairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = SyncCommitteeCommitmentPairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = SyncCommitteeCommitmentPairing.G2Point(
            [
                4252822878758300859123897981450591353533073413197771768651442665752259397132,
                6375614351688725206403948262868962793625744043794305715222011528459656738731
            ],
            [
                21847035105528745403288232691147584728191162732299865338377159692350059136679,
                10505242626370262277552901082094356697409835680220590971873171140371331206856
            ]
        );
        vk.gamma2 = SyncCommitteeCommitmentPairing.G2Point(
            [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            [
                4082367875863433681332203403145435568316851327593401208105741076214120093531,
                8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
        );
        vk.delta2 = SyncCommitteeCommitmentPairing.G2Point(
            [
                3673211675016421152898753296628825860216932366390186010677799865826414453848,
                12187699871175162520563728271005448007532901953735825388995760195666107108114
            ],
            [
                13470677720427558424120778727381771465638492325145587444004169485617282907717,
                3928142835555125189531367984506784025840943097435080817927126896881468426417
            ]
        );
        vk.IC = new SyncCommitteeCommitmentPairing.G1Point[](34);

        vk.IC[0] = SyncCommitteeCommitmentPairing.G1Point(
            4795191551222101489305747239686725404646279919894677853631739899938973384052,
            1373586094791930197309215040841139803062323372406408816583360788007439296945
        );

        vk.IC[1] = SyncCommitteeCommitmentPairing.G1Point(
            13113183227081184987644074880786553266328079865006426465785441334252795690294,
            18753711890950305174219463925403101789262054477967293165993158398244452357334
        );

        vk.IC[2] = SyncCommitteeCommitmentPairing.G1Point(
            1457803216951495533496028056411068510755062380597369393018989800889407158850,
            11254846360191053722871534028616557758610518584856689904573871703124909443969
        );

        vk.IC[3] = SyncCommitteeCommitmentPairing.G1Point(
            8470295912803698886024948279633626974767479255380260007514469149219196285591,
            7710898327217166714598701364342042401151975049073776268821968563373494495031
        );

        vk.IC[4] = SyncCommitteeCommitmentPairing.G1Point(
            6849081198715854254099463546841658245207045607039507385181078195512611163018,
            21575359392901342786524496970644265010099770146783985965849459317318159068303
        );

        vk.IC[5] = SyncCommitteeCommitmentPairing.G1Point(
            17256895879384895053898031826183624095413764703927605078207183361196362439188,
            4223727400694151053038999394850898656355729003010210112013153257375899184749
        );

        vk.IC[6] = SyncCommitteeCommitmentPairing.G1Point(
            11277638186624958192473974808032103087119944940691139312387356848671791461269,
            177566017078008855758375087884185251523734027994781159427942501224270110323
        );

        vk.IC[7] = SyncCommitteeCommitmentPairing.G1Point(
            3949184504328302681344753079530768997001171799812236613588309481401519390765,
            15853822716040551365780499784904727776441140221273182481262478167207484336656
        );

        vk.IC[8] = SyncCommitteeCommitmentPairing.G1Point(
            3539121768872813206609794467980590379212837050946489392444780996350996136065,
            3922883352986539471033765773675276278142619109403733580220602160821917146216
        );

        vk.IC[9] = SyncCommitteeCommitmentPairing.G1Point(
            2876441234631667977250209580698528690896448532889340929833134524756467509174,
            15962923295273447889353047676257249002015642947577544584911932064063338332752
        );

        vk.IC[10] = SyncCommitteeCommitmentPairing.G1Point(
            2743095913222794646248768536068132751062910861877710035840483104432774045361,
            1929868971660472284860872845179905165576983022428893073692521240088598734129
        );

        vk.IC[11] = SyncCommitteeCommitmentPairing.G1Point(
            16506876686171874674156419854926715978704633069866064607196353739878940606477,
            15080226275320212354052583454393952898131928022676352025662199182332420779815
        );

        vk.IC[12] = SyncCommitteeCommitmentPairing.G1Point(
            19597057087406450021178176069695876922399962725231206403775835873297063269572,
            7096650376640542356672904160495942021769695417427824190668965121056746023876
        );

        vk.IC[13] = SyncCommitteeCommitmentPairing.G1Point(
            21560037854067516299037638337470754471675994834903466370370150346657424387446,
            11681037958635598963372112671637490909615366882333504629440913796429660715018
        );

        vk.IC[14] = SyncCommitteeCommitmentPairing.G1Point(
            12873753248740368072475985637056621455677382233305046370093910258916825247245,
            7130117706956753646523965993765396586045347494474764856640517905235429483335
        );

        vk.IC[15] = SyncCommitteeCommitmentPairing.G1Point(
            6390246008683175830052501719759149130328680627558701690364370376398243852645,
            21042083301279734192841064691661742205628538972758690069563873974070213880519
        );

        vk.IC[16] = SyncCommitteeCommitmentPairing.G1Point(
            9190361621173462852233083398495392871080898322303749032767914455996034256014,
            3166853231778333185040665510513264409238787808299535890881133005924112508058
        );

        vk.IC[17] = SyncCommitteeCommitmentPairing.G1Point(
            10528735437273101347940921665898344944312763281001302504582127173497146410650,
            12380918075954273893867517323128986284380771938020945018358974247457880251494
        );

        vk.IC[18] = SyncCommitteeCommitmentPairing.G1Point(
            18565816180642371490054834904337694233062016555224366039901620399360638143787,
            13348038710466240945159586471207455434337910512073338009165064190760234069484
        );

        vk.IC[19] = SyncCommitteeCommitmentPairing.G1Point(
            11627405508481850140993355225908727010943843388055241670429716392792671786570,
            11636765145979465572366983973459057642535663157570822605228614274589821410115
        );

        vk.IC[20] = SyncCommitteeCommitmentPairing.G1Point(
            7210806950322513829208502267236533528603926122553095787092626285527861372501,
            18294507783553194491561296585085377792539810729101581629666866157355971500513
        );

        vk.IC[21] = SyncCommitteeCommitmentPairing.G1Point(
            4784563431697238472835563380324941776380101762296690120965848578511979194172,
            18793068013197121255384966076264688363354310204821475864690755582198660936763
        );

        vk.IC[22] = SyncCommitteeCommitmentPairing.G1Point(
            5529655685369670650572348079280364264093110161290265927182855430726156793160,
            9646729969125722115539793202800781514920954390593112101309082306156196654844
        );

        vk.IC[23] = SyncCommitteeCommitmentPairing.G1Point(
            4453561650954751757891022837446150182313826316516412303017591914927981485707,
            7265134375634667316890055868560567781169241440944741739400905824666995810067
        );

        vk.IC[24] = SyncCommitteeCommitmentPairing.G1Point(
            12116766101738333194513364502203738608793382688076122255341194048730392856811,
            10624160921924740827280661107653238672563136901881810447868837068749679616319
        );

        vk.IC[25] = SyncCommitteeCommitmentPairing.G1Point(
            6251698205636783031722670792199881941935110174104794783187283860162986283407,
            11711502304035455088593621997266597595478071378282423473187806531689609022915
        );

        vk.IC[26] = SyncCommitteeCommitmentPairing.G1Point(
            7572621288357304896610941327683629553031083027677247988480702962701425841813,
            11525475541920950135954124618008822096567193784061136988453069022775703412298
        );

        vk.IC[27] = SyncCommitteeCommitmentPairing.G1Point(
            3356470642930272719456491737996917445140853270316619572709676710308085030210,
            2522662145931702141522208203853708879317675123203606222838628398243049618390
        );

        vk.IC[28] = SyncCommitteeCommitmentPairing.G1Point(
            20618769397246956774205784576708613229231934369100862770855080926153570563111,
            16104164871487573776167264794163504912051248113059114003722745538640057047886
        );

        vk.IC[29] = SyncCommitteeCommitmentPairing.G1Point(
            2774247457687250488439686234085658018824512082599513667319755852550914511241,
            6638819334928947755062145116222027431715248684461588185114685004312584337028
        );

        vk.IC[30] = SyncCommitteeCommitmentPairing.G1Point(
            9636266977473697624310653551756081264817998080004658884863290987165727789250,
            3341965601435906331877626172092684520261414702972085815587198485185818686506
        );

        vk.IC[31] = SyncCommitteeCommitmentPairing.G1Point(
            8795884974584280997930826730988359087662864888764652468867604287844472198667,
            18522490985949073699848740388401516427267750228537720561157929400956452642960
        );

        vk.IC[32] = SyncCommitteeCommitmentPairing.G1Point(
            20037446854735117821807316443090415103518086688914825640022089006200511712239,
            20448902132641114929957440424516430049008631146006193102619481246321448384331
        );

        vk.IC[33] = SyncCommitteeCommitmentPairing.G1Point(
            6422341509342503621458163846361336365061348644156209294032409964334776978688,
            19090547320127398500863057386563257425922444858080548954056808957681195091218
        );
    }

    function verify(uint256[] memory input, Proof memory proof) internal view returns (uint256) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length, 'verifier-bad-input');
        // Compute the linear combination vk_x
        SyncCommitteeCommitmentPairing.G1Point memory vk_x = SyncCommitteeCommitmentPairing.G1Point(
            0,
            0
        );
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field, 'verifier-gte-snark-scalar-field');
            vk_x = SyncCommitteeCommitmentPairing.addition(
                vk_x,
                SyncCommitteeCommitmentPairing.scalar_mul(vk.IC[i + 1], input[i])
            );
        }
        vk_x = SyncCommitteeCommitmentPairing.addition(vk_x, vk.IC[0]);
        if (
            !SyncCommitteeCommitmentPairing.pairingProd4(
                SyncCommitteeCommitmentPairing.negate(proof.A),
                proof.B,
                vk.alfa1,
                vk.beta2,
                vk_x,
                vk.gamma2,
                proof.C,
                vk.delta2
            )
        ) return 1;
        return 0;
    }

    /// @return r  bool true if proof is valid
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[33] memory input
    ) public view returns (bool r) {
        Proof memory proof;
        proof.A = SyncCommitteeCommitmentPairing.G1Point(a[0], a[1]);
        proof.B = SyncCommitteeCommitmentPairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = SyncCommitteeCommitmentPairing.G1Point(c[0], c[1]);
        uint256[] memory inputValues = new uint256[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}