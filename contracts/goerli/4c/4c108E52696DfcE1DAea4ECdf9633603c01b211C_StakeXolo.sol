// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

interface IErc721 {
  function ownerOf(uint256 tokenId) external view returns (address);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

// ERC20
interface ITominToken {
  function mint(address add, uint256 amount) external;
}

interface IErc20 {
  function transfer(address to, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
}

contract StakeXolo is IERC721Receiver, Ownable {
  using Strings for uint256;

  IErc721 theyXolo;
  ITominToken tomin;
  IErc20 ierc20;

  bool public isStarted = true;
  uint8 defaultTokenRate = 100;

  mapping(uint256 => mapping(address => uint256)) private idToStartingTime;
  mapping(address => uint256[]) xolosStaked;
  mapping(uint256 => address) idToStaker;

  constructor(address _theyXoloAddress, address _tominAddress) {
    theyXolo = IErc721(_theyXoloAddress);
    tomin = ITominToken(_tominAddress);
  }

  function stake(uint256[] memory xoloIds) external {
    require(isStarted, '$TOMIN staking paused');

    uint256[] memory _xoloIds = new uint256[](xoloIds.length);

    _xoloIds = xoloIds;

    for (uint256 i; i < _xoloIds.length; i++) {
      require(
        theyXolo.ownerOf(_xoloIds[i]) == msg.sender,
        'Not your They Xolo Token'
      );

      idToStartingTime[_xoloIds[i]][msg.sender] = block.timestamp;

      theyXolo.transferFrom(msg.sender, address(this), _xoloIds[i]);

      idToStaker[_xoloIds[i]] = msg.sender;
      xolosStaked[msg.sender].push(_xoloIds[i]);
    }
  }

  function unstake(uint256[] memory xoloIds) external {
    uint256[] memory _xoloIds = new uint256[](xoloIds.length);

    _xoloIds = xoloIds;

    for (uint256 i; i < _xoloIds.length; i++) {
      require(
        idToStaker[_xoloIds[i]] == msg.sender,
        'Not your They Xolo Token'
      );

      theyXolo.transferFrom(address(this), msg.sender, _xoloIds[i]);

      for (uint256 j; j < xolosStaked[msg.sender].length; j++) {
        if (xolosStaked[msg.sender][j] == _xoloIds[i]) {
          xolosStaked[msg.sender][j] = xolosStaked[msg.sender][
            xolosStaked[msg.sender].length - 1
          ];
          xolosStaked[msg.sender].pop();
          break;
        }
      }

      uint256 current;
      uint256 reward;

      delete idToStaker[_xoloIds[i]];

      if (idToStartingTime[_xoloIds[i]][msg.sender] > 0) {
        uint256 rate = defaultTokenRate;
        current = block.timestamp - idToStartingTime[_xoloIds[i]][msg.sender];

        reward = ((rate * 10**18) * current) / 86400;

        tomin.mint(msg.sender, reward);
        idToStartingTime[_xoloIds[i]][msg.sender] = 0;
      }
    }
  }

  function setStakingState(bool _isStarted) public onlyOwner {
    isStarted = _isStarted;
  }

  function claim() public {
    require(xolosStaked[msg.sender].length > 0, 'No tokens staked');
    uint256[] memory xoloIds = new uint256[](xolosStaked[msg.sender].length);
    xoloIds = xolosStaked[msg.sender];

    uint256 current;
    uint256 reward;
    uint256 rewardbal;

    for (uint256 i; i < xoloIds.length; i++) {
      if (idToStartingTime[xoloIds[i]][msg.sender] > 0) {
        uint256 rate = defaultTokenRate;
        current = block.timestamp - idToStartingTime[xoloIds[i]][msg.sender];
        reward = ((rate * 10**18) * current) / 86400;
        rewardbal += reward;
        idToStartingTime[xoloIds[i]][msg.sender] = block.timestamp;
      }
    }

    tomin.mint(msg.sender, rewardbal);
  }

  function balance(uint256 tokenId) public view returns (uint256) {
    uint256 current;
    uint256 reward;

    if (idToStartingTime[tokenId][msg.sender] > 0) {
      uint256 rate = defaultTokenRate;
      current = block.timestamp - idToStartingTime[tokenId][msg.sender];
      reward = ((rate * 10**18) * current) / 86400;

      return reward;
    }

    return 0;
  }

  function balanceOf(address account) public view returns (uint256) {
    uint256[] memory xoloIds = new uint256[](xolosStaked[account].length);

    xoloIds = xolosStaked[account];

    uint256 current;
    uint256 reward;
    uint256 rewardbal;

    for (uint256 i; i < xoloIds.length; i++) {
      if (idToStartingTime[xoloIds[i]][account] > 0) {
        uint256 rate = defaultTokenRate;

        current = block.timestamp - idToStartingTime[xoloIds[i]][account];
        reward = ((rate * 10**18) * current) / 86400;
        rewardbal += reward;
      }
    }

    return rewardbal;
  }

  function deposits(address account) public view returns (uint256[] memory) {
    return xolosStaked[account];
  }

  function withdrawErc20(address _tokenAddress, address to) public onlyOwner {
    ierc20 = IErc20(_tokenAddress);
    ierc20.transfer(to, ierc20.balanceOf(address(this)));
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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