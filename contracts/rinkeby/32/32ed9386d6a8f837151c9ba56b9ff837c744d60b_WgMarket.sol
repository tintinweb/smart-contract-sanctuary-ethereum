/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

pragma solidity =0.6.6;
pragma experimental ABIEncoderV2;


/**
 * Math operations with safety checks
 */
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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

interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

interface ERC721 {
    function totalSupply() external view   returns (uint) ;
    function mint(address to) external ;
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract WgMarket is Ownable{
    using SafeMath for uint;
    ERC20 public usdt;
    ERC20 public busd;
    ERC721 public nft;
    uint public basePrice = 1 ether;

    mapping (uint => uint[]) public downListMap;
    mapping (uint => uint) public upMap;
    mapping (string => uint[]) public groupMap;
    mapping (uint => Record) public recordMap;

    struct Record {
        uint id;
        uint price;
        uint time;
    }

    event BuyToken(address indexed from,uint gotValue, uint constVlau);
    event GovWithdrawUsdt( address indexed to, uint256 value);
    event GovWithdrawBusd( address indexed to, uint256 value);

    constructor(address _nft,address _usdt,address _busd)public {
        nft = ERC721(_nft);
        usdt = ERC20(_usdt);
        busd = ERC20(_busd);
    }

    function totalSupply() public view returns (uint){
        return nft.totalSupply();
    }

    function getNextId(uint256 _offset) public view returns (uint){
        return totalSupply()+_offset;
    }

    function getPrice(uint256 _index) public view returns (uint){
        uint count = totalSupply();
        return basePrice.mul(100+_index).div(100);
    }

    function getTotalCost(uint _count) public view returns (uint){
        uint rs = 0;
        for(uint i=0;i<_count;i++){
            rs += getPrice(getNextId(i));
        }
        return rs;
    }

    function getDownList(uint256 id) public view returns (Record [] memory){
        uint[] memory downs = downListMap[id];
        Record[] memory rs = new Record[](downs.length);
        for (uint i=0; i < downs.length; i++) {
            Record storage down = recordMap[downs[i]];
            rs[i]= down;
        }
        return rs;
    }

    function getTokensOf(address addr) public view returns (uint [] memory){
        uint count = nft.balanceOf(addr);
        uint[] memory rs = new uint[](count);
        for (uint i=0; i < count; i++) {
            rs[i]= nft.tokenOfOwnerByIndex(addr,i);
        }
        return rs;
    }

    function buy(uint256 _count, uint _cost, string memory _group, uint _upper, bool isBusd) public {
        ERC20 token = usdt;
        if(isBusd){
            token = busd;
        }
        // 2. send Token
        uint amount = 0;
        for(uint i = 0;i< _count;i++){
            uint index = getNextId(i);
            amount += getPrice(index);
        }
        require(
            amount == _cost,
            "Price change"
        );

        uint allowed = token.allowance(msg.sender,address(this));
        uint balanced = token.balanceOf(msg.sender);
        require(allowed >= amount, "!allowed");
        require(balanced >= amount, "!balanced");
        token.transferFrom( msg.sender,address(this), amount);

        // 3. mint nft
        for(uint i = 0;i< _count;i++){
            uint index = getNextId(i);
            uint cost = getPrice(index);
            emit BuyToken(msg.sender,index, cost);
            Record memory record = Record({id:index, price:cost, time:now});
            recordMap[index] = record;
            if(_upper <= 50000){
                upMap[index] = _upper;
                downListMap[_upper].push(index);
            }
            if(bytes(_group).length > 0){
                groupMap[_group].push(index);
            }

            nft.mint(msg.sender);
        }
    }

    function setBasePrice(uint256 _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }

    function setUsdt(address _addr) public onlyOwner {
        usdt = ERC20(_addr);
    }

    function setBusd(address _addr) public onlyOwner {
        busd = ERC20(_addr);
    }

    function withdrawUsdt(address _to,uint256 _amount) public onlyOwner {
        require(_amount > 0, "!zero input");
        usdt.transfer( _to, _amount);
        emit GovWithdrawUsdt( _to, _amount);
    }

    function withdrawBusd(address _to,uint256 _amount) public onlyOwner {
        require(_amount > 0, "!zero input");
        busd.transfer( _to, _amount);
        emit GovWithdrawBusd( _to, _amount);
    }
}