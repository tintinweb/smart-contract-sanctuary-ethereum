pragma solidity ^0.8.4;

contract FoodNFTs {

    uint256 private artworkCount = 0;
    uint256 private auctionsCount = 0;
    uint256 private providersCount = 0;

    struct Artwork {
        uint256 id;
        uint256 providerID;
        string title;
        string image;
        string description;
        uint256 amount;
        uint256 mintedCount;
        uint256 price;
    }

    struct Provider {
        uint256 id; 
        string name;
        string logo;
        address addr;
        uint split;
        bool isEnabled;
    }

    address owner;

    Provider[] private allProviders;
    Artwork[] private allArtworks;

    mapping(address => Provider) private providerFor;
    mapping(uint256 => Provider) private providerForID;

    mapping(uint256 => Artwork) private artworkForID;
    mapping(address => Artwork[]) private artworksFor;

    constructor() { 
        owner = msg.sender;
    }

    function getRole() public view returns (string memory) {
        if (owner == msg.sender) {
            return "owner";
        } else if (providerFor[msg.sender].id != 0) {
            return "provider";
        } else {
            return "user";
        }
    }

    function addProvider(string calldata _name, uint _split, string calldata _logo, address _providerAddress, bool _isEnabled) public {
        require(msg.sender == owner, "Only the owner can add providers");
        require(_providerAddress != owner, "The owner can't be a provider");
        require(providerFor[_providerAddress].id == 0, "A provider with that address already exists");
        require(_split < 100, "The split must be less than 100");

        uint256 providerID = ++providersCount;

        Provider memory p = Provider({ id: providerID, name: _name, logo: _logo, addr: _providerAddress, split: _split, isEnabled: _isEnabled });
        providerFor[_providerAddress] = p;
        providerForID[providerID] = p;

        allProviders.push(p);
    } 

    function getProviderByAddress(address _owner) public view returns (Provider memory) {
        Provider memory p = providerFor[_owner];
        return(p);
    }

    function getProviderByID(uint256 _id) public view returns (Provider memory) {
        require(_id <= providersCount, "The provider doesn't exists");
        Provider memory p = providerForID[_id];
        return(p);
    }

    function getAllProviders() public view returns (Provider[] memory) {
        return allProviders;
    }

    function addArtwork(string calldata _title, string calldata _image, string calldata _description, uint256 _amount, uint _price) public {
        Provider memory provider = providerFor[msg.sender];
        require(provider.id > 0, "You don't have a profile stored in the contract");
        
        uint256 artworkId = ++artworkCount;
        Artwork memory a = Artwork({id: artworkId, providerID: provider.id, title: _title, image: _image, description: _description, amount: _amount, mintedCount: 0, price: _price });

        artworksFor[msg.sender].push(a);
        artworkForID[artworkId] = a;
        allArtworks.push(a);
    }

    function getAllArtworks(address _owner) public view returns (Artwork[] memory) {
        return artworksFor[_owner];
    } 

}