// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";

contract MerkleRewardsDistributor is Ownable, ReentrancyGuard {
    /// @notice Used in _swapMultiple so that the optimal swap path is passed externally.
    struct tokenToSwap {
        address _tokenAddress;
        address[] _path;
    }

    IUniswapV2Router02 public routerContract;

    address private _wethContractAddress;

    address private _xyzContractAddress;

    bytes32 public merkleRoot;
    IERC20 public tokenContract;

    mapping(address => uint256) public claimedTokensPerUser;
    mapping(uint256 => bool) public claimedIndex;

    mapping(address => uint256) public totalTokensAttributed;
    uint256 private _currentEtherToSwap;

    uint256 private _epochsCount;

    mapping(address => address[]) paths;

    // uint256 taxPercentage;

    event Claimed(uint256 index, address account, uint256 amount);
    event EpochEnded(
        uint256 endedEpochNum,
        uint256 timestamp,
        uint256 addedTokensInEpoch
    );
    event XYZReceived(uint256 receivedXYZ);
    event MerkleProofCIDUpdated(bytes32 _newMerkleCDI);

    constructor(
        address _tokenContract,
        address _initialRouterAddress,
        address _wethAddress,
        address _xyzAddress
    ) {
        tokenContract = IERC20(_tokenContract);
        routerContract = IUniswapV2Router02(_initialRouterAddress);
        _wethContractAddress = _wethAddress;
        _xyzContractAddress = _xyzAddress;
    }

    function setRoot(bytes32 _merkleRoot, bytes32 _newMerkleCDI)
        external
        onlyOwner
    {
        merkleRoot = _merkleRoot;
        emit MerkleProofCIDUpdated(_newMerkleCDI);
    }

    // TODO: Maybe we'll need the ERC20 contract address also here ? Because every user can claim a different token
    // TODO: Do we need require(msg.sender == userAddress) ? Currently everyone can invoke this function.
    function claim(
        uint256 _epoch,
        uint256 leafIndex,
        address userAddress,
        uint256 totalTokenAmount,
        bytes32[] calldata merkleProof
    ) public nonReentrant {
        require(
            _epoch <= getCurrentEpoch(),
            "This epoch id hasn't been mined yet"
        );
        require(
            isInState(leafIndex, userAddress, totalTokenAmount, merkleProof),
            "MerkleRewardsDistributor: Invalid proof."
        );
        require(
            !claimedIndex[leafIndex],
            "MerkleRewardsDistributor: Reward already claimed."
        );

        uint256 tokensToDistribute = (totalTokenAmount >
            claimedTokensPerUser[userAddress])
            ? (totalTokenAmount - claimedTokensPerUser[userAddress])
            : 0;

        require(
            tokensToDistribute > 0,
            "MerkleRewardsDistributor: No reward available for distribution."
        );

        tokenContract.transfer(userAddress, tokensToDistribute);

        claimedTokensPerUser[userAddress] = totalTokenAmount;
        claimedIndex[leafIndex] = true;

        emit Claimed(leafIndex, userAddress, tokensToDistribute);
    }

    function isInState(
        uint256 leafIndex,
        address userAddress,
        uint256 totalTokenAmount,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        bytes32 node = keccak256(
            abi.encodePacked(leafIndex, userAddress, totalTokenAmount)
        );
        return MerkleProof.verify(merkleProof, merkleRoot, node);
    }

    /// @notice Ends the current epoch and marks all attributed tokens and ETH.
    function endEpoch(
        address[] calldata tokensAttributed,
        uint256[] calldata amountsAttributed
    ) external payable onlyOwner {
        if (msg.value > 0) {
            _currentEtherToSwap = msg.value;
        }
        uint256 tokensAttribLen = tokensAttributed.length;

        require(
            tokensAttribLen == amountsAttributed.length,
            "Number of tokens attributed should be equal to number of amounts attributed"
        );

        uint256 totalRoyalties = 0;

        for (uint256 i = 0; i < tokensAttribLen; ++i) {
            totalTokensAttributed[tokensAttributed[i]] += amountsAttributed[i];
            totalRoyalties += amountsAttributed[i];
        }

        emit EpochEnded(_epochsCount, block.timestamp, totalRoyalties);
        _epochsCount++;
    }

    /// @notice Swaps _tokenIn for _tokenOut with the recipient being this contract.
    /// @notice Note that you provide a minimum amount of T2. If the minimum amount is too high, transaction will revert. Otherwise, you get the max possible amount of T2 depending on the amount of T1 you provide.
    /// @dev Transaction may revert if a direct swap between the two tokens doesn't exist.
    function _swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory path
    ) private {
        uint256[] memory amounts = routerContract.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            address(this),
            block.timestamp + 15 minutes
        );

        emit XYZReceived(amounts[1]);
    }

    /// @notice Swaps all tokens in _tokensIn for $XYZ. Also swaps ETH for $XYZ if transaction value > 0.
    function swapMultiple(
        uint256[] calldata _amountsOutMin,
        tokenToSwap[] calldata _tokensIn
    ) external payable onlyOwner {
        uint256 tokensToBeSwappedLen = _tokensIn.length;

        if (msg.value > 0) {
            address[] memory path = new address[](2);
            path[0] = _wethContractAddress;
            path[1] = _xyzContractAddress;

            uint256[] memory amounts = routerContract.swapExactETHForTokens{
                value: msg.value
            }(
                _amountsOutMin[0],
                path,
                address(this),
                block.timestamp + 15 minutes
            );
            _currentEtherToSwap = _currentEtherToSwap - msg.value;
            emit XYZReceived(amounts[1]);
        }

        for (uint256 i = 0; i < tokensToBeSwappedLen; ++i) {
            address currentTokenToSwap = _tokensIn[i]._tokenAddress;

            uint256 amountToSwap = totalTokensAttributed[currentTokenToSwap];

            require(amountToSwap > 0, "Not enough amount attributed");
            IERC20(currentTokenToSwap).approve(
                address(routerContract),
                amountToSwap
            );
            _swap(amountToSwap, _amountsOutMin[i + 1], _tokensIn[i]._path);
        }
    }

    function getCurrentEpoch() public view returns (uint256) {
        return _epochsCount;
    }

    function setRouterContract(address _newRouterContractAddress)
        external
        onlyOwner
    {
        routerContract = IUniswapV2Router02(_newRouterContractAddress);
    }

    function routerContractAddress() external view returns (address) {
        return address(routerContract);
    }

    function setXYZContract(address _newXYZAddress) external onlyOwner {
        _xyzContractAddress = _newXYZAddress;
    }

    function xyzContract() external view returns (address) {
        return _xyzContractAddress;
    }

    function setWETHContract(address _newWETHAddress) external onlyOwner {
        _wethContractAddress = _newWETHAddress;
    }

    function WETH() external view returns (address) {
        return _wethContractAddress;
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