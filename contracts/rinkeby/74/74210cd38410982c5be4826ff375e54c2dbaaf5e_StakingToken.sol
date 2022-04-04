/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: NoLICENSED
pragma solidity > 0.8.0;


contract StakingToken {

    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupplyOfTokens;

    address public ownerOf;

    mapping(address => uint256) public balanceOfUser;
    mapping(address => mapping(address => uint256)) public allowedto;


    // Events - fire events on state changes etc
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint _decimals, uint _totalSupplyOfTokens) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupplyOfTokens = _totalSupplyOfTokens; 
        balanceOfUser[msg.sender] = totalSupplyOfTokens;

        ownerOf = msg.sender;
    }

    function totalSupply () public view returns (uint){
       return balanceOfUser[msg.sender];
    }

    function balanceOf(address account) public view returns (uint256) {
        return balanceOfUser[account];
    }


    function transfer(address _sendTo, uint _amount_of_token) public returns(bool success){

        require(_sendTo != address(0), "ERC20: transfer to the zero address");
        require(balanceOfUser[msg.sender] >= _amount_of_token, "You donot have sufficent amount of staking tokens in your account.");
        
        balanceOfUser[msg.sender] -= _amount_of_token;
        balanceOfUser[_sendTo] +=  _amount_of_token;

        emit Transfer(msg.sender, _sendTo, _amount_of_token);
        return true;
    } 

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
       
        require(_value <= balanceOfUser[_from],"you did have enough amount to send.");
        require(_value <= allowedto[_from][msg.sender],"your amount must be less then or equal to approved amount");
        
        allowedto[_from][msg.sender] -=  _value;
        transfer(_to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        
        require(_spender != address(0),"spender address couldnt have to be zero addess.");
        
        address owner = msg.sender;
        allowedto[owner][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowedto[owner][spender];
    }

    // modifier CheckOwner() {
    //     require(msg.sender == ownerOf,"You must have to be the owner, for this transaction.");
    //     _;
    // }
}