/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

contract CuentaAhorro{

    address private owner;
    string private name;
    int256 saldo;

    constructor(string memory ahorrador) {
        //console.log("Owner contract deployed by:", msg.sender);
        owner = msg.sender; 
        name = ahorrador;
        saldo = 0;
    }

    function Ahorrar( int256 monto ) public{
        saldo += monto;
    } 
    function VerSaldo() public view returns (int256){
        return saldo;
    }
    function Retirar( int256 monto) public{
         saldo = saldo - monto;
    }
    
    modifier validaRetiro(int256 monto) {
        require (monto > saldo, "Saldo insuficiente");
        _;
    }

}