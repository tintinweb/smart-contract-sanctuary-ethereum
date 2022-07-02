/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

pragma solidity =0.8.1;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


interface IEtnShop{
    function canUploadProduct(address to,uint commId, uint shopId) external view returns ( bool);
    function getTokenId(uint commId, uint shopId) external view virtual returns (uint) ;
    function getShopOwner(uint commId, uint shopId) external view returns ( address);
}

interface IERC20{
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IFactory {
    function createContract(string calldata name, string calldata symbol, bytes32 salt) external returns (address);
}

contract EtnProduct is  Ownable {
    IEtnShop public etnShop; //链商addr

    IFactory public factory;

    mapping(uint => address[]) public shopProdListMap;
    mapping(address => Product) public tokenProdMap;
    mapping(address => address) public ownerMap;
    address[] public tokenList;
    uint _totalSupply = 0;

    event NewToken(address indexed token);

    struct Product {
        uint price;
        string name;
        string video;
        string logo;
        string qrCode;
        string phone;
        string next;
    }

    constructor(address _etnShop,address _factory)public {
        etnShop = IEtnShop(_etnShop);
        factory = IFactory(_factory);
    }

    function newProduct(uint commId, uint shopId, uint price, string memory name, string memory video ) public {
        uint shopTokenId = etnShop.getTokenId(commId,shopId);
        Product memory p = Product(price,name,video,"","","","");
        address erc20Addr = factory.createContract( name,  name, bytes32(shopTokenId));
        tokenProdMap[erc20Addr] = p;
        shopProdListMap[shopTokenId].push(erc20Addr);
        ownerMap[erc20Addr] = msg.sender;
        _totalSupply++;
        tokenList.push(erc20Addr);
        emit NewToken(erc20Addr);
    }

    function updateProduct(address erc20Addr, string memory name, string memory video,
        string memory logo, string memory qrCode, string memory phone, string memory next, uint price) public {

        Product storage p = tokenProdMap[erc20Addr];
        p.name = name;
        p.video = video;
        p.logo = logo;
        p.qrCode = qrCode;
        p.phone = phone;
        p.next = next;
        p.price = price;
    }

    function transferTo(address to, address erc20Addr) public {
        require(isOwner(msg.sender, erc20Addr));
        ownerMap[erc20Addr] = to;
    }

    //name, logo,price
    function getShopProducts(uint commId, uint shopId) public view returns (address[] memory erc20Addrs, string[] memory,string[] memory,uint[] memory){
        uint shopTokenId = etnShop.getTokenId(commId,shopId);
        uint len = shopProdListMap[shopTokenId].length;

        address[] memory erc20Addrs= new address[](len);
        string[] memory names = new string[](len);
        string[] memory logos = new string[](len);
        uint[] memory prices = new uint[](len);

        for (uint i = 0; i < len; i++) {
            address erc20Addr = shopProdListMap[shopTokenId][i];
            Product memory p = tokenProdMap[erc20Addr];
            erc20Addrs[i] = erc20Addr;
            names[i] = p.name;
            logos[i] = p.logo;
            prices[i] = p.price;
        }
        return (erc20Addrs,names,logos,prices);
    }

    function isOwner(address to, address erc20Addr) public view returns (bool){
        return ownerMap[erc20Addr] == to;
    }

    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }

    function withdrawToken(address _token, address _to,uint256 _amount) public onlyOwner {
        require(_amount > 0, "!zero input");
        IERC20 token = IERC20(_token);
        uint balanced = token.balanceOf(address(this));
        require(balanced >= _amount, "!balanced");
        token.transfer( _to, _amount);
    }
}