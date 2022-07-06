/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// contracts/NFTMarketplace.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

library Counters {
    struct Counter {
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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC2981 is IERC721 {
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

contract NFTMarketplace is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using Address for address payable;
    Counters.Counter private itemCounter; //start from 1
    Counters.Counter private itemSoldCounter;
    Counters.Counter private swapCounter;

    uint256 private collectedFees;

    uint256 public marketplaceFee = 150;
    uint256 public immutable denominator = 1000;

    enum State {
        Created,
        Release,
        Inactive
    }

    struct MarketItem {
        uint256 id;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable buyer;
        uint256 price;
        uint256 expiry;
        State state;
    }

    struct SwapItem {
        uint256 id;
        address[] sellerNFTContracts;
        uint256[] sellerTokenIds;
        address[] buyerNFTContracts;
        uint256[] buyerTokenIds;
        uint256 expiry;
        address seller;
        address buyer;
        State state;
    }

    mapping(uint256 => MarketItem) public marketItems;
    mapping(uint256 => SwapItem) public swapItems;

    event MarketItemCreated(
        uint256 indexed id,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price,
        uint256 expiry,
        State state
    );

    event MarketItemSold(
        uint256 indexed id,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address buyer,
        uint256 price,
        State state
    );

    event SwapItemCreated(
        uint256 indexed id,
        address[] sellerNFTContracts,
        uint256[] sellerTokenIds,
        address[] buyerNFTContracts,
        uint256[] buyerTokenIds,
        address seller,
        address buyer,
        uint256 expiry,
        State state
    );

    constructor() {}

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 expiry
    ) public {
        require(expiry > block.timestamp, "Invalid Expiry");
        require(price > 0, "Price must be at least 1 wei");

        require(
            checkAllowance(_msgSender(), nftContract, tokenId),
            "NFT must be approved to market"
        );


        itemCounter.increment();
        uint256 id = itemCounter.current();

        marketItems[id] = MarketItem(
            id,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            expiry,
            State.Created
        );


        emit MarketItemCreated(
            id,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            expiry,
            State.Created
        );
    }

    function createSwapItem(
        address seller,
        address[] calldata _sellerNFTContracts,
        uint256[] calldata _sellerTokenIds,
        address[] calldata _buyerNFTContracts,
        uint256[] calldata _buyerTokenIds,
        uint256 _expiry
    ) public {
        require(_expiry > block.timestamp, "Invalid expiry");
        require(_sellerNFTContracts.length == _sellerTokenIds.length, "Seller lengths mismatch");
        require(_buyerNFTContracts.length == _buyerTokenIds.length, "Buyer lengths mismatch");

        for (uint256 i; i < _sellerNFTContracts.length; i++) {
            require(IERC721(_sellerNFTContracts[i]).ownerOf(_sellerTokenIds[i]) == seller, "Token not owned by seller");
            require(checkAllowance(seller, _sellerNFTContracts[i], _sellerTokenIds[i]), "Seller NFT is not approved to the market");
        }

        for (uint256 i; i < _buyerNFTContracts.length; i++) {
            require(IERC721(_sellerNFTContracts[i]).ownerOf(_sellerTokenIds[i]) == _msgSender(), "Token not owned by seller");
            require(checkAllowance(_msgSender(), _buyerNFTContracts[i], _buyerTokenIds[i]), "Buyer NFT is not approved to the market");
        }

        swapCounter.increment();
        uint256 id = swapCounter.current();

        swapItems[id] = SwapItem(
            id,
            _sellerNFTContracts,
            _sellerTokenIds,
            _buyerNFTContracts,
            _buyerTokenIds,
            _expiry,
            seller,
            _msgSender(),
            State.Created
        );
    }

    function completeSwap(uint256 id) public {
        SwapItem storage item = swapItems[id];
        require(item.expiry >= block.timestamp, "Item has expired");
        require(_msgSender() == item.seller, "Not authorised");

        for (uint256 i; i < item.sellerNFTContracts.length; i++) {
            require(IERC721(item.sellerNFTContracts[i]).ownerOf(item.sellerTokenIds[i]) == item.seller, "Token not owned by seller");
            require(checkAllowance(item.seller, item.sellerNFTContracts[i], item.sellerTokenIds[i]), "Seller NFT must be approved to market");
        }

        for (uint256 i; i < item.buyerNFTContracts.length; i++) {
            require(IERC721(item.buyerNFTContracts[i]).ownerOf(item.buyerTokenIds[i]) == item.buyer, "Token not owned by seller");
            require(checkAllowance(item.buyer, item.buyerNFTContracts[i], item.buyerTokenIds[i]), "Buyer NFT must be approved to market");
        }

        item.state = State.Release;

        for (uint256 i; i < item.sellerNFTContracts.length; i++) {
            IERC721(item.sellerNFTContracts[i]).safeTransferFrom(item.seller, item.buyer, item.sellerTokenIds[i]);
        }

        for (uint256 i; i < item.buyerNFTContracts.length; i++) {
            IERC721(item.buyerNFTContracts[i]).safeTransferFrom(item.buyer, item.seller, item.buyerTokenIds[i]);
        }


    }

    function deleteMarketItem(uint256 itemId) public nonReentrant {
        require(itemId <= itemCounter.current(), "id must be less than item count");
        require(
            marketItems[itemId].state == State.Created,
            "item must be on market"
        );

        require(
            marketItems[itemId].expiry > block.timestamp,
            "Item has expired"
        );

        MarketItem storage item = marketItems[itemId];

        require(
            IERC721(item.nftContract).ownerOf(item.tokenId) == _msgSender(),
            "must be the owner"
        );
        require(
            checkAllowance(_msgSender(), item.nftContract, item.tokenId),
            "NFT must be approved to market"
        );

        item.state = State.Inactive;

        emit MarketItemSold(
            itemId,
            item.nftContract,
            item.tokenId,
            item.seller,
            address(0),
            0,
            State.Inactive
        );
    }

    function createMarketSale(uint256 id)
        public
        payable
        nonReentrant
    {
        MarketItem storage item = marketItems[id];
        uint256 price = item.price;
        uint256 tokenId = item.tokenId;

        require(msg.value == price, "Please submit the asking price");
        require(
            checkAllowance(_msgSender(), item.nftContract, tokenId),
            "NFT must be approved to market"
        );

        require(IERC721(item.nftContract).ownerOf(tokenId) == item.seller, "Seller is not the owner");

        require(
            item.expiry > block.timestamp,
            "Item has expired"
        );

        item.buyer = payable(_msgSender());
        item.state = State.Release;
        itemSoldCounter.increment();

        // (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(item.nftContract)
        //     .royaltyInfo(tokenId, msg.value);

        uint256 platformFee = (msg.value * marketplaceFee) / denominator;

        uint256 toSeller = msg.value - (/*royaltyAmount +*/ platformFee);

        collectedFees += platformFee;
        // payable(royaltyReceiver).sendValue(royaltyAmount);
        item.seller.sendValue(toSeller);

        IERC721(item.nftContract).transferFrom(item.seller, _msgSender(), tokenId);

        emit MarketItemSold(
            id,
            item.nftContract,
            tokenId,
            item.seller,
            _msgSender(),
            price,
            State.Release
        );
    }

    /**
     * @dev Returns all unsold market items
     * condition:
     *  1) state == Created
     *  2) buyer = 0x0
     *  3) still have approve
     */
    function fetchActiveItems(address user)
        public
        view
        returns (MarketItem[] memory)
    {
        return fetchHepler(FetchOperator.ActiveItems, user);
    }

    /**
     * @dev Returns only market items a user has purchased
     * todo pagination
     */
    function fetchMyPurchasedItems(address user)
        public
        view
        returns (MarketItem[] memory)
    {
        return fetchHepler(FetchOperator.MyPurchasedItems, user);
    }

    /**
     * @dev Returns only market items a user has created
     * todo pagination
     */
    function fetchMyCreatedItems(address user)
        public
        view
        returns (MarketItem[] memory)
    {
        return fetchHepler(FetchOperator.MyCreatedItems, user);
    }

    enum FetchOperator {
        ActiveItems,
        MyPurchasedItems,
        MyCreatedItems
    }

    function fetchHepler(FetchOperator _op, address user)
        private
        view
        returns (MarketItem[] memory)
    {
        uint256 total = itemCounter.current();

        uint256 itemCount = 0;
        for (uint256 i = 1; i <= total; i++) {
            if (isCondition(marketItems[i], _op, user)) {
                itemCount++;
            }
        }

        uint256 index = 0;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 1; i <= total; i++) {
            if (isCondition(marketItems[i], _op, user)) {
                items[index] = marketItems[i];
                index++;
            }
        }
        return items;
    }

    /**
     * @dev helper to build condition
     *
     * todo should reduce duplicate contract call here
     * (IERC721(item.nftContract).getApproved(item.tokenId) called in two loop
     */
    function isCondition(
        MarketItem memory item,
        FetchOperator _op,
        address user
    ) private view returns (bool) {
        if (_op == FetchOperator.MyCreatedItems) {
            return
                (item.seller == user && item.state != State.Inactive && item.expiry >= block.timestamp)
                    ? true
                    : false;
        } else if (_op == FetchOperator.MyPurchasedItems) {
            return (item.buyer == user) ? true : false;
        } else if (_op == FetchOperator.ActiveItems) {
            return
                (item.buyer == address(0) &&
                item.state == State.Created &&
                checkAllowance(_msgSender(), item.nftContract, item.tokenId) &&
                item.expiry >= block.timestamp
                )
                    ? true
                    : false;
        } else {
            return false;
        }
    }

    function checkAllowance(address user, address nftContract, uint256 tokenId) internal view returns (bool) {
        return (IERC721(nftContract).getApproved(tokenId) == address(this) || 
                IERC721(nftContract).isApprovedForAll(user, address(this))) ? true : false;
    }

    function withdrawFees() external onlyOwner {
        uint256 toSend = collectedFees;
        collectedFees = 0;
        payable(owner()).sendValue(toSend);
    }
}