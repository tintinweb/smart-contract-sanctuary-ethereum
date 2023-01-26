/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// File: SellingToken.sol



pragma solidity 0.8.17;

contract ERC20Selling{
    string public name = "ERC20";
    string public symbol = "ERC";
    uint256 public totalSupply = 1000000000000000000000000000; //1 billion tokens ;
    uint8 public decimals = 18;
    address public Owner;

    event moved(
        address from,address to, uint value
    );
    event approval(
        address from,address to,uint value
    );

    mapping(address=>uint256) public balanceOf;
    mapping(address =>mapping(address=>uint256)) public allowance;



    constructor(){
        Owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        

    }
   function getDecimals() public view returns(uint){
        return decimals;
    }

    function transfer(address _to, uint _value) public returns(bool success) {

        require(balanceOf[msg.sender] >= _value,"Insufficuent Token");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit moved(msg.sender,_to,_value);
        return true;
    }

    function approve(address _spender, uint _value) public {
        require(balanceOf[msg.sender] >= _value,"Insufficient balance");
        allowance[msg.sender][_spender] = _value;
        emit approval(msg.sender,_spender,_value);
    }
    
    function transferFrom(address _owner ,address _anotherOwner, uint _value) public returns(bool success){
            require(_value <= balanceOf[_owner],"Insufficent Amount");
            require(_value <= allowance[_owner][msg.sender],"Insufficent Allowance");

            balanceOf[_owner] -= _value;
            balanceOf[_anotherOwner] += _value;
            allowance[_owner][msg.sender] -= _value;

            emit moved(_owner,_anotherOwner,_value);
            return true;

     
    }



}
// File: BuyingToken.sol



pragma solidity 0.8.17;

contract MetaBuying{
    string public name = "MetaCubes";
    string public symbol = "Meta";
    uint256 public totalSupply = 1000000000000000000; //1 billion tokens ;
    uint8 public decimals = 9;
    address public Owner;

    event moved(
        address from,address to, uint value
    );
    event approval(
        address from,address to,uint value
    );

    mapping(address=>uint256) public balanceOf;
    mapping(address =>mapping(address=>uint256)) public allowance;



    constructor(){
        Owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        

    }
    function getDecimals() public view returns(uint){
        return decimals;
    }

    function transfer(address _to, uint _value) public returns(bool success) {

        require(balanceOf[msg.sender] >= _value,"Insufficuent Token");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit moved(msg.sender,_to,_value);
        return true;
    }

    function approve(address _spender, uint _value) public {
        require(balanceOf[msg.sender] >= _value,"Insufficient balance");
        allowance[msg.sender][_spender] = _value;
        emit approval(msg.sender,_spender,_value);
    }
    
    function transferFrom(address _owner ,address _anotherOwner, uint _value) public returns(bool success){
            require(_value <= balanceOf[_owner],"Insufficent Amount");
            require(_value <= allowance[_owner][msg.sender],"Insufficent Allowance");

            balanceOf[_owner] -= _value;
            balanceOf[_anotherOwner] += _value;
            allowance[_owner][msg.sender] -= _value;

            emit moved(_owner,_anotherOwner,_value);
            return true;

     
    }



}
// File: TokensSale.sol



pragma solidity 0.8.17;



contract TokenToTokenSale{
    address admin;
    ERC20Selling public Erc20Sell;
    MetaBuying public MetaBuy;
    
    constructor(ERC20Selling _Erc20Sell,MetaBuying _MetaBuy) {
        admin = msg.sender;
        Erc20Sell = _Erc20Sell;
        MetaBuy = _MetaBuy;
    }

    function buyToken(uint _tokenAmount) public payable{
        require(_tokenAmount > 0,"Invalid Input");
        uint setTokenDecimal = _tokenAmount * 10 ** Erc20Sell.getDecimals();
        uint tokenWorth =   10 ** MetaBuy.getDecimals() * 10 ** Erc20Sell.getDecimals();
        uint tokensToTransfer = setTokenDecimal / tokenWorth * 10;
        MetaBuy.transferFrom(msg.sender,address(this),_tokenAmount);

        Erc20Sell.transfer(msg.sender,tokensToTransfer);
        

    }
    

}