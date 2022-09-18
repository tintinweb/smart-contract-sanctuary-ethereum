pragma solidity ^0.8.17;

import '../../PointFactory.sol';
import './Erc721CountPoint.sol';

contract Erc721CountFactory is PointFactory {
    constructor(address routerAddress) PointFactory(routerAddress) {}

    function makePoint(
        uint256 dealId,
        address token,
        uint256 needCount,
        address from,
        address to
    ) public {
        addPoint(
            dealId,
            address(
                new Erc721CountPoint(
                    address(swaper),
                    token,
                    needCount,
                    from,
                    to,
                    swaper.feeAddress(),
                    swaper.feeEth()
                )
            )
        );
    }
}

pragma solidity ^0.8.17;

import '../ISwapper.sol';
import '../Deal.sol';
import '../IDealPointFactory.sol';

abstract contract PointFactory is IDealPointFactory {
    ISwapper public swaper;
    mapping(address => uint256) public countsByCreator;
    uint256 countTotal;

    constructor(address routerAddress) {
        swaper = ISwapper(routerAddress);
    }

    function addPoint(uint256 dealId, address point) internal {
        ++countTotal;
        uint256 localCount = countsByCreator[msg.sender] + 1;
        countsByCreator[msg.sender] = localCount;
        Deal memory deal = swaper.getDeal(dealId);
        require(
            msg.sender == deal.owner0 || msg.sender == deal.owner1,
            'only owner can add the deal to dealPoint'
        );
        swaper.addDealPoint(dealId, address(point));
    }
}

pragma solidity ^0.8.17;

import '../../DealPoint.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

/// @dev позволяет создавать деталь сделки по трансферу ERC20 токена // allows to create a transaction detail for the transfer of ERC20 tokens
contract Erc721CountPoint is DealPoint {
    IERC721Enumerable public token;
    uint256 public needCount;
    address public from;
    address public to;
    uint256 public feeEth;

    receive() external payable {}

    constructor(
        address _router,
        address _token,
        uint256 _needCount,
        address _from,
        address _to,
        address _feeAddress,
        uint256 _feeEth
    ) DealPoint(_router, _feeAddress) {
        token = IERC721Enumerable(_token);
        needCount = _needCount;
        from = _from;
        to = _to;
        feeEth = _feeEth;
        require(
            token.supportsInterface(type(IERC721Enumerable).interfaceId),
            'interface does not supports'
        );
    }

    function isComplete() external view override returns (bool) {
        return token.balanceOf(address(this)) >= needCount;
    }

    function withdraw() external payable {
        if (isSwapped) {
            require(msg.value >= feeEth);
            payable(feeAddress).transfer(feeEth);
        }
        address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        uint256 count = token.balanceOf(address(this));
        for (uint256 i = 0; i < count; ++i) {
            token.transferFrom(
                address(this),
                owner,
                token.tokenOfOwnerByIndex(owner, 0)
            );
        }
    }

    function withdraw(uint256 tokenId) external {
        address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        token.transferFrom(address(this), owner, tokenId);
    }
}

pragma solidity ^0.8.17;
import '../fee/IFeeSettings.sol';
import './Deal.sol';

interface ISwapper is IFeeSettings {
    /// @dev adds a contract clause with the specified address to the deal
    /// this method can only be called by a factory
    function addDealPoint(uint256 dealId, address point) external;

    /// @dev returns the deal
    function getDeal(uint256 dealId) external view returns (Deal memory);
}

pragma solidity ^0.8.17;

import './IDealPoint.sol';

struct Deal {
    uint256 state; // 0 - not exists, 1-editing 2-execution 3-swaped
    address owner0; // owner 0 - creator
    address owner1; // owner 1 - second part
}

pragma solidity ^0.8.17;
import './IDealPoint.sol';

interface IDealPointFactory {}

pragma solidity ^0.8.17;
interface IFeeSettings {
    function feeAddress() external returns (address); // address to pay fee

    function feePercent() external returns (uint256); // fee in 1/decimals for deviding values

    function feeDecimals() external view returns(uint256); // fee decimals

    function feeEth() external returns (uint256); // fee value for not dividing deal points
}

pragma solidity ^0.8.17;

interface IDealPoint {
    function isComplete() external view returns (bool); // whether the conditions are met

    function swap() external; // swap

    function withdraw() external payable; // withdraws the owner's funds
}

pragma solidity ^0.8.17;
import '../IDealPoint.sol';

abstract contract DealPoint is IDealPoint {
    address public router; // router has no specified type for testing reasons
    address feeAddress;
    bool public isSwapped;

    constructor(address _router, address _feeAddress) {
        router = _router;
        feeAddress = _feeAddress;
    }

    function swap() external virtual {
        require(msg.sender == router);
        isSwapped = true;
    }

    function isComplete() external view virtual returns (bool);
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