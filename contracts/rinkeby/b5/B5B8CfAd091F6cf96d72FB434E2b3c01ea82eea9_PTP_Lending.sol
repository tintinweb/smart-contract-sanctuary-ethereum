//SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IERC20.sol";

error PTP_zeroEntrance();
error PTP_blacklisted();
error PTP_canZeroOrSameOwner();
error PTP_moreThanBalance();

contract PTP_Lending is Ownable, ReentrancyGuard {
	uint136 private Admin_Password;
	uint256 private Tokens = 0;
	uint256 private Number_Document = 0;
	address private Owner;
	address private Owner_two;

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
	mapping(address => bool) private blacklisted;
	//=================================
	event Document_Operation(
		uint256 _ID,
		address indexed _From,
		address indexed _To,
		string _Type_transaction,
		uint256 _Value
	);
	event DepositedETH(address indexed from, uint256 indexed value);
	event DepositedToken(
		address indexed from,
		address indexed token,
		uint256 indexed value
	);
	event WithdrawedETH(address indexed receiver, uint256 indexed amount);
	event WithdrawedToken(
		address indexed from,
		address indexed token,
		uint256 indexed value
	);

	modifier notBadGuy() {
		if (blacklisted[msg.sender] == true) {
			revert PTP_blacklisted();
		}
		_;
	}

	//==================================
	constructor(uint136 _Pass, address _Address){
		Owner_two = _Address;
		Admin_Password = _Pass;
	}

	function Change_owner(address _Address, uint136 _Pass) external {
		require(_Address == Owner_two && _Pass == Admin_Password);
		_transferOwnership(msg.sender);
	}

	//===================================
	function set_TokenAddress(
		string calldata _Name_Token,
		address _tokenAddress,
		uint256 _decimal,
		uint256 _fee,
		address chainlink
	) external onlyOwner {
		Tokens++;
		Holder memory h = _Holders[Tokens];
		require(_tokenAddress != address(0)); // Checks that "_tokenAddress" is not zero
		h.Name = _Name_Token;
		h.erc20TokenAddress = _tokenAddress; // Sets "erc20TokenAddress"
		h.erc20Token = IERC20(h.erc20TokenAddress); // Sets "erc20Token"
		h.Decimal = _decimal;
		h.Transaction_Fee = _fee;
		h.priceFeed = AggregatorV3Interface(chainlink);
		_Holders[Tokens] = h;
	}

	function Deposit_ETH() public payable nonReentrant notBadGuy{
		Account[msg.sender][1].Amount_Holder += msg.value;
		emit DepositedETH(msg.sender, msg.value);
	}

	function DepositTokens(uint256 _id, uint256 _value)
		public
		nonReentrant
		notBadGuy
	{
		require(_id <= Tokens, "Invalid Id");
		address tokenAddress = _Holders[_id].erc20TokenAddress;
		require(tokenAddress != address(0));
		IERC20(tokenAddress).transferFrom(msg.sender, address(this), _value);
		Account[msg.sender][_id].Amount_Holder += _value;
		emit DepositedToken(msg.sender, tokenAddress, _value);
	}

	function WithdrawETH(uint256 amount) public nonReentrant notBadGuy{
		Holder memory h = Account[msg.sender][1];
		require(h.Amount_Holder >= amount, "Not Enough Balance");
		payable(msg.sender).transfer(amount);
		h.Amount_Holder = h.Amount_Holder - amount;
		Account[msg.sender][1] = h;
		emit WithdrawedETH(msg.sender, amount);
	}

	function withdrawToken(uint256 _id, uint256 amount) public nonReentrant notBadGuy{
		Holder memory h = Account[msg.sender][_id];
		require(h.Amount_Holder >= amount, "Not Enough Balance");
		address tokenAddress = _Holders[_id].erc20TokenAddress;
		h.Amount_Holder = h.Amount_Holder - amount;
		Account[msg.sender][_id] = h;
		IERC20(tokenAddress).transfer(msg.sender, amount);
		emit WithdrawedToken(msg.sender, tokenAddress, amount);
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
		Account[owner()][_id_Bail].Amount_Holder += _Holders[_id_Bail]
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
		Account[owner()][_Documents[_Id_Transaction].Id_Token_Bail]
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
			Account[owner()][_Documents[_Id_Transaction].Id_Token]
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
			Account[owner()][_Documents[_Id_Transaction].Id_Token_Bail]
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
					Account[owner()][_Documents[i].Id_Token].Amount_Holder += _Holders[
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
					Account[owner()][_Documents[i].Id_Token_Bail].Amount_Holder += _Holders[
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

	function getDocumentsCount() public view returns (uint256) {
		return Number_Document;
	}

	function getTotalTokens() public view returns(uint256){
		return Tokens;
	}

	//Setters
	function blackListAddress(address badGuy) public onlyOwner {
		blacklisted[badGuy] = true;
	}

	function unBlackListAddress(address bl) public onlyOwner {
		blacklisted[bl] = false;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// SPDX-License-Identifier: MIT
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