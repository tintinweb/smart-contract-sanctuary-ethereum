/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract supplychain {



    struct ManufacturerDetails {
        
        string Out_date;
        
    }


      struct projectDetails {
        string current_owner ;
        string previous_owner ;
        uint256 Manufacturer_ID ;
        uint256 Distributor_ID ;
        uint256 Retailer_ID ;
        string Manufacturer_State ;
        string Distributer_State ;
        string Retailer_State ;
        string owner_name;
        string mgf_date;
        string exp_date;
         string buyer_id;
        // uint256 productid;
    }


        struct Manufacture_d {
        
        string name;
        string city;
        string country;
      
    }

       struct Distributer_d {
        
        string name;
        string city;
        string country;
      
    }

   struct Retailer_d {
        
        string name;
        string city;
        string country;
      
    }

     struct Buyer_d {
        
        string name;
        string city;
        string country;
      
    }



  mapping (address => uint256) public  m_AutoId;
  mapping (address => uint256) public  d_AutoId;
  mapping (address => uint256) public  r_AutoId;
    mapping(uint256 => projectDetails ) public tractProject;

        mapping(uint256 => Manufacture_d) public Manufacture_Detail;
    mapping(uint256 => Distributer_d) public Distributer_Detail;
    mapping(uint256 => Retailer_d) public Retailer_Detail;
    mapping(uint256 => Buyer_d) public Buyer_Detail;



    struct DistributorDetails {
        string Out_date;
        string In_date;
        
    }

    struct RetailerDetails {
         string Out_date;
        string In_date;
    }

     

    mapping(uint256 => ManufacturerDetails) public Manufacture_Tracking;
    mapping(uint256 => DistributorDetails) public Distributor_Tracking;
    mapping(uint256 => RetailerDetails) public Retailer_Tracking;


 address Admin;


    constructor(){
    Admin = msg.sender;

}


    function manufacturer(
        
        string memory mgf_date,
        string memory exp_date,
        string memory _State,
        string memory _Out_date,
         uint256 productid
    ) public {
        tractProject[productid].current_owner = "Manufacture";
        tractProject[productid].previous_owner = "Manufacture";
        tractProject[productid].Manufacturer_ID =  m_AutoId[msg.sender];
        tractProject[productid].exp_date = exp_date;
         tractProject[productid].mgf_date = mgf_date;
         Manufacture_Tracking[productid].Out_date = _Out_date;
         tractProject[productid].Manufacturer_State = _State;
        //  tractProject[productid].productid = productid;
    }

    function Distributer(
        
        string memory _State,
        string memory In_date,
        string memory Out_date,
         uint256 productid

    ) public {
        tractProject[productid].current_owner = "Distributer";
        tractProject[productid].previous_owner = "Manufacture";
        tractProject[productid].Distributor_ID = d_AutoId[msg.sender];
        tractProject[productid].Distributer_State = _State;
        Distributor_Tracking[productid].Out_date = Out_date;
         Distributor_Tracking[productid].In_date = In_date;
        //  tractProject[productid].productid = productid;
    }




        function addManufacture(string memory _name , string memory _city , string memory _country  , uint256 _id , address _address) public {
        //  Manufacture_d memory u = Manufacture_Detail[_id];
         require(msg.sender == Admin ,"only Admin can run this function ");
        Manufacture_Detail[_id].name = _name;
        Manufacture_Detail[_id].city = _city;
        Manufacture_Detail[_id].country = _country;
        m_AutoId[_address] = _id;

    }




     function addDistributer(string memory _name , string memory _city , string memory _country  , uint256 _id , address _address) public {
        //  Distributer_d memory u = Distributer_Detail[_id];
          require(msg.sender == Admin ,"only Admin can run this function ");
        Distributer_Detail[_id].name = _name;
        Distributer_Detail[_id].city = _city;
        Distributer_Detail[_id].country = _country;
            d_AutoId[_address] = _id;

    }
    
     function addRetailer(string memory _name , string memory _city , string memory _country  , uint256 _id , address _address) public {
        //  Retailer_d memory u = Retailer_Detail[_id];
          require(msg.sender == Admin ,"only Admin can run this function ");
        Retailer_Detail[_id].name = _name;
        Retailer_Detail[_id].city = _city;
        Retailer_Detail[_id].country = _country;
        r_AutoId[_address] = _id;

    }


      function addBuyer(string memory _name , string memory _city , string memory _country  , uint256 _id) public {
        //  Manufacture_d memory u = Manufacture_Detail[_id];
         require(msg.sender == Admin ,"only Admin can run this function ");
        Buyer_Detail[_id].name = _name;
        Buyer_Detail[_id].city = _city;
        Buyer_Detail[_id].country = _country;

    }

     function Retailer(
        
          string memory _State,
           string memory In_date,
        string memory Out_date,
        uint256 productid,

        string  memory buyer_id
    ) public {
        tractProject[productid].current_owner = "Retailer";
        tractProject[productid].previous_owner = "Distributer";
        tractProject[productid].Retailer_ID = r_AutoId[msg.sender];
         tractProject[productid].Retailer_State = _State;
          Retailer_Tracking[productid].Out_date = Out_date;
         Retailer_Tracking[productid].In_date = In_date;
         tractProject[productid].buyer_id = buyer_id;
    }
}