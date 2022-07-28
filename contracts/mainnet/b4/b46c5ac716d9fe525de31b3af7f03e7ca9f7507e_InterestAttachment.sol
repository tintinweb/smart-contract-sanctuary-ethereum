/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function transferFrom(address, address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
}

interface IVaultController {
    function repayUSDi(uint96 id, uint192 amount) external;
    function repayAllUSDi(uint96 id) external;
    function vaultBorrowingPower(uint96 id) external view returns (uint192);
    function vaultLiability(uint96 id) external view returns (uint192);
}

contract InterestAttachment {
    IERC20 USDi = IERC20(0x2A54bA2964C8Cd459Dc568853F79813a60761B58);
    IVaultController public VC = IVaultController(0x4aaE9823Fb4C70490F1d802fC697F3ffF8D5CbE3);
    address public admin;
    uint96 public _vaultID;
    uint public _minUP;

    modifier onlyAdmin{
        require(admin == msg.sender, "admin only");
        _;
    }
    //// This contract is an attachment that allows you to use interestprotocol.io with a special feature that lets you automatically
    //// pay off your debt when your UP, or "Utilization Percentage" reaches a certain amount.

    constructor(uint96 vaultID_, uint256 minUP_, address admin_) {
        if (admin_ == address(0x0)) {
            admin = msg.sender;
        } else {
            admin = msg.sender;
        }
        _vaultID = vaultID_;
        _minUP = minUP_;
    }

    function execute() public {
        require(_minUP <= uint(CalculateUP()), "This function cannot be called yet");
        // Send all USDi from the admin to this contract
        USDi.transferFrom(admin, address(this), USDi.balanceOf(admin));
        // If you have enough to pay the entire thing do it, if you don't then just pay what you can
        if(VC.vaultLiability(_vaultID) < USDi.balanceOf(address(this))){
            VC.repayAllUSDi(_vaultID);
        } else {
            VC.repayUSDi(_vaultID, uint192(USDi.balanceOf(address(this))));
        }
        // Send any remaining USDi to the admin
        bool success = USDi.transfer(admin, USDi.balanceOf(address(this)));
        require(success, "erc20 transfer failed");
    }

    // You can withdraw extra ETH held by this contract using this function
    function sweep() public onlyAdmin{
        (bool sent,) = admin.call{value: (address(this)).balance}("");
        require(sent, "transfer failed");
    }

    // You can withdraw extra tokens held by this contract using this function
    function sweepToken(IERC20 token_) public onlyAdmin{
        bool success = token_.transfer(admin, token_.balanceOf(address(this)));
        require(success, "erc20 transfer failed");
    }

    // a function that calculates the UP of your vault
    function CalculateUP() public view returns (uint192) {
        uint192 vaultLiability = VC.vaultLiability(_vaultID);
        uint192 vaultBorrowingPower = VC.vaultBorrowingPower(_vaultID);
        // Your UP
        return uint192(uint256(vaultLiability * 100) / vaultBorrowingPower);
    }

    // Functions that let you change values like the trigger UP or the vault ID this contract reads

    function EditTriggerUP(uint amount_) public onlyAdmin {
        _minUP = amount_;
    }
    function EditVaultID(uint96 id_) public onlyAdmin{
        _vaultID = id_;
    }
}