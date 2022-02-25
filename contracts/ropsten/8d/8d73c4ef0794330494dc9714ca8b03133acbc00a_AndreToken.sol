/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

pragma solidity 0.8.7;

    library SafeMath {
        function mul(uint256 a, uint256 b) internal pure returns (uint256) {
            if (a == 0) {
            return 0;
            }
            uint256 c = a * b;
            assert(c / a == b);
            return c;
        }

        function div(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a / b;
            return c;
        }

        function sub(uint256 a, uint256 b) internal pure returns (uint256) {
            assert(b <= a);
            return a - b;
        }

        function add(uint256 a, uint256 b) internal pure returns (uint256) {
            uint256 c = a + b;
            assert(c >= a);
            return c;
        }
    }

contract AndreToken {

    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    /**
    * Layout:
    * 1. Storage variable --> Part: 
        1. Data Types --> uint256, bytes32, bool, string.
        2. Visibility --> Public, private, internal, external.
        3. Variable / storage name.
    * 2. Event.
    * 3. Modifier.
    * 4. Function.
        1. visibility -> public, private, internal, external
        2. Type -> view, pure, constant
    */
    string private name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public temp;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    /* 
    mapping == dict, array of object. 
    adress -> tipe data 
    */
    constructor(){
        name = "AndreToken";
        symbol = "ANTO";
        totalSupply = 100e18;
        balanceOf[msg.sender] = totalSupply;
    }

    function decimals() public pure returns(uint8){
        return 18;
    }

    /**
    - Transfer token to spesific address.
    - address = 20 bytes = 40 characters excluding 0x
    **/

    function transfer(address _to, uint256 _amount) public returns (bool){
        // require fungsi bawaan untuk validasi
        require(_amount > 0, "ERR_ZERO_AMOUNT");
        require(_to != address(0), "ERR_ZERO_ADDRESS");

        // msg.sender == caller address / caller wallet address
        // msg.value == how many ethereum being sent.
        // msg.data == hexadecimal.
        require(balanceOf[msg.sender] >= _amount);

        /** 
        Process
        1. sub balance sender
        2. add balance recipient
        **/
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);
        
        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool){
        require(_amount > 0, "ERR_ZERO_AMOUNT");
        require(allowance[_from][msg.sender] >= _amount, "ERR_LESS_ALOWANCE");
        require(_to != address(0), "ERR_ZERO_ADDRESS");
        require(balanceOf[_from] >= _amount,"ERR_INSUFFIENT_BALANCE");

        //process
        balanceOf[_from] = balanceOf[_from].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_amount);

        emit Transfer(_from, _to, _amount);

        return true;
    }

    function approve(address _spender, uint256 _amount) public returns(bool){
        require(_amount > 0, "ERR_ZERO_AMOUNT");

        allowance[msg.sender][_spender] = _amount;
        
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }


//     function name() public view returns (string)
// function symbol() public view returns (string)
// function decimals() public view returns (uint8)
// function totalSupply() public view returns (uint256)
// function balanceOf(address _owner) public view returns (uint256 balance)
// function transfer(address _to, uint256 _value) public returns (bool success)
// function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)
// function approve(address _spender, uint256 _value) public returns (bool success)
// function allowance(address _owner, address _spender) public view returns (uint256 remaining)
}