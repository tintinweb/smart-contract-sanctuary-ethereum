/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// Copyright (c) 2019-2021 Blockchain Presence
// SPDX-License-Identifier: UNLICENSED
// BCP mainnet contract (different from the BCP testnet contract)
pragma solidity ^0.7.0;

contract BlockchainPresence {

//*******************************************Global Variables********************************************************
    
    // BCPGross: ether balance accessible to owner
    uint public BCPGross; 
    // Hash that identifies the ABI of the Mailbox function
    bytes4  constant BCP_Mailbox = bytes4(keccak256("Mailbox(uint32,int88,bool)"));
    // Gas amount used for the Relay function
    uint40 constant _gasForRelay = 40000;
    
//*************************************************Structs************************************************************

    /** 
    @dev stores all sender addresses
    @param _PIN is the SCAs main address
    @param _PUK is the senders main address
    @param _PUK2a first of the PUK2 triplet. Is held by the sender
    @param _PUK2b second of the PUK2 triplet. Is held by the first trusted party
    @param _PUK2c third of the PUK2 triplet. Is held by the second trusted party
    */
    struct Sender {
        address payable _PIN;
        address payable _PUK;
        address _PUK2a;
        address _PUK2b;
        address _PUK2c;
    }

    /**
    @dev stores the msg.sender and the desired new Sender, needed for comparison reasons in the ResetPINPUK function
    @param _claimant is the address that called the ResetPINPUK function
    @param _newSender is the nested Sender struct
    */
    struct ResetPUK {
        address payable _claimant;
        Sender _newSender;
    }
    
    /**
    @dev stores the Commitment information
    @param SenderID uint that identifies a specific sender (is constant)
    @param _horizon the date until when a sender commits himself (in Unix epochtime, i.e., seconds since 01.01.1970)
    @param _senderFee stores the fee that is required
    @param _descriptionHash is the hashed description of the .pdf file
     */
    struct Commitment {
        int64 SenderID;
        uint32 _horizon;
        uint64 _senderFee;
        bytes32 _descriptionHash;
    }
    
    /**
    @dev stores the order information
    @param _deliveryAddress is the receivers address
    @param commitmentID int that identfies the senders most recent .pdf file
    @param _gasPrice uint that sets the max amount of transaction fees
    @param OrderID the orderID
    @param gasForDelivery Total gas amount for the Relay process 
    */
    struct Order {
        address payable _deliveryAddress;
        int64 commitmentID;
        uint64 _gasPrice;
        uint32 OrderID;
        uint gasForDelivery;
    }

//*************************************************Arrays*************************************************************
    
    /**
    @dev stores all Senders
    */
    Sender[] public senders;
    
    /**
    @dev stores all Commitments
    */
    Commitment[] public commitments;
    
    /**
    @dev stores all Orders
    */
    Order[] public orders;
    
//*************************************************Mappings************************************************************

    /**
    @dev maps the PIN and PUK to a SenderID
    NOTE: ensures that 
        (i) Different SenderIDs have different PINs
        (ii) PINs are not used as PUKs
    */
    mapping(address => int64) public keyMap;

    /**
    @dev maps SenderID to ResetPUK
    NOTE: recalls existing claims of the ResetPINPUK function
    */
    mapping(int64 => ResetPUK) private resetIndex;
    
    

//*************************************************Events************************************************************

    /**
    @dev provides information of a new sender to the website
    @param SenderID int64 that identifies a specific sender
    @param PIN is the main address
    @param PUK is the address to change the PIN address
    @param PUK2a first of the PUK2 triplet. Is held by the sender
    @param PUK2b second of the PUK2 triplet. Is held by the first trusted party
    @param PUK2c third of the PUK2 triplet. Is held by the second trusted party
     */
    event newSender(
        int64 SenderID,
        address payable PIN,
        address payable PUK,
        address PUK2a,
        address PUK2b,
        address PUK2c
    );

    /**
    @dev provides information of a changed PIN to the website
    @param SenderID uint that identifies a specific sender (is constant)
    @param newPIN alternative PIN for the deleted one
     */
    event PINChanged(
        int64 SenderID,
        address newPIN
    );
    
    /**
    @dev provides information of a changed _gasPrice to the website
    @param OrderID uint that identifies a specific Order
    @param _newGasPrice is alternative _gasPrice for the deleted one
     */
    event GasPriceChanged(
        uint32 OrderID,
        uint64 _newGasPrice
        );
    /**
    @dev provides information of calls of the ResetPINPUK function in its first stage of the reset process
    @param SenderID uint that identifies a specific sender (is constant)
    @param PIN is the main address
     */
    event newClaim(
        int64 SenderID,
        address payable PIN,
        address payable PUK,
        address PUK2a,
        address PUK2b,
        address PUK2c
    );

    /**
    @dev provides information of a fallbackCall to the website
    @param CustomerAddress is the address that called the fallback function
    @param MonetaryAmount is the msg.value that was provided within the call
     */
    event fallbackCall(
        address CustomerAddress,
        uint MonetaryAmount
    );
    
    /**
    @dev provides information of a fallbackCall to the website
    @param SenderID uint that identifies a specific sender (is constant)
    @param PIN is the main address
    @param PUK is the address to change the PIN address
    @param PUK2a first of the PUK2 triplet. Is held by the sender
    @param PUK2b second of the PUK2 triplet. Is held by the first trusted party
    @param PUK2c third of the PUK2 triplet. Is held by the second trusted party
     */
    event resetPINPUK(
        int64 SenderID,
        address payable PIN,
        address payable PUK,
        address PUK2a,
        address PUK2b,
        address PUK2c
    );

    /**
    @dev provides information of a new commitment to the website
    @param SenderID uint that identifies a specific sender (is constant)
    @param commitmentID uint that identfies the senders most recent .xlsx file
     */
    event newCommitment( 
        int64 SenderID,
        int64 commitmentID
    );

    /**
    @dev provides information of a new order to the website
    @param _PIN is the senders main address
    @param orderID uint that identifies a specific order
    @param commitmentID uint that identfies the senders most recent .xlsx file
    @param _location is the position (column and row) in the .xlsx file
    @param _orderDate date on which the order should arrive (in epochtime)
    @param _gasForDelivery is the total amount of gas that is available for the delivery process
    @param _gasPrice sets the gas Price for the delivery process
    @param receiverAddress is the address of the receiver 
     */
    event newOrder(
        address indexed _PIN,
        uint32 orderID,
        int64 commitmentID,
        string _location,
        uint32 _orderDate,
        uint40 _gasForDelivery,
        uint64 _gasPrice,
        address receiverAddress
    );

    /**
    @dev provides information of the delivered data to the website
    @param orderID uint that identifies a specific order
    @param _statusFlag is a control variable that shows if the incoming transaction contains the datapoint
    @param _status shows whether the oder is open or closed
     */
    event dataDelivered(
        uint32  orderID,
        bool _statusFlag,
        bool _status
    );

    /**
    @dev provides information about the horizon Extension to the website
    @param horizon is the new expire date 
    @param commitmentID int that identfies the senders most recent .xlsx file 
    */
    event horizonExtension(
        uint32 horizon,
        int64 commitmentID
    );
    
//++++++++++++++++++++++++++++++++++++++++++++++++++Start of the Account Management module++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
     The account management module consists of four functions:
    - NewSenderPro: Sets up a sender account using five EOAs (PIN, PUK, and PUK2 triplet)
    - NewSender: Sets up a sender account using two EOAs (PIN, PUK)
    - ChangePIN: Allows to change the PIN
    - ResetPINPUK: Allows to reset the sender account (keeping the SenderID)
    */

    /**
    @dev function register allows to set PIN, PUK and PUK2 triplet, thereby creating the SenderID
    @dev SenderID is >=0 for registrations in the mainnet (and <0 for registrations in the testnet)
    @dev this function has to be called via the PUK address
    @param _PIN is the SCAs main address
    @param _PUK is the senders main address
    @param _PUK2a first of the PUK2 triplet. Is held by the sender
    @param _PUK2b second of the PUK2 triplet. Is held by the first trusted party
    @param _PUK2c third of the PUK2 triplet. Is held by the second trusted party
    */
    function NewSenderPro(
        address payable _PIN, 
        address payable _PUK, 
        address _PUK2a, 
        address _PUK2b, 
        address _PUK2c
    )
        public 
        returns (int64)
    {
        //Checks if the function caller is the PUK
        require(msg.sender == _PUK, "Executing wallet must be equal to PUK!");
        //checks that the PUK, PUK2a, PUK2b and PUK2c are different addresses than the PIN Adress
        require(
            _PIN != _PUK &&
            _PIN != _PUK2a &&
            _PIN != _PUK2b &&
            _PIN != _PUK2c, "PIN can't be PUK/PUK2a/PUK2b/PUK2c"
            );
        //Checks if the PIN is already in use
        require(keyMap[_PIN] == 0x0 , "PIN already in use");
         //Checks if the PUK is already in use
        require(keyMap[_PUK] == 0x0, "PUK already in use");
        //creates SenderID and stores the sender information
        int64 SenderID = int64(senders.length); 
        senders.push(Sender(
            _PIN,
            _PUK,
            _PUK2a,
            _PUK2b,
            _PUK2c));
        //create dependency PIN / PUK -> SenderID
        keyMap[_PIN] = SenderID;
        keyMap[_PUK] = SenderID;
        //create dependency PIN / PUK -> SenderID
        //sends information of a new sender to the website
        emit newSender(SenderID, _PIN, _PUK, _PUK2a, _PUK2b, _PUK2c);
        return(SenderID);
    }

    /**
    @dev function registers new senders within a lower security level using the PUK address as PUK und PUK2 triplet
    @param _PIN is the SCAs main address
    @param _PUK is the senders main address
     */
    function NewSender(
        address payable _PIN, 
        address payable _PUK
    ) 
        external 
        returns (int64)
    {
        int64 SenderID = NewSenderPro(
            _PIN, 
            _PUK, 
            _PUK, 
            _PUK, 
            _PUK); 
        return(SenderID);
    }

    /**
    @dev to change the PIN address
    @dev has to be called by the PUK
    @param _newPIN alternative PIN for the deleted one
    */
    function ChangePIN(address payable _newPIN) external {
    
        // 1. Authentication
        int64 senderID = keyMap[msg.sender];
        Sender storage s = senders[uint (senderID)];
        require(msg.sender == s._PUK, "Invalid PUK");
    
        // 2. Formal check of PIN
        require(
        s._PUK2a != _newPIN &&
        s._PUK2b != _newPIN &&
        s._PUK2c != _newPIN, "Can't use PUK2a/PUK2b/PUK2c as PIN"
        );
        //requires that the PIN is not already in use => implies that the newPIN is not equal to the PUK or belongs to another sender
        require(keyMap[_newPIN] == 0x0, "PIN already in use");
    
        // 3. Documentation
        keyMap[s._PIN] = 0x0;
        s._PIN = _newPIN;
        keyMap[_newPIN] = senderID;
        emit PINChanged(senderID, _newPIN);
    }  
    
    //@dev returns false if claim, 1 if PINPUK changed
    
    //formal correctness of the ResetPINPUK function doesnt get checked enough thoroughly...
    function ResetPINPUK(
        int64 SenderID, 
        address payable _newPIN, 
        address payable _newPUK, 
        address _newPUK2a, 
        address _newPUK2b, 
        address _newPUK2c
    )
        external 
        returns (bool) 
    {
        require (SenderID>=0, "Must be a SenderID >= 0!");
        Sender storage s = senders[uint(SenderID)];
        ResetPUK storage r = resetIndex[SenderID]; 
    
    // 1. Authentication
        require((msg.sender == s._PUK2a) || (msg.sender == s._PUK2b) || (msg.sender == s._PUK2c),"msg.sender must be either PUK2a, PUK2b or PUK2c");
    
    // 2. Check formal correctness
        require(_newPIN != _newPUK && _newPIN != _newPUK2a && _newPIN != _newPUK2b && _newPIN != _newPUK2c ,"new PIN cannot be equal to new PUK or one of the PUK2 triplet");
        
    // 3. Further Authentication
        require(msg.sender != r._claimant, "to approve the claim you have to use another address of the PUK2a/PUK2b/PUK2c triplet!"); 
    
    // 4. Case distinction
        if (s._PUK == s._PUK2a && 
            s._PUK == s._PUK2b && 
            s._PUK == s._PUK2c) {
                keyMap[s._PIN] = 0x0;
                keyMap[s._PUK] = 0x0;
                s._PIN = _newPIN;
                s._PUK = _newPUK;
                keyMap[_newPIN] = SenderID;
                keyMap[_newPUK] = SenderID;
                s._PUK2a = _newPUK2a;
                s._PUK2b = _newPUK2b;
                s._PUK2c = _newPUK2c;
                emit resetPINPUK(SenderID, _newPIN, _newPUK, _newPUK2a, _newPUK2b, _newPUK2c);
                return true;
        } else if (r._claimant == address(0)){
            r._claimant = msg.sender;
            r._newSender._PIN = _newPIN;
            r._newSender._PUK = _newPUK;
            r._newSender._PUK2a = _newPUK2a;
            r._newSender._PUK2b = _newPUK2b;
            r._newSender._PUK2c = _newPUK2c;
            emit newClaim(SenderID, _newPIN, _newPUK, _newPUK2a, _newPUK2b, _newPUK2c);
            return false;
        } else if (_newPIN == r._newSender._PIN && 
            _newPUK == r._newSender._PUK && 
            _newPUK2a == r._newSender._PUK2a && 
            _newPUK2b == r._newSender._PUK2b && 
            _newPUK2c == r._newSender._PUK2c){
            keyMap[s._PIN] = 0x0;
            keyMap[s._PUK] = 0x0;
            s._PIN = _newPIN;
            s._PUK = _newPUK;
            keyMap[_newPIN] = SenderID;
            keyMap[_newPUK] = SenderID;
            s._PUK2a = _newPUK2a;
            s._PUK2b = _newPUK2b;
            s._PUK2c = _newPUK2c;
            resetIndex[SenderID] = ResetPUK(address(0), Sender(address(0),address(0),address(0),address(0),address(0)));
            emit resetPINPUK(SenderID, _newPIN, _newPUK, _newPUK2a, _newPUK2b, _newPUK2c);
            return true;
        } else {
            resetIndex[SenderID] = ResetPUK(address(0), Sender(address(0),address(0),address(0),address(0),address(0)));
            return false; // could add an event here to check to monitor wrong chagne claims
        }
    }
//-----------------------------------------------End of the Account Management module-----------------------------------------------------
    
//++++++++++++++++++++++++++++++++++++++++++++++++++Start of the Commitment module+++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
    The Commitment module consists of two functions:
    - NewCommitment: Registers newly provided .xlsx files within their corresponding commitments.
    - HorizonExtension: Extends the DICs commitment horizon.
    */

    /**
    @dev sets up new commitments for .xlsx files
    @param SenderID uint that identifies a specific sender (is constant)
    @param _horizon the date until when a sender commits himself (in epochtime)
    @param _senderFee sets the fee that is required to be paid within the order process
    @param _descriptionHash sets the identification parameter for the commited data
     */
   function NewCommitment(
        int64 SenderID, 
        uint32 _horizon, 
        uint64 _senderFee, 
        bytes32 _descriptionHash
    )   
        external 
        returns (int64) 
    {
        // TODO get senderID via msg.sender and keymap
        require (SenderID >= 0, "Must be a SenderID >=0!");
        require(msg.sender == senders[uint(SenderID)]._PUK, "Invalid PUK for senderID");
        require(_horizon >= block.timestamp, "Horizon must be in the future");

        int64 commitmentID = int64(commitments.length);
        commitments.push(Commitment(
                SenderID,
                _horizon,
                _senderFee,
                _descriptionHash));

        emit newCommitment(SenderID, commitmentID);
        return(commitmentID);
    }

    /**
    @dev extends the senders commitment
    @param commitmentID uint that identfies the senders most recent .xlsx file  -> here that ID should be chosen the sender wishes to extend
    @param _newHorizon the date until when a sender commits himself (in epochtime)
     */
    function HorizonExtension(int64 commitmentID, uint32 _newHorizon) external {
        // 1. Authentication
        require (commitmentID > 0, "Must be a commitmentID > 0!");
        Commitment storage c = commitments[uint (commitmentID)];
        require(msg.sender == senders[uint(c.SenderID)]._PUK, "Invalid PUK");
        
        // 2. Formal correctness
        require(_newHorizon >= c._horizon, "New date must be greater than the old date");
        
        // 3. Changing to the new horizon
        c._horizon = _newHorizon;
        emit horizonExtension(c._horizon, commitmentID);
    }

//-----------------------------------------------------End of the Commitments module-------------------------------------------------------

//+++++++++++++++++++++++++++++++++++++++++++++++Start of the Order & Delivery module++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
    The order & delivery module consists of nine order functions and the Relay function:
    The order functions differ in the number of function arguments:
    - GetTransactionCosts: Determines the transaction costs
    - GeneralOrder: Is the only order function that contains the hole function body
    - Relay: Receives the incoming data and transfers it to the final receiver and substracts the fee from the original payment of the receiver.
    */

    // This function allows the receiver to determine the value that needs to be attached to the ORDER transaction
    function GetTransactionCosts(int64 _commitmentID, uint40 _gasForMailbox, uint _gasPriceInGWei) external view returns (uint) {
        require (_commitmentID > 0, "Must be a commitmentID > 0!");
        //convert to wei
        require(_commitmentID < int64(commitments.length), "Invalid commitmentID");
        uint _senderFee = commitments[uint(_commitmentID)]._senderFee;
        //_gasPriceInGWei * 1e9 converts _gasPriceInGwei to Wei
        return uint((_gasForMailbox+_gasForRelay) * _gasPriceInGWei * 1e9 + _senderFee);
    }

    /**
    @dev general order function for customized orders
    @param commitmentID uint that identifies a specific commitment
    @param _gasForMailbox is the maximum of gas that is available for the delivery process (set by the receiver)
    param _location is the position (column and row) in the .xlsx file
    @param _orderDate date on which the order should arrive (in epochtime)
     */
function ORDER(
        int64 commitmentID, 
        uint40 _gasForMailbox, 
        string calldata _location, 
        uint32 _orderDate,
        uint64 _gasPrice
    ) 
        external 
        payable 
        returns (uint32)
    {
        // convert Gwei to wei
        _gasPrice = _gasPrice*1e9;
    // 1. Order analysis
        require (commitmentID > 0, "Must be a commitmentID > 0!");
        require(commitmentID < int64(commitments.length), "Invalid commitmentID");
        Commitment memory c = commitments[uint(commitmentID)];
        uint32 OrderID  = uint32(orders.length);
        uint40 _gasForDelivery = _gasForMailbox + _gasForRelay;
        uint _gasCost = _gasForDelivery * _gasPrice;   
        int delta = int(msg.value) - int(_gasCost+c._senderFee);
        if (delta > 0){BCPGross += uint(delta);} 
    // 2. Checking incoming order
        require(delta >= 0, "Insufficient funds for Relay transaction");
    // 3. Reporting to website
        address payable PIN = senders[uint(c.SenderID)]._PIN;
        emit newOrder(
            PIN,
            OrderID,
            commitmentID,
            _location,
            _orderDate,
            _gasForDelivery,
            _gasPrice,
            msg.sender);

    // 4. Fueling delivery
        PIN.transfer(_gasCost); // IS THIS CORRECT?
    // 5. Storing order
        orders.push(Order(
            msg.sender, //tx.origin
            commitmentID,
            _gasPrice,
            OrderID,
            _gasForDelivery
            ));
        return(OrderID);
   }

       /**
    @dev to change the _gasPrice of a Order
    @dev has to be called by the PUK
    @param _newGasPrice is the new __gasPrice for the Sender
    */
    function ChangeGasPrice(uint64 _newGasPrice, uint32 OrderID) payable external {
        Order storage order = orders[uint32 (OrderID)];
        require(msg.sender == order._deliveryAddress, "Use the same address you used for odering"); // This will only allow the receiver contract to change the gasPrice not necessarily the receiver
        _newGasPrice = _newGasPrice * 1e9;
        uint oldGasPrice = order._gasPrice;
        order._gasPrice = _newGasPrice;
        address payable senderPIN = senders[uint(commitments[uint(order.commitmentID)].SenderID)]._PIN;
        if (_newGasPrice>oldGasPrice) {
            uint toTransfer = order.gasForDelivery * (_newGasPrice-oldGasPrice);
            require(msg.value >= toTransfer, "value provided to low");
            senderPIN.transfer(toTransfer);
        }
        emit GasPriceChanged(OrderID, _newGasPrice);
    }
               
    /**
    @dev receives the final data and collects the fee
    @param orderID uint that identifies a specific order (is constant)
    @param _data is the finally requested information behind the order
    @param _statusFlag is a control variable that shows if the incoming transaction contains the datapoint
     */
    function Relay(uint32 orderID, int88 _data, bool _statusFlag) external payable {
    // 1. On-Chain authentication
        Order memory o = orders[orderID];
        Commitment memory c = commitments[uint(o.commitmentID)];
        require(o._deliveryAddress != address(0), "Order already delivered");
        require(msg.sender == senders[uint(c.SenderID)]._PIN, "Not authorized!"); 
    // 2. Delivery
        delete orders[orderID];
        (bool sent, ) = o._deliveryAddress.call(abi.encodeWithSelector(BCP_Mailbox, orderID, _data, _statusFlag));
        emit dataDelivered(orderID, _statusFlag, sent);
    // 3. Compensation
        uint64 _fee = c._senderFee;
        if(_fee > 0){
            if(_statusFlag){
                senders[uint(c.SenderID)]._PUK.transfer(_fee/2);
                BCPGross += _fee/2; 
            } else {
                o._deliveryAddress.transfer(_fee);
            }
        }
    }

//------------------------------------------------End of the Order & Delivery module-------------------------------------------------------

//+++++++++++++++++++++++++++++++++++++++++++++++Start of the Contract Information Module++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /**
    @dev determines the SenderID via the address (PIN or PUK)
    @dev the possibility to easlily get your SenderID increases the sender convenience
    @dev is needed for testing purposes, you have to kblock.timestamp the SenderID
     */
    function GetSenderID() external view returns(int64) {
        return(keyMap[msg.sender]);
    }

    /**
    @dev returns the entire sender struct
    @dev has to be called by the PUK
    @dev is needed for testing purposes (backend) you have to check whether PIN and/or PUK got changed
    @param SenderID uint that identifies a specific sender (is constant)
     */
    function GetSenderInformation(int64 SenderID) public view returns (address, address, address, address, address) {
        require (SenderID >= 0, "Must be a SenderID >= 0!");
        
        require(
        msg.sender == senders[0]._PIN ||
        msg.sender == senders[uint(SenderID)]._PUK, "Has to be called by the Website or the right sender"
        );
        
        
        Sender storage s = senders[uint (SenderID)];
        return(
            s._PIN,
            s._PUK,
            s._PUK2a,
            s._PUK2b,
            s._PUK2c
        );
    }

        
    
    /**
    @dev returns the PIN of a SenderID
     */
    function GetPIN(int64 SenderID) public view returns (address payable) {
        require (SenderID >= 0, "Must be a SenderID >= 0!");
        Sender storage s = senders[uint (SenderID)];
        return(s._PIN);
    }

    /**
    @dev returns the PUK of a SenderID
     */
    function GetPUK(int64 SenderID) public view returns (address payable) {
        require (SenderID >= 0, "Must be a SenderID >= 0!");
        Sender storage s = senders[uint (SenderID)];
        return(s._PUK);
    }
    
    /**
    @dev necessary to be able to display the receiver address on our webpage
    @param orderID uint that identifies a specific order (is constant)
     */
    function GetReceiverFromOrderID(uint32 orderID) public view returns (address) {
        require(msg.sender == senders[0]._PIN, "Not authorized!");
        return(orders[orderID]._deliveryAddress);
    }
    
//-----------------------------------------------End of the Account Management module-----------------------------------------------------

//+++++++++++++++++++++++++++++++++++++++++++++++Start of the Contract Governance module++++++++++++++++++++++++++++++++++++++++++++++++++++

    /**
    The contract governance module consists of three functions:
    - Constructor: Authentication and initial registrations
    - Fallback: Recommended
    - Collect: Transfers any positive balance to the owner's address
    */

    /**
    @dev registers BCP as SenderID-0
    @dev registers SenderID-1 through SenderID-3
    @dev keeps commitment 0 empty
    @dev commits commitments 1-21
     */
    constructor(address payable _PIN, address payable _PUK, address _PUK2a, address _PUK2b, address _PUK2c) {
        
        //*************************************************Registration Constructor******************************************************
        // 1. Authentication
        require (msg.sender == _PUK);
        
        // 2. Initial registration: BCP (SenderID-0)
        senders.push(Sender(_PIN, _PUK, _PUK2a, _PUK2b, _PUK2c));
        keyMap[_PIN] = 0;
        keyMap[_PUK] = 0;
        /*
        // 3. Initial registration: Random and random stuff (SenderID-1)
        senders.push(Sender(
            0x50dc646B7Aa3ddED162DfD801a35De89cAC7C1af,
            0x35228af8488F5FBA5161293fFa9fD6903aC19f88,
            0x4384A01045CCB9cAEBb75d9423C2F49FaFffAc21,
            0x03c10878054b5fc0DCd59c08E23940250220B20E,
            0x927F09B02C027B61D1477132440FEF3515EBe022
        ));
        keyMap[0x50dc646B7Aa3ddED162DfD801a35De89cAC7C1af] = 1;
        keyMap[0x35228af8488F5FBA5161293fFa9fD6903aC19f88] = 1;
        
        // 4. Initial registration: Financial Infos (SenderID-2)
        senders.push(Sender(
            0x053Cb36Ed183F76d1CbedA5B5Fe9BC57cA5B1a8A,
            0x2103a314d383c59Cfa31726516044b4e0458A22a,
            0x4384A01045CCB9cAEBb75d9423C2F49FaFffAc21,
            0x03c10878054b5fc0DCd59c08E23940250220B20E,
            0x927F09B02C027B61D1477132440FEF3515EBe022
        ));
        keyMap[0x053Cb36Ed183F76d1CbedA5B5Fe9BC57cA5B1a8A] = 2;
        keyMap[0x2103a314d383c59Cfa31726516044b4e0458A22a] = 2;
      
        // 5. Initial registration: Blockchain Infos (SenderID-3)
        senders.push(Sender(
            0xcF7a14be41D4fB6a4Dd39eb2dC4c0E2D74f5B0ff,
            0x074ccD50D1B9F2B20Bd6263418e32D0B1D390b30,
            0x4384A01045CCB9cAEBb75d9423C2F49FaFffAc21,
            0x03c10878054b5fc0DCd59c08E23940250220B20E,
            0x927F09B02C027B61D1477132440FEF3515EBe022
        ));
        keyMap[0xcF7a14be41D4fB6a4Dd39eb2dC4c0E2D74f5B0ff] = 3;
        keyMap[0x074ccD50D1B9F2B20Bd6263418e32D0B1D390b30] = 3;
        */
        //*************************************************Commitment and Order Constructor******************************************************
        // Initial commitment: The BCP owner and Website (void commitment, fill in 0) (senderID-0)
        commitments.push(Commitment(0, 0, 0, 0));  
        
        // Initial commitment: Random and random stuff (SenderID-1)     
        /*
        commitments.push(Commitment(1, uint32(block.timestamp + 60 days), 500000 gwei, 0x77fafae1cc291a96a61a79128bd472577082c88c8d20d5201010960dbd699b68));  //1 Random
        commitments.push(Commitment(1, uint32(block.timestamp + 60 days), 500000 gwei, 0x79813451690fccbd9031b3fc4b8e5c2bed5c5676769f7f28063695d0d1daec37));  //2 White Ether
        commitments.push(Commitment(1, uint32(block.timestamp + 60 days), 500000 gwei, 0x266c16d18acf2c6dee1c6f3ca5c4cee08b938663fe266456c3b56ea9c8adb2a5));  //3 SBB Abfahrt
        commitments.push(Commitment(1, uint32(block.timestamp + 60 days), 500000 gwei, 0x2b5d7785e6849a450c68a3ac02d016589dc10684aaf8898e8fdfa3059940dd24));  //4 SBB Ankunft
        commitments.push(Commitment(1, uint32(block.timestamp + 60 days), 500000 gwei, 0xb7f60f0919988154d7dc59e2cda32697eb27422bd617213731c6ad002d2ecd4d));  //5 Temperature and Humidity


        // Initial commitment: Financial Infos (SenderID-2)

        commitments.push(Commitment(2, uint32(block.timestamp + 60 days), 500000 gwei, 0x87ecaf907fda1db16da65f41bf1b28455acc570ae3d94b74c8a553b86377295c)); //6 BTC/ETC                       
        commitments.push(Commitment(2, uint32(block.timestamp + 60 days), 500000 gwei, 0x9c27e5bb7785826e02978c338ba68a27786dbb4b7f8e66b3976ea5820a54bbbc)); //7 Wechselkurse (Fiat und Crypto)                         
        commitments.push(Commitment(2, uint32(block.timestamp + 60 days), 500000 gwei, 0x304eeba5286743392277b5dbe80a35d45f90b53b7e3beb882810efd3e9f8c795)); //8: US Stocks prices (letzte, oder historical Schlusskurs)
        commitments.push(Commitment(2, uint32(block.timestamp + 60 days), 500000 gwei, 0xd702600f64d0607b84ee7ea7d5076ca166ee4673e5785a9a644ab9480561f12a)); //9: SIX Stocks prices (letzte Schlusskurs)
        commitments.push(Commitment(2, uint32(block.timestamp + 60 days), 500000 gwei, 0x3cb09e106c947e0d481f6d72fa2e433fe2b5927d1bd8a142dd58ba0aafa6eebf)); //10: Company metrics wie EBITDA, EPS, market Cap, ROE usw. von US Company
        commitments.push(Commitment(2, uint32(block.timestamp + 60 days), 500000 gwei, 0x492cbd5102da88017e9b4827181adad600fdb1bcfeeb9e76472e44faede943e3)); //11: SAR kurs (SARON, SARTN, SAR1W usw) von der SNB
        commitments.push(Commitment(2, uint32(block.timestamp + 60 days), 500000 gwei, 0xfed8cd391589d0a42f6d8507814bcca836fad539ca2962e6f4c6cc4b27bf976c)); //12: Spot interest rates with different maturities for SWISS Confederation Bond 
        commitments.push(Commitment(2, uint32(block.timestamp + 60 days), 500000 gwei, 0xbb12aa3564726bc979935ee19d7b6fe16aee301071612a3e9bd5ce73fb7ebb9d)); //13: Metals preis (Gold, Silver, Platinum. Palladium)
        
        
        // Initial commitment: Blockchain Infos (SenderID-3)
       
        commitments.push(Commitment(3, uint32(block.timestamp + 60 days), 500000 gwei, 0x3d7890c831b559be718d67f1eb71243611a63eed977998035d60adecb551e6dc));  //14: aktuelle preis von irgendeine Cryptocurrency               
        commitments.push(Commitment(3, uint32(block.timestamp + 60 days), 500000 gwei, 0x899a6732dee50dbeae1ea2df8f5c432c887d89cf122781d1eff6dc52449e9ca3));  //15: Coins infos wie market Cap, volume, supply, market cap rank
        commitments.push(Commitment(3, uint32(block.timestamp + 60 days), 500000 gwei, 0x5cb0313b5a7beee21d901d004f18886aaa160e16d08ce31c8295d32f1104c0c0));  //16: Reccommended gas price for each transaction speed (ETH Gas Station)
        commitments.push(Commitment(3, uint32(block.timestamp + 60 days), 500000 gwei, 0x23967581be8b37cb139d1d754b5dd8b8b68392c7fb56c1bc3dcf11e98652fbe0));  //17: Waiting Time for each speed (ETH GAS Station)
        commitments.push(Commitment(3, uint32(block.timestamp + 60 days), 500000 gwei, 0xf8ffc3e2b6b5457109a93512cb2bc8b197b8efed73b2cbc427a8f4312a875574));  //18: Account Balance von eine Adresse in eine der folgende Blockchain (btc, eth, ltc, dash oder doge)             
        commitments.push(Commitment(3, uint32(block.timestamp + 60 days), 500000 gwei, 0x8d5b83c35ecad1633ecc075f606d3e03e5c4a2b54e671d4d48b4397988e8d7c0));  //19: Average Transaction cost for transaction mined within 3-6 blocks (  btc, eth, ltc, dash oder doge)
        commitments.push(Commitment(3, uint32(block.timestamp + 60 days), 500000 gwei, 0x041d786c6077dcb430715b3c888adc89302445bf521ed7d9dbc20ac486fc5ab7));  //20: Nr. of blocks (btc, eth, ltc, dash oder doge)               
        commitments.push(Commitment(3, uint32(block.timestamp + 60 days), 500000 gwei, 0xf7b3b1e5b7ff652c32e0c56864602f045ab7d0df0943d7de78a1ffb82033d618));  //21: Nr. of unconfirmed transactions (btc, eth, ltc, dash oder doge            
        */
    }
    
    fallback() external payable {
        BCPGross += msg.value;
        emit fallbackCall(msg.sender, msg.value);
    }
    
    /**
    @dev transfers all collected payments from this contract to the owner
    */
    function Collect() external {
        require(msg.sender == senders[0]._PUK, "Not authorized!");
        senders[0]._PUK.transfer(BCPGross); 
        BCPGross = 0;
    }

//----------------------------------------------End of the Contract Governance module------------------------------------------------------
}
//--------------------------------------------------------End of Contract------------------------------------------------------------------