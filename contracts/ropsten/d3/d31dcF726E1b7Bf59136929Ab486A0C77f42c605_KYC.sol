/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;


contract Owners {
    //owner address for ownership validation
    address owner;

    constructor() public {
        owner = msg.sender;
//        log("owner=",owner);
    }
    //owner check modifier
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

//    //contract distruction by owner only
//    function close()  public  onlyOwner {
////        log("##contract closed by owner=",owner);
//        selfdestruct(owner);
//    }

    //constractor to verify real owner assignment
    function getOwner()    public view returns (address){
        return owner ;
    }
    //log event for debug purposes
//    event log(string loga, address logb);
}

pragma solidity ^0.6.4;


contract IdentityUtils {


    function uintToString(uint u)  pure  public returns ( string memory ){

        return bytes32ToString(bytes32(u));
    }

    function stringToUint(string memory  s) pure public returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c =uint(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function  addresstoBytes(address a) public pure returns (bytes memory  b)  {
        assembly {
        let m := mload(0x40)
        mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
        mstore(0x40, add(m, 52))
        b := m

        }
    }



    function addresstoString(address x) public pure returns (string memory ) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
        b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }

/*
    function stringToUint(string memory s)  public pure returns (uint result) {
            bytes memory b = bytes(s);
            uint i;
            result = 0;
            for (i = 0; i < b.length; i++) {
                uint c = uint(b[i]);
                if (c >= 48 && c <= 57) {
                    result = result * 10 + (c - 48);
                }
            }
        }


    function uintToString(uint _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
*/

    function bytes32ToString (bytes32   data) pure public  returns ( string memory ) {
        bytes memory bytesString = new bytes(32);
        for (uint j=0; j<32; j++) {
            byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[j] = char;
            }
        }
        return string(bytesString);
    }

    function stringToBytes32(string memory source) pure public returns (bytes32   result) {
        assembly {
        result := mload(add(source, 32))
        }
    }

    function toBytes(uint256 x)  pure public returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function uintToBytes32(uint v) pure public returns (bytes32   ret) {
        if (v == 0) {
            ret = '0';
        }
        else {
        while (v > 0) {
        ret = bytes32(uint(ret) / (2 ** 8));
        ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
        v /= 10;
        }
        }
        return ret;
    }

    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function stringcompare(string memory _a, string memory  _b) pure public returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
        if (a[i] < b[i])
        return -1;
        else if (a[i] > b[i])
        return 1;
        if (a.length < b.length)
        return -1;
        else if (a.length > b.length)
        return 1;
        else
        return 0;
    }


}



abstract contract PermissionExtender is Owners,IdentityUtils{

    mapping(string => mapping(uint8 => int)) permissions;


    //    //***
    //    //*** MODIFIERS
    //    //***
    //    //premissions modifier for bank functions
    /*
    modifier onlyPermited() {
        if ( msg.sender != getCustomerAddress() ) {
            revert();
        }
        _;
    }
    */

    //    function setAttribute(String attrName) constant private returns (int);
    //    function setAttributeValue(String attrName ,string attrVallue) constant private returns (boolean);
    function getAttributeValue(string memory attrName) view internal virtual returns (bytes32);
    //function getCustomerAddress() view public virtual returns (address);
    function getKYCPerformer()   view  public virtual returns (uint8);
    function getAttributeName(uint row) view virtual public  returns (bytes32);
    function getAttributeLength() view virtual public returns (uint);


    function getAttributeList() view virtual public returns (bytes32[] memory);

    function setAttributePermission(string memory  attributeName ,uint8 companion_id , int permission)   public returns (int)
    {

        //        require(msg.sender == owner || msg.sender==getCustomerAddress());



         //        require(PermissionExtender(permissionExtenderAddress).getCustomerAddress ==getConsumerAddress(id));


         if (stringcompare(attributeName,"*") == 0)
         {
/*
            bytes32[] memory attrlist=getAttributeList();
            for (uint account_ind=0; account_ind < attrlist.length; account_ind++) {
                        string memory attrname=bytes32ToString(attrlist[account_ind]);
                        permissions[attrname][companion_id]=permission;
            }
*/

            permissions["fullname"][companion_id]=permission;
            permissions["id"][companion_id]=permission;
            permissions["address"][companion_id]=permission;
            permissions["issued_country"][companion_id]=permission;
            permissions["sex"][companion_id]=permission;
            permissions["smoking"][companion_id]=permission;
            permissions["date_of_birth"][companion_id]=permission;

         }
         else
             permissions[attributeName][companion_id]=permission;

     }



    function isAttributePermited(string memory  attrName,uint8 companion_id) view public returns (int)
    {
  //      if (msg.sender == owner)
  //          return 1;
  //      else
            return (permissions[attrName][companion_id]);

    }



    function getAttribute(string memory attrName,uint8 companion_id) view public returns (bytes32 )
    {

        if (isAttributePermited(attrName, companion_id)!=0)
        {
            return getAttributeValue(attrName);
        }
            else
                return stringToBytes32("not permited");

    }

//    function getAttributeString(string attrName) constant public returns (string )
//    {
//        return bytes32ToString(getAttribute(attrName));
//    }
}


contract KYC is PermissionExtender {

    bytes32[] public  attributesList;
    //string[] public  attributesList;
   // address customer;
    uint8 kycPerformer;
    mapping(string => bytes32) internal attributes;
    
    constructor(uint8 _kycPerformer,string memory fullname,string memory id,string memory issued_country,
            string memory laddress, string memory sex, string memory date_of_birth,  bool  isSmoking) public {
           kycPerformer=_kycPerformer;
           // customer=_customer;
            attributesList.push(stringToBytes32("fullname"));
            attributes["fullname"]=stringToBytes32(fullname);
            attributesList.push(stringToBytes32("id"));
            attributes["id"]=stringToBytes32(id);
            attributesList.push(stringToBytes32("issued_country"));
            attributes["issued_country"]=stringToBytes32(issued_country);
            attributesList.push(stringToBytes32("address"));
            attributes["address"]=stringToBytes32(laddress);

            attributesList.push(stringToBytes32("sex"));
            attributes["sex"]=stringToBytes32(sex);

            attributesList.push(stringToBytes32("date_of_birth"));
            attributes["date_of_birth"]=stringToBytes32(date_of_birth);
    
            attributesList.push(stringToBytes32("smoking"));
            if(isSmoking)
                attributes["smoking"]=stringToBytes32("YES");
            else
                attributes["smoking"]=stringToBytes32("NO");

        }
        
        








function getAttributeValue(string memory attrName)  override  view internal virtual  returns (bytes32)
{
    return attributes[attrName];
}

/*
function getCustomerAddress()  override  view public virtual returns (address)
{
    return customer;
}
*/
    function getKYCPerformer()  override  view public virtual returns (uint8)
    {
        return kycPerformer;
    }

    function getAttributeName(uint row) override   view public virtual returns (bytes32)
    {
        if (row<attributesList.length)
            return attributesList[row];
        else
            return "";
    }

    function getAttributeLength()  override view public virtual returns (uint)
    {
        return attributesList.length;
    }

    function getAttributeList()  override view virtual public returns (bytes32[] memory)
        {
            return attributesList;
        }

//    function getFullData(address) constant public returns (string,string,string,string,string,boolean);


}