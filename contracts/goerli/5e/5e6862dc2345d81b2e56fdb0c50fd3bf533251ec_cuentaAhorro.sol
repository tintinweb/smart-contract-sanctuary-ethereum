/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

contract cuentaAhorro{

    //Struct
    struct Cuenta{
        int numero;
        int saldo;
        string nombre;
    }

    //forma 1
    Cuenta public c1 = Cuenta(12345, 0, "Camilo Camargo");
    
  
    //validar ingreso
     modifier validaIngreso(int money){
        require (money < 10000, "No puedes ingresar mas de 10000");
        _;
    }

    
    //ingresar saldo
     function setSaldo(int p1) public validaIngreso(p1){
       c1.saldo = c1.saldo + p1;
    }

    //validar ingreso
     modifier validaRetiro(int money){
        require (money > 0, "Debes retirar algo mayor que 0");
        _;
    }

    //retirar saldo
     function getSaldo(int p1) public validaRetiro(p1){
       c1.saldo = c1.saldo - p1;
    }
    

}