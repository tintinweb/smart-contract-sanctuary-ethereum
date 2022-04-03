/**
 *Submitted for verification at Etherscan.io on 2022-04-03
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

    uint endtime = 30000;// the time of getting information from trainer
    uint get_information_end = block.timestamp + endtime;

    mapping(address => uint) depositReturns;// store the deposit of each trainer



// get the information from trainer
    function get_information(address _trainer_address,uint _accuracy,address model_address ) payable public {
        require(
            block.timestamp <= get_information_end,
            "Get Information End"
        );

        // everytime write information in the contract, trainer pay ether to the contract as deposit, when end, will back 
        payable(address(this)).transfer(0.0001 ether) ; 

        depositReturns[msg.sender] = 1;// take 1 as example, store
        

        trainer_add = _trainer_address;
        accuracy = _accuracy;
        model = model_address;

        data_trainer_add.push() = trainer_add;//push the data into the array
        data_accuracy.push() = accuracy;
        data_model.push() = model;

        counter = counter+1;      // length of array
    }
    
 
    // to get the information of the best result first one
   function best_result() public view returns(address best_trainer_add,uint best_accuracy,address best_model) {
        uint first;
        uint x;
        uint num;
        x = data_accuracy[0];

        for( uint i = 0; i < data_accuracy.length; i++ ){
            if( x < data_accuracy[i]){
                x = data_accuracy[i];
                num = i;
            }
        }

        first = num; // record the number of the first result in array
        best_accuracy = x;
        best_trainer_add = data_trainer_add[first];
        best_model = data_model[first];

        return (best_trainer_add,best_accuracy,best_model);
    }

 
// to get the second result
  function second_result() public view returns(address second_trainer_add,uint second_accuracy,address second_model) {

        uint first;
        uint second;

        uint x;
        x = data_accuracy[0];

        for( uint i = 0; i < data_accuracy.length; i++ ){
            if( x < data_accuracy[i]){
                x = data_accuracy[i];
                first = i;
            }
        }


        // get the second result
        uint y;
        y =data_accuracy[0]; 

        for( uint i = 0; i < data_accuracy.length; i++ ){
            if(i != first){
              if( y < data_accuracy[i]){

                y = data_accuracy[i];
                second = i;
              }
            }
        }

        second_accuracy = y;
        second_trainer_add = data_trainer_add[second];
        second_model = data_model[second];

        return (second_trainer_add,second_accuracy,second_model);
    }




// to get the third result
  function third_result() public view returns(address third_trainer_add,uint third_accuracy,address third_model) {
      

        uint first;
        uint second;
        uint third;

        // get first
        uint x;
        x = data_accuracy[0];

        for( uint i = 0; i < data_accuracy.length; i++ ){
            if( x < data_accuracy[i]){
                x = data_accuracy[i];
                first = i;
            }
        }

        // get the second 
        uint y;
        y =data_accuracy[0]; 
       for( uint i = 0; i < data_accuracy.length; i++ ){
            if(i != first){
                if( y < data_accuracy[i]){
                    y = data_accuracy[i];
                    second = i;
              }
            }
        }

        // get the third 
        uint z;
        z =data_accuracy[0]; 
       for( uint i = 0; i < data_accuracy.length; i++ ){
            if(i != first){
                if(i != second){
                    if( z < data_accuracy[i]){
                        z = data_accuracy[i];
                        third = i;
                }
              }
            }
        }
        
        third_accuracy = z;
        third_trainer_add = data_trainer_add[third];
        third_model = data_model[third];

        return (third_trainer_add,third_accuracy,third_model);
    }






// withdraw the deposit of trainer except the first, second, third one
    function withdraw() public returns (bool) {
        // add a time limit
        
        // get the first, second, third result address

        uint first;
        uint second;
        uint third;

        // get first
        uint x;
        x = data_accuracy[0];

        for( uint i = 0; i < data_accuracy.length; i++ ){
            if( x < data_accuracy[i]){
                x = data_accuracy[i];
                first = i;
            }
        }

        // get the second 
        uint y;
        y =data_accuracy[0]; 
       for( uint i = 0; i < data_accuracy.length; i++ ){
            if(i != first){
                if( y < data_accuracy[i]){
                    y = data_accuracy[i];
                    second = i;
              }
            }
        }

        // get the third 
        uint z;
        z =data_accuracy[0]; 
       for( uint i = 0; i < data_accuracy.length; i++ ){
            if(i != first){
                if(i != second){
                    if( z < data_accuracy[i]){
                        z = data_accuracy[i];
                        third = i;
                }
              }
            }
        }






        uint amount = depositReturns[msg.sender];
        //address payable x_address = msg.sender;
        //address y_address = x_address;

        if(msg.sender != data_trainer_add[first]){
            if(msg.sender != data_trainer_add[second]){
                if(msg.sender != data_trainer_add[third]){
                     if (amount > 0) {
                         depositReturns[msg.sender] = 0;                          
                        // once the trainer get back the deposit, the amount becomes 0
                         if (!payable(msg.sender).send(amount)) {
                             depositReturns[msg.sender] = amount;
                             return false;
                            }
                        }
                     return true;

                }
                return true;

            }
            return true;
        }
        return true;
    }


    function get_testdata() public view returns (string memory testdata) {
        require(
            block.timestamp >= get_information_end,
            "Write Information is not Ended"
        ) ;      

        testdata = "Qmbks1p1swhfpCTM5v24VE7WwriLke2bxmn3kAS3YGeCQ6" ;

        return testdata;
    }

    


    
}