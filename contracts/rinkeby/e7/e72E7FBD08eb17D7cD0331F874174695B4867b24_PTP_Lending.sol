/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
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

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}





contract PTP_Lending{
    uint136 private Admin_Password  ;
    uint private Tokens = 0 ;
    uint  private Number_Document = 0 ;
    address private Owner; 
    address private Owner_two ;

    //==========================
     struct Holder{
       string Name;
       uint Amount_Holder;//This variable holds the amount of user money .
       uint  Decimal ;
       uint Transaction_Fee ;//This variable holds the cost of transactions
       address erc20TokenAddress;//This variable stores the contract address of a digital currency .
       IERC20 erc20Token;
       AggregatorV3Interface priceFeed;
       
    }
    struct Document{
        uint Id_Document;
        uint Id_Token  ;
        uint Id_Token_Bail ;
        uint Amount_Document;
        uint Amount_Bail ;
        uint Date_Document ;
        address  Receiver ;
        address Creator ;
        bool Open_Document ;
        uint8 Liquidation ;
        uint Currency_Received ;
        uint Amount_Received ;
        uint Validity_Document;
    }
    struct Transaction{
      uint Id_Transaction ;
    }
   
    mapping (address => uint) private _Count;
    mapping (uint => Transaction) private _Transactions;
    mapping (address =>  mapping (uint => Transaction)) private _ID_Transactions;
    mapping (uint => Holder) private  _Holders;
    mapping (uint => Document) private  _Documents;
    mapping (address => mapping (uint => Holder)) private Account;
    //New CodeBlock//
    mapping (address=>AggregatorV3Interface) internal _tokensPriceFeedAddress;
    modifier onlyOwner {
        require(msg.sender == Owner);
        _;
    }
    //End of CodeBlock//
    //=================================
  event Document_Operation (uint256  _ID , address indexed _From , address  indexed _To ,string _Type_transaction , uint256 _Value );
  event Deposit ( address indexed _From , address  indexed _To ,string _Type_transaction , uint256 _Value);
  event Withdraw(address indexed _From , address  indexed _To ,string _Type_transaction , uint256 _Value);
  //==================================
  constructor(uint136 _Pass ,  address _Address) public {
    Owner = msg.sender;
    Owner_two = _Address ;
    Admin_Password = _Pass ;
  }
  //===================================

   //New CodeBlock//
    function SetChainlinkPriceFeedAddress(address tokenAddress,address priceFeedAddress) public onlyOwner{
        _tokensPriceFeedAddress[tokenAddress] = AggregatorV3Interface(priceFeedAddress);
    }

    function CheckPriceFeedAddress(address tokenAddress) public view returns(AggregatorV3Interface){
        return _tokensPriceFeedAddress[tokenAddress];
    }

    function GetTokenPrice(address tokenAddress,bool calculateAsGwei) public view  returns(uint256){
        require(_tokensPriceFeedAddress[tokenAddress]!=AggregatorV3Interface(address(0)),"owner must first set priceFeedAddress");
        (, int256 price, , , ) =   _tokensPriceFeedAddress[tokenAddress].latestRoundData();
        if(calculateAsGwei){
            return  (uint256(price) * 10**10);
        }
        else{
            return uint256(price);
        }
        
    }
   //End of CodeBlock//

  
    function Change_owner(address _Address , uint136 _Pass) external {
        require( _Address == Owner_two && _Pass == Admin_Password);
           Owner = msg.sender ;  
    }
    function set_TokenAddress(uint _id , string calldata _Name_Token , address _tokenAddress , uint _decimal ,uint _fee , AggregatorV3Interface chainlink) external {
        require (Owner == msg.sender ,"This function is for the owner of this contract and you can not execute it");        //   Owner = msg.sender ;  
        if (_id > 0 && _id > Tokens){
          Tokens ++ ;
        }
        require(_tokenAddress != address(0)); // Checks that "_tokenAddress" is not zero
        _Holders[_id].Name = _Name_Token;
        _Holders[_id].erc20TokenAddress = _tokenAddress; // Sets "erc20TokenAddress"
        _Holders[_id].erc20Token = IERC20( _Holders[_id].erc20TokenAddress); // Sets "erc20Token"
        _Holders[_id].Decimal = _decimal ;
        _Holders[_id].Transaction_Fee  =_fee ;
        _Holders[_id].priceFeed = chainlink;
    }
     function Deposit_money(uint _id , uint _value) public payable{
      
        require (_value > 0 && _Holders[_id].erc20TokenAddress  != address(0));
        if( _id == 1 ){   
           require (_value <= msg.sender.balance);
           Account[msg.sender][1].Amount_Holder += msg.value;
           emit Deposit( msg.sender , address(this) , "Deposit" , msg.value );
        }else{
            require (_value <= _Holders[_id].erc20Token.balanceOf(msg.sender));
            uint _allowedValue = _Holders[_id].erc20Token.allowance(msg.sender, address(this)); // Checks for allowed value
            require(_value <= _allowedValue); // checks that "_value" is allowed
            bool A = _Holders[_id]. erc20Token.transferFrom(msg.sender, address(this),  _value  ); //Token payment done!
            if( A == true ){
               Account[msg.sender][_id].Amount_Holder +=  _value ;
               emit Deposit(msg.sender , address(this) , "Deposit" ,_value );
             }
        }
    }
  
    function Withdraw_money(uint _id , uint _value) public  {
       uint Wd = _value ;
       require( _value  <= Account[msg.sender][_id].Amount_Holder && _value > 0 && _Holders[_id].erc20TokenAddress  != address(0));
        if( _id == 1){
            Account[msg.sender][1].Amount_Holder -= Wd;
            //msg.sender.transfer(Wd);
            payable(msg.sender).transfer(Wd);
            emit Withdraw( address(this) , msg.sender ,  " Withdraw" , Wd );
        }
        else{ 
             Account[msg.sender][_id].Amount_Holder -=  Wd  ;
             bool A = _Holders[_id].erc20Token.transfer(msg.sender, Wd );
             if(A == true){
              emit Withdraw( address(this) , msg.sender ,  " Withdraw" , Wd );
             }
        }

    }
    //=======================================A number of functional functions (types view) are written below this line.
 
    
    function getLatestPrice(uint _Key) private view returns (uint) {
        //This method must decprecated and use GetTokenPrice Function instead
        //TODO 
        //Alternativly you can call GetTokenPrice here and return the value instead of changing entire code
        return(0);
    }
   function Show_Total_Document() public view returns(uint){
     return(Number_Document);
   }
  
  function balanceOf_Account(uint _id ) public view returns(uint) {
     require ( _Holders[_id].erc20TokenAddress  != address(0));
     return(Account[msg.sender][_id].Amount_Holder);
    }

   function Show_Transactions() public view returns(uint , string memory , address , string memory , address){
           return(_ID_Transactions[msg.sender][_Count[msg.sender]].Id_Transaction , "From:" ,_Documents[_ID_Transactions[msg.sender][_Count[msg.sender]].Id_Transaction].Creator , "To:" ,_Documents[_ID_Transactions[msg.sender][_Count[msg.sender]].Id_Transaction]. Receiver ); 
    }
  








    function Document_currency_type(uint _Id) private view returns(string memory){
      for(uint i = 0 ; i <= Tokens; i++) {
           if(_Documents[_Id ].Id_Token == i){
              return(_Holders[i].Name );  
           }
      }
    }
     function Type_collateral(uint _Id ) private view returns(string memory){
      for(uint i = 0 ; i <= Tokens; i++) {
           if(_Documents[_Id ].Id_Token_Bail  == i){
              return(_Holders[i].Name );  
           }
      }
    }
     function Type_currency_traded(uint _Id ) private view returns(string memory){
      for(uint i = 0 ; i <= Tokens; i++) {  
           if(_Documents[_Id ].Currency_Received  == i){
              return(_Holders[i].Name );  
           }
      }
    }
    function Type_liquidation_status(uint _Id ) private view returns(string memory){
           if(_Documents[_Id ].Liquidation  == 1){
              return("Active" );  
           }else {
              return("Inactive");
           }
    }
    //==================================================
    function Creation_Credit_Document_One_way(uint _id_money_Document , uint _value_Amount_Document , uint _value_Date , address  _value_Receiver , uint _id_Bail , uint256 _value_Amount_Bail , uint8 _value_Liquidation  ) external {
        require (_Holders[_id_money_Document].erc20TokenAddress != address(0));
        require (_Holders[_id_Bail].erc20TokenAddress != address(0));
        require (_value_Amount_Document > 0 && _value_Date > 0 && _value_Receiver != address(0));
        require (_value_Amount_Bail > _Holders[_id_Bail].Transaction_Fee && (_value_Amount_Bail + _Holders[_id_Bail].Transaction_Fee) <= Account[msg.sender][_id_Bail].Amount_Holder,"You do not have enough funds to register this transaction on this platform.");
        Account[msg.sender][_id_Bail].Amount_Holder -=(_value_Amount_Bail + _Holders[_id_Bail].Transaction_Fee) ;
        Number_Document ++ ;
        Document memory _Doc ;
        _Doc.Id_Document = Number_Document;
        _Doc.Id_Token = _id_money_Document ;
        _Doc.Id_Token_Bail = _id_Bail ;
        _Doc.Amount_Document =_value_Amount_Document  ;
        _Doc.Amount_Bail = _value_Amount_Bail;
        _Doc.Date_Document = _value_Date ;
        _Doc.Receiver = _value_Receiver ;
        _Doc.Creator = msg.sender ;
        _Doc.Liquidation = _value_Liquidation;
        _Doc.Open_Document = true ;
        _Doc.Currency_Received = 0 ;
        _Doc.Amount_Received = 0 ;
        _Doc.Validity_Document = 0 ;
        _Documents[Number_Document]= _Doc ;
        Account[Owner][_id_Bail].Amount_Holder += _Holders[_id_Bail].Transaction_Fee ;
        _Count[msg.sender] += 1 ;
        _Count[_value_Receiver] += 1 ;
        _ID_Transactions[msg.sender][_Count[msg.sender]].Id_Transaction = Number_Document;
        _ID_Transactions[_value_Receiver][_Count[_value_Receiver]].Id_Transaction = Number_Document;
        emit Document_Operation(Number_Document , msg.sender , _value_Receiver  , " Creation Credit Document One way" , _value_Amount_Document );  
    }
    function Creation_Credit_Document_Bilateral(uint _id_money_Document , uint _value_Amount_Document , uint _value_Date , uint _id_Bail , uint _value_Amount_Bail , uint8 _value_Liquidation  , uint32 _id_Currency_Received , uint _value_Amount_Received ) external {
        require (_Holders[_id_money_Document].erc20TokenAddress != address(0));
        require (_Holders[_id_Bail].erc20TokenAddress != address(0));
        require (_value_Amount_Bail > _Holders[_id_Bail].Transaction_Fee && (_value_Amount_Bail + _Holders[_id_Bail].Transaction_Fee)  <= Account[msg.sender][_id_Bail].Amount_Holder , "You do not have enough funds to register this transaction on this platform.");
        require (_value_Amount_Document > 0 && _value_Date > 0 );
        require (_value_Amount_Received > 0  && _id_Currency_Received > 0 &&  _id_Currency_Received <= Tokens);
      // require ( _value_Amount_Received <= Account[ _value_Receiver ][_id_Currency_Received ].Amount_Holder);      
     
        Number_Document ++ ;
        Document memory _Doc ;
        _Doc.Id_Document = Number_Document;
        _Doc.Id_Token = _id_money_Document ;
        _Doc.Id_Token_Bail = _id_Bail ;
        _Doc.Amount_Document =_value_Amount_Document  ;
        _Doc.Amount_Bail = _value_Amount_Bail;
        _Doc.Date_Document = _value_Date ;
        _Doc.Receiver = address(0) ;
        _Doc.Creator = msg.sender ;
        _Doc.Liquidation = _value_Liquidation;
        _Doc.Open_Document = false ;
        _Doc.Currency_Received = _id_Currency_Received ;
        _Doc.Amount_Received = _value_Amount_Received ;
        _Doc.Validity_Document = (block.timestamp + 172800 );
        _Documents[Number_Document]= _Doc ;
        _Count[msg.sender] += 1 ;
        _ID_Transactions[msg.sender][_Count[msg.sender]].Id_Transaction = Number_Document;
      //  _Count[_value_Receiver] += 1 ;
       // _ID_Transactions[_value_Receiver][_Count[_value_Receiver]].Id_Transaction = Number_Document;
         //emit  Document_Operation(Number_Document , msg.sender , _value_Receiver  , " Creation Credit Document Bilateral" , _value_Amount_Document );
    }
   
    function Confirm_Transaction(uint _Id_Transaction) external  returns(bool){
        require(    _Documents[_Id_Transaction].Id_Document == _Id_Transaction &&  _Documents[_Id_Transaction].Open_Document == false && block.timestamp <= _Documents[_Id_Transaction].Validity_Document,"This transaction is probably out of date or you entered the transaction ID incorrectly");
        require((_Documents[_Id_Transaction].Amount_Bail + _Holders[_Documents[_Id_Transaction].Id_Token_Bail].Transaction_Fee)  <= Account[_Documents[_Id_Transaction].Creator][_Documents[_Id_Transaction].Id_Token_Bail].Amount_Holder && _Documents[_Id_Transaction].Amount_Received <= Account[msg.sender][ _Documents[_Id_Transaction].Currency_Received].Amount_Holder,"The creator may not have sufficient collateral for the transaction.");//_Holders[_Documents[_Id_Transaction].Currency_Received].erc20Token.balanceOf(msg.sender)){
                   Account[_Documents[_Id_Transaction].Creator][_Documents[_Id_Transaction].Id_Token_Bail].Amount_Holder -= (_Documents[_Id_Transaction].Amount_Bail  +   _Holders[_Documents[_Id_Transaction].Id_Token_Bail].Transaction_Fee);                  
                   Account[msg.sender][_Documents[_Id_Transaction].Currency_Received].Amount_Holder -= _Documents[_Id_Transaction].Amount_Received;
                   Account[_Documents[_Id_Transaction].Creator][_Documents[_Id_Transaction].Currency_Received].Amount_Holder +=_Documents[_Id_Transaction].Amount_Received;
                   _Documents[_Id_Transaction].Open_Document = true ;
                   _Documents[_Id_Transaction].Receiver = msg.sender ;
                   _Count[msg.sender] += 1 ;
                   _ID_Transactions[msg.sender][_Count[msg.sender]].Id_Transaction = _Documents[_Id_Transaction].Id_Document ;
                   Account[Owner][_Documents[_Id_Transaction].Id_Token_Bail].Amount_Holder += _Holders[_Documents[_Id_Transaction].Id_Token_Bail].Transaction_Fee ;
                   emit  Document_Operation(_Documents[_Id_Transaction].Id_Document  , msg.sender , _Documents[_Id_Transaction].Creator , " Bilateral transaction approval" , _Documents[_Id_Transaction].Amount_Received);
               return(true);  
    }
    /*The following function (edit) is applicable to increase the amount of bail of a document but can not change the recipient of the document.
      Note that you can not reduce the amount of bail, but you can increase it.
      This is used to prevent the liquidation of the collateral*/
    function Edit_Credit_Document(uint _id , uint256 _Value) external {
             require (_Documents[_id].Open_Document == true);
             require (  msg.sender == _Documents[_id].Creator , "Not applicable because either the document ID is incorrect or you are not the creator of the document.");
             require (_Value <= Account[msg.sender][_Documents[_id].Id_Token_Bail].Amount_Holder ,"Your budget for this transaction is not fraudulent. Please increase your account first");
             Account[msg.sender][_Documents[_id].Id_Token_Bail].Amount_Holder -= _Value ; 
             _Documents[_id].Amount_Bail += _Value ;            
     
    }
  
     /* The following function allows the user to close the long-term transaction created in the above function.
      Of course, to close a long-term transaction, this function checks the conditions in which it is registered.*/
    function Withdraw_Document(uint _Id_Transaction) external {
            require( _Documents[_Id_Transaction].Open_Document == true && block.timestamp > _Documents[_Id_Transaction].Date_Document && msg.sender == _Documents[_Id_Transaction].Receiver  );
             if(_Documents[_Id_Transaction].Amount_Document <= Account[_Documents[_Id_Transaction].Creator][_Documents[_Id_Transaction].Id_Token].Amount_Holder){
               Account[_Documents[_Id_Transaction].Creator][_Documents[_Id_Transaction].Id_Token].Amount_Holder -= _Documents[_Id_Transaction].Amount_Document ;
               Account[_Documents[_Id_Transaction].Creator][_Documents[_Id_Transaction].Id_Token_Bail].Amount_Holder += _Documents[_Id_Transaction].Amount_Bail ;
               _Documents[_Id_Transaction].Amount_Document -= _Holders[_Documents[_Id_Transaction].Id_Token].Transaction_Fee ;
               Account[_Documents[_Id_Transaction].Receiver][_Documents[_Id_Transaction].Id_Token].Amount_Holder += _Documents[_Id_Transaction].Amount_Document;
               _Documents[_Id_Transaction].Open_Document = false ;
                Account[Owner][_Documents[_Id_Transaction].Id_Token].Amount_Holder +=_Holders[_Documents[_Id_Transaction].Id_Token].Transaction_Fee ;
               emit  Document_Operation(_Documents[_Id_Transaction].Id_Document ,_Documents[_Id_Transaction].Creator , msg.sender , "Withdraw_Document" , _Documents[_Id_Transaction].Amount_Document);
              }else{
                  _Documents[_Id_Transaction].Amount_Bail -= _Holders[_Documents[_Id_Transaction].Id_Token_Bail].Transaction_Fee ;
                  Account[_Documents[_Id_Transaction].Receiver][_Documents[_Id_Transaction].Id_Token_Bail].Amount_Holder += _Documents[_Id_Transaction].Amount_Bail;
                  _Documents[_Id_Transaction].Open_Document = false ;
                  Account[Owner][_Documents[_Id_Transaction].Id_Token_Bail].Amount_Holder +=_Holders[_Documents[_Id_Transaction].Id_Token_Bail].Transaction_Fee ;
                  emit  Document_Operation(_Documents[_Id_Transaction].Id_Document ,_Documents[_Id_Transaction].Creator , msg.sender , "Withdraw_Document" , _Documents[_Id_Transaction].Amount_Bail);
              }
    }


 function Close_Document_Equal_Value (uint _Id) external {
   // for(uint i = 0; i <= Number_Document ; i++){
    require( msg.sender == _Documents[_Id].Receiver && _Documents[_Id].Open_Document == true && _Documents[_Id].Liquidation == 1 && (getLatestPrice(_Documents[_Id].Id_Token_Bail) * _Documents[_Id].Amount_Bail / 10 ** _Holders[_Documents[_Id].Id_Token_Bail].Decimal)  <= (getLatestPrice(_Documents[_Id].Id_Token) * _Documents[_Id].Amount_Document / 10 ** _Holders[_Documents[_Id].Id_Token].Decimal),"This document is not eligible for dissolution");
             if(_Documents[_Id].Amount_Document <= Account[_Documents[_Id].Creator][_Documents[_Id].Id_Token].Amount_Holder){
                 Account[_Documents[_Id].Creator][_Documents[_Id].Id_Token].Amount_Holder -= _Documents[_Id].Amount_Document ;
                 Account[_Documents[_Id].Creator][_Documents[_Id].Id_Token_Bail].Amount_Holder += _Documents[_Id].Amount_Bail ;
                 _Documents[_Id].Amount_Document -= _Holders[_Documents[_Id].Id_Token].Transaction_Fee ;
                 _Documents[_Id].Open_Document = false ;
                 Account[_Documents[_Id].Receiver][_Documents[_Id].Id_Token].Amount_Holder += _Documents[_Id].Amount_Document;
                 Account[Owner][_Documents[_Id].Id_Token].Amount_Holder +=_Holders[_Documents[_Id].Id_Token].Transaction_Fee ;  
                 emit  Document_Operation(_Documents[_Id].Id_Document ,_Documents[_Id].Creator , msg.sender , "Withdraw_Document(Liquidated)" , _Documents[_Id].Amount_Document);
              }else{
                  _Documents[_Id].Amount_Bail -= _Holders[_Documents[_Id].Id_Token_Bail].Transaction_Fee ;
                   Account[_Documents[_Id].Receiver][_Documents[_Id].Id_Token_Bail].Amount_Holder += _Documents[_Id].Amount_Bail ;
                   _Documents[_Id].Open_Document = false ;
                   Account[Owner][_Documents[_Id].Id_Token_Bail].Amount_Holder +=_Holders[_Documents[_Id].Id_Token_Bail].Transaction_Fee ;
                  emit  Document_Operation(_Documents[_Id].Id_Document  ,_Documents[_Id].Creator , msg.sender , "Withdraw_Document(Liquidated)" , _Documents[_Id].Amount_Bail);
             } 
  }

}