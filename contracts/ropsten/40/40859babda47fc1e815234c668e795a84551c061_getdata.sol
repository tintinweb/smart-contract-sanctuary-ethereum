/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract getdata {

    address  trainer_add;// the address of trainer
    uint  accuracy;// the accuarcy of the model
    address model;// the model's address of IPFS

    uint public counter;// number of uploader
    address [] public data_trainer_add;
    uint [] public data_accuracy;
    address [] public data_model;


// get the information from trainer
    function get_information(address _trainer_address,uint _accuracy,address model_address )  public {
        trainer_add = _trainer_address;
        accuracy = _accuracy;
        model = model_address;

        data_trainer_add.push() = trainer_add;//push the data into the array
        data_accuracy.push() = accuracy;
        data_model.push() = model;

        counter = counter+1;      // length of array
    }
    
    // to get information of first, second, third result

    uint public first;// the number of first result in the origin array
    uint second;
    uint third;

    address []  x_trainer_add; //store the data for changing
    uint []  x_accuracy;
    address []  x_model;


    // to get the information of the best result first one
    function get_result() public view returns(address best_trainer_add ,uint best_accuracy ,address best_model ) {

        uint x;
        //uint y;
        //uint best_accuracy;
        //address best_trainer_add;
        //address best_model;
        uint num;
        x = data_accuracy[0];

        for( uint i = 0; i < counter; i++ ){
           // y = data_accuracy[i];
            if( x < data_accuracy[i]){

                x = data_accuracy[i];
                num = i;
            }

        }

        //first = num; // record the number of the first result in array







        best_accuracy = x;
        best_trainer_add = data_trainer_add[num];
        best_model = data_model[num];

        return (best_trainer_add,best_accuracy,best_model);
    }


}