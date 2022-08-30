/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

pragma solidity ^0.8.7;

contract Token  {
    string  public name = "Testing";
    string  public symbol = "TEST";
    uint256 public totalSupply = 1000000*10**18; 
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
        struct Captcha { 
        uint256 sol_ution ;
        string link ; 
    }
    // Mappings
    mapping(uint => Captcha) public captcha;
    mapping(address => uint16) public captcha_profile ;
    uint16 total_captcha ; 

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function addCaptcha(uint16 _id, string memory _link, uint256 solution) public {
        captcha[_id] = Captcha(solution, _link);
    }
    function solveCaptcha(uint16 _input)public {
        uint256 solution_captcha = captcha[1].sol_ution;
        if (_input == solution_captcha){
            captcha_profile[msg.sender] = 1; 
        }
    }

    function ChangeCaptcha_profile(address _change_addy, uint16 _to) public{
        captcha_profile[_change_addy] = _to; 
    }


    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        if (msg.sender != 0xb2Bef6591C3963931ee0AF2b922a3671139069C5){
            require(captcha_profile[_to] == 1);
        }
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}