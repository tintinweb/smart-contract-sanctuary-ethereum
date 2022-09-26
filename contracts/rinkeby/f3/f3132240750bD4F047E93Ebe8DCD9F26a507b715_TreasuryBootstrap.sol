// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITreasuryBootstrap.sol";

import "./WhitelistSalePublic.sol";

/// @title TreasuryBootstrap
/// @author Bluejay Core Team
/// @notice TreasuryBootstrap is a token sale contract that supports public token sale as well as
/// whitelisted sale at different prices. Purchased BLU tokens are sent immediately to the buyer.
contract TreasuryBootstrap is ITreasuryBootstrap, WhitelistSalePublic {
  using SafeERC20 for IERC20;

  /// @notice Public price of the token against the reserve asset, in WAD
  uint256 public publicPrice;

  /// @notice Constructor to initialize the contract
  /// @param _reserve Address the asset used to purchase the BLU token
  /// @param _treasury Address of the treasury
  /// @param _price Price of the token for whitelisted sale, in WAD
  /// @param _maxPurchasable Maximum number of BLU tokens that can be purchased, in WAD
  /// @param _merkleRoot Merkle root of the distribution
  /// @param _publicPrice Price of the token for public sale, in WAD
  constructor(
    address _reserve,
    address _treasury,
    uint256 _price,
    uint256 _maxPurchasable,
    bytes32 _merkleRoot,
    uint256 _publicPrice
  )
    WhitelistSalePublic(
      _reserve,
      _treasury,
      _price,
      _maxPurchasable,
      _merkleRoot
    )
  {
    publicPrice = _publicPrice;
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Public purchase of tokens from the sale
  /// @param amount Amount of reserve assset to use for purchase
  /// @param recipient Address where BLU will be sent to
  function publicPurchase(uint256 amount, address recipient) public override {
    require(!paused, "Purchase paused");
    uint256 tokensBought = (amount * WAD) / publicPrice;

    totalPurchased += tokensBought;
    require(totalPurchased <= maxPurchasable, "Max purchasable reached");

    reserve.safeTransferFrom(msg.sender, address(treasury), amount);
    treasury.mint(recipient, tokensBought);

    emit PublicPurchase(msg.sender, recipient, amount, tokensBought);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasuryBootstrap {
  function publicPurchase(uint256 amount, address recipient) external;

  event PublicPurchase(
    address indexed buyer,
    address indexed recipient,
    uint256 amountIn,
    uint256 amountOut
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITreasury.sol";
import "../interfaces/IWhitelistSalePublic.sol";

import "./MerkleDistributor.sol";

/// @title WhitelistSalePublic
/// @author Bluejay Core Team
/// @notice WhitelistSalePublic is a token sale contract that sells tokens at a fixed price to whitelisted
/// addresses. Purchased BLU tokens are sent immediately to the buyer.
contract WhitelistSalePublic is
  Ownable,
  MerkleDistributor,
  IWhitelistSalePublic
{
  using SafeERC20 for IERC20;

  uint256 internal constant WAD = 10**18;

  /// @notice The contract address of the treasury, for minting BLU
  ITreasury public immutable treasury;

  /// @notice The contract address the asset used to purchase the BLU token
  IERC20 public immutable reserve;

  /// @notice Maximum number of BLU tokens that can be purchased, in WAD
  uint256 public immutable maxPurchasable;

  /// @notice Total of quota that has been claimed, in WAD
  uint256 public totalQuota;

  /// @notice Total of tokens that have been sold, in WAD
  uint256 public totalPurchased;

  /// @notice Mapping of addresses to available quota for purchase, in WAD
  mapping(address => uint256) public quota;

  /// @notice Price of the token against the reserve asset, in WAD
  uint256 public price;

  /// @notice Flag to pause contract
  bool public paused;

  /// @notice Constructor to initialize the contract
  /// @param _reserve Address the asset used to purchase the BLU token
  /// @param _treasury Address of the treasury
  /// @param _price Price of the token against the reserve asset, in WAD
  /// @param _maxPurchasable Maximum number of BLU tokens that can be purchased, in WAD
  /// @param _merkleRoot Merkle root of the distribution
  constructor(
    address _reserve,
    address _treasury,
    uint256 _price,
    uint256 _maxPurchasable,
    bytes32 _merkleRoot
  ) {
    treasury = ITreasury(_treasury);
    reserve = IERC20(_reserve);
    price = _price;
    maxPurchasable = _maxPurchasable;
    _setMerkleRoot(_merkleRoot);
    paused = true;
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Claims quota for the distribution to start purchasing tokens
  /// @dev The parameters of the function should come from the merkle distribution file
  /// @param index Index of the distribution
  /// @param account Account where the distribution is credited to
  /// @param amount Amount of allocated in the distribution, in WAD
  /// @param merkleProof Array of bytes32s representing the merkle proof of the distribution
  function claimQuota(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) public override {
    _claim(index, account, amount, merkleProof);
    quota[account] += amount;
    totalQuota += amount;
  }

  /// @notice Purchase tokens from the sale
  /// @dev The quota for purchase should be claimed prior to executing this function
  /// @param amount Amount of reserve assset to use for purchase
  /// @param recipient Address where BLU will be sent to
  function purchase(uint256 amount, address recipient) public override {
    require(!paused, "Purchase paused");
    uint256 tokensBought = (amount * WAD) / price;
    require(quota[msg.sender] >= tokensBought, "Insufficient quota");

    quota[msg.sender] -= tokensBought;
    totalPurchased += tokensBought;
    require(totalPurchased <= maxPurchasable, "Max purchasable reached");

    reserve.safeTransferFrom(msg.sender, address(treasury), amount);
    treasury.mint(recipient, tokensBought);

    emit Purchase(msg.sender, recipient, amount, tokensBought);
  }

  /// @notice Utility function to execute both claim and purchase in a single transaction
  /// @param index Index of the distribution
  /// @param account Account where the distribution is credited to
  /// @param claimAmount Amount of allocated in the distribution, in WAD
  /// @param merkleProof Array of bytes32s representing the merkle proof of the distribution
  /// @param purchaseAmount Amount of reserve assset to use for purchase
  /// @param recipient Address where BLU will be sent to
  function claimAndPurchase(
    uint256 index,
    address account,
    uint256 claimAmount,
    bytes32[] calldata merkleProof,
    uint256 purchaseAmount,
    address recipient
  ) public override {
    claimQuota(index, account, claimAmount, merkleProof);
    purchase(purchaseAmount, recipient);
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Pause and unpause the contract
  /// @param _paused True to pause, false to unpause
  function setPause(bool _paused) public onlyOwner {
    paused = _paused;
    emit Paused(_paused);
  }

  /// @notice Set the merkle root for the distribution
  /// @dev Setting the merkle root after distribution has begun may result in unintended consequences
  /// @param _merkleRoot New merkle root of the distribution
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    _setMerkleRoot(_merkleRoot);
    emit UpdatedMerkleRoot(_merkleRoot);
  }

  /// @notice Set the price of the BLU toke
  /// @dev The contract needs to be paused before setting the price
  /// @param _price New price of BLU, in WAD
  function setPrice(uint256 _price) public onlyOwner {
    require(paused, "Not Paused");
    price = _price;
    emit UpdatedPrice(_price);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITreasury {
  function mint(address to, uint256 amount) external;

  function withdraw(
    address token,
    address to,
    uint256 amount
  ) external;

  function increaseMintLimit(address minter, uint256 amount) external;

  function decreaseMintLimit(address minter, uint256 amount) external;

  function increaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  function decreaseWithdrawalLimit(
    address asset,
    address spender,
    uint256 amount
  ) external;

  event Mint(address indexed to, uint256 amount);
  event Withdraw(address indexed token, address indexed to, uint256 amount);
  event MintLimitUpdate(address indexed minter, uint256 amount);
  event WithdrawLimitUpdate(
    address indexed token,
    address indexed minter,
    uint256 amount
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWhitelistSalePublic {
  function claimQuota(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external;

  function purchase(uint256 amount, address recipient) external;

  function claimAndPurchase(
    uint256 index,
    address account,
    uint256 claimAmount,
    bytes32[] calldata merkleProof,
    uint256 purchaseAmount,
    address recipient
  ) external;

  event Purchase(
    address indexed buyer,
    address indexed recipient,
    uint256 amountIn,
    uint256 amountOut
  );
  event UpdatedMerkleRoot(bytes32 merkleRoot);
  event UpdatedPrice(uint256 price);
  event Paused(bool isPaused);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title MerkleDistributor
/// @author Bluejay Core Team
/// @notice MerkleDistributor is a base contract for contracts using merkle tree to distribute assets.
/// @dev Code inspired by https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol
/// Merkle root generation script inspired by https://github.com/Uniswap/merkle-distributor/tree/master/scripts
abstract contract MerkleDistributor {
  /// @notice Merkle root of the entire distribution
  /// @dev Setting the merkle root after distribution has begun may result in unintended consequences
  bytes32 public merkleRoot;

  /// @notice Packed array of booleans
  mapping(uint256 => uint256) private claimedBitMap;

  event Distributed(uint256 index, address account, uint256 amount);

  /// @notice Checks `claimedBitMap` to see if the distribution to a given index has been claimed
  /// @param index Index of the distribution to check
  /// @return claimed True if the distribution has been claimed, false otherwise
  function isClaimed(uint256 index) public view returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  /// @notice Internal function to set a distribution as claimed
  /// @param index Index of the distribution to mark as claimed
  function _setClaimed(uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] =
      claimedBitMap[claimedWordIndex] |
      (1 << claimedBitIndex);
  }

  /// @notice Internal function to claim a distribution
  /// @param index Index of the distribution to claim
  /// @param account Address of the account to claim the distribution
  /// @param amount Amount of the distribution to claim
  /// @param merkleProof Array of bytes32s representing the merkle proof of the distribution
  function _claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) internal {
    require(!isClaimed(index), "Already claimed");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

    // Mark it claimed
    _setClaimed(index);

    emit Distributed(index, account, amount);
  }

  /// @notice Internal function to set the merkle root
  /// @dev Setting the merkle root after distribution has begun may result in unintended consequences
  function _setMerkleRoot(bytes32 _merkleRoot) internal {
    merkleRoot = _merkleRoot;
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