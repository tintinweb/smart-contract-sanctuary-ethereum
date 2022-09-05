// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./interfaces/ICore.sol";
import "./interfaces/IOpenseaFactory.sol";
import "./interfaces/IRoyaltySplitter.sol";
import "./interfaces/INFT.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

import "@openzeppelin/contracts/access/Ownable.sol";


contract Core is Ownable, ICore {

    bytes32 constant private SALTER = hex"10";

    // Slot 1, 2, 3: 
    address public immutable NFT_IMPLEMENTATION;
    address public immutable OPENSEA_MINTER_IMPLEMENTATION;
    address public immutable ROYALTY_SPLITTER_IMPLEMENTATION;

    constructor(address nftImp, address openseaImp, address splitterImp) {
        NFT_IMPLEMENTATION = nftImp;
        OPENSEA_MINTER_IMPLEMENTATION = openseaImp;
        ROYALTY_SPLITTER_IMPLEMENTATION = splitterImp;
    }

    function newNFT(NewNFTParams calldata params) external onlyOwner returns(address) {
        address nft = Clones.cloneDeterministic(NFT_IMPLEMENTATION, params.nftSalt);
        bytes32 salt = _salt(nft);

        address openseaMinter = Clones.cloneDeterministic(OPENSEA_MINTER_IMPLEMENTATION, salt);
        address splitter = Clones.cloneDeterministic(ROYALTY_SPLITTER_IMPLEMENTATION, salt);
        address splitterFirstSale = Clones.cloneDeterministic(ROYALTY_SPLITTER_IMPLEMENTATION, _alterSalt(salt));

        INFT(nft).initialize(
            params.name,
            params.symbol,
            params.baseURI,
            params.totalSupply,
            params.royaltyInBasisPoints,
            openseaMinter,
            splitter
        );
        IRoyaltySplitter(splitter).initialize(
            params.royals.accounts, params.royals.shares
        );
        IOpenseaFactory(openseaMinter).initialize(
            params.owner,
            splitterFirstSale,
            params.royaltyInBasisPointsFirstSale,
            nft,
            params.premint
        );
        IRoyaltySplitter(splitterFirstSale).initialize(
            params.royalsFirstSale.accounts, params.royalsFirstSale.shares
        );

        emit NewNFT(nft, openseaMinter, splitter, splitterFirstSale, params);
        return nft;
    }

    function _salt(address nft) private pure returns(bytes32) {
        return bytes32(abi.encode(nft));
    }

    function _alterSalt(bytes32 salt) private pure returns(bytes32) {
        return salt | SALTER;
    }

    function setImplementation(Imp implementation, address newImp) public onlyOwner {
        require(implementation != Imp.NONE);
        assembly {
            sstore(implementation, newImp)
        }
    }

    function getNFTBySalt(bytes32 salt) external view returns(address) {
        return Clones.predictDeterministicAddress(NFT_IMPLEMENTATION, salt);
    }

    function getOpenseaMinterByNFT(address nft) external view returns(address) {
        return Clones.predictDeterministicAddress(
            OPENSEA_MINTER_IMPLEMENTATION, 
            _salt(nft)
        );
    }

    function getRoyaltySplitterByNFT(address nft) external view returns(address) {
        return Clones.predictDeterministicAddress(
            ROYALTY_SPLITTER_IMPLEMENTATION, 
            _salt(nft)
        );
    }

    function getRoyaltySplitterFirstSaleByNFT(address nft) external view returns(address) {
        return Clones.predictDeterministicAddress(
            ROYALTY_SPLITTER_IMPLEMENTATION, 
            _alterSalt(_salt(nft))
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IRoyaltySplitter {
    function initialize(address[] calldata royaltyRecipients, uint256[] calldata _shares) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IOpenseaFactory {
    
    function initialize(
        address _owner,
        address _splitter,
        uint256 royaltyInBasisPoints, 
        address _underlyingNFT, 
        uint256 premint
    ) external;

    function emitEvents(uint256 start, uint256 end) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface INFT {
    function initialize( 
        string calldata name_, 
        string calldata symbol_,
        string calldata baseURI,
        uint256 totalSupply,
        uint256 royaltyInBasisPoints,
        address _minter,
        address splitter
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface ICore {
    enum Imp {
        NONE,
        NFT,
        OPENSEA,
        SPLITTER
    }

    struct Royals {
        address[] accounts;
        uint256[] shares;
    }

    struct NewNFTParams {
        string name;
        string symbol;
        string baseURI;
        bytes32 nftSalt;
        address owner;
        uint256 totalSupply;
        uint256 premint;
        Royals royals;
        uint256 royaltyInBasisPoints;
        Royals royalsFirstSale;
        uint256 royaltyInBasisPointsFirstSale;
    }

    event NewNFT(
        address nft, 
        address openseaMinter, 
        address splitter, 
        address splitterFirstSale, 
        NewNFTParams params
    );

    function newNFT(NewNFTParams calldata params) external returns(address);
   
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