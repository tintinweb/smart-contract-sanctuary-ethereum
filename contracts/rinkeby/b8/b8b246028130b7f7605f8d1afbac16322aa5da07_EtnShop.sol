/**
 *Submitted for verification at Etherscan.io on 2022-06-07
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

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}
interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external;
}
interface ERC20_Returns {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
interface ShopNft {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function mint(address to, uint mintIndex ) external  returns (uint);
}

contract EtnShop is  Ownable {
    using SafeMath for uint;

    address public host;    //30%
    address public pool;    //10%
    ERC721 public commNft; //公社addr
    ShopNft public shopNft; //链商addr
    ERC20 public usdt;     //usdt
    ERC20 public etnU;    //etn usdt
    uint public mintCost = 1998 * 10**18;
    uint public stakeLife = 3650*24*60*60;

    mapping(address => uint) public mintTimeMap;
    mapping(address => uint) public mintIdMap;
    mapping(address => uint) public withdrawMap;
    mapping(uint => mapping(address => bool)) public inviteMap;
    //    mapping(uint => uint) public shopIdMap;
    mapping(uint => Shop[]) public shopMap;
    //    mapping(uint =>  Shop) public tokenShopMap; //与上重复,以后去掉一个

    struct Shop {
        uint shopId;
        string name;
        string logo;
    }

    constructor()
    {
    }

    function invite(address to, uint commId) public {
        address commOwner = commNft.ownerOf(commId);
        require(commOwner == msg.sender, "not comm owner");
        inviteMap[commId][to] = true;
    }


    function mint( uint commId, string memory name, string memory logo) public returns (uint){
        return mintTo(msg.sender,commId,name, logo);
    }

    function mintTo(address to, uint commId,string memory name, string memory logo) public returns (uint){
        require(inviteMap[commId][to] == true, "not invited");
        uint shopId = shopMap[commId].length;
        uint tokenId = getTokenId(commId, shopId);

        uint allowed = usdt.allowance(msg.sender,address(this));
        uint balanced = usdt.balanceOf(msg.sender);
        require(allowed >= mintCost, "!allowed");
        require(balanced >= mintCost, "!balanced");
        usdt.transferFrom(msg.sender,address(this), mintCost);

        address commOwner = commNft.ownerOf(commId);
        usdt.transferFrom(address(this),host, mintCost*30/100);
        usdt.transferFrom(address(this),pool, mintCost*10/100);
        usdt.transferFrom(address(this),commOwner, mintCost*60/100);

        shopNft.mint(to, tokenId);
        mintTimeMap[to] = block.timestamp;
        mintIdMap[to] = tokenId;
        Shop memory s = Shop(shopId,name,logo);
        shopMap[commId].push(s);
        return tokenId;
    }

    function withdraw() public {
        uint value = withdrawValue(msg.sender);
        if(withdrawMap[msg.sender] +value > mintCost){
            value= mintCost.sub(withdrawMap[msg.sender]);
        }
        withdrawMap[msg.sender] = withdrawMap[msg.sender] +value;
        require(value>0, "no withdraw value");
        uint balanced = etnU.balanceOf(address(this));
        require(balanced >= value, "!balanced");

        etnU.transferFrom(address(this),msg.sender, value);
    }

    function withdrawValue(address to) public view virtual returns (uint) {
        uint blkTime = mintTimeMap[to];
        if(blkTime == 0){
            return 0;
        }
        return mintCost * (block.timestamp - blkTime) /stakeLife - withdrawMap[to];
    }

    function  getTokenId(uint commId, uint shopId) public view virtual returns (uint) {
        require(shopId < 100, "big shop id");
        return commId*100+shopId;
    }

    function getCommShops(uint commId) public view returns ( uint[] memory, string[] memory,string[] memory){
        uint len = shopMap[commId].length;
        uint[] memory shopIds = new uint[](len);
        string[] memory names = new string[](len);
        string[] memory logos = new string[](len);

        for (uint i = 0; i < len; i++) {
            shopIds[i] = shopMap[commId][i].shopId;
            names[i] = shopMap[commId][i].name;
            logos[i] = shopMap[commId][i].logo;
        }
        return (shopIds,names,logos);
    }

    function getShopNum(uint commId) public view returns ( uint){
        return shopMap[commId].length;
    }

    function canMintShop(uint commId, address to) public view returns ( bool){
        return inviteMap[commId][to] && mintTimeMap[to] == 0;
    }

    function canUploadProduct(address to,uint commId, uint shopId) public view returns ( bool){
        uint tokenId = getTokenId(commId,shopId);
        return shopNft.ownerOf(tokenId) == to;
    }

    function getShopOwner(uint commId, uint shopId) public view returns ( address){
        uint tokenId = getTokenId(commId, shopId);
        return shopNft.ownerOf(tokenId);
    }

    function getCommOwner(uint commId) public view returns ( address){
        return commNft.ownerOf(commId);
    }

    function setup(address _host, address _pool, address _commNft, address _shopNft, address _usdt, address _etnU) public onlyOwner {
        host = _host;
        pool = _pool;
        commNft = ERC721(_commNft);
        shopNft = ShopNft(_shopNft);
        usdt = ERC20(_usdt);
        etnU = ERC20(_etnU);
    }
}