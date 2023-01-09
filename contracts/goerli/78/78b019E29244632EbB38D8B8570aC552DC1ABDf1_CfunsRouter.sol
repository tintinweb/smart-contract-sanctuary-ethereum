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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: GPL-3.0

/// @title The Cfuns router contract
/// @dev Here, the user realizes the interaction between 721 and 1155.

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ICfunsDescriptorMinimal } from './interfaces/ICfunsDescriptorMinimal.sol';
import { ICfunsSeeder } from './interfaces/ICfunsSeeder.sol';
import { ICfunsToken } from './interfaces/ICfunsToken.sol';
import { ICfunsPartToken } from './interfaces/ICfunsPartToken.sol';
import { ICfunsRouter } from './interfaces/ICfunsRouter.sol';


contract CfunsRouter is ICfunsRouter, Ownable{
    // The cfuners DAO address (creators org)
    address public cfunersDAO;

    // An address who has permissions to control this contrant
    address public controller;

    
    // The Cfuns token 
    ICfunsToken public cfunsToken;

    // The Cfuns Parttoken
    ICfunsPartToken public partToken;

     // The Cfuns token URI descriptor
    ICfunsDescriptorMinimal public descriptor;

    // The Cfuns token seeder
    ICfunsSeeder public seeder;

    // Whether the controller can be updated
    bool public isControllerLocked;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;


    constructor(
        address _cfunersDAO,
        address _controller,
        ICfunsToken _cfunsToken,
        ICfunsPartToken _partToken,
        ICfunsDescriptorMinimal _descriptor,
        ICfunsSeeder _seeder
    ) {
        cfunersDAO = _cfunersDAO;
        controller = _controller;
        cfunsToken = _cfunsToken;
        partToken = _partToken;
        descriptor = _descriptor;
        seeder = _seeder;
    }

    /**
     * @notice Require that the Controller has not been locked.
     */
    modifier whenControllerNotLocked() {
        require(!isControllerLocked, 'Controller is locked');
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'Seeder is locked');
        _;
    }

    /**
     * @notice Require that the sender is the cfuners DAO.
     */
    modifier onlyCfunersDAO() {
        require(msg.sender == cfunersDAO, 'Sender is not the cfuners DAO');
        _;
    }

    /**
     * @notice Require that the sender is the controller.
     */
    modifier onlyController() {
        require(msg.sender == controller, 'Sender is not the controller');
        _;
    }

    //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    
    /**
     * @notice mint a cfun token（721）
     * @dev This token is similar to a display panel
     */
    function mintCfun() public returns(uint256) {
        uint256 currentCfunId = cfunsToken.mintTo(msg.sender);
        return currentCfunId;
    }

    /**
     * @notice mint 5个基础部位的parttoken
     * @dev 生成6个随机的属性index（1背景5基础部位），并生成PartToken（1155）
     */
    function mintParts() public returns(uint256[] memory) {
        ICfunsSeeder.Seed memory new_seed = seeder.generateSeed(msg.sender, descriptor);
        uint48[] memory seedIndexs = new uint48[](5);
        seedIndexs[0] = (new_seed.face);
        seedIndexs[1] = (new_seed.hair);
        seedIndexs[2] = (new_seed.eye);
        seedIndexs[3] = (new_seed.mouth);
        seedIndexs[4] = (new_seed.mouth);
        uint256[] memory ids =partToken.mintBatch(msg.sender, seedIndexs);
        return ids;
    }

    /**
     * @notice mint 1个parttoken
     * @dev 生成目标部位的PartToken（1155）
     */
    function mintPart(uint8 partNum, uint48 partIndex) public returns(uint256) {
        uint256 partTokenId = partToken.mint(msg.sender, partNum, partIndex);
        return partTokenId;
    }

    /**
     * @notice 更改指定cfun的seed里的background元素
     * @param backgroundIndex seed的第一个参数，对应descriptor存储的backgrounds的index
     */
    function changeBackground(uint256 cfunId, uint48 backgroundIndex) onlyController public returns(bool) {
        (uint8 down_partNum, ) = cfunsToken.updateSeed(cfunId, msg.sender, 0, backgroundIndex);
        require(down_partNum == 0);
        return true;
    }

    /**
     * @notice 将parttoken加入cfuntoken
     * @dev 将拥有的parttoken的index参数修改到指定ID的cfuntoken的seed中，使用后的1155burn掉
     */
    function addPart(uint256 cfunId, uint256 partTokenId) public returns(bool){
        (uint8 _partNum, uint48 _partIndex) = partToken.getPart(partTokenId, msg.sender);
        require(_partNum > 5,"The basic part cannot use add");
        cfunsToken.updateSeed(cfunId, msg.sender, _partNum, _partIndex);
        return true;
    }

    /**
     * @notice 将parttoken更换cfuntoken里的部件
     * @dev 将拥有的parttoken的index参数修改到指定ID的cfuntoken的seed中，使用后的1155burn掉，换下来的部件
            会被mint成新的1155
     */
    function changePart(uint256 cfunId, uint256 partTokenId)  public returns(uint48){
        (uint8 _partNum, uint48 _partIndex) = partToken.getPart(partTokenId, msg.sender);
        //require(_partNum < 6,"The Additional part cannot use change");
        (uint8 down_partNum, uint48 down_partIndex) = cfunsToken.updateSeed(cfunId, msg.sender, _partNum, _partIndex);
        partToken.mint(msg.sender, down_partNum, down_partIndex);
        return down_partIndex;
    }

    /**
     * @notice 移除指定cfuntoken的某个部件
     * @dev 用户可以选择将指定cfuntoken的任一部件取下并生成1155
            无法移出初始化部件
     */
    function removePart(uint256 cfunId, uint8 down_partNum)  public returns(bool) {
        uint48 down_partIndex = cfunsToken.resetPart(cfunId, msg.sender, down_partNum);
        partToken.mint(msg.sender, down_partNum, down_partIndex);
        return true;

    }

    //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    //                                       setting
    //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    /**
     * @notice Set the cfuners DAO.
     * @dev Only callable by the cfuners DAO when not locked.
     */
    function setCfunersDAO(address _cfunersDAO) external override onlyCfunersDAO {
        cfunersDAO = _cfunersDAO;

        emit CfunersDAOUpdated(_cfunersDAO);
    }

    /**
     * @notice Set the token controller.
     * @dev Only callable by the owner when not locked.
     */
    function setController(address _controller) external override onlyOwner whenControllerNotLocked {
        controller = _controller;

        emit ControllerUpdated(_controller);
    }

    /**
     * @notice Lock the controller.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockController() external override onlyOwner whenControllerNotLocked{
        isControllerLocked = true;

        emit ControllerLocked();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(ICfunsDescriptorMinimal _descriptor) external override onlyOwner  whenDescriptorNotLocked{
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(ICfunsSeeder _seeder) external override onlyOwner  whenSeederNotLocked{
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for NounsDescriptor versions, as used by NounsToken and NounsSeeder.

pragma solidity ^0.8.6;

import { ICfunsSeeder } from './ICfunsSeeder.sol';

interface ICfunsDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, ICfunsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, ICfunsSeeder.Seed memory seed) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function faceCount() external view returns (uint256);

    function hairCount() external view returns (uint256);

    function eyeCount() external view returns (uint256);

    function noseCount() external view returns (uint256);

    function mouthCount() external view returns (uint256);

    function part1Count() external view returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

pragma solidity ^0.8.6;

import { IERC1155 } from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import { ICfunsDescriptorMinimal } from './ICfunsDescriptorMinimal.sol';
import { ICfunsSeeder } from './ICfunsSeeder.sol';

interface ICfunsPartToken is IERC1155 {

    event CfunPartBurned(address from, uint256 cfunId, uint256 amount);

    event RouterUpdated(address router);

    event Mint(address to, uint256 tokenId, uint8 partNum);

    event MintBatch(address to, uint256[] ids, uint256[] amounts);

    event GetPart(uint256 tokenId, address user);

    function setRouter(address _router) external;
    
    function mint(address to, uint8 partNum, uint48 partIndex) external returns(uint256);

    function burn(address from, uint256 cfunId, uint256 amount) external returns(bool);

    function mintBatch(address to, uint48[] calldata seedIndexs) external returns(uint256[] memory);

    function getPart(uint256 tokenId, address user) external returns(uint8 partNum, uint48 partIndex);

    

    

}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { ICfunsDescriptorMinimal } from './ICfunsDescriptorMinimal.sol';
import { ICfunsSeeder } from './ICfunsSeeder.sol';

interface ICfunsRouter {
    event ControllerUpdated(address controller);

    event ControllerLocked();

    event CfunersDAOUpdated(address cfunersDAO);

    event DescriptorUpdated(ICfunsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event SeederUpdated(ICfunsSeeder seeder);

    event SeederLocked();
    
    function mintCfun() external returns (uint256);

    function mintPart(uint8 partNum, uint48 partIndex) external returns(uint256);

    function mintParts() external returns(uint256[] memory);

    function changeBackground(uint256 cfunId, uint48 backgroundIndex) external returns(bool);

    function changePart(uint256 cfunId, uint256 partTokenId) external returns(uint48);

    function removePart(uint256 cfunId, uint8 down_partNum) external returns(bool);

    function setCfunersDAO(address cfunersDAO) external;

    function setController(address _controller) external;

    function lockController() external;

    function setDescriptor(ICfunsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;

    function setSeeder(ICfunsSeeder seeder) external;

    function lockSeeder() external;

}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

pragma solidity ^0.8.6;

import { ICfunsDescriptorMinimal } from './ICfunsDescriptorMinimal.sol';

interface ICfunsSeeder {
    struct Seed {
        uint48 background;      //背景
        uint48 face;            //脸型
        uint48 hair;            //头发
        uint48 eye;            //眼部
        uint48 nose;
        uint48 mouth;          //嘴部
        uint48 part1;
    }

    function generateSeed(address user, ICfunsDescriptorMinimal descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { ICfunsDescriptorMinimal } from './ICfunsDescriptorMinimal.sol';
import { ICfunsSeeder } from './ICfunsSeeder.sol';

interface ICfunsToken is IERC721 {
    event CfunCreated(uint256 indexed tokenId, ICfunsSeeder.Seed seed);

    event CfunBurned(uint256 indexed tokenId);

    event CfunersDAOUpdated(address cfunersDAO);

    event RouterUpdated(address minter);

    event RouterLocked();

    event DescriptorUpdated(ICfunsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event SeederUpdated(ICfunsSeeder seeder);

    event SeederLocked();

    function mintTo(address to) external returns (uint256);

    function burn(uint256 tokenId) external returns (bool);

    function dataURI(uint256 tokenId) external returns (string memory);

    function setCfunersDAO(address cfunersDAO) external;

    function setRouter(address _router) external;

    function lockRouter() external;

    function setDescriptor(ICfunsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;

    function setSeeder(ICfunsSeeder seeder) external;

    function lockSeeder() external;

    function updateSeed(
        uint256 cfunId, 
        address owner, 
        uint8 up_partNum, 
        uint48 up_partIndex
        ) external returns(uint8 down_partNum, uint48 down_partIndex);

    function resetPart(
        uint256 cfunId, 
        address owner, 
        uint8 up_partNum
        ) external returns(uint48 down_partIndex);
}