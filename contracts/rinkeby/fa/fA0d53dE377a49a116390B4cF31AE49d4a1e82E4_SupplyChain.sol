// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.9.0;

import "./Structure.sol";

contract SupplyChain {
    event ManufacturerAdded(address indexed _account);

    // asset id will be tracked
    uint256 public aid;
    uint256 sku;
    uint256 public assetPrice;
    // owner will be tracked
    address owner;

    mapping(uint256 => Structure.Asset) assets;
    mapping(uint256 => Structure.AssetHistory) assetHistory;
    mapping(address => Structure.Roles) roles;

    function hasManufacturerRole(address _account) public view returns (bool) {
        require(_account != address(0));
        return roles[_account].Manufacturer;
    }

    function addManufacturerRole(address _account) public {
        require(_account != address(0));
        require(!hasManufacturerRole(_account));

        roles[_account].Manufacturer = true;
    }

    function hasThirdPartyRole(address _account) public view returns (bool) {
        require(_account != address(0));
        return roles[_account].ThirdParty;
    }

    function addThirdPartyRole(address _account) public {
        require(_account != address(0));
        require(!hasThirdPartyRole(_account));

        roles[_account].ThirdParty = true;
    }

    function hasDeliveryServiceRole(address _account)
        public
        view
        returns (bool)
    {
        require(_account != address(0));
        return roles[_account].DeliveryService;
    }

    function addDeliveryServiceRole(address _account) public {
        require(_account != address(0));
        require(!hasDeliveryServiceRole(_account));

        roles[_account].DeliveryService = true;
    }

    function hasCustomerRole(address _account) public view returns (bool) {
        require(_account != address(0));
        return roles[_account].Customer;
    }

    function addCustomerRole(address _account) public {
        require(_account != address(0));
        require(!hasDeliveryServiceRole(_account));

        roles[_account].Customer = true;
    }

    constructor() public payable {
        owner = msg.sender;
        sku = 1;
        aid = 1;
    }

    event Manufactured(uint256 aid);
    event PurchasedByThirdParty(uint256 aid);
    event ShippedByManufacturer(uint256 aid);
    event ReceivedByThirdParty(uint256 aid);
    event PurchasedByCustomer(uint256 aid);
    event ShippedByThirdParty(uint256 aid);
    event ReceivedByDeliveryService(uint256 aid);
    event ShippedByDeliveryService(uint256 aid);
    event ReceivedByCustomer(uint256 aid);

    modifier verifyAddress(address add) {
        require(msg.sender == add);
        _;
    }

    modifier manufactured(uint256 _aid) {
        require(assets[_aid].assetState == Structure.State.Manufactured);
        _;
    }

    modifier shippedByManufacturer(uint256 _aid) {
        require(
            assets[_aid].assetState == Structure.State.ShippedByManufacturer
        );
        _;
    }

    modifier receivedByThirdParty(uint256 _aid) {
        require(
            assets[_aid].assetState == Structure.State.ReceivedByThirdParty
        );
        _;
    }

    modifier purchasedByCustomer(uint256 _aid) {
        require(assets[_aid].assetState == Structure.State.PurchasedByCustomer);
        _;
    }

    modifier shippedByThirdParty(uint256 _aid) {
        require(assets[_aid].assetState == Structure.State.ShippedByThirdParty);
        _;
    }

    modifier receivedByDeliveryService(uint256 _aid) {
        require(
            assets[_aid].assetState == Structure.State.ReceivedByDeliveryService
        );
        _;
    }

    modifier shippedByDeliveryService(uint256 _aid) {
        require(
            assets[_aid].assetState == Structure.State.ShippedByDeliveryService
        );
        _;
    }

    modifier receivedByCustomer(uint256 _aid) {
        require(assets[_aid].assetState == Structure.State.ReceivedByCustomer);
        _;
    }

    function manufactureEmptyInitialize(Structure.Asset memory asset)
        internal
        pure
    {
        address thirdParty;
        bytes32 transaction;
        string memory thirdPartyLongitude;
        string memory thirdPartyLatitude;

        address deliveryService;
        string memory deliveryServiceLongitude;
        string memory deliveryServiceLatitude;

        address customer;

        asset.thirdparty.thirdParty = thirdParty;
        asset.thirdparty.thirdPartyLongitude = thirdPartyLongitude;
        asset.thirdparty.thirdPartyLatitude = thirdPartyLatitude;

        asset.deliveryservice.deliveryService = deliveryService;
        asset
            .deliveryservice
            .deliveryServiceLongitude = deliveryServiceLongitude;
        asset.deliveryservice.deliveryServiceLatitude = deliveryServiceLatitude;

        asset.customer.customer = customer;
        asset.transaction = transaction;
    }

    function manufactureAssetInitialize(
        Structure.Asset memory asset,
        string memory assetId
    ) internal pure {
        asset.assetdet.assetId = assetId;
    }

    /**
     * @dev STEP 1 : Manufactured a asset and validated the asset by interal employee or exteral entity.
     */
    function manufactureAsset(
        string memory manufacturerLongitude,
        string memory manufacturerLatitude,
        string memory assetId,
        bytes32 validatorCredential
    ) public {
        require(hasManufacturerRole(msg.sender));
        uint256 _aid = aid;
        Structure.Asset memory asset;
        asset.sku = sku;
        asset.aid = _aid;

        asset.manufacturer.manufacturerLongitude = manufacturerLongitude;
        asset.manufacturer.manufacturerLatitude = manufacturerLatitude;
        asset.manufacturer.manufacturedDate = block.timestamp;

        asset.owner = msg.sender;
        asset.validator.validatorCredential = validatorCredential;
        asset.manufacturer.manufacturer = msg.sender;
        manufactureEmptyInitialize(asset);

        asset.assetState = Structure.State.Manufactured;

        manufactureAssetInitialize(asset, assetId);

        assets[_aid] = asset;

        assetHistory[_aid].history.push(asset);

        sku++;
        aid = aid + 1;

        emit Manufactured(_aid);
    }

    // function validateAsset(bytes32 validatorCredential) public {

    //
    // }

    /**
     * @dev STEP 2 : Purchase of manufactured asset by Third Party.
     */
    function purchaseByThirdParty(uint256 _aid) public manufactured(_aid) {
        require(hasThirdPartyRole(msg.sender));

        assets[_aid].thirdparty.thirdParty = msg.sender;
        assets[_aid].assetState = Structure.State.PurchasedByThirdParty;
        assetHistory[_aid].history.push(assets[_aid]);

        emit PurchasedByThirdParty(_aid);
    }

    /**
     * @dev STEP 3 : Shipping of purchased asset to Third Party.
     */
    function shipToThirdParty(uint256 _aid)
        public
        verifyAddress(assets[_aid].manufacturer.manufacturer)
    {
        require(hasManufacturerRole(msg.sender));
        assets[_aid].assetState = Structure.State.ShippedByManufacturer;
        assetHistory[_aid].history.push(assets[_aid]);

        emit ShippedByManufacturer(_aid);
    }

    /**
     * @dev STEP 4 : Received the purchased asset shipped by Manufacturer.
     */
    function receiveByThirdParty(
        uint256 _aid,
        string memory thirdPartyLongitude,
        string memory thirdPartyLatitude
    )
        public
        shippedByManufacturer(_aid)
        verifyAddress(assets[_aid].thirdparty.thirdParty)
    {
        require(hasThirdPartyRole(msg.sender));
        assets[_aid].owner = msg.sender;
        assets[_aid].thirdparty.thirdPartyLongitude = thirdPartyLongitude;
        assets[_aid].thirdparty.thirdPartyLatitude = thirdPartyLatitude;
        assets[_aid].thirdparty.thirdPartyDate = block.timestamp;

        assets[_aid].assetState = Structure.State.ReceivedByThirdParty;
        assetHistory[_aid].history.push(assets[_aid]);

        emit ReceivedByThirdParty(_aid);
    }

    /**
     * @dev STEP 5 : Purchase of a asset at third party by Customer.
     */
    function purchaseByCustomer(uint256 _aid)
        public
        receivedByThirdParty(_aid)
    {
        require(hasCustomerRole(msg.sender));

        assets[_aid].customer.customer = msg.sender;
        assets[_aid].assetState = Structure.State.PurchasedByCustomer;
        assetHistory[_aid].history.push(assets[_aid]);

        emit PurchasedByCustomer(_aid);
    }

    ///@dev STEP 7 : Shipping of asset by third party purchased by customer.
    function shipByThirdParty(uint256 _aid)
        public
        verifyAddress(assets[_aid].owner)
        verifyAddress(assets[_aid].thirdparty.thirdParty)
    {
        require(hasThirdPartyRole(msg.sender));
        assets[_aid].assetState = Structure.State.ShippedByThirdParty;
        assetHistory[_aid].history.push(assets[_aid]);

        emit ShippedByThirdParty(_aid);
    }

    ///@dev STEP 8 : Receiveing of asset by delivery service purchased by customer. eg: "9.994371633400082","76.31791103906511"
    function receiveByDeliveryService(
        uint256 _aid,
        string memory deliveryServiceLongitude,
        string memory deliveryServiceLatitude
    ) public shippedByThirdParty(_aid) {
        require(hasDeliveryServiceRole(msg.sender));
        assets[_aid].owner = msg.sender;
        assets[_aid].deliveryservice.deliveryService = msg.sender;
        assets[_aid]
            .deliveryservice
            .deliveryServiceLongitude = deliveryServiceLongitude;
        assets[_aid]
            .deliveryservice
            .deliveryServiceLatitude = deliveryServiceLatitude;
        assets[_aid].deliveryservice.deliveryServiceDate = block.timestamp;

        assets[_aid].assetState = Structure.State.ReceivedByDeliveryService;
        assetHistory[_aid].history.push(assets[_aid]);

        emit ReceivedByDeliveryService(_aid);
    }

    ///@dev STEP 9 : Shipping of asset by delivery service purchased by customer.
    function shipByDeliveryService(uint256 _aid)
        public
        receivedByDeliveryService(_aid)
        verifyAddress(assets[_aid].owner)
        verifyAddress(assets[_aid].deliveryservice.deliveryService)
    {
        require(hasDeliveryServiceRole(msg.sender));
        assets[_aid].assetState = Structure.State.ShippedByDeliveryService;
        assetHistory[_aid].history.push(assets[_aid]);

        emit ShippedByDeliveryService(_aid);
    }

    ///@dev STEP 10 : Shipping of asset by delivery service purchased by customer.
    function receiveByCustomer(
        uint256 _aid,
        string memory customerLongitude,
        string memory customerLatitude
    )
        public
        shippedByDeliveryService(_aid)
        verifyAddress(assets[_aid].customer.customer)
    {
        require(hasCustomerRole(msg.sender));
        assets[_aid].owner = msg.sender;
        assets[_aid].customer.customer = msg.sender;
        assets[_aid].customer.customerLongitude = customerLongitude;
        assets[_aid].customer.customerLatitude = customerLatitude;
        assets[_aid].customer.customerDate = block.timestamp;

        assets[_aid].assetState = Structure.State.ReceivedByCustomer;
        assetHistory[_aid].history.push(assets[_aid]);

        emit ReceivedByCustomer(_aid);
    }

    ///@dev Fetch asset
    function fetchAssetPart1(
        uint256 _aid,
        string memory _type,
        uint256 i
    )
        public
        view
        returns (
            uint256,
            address,
            address,
            string memory,
            string memory,
            uint256
        )
    {
        require(assets[_aid].aid != 0);
        Structure.Asset storage asset = assets[_aid];
        if (keccak256(bytes(_type)) == keccak256(bytes("asset"))) {
            asset = assets[_aid];
        }
        if (keccak256(bytes(_type)) == keccak256(bytes("history"))) {
            asset = assetHistory[_aid].history[i];
        }
        return (
            asset.aid,
            asset.owner,
            asset.manufacturer.manufacturer,
            asset.manufacturer.manufacturerLongitude,
            asset.manufacturer.manufacturerLatitude,
            asset.manufacturer.manufacturedDate
        );
    }

    ///@dev Fetch asset
    function fetchAssetPart2(
        uint256 _aid,
        string memory _type,
        uint256 i
    ) public view returns (string memory, Structure.State) {
        require(assets[_aid].aid != 0);
        Structure.Asset storage asset = assets[_aid];
        if (keccak256(bytes(_type)) == keccak256(bytes("asset"))) {
            asset = assets[_aid];
        }
        if (keccak256(bytes(_type)) == keccak256(bytes("history"))) {
            asset = assetHistory[_aid].history[i];
        }
        return (asset.assetdet.assetId, asset.assetState);
    }

    function fetchAssetPart3(
        uint256 _aid,
        bytes memory _type,
        uint256 i
    )
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256,
            address,
            string memory,
            string memory,
            uint256
        )
    {
        require(assets[_aid].aid != 0);
        Structure.Asset storage asset = assets[_aid];
        if (keccak256(bytes(_type)) == keccak256(bytes("asset"))) {
            asset = assets[_aid];
        }
        if (keccak256(bytes(_type)) == keccak256(bytes("history"))) {
            asset = assetHistory[_aid].history[i];
        }
        return (
            asset.thirdparty.thirdParty,
            asset.thirdparty.thirdPartyLongitude,
            asset.thirdparty.thirdPartyLatitude,
            asset.thirdparty.thirdPartyDate,
            asset.deliveryservice.deliveryService,
            asset.deliveryservice.deliveryServiceLongitude,
            asset.deliveryservice.deliveryServiceLatitude,
            asset.deliveryservice.deliveryServiceDate
        );
    }

    function fetchAssetPart4(
        uint256 _aid,
        bytes memory _type,
        uint256 i
    )
        public
        view
        returns (
            address,
            string memory,
            string memory,
            uint256,
            bytes32
        )
    {
        require(assets[_aid].aid != 0);
        Structure.Asset storage asset = assets[_aid];
        if (keccak256(bytes(_type)) == keccak256(bytes("asset"))) {
            asset = assets[_aid];
        }
        if (keccak256(bytes(_type)) == keccak256(bytes("history"))) {
            asset = assetHistory[_aid].history[i];
        }
        return (
            asset.customer.customer,
            asset.customer.customerLongitude,
            asset.customer.customerLatitude,
            asset.customer.customerDate,
            asset.transaction
        );
    }

    function fetchAssetCount() public view returns (uint256) {
        return aid;
    }

    function fetchAssetHistoryLength(uint256 _aid)
        public
        view
        returns (uint256)
    {
        return assetHistory[_aid].history.length;
    }

    function fetchAssetState(uint256 _aid)
        public
        view
        returns (Structure.State)
    {
        return assets[_aid].assetState;
    }

    function setTransactionHashOnManufacture(bytes32 tran) public {
        assetHistory[aid - 1]
            .history[assetHistory[aid - 1].history.length - 1]
            .transaction = tran;
    }

    function setTransactionHash(uint256 _aid, bytes32 tran) public {
        Structure.Asset storage p = assetHistory[_aid].history[
            assetHistory[_aid].history.length - 1
        ];
        p.transaction = tran;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 <0.9.0;

library Structure {
    enum State {
        Manufactured,
        PurchasedByThirdParty,
        ShippedByManufacturer,
        ReceivedByThirdParty,
        PurchasedByCustomer,
        ShippedByThirdParty,
        ReceivedByDeliveryService,
        ShippedByDeliveryService,
        ReceivedByCustomer
    }

    struct ManufactureDetails {
        address manufacturer;
        string manufacturerLongitude;
        string manufacturerLatitude;
        uint256 manufacturedDate;
    }

    struct ThirdPartyDetails {
        address thirdParty;
        string thirdPartyLongitude;
        string thirdPartyLatitude;
        uint256 thirdPartyDate;
    }

    struct DeliveryServiceDetails {
        address deliveryService;
        string deliveryServiceLongitude;
        string deliveryServiceLatitude;
        uint256 deliveryServiceDate;
    }

    struct validatorDetails {
        bytes32 validatorCredential;
    }

    struct CustomerDetails {
        address customer;
        string customerLongitude;
        string customerLatitude;
        uint256 customerDate;
    }

    struct AssetDetails {
        string assetId;
    }

    struct Asset {
        uint256 aid;
        uint256 sku;
        address owner;
        State assetState;
        validatorDetails validator;
        ManufactureDetails manufacturer;
        ThirdPartyDetails thirdparty;
        AssetDetails assetdet;
        DeliveryServiceDetails deliveryservice;
        CustomerDetails customer;
        bytes32 transaction;
    }

    struct AssetHistory {
        Asset[] history;
    }

    struct Roles {
        bool Manufacturer;
        bool ThirdParty;
        bool DeliveryService;
        bool Customer;
    }
}