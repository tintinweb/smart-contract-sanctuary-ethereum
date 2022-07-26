// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Authorized.sol";

contract Amazon is Authorized {
    mapping(string => uint256) public itemsInStoke;

    struct CartItem {
        string itemName;
        uint256 Quantity;
        bool inStoke;
        bool isGeft;
    }
    address[] public UsersWhoPushItemsToCart;

    mapping(address => CartItem[]) public CartItemsOfOwner;

    struct order {
        string itemName;
        uint256 Quantity;
        string addressTo;
        string message;
        bool isGeft;
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

    function removeItemFromStoke(string memory _itemName) public onlyStaff {
        delete itemsInStoke[_itemName];
    }

    function addItemsToCart(
        string memory _itemName,
        uint256 _Quantity,
        bool _isGeft
    ) public {
        bool _inStoke;
        if (itemsInStoke[_itemName] > 0) {
            _inStoke = true;
        }

        CartItemsOfOwner[msg.sender].push(
            CartItem(_itemName, _Quantity, _inStoke, _isGeft)
        );
        UsersWhoPushItemsToCart.push(msg.sender);
    }

    // check Cart Items of adderss is it empty
    function checkCartItems(address _user) private {
        uint256 itemsLength;
        for (uint256 i = 0; i < CartItemsOfOwner[_user].length; i++) {
            if (CartItemsOfOwner[_user][i].Quantity != 0) {
                itemsLength++;
            }
        }
        if (itemsLength == 0) {
            for (uint256 i = 0; i < UsersWhoPushItemsToCart.length; i++) {
                if (UsersWhoPushItemsToCart[i] == _user) {
                    delete UsersWhoPushItemsToCart[i];
                }
            }
        }
    }

    function removetemsFromCart(string memory _itemName) public {
        require(CartItemsOfOwner[msg.sender].length > 0);
        for (uint256 i = 0; i < CartItemsOfOwner[msg.sender].length; i++) {
            if (
                keccak256(
                    abi.encodePacked(CartItemsOfOwner[msg.sender][i].itemName)
                ) == keccak256(abi.encodePacked(_itemName))
            ) {
                delete CartItemsOfOwner[msg.sender][i];
                checkCartItems(msg.sender);
            }
        }
    }

    function changeQuantity(string memory _itemName, uint256 _Quantity) public {
        require(CartItemsOfOwner[msg.sender].length > 0);
        require(_Quantity > 0);

        for (uint256 i = 0; i < CartItemsOfOwner[msg.sender].length; i++) {
            if (
                keccak256(
                    abi.encodePacked(CartItemsOfOwner[msg.sender][i].itemName)
                ) ==
                keccak256(abi.encodePacked(_itemName)) ||
                CartItemsOfOwner[msg.sender][i].Quantity != _Quantity
            ) {
                CartItemsOfOwner[msg.sender][i].Quantity = _Quantity;
            }
        }
    }

    function setGift(string memory _itemName, bool _isGeft) public {
        require(CartItemsOfOwner[msg.sender].length > 0);

        for (uint256 i = 0; i < CartItemsOfOwner[msg.sender].length; i++) {
            if (
                keccak256(
                    abi.encodePacked(CartItemsOfOwner[msg.sender][i].itemName)
                ) ==
                keccak256(abi.encodePacked(_itemName)) ||
                CartItemsOfOwner[msg.sender][i].isGeft != _isGeft
            ) {
                CartItemsOfOwner[msg.sender][i].isGeft = _isGeft;
            }
        }
    }

  function isUsersHasItemsInCart(address _user)
        public
        view
        returns (bool _hasItemsInCart)
    {
        for (uint256 i = 0; i < UsersWhoPushItemsToCart.length; i++) {
            if (UsersWhoPushItemsToCart[i] == _user) {
                _hasItemsInCart = true;
            }
        }
        return _hasItemsInCart;
    }

    function getCartItemsOfOwner(address _userAddress)
        public
        view
        returns (CartItem[] memory _CartItemsOfOwner )
    {
      if(isUsersHasItemsInCart(_userAddress)){
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
      if(isUsersHasOrders(_userAddress)){
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