/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

pragma solidity 0.8.11;
/*
           $$$$$$$$\  $$$$$$\        $$$$$$$\             $$$$$$\   $$$$$$\  $$\           
           \__$$  __|$$  __$$\       $$  __$$\           $$  __$$\ $$  __$$\ $$ |          
$$\  $$\  $$\ $$ |   $$ /  \__|      $$ |  $$ | $$$$$$\  $$ /  \__|$$ /  \__|$$ | $$$$$$\  
$$ | $$ | $$ |$$ |   $$ |            $$$$$$$  | \____$$\ $$$$\     $$$$\     $$ |$$  __$$\ 
$$ | $$ | $$ |$$ |   $$ |            $$  __$$<  $$$$$$$ |$$  _|    $$  _|    $$ |$$$$$$$$ |
$$ | $$ | $$ |$$ |   $$ |  $$\       $$ |  $$ |$$  __$$ |$$ |      $$ |      $$ |$$   ____|
\$$$$$\$$$$  |$$ |   \$$$$$$  |      $$ |  $$ |\$$$$$$$ |$$ |      $$ |      $$ |\$$$$$$$\ 
 \_____\____/ \__|    \______/       \__|  \__| \_______|\__|      \__|      \__| \_______|
                                                                                           
                                                                                           
                                                                                           
 $$$$$$\                       $$\                                    $$\                  
$$  __$$\                      $$ |                                   $$ |                 
$$ /  \__| $$$$$$\  $$$$$$$\ $$$$$$\    $$$$$$\  $$$$$$\   $$$$$$$\ $$$$$$\                
$$ |      $$  __$$\ $$  __$$\\_$$  _|  $$  __$$\ \____$$\ $$  _____|\_$$  _|               
$$ |      $$ /  $$ |$$ |  $$ | $$ |    $$ |  \__|$$$$$$$ |$$ /        $$ |                 
$$ |  $$\ $$ |  $$ |$$ |  $$ | $$ |$$\ $$ |     $$  __$$ |$$ |        $$ |$$\              
\$$$$$$  |\$$$$$$  |$$ |  $$ | \$$$$  |$$ |     \$$$$$$$ |\$$$$$$$\   \$$$$  |             
 \______/  \______/ \__|  \__|  \____/ \__|      \_______| \_______|   \____/              
                                                                                           
-Smart Contract to handle the spending of balances and claiming of rewards
- on raffles etc
- v1.0 -> Initial release!
*/
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

//Interface to NFT contract which is the wrapper
interface wrapper{
  function ownerOf(uint256 tokenId) external view returns (address);
  function balanceOf(address owner) external view returns (uint256);
}
interface wrapperdb {
    function isBlockedNFT(uint _tokenID) external view returns(bool,uint256); 
}
       ////Interface to the CTKN Rewards/balance BankContract
interface Bank{
 function manageBalances(uint _option,address _user,uint _amount) external;
 function getBalance(address _user) external view returns(uint);
 
}

interface NFT{
    function transferFrom(address from,address to,uint256 tokenId) external;
}

interface ERC20 {
    ////Interface to Token
  function balanceOf(address owner) external view returns (uint256);
  function transfer(address _to, uint256 _tokens) external returns (bool);
}

interface Staking {
function isOnWhitelist(address _wl)external view returns(bool);
function setLastClaimExternal(address _payee) external;
function calculatePayoutAmount(address _payee) external view returns(uint);
}

contract wtcRaffle{
    //Arrays///
    //Std Variables///
    address public wrapperaddress = 0x16e2220Bba4a2c5C71f628f4DB2D5D1e0D6ad6e0; //Address of Wrapper Contract
    address public bank = 0x87cEc4c1016913219570fDc7779a08004ebE71d0;
    address public db = 0x131Bc921fDf520E62eca46c1011Fc885d6B29B9f;
    address public Owner;
    address public stakingcontract = 0x6b93a6d1699c5C172Ca20c82fb97C1c5ab871F96;
    uint numrafflesallowed=20; //Default number of raffles allowed at a single time
    uint numactiveraffles; // number of created raffles
    bool rafflesopen = true; //Global to stop raffles
    bool autoclaiming = true; //Auto claim on or off
    uint creatorpercentage = 10; //Default 10%
    uint public maxtickets = 5; //Max number of tickets per TX
    ///////Important Mappings///////
    mapping(uint => Raffle) public raffles; //mapping to keep track of Raffles created dynamically
    mapping(address => bool) authorized; //Authorised to create a unique raffle
    ////Raffle Structure///
    struct Raffle {
    string rafflename; //identifier used to verify that the correct raffle is being used
    string imgurl; //Image to show on website
    address creator; //Wallet that created the raffle
    address[] tickets; //Keep track of who has bought a ticket
    uint endtime; //Unix timestamp when raffle ends
    uint ticketprice; //Price of ticket for this raffle
    address winner; //Winner of raffle!
    address project; //Address to facilitate the transfer out of an NFT or Tokens
    bool istoken; // Used to allow the listing of Tokens up for raffle
    bool isopen; // Extra variable to cover and ensure that the raffle can be paused!
    bool wtconly; //Sepcifies if non WTC holders can enter this raffle!
    uint prizevalue; // This is an int which can represent a number of tokens or an NFT number
    bool nonwtconly; //Special Raffle to ensure non WTC can only enter
    }
    ////////////////////////////////
    using SafeMath for uint;
    ///////////////////////////////
    modifier onlyOwner() {
        require(msg.sender == Owner);
        _;
    }
    
    constructor () {
      Owner = msg.sender; //Owner of Contract
    }

    ///Configure the aspects of the contract
    function configOptions(uint option,address _address,uint _value,bool _yesorno) external onlyOwner{
        if (option==1)
        {
        wrapperaddress = _address;
        }
        if (option==2)
        {
        bank = _address;
        }
        if (option==3)
        {
        db = _address;
        }
        if (option==4)
        {
        numrafflesallowed = _value;
        }
        if (option==5)
        {
        stakingcontract = _address;
        }
        if (option==6)
        {
        rafflesopen = _yesorno;
        }
        if (option==7)
        {
        creatorpercentage = _value;
        }
        if (option==8)
        {
        autoclaiming = _yesorno;
        }
        if (option==9)
        {
        maxtickets = _value;
        }
        if (option==10)
        {
        Owner = _address; //Renounce ownership!
        }
        }



    function getStats(uint _option) external view returns(uint)
    {
        uint temp;
        if (_option==1)
        {
            temp = numactiveraffles;
        }
        if (_option==2)
        {
            temp = numrafflesallowed;
        }

        return temp;
    }
    ///Setup a new Raffle
    function newRaffle(string memory _name,string memory _url,address _creator,uint _endtime,address _projectaddress,bool _istoken,bool _isopen,bool _nonwtconly,bool _wtconly,uint _valueornftnum,uint _ticketprice) external {
        //Are raffles allowed at global level?
        require (rafflesopen==true,"Raffles are currently disabled!");
        bool cancreate = authorized[msg.sender];
        if(msg.sender!=Owner)
        {
        ///Verify that user is allowed to make a raffle
        require(cancreate==true,"Not Allowed to create a raffle!");
        ///Verify the user is holding a wTC
        }
        //Create new raffle!
        require(numactiveraffles <= numrafflesallowed,"Too Many Active Raffles, try again later!");
        ///Ensure raffle 0 is 
        if(numactiveraffles==0)
        {
        Raffle storage newraffle = raffles[0];
        newraffle.rafflename = _name;
        newraffle.imgurl = _url;
        newraffle.creator = msg.sender;
        newraffle.isopen = _isopen;
        newraffle.endtime = _endtime;
        newraffle.project = _projectaddress;
        newraffle.istoken = _istoken;
        newraffle.nonwtconly = _nonwtconly;
        newraffle.wtconly = _wtconly;
        newraffle.ticketprice = _ticketprice;
        require (_valueornftnum > 0 ,"Please enter in a valid amount/nft number!");
        newraffle.prizevalue = _valueornftnum;
        }
        else
        {  
        Raffle storage newraffle = raffles[numactiveraffles];
        newraffle.rafflename = _name;
        newraffle.imgurl = _url;
        newraffle.creator = msg.sender;
        newraffle.isopen = _isopen;
        newraffle.endtime = _endtime;
        newraffle.project = _projectaddress;
        newraffle.istoken = _istoken;
        newraffle.nonwtconly = _nonwtconly;
        newraffle.wtconly = _wtconly;
        newraffle.ticketprice = _ticketprice;
        require (_valueornftnum > 0 ,"Please enter in a valid amount/nft number!");
        newraffle.prizevalue = _valueornftnum;

        }

        numactiveraffles++; //increment the number of active raffles
        
    }
    
    ///Function to provide and entry into a raffle for a user
    function enterRaffle(uint _rafflenumber,uint _numtickets) external{
        bool buying;
        uint balance;
        uint tempbalance;
        uint value;
        bool claiming; //re-entrancy guard to stop double claiming
    //Are raffles allowed at global level?
    require (rafflesopen==true,"Raffles are currently disabled!");
    ////retrieve the selected raffle!//////
    Raffle storage temp = raffles[_rafflenumber];
    ////Verify if the user is holding a WTC
    if (temp.nonwtconly!=true)
    {
    if (temp.wtconly==true)
    {
    require(wrapper(wrapperaddress).balanceOf(msg.sender) > 0,"You do not hold a wTC!");
    }
    }
    if (temp.nonwtconly==true)
    {
    require(wrapper(wrapperaddress).balanceOf(msg.sender) == 0,"WTC holders cannot enter this raffle!");
    //Verify is user is on whitelise
    require ((Staking(stakingcontract).isOnWhitelist(msg.sender)==true),"You are not eligable!");
    }
    require(_numtickets <= maxtickets,"Too Many tickets requested for this TX");
    value = temp.ticketprice.mul(_numtickets); //Get the tx value
    ////Ensure the user has enough funds to buy a raffle ticket!
    balance = Bank(bank).getBalance(msg.sender);
    if(autoclaiming==true && claiming==false) 
    {
    claiming = true;
    tempbalance = Staking(stakingcontract).calculatePayoutAmount(msg.sender);
    if (tempbalance>0)
    {
        Bank(bank).manageBalances(1,msg.sender,tempbalance); //Add the outstanding balance to balance
        Staking(stakingcontract).setLastClaimExternal(msg.sender); //
    }
    }
    //Get Updated Balance
    balance = Bank(bank).getBalance(msg.sender);
    require (balance >= value,"Insufficient funds!");
    ///Begin the buying loop!///
    require(buying==false,"Re-entry not allowed!");
    buying = true;
    ///loop to insert user!
    ///Verify that raffle is not paused!
    require (temp.isopen==true,"Selected raffle is paused!");
    ///Verify it has not ended!/////
    require (block.timestamp < temp.endtime, "Raffle has ended!");
    ///loop to insert tickets!
    for (uint256 s = 0; s < _numtickets; s += 1){
           temp.tickets.push(msg.sender);
    }
    
    
    
    ///Remove from balance
    Bank(bank).manageBalances(2,msg.sender,value);
    
    }
    
    /////Function to claim reward
    function claimPrize(uint _rafflenumber) external
    {
    //Are raffles allowed at global level?
    require (rafflesopen==true,"Raffles are currently disabled!");
    ///retrieve the selected raffle!//////
    Raffle storage temp = raffles[_rafflenumber];
    ///Verification that user is not blocked
    (bool isblocked,) = wrapperdb(db).isBlockedNFT(1); //Default to the 1 to force an address based check in the DB
    require(isblocked!=true,"Address has been blocked!");
    ///Verify that the claiment is actually the winner!
    require (msg.sender == temp.winner,"Sorry you are not the winner!");
    ///Verify that the raffle is ended////
    require (block.timestamp > temp.endtime, "Raffle has not ended!");
    
    //Verify if the prize is a token or an NFT
    if (temp.istoken==false)
    {
        //NFT
        NFT(temp.project).transferFrom(address(this),msg.sender,temp.prizevalue); //Prizevalue in this case is the NFT number!
    }
    if (temp.istoken==true)
    {
        //TOKEN payout!
        ERC20(temp.project).transfer(msg.sender,temp.prizevalue);
    }
    ///Set the Winner to The ETH burn address to ensure that there is no doublespends!
    temp.winner = 0x000000000000000000000000000000000000dEaD;
    temp.isopen=false; //Pause the raffle too!
    ///
    }

    //Manual Payout for the winner!
    function airdropPayout(uint _rafflenumber,address _payee) external {
        ////retrieve the selected raffle!//////
    Raffle storage temp = raffles[_rafflenumber];
    //Add check to make sure the winner is actually the winner!
    require(temp.winner==_payee,"User is not the winner!");
    if (msg.sender != Owner)
    {
    bool temp = authorized[msg.sender];
    require(temp==true,"You are not authorised!");
    }
    if (temp.istoken==false)
    {
        //NFT
        NFT(temp.project).transferFrom(address(this),_payee,temp.prizevalue); //Prizevalue in this case is the NFT number!
    }
    if (temp.istoken==true)
    {
        //TOKEN payout!
        ERC20(temp.project).transfer(_payee,temp.prizevalue);
    }
    ///Set the Winner to The ETH burn address to ensure that there is no doublespends!
    temp.winner = 0x000000000000000000000000000000000000dEaD;
    temp.isopen=false; //Pause the raffle too!
    temp.endtime = block.timestamp; // Ensure raffle has ended time wise!
    }
    
    //Function to manage the parameters of a certain raffle if needs be
    function manageRaffle(uint _rafflenumber,uint option,string memory _text,address _address,uint _value,bool _yesno,uint _ticketprice) external onlyOwner{
        ////retrieve the selected raffle!//////
        Raffle storage temp = raffles[_rafflenumber];
        uint temp1;
        uint temp2;
        if (option==1)
        {
        temp.rafflename = _text;
        }
        if (option==2)
        {
        temp.imgurl = _text;
        }
        if (option==3)
        {
        temp.endtime = _value; 
        }
        if (option==4)
        {
        temp.winner = _address;
        temp.isopen = false; //End the raffle right away!
        temp.endtime = block.timestamp; // set end time to now!
        }
        if (option==5)
        {
        temp.project = _address;
        }
        if (option==6)
        {
        temp.istoken = _yesno;
        }
        if (option==7)
        {
        temp.isopen = _yesno;
        }
        if (option==8)
        {
        temp.wtconly = _yesno;
        }
        if (option==9)
        {
        temp.prizevalue = _value;
        }
        if (option==10)
        {
        temp.nonwtconly = _yesno;
        }
        if (option==11)
        {
        ////remove user from raffle array!
        temp.tickets[_value] = temp.tickets[temp.tickets.length - 1]; //_value is the index
        temp.tickets.pop();
        }
        if (option==12)
        {
        ////remove user from raffle array!
        temp.tickets.push(_address);
        }
        if (option==13)
        {
        ///payout the creator
        if (creatorpercentage==10)
        {
            temp1 = temp.tickets.length.div(100);
            temp2 = temp1.mul(10);
            Bank(bank).manageBalances(1,temp.creator,temp2);
        }
        if (creatorpercentage==20)
        {
            temp1 = temp.tickets.length.div(100);
            temp2 = temp1.mul(20);
            Bank(bank).manageBalances(1,temp.creator,temp2);
        }
        if (creatorpercentage==30)
        {
            temp1 = temp.tickets.length.div(100);
            temp2 = temp1.mul(30);
            Bank(bank).manageBalances(1,temp.creator,temp2);
        }
        if (option==14)
        {
            temp.ticketprice = _ticketprice;
        }

        }
        
    }

    //Function to all authorized users ability to set winner
    function setWinner(uint _rafflenumber,address _winner) external{
    Raffle storage temp = raffles[_rafflenumber];
    if (msg.sender!=Owner)
    {
      bool temp = authorized[msg.sender];
      require (temp==true,"Not authorized to set Winner!");
    }
    temp.winner = _winner;
    temp.isopen = false; //End the raffle right away!
    temp.endtime = block.timestamp; // set end time to now!
    }


    //Function to retrieve Tokens/NFT's in error out of the contract!
    //Manual Payout for the winner!
    function emergencywithdrawl(uint _rafflenumber,address _project,address _payee) external onlyOwner{
        ////retrieve the selected raffle!//////
        Raffle storage temp = raffles[_rafflenumber];
    if (temp.istoken==false)
    {
        //NFT
        NFT(_project).transferFrom(address(this),_payee,temp.prizevalue); //Prizevalue in this case is the NFT number!
    }
    if (temp.istoken==true)
    {
        //TOKEN payout!
        ERC20(_project).transfer(_payee,temp.prizevalue);
    }
    }

    
    //Function to retrieve data from a raffle
    function getRaffleDetails(uint _rafflenumber) external view returns(string memory,string memory,address,uint,uint,address,address,bool,bool,uint,uint)
    {
        Raffle storage temp = raffles[_rafflenumber];
        return (temp.rafflename,temp.imgurl,temp.creator,temp.tickets.length,temp.endtime,temp.winner,temp.project,temp.isopen,temp.wtconly,temp.prizevalue,temp.ticketprice);

    }

    function getAddressAtIndex(uint _rafflenumber,uint _index)external view returns(address)
    {
        Raffle storage temp = raffles[_rafflenumber];
        return (temp.tickets[_index]);
    }

    function manageAuth(address _newuser,bool _isallowed) external onlyOwner
    {
        authorized[_newuser] = _isallowed;
    }

    function getNumTicketsPerUser(address _ticketholder,uint _rafflenumber) external view returns(uint)
    {
        Raffle storage temp = raffles[_rafflenumber];
        uint ticketcount = temp.tickets.length;
        uint userstickets;
        ///loop to insert tickets!
        for (uint256 s = 0; s < ticketcount; s += 1){
           if(temp.tickets[s]==_ticketholder)
           {
               userstickets++;
           }
    }
          //Return the amount of tickets a user has in a raffle
          return userstickets;
        
    }


}