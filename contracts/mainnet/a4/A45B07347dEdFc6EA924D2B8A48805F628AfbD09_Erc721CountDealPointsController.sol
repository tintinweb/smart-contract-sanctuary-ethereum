// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../../../DealPointsController.sol';
import './IErc721CountDealPointsController.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import './../../../DealPointDataInternal.sol';

contract Erc721CountDealPointsController is
    DealPointsController,
    IErc721CountDealPointsController
{
    mapping(uint256 => uint256[]) _tokensId;

    constructor(address dealsController_)
        DealPointsController(dealsController_)
    {}

    function dealPointTypeId() external pure returns (uint256) {
        return 4;
    }

    /// @dev creates the deal point
    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        address token_,
        uint256 count_
    ) external {
        uint256 pointId = _dealsController.getTotalDealPointsCount() + 1;
        _data[pointId] = DealPointDataInternal(dealId_, count_, from_, to_);
        _tokenAddress[pointId] = token_;
        _dealsController.addDealPoint(dealId_, address(this), pointId);
    }

    function tokensId(uint256 pointId)
        external
        view
        returns (uint256[] memory)
    {
        return _tokensId[pointId];
    }

    function _execute(uint256 pointId, address from) internal virtual override {
        // transfer
        DealPointDataInternal memory point = _data[pointId];
        IERC721Enumerable token = IERC721Enumerable(_tokenAddress[pointId]);
        uint256 cnt = point.value;
        uint256[] memory items = new uint256[](cnt);
        for (uint256 i = 0; i < cnt; ++i) {
            uint256 tokenId = token.tokenOfOwnerByIndex(from, 0);
            token.transferFrom(from, address(this), tokenId);
            items[i] = tokenId;
        }
        _tokensId[pointId] = items;
        ++_balances[pointId];

        // calculate fee
        _fee[pointId] = _dealsController.feeEth();
    }

    function _withdraw(
        uint256 pointId,
        address withdrawAddr,
        uint256 withdrawCount
    ) internal virtual override {
        DealPointDataInternal memory point = _data[pointId];
        uint256 pointFee = _fee[pointId];
        if (!this.isSwapped(pointId)) pointFee = 0;
        IERC721 token = IERC721(_tokenAddress[pointId]);
        if (pointFee > 0) {
            require(msg.value >= pointFee, 'not enough eth fee for withdraw');
            (bool sentFee, ) = payable(_dealsController.feeAddress()).call{
                value: pointFee
            }('');
            require(sentFee, 'sent fee error: ether is not sent');
        }
        uint256 cnt = point.value;
        uint256[] memory items = _tokensId[pointId];
        for (uint256 i = 0; i < cnt; ++i) {
            uint256 tokenId = items[i];
            token.transferFrom(address(this), withdrawAddr, tokenId);
        }
        delete _tokensId[pointId];
    }

    function feeIsEthOnWithdraw() external pure returns (bool) {
        return true;
    }

    function executeEtherValue(uint256 pointId)
        external
        pure
        returns (uint256)
    {
        return 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './IDealPointsController.sol';
import './IDealsController.sol';
import './DealPointDataInternal.sol';

abstract contract DealPointsController is IDealPointsController {
    IDealsController immutable _dealsController;
    mapping(uint256 => DealPointDataInternal) internal _data;

    /*mapping(uint256 => uint256) internal _dealId;
    mapping(uint256 => address) internal _from;
    mapping(uint256 => address) internal _to;
    mapping(uint256 => uint256) internal _value;*/
    mapping(uint256 => uint256) internal _balances;
    mapping(uint256 => uint256) internal _fee;
    mapping(uint256 => bool) internal _isExecuted;
    mapping(uint256 => address) internal _tokenAddress;

    constructor(address dealsController_) {
        _dealsController = IDealsController(dealsController_);
    }

    receive() external payable {}

    modifier onlyDealsController() {
        require(
            address(_dealsController) == msg.sender,
            'only deals controller can call this function'
        );
        _;
    }

    modifier onlyFactory() {
        require(
            _dealsController.isFactory(msg.sender),
            'only factory can call this function'
        );
        _;
    }

    function isSwapped(uint256 pointId) external view returns (bool) {
        //return _dealsController.isSwapped(_dealId[pointId]);
        return _dealsController.isSwapped(_data[pointId].dealId);
    }

    function isExecuted(uint256 pointId) external view returns (bool) {
        return _isExecuted[pointId];
        //return _data[pointId].isExecuted;
    }

    function dealId(uint256 pointId) external view returns (uint256) {
        //return _dealId[pointId];
        return _data[pointId].dealId;
    }

    function from(uint256 pointId) external view returns (address) {
        //return _from[pointId];
        return _data[pointId].from;
    }

    function to(uint256 pointId) external view returns (address) {
        //return _to[pointId];
        return _data[pointId].to;
    }

    function setTo(uint256 pointId, address account)
        external
        onlyDealsController
    {
        require(
            //_to[pointId] == address(0),
            _data[pointId].to == address(0),
            'to can be setted only once for deal point'
        );
        //_to[pointId] = account;
        _data[pointId].to = account;
    }

    function tokenAddress(uint256 pointId) external view returns (address) {
        return _tokenAddress[pointId];
    }

    function value(uint256 pointId) external view returns (uint256) {
        //return _value[pointId];
        return _data[pointId].value;
    }

    function balance(uint256 pointId) external view returns (uint256) {
        return _balances[pointId];
        //return _data[pointId].balance;
    }

    function fee(uint256 pointId) external view returns (uint256) {
        return _fee[pointId];
        //return _data[pointId].fee;
    }

    function owner(uint256 pointId) external view returns (address) {
        //return this.isSwapped(pointId) ? this.to(pointId) : this.from(pointId);
        DealPointDataInternal memory point = _data[pointId];
        return this.isSwapped(pointId) ? point.to : point.from;
    }

    function dealsController() external view returns (address) {
        return address(_dealsController);
    }

    function withdraw(uint256 pointId) external payable onlyDealsController {
        address ownerAddr = this.owner(pointId);
        DealPointDataInternal memory point = _data[pointId];
        require(
            _balances[pointId] > 0,
            //point.balance > 0,
            'has no balance to withdraw'
        );
        require(
            address(_dealsController) == msg.sender || ownerAddr == msg.sender,
            'only owner or deals controller can withdraw'
        );
        if (ownerAddr == point.from) _isExecuted[pointId] = false;
        uint256 withdrawCount = _balances[pointId];
        _balances[pointId] = 0;
        require(withdrawCount > 0, 'not enough balance');
        _withdraw(pointId, ownerAddr, withdrawCount);
    }

    function execute(uint256 pointId, address addr)
        external
        payable
        onlyDealsController
    {
        DealPointDataInternal storage point = _data[pointId];
        if (_isExecuted[pointId]) return;
        //if (_from[pointId] == address(0)) _from[pointId] = addr;
        //if (point.isExecuted) return;
        if (point.from == address(0)) point.from = addr;
        _execute(pointId, addr);
        _isExecuted[pointId] = true;
        //point.isExecuted = true;
    }

    function _execute(uint256 pointId, address from) internal virtual;

    function _withdraw(
        uint256 pointId,
        address withdrawAddr,
        uint256 withdrawCount
    ) internal virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IErc721CountDealPointsController {
    /// @dev creates the deal point
    function createPoint(
        uint256 dealId_,
        address from_,
        address to_,
        address token_,
        uint256 count_
    ) external;

    /// @dev all tokens, that stores deal point
    function tokensId(uint256 pointId) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct DealPointDataInternal {
    uint256 dealId;
    uint256 value;
    address from;
    address to;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IDealPointsController {
    receive() external payable;

    /// @dev returns type id of dealpoints
    /// 1 - eth
    /// 2 - erc20
    /// 3 erc721 item
    /// 4 erc721 count
    function dealPointTypeId() external pure returns (uint256);

    /// @dev returns deal id for deal point or 0 if point is not exists in this controller
    function dealId(uint256 pointId) external view returns (uint256);

    /// @dev token contract address, that need to be transferred or zero
    function tokenAddress(uint256 pointId) external view returns (address);

    /// @dev from
    /// zero address - for open swap
    function from(uint256 pointId) external view returns (address);

    /// @dev to
    function to(uint256 pointId) external view returns (address);

    /// @dev sets to account for point
    /// only DealsController and only once
    function setTo(uint256 pointId, address account) external;

    /// @dev asset value (count or nft id), needs to execute deal point
    function value(uint256 pointId) external view returns (uint256);

    /// @dev balance of the deal point
    function balance(uint256 pointId) external view returns (uint256);

    /// @dev deal point fee. In ether or token. Only if withdraw after deal is swapped
    function fee(uint256 pointId) external view returns (uint256);

    /// @dev if true, than fee is ether, that sends on withdraw after swapped
    function feeIsEthOnWithdraw() external pure returns (bool);

    /// @dev current owner of deal point
    /// zero address - for open deals, before execution
    function owner(uint256 pointId) external view returns (address);

    /// @dev deals controller
    function dealsController() external view returns (address);

    /// @dev if true, than deal is swapped
    function isSwapped(uint256 pointId) external view returns (bool);

    /// @dev if true, than point is executed and can be swaped
    function isExecuted(uint256 pointId) external view returns (bool);

    /// @dev executes the point, by using address
    /// if already executed than nothing happens
    function execute(uint256 pointId, address addr) external payable;

    /// @dev the execute ether value for owner with number
    function executeEtherValue(uint256 pointId) external view returns(uint256);

    /// @dev withdraw the asset from deal point
    /// only deals controller
    function withdraw(uint256 pointId) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../fee/IFeeSettings.sol';
import '../lib/factories/IHasFactories.sol';
import './Deal.sol';
import './DealPointData.sol';

interface IDealsController is IFeeSettings, IHasFactories {
    /// @dev new deal created
    /// deals are creates by factories by one transaction, therefore another events, such as deal point adding is no need
    event NewDeal(uint256 indexed dealId, address indexed creator);
    /// @dev the deal is swapped
    event Swap(uint256 indexed dealId);
    /// @dev the deal is executed by account
    event Execute(uint256 indexed dealId, address account, bool executed);
    /// @dev the deal withdraw
    event OnWithdraw(uint256 indexed dealId, address indexed account);

    /// @dev swap the deal
    function swap(uint256 dealId) external;

    /// @dev if true, than deal is swapped
    function isSwapped(uint256 dealId) external view returns (bool);

    /// @dev total deal points count
    function getTotalDealPointsCount() external view returns (uint256);

    /// @dev creates the deal.
    /// Only for factories.
    /// @param owner1 - first owner (creator)
    /// @param owner2 - second owner of deal. If zero than deal is open for any account
    /// @return id of new deal
    function createDeal(address owner1, address owner2)
        external
        returns (uint256);

    /// @dev returns all deal information
    function getDeal(uint256 dealId)
        external
        view
        returns (Deal memory, DealPointData[] memory);

    /// @dev returns the deals header information (without points)
    function getDealHeader(uint256 dealId) external view returns (Deal memory);

    /// @dev adds the deal point to deal.
    /// only for factories
    /// @param dealId deal id
    function addDealPoint(
        uint256 dealId,
        address dealPointsController,
        uint256 newPointId
    ) external;

    /// @dev returns deal point by its index in deal
    function getDealPoint(uint256 dealId, uint256 pointIndex)
        external
        view
        returns (DealPointData memory);

    /// @dev returns deal points count for the deal
    function getDealPointsCount(uint256 dealId) external view returns (uint256);

    /// @dev returns true, if all deal points is executed, and can be made swap, if not swapped already
    function isExecuted(uint256 dealId) external view returns (bool);

    /// @dev makes withdraw from all deal points of deal, where caller is owner
    function withdraw(uint256 dealId) external payable;

    /// @dev stops all editing for deal
    /// only for factories
    function stopDealEditing(uint256 dealId) external;

    /// @dev executes all points of the deal
    function execute(uint256 dealId) external payable;

    /// @dev the execute ether value for owner with number
    function executeEtherValue(uint256 dealId, uint256 ownerNumber) external view returns(uint256);

    /// @dev returns fee in ether on withdraw for owner number
    function feeEthOnWithdraw(uint256 dealId, uint256 ownerNumber)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '../ownable/IOwnable.sol';

interface IHasFactories is IOwnable {
    /// @dev returns true, if addres is factory
    function isFactory(address addr) external view returns (bool);

    /// @dev mark address as factory (only owner)
    function addFactory(address factory) external;

    /// @dev mark address as not factory (only owner)
    function removeFactory(address factory) external;

    /// @dev mark addresses as factory or not (only owner)
    function setFactories(address[] calldata addresses, bool isFactory_)
        external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import './DealPointRef.sol';

struct Deal {
    uint256 state; // 0 - not exists, 1-editing 2-execution 3-swaped
    address owner1; // owner 1 - creator
    address owner2; // owner 2 - second part if zero than it is open deal
    uint256 pointsCount;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct DealPointData {
    address controller;
    uint256 id;
    /// @dev deal point id
    /// 1 - eth
    /// 2 - erc20
    /// 3 erc721 item
    /// 4 erc721 count
    uint256 dealPointTypeId;
    uint256 dealId;
    address from;
    address to;
    address owner;
    uint256 value;
    uint256 balance;
    uint256 fee;
    address tokenAddress;
    bool isSwapped;
    bool isExecuted;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IOwnable {
    function owner() external view returns (address);

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

struct DealPointRef {
    /// @dev controller of deal point
    address controller;
    /// @dev id of the deal point
    uint256 id;
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