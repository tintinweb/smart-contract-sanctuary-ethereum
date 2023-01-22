// SPDX-License-Identifier: MIT

/**
 *  @authors: [@ljrahn]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity 0.8.13;


contract IchnaeaCore {

    uint8 immutable maxSupplyChainLength = 20;

    struct InstanceVerifierDetails {
        uint64 timeStamp;
        bool signedOff;
    }
    
    struct ProductVerifierDetails {
        string companyName;
        string location;
        string travelMethod;
        address signer;
    }

    struct Product {
        string productName;
        string productWeight; // kg
        string ipfsDocumentUrl;
    }

    // mapping for translating an id of an instance of a product to a product id
    mapping(bytes32 => uint32) public instanceIdToProductId;

    // product ID counter to keep track of product id
    uint32 public productIdCounter;

    // a product as defined by the Product struct
    mapping(uint32 => Product) public productIdToProduct;

    // definition for a supply chain route
    mapping(uint32 => ProductVerifierDetails[]) public productIdToProductVerifierSupplyChain; 

    // actual status of where a product instance is in the supply chain 
    mapping(bytes32 => InstanceVerifierDetails[]) public instanceIdToInstanceVerifierSupplyChain;

    event UpdateInstance(bytes32 indexed instanceId, uint32 indexed productId, uint64[] timeStamp, bool[] signedOff);
    event ProductCreated(uint32 indexed productId, string indexed productName, string productWeight, string ipfsDocumentUrl, string[] companyName, string[] location, string[] travelMethod, address[] signer);

    function createProduct(Product memory _product, ProductVerifierDetails[] memory _supplyChainRoute) public {
        require(_supplyChainRoute.length <= maxSupplyChainLength, "provided supplyChainRoute length is too long. length must be less than or equal to 20");
        require(_supplyChainRoute.length >= 1, "provided supplyChainRoute is too short. length must be greater than or equal to 1.");
        
        productIdToProduct[productIdCounter] = _product;
        string[] memory _companyName = new string[](_supplyChainRoute.length);
        string[] memory _location = new string[](_supplyChainRoute.length);
        string[] memory _travelMethod = new string[](_supplyChainRoute.length); 
        address[] memory _signer = new address[](_supplyChainRoute.length);

        for (uint8 i = 0; i < _supplyChainRoute.length; i++) {
            productIdToProductVerifierSupplyChain[productIdCounter].push(_supplyChainRoute[i]);
            _companyName[i] = _supplyChainRoute[i].companyName;
            _location[i] = _supplyChainRoute[i].location;
            _travelMethod[i] = _supplyChainRoute[i].travelMethod;
            _signer[i] = _supplyChainRoute[i].signer;
        }

        emit ProductCreated({
            productId: productIdCounter,
            productName: _product.productName,
            productWeight: _product.productWeight,
            ipfsDocumentUrl: _product.ipfsDocumentUrl,
            companyName: _companyName,
            location: _location,
            travelMethod: _travelMethod,
            signer: _signer
        });

        productIdCounter++;
    } 

    function instantiateProductInstance(bytes32 _instanceId, uint32 _productId) public {
        ProductVerifierDetails[] memory _supplyChainRoute = productIdToProductVerifierSupplyChain[_productId];

        require(_productId >= 0 && _productId < productIdCounter, "productId does not exist.");
        require(instanceIdToInstanceVerifierSupplyChain[_instanceId].length == 0, "instanceId already exists");
        require(_supplyChainRoute[0].signer == msg.sender, "incorrect signer for instantiating a product instance");

        instanceIdToProductId[_instanceId] = _productId;

        uint64[] memory _timeStamp = new uint64[](_supplyChainRoute.length);
        bool[] memory _signedOff = new bool[](_supplyChainRoute.length);

        for (uint8 i = 0; i < _supplyChainRoute.length; i++) {
            if (i == 0) {
                instanceIdToInstanceVerifierSupplyChain[_instanceId].push(InstanceVerifierDetails({
                    signedOff: true,
                    timeStamp: uint64(block.timestamp)
                }));
                _signedOff[i] = true;
                _timeStamp[i] = uint64(block.timestamp);
            } else {
                instanceIdToInstanceVerifierSupplyChain[_instanceId].push(InstanceVerifierDetails({
                    signedOff: false,
                    timeStamp: 0
                })); 
                _signedOff[i] = false;
                _timeStamp[i] = 0;
            }
        }

        emit UpdateInstance({
            instanceId: _instanceId,
            productId: _productId,
            signedOff: _signedOff,
            timeStamp: _timeStamp
        });
    }

    function verifyInstance(bytes32 _instanceId) public {
        uint32 _productId = instanceIdToProductId[_instanceId];
        require(instanceIdToInstanceVerifierSupplyChain[_instanceId].length > 0, "instance has not yet been instantiated");

        ProductVerifierDetails[] memory _supplyChainRoute = productIdToProductVerifierSupplyChain[_productId];

        uint64[] memory _timeStamp = new uint64[](_supplyChainRoute.length);
        bool[] memory _signedOff = new bool[](_supplyChainRoute.length);

        for (uint8 i = 0; i < _supplyChainRoute.length; i++) {
            if (instanceIdToInstanceVerifierSupplyChain[_instanceId][i].signedOff == false) {
                require(_supplyChainRoute[i].signer == msg.sender, "invalid signer");
                instanceIdToInstanceVerifierSupplyChain[_instanceId][i].signedOff = true;
                instanceIdToInstanceVerifierSupplyChain[_instanceId][i].timeStamp = uint64(block.timestamp);

                _signedOff[i] = true;
                _timeStamp[i] = uint64(block.timestamp);
                break;
            } else if (instanceIdToInstanceVerifierSupplyChain[_instanceId][i].signedOff == true && i == _supplyChainRoute.length - 1) {
                revert("product has already gone through complete supply chain");
            } else {
                _signedOff[i] = true;
                _timeStamp[i] = uint64(block.timestamp);
            }
        }

        emit UpdateInstance({
            instanceId: _instanceId,
            productId: _productId,
            signedOff: _signedOff,
            timeStamp: _timeStamp
        });
    }
}