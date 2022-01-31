/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Escrow
 * @dev Implements escrow process 
 */
contract EscrowStorage {

    // Array with all escrows
    Escrow[] public escrows;

    // Mapping from dealer to a list of owned escrows
    mapping(address => uint[]) public escrowDealer;

    // Mapping from escrow index to buyer deposit
    mapping(uint256 => Deposit) public escrowDeposits;

    // Escrow struct which holds all the required info
    struct Escrow {
        address payable dealer;
        uint256 price;
        bool created;
        bool escrowed;
        bool complited;
    }

    // Deposit struct holds buyers info
    struct Deposit {
        address payable buyer;
        uint256 amount;
    }

    address owner;

    constructor() {
        owner = msg.sender;
    }

    // Array of the guarantors
    address[] public guarantors;

    /**
    * @dev
    */
    modifier isOwner() {
        require(owner == msg.sender);
        _;
    }

    /**
    * @dev Guarantees msg.sender is host of the given escrow
    */
    modifier isGuarator() {
        for (uint i = 0; i < guarantors.length; i++) {
            require(guarantors[i] == msg.sender);
            _;
        }
    }

    /**
    * @dev Guarantees msg.sender is dealer of the given escrow
    * @param _escrowID uint of the escrow to validate its ownership belongs to msg.sender
    */
    modifier isDealer(uint _escrowID) {
        require(escrows[_escrowID].dealer == msg.sender);
        _;
    }

    /**
    * @dev getGuarantors
    */
    /*
    function getGuarantors() public view returns(address[] memory) {
        return guarantors;
    }
    */

    /**
    * @dev setGuarantors
    */
    function setGuarantors(address[] memory addresses) public isOwner {
        delete guarantors;
        for (uint i = 0; i < addresses.length; i++) {
            guarantors.push(addresses[i]);
        }
    }

    /**
    * @dev Gets an array of owned escrows
    * @param _dealer address of the escrow dealer
    */
    function getEscrowsOf(address _dealer) public view returns(uint[] memory) {
        uint[] memory dealedEscrows = escrowDealer[_dealer];
        return dealedEscrows;
    }

    /**
    * @dev Gets the total number of escrows owned by an address
    * @param _dealer addres of the escrow dealer
    */
    function getCountEscrowsOf(address _dealer) public view returns(uint) {
        return escrowDealer[_dealer].length;
    }

    /**
    * @dev Gets the info of a given escrow which stored within a struct
    * @param _escrowID uint ID of the escrow
    * @return dealer address of the escrow
    * @return price uint256 of the escrow
    * @return created bool whether the escrow is created
    * @return escrowed bool whether the escrow is escrowed
    * @return complited bool whether the escrow is complited
    */
    function getEscrowByID(uint _escrowID) public view returns(
        address dealer,
        uint256 price,
        bool created,
        bool escrowed,
        bool complited) {

        Escrow memory esc = escrows[_escrowID];
        return (
            esc.dealer,
            esc.price,
            esc.created,
            esc.escrowed,
            esc.complited);
        }
    
    /**
    * @dev Creates an escrow with the given information
    * @param _price uint256 price of the escrow
    * @return created bool whether the escrow is created
    */
    function createEscrow(uint _price) public returns(bool) {
        uint escrowID = escrows.length;
        Escrow memory newEscrow;
        newEscrow.dealer = payable(msg.sender);
        newEscrow.price = _price;
        newEscrow.created = true;
        newEscrow.escrowed = false;
        newEscrow.complited = false;

        escrows.push(newEscrow);
        escrowDealer[msg.sender].push(escrowID);

        emit EscrowCreated(msg.sender, escrowID);
        return true;
    }

    /**
    * @dev Cancels an ongoing escrow to dealer
    */
    function cancelEscrowToDealer(uint _escrowID) public isGuarator {
        Escrow memory esc = escrows[_escrowID];
        Deposit memory dep = escrowDeposits[_escrowID];

        if (!esc.dealer.send(dep.amount)) {
            revert();
        }
        escrows[_escrowID].complited = true;
        emit EscrowCanceled(esc.dealer, _escrowID);
    }

    /**
    * @dev Cancels an ongoing escrow to buyer
    */
    function cancelEscrowToBuyer(uint _escrowID) public isGuarator {
        Deposit memory dep = escrowDeposits[_escrowID];

        if (!dep.buyer.send(dep.amount)) {
            revert();
        }
        escrows[_escrowID].complited = true;
        emit EscrowCanceled(dep.buyer, _escrowID);
    }

    /**
    * @dev Buyer deposits amount on an escrow
    */
    function depositEscrow(uint _escrowID) external payable {
        uint ethAmountSent = msg.value;

        // Dealer can't buy on their escrows
        Escrow memory myEscrow = escrows[_escrowID];
        if (myEscrow.dealer == msg.sender) revert();

        if (ethAmountSent < myEscrow.price) revert();

        Deposit memory newDeposit;
        newDeposit.buyer = payable(msg.sender);
        newDeposit.amount = ethAmountSent;
        escrowDeposits[_escrowID] = newDeposit;
        emit DepositSuccess(msg.sender, _escrowID);
    }

    /*
    * @dev Complited an deposited escrow
    */
    function compileEscrow(uint _escrowID) public {
        Deposit memory myDeposit = escrowDeposits[_escrowID];

        // Only buyer
        if (myDeposit.buyer != msg.sender) revert();

        Escrow memory esc = escrows[_escrowID];

        if (!esc.dealer.send(myDeposit.amount)) {
            revert();
        }

        esc.complited = true;
        emit EscrowComplited(msg.sender, _escrowID);
    }

    event DepositSuccess(address _from, uint _escrowID);

    // EscrowCreated is fired when an escrow is created
    event EscrowCreated(address _dealer, uint _escrowID);

    // EscrowCanceled is fired when an escrow is canceled
    event EscrowCanceled(address _dealer, uint _escrowID);

    // EscrowComplited is fired when an escrow is complited
    event EscrowComplited(address _dealer, uint _escrowID);
}