pragma solidity ^0.8.16;

contract PLM {
    event CompanyAdded(
        uint indexed id,
        string name,
        address indexed owner
    );
    event ProductAdded(
        uint indexed id,
        string name,
        string imageHash,
        string description,
        uint indexed companyId,
        uint indexed productCategoryId
    );
    event ProductUpdated(
        uint indexed id,
        string name,
        string imageHash,
        string description,
        uint indexed productCategoryId
    );
    event ProductLifecycleUpdated(
        uint indexed id,
        uint currentStage,
        string record,
        string docHash,
        address indexed user
    );
    event ProductCategoryAdded(
        uint indexed id,
        string name,
        string description,
        string[] stages,
        address[] stagesAssignees,
        uint indexed companyId
    );
    event ProductCategoryUpdated(
        uint indexed id,
        string name,
        string description,
        string[] stages,
        address[] stagesAssignees
    );

    struct Company {
        address owner;
        string name;
    }

    struct ProductCategory {
        string name;
        string description;
        string[] stages;
        address[] stagesAssignees;
    }

    struct Product {
        string name;
        string imageHash;
        string description;
        uint currentStage;
        string[] lifecycleRecords;
        string[] lifecycleDocsHashes;
        uint productCategoryId;
    }

    mapping(uint => Company) public companies;
    uint256 private companiesCounter = 0;

    mapping(uint => ProductCategory) public productCategories;
    mapping(uint => uint) public productCategoriesToCompany;
    uint256 private productCategoriesCounter = 0;

    mapping(uint => Product) public products;
    mapping(uint => uint) public productsToCompany;
    uint256 private productsCounter = 0;

    function createCompany(string memory name) public {
        require(bytes(name).length > 0, "Category name is required");

        Company storage company = companies[++companiesCounter];
        company.owner = msg.sender;
        company.name = name;

        emit CompanyAdded(companiesCounter, name, msg.sender);
    }

    function createProductCategory(uint companyId, string memory name, string memory description, string[] memory stages, address[] memory stagesAssignees) public {
        require(companies[companyId].owner == msg.sender, "Only company owner is allowed to perform this action");
        require(bytes(name).length > 0, "Category name is required");

        ProductCategory storage productCategory = productCategories[++productCategoriesCounter];
        productCategory.name = name;
        productCategory.stages = stages;
        productCategory.stagesAssignees = stagesAssignees;

        productCategoriesToCompany[productCategoriesCounter] = companyId;

        emit ProductCategoryAdded(productCategoriesCounter, name, description, stages, stagesAssignees, companyId);
    }

    function updateProductCategory(uint id, string memory name, string memory description, string[] memory stages, address[] memory stagesAssignees) public {
        require(companies[productCategoriesToCompany[id]].owner == msg.sender, "Only company owner is allowed to perform this action");
        require(bytes(productCategories[id].name).length > 0, "Invalid product category");

        ProductCategory storage productCategory = productCategories[id];
        productCategory.name = name;
        productCategory.description = description;
        productCategory.stages = stages;
        productCategory.stagesAssignees = stagesAssignees;

        emit ProductCategoryUpdated(id, name, description, stages, stagesAssignees);
    }

    function createProduct(uint companyId, uint productCategoryId, string memory name, string memory imageHash, string memory description) public {
        require(companies[companyId].owner == msg.sender, "Only company owner is allowed to perform this action");
        require(bytes(productCategories[productCategoryId].name).length > 0, "Invalid product category");
        require(productCategoriesToCompany[productCategoryId] == companyId, "Company id does not match");
        require(productCategories[productCategoryId].stages.length > 0, "Product category should have at least 1 stage");

        Product storage product = products[++productsCounter];
        product.name = name;
        product.description = description;
        product.imageHash = imageHash;
        product.productCategoryId = productCategoryId;
        product.currentStage = 0;

        productsToCompany[productsCounter] = companyId;

        emit ProductAdded(productsCounter, name, imageHash, description, companyId, productCategoryId);
    }

    function updateProduct(uint id, uint productCategoryId, string memory name, string memory imageHash, string memory description) public {
        require(companies[productsToCompany[id]].owner == msg.sender, "Only company owner is allowed to perform this action");
        require(bytes(productCategories[id].name).length > 0, "Invalid product category");
        require(productCategoriesToCompany[productCategoryId] == productsToCompany[id], "Company id does not match");
        require(productCategories[productCategoryId].stages.length > 0, "Product category should have at least 1 stage");

        Product storage product = products[id];
        product.name = name;
        product.imageHash = imageHash;
        product.description = description;
        if (productCategoryId != product.productCategoryId) {
            product.productCategoryId = productCategoryId;
            product.currentStage = 0;
        }

        emit ProductUpdated(id, name, imageHash, description, productCategoryId);
    }

    function processToNextStage(uint id, string memory record, string memory docHash) public {
        Product storage product = products[id];
        require(bytes(product.name).length > 0, "Invalid product");
        require(productCategories[product.productCategoryId].stagesAssignees[product.currentStage] == msg.sender, "Only user assigned to current stage is allowed to perform this action");
        require(product.currentStage < productCategories[product.productCategoryId].stages.length, "Product is already at the final stage");

        product.lifecycleRecords.push(record);
        product.lifecycleDocsHashes.push(docHash);
        product.currentStage++;

        emit ProductLifecycleUpdated(id, product.currentStage, record, docHash, msg.sender);
    }
}