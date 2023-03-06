// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */


contract SupplyChain {

    address public owner;
    struct Product {
        uint256 id;
        string productName;
        string description;
        uint256 price;
        string image;
        uint256 stock;
        uint256 manufacturerID;
        uint256 modelID;
        uint256 yearID;
    }

    struct Manufacturer {
        uint256 id;
        string manName;
        
    }

    struct Model {
        uint256 id;
        string modelName;
        uint256 manufacturerID;
    }

    struct YearOfCar {
        uint256 id;
        uint256 yearName;
        uint256 manufacturerID;
        uint256 modelID;
    }


    // Creating a hierachy of the product => Manufacturer => Models => Year

    mapping(uint256 => Product) public products;
    mapping(uint256 => Manufacturer) public manufacturers;
    mapping(uint256 => Model) public models;
    mapping(uint256 => YearOfCar) public yearsOfCars;

    // Mapping IDs to each other Manufacturer is considered to be the parent of all.

    mapping(uint256 => uint256) public productManufacturer;
    mapping(uint256 => uint256) public modelManufacturer;
    mapping(uint256 => uint256) public yearManufacturer;


    // Mapping IDs for the parent Model and child year.
    mapping(uint256 => uint256) public yearModel;

    // Assigning the IDs variables

    uint256 public nextProductID;
    uint256 public nextManufacturerID;
    uint256 public nextModelID;
    uint256 public nextYearID;



    struct Order {
        address manufacturer;
        uint256 productID;
        uint256 quantity;
        string deliveryAddress;
        uint256 date;
        string status;
    }


    
    constructor  () public{
        owner = msg.sender;

    }
    modifier restricted () {
        require(msg.sender == owner);
        _;
    }


    // Creating all the products

    function addProduct (string memory _productName, string memory _description, uint256  _price, string memory _image, uint256 _stock, uint256 _manufacturerID, uint256 _modelID, uint256 _yearID) public restricted {
        uint256 productID = nextProductID++;
        products[productID] = Product(productID, _productName, _description, _price, _image, _stock, _manufacturerID, _modelID, _yearID);
        productManufacturer[productID] = _manufacturerID;
    }
    function addManufacturer (string memory _name) public {
        uint256 manufacturerID = nextManufacturerID++;
        manufacturers[manufacturerID] = Manufacturer(manufacturerID, _name);
    }

    function addModel (string memory _modelName, uint256 _manufacturerID) public {
        uint256 modelID = nextModelID++;
        models[modelID] =  Model(modelID, _modelName, _manufacturerID);
        modelManufacturer[modelID] = _manufacturerID;

    }

    function addYear (uint256 _yearName, uint256 _manufacturerID, uint256 _modelID) public{
        uint256 yearID = nextYearID++;
        yearsOfCars[yearID] = YearOfCar(yearID, _yearName, _manufacturerID, _modelID);
    }

    // Removing all the products

    function removeProduct (uint256 index) public {
        require(products[index].id != 0, "Invalid product ID");
        delete products[index];
    }
    function removeManufacturer (uint256 index) public {
        require(manufacturers[index].id != 0, "Invalid manufacturer ID");
        delete manufacturers[index];
        for(uint256 i = 0; i < nextProductID; i++){
            if(productManufacturer[i] == index){
                delete products[i];
                delete productManufacturer[i];
            }
        }
        for(uint256 i = 0; i < nextModelID; i++) {
            if(modelManufacturer[i] == index){
                delete modelManufacturer[i];
                delete models[i];
            }
        }
        for(uint256 i = 0; i < nextYearID; i++) {
            if(yearManufacturer[i] == index){
                delete yearManufacturer[i];
                delete models[i];
            }
        }
    }
    function removeModel(uint256 index) public {
        require(models[index].id != 0, "Invalid model ID");
        delete models[index];
        for(uint256 i = 0; i < nextProductID; i++){
            if(products[i].modelID == index){
                delete products[i];
            }
        }
        for(uint256 i = 0; i < nextYearID; i++){
            if(yearModel[i] == index){
                delete yearModel[i];
            }

        }
    }

    // Showing the products 

    // function getProduct(uint256 index) public view returns (Product memory ){
    //     require(products[index].id != 0, "Invalid product id");
    //     return products[index];
    // } 


    // function getAllProducts () public view returns (Product[] memory){
    //     uint256 numberOfProducts = nextProductID - 1;
    //     Product[] memory result = new Product[](numberOfProducts);
    //     uint256 resultIndex = 0;
    //     for(uint256 i = 1; i <= numberOfProducts; i++){
    //         if(products[i].id != 0){
    //             result[resultIndex] = products[i];
    //             resultIndex++;
    //         }
    //     }
    //     return result;
    // }

    function getAllManufacturers() public view returns (Manufacturer[] memory) { 
        uint256 numberOfManufacturers = nextManufacturerID - 1; 
        Manufacturer[] memory result = new Manufacturer[](numberOfManufacturers); 
        uint256 resultIndex = 0; 
        for (uint256 i = 1; i <= numberOfManufacturers; i++) { 
            
                 result[resultIndex] = manufacturers[i]; resultIndex++; 
            } 
          return result; 
    }


    // function getAllModels () public view returns (Model[] memory){
    //     uint256 numberOfModels = nextModelID - 1;
    //     Model[] memory result = new Model[](numberOfModels);
    //     uint256 resultIndex = 0;
    //     for(uint256 i = 1; i <= numberOfModels; i++){
    //         if(models[i].id != 0){
    //             result[resultIndex] = models[i];
    //             resultIndex++;
    //         }
    //     }
    //     return result;
    // }

    // function getAllYears () public view returns (YearOfCar[] memory) {
    //     uint256 numberOfYears = nextYearID - 1;
    //     YearOfCar[] memory result = new YearOfCar[](numberOfYears);
    //     uint256 resultIndex = 0;
    //     for(uint256 i = 1; i <= numberOfYears; i++){
    //         if(yearsOfCars[i].id != 0){
    //             result[resultIndex] = yearsOfCars[i];
    //             resultIndex++;
    //         }
    //     }
    //     return result;
    // }
    // function removeYears(uint256 index) public {
    //     require(yearsOfCars[index].id != 0, "Invalid model ID");
    //     delete yearsOfCars[index];
    //     for(uint256 i = 0; i < nextProductID; i++){
    //         if(productManufacturer[i] == index){
    //             delete products[i];
    //             delete productManufacturer[i];
    //         }
    //     }
    //     for(uint256 i = 0; i < nextModelID; i++){
    //         if(manufacturerModel[i] == index)
    //     }
    // }


    // function createOrder(uint256 _id, uint256 _quantity, string memory _deliveryAddress, uint256 _date) public {
        
    //     Order memory newOrder = Order({
    //         manufacturer: msg.sender,
    //         productID: _id,
    //         quantity: _quantity,
    //         deliveryAddress: _deliveryAddress,
    //         date: _date 
    //     });

    //     orders.push(newOrder);
    // } 
    
}