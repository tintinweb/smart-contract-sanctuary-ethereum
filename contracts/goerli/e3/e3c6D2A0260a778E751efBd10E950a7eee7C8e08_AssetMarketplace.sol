/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

pragma solidity 0.8.4;

//Contract to create assets and buy stakes

contract AssetMarketplace {
    //Asset than any user  can create
    struct Asset {
        //name of the Asset used to refer to it, two different Assets cannot have the same name
        string name;
        //Price in smallest unit must be > 0
        uint256 price;
        //Number of buyable stakes is price - sum of stakes already bought
        uint256 nbBuyableStakes;
        //Address of user that created the asset
        address payable assetCreator;
        //Mapping of nb of stakes owned by any address
        mapping(address => uint256) stakesOwnedByInvestors;
        //Array of addresses that already bought stakes
        address[] allInvestors;
    }

    address private assetMarketplaceCreator;
    mapping(string => Asset) private createdAssets;
    string[] private allAssets;

    //When asset is created
    event AssetCreated(string name, uint256 price, address assetCreator);
    //When stake is bought
    event boughtStakeFromAsset(
        string name,
        uint256 quantity,
        address assetInvestor,
        uint256 nbBuyableStakes
    );

    constructor() {
        assetMarketplaceCreator = msg.sender;
    }

    //Create an asset
    function createAsset(string calldata name, uint256 price) public {
        //If an Asset with a specific name has already been created, price is >0 and we must choose another name
        require(
            createdAssets[name].price == 0,
            "Asset name already used, please choose another name"
        );
        //Asset price must be > 0
        require(price > 0, "Asset price must be > 0");

        createdAssets[name];
        createdAssets[name].name = name;
        createdAssets[name].price = price;
        createdAssets[name].nbBuyableStakes = price;
        createdAssets[name].assetCreator = payable(msg.sender);
        allAssets.push(name);
        emit AssetCreated(name, price, msg.sender);
    }

    //Buy a stakes from an asset
    function buyStakeFromAsset(string calldata name) public payable {
        //if asset not exisiting, asset price is equal to 0
        require(createdAssets[name].price > 0, "Asset not existing, see created assets with getAllAssets");
        //asset must have more buyable stakes than message value
        require(
            createdAssets[name].nbBuyableStakes >= msg.value,
            "Not enough available stakes"
        );
        createdAssets[name].nbBuyableStakes -= msg.value;
        createdAssets[name].stakesOwnedByInvestors[msg.sender] = msg.value;
        address payable _assetCreator = createdAssets[name].assetCreator;
        (bool sent, bytes memory data) = _assetCreator.call{value: msg.value}(
            ""
        );
        require(sent, "Failed to send Ether");
        createdAssets[name].allInvestors.push(msg.sender);

        emit boughtStakeFromAsset(
            name,
            msg.value,
            msg.sender,
            createdAssets[name].nbBuyableStakes
        );
    }

    function getAllAssets() public view returns (string[] memory) {
        return allAssets;
    }

    function getAssetCreator(string memory name) public view returns (address) {
        return createdAssets[name].assetCreator;
    }

    function getAssetAllInvestors(string memory name)
        public
        view
        returns (address[] memory)
    {
        return createdAssets[name].allInvestors;
    }

    function getAssetInvestorStakes(string memory name, address investor)
        public
        view
        returns (uint256)
    {
        return createdAssets[name].stakesOwnedByInvestors[investor];
    }

    function getAssetNbBuyableStakes(string memory name)
        public
        view
        returns (uint256)
    {
        return createdAssets[name].nbBuyableStakes;
    }

    function getAssetPrice(string memory name)
        public
        view
        returns (uint256)
    {
        return createdAssets[name].price;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return owner.balance;
    }

    function getAssetMarketplaceCreator() public view returns (address) {
        return assetMarketplaceCreator;
    }
}