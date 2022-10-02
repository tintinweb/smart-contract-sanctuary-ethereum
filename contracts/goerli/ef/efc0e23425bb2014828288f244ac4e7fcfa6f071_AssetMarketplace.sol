/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

pragma solidity 0.8.4;

//Contract to create assets and buy stakes

contract AssetMarketplace {

  //Asset has a name, a price and a creator
  struct Asset {
      string name;
      uint price;
      uint nbBuyableStakes;
      address payable assetCreator;
      bool alreadyCreated;
      mapping(address=>uint) stakesOwnedByInvestors;
      address[] allInvestors;
   }

  address public assetMarketplaceCreator;
  mapping(string => Asset) public createdAssets;
  string[] public allAssets;
  
  //When asset is created
  event AssetCreated(string name, uint price, address assetCreator);
  //When stake is bought
  event boughtStakeFromAsset(string name, uint quantity, address assetInvestor, uint nbBuyableStakes);
  

  constructor () {
    assetMarketplaceCreator = msg.sender;
  }

  //Create an asset
  function createAsset(string calldata name, uint price) public {
    require(!createdAssets[name].alreadyCreated, "Asset name already used, please choose another name");
    require(price>0, "Asset price must be > 0");
    

    createdAssets[name];
    createdAssets[name].name = name;
    createdAssets[name].price = price;
    createdAssets[name].nbBuyableStakes = price;
    createdAssets[name].assetCreator = payable(msg.sender);
    createdAssets[name].alreadyCreated = true;
    allAssets.push(name);
    emit AssetCreated(name, price, msg.sender);
    
  }

  //Buy a stakes from an asset
  function buyStakeFromAsset(string calldata name) public payable{
    require(createdAssets[name].nbBuyableStakes>=msg.value, "Not enough available stakes");
    createdAssets[name].nbBuyableStakes -= msg.value;
    createdAssets[name].stakesOwnedByInvestors[msg.sender] = msg.value;
    address payable _assetCreator = createdAssets[name].assetCreator;
    (bool sent, bytes memory data) = _assetCreator.call{value: msg.value}("");
    require(sent, "Failed to send Ether");
    createdAssets[name].allInvestors.push(msg.sender);

    
    emit boughtStakeFromAsset(name, msg.value, msg.sender, createdAssets[name].nbBuyableStakes);
  }

  
  function AssetMarketplaceCreator()  public view returns (address){
      return assetMarketplaceCreator;

  }


  function getAllAssets()  public view returns (string[] memory){
      return allAssets;

  }

  function getAssetCreator(string memory name)  public view returns (address){
      return createdAssets[name].assetCreator;

  }


  function getAssetAllInvestors(string memory name)  public view returns (address[] memory){
      return createdAssets[name].allInvestors;

  }

  function getAssetInvestorStakes(string memory name, address investor)  public view returns (uint){
      return createdAssets[name].stakesOwnedByInvestors[investor];

  }

  function getNbBuyableStakes(string memory name)  public view returns (uint){
  return createdAssets[name].nbBuyableStakes;
  }

  function balanceOf(address owner) public view returns (uint256) {
        return owner.balance;
    }

  function getAssetMarketplaceCreator() public view returns (address) {
        return assetMarketplaceCreator;
    }



}