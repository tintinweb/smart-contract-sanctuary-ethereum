/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract importblockt {
    // Event to emit when a Memo is created.
    event NewImport (
        uint256 importId,
        string receiverName,
        string importDate
    );
    event NewOrderImport (
        uint256 orderImportId,
        uint256 amount
    ); 
    event NewProduct (
        uint256 productId,
        string productName,
        string productType,
        string productDetail,
        string productUnit
    );
    event NewCategory (
        uint256 categoryId,
        string categoryName,
        string categoryDetail
    );
    event NewOwner (
        uint256 ownerId,
        string ownerName,
        string ownerPhone
    );
    event NewExport (
        uint256 exportId,
        string dateExport
    );
    event NewOrder (
        uint256 orderId
    );

    struct Import {
        uint256 importId;
        string receiverName;
        string importDate;
    }
    struct OrderImport {
        uint256 orderImportId;
        uint256 amount;
    }
    struct Product {
        uint256 productId;
        string productName;
        string productType;
        string productDetail;
        string productUnit;
    }

    struct Category {
        uint256 categoryId;
        string categoryName;
        string categoryDetail;
    }

    struct Owner {
        uint256 ownerId;
        string ownerName;
        string ownerPhone;
    }
    struct Export {
        uint256 exportId;
        string dateExport;
    }
    struct Order {
        uint256 orderId;
    }
    // struct All {
    //     uint256 allId;
    //     uint256 importId;
    //     string receiverName;
    //     string importDate;
    //     uint256 orderImportId;
    //     uint256 amount;
    //     uint256 productId;
    //     string productName;
    //     string productType;
    //     string productDetail;
    //     string productUnit;
    //     uint256 categoryId;
    //     string categoryName;
    //     string categoryDetail;
    //     uint256 ownerId;
    //     string ownerName;
    //     string ownerPhone;
    //     uint256 exportId;
    //     string dateExport;
    //     uint256 orderId;
    // }

    // List of all memos received from coffee purchases.
    // Import[] imports;
    // OrderImport[] orderImports;
    // Product[] products;
    // Category[] categorys;
    // Owner[] owners;
    // Export[] exports;
    // Order[] orders;
    
    Import imports;
    OrderImport orderImports;
    Product products;
    Category categorys;
    Owner owners;
    Export exports;
    Order orders;
    // All alls;
    /**
     * @dev fetches all stored memos
     */

    // //1
    // function getImports()public view returns (Import[] memory)
    // {
    //     return (imports);
    // }
   
    // function getImports(uint256 importId)public view returns (uint256, string memory receiverName, string memory importDate)
    // {
    //     return (ImId[importId].importId, ImId[importId].receiverName, ImId[importId].importDate);
    // }

    // //2
    // function getOrderImports()public view returns (OrderImport[] memory)
    // {
    //     return orderImports;
    // }
    // //3
    // function getProducts() public view returns (Product[] memory)
    // {
    //     return products;
    // }
    // //4
    // function getCategorys() public view returns (Category[] memory)
    // {
    //     return categorys;
    // }
    // //5
    // function getOwners() public view returns (Owner[] memory)
    // {
    //     return owners;
    // }
    // //6
    // function getExports() public view returns (Export[] memory) 
    // {
    //     return exports;
    // }
    // //7
    // function getOrders() public view returns (Order[] memory)
    // {
    //     return orders;
    // }

    //1
    // function addImport(
    //     uint256 _importId,
    //     string memory _receiverName,
    //     string memory _importDate
    // ) public payable {
    //     // Add the memo to storage!
    //     imports.push(Import(_importId, _receiverName, _importDate)
    //     );

    //     // Emit a NewMemo event with details about the memo.
    //     emit NewImport(_importId, _receiverName, _importDate);
    // }

    mapping(uint256 => Import) public ImId;
    mapping(uint256 => OrderImport) public OiId;
    mapping(uint256 => Product) public PrId;
    mapping(uint256 => Category) public CaId;
    mapping(uint256 => Owner) public OwId;
    mapping(uint256 => Export) public ExId;
    mapping(uint256 => Order) public OrId;
    // mapping(uint256 => All) public AlId;



    // //2
    // function addOrderImport(
    //     uint256 _orderImportId,
    //     uint256 _amount
    // ) public payable {
    //     // Add the memo to storage!
    //     orderImports.push(OrderImport(_orderImportId, _amount)
    //     );

    //     // Emit a NewMemo event with details about the memo.
    //     emit NewOrderImport(_orderImportId, _amount);
    // }
    // //3
    // function addProduct(
    //     uint256 _productId,
    //     string memory _productName,
    //     string memory _productType,
    //     string memory _productDetail,
    //     string memory _productUnit
    // ) public payable {
    //     // Add the memo to storage!
    //     products.push(Product(_productId, _productName, _productType, _productDetail, _productUnit));

    //     // Emit a NewMemo event with details about the memo.
    //     emit NewProduct(_productId, _productName, _productType, _productDetail, _productUnit);
    // }

    // //4
    // function addCategory(
    //     uint256 _categoryId,
    //     string memory _categoryName,
    //     string memory _categoryDetail
    // ) public payable {
    //     // Add the memo to storage!
    //     categorys.push(Category(_categoryId, _categoryName, _categoryDetail));

    //     // Emit a NewMemo event with details about the memo.
    //     emit NewCategory(_categoryId, _categoryName, _categoryDetail);
    // }

    // //5
    // function addOwner(
    //     uint256 _ownerId,
    //     string memory _ownerName,
    //     string memory _ownerPhone
    // ) public payable {
    //     // Add the memo to storage!
    //     owners.push(Owner(_ownerId, _ownerName, _ownerPhone));

    //     // Emit a NewMemo event with details about the memo.
    //     emit NewOwner(_ownerId, _ownerName, _ownerPhone);
    // }

    // //6
    // function addExport(
    //     uint256 _exportId,
    //     string memory _exportDate
    // ) public payable {
    //     // Add the memo to storage!
    //     exports.push(Export(_exportId, _exportDate));

    //     // Emit a NewMemo event with details about the memo.
    //     emit NewExport(_exportId, _exportDate);
    // }

    // //7
    // function addOrder(
    //     uint256 _orderId
    // ) public payable {
    //     // Add the memo to storage!
    //     orders.push(Order(_orderId));

    //     // Emit a NewMemo event with details about the memo.
    //     emit NewOrder(_orderId);
    // }

    //1
    function setIm(uint256 importId, string memory receiverName, string memory importDate) public {
      imports = Import(importId, receiverName, importDate);
      ImId[importId] = imports;
    }
    function getSpecificResultIm(uint256 importId) public view returns (uint256, string memory receiverName, string memory importDate) {
      return (ImId[importId].importId, ImId[importId].receiverName ,ImId[importId].importDate);
    }

    //2
    function setOi(uint256 orderImportId, uint256 amount) public {
      orderImports = OrderImport(orderImportId, amount);
      OiId[orderImportId] = orderImports;
    }
    function getSpecificResultOi(uint256 orderImportId) public view returns (uint256, uint256) {
      return (OiId[orderImportId].orderImportId, OiId[orderImportId].amount);
    }   

    //3
    function setPr(uint256 productId,
        string memory productName,
        string memory productType,
        string memory productDetail,
        string memory productUnit) public {
      products = Product(productId, productName, productType, productDetail, productUnit);
      PrId[productId] = products;
   }
    function getSpecificResultPr(uint256 productId) public view returns (uint256, string memory productName,
        string memory productType,
        string memory productDetail,
        string memory productUnit) {
      return (PrId[productId].productId, PrId[productId].productName ,PrId[productId].productType, PrId[productId].productDetail, PrId[productId].productUnit);
    }   

    //4
    function setCa(uint256 categoryId, string memory categoryName, string memory categoryDetail) public {
      categorys = Category(categoryId, categoryName, categoryDetail);
      CaId[categoryId] = categorys;
    }
    function getSpecificResultCa(uint256 categoryId) public view returns (uint256,
        string memory categoryName,
        string memory categoryDetail) {
      return (CaId[categoryId].categoryId, CaId[categoryId].categoryName ,CaId[categoryId].categoryDetail);
    }

    //5
    function setOw(uint256 ownerId,
        string memory ownerName,
        string memory ownerPhone) public {
      owners = Owner(ownerId, ownerName, ownerPhone);
      OwId[ownerId] = owners;
    }
   function getSpecificResultOw(uint256 ownerId) public view returns (uint256, string memory ownerName,
        string memory ownerPhone) {
      return (OwId[ownerId].ownerId, OwId[ownerId].ownerName, OwId[ownerId].ownerPhone);
   }   

    //6
    function setEx(uint256 exportId,string memory dateExport) public {
      exports = Export(exportId, dateExport);
      ExId[exportId] = exports;
    }
    function getSpecificResultEx(uint256 exportId) public view returns (uint256,string memory dateExport) {
      return (ExId[exportId].exportId, ExId[exportId].dateExport);
   }   

   //7
    function setOr(uint256 orderId) public {
      orders = Order(orderId);
      OrId[orderId] = orders;
    }
    function getSpecificResultOr(uint256 orderId) public view returns (uint256) {
      return (OrId[orderId].orderId);
    }   

    // //All
    // function getSpecificResultAl(uint256 allId) public view returns (uint256, string memory receiverName, string memory importDate, uint256, uint256) {
    //   return (AlId[allId].importId, AlId[allId].receiverName ,AlId[allId].importDate, AlId[allId].orderImportId, AlId[allId].amount);
    // }
   
}