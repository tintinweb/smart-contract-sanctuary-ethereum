import "./Erc721ItemAsset.sol";
import "contracts/position_trading/ContractData.sol";
import "contracts/position_trading/IPositionsController.sol";
import "contracts/position_trading/assets/AssetFactory.sol";

contract Erc721ItemAssetFactory is AssetFactory {
    constructor(address positionsController_) AssetFactory(positionsController_) {}

    function setOwnerAsset(
        uint256 positionId,
        address contractAddress,
        uint256 tokenId
    ) external {
        _setOwnerAsset(
            positionId,
            createAsset(positionId, contractAddress, tokenId)
        );
    }

    function setOutputAsset(
        uint256 positionId,
        address contractAddress,
        uint256 tokenId
    ) external {
        _setOutputAsset(
            positionId,
            createAsset(positionId, contractAddress, tokenId)
        );
    }

    function createAsset(
        uint256 positionId,
        address contractAddress,
        uint256 tokenId
    ) internal returns (ContractData memory) {
        ContractData memory data;
        data.factory = address(this);
        data.contractAddr = address(
            new Erc721ItemAsset(
                address(positionsController),
                positionId,
                contractAddress,
                tokenId
            )
        );
        return data;
    }
}

import "contracts/position_trading/assets/AssetBase.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Erc721ItemAsset is AssetBase {
    address public contractAddress;
    uint256 public tokenId;

    constructor(
        address positionsController,
        uint256 positionId,
        address contractAddress_,
        uint256 tokenId_
    ) AssetBase(positionsController, positionId) {
        contractAddress = contractAddress_;
        tokenId = tokenId_;
    }

    function count() external view override returns (uint256) {
        return
            IERC721(contractAddress).ownerOf(tokenId) == address(this) ? 1 : 0;
    }

    function withdrawInternal(address recipient, uint256 amount)
        internal
        virtual
        override
    {
        if (amount == 0) return;
        require(amount == 1);
        IERC721(contractAddress).transferFrom(
            address(this),
            recipient,
            tokenId
        );
    }

    function transferToAsset(address spender) external {
        address alg = _algorithm();
        if (alg != address(0))
            IPositionAlgorithm(alg).beforeAssetTransfer(
                positionId,
                address(this),
                spender,
                address(this),
                1
            );
        if (alg != address(0))
            IERC721(contractAddress).transferFrom(
                spender,
                address(this),
                tokenId
            );
        IPositionAlgorithm(alg).afterAssetTransfer(
            positionId,
            address(this),
            spender,
            address(this),
            1
        );
    }
}

import "contracts/position_trading/assets/IAsset.sol";

/// @dev данные порождаемого фабрикой контракта
struct ContractData {
    address factory; // фабрика
    address contractAddr; // контракт
}

import "contracts/position_trading/ContractData.sol";

interface IPositionsController {
    /// @dev возвращает владельца позиции
    function ownerOf(uint256 positionId) external view returns (address);

    /// @dev возвращает актив владельца позиции
    function ownerAsset(uint256 positionId)
        external view
        returns (ContractData memory);

    /// @dev возвращает актив владельца позиции
    function outputAsset(uint256 positionId)
        external view
        returns (ContractData memory);

    /// @dev создает позицию
    function createPosition() external;

    /// @dev задает ассет владельца
    function setOwnerAsset(uint256 positionId, ContractData calldata data)
        external;

    /// @dev задает выходной ассет
    function setOutputAsset(uint256 positionId, ContractData calldata data)
        external;

    /// @dev задает алгоритм позиции
    function setAlgorithm(uint256 positionId, ContractData calldata data)
        external;

    /// @dev возвращает алгоритм позиции
    function getAlgorithm(uint256 positionId) external view returns(ContractData memory data);

    /// @dev запрещает редактировать позицию
    function disableEdit(uint256 positionId) external;
}

import "contracts/position_trading/ContractData.sol";
import "contracts/position_trading/IPositionsController.sol";
import "contracts/position_trading/ContractData.sol";

contract AssetFactory {
    IPositionsController public positionsController;

    modifier onlyPositionOwner(uint256 positionId) {
        require(positionsController.ownerOf(positionId) == msg.sender);
        _;
    }

    constructor(address positionsController_) {
        positionsController = IPositionsController(positionsController_);
    }

    function _setOwnerAsset(
        uint256 positionId,
        ContractData memory contractData
    ) internal onlyPositionOwner(positionId) {
        positionsController.setOwnerAsset(positionId, contractData);
    }

    function _setOutputAsset(
        uint256 positionId,
        ContractData memory contractData
    ) internal onlyPositionOwner(positionId) {
        positionsController.setOutputAsset(positionId, contractData);
    }
}

import "contracts/position_trading/assets/IAsset.sol";
import "contracts/position_trading/algorithms/IPositionAlgorithm.sol";
import "contracts/position_trading/IPositionsController.sol";

abstract contract AssetBase is IAsset {
    IPositionsController public positionsController;
    uint256 public positionId;

    constructor(address positionsController_, uint256 positionId_) {
        positionsController = IPositionsController(positionsController_);
        positionId = positionId_;
    }

    modifier onlyAlgorithm() {
        require(msg.sender == _algorithm(), 'algorithms only');
        _;
    }
    /*modifier onlyAlgorithmOrOwner() {
        require(
            msg.sender == this.algorithm() ||
                msg.sender == positionsController.ownerOf(positionId)
        );
        _;
    }*/

    function algorithm() external view override returns (address) {
        return address(_algorithm());
    }

    function _algorithm() internal view returns (address) {
        return positionsController.getAlgorithm(positionId).contractAddr;
    }

    function withdraw(address recipient, uint256 amount)
        external
        override
        onlyAlgorithm
    {
        address alg = _algorithm();
        if (alg != address(0))
            IPositionAlgorithm(alg).beforeAssetTransfer(
                positionId,
                address(this),
                address(this),
                recipient,
                amount
            );
        withdrawInternal(recipient, amount);
        if (alg != address(0))
            IPositionAlgorithm(alg).afterAssetTransfer(
                positionId,
                address(this),
                address(this),
                recipient,
                amount
            );
    }

    function withdrawInternal(address recipient, uint256 amount)
        internal
        virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

interface IAsset{
    /// @dev обслуживающий алгоритм
    function algorithm() external view returns(address);
    /// @dev количество ассета
    function count() external view returns(uint256);
    /// @dev вывод определенного количества ассета на определенный адрес
    function withdraw(address recipient, uint256 amount) external;
}

interface IPositionAlgorithm{
    /// @dev если истина, то алгоритм позволяет редактировать позицию
    function allowEditPosition(uint256 positionId) external view returns(bool);
    function beforeAssetTransfer(uint256 positionId, address asset, address from, address to, uint256 amount) external;
    function afterAssetTransfer(uint256 positionId, address asset, address from, address to, uint256 amount) external;
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