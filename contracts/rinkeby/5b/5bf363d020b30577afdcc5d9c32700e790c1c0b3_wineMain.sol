/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;




//erc721็ไป้ข
abstract contract ERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    function totalSupply() virtual public view returns (uint256 total);
    function balanceOf(address _owner) virtual public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId)  virtual public view returns (address _owner);
    function transfer(address _to, uint256 _tokenId) virtual public;
    function approve(address _to, uint256 _tokenId) virtual public;
    function transferFrom(address _from, address _to, uint256 _tokenId) virtual external;
    function name() virtual external view returns (string memory _name);
    function symbol() virtual external view returns (string memory _symbol);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
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
    constructor() {
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



contract wineMain is  ERC721, Ownable {

    using SafeMath for uint256;
    string public name_ = "wineToken";

    struct wine {
        string year; //้็ๅนดไปฝ 1958, 1982, 1988, 1963 
        string county; //้็็ขๅฐ Spain, France, Italy, Germany
        string grades; //ๆ่ณ็ญ็ด Bronze, Silver, Gold
    }

    wine[] public many_wine;
    string public symbol_ = "Wine";

    mapping (uint => address) public wineToOwner; //ๆฏ้ป้้ฝๆไธๅ็จไธ็กไบ็็ทจ่๏ผๅผๅซๆญคmapping๏ผๅพๅฐ็ธๅฐๆ็ไธปไบบ
    mapping (address => uint) ownerWineCount; //ๅๅณๆๅธณ่ๅบไธ็้ๆธ้
    mapping (uint => address) wineApprovals; //ๅ ERC721 ไธๆจฃ๏ผๆฏๅฆๅๆ่ขซ่ฝ่ตฐ


    event Take(address _to, address _from,uint _tokenId);
    event Create(uint _tokenId, string year, string county, string grades);

    function name() override external view returns (string memory) {
        return name_;
    }

    function symbol() override external view returns (string memory) {
        return symbol_;
    }

    function totalSupply() override public view returns (uint256) {
        return many_wine.length;
    }

    function balanceOf(address _owner) override public view returns (uint256 _balance) {
        return ownerWineCount[_owner]; // ๆญคๆนๆณๅชๆฏ้กฏ็คบๆๅธณ่ ้ค้ก
    }

    function ownerOf(uint256 _tokenId) override public view returns (address _owner) {
        return wineToOwner[_tokenId]; // ๆญคๆนๆณๅชๆฏ้กฏ็คบๆ้ ๆๆ่
    }

    function checkAllOwner(uint256[] memory _tokenId, address owner) public view returns (bool) {
        for(uint i=0;i<_tokenId.length;i++){
            if(owner != wineToOwner[_tokenId[i]]){
                return false;   //็ตฆไบไธ้ฃไธฒ้๏ผๅคๆทไฝฟ็จ่ๆฏไธๆฏ้ฝๆฏๅไธไบบ
            }
        }
        
        return true;
    }

    function seeWineYears(uint256 _tokenId) public view returns (string memory year) {
        return many_wine[_tokenId].year;
    }

    function seeWineCounty(uint256 _tokenId) public view returns (string memory county) {
        return many_wine[_tokenId].county;
    }
    
    function seeWineGrades(uint256 _tokenId) public view returns (string memory grades) {
        return many_wine[_tokenId].grades;
    }

    function getWineByOwner(address _owner) external view returns(uint[] memory) { //ๆญคๆนๆณๅๅณๆๆๅธณๆถๅง็"้ID"
        uint[] memory result = new uint[](ownerWineCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < many_wine.length; i++) {
            if (wineToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function transfer(address _to, uint256 _tokenId) override public {
        //TO DO ่ซไฝฟ็จrequireๅคๆท่ฆ่ฝ็้idๆฏไธๆฏ่ฝ็งป่็
        require(wineToOwner[_tokenId] == msg.sender);
        //ๅขๅ?ๅ่ด่็ๆๆ้ๆธ้
        //ๆธๅฐ่ฝๅบ่็ๆๆ้ๆธ้
        ownerWineCount[_to]++;
        ownerWineCount[msg.sender]--;
        
        wineToOwner[_tokenId] = _to;
        //้ๆๆๆฌ่ฝ็งป
        
        emit Transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _to, uint256 _tokenId) override public {
        require(wineToOwner[_tokenId] == msg.sender);
        
        wineApprovals[_tokenId] = _to;
        
        emit Approval(msg.sender, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) override external {
        // Safety check to prevent against an unexpected 0x0 default.
        require(wineToOwner[_tokenId] == _from); 
        require(_to != address(0)); 

        ownerWineCount[_to] ++;
        ownerWineCount[_from] --;
        wineToOwner[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function takeOwnership(uint256 _tokenId) public {
        require(wineToOwner[_tokenId] == msg.sender);
        
        address owner = ownerOf(_tokenId);

        ownerWineCount[msg.sender] = ownerWineCount[msg.sender].add(1);
        ownerWineCount[owner] = ownerWineCount[owner].sub(1);
        wineToOwner[_tokenId] = msg.sender;
        
        emit Take(msg.sender, owner, _tokenId);
    }


    string[] years_list = ["1958", "1982", "1988", "1963"];
    string[] county_list = ["Spain", "France", "Italy", "Germany"];
    string[] grades_list = ["Bronze", "Silver", "Gold"];

    function createWine() public payable{
        //require(msg.value >= 1000 wei, "่ณผ่ณฃ้็NFT้่ฆ่ณๅฐ0.01ETH"); 
        string storage year;
        string storage county;
        string storage grades;
        
        
        //TO DO 
        //ไฝฟ็จไบๆธไพ็ข็DNA, ๆ็ด, ้็จฎ้ก
        bytes32 result1 = keccak256(abi.encodePacked(msg.sender, address(this), block.timestamp, block.coinbase, block.number));
        bytes32 result2 = keccak256(abi.encodePacked(msg.sender, address(this), block.timestamp, block.coinbase, block.number));
        bytes32 result3 = keccak256(abi.encodePacked(msg.sender, address(this), block.timestamp, block.coinbase, block.number));
        year = years_list[(uint(result1) % 4)];
        county = county_list[(uint(result2) % 4)];
        grades = grades_list[(uint(result3) % 3)];
        
        //ๅๆ็ฉๅตๆ๏ผๅฏไปฅ้ๅถๆฏๆฌกๅปบ็ซ้้่ฆ่ฑ่ฒปๅคๅฐETH

        
        many_wine.push(wine(year, county, grades));
        uint id = many_wine.length - 1;
        emit Create(id, year, county, grades);
        wineToOwner[id] = msg.sender;
        ownerWineCount[msg.sender]++;
 
    }
  
}