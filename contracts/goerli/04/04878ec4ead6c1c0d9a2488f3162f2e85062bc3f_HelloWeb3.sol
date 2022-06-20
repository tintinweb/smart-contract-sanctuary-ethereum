/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
contract HelloWeb3{
    string public _string_0 = "My first step!";
    string public _string_1 = "Goal, creat an shit nft in the next bull! ";

    struct detail_address{
        address paid_address;
        uint paid_max_wei;
        uint leave_wei;
        bool exists;
    }
    event addressADD(uint indexed id, address paid_address, uint paid_max_wei);
    detail_address[]  transfer_address;
    function Paytome(uint address_id) external payable returns(address sender, uint256 balance,uint256 gas){
        balance=address(this).balance;
        address  sender_address=msg.sender;
        uint gas_limit=block.gaslimit;
        if(msg.value>0){

            if(address_id<transfer_address.length){
                if(transfer_address[address_id].paid_address==msg.sender){
                    transfer_address[address_id].paid_max_wei=transfer_address[address_id].paid_max_wei+msg.value;
                    transfer_address[address_id].leave_wei=transfer_address[address_id].leave_wei+msg.value;
                    emit addressADD(address_id,msg.sender,transfer_address[address_id].paid_max_wei);
                }else{
                    revert('error address_id, you are not the id holder');
                }
                }else{
                    detail_address memory detail_address0=detail_address(msg.sender,msg.value,msg.value,true);
                    transfer_address.push(detail_address0);
                    uint id = transfer_address.length-1;
                    emit addressADD(id,msg.sender,msg.value);
                }
        }
 
        return (sender_address, balance,gas_limit);
    }
    function backtoyou(address payable send_address,uint address_id,uint send_wei_value) external payable returns(uint256,uint256){
        if(send_wei_value>0 ){
            if(address_id<transfer_address.length){
                if(transfer_address[address_id].paid_address==msg.sender){
                    if(transfer_address[address_id].leave_wei-block.gaslimit>=send_wei_value){
                        if(address(this).balance-block.gaslimit>send_wei_value){
                            send_address.transfer(send_wei_value-block.gaslimit);
                            transfer_address[address_id].leave_wei=transfer_address[address_id].leave_wei-send_wei_value;
                        }else{
                            revert("contract not have enough wei");
                        }
                    }else{
                        revert("your leave value is lower than your try to send");
                    }
                }else{
                    revert("your id  wrong");
                }
            }
        }
        return(address(this).balance,transfer_address[address_id].leave_wei);
    }
    function get_address_id(address find_address) view external returns(uint address_id){
        for(uint i; i<transfer_address.length;i++){
            if (transfer_address[i].paid_address==find_address){
                return(i);
            }
        }
    }
    }