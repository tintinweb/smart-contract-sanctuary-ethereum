/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

pragma solidity >=0.7.0 <0.9.0;

contract TestCoin{

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    string public constant name = "Test Coin";
    string public constant symbol = "TCO";
    uint8 public constant decimal = 18;
    uint totalSupply;

    mapping(address=>uint256) balances;
    mapping(address=>mapping(address=>uint256)) allowed;

    constructor(uint256 total){
        totalSupply = total;
        balances[msg.sender] = totalSupply;
    }

    function _mint(uint token) private returns(bool){
        balances[msg.sender] += token;
        return true;
    }

    function balanceOf(address tokenOwner) public view returns(uint){
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint tokens) public returns(bool){
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] -= tokens;
        balances[receiver] += tokens;
        emit Transfer(msg.sender,receiver,tokens);
        return true;
    }

    function approve(address white, uint tokens) public returns(bool){
        allowed[msg.sender][white] = tokens;
        emit Approval(msg.sender,white,tokens);
        return true;
    }

    function allowance(address owner, address white) public view returns(uint){
        return allowed[owner][white];
    }

    function transferFrom(address owner,address buyer, uint token) public returns(bool){
        require(token <= balances[owner],"Not enough balance");
        require(token <= allowed[msg.sender][owner]);
        balances[owner] -= token;
        balances[buyer] += token;
        emit Transfer(owner, buyer, token);
        return true;
    }


}