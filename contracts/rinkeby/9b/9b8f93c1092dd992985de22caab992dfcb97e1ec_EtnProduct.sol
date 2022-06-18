/**
 *Submitted for verification at Etherscan.io on 2022-06-18
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

interface ERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface EtnShop{
    function canUploadProduct(address to,uint commId, uint shopId) external view returns ( bool);
    function getShopOwner(uint commId, uint shopId) external view returns ( address);

}

contract EtnProduct is  Ownable {
    using SafeMath for uint;

    EtnShop public etnShop; //链商addr

    mapping(uint => Product) public productMap;

    struct Product {
        uint productId;
        uint price;
        string name;
        string video;
        string logo;
        string qrCode;
        string phone;
        string next;

    }
    constructor()
    {
    }

    function newProduct(uint price, string memory name, string memory video ) public {
        uint pId = 0;
        Product memory p = Product(pId,price,name,video,"","","","");
        productMap[pId] = p;
    }

    function updateProduct(uint productId, string memory name, string memory video,
        string memory logo, string memory qrCode, string memory phone, string memory next, uint price) public {
        Product memory p = productMap[productId];
        p.name = name;
        p.video = video;
        p.logo = logo;
        p.qrCode = qrCode;
        p.phone = phone;
        p.name = next;
        p.price = price;
    }
}