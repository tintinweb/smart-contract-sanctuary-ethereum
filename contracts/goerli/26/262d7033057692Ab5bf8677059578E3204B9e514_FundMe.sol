// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;



error FundMe__OnlyOwner();
error FundMe__NotEnoughFundsToWithdraw();
error FundMe__TransactionFailed();


contract FundMe {

    address private immutable i_owner;

    // The amount of funds donated by an address

    mapping(address => uint256) private donations;
    address[] private donators;

    constructor() {

        i_owner = msg.sender;

    } // end constructor


    receive() external payable {

        fund();

    } // end receive()


    fallback() external payable {


    } // end fallback()


    /**
     * @notice A function to fund the contract.
     */
    function fund() public payable {

        uint256 amountDonated = donations[msg.sender];

        if (amountDonated == 0) {

            donators.push(msg.sender);

        } // end if

        amountDonated += msg.value;

        // Update the information in storage

        donations[msg.sender] = amountDonated;

    } // end fund()


    /**
     * @notice This is a function to withdraw all the funds from a contract,
     *         can be called only by the contract owner.
     */
    function withdraw() public onlyOwner {

        // Check if there are funds to withdraw

        if (address(this).balance == 0) {

            // Revert the transaction

            revert FundMe__NotEnoughFundsToWithdraw();

        } // end if

        // Remove all the contributors

        delete donators;

        // Send all the funds

        (bool success,) = payable(msg.sender).call{ value: address(this).balance }("");

        // Check if the funds were not sent successfully, then revert the transaction

        if (success == false) {

            // Revert the transaction

            revert FundMe__TransactionFailed();

        } // end if

    } // end withdraw()


    // Getter functions

    /**
     * @notice A function to get the contract owner.
     */
    function getContractOwner() public view returns(address) {

        return i_owner;

    } // end getContractOwner()


    /**
     * @notice A function to get all the donators to a contract.
     */
    function getAllDonators() public view returns(address[] memory) {

        return donators;

    } // end getAllDonators()


    /**
     * @notice A function to get the amount of funds donated by an address.
     * 
     * @param _address Address to check the amount of funds donated by.
     */
    function getAmountDonated(address _address) public view returns(uint256) {

        return donations[_address];

    } // end getAmountDonated()


    /**
     * @notice A function which returns the total value donated to a contract.
     */
    function getTotalValueDonated() public view returns(uint256) {

        return address(this).balance;

    } // end getTotalValueDonated()


    // Modifiers


    /**
     * @notice A modifier to check if a function is called by the contract owner.
     */
    modifier onlyOwner() {

        // Check if it the owner of a contract
        
        if (msg.sender != i_owner) {

            // Revert the transaction
            
            revert FundMe__OnlyOwner();

        } // end if

        _;

    } // end onlyOwner()

} // end FundMe