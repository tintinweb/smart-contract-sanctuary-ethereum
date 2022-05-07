/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// Part: OpenZeppelin/[email protected]/IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// Part: Owned

/*
* @title: 
* @author: Anthony (fps) https://github.com/fps8k .
* @dev: 
*/

contract Owned
{
    address internal contract_owner;

    event MoveOwnership(address, address);




    /*
    * @dev:
    *
    * Initializes the `contract_owner` to whoever deployed the contract.
    */

    constructor()
    {
        contract_owner = msg.sender;  
        emit MoveOwnership(address(0), msg.sender);
    }




    /*
    * @dev:
    *
    * Validates that `msg.sender` is the contract owner.
    */

    modifier isOwner()
    {
        require(msg.sender == contract_owner, "!Owner");
        _;
    }




    /*
    * @dev:
    *
    * Moves ownership of conract from `contract_owner` to `new_contract_owner`.
    * 
    *
    * @param:
    * 
    * address new_contract_owner.
    */

    function moveOwnership(address new_contract_owner) public isOwner
    {
        require(new_contract_owner != address(0), "0 Address");
        contract_owner = new_contract_owner;
        emit MoveOwnership(msg.sender, new_contract_owner);
    }
}

// File: Covered.sol

/*
* @title: Sellable smart contract, funded with tokens.
* @author: Anthony (fps) https://github.com/fps8k .
* @dev: 
* This smart contract involves an contract_owner depositing tokens into the smart contract, then he can list the smart contract for sale.
* The buyer then purchases the smart contract and can take the tokens in the smart contract.
*
* O W N   C O N T R A C T .
* D E P O S I T   T O K E N S   I N   T H E   C O N T R A C T .
* L I S T   T H E   C O N T R A C T   F O R   S A L E.
* B U Y   C O N T R A C T   A N D   B E C O M E   O W N E R.
* W I T H D R A W   T O K E N S.
*/

contract Sellable is Owned
{
    // isOwner from Owned.


    // Toggle for the sale and non-sale of the contract.

    bool private on_sale = false;


    // The highest bid, highest bidder.

    uint256 private highest_bid;
    address private highest_bidder;

    uint256 private contract_price;
    uint256 private stored_contract_tokens;

    IERC20 token = IERC20(0xB57ee0797C3fc0205714a577c02F7205bB89dF30);




    /*
    * @dev:
    *
    * Checks if the token to be stored in the contract passes 2 tests:
    *
    * -> The current token must be none.
    * -> The new token to be added must be the same with the existing token.
    *
    * Returns true if one of the conditions is met.
    * 
    *
    * @param:
    *
    * IERC20 __token.
    * 
    *
    * @return:
    * 
    * bool.
    */

    function canDeposit(IERC20 __token) public view returns(bool)
    {
        bool is_empty = (address(token) == address(0));
        bool is_same_token = (token == IERC20(__token));
        
        return (is_empty || is_same_token);
    }




    /*
    * @dev:
    *
    * Allows the `contract_owner` of the contract to deposit some of his tokens into the contract.
    * Only the `contract_owner` of the contract can deposit tokens.
    *
    * The `contract_owner` must have some allowance given to himself on the tokens he wants to deposit.
    * The contract must not be on sale for this function to be called.
    *
    * There cannot be two different tokens in the account.
    * 
    *
    * @param:
    *
    * address __token, uint256 _amount.
    */

    function depositTokens(address _token, uint256 _amount) public isOwner
    {
        require(!on_sale, "Contract is on sale");
        require(_token != address(0), "Zero token address");
        require(canDeposit(IERC20(_token)), "You cannot have 2 different tokens in this contract, Withdraw existing tokens.");

        token = IERC20(_token);


        // Token holder will give contract some allowance.

        require(token.allowance(msg.sender, address(this)) >= _amount, "You don't have enough allowance tokens.");
        token.transferFrom(msg.sender, address(this), _amount);

        stored_contract_tokens += _amount;
    }




    /*
    * @dev:
    *
    * The contract must not be on sale for this function to be called.
    * This allows the contract_owner to place a price on his contract.
    * The maximum allowed for contract sale is 8 ether.
    * Turns on `on_sale` to true.
    *
    * The contract must have a minimum of tokens before it can be listed for sale, say 100.
    * 
    *
    * @param:
    *
    * uint256 _amount.
    */

    function placeOnSaleInGwei(uint256 _amount) public isOwner
    {
        require(!on_sale, "Contract is for sale at the moment.");                           // Req on_sale == False;
        require(stored_contract_tokens >= 50, "There must be a minimum of 100 tokens to list contract on sale.");
        require(_amount <= 8 ether, "Amount must be <= 8 ether.");
        on_sale = !on_sale;
        contract_price = _amount;
    }




    /*
    * @dev:
    * 
    * Allows anyone to bid as long as their bid >= contract price and > highest bid standing set in the placeOnSaleInGwei.
    * The contract must be on sale.
    * Bidder cannnot be a 0 address.
    * Msg.value must be >= contract price and > highest_bid.
    *
    * This pays back the amount the old highest bidder had.
    * New highest bidder and new highest bid replaces the old spots.
    */

    function bidContract() public payable
    {
        require(on_sale, "Contract is not for sale at the moment.");                        // Req on_sale == True;
        require(msg.sender != address(0), "Txn from 0 address.");
        require(msg.sender != contract_owner, "You cannot bid your contract.");
        require(msg.value > 0, "Price <= 0");
        require(msg.value >= contract_price, "Bid < Contract price.");
        require(msg.value > highest_bid, "Yours isn't the highest, it is unaccepted.");


        if (highest_bid > 0 && highest_bidder != address(0))
            payable(highest_bidder).transfer(highest_bid);

            delete highest_bidder;
            delete highest_bid;


        highest_bid = msg.value;
        highest_bidder = msg.sender;
    }




    /*
    * @dev:
    *
    * Sells the contract to the highest bidder.
    * Makes the highest bidder the contract_owner.
    * Sets the on sale to false.
    */

    function sellContract() public isOwner
    {
        require(on_sale, "Not on sale");                                            // Req on_sale == True;
        require(highest_bid > 0, "No bids yet.");
        require(highest_bidder != address(0), "No bidder yet.");

        address old_contract_owner = contract_owner;

        payable(contract_owner).transfer(highest_bid);
        moveOwnership(highest_bidder);

        delete highest_bidder;
        delete highest_bid;
        
        on_sale = !on_sale;                                                         // on_sale == False;

        emit MoveOwnership(old_contract_owner, contract_owner);
    }




    /*
    * @dev:
    *
    * Cancels the sale and repays the current highest bidder.
    */

    function revokeSale() public isOwner
    {
        require(on_sale, "Contract not on sale.");
        on_sale = !on_sale;

        if (highest_bid > 0 && highest_bidder != address(0))
            payable(highest_bidder).transfer(highest_bid);

        delete highest_bidder;
        delete highest_bid;
    }




    /*
    * @dev:
    *
    * Allows the token owner to withdraw the tokens he has put in the contract.
    * OR
    * Allows the token owner to withdraw the tokens stored in the contrat after purchase.
    */

    function withdrawTokens() public isOwner
    {
        require(!on_sale, "Contract is on sale.");
        require(stored_contract_tokens > 0, "This contract has no stored tokens");

        token.transfer(msg.sender, stored_contract_tokens);

        delete token;
    }
}