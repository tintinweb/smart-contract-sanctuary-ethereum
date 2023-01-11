// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract marketPlace {
    //    enum state to check status of the NFT
    // enum State{
    //     Active,
    //     Cancel,
    //     Sold,
    //     End
    // }
    //  structure to store info of listed NFT
    struct list {
        // State _status;
        uint256 id;
        uint256 price;
        address token_address;
        address seller;
        address erc20Tkn;
        bool list;
    }

    struct auctionier {
        uint256 id;
        uint256 price;
        address token_address;
        address Erc20;
        address seller;
        uint256 startTime;
        uint256 endTime;
        uint highestPayableBid;
        // uint increment;
        address highestBidder;
        bool aucStart;
        bool aucCanceled;
    }
    // events

    event Listed(
        // State _status,
        uint256 id,
        uint256 price,
        address token_address,
        address seller,
        bool list
    );

    event Canceled(
        // State _status,
        uint256 id,
        bool list
    );

    event End(
        // State _status,
        uint256 id,
        bool list
    );

    event Sold(
        // State _status,
        uint256 id,
        bool list
    );
    // Mapping to store listed nft data on uint type key value

    mapping(uint256 => list) public listingMap;
    mapping(uint256 => auctionier) public aucInfo;

    // list[] public listArray;

    // uint256 private _listingId = 1;
    // address payable auctionier;
    // uint public startTime;
    // uint public endTime;

    // aucState public _aucState;

    // uint public highestBid;
    // uint increment;

    // mapping (address => uint) public allBids;
    // list function to list nfts

    function listNft(
        address _token,
        address _erc20,
        uint256 _id,
        uint256 _price
    ) public {
        require(aucInfo[_id].aucStart == false, "auction is started");
        require(listingMap[_id].list == false);
        IERC721(_token).transferFrom(msg.sender, address(this), _id);
        // listingMap[_id]._status = State.Active;
        listingMap[_id].id = _id;
        listingMap[_id].price = _price * 1**1;
        listingMap[_id].token_address = _token;
        listingMap[_id].seller = msg.sender;
        listingMap[_id].erc20Tkn = _erc20;
        listingMap[_id].list = true;
        // _listingId ++;

        emit Listed(_id, _price, _token, msg.sender, true);
    }

    function canceListorAuction(uint256 _id) public returns (string memory) {
        if (listingMap[_id].list == true) {
            // require(listingMap[_id]._status == State.Active);
            require(msg.sender == listingMap[_id].seller);

            IERC721(listingMap[_id].token_address).transferFrom(
                address(this),
                msg.sender,
                listingMap[_id].id
            );

            listingMap[_id].list = false;

            emit Canceled(_id, false);
        }

        if (aucInfo[_id].aucStart == true) {
            require(
                msg.sender == aucInfo[_id].seller,
                "You are not the seller"
            );
            // require(aucInfo[_id].aucStart == true,"auction is not started yet");
            require(
                aucInfo[_id].aucCanceled == false,
                "auction is already cancelled"
            );
            IERC721(aucInfo[_id].token_address).transferFrom(
                address(this),
                msg.sender,
                aucInfo[_id].id
            );
            aucInfo[_id].startTime = 0;
            aucInfo[_id].endTime = 0;
            aucInfo[_id].aucCanceled = true;
            aucInfo[_id].aucStart = false;
        } else {
            return "First list or auctionate your token";
        }
    }

    function buyNft(uint256 _id, uint256 _price) public payable {
        require(listingMap[_id].list == true, "Listing is not active yet");
        require(
            msg.sender != listingMap[_id].seller,
            "seller can't buy the Nft"
        );
        if (listingMap[_id].erc20Tkn != address(0)) {
            require(
                _price >= listingMap[_id].price,
                "your price is not correct"
            );

            IERC20(listingMap[_id].erc20Tkn).transferFrom(
                msg.sender,
                listingMap[_id].seller,
                _price
            );
            IERC721(listingMap[_id].token_address).transferFrom(
                address(this),
                msg.sender,
                listingMap[_id].id
            );

            // payable(listingMap[_id].seller).transfer(msg.value);

            listingMap[_id].list = false;

            emit Sold(_id, false);
        } else {
            _price = msg.value;
            require(
                _price >= listingMap[_id].price,
                "your price is not correct"
            );

            // IERC20(listingMap[_id].erc20Tkn).transferFrom(msg.sender,listingMap[_id].seller,_price);
            IERC721(listingMap[_id].token_address).transferFrom(
                address(this),
                msg.sender,
                listingMap[_id].id
            );

            // (bool, bytes memory) = msg.sender.call{value : _price}("");
            payable(listingMap[_id].seller).transfer(_price);

            listingMap[_id].list = false;

            emit Sold(_id, false);
        }
    }

    function auction(
        address _token,
        address erc20,
        uint256 _id,
        uint256 _initPrice,
        uint256 _duration
    ) public {
        // require(listingMap[_id]._status == State.Active,"Listing is not active");
        // require(msg.sender == listingMap[_id].seller,"You are not the seller");
        // require(listingMap[_id]._status != State.Active,"You already listed your NFT");
        require(listingMap[_id].list == false, "you already listed your NFT");
        require(aucInfo[_id].aucStart == false);
        IERC721(_token).transferFrom(msg.sender, address(this), _id);
        aucInfo[_id].id = _id;
        aucInfo[_id].price = _initPrice;
        aucInfo[_id].token_address = _token;
        aucInfo[_id].Erc20 = erc20;
        aucInfo[_id].seller = msg.sender;
        aucInfo[_id].startTime = block.timestamp;
        aucInfo[_id].endTime = block.timestamp + _duration;
        aucInfo[_id].aucCanceled = false;
        aucInfo[_id].aucStart = true;
    }

    // function cancelAuction(uint256 _id) public {
    //     // require(listingMap[_id]._status == State.Active,"Listing is not active");
    //     require(msg.sender == aucInfo[_id].seller,"You are not the seller");
    //     require(aucInfo[_id].aucStart == true,"auction is not started yet");
    //     require(aucInfo[_id].aucCanceled == false,"auction is already cancelled");
    //     aucInfo[_listingId].startTime = 0;
    //     aucInfo[_listingId].endTime = 0;
    //     aucInfo[_listingId].aucCanceled = true;
    //     aucInfo[_listingId].aucStart = false;
    // }

    function bidding(uint256 _id, uint256 _price) public payable {
        require(aucInfo[_id].aucStart == true, "Auction is not started");
        require(
            aucInfo[_id].aucCanceled == false,
            "auction is already cancelled"
        );
        require(msg.sender != aucInfo[_id].seller, "you can't bid");

        require(_price > aucInfo[_id].price, "Enter correct price");
        require(block.timestamp < aucInfo[_id].endTime, "auction is ended");

        IERC20 tkn = IERC20(aucInfo[_id].Erc20);
        if (aucInfo[_id].Erc20 != address(0)) {
            require(_price > aucInfo[_id].highestPayableBid, "Your bid is low");

            uint _currentBid = _price;

            // tkn.transferFrom(msg.sender, address(this), _currentBid);

            if (
                aucInfo[_id].highestBidder != address(0) &&
                _currentBid > aucInfo[_id].highestPayableBid
            ) {
                // require(_currentBid > highestPayableBid);
                // _currentBid =  msg.value;
                tkn.transfer(
                    aucInfo[_id].highestBidder,
                    aucInfo[_id].highestPayableBid
                );
                // allBids[highestBidder] = highestPayableBid;
            }
            aucInfo[_id].highestPayableBid = _currentBid;
            aucInfo[_id].highestBidder = msg.sender;
            tkn.transferFrom(
                aucInfo[_id].highestBidder,
                address(this),
                aucInfo[_id].highestPayableBid
            );
        } else {
            // require(aucInfo[_id].aucStart == true,"Auction is not started");
            // require(aucInfo[_id].aucCanceled == false,"auction is already cancelled");
            // require(msg.sender != aucInfo[_id].seller,"you can't bid");

            // require(msg.value > aucInfo[_id].price,"Enter correct price");
            // require(block.timestamp < aucInfo[_id].endTime,"auction is ended");
            // require(msg.value > aucInfo[_id].highestPayableBid,"Your bid is low");
            // require(highestBidder != address(0));
            require(_price > aucInfo[_id].highestPayableBid, "Your bid is low");
            uint _currentBid = msg.value;

            if (
                aucInfo[_id].highestBidder != address(0) &&
                _currentBid > aucInfo[_id].highestPayableBid
            ) {
                // require(_currentBid > highestPayableBid);
                // _currentBid =  msg.value;
                payable(aucInfo[_id].highestBidder).transfer(
                    aucInfo[_id].highestPayableBid
                );
                // allBids[highestBidder] = highestPayableBid;
            }
            aucInfo[_id].highestPayableBid = _currentBid;
            aucInfo[_id].highestBidder = msg.sender;
        }
        // highestPayableBid = msg.value;
        // highestBidder = msg.sender;
    }

    function finalizeAuction(uint256 _id) public payable {
        require(
            aucInfo[_id].aucCanceled == false ||
                block.timestamp > aucInfo[_id].endTime,
            "Auction is not started"
        );
        require(
            msg.sender == aucInfo[_id].highestBidder ||
                msg.sender == aucInfo[_id].seller,
            "error"
        );

        // address payable person;
        // uint256 value;
        IERC721(aucInfo[_id].token_address).transferFrom(
            address(this),
            aucInfo[_id].highestBidder,
            aucInfo[_id].id
        );

        aucInfo[_id].aucStart = false;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}