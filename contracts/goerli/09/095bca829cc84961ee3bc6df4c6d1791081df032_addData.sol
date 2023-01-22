/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract addData {

    string  public  Car_maker;
      string  public  Dealer_name;
      string  public  Car_year;
      string  public  Estimated_value;
      string  public  Verified_Owner;
      string  public  Vin_number;
      string  public  color_name;
      string  public  Engin_size;
     string  public  fuel_type;
     string  public  no_of_doors;
     string  public  drive_wheel_configuration;
     string  public  cargo_Volume;
     string  public  meet_emission_standard;
    string  public  modal_date;
    string  public  no_of_airbag;
   string  public  Car_location;
    string  public  Car_tax;
    string  public  Image_location;
    string  public  wallet_id;
    string  public  nft_name;



    function enter_Car_maker(string memory _data) public  {
        Car_maker = _data;

    }

     function enter_Dealer_name(string memory _data) public  {
        Dealer_name = _data;

    }

     function enter_Car_year(string memory _data) public  {
        Car_year = _data;

    }

     function enter_Estimated_value(string memory _data) public  {
        Estimated_value = _data;

    }

     function enter_Verified_Owner(string memory _data) public  {
        Verified_Owner = _data;

    }
     function enter_Vin_number(string memory _data) public  {
        Vin_number = _data;

    }
     function enter_color_name(string memory _data) public  {
        color_name = _data;

    }
     function enter_Engin_size(string memory _data) public  {
        Engin_size = _data;

    }



     function enter_fuel_type(string memory _data) public  {
        fuel_type = _data;

    }



     function enter_no_of_doors(string memory _data) public  {
        no_of_doors = _data;

    }
     function enter_drive_wheel_configuration(string memory _data) public  {
        drive_wheel_configuration = _data;

    }
     function enter_cargo_Volume(string memory _data) public  {
        cargo_Volume = _data;

    }


     function enter_meet_emission_standard(string memory _data) public  {
        meet_emission_standard = _data;

    }
     function enter_modal_date(string memory _data) public  {
        modal_date = _data;

    }


    function enter_no_of_airbag(string memory _data) public  {
        no_of_airbag = _data;

    }



     function enter_Car_location(string memory _data) public  {
        Car_location = _data;

    }

     function enter_Car_tax(string memory _data) public  {
        Car_tax = _data;

    }

     function enter_Image_location(string memory _data) public  {
        Image_location = _data;

    }


     function enter_wallet_id(string memory _data) public  {
        wallet_id = _data;

    }

     function enter_nft_name(string memory _data) public  {
        nft_name = _data;

    }
     



}