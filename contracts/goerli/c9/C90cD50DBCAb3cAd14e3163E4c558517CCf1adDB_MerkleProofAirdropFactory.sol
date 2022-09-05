//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

interface IClonableWhitelistReference {
  function initialize(bytes32 merkleRoot) external;
}

interface IClonableAirdropMinimal1155Reference {
  function initialize(
    address merkleProofWhitelist,
    address tokenContract,
    uint256 tokenId,
    uint256 startTime,
    uint256 endTime,
    address _admin,
    address _payout
  ) external;
}

interface IClonableERC1155Reference {
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory tokenURI,
        address admin,
        address factory,
        address minter
    ) external;
    function grantRole(
        bytes32 role,
        address account
    ) external;
    function setTokenURI(
        uint256 _tokenId,
        string memory _tokenURI
    ) external;
    function tokenIdToURI(
        uint256 _tokenId
    ) external returns (string memory);
}

contract MerkleProofAirdropFactory is Ownable {

    event NewMerkle1155AirdropClone(
        uint256 indexed id,
        address indexed referenceContract,
        address indexed airdropClone,
        address merkleProofWhitelist,
        uint256 startTime,
        uint256 endTime
    );

    event NewMerkleWhitelistClone(
        address indexed referenceContract,
        address indexed merkleProofWhitelistClone
    );

    event NewERC1155Clone(
        address indexed referenceContract,
        address indexed erc1155Clone
    );

    event SetClonableAirdropReferenceValidity(
        address indexed referenceContract,
        bool validity
    );

    event SetClonableWhitelistReferenceValidity(
        address indexed referenceContract,
        bool validity
    );

    event SetClonableERC1155ReferenceValidity(
        address indexed referenceContract,
        bool validity
    );

    mapping(address => bool) public validClonableERC1155References;
    mapping(address => bool) public validClonableAirdropReferences;
    mapping(address => bool) public validClonableWhitelistReferences;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Controlled variables
    using Counters for Counters.Counter;
    Counters.Counter private _airdropIds;

    constructor(
        address _clonableERC1155,
        address _clonableMerkleAirdrop,
        address _clonableMerkleWhitelist
    ) {
        validClonableERC1155References[_clonableERC1155] = true;
        validClonableAirdropReferences[_clonableMerkleAirdrop] = true;
        validClonableWhitelistReferences[_clonableMerkleWhitelist] = true;
        emit SetClonableERC1155ReferenceValidity(_clonableERC1155, true);
        emit SetClonableWhitelistReferenceValidity(_clonableMerkleWhitelist, true);
        emit SetClonableAirdropReferenceValidity(_clonableMerkleAirdrop, true);
    }

    function newMerkleAirdrop(
        address _airdropReferenceContract,
        address _whitelistContract,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _startTime,
        uint256 _endTime,
        address _admin,
        address _payout
    ) external onlyOwner {
        require(validClonableAirdropReferences[_airdropReferenceContract], "INVALID_AIRDROP_REFERENCE_CONTRACT");
        _airdropIds.increment();
        uint256 newAirdropId = _airdropIds.current();
        // Deploy new airdrop contract
        address newAirdropCloneAddress = Clones.clone(_airdropReferenceContract);
        IClonableAirdropMinimal1155Reference newAirdropClone = IClonableAirdropMinimal1155Reference(newAirdropCloneAddress);
        newAirdropClone.initialize(_whitelistContract, _tokenContract, _tokenId, _startTime, _endTime, _admin, _payout);
        emit NewMerkle1155AirdropClone(newAirdropId, _airdropReferenceContract, newAirdropCloneAddress, _whitelistContract, _startTime, _endTime);
        // Set the airdrop contract as a minter of the NFT contract
        IClonableERC1155Reference existingERC1155Clone = IClonableERC1155Reference(_tokenContract);
        existingERC1155Clone.grantRole(MINTER_ROLE, newAirdropCloneAddress);
    }

    function newMerkleWhitelist(
        address _whitelistReferenceContract,
        bytes32 _merkleRoot
    ) external onlyOwner {
        require(validClonableWhitelistReferences[_whitelistReferenceContract], "INVALID_WHITELIST_REFERENCE_CONTRACT");
        // Deploy new whitelist contract
        address newWhitelistCloneAddress = Clones.clone(_whitelistReferenceContract);
        IClonableWhitelistReference newWhitelistClone = IClonableWhitelistReference(newWhitelistCloneAddress);
        newWhitelistClone.initialize(_merkleRoot);
        emit NewMerkleWhitelistClone(_whitelistReferenceContract, newWhitelistCloneAddress);
    }

    function newERC1155(
        address _erc1155ReferenceContract,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenURI,
        address _admin,
        address _minter
    ) external onlyOwner {
        require(validClonableERC1155References[_erc1155ReferenceContract], "INVALID_ERC1155_REFERENCE_CONTRACT");
        // Deploy new ERC1155 contract
        address newERC1155CloneAddress = Clones.clone(_erc1155ReferenceContract);
        IClonableERC1155Reference newERC1155Clone = IClonableERC1155Reference(newERC1155CloneAddress);
        newERC1155Clone.initialize(
            _tokenName,
            _tokenSymbol,
            _tokenURI,
            _admin,
            address(this),
            _minter
        );
        emit NewERC1155Clone(_erc1155ReferenceContract, newERC1155CloneAddress);
    }

    function newMerkleAirdropAndWhitelist(
        address _airdropReferenceContract,
        address _whitelistReferenceContract,
        bytes32 _merkleRoot,
        uint256 _startTime,
        uint256 _endTime,
        address _tokenContract,
        uint256 _tokenId,
        string memory _tokenURI,
        address _admin,
        address _payout
    ) external onlyOwner {
        require(validClonableAirdropReferences[_airdropReferenceContract], "INVALID_AIRDROP_REFERENCE_CONTRACT");
        require(validClonableWhitelistReferences[_whitelistReferenceContract], "INVALID_WHITELIST_REFERENCE_CONTRACT");
        _airdropIds.increment();
        uint256 newAirdropId = _airdropIds.current();
        // Deploy new whitelist contract
        address newWhitelistCloneAddress = cloneAndInitWhitelist(_whitelistReferenceContract, _merkleRoot);
        // Deploy new airdrop contract
        address newAirdropCloneAddress = Clones.clone(_airdropReferenceContract);
        initAirdropClone(newAirdropCloneAddress, newWhitelistCloneAddress, _tokenContract, _tokenId, _startTime, _endTime, _admin, _payout);
        emit NewMerkle1155AirdropClone(newAirdropId, _airdropReferenceContract, newAirdropCloneAddress, newWhitelistCloneAddress, _startTime, _endTime);
        // Set the airdrop contract as a minter of the NFT contract
        IClonableERC1155Reference existingERC1155Clone = IClonableERC1155Reference(_tokenContract);
        existingERC1155Clone.grantRole(MINTER_ROLE, newAirdropCloneAddress);
        // Set the tokenURI of the new token ID if there isn't one set already
        if(keccak256(bytes(existingERC1155Clone.tokenIdToURI(_tokenId))) == keccak256(bytes(""))) {
            existingERC1155Clone.setTokenURI(_tokenId, _tokenURI);
        }
    }

    function newMerkleAirdropAndWhitelistAndERC1155(
        address _airdropReferenceContract,
        address _whitelistReferenceContract,
        address _erc1155ReferenceContract,
        bytes32 _merkleRoot,
        uint256 _startTime,
        uint256 _endTime,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenURI,
        address _tokenAdmin,
        address _payout
    ) external onlyOwner {
        require(validClonableAirdropReferences[_airdropReferenceContract], "INVALID_AIRDROP_REFERENCE_CONTRACT");
        _airdropIds.increment();
        uint256 newAirdropId = _airdropIds.current();
        // Deploy new airdrop contract
        address newAirdropCloneAddress = Clones.clone(_airdropReferenceContract);
        // Deploy and init new whitelist contract
        address newWhitelistCloneAddress = cloneAndInitWhitelist(_whitelistReferenceContract, _merkleRoot);
        // Deploy and init new ERC1155 contract
        address newERC1155CloneAddress = cloneAndInitERC1155(
            _erc1155ReferenceContract,
            _tokenName,
            _tokenSymbol,
            _tokenURI,
            _tokenAdmin,
            newAirdropCloneAddress
        );
        // Initialize new airdrop contract
        initAirdropClone(newAirdropCloneAddress, newWhitelistCloneAddress, newERC1155CloneAddress, 1, _startTime, _endTime, _tokenAdmin, _payout);
        emit NewMerkle1155AirdropClone(newAirdropId, _airdropReferenceContract, newAirdropCloneAddress, newWhitelistCloneAddress, _startTime, _endTime);
    }

    function setClonableAirdropReferenceValidity(
        address _airdropReferenceContract,
        bool _validity
    ) external onlyOwner {
        validClonableAirdropReferences[_airdropReferenceContract] = _validity;
        emit SetClonableAirdropReferenceValidity(_airdropReferenceContract, _validity);
    }

    function setClonableWhitelistReferenceValidity(
        address _whitelistReferenceContract,
        bool _validity
    ) external onlyOwner {
        validClonableWhitelistReferences[_whitelistReferenceContract] = _validity;
        emit SetClonableWhitelistReferenceValidity(_whitelistReferenceContract, _validity);
    }

    function setClonableERC1155ReferenceValidity(
        address _erc1155ReferenceContract,
        bool _validity
    ) external onlyOwner {
        validClonableERC1155References[_erc1155ReferenceContract] = _validity;
        emit SetClonableERC1155ReferenceValidity(_erc1155ReferenceContract, _validity);
    }

    // Internal functions

    function initAirdropClone(
        address _clone,
        address _merkleProofWhitelist,
        address _tokenContract,
        uint256 _tokenId,
        uint256 _startTime,
        uint256 _endTime,
        address _admin,
        address _payout
    ) internal {
        IClonableAirdropMinimal1155Reference newAirdropClone = IClonableAirdropMinimal1155Reference(_clone);
        newAirdropClone.initialize(_merkleProofWhitelist, _tokenContract, _tokenId, _startTime, _endTime, _admin, _payout);
    }

    function cloneAndInitWhitelist(
        address _whitelistReferenceContract,
        bytes32 _merkleRoot
    ) internal returns (address) {
        require(validClonableWhitelistReferences[_whitelistReferenceContract], "INVALID_WHITELIST_REFERENCE_CONTRACT");
        // Deploy new whitelist contract
        address newWhitelistCloneAddress = Clones.clone(_whitelistReferenceContract);
        // Initialize new whitelist contract
        IClonableWhitelistReference newWhitelistClone = IClonableWhitelistReference(newWhitelistCloneAddress);
        newWhitelistClone.initialize(_merkleRoot);
        emit NewMerkleWhitelistClone(_whitelistReferenceContract, newWhitelistCloneAddress);
        return newWhitelistCloneAddress;
    }

    function cloneAndInitERC1155(
        address _erc1155ReferenceContract,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenURI,
        address _tokenAdmin,
        address _airdropCloneAddress
    ) internal returns (address) {
        require(validClonableERC1155References[_erc1155ReferenceContract], "INVALID_ERC1155_REFERENCE_CONTRACT");
        // Deploy new ERC1155 contract
        address newERC1155CloneAddress = Clones.clone(_erc1155ReferenceContract);
        // Initialize new ERC1155 contract
        IClonableERC1155Reference newERC1155Clone = IClonableERC1155Reference(newERC1155CloneAddress);
        newERC1155Clone.initialize(
            _tokenName,
            _tokenSymbol,
            _tokenURI,
            _tokenAdmin,
            address(this),
            _airdropCloneAddress
        );
        emit NewERC1155Clone(_erc1155ReferenceContract, newERC1155CloneAddress);
        return newERC1155CloneAddress;
    }

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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