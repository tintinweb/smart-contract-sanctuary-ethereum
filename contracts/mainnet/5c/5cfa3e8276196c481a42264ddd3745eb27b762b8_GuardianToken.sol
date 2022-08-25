/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Guardian Token
 * @dev This is the token of the Guardians of the Galaxy project.
 */
contract GuardianToken {


    /* Owner */
    // The DAO or multisig which is allowed to mint
    address public owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; 
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    /* ERC20 */
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Guardian";
    string public symbol = "GUARD";
    uint8 public decimals = 18;

    /**
     * @dev Transfer tokens.
     * @param recipient The recipient of the tokens.
     * @param amount The amount to transfer.
     */
    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Approve another account to spend tokens.
     * @param spender The account to be allowed the spending of tokens.
     * @param amount The amount of tokens which can be spent.
     */
    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfer tokens on behalf of another account.
     * @param sender The account the tokens should be sent from.
     * @param recipient The account to receive the tokens.
     * @param amount The amount of tokens to send.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /** @dev Creates tokens.
      * @param account Account to receive the tokens.
      * @param amount Amount of tokens to assign.
     */
    function mint(address account, uint256 amount) external isOwner {
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }


}