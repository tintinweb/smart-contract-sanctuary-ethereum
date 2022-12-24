/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract Supplychain{

    address owner;
   
   constructor() {
      owner = msg.sender;
   }

enum roles{
    norole,
    supplier,
    manufacturer,
    distributor,
    retailer,
    revoke}

struct UserInfo{
    string name;
    string location;
    address ethAddress;
    roles role;
    }

mapping(address => UserInfo) private UsersDetails;
address[] users;

modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

/***********************************************Admin Section****************************************************/

event UserRegister(address indexed EthAddress, string Name);
event UserRoleRevoked(address indexed EthAddress, string Name, uint Role);
event UserRoleRessign(address indexed EthAddress, string Name, uint Role);

function registerUser(address EthAddress,string memory Name,string memory Location,uint Role) public onlyOwner{
        require(UsersDetails[EthAddress].role==roles.norole,"User Already registered");
        UsersDetails[EthAddress].name = Name;
        UsersDetails[EthAddress].location = Location;
        UsersDetails[EthAddress].ethAddress = EthAddress;
        UsersDetails[EthAddress].role = roles(Role);
        users.push(EthAddress);
        emit UserRegister(EthAddress, Name);}

function revokeRole(address userAddress) public onlyOwner {
        require(UsersDetails[userAddress].role!=roles.norole,"user not registered");
        emit UserRoleRevoked(userAddress, UsersDetails[userAddress].name, uint(UsersDetails[userAddress].role));
        UsersDetails[userAddress].role=roles(5);}

function reassignRole(address userAddress,uint Role) public onlyOwner {
          require(UsersDetails[userAddress].role != roles.norole, "User not registered");
        UsersDetails[userAddress].role = roles(Role);
        emit UserRoleRessign(userAddress, UsersDetails[userAddress].name,uint(UsersDetails[userAddress].role));
    }

/***********************************************User Section****************************************************/

function getUserInfo(address userAddress) public view returns(string memory,string memory,address,uint){
       return (
           UsersDetails[userAddress].name,
           UsersDetails[userAddress].location,
           UsersDetails[userAddress].ethAddress,
           uint(UsersDetails[userAddress].role)
       );
   }

/***********************************************Supplier****************************************************/


/***********************************************Chain addproduct****************************************************/

enum packageStatus{atCreator,delivered_to_Manufacturer,delivered_to_Distributor,delivered_to_retailer}
        packageStatus status;
uint product_id=0;

    struct Product{
        uint256 id;
        string name;
        string temp;
        string humidity;
        uint256 quantity;
        address manufacturing;
        address supplier;
        uint256 timestamp;
        }

        packageStatus constant defaultstatus = packageStatus.atCreator;

Product[] public products_list;
Product private productInfo;

mapping (uint256 => Product) private products;

    struct ProductatManufacturing{
        // uint256 product_id;
        string temp_m;
        string humidity_m;
        uint256 quantity_m;
        address distributor;
        uint256 timestamp;
        }

ProductatManufacturing[] public ProductatManufacturing_list;
ProductatManufacturing private ProductatManufacturingInfo;

mapping (uint256 => ProductatManufacturing) private ProductatManufacturings;
    
    
    struct ProductatDistributor{
        // uint256 product_id;
        string temp_d;
        string humidity_d;
        uint256 quantity_d;
        address retailer;
        uint256 timestamp;
        }

        // string tempd = temp_d;
        // string humidityd = humidity_d;
        // uint256 quantityd = quantity_d;
        // address retail = retailer;

ProductatDistributor[] public ProductatDistributor_list;
ProductatDistributor private ProductatDistributorInfo;

mapping (uint256 => ProductatDistributor) private ProductatDistributors;



event ShippmentUpdate(
        address indexed Manufacturer,
        address indexed supplier,
        uint TransporterTpye,
        uint Status
    );
event Create(address Supplier, string  _temp, string _humidity);

    function AddProduct(
        string memory _name,
        string memory _temp,
        string memory _humidity,
        uint256 _quantity,
        address _manufacturing,
        address _supplier) public payable {
        require(UsersDetails[msg.sender].role==roles(1),"Only supplier can call this function");
        productInfo=Product(product_id,_name,_temp,_humidity,_quantity,_manufacturing,_supplier,block.timestamp);
        products[product_id]=(productInfo);
        products_list.push(productInfo);
        product_id++;
        emit Create(msg.sender, _temp, _humidity); 
        }

    function delivered_to_Manufacturer(address) public {
        require(UsersDetails[msg.sender].role==roles(1),"Only supplier can call this function");
        require(status==packageStatus(0),"the package is no longer with the owner!");
        status=packageStatus(1);
        // emit ShippmentUpdate(address, 1, 1);
    }

    function AddProductforManufacturer(string memory _temp_m,string memory _humidity_m,uint256 _quantity_m,address _distributor) public payable {
        require(UsersDetails[msg.sender].role==roles(2),"Only Manufacturer can call this function");
        ProductatManufacturingInfo=ProductatManufacturing(_temp_m,_humidity_m,_quantity_m,_distributor,block.timestamp); /*Product ID */
        ProductatManufacturings[product_id]=(ProductatManufacturingInfo);
        ProductatManufacturing_list.push(ProductatManufacturingInfo);
    }


    function delivered_to_Distributor(address) public {
        require(UsersDetails[msg.sender].role==roles(2),"Only Manufacturer can call this function");
        require(status==packageStatus(1),"Package not shipped yet!");
        status=packageStatus(2);
        // emit ShippmentUpdate(address , shipper, manufacturer, 1, 2);
    }

    function AddProductforDistributor(string memory _temp_d,string memory _humidity_d,uint256 _quantity_d,address _retailer) public payable {
        require(UsersDetails[msg.sender].role==roles(3),"Only Distributor can call this function");
        ProductatDistributorInfo=ProductatDistributor(_temp_d,_humidity_d,_quantity_d,_retailer,block.timestamp); /*Product ID */
        ProductatDistributors[product_id]=(ProductatDistributorInfo);
        ProductatDistributor_list.push(ProductatDistributorInfo);
    }

    function delivered_to_retailer(address) public {
        require(UsersDetails[msg.sender].role==roles(3),"Only Distributor can call this function");
        require(status==packageStatus(2),"Package not shipped yet!");
        status=packageStatus(3);
        // emit ShippmentUpdate(address , shipper, manufacturer, 1, 3);
    }

    function getProductStatus(uint) public view returns(uint){
        return uint(status);}

    // function getProductatDistributorInfo() public view returns(string memory,string memory,uint256,address,uint256){
    //     return ProductatDistributor_list();}

}