//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title An Sale Contract for bidding and selling single and batched NFTs
/// @author Avo Labs GmbH
/// @notice This contract can be used for Saleing any NFTs, and accepts any ERC20 token as payment
contract NFTSale {
    mapping(address => mapping(uint256 => mapping(address => Offer[]))) public nftSales;
    mapping(address => mapping(uint256 => mapping(address => State))) public nftState;    
    mapping(address => uint256) failedTransferCredits;
    enum State { Created, Release, Inactive }
    //Each Offer is linked to each NFT sale (contract + id pairing + seller).
    struct Offer {
        address nftBuyer;
        uint64  offerEnd;
        address ERC20Token;
        uint128 tokenAmount;
    }

    address[]   feeRecipients;
    uint32[]    feePercentages;

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/


    event OfferMade(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address bidder,
        uint64 offerEnd,
        address erc20Token,
        uint128 tokenAmount
    );

    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address bidder,
        address erc20Token,
        uint128 tokenAmount
    );

    event SaleOpened(
        address _nftContractAddress, 
        uint256 _tokenId, 
        address nftSeller
    );

    event SaleBlocked(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller
    );

    event OfferWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address highestBidder
    );

    event OfferTaken(
        address nftContractAddress, 
        uint256 tokenId,
        address nftSeller,
        address bidder,
        address erc20Token,
        uint128 tokenAmount
    );
    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║            EVENTS           ║
      ╚═════════════════════════════╝*/
    /**********************************/
    /*╔═════════════════════════════╗
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/

    modifier SaleOngoing(address _nftContractAddress, uint256 _tokenId, address _nftSeller) {
        require(
            _isSaleOngoing(_nftContractAddress, _tokenId, _nftSeller),
            "Sale has ended"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 _price) {
        require(_price > 0, "Price cannot be 0");
        _;
    }

    modifier notNftSeller(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender != 
                IERC721(_nftContractAddress).ownerOf(_tokenId),
            "Owner cannot bid on own NFT"
        );
        _;
    }
    modifier onlyNftOwner(address _nftContractAddress, uint256 _tokenId) {
        require(
            msg.sender ==
                IERC721(_nftContractAddress).ownerOf(_tokenId),
            "Only nft seller"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    modifier isFeePercentagesLessThanMaximum(uint32[] memory _feePercentages) {
        uint32 totalPercent;
        for (uint256 i = 0; i < _feePercentages.length; i++) {
            totalPercent = totalPercent + _feePercentages[i];
        }
        require(totalPercent <= 10000, "Fee percentages exceed maximum");
        _;
    }

    modifier correctFeeRecipientsAndPercentages(
        uint256 _recipientsLength,
        uint256 _percentagesLength
    ) {
        require(
            _recipientsLength == _percentagesLength,
            "Recipients != percentages"
        );
        _;
    }

    modifier isNotASale(address _nftContractAddress, uint256 _tokenId, address _nftSeller) {
        require(
            _isSaleInactive(_nftContractAddress, _tokenId, _nftSeller),
            "Not applicable for a sale"
        );
        _;
    }


    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/
    /**********************************/
    // constructor
    constructor() {
    }

    /*╔══════════════════════════════╗
      ║    Sale CHECK FUNCTIONS   ║
      ╚══════════════════════════════╝*/
    /*
     * An NFT is open for sale 
     */
    function _isSaleOngoing(address _nftContractAddress, uint256 _tokenId, address _nftSeller)
        internal
        view
        returns (bool)
    {
        return (nftState[_nftContractAddress][_tokenId][_nftSeller] != State.Release &&
        nftState[_nftContractAddress][_tokenId][_nftSeller] != State.Inactive );
    }

    // NFT sold
    function _isSaleOver(address _nftContractAddress, uint256 _tokenId, address _nftSeller)
        internal
        view
        returns (bool)
    {
        return (nftState[_nftContractAddress][_tokenId][_nftSeller] == State.Release);
    }
    // NFT hidden
    function _isSaleInactive(address _nftContractAddress, uint256 _tokenId, address _nftSeller)
        internal
        view
        returns (bool)
    {
        return (nftState[_nftContractAddress][_tokenId][_nftSeller] == State.Inactive);
    }


    /*
     * Returns the percentage of the total bid (used to calculate fee payments)
     */
    function _getPortionOfBid(uint256 _totalBid, uint256 _percentage)
        internal
        pure
        returns (uint256)
    {
        return (_totalBid * (_percentage)) / 10000;
    }

    function _isOfferValid(address _nftContractAddress, uint256 _tokenId, address _nftSeller, address _nftBuyer) 
        internal 
        view 
        returns (bool) 
    {
        uint64 offerEnd =
            _getOfferEnd(_nftContractAddress, _tokenId, _nftSeller, _nftBuyer);
        return (
            offerEnd < uint64(block.timestamp) &&
            offerEnd > 0            
        );
    }


    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║    Sale CHECK FUNCTIONS   ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║    DEFAULT GETTER FUNCTIONS  ║
      ╚══════════════════════════════╝*/
    /*****************************************************************
     * These functions check if the applicable Sale parameter has *
     * been set by the NFT seller. If not, return the default value. *
     *****************************************************************/


    function _getOfferEnd(address _nftContractAddress, uint256 _tokenId, address _nftSeller, address _nftBuyer)
        internal
        view
        returns (uint64)
    {
        uint size = nftSales[_nftContractAddress][_tokenId][_nftSeller].length;
        uint64 offerEnd;
        for (uint i = 0; i < size; i++) {
            if (nftSales[_nftContractAddress][_tokenId][_nftSeller]
                [i].nftBuyer == _nftBuyer) {
                    offerEnd - nftSales[_nftContractAddress][_tokenId][_nftSeller]
                    [i].offerEnd;
            }
        }
        return offerEnd;
  }


    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║    DEFAULT GETTER FUNCTIONS  ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║  TRANSFER NFTS TO CONTRACT   ║
      ╚══════════════════════════════╝*/
    function _transferNftToSaleContract(
        address _nftContractAddress,
        uint256 _tokenId
    ) internal { 
        IERC721(_nftContractAddress).transferFrom(
            msg.sender, 
            address(this),
            _tokenId
        );
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "nft transfer failed"
        );
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║  TRANSFER NFTS TO CONTRACT   ║
      ╚══════════════════════════════╝*/
    /**********************************/


    /*╔═════════════════════════════╗
      ║        BID FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /********************************************************************
     * Make bids with ETH or an ERC20 Token specified by the NFT seller.*
     * Additionally, a buyer can pay the asking price to conclude a sale*
     * of an NFT.                                                      *
     ********************************************************************/

    function _makeOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint64  _offerEnd,
        address _erc20Token,
        uint128 _tokenAmount
    )
        internal
        notNftSeller(_nftContractAddress, _tokenId)
        priceGreaterThanZero(_tokenAmount)
    {
        nftSales[_nftContractAddress][_tokenId][_nftSeller]
            .push(Offer(msg.sender, _offerEnd, _erc20Token, _tokenAmount ));

        if (!_isSaleOngoing(_nftContractAddress, _tokenId, _nftSeller)) 
            nftState[_nftContractAddress][_tokenId][_nftSeller] = State.Created;
        emit OfferMade(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            msg.sender,
            _offerEnd,
            _erc20Token,
            _tokenAmount
        );
   }

    function makeOffer(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,
        uint64  _offerEnd,
        address _erc20Token,
        uint128 _tokenAmount
    )
        external
        SaleOngoing(_nftContractAddress, _tokenId, _nftSeller)
    {
        require(
            !_isOfferValid(_nftContractAddress, _tokenId, _nftSeller, msg.sender),
            'Previous Offer is not expired'
        );
        _makeOffer(_nftContractAddress, _tokenId, _nftSeller, _offerEnd, _erc20Token, _tokenAmount);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║        BID FUNCTIONS         ║
      ╚══════════════════════════════╝*/
    /**********************************/

      /*╔══════════════════════════════╗
      ║       RESET FUNCTIONS        ║
      ╚══════════════════════════════╝*/

    /*
     * Reset all bid related parameters for an NFT.
     * This effectively sets an NFT as having no active bids
     */
    function _resetBids(address _nftContractAddress, uint256 _tokenId, address _nftSeller)
        internal
    {
        delete nftSales[_nftContractAddress][_tokenId][_nftSeller]
            ;
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       RESET FUNCTIONS        ║
      ╚══════════════════════════════╝*/
    /**********************************/

 
    /*╔══════════════════════════════╗
      ║  TRANSFER NFT & PAY SELLER   ║
      ╚══════════════════════════════╝*/
    function _transferNftAndPaySeller(
        address _nftContractAddress,
        uint256 _tokenId,
        address _nftSeller,  
        address _nftBidder,
        address _erc20Token,
        uint128 _tokenAmount
    ) internal {
        _resetBids(_nftContractAddress, _tokenId, _nftSeller);
        _payFeesAndSeller(
            _nftSeller,
            _nftBidder,
            _erc20Token,
            _tokenAmount
        );
        IERC721(_nftContractAddress).transferFrom(
            address(this),
            _nftBidder,
            _tokenId
        );

        emit NFTTransferredAndSellerPaid(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftBidder,
            _erc20Token,
            _tokenAmount
        );
    }

    function _payFeesAndSeller(
        address _nftSeller,
        address _nftBidder,
        address _erc20Token,
        uint256 _tokenAmount
    ) internal {
        uint256 feesPaid;
        for (
            uint256 i = 0;
            i <  feeRecipients.length;
            i++
        ) {
            uint256 fee = _getPortionOfBid(
                _tokenAmount,
                feePercentages[i]
            );
            feesPaid = feesPaid + fee;
            _payout(
                _erc20Token,
                _nftBidder,
                feeRecipients[i],
                fee
            );
        }
        _payout(
            _erc20Token,
            _nftBidder,
            _nftSeller,
            (_tokenAmount - feesPaid)
        );
    }

    function _payout(
        address _erc20Token,
        address _sender,
        address _recipient,
        uint256 _tokenAmount
    ) internal {
        IERC20(_erc20Token).transferFrom(_sender, _recipient, _tokenAmount);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║  TRANSFER NFT & PAY SELLER   ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║      OPEN & WITHDRAW       ║
      ╚══════════════════════════════╝*/
    function openSale(address _nftContractAddress, uint256 _tokenId)
        external
        isNotASale(_nftContractAddress, _tokenId, msg.sender)
    {
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender,
            "Not NFT owner"
        );
        
        nftState[_nftContractAddress][_tokenId][msg.sender] == State.Created;
        emit SaleOpened(_nftContractAddress, _tokenId, msg.sender);
    }

    function withdrawSale(address _nftContractAddress, uint256 _tokenId)
        external
    {
        //only the NFT owner can prematurely close and Sale
        require(
            IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender,
            "Not NFT owner"
        );
        nftState[_nftContractAddress][_tokenId][msg.sender] == State.Inactive;
        emit SaleBlocked(_nftContractAddress, _tokenId, msg.sender);
    }

    function withdrawBid(address _nftContractAddress, uint256 _tokenId, address _nftSeller)
        external
    {
        uint size = nftSales[_nftContractAddress][_tokenId][_nftSeller].length;
        bool deleted = false;
        for (uint i = 0; i < size; i++) {
            if (nftSales[_nftContractAddress][_tokenId][_nftSeller]
                [i].nftBuyer == msg.sender) {
                    delete nftSales[_nftContractAddress][_tokenId][_nftSeller]
                    [i];
                    deleted = true;
            }
        }
        if (deleted)  
            emit OfferWithdrawn(_nftContractAddress, _tokenId, _nftSeller, msg.sender);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║      SETTLE & WITHDRAW       ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║       UPDATE Sale         ║
      ╚══════════════════════════════╝*/
 

    /*
     * The NFT seller can opt to end an Sale by taking the current highest bid.
     */
    function takeOffer(
        address _nftContractAddress, 
        uint256 _tokenId,  
        address _nftBuyer,
        address _erc20Token,
        uint128 _tokenAmount
    )
        external
        onlyNftOwner(_nftContractAddress, _tokenId)
    {
        
        require(
            _isOfferValid(_nftContractAddress, _tokenId, msg.sender, _nftBuyer),
            'Offer is expired'
        );
        _transferNftToSaleContract(_nftContractAddress, _tokenId);
        _transferNftAndPaySeller(
            _nftContractAddress, 
            _tokenId, 
            msg.sender,
            _nftBuyer,
            _erc20Token,
            _tokenAmount
        );
        emit OfferTaken(
            _nftContractAddress, 
            _tokenId, 
            msg.sender,
            _nftBuyer,
            _erc20Token,
            _tokenAmount 
        );
    }


    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║       UPDATE Sale         ║
      ╚══════════════════════════════╝*/
    /**********************************/
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}