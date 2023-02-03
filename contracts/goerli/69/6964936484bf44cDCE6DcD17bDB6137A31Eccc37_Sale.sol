/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier:MIT
pragma solidity >=0.7.0 <0.9.0;

// deployed at= 0xe917F0E31E4948a83840400b4da8AF81137432d6

interface myTokenI
{
    function balanceOf(address _address) external view returns(uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function decimals() external view returns (uint8);
    // Agregados extra
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

abstract contract TokenSale
{ 
    // variables
    address public owner;
    uint256 public price;
    myTokenI myTokenContract;

    //constructor
    constructor(address _AddrContract)
    {
        owner=msg.sender;
        price=1 gwei;
        myTokenContract=myTokenI(_AddrContract);
    }

    //modificadores

    modifier only_owner() virtual ;

    //funciones a implementar
    function buy(uint256 _numTokens) public virtual payable;// poder comprar tokens
    function sell(uint256 _numTokens) public virtual;// poder vender tokens
    function endSold() public virtual ;// poder finalizar la venta recibiendo el owner saldo y tokens sobrantes
    // corregimos funcion changeOwner para poder recibir un address para cambiar el owner
    function changeOwner(address _addr) public virtual ;// agregar evento para marcar este cambio
    // agregar una función para cambiar el address del token

    // eventos a emitir
    event Sold(address buyer, uint256 amount);    
}

contract Sale is TokenSale
{ 

    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if(a==0)
        {
            return 0;
        }
        uint256 c=a*b;
        require((c/a)==b);
        return(c);
    }

    constructor(address _AddrContract) TokenSale(_AddrContract){}

    modifier only_owner() override {
        require(msg.sender==owner,"no eres el owner");
        _;
    }

    // pago ethers y me dan tokens
    function buy(uint256 _numTokens) public override payable {
        require(msg.value==mul(_numTokens,price));
        uint256 scaledAmount=mul(_numTokens,uint256(10)**myTokenContract.decimals());
        require( myTokenContract.balanceOf(address(this)) >=scaledAmount );
        require( myTokenContract.transfer(msg.sender, scaledAmount) );
        emit Sold(msg.sender,_numTokens);
    }

    // me saca tokens y me dan ethers (acuerdense que antes de esto deben aprobar el envío del token con spendeer a este contrato)
    function sell(uint256 _numTokens) public override {
        uint256 valorEthers;
        uint256 valorTokens;

        valorEthers = mul(_numTokens,price) / 10;
        valorEthers = mul(valorEthers,8);
        valorTokens = mul(_numTokens,uint256(10)**myTokenContract.decimals());

        require( address(this).balance >= valorEthers , "No tenemos los ethers suficiente para darle");
        require(myTokenContract.balanceOf(msg.sender)>= valorTokens, "usted no tiene los tokens necesarios");

        require(myTokenContract.transferFrom(msg.sender, address(this), valorTokens) , "no pudimos transferirnos los tokens. haga el approve y vuelva a intentarlo");
        payable(msg.sender).transfer(valorEthers);

        emit bought(msg.sender,_numTokens, block.timestamp);
    }

    function endSold() public only_owner override {
        payable(msg.sender).transfer(address(this).balance);
        myTokenContract.transfer( owner, myTokenContract.balanceOf(address(this)) );
    }

    function changeOwner(address _addr) public override only_owner {
        owner=_addr;
    }

    // Funcion agregada
    function changeMyTokenContract(address _AddrContract) public only_owner virtual {
        myTokenContract=myTokenI(_AddrContract);
    }

    function changePrice(uint256 _price) public only_owner virtual {
        price = _price;
    }

    // evento agregado para poder generar log de las compras y no solo las ventas
    // le agregé el indexed para facilitar busquedas y el timestamp para usar block.timestamp
    event bought(address indexed seller, uint256 amount, uint256 timestamp);
}