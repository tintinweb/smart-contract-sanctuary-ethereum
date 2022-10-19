/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: GPL-3.0
// @title A contract that represents a VIP Pass
// @author David Liu, Founder of dApp Technology Inc.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title VipPass
 * @dev Digital Vip Pass
 */
contract VipPass {

    address public admin;

    // (minter => isMinter)
    mapping(address => bool) public isMinter;

    // (holder => balance)
    mapping(address => uint256) public balanceOf;

    // (account => (approvedSpender => isApproved))
    mapping(address => mapping(address => bool)) public isApproved;

    event Transfer(address indexed sender, address indexed receiver, uint256 amt);


    /**
     * @dev Sets the admin that manages the VIP Passes
     * @param _admin the admin who manages the VIP Passes
     */
    constructor(address _admin) {
        admin = _admin;
        isMinter[admin] = true;
    }

    /**
     * @dev Mints new VIP Passes to an account
     * @param receiver the account that receives the newly minted VIP Passes
     * @param mintAmt the amt of VIP Passes to mint
     */
    function mint(address receiver, uint256 mintAmt) public {
        require(isMinter[msg.sender], "Caller does not have minting rights");

        balanceOf[receiver] += mintAmt;

        emit Transfer(address(0), receiver, mintAmt);
    }

    /**
     * @dev Tranfer VIP Passes from the caller's account to another account
     * @param sender the sender of the VIP Pass transfer
     * @param receiver the receiver of the VIP Pass transfer
     * @param transferAmt the amt of VIP Passes to transfer
     */ 
    function transfer(address sender, address receiver, uint256 transferAmt) public {
        require(sender == msg.sender || isApproved[sender][msg.sender], "Transfer not allowed");

        balanceOf[sender] -= transferAmt;
        balanceOf[receiver] += transferAmt;

        emit Transfer(sender, receiver, transferAmt);
    }

    /**
     * @dev Set Minter Permissions
     * @param minter the target minter
     * @param _isMinter whether or not the minter had minting rights
     */
    function manageMinters(address minter, bool _isMinter) public {
        require(msg.sender == admin, "Caller is not admin");

        isMinter[minter] = _isMinter;
    }

    /**
     * @dev Set the approval permission of tranferring VIP Passes for caller's account
     * @param spender the target account that can havce permission to transfer caller's VIP Passes
     * @param _isApproved whether or not the spender is approved
     */
    function approveSpender(address spender, bool _isApproved) public {
       isApproved[msg.sender][spender] = _isApproved;
    } 

}