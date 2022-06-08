// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import { AaveMerkleDistributor } from "./AaveMerkleDistributor.sol";
import { IInitializableAdminUpgradeabilityProxy } from "./interfaces/IInitializableAdminUpgradeabilityProxy.sol";

/// @title Payload to initialize the tokens rescue phase 1
/// @author BGD
/// @notice Provides an execute function for Aave governance to:
///         - Initialize the AaveMerkleDistributor with the merkleTrees for token rescue for:
///         - AAVE, stkAAVE, USDT, UNI tokens
contract ProposalPayloadShort {
    AaveMerkleDistributor public immutable AAVE_MERKLE_DISTRIBUTOR;
    address public immutable LEND_TO_AAVE_MIGRATOR_IMPL;

    // AAVE distribution
    address public constant AAVE_TOKEN =
        0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    bytes32 public constant AAVE_MERKLE_ROOT =
        0x891147aad252d84ea6b63a5aa3546c02efccb86b862c723f6f08ec7a219f14c9;

    // stkAAVE distribution
    address public constant stkAAVE_TOKEN =
        0x4da27a545c0c5B758a6BA100e3a049001de870f5;

    bytes32 public constant stkAAVE_MERKLE_ROOT =
        0x71d2b70cb25ea6bbdc276c4b4b9f209c53131d652f962b4d5f6d89fe5a1c6760;

    // USDT distribution
    address public constant USDT_TOKEN =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;

    bytes32 public constant USDT_MERKLE_ROOT =
        0xc7ee13da36bc0398f570e2c50daea6d04645f112371489486655d566c141c156;

    // UNI distribution
    address public constant UNI_TOKEN =
        0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;

    bytes32 public constant UNI_MERKLE_ROOT =
        0x0d02ecdaab34b26ed6ffa029ffa15bc377852ba0dc0e2ce18927d554ea3d939e;

    // LEND rescue constants
    IInitializableAdminUpgradeabilityProxy
        public constant MIGRATOR_PROXY_ADDRESS =
        IInitializableAdminUpgradeabilityProxy(
            0x317625234562B1526Ea2FaC4030Ea499C5291de4
        );

    uint256 public constant LEND_TO_MIGRATOR_RESCUE_AMOUNT =
        8007719287288096435418;

    uint256 public constant LEND_TO_LEND_RESCUE_AMOUNT =
        841600717506653731350931;

    constructor(
        AaveMerkleDistributor aaveMerkleDistributor,
        address lendToAaveMigratorImpl
    ) public {
        AAVE_MERKLE_DISTRIBUTOR = aaveMerkleDistributor;
        LEND_TO_AAVE_MIGRATOR_IMPL = lendToAaveMigratorImpl;
    }

    function execute() external {
        // initialize first distributions
        address[] memory tokens = new address[](4);
        tokens[0] = AAVE_TOKEN;
        tokens[1] = stkAAVE_TOKEN;
        tokens[2] = USDT_TOKEN;
        tokens[3] = UNI_TOKEN;

        bytes32[] memory merkleRoots = new bytes32[](4);
        merkleRoots[0] = AAVE_MERKLE_ROOT;
        merkleRoots[1] = stkAAVE_MERKLE_ROOT;
        merkleRoots[2] = USDT_MERKLE_ROOT;
        merkleRoots[3] = UNI_MERKLE_ROOT;

        AAVE_MERKLE_DISTRIBUTOR.addDistributions(tokens, merkleRoots);

        // Deploy new LendToAaveMigrator implementation and rescue LEND
        uint256 totalLendAmountToRescue = LEND_TO_MIGRATOR_RESCUE_AMOUNT +
            LEND_TO_LEND_RESCUE_AMOUNT;
        MIGRATOR_PROXY_ADDRESS.upgradeToAndCall(
            LEND_TO_AAVE_MIGRATOR_IMPL,
            abi.encodeWithSignature(
                "initialize(address,uint256)",
                address(AAVE_MERKLE_DISTRIBUTOR),
                totalLendAmountToRescue
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC20} from "./dependencies/openZeppelin/IERC20.sol";
import {SafeERC20} from "./dependencies/openZeppelin/SafeERC20.sol";
import {Ownable} from "./dependencies/openZeppelin/Ownable.sol";
import {MerkleProof} from "./dependencies/openZeppelin/MerkleProof.sol";
import {IAaveMerkleDistributor} from "./interfaces/IAaveMerkleDistributor.sol";


contract AaveMerkleDistributor is Ownable, IAaveMerkleDistributor {
    using SafeERC20 for IERC20;

    mapping(uint256 => Distribution) public _distributions;

    uint256 public override _nextDistributionId = 0;

    function contructor() public {}

    /// @inheritdoc IAaveMerkleDistributor
    function getDistribution(uint256 distributionId) external view override returns (DistributionWithoutClaimed memory) {
        require(distributionId < _nextDistributionId, 'MerkleDistributor: Distribution dont exist');
                
        return DistributionWithoutClaimed({token: _distributions[distributionId].token, merkleRoot: _distributions[distributionId].merkleRoot});
    }

    /// @inheritdoc IAaveMerkleDistributor
    function addDistributions(address[] memory tokens, bytes32[] memory merkleRoots) external onlyOwner override {
        require(tokens.length == merkleRoots.length, 'MerkleDistributor: tokens not the same length as merkleRoots'); 
        for(uint i = 0; i < tokens.length; i++) {
            uint256 currentDistributionId = _nextDistributionId;
            _distributions[currentDistributionId].token = tokens[i];
            _distributions[currentDistributionId].merkleRoot = merkleRoots[i];

            _nextDistributionId++;

            emit DistributionAdded(tokens[i], merkleRoots[i], currentDistributionId);
        }
    }

    /// @inheritdoc IAaveMerkleDistributor
    function isClaimed(uint256 index, uint256 distributionId) public view override returns (bool) {
        require(distributionId < _nextDistributionId, 'MerkleDistributor: Distribution dont exist');
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = _distributions[distributionId].claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /// @inheritdoc IAaveMerkleDistributor
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, uint256 distributionId) external override {
        require(distributionId < _nextDistributionId, 'MerkleDistributor: Distribution dont exist');
        require(!isClaimed(index, distributionId), 'MerkleDistributor: Drop already claimed.');

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, _distributions[distributionId].merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index, distributionId);
        IERC20(_distributions[distributionId].token).safeTransfer(account, amount);

        emit Claimed(index, account, amount, distributionId);
    }

    /// @inheritdoc IAaveMerkleDistributor
    function emergencyTokenTransfer(
        address erc20Token,
        address to,
        uint256 amount
    ) external override onlyOwner {
        IERC20(erc20Token).safeTransfer(to, amount);
    }

    /// @inheritdoc IAaveMerkleDistributor
    function emergencyEtherTransfer(address to, uint256 amount) external override onlyOwner {
        _safeTransferETH(to, amount);
    }
    
    /**
    * @dev set claimed as true for index on distributionId
    * @param index indicating which node of the tree needs to be set as true
    * @param distributionId id of the distribution we want to set claimed to true
    */
    function _setClaimed(uint256 index, uint256 distributionId) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        _distributions[distributionId].claimedBitMap[claimedWordIndex] = 
            _distributions[distributionId].claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    /**
    * @dev transfer ETH to an address, revert if it fails.
    * @param to recipient of the transfer
    * @param value the amount to send
    */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.0 <0.9.0;


interface IInitializableAdminUpgradeabilityProxy {
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable;
    function admin() external returns (address);
    function REVISION() external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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

pragma solidity ^0.8.0;

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)
// commit: 3bdf4bf

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
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
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IAaveMerkleDistributor {
    /// @dev struct that contains the information for a distributionId id
    /// @param merkleRoot the merkle root of the merkle tree containing account balances available to claim.
    /// @param claimedBitMap containing the address index to claimed bool. 
    //       This works by storing the indexes 0-255 as 0, 256-511 as 1.
    //       It is using the bit representation of uint256 to save on gas.
    struct Distribution {
        address token;
        bytes32 merkleRoot;
        mapping(uint256 => uint256) claimedBitMap;
    }

    /// @dev distribution information structure without the claim bitmap for usage as return object
    struct DistributionWithoutClaimed {
        address token;
        bytes32 merkleRoot;
    }

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address indexed account, uint256 amount, uint256 indexed distributionId);
    // this event is triggered when adding a new distribution
    event DistributionAdded(address indexed token, bytes32 indexed merkleRoot, uint256 indexed distributionId);
    
    /**
    * @dev returns the token and merkleRoot of a distirbution id
    * @param distributionId id of the distribution we want the information of
    */
    function getDistribution(uint256 distributionId) external view returns (DistributionWithoutClaimed memory);

    /** 
    * @dev Returns the id of the next distribution.
    */
    function _nextDistributionId() external view returns (uint256);
    
    /**
    * @dev Returns true if the index has been marked claimed.
    * @param index of the address and proof of the claimer
    * @param distributionId id of the distribution you want to check if index has been claimed
    */
    function isClaimed(uint256 index, uint256 distributionId) external view returns (bool);
    
    /**
    * @dev Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    * @param index index of the account that wants to claim
    * @param account address that wants to claim, and where the amount of tokens will be sent to
    * @param amount the amount that will be claimed
    * @param merkleProof proof that the account with index and amount is on the merkleTree, and can claim
    * @param distributionId id of the token distribution
    */
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof, uint256 distributionId) external;
    
    /**
    * @dev adds the pair of token and merkleRoot as new distributions
    * @param tokens that needs to be distributed
    * @param merkleRoots containing the information of index, address, value of the users that can claim
    * the token
    */
    function addDistributions(address[] memory tokens, bytes32[] memory merkleRoots) external;
    
    /**
    * @dev transfer ERC20 from the utility contract, for ERC20 recovery in case of stuck tokens due
    * direct transfers to the contract address.
    * @param erc20Token erc20 token to transfer
    * @param to recipient of the transfer
    * @param amount amount to send
    */
    function emergencyTokenTransfer(address erc20Token, address to, uint256 amount) external;

    /**
    * @dev transfer native Ether from the utility contract, for native Ether recovery in case of stuck Ether
    * due selfdestructs or transfer ether to pre-computated contract address before deployment.
    * @param to recipient of the transfer
    * @param amount amount to send
    */
    function emergencyEtherTransfer(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}