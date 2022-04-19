// SPDX-License-Identifier: MIT
// Gallery of solid state contracts

pragma solidity ^0.8.0;
pragma abicoder v2;

import "IERC20.sol";

contract SolidStateGallery {
    struct buyOrder {
        address artworkAddress;
        address orderOwner;
        uint256 shareValue;
        uint256 ethValue;
        uint256 balance;
        OrderState state;
    }
    struct sellOrder {
        address artworkAddress;
        address orderOwner;
        uint256 shareValue;
        uint256 ethValue;
        uint256 balance;
        OrderState state;
    }

    enum OrderState {
        OPEN,
        CLOSED,
        CANCELLED
    }
    struct transaction {
        address artwork;
        uint256 eth;
        uint256 share;
        uint256 buyId;
        uint256 sellId;
        address buyer;
        address seller;
    }

    mapping(uint256 => transaction) private transactions;
    uint256 transactionCount = 0;

    mapping(uint256 => buyOrder) private buyOrders;
    mapping(uint256 => sellOrder) private sellOrders;
    uint256 buyOrderCount = 0;
    uint256 sellOrderCount = 0;

    mapping(uint256 => address) private artWorkContracts;
    mapping(uint256 => string) private artWorkCollections;
    mapping(uint256 => uint256) private artWorkCollection;
    mapping(address => bool) private artWorkVisibility;
    uint256 private artWorkCount;
    uint256 private collectionCount;
    address[] private owners;
    uint256 ownerCount;

    struct allArtworks {
        address contractAddress;
        bool visibilty;
    }

    modifier onlyOwner() {
        require(msg.sender == owners[ownerCount]);
        _;
    }

    constructor() {
        owners.push(msg.sender);
        artWorkCount = 0;
        ownerCount = 0;
        collectionCount = 0;
    }

    function addArtWork(address _artWorkAddress, uint256 _collectionId)
        public
        onlyOwner
    {
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            require(
                artWorkContracts[artWorkIndex] != _artWorkAddress,
                "Art work already added"
            );
        }
        artWorkContracts[artWorkCount] = _artWorkAddress;
        artWorkCollection[artWorkCount] = _collectionId;
        artWorkVisibility[_artWorkAddress] = false;
        artWorkCount++;
    }

    function addCollection(string memory _collectionName) public onlyOwner {
        for (
            uint256 collectionIndex = 0;
            collectionIndex < collectionCount;
            collectionIndex++
        ) {
            require(
                compareStrings(
                    artWorkCollections[collectionIndex],
                    _collectionName
                ) == false,
                "Collection is already added"
            );
        }
        artWorkCollections[collectionCount] = _collectionName;

        collectionCount++;
    }

    function getCollectionIdByName(string memory _collectionName)
        public
        view
        returns (uint256)
    {
        bool isName = false;
        for (
            uint256 collectionIndex = 0;
            collectionIndex < collectionCount;
            collectionIndex++
        ) {
            if (
                compareStrings(
                    artWorkCollections[collectionIndex],
                    _collectionName
                ) == true
            ) {
                return collectionIndex;
            }
        }
        require(isName == true, "No Collection By That Name");
        return 0;
    }

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function getCollections() public view returns (string[] memory) {
        string[] memory collections = new string[](collectionCount);
        for (
            uint256 collectionIndex = 0;
            collectionIndex < collectionCount;
            collectionIndex++
        ) {
            collections[collectionIndex] = artWorkCollections[collectionIndex];
        }
        return collections;
    }

    function getAllArtWorksByCollectionId(uint256 _Id)
        public
        view
        returns (address[] memory, bool[] memory)
    {
        uint256 count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkCollection[artWorkIndex] == _Id) {
                count++;
            }
        }
        address[] memory contracts = new address[](count);
        bool[] memory visibility = new bool[](count);
        count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkCollection[artWorkIndex] == _Id) {
                contracts[count] = artWorkContracts[artWorkIndex];
                visibility[count] = artWorkVisibility[
                    artWorkContracts[artWorkIndex]
                ];
                count++;
            }
        }
        return (contracts, visibility);
    }

    function getArtWorksByCollectionId(uint256 _Id)
        public
        view
        returns (address[] memory)
    {
        uint256 count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkVisibility[artWorkContracts[artWorkIndex]] == true) {
                if (artWorkCollection[artWorkIndex] == _Id) {
                    count++;
                }
            }
        }
        address[] memory contracts = new address[](count);
        count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkVisibility[artWorkContracts[artWorkIndex]] == true) {
                if (artWorkCollection[artWorkIndex] == _Id) {
                    contracts[count] = artWorkContracts[artWorkIndex];
                    count++;
                }
            }
        }
        return contracts;
    }

    function getAllArtWorks()
        public
        view
        returns (address[] memory, bool[] memory)
    {
        address[] memory contracts = new address[](artWorkCount);
        bool[] memory visibility = new bool[](artWorkCount);
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            contracts[artWorkIndex] = artWorkContracts[artWorkIndex];
            visibility[artWorkIndex] = artWorkVisibility[
                artWorkContracts[artWorkIndex]
            ];
        }
        return (contracts, visibility);
    }

    function getArtWorks() public view returns (address[] memory) {
        uint256 count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkVisibility[artWorkContracts[artWorkIndex]] == true) {
                count++;
            }
        }
        address[] memory contracts = new address[](count);
        count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkVisibility[artWorkContracts[artWorkIndex]] == true) {
                contracts[count] = artWorkContracts[artWorkIndex];
                count++;
            }
        }
        return contracts;
    }

    function setArtWorkVisibility(
        address _artWorkContractAddress,
        bool _visibility
    ) public onlyOwner {
        artWorkVisibility[_artWorkContractAddress] = _visibility;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function newOwner(address _newOwnerAddress) public onlyOwner {
        ownerCount++;
        owners.push(_newOwnerAddress);
    }

    /// TRADE THE SHARES/TOKENS FOR ETH

    function getAllBuyOrders(address _artworkAddress)
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint8 c = 0;
        for (uint8 j = 0; j < buyOrderCount; j++) {
            if (buyOrders[j].state == OrderState.OPEN) {
                if (buyOrders[j].artworkAddress == _artworkAddress) {
                    c += 1;
                }
            }
        }

        uint256[] memory _shareValues = new uint256[](c);
        uint256[] memory _ethValues = new uint256[](c);
        uint256[] memory _balances = new uint256[](c);
        uint256[] memory _ids = new uint256[](c);
        c = 0;
        for (uint8 j = 0; j < buyOrderCount; j++) {
            if (buyOrders[j].state == OrderState.OPEN) {
                if (buyOrders[j].artworkAddress == _artworkAddress) {
                    _shareValues[c] = buyOrders[j].shareValue;
                    _ethValues[c] = buyOrders[j].ethValue;
                    _balances[c] = buyOrders[j].balance;
                    _ids[c] = j;
                    c++;
                }
            }
        }
        return (_shareValues, _ethValues, _balances, _ids);
    }

    function getBuyOrdersByAddress(address _artworkAddress, address _address)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            OrderState[] memory,
            uint256[] memory
        )
    {
        uint8 c = 0;
        for (uint8 j = 0; j < buyOrderCount; j++) {
            if (buyOrders[j].orderOwner == _address) {
                if (buyOrders[j].artworkAddress == _artworkAddress) {
                    c++;
                }
            }
        }
        address[] memory _orderOwners = new address[](c);
        uint256[] memory _shareValues = new uint256[](c);
        uint256[] memory _ethValues = new uint256[](c);
        uint256[] memory _balances = new uint256[](c);
        uint256[] memory _ids = new uint256[](c);
        OrderState[] memory _states = new OrderState[](c);
        c = 0;
        for (uint8 j = 0; j < buyOrderCount; j++) {
            if (buyOrders[j].orderOwner == _address) {
                if (buyOrders[j].artworkAddress == _artworkAddress) {
                    _orderOwners[c] = buyOrders[j].orderOwner;
                    _shareValues[c] = buyOrders[j].shareValue;
                    _ethValues[c] = buyOrders[j].ethValue;
                    _balances[c] = buyOrders[j].balance;

                    _ids[c] = j;
                    _states[c] = buyOrders[j].state;
                    c++;
                }
            }
        }
        return (
            _orderOwners,
            _shareValues,
            _ethValues,
            _balances,
            _states,
            _ids
        );
    }

    function getAllSellOrders(address _artworkAddress)
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint8 c = 0;
        for (uint8 j = 0; j < sellOrderCount; j++) {
            if (sellOrders[j].artworkAddress == _artworkAddress) {
                if (sellOrders[j].state == OrderState.OPEN) {
                    c++;
                }
            }
        }
        uint256[] memory _shareValues = new uint256[](c);
        uint256[] memory _ethValues = new uint256[](c);
        uint256[] memory _balances = new uint256[](c);
        uint256[] memory _ids = new uint256[](c);
        c = 0;
        for (uint8 j = 0; j < sellOrderCount; j++) {
            if (sellOrders[j].artworkAddress == _artworkAddress) {
                if (sellOrders[j].state == OrderState.OPEN) {
                    _shareValues[c] = sellOrders[j].shareValue;
                    _ethValues[c] = sellOrders[j].ethValue;
                    _balances[c] = sellOrders[j].balance;
                    _ids[c] = j;
                    c++;
                }
            }
        }
        return (_shareValues, _ethValues, _balances, _ids);
    }

    function getSellOrdersByAddress(address _artworkAddress, address _address)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            OrderState[] memory,
            uint256[] memory
        )
    {
        uint8 c = 0;
        for (uint8 j = 0; j < sellOrderCount; j++) {
            if (sellOrders[j].artworkAddress == _artworkAddress) {
                if (sellOrders[j].orderOwner == _address) {
                    c++;
                }
            }
        }
        address[] memory _orderOwners = new address[](c);
        uint256[] memory _shareValues = new uint256[](c);
        uint256[] memory _ethValues = new uint256[](c);
        uint256[] memory _balances = new uint256[](c);
        uint256[] memory _ids = new uint256[](c);
        OrderState[] memory _states = new OrderState[](c);
        c = 0;
        for (uint8 j = 0; j < sellOrderCount; j++) {
            if (sellOrders[j].orderOwner == _address) {
                if (sellOrders[j].artworkAddress == _artworkAddress) {
                    _orderOwners[c] = sellOrders[j].orderOwner;
                    _shareValues[c] = sellOrders[j].shareValue;
                    _ethValues[c] = sellOrders[j].ethValue;
                    _balances[c] = sellOrders[j].balance;
                    _states[c] = sellOrders[j].state;
                    _ids[c] = j;
                    c++;
                }
            }
        }
        return (
            _orderOwners,
            _shareValues,
            _ethValues,
            _balances,
            _states,
            _ids
        );
    }

    function placeBuyOrder(
        address _artworkAddress,
        uint256 shareValue,
        uint256 ethValue
    ) public payable returns (uint256) {
        require(shareValue > 0, "share value can not be 0");
        require(ethValue > 0, "share value can not be 0");

        require((msg.value / shareValue) == ethValue, "can not make order");
        buyOrders[buyOrderCount] = buyOrder(
            _artworkAddress,
            msg.sender,
            shareValue,
            ethValue,
            msg.value,
            OrderState.OPEN
        );

        fillBuyOrder(buyOrderCount);
        buyOrderCount += 1;
        return buyOrderCount - 1;
    }

    function placeSellOrder(
        address _artworkAddress,
        uint256 shareValue,
        uint256 ethValue
    ) public returns (uint256) {
        require(shareValue > 0, "share value can not be 0");
        require(ethValue > 0, "share value can not be 0");
        //IERC20(_artworkAddress).allowance(msg.sender, address(this));
        IERC20(_artworkAddress).transferFrom(
            msg.sender,
            address(this),
            shareValue
        );
        sellOrders[sellOrderCount] = sellOrder(
            _artworkAddress,
            msg.sender,
            shareValue,
            ethValue,
            shareValue,
            OrderState.OPEN
        );

        fillSellOrder(sellOrderCount);
        sellOrderCount += 1;
        return sellOrderCount - 1; // IERC20(_artworkAddress).balanceOf(msg.sender); //
    }

    function cancelBuyOrder(uint256 id) public {
        require(
            buyOrders[id].orderOwner == msg.sender,
            "msg.sender is not order owner"
        );
        require(buyOrders[id].state == OrderState.OPEN, "order is not open");

        address payable payee = payable(msg.sender);
        payee.transfer(buyOrders[id].balance);
        buyOrders[id].balance = 0;
        buyOrders[id].state = OrderState.CANCELLED;
    }

    function cancelSellOrder(uint256 id) public {
        require(
            sellOrders[id].orderOwner == msg.sender,
            "msg.sender is not order owner"
        );
        require(sellOrders[id].state == OrderState.OPEN, "order is not open");

        sellOrders[id].state = OrderState.CANCELLED;
        IERC20(sellOrders[id].artworkAddress).transfer(
            sellOrders[id].orderOwner,
            sellOrders[id].balance
        );
        sellOrders[id].balance = 0;
    }

    function getHeldShares(address _artworkAddress)
        public
        view
        returns (uint256)
    {
        uint256 heldShares = 0;
        for (uint8 j = 0; j < sellOrderCount; j++) {
            if (sellOrders[j].artworkAddress == _artworkAddress) {
                heldShares += sellOrders[j].balance;
            }
        }
        return heldShares;
    }

    function getHeldETH(address _artworkAddress) public view returns (uint256) {
        uint256 heldETH = 0;
        for (uint8 j = 0; j < buyOrderCount; j++) {
            if (buyOrders[j].artworkAddress == _artworkAddress) {
                heldETH += buyOrders[j].balance;
            }
        }
        return heldETH;
    }

    function fillBuyOrder(uint256 bc) private {
        for (uint8 j = 0; j < sellOrderCount; j++) {
            if (sellOrders[j].state == OrderState.OPEN) {
                if (buyOrders[bc].state == OrderState.OPEN) {
                    if (
                        sellOrders[j].artworkAddress ==
                        buyOrders[bc].artworkAddress
                    ) {
                        if (sellOrders[j].ethValue == buyOrders[bc].ethValue) {
                            address payable seller = payable(
                                sellOrders[j].orderOwner
                            );
                            uint256 transferAmount = 0;
                            if (
                                sellOrders[j].balance >=
                                buyOrders[bc].shareValue
                            ) {
                                sellOrders[j].balance =
                                    sellOrders[j].balance -
                                    buyOrders[bc].shareValue;

                                transferAmount = buyOrders[bc].shareValue;

                                buyOrders[bc].balance = 0;
                                buyOrders[bc].shareValue = 0;

                                buyOrders[bc].state = OrderState.CLOSED;

                                if (sellOrders[j].balance == 0) {
                                    sellOrders[j].state = OrderState.CLOSED;
                                }
                            } else {
                                buyOrders[bc].balance =
                                    buyOrders[bc].balance -
                                    (sellOrders[j].ethValue *
                                        sellOrders[j].balance);

                                buyOrders[bc].shareValue =
                                    buyOrders[bc].shareValue -
                                    sellOrders[j].balance;

                                transferAmount = sellOrders[j].balance;

                                sellOrders[j].balance = 0;
                                sellOrders[j].state = OrderState.CLOSED;
                                if (buyOrders[bc].balance == 0) {
                                    buyOrders[bc].state = OrderState.CLOSED;
                                }
                            }
                            seller.transfer(
                                buyOrders[bc].ethValue * transferAmount
                            );

                            IERC20(buyOrders[bc].artworkAddress).transfer(
                                buyOrders[bc].orderOwner,
                                transferAmount
                            );
                            orderTransaction(
                                buyOrders[bc].artworkAddress,
                                buyOrders[bc].ethValue * transferAmount,
                                transferAmount,
                                bc,
                                j,
                                buyOrders[bc].orderOwner,
                                sellOrders[j].orderOwner
                            );
                        }
                    }
                }
            }
        }
    }

    function fillSellOrder(uint256 sc) private {
        for (uint8 j = 0; j < buyOrderCount; j++) {
            if (sellOrders[sc].state == OrderState.OPEN) {
                if (buyOrders[j].state == OrderState.OPEN) {
                    if (
                        sellOrders[sc].artworkAddress ==
                        buyOrders[j].artworkAddress
                    ) {
                        if (sellOrders[sc].ethValue == buyOrders[j].ethValue) {
                            address payable seller = payable(
                                sellOrders[sc].orderOwner
                            );
                            uint256 transferAmount = 0;
                            if (
                                sellOrders[sc].balance >=
                                buyOrders[j].shareValue
                            ) {
                                sellOrders[sc].balance =
                                    sellOrders[sc].balance -
                                    buyOrders[j].shareValue;

                                transferAmount = buyOrders[j].shareValue;

                                buyOrders[j].balance = 0;
                                buyOrders[j].shareValue = 0;

                                buyOrders[j].state = OrderState.CLOSED;

                                if (sellOrders[sc].balance == 0) {
                                    sellOrders[sc].state = OrderState.CLOSED;
                                }
                            } else {
                                buyOrders[j].balance =
                                    buyOrders[j].balance -
                                    (sellOrders[sc].ethValue *
                                        sellOrders[sc].balance);

                                transferAmount = sellOrders[sc].balance;
                                buyOrders[j].shareValue =
                                    buyOrders[j].shareValue -
                                    sellOrders[sc].balance;

                                sellOrders[sc].balance = 0;
                                sellOrders[sc].state = OrderState.CLOSED;
                                if (buyOrders[j].balance == 0) {
                                    buyOrders[j].state = OrderState.CLOSED;
                                }
                            }

                            seller.transfer(
                                buyOrders[j].ethValue * transferAmount
                            );
                            IERC20(buyOrders[j].artworkAddress).transfer(
                                buyOrders[j].orderOwner,
                                transferAmount
                            );
                            orderTransaction(
                                buyOrders[j].artworkAddress,
                                buyOrders[j].ethValue * transferAmount,
                                transferAmount,
                                j,
                                sc,
                                buyOrders[j].orderOwner,
                                sellOrders[sc].orderOwner
                            );
                        }
                    }
                }
            }
        }
    }

    function orderTransaction(
        address artwork,
        uint256 eth,
        uint256 share,
        uint256 buyId,
        uint256 sellId,
        address buyer,
        address seller
    ) internal {
        transactions[transactionCount].artwork = artwork;
        transactions[transactionCount].eth = eth;
        transactions[transactionCount].share = share;
        transactions[transactionCount].buyId = buyId;
        transactions[transactionCount].sellId = sellId;
        transactions[transactionCount].buyer = buyer;
        transactions[transactionCount].seller = seller;
        transactionCount++;
    }

    function getTransactions(address _artworkAddress)
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            address[] memory,
            address[] memory
        )
    {
        uint256 c = 0;
        for (uint8 j = 0; j < transactionCount; j++) {
            if (transactions[j].artwork == _artworkAddress) {
                c++;
            }
        }
        address[] memory artwork = new address[](c);
        uint256[] memory eth = new uint256[](c);
        uint256[] memory share = new uint256[](c);
        uint256[] memory buyId = new uint256[](c);
        uint256[] memory sellId = new uint256[](c);
        address[] memory buyer = new address[](c);
        address[] memory seller = new address[](c);
        c = 0;
        for (uint8 j = 0; j < transactionCount; j++) {
            if (transactions[j].artwork == _artworkAddress) {
                artwork[c] = transactions[j].artwork;
                eth[c] = transactions[j].eth;
                share[c] = transactions[j].share;
                buyId[c] = transactions[j].buyId;
                sellId[c] = transactions[j].sellId;
                buyer[c] = transactions[j].buyer;
                seller[c] = transactions[j].seller;
                c++;
            }
        }
        return (eth, share, buyId, sellId, buyer, seller);
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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