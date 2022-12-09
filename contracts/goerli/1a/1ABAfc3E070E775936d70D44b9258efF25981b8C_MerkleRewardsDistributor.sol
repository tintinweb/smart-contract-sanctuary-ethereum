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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

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
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";

/**
 *  @title A Rewards Distributor Contract
 *  @notice A rewards distribution contract using a Merkle Tree to verify the amount and
 *          address of the user claiming ERC20 tokens
 *  @dev Functions are intended to be triggered on a specific timeframe (epoch) via a back-end
 *       service
 */
contract MerkleRewardsDistributor is Ownable, ReentrancyGuard {

    //
    // Constants ==================================================================================
    //

    uint16 public constant BPS_MAX = 10000;    

    //
    // State ======================================================================================
    //

    IERC20 public tokenContract;
    IUniswapV2Router02 public routerContract;

    bool public betweenEpochs;
    address public adminAddress;
    address public daoAddress;
    address public treasuryAddress;
    bytes32 public merkleRoot;
    /// @dev Treasury fee percentage expressed in basis points
    uint16 public treasuryFeeBps;
    uint256 public currentEpoch;
    /// @dev Cumulative amount of fees allocated to treasury during current epoch
    uint256 public treasuryFees;    
    
    uint256 public minStakeAmount = 2000 * 1e18;
    uint256 public swapTimeout = 15 minutes;

    mapping(bytes32 => bool) public claimed;

    //
    // Constructor ================================================================================
    //

    constructor(
        address _adminAddress,
        address _treasuryAddress,
        address _daoAddress,
        address tokenAddress,
        address routerAddress
    ) {
        adminAddress = _adminAddress;
        treasuryAddress = _treasuryAddress;
        daoAddress = _daoAddress;
        tokenContract = IERC20(tokenAddress);
        routerContract = IUniswapV2Router02(routerAddress);
    }

    //
    // Receive function ===========================================================================
    //

    receive() external payable {
        // Empty
    }

    //
    // Modifiers ==================================================================================
    //

    modifier claimsEnabled() {
        if(betweenEpochs) revert ClaimsDisabledUntilNextEpoch();
        _;
    }

    modifier onlyAdmin() {
        if(msg.sender != adminAddress) revert OnlyAdmin();
        _;
    }

    modifier onlyDao() {
        if(msg.sender != daoAddress) revert OnlyDao();
        _;
    }

    //
    // External functions =========================================================================
    //

    /**
     * @notice Transfers tokens to the claimer address if he was included in the Merkle Tree with
     *         the specified index
     */
    function claim(
        uint256 amountToClaim,
        bytes32[] calldata merkleProof
    ) external nonReentrant claimsEnabled {
        bytes32 leaf = toLeaf(currentEpoch, msg.sender, amountToClaim);
        /// @dev make sure the merkle proof validates the claim
        if(!MerkleProof.verify(merkleProof, merkleRoot, leaf)) revert InvalidMerkleProof();
        /// @dev cannot claim same leaf more than oncer per epoch
        if(claimed[leaf]) revert RewardAlreadyClaimed();
        
        claimed[leaf] = true;

        tokenContract.transfer(msg.sender, amountToClaim);

        emit Claimed(msg.sender, currentEpoch, amountToClaim);
    }

    function claimsDisabled() external view returns (bool) {
        return betweenEpochs;
    }

    /**
     *  @notice Ends the current epoch, marks all attributed tokens, ETH and when the epoch has ended
     */
    function endEpoch(
        uint256 epochNumber,
        uint256 ethAttributed,
        address[] memory ethSwapPath,
        uint256 ethReturnMin,
        address[] memory tokensAttributed,
        uint256[] memory amountsAttributed,
        address[][] memory swapPaths,
        uint256[] memory amountsOutMin
    ) external onlyAdmin {
        /// @dev make sure the caller knows which epoch they're ending
        if(epochNumber != currentEpoch) revert IncorrectEpoch();

        if(ethAttributed > address(this).balance) {
            revert InsufficientEthBalance(ethAttributed, address(this).balance);
        }
        
        /// @dev make sure our input arrays have matching lengths
        uint256 tokenCount = tokensAttributed.length;
        if(amountsAttributed.length != tokenCount
            || swapPaths.length != tokenCount
            || amountsOutMin.length != tokenCount
        ) revert MismatchedArrayLengths();

        /// @dev pause claims until our the next/new merkle root set
        betweenEpochs = true;

        /// @dev emit event and increment currentEpoch
        emit EpochEnded(currentEpoch, block.timestamp);

        if(ethAttributed > 0 || tokensAttributed.length > 0) {
            /// @dev Execute the token/ETH swaps
            swapMultiple(
                ethAttributed,
                ethSwapPath,
                ethReturnMin,
                tokensAttributed,
                amountsAttributed,
                swapPaths,
                amountsOutMin
            );
        }

        if(treasuryFees > 0) {
            depositTreasuryFees();
        }
    }

    function nextEpoch(bytes32 newMerkleRoot, bytes memory newMerkleCDI) external onlyAdmin {
        if(!betweenEpochs) revert InvalidRequest("Epoch in progress");
        currentEpoch += 1;
        betweenEpochs = false;
        treasuryFees = 0;
        setMerkleRoot(newMerkleRoot, newMerkleCDI);
        emit EpochStarted(currentEpoch);
    }

    function setAdminAddress(address _adminAddress) external onlyOwner {
        emit AdminAddressUpdated(adminAddress, _adminAddress);
        adminAddress = _adminAddress;
    }

    function setDaoAddress(address _daoAddress) external onlyOwner {
        emit DaoAddressUpdated(daoAddress, _daoAddress);
        daoAddress = _daoAddress;
    }

    function setMinStakeAmount(uint256 _minStakeAmount) external onlyDao {
        emit MinStakeAmountUpdated(minStakeAmount, _minStakeAmount);
        minStakeAmount = _minStakeAmount;
    }

    function setRouterContract(address _routerContract) external onlyOwner {
        emit RouterContractUpdated(address(routerContract), _routerContract);
        routerContract = IUniswapV2Router02(_routerContract);
    }

    /**
     * @notice Sets the swap timeout for ERC20 token swaps via the router contract
     * @param _swapTimeout the new timeout expressed in seconds
     */
    function setSwapTimeout(uint256 _swapTimeout) external onlyOwner {
        emit SwapTimeoutUpdated(swapTimeout, _swapTimeout);
        swapTimeout = _swapTimeout;
    }

    /**
     * @notice Updates the treasury fee recipient address
     * @param _treasuryAddress the new treasury address
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        emit TreasuryAddressUpdated(treasuryAddress, _treasuryAddress);
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice Updates the treasury fee percentage
     * @param _treasuryFeeBps the fee percentage expressed in basis points e.g. 650 is 6.5%
     */
    function setTreasuryFeeBps(uint16 _treasuryFeeBps) external onlyDao {
        if(_treasuryFeeBps > BPS_MAX) revert InvalidTreasuryFee();
        emit TreasuryFeeUpdated(treasuryFeeBps, _treasuryFeeBps);
        treasuryFeeBps = _treasuryFeeBps;
    }

    //
    // Internal functions =========================================================================
    //

    /**
     * @notice Transfer cumulative treasury fees if any to `treasuryAddress`
     */
    function depositTreasuryFees() internal {
        uint256 _treasuryFees = treasuryFees;
        treasuryFees = 0;
        tokenContract.transfer(treasuryAddress, _treasuryFees);
        emit DepositedTreasuryFees(treasuryAddress, _treasuryFees);
    }

    /**
     *  @notice Calculates a leaf of the tree in bytes format (to be passed for verification).
     *      The leaf includes the epoch number which means they are unique across epochs
     *      for identical addresses and claim amounts. Leaves are double-hashed to prevent
     *      second preimage attacks, see:
     * 
     *      https://flawed.net.nz/2018/02/21/attacking-merkle-trees-with-a-second-preimage-attack/
     */
    function toLeaf(uint256 epoch, address addr, uint256 amount)
        internal
        pure
        returns (bytes32) {
        return keccak256(
            bytes.concat(
                keccak256(
                    abi.encode(epoch, addr, amount)
                )
            )
        );
    }

    /**
     * @param newMerkleRoot the newly calculated root of the tree after all user info is updated
     *        at the end of an epoch
     * @param newMerkleCDI the new CDI on IPFS where the file to rebuild the Merkle Tree is
     *        contained
     */
    function setMerkleRoot(bytes32 newMerkleRoot, bytes memory newMerkleCDI) internal {
        merkleRoot = newMerkleRoot;
        emit MerkleProofCIDUpdated(newMerkleCDI);
    }

    /**
     *  @notice Does a bunch of swaps with all tokens in tokensIn. Also swaps ETH for tokenContract
     *          if transaction value > 0.
     *  @dev amountsOutMin array should be passed with the right minimum amounts calculated
     *       otherwise the transaction would fail.
     */
    function swapMultiple(
        uint256 ethAttributed,
        address[] memory ethSwapPath,
        uint256 ethReturnMin,
        address[] memory tokensAttributed,
        uint256[] memory amountsAttributed,
        address[][] memory swapPaths,
        uint256[] memory amountsOutMin
    ) internal {

        if (ethAttributed > 0) {
            _swapEth(ethAttributed, ethSwapPath, ethReturnMin);
        }

        address currentTokenToSwap;
        uint256 tokenAmount;

        /// @dev iterate over tokens and swap each of them
        for (uint256 i = 0; i < tokensAttributed.length;) {
            
            currentTokenToSwap = tokensAttributed[i];
            tokenAmount = amountsAttributed[i];

            if(tokenAmount > IERC20(currentTokenToSwap).balanceOf(address(this))) {
                revert InsufficientTokenBalance(
                    currentTokenToSwap,
                    tokenAmount,
                    IERC20(currentTokenToSwap).balanceOf(address(this))
                );
            }

            if(currentTokenToSwap == address(tokenContract)) {
                /// @dev no swap needs to occur in this case
                _finalizeErc20Swap(currentTokenToSwap, tokenAmount);
            }
            else {
                IERC20(currentTokenToSwap).approve(
                    address(routerContract),
                    tokenAmount
                );

                _swapErc20(tokenAmount, amountsOutMin[i], swapPaths[i]);
            }

            /// @dev gas savings, can't overflow bc constrained by our array's length
            unchecked {
                i++;
            }
        }
    }

    //
    // Private functions ==========================================================================
    //

    /**
     * @notice Possibly apply treasury fee to swapped token amount and emit swap event
     * @param tokenAmount the amount of reward tokens received from the token/Eth swap
     */
    function _applyFee(uint256 tokenAmount) private returns (uint256) {
        if(treasuryFeeBps > 0) {
            uint256 feeAmount = treasuryFeeBps * tokenAmount / BPS_MAX;
            tokenAmount -= feeAmount;
            treasuryFees += feeAmount;
            emit TreasuryFeeTaken(currentEpoch, feeAmount);
        }

        return tokenAmount;
    }

    function _finalizeErc20Swap(address tokenAddress, uint256 tokenAmount) private {
        uint256 netTokenAmount = _applyFee(tokenAmount);
        emit TokensSwapped(tokenAmount, netTokenAmount, currentEpoch, tokenAddress);
    }

    /**
     *  @dev Swaps tokens in path with the recipient being this contract
     *  @dev The optimal path relies on being accepted externally
     */
    function _swapErc20(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    ) private {
        uint256[] memory amounts = routerContract.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + swapTimeout
        );

        _finalizeErc20Swap(path[0], amounts[1]);
    }

    function _swapEth(uint256 ethAmount, address[] memory ethSwapPath, uint256 ethReturnMin) private {
        uint256[] memory amounts = routerContract.swapExactETHForTokens{
            value: ethAmount
        }(
            ethReturnMin,
            ethSwapPath,
            address(this),
            block.timestamp + swapTimeout
        );

        uint256 netTokenAmount = _applyFee(amounts[1]);

        emit EthSwapped(amounts[1], netTokenAmount, currentEpoch);
    }

    //
    // Errors/events ==============================================================================
    //

    error ClaimsDisabledUntilNextEpoch();
    error IncorrectEpoch();
    error InvalidEpoch();
    error InvalidMerkleProof();
    error InvalidRequest(string msg);
    error InvalidTreasuryFee();
    error InsufficientEthBalance(uint256 required, uint256 actual);
    error InsufficientTokenBalance(address token, uint256 required, uint256 actual);
    error MismatchedArrayLengths();
    error NoTokensAttributed();
    error OnlyAdmin();
    error OnlyDao();
    error RewardAlreadyClaimed();

    event AdminAddressUpdated(address indexed from, address indexed to);
    event Claimed(address indexed account, uint256 epoch, uint256 amount);
    event DaoAddressUpdated(address indexed from, address indexed to);
    event DepositedTreasuryFees(address indexed addr, uint256 amount);
    event EpochEnded(uint256 endedEpochNum, uint256 timestamp);
    event EpochStarted(uint256 epochNumber);
    event EthSwapped(uint256 swapAmountOut, uint256 receivedTokens, uint256 epoch);
    event MerkleProofCIDUpdated(bytes newMerkleCDI);
    event MinStakeAmountUpdated(uint256 from, uint256 to);
    event RouterContractUpdated(address indexed from, address indexed to);
    event SwapTimeoutUpdated(uint256 from, uint256 to);
    event TokensSwapped(uint256 swapAmountOut, uint256 receivedTokens, uint256 epoch, address indexed tokenAddress);
    event TreasuryAddressUpdated(address indexed from, address indexed to);
    event TreasuryFeeTaken(uint256 epoch, uint256 amount);
    event TreasuryFeeUpdated(uint256 from, uint256 to);
}