pragma solidity ^0.5.0;

import './ART.sol';
import './Allure.sol';

contract AllureStaking {
    string public name = 'Allure Staking';
    address public owner;
    Allure public allure;
    ART public art;

    address[] public stakers;
     
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor(ART _art, Allure _allure) public {
        art = _art;
        allure = _allure;
        owner = msg.sender;
    }

    //Staking function
    function depositTokens(uint _amount) public {

        // require staking amount to be greater than zero
        require(_amount > 0, 'amount cannot be 0');

        //Transfer allure tokens to this contract for staking
        allure.transferFrom(msg.sender, address(this), _amount);

        // Update Staking Balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;

        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // Update Staking Balance
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    //unstake tokens
    function unstakeTokens() public {
        uint balance = stakingBalance[msg.sender];
        require(balance > 0, 'unstaking balance cannot be less than zero');

        //transfer the tokens to the specified contract address
        allure.transfer(msg.sender, balance);

        // reset staking Balance
        stakingBalance[msg.sender] = 0;


        // Update Staking Status
        isStaking[msg.sender] = false;
    }

    // issue rewards\
    function issueTokens() public {
        // require the owner to issue tokens only
        require(msg.sender == owner, 'caller must be the owner of the message');
        for (uint i=0; i<stakers.length; i++) {
            address recipients = stakers[i];
            uint balance = stakingBalance[recipients] / 9; //9 to create percentage incentive for stakers
            if(balance > 0) {
                art.transfer(recipients, balance);
            }
        }
    }

    

}

pragma solidity ^0.5.0;

contract Allure {
    string  public name = "Allure Energy Token";
    string  public symbol = "AET";
    uint256 public totalSupply = 100000000000000000000000000;  // 1 million tokens
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // require that the value is greater or equal for transfer
        require(balanceOf[msg.sender] >= _value);
        // transfer the amount and subtract the balanceOf
        balanceOf[msg.sender] -= _value;
        // add the balance
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender] [_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
       require(_value <= balanceOf[_from]);
       require(_value <= allowance[_from][msg.sender]);
       // add the balance for transferFrom
       balanceOf[_to] += _value;
       // subtract the balance for transferFrom
       balanceOf[_from] -= _value;
       allowance[msg.sender][_from] -= _value;
       emit Transfer(_from, _to, _value);
       return true;
    }

    
}

pragma solidity ^0.5.0;

contract ART {
    string  public name = "Allure Reward Token";
    string  public symbol = "ART";
    uint256 public totalSupply = 100000000000000000000000000;  // 1 million tokens
    uint8   public decimals = 18;

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // require that the value is greater or equal for transfer
        require(balanceOf[msg.sender] >= _value);
        // transfer the amount and subtract the balanceOf
        balanceOf[msg.sender] -= _value;
        // add the balance
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender] [_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
       require(_value <= balanceOf[_from]);
       require(_value <= allowance[_from][msg.sender]);
       // add the balance for transferFrom
       balanceOf[_to] += _value;
       // subtract the balance for transferFrom
       balanceOf[_from] -= _value;
       allowance[msg.sender][_from] -= _value;
       emit Transfer(_from, _to, _value);
       return true;
    }

    
}