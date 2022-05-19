// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./IBVVToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./abstractBVV.sol";
contract BlockchainVidyutVibhag is abstractBVV{

   uint public timePeriod = 60 * 1 seconds;   //for next 1 month 2611769
   uint public penaltyAmount=10;    //penalty in token
   uint public tokenGivenToUser=100;
   string[]public users;
               
   

    struct User{
        address userAddress;
        string name;
        string residentialAdd;
        uint current_time;
        bool isActive;
        uint units;
        uint payableAmount;
        uint dueTime ;
        
    }
    // mapping..
    mapping(address=>User)public userMap;
   
   // constructor..    
    constructor(){
        admin = msg.sender;
    }

    // Created token instance...
    address public BVVTokenContract=0x7fB64c57c73d40D64FD110b29bAE8FbE72850389;
    IBVVToken Ibvv=IBVVToken(BVVTokenContract);
    
    function checkBalance(address userAddress)public view returns(uint256){
        return Ibvv.CheckBalanceOf(userAddress);
    }
 
  
    function _tokenTransfer(address to,uint amount) internal {
        Ibvv.tokenTransferFrom(msg.sender,to,amount);
    }

 
    function createOperator(address adsOfOperator)external  override onlyAdmin {
      operator[adsOfOperator] = true; 
    }
    function removeOperators(address operatorAds)external override onlyAdmin{
        operator[operatorAds] = false;

    } 
    function userRegisteration(address userAddress,string memory _name,string memory _residentialAdd,bool isActive)public override onlyAdmin {
        require(userMap[userAddress].isActive==false,"Already Registered");
        _tokenTransfer(userAddress,tokenGivenToUser);
      
        userMap[userAddress]=User(userAddress,_name,_residentialAdd,0,true,0,0,0);

        // push name into the 'users' array to return list of user
        users.push(userMap[userAddress].name);
       
        emit registredUserEvent(userAddress,_name,true);
     
    }
    function removeUser(address adsOfUser)external override onlyAdmin returns(bool){
        userMap[adsOfUser].isActive = false;

    }

    //Operator, Generate bill for users and store their current and duetime.
    function generateBill(address ads,uint _units)external override  onlyOperator{
        require(userMap[ads].isActive==true,"Invalid user address");
        userMap[ads].units= _units;
        userMap[ads].payableAmount = 8*_units;
        
        // store current time and duetime of user in struct
        userMap[ads].current_time=block.timestamp;
        userMap[ads].dueTime=(block.timestamp+timePeriod);

                
    }
    function billPay() external override {
        // add panelty to user after due time
        _paneltyToUser();

        require(userMap[msg.sender].isActive==true,"Inavlid user address,Unble to pay");
        require(userMap[msg.sender].units>0,"Already paid");
        require(checkBalance(msg.sender)>=userMap[msg.sender].payableAmount,"Insufficient amount to paid");

        _tokenTransfer(address(this),userMap[msg.sender].payableAmount);

        // address payable _to=payable(address(this));
        // bool sent = _to.send(msg.value);

        userMap[msg.sender].units = 0;
        userMap[msg.sender].payableAmount = 0;

        
        emit paidBillEvents(msg.sender,true);

    
    }
    function _paneltyToUser() internal{
        if(block.timestamp>=userMap[msg.sender].dueTime){
            userMap[msg.sender].payableAmount+=penaltyAmount;

        }      

    }

    function updateTokenGivenToUser(uint tokenAmount)public override{
        tokenGivenToUser = tokenAmount;

    }
    function getUnitsAndPayableAmountOfUser()public override view returns(uint,uint){
        require(userMap[msg.sender].isActive==true,"User does not exist!");
        return (userMap[msg.sender].units,userMap[msg.sender].payableAmount); 
           
    }
    function getBVVBalance() public override view returns(uint){
        // return (address(this)).checkBalance();
        return checkBalance(address(this));
    }
   
    function getRegisterUserNames(uint index)public override view returns(string memory){
        return users[index];
    }


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./IBVV.sol";
abstract contract abstractBVV is IBVV{
    address public admin;
    mapping(address=>bool)public operator;


    modifier onlyAdmin {
      require(msg.sender == admin,"BlockchainVidyutVibhag:Only Admin Can Access");
      _;
    }
    modifier onlyOperator {
      require(operator[msg.sender],"BlockchainVidyutVibhag:only Operator Can Acccess");
       _;  
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


interface IBVVToken{
    
    function CheckBalanceOf(address account) external view returns (uint256);
    function tokenTransferFrom(address from,address to, uint amount) external;
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


interface IBVV{

    event registredUserEvent(
        address  userAddress,
        string name,
        bool status
        
        
    );
    event paidBillEvents(
        address  _from,
        bool status
    );

    function createOperator(address adsOfOperator)  external;    
    function removeOperators(address operatorAds) external;
    function userRegisteration(address userAddress,string memory _name,string memory _add,bool isActive)external;
    function removeUser(address adsOfUser)external  returns(bool);
    function generateBill(address ads,uint _units)  external;
    function billPay()  external;
    function getBVVBalance()external view returns(uint);
    function getRegisterUserNames(uint index)  external view returns(string memory);
    function updateTokenGivenToUser(uint tokenAmount)external;
    function getUnitsAndPayableAmountOfUser()external view returns(uint,uint);

}