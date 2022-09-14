//SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract nftescrow is IERC721Receiver {
    enum LoanState {
        newLoan,
        loanDeposited,
        nftDeposited,
        loanWithdrawal
    }

    using Counters for Counters.Counter;
    Counters.Counter private _loanIds;

    // address payable public sellerAddress;
    // address payable public buyerAddress;
    // address public nftAddress;
    // uint256 tokenID;
    // bool buyerCancel = false;
    // bool sellerCancel = false;
    // ProjectState public projectState;

    struct Loan {
        address payable borrowerAddress;
        address payable lenderAddress;
        address nftAddress;
        uint256 tokenId;
        uint256 loanAmount;
        uint256 ethDeposit;
        // bool buyerCancel = false;
        // bool sellerCancel = false;
        LoanState loanState;
    }

    // TODO: Esta public por debug, poner en private mas adelante
    mapping(uint256 => Loan) public loans;

    constructor() public {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) public override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // TODO: Se puede sacar este paso y crear el loan en el paso siguiente?
    function createLoan(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _loanAmount
    ) external {
        _loanIds.increment();
        uint256 loanId = _loanIds.current();
        loans[loanId] = Loan(
            payable(msg.sender),
            payable(address(0)),
            _nftAddress,
            _tokenId,
            _loanAmount,
            0,
            LoanState.newLoan
        );
        _depositNFT(loanId);
    }

    function getBorrowerLoans(address _borrowerAddress)
        external
        view
        returns (Loan[] memory)
    {
        Loan[] memory borrowerLoans = new Loan[](_loanIds.current());
        uint count = 0;
        for (uint i = 0; i < _loanIds.current(); i++) {
            if (loans[i].borrowerAddress == _borrowerAddress) {
                borrowerLoans[count] = loans[i];
                count += 1;
            }
        }

        Loan[] memory filteredLoans = new Loan[](count);
        for (uint i = 0; i < count; i++) {
            filteredLoans[i] = borrowerLoans[i];
        }

        return filteredLoans;
    }

    function getLenderLoans(address _lenderAddress)
        external
        view
        returns (Loan[] memory)
    {
        Loan[] memory lenderLoans = new Loan[](_loanIds.current());
        uint count = 0;
        for (uint i = 0; i < _loanIds.current(); i++) {
            if (loans[i].lenderAddress == _lenderAddress) {
                lenderLoans[count] = loans[i];
                count += 1;
            }
        }

        Loan[] memory filteredLoans = new Loan[](count);
        for (uint i = 0; i < count; i++) {
            filteredLoans[i] = lenderLoans[i];
        }

        return filteredLoans;
    }

    function depositETH(uint256 _loanId) external payable {
        loans[_loanId].lenderAddress = payable(msg.sender);
        loans[_loanId].ethDeposit = msg.value;
        loans[_loanId].loanState = LoanState.loanDeposited;
    }

    function _depositNFT(uint256 _loanId) private {
        address nftAddress = loans[_loanId].nftAddress;
        uint256 tokenId = loans[_loanId].tokenId;
        IERC721(nftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        loans[_loanId].loanState = LoanState.nftDeposited;
    }

    function getLoansItems() public view returns (Loan[] memory) {
        uint itemCount = _loanIds.current();
        uint currentIndex = 0;

        Loan[] memory items = new Loan[](itemCount);

        for (uint i = 0; i < itemCount; i++) {
            if (loans[i + 1].loanState == LoanState.nftDeposited) {
                uint currentId = i + 1;
                Loan memory currentItem = loans[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return items;
    }

    function cancelAtNFT(uint256 _loanId) public onlyBorrower(_loanId) {
        address nftAddress = loans[_loanId].nftAddress;
        uint256 tokenId = loans[_loanId].tokenId;
        IERC721(nftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        loans[_loanId].loanState = LoanState.loanDeposited;
    }

    // function cancelBeforeDelivery(bool _state)
    //     public
    //     inProjectState(ProjectState.ethDeposited)
    //     payable
    //     BuyerOrSeller
    // {
    //     if (msg.sender == sellerAddress){
    //         sellerCancel = _state;
    //     }
    //     else{
    //         buyerCancel = _state;
    //     }

    //     if (sellerCancel == true && buyerCancel == true){
    //         ERC721(nftAddress).safeTransferFrom(address(this), sellerAddress, tokenID);
    //         buyerAddress.transfer(address(this).balance);
    //         projectState = ProjectState.canceledBeforeDelivery;
    //     }
    // }

    // function depositETH()
    //     public
    //     payable
    //     inProjectState(ProjectState.nftDeposited)
    // {
    //     buyerAddress = payable(msg.sender);
    //     projectState = ProjectState.ethDeposited;
    // }

    // function initiateDelivery()
    //     public
    //     inProjectState(ProjectState.ethDeposited)
    //     onlySeller
    //     noDispute
    // {
    //     projectState = ProjectState.deliveryInitiated;
    // }

    // function confirmDelivery()
    //     public
    //     payable
    //     inProjectState(ProjectState.deliveryInitiated)
    //     onlyBuyer
    // {
    //     ERC721(nftAddress).safeTransferFrom(address(this), buyerAddress, tokenID);
    //     sellerAddress.transfer(address(this).balance);
    //     projectState = ProjectState.delivered;
    // }

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyBorrower(uint256 _loanId) {
        require(msg.sender == loans[_loanId].borrowerAddress);
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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