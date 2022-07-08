//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IERC20.sol";

contract PTP_Lending {
	uint136 private Admin_Password;
	uint256 private Tokens = 0;
	uint256 private Number_Document = 0;
	address private Owner;
	address private Owner_two;

	//==========================
	struct Holder {
		string Name;
		uint256 Amount_Holder; //This variable holds the amount of user money .
		uint256 Decimal;
		uint256 Transaction_Fee; //This variable holds the cost of transactions
		address erc20TokenAddress; //This variable stores the contract address of a digital currency .
		IERC20 erc20Token;
		AggregatorV3Interface priceFeed;
	}
	struct Document {
		uint256 Id_Document;
		uint256 Id_Token;
		uint256 Id_Token_Bail;
		uint256 Amount_Document;
		uint256 Amount_Bail;
		uint256 Date_Document;
		address Receiver;
		address Creator;
		bool Open_Document;
		uint8 Liquidation;
		uint256 Currency_Received;
		uint256 Amount_Received;
		uint256 Validity_Document;
	}
	struct Transaction {
		uint256 Id_Transaction;
	}

	mapping(address => uint256) private _Count;
	mapping(uint256 => Transaction) private _Transactions;
	mapping(address => mapping(uint256 => Transaction)) private _ID_Transactions;
	mapping(uint256 => Holder) private _Holders;
	mapping(uint256 => Document) public _Documents;
	mapping(address => mapping(uint256 => Holder)) private Account;
	//=================================
	event Document_Operation(
		uint256 _ID,
		address indexed _From,
		address indexed _To,
		string _Type_transaction,
		uint256 _Value
	);
	event Deposit(
		address indexed _From,
		address indexed _To,
		string _Type_transaction,
		uint256 _Value
	);
	event Withdraw(
		address indexed _From,
		address indexed _To,
		string _Type_transaction,
		uint256 _Value
	);
	event AggregatorAddressChanged(address indexed newAddress);

	//==================================
	constructor(uint136 _Pass, address _Address) public {
		Owner = msg.sender;
		Owner_two = _Address;
		Admin_Password = _Pass;
	}

	//===================================

	function set_TokenAddress(
		string calldata _Name_Token,
		address _tokenAddress,
		uint256 _decimal,
		uint256 _fee,
		address chainlink
	) external {
		require(Owner == msg.sender);
		Tokens++;
		require(_tokenAddress != address(0)); // Checks that "_tokenAddress" is not zero
		_Holders[Tokens].Name = _Name_Token;
		_Holders[Tokens].erc20TokenAddress = _tokenAddress; // Sets "erc20TokenAddress"
		_Holders[Tokens].erc20Token = IERC20(_Holders[Tokens].erc20TokenAddress); // Sets "erc20Token"
		_Holders[Tokens].Decimal = _decimal;
		_Holders[Tokens].Transaction_Fee = _fee;
		_Holders[Tokens].priceFeed = AggregatorV3Interface(chainlink);
	}

	function Change_owner(address _Address, uint136 _Pass) external {
		require(_Address == Owner_two && _Pass == Admin_Password);
		Owner = msg.sender;
	}

	function Deposit_money(uint256 _id, uint256 _value) public payable {
		require(_value > 0 && _id > 0 && _id <= Tokens);
		if (_id == 1) {
			Account[msg.sender][1].Amount_Holder += _value;
			emit Deposit(msg.sender, address(this), "Deposit", msg.value);
		} else {
			require(_Holders[_id].erc20TokenAddress != address(0)); // Checks that "erc20TokenAddress" is set
			uint256 _allowedValue = _Holders[_id].erc20Token.allowance(
				msg.sender,
				address(this)
			); // Checks for allowed value
			require(_value <= _allowedValue); // checks that "_value" is allowed
			bool A = _Holders[_id].erc20Token.transferFrom(
				msg.sender,
				address(this),
				_value
			); //Token payment done!
			if (A == true) {
				Account[msg.sender][_id].Amount_Holder += _value;
				emit Deposit(msg.sender, address(this), "Deposit", _value);
			}
		}
	}

	function Withdraw_money(uint256 _id, uint256 _value) public {
		uint256 Wd = _value;
		require(
			_value <= Account[msg.sender][_id].Amount_Holder &&
				_value > 0 &&
				_id <= Tokens
		);
		if (_id == 1) {
			Account[msg.sender][1].Amount_Holder -= Wd;
			payable(msg.sender).transfer(Wd);
			emit Withdraw(address(this), msg.sender, " Withdraw", Wd);
		} else {
			Account[msg.sender][_id].Amount_Holder -= Wd;
			bool A = _Holders[_id].erc20Token.transfer(msg.sender, Wd);
			if (A == true) {
				emit Withdraw(address(this), msg.sender, " Withdraw", Wd);
			}
		}
	}

	//=======================================A number of functional functions (types view) are written below this line.

	function getLatestPrice(uint256 _Key) public view returns (uint256) {
		(, int256 price, , , ) = _Holders[_Key].priceFeed.latestRoundData();
		return uint256(price / 10**8);
	}

	function Show_Total_Document() public view returns (uint256) {
		return (Number_Document);
	}

	function balanceOf_Account(uint256 _id) public view returns (uint256) {
		return (Account[msg.sender][_id].Amount_Holder);
	}

	function Show_Transactions()
		public
		view
		returns (
			uint256,
			string memory,
			address,
			string memory,
			address
		)
	{
		return (
			_ID_Transactions[msg.sender][_Count[msg.sender]].Id_Transaction,
			"From:",
			_Documents[
				_ID_Transactions[msg.sender][_Count[msg.sender]].Id_Transaction
			].Creator,
			"To:",
			_Documents[
				_ID_Transactions[msg.sender][_Count[msg.sender]].Id_Transaction
			].Receiver
		);
	}

	function Show_Specific_transaction(uint256 _id)
		public
		view
		returns (uint256)
	{
		require(_id <= _Count[msg.sender], "There is probably no such transaction");
		return (_ID_Transactions[msg.sender][_id].Id_Transaction);
	}

	function Show_Type_of_currency_received(uint256 _Id_Transaction)
		public
		view
		returns (
			string memory,
			string memory,
			uint256
		)
	{
		//  string memory,uint ,string memory,string memory,uint){
		return (
			"Type of currency received :",
			Document_currency_type(_Id_Transaction),
			_Documents[_Id_Transaction].Amount_Document
		); //"Date of payment:",_Documents[_Id_Transaction].Date_Document , "Type of currency traded:" ,
	}

	function Show_Type_of_collateral(uint256 _Id_Transaction)
		public
		view
		returns (
			string memory,
			string memory,
			uint256
		)
	{
		//  string memory,uint ,string memory,string memory,uint){
		return (
			"Type of collateral:",
			Type_collateral(_Id_Transaction),
			_Documents[_Id_Transaction].Amount_Bail
		); //"Date of payment:",_Documents[_Id_Transaction].Date_Document , "Type of currency traded:" ,
	}

	function Show_Date_of_payment(uint256 _Id_Transaction)
		public
		view
		returns (string memory, uint256)
	{
		return ("Date of payment :", _Documents[_Id_Transaction].Date_Document);
	}

	function show_Type_currency_traded(uint256 _Id_Transaction)
		public
		view
		returns (
			string memory,
			string memory,
			uint256
		)
	{
		return (
			"Type of currency traded:",
			Type_currency_traded(_Id_Transaction),
			_Documents[_Id_Transaction].Amount_Received
		);
	}

	function Show_liquidation_status(uint256 _Id_Transaction)
		public
		view
		returns (string memory, string memory)
	{
		return ("Liquidation status:", Type_liquidation_status(_Id_Transaction));
	}

	function Show_your_entire_transaction()
		public
		view
		returns (string memory, uint256)
	{
		return ("Your entire transaction:", _Count[msg.sender]);
	}

	//The following function returns public documents (without recipient address).
	//This function shows the ID of documents that have no address.
	function Show_Public_documents(uint256 _Counter)
		public
		view
		returns (uint256)
	{
		require(
			_Documents[_Counter].Open_Document == false &&
				block.timestamp <= _Documents[_Counter].Validity_Document &&
				_Documents[_Counter].Validity_Document > 0
		);
		return (_Documents[_Counter].Id_Document);
	}

	function Document_currency_type(uint256 _Id)
		private
		view
		returns (string memory)
	{
		for (uint256 i = 0; i <= Tokens; i++) {
			if (_Documents[_Id].Id_Token == i) {
				return (_Holders[i].Name);
			}
		}
	}

	function Type_collateral(uint256 _Id) private view returns (string memory) {
		for (uint256 i = 0; i <= Tokens; i++) {
			if (_Documents[_Id].Id_Token_Bail == i) {
				return (_Holders[i].Name);
			}
		}
	}

	function Type_currency_traded(uint256 _Id)
		private
		view
		returns (string memory)
	{
		for (uint256 i = 0; i <= Tokens; i++) {
			if (_Documents[_Id].Currency_Received == i) {
				return (_Holders[i].Name);
			}
		}
	}

	function Type_liquidation_status(uint256 _Id)
		private
		view
		returns (string memory)
	{
		if (_Documents[_Id].Liquidation == 1) {
			return ("Active");
		} else {
			return ("Inactive");
		}
	}

	//==================================================
	function Creation_Credit_Document_One_way(
		uint256 _id_money_Document,
		uint256 _value_Amount_Document,
		uint256 _value_Date,
		address _value_Receiver,
		uint256 _id_Bail,
		uint256 _value_Amount_Bail,
		uint8 _value_Liquidation
	) external {
		require(_Holders[_id_money_Document].erc20TokenAddress != address(0));
		require(_Holders[_id_Bail].erc20TokenAddress != address(0));
		require(
			_value_Amount_Document > 0 &&
				_value_Date > 0 &&
				_value_Receiver != address(0)
		);
		require(
			_value_Amount_Bail > _Holders[_id_Bail].Transaction_Fee &&
				(_value_Amount_Bail + _Holders[_id_Bail].Transaction_Fee) <=
				Account[msg.sender][_id_Bail].Amount_Holder,
			"You do not have enough funds to register this transaction on this platform."
		);
		Account[msg.sender][_id_Bail].Amount_Holder -= (_value_Amount_Bail +
			_Holders[_id_Bail].Transaction_Fee);
		Number_Document++;
		Document memory _Doc;
		_Doc.Id_Document = Number_Document;
		_Doc.Id_Token = _id_money_Document;
		_Doc.Id_Token_Bail = _id_Bail;
		_Doc.Amount_Document = _value_Amount_Document;
		_Doc.Amount_Bail = _value_Amount_Bail;
		_Doc.Date_Document = _value_Date;
		_Doc.Receiver = _value_Receiver;
		_Doc.Creator = msg.sender;
		_Doc.Liquidation = _value_Liquidation;
		_Doc.Open_Document = true;
		_Doc.Currency_Received = 0;
		_Doc.Amount_Received = 0;
		_Doc.Validity_Document = 0;
		_Documents[Number_Document] = _Doc;
		Account[Owner][_id_Bail].Amount_Holder += _Holders[_id_Bail]
			.Transaction_Fee;
		_Count[msg.sender] += 1;
		_Count[_value_Receiver] += 1;
		_ID_Transactions[msg.sender][_Count[msg.sender]]
			.Id_Transaction = Number_Document;
		_ID_Transactions[_value_Receiver][_Count[_value_Receiver]]
			.Id_Transaction = Number_Document;
		emit Document_Operation(
			Number_Document,
			msg.sender,
			_value_Receiver,
			" Creation Credit Document One way",
			_value_Amount_Document
		);
	}

	function Creation_Credit_Document_Bilateral(
		uint256 _id_money_Document,
		uint256 _value_Amount_Document,
		uint256 _value_Date,
		uint256 _id_Bail,
		uint256 _value_Amount_Bail,
		uint8 _value_Liquidation,
		uint32 _id_Currency_Received,
		uint256 _value_Amount_Received
	) external {
		require(_Holders[_id_money_Document].erc20TokenAddress != address(0));
		require(_Holders[_id_Bail].erc20TokenAddress != address(0));
		require(
			_value_Amount_Bail > _Holders[_id_Bail].Transaction_Fee &&
				(_value_Amount_Bail + _Holders[_id_Bail].Transaction_Fee) <=
				Account[msg.sender][_id_Bail].Amount_Holder,
			"You do not have enough funds to register this transaction on this platform."
		);
		require(_value_Amount_Document > 0 && _value_Date > 0);
		require(
			_value_Amount_Received > 0 &&
				_id_Currency_Received > 0 &&
				_id_Currency_Received <= Tokens
		);
		// require ( _value_Amount_Received <= Account[ _value_Receiver ][_id_Currency_Received ].Amount_Holder);

		Number_Document++;
		Document memory _Doc;
		_Doc.Id_Document = Number_Document;
		_Doc.Id_Token = _id_money_Document;
		_Doc.Id_Token_Bail = _id_Bail;
		_Doc.Amount_Document = _value_Amount_Document;
		_Doc.Amount_Bail = _value_Amount_Bail;
		_Doc.Date_Document = _value_Date;
		_Doc.Receiver = address(0);
		_Doc.Creator = msg.sender;
		_Doc.Liquidation = _value_Liquidation;
		_Doc.Open_Document = false;
		_Doc.Currency_Received = _id_Currency_Received;
		_Doc.Amount_Received = _value_Amount_Received;
		_Doc.Validity_Document = (block.timestamp + 172800);
		_Documents[Number_Document] = _Doc;
		_Count[msg.sender] += 1;
		_ID_Transactions[msg.sender][_Count[msg.sender]]
			.Id_Transaction = Number_Document;
		//  _Count[_value_Receiver] += 1 ;
		// _ID_Transactions[_value_Receiver][_Count[_value_Receiver]].Id_Transaction = Number_Document;
		//emit  Document_Operation(Number_Document , msg.sender , _value_Receiver  , " Creation Credit Document Bilateral" , _value_Amount_Document );
	}

	function Confirm_Transaction(uint256 _Id_Transaction)
		external
		returns (bool)
	{
		require(
			_Documents[_Id_Transaction].Id_Document == _Id_Transaction &&
				_Documents[_Id_Transaction].Open_Document == false &&
				block.timestamp <= _Documents[_Id_Transaction].Validity_Document,
			"This transaction is probably out of date or you entered the transaction ID incorrectly"
		);
		require(
			(_Documents[_Id_Transaction].Amount_Bail +
				_Holders[_Documents[_Id_Transaction].Id_Token_Bail].Transaction_Fee) <=
				Account[_Documents[_Id_Transaction].Creator][
					_Documents[_Id_Transaction].Id_Token_Bail
				].Amount_Holder &&
				_Documents[_Id_Transaction].Amount_Received <=
				Account[msg.sender][_Documents[_Id_Transaction].Currency_Received]
					.Amount_Holder,
			"The creator may not have sufficient collateral for the transaction."
		); //_Holders[_Documents[_Id_Transaction].Currency_Received].erc20Token.balanceOf(msg.sender)){
		Account[_Documents[_Id_Transaction].Creator][
			_Documents[_Id_Transaction].Id_Token_Bail
		].Amount_Holder -= (_Documents[_Id_Transaction].Amount_Bail +
			_Holders[_Documents[_Id_Transaction].Id_Token_Bail].Transaction_Fee);
		Account[msg.sender][_Documents[_Id_Transaction].Currency_Received]
			.Amount_Holder -= _Documents[_Id_Transaction].Amount_Received;
		Account[_Documents[_Id_Transaction].Creator][
			_Documents[_Id_Transaction].Currency_Received
		].Amount_Holder += _Documents[_Id_Transaction].Amount_Received;
		_Documents[_Id_Transaction].Open_Document = true;
		_Documents[_Id_Transaction].Receiver = msg.sender;
		_Count[msg.sender] += 1;
		_ID_Transactions[msg.sender][_Count[msg.sender]]
			.Id_Transaction = _Documents[_Id_Transaction].Id_Document;
		Account[Owner][_Documents[_Id_Transaction].Id_Token_Bail]
			.Amount_Holder += _Holders[_Documents[_Id_Transaction].Id_Token_Bail]
			.Transaction_Fee;
		emit Document_Operation(
			_Documents[_Id_Transaction].Id_Document,
			msg.sender,
			_Documents[_Id_Transaction].Creator,
			" Bilateral transaction approval",
			_Documents[_Id_Transaction].Amount_Received
		);
		return (true);
	}

	/*The following function (edit) is applicable to increase the amount of bail of a document but can not change the recipient of the document.
      Note that you can not reduce the amount of bail, but you can increase it.
      This is used to prevent the liquidation of the collateral*/
	function Edit_Credit_Document(uint256 _id, uint256 _Value) external {
		require(_Documents[_id].Open_Document == true);
		require(
			msg.sender == _Documents[_id].Creator,
			"Not applicable because either the document ID is incorrect or you are not the creator of the document."
		);
		require(
			_Value <=
				Account[msg.sender][_Documents[_id].Id_Token_Bail].Amount_Holder,
			"Your budget for this transaction is not fraudulent. Please increase your account first"
		);
		Account[msg.sender][_Documents[_id].Id_Token_Bail].Amount_Holder -= _Value;
		_Documents[_id].Amount_Bail += _Value;
	}

	/* The following function allows the user to close the long-term transaction created in the above function.
      Of course, to close a long-term transaction, this function checks the conditions in which it is registered.*/
	function Withdraw_Document(uint256 _Id_Transaction) external {
		require(
			_Documents[_Id_Transaction].Open_Document == true &&
				block.timestamp > _Documents[_Id_Transaction].Date_Document &&
				msg.sender == _Documents[_Id_Transaction].Receiver
		);
		if (
			_Documents[_Id_Transaction].Amount_Document <=
			Account[_Documents[_Id_Transaction].Creator][
				_Documents[_Id_Transaction].Id_Token
			].Amount_Holder
		) {
			Account[_Documents[_Id_Transaction].Creator][
				_Documents[_Id_Transaction].Id_Token
			].Amount_Holder -= _Documents[_Id_Transaction].Amount_Document;
			Account[_Documents[_Id_Transaction].Creator][
				_Documents[_Id_Transaction].Id_Token_Bail
			].Amount_Holder += _Documents[_Id_Transaction].Amount_Bail;
			_Documents[_Id_Transaction].Amount_Document -= _Holders[
				_Documents[_Id_Transaction].Id_Token
			].Transaction_Fee;
			Account[_Documents[_Id_Transaction].Receiver][
				_Documents[_Id_Transaction].Id_Token
			].Amount_Holder += _Documents[_Id_Transaction].Amount_Document;
			_Documents[_Id_Transaction].Open_Document = false;
			Account[Owner][_Documents[_Id_Transaction].Id_Token]
				.Amount_Holder += _Holders[_Documents[_Id_Transaction].Id_Token]
				.Transaction_Fee;
			emit Document_Operation(
				_Documents[_Id_Transaction].Id_Document,
				_Documents[_Id_Transaction].Creator,
				msg.sender,
				"Withdraw_Document",
				_Documents[_Id_Transaction].Amount_Document
			);
		} else {
			_Documents[_Id_Transaction].Amount_Bail -= _Holders[
				_Documents[_Id_Transaction].Id_Token_Bail
			].Transaction_Fee;
			Account[_Documents[_Id_Transaction].Receiver][
				_Documents[_Id_Transaction].Id_Token_Bail
			].Amount_Holder += _Documents[_Id_Transaction].Amount_Bail;
			_Documents[_Id_Transaction].Open_Document = false;
			Account[Owner][_Documents[_Id_Transaction].Id_Token_Bail]
				.Amount_Holder += _Holders[_Documents[_Id_Transaction].Id_Token_Bail]
				.Transaction_Fee;
			emit Document_Operation(
				_Documents[_Id_Transaction].Id_Document,
				_Documents[_Id_Transaction].Creator,
				msg.sender,
				"Withdraw_Document",
				_Documents[_Id_Transaction].Amount_Bail
			);
		}
	}

	/*The following function returns the status of the document (term transaction).
  The person creating the document as well as the person receiving the document can see this situation
  This function shows the status of the document in terms of the value of the 
  document relative to the collateral, as well as other specifications.*/
	function Show_Document_Status() public view returns (uint256) {
		for (uint256 i = 0; i <= Number_Document; i++) {
			if (
				(msg.sender == _Documents[i].Receiver ||
					msg.sender == _Documents[i].Creator) &&
				_Documents[i].Liquidation == 1 &&
				_Documents[i].Open_Document == true
			) {
				if (
					((getLatestPrice(_Documents[i].Id_Token_Bail) *
						_Documents[i].Amount_Bail) /
						10**_Holders[_Documents[i].Id_Token_Bail].Decimal) <=
					((getLatestPrice(_Documents[i].Id_Token) *
						_Documents[i].Amount_Document) /
						10**_Holders[_Documents[i].Id_Token].Decimal)
				) {
					return (_Documents[i].Id_Document);
				}
			}
		}
	}

	function Show_Status(uint256 _Id) public view returns (uint256, uint256) {
		//  uint Q1 = _Documents[_Id].Amount_Document / 10 ** _Holders[_Documents[_Id].Id_Token].Decimal ;
		//  uint q2 = _Documents[_Id].Amount_Bail / 10 ** _Holders[_Documents[_Id].Id_Token_Bail].Decimal;
		//   if ((msg.sender == _Documents[ _Id].Receiver || msg.sender == _Documents[_Id].Creator) && _Documents[_Id].Liquidation == 1 && _Documents[_Id].Open_Document == true){
		//  if ( (getLatestPrice(_Documents[_Id].Id_Token) * Q1)   <= (getLatestPrice(_Documents[_Id].Id_Token_Bail) * q2)){
		uint256 PO = (getLatestPrice(_Documents[_Id].Id_Token) *
			_Documents[_Id].Amount_Document) /
			10**_Holders[_Documents[_Id].Id_Token].Decimal;
		uint256 PX = (getLatestPrice(_Documents[_Id].Id_Token_Bail) *
			_Documents[_Id].Amount_Bail) /
			10**_Holders[_Documents[_Id].Id_Token_Bail].Decimal;
		return (PO, PX);
	}

	/* The following function allows the user to close the long-term transaction created in the above function.
     However, to close a long-term transaction, this function does not take into account the time conditions and when the value of the 
     document is equal to the value of the collateral recorded in the document, it closes the transaction before the specified date. */
	function Close_Document_Equal_Value() external {
		for (uint256 i = 0; i <= Number_Document; i++) {
			if (
				msg.sender == _Documents[i].Receiver &&
				_Documents[i].Open_Document == true &&
				_Documents[i].Liquidation == 1 &&
				((getLatestPrice(_Documents[i].Id_Token_Bail) *
					_Documents[i].Amount_Bail) /
					10**_Holders[_Documents[i].Id_Token_Bail].Decimal) <=
				((getLatestPrice(_Documents[i].Id_Token) *
					_Documents[i].Amount_Document) /
					10**_Holders[_Documents[i].Id_Token].Decimal)
			) {
				if (
					_Documents[i].Amount_Document <=
					Account[_Documents[i].Creator][_Documents[i].Id_Token].Amount_Holder
				) {
					Account[_Documents[i].Creator][_Documents[i].Id_Token]
						.Amount_Holder -= _Documents[i].Amount_Document;
					Account[_Documents[i].Creator][_Documents[i].Id_Token_Bail]
						.Amount_Holder += _Documents[i].Amount_Bail;
					_Documents[i].Amount_Document -= _Holders[_Documents[i].Id_Token]
						.Transaction_Fee;
					_Documents[i].Open_Document = false;
					Account[_Documents[i].Receiver][_Documents[i].Id_Token]
						.Amount_Holder += _Documents[i].Amount_Document;
					Account[Owner][_Documents[i].Id_Token].Amount_Holder += _Holders[
						_Documents[i].Id_Token
					].Transaction_Fee;
					emit Document_Operation(
						_Documents[i].Id_Document,
						_Documents[i].Creator,
						msg.sender,
						"Withdraw_Document(Liquidated)",
						_Documents[i].Amount_Document
					);
				} else {
					_Documents[i].Amount_Bail -= _Holders[_Documents[i].Id_Token_Bail]
						.Transaction_Fee;
					Account[_Documents[i].Receiver][_Documents[i].Id_Token_Bail]
						.Amount_Holder += _Documents[i].Amount_Bail;
					_Documents[i].Open_Document = false;
					Account[Owner][_Documents[i].Id_Token_Bail].Amount_Holder += _Holders[
						_Documents[i].Id_Token_Bail
					].Transaction_Fee;
					emit Document_Operation(
						_Documents[i].Id_Document,
						_Documents[i].Creator,
						msg.sender,
						"Withdraw_Document(Liquidated)",
						_Documents[i].Amount_Bail
					);
				}
			}
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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