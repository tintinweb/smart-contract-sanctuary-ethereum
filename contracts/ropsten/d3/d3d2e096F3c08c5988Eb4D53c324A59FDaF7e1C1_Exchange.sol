pragma solidity ^0.8.0;

import "./Token.sol";
// TODO:
// [X] Set the fee account
// [X] Deposit Ether
// [X] Withdraw Ether
// [X] Deposit JJC
// [X] Withdraw JJC
// [X] Check balances
// [X] Make order
// [X] Cancel order
// [X] Fill order
// [X] Charge fees

contract Exchange {
    //Variables
    address public feeAccount; // the account that receives exchange fees
    uint256 public feePercent;
    address constant ETHER = address(0); // allows to store Ether in token mappings to save storage space on the contract
    mapping(address => mapping(address => uint256)) public tokens;  //first key is token address (which token?) second is the address of the user
    mapping(uint256 => _Order) public orders; //Orders' book
    mapping(uint256 => bool) public orderCanceled;
    mapping(uint256 => bool) public orderFilled;
    uint256 public orderCount = 0;

    //Events
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    event Order (
        uint id,
        address user,
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint timestamp
    );
    event Cancel (
        uint id,
        address user,
        address tokenGet,
        uint amountGet,
        address tokenGive,
        uint amountGive,
        uint timestamp
    );
    event Trade(
        uint256 id,
        address user,
        address tokenGet,
        uint256 amountGet,
        address tokenGive,
        uint256 amountGive,
        address userFill,
        uint256 timestamp
    );

    struct _Order {
        uint id;
        address user;
        address tokenGet;
        uint amountGet;
        address tokenGive;
        uint amountGive;
        uint timestamp;
    }


    constructor(address _feeAccount, uint256  _feePercent) {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
    }

    // Used to handle direct transfer to the address
    fallback() external payable {
        revert();
    }

    function depositEther() public payable{
        tokens[ETHER][msg.sender] += msg.value;
        emit Deposit(ETHER, msg.sender, msg.value, tokens[ETHER][msg.sender]);
    }

    function withdrawEther(uint _amount) public {
        require(tokens[ETHER][msg.sender] >= _amount);
        tokens[ETHER][msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit Withdraw(ETHER, msg.sender, _amount, tokens[ETHER][msg.sender]);
    }

    function depositToken(address _token, uint _amount) public {
        require(_token != ETHER);
        // you must approve this token in front-end (and/or tests) b4 deposit
        require(Token(_token).transferFrom(msg.sender, address(this), _amount));
        tokens[_token][msg.sender] += _amount;
        emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);

    }

        function withdrawToken(address _token,uint _amount) public {
        require(tokens[_token][msg.sender] >= _amount);
        tokens[_token][msg.sender] -= _amount;
        require(Token(_token).transfer(msg.sender,_amount));
        emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
    }

    function balanceOf(address _token, address _user) public view returns (uint256){
        return tokens[_token][_user];
    }

    function makeOrder(address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) public {
        orderCount += 1;
        orders[orderCount] = _Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, block.timestamp);
        emit Order(orderCount, msg.sender, _tokenGet, _amountGet, _tokenGive, _amountGive, block.timestamp);
    }

    function cancelOrder(uint256 _id) public {
        _Order storage _order = orders[_id];
        require(address(_order.user) == msg.sender);
        require(_order.id == _id);
        orderCanceled[_id] = true;
        emit Cancel(_order.id, msg.sender, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive, _order.timestamp);
    }

        function fillOrder(uint256 _id) public {
        require(_id > 0 && _id <= orderCount, 'Error, wrong id');
        require(!orderFilled[_id], 'Error, order already filled');
        require(!orderCanceled[_id], 'Error, order already cancelled');
        _Order storage _order = orders[_id];
        _trade(_order.id, _order.user, _order.tokenGet, _order.amountGet, _order.tokenGive, _order.amountGive);
        orderFilled[_order.id] = true;
    }

    function _trade(uint256 _orderId, address _user, address _tokenGet, uint256 _amountGet, address _tokenGive, uint256 _amountGive) internal {
        // Fee paid by the user that fills the order, a.k.a. msg.sender.
        uint256 _feeAmount = _amountGet*feePercent/100;

        tokens[_tokenGet][msg.sender] -= (_amountGet + _feeAmount);
        tokens[_tokenGet][_user] += _amountGet;
        tokens[_tokenGet][feeAccount] += _feeAmount;
        tokens[_tokenGive][_user] -= _amountGive;
        tokens[_tokenGive][msg.sender] += _amountGive;

        emit Trade(_orderId, _user, _tokenGet, _amountGet, _tokenGive, _amountGive, msg.sender, block.timestamp);
    }
}

pragma solidity ^0.8.0;

// Safemath not needed anymore from sol 0.8 onwards
// import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Token {
    // Safemath not needed anymore from sol 0.8 onwards
    // using SafeMath for uint;

    //Variables
    string public name = "JoJo Coin";
    string public symbol = "JJC";
    uint256 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address =>mapping(address => uint256)) public allowance; //Tracks how many tokens the exchange is allowed to spend. First address is yours, second is the exchange


    //Events
    event Transfer(address indexed from, address indexed to, uint256 value);        //indexed means only the events in which we're the receiver/sender?
    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor() {
        totalSupply = 1000000 * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value);
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal{
        require(_to != address(0));
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    // Approve tokens - Allow someone else to spend our tokens
    function approve(address _spender, uint256 _value) public returns (bool success){
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    // Transfer from
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }
}