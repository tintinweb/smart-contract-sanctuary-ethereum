/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

pragma solidity 0.6.12;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
/*
$$\      $$\                                                        $$\  $$$$$$\                                                        $$\                     
$$ | $\  $$ |                                                       $$ |$$  __$$\                                                       \__|                    
$$ |$$$\ $$ | $$$$$$\  $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$$ |$$ /  \__| $$$$$$\  $$$$$$\$$$$\   $$$$$$\   $$$$$$\  $$$$$$$\  $$\  $$$$$$\  $$$$$$$\  
$$ $$ $$\$$ |$$  __$$\ \____$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  __$$ |$$ |      $$  __$$\ $$  _$$  _$$\ $$  __$$\  \____$$\ $$  __$$\ $$ |$$  __$$\ $$  __$$\ 
$$$$  _$$$$ |$$ |  \__|$$$$$$$ |$$ /  $$ |$$ /  $$ |$$$$$$$$ |$$ /  $$ |$$ |      $$ /  $$ |$$ / $$ / $$ |$$ /  $$ | $$$$$$$ |$$ |  $$ |$$ |$$ /  $$ |$$ |  $$ |
$$$  / \$$$ |$$ |     $$  __$$ |$$ |  $$ |$$ |  $$ |$$   ____|$$ |  $$ |$$ |  $$\ $$ |  $$ |$$ | $$ | $$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |
$$  /   \$$ |$$ |     \$$$$$$$ |$$$$$$$  |$$$$$$$  |\$$$$$$$\ \$$$$$$$ |\$$$$$$  |\$$$$$$  |$$ | $$ | $$ |$$$$$$$  |\$$$$$$$ |$$ |  $$ |$$ |\$$$$$$  |$$ |  $$ |
\__/     \__|\__|      \_______|$$  ____/ $$  ____/  \_______| \_______| \______/  \______/ \__| \__| \__|$$  ____/  \_______|\__|  \__|\__| \______/ \__|  \__|
                                $$ |      $$ |                                                            $$ |                                                  
                                $$ |      $$ |                                                            $$ |                                                  
                                \__|      \__|                                                            \__|                                                  
 $$$$$$\ $$$$$$$$\ $$\   $$\ $$\   $$\         $$$$$$$\                      $$\                                                                                
$$  __$$\\__$$  __|$$ | $$  |$$$\  $$ |        $$  __$$\                     $$ |                                                                               
$$ /  \__|  $$ |   $$ |$$  / $$$$\ $$ |        $$ |  $$ | $$$$$$\  $$$$$$$\  $$ |  $$\                                                                          
$$ |        $$ |   $$$$$  /  $$ $$\$$ |$$$$$$\ $$$$$$$\ | \____$$\ $$  __$$\ $$ | $$  |                                                                         
$$ |        $$ |   $$  $$<   $$ \$$$$ |\______|$$  __$$\  $$$$$$$ |$$ |  $$ |$$$$$$  /                                                                          
$$ |  $$\   $$ |   $$ |\$$\  $$ |\$$$ |        $$ |  $$ |$$  __$$ |$$ |  $$ |$$  _$$<                                                                           
\$$$$$$  |  $$ |   $$ | \$$\ $$ | \$$ |        $$$$$$$  |\$$$$$$$ |$$ |  $$ |$$ | \$$\                                                                          
 \______/   \__|   \__|  \__|\__|  \__|        \_______/  \_______|\__|  \__|\__|  \__|                   
                                                                                               

-NFT data store to hold the following
- Staking Rewards balances for Users
- Manage User Balances etc
*/
pragma solidity 0.6.12;
//Interfaces to the various externals
interface CTKN {
    ////Interface to Token
  function transfer(address _to, uint256 _tokens) external returns (bool);
}

interface Staking {
    ////Interface to Token
  function transfer(address _to, uint256 _tokens) external returns (bool);
}

 

contract wTCBank{
    //Std Variables///
    address public CTKNaddress = 0x89af532726f48b7E77aE60705E166252e9Dcde15;
    address public Owner;
    address public stakingcontract = 0xB245DE0F3bef7121582b8F11fC6a662B07d28684; //Staking
    address public rafflecontract;  //Raffle
    address public futurecontract; //Future proof Contract
    bool public purewithdrawlson; //Enable claiming balance in tokens
    bool public allowtokenpayouts; //Allow users to withdraw real tokens!
    ///////Important Mappings///////
    mapping(address => uint) internal clientbalance; //Dynamic mapping of ar enabled/disabled
    mapping(address => bool) internal blockedclients; //Dynamic mapping of art
    mapping(address => bool) internal isclient; //Mapping to hold valid clients
    ///////////////////////////////
    
    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }
     using SafeMath for uint;
    constructor () public {
      Owner = msg.sender; //Owner of Contract   
    }
    ///Update NB address if required
    function configNBAddresses(uint option,address _address,bool _onoroff) external onlyOwner{
        if (option==1)
        {
        CTKNaddress = _address;
        }
        if (option==2)
        {
        stakingcontract = _address;
        }
        if (option==3)
        {
        purewithdrawlson = _onoroff;
        }
        if (option==4)
        {
        rafflecontract = _address;
        }
        if (option==5)
        {
        allowtokenpayouts = _onoroff;
        }
        if (option==6)
        {
        futurecontract = _address;    
        }
        if (option==7)
        {
        Owner = _address;  //Renounce Ownership
        }
        }

    //Function to Verify whether an NFT is blocked
    function isBlockedClient(address _client) public view returns(bool)
   {
       bool temp;
       temp = blockedclients[_client];
       return (temp);
   }
   //Function to return whether they are a holder or not
   function isClient(address _address) public view returns(bool)
   {
       bool temp;
       if(isclient[_address]==true)
       {
          temp=true; 
       }
       return temp;
   }
   function manageClients(uint _option,bool _clearbalance,address _holder) external {
       require(msg.sender==Owner || msg.sender==stakingcontract,"(Bank) Not Authorized");
       if (_option==1) //Remove
       {
           isclient[_holder]=false;
           if (_clearbalance==true) //Clear balance
           {
               clientbalance[_holder] = 0;
           }
       }
       if (_option==2) //Add
       {
           isclient[_holder]=true;
       }
       
   }
  
   ///Function to manage addresses
   function manageBlockedClients(int option,address _wallet) external onlyOwner{
      
       if (option==1) // Add client as blocked
       {
           blockedclients[_wallet] = true;
           
       }
       if (option==2) //Remove being blocked
       {
           bool _isBlockedClient = blockedclients[_wallet];
       if(_isBlockedClient){
           blockedclients[_wallet] = false;
          
       }
       }
   
   }

   //Function to set user balances -> Staking and Raffles Website
   function manageBalances(uint _option,address _user,uint _amount) external {
       uint temp;
       bool isablockedclient;
    require(msg.sender == Owner || msg.sender == stakingcontract || msg.sender == rafflecontract || msg.sender ==futurecontract,"(Bank) Not Auth!");
    isablockedclient = isBlockedClient(_user);
    require(isablockedclient!=true,"(Bank) User is blocked!");
    temp = clientbalance[_user];
    if (_option==1) // add
    {
        clientbalance[_user] = temp.add(_amount);
    }
    if (_option==2) // sub
    {
        clientbalance[_user] = temp.sub(_amount);
    }
    if (_option==3) // zero balance
    {
        clientbalance[_user] = 0;
    }
    if (_option==4) // setasClient
    {
        isclient[_user] = true;
    }
    if (_option==5) // remove from ClientList
    {
        isclient[_user] = false;
    }
 }
   
   //Return Users balances
   function getBalance(address _user) external view returns(uint)
   {
       uint temp;
       temp = clientbalance[_user];
       return temp;
   }
   
   //Function to allow cashout of REAL tokens
   function tokenWithdraw() public
   {
     bool isstopped;
     uint reward;
     reward = clientbalance[msg.sender];
     require(allowtokenpayouts==true,"(Bank) Payouts not allowed");
     isstopped = isBlockedClient(msg.sender);
     require(isstopped!=true,"(Bank) Blocked Withdraw");
     require(reward > 0,"(BANK) Balance is 0!");
     CTKN(CTKNaddress).transfer(msg.sender,reward);
     //zero the reward
     clientbalance[msg.sender] = 0;
   }

   //Function to move funds back out to Token Contract//
  //This is put in place to manage funds in the staking contract and be able to remove funds if needed///
  function returnTokens(uint _amountOfCTKN,address _reciever) external onlyOwner{
     CTKN(CTKNaddress).transfer(_reciever,_amountOfCTKN);
  }
   


}