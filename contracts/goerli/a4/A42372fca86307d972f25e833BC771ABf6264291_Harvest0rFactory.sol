pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT

/** 
  @title Harvest0rFactory
  @author lourens.eth
  @notice The Harvest0r Factory is responsible for creating new `Harvest0r`-token pairs.
          Harvest0rs allow holders of an access token to access a market for tokens.

 __    __                                                      __       ______
/  |  /  |                                                    /  |     /      \
$$ |  $$ |  ______    ______   __     __  ______    _______  _$$ |_   /$$$$$$  |  ______
$$ |__$$ | /      \  /      \ /  \   /  |/      \  /       |/ $$   |  $$$  \$$ | /      \
$$    $$ | $$$$$$  |/$$$$$$  |$$  \ /$$//$$$$$$  |/$$$$$$$/ $$$$$$/   $$$$  $$ |/$$$$$$  |
$$$$$$$$ | /    $$ |$$ |  $$/  $$  /$$/ $$    $$ |$$      \   $$ | __ $$ $$ $$ |$$ |  $$/
$$ |  $$ |/$$$$$$$ |$$ |        $$ $$/  $$$$$$$$/  $$$$$$  |  $$ |/  |$$ \$$$$ |$$ |
$$ |  $$ |$$    $$ |$$ |         $$$/   $$       |/     $$/   $$  $$/ $$   $$$/ $$ |
$$/   $$/  $$$$$$$/ $$/           $/     $$$$$$$/ $$$$$$$/     $$$$/   $$$$$$/  $$/


 ________                     __
/        |                   /  |
$$$$$$$$/______    _______  _$$ |_     ______    ______   __    __ 
$$ |__  /      \  /       |/ $$   |   /      \  /      \ /  |  /  |
$$    | $$$$$$  |/$$$$$$$/ $$$$$$/   /$$$$$$  |/$$$$$$  |$$ |  $$ |
$$$$$/  /    $$ |$$ |        $$ | __ $$ |  $$ |$$ |  $$/ $$ |  $$ |
$$ |   /$$$$$$$ |$$ \_____   $$ |/  |$$ \__$$ |$$ |      $$ \__$$ |
$$ |   $$    $$ |$$       |  $$  $$/ $$    $$/ $$ |      $$    $$ |
$$/     $$$$$$$/  $$$$$$$/    $$$$/   $$$$$$/  $$/        $$$$$$$ |
                                                         /  \__$$ |
                                                         $$    $$/
                                                          $$$$$$/
 */

/******************************************************************
 *                            IMPORTS                             *
 ******************************************************************/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/******************************************************************
 *                        INTERFACES                              *
 ******************************************************************/

import "./interfaces/IHarvest0r.sol";
import "./interfaces/IHarvest0rFactory.sol";

contract Harvest0rFactory is IHarvest0rFactory, Ownable {
  /******************************************************************
   *                            EVENTS                              *
   ******************************************************************/
  
  /// A new Token-Harvestor has bee been deployed
  event HarvestorDeployed(address indexed token, address indexed harvestor);

  /******************************************************************
   *                            STORAGE                             *
   ******************************************************************/

  /// The address of the `Harvest0r` implementation
  address private harvestorMaster;
  /// The address of the `Seeds Access Voucher` NFT
  address private seedsNft;
  /// Mapping of token address to `Harvest0r` contract
  mapping(address => address) private tokenHarvestors;
  /// Mapping containing harvestor addresses
  mapping(address => bool) private harvestors;

  /******************************************************************
   *                         Set up                                 *
   ******************************************************************/

  /// @inheritdoc IHarvest0rFactory
  function setup(address implementation, address seeds) external {
    harvestorMaster = implementation;
    seedsNft = seeds;
  }

  /******************************************************************
   *                 HARVEST0R-RELATED FUNCTIONALITY                *
   ******************************************************************/

  /// @inheritdoc IHarvest0rFactory
  function newHarvestor(address targetToken) external returns (address harvestor) {
    if (tokenHarvestors[targetToken] != address(0)) {revert Exists();}

    harvestor = Clones.clone(harvestorMaster);
    IHarvest0r(harvestor).init(seedsNft, targetToken, owner());

    tokenHarvestors[targetToken] = harvestor;
    harvestors[harvestor] = true;

    emit HarvestorDeployed(targetToken, harvestor);
  }

  /// @inheritdoc IHarvest0rFactory
  function isHarvestor(address target) external view returns (bool) {
    return harvestors[target];
  }

  /******************************************************************
   *                       VIEW FUNCTIONS                           *
   ******************************************************************/

  /// @inheritdoc IHarvest0rFactory
  function viewImplementation() external view returns (address) {
    return harvestorMaster;
  }

  /// @inheritdoc IHarvest0rFactory
  function findHarvestor(address token) external view returns (address) {
    return tokenHarvestors[token];
  }
}

pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT

/// @title Harvest0r Interface
/// @author lourens.eth

interface IHarvest0r {

  /******************************************************************
   *                            ERRORS                              *
   ******************************************************************/
  /// The caller does not own the target `SEEDS` NFT
  error NotOwner();
  /// `SEEDS[tokenId`] does not have enough charges
  error UnsufficientCharge();

  /******************************************************************
   *                         INITIALIZE                             *
   ******************************************************************/

  /// @notice Initializes the `Harvest0r` field for the specified token
  /// @param _seeds The address for the `SEEDS` NFT
  /// @param _token The target token to be harvested
  /// @param owner The owner of the Harvestor
  function init(address _seeds, address _token, address owner) external;

  /******************************************************************
   *                    HARVEST0R FUNCTIONALITY                     *
   ******************************************************************/

  /// @notice Allows a user to sell a token for 
  /// @dev The `Havest0r` makes a market and buys a token for `buyAmount`
  /// @param tokenId The target `tokenId` which loses a charge
  /// @param value The amount of `token` to sell for `buyAmount`
  function sellToken(uint256 tokenId, uint256 value) external;

  /******************************************************************
   *                      OWNER FUNCTIONS                           *
   ******************************************************************/

  /// @notice Transfers the bought tokens to `target`
  /// @param target The address to which to transfer the tokens
  /// @param value The amount of tokens to transfer to `target`
  function transferToken(address target, uint256 value) external;

  /******************************************************************
   *                       VIEW FUNCTIONS                           *
   ******************************************************************/

  /// @notice Returns the token this Harvestor is linked to
  /// @return address The address of the token this Harvestor can accept
  function viewToken() external view returns (address);
}

pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT

/// @title Harvest0rFactory Interface
/// @author lourens.eth

interface IHarvest0rFactory {

  /******************************************************************
   *                            ERRORS                              *
   ******************************************************************/

  /// The Harvestor contract for this token exists
  error Exists();

  /******************************************************************
   *                 HARVST0R-RELATED FUNCTIONALITY                 *
   ******************************************************************/

  /// @notice Sets up the Harvestor Factory
  /// @param implementation The address of the MasterCopy for Harvestors
  /// @param seeds The address for the `Seeds Access Voucher` NFTs
  function setup(address implementation, address seeds) external;

  /// @notice Deploys a `Harvest0r` contract for the target token
  /// @param targetToken The token address for the new Harvestor
  /// @return harvestor The address for the newly deployed `Harvest0r`
  function newHarvestor(address targetToken) external returns (address harvestor);

  /// @notice Checks if a contract is a `Harvest0r`
  /// @param target The address of the Harvestor being inspected
  /// @return bool The result of the Harvestor check
  function isHarvestor(address target) external view returns (bool);

  /// @notice Returns the implementation address
  /// @return address The address of the master copy (implementation contract)
  function viewImplementation() external view returns (address);

  /// @notice Returns the harvestor for a given token address
  /// @param token The token address
  /// @return address The address of the Harvestor for this token
  function findHarvestor(address token) external view returns (address);

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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