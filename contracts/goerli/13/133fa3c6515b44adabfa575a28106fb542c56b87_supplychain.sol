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
        string Manufacturer_ID ;
        string Distributor_ID ;
        string Retailer_ID ;
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
        string memory  manufacture_id,
        string memory mgf_date,
        string memory exp_date,
        string memory _State,
        string memory _Out_date,
         uint256 productid
    ) public {
        tractProject[productid].current_owner = "Manufacture";
        tractProject[productid].previous_owner = "Manufacture";
        tractProject[productid].Manufacturer_ID = manufacture_id;
        tractProject[productid].exp_date = exp_date;
         tractProject[productid].mgf_date = mgf_date;
         Manufacture_Tracking[productid].Out_date = _Out_date;
         tractProject[productid].Manufacturer_State = _State;
        //  tractProject[productid].productid = productid;
    }

    function Distributer(
        string memory Distributer_id,
        string memory _State,
        string memory In_date,
        string memory Out_date,
         uint256 productid

    ) public {
        tractProject[productid].current_owner = "Distributer";
        tractProject[productid].previous_owner = "Manufacture";
        tractProject[productid].Distributor_ID = Distributer_id;
        tractProject[productid].Distributer_State = _State;
        Distributor_Tracking[productid].Out_date = Out_date;
         Distributor_Tracking[productid].In_date = In_date;
        //  tractProject[productid].productid = productid;
    }

        function addManufacture(string memory _name , string memory _city , string memory _country  , uint256 _id) public {
        //  Manufacture_d memory u = Manufacture_Detail[_id];
         require(msg.sender == Admin ,"only Admin can run this function ");
        Manufacture_Detail[_id].name = _name;
        Manufacture_Detail[_id].city = _city;
        Manufacture_Detail[_id].country = _country;

    }




     function addDistributer(string memory _name , string memory _city , string memory _country  , uint256 _id) public {
        //  Distributer_d memory u = Distributer_Detail[_id];
          require(msg.sender == Admin ,"only Admin can run this function ");
        Distributer_Detail[_id].name = _name;
        Distributer_Detail[_id].city = _city;
        Distributer_Detail[_id].country = _country;

    }
    
     function addRetailer(string memory _name , string memory _city , string memory _country  , uint256 _id) public {
        //  Retailer_d memory u = Retailer_Detail[_id];
          require(msg.sender == Admin ,"only Admin can run this function ");
        Retailer_Detail[_id].name = _name;
        Retailer_Detail[_id].city = _city;
        Retailer_Detail[_id].country = _country;

    }


      function addBuyer(string memory _name , string memory _city , string memory _country  , uint256 _id) public {
        //  Manufacture_d memory u = Manufacture_Detail[_id];
         require(msg.sender == Admin ,"only Admin can run this function ");
        Buyer_Detail[_id].name = _name;
        Buyer_Detail[_id].city = _city;
        Buyer_Detail[_id].country = _country;

    }

     function Retailer(
        string memory Retailer_id,
          string memory _State,
           string memory In_date,
        string memory Out_date,
        uint256 productid,

        string  memory buyer_id
    ) public {
        tractProject[productid].current_owner = "Retailer";
        tractProject[productid].previous_owner = "Distributer";
        tractProject[productid].Retailer_ID = Retailer_id;
         tractProject[productid].Retailer_State = _State;
          Retailer_Tracking[productid].Out_date = Out_date;
         Retailer_Tracking[productid].In_date = In_date;
         tractProject[productid].buyer_id = buyer_id;
    }
}