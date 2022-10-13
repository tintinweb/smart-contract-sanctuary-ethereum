pragma solidity ^0.5.0;
import "./SafeMath.sol";

// Interface real esate
interface IRealEstate {
	function getOwnersOfCert(uint256 _idCertificate)
		external
		view
		returns (address[] memory);

	function getRepresentativeOfOwners(uint256 _idCertificate)
		external
		view
		returns (address);

    // 0: PENDING - 1: ACTIVATE - 2: IN_TRANSACTION
	function getStateOfCert(uint256 _idCertificate) external view returns(uint8);

	function setStateOfCertInTransaction(uint256 _idCertificate) external;

	function setStateOfCertOutTransaction(uint256 _idCertificate) external;

	function transferOwnership(
		uint256 _idCertificate,
		address[] calldata _newOwners
	) external;
}

/**
 * @dev Contract manager transaction of real estate
 */

contract Transaction {

    // ------------------------------ Variables ------------------------------

	using SafeMath for uint256;

	IRealEstate RealEstate;
    uint256 public id;
	address private owner;

    // state of transaction
	enum State {
		DEPOSIT_REQUEST,                // Transaction created
		DEPOSIT_CANCELED_BY_BUYER,      // Buyer cancel transaction, transaction has not been signed
		DEPOSIT_CANCELED_BY_SELLER,     // Seller cancel transaction, transaction has not been signed
		DEPOSIT_SIGNED,                 // seller sign transaction
		DEPOSIT_BROKEN_BY_BUYER,        // Buyer cancel transaction, transaction signed
		DEPOSIT_BROKEN_BY_SELLER,       // Seller cancel transaction, transaction signed
		TRANSFER_REQUEST,               // Buyer transfer remaining amount (same requrest transfer contract)
		TRANSFER_CANCELED_BY_SELLER,    // Seller refuse (same BRAKE_DEPOSIT)
		TRANSFER_SIGNED                 // Seller sign transaction => Finish
	}

    mapping(uint256 => State) public idToState;             // mapping id to state of transaction
	mapping(uint256 => Transaction) public idToTransaction; // mapping id to data of transaction

	struct Transaction {
		address[] buyers;
		address[] sellers;
		uint256 idCertificate;
		uint256 depositPrice;
		uint256 transferPrice;
		uint256 timeStart;
		uint256 timeEnd;
	}

    // -------------------------------- Event --------------------------------
	event TransactionCreated(
		address[] buyers,
		address[] sellers,
		uint256 idTransaction,
		uint256 idCertificate,
		uint256 depositPrice,
		uint256 transferPrice,
		uint256 timeStart,
		uint256 timeEnd
	);

	event DepositSigned(
	    uint256 idTransaction
	);

	event TransactionCanceled(
	    uint256 idTransaction,
	    State state
	);

    event Payment(uint256 idTransaction);

	event TransactionSuccess(
        uint256 idTransaction
	);

	constructor(IRealEstate _realEstateContractAddress) public {
		RealEstate =  IRealEstate(_realEstateContractAddress);
// 		_realEstateContractAddress;
	}

	function setRealEstateContract(IRealEstate _realEstateContractAddress)
		public
	{
		RealEstate = IRealEstate(_realEstateContractAddress);
	}

    // ------------------------------ Core Function ------------------------------
	/**
     * @notice Create transaction (same send request deposit contract)
     * @dev Buyer create transaction and send deposit amount to contract address
     */
	function createTransaction(
		address[] memory _buyers,
		uint256 _idCertificate,
		uint256 _depositPrice,
		uint256 _transferPrice,
		uint256 _depositTime // days
	) public payable {
		require(RealEstate.getStateOfCert(_idCertificate) == 1, "CreateTransaction: Require state of certificate is ACTIVATE");
	   // require(_buyers[0] == msg.sender, "Transaction: Require first buyer is msg.sender");
		require(
			msg.value >= _depositPrice,
			"CreateTransaction: Require value greater than deposit price"
		);
		require(_depositPrice <= _transferPrice, "CreateTransaction: Deposit price must be smaller than transfer price");
		address[] memory owners = RealEstate.getOwnersOfCert(_idCertificate);
		uint256 timeEnd = now + _depositTime * 24 * 60 * 60; // convert days to seconds
		Transaction memory transaction = Transaction({
			buyers: _buyers,
			sellers: owners,
			idCertificate: _idCertificate,
			depositPrice: _depositPrice,
			transferPrice: _transferPrice,
			timeStart: now,
			timeEnd: timeEnd
		});
		id = id.add(1);
		idToTransaction[id] = transaction;
		idToState[id] = State.DEPOSIT_REQUEST;
		emit TransactionCreated(
			_buyers,
			owners,
			id,
			_idCertificate,
			_depositPrice,
			_transferPrice,
			now,
			timeEnd
		);
	}


    /**
     * @notice Accept deposit (same signed the deposit contract)
     * @dev Allow only representative of seller call
     * Seller will receive the deposit amount and set state to SIGNED
     */
	function acceptTransaction(uint256 _idTransaction)
		public
		onlyState(_idTransaction, State.DEPOSIT_REQUEST)
	{
		Transaction memory transaction = idToTransaction[_idTransaction];
		require(now <= transaction.timeEnd, "AcceptTransaction: Transaction has expired");
		address representativeOwners = transaction.sellers[0];
		require(
			(msg.sender == representativeOwners),
			"AcceptTransaction: require representative of owner"
		);
		msg.sender.transfer(transaction.depositPrice);
		idToState[_idTransaction] = State.DEPOSIT_SIGNED;
		RealEstate.setStateOfCertInTransaction(transaction.idCertificate);
		emit DepositSigned(_idTransaction);
	}

	/**
	 * @notice Buyer cancel transaction
	 * @dev Only transactions are subject to change (can modify state of transaction)
     * if transaction not signed => refund deposit amount to buyers
     * if transaction signed => buyer lost the deposit price
	 */
    function buyerCancelTransaction(uint256 _idTransaction) public allowModify(_idTransaction){
        Transaction memory transaction = idToTransaction[_idTransaction];
        require(msg.sender == transaction.buyers[0],"BuyerCancelTransaction: require representative buyers");
        // if state of transaction DEPOSIT_REQUEST => cancel and recive deposit price
        if(idToState[_idTransaction] == State.DEPOSIT_REQUEST){
            msg.sender.transfer(transaction.depositPrice);
            idToState[_idTransaction] = State.DEPOSIT_CANCELED_BY_BUYER;
        }
        else if(idToState[_idTransaction] == State.DEPOSIT_SIGNED){
            idToState[_idTransaction] = State.DEPOSIT_BROKEN_BY_BUYER;
        }
        else if(idToState[_idTransaction] == State.TRANSFER_REQUEST){
            msg.sender.transfer(transaction.transferPrice.sub(transaction.depositPrice).add(transaction.transferPrice.div(200)));
            idToState[_idTransaction] = State.DEPOSIT_BROKEN_BY_BUYER;
        }
        RealEstate.setStateOfCertOutTransaction(transaction.idCertificate);
		emit TransactionCanceled(_idTransaction, idToState[_idTransaction]);
    }

	/**
	 * @notice Seller cancel transaction
	 * @dev Only transactions are subject to change (can modify state of transaction)
     * if transaction not signed => refund deposit amount to buyers
     * if transaction signed => seller send compensation = 2 * deposit price to buyer
	 */
    function sellerCancelTransaction(uint256 _idTransaction) public payable allowModify(_idTransaction){
        Transaction memory transaction = idToTransaction[_idTransaction];
        require(msg.sender == transaction.sellers[0],"SellerCancelTransaction: require representative sellers");
        // seller refuse DEPOSIT_REQUEST of buyer => buyers recive depositPrice previously transferred
	    if(idToState[_idTransaction] == State.DEPOSIT_REQUEST){
	        address payable buyer = address(uint160(transaction.buyers[0]));
	        buyer.transfer(transaction.depositPrice);
	        idToState[_idTransaction] = State.DEPOSIT_CANCELED_BY_SELLER;
	    }
		    // seller break transaction (deposit contract) => compensation for buyer
	    else if(idToState[_idTransaction] == State.DEPOSIT_SIGNED){
	        uint256 compensationAmount = transaction.depositPrice.mul(2);
		require(
			msg.value >= compensationAmount,
			"SellerCancelTransaction: Value must be greater than 2 * deposit price"
		    );
	    	address payable buyer = address(uint160(transaction.buyers[0]));
		    buyer.transfer(compensationAmount);
		    idToState[_idTransaction] = State.DEPOSIT_BROKEN_BY_SELLER;
	    }
        // if buyer sended payment => refund payment + 0.5% tax and compensation amount
        else if(idToState[_idTransaction] == State.TRANSFER_REQUEST){
	        uint256 compensationAmount = transaction.depositPrice.mul(2);
            uint256 transferAmount = transaction.transferPrice.sub(transaction.depositPrice);
            uint256 totalAmount = transferAmount.add(compensationAmount).add(transaction.transferPrice.div(200));// value return to buyer
		require(
			msg.value >= compensationAmount,
			"SellerCancelTransaction: Value must be greater than 2 * deposit price"
		    );
            require(address(this).balance >= totalAmount, "Balace contract address not enough");
	    	address payable buyer = address(uint160(transaction.buyers[0]));
		    buyer.transfer(totalAmount);
		    idToState[_idTransaction] = State.TRANSFER_CANCELED_BY_SELLER;
	    }
        RealEstate.setStateOfCertOutTransaction(transaction.idCertificate);
		emit TransactionCanceled(_idTransaction, idToState[_idTransaction]);
    }

	/**
	 * @notice Cancel transaction
	 * @dev Only transactions are subject to change (can modify state of transaction)
     * if transaction not signed => refund deposit amount to buyers
     * if transaction signed and sellers call => send compensation for buyers
	 */
	function cancelTransaction(uint256 _idTransaction)
		public
		payable
 		allowModify(_idTransaction)
	{
		Transaction memory transaction = idToTransaction[_idTransaction];
		if (msg.sender == transaction.buyers[0]) {
		    // buyer cancel DEPOSTI_REQUEST and recive depositPrice
		    if(idToState[_idTransaction] == State.DEPOSIT_REQUEST){
		        msg.sender.transfer(transaction.depositPrice);
			    idToState[_idTransaction] = State.DEPOSIT_CANCELED_BY_BUYER;
		    }
		    // buyer break transaction (deposit contract) => never recive the depositPrice previously transferred
			else if(idToState[_idTransaction] == State.DEPOSIT_SIGNED){
			    idToState[_idTransaction] = State.DEPOSIT_BROKEN_BY_BUYER;
			}
            else if(idToState[_idTransaction] == State.TRANSFER_REQUEST){
                msg.sender.transfer(transaction.transferPrice.sub(transaction.depositPrice).add(transaction.transferPrice.div(200)));
                idToState[_idTransaction] = State.DEPOSIT_BROKEN_BY_BUYER;
            }
		} else if (msg.sender == transaction.sellers[0]) {
		    // seller refuse DEPOSIT_REQUEST of buyer => buyers recive depositPrice previously transferred
		    if(idToState[_idTransaction] == State.DEPOSIT_REQUEST){
		        address payable buyer = address(uint160(transaction.buyers[0]));
		        buyer.transfer(transaction.depositPrice);
		        idToState[_idTransaction] = State.DEPOSIT_CANCELED_BY_SELLER;
		    }
		    // seller break transaction (deposit contract) => compensation for buyer
		    else if(idToState[_idTransaction] == State.DEPOSIT_SIGNED){
		        uint256 compensationAmount = transaction.depositPrice.mul(2);
			require(
				msg.value >= compensationAmount,
				"CancelTransaction: Value must be greater compensation amount."
			    );
		    	address payable buyer = address(uint160(transaction.buyers[0]));
			    buyer.transfer(compensationAmount);
			    idToState[_idTransaction] = State.DEPOSIT_BROKEN_BY_BUYER;
		    }
            // if buyer sended payment => refund payment and compensation
            else if(idToState[_idTransaction] == State.TRANSFER_REQUEST){
		        uint256 compensationAmount = transaction.depositPrice.mul(2);
                uint256 totalAmount = transaction.transferPrice.add(compensationAmount).add(transaction.transferPrice.div(200));
			require(
				msg.value >= compensationAmount,
				"CancelTransaction: Value must be greater than compensation amount."
			    );
		    	address payable buyer = address(uint160(transaction.buyers[0]));
			    buyer.transfer(totalAmount);
			    idToState[_idTransaction] = State.TRANSFER_CANCELED_BY_SELLER;
		    }
		} else {
			revert("CancelTransaction: You're not permission.");
		}
		RealEstate.setStateOfCertOutTransaction(transaction.idCertificate);
		emit TransactionCanceled(_idTransaction, idToState[_idTransaction]);

	}


	/**
     * @notice Payment transaction
     * @dev Only representative of buyer (buyer[0])
     * buyer send remaining amount of transction to contract address (same sign transfer contract)
     */
	function payment(uint256 _idTransaction)
		public
		payable
		onlyState(_idTransaction, State.DEPOSIT_SIGNED)
	{
		Transaction memory transaction = idToTransaction[_idTransaction];
		require(now <= transaction.timeEnd, "Payment: Transaction has expired.");
		address representativeBuyer = transaction.buyers[0];
		require(
			msg.sender == representativeBuyer,
			"Payment: Only representative of buyers."
		);
		uint256 remainingAmount = transaction.transferPrice.sub(
			transaction.depositPrice
		);
		uint256 registrationTax = transaction.transferPrice.div(200); // 0.5% tax
		uint256 totalAmount = remainingAmount.add(registrationTax);
		require(
			(msg.value >= totalAmount),
			"Payment: Value must be greater than total amount"
		);
		idToState[_idTransaction] = State.TRANSFER_REQUEST;
        emit Payment(_idTransaction);
    }


	/**
     * @notice Confirm transaction
     * @dev Seller confirm transaction recive remaining amount of transaction
     * and transfer ownership of certificate to buyer
     */
	function confirmTransaction(uint256 _idTransaction)
		public payable
		onlyState(_idTransaction, State.TRANSFER_REQUEST)
	{
		Transaction memory transaction = idToTransaction[_idTransaction];
		require(now  <= transaction.timeEnd, "ConfirmTransaction: Transaction has expired.");
		address representativeSellers = transaction.sellers[0];
		require(
			msg.sender == representativeSellers,
			"ConfirmTransaction: Require representative of sellers."
		);
		uint256 personalIncomeTax = transaction.transferPrice.div(50); // 2% tax
		uint256 remainingAmount = transaction.transferPrice.sub(transaction.depositPrice);
		// remaining amount < personal tax => it must pay more.
		if(remainingAmount < personalIncomeTax){
			uint256 costsIncurred = personalIncomeTax - remainingAmount;
			require(msg.value >= costsIncurred, "ConfirmTransaction: Value must be greater costs incurred.");
		}
		else{
			uint256 valueAfterTax = remainingAmount - personalIncomeTax;
			msg.sender.transfer(valueAfterTax);
		}
		RealEstate.transferOwnership(
			transaction.idCertificate,
			transaction.buyers
		);
        idToState[_idTransaction] = State.TRANSFER_SIGNED;
		RealEstate.setStateOfCertOutTransaction(transaction.idCertificate);
        emit TransactionSuccess(_idTransaction);
	}

    // ------------------------------ View Function ------------------------------
    /**
     * @notice Get information of transaction
     */
	function getTransaction(uint256 _idTransaction)
		public
		view
		returns (
			address[] memory,
			address[] memory,
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		Transaction memory transaction = idToTransaction[_idTransaction];
		return (
			transaction.buyers,
			transaction.sellers,
			transaction.idCertificate,
			transaction.depositPrice,
			transaction.transferPrice,
			transaction.timeStart,
			transaction.timeEnd
		);
	}

    // ------------------------------ Mofifier ------------------------------
    modifier onlyState(uint256 _idTransaction, State _state) {
        require(
            (idToState[_idTransaction] == _state),
            "OnlyState: Require state."
        );
        _;
    }

    modifier allowModify(uint256 _idTransaction){
        require((idToState[_idTransaction] == State.DEPOSIT_REQUEST || idToState[_idTransaction] == State.DEPOSIT_SIGNED || idToState[_idTransaction] == State.TRANSFER_REQUEST),"AllowModify: Transaction can't allow modifier.");
        _;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}