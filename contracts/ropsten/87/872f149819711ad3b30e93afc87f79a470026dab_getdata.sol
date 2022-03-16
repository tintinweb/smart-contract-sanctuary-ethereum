/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract getdata {

    uint counter;// number of uploader

    address  trainer_add;// the address of trainer
    uint  accuracy;// the accuarcy of the model
    address model;// the model's address of IPFS

    address [] public data_trainer_add;
    uint [] public data_accuracy;
    address [] public data_model;
    uint public number;

// get the infomation from trainer
    function get_trainer_add(address _trainer_address,uint _accuracy,address model_address )  public {
        trainer_add = _trainer_address;
        accuracy = _accuracy;
        model = model_address;

        data_trainer_add.push() = trainer_add;//push the data into the array
        data_accuracy.push() = accuracy;
        data_model.push() = model;

        counter = counter+1;      // length of array
    }

    function best_result() public view returns(address ,uint ,address ) {

        uint x;
        //uint y;
        uint best_accuracy;
        address best_trainer_add;
        address best_model;
        uint num;
        x = data_accuracy[0];

        for( uint i = 0; i < counter; i++ ){
           // y = data_accuracy[i];
            if( x < data_accuracy[i]){

                x = data_accuracy[i];
                num = i;
            }


        }
        best_accuracy = x;
        best_trainer_add = data_trainer_add[num];
        best_model = data_model[num];
        return (best_trainer_add,best_accuracy,best_model);
    }

}