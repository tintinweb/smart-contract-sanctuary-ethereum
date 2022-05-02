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







//
//
// check user exist (no)-> verify it -> can't verify -> [or insert kyc request to other company] ,
//                                      if verified  -> insert (create) new user -id is a key
//                  (yes)-> request consent by user.
//  update current verification -> only by regulator now-> will be by party in  future
//  customer will go through consents request /or just give permitions to company for some attributes or by chosing (*) to all attributes.
//  customer can reverse permissions for all attributes.
//    best case save documents on ipfs and save hash for customer as attribute. (example id hash - FULL NAME+ id NUM+ date of originate)
//
//
//
contract Regulator is Owners,IdentityUtils{



    event RegulatoryContractDeployed (address msgSender,string  msgstr,uint timestamp);

    constructor() public {
//    function Regulator(){
        owner = msg.sender;

       emit RegulatoryContractDeployed(owner,"Mined",now);
        // add bank hapoalin
        submitCompany( owner ,
        "בנק הפועלים"
        ,"הנגב 11 תל אביב",
         1);


 /*
        Company storage company=companies[owner];
        company.name   = "בנק הפועלים";
        company.local_address="הנגב 11 תל אביב";
        company.registry_id=1 ;
        companiesList.push(owner);
        companiesIdCache[company.id]=true ;
        emit AddCompany(owner,company.name,block.timestamp);
*/
    }

    //describes the beneficiary object
        struct Company {
            string name;
            string local_address;
            uint8 registry_id;
        }


        mapping (uint8=>Company) public companiesbyid ;
        mapping (address=>uint8) public companiesbyaddress;
        uint8  []  public companiesList;



    struct Consumer {
            address chainAddress;
            bool registered;
            bool verified;
            address kyc;
            bool require_update;
            bool update_in_progress;
            //mapping(uint8 => address)  permissions;
            //mapping(address => mapping(address => bool) )  requests;

        }

        mapping (bytes32=>Consumer)  consumers;
        mapping (address=>bytes32)  consumersCache;


    // KycRequest struct. It defines kyc request details of customers
            struct ConsentRequest {
                uint8 company_id;
                bytes32 id;
                uint8 kyc_manager_id;
                bool performed;
                uint perform_stamp;
            }

           ConsentRequest[]  consentRequests ;
           //mapping(bytes32 => ConcensusRequest) public concensusRequests


    event submitConsentRequest (string  id,uint8  company_id,uint timestamp)  ;

           function createConsentRequest(string memory id,uint8 company_id,uint8 kyc_manager_id) public   {

            //   require(!check_is_consent_request_exist(id, company_id),"Request already exists!");
            //   require(consumers[id].chainAddress != address(0), "Customer still not  exist!");
            //   require( !consumers[id].verified , "Customer still not  verified!");

            bytes32 idbytes32=stringToBytes32(id);
            consentRequests.push(ConsentRequest(company_id,idbytes32,kyc_manager_id,false,0 ));

            emit submitConsentRequest(id,  company_id,block.timestamp);

           // return consentRequests.length;
         }

         event performedConsentRequest (string  id,uint8  company_id,uint8 kyc_manager_id,bool finished,uint timestamp)  ;


         function finishConsentRequest(string memory id,uint8 company_id,uint8 kyc_manager_id,bool finished) public   {

                     //   require(!check_is_consent_request_exist(id, company_id),"Request already exists!");
                     //   require(consumers[id].chainAddress != address(0), "Customer still not  exist!");
                     //   require( !consumers[id].verified , "Customer still not  verified!");


                     bytes32 idbytes32=stringToBytes32(id);
                     for (uint256 i = 0; i < consentRequests.length; i++) {
                          if (consentRequests[i].company_id==company_id && consentRequests[i].id==idbytes32
                                                  && consentRequests[i].kyc_manager_id==kyc_manager_id)
                                {
                                     consentRequests[i].performed=finished;
                                     consentRequests[i].perform_stamp=block.timestamp;

                                 }

                     emit performedConsentRequest(id,  company_id, kyc_manager_id, finished,block.timestamp);
                  }

    }

    /*
           function getConsentRequestsbyConsumer(string memory id,uint8 company_id)
                public external
                view
                returns (uint8[] memory)
            {
                    require(true != true,"not implemented yet!");
                    bytes32 idbytes32=stringToBytes32(id);
                    uint8[] memory consentList=new uint8[] ;
                   // uint8 count = 0;

                    // Get all the dataHash of the customer for which bank has raised a request
                    for (uint256 i = 0; i < consentRequests.length; i++) {
                        if (consentRequests[i].id== idbytes32) {
                            consentList.push(consentRequests[i].company_id);
                        }

                    }
                    return consentList;
                }

           function getConsentRequestsbyCompany(uint8 company_id) public
            view
            returns (string[] memory)

        {
                require(true != true,"not implemented yet!");
                string[] memory consentList ;
                uint8 count = 0;

                // Get all the dataHash of the customer for which bank has raised a request
                for (uint256 i = 0; i < consentRequests.length; i++) {
                    if (consentRequests[i].company_id == company_id) {

                    string id=bytes32ToString(consentRequests[i].id);
                    consentList.push(id);
                    }

                }
                return consentList;
            }

    */
        function getConsentRequests()
      //     public
            view
            external
            returns (ConsentRequest[] memory)

        {
                //require(true != true,"not implemented yet!");

                return consentRequests;
            }





    function getConsumerAddress(string memory id ) public view returns(address)   {

        bytes32 idbytes32=stringToBytes32(id);
        return consumers[idbytes32].chainAddress;
    }

    event AddConsumer (address indexed consumerAddress,string   id,uint timestamp);

                //  function to add a customer profile to the database
                //  returns 0 if successful
                //  returns 7 if no access rights to transaction request sender
                //  returns 1 if size limit of the database is reached
                //  returns 2 if customer already in network

            function submitConsumer(address consumerAddress , string memory id) public returns (uint) {

                bytes32 idbytes32=stringToBytes32(id);
           /*
                if (consumers[idbytes32].chainAddress!= address(0))
                    return 2;
*/
                Consumer storage consumer=consumers[idbytes32];
                consumer.chainAddress    = consumerAddress;
                consumer.registered   = true;
                consumersCache[consumerAddress]=idbytes32;

                return 0;
            }


            function getConsumer( string memory id) public
                    view returns
                    (Consumer memory) {

                        bytes32 idbytes32=stringToBytes32(id);
                        Consumer memory consumer=consumers[idbytes32];

                        return consumer;
                }



    event AddCompany (address indexed companyAddress,string  name,uint8 registry_id, uint timestamp);
    function submitCompany(address companyAddress , string memory _name,string memory _local_address,uint8 registry_id) public  {
  //      require(companyAddress!=owner,"Company address can't be same as regulator");
  //      require( companiesbyid[company_id].registry_id==0 , "Company with this id already exist!");
        Company storage company=companiesbyid[registry_id];
        company.name   = _name;
        company.local_address=_local_address;
        company.registry_id=registry_id;
        companiesList.push(registry_id);
        companiesbyaddress[companyAddress]=registry_id;
        emit AddCompany(companyAddress,_name,registry_id,block.timestamp);
    }




    function getCompany( uint8 registry_id) public view returns(string memory,string memory,uint8 )   {
 //       require( companiesIdCache[registry_id] , "Company with this id not exist!");

            Company memory company=companiesbyid[registry_id];
            return (company.name,company.local_address,company.registry_id);
        }


    function connectCompanyAddress( address companyAddress,uint8 id) public     {
         //   require(companyAddress ==owner || companyAddress!=owner,"Company address can't be same as regulator");
        require(true!=true,"Not implemented yet");
        companiesbyaddress[companyAddress]=id;

    }



/*
       function check_is_consent_request_exist(string memory id,uint8 company_id) public payable returns(bool) {
               return false;
       }
*/


    event finalizeKYC(string    id,address permissionExtenderAddress,uint8 company_registry_id ,uint timestamp);
    function performKYC(string memory id , address permissionExtenderAddress,uint8 company_registry_id) public   {

        bytes32 idbytes32=stringToBytes32(id);
        Consumer storage consumer=consumers[idbytes32];
        consumer.kyc=  permissionExtenderAddress;
        emit finalizeKYC(id,PermissionExtender(permissionExtenderAddress).getOwner(), company_registry_id ,block.timestamp);


        addCompanionPermission(id , company_registry_id,"*",1);


        }




   function performFullKYC(string memory fullname,string memory id,string memory issued_country,string memory laddress,string memory sex,
        string memory date_of_birth,  bool  smoking,  uint8 company_registry_id) public   {

            bytes32 idbytes32=stringToBytes32(id);
            Consumer storage consumer=consumers[idbytes32];
            PermissionExtender kyc = new KYC( company_registry_id, fullname, id, issued_country, laddress, sex, date_of_birth,
                                           smoking );
            consumer.kyc =  address(kyc);
            emit finalizeKYC(id,kyc.getOwner(), company_registry_id ,block.timestamp);


            addCompanionPermission(id , company_registry_id,"*",1);


            }

/*
    function getKYC(string memory id) public view returns(kyc )
     {
            bytes32 idbytes32=stringToBytes32(id);

             // require(consumers[idbytes32].chainAddress != address(0) && consumers[getConsumerAddress(id)].permissions[basecompanyAddress]!= address(0));
             return consumers[idbytes32].kyc;

      }
*/


    event addPermission(address indexed performerAddress,string  id , uint8 company_registry_id,string  attributeName,uint8   attributepermission ,uint timestamp);

    function getConsumerAttributeList( string memory id,uint8 company_registry_id) public view returns(bytes32[] memory)
             {
                bytes32 idbytes32=stringToBytes32(id);
                 return PermissionExtender(consumers[idbytes32].kyc).getAttributeList();

             }


    function addCompanionPermission(string memory id , uint8 company_registry_id,string memory attributeName,uint8   attributepermission) public   {

             //        require(PermissionExtender(permissionExtenderAddress).getCustomerAddress ==getConsumerAddress(id));

             bytes32 idbytes32=stringToBytes32(id);

             PermissionExtender(consumers[idbytes32].kyc).setAttributePermission(attributeName,company_registry_id,attributepermission);

              emit addPermission(msg.sender, id,company_registry_id,attributeName,attributepermission, now);
         }

     function getConsumerAttributePermission( string memory id,uint8 company_registry_id,string memory attributeName) public view returns(int permission)
         {
            bytes32 idbytes32=stringToBytes32(id);
             return PermissionExtender(consumers[idbytes32].kyc).isAttributePermited(attributeName,company_registry_id);

         }

         function getConsumerAttributeValue(string memory id,uint8 company_registry_id,string memory attributeName) public view returns(bytes32 )
         {
            bytes32 idbytes32=stringToBytes32(id);
             // require(consumers[idbytes32].chainAddress != address(0) && consumers[getConsumerAddress(id)].permissions[basecompanyAddress]!= address(0));
             return PermissionExtender(consumers[idbytes32].kyc).getAttribute(attributeName,company_registry_id);

         }

         function getConsumerAttributeName(string memory id,uint row) public view returns(bytes32 )
         {

            bytes32 idbytes32=stringToBytes32(id);
             // require(consumers[idbytes32].chainAddress != address(0) && consumers[getConsumerAddress(id)].permissions[basecompanyAddress]!= address(0));
             return PermissionExtender(consumers[idbytes32].kyc).getAttributeName( row);

         }
         function getAttributeLength(string memory id) public view returns(uint )
         {

            bytes32 idbytes32=stringToBytes32(id);
             // require(consumers[idbytes32].chainAddress != address(0) && consumers[getConsumerAddress(id)].permissions[basecompanyAddress]!= address(0));
             return PermissionExtender(consumers[idbytes32].kyc).getAttributeLength( );

         }



    function getCurrentKYCPerformer(string memory id) public view returns(uint )
    {
                bytes32 idbytes32=stringToBytes32(id);
                if (consumers[idbytes32].kyc!=address(0))
                {
                    return PermissionExtender(consumers[idbytes32].kyc).getKYCPerformer( );
                }
                else
                {
                    return 0;
                }

     }



    function getCompaniesList() public view returns(  uint8 [] memory)
    {
        // require(consumers[getConsumerAddress(id)].chainAddress != address(0) && consumers[getConsumerAddress(id)].permissions[basecompanyAddress]!= address(0));

        return companiesList;
    }





}