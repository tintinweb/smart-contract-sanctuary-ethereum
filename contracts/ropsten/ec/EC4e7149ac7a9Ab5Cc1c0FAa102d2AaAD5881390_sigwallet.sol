/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: GPL-3.0

//sigwallet IPFS project
//@dev https://github.com/anthonybudd/VIPFS
//@dev quicknode API service
//@dep Node.js® 16.4.2

pragma solidity >=0.4.16 <0.9.0;

contract sigwallet{
    uint public totalfunds;
    address mainowner;
    address public beneficiary;
    uint public sendamount;
    mapping(address => bool) public owners;
    uint public totalowners;
    address[] whosign;
    uint public totalsigns = 0;
    address[] whoresetbeneficiary;
    uint public totalreset = 0;
    uint public maxsigns = 1;

    constructor() public{
        owners[msg.sender] = true;
        mainowner = msg.sender;
        totalowners = 1;
    }

    function getEther() public payable{
        totalfunds += msg.value;
    }

    function setBeneficiary(address to, uint amount) public{
        require(owners[msg.sender] == true,"no owner");
        require(totalsigns == 0,"can't reset, one owner sign the transaction");
        require(to != address(0),"recipient address not valid");
        beneficiary = to;
        sendamount  = amount;
    }

    function resetBeneficiary() public{
        require(owners[msg.sender] == true,"no owner");
        bool signedbefore = false;
        for(uint i; i < whoresetbeneficiary.length; i++){
            if(whoresetbeneficiary[i] == msg.sender){
                signedbefore = true;
            }
        }
        require(signedbefore == false, "already sign");
        totalreset += 1;
        if(maxsigns == totalreset){
            beneficiary = address(0);
            sendamount = 0;
            totalreset = 0;
        }
        if(maxsigns < totalreset){
            totalreset = 0;
        }
    }

    function signAndSend(address to) public{
        require(owners[msg.sender] == true,"no owner");
        require(beneficiary == to ,"recipient must be same");
        bool signedbefore = false;
        for(uint i; i < whosign.length; i++){
            if(whosign[i] == msg.sender){
                signedbefore = true;
            }
        }
        require(signedbefore == false, "already sign");
        sign();
        if(maxsigns == totalsigns){
            reset();
            require(address(this).balance >= sendamount, "balance is not sufficient");
            require(beneficiary.send(sendamount), "can't transfer");
            totalfunds -= sendamount;
        }
        if(maxsigns < totalsigns){
            reset();
        }
    }

    function sign(){
        totalsigns += 1;
        whosign.push(msg.sender);
    }

    function reset(){
        totalsigns = 0;
        for(uint i=0; i < whosign.length;i++){
            delete whosign[i];
        }
    }

    function addOwner(address owner) public{
        require(mainowner == msg.sender, "no mainowner");
        require(owners[msg.sender] == true,"no owner");
        owners[owner] = true;
        totalowners += 1;
    }

    function removeOwner(address owner) public{
        require(owner != mainowner, "can't remove the mainowner");
        require(mainowner == msg.sender, "no mainowner");
        require(owners[msg.sender] == true,"no owner");
        require(maxsigns < totalowners,"maxsign must less than the total owners");
        owners[owner] = false;
        totalowners -= 1;
    }

    function changeMaxSign(uint num) public{
        require(mainowner == msg.sender, "no mainowner");
        require(num >=1 && num <= totalowners,"maxsign must be up to 0 & less or equal than the total owners");
        require(owners[msg.sender] == true,"no owner");
        maxsigns = num;
    }
}