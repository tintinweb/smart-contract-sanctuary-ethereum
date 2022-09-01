/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: sustainee.sol


pragma solidity ^0.8.13;



contract mappingSimplified is Ownable {
    uint public platform_fee;
    bool public is_contract_active;


    constructor(uint _platform_fee, bool _is_contract_active){
        platform_fee = _platform_fee;
        is_contract_active = _is_contract_active;

    }

    struct Quotation {
        string id;
        address initiator;
        address payable receiver;
        uint amount_received;
        uint fee_paid;
        uint amount_withdrawn;
        uint goal_amount;

        bool is_paused;
        bool is_paused_sustainee;
        bool is_closed;
    }

    mapping (string => Quotation) quotation;
    mapping(string => mapping(address => uint)) public donatorDonation;

    // -------MODIFIERS-------

    modifier isQuotationOwner(string calldata _id){
        require((msg.sender == quotation[_id].initiator || msg.sender == quotation[_id].receiver), 'unauthorized');
        _;
    }


    modifier isQuotationActive(string calldata _id){
        require(quotation[_id].is_paused, 'Quotation Paused By Owner');
        require(quotation[_id].is_paused, 'Quotation Paused By Sustainee');
        _;
    }


    modifier isWithdrawAmountMoreThanFee(string calldata _id){
        require(quotation[_id].amount_received > platform_fee, 'Not Enough Funds to Withdraw');
        _;
    }

    modifier isContractActive(){
        require(is_contract_active, 'Contract not active');
        _;
    }

    modifier isWithdrawn(string calldata _quotation_id){
        require(quotation[_quotation_id].is_closed, "Withdraw");
        _;
    }


    // -------SET FUNCTIONS-------
    function pauseUnpauseContract(bool state) public onlyOwner{
        is_contract_active = state;
    }


    function setQuotation(
    string calldata _id, 
    address payable _receiver, 
    uint _goal_amount) public isContractActive{
        quotation[_id] = Quotation(_id, msg.sender, _receiver,  0, 0 , 0, _goal_amount, false, false, false);
    }

    function changeQuotationPrice(uint fee) public onlyOwner{
        platform_fee = fee;
    }

    function sustaineePauseQuotation(
        string calldata _id, bool state
    ) public onlyOwner {
        quotation[_id].is_paused_sustainee = state; // true untrue
    }


    function pauseQuotation(
        string calldata _id, bool state) public 
        isContractActive isQuotationOwner(_id)  isWithdrawn(_id){
         quotation[_id].is_paused = state; //true untrue
    }

    // Donation

    function Water(
        string calldata _farm_id) public payable isQuotationActive(_farm_id)  isWithdrawn(_farm_id) {
        donatorDonation[_farm_id][msg.sender] = donatorDonation[_farm_id][msg.sender] + msg.value;
        quotation[_farm_id].amount_received += msg.value;
    }


    function farmerLiquidate(string calldata _quotation_id) public payable 
    isWithdrawn(_quotation_id)
    isQuotationOwner(_quotation_id) 
    isQuotationActive(_quotation_id)
    isWithdrawAmountMoreThanFee(_quotation_id)
    isContractActive{
        uint curr_funds = quotation[_quotation_id].amount_received;
        quotation[_quotation_id].amount_received = 0;
        quotation[_quotation_id].is_closed = true;
        quotation[_quotation_id].amount_withdrawn = curr_funds-platform_fee;
        quotation[_quotation_id].fee_paid = platform_fee;
        quotation[_quotation_id].receiver.transfer(curr_funds-platform_fee);
    }

    // -------GET FUNCTIONS-------
    // function getDonatorDonation(string calldata _farm_id)public view returns (uint amount){
    //    return (donatorDonation[_farm_id][msg.sender]); 
    // }


    function getQuotation(string calldata _id) public view returns (Quotation memory){
        return quotation[_id];
    }

}