//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "./Products.sol";
import "./Sellers.sol";
import "./Buyers.sol";

contract Ecommerce is Products, Sellers, Buyers {
    function buyProduct(
        string[] memory _prodName,
        uint256[] memory _prodPrice,
        uint256[] memory _qnt,
        uint256[] memory _prodIds,
        uint256 _paymentId,
        string memory _orderStatus
    ) public payable onlyBuyer {
        uint256 totalAmt = 0;
        for (uint256 prod = 0; prod < _prodIds.length; prod++) {
            decreaseStock(_prodIds[prod], _qnt[prod]);
            uint256 amt = getPrice(_prodIds[prod]) * _qnt[prod];
            totalAmt += amt;
            address payable selleradd = getSellerAddress(_prodIds[prod]);
            addOrder(
                _prodIds[prod],
                _qnt[prod],
                amt,
                selleradd,
                _orderStatus,
                _paymentId
            );
        }
        require(msg.value >= totalAmt, "insufficient ethers for transaction");
    }

    function addProduct(
        string memory _name,
        uint256 _price,
        uint256 _stock,
        string memory _desc,
        string memory _category,
        string memory _imgHash
    ) public onlySeller {
        require(_stock > 0, "invalid stock qnt");
        require(_price > 0, "invalid price amt");

        productCount++;
        products.push(
            Product(
                productCount,
                _name,
                _price,
                _stock,
                _imgHash,
                _desc,
                _category,
                payable(msg.sender)
            )
        );
        SellerProductCount[msg.sender]++;
        emit ProductAdded(
            productCount,
            _name,
            _price,
            _stock,
            _imgHash,
            _desc,
            _category,
            payable(msg.sender)
        );
    }

    function confirmation(uint256 _oId) public payable {
        confirmOrder(_oId);
        uint256 amt = getPendingOrderAmt(_oId);
        uint256 weiAmt = amt * (10**18);
        address payable sellerAddress = getOrderSellerAddress(_oId);
        sellerAddress.transfer(weiAmt);
    }

    function getbBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function countSellerOrders() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < buyers.length; i++) {
            address buyer = buyers[i].buyerAddress;
            Order[] memory buyerOrderList = orderList[buyer];
            for (uint256 j = 0; j < buyerOrderList.length; j++) {
                if (buyerOrderList[j].sellerAddress == msg.sender) {
                    count++;
                }
            }
        }
        return count;
    }

    function getSellerOrders() public view returns (Order[] memory) {
        uint256 sellerOrdersCount = countSellerOrders();
        Order[] memory sellersOrders = new Order[](sellerOrdersCount);
        uint256 counter = 0;
        for (uint256 i = 0; i < buyers.length; i++) {
            address buyer = buyers[i].buyerAddress;
            Order[] memory buyerOrderList = orderList[buyer];
            for (uint256 j = 0; j < buyerOrderList.length; j++) {
                if (buyerOrderList[j].sellerAddress == msg.sender) {
                    sellersOrders[counter] = buyerOrderList[j];
                    counter++;
                    if (counter == sellerOrdersCount) {
                        break;
                    }
                }
            }
        }
        return sellersOrders;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Products {
    uint256 public productCount;

    struct Product {
        uint256 pid;
        string name;
        uint256 price;
        uint256 stock;
        string imgHash;
        string desc;
        string category;
        address payable sellerAddress;
    }

    Product[] public products;

    mapping(address => uint256) public SellerProductCount;

    event ProductAdded(
        uint256 pid,
        string name,
        uint256 price,
        uint256 stock,
        string imgHash,
        string desc,
        string category,
        address payable sellerAddress
    );

    function getProduct(uint256 _pid) public view returns (Product memory) {
        return products[_pid - 1];
    }

    function decreaseStock(uint256 _pid, uint256 qnt) public {
        products[_pid - 1].stock = products[_pid - 1].stock - qnt;
    }

    function getPrice(uint256 _pid) public view returns (uint256) {
        return products[_pid - 1].price;
    }

    function getName(uint256 _pid) public view returns (string memory) {
        return products[_pid - 1].name;
    }

    function getSellerAddress(uint256 _pid)
        public
        view
        returns (address payable)
    {
        return products[_pid - 1].sellerAddress;
    }

    function getSellerProducts() public view returns (Product[] memory) {
        uint256 counter = SellerProductCount[msg.sender];
        uint256 flag = 0;
        Product[] memory ans = new Product[](counter);
        for (uint256 i = 0; i < products.length; i++) {
            if (products[i].sellerAddress == msg.sender) {
                ans[flag] = products[i];
                flag++;
                if (counter == flag) {
                    break;
                }
            }
        }
        return ans;
    }

    function getAllProducts() public view returns (Product[] memory) {
        return products;
    }

    function countProductsByCat(string memory cate)
        private
        view
        returns (uint256)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < products.length; i++) {
            if (
                keccak256(bytes(products[i].category)) == keccak256(bytes(cate))
            ) {
                count++;
            }
        }
        return count;
    }

    function getProductsByCategory(string memory category)
        public
        view
        returns (Product[] memory)
    {
        uint256 noOfProds = countProductsByCat(category);
        uint256 counter = 0;
        Product[] memory prods = new Product[](noOfProds);
        for (uint256 i = 0; i < products.length; i++) {
            if (
                keccak256(bytes(products[i].category)) ==
                keccak256(bytes(category))
            ) {
                prods[counter] = products[i];
                counter++;
                if (counter == noOfProds) {
                    break;
                }
            }
        }
        return prods;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Sellers {
    struct Seller {
        string name;
        address payable sellerAddress;
    }

    Seller[] public sellers;

    event SellerAdded(string name, address payable sellerAddress);

    modifier onlyNewSeller() {
        require(!isOldSeller(), "Existing Seller");
        _;
    }

    modifier onlySeller() {
        require(isOldSeller());
        _;
    }

    function addSeller(string memory _name) public onlyNewSeller {
        sellers.push(Seller(_name, payable(msg.sender)));
        emit SellerAdded(_name, payable(msg.sender));
    }

    function isOldSeller() public view returns (bool) {
        for (uint256 i = 0; i < sellers.length; i++) {
            if (msg.sender == sellers[i].sellerAddress) return true;
        }
        return false;
    }

    function getSeller() public view returns (Seller memory) {
        for (uint256 i = 0; i < sellers.length; i++) {
            if (msg.sender == sellers[i].sellerAddress) return sellers[i];
        }
        Seller memory nullSeller = Seller("null", payable(address(0)));
        return nullSeller;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract Buyers {
    uint256 public orderId;

    struct Buyer {
        string name;
        string deliveryAdd;
        address payable buyerAddress;
    }

    struct Order {
        uint256 ordId;
        uint256 pid;
        uint256 qnt;
        uint256 amt;
        address payable sellerAddress;
        bool paymentStatus;
        string orderStatus;
        uint256 pmtId;
    }

    Buyer[] public buyers;

    mapping(address => Order[]) public orderList;

    event BuyerAdded(string name, string deliveryAdd, address buyerAddress);

    event ProductBought(
        uint256 oId,
        uint256 pid,
        uint256 qnt,
        uint256 amt,
        address buyerAddress
    );

    function _isOldBuyer() public view returns (bool) {
        for (uint256 i = 0; i < buyers.length; i++) {
            if (msg.sender == buyers[i].buyerAddress) return true;
        }
        return false;
    }

    modifier onlyNewBuyer() {
        require(!_isOldBuyer());
        _;
    }

    modifier onlyBuyer() {
        require(_isOldBuyer());
        _;
    }

    function addBuyer(string memory _name, string memory _deliveryAdd)
        public
        onlyNewBuyer
    {
        buyers.push(Buyer(_name, _deliveryAdd, payable(msg.sender)));
        emit BuyerAdded(_name, _deliveryAdd, msg.sender);
    }

    function getBuyerInfo() public view returns (Buyer memory) {
        for (uint256 i = 0; i < buyers.length; i++) {
            if (msg.sender == buyers[i].buyerAddress) {
                return buyers[i];
            }
        }
    }

    function addOrder(
        uint256 _pid,
        uint256 _qnt,
        uint256 _amt,
        address payable sellerAdd,
        string memory _orderStatus,
        uint256 _pmtId
    ) internal {
        orderId++;
        orderList[msg.sender].push(
            Order(
                orderId,
                _pid,
                _qnt,
                _amt,
                sellerAdd,
                false,
                _orderStatus,
                _pmtId
            )
        );
        emit ProductBought(orderId, _pid, _qnt, _amt, msg.sender);
    }

    function getBuyerOrders() public view returns (Order[] memory) {
        return orderList[msg.sender];
    }

    function getOrderById(uint256 _oId) public view returns (Order memory) {
        Order[] memory orders = orderList[msg.sender];
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].ordId == _oId) {
                return orders[i];
            }
        }
        Order memory nullOrder = Order(
            0,
            0,
            0,
            0,
            payable(address(0x0)),
            false,
            "",
            0
        );
        return nullOrder;
    }

    function confirmOrder(uint256 _oId) public {
        Order[] storage orders = orderList[msg.sender];
        for (uint256 i = 0; i < orders.length; i++) {
            if (orders[i].ordId == _oId) {
                orders[i].paymentStatus = true;
                break;
            }
        }
    }

    function getPendingOrderAmt(uint256 _oId) public view returns (uint256) {
        Order memory order = getOrderById(_oId);
        return order.amt;
    }

    function getOrderSellerAddress(uint256 _oId)
        public
        view
        returns (address payable)
    {
        Order memory order = getOrderById(_oId);
        return order.sellerAddress;
    }

    // function getSellerOrders() public view returns (Order[] memory) {
    //     uint256 orderCount = 0;
    //     for (uint256 i = 1; i <= buyerCount; i++) {
    //         Order[] memory orders = orderList[i];
    //         for (uint256 j = 0; j < orders.length; j++) {
    //             if (orders[j].sellerAddress == msg.sender) {
    //                 orderCount++;
    //             }
    //         }
    //     }
    //     Order[] memory sellerOrders = new Order[](orderCount);
    //     uint256 orderCounter = 0;
    //     for (uint256 i = 1; i <= buyerCount; i++) {
    //         Order[] memory orders = orderList[i];
    //         for (uint256 j = 0; j < orders.length; j++) {
    //             if (orders[j].sellerAddress == msg.sender) {
    //                 sellerOrders[orderCounter] = orders[j];
    //                 orderCounter++;
    //                 if (orderCounter == orderCount) {
    //                     break;
    //                 }
    //             }
    //         }
    //     }
    //     return sellerOrders;
    // }
}