/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// SPDX-License-Identifier: UNLICENSED
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File contracts/utils/IOtoCoMaster.sol

pragma solidity ^0.8.0;

interface IOtoCoMaster {

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev See {OtoCoMaster-baseFee}.
     */
    function baseFee() external view returns (uint256 fee);

    receive() external payable;
}


// File contracts/utils/IOtoCoPlugin.sol

pragma solidity ^0.8.0;

interface IOtoCoPlugin {

    /**
     * Plugin initializer with a fuinction template to be used.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     *
     * @param pluginData The parameters to create a new instance of plugin.
     */
    function addPlugin(uint256 seriesId, bytes calldata pluginData) external payable;

    /**
     * Allow attach a previously deployed plugin if possible
     * @dev This function should run enumerous amounts of verifications before allow the attachment.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     *
     * @param pluginData The parameters to remove a instance of the plugin.
     */
    function attachPlugin(uint256 seriesId, bytes calldata pluginData) external payable;

    /**
     * Plugin initializer with a fuinction template to be used.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     *
     * @param pluginData The parameters to remove a instance of the plugin.
     */
    function removePlugin(uint256 seriesId, bytes calldata pluginData) external payable;
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/OtoCoPlugin.sol

pragma solidity ^0.8.0;



abstract contract OtoCoPlugin is IOtoCoPlugin, Ownable {

    // Reference to the OtoCo Master to transfer plugin cost
    IOtoCoMaster public otocoMaster;

    /**
     * Modifier to allow only series owners to change content.
     * @param tokenId The plugin index to update.
     */
    modifier onlySeriesOwner(uint256 tokenId) {
        require(otocoMaster.ownerOf(tokenId) == msg.sender, "OtoCoPlugin: Not the entity owner.");
        _;
    }

    /**
     * Modifier to check if the function set the correct amount of ETH value and transfer it to master.
     * If baseFee are 0 or sender is OtoCoMaster this step is jumped.
     * @dev in the future add/attact/remove could be called from OtoCo Master. In those cases no transfer should be called.
     */
    modifier transferFees() {
        if (otocoMaster.baseFee() > 0 && msg.sender != address(otocoMaster)) payable(otocoMaster).transfer(msg.value);
        _;
    }

    constructor(address payable _otocoMaster) Ownable() {
        otocoMaster = IOtoCoMaster(_otocoMaster);
    }

    /**
     * Plugin initializer with a fuinction template to be used.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     * @dev Override this function to implement your elements.
     * @param pluginData The parameters to create a new instance of plugin.
     */
    function addPlugin(uint256 seriesId, bytes calldata pluginData) external payable virtual override;

    /**
     * Allow attach a previously deployed plugin if possible
     * @dev This function should run enumerous amounts of verifications before allow the attachment.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     * @dev Override this function to implement your elements.
     * @param pluginData The parameters to remove a instance of the plugin.
     */
    function attachPlugin(uint256 seriesId, bytes calldata pluginData) external payable virtual override {
        revert("OtoCoPlugin: Attach elements are not possible on this plugin.");
    }

    /**
     * Plugin initializer with a fuinction template to be used.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     * @dev Override this function to implement your elements.
     * @param pluginData The parameters to remove a instance of the plugin.
     */
    function removePlugin(uint256 seriesId, bytes calldata pluginData) external payable virtual override {
        revert("OtoCoPlugin: Remove elements are not possible on this plugin.");
    }
}


// File contracts/plugins/Multisig.sol

pragma solidity ^0.8.0;


interface GnosisSafeProxyFactory {
    function createProxy(address singleton, bytes memory data) external returns (address proxy);
}

/**
 * Multisig
 */
contract Multisig is OtoCoPlugin {

    event MultisigAdded(uint256 indexed series, address multisig);
    event MultisigRemoved(uint256 indexed series, address multisig);

    address public gnosisMasterCopy;
    address public gnosisProxyFactory;

    mapping(uint256 => uint256) public multisigPerEntity;
    mapping(uint256 => address[]) public multisigDeployed;

    constructor(
        address payable otocoMaster,
        address masterCopy,
        address proxyFactory,
        uint256[] memory prevIds,
        address[] memory prevMultisig
    ) OtoCoPlugin(otocoMaster) {
        gnosisMasterCopy = masterCopy;
        gnosisProxyFactory = proxyFactory;
        for (uint i = 0; i < prevIds.length; i++ ) {
            multisigDeployed[prevIds[i]].push(prevMultisig[i]);
            multisigPerEntity[prevIds[i]]++;
            emit MultisigAdded(prevIds[i], prevMultisig[i]);
        }
    }

    function updateGnosisMasterCopy(address newAddress) public onlyOwner {
        gnosisMasterCopy = newAddress;
    }

    function updateGnosisProxyFactory(address newAddress) public onlyOwner {
        gnosisProxyFactory = newAddress;
    }

    function addPlugin(uint256 seriesId, bytes calldata pluginData) public onlySeriesOwner(seriesId) transferFees() payable override {
        address proxy = GnosisSafeProxyFactory(gnosisProxyFactory).createProxy(gnosisMasterCopy, pluginData);
        multisigDeployed[seriesId].push(proxy);
        multisigPerEntity[seriesId]++;
        emit MultisigAdded(seriesId, proxy);
    }

    /**
    * Attaching a pre-existing multisig to the entity
    * @dev seriesId Series to remove token from
    * @dev newMultisig Multisig address to be attached
    *
    * @param pluginData Encoded parameters to create a new token.
     */
    function attachPlugin(uint256 seriesId, bytes calldata pluginData) public onlySeriesOwner(seriesId) transferFees() payable override {
        (
            address newMultisig
        ) = abi.decode(pluginData, ( address));
        multisigDeployed[seriesId].push(newMultisig);
        multisigPerEntity[seriesId]++;
        emit MultisigAdded(seriesId, newMultisig);
    }

    function removePlugin(uint256 seriesId, bytes calldata pluginData) public onlySeriesOwner(seriesId) transferFees() payable override {
        (
            uint256 toRemove
        ) = abi.decode(pluginData, (uint256));
        address multisigRemoved = multisigDeployed[seriesId][toRemove];
        // Copy last token to the removed slot
        multisigDeployed[seriesId][toRemove] = multisigDeployed[seriesId][multisigDeployed[seriesId].length - 1];
        // Remove the last token from array
        multisigDeployed[seriesId].pop();
        multisigPerEntity[seriesId]--;
        emit MultisigRemoved(seriesId, multisigRemoved);
    }

}