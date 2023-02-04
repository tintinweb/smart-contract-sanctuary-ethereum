// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../nfts/IGivitNFT.sol";
import "../wallet/IGivitNFTWallet.sol";
import "../utils/Ownable.sol";

contract GivitNFTFactory is Ownable {
    address public nftTemplate;
    address public walletTemplate;
    address public forwarder;
    address public minter;
   
    event GivitNFTCollectionCreated(address indexed _nft, address indexed _wallet, address _owner, string _nftUri);
    event ForwarderUpdated(address _forwarder);
    event NFTTemplateUpdated(address _nftTemplate);
    event WalletTemplateUpdated(address _walletTemplate);
    event MinterUpdated(address _minterTemplate);

    constructor (
        address _forwarder,
        address _nftTemplate, 
        address _walletTemplate,
        address _minter
    ) {
        forwarder = _forwarder;
        nftTemplate = _nftTemplate;
        walletTemplate = _walletTemplate;
        minter = _minter;
    }

    function updateForwarder(address _forwarder) external onlyOwner {
        require(_forwarder != address(0), "NullAddress");

        forwarder = _forwarder;
        emit ForwarderUpdated(_forwarder);
    }

    function updateNFTTemplate(address _nftTemplate) external onlyOwner {
        require(_nftTemplate != address(0), "NullAddress");

        nftTemplate = _nftTemplate;
        emit NFTTemplateUpdated(_nftTemplate);
    }

    function updateWalletTemplate(address _walletTemplate) external onlyOwner {
        require(_walletTemplate != address(0), "NullAddress");

        walletTemplate = _walletTemplate;
        emit WalletTemplateUpdated(_walletTemplate);
    }

    function updateMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "NullAddress");

        minter = _minter;
        emit MinterUpdated(_minter);
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        string memory _nftUri,
        uint48 _royaltiesFeeInBips,
        uint256[] calldata _splitPercentagesInBips, 
        address[] calldata _splitWallets
    ) external {
        address nft = Clones.clone(nftTemplate);
        address wallet = Clones.clone(walletTemplate);
        
        IGivitNFTWallet(wallet).initialize(msg.sender, _splitPercentagesInBips, _splitWallets);
        IGivitNFT(nft).initialize(forwarder, _name, _symbol, _nftUri, _royaltiesFeeInBips, wallet, msg.sender);

        emit GivitNFTCollectionCreated(nft, wallet, msg.sender, _nftUri);
    }
}

// SPDX-License-Identifier: CC0-1.0

pragma solidity 0.8.16;

interface IGivitNFTWallet {
    
    function initialize(address _owner, uint256[] memory _splitPercentagesBips, address[] memory _splitWallets) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
    address public owner;
    address public ownerPendingClaim;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewOwnershipProposed(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "OnlyOwner");
        _;
    }

    function proposeChangeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZeroAddress");
        ownerPendingClaim = newOwner;

        emit NewOwnershipProposed(_msgSender(), newOwner);
    }

    function claimOwnership() external {
        require(_msgSender() == ownerPendingClaim, "OnlyProposedOwner");

        ownerPendingClaim = address(0);
        _transferOwnership(_msgSender());
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IGivitNFT {
    
    function initialize(
        address _forwarder,
        string memory _name, 
        string memory _symbol, 
        string memory _uri,
        uint256 _salesFeeInBips, 
        address _salesWallet, 
        address _owner
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeMint(address _to, uint256 _id) external;
    function owner() external returns(address);
    function salesFeeInBips() external returns(uint256);
    function salesWallet() external returns(address);
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