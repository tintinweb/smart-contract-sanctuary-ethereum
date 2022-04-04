/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Wormhole {


  address public owner;
  uint public credit_conversion=10000*10**18;//1 ETH buys this amount of credits
  uint public protocol_transaction_fee=4000;//in basis points - (i.e.300)
  uint public collected_transaction_fees;//in credits
  using SafeMath for uint256;




  mapping (address => individual_creator) public creators_array;//record-keeping for creators
  mapping (address => individual_stream[]) public past_streams;//record-keeping for a creator's past streams
  mapping (address => individual_stream) public stream_array;//record-keeping for streams
  mapping (string => address) public usernames;//record-keeping of unique usernames
  
  mapping (address => bool) public banned_streamers;
  mapping (address => uint) public credit_balance;
  address[] active_streamers;

  mapping (address => address) public linkMobileToDesktop;
  mapping (address => address) public linkDesktopToMobile;


  struct individual_creator{
      string creator_name;
      string creator_pic;
      uint creator_cost;
      string stream_key;
      bool is_created;
  }
    struct individual_stream{
      string stream_url;
      string stream_thumbnail;
      string stream_description;
      string creator_name;
      address streamer_address;
      uint cost;
      bool is_streaming;
      uint start_time;
      uint paid;
  }

  event Stream_Payment(
      address indexed _from,
      uint256 _payment_amount,
      address _streamer_address,
      string _streamer_name,
      uint256 _timestamp
  );
  event Mobile_Desktop_Linked(
      address indexed mobileAddress,
      address indexed desktopAddress
  );


  constructor() public {
    owner = msg.sender;
  }
  receive() external payable {}




  function refund_credits() external returns (uint){
    require(0 < credit_balance[msg.sender], "You don't have enough credits left");


    uint remaining_credits=credit_balance[msg.sender];
    credit_balance[msg.sender]=0;

    uint _mul=remaining_credits.mul(10**18);
    uint _div=_mul.div(credit_conversion);
    msg.sender.transfer(_div);

  }
  function extract_protocol_revenue() external returns (uint){

    require(msg.sender == owner, "Only owner can extract protocol revenue");
    require(0 < collected_transaction_fees, "No Collected Transaction Fees");


    uint remaining_credits=collected_transaction_fees;
    collected_transaction_fees=0;

    uint _mul=remaining_credits.mul(10**18);
    uint _div=_mul.div(credit_conversion);
    msg.sender.transfer(_div);

  }
  function buy_credits() public payable{
    require(banned_streamers[msg.sender] ==false, "You are banned from acquiring credits!");

    uint _mul=msg.value.mul(credit_conversion);
    uint _div=_mul.div(10**18);
    credit_balance[msg.sender]=credit_balance[msg.sender]+_div;
  }
  function stream_payment(uint cost, address streamer_address) public{
      require(cost <=credit_balance[msg.sender], "You don't have enough credits left");

      uint credit_after_deducting_fee=return_credit_after_fee(cost);
      uint fee_allocation=cost.sub(credit_after_deducting_fee);


      credit_balance[msg.sender]=credit_balance[msg.sender]-cost;
      collected_transaction_fees=collected_transaction_fees + fee_allocation;
      credit_balance[streamer_address]=credit_balance[streamer_address]+credit_after_deducting_fee;

      individual_stream memory this_stream=stream_array[streamer_address];
      string memory this_creator_name=this_stream.creator_name;
      stream_array[streamer_address].paid=stream_array[streamer_address].paid+credit_after_deducting_fee;

      emit Stream_Payment(msg.sender, cost, streamer_address, this_creator_name, block.timestamp);

  }
  function end_stream(address streamer_to_cancel) public{

    require(streamer_to_cancel ==msg.sender || owner == msg.sender, "You don't have permission to cancel this stream!");

    past_streams[streamer_to_cancel].push(stream_array[streamer_to_cancel]);//add current stream to array containing all previous streams

    individual_stream memory blank_stream_struc = individual_stream({stream_url:"", stream_thumbnail:"", stream_description:"", creator_name:"", streamer_address:0x0000000000000000000000000000000000000000, cost:0, is_streaming:false, start_time:0, paid:0});
    stream_array[streamer_to_cancel]=blank_stream_struc;
    
      for(uint i =0; i<active_streamers.length; i++){
         if(active_streamers[i]==streamer_to_cancel){//remove this specific user from the array

				      for(uint j =i; j<active_streamers.length - 1; j++){///uses more gas than unordered deletion
					      active_streamers[j]=active_streamers[j+1];
				      }
				      active_streamers.pop();
              return;

          }
      }
  }
  function start_stream(string memory _stream_url, string memory _stream_thumbnail, string memory _stream_description, string memory _creator_name, uint _cost) public{
    require(banned_streamers[msg.sender] ==false, "You are banned from streaming!");
    require(keccak256(abi.encodePacked(creators_array[msg.sender].stream_key))!=keccak256(abi.encodePacked("")), "You need to approve streaming!");

    bool check_if_already_streaming =stream_array[msg.sender].is_streaming;
    require(check_if_already_streaming ==false, "You can only have 1 active stream running!");

    individual_stream memory new_stream = individual_stream({stream_url:_stream_url, stream_thumbnail:_stream_thumbnail, stream_description:_stream_description, creator_name:_creator_name, streamer_address:msg.sender, cost:_cost, is_streaming:true, start_time:block.timestamp, paid:0});
    stream_array[msg.sender]=new_stream;
    active_streamers.push(msg.sender);

  }
  function update_creator_info(string memory _creator_name, string memory _creator_pic, uint _creator_cost) public {

      bool check_if_exists=creators_array[msg.sender].is_created;
      if(check_if_exists==false){//new account

        address check_username=usernames[_creator_name];
        require(check_username==address(0), "Chosen username already taken");

        usernames[_creator_name]=msg.sender;
        individual_creator memory creator_struc = individual_creator({creator_name:_creator_name, creator_pic:_creator_pic, creator_cost:_creator_cost, stream_key:"", is_created:true});
        creators_array[msg.sender]=creator_struc;
      }
      else{//updating existing account - do not allow changing username
        creators_array[msg.sender].creator_pic=_creator_pic;
        creators_array[msg.sender].creator_cost=_creator_cost;
      }
      
      

  }
  function approve_streaming_for_creator(string memory _stream_key) public {
    require(creators_array[msg.sender].is_created==true, "Must create profile first");//can only approve stream if profile has been created
    
    creators_array[msg.sender].stream_key=_stream_key;
  }
  function fetch_all_live_streams() external view returns (individual_stream[] memory){

    individual_stream[] memory fetched_streams = new individual_stream[](active_streamers.length);
    for(uint i =0; i<active_streamers.length; i++){
        fetched_streams[i] = stream_array[active_streamers[i]];
    }
    return fetched_streams;

  }
  function fetch_past_streams(address fetch_account) external view returns (individual_stream[] memory){
    return past_streams[fetch_account];
  }
  function fetch_creator_stream(address fetch_account) external view returns (individual_stream memory){
    return stream_array[fetch_account];
  }
  function fetch_balance(address fetch_account) external view returns (uint){
    return credit_balance[fetch_account];
  }
  function fetch_creator_info(address fetch_account) external view returns (individual_creator memory){
    return creators_array[fetch_account];
  }



/////////////////////////////////////////////////////////////////////////////////////////////////Utility Functions//////////////////////////////////////////////////////////////////////
  function return_active_streamers() public view returns (address [] memory){
    return active_streamers;
  }
  function transfer_owner(address newOwner) public{
      require(owner == msg.sender, "You don't have permission to transfer ownership!");
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      owner = newOwner;
  }
  function set_protocol_transaction_fee(uint _new_fee) external{
      require(owner == msg.sender, "You don't have permission to set the transaction fee!");

      protocol_transaction_fee=_new_fee;
      return;
  }
  function return_credit_after_fee(uint _amount) public view returns (uint){
      uint one_hundred=10000;//in basis points
      uint subtract_fee=one_hundred.sub(protocol_transaction_fee);
      uint credit_after_fee=_amount.mul(subtract_fee);
      credit_after_fee=credit_after_fee.div(one_hundred);
      return credit_after_fee; 
  }
  function ban_unban_streamer(address streamer, uint _type) external{
    require(owner == msg.sender, "You don't have permission to ban a streamer!");

    if(_type==0){
      banned_streamers[streamer]=false;
    }
    else{
      banned_streamers[streamer]=true;
    }
  }

  function link_mobile_desktop_wallest(address mobile, address desktop) external{// To:do: add in only can call
    require(owner == msg.sender, "No permission to link wallets");

    linkMobileToDesktop[mobile]=desktop;
    linkDesktopToMobile[desktop]=mobile;

    emit Mobile_Desktop_Linked(mobile,desktop);

  }


}