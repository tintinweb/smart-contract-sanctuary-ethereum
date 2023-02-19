pragma solidity ^0.8.16;

contract PLM {
    event CompanyAdded(
        bytes32 indexed id,
        string name,
        address indexed owner
    );
    event ProductAdded(
        bytes32 indexed id,
        string name,
        string description,
        string imageHash,
        bytes32 indexed companyId,
        bytes32 indexed productCategoryId
    );
    event ProductUpdated(
        bytes32 indexed id,
        string name,
        string description,
        string imageHash,
        bytes32 indexed productCategoryId
    );
    event ProductLifecycleUpdated(
        bytes32 indexed productId,
        address user,
        string record,
        string docHash,
        uint currentStage
    );
    event ProductCategoryAdded(
        bytes32 indexed id,
        string name,
        string[] stages,
        address[] stagesAssignees,
        bytes32 indexed companyId
    );
    event ProductCategoryUpdated(
        bytes32 indexed id,
        string name,
        string[] stages,
        address[] stagesAssignees
    );

    struct Company {
        address owner;
        string name;
    }

    struct ProductCategory {
        string name;
        string[] stages;
        address[] stagesAssignees;
    }

    struct Product {
        string name;
        string description;
        string imageHash;
        uint currentStage;
        string[] lifecycleRecords;
        string[] lifecycleDocsHashes;
        bytes32 productCategoryId;
    }

    mapping(bytes32 => Company) public companies;
    uint256 private companiesCounter = 0;

    mapping(bytes32 => ProductCategory) public productCategories;
    mapping(bytes32 => bytes32) public productCategoriesToCompany;
    uint256 private productCategoriesCounter = 0;

    mapping(bytes32 => Product) public products;
    mapping(bytes32 => bytes32) public productsToCompany;
    uint256 private productsCounter = 0;

    function createCompany(string memory name) public {
        require(bytes(name).length > 0, "Category name is required");

        bytes32 id = hash("company", ++companiesCounter);
        Company storage company = companies[id];
        company.owner = msg.sender;
        company.name = name;

        emit CompanyAdded(id, name, msg.sender);
    }

    function createProductCategory(bytes32 companyId, string memory name, string[] memory stages, address[] memory stagesAssignees) public {
        require(companies[companyId].owner == msg.sender, "Only company owner is allowed to perform this action");
        require(bytes(name).length > 0, "Category name is required");

        bytes32 id = hash("productCategory", ++productCategoriesCounter);
        ProductCategory storage productCategory = productCategories[id];
        productCategory.name = name;
        productCategory.stages = stages;
        productCategory.stagesAssignees = stagesAssignees;

        productCategoriesToCompany[id] = companyId;

        emit ProductCategoryAdded(id, name, stages, stagesAssignees, companyId);
    }

    function updateProductCategory(bytes32 id, string memory name, string[] memory stages, address[] memory stagesAssignees) public {
        require(companies[productCategoriesToCompany[id]].owner == msg.sender, "Only company owner is allowed to perform this action");
        require(bytes(productCategories[id].name).length > 0, "Invalid product category");

        ProductCategory storage productCategory = productCategories[id];
        productCategory.name = name;
        productCategory.stages = stages;
        productCategory.stagesAssignees = stagesAssignees;

        emit ProductCategoryUpdated(id, name, stages, stagesAssignees);
    }

    function createProduct(bytes32 companyId, bytes32 productCategoryId, string memory name, string memory description, string memory imageHash) public {
        require(companies[companyId].owner == msg.sender, "Only company owner is allowed to perform this action");
        require(bytes(productCategories[productCategoryId].name).length > 0, "Invalid product category");
        require(productCategoriesToCompany[productCategoryId] == companyId, "Company id does not match");
        require(productCategories[productCategoryId].stages.length > 0, "Product category should have at least 1 stage");

        bytes32 id = hash("product", ++productsCounter);
        Product storage product = products[id];
        product.name = name;
        product.description = description;
        product.imageHash = imageHash;
        product.productCategoryId = productCategoryId;
        product.currentStage = 0;

        productsToCompany[id] = companyId;

        emit ProductAdded(id, name, description, imageHash, companyId, productCategoryId);
    }

    function updateProduct(bytes32 id, bytes32 productCategoryId, string memory name, string memory description, string memory imageHash) public {
        require(companies[productsToCompany[id]].owner == msg.sender, "Only company owner is allowed to perform this action");
        require(bytes(productCategories[id].name).length > 0, "Invalid product category");
        require(productCategoriesToCompany[productCategoryId] == productsToCompany[id], "Company id does not match");
        require(productCategories[productCategoryId].stages.length > 0, "Product category should have at least 1 stage");

        Product storage product = products[id];
        product.name = name;
        product.description = description;
        product.imageHash = imageHash;
        if (productCategoryId != product.productCategoryId) {
            product.productCategoryId = productCategoryId;
            product.currentStage = 0;
        }

        emit ProductUpdated(id, name, description, imageHash, productCategoryId);
    }

    function processToNextStage(bytes32 productId, string memory record, string memory docHash) public {
        Product storage product = products[productId];
        require(bytes(product.name).length > 0, "Invalid product");
        require(productCategories[product.productCategoryId].stagesAssignees[product.currentStage] == msg.sender, "Only user assigned to current stage is allowed to perform this action");
        require(product.currentStage < productCategories[product.productCategoryId].stages.length, "Product is already at the final stage");

        product.lifecycleRecords.push(record);
        product.lifecycleDocsHashes.push(docHash);
        product.currentStage++;

        emit ProductLifecycleUpdated(productId, msg.sender, record, docHash, product.currentStage);
    }

    function hash(string memory key, uint256 id) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(key, id));
    }
}