/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract BuyMeACoffee {
    // Event to emit when a Memo is created.
    event NewProduct(
        string productId,
        string name,
        uint256 amount,
        string unit
    );

    event NewProductCategory(
        string productCategoryId,
        string name,
        string Detail
    );

    event NewProductOwner(string productOwnerId, string name, string telno);

    event NewProductWithdraw(
        string productWithdrawId,
        string consigneeName,
        string productWithdraw,
        uint256 amount,
        string date,
        string productType
    );

    event NewProductImport(
        string productImportId,
        string productImport,
        uint256 amount,
        string date
    );

    struct Product {
        string productId;
        string name;
        uint256 amount;
        string unit;
    }

    struct ProductCategory {
        string productCategoryId;
        string name;
        string Detail;
    }

    struct ProductOwner {
        string productOwnerId;
        string name;
        string telno;
    }

    struct ProductWithdraw {
        string productWithdrawId;
        string consigneeName;
        string productWithdraw;
        uint256 amount;
        string date;
        string productType;
    }

    struct ProductImport {
        string productImportId;
        string productImport;
        uint256 amount;
        string date;
    }

    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
    address payable owner;

    // List of all memos received from coffee purchases.
    Product[] products;
    ProductCategory[] productCategorys;
    ProductOwner[] productOwners;
    ProductWithdraw[] productWithdraws;
    ProductImport[] productImports;

    constructor() {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        owner = payable(msg.sender);
    }

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

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _productId name of the coffee purchaser
     * @param _name name of the coffee purchaser
     * @param _amount name of the coffee purchaser
     * @param _unit name of the coffee purchaser
     */
    //1
    function addProduct(
        string memory _productId,
        string memory _name,
        uint256 _amount,
        string memory _unit

    ) public payable {
        // Add the memo to storage!
        products.push(Product(_productId, _name, _amount, _unit));

        // Emit a NewMemo event with details about the memo.
        emit NewProduct(_productId, _name, _amount, _unit);
    }

    //2
    function addProductCategory(
        string memory _productCategoryId,
        string memory _name,
        string memory _Detail
    ) public payable {
        // Add the memo to storage!
        productCategorys.push(
            ProductCategory(_productCategoryId, _name, _Detail)
        );

        // Emit a NewMemo event with details about the memo.
        emit NewProductCategory(_productCategoryId, _name, _Detail);
    }

    //3
    function addProductOwner(
        string memory _productOwnerId,
        string memory _name,
        string memory _telno

    ) public payable {
        // Add the memo to storage!
        productOwners.push(ProductOwner(_productOwnerId, _name, _telno));

        // Emit a NewMemo event with details about the memo.
        emit NewProductOwner(_productOwnerId, _name, _telno);
    }

    //4
    function addProductWithdraw(
        string memory _productWithdrawId,
        string memory _consigneeName,
        string memory _productWithdraw,
        uint256 _amount,
        string memory _date,
        string memory _productType
    ) public payable {
        // Add the memo to storage!
        productWithdraws.push(
            ProductWithdraw(
                _productWithdrawId,
                _consigneeName,
                _productWithdraw,
                _amount,
                _date,
                _productType
            )
        );

        // Emit a NewMemo event with details about the memo.
        emit NewProductWithdraw(
            _productWithdrawId,
            _consigneeName,
            _productWithdraw,
            _amount,
            _date,
            _productType
        );
    }

    //5
    function addProductImport(
        string memory _productImportId,
        string memory _productImport,
        uint256 _amount,
        string memory _date
    ) public payable {
        // Add the memo to storage!
        productImports.push(
            ProductImport(_productImportId, _productImport, _amount, _date)
        );

        // Emit a NewMemo event with details about the memo.
        emit NewProductImport(_productImportId, _productImport, _amount, _date);
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }
}