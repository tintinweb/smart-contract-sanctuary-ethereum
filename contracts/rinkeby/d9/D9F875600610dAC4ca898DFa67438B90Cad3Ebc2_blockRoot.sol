/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract blockRoot{

    struct Data{
        string name;
        string origin;
        string businessName;
        string product;
        string batch;
        string packing;
        uint amount;
        address wallet;
    }

    Data public data;

    event newData(string name,
                  string origin,
                  string businessName,
                  string product,
                  string batch,
                  string packing,
                  uint amount,
                  address wallet);

    function pushData(string memory _name,
                      string memory _origin, 
                      string memory _businessName,
                      string memory _product,
                      string memory _batch,
                      string memory _packing,
                      uint _amount) public {
        
        data = Data(_name,
                    _origin,
                    _businessName,
                    _product,
                    _batch,
                    _packing,
                    _amount,
                    msg.sender);

        emit newData(_name,
                     _origin,
                     _businessName,
                     _product,
                     _batch,
                     _packing,
                     _amount,
                     msg.sender);
    }

}