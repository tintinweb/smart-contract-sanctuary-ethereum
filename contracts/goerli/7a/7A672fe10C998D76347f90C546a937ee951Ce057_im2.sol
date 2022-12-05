/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract im2 {
    // Event to emit when a Memo is created.
    event NewIm (
        uint256 imId,
        string imDate
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
        string exportDate
    );
    event NewOrderExport (
        uint256 orderExportId
    );

    struct Im {
        uint256 imId;
        string imDate;
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
        string exportDate;
    }
    struct OrderExport {
        uint256 orderExportId;
    }

    // List of all memos received from coffee purchases.
    Im[] ims;
    OrderImport[] orderImports;
    Product[] products;
    Category[] categorys;
    Owner[] owners;
    Export[] exports;
    OrderExport[] orderExports;

    /**
     * @dev fetches all stored memos
     */

    //1
    function getIms()public view returns (Im[] memory)
    {
        return ims;
    }
    //2
    function getOrderImports()public view returns (OrderImport[] memory)
    {
        return orderImports;
    }
    //3
    function getProducts() public view returns (Product[] memory)
    {
        return products;
    }
    //4
    function getCategorys() public view returns (Category[] memory)
    {
        return categorys;
    }
    //5
    function getOwners() public view returns (Owner[] memory)
    {
        return owners;
    }
    //6
    function getExports() public view returns (Export[] memory) 
    {
        return exports;
    }
    //7
    function getOrderExports() public view returns (OrderExport[] memory)
    {
        return orderExports;
    }

    //1
    function addIm(
        uint256 _imId,
        string memory _imDate
    ) public payable {
        // Add the memo to storage!
        ims.push(Im(_imId, _imDate)
        );

        // Emit a NewMemo event with details about the memo.
        emit NewIm(_imId, _imDate);
    }
    //2
    function addOrderImport(
        uint256 _orderImportId,
        uint256 _amount
    ) public payable {
        // Add the memo to storage!
        orderImports.push(OrderImport(_orderImportId, _amount)
        );

        // Emit a NewMemo event with details about the memo.
        emit NewOrderImport(_orderImportId, _amount);
    }
    //3
    function addProduct(
        uint256 _productId,
        string memory _productName,
        string memory _productType,
        string memory _productDetail,
        string memory _productUnit
    ) public payable {
        // Add the memo to storage!
        products.push(Product(_productId, _productName, _productType, _productDetail, _productUnit));

        // Emit a NewMemo event with details about the memo.
        emit NewProduct(_productId, _productName, _productType, _productDetail, _productUnit);
    }

    //4
    function addCategory(
        uint256 _categoryId,
        string memory _categoryName,
        string memory _categoryDetail
    ) public payable {
        // Add the memo to storage!
        categorys.push(Category(_categoryId, _categoryName, _categoryDetail));

        // Emit a NewMemo event with details about the memo.
        emit NewCategory(_categoryId, _categoryName, _categoryDetail);
    }

    //5
    function addOwner(
        uint256 _ownerId,
        string memory _ownerName,
        string memory _ownerPhone
    ) public payable {
        // Add the memo to storage!
        owners.push(Owner(_ownerId, _ownerName, _ownerPhone));

        // Emit a NewMemo event with details about the memo.
        emit NewOwner(_ownerId, _ownerName, _ownerPhone);
    }

    //6
    function addExport(
        uint256 _exportId,
        string memory _exportDate
    ) public payable {
        // Add the memo to storage!
        exports.push(Export(_exportId, _exportDate));

        // Emit a NewMemo event with details about the memo.
        emit NewExport(_exportId, _exportDate);
    }

    //7
    function addOrderExport(
        uint256 _orderExportId
    ) public payable {
        // Add the memo to storage!
        orderExports.push(OrderExport(_orderExportId));

        // Emit a NewMemo event with details about the memo.
        emit NewOrderExport(_orderExportId);
    }

}