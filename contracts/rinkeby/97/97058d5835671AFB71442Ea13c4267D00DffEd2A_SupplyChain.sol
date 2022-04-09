// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "EntityChain.sol";

contract SupplyChain {

    enum Status {
        MANUFACTURED,
        DELIVERING_RECEIVED,
        DELIVERING_DISTRIBUTED,
        DELIVERING_STORAGE,
        STORAGE_RECEIVED,
        STORAGE_DISTRIBUTED,
        PRODUCT_SOLD
    }

    struct Product {
        uint256 id;
        string product_type;
        string product_type_description;
        string description;
        uint256 entity;
        uint status;
        string image_url;
        string price;
        bool isExist;
    }

    Product[] products;
    uint256 lastProdId;

    event AddProductEvent(
            string id, 
            string product_type,
            string product_type_description, 
            string description,
            uint256 entity, 
            uint status, 
            string image_url,
            string price, 
            bool isExist
    );

    event SetProductOwnerEvent(
            uint256 product_id, 
            uint256 entity_old_id,
            uint256 entity_new_id,
            string product_type,
            uint status, 
            string price
    );

    event SetProductStatusEvent(
            uint256 product_id, 
            uint status_old_id,
            uint status_new_id
    );


    constructor() {
        lastProdId = 0;
    }


    function addProduct(string memory _product_type, 
                        string memory _product_type_description, 
                        string memory _description, 
                        uint256 _entity, 
                        uint _status, 
                        string memory _image_url, 
                        string memory _price) public 
        returns (
            string memory _lastProdId
        ) {
        // get new id for product
        string memory _uid_str = uint2str(lastProdId++);


        // set new product
        Product memory product = Product(lastProdId, _product_type, _product_type_description, _description,  _entity, _status, _image_url, _price, true);
        products.push(product);


        // update general info
        emit AddProductEvent(_uid_str, _product_type, _product_type_description, _description, _entity, _status, _image_url, _price, true);

        return _uid_str;
    }

    function getProduct(uint256 _id) public view 
        returns (
            string memory __id, 
            string memory _product_type, 
            string memory _product_type_description, 
            string memory _description, 
            uint256 _entity, 
            string memory _status, 
            string memory _image_url, 
            string memory _price
        ) {
        //verify if product exists
        require(products[_id].isExist, "Product not found !");

        Product memory product = products[_id];

        return (uint2str(product.id), product.product_type, product.product_type_description, product.description, product.entity, getStatusName(product.status), product.image_url, product.price);
    }

    function getProductTotal() public view
        returns ( 
            uint256 total_products 
        ) {
        return (products.length);
    }

    function getStatus(string memory _status) public pure returns(uint) {
        if (keccak256(bytes(_status)) == keccak256(bytes("MANUFACTURED"))) return 0;
        if (keccak256(bytes(_status)) == keccak256(bytes("DELIVERING_RECEIVED"))) return 1;
        if (keccak256(bytes(_status)) == keccak256(bytes("DELIVERING_DISTRIBUTED"))) return 2;
        if (keccak256(bytes(_status)) == keccak256(bytes("DELIVERING_STORAGE"))) return 3;
        if (keccak256(bytes(_status)) == keccak256(bytes("STORAGE_RECEIVED"))) return 4;
        if (keccak256(bytes(_status)) == keccak256(bytes("STORAGE_DISTRIBUTED"))) return 5;
        if (keccak256(bytes(_status)) == keccak256(bytes("PRODUCT_SOLD"))) return 6;
    }

    function getStatusName(uint _status) public pure 
        returns (
            string memory status
        ) {
        if (_status == 0) return "MANUFACTURED";
        if (_status == 1) return "DELIVERING_RECEIVED";
        if (_status == 2) return "DELIVERING_DISTRIBUTED";
        if (_status == 3) return "DELIVERING_STORAGE";
        if (_status == 4) return "STORAGE_RECEIVED";
        if (_status == 5) return "STORAGE_DISTRIBUTED";
        if (_status == 6) return "PRODUCT_SOLD";
    }

    function setProductOwner(uint256 product_id, uint256 _entity_id) public 
        returns(
            bool product_changed
        ) {
        //verify if product exists
        require(products[product_id].isExist, "Product not found !");    

        // get the old entity
        uint256 old_entity = products[product_id].entity;

        // change product owner
        products[product_id].entity = _entity_id;

        // emit change event
        emit SetProductOwnerEvent(
            product_id, 
            old_entity,
            _entity_id,
            products[product_id].product_type,
            products[product_id].status, 
            products[product_id].price
        );
        return true; 
    }

    function setProductStatus(uint256 product_id, uint _status) public 
        returns(
            bool product_status_changed
        ) {

        //verify if product exists
        require(products[product_id].isExist, "Product not found !");    

        // get the old status
        uint256 old_status = products[product_id].status;

        // change product owner
        products[product_id].status = _status;

        // emit change event
        emit SetProductStatusEvent(
            product_id, 
            old_status,
            _status
        );

        return true; 
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EntityChain {

    enum Role {
        PRODUCER,
        DISTRIBUTOR,
        STORAGE,
        CONSUMER
    }

    struct Entity {
        string id;
        string name;
        uint role;  
        bool exists;
    }

    mapping(string => uint256) public entityByName; 
    Entity[] public entities;
    uint256 public totalEntities;

    event AddEntityEvent(string entityId, uint role);

    function addEntity(string memory _name, uint _role) public returns (uint256 total) {
        // verify if name is empty
        require(keccak256(bytes(_name)) != "", "Name cannot be empty");

        // get new id for the entity
        string memory _ent = uint2str(totalEntities++);

        // create new entity
        Entity memory entity = Entity(_ent, _name, _role, true);

        // add to entities array
        entities.push(entity);

        // add entry to name's array
        entityByName[_name] = totalEntities;

        // emit event add
        emit AddEntityEvent (entity.id, _role);

        return totalEntities;
    }

    function getTotalEntities() public view returns (uint256 length){
        return entities.length;
    }

    function getEntityString(string memory _name) public view 
        returns (
            string memory id,
            string memory name,
            string memory role
        ) {
        require(entityByName[_name] > 0, "Entity not found on array !");

        Entity memory entity = entities[(entityByName[_name]-1)];

        role = getRole(entity.role);
        return (entity.id, entity.name, role);
    }

    function getEntityInt(uint256 _id) public view 
        returns (
            string memory id,
            string memory name,
            string memory role
        ) {
        require(entities[(_id - 1)].exists, "Entity not found on array !");

        Entity memory entity = entities[(_id - 1)];

        role = getRole(entity.role);
        return (entity.id, entity.name, role);
    }


    function getRole(string memory _role) public pure returns(uint role) {
        if (keccak256(bytes(_role)) == keccak256(bytes("PRODUCER"))) return 0;
        if (keccak256(bytes(_role)) == keccak256(bytes("DISTRIBUTOR"))) return 1;
        if (keccak256(bytes(_role)) == keccak256(bytes("STORAGE"))) return 2;
        if (keccak256(bytes(_role)) == keccak256(bytes("CONSUMER"))) return 3;
    }

    function getRole(uint role) public pure returns (string memory _role) {
        if (role == 0) return "PRODUCER";
        if (role == 1) return "DISTRIBUTOR";
        if (role == 2) return "STORAGE";
        if (role == 3) return "CONSUMER";
    }


    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }


}