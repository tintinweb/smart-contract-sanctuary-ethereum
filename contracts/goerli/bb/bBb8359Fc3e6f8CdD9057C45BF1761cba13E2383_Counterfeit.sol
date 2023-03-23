pragma solidity ^0.8.0;

interface KYCVerification {
    function verify(bytes32 _kycDocumentHash) external view returns (bool);
}

contract Counterfeit {
    struct Product {
        string name;
        string description;
        bytes32 imageHash;
        mapping(uint256 => uint256) quantities;
        uint256 numQuantities;
    }

    struct Company {
        address owner;
        string name;
        string description;
        bytes32 kycDocumentHash;
        mapping(uint256 => Product) products;
        uint256 numProducts;
    }

    mapping(uint256 => Company) public companies;
    mapping(bytes32 => bytes) private images;
    uint256 public numberOfCompanies;
    KYCVerification private kycVerification;

    constructor(KYCVerification _kycVerification) {
        kycVerification = _kycVerification;
    }

    function createCompany(address _owner, string memory _name, string memory _description, bytes32 _kycDocumentHash) public returns(uint256) {
        require(kycVerification.verify(_kycDocumentHash), "KYC document hash is not valid.");
        Company storage company = companies[numberOfCompanies];
        company.owner = _owner;
        company.name = _name;
        company.description = _description;
        company.kycDocumentHash = _kycDocumentHash;
        numberOfCompanies++;
        return numberOfCompanies-1;
    }

    function addProduct(uint256 _id, string memory _name, string memory _description, bytes memory _imageData, uint256[] memory _quantityIds, uint256[] memory _quantities) public returns (bytes32) {
        Company storage company = companies[_id];
        require(company.owner == msg.sender, "Only the owner of the company can add products.");
        require(_quantityIds.length == _quantities.length, "Quantity ids and amounts must have the same length.");

        bytes32 imageHash = keccak256(_imageData);
        images[imageHash] = _imageData;

        Product storage product = company.products[company.numProducts];
        product.name = _name;
        product.description = _description;
        product.imageHash = imageHash;
        for (uint256 i = 0; i < _quantityIds.length; i++) {
            product.quantities[_quantityIds[i]] = _quantities[i];
        }
        product.numQuantities = _quantityIds.length;
        company.numProducts++;

        return imageHash;
    }

    function addQuantity(uint256 _companyId, uint256 _productId, uint256 _quantityId, uint256 _amount) public {
        Company storage company = companies[_companyId];
        require(company.owner == msg.sender, "Only the owner of the company can add quantities.");

        Product storage product = company.products[_productId];
        product.quantities[_quantityId] += _amount;
        if (product.quantities[_quantityId] == _amount) {
            product.numQuantities++;
        }
    }

    function getProductImages(uint256 _companyId) public view returns (bytes[] memory) {
        Company storage company = companies[_companyId];
        bytes[] memory result = new bytes[](company.numProducts);
        for (uint256 i = 0; i < company.numProducts; i++) {
            result[i] = images[company.products[i].imageHash];
        }
        return result;
    }
}