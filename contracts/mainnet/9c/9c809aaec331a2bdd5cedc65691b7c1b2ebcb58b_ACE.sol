/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: ACE.sol


// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract ACED {
    address owner;
    address buyer;
    address seller;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    function setBuyer(address _address) external {
        require(msg.sender == owner);
        buyer = _address;
    }
    function setSeller(address _address) external {
        require(msg.sender == owner);
        seller = _address;
    }

    function withdraw(bool _native, address _to, uint256 _amount, address _tokenAddress) external {        
        require(msg.sender == owner && (_to == buyer || _to == seller), "160");

        if(_native) {
            payable(_to).transfer(_amount);
        } else {
            IERC20 crypto1 = IERC20(address(_tokenAddress));
            require(crypto1.transfer(_to, _amount), "161");
        }     
    }
}

/// @title Antonomous Crypto Escrow Smart Contract
/// @author ADC
contract ACE {

    // Created escrow number
    uint256 public counter;

    // Escrow ID <-> Escrow mapping
    mapping(bytes32 => AnscaEscrow) anscaEscrowList;
    // Wallet reputation information
    mapping(address => AnscaReputation) reputation;
    // Wallet <-> Escrow ID mapping
    mapping(address => bytes32[]) ownerEscrowMapping;
    // Protocol Fee
    uint256 public FEE = 75; //75 = 0.75%
    // Time unit
    uint256 public dayInSecond;
    // If the contract is paused
    bool public paused;

    
    address owner;
    // Address receiving escrow fees
    address feeCollectorAddress;

    // List of escrow states
    enum State{ NULL, NEW_SELLER, ONGOING, ONGOING_LOCKED, DISPUTE, COMPLETE }
    // List of user actions
    enum Action{ NULL, CREATE, CANCEL, DEPOSIT, WITHDRAW, VALIDATE, LOCK, UNLOCK, NEW_DELIVERY_TIME_REQUEST, ACCEPT_NEW_DELIVERY_TIME_REQUEST, DISCOUNT_REQUEST, ACCEPT_DISCOUNT_REQUEST }
    
    // Escrow model
    struct AnscaEscrow {
        bytes32 id;
        bytes32 label;
        address tokenAddress;
        bytes32 buyerStrVar;
        bytes32 sellerStrVar;
        uint256 amount;
        uint256 amountMinusFee;
        uint256 startTimestamp;        
        uint256 creationTimestamp;
        uint256 lockTimestamp;
        uint256 unlockTimestamp;
        uint256 buyerLastActionDate;
        uint256 sellerLastActionDate;
        uint32 deliveryTime;
        uint32 buyerNbrVar;
        uint32 sellerNbrVar;
        uint32 discount;        
        bool native;
        bool sellerHasReceivedHisShare;
        bool buyerHasReceivedHisShare;
        bool dispute;
        Action buyerLastAction;
        Action sellerLastAction;
        State state;
        address buyer;
        address buyerHandler;
        address seller;        
        address sellerHandler;
        address depositContract;
    }

    // Wallet reputation information model
    struct AnscaReputation {
        uint256 escrowNumber;
        uint256 disputeNumber;
        uint256 firstEscrowDate;
        uint256 lastEscrowDate;
    }

    event ACEEvent(address from, address indexed buyer ,address indexed seller, bytes32 indexed id, uint8 action);

    event CompleteEvent(bytes32 indexed id, uint256 amount, bool dispute, address indexed buyer, address indexed seller, address tokenAddress);

    constructor(address _feeCollectorAddress, uint256 _dayInSecond) {
        owner = msg.sender;
        feeCollectorAddress = _feeCollectorAddress;
        dayInSecond = _dayInSecond;
    }

    /// @notice Get the escrow information by ID
    /// @param _id Id of the escrow
    function getEscrowById(bytes32 _id) external view returns(string memory) {
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];

        string memory resultPart1;
        string memory resultPart2;
        string memory resultPart3;
        string memory resultPart4;  

        {
            resultPart1 = string(abi.encodePacked(
            localAnscaEscrow.id,
            ";",
            localAnscaEscrow.native ? "TRUE" : "FALSE",
            ";",
            Strings.toHexString(uint256(uint160(address(localAnscaEscrow.tokenAddress)))),
            ";",
            Strings.toString(localAnscaEscrow.amount),
            ";",
            Strings.toString(uint256(localAnscaEscrow.discount)),
            ";",
            Strings.toString(uint256(localAnscaEscrow.deliveryTime)),
            ";",
            Strings.toString(localAnscaEscrow.startTimestamp)));
        }

        {
            resultPart2 = string(abi.encodePacked(
            ";",
            Strings.toString(uint256(localAnscaEscrow.state)),
            ";",
            Strings.toHexString(uint256(uint160(address(localAnscaEscrow.buyer)))),
            ";",
            Strings.toString(uint256(localAnscaEscrow.buyerLastAction)),
            ";",
            Strings.toString(localAnscaEscrow.buyerLastActionDate),
            ";",
            Strings.toString(uint256(localAnscaEscrow.buyerNbrVar)),
            ";",
            localAnscaEscrow.buyerStrVar,
            ";",
            localAnscaEscrow.buyerHasReceivedHisShare ? "TRUE" : "FALSE"));
        }

        {
            resultPart3 = string(abi.encodePacked(
            ";",
            Strings.toHexString(uint256(uint160(address(localAnscaEscrow.seller)))),
            ";",
            Strings.toString(uint256(localAnscaEscrow.sellerLastAction)),
            ";",
            Strings.toString(localAnscaEscrow.sellerLastActionDate),
            ";",
            Strings.toString(uint256(localAnscaEscrow.sellerNbrVar)),
            ";",
            localAnscaEscrow.sellerStrVar,
            ";",
            localAnscaEscrow.sellerHasReceivedHisShare ? "TRUE" : "FALSE",
            ";",
            localAnscaEscrow.label,
            ";",
            Strings.toString(localAnscaEscrow.creationTimestamp)
            ));
        }
        {
            resultPart4 = string(abi.encodePacked(
            ";",
            Strings.toString(localAnscaEscrow.lockTimestamp),
            ";",
            Strings.toString(localAnscaEscrow.unlockTimestamp),
            ";",
            Strings.toHexString(uint256(uint160(address(localAnscaEscrow.buyerHandler)))),
            ";",
            Strings.toHexString(uint256(uint160(address(localAnscaEscrow.sellerHandler))))
            ));
        }
        
        return string(abi.encodePacked(resultPart1, resultPart2, resultPart3, resultPart4));
    }

    /// @notice Get the address reputation
    /// @param _address the address for wich we want to retreive the reputation
    function getAddressReputation(address _address) external view returns(string memory){
        return string(abi.encodePacked(
            Strings.toString(reputation[_address].escrowNumber),
            ";",
            Strings.toString(reputation[_address].disputeNumber),
            ";",
            Strings.toString(reputation[_address].firstEscrowDate),
            ";",
            Strings.toString(reputation[_address].lastEscrowDate)
            ));
    }

    /// @notice True if the escrow ended without going into dispute
    /// @param _id Id of the escrow
    function escrowWentWell(bytes32 _id) external view returns(bool) {
        return anscaEscrowList[_id].state == State.COMPLETE && !anscaEscrowList[_id].dispute;
    }

    /// @notice True if the provided address is involved in the escrow
    /// @param _id Id of the escrow
    /// @param _address the address to check
    function addressIsInvolved(bytes32 _id, address _address) external view returns(bool) {
        return anscaEscrowList[_id].buyer == _address || anscaEscrowList[_id].seller == _address;
    }

    // ##############################################################
    // #####                                                    #####
    // ################# Buyer and Seller actions ###################
    // #####                                                    #####
    // ##############################################################

    /// @notice Creates a new crypto escrow. Can be called by the buyer or the seller. If called by the buyer, the deposit is made at the same time and the escrow goes to the ONGOING state. If called by the seller, the escrow is still in the NEW state and waits for the buyer deposit to pass to the ONGOING state
    /// @param _id Id of the escrow
    /// @param _native Whether the native blockchain token is used or one from a deployed ERC20 smart contract
    /// @param _tokenAddress The smart contract address of the ERC20 token if applicable
    /// @param _amount The amount to lock in the escrow
    /// @param _deliveryTime The duration of this escrow before it goes to the dispute state. Can be modify later if the parties come to an agreement
    /// @param _label A description for this escrow
    /// @param _asBuyer If it is the buyer who initiate this creation
    /// @param _sellerAddress the address of the seller filled in by the buyer if applicable
    function createEscrow(bytes32 _id, bool _native, address _tokenAddress, uint256 _amount, uint32 _deliveryTime, bytes32 _label, bool _asBuyer, address _sellerAddress, address _handlerAddress)  external payable {
        //Checks
        require(!paused, "50");
        require(anscaEscrowList[_id].id != _id || 
            (anscaEscrowList[_id].sellerHasReceivedHisShare && anscaEscrowList[_id].buyerHasReceivedHisShare) ||
            (anscaEscrowList[_id].sellerHasReceivedHisShare && anscaEscrowList[_id].discount == 0) || 
            (anscaEscrowList[_id].buyerHasReceivedHisShare && anscaEscrowList[_id].discount == 100) ||
            (anscaEscrowList[_id].state == State.NEW_SELLER && block.timestamp > (anscaEscrowList[_id].creationTimestamp + 30 * dayInSecond)) ,"51");
        require(_deliveryTime >= dayInSecond, "53");
        if(!_native) {
            require(_tokenAddress != address(0), "54");
        } else {
            _tokenAddress = address(0);
        }

        //States
        AnscaEscrow memory localAnscaEscrow = AnscaEscrow({
            id: _id,
            label: _label,
            native: _native,
            tokenAddress: _tokenAddress,
            amount: _amount,
            amountMinusFee: _amount - (_amount * FEE) / 10000,
            discount: 0,
            deliveryTime: _deliveryTime,
            startTimestamp: _asBuyer ? block.timestamp : 0,
            lockTimestamp: 0,
            unlockTimestamp: 0,
            state: _asBuyer ? State.ONGOING : State.NEW_SELLER,
            buyer: _asBuyer ? address(msg.sender) : address(0),
            buyerHandler: _asBuyer ? _handlerAddress : address(0),
            buyerLastAction: _asBuyer ? Action.CREATE : Action.NULL,
            buyerLastActionDate: _asBuyer ? block.timestamp : 0,
            buyerNbrVar: 0,
            buyerStrVar: "",
            buyerHasReceivedHisShare: false,
            seller: _asBuyer ? _sellerAddress : address(msg.sender),
            sellerHandler: _asBuyer ? address(0) : _handlerAddress,
            sellerLastAction: _asBuyer ? Action.NULL : Action.CREATE,
            sellerLastActionDate: _asBuyer ? 0 : block.timestamp,
            sellerNbrVar: 0,
            sellerStrVar: "",
            sellerHasReceivedHisShare: false,
            creationTimestamp: block.timestamp,
            depositContract: address(0),
            dispute: false
            });

            anscaEscrowList[_id] = localAnscaEscrow;            
            if(_asBuyer) {     
                require(msg.sender != _sellerAddress && _sellerAddress != address(0), "55");           
                ownerEscrowMapping[localAnscaEscrow.seller].push(_id);
                if(_native) {
                    nativeDepositInternal(localAnscaEscrow);
                } else {
                    depositInternal(localAnscaEscrow);
                }                
            } else {                
                ownerEscrowMapping[msg.sender].push(_id);
            }
            emitACEEvent(msg.sender, localAnscaEscrow.buyer, localAnscaEscrow.seller, _id, Action.CREATE); 
            counter++;
    }

    /// @notice returns all the escrow ID for the calling wallet
    function getAllEscrowsForSender() external view returns(bytes32[] memory){
        return ownerEscrowMapping[msg.sender];
    }

    // ONGOING or DISPUTE
    /// @notice Allow the buyer and the seller to make a discount proposal. If the escrow is in DISPUTE state, both parties have only 24 hours after the proposal of the other party to make a discount proposal
    /// @param _id The escrow ID
    /// @param _discount The discount value like "10" for 10%
    function proposeAmountDiscount(bytes32 _id, uint32 _discount) external {
        //Checks
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];
        require(isSellerParty(localAnscaEscrow, msg.sender) || isBuyerParty(localAnscaEscrow, msg.sender), "10");
        require(_discount >= 0 && _discount <= 100, "11");
        bool localisInOrGoingToBeDispute = isInOrGoingToBeDispute(localAnscaEscrow, false);
        require(isInOrGoingToBeOngoing(localAnscaEscrow, false) || localisInOrGoingToBeDispute, "12");

        //States        
        if(localAnscaEscrow.state != State.DISPUTE && localisInOrGoingToBeDispute) {
            localAnscaEscrow.state = State.DISPUTE;            
            reputation[localAnscaEscrow.buyer].disputeNumber++;
        }
        if(localAnscaEscrow.state == State.DISPUTE && !localAnscaEscrow.dispute && ((localAnscaEscrow.sellerLastAction != Action.NULL && localAnscaEscrow.sellerLastAction != Action.CREATE) || isSellerParty(localAnscaEscrow, msg.sender))  ) {
            localAnscaEscrow.dispute = true;
            reputation[localAnscaEscrow.seller].disputeNumber++;
        }

        if(localAnscaEscrow.state == State.ONGOING || localAnscaEscrow.state == State.ONGOING_LOCKED) {
            if(
                (isSellerParty(localAnscaEscrow, msg.sender) && 
                localAnscaEscrow.buyerLastAction == Action.DISCOUNT_REQUEST && 
                localAnscaEscrow.buyerNbrVar == _discount)
                ||
                (isBuyerParty(localAnscaEscrow, msg.sender) && 
                localAnscaEscrow.sellerLastAction == Action.DISCOUNT_REQUEST && 
                localAnscaEscrow.sellerNbrVar == _discount)                
            ) {
                updateAction(localAnscaEscrow, msg.sender, Action.ACCEPT_DISCOUNT_REQUEST, _discount, "");
                localAnscaEscrow.discount = _discount;
            } else {
                updateAction(localAnscaEscrow, msg.sender, Action.DISCOUNT_REQUEST, _discount, "");
            }

        } else if(localAnscaEscrow.state == State.DISPUTE) {
            if(
                (isSellerParty(localAnscaEscrow, msg.sender) && 
                localAnscaEscrow.buyerLastAction == Action.DISCOUNT_REQUEST &&
                localAnscaEscrow.buyerLastActionDate > (localAnscaEscrow.startTimestamp + localAnscaEscrow.deliveryTime) &&
                (block.timestamp > (localAnscaEscrow.buyerLastActionDate + dayInSecond) || localAnscaEscrow.buyerNbrVar == _discount))
                ||
                (isBuyerParty(localAnscaEscrow, msg.sender) && 
                localAnscaEscrow.sellerLastAction == Action.DISCOUNT_REQUEST &&
                localAnscaEscrow.sellerLastActionDate > (localAnscaEscrow.startTimestamp + localAnscaEscrow.deliveryTime) &&
                (block.timestamp > (localAnscaEscrow.sellerLastActionDate + dayInSecond) || localAnscaEscrow.sellerNbrVar == _discount))
                ) {
                    if((isSellerParty(localAnscaEscrow, msg.sender) && localAnscaEscrow.buyerNbrVar == _discount) || (isBuyerParty(localAnscaEscrow, msg.sender) && localAnscaEscrow.sellerNbrVar == _discount)) {
                        updateAction(localAnscaEscrow, msg.sender, Action.ACCEPT_DISCOUNT_REQUEST, _discount, "");
                    } else {
                        updateAction(localAnscaEscrow, msg.sender, Action.DISCOUNT_REQUEST, _discount, "");
                    }
                localAnscaEscrow.state = State.COMPLETE;
            } else {
                localAnscaEscrow.discount = _discount;
                updateAction(localAnscaEscrow, msg.sender, Action.DISCOUNT_REQUEST, _discount, "");
            }            
        }
        
        anscaEscrowList[_id] = localAnscaEscrow;
    }

    // COMPLETE
    /// @notice Allow both parties to withdraw their funds from the escrow if the case may be. If everything went well and there is no discount, only the seller can make a withdrawal. If there is a discount both the buyer and the seller are able to make a withdrawl. If the seller has CANCELED the escrow, only the buyer can make a withdrawl of all his funds.  
    /// @param _id The escrow ID
    function withdraw(bytes32 _id) external {
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];
        
        //Checks 1 
        bool localIsBuyerParty = isBuyerParty(localAnscaEscrow, msg.sender);
        bool localIsSellerParty = isSellerParty(localAnscaEscrow, msg.sender);
        require(localIsBuyerParty || localIsSellerParty, "40");

        //States 1
        if (isInOrGoingToBeComplete(localAnscaEscrow, false)) {
            localAnscaEscrow.state = State.COMPLETE;
        } else if (localAnscaEscrow.state == State.DISPUTE) {
            uint32 finalDiscount = localAnscaEscrow.discount;
            uint256 bts = block.timestamp;
            if(bts > (localAnscaEscrow.startTimestamp + localAnscaEscrow.deliveryTime + dayInSecond)) {
                if(bts > (localAnscaEscrow.sellerLastActionDate + dayInSecond) && bts > (localAnscaEscrow.buyerLastActionDate + dayInSecond)) {
                    if(localAnscaEscrow.sellerLastAction == Action.DISCOUNT_REQUEST) {
                        finalDiscount = localAnscaEscrow.sellerNbrVar;
                    }
                    if(localAnscaEscrow.buyerLastAction == Action.DISCOUNT_REQUEST && localAnscaEscrow.buyerLastActionDate > localAnscaEscrow.sellerLastActionDate) {
                        finalDiscount = localAnscaEscrow.buyerNbrVar;
                    }                
                    localAnscaEscrow.discount = finalDiscount;
                    localAnscaEscrow.state = State.COMPLETE;
                }
            }            
        }        
        
        //Checks
        require(localAnscaEscrow.state == State.COMPLETE, "41");

        //States 2
        updateAction(localAnscaEscrow, msg.sender, Action.WITHDRAW, 0, "");

        payParty(localAnscaEscrow, localIsBuyerParty ? localAnscaEscrow.buyer : localAnscaEscrow.seller);
    }

    function changeHandler(bytes32 _id, address _address) external {
        if(msg.sender == anscaEscrowList[_id].buyer) {
            require(_address != anscaEscrowList[_id].sellerHandler);
            anscaEscrowList[_id].buyerHandler = _address;
        } else if (msg.sender == anscaEscrowList[_id].seller) {
            require(_address != anscaEscrowList[_id].buyerHandler);
            anscaEscrowList[_id].sellerHandler = _address;
        }
    }

    // ##############################################################
    // #####                                                    #####
    // ####################### Seller actions #######################
    // #####                                                    #####
    // ##############################################################
    
    /// @notice Allow the seller to cancel the escrow. This unlocks all the funds to the buyer
    /// @param _id The escrow ID
    function cancelEscrow(bytes32 _id) external {
        //Checks
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];
        require(isSellerParty(localAnscaEscrow, msg.sender), "60");
        
        //States
        updateAction(localAnscaEscrow, msg.sender, Action.CANCEL, 0, "");
        localAnscaEscrow.discount = 100;
        localAnscaEscrow.state = State.COMPLETE;        
        anscaEscrowList[_id] = localAnscaEscrow;

        //Actions
        payParties(localAnscaEscrow);
    }

    // ONGOING
    /// @notice Allow the seller to make a delivery time change request. This request must be accepted for the new deadline to be taken into account 
    /// @param _id The escrow ID 
    /// @param _deliveryTime The new delivery time proposal
    function proposeNewDeliveryTime(bytes32 _id, uint32 _deliveryTime) external {
        //Checks
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];
        require(isSellerParty(localAnscaEscrow, msg.sender) && _deliveryTime > localAnscaEscrow.deliveryTime, "70");
        isInOrGoingToBeOngoing(localAnscaEscrow, true);

        //States
        updateAction(localAnscaEscrow, msg.sender, Action.NEW_DELIVERY_TIME_REQUEST, _deliveryTime, "");
        anscaEscrowList[_id] = localAnscaEscrow;
    }

    // ##############################################################
    // #####                                                    #####
    // ####################### Buyer actions #######################
    // #####                                                    #####
    // ##############################################################

    // NEW
    /// @notice Allows the buyer to make the deposit in case of a seller escrow creation. Once the deposit is made the escrow goes to the ONGOING state.
    /// @param _id The escrow ID
    function deposit(bytes32 _id, address _handlerAddress) external payable {
        //Checks
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];
        require(localAnscaEscrow.state == State.NEW_SELLER && localAnscaEscrow.seller != msg.sender, "80");

        updateAction(localAnscaEscrow, msg.sender, Action.DEPOSIT, 0, "");
        localAnscaEscrow.buyerHandler = _handlerAddress;
        if(localAnscaEscrow.native) {
            nativeDepositInternal(localAnscaEscrow);
        } else {
            depositInternal(localAnscaEscrow);  
        }        
    }

    function nativeDepositInternal(AnscaEscrow memory localAnscaEscrow) internal {
        //Checks
        require(localAnscaEscrow.native && msg.value >= localAnscaEscrow.amount, "90");

        //States
        preDeposit(localAnscaEscrow);

        //Actions
        payable(localAnscaEscrow.depositContract).transfer(localAnscaEscrow.amountMinusFee);
        payable(feeCollectorAddress).transfer(localAnscaEscrow.amount - localAnscaEscrow.amountMinusFee);
    }

    function depositInternal(AnscaEscrow memory localAnscaEscrow) internal {
        //Checks 1        
        require(!localAnscaEscrow.native, "82");

        //States
        preDeposit(localAnscaEscrow);
        
        //Actions
        IERC20 crypto = IERC20(address(localAnscaEscrow.tokenAddress));      
        bool success = crypto.transferFrom(msg.sender, localAnscaEscrow.depositContract, localAnscaEscrow.amountMinusFee);
        success = crypto.transferFrom(msg.sender, feeCollectorAddress, localAnscaEscrow.amount - localAnscaEscrow.amountMinusFee);
        require(success);
    }

    function preDeposit(AnscaEscrow memory localAnscaEscrow) internal {  
        //Checks
        require(localAnscaEscrow.seller != msg.sender, "81");

        //States        
        if(localAnscaEscrow.state == State.NEW_SELLER) {
            localAnscaEscrow.buyer = msg.sender;
        }
        startEscrow(localAnscaEscrow);     
        ownerEscrowMapping[msg.sender].push(localAnscaEscrow.id);

        anscaEscrowList[localAnscaEscrow.id] = localAnscaEscrow;
    }

    // ONGOING
    /// @notice Enable the buyer to accept a previous delivery time change request made by the seller. When accepted, the new delivery time replace the previous one
    /// @param _id The escrow ID
    function acceptNewDeliveryTime(bytes32 _id) external {
        //Checks
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];
        require(isBuyerParty(localAnscaEscrow, msg.sender) && localAnscaEscrow.sellerLastAction == Action.NEW_DELIVERY_TIME_REQUEST && localAnscaEscrow.buyerLastActionDate < localAnscaEscrow.sellerLastActionDate, "100");
        isInOrGoingToBeOngoing(localAnscaEscrow, true);

        //States
        updateAction(localAnscaEscrow, msg.sender, Action.ACCEPT_NEW_DELIVERY_TIME_REQUEST, 0, "");
        localAnscaEscrow.deliveryTime = localAnscaEscrow.sellerNbrVar;
        anscaEscrowList[_id] = localAnscaEscrow;
    }

    // ONGOING
    /// @notice Allow the buyer to lock or unlock an escrow. A locked escrow will automatically go in the dispute state at the end of teh delivery time
    /// @param _id The escrow ID
    /// @param _lock True to lock, false to unlock
    function lock(bytes32 _id, bool _lock) external {
        //Checks
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];
        require(isBuyerParty(localAnscaEscrow, msg.sender), "110");
        isInOrGoingToBeOngoing(localAnscaEscrow, true);

        //States
        if(_lock) {
            localAnscaEscrow.state = State.ONGOING_LOCKED;
            localAnscaEscrow.lockTimestamp = block.timestamp;
            emitACEEvent(localAnscaEscrow.buyer, localAnscaEscrow.buyer, localAnscaEscrow.seller, _id, Action.LOCK); 
        } else {
            localAnscaEscrow.state = State.ONGOING;
            localAnscaEscrow.unlockTimestamp = block.timestamp;
            emitACEEvent(localAnscaEscrow.buyer, localAnscaEscrow.buyer, localAnscaEscrow.seller, _id, Action.UNLOCK); 
        }  
        anscaEscrowList[_id] = localAnscaEscrow;
    }

    // ONGOING
    /// @notice Enable the buyer to validate the escrow before the end of the delivery time. It will passes the escrow in the complete state and allow the parties to withdraw there funds
    /// @param _id The escrow ID
    function validateEscrow(bytes32 _id) external {
        //Checks
        AnscaEscrow memory localAnscaEscrow = anscaEscrowList[_id];
        require(isBuyerParty(localAnscaEscrow, msg.sender), "130");
        isInOrGoingToBeOngoing(localAnscaEscrow, true);

        //States
        updateAction(localAnscaEscrow, msg.sender, Action.VALIDATE, 0, "");
        localAnscaEscrow.state = State.COMPLETE;        
        anscaEscrowList[_id] = localAnscaEscrow;

        //Actions
        payParties(localAnscaEscrow);
    }

    // ##############################################################
    // #####                                                    #####
    // #################### Privileged actions ######################
    // #####                                                    #####
    // ##############################################################

    function changeFeeCollectorAddress(address _adr) external {
        require(msg.sender == owner);
        feeCollectorAddress = _adr;
    }

    function changeFee(uint256 _fee) external {
        require(msg.sender == owner && _fee <= 100);// 100 = 1%
        FEE = _fee;
    }

    function pause(bool _pause) external {
        require(msg.sender == owner);
        paused = _pause;
    }

    // ##############################################################
    // #####                                                    #####
    // ########################### Internals  #######################
    // #####                                                    #####
    // ##############################################################

    function isBuyerParty(AnscaEscrow memory _localAnscaEscrow, address _address) internal pure returns(bool) {
        return _localAnscaEscrow.buyer == _address || (_address != address(0) && _localAnscaEscrow.buyerHandler == _address);
    }

    function isSellerParty(AnscaEscrow memory _localAnscaEscrow, address _address) internal pure returns(bool) {
        return _localAnscaEscrow.seller == _address || (_address != address(0) && _localAnscaEscrow.sellerHandler == _address);
    }

    function payParties(AnscaEscrow memory _localAnscaEscrow) internal {
        if(_localAnscaEscrow.discount > 0) {
            payParty(_localAnscaEscrow, _localAnscaEscrow.buyer);
        }
        if(_localAnscaEscrow.discount < 100) {
            payParty(_localAnscaEscrow, _localAnscaEscrow.seller);            
        }
    }

    function payParty(AnscaEscrow memory _localAnscaEscrow, address _partyAddress) internal {
        require((_partyAddress == _localAnscaEscrow.seller && !_localAnscaEscrow.sellerHasReceivedHisShare && _localAnscaEscrow.discount < 100) || 
                (_partyAddress == _localAnscaEscrow.buyer && !_localAnscaEscrow.buyerHasReceivedHisShare && _localAnscaEscrow.discount > 0)
                , "200");

        if(!_localAnscaEscrow.buyerHasReceivedHisShare && !_localAnscaEscrow.sellerHasReceivedHisShare) {
            emitCompleteEvent(_localAnscaEscrow);
        }

        bool isBuyer = _partyAddress == _localAnscaEscrow.buyer;
        if(isBuyer) {
            anscaEscrowList[_localAnscaEscrow.id].buyerHasReceivedHisShare = true;
        } else {
            anscaEscrowList[_localAnscaEscrow.id].sellerHasReceivedHisShare = true;
        }

        // Actions        
        uint256 part = isBuyer ? _localAnscaEscrow.amountMinusFee * _localAnscaEscrow.discount / 100 : _localAnscaEscrow.amountMinusFee - (_localAnscaEscrow.amountMinusFee * _localAnscaEscrow.discount / 100);
        ACED aced = ACED(payable(_localAnscaEscrow.depositContract)); 
        if(_localAnscaEscrow.native) {
            aced.withdraw(true, _partyAddress, part, address(0));
        } else {
            aced.withdraw(false, _partyAddress, part, _localAnscaEscrow.tokenAddress);
        }
    }

    function startEscrow(AnscaEscrow memory _localAnscaEscrow) internal {
        if(_localAnscaEscrow.state == State.NEW_SELLER) {
            _localAnscaEscrow.buyer = msg.sender;
        }
        _localAnscaEscrow.state = State.ONGOING;
        uint256 bts =  block.timestamp;
        _localAnscaEscrow.startTimestamp = bts;

        reputation[_localAnscaEscrow.seller].escrowNumber++;
        if(reputation[_localAnscaEscrow.seller].firstEscrowDate == 0) {
            reputation[_localAnscaEscrow.seller].firstEscrowDate = bts;
        }
        reputation[_localAnscaEscrow.seller].lastEscrowDate = bts;        

        reputation[_localAnscaEscrow.buyer].escrowNumber++;
        if(reputation[_localAnscaEscrow.buyer].firstEscrowDate == 0) {
            reputation[_localAnscaEscrow.buyer].firstEscrowDate = bts;
        }
        reputation[_localAnscaEscrow.buyer].lastEscrowDate = bts;

        _localAnscaEscrow.depositContract = address(new ACED());
        ACED(payable(_localAnscaEscrow.depositContract)).setBuyer(_localAnscaEscrow.buyer);
        ACED(payable(_localAnscaEscrow.depositContract)).setSeller(_localAnscaEscrow.seller);
    }

    function updateAction(AnscaEscrow memory _anscaEscrow, address _profil, Action _action, uint32 _nbr, bytes32 _str) internal {
        uint256 bts =  block.timestamp;
        address localProfil = isBuyerParty(_anscaEscrow, _profil) ? _anscaEscrow.buyer : _anscaEscrow.seller; 
        if(localProfil == _anscaEscrow.buyer) {
            _anscaEscrow.buyerLastActionDate = bts;
            _anscaEscrow.buyerLastAction = _action;
            _anscaEscrow.buyerNbrVar = _nbr; 
            _anscaEscrow.buyerStrVar = _str;
        } else {
            _anscaEscrow.sellerLastActionDate = bts;
            _anscaEscrow.sellerLastAction = _action;
            _anscaEscrow.sellerNbrVar = _nbr; 
            _anscaEscrow.sellerStrVar = _str;
        }
        emitACEEvent(localProfil, _anscaEscrow.buyer, _anscaEscrow.seller, _anscaEscrow.id, _action);        
    }

    function emitACEEvent(address _from, address _buyer, address _seller, bytes32 _id, Action _action) internal {
        emit ACEEvent(_from, _buyer, _seller, _id, uint8(_action));
    }

    function emitCompleteEvent(AnscaEscrow memory _anscaEscrow) internal {
        emit CompleteEvent(_anscaEscrow.id, _anscaEscrow.amount, _anscaEscrow.dispute, _anscaEscrow.buyer, _anscaEscrow.seller, _anscaEscrow.tokenAddress);
    }
    
    function isInOrGoingToBeOngoing(AnscaEscrow memory _escrow, bool _required) internal view returns(bool) {
        if(isInOrGoingToBeDispute(_escrow, false) || isInOrGoingToBeComplete(_escrow, false)) {
            if(_required) {
            revert("R3");
            } else {
                return false;
            }
        }

        if(_escrow.state != State.ONGOING && _escrow.state != State.ONGOING_LOCKED) {
            if(_required) {
            revert("R4");
            } else {
                return false;
            }
        }
        return true;
    }

    function isInOrGoingToBeDispute(AnscaEscrow memory _escrow, bool _required) internal view returns(bool) {
        if(_escrow.state == State.DISPUTE) {
            if(isInOrGoingToBeComplete(_escrow, false)) {
                if(_required) {
                revert("R5");
                } else {
                    return false;
                }
            }
            return true;
        }

        if(block.timestamp > (_escrow.startTimestamp + _escrow.deliveryTime) && _escrow.state == State.ONGOING_LOCKED)  {
            return true;
        }

        if(_required) {
            revert("R7");
        } else {
            return false;
        }
    }

    function isInOrGoingToBeComplete(AnscaEscrow memory _escrow, bool _required) internal view returns(bool) {

        if(_escrow.state == State.COMPLETE || _escrow.buyerLastAction == Action.VALIDATE) {
            return true;
        }

        uint256 bts = block.timestamp;

        if(            
            _escrow.state == State.ONGOING &&
            _escrow.startTimestamp > 0 &&
            bts > (_escrow.startTimestamp + _escrow.deliveryTime)
        ) {
            return true;
        }

        if(
            _escrow.startTimestamp > 0 &&
            bts > (_escrow.startTimestamp + _escrow.deliveryTime + dayInSecond) &&
            bts > _escrow.sellerLastActionDate + dayInSecond &&
            bts > _escrow.buyerLastActionDate + dayInSecond
        ) {
            return true;
        }

        if(_required) {
            revert("R8");
        } else {
            return false;
        }
    }
}