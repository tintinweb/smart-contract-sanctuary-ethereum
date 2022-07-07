/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// File: Marketplace.sol

// contracts/NFTMarketplace.sol

pragma solidity 0.8.15;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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

abstract contract BasePlace is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    using Address for address payable;
    Counters.Counter private itemCounter; //start from 1
    Counters.Counter private itemSoldCounter;
    Counters.Counter private swapCounter;

    mapping(address => uint256) private collectedFees;

    address private marketOperator;

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
        address creatorAddress;
        uint256 creatorRoyalty;
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
        address token,
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

    event SwapSuccessful(
        uint256 indexed id,
        address[] sellerNFTContracts,
        uint256[] sellerTokenIds,
        address[] buyerNFTContracts,
        uint256[] buyerTokenIds,
        address seller,
        address buyer,
        State state
    );

    constructor(address operator) {
        marketOperator = operator;
    }

    /// @dev View functions

    function fetchAllActiveItems() external view returns (MarketItem[] memory) {
        uint256 itemCount;
        uint256 total = itemCounter.current();
        for (uint256 i = 1; i < total; i++) {
            if (marketItems[i].buyer == address(0) &&
                marketItems[i].state == State.Created &&
                marketItems[i].expiry >= block.timestamp &&
                checkAllowance(marketItems[i].seller, marketItems[i].nftContract, marketItems[i].tokenId)) {
                    itemCount ++;
                }
        }

        uint256 index;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 1; i < total; i++) {
            if (marketItems[i].buyer == address(0) &&
                marketItems[i].state == State.Created &&
                marketItems[i].expiry >= block.timestamp &&
                checkAllowance(marketItems[i].seller, marketItems[i].nftContract, marketItems[i].tokenId)) {
                    items[index] = marketItems[i];
                    index ++;
                }
        }
        return items;
    }

    function fetchAllNFTItems(address _nftContract) external view returns (MarketItem[] memory) {
        uint256 itemCount;
        uint256 total = itemCounter.current();
        for (uint256 i = 1; i < total; i++) {
            if (marketItems[i].nftContract == _nftContract) {
                itemCount ++;
            }
        }
        uint256 index;
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 1; i < total; i++) {
            if (marketItems[i].nftContract == _nftContract) {
                items[index] = marketItems[i];
                index ++;
            }
        }
        return items;
    }

    function fetchAllUserSwaps(address user) external view returns (SwapItem[] memory) {
        uint256 itemCount;
        uint256 total = swapCounter.current();
        for (uint256 i = 1; i < total; i++) {
            if (swapItems[i].state == State.Created &&
                swapItems[i].expiry >= block.timestamp &&
                (swapItems[i].buyer == user || swapItems[i].seller == user)) {
                    itemCount ++;
                }
        }
        uint256 index;
        SwapItem[] memory items = new SwapItem[](itemCount);
        for (uint256 i = 1; i < total; i++) {
            if (swapItems[i].state == State.Created &&
                swapItems[i].expiry >= block.timestamp &&
                (swapItems[i].buyer == user || swapItems[i].seller == user)) {
                    items[index] = swapItems[i];
                    index ++;
            }
        }
        return items;
    }

    function fetchUserActiveItems(address user)
        external
        view
        returns (MarketItem[] memory)
    {
        return fetchHepler(FetchOperator.ActiveItems, user);
    }

    function fetchMyPurchasedItems(address user)
        external
        view
        returns (MarketItem[] memory)
    {
        return fetchHepler(FetchOperator.MyPurchasedItems, user);
    }

    function fetchMyCreatedItems(address user)
        external
        view
        returns (MarketItem[] memory)
    {
        return fetchHepler(FetchOperator.MyCreatedItems, user);
    }

    /// @dev Public write functions

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 expiry,
        address creatorAddress,
        uint256 creatorRoyalty,
        bytes memory data
    ) external {
        require(verifyPost(nftContract, tokenId, _msgSender(), price, expiry, creatorAddress, creatorRoyalty, data), "Not authorised");
        require(expiry <= (block.timestamp + 30*24*60*60), "Invalid Expiry");
        require(price > 0, "Price must be at least 1 wei");
        require(checkAllowance(_msgSender(), nftContract, tokenId), "NFT must be approved to market");

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
            creatorAddress,
            creatorRoyalty,
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

    function createMarketSale(uint256 id) external payable nonReentrant {
        MarketItem storage item = marketItems[id];
        uint256 price = item.price;
        uint256 tokenId = item.tokenId;

        require(msg.value == price, "Please submit the asking price");
        require(checkAllowance(item.seller, item.nftContract, tokenId), "NFT must be approved to market");
        require(IERC721(item.nftContract).ownerOf(tokenId) == item.seller, "Seller is not the owner");
        require(item.expiry > block.timestamp, "Item has expired");
        require(item.state == State.Created, "Invalid State");

        item.buyer = payable(_msgSender());
        item.state = State.Release;
        itemSoldCounter.increment();

        uint256 toSeller = msg.value;

        if (marketplaceFee > 0) {
            uint256 platformFee = (msg.value * marketplaceFee) / denominator;
            collectedFees[address(0)] += platformFee;
            toSeller -= platformFee;
        }

        if (item.creatorRoyalty > 0) {
            uint256 creatorRoyalty = (msg.value * item.creatorRoyalty) / denominator;
            toSeller -= creatorRoyalty;
            payable(item.creatorAddress).sendValue(creatorRoyalty);
        }

        item.seller.sendValue(toSeller);

        IERC721(item.nftContract).transferFrom(item.seller, _msgSender(), tokenId);

        emit MarketItemSold(
            id,
            item.nftContract,
            tokenId,
            item.seller,
            _msgSender(),
            address(0),
            price,
            State.Release
        );
    }

    function deleteMarketItem(uint256 itemId) external {
        require(itemId <= itemCounter.current(), "id must be less than item count");
        MarketItem storage item = marketItems[itemId];
        require(item.state == State.Created, "item must be on market");
        require(item.expiry >= block.timestamp, "Item has expired");
        require(IERC721(item.nftContract).ownerOf(item.tokenId) == _msgSender(), "Caller is not the owner of NFT");
        require(item.seller == _msgSender(), "Caller is not the owner");
        require(checkAllowance(_msgSender(), item.nftContract, item.tokenId), "NFT must be approved to market");

        item.state = State.Inactive;

        emit MarketItemSold(
            itemId,
            item.nftContract,
            item.tokenId,
            item.seller,
            address(0),
            address(0),
            0,
            State.Inactive
        );
    }

    function completeMarketSaleBid(uint256 id, address nftContract, uint256 tokenId, address seller, address buyer, address token, uint256 price, address creatorAddress, uint256 creatorRoyalty, bytes memory data) external nonReentrant {
        require(verifyBid(id, nftContract, tokenId, seller, buyer, token, price, creatorAddress, creatorRoyalty, data), "Invalid signature");
        require(IERC20(token).allowance(buyer, address(this)) >= price, "Not enough approved");

        IERC20(token).transferFrom(buyer, address(this), price);
        uint256 toSeller = price;

        if (marketplaceFee > 0) {
            uint256 platformFee = (price * marketplaceFee) / denominator;
            collectedFees[token] += platformFee;
            toSeller -= platformFee;
        }

        if (creatorRoyalty > 0) {
            uint256 creatorFee = (price * creatorRoyalty) / denominator;
            toSeller -= creatorFee;
            IERC20(token).transfer(creatorAddress, creatorFee);
        }

        IERC721(nftContract).safeTransferFrom(seller, buyer, tokenId);
        IERC20(token).transfer(seller, toSeller);

        emit MarketItemSold(
            id, 
            nftContract, 
            tokenId, 
            seller, 
            buyer, 
            token,
            price, 
            State.Release);
        
    }

    function createSwapItem(
        address seller,
        address[] calldata _sellerNFTContracts,
        uint256[] calldata _sellerTokenIds,
        address[] calldata _buyerNFTContracts,
        uint256[] calldata _buyerTokenIds,
        uint256 _expiry
    ) external {
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

    function completeSwap(uint256 itemId) external {
        SwapItem storage item = swapItems[itemId];
        require(item.expiry >= block.timestamp, "Item has expired");
        require(_msgSender() == item.seller, "Not authorised");
        require(item.state == State.Created, "Invalid State");

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

        itemSoldCounter.increment();

        emit SwapSuccessful(
            itemId, 
            item.sellerNFTContracts, 
            item.sellerTokenIds, 
            item.buyerNFTContracts, 
            item.buyerTokenIds, 
            item.seller, 
            item.buyer, 
            item.state
        );

    }

    function deleteSwapItem(uint256 itemId) external {
        require(itemId <= swapCounter.current(), "id must be less than item count");
        SwapItem storage item = swapItems[itemId];
        require(item.state == State.Created, "Item must be on market");
        require(item.expiry >= block.timestamp, "Item has expired");
        require(item.buyer == _msgSender(), "Caller is not authorised");
        item.state = State.Inactive;
        emit SwapSuccessful(
            itemId, 
            item.sellerNFTContracts, 
            item.sellerTokenIds, 
            item.buyerNFTContracts, 
            item.buyerTokenIds, 
            item.seller, 
            item.buyer, 
            item.state
            );
    }

    /// @dev Internal Functions

    enum FetchOperator {
        ActiveItems,
        MyPurchasedItems,
        MyCreatedItems
    }

    function fetchHepler(FetchOperator _op, address user)
        internal
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

    function isCondition(
        MarketItem memory item,
        FetchOperator _op,
        address user
    ) internal view returns (bool) {
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
                item.seller == user &&
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

    function withdrawFees(address token) external onlyOwner {
        uint256 toSend = collectedFees[token];
        collectedFees[token] = 0;
        if (token == address(0)) {
            payable(owner()).sendValue(toSend);
        } else {
            IERC20(token).transfer(owner(), toSend);
        }
    }

    /// @dev Bytes verification

    function verifyPost(address nftContract, uint256 tokenId, address seller, uint256 price, uint256 expiry, address creatorAddress, uint256 creatorRoyalty, bytes memory data) internal view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(nftContract, tokenId, seller, price, expiry, creatorAddress, creatorRoyalty));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return recoverSigner(ethSignedMessageHash, data) == marketOperator;
    }

    function verifyBid(uint256 id, address nftContract, uint256 tokenId, address seller, address buyer, address token, uint256 price, address creatorAddress, uint256 creatorRoyalty, bytes memory data) internal view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(id, nftContract, tokenId, seller, buyer, token, price, creatorAddress, creatorRoyalty));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        return recoverSigner(ethSignedMessageHash, data) == marketOperator;
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

}


abstract contract CrossChain is ReentrancyGuard, Ownable {
    uint256 public zeta;

    function changeZeta(uint256 number) public {
        zeta = number;
    }
}

contract MarketPlace is BasePlace, CrossChain {

    constructor(address sys) BasePlace(sys) {}



    /// @dev For testing purposes only 

    function getMessageHashBid(uint256 id, address nftContract, uint256 tokenId, address seller, address buyer, address token, uint256 price, address creatorAddress, uint256 creatorRoyalty) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(id, nftContract, tokenId, seller, buyer, token, price, creatorAddress, creatorRoyalty));
    }

    function getMessageHashPost(address nftContract, uint256 tokenId, address seller, uint256 price, uint256 expiry, address creatorAddress, uint256 creatorRoyalty) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(nftContract, tokenId, seller, price, expiry, creatorAddress, creatorRoyalty));
    }

}