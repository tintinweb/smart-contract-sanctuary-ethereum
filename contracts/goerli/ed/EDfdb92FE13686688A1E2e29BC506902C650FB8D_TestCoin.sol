/**
 *Submitted for verification at Etherscan.io on 2022-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

library SafeMath {
    function add(uint a, uint b) internal pure returns(uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

    function sub(uint a, uint b) internal pure returns(uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns(uint) {
        if(a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns(uint) {
        uint c = a / b;

        return c;
    }
}

contract Ownable {
    address payable public owner;
    
    event OwnershipTransferred(address newOwner);

    constructor()  {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public  {
        require(newOwner != address(0));

        owner = newOwner;
        emit OwnershipTransferred(owner);
    }
}


abstract contract ERC20  {
    function totalSupply() virtual public view returns (uint);//retorna todo supply da moeda
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    //mostra balanco de cada usuario
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    //é uma consulta para saber se um usuario pode movimentar moedas
    //em nome de outro usuario, entao ela espera o endereço de quem tem os tokens
    //e o endereço do procurador de quem vai movimentar aqueles tokens em seu
    //nome e ainda precisa retornar a quantidade de tokens que ainda consegue movimentar em
    //nome de quem é done daqueles tokens
    function transfer(address to, uint tokens) virtual public returns (bool success);
    //bem parecida com a criada por nos, so tem uma diferença
    //precisa retornar uma boleana no final
    function approve(address spender, uint tokens) virtual public returns (bool success);
    //permite que outros usuarios transfiram moedas no seu nome, entao ela
    //espera quem vai poder fazer isso por voce, seu procurador no caso
    //e a quantidade de tokens que essa pessoa vai movimentar no seu nome
    //espera uma boleana no final
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    //que é como um procurador movimenta moedas de quem permitiu
    //espera o endereço de quem guarda as moedas,
    //endereço de quem vai receber
    //e quantidade  de tokens que vao ser transferidos e 
    //retorna boleana no final

    event Transfer(address indexed from, address indexed to, uint tokens);
    //evento transfer que é igual ao nosso
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    //é disparado quando vc da permissao para algum outro usuario
    //gastar moedas em seu nome
    //dispara o endereço de quem e dono, quem esta gastando, e a quantidade
    //que o procurador tem permissao para movimentar
}

abstract contract BasicToken is Ownable,ERC20 {
    using SafeMath for uint;

    
    uint internal _totalSupply;
    mapping(address => uint) internal _balances;
    mapping(address => mapping(address => uint)) internal _allowed;

    //ENDEREco => ENDERECO =>UNIT

    function totalSupply() override public view returns (uint){
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) override public view returns (uint balance){
        return _balances[tokenOwner];
    }

    function transfer(address to, uint tokens) override public returns (bool sucess){
        require(_balances[msg.sender] >= tokens);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender].sub(tokens);
        _balances[to] = _balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);

        return true;

    }

    function approve(address spender, uint tokens) override public returns(bool sucess){
        //a gente nao consegue falr o que ela faz antes de ter um lugar na block chain
        //onde armazena essas autorizaçoes, quem deu permissao para quem?
        //quantos tokens essa pessoa pode gastar
        _allowed[msg.sender][spender] = tokens;

        emit Approval(msg.sender,spender,tokens);
        //esta declarado no ERC-20
        return true;
    }

    function allowance(address tokenOwner, address spender) override public view returns(uint remaining)
    {
        return _allowed[tokenOwner][spender];
    }

    function transferFrom(address from, address to, uint tokens) override public returns (bool sucess){
        require(_allowed[from][msg.sender]>=tokens);
        require(_balances[from] >= tokens);
        require(to != address(0));

        _balances[from] = _balances[from].sub(tokens);
        _balances[to] = _balances[to].add(tokens);
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(tokens);

        emit Transfer(from, to, tokens);
        
        return true;
    }
}

contract MintableToken is BasicToken{
    using SafeMath for uint;

    event Mint(address indexed to,uint tokens);

    function mint(address to, uint tokens) onlyOwner public{
        _balances[to] = _balances[to].add(tokens);
        _totalSupply = _totalSupply.add(tokens);

        emit Mint(to, tokens);
    }
}

contract TestCoin is MintableToken {

    string public constant name = "Shiba Verse";
    string public constant symbol = "SVE";
    uint8 public constant decimals = 18;
    //18 casas decimais assim como o ether
    //significa que a menor parte um Wei
    //é a mesma coisa que 10^(-18) ether 
}

/*
contract BasicToken is Ownable,ERC20 {
    using SafeMath for uint;

    string public constant name = "Test Coin";
    string public constant symbol = "TST";
    uint8 public constant decimals = 18;
    uint internal _totalSupply;//aqui temos apenas a variavel mais o ERC20 necessita de funcao
    mapping(address => uint) _balances;

    event Mint(address indexed to, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    function mint(address to, uint tokens) onlyOwner public {
        _balances[to] = _balances[to].add(tokens);
        totalSupply = totalSupply.add(tokens);

        emit Mint(to, tokens);
    }

    function totalSupply() public view returns (uint){
        return _totalSupply;
    }

    function transfer(address to, uint tokens) public {
        require(_balances[msg.sender] >= tokens);
        require(to != address(0));

        _balances[msg.sender] = _balances[msg.sender].sub(tokens);
        _balances[to] = _balances[to].add(tokens);

        emit Transfer(msg.sender, to, tokens);
    }
}

*/