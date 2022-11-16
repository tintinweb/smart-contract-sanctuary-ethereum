/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract OpenHatch is Ownable {
    using SafeMath for *;

    uint256 private _days;
    address fundBox;
    uint256 submit_fee = 10; // 2% foundation
    uint256 fee = 200; // 2% foundation
    //variables defined
    address[] public judges;
    string private code;
    enum TYPEBOX{ REWARDS, FEES }

    struct Proposal_str {
        uint256 budget;
        uint256[] slot_budget;
        uint256[] slot_paid;
        address author;
        address acceptor;
        string id;
        uint256 start_date;
        uint256 due_date;
        bool active;
        uint256 count_timelines;
        address base_token;
    }

    struct Judge_form {
        address judge;
        address _base_token;
        uint256 deposit;
        string id;
        bool active;
        bool withdraw;
    }

    struct Subscribe_form {
        address owner;
        uint256 fee;
        bool active;
        uint256 due_date;
        uint256 start_date;
        address base_token;
    }

    struct Box_Fees {
        
        TYPEBOX boxType;
        uint sum;
    }
    mapping(string => Subscribe_form) private _Subscribe;
    mapping(string => uint256) private balanceSubscription;
    mapping(string => Proposal_str) _OpenHatch;
    mapping(string => Judge_form) _judges;
    mapping(address => uint) _depositJudges;
    mapping(address => mapping(TYPEBOX => uint)) public _depositBox;
    mapping(address => uint) private _limitionWithdraw;
   

    Proposal_str proposal_str;

    constructor(
        // address fundBox_address,
        // string memory _code,
        // uint256 Days
    ) {
        // code = _code;
        // fundBox = fundBox_address;
        // _days = Days;
        code = "sadsa";
        fundBox = 0xb0849Ace22a4738475bc62C02dA79a15a5Bc6B8A;
        _days = 22;
    }

    //modifiers
    modifier onlyAuthor(string memory id) {
        require(msg.sender == _OpenHatch[id].author, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    modifier isOpen(string memory id) {
        require(_OpenHatch[id].active, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    //functions

    function submit_openHatch(
        address[] memory mix_addresses,// author , acceptor , bastoken
        uint256 _budget,
        uint256[] memory _slot_budget,
        uint256[] memory _slot_paid,
        string memory _id,
        uint256 _due_date,
        uint256 _count_timelines
    ) public returns (bool) {
        //
        require(
            keccak256(bytes(_OpenHatch[_id].id)) != keccak256(bytes(_id)),
            "This OpenHatck has been registerd "
        );

        //   uint f  = _budget;
        uint256 totalFee = (_budget * fee) / get_submitFee();
        uint256 real_budget = _budget - totalFee;
        uint256 fee_rewards = totalFee/2;
        uint256 fee_admin = totalFee - fee_rewards;
   
        //   require(sum_array(_slot_budget, platfdorm), "The total budget is wrong!");

        //send to fund box
        _depositBox[mix_addresses[2]][TYPEBOX.FEES] = _depositBox[mix_addresses[2]][TYPEBOX.FEES] + fee_admin;
        _depositBox[mix_addresses[2]][TYPEBOX.REWARDS] = _depositBox[mix_addresses[2]][TYPEBOX.REWARDS] + fee_rewards;
        // _depositBox[TYPEBOX.FEES]=_depositBox[TYPEBOX.FEES]+fee_admin;
        transferToContract(mix_addresses[2], msg.sender, address(this), _budget);
     

        creator(
            real_budget,
            _slot_budget,
            _slot_paid,
             mix_addresses,
            _id,
            timestamp(),
            _due_date,
            _count_timelines
            
        );
        return true;
    }

    function creator(
        uint256 _budget,
        uint256[] memory _slot_budget,
        uint256[] memory _slot_paid,
        address[] memory mix_addresses,
        string memory _id,
        uint256 _start_date,
        uint256 _due_date,
        uint256 _count_timelines
    ) internal  slot_(_budget,_slot_budget){
        //make openhatch
        _OpenHatch[_id] = Proposal_str(
            _budget,
            _slot_budget,
            _slot_paid,
            mix_addresses[0],//author
            mix_addresses[1],//_acceptor
            _id,
            _start_date,
            _due_date,
            true,
            _count_timelines,
            mix_addresses[2]//_base_token
        );
    }

    modifier slot_(
        uint256 _budget,
        uint256[] memory _slot_budget
    )
    {
        bool result = false;
        uint total = 0;
        for (uint256 i = 0; i < _slot_budget.length; i++) {
            total = _slot_budget[i]+total;
        }

        if(total == _budget){
            result = true;
        }
        require(total == _budget, "the budget is opposite of slots");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
       
    }


    function get_openHatck(string memory id)
        public
        view
        returns (Proposal_str memory)
    {
        return _OpenHatch[id];
    }

   
    function get_submitFee()
    public
    view
    returns ( uint)
    {
        return submit_fee*1000;
    }

    function get_rewardsBox(address base_token)
    public
    view
    returns ( uint)
    {

        return _depositBox[base_token][TYPEBOX.REWARDS];
    }

    function get_adminBox(address base_token)
    public
    view
    returns ( uint)
    {
        return _depositBox[base_token][TYPEBOX.FEES];
    }

    function set_submitFee(uint _fee)
    public
    onlyOwner
    {
        submit_fee = _fee;
    }


    function close_openHatch(string memory id)
        public
        onlyAuthor(id)
        isOpen(id)
    {
        _OpenHatch[id].active = false;
    }

    function submitAsSubscribe(
        uint256 _fee,
        string memory _authorId,
        address _base_token
    ) public returns (bool) {
        require(
            balance_token(_base_token, msg.sender) >= _fee,
            "Please submit the asking fee!"
        );

        transferToContract(_base_token, msg.sender, address(this), _fee);
        _Subscribe[_authorId] = Subscribe_form(
            msg.sender,
            _fee,
            true,
            timestampDays(_days),
            timestamp(),
            _base_token
        );

        return true;
    }

    function submitSubscription(uint256 _fee, string memory _authorId)
        public
        returns (bool)
    {
        address token = _Subscribe[_authorId].base_token;
        require(
            balance_token(token, msg.sender) >= _fee,
            "Please submit the asking fee!"
        );
        require(
            _Subscribe[_authorId].due_date != timestamp(),
            "This Subscribe Is unavailable !"
        );
        transferToContract(token, msg.sender, address(this), _fee);
        balanceSubscription[_authorId] = balanceSubscription[_authorId] + _fee;
        return true;
    }

    function returnSubscribe(string memory _authorId)
        public
        view
        returns (Subscribe_form memory)
    {
        return _Subscribe[_authorId];
    }

    function WithdrawSubscrip(uint256 _fee, string memory _authorId)
        public
        returns (bool)
    {
        require(
            balanceSubscription[_authorId] >= _fee,
            "Please submit the asking fee!"
        );
        require(
            _Subscribe[_authorId].active == false,
            "This Subscribe Is unavailable !"
        );
        require(
            _Subscribe[_authorId].owner != msg.sender,
            "This Subscribe Is unavailable !"
        );
        transferFromContract(
            _Subscribe[_authorId].base_token,
            _Subscribe[_authorId].owner,
            _fee
        );
        balanceSubscription[_authorId] = balanceSubscription[_authorId] - _fee;
        return true;
    }

    function withdrawReward(uint256 amount, string memory _judgeId,address base_token)
     public
     returns (bool)
    {

        require(
            _judges[_judgeId].active == false,
            "This _judgeId Is unavailable !"
        );

        require(
            _depositBox[base_token][TYPEBOX.REWARDS]< amount,
            
            "This _judgeId Is unavailable !"
        );


        require(
            _judges[_judgeId].judge != msg.sender,
            "This _judgeId Is unavailable !"
        );

        require(
            _limitionWithdraw[msg.sender] != timestamp(),
            "This Subscribe Is unavailable !"
        );

        transferFromContract(
            base_token,
            _judges[_judgeId].judge,
            amount
        );

  
            _depositBox[base_token][TYPEBOX.REWARDS] =_depositBox[base_token][TYPEBOX.REWARDS]- amount ;
            _limitionWithdraw[msg.sender] = timestampDays(8);
            return true;

        }

   
    
    function limitaionJudge() public view returns (uint){
     return _limitionWithdraw[msg.sender];
    }
     

    function withdrawRewardAdmin(uint256 amount,   address base_token)
        public
        onlyOwner
        returns (bool)
    {



        require(

            _depositBox[base_token][TYPEBOX.FEES]< amount,
            "This Subscribe Is unavailable !"
        );


        transferFromContract(
            base_token,
            owner(),
            amount
        );

        _depositBox[base_token][TYPEBOX.FEES] =  _depositBox[base_token][TYPEBOX.FEES] - amount ;
        return true;
    }

    function close_openHatch_admin(string memory id)
        public
        onlyOwner
        isOpen(id)
    {
        _OpenHatch[id].active = false;
    }

    function add_pays(uint256[] memory phase_indexs, string memory id)
        public
        onlyAuthor(id)
        isOpen(id)
    {
        for (uint256 i = 0; i < phase_indexs.length; i++) {
            add_pay(phase_indexs[i], id);
        }
    }

    function add_pay(uint256 phase_index, string memory id)
        public
        onlyAuthor(id)
        isOpen(id)
    {
        proposal_str = _OpenHatch[id];
        if (phase_index > proposal_str.slot_paid.length) return;

        //send to acceptor
        transferFromContract(
            proposal_str.base_token,
            proposal_str.acceptor,
            proposal_str.slot_budget[phase_index]
        );

        //paid success
        proposal_str.slot_paid.push(proposal_str.slot_paid.length + 1);
    }

    function add_pay_admin(uint256 phase_index, string memory id)
        public
        onlyOwner
        isOpen(id)
    {
        proposal_str = _OpenHatch[id];
        if (phase_index > proposal_str.slot_paid.length) return;

        //send to acceptor
        transferFromContract(
            proposal_str.base_token,
            proposal_str.acceptor,
            proposal_str.slot_budget[phase_index]
        );

        //paid success
        proposal_str.slot_paid.push(proposal_str.slot_paid.length + 1);
    }

    function add_judge(
        string memory id,
        string memory _code,
        uint256 deposit,
        address _base_token
    ) public {
        if (
            (keccak256(abi.encodePacked((_code))) !=
                keccak256(abi.encodePacked((code))))
        ) {
            revert("This code not found");
        }
        require(
            keccak256(bytes(_judges[id].id)) != keccak256(bytes(id)),
            "This Judge has been registerd "
        );

        _judges[id] = Judge_form(
            msg.sender,
            _base_token,
            deposit,
            id,
            true,
            false
        );
        //send deposit to contarct
        transferToContract(_base_token, msg.sender, address(this), deposit);
    }

    function get_judge(string memory _id)
        public
        view
        returns (Judge_form memory)
    {
        return _judges[_id];
    }

    function pop_judge(string memory _id) internal onlyOwner {
        _judges[_id].active = false;
        _judges[_id].withdraw = true;

        //back deposit to judge
        //  //send to owner of platform
        transferFromContract(
            _judges[_id]._base_token,
            _judges[_id].judge,
            _judges[_id].deposit
        );
    }

    function change_FundBox_address(address _newAddress) public onlyOwner {
        fundBox = _newAddress;
    }

    function change_fee(uint256 _newFee) public onlyOwner {
        fee = _newFee;
    }

    //helpers
    function sum_array(uint256[] memory array, uint256 total)
        internal
        pure
        returns (bool)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < array.length; i++) {
            sum = array[i] + sum;
        }

        if (sum > total) {
            return false;
        } else {
            return true;
        }
    }

    function fee_platform(uint256 pre) public view returns (uint256) {
        return (pre * fee) / 10000; //
    }

    function transferToContract(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        // requires approval from `victim` to `TokenSwap`
        IERC20(token).transferFrom(from, to, amount);

        // bool owner_share_sent = payable(_owner).send(owner_share);
    }

    function balance_token(address token, address own)
        public
        view
        returns (uint256)
    {
        // requires approval from `victim` to `TokenSwap`
        return IERC20(token).balanceOf(own);
    }

    function transferFromContract(
        address token,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).transfer(to, amount);
    }

    function allowcheck(
        address token,
        address owner,
        address spender
    ) public view returns (uint256) {
        return IERC20(token).allowance(owner, spender);
    }

    function timestamp() private view returns (uint256) {
        return 1000 * block.timestamp; // solidity count seconds, not miliseconds
    }

    function timestampDays(uint _day) private view returns (uint256) {
        uint256 time = 1000 * block.timestamp;
        time = _day * 86400000;
        return time; // solidity count seconds, not miliseconds
    }
}