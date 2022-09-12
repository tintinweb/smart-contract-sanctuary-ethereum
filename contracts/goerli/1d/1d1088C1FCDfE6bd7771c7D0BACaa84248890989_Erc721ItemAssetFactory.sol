import './Erc721ItemAsset.sol';
import 'contracts/lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/position_trading/assets/AssetFactoryBase.sol';
import 'contracts/interfaces/assets/typed/IErc721ItemAsset.sol';
import 'contracts/interfaces/assets/typed/IErc721ItemAssetFactory.sol';

contract Erc721ItemAssetFactory is AssetFactoryBase, IErc721ItemAssetFactory {
    constructor(address positionsController_)
        AssetFactoryBase(positionsController_)
    {}

    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        address contractAddress,
        uint256 tokenId
    ) external {
        _setAsset(positionId, assetCode, createAsset(contractAddress, tokenId));
    }

    function createAsset(address contractAddress, uint256 tokenId)
        internal
        returns (ContractData memory)
    {
        ContractData memory data;
        data.factory = address(this);
        data.contractAddr = address(
            new Erc721ItemAsset(
                address(positionsController),
                this,
                contractAddress,
                tokenId
            )
        );
        return data;
    }

    function _clone(address asset, address owner)
        internal
        override
        returns (IAsset)
    {
        return
            new Erc721ItemAsset(
                owner,
                this,
                IErc721ItemAsset(asset).getContractAddress(),
                IErc721ItemAsset(asset).getTokenId()
            );
    }
}

import 'contracts/position_trading/assets/AssetBase.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import 'contracts/position_trading/PositionSnapshot.sol';
import 'contracts/interfaces/position_trading/IPositionAlgorithm.sol';
import 'contracts/interfaces/assets/typed/IErc721ItemAsset.sol';

contract Erc721ItemAsset is AssetBase, IErc721ItemAsset {
    address contractAddress;
    uint256 tokenId;

    constructor(
        address owner_,
        IAssetCloneFactory factory_,
        address contractAddress_,
        uint256 tokenId_
    ) AssetBase(owner_, factory_) {
        contractAddress = contractAddress_;
        tokenId = tokenId_;
    }

    function getContractAddress() external view override returns (address) {
        return contractAddress;
    }

    function getTokenId() external view override returns (uint256) {
        return tokenId;
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

    function transferToAsset(uint256[] calldata data)
        external
    {
        listener().beforeAssetTransfer(
            address(this),
            msg.sender,
            address(this),
            1,
            data
        );
        IERC721(contractAddress).transferFrom(msg.sender, address(this), tokenId);
        listener().afterAssetTransfer(
            address(this),
            msg.sender,
            address(this),
            1,
            data
        );
    }

    function clone(address owner) external override returns (IAsset) {
        return factory.clone(address(this), owner);
    }

    function assetTypeId() external pure override returns (uint256) {
        return 3;
    }
}

/// @dev данные порождаемого фабрикой контракта
struct ContractData {
    address factory; // фабрика
    address contractAddr; // контракт
}

import 'contracts/lib/factories/ContractData.sol';
import 'contracts/fee/IFeeSettings.sol';

interface IPositionsController {
    /// @dev возвращает налоговые настройки
    function getFeeSettings() external view returns(IFeeSettings);

    /// @dev возвращает владельца позиции
    function ownerOf(uint256 positionId) external view returns (address);

    /// @dev меняет владельца позиции
    function transferPositionOwnership(uint256 positionId, address newOwner)
        external;

    /// @dev возаращает позицию ассета его адресу
    function getAssetPositionId(address assetAddress)
        external
        view
        returns (uint256);

    /// @dev возвращает актив по его коду в позиции 1 или 2
    function getAsset(uint256 positionId, uint256 assetCode)
        external
        view
        returns (ContractData memory);

    /// @dev создает позицию
    function createPosition() external;

    /// @dev задает ассет на позицию
    /// @param positionId ID позиции
    /// @param assetCode код ассета 1 - овнер ассет 2 - выходной ассет
    /// @param data данные контракта ассета
    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        ContractData calldata data
    ) external;

    /// @dev задает алгоритм позиции
    function setAlgorithm(uint256 positionId, ContractData calldata data)
        external;

    /// @dev возвращает алгоритм позиции
    function getAlgorithm(uint256 positionId)
        external
        view
        returns (ContractData memory data);

    /// @dev запрещает редактировать позицию
    function disableEdit(uint256 positionId) external;

    /// @dev возвращает позицию из списка позиций аккаунта
    function positionOfOwnerByIndex(address account, uint256 index)
        external
        view
        returns (uint256);

    /// @dev возвращает количество позиций, которыми владеет аккаунт
    function ownedPositionsCount(address account)
        external
        view
        returns (uint256);
}

import 'contracts/lib/factories/ContractData.sol';
import 'contracts/interfaces/position_trading/IPositionsController.sol';
import 'contracts/interfaces/assets/IAssetCloneFactory.sol';

abstract contract AssetFactoryBase is IAssetCloneFactory {
    IPositionsController public positionsController;

    constructor(address positionsController_) {
        positionsController = IPositionsController(positionsController_);
    }

    modifier onlyPositionOwner(uint256 positionId) {
        require(positionsController.ownerOf(positionId) == msg.sender);
        _;
    }

    function _setAsset(
        uint256 positionId,
        uint256 assetCode,
        ContractData memory contractData
    ) internal onlyPositionOwner(positionId) {
        positionsController.setAsset(positionId, assetCode, contractData);
    }

    function clone(address asset, address owner)
        external
        override
        returns (IAsset)
    {
        require(msg.sender == asset, 'only for assets');
        return _clone(asset, owner);
    }

    function _clone(address asset, address owner)
        internal
        virtual
        returns (IAsset);
}

interface IErc721ItemAsset {
    function getContractAddress() external returns (address);

    function getTokenId() external returns (uint256);
}

interface IErc721ItemAssetFactory {
    function setAsset(
        uint256 positionId,
        uint256 assetCode,
        address contractAddress,
        uint256 tokenId
    ) external;
}

import 'contracts/interfaces/assets/IAsset.sol';
import 'contracts/interfaces/assets/IAssetListener.sol';
import 'contracts/lib/ownable/OwnableSimple.sol';
import 'contracts/interfaces/assets/IAssetCloneFactory.sol';

/// @dev ассет всегда имеет овнером алгоритм, листенер событий ассета
abstract contract AssetBase is IAsset, OwnableSimple {
    IAssetCloneFactory public factory;
    bool internal _isNotifyListener;

    constructor(address owner_, IAssetCloneFactory factory_)
        OwnableSimple(owner_)
    {
        _owner = address(owner_);
        factory = factory_;
    }

    function listener() internal view returns (IAssetListener) {
        return IAssetListener(_owner);
    }

    function withdraw(address recipient, uint256 amount)
        external
        virtual
        override
        onlyOwner
    {
        uint256[] memory data;
        if (_isNotifyListener)
            listener().beforeAssetTransfer(
                address(this),
                address(this),
                recipient,
                amount,
                data
            );
        withdrawInternal(recipient, amount);
        if (_isNotifyListener)
            listener().afterAssetTransfer(
                address(this),
                address(this),
                recipient,
                amount,
                data
            );
    }

    function withdrawInternal(address recipient, uint256 amount)
        internal
        virtual;

    function isNotifyListener() external view returns (bool) {
        return _isNotifyListener;
    }

    function setNotifyListener(bool value) external onlyOwner {
        _isNotifyListener = value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// todo вырезать
struct PositionSnapshot {
    uint256 owner;
    uint256 output;
    uint256 slippage;
}

import 'contracts/interfaces/assets/IAssetListener.sol';

interface IPositionAlgorithm is IAssetListener {
    /// @dev если истина, то алгоритм блокирует редактирование позиции
    function isPositionLocked(uint256 positionId) external view returns (bool);

    /// @dev передаtn право владения ассетом указанному адресу
    function transferAssetOwnerShipTo(address asset, address newOwner) external;
}

import 'contracts/interfaces/IOwnable.sol';

/// @dev абстракция ассета
/// владелец ассета всегда алгоритм-наблюдатель ассета
interface IAsset is IOwnable {
    /// @dev количество ассета
    function count() external view returns (uint256);

    /// @dev вывод определенного количества ассета на определенный адрес
    function withdraw(address recipient, uint256 amount) external;

    /// @dev создает копию текущего ассета, с 0 балансом и указанным овнером
    function clone(address owner) external returns (IAsset);

    /// @dev возвращает код типа ассета (также используется для проверки потдержки интерфейса ассета)
    function assetTypeId() external returns (uint256);

    /// @dev если истина, то оповещает своего наблюдателя (овнера)
    function isNotifyListener() external returns (bool);

    /// @dev включает или отключает механизм оповещения наблюдателя
    function setNotifyListener(bool value) external;
}

import 'contracts/position_trading/PositionSnapshot.sol';

interface IAssetListener {
    function beforeAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external;

    function afterAssetTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256[] memory data
    ) external;
}

import 'contracts/interfaces/IOwnable.sol';

/// @dev овнабл, оптимизированый, для динамически порождаемых контрактов
contract OwnableSimple is IOwnable {
    address internal _owner;

    constructor(address owner_) {
        _owner = owner_;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'caller is not the owner');
        _;
    }

    function owner() external virtual override returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
    }
}

import 'contracts/interfaces/assets/IAsset.sol';

interface IAssetCloneFactory {
    /// @dev делает копию ассета (количество ассета будет 0)
    function clone(address asset, address owner) external returns (IAsset);
}

interface IOwnable {
    function owner() external returns (address);

    function transferOwnership(address newOwner) external;
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

interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}