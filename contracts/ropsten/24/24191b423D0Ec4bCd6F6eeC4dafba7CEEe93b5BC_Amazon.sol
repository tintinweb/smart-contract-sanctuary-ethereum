// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Authorized.sol";

contract Amazon is Authorized {
    mapping(string => uint256) public itemsInStoke;

    struct CartItem {
        string itemName;
        uint256 Quantity;
        bool inStoke;
        bool isGift;
    }
    address[] public UsersWhoPushItemsToCart;

    mapping(address => CartItem[]) public CartItemsOfOwner;

    struct order {
        string itemName;
        uint256 Quantity;
        string addressTo;
        string message;
        bool isGift;
    }
    address[] public UsersWhoRequested;

    mapping(address => order[]) public UsersOrders;

    function addItemsToStoke(
        string[] memory _itemsName,
        uint256[] memory _ItemsPrice
    ) public onlyStaff {
        for (uint256 i = 0; i < _itemsName.length; i++) {
            itemsInStoke[_itemsName[i]] = _ItemsPrice[i];
        }
    }

    function removeItemsFromStoke(string[] memory _itemName) public onlyStaff {
        for (uint256 i = 0; i < _itemName.length; i++) {
            delete itemsInStoke[_itemName[i]];
        }
    }

    //  check if item Already in owner Cart
    function chakeIfItemInUserCart(
        address _owner,
        string memory _itemName,
        bool _isGift
    ) private view returns (uint256 _indexOfItem) {
        for (uint256 i = 0; i < CartItemsOfOwner[_owner].length; i++) {
            if (
                keccak256(
                    abi.encodePacked(CartItemsOfOwner[_owner][i].itemName)
                ) ==
                keccak256(abi.encodePacked(_itemName)) &&
                CartItemsOfOwner[_owner][i].isGift == _isGift
            ) {
                _indexOfItem = i + 1;
            }
        }
        return _indexOfItem;
    }

    // check Cart Items of owner is it empty
    function checkCartItemsIsItEmpty(address _owner)
        private
        view
        returns (bool _isCartImpty)
    {
        uint256 itemsLength;

        for (uint256 i = 0; i < CartItemsOfOwner[_owner].length; i++) {
            if (CartItemsOfOwner[_owner][i].Quantity > 0) {
                itemsLength++;
            }
        }
        if (itemsLength == 0) {
            _isCartImpty = true;
        }
        return _isCartImpty;
    }

    function addItemsToCart(
        string memory _itemName,
        uint256 _Quantity,
        bool _isGift
    ) public {
        if (checkCartItemsIsItEmpty(msg.sender)) {
            UsersWhoPushItemsToCart.push(msg.sender);
        }

        bool _inStoke;
        if (itemsInStoke[_itemName] > 0) {
            _inStoke = true;
        }

        uint256 indexOfItem = chakeIfItemInUserCart(
            msg.sender,
            _itemName,
            _isGift
        );
        if (indexOfItem > 0) {
            CartItemsOfOwner[msg.sender][indexOfItem - 1].Quantity =
                CartItemsOfOwner[msg.sender][indexOfItem - 1].Quantity +
                _Quantity;
        } else {
            CartItemsOfOwner[msg.sender].push(
                CartItem(_itemName, _Quantity, _inStoke, _isGift)
            );
        }
    }

    function removeItemFromCart(string memory _itemName, bool _isGift) public {
        require(CartItemsOfOwner[msg.sender].length > 0);
        uint256 _indexOfItem = chakeIfItemInUserCart(
            msg.sender,
            _itemName,
            _isGift
        );
        if (_indexOfItem > 0) {
            delete CartItemsOfOwner[msg.sender][_indexOfItem - 1];
        }
        if (checkCartItemsIsItEmpty(msg.sender)) {
            for (uint256 i = 0; i < UsersWhoPushItemsToCart.length; i++) {
                if (UsersWhoPushItemsToCart[i] == msg.sender) {
                    delete UsersWhoPushItemsToCart[i];
                }
            }
        }
    }

    function changeQuantity(
        string memory _itemName,
        uint256 _Quantity,
        bool _isGift
    ) public {
        require(CartItemsOfOwner[msg.sender].length > 0);
        require(_Quantity > 0);
        uint256 _indexOfItem = chakeIfItemInUserCart(
            msg.sender,
            _itemName,
            _isGift
        );

        if (_indexOfItem > 0) {
            require(
                CartItemsOfOwner[msg.sender][_indexOfItem - 1].Quantity !=
                    _Quantity
            );
            CartItemsOfOwner[msg.sender][_indexOfItem - 1].Quantity = _Quantity;
        }
    }

    function setGift(string memory _itemName, bool _isGift) public {
        require(CartItemsOfOwner[msg.sender].length > 0);
        bool _itemisGift = !_isGift;
        uint256 _indexOfProduct = chakeIfItemInUserCart(
            msg.sender,
            _itemName,
            _itemisGift
        );
        uint256 _indexOfOppositeProduct = chakeIfItemInUserCart(
            msg.sender,
            _itemName,
            _isGift
        );

        if (_indexOfProduct > 0 && _indexOfOppositeProduct > 0) {
            CartItemsOfOwner[msg.sender][_indexOfOppositeProduct - 1].Quantity =
                CartItemsOfOwner[msg.sender][_indexOfOppositeProduct - 1]
                    .Quantity +
                CartItemsOfOwner[msg.sender][_indexOfProduct - 1].Quantity;

            delete CartItemsOfOwner[msg.sender][_indexOfProduct - 1];
        } else if (_indexOfProduct > 0 && _indexOfOppositeProduct == 0) {
            CartItemsOfOwner[msg.sender][_indexOfProduct - 1].isGift = _isGift;
        }
    }

    function getCartItemsOfOwner(address _userAddress)
        public
        view
        returns (CartItem[] memory _CartItemsOfOwner)
    {
        if (!checkCartItemsIsItEmpty(_userAddress)) {
            _CartItemsOfOwner = CartItemsOfOwner[_userAddress];
        }
        return _CartItemsOfOwner;
    }

    function isUsersHasOrders(address _user)
        public
        view
        returns (bool _UsersHasOrders)
    {
        for (uint256 i = 0; i < UsersWhoRequested.length; i++) {
            if (UsersWhoRequested[i] == _user) {
                _UsersHasOrders = true;
            }
        }
        return _UsersHasOrders;
    }

    function getUsersOrders(address _userAddress)
        public
        view
        returns (order[] memory _orders)
    {
        if (isUsersHasOrders(_userAddress)) {
            _orders = UsersOrders[_userAddress];
        }
        return _orders;
    }

    function buyItem(
        string memory _itemName,
        string memory _DeliveryAddress,
        string memory _message,
        uint256 _Quantity,
        bool isGeft
    ) public payable {
        require(itemsInStoke[_itemName] > 0);
        require(msg.value >= (itemsInStoke[_itemName] * _Quantity));

        UsersOrders[msg.sender].push(
            order(_itemName, _Quantity, _DeliveryAddress, _message, isGeft)
        );
        UsersWhoRequested.push(msg.sender);
    }

    function buyItems(
        string[] memory _itemsName,
        string[] memory _DeliveryAddress,
        string[] memory _messages,
        uint256[] memory _Quantitys,
        bool[] memory _isGeft
    ) public payable {
        uint256 _itemsInStoke;
        uint256 _totalAmounts;
        for (uint256 i = 0; i < _itemsName.length; i++) {
            _totalAmounts =
                _totalAmounts +
                itemsInStoke[_itemsName[i]] *
                _Quantitys[i];

            if (itemsInStoke[_itemsName[i]] > 0) {
                _itemsInStoke++;
            }
        }

        require(_itemsInStoke == _itemsName.length);
        require(msg.value >= _totalAmounts);

        for (uint256 j = 0; j < _itemsName.length; j++) {
            UsersOrders[msg.sender].push(
                order(
                    _itemsName[j],
                    _Quantitys[j],
                    _DeliveryAddress[j],
                    _messages[j],
                    _isGeft[j]
                )
            );
        }
        UsersWhoRequested.push(msg.sender);
    }

    // check Users Orders of adderss is it empty
    function checkUsersOrders(address _user) private {
        uint256 _UsersOrders;
        for (uint256 i = 0; i < UsersOrders[_user].length; i++) {
            if (UsersOrders[_user][i].Quantity != 0) {
                _UsersOrders++;
            }
        }
        if (_UsersOrders == 0) {
            for (uint256 i = 0; i < UsersWhoRequested.length; i++) {
                if (UsersWhoRequested[i] == _user) {
                    delete UsersWhoRequested[i];
                }
            }
        }
    }

    // The request has been sent successfully

    function requestSent(address _address, string memory _itemName)
        public
        onlyStaff
    {
        for (uint256 i = 0; i < UsersOrders[_address].length; i++) {
            if (
                keccak256(
                    abi.encodePacked(UsersOrders[_address][i].itemName)
                ) == keccak256(abi.encodePacked(_itemName))
            ) {
                delete UsersOrders[_address][i];
                checkUsersOrders(_address);
            }
        }
    }

    function getProfits() public onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Authorized {
    address public admin;
    uint256 public price;

    mapping(address => bool) public staff;

    constructor() {
        admin = msg.sender;
        staff[msg.sender] = true;
        price = 50000000000000;  // 50000000000000 BNB or ETH to Wei = 1 USD , This is only an assumption
    }

    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "This function is restricted to the contract's admin"
        );
        _;
    }

    modifier onlyStaff() {
        require(
            staff[msg.sender],
            "This function is restricted to the contract's Staff"
        );
        _;
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
        staff[_newAdmin] = true;
    }

    function addStaff(address[] calldata _newStaff) public onlyAdmin {
        for (uint256 i = 0; i < _newStaff.length; i++) {
            staff[_newStaff[i]] = true;
        }
    }

    function removeStaff(address _Staff) public onlyAdmin {
        delete staff[_Staff];
    }



}