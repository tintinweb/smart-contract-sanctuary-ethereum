/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Import {
    // Event to emit when a Memo is created.
    event NewProduct(
        string productId,
        string nameProduct
    );

    event NewProductCategory(
        string productCategoryId,
        string nameCategory,
        string detail
    );

    event NewProductOwner(
        string productOwnerId,
        string nametOwner,
        string telno
    );

    event NewProductWithdraw(
        string productWithdrawId,
        string nameConsignee,
        string productWithdraw,
        string dateWithdraw,
        string productType,
        uint256 amountWithdraw,
        string unitWithdraw
    );

    event NewProductImport(
        string productImportId,
        string productImport,
        string dateImport,
        uint256 amountImport,
        string unitImport
    );

    struct Product {
        string productId;
        string nameProduct;
    }

    struct ProductCategory {
        string productCategoryId;
        string nameCategory;
        string detail;
    }

    struct ProductOwner {
        string productOwnerId;
        string nameOwner;
        string telno;
    }

    struct ProductWithdraw {
        string productWithdrawId;
        string nameConsignee;
        string productWithdraw;
        string dateWithdraw;
        string productType;
        uint256 amountWithdraw;
        string unitWithdraw;
    }

    struct ProductImport {
        string productImportId;
        string productImport;
        string dateImport;
        uint256 amountImport;
        string unitImport;
    }

    // List of all memos received from coffee purchases.
    Product[] products;
    ProductCategory[] productCategorys;
    ProductOwner[] productOwners;
    ProductWithdraw[] productWithdraws;
    ProductImport[] productImports;
    
    /**
     * @dev fetches all stored memos
     */

    function getProducts() public view returns (Product[] memory) 
    {
        return products;
    }

    function getProductCategorys() public view returns (ProductCategory[] memory)
    {
        return productCategorys;
    }

    function getProductOwners() public view returns (ProductOwner[] memory) 
    {
        return productOwners;
    }

    function getProductWithdraws()
        public
        view
        returns (ProductWithdraw[] memory)
    {
        return productWithdraws;
    }

    function getProductImports() public view returns (ProductImport[] memory) {
        return productImports;
    }


    //1
    function addProduct(
        string memory _productId,
        string memory _nameProduct
    ) public payable {
        // Add the memo to storage!
        products.push(Product(_productId, _nameProduct));

        // Emit a NewMemo event with details about the memo.
        emit NewProduct(_productId, _nameProduct);
    }

    //2
    function addProductCategory(
        string memory _productCategoryId,
        string memory _nameCategory,
        string memory _detail
    ) public payable {
        // Add the memo to storage!
        productCategorys.push(
            ProductCategory(_productCategoryId, _nameCategory, _detail)
        );

        // Emit a NewMemo event with details about the memo.
        emit NewProductCategory(_productCategoryId, _nameCategory, _detail);
    }

    //3
    function addProductOwner(
        string memory _productOwnerId,
        string memory _nameOwner,
        string memory _telno

    ) public payable {
        // Add the memo to storage!
        productOwners.push(ProductOwner(_productOwnerId, _nameOwner, _telno));

        // Emit a NewMemo event with details about the memo.
        emit NewProductOwner(_productOwnerId, _nameOwner, _telno);
    }

    //4
    function addProductWithdraw(
        string memory _productWithdrawId,
        string memory _nameConsignee,
        string memory _productWithdraw,
        string memory _date,
        string memory _productType,
        uint256 _amountWithdraw,
        string memory _unitWithdraw
    ) public payable {
        // Add the memo to storage!
        productWithdraws.push(
            ProductWithdraw(
                _productWithdrawId,
                _nameConsignee,
                _productWithdraw,
                _date,
                _productType,
                _amountWithdraw,
                _unitWithdraw
            )
        );

        // Emit a NewMemo event with details about the memo.
        emit NewProductWithdraw(
            _productWithdrawId,
            _nameConsignee,
            _productWithdraw,
            _date,
            _productType,
            _amountWithdraw,
            _unitWithdraw
        );
    }

    //5
    function addProductImport(
        string memory _productImportId,
        string memory _productImport,
        string memory _date,
        uint256 _amountImport,
        string memory _unitImport
    ) public payable {
        // Add the memo to storage!
        productImports.push(
            ProductImport(_productImportId, _productImport, _date, _amountImport, _unitImport)
        );

        // Emit a NewMemo event with details about the memo.
        emit NewProductImport(_productImportId, _productImport, _date, _amountImport, _unitImport);
    }
}