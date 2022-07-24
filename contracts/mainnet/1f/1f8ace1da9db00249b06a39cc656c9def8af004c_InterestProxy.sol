/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
// https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

contract InterestProxy{

//// This contract is an attachment that allows you to use interestprotocol.io with a special feature that lets you automatically 
//// pay off your debt when your LTV reaches a certain amount.

    // How to setup this contract

    // Step 1: Configure the contstructor to the values you want, make sure to double and triple check!
    // Step 2: Deploy the contract.
    // Step 3: Manually approve USDi for use on this contract using a block explorer.
    // Step 4: Go to https://app.gelato.network/new-task to hook up this contract with gelato, set it to activate "whenever possible"
    // Step 5: Gelato should already tell you this, but make sure you give enough ETH to their vault so it can activate this contract when it needs to


//// Commissioned by Fishy#0007 on 6/17/2022

    // the constructor that activates when you deploy the contract, this is where you change settings before deploying.

    constructor(){

        admin = msg.sender;
        VaultID = 27; // <------- MAKE SURE THIS IS RIGHT!!!!!!!
        MINLTV = 80;
    }

//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////

    // The ERC20 token and the Vault controller:

    ERC20 USDi = ERC20(0x203c05ACb6FC02F5fA31bd7bE371E7B213e59Ff7);
    VaultController public Vault = VaultController(0x385E2C6b5777Bc5ED960508E774E4807DDe6618c);

    // All other variables

    address public admin;
    uint96 public VaultID;
    uint public bounty;
    uint public MINLTV;

    // And modifiers

    modifier onlyAdmin{

        require(admin == msg.sender, "You can't call this admin function because you are not the admin (duh)");
        _;
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    function execute() public{

        require(MINLTV <= uint(CalculateLTV()), "This function cannot be called yet");

        // Send all USDi from fishy to this contract

        USDi.transferFrom(admin, address(this), USDi.balanceOf(admin));

        // If you have enough to pay the entire thing do it, if you don't then just pay what you can

        if(Vault.vaultLiability(VaultID) < USDi.balanceOf(address(this))){Vault.repayAllUSDi(VaultID);}
        else{Vault.repayUSDi(VaultID, uint192(USDi.balanceOf(address(this))));}

        // Send any remaining USDi to fishy

        USDi.transfer(admin, USDi.balanceOf(address(this)));
    
    }

    // You can withdraw extra ETH held by this contract using this function

    function sweep() public onlyAdmin{

        (bool sent,) = admin.call{value: (address(this)).balance}("");
        require(sent, "transfer failed");
    }

    // You can withdraw extra tokens held by this contract using this function

    function sweepToken(ERC20 WhatToken) public onlyAdmin{

        WhatToken.transfer(admin, WhatToken.balanceOf(address(this)));
    }

    // a function that calculates the LTV of your vault

    function CalculateLTV() public view returns(uint192){

        // MAXLTV = maximum amount of USDi a vault can borrow
        // FULLLTV = How much USDi your collateral is worth (Also 100% LTV)

        uint192 MAXLTV = Vault.vaultLiability(VaultID) + Vault.vaultBorrowingPower(VaultID);
        uint192 FULLLTV = (1176470588235294 * MAXLTV)/10e15;

        // Your LTV

        return (Vault.vaultLiability(VaultID)*10)/FULLLTV;
    }

    // Functions that let you change values like the trigger LTV or the vault ID this contract reads

    function EditTriggerLTV(uint HowMuch) public onlyAdmin{MINLTV = HowMuch;}
    function EditVaultID(uint96 WhatID) public onlyAdmin{VaultID = WhatID;}
}

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

interface ERC20{

    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function approve(address, uint) external;
}

interface VaultController{

    function repayUSDi(uint96 id, uint192 amount) external;
    function repayAllUSDi(uint96 id) external;
    function vaultBorrowingPower(uint96 id) external view returns (uint192);
    function vaultLiability(uint96 id) external view returns (uint192);
}