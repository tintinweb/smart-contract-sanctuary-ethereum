// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
import "./lib/MerkleUtils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title A Rewards Distributor Contract
/// @notice A simple rewards distribution contract, using a Merkle Tree to verify the amount and address of the user claiming ERC20 tokens
/// @dev Functions are intended to be triggered on a specific timeframe (epoch) via a back-end service

contract MerkleRewardsDistributor is Ownable, ReentrancyGuard {
    /// @dev Used in _swapMultiple so that the optimal swap path is passed externally.
    struct tokenToSwap {
        address _tokenAddress;
        address[] _path;
    }

    IUniswapV2Router02 public routerContract;

    address private _wethContractAddress;

    bytes32 public merkleRoot;
    IERC20 public tokenContract;

    mapping(address => uint256) public claimedTokensPerUser;
    mapping(uint256 => bool) public claimedIndex;

    mapping(address => uint256) public totalTokensAttributed; // TODO: Think about public or private
    uint256 private _currentEtherToSwap;

    uint256 private _epochsCount;

    mapping(address => address[]) paths;

    // uint256 taxPercentage;

    event Claimed(uint256 index, address account, uint256 amount);
    event EpochEnded(uint256 endedEpochNum, uint256 timestamp);
    event TokensReceived(uint256 receivedTokens);
    event MerkleProofCIDUpdated(bytes32 indexed _newMerkleCDI);

    constructor(
        address _tokenContract,
        address _initialRouterAddress,
        address _wethAddress
    ) {
        tokenContract = IERC20(_tokenContract);
        routerContract = IUniswapV2Router02(_initialRouterAddress);
        _wethContractAddress = _wethAddress;
    }

    /// @param _merkleRoot the newly calculated root of the tree after all user info is updated at the end of an epoch
    /// @param _newMerkleCDI the new CDI on IPFS where the file to rebuild the Merkle Tree is contained
    function setRoot(bytes32 _merkleRoot, bytes32 _newMerkleCDI)
        public
        onlyOwner
    {
        merkleRoot = _merkleRoot;
        emit MerkleProofCIDUpdated(_newMerkleCDI);
    }

    /// @notice Transfers tokens to the claimer address if he was included in the Merkle Tree with the specified index
    /// @param epoch The id of the epoch with the latest user info
    function claim(
        uint256 epoch,
        uint256 leafIndex,
        address userAddress,
        uint256 amountToClaim,
        bytes32[] calldata merkleProof
    ) public nonReentrant {
        require(msg.sender == userAddress, "Claimer should be userAddress");
        require(
            epoch <= getCurrentEpoch(),
            "The requested epoch is not yet processed"
        );
        require(
            isInState(userAddress, amountToClaim, merkleProof, leafIndex),
            "MerkleRewardsDistributor: Invalid proof."
        );
        require(
            !claimedIndex[leafIndex],
            "MerkleRewardsDistributor: Reward already claimed."
        );
        uint256 tokensToDistribute = (amountToClaim >
            claimedTokensPerUser[userAddress])
            ? (amountToClaim - claimedTokensPerUser[userAddress])
            : 0;

        require(
            tokensToDistribute > 0,
            "MerkleRewardsDistributor: No reward available for distribution."
        );

        tokenContract.transfer(userAddress, tokensToDistribute);

        claimedTokensPerUser[userAddress] = amountToClaim;
        claimedIndex[leafIndex] = true;

        emit Claimed(leafIndex, userAddress, tokensToDistribute);
    }

    /// @notice Asks the tree whether or not a user was included with a specific index and amount of tokens that he is able to claim
    function isInState(
        address userAddress,
        uint256 amountToClaim,
        bytes32[] memory merkleProof,
        uint256 leafIndex
    ) public view returns (bool) {
        return
            _verify(_leaf(userAddress, amountToClaim), merkleProof, leafIndex);
    }

    /// @notice Ends the current epoch, marks all attributed tokens, ETH and when the epoch has ended
    function endEpoch(
        uint256 _etherAmount,
        address[] calldata tokensAttributed,
        uint256[] calldata amountsAttributed
    ) external onlyOwner {
        require(_etherAmount >= 0, "Ether attributed is non-positive");
        if (_etherAmount > 0) {
            _currentEtherToSwap = _etherAmount;
        }
        uint256 tokensAttribLen = tokensAttributed.length;

        require(
            tokensAttribLen == amountsAttributed.length,
            "Number of tokens attributed should be equal to number of amounts attributed"
        );

        for (uint256 i = 0; i < tokensAttribLen; ++i) {
            totalTokensAttributed[tokensAttributed[i]] += amountsAttributed[i];
        }

        emit EpochEnded(_epochsCount, block.timestamp);
        _epochsCount++;
    }

    /// @dev Swaps tokens in path with the recipient being this contract
    /// @dev The optimal path relies on being accepted externally
    function _swap(
        uint256 _amountIn,
        uint256 _amountOutMin,
        address[] memory _path
    ) private {
        uint256[] memory amounts = routerContract.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            address(this),
            block.timestamp + 15 minutes
        );

        emit TokensReceived(amounts[1]);
    }

    /// @notice Does a bunch of swaps with all tokens in _tokensIn. Also swaps ETH for tokenContract if transaction value > 0.
    /// @dev _amountsOutMin array should be passed with the right minimum amounts calculated otherwise the transaction would fail.
    function swapMultiple(
        tokenToSwap[] calldata _tokensIn,
        uint256[] calldata _amountsOutMin
    ) external payable onlyOwner {
        uint256 tokensToBeSwappedLen = _tokensIn.length;
        require(tokensToBeSwappedLen > 0 || msg.value > 0, "Either ETH or ERC-20 tokens should be present for the swap");
        if (msg.value > 0) {
            address[] memory path = new address[](2);
            path[0] = _wethContractAddress;
            path[1] = address(tokenContract);

            uint256[] memory amounts = routerContract.swapExactETHForTokens{
                value: msg.value
            }(
                _amountsOutMin[0],
                path,
                address(this),
                block.timestamp + 15 minutes
            );
            _currentEtherToSwap = _currentEtherToSwap - msg.value;
            emit TokensReceived(amounts[1]);
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
            totalTokensAttributed[currentTokenToSwap] -= amountToSwap;
        }
    }

    ///@dev returns a leaf of the tree in bytes format (to be passed for verification)
    function _leaf(address account, uint256 amountToClaim)
        internal
        view
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(account)), 20),
                ":",
                Strings.toString(amountToClaim)
            );
    }

    ///@dev Verifies whether a leaf is included in the tree with the passed proof and leafIdx
    function _verify(
        bytes memory leaf,
        bytes32[] memory proof,
        uint256 leafIndex
    ) internal view returns (bool) {
        return MerkleUtils.containedInTree(merkleRoot, leaf, proof, leafIndex);
    }

    ///@dev Returns last processed epoch number
    function getCurrentEpoch() public view returns (uint256) {
        return _epochsCount;
    }

    function setRouterContract(address _newRouterContractAddress)
        external
        onlyOwner
    {
        routerContract = IUniswapV2Router02(_newRouterContractAddress);
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

library MerkleUtils {
    function containedInTree(bytes32 merkleRoot, bytes memory data, bytes32[] memory nodes, uint256 index) public view returns(bool) {
        bytes32 hashData = keccak256(data);
        for(uint i = 0; i < nodes.length; i++) {
            if(index % 2 == 1) {
                hashData = keccak256(abi.encodePacked(nodes[i], hashData));
            } else {
                hashData = keccak256(abi.encodePacked(hashData, nodes[i]));
            }
            index /= 2;
        }
        return hashData == merkleRoot;
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