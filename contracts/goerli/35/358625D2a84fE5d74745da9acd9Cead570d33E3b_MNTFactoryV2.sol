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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.12;

/// @author Monumental Team
/// @title Standard Contract
interface IMNTContract {


    /// Initialize
    /// @param creator creator address
    /// @param pinCode pinCode
    /// @param _nftName nft name
    /// @param _nftSymbol symbol
    /// @param baseUrl baseUrl
    /// @param royalties royalties
    /// @param maxSupply maxSupply
    /// @notice Standard constructor
    function initializeStandard(
        address creator,
        uint256 pinCode,
        string memory _nftName,
        string memory _nftSymbol,
        string memory baseUrl,
        uint256 royalties,
        uint256 maxSupply
    ) external returns (bool);
}

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./IMNTContract.sol";

/// @author Monumental Team
/// @title MNT Factory
contract MNTFactoryV2  is Ownable {

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    address[] private allClones;

    address private mntImplementationStandard;
    address private mntImplementationCommunity;

    event MNTCreatedAddress(address _creator, uint256 pinCode, address _address);

    struct RoyaltiesInfo {
        address recipient;
        uint256 royalties;
    }

    constructor(address implementationAddress) {
        mntImplementationStandard = implementationAddress;
    }

    /// Set implementation standard address
    /// @param _mntImplementationStandard address
    function setImplementationStandard(address _mntImplementationStandard) public onlyOwner {
        mntImplementationStandard = _mntImplementationStandard;
    }

    /// Set implementation community address
    /// @param _mntImplementationCommunity address
    function setImplementationCommunity(address _mntImplementationCommunity) public onlyOwner {
        mntImplementationCommunity= _mntImplementationCommunity;
    }

    /// Checks if contract implements the ERC-2981 interface
    /// @param _contract contract address
    /// @return true if ERC-2981 interface is supported, false otherwise
    function _checkRoyalties(address _contract) internal returns (bool) {
        (bool success) = IERC2981(_contract).
        supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    /// Get the royalities defined on the contract
    /// @param _address contract address
    /// @param _tokenId contract address
    /// @return the royalties information, means receiver and royalties amount
    function getRoyaltiesInfo(address _address, uint256 _tokenId) external payable returns (RoyaltiesInfo memory){

        if (_checkRoyalties(_address)) {
            // Get amount of royalties for 100 ETH (the result will be the percentage) and recipient
            (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(_address).royaltyInfo(_tokenId, 100);
            return RoyaltiesInfo(royaltiesReceiver, royaltiesAmount);
        }
        return RoyaltiesInfo(address(0), 0);
    }

    ///////////////////////

    /// Create a standard edition contract
    /// @param _creator creator address
    /// @param _pinCode pin code
    /// @param _nftName contract name
    /// @param _nftSymbol contract symbol
    /// @param _baseURL base URL of token
    /// @param _royalties royalties
    /// @param _maxSupply max supply
    /// @notice Create a standard edition contract
    function mntCreateStandard(
        address _creator,
        uint256 _pinCode,
        string memory _nftName,
        string memory _nftSymbol,
        string memory _baseURL,
        uint256 _royalties,
        uint256 _maxSupply)
    external returns(address instance) {

        require(mntImplementationStandard != address(0), "invalid implementation address");

        instance = Clones.clone(mntImplementationStandard);

        require(instance != address(0), "clone failed");

        bool success = IMNTContract(payable(instance)).initializeStandard(_creator, _pinCode, _nftName,  _nftSymbol, _baseURL, _royalties, _maxSupply);

        require(success, "init failed");

        allClones.push(instance);

        emit MNTCreatedAddress(_creator, _pinCode, address(instance));

    }

    /// Create a community edition contract
    /// @param _creator creator address
    /// @param _pinCode pin code
    /// @param _nftNameAndSymbol contract name
    /// @param _params parameters
    /// @param _royalties royalties
    /// @param _maxSupply max supply
    /// @param _communityOptions community options
    /// @param _onlyWhitelisted only white listed
    /// @param _whitelistedAddresses whitelisted addresses
    /// @param _feeRecipients fee recipients
    /// @param _feePercentages fee percentages
    /// @notice Create a community edition contract
    function mntCreateCommunity(
        address _creator,
        uint256 _pinCode,
        string[] memory _nftNameAndSymbol,
        string[] memory _params,
        uint8 _royalties,
        uint8 _maxSupply,
        uint256[] memory _communityOptions,
        bool _onlyWhitelisted,
        address[] memory _whitelistedAddresses,
        address[] memory _feeRecipients,
        uint32[] memory _feePercentages
    )
    external returns(address instance) {


/*        MNTContractCommunity community = new MNTContractCommunity(
            _nftNameAndSymbol[0],
            _nftNameAndSymbol[1],
            _params,
            _creator,
            _royalties,
            _maxSupply,
            _communityOptions,
            _onlyWhitelisted,
            _whitelistedAddresses,
            _feeRecipients,
            _feePercentages
        );*/


//        instance = Clones.clone(mntImplementationStandard);
//
//        (bool success1, ) = instance.call(abi.encodeWithSignature("initializeCommunity(address, uint256, string, string, string, uint256, uint256)",_creator, _pinCode, _nftName,  _nftSymbol, _baseURL, _royalties, _maxSupply));
//        require(success1,"init failed");
//
//        allClones.push(instance);
//
//        emit MNTCreatedAddress(_creator, _pinCode, address(instance));

    }


    function getCount()
    public view returns(uint256) {
        return allClones.length;
    }

    function getImplementationStandard()
    public view returns(address) {
    return mntImplementationStandard;
    }

    function getImplementationCommunity()
    public view returns(address) {
    return mntImplementationCommunity;
    }

}