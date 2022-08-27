/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

pragma solidity ^0.4.25;

interface tokenRecipient 
{ 
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}
//contrato para definir quien es el administrador central del token
contract owned 
{    
  	address public owner;

    constructor() public    
    {        
    	owner = msg.sender;

    }    
    modifier onlyOwner     
    {        
    	require(msg.sender == owner);
        _;

    }

    function transferOwnership(address newOwner) onlyOwner public     
    {        
    	owner = newOwner;

    }
}

contract TokenPrueba1 is owned
{    
    //Variables publicas del token    
   	string public name;

    string public symbol;

    //18 decimales es el parametro por defecto, evitar cambiarlo    
    uint256 public decimals = 8;

    //cantidad total de la moneda
    uint256 public totalSupply;

    //Crea un arreglo para llevar los balances de las cuentas    
    mapping (address => uint256) public balanceOf;

    //Arreglo que guarda la "toleracia" de las cuentas con otras, cuanto pueden "tomar" estas    
    mapping (address => mapping (address => uint256)) public allowance;

    //cuentas congeladas    
    mapping (address => bool) public frozenAccount;

    // Crea un evento en la blockchain que notifica a los clientes de la transferencia    
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Crea un evento en la blockchain que notifica a los clientes de la aprobación    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // Notifica a los clientes de la cantidad quemada    
    event Burn(uint256 value);

    // Crea un evento que notifica sobre las cuentas congeladas    
    event FrozenFunds(address target, bool frozen);

    /**
    * Funcion constructora     
    * Le da todos los tokens al creador del contrato      
    *     
    *@param initialSupply La cantidad inicial del token     
    *@param tokenName El nombre del token     
    *@param tokenSymbol El símbolo a usar por parte del token     
    *@param centralMinter La direccion del creador     
    **/    
    constructor(uint256 initialSupply,string tokenName,string tokenSymbol, address centralMinter) public     
    {        
    	//Le damos valor al totalSupply y le damos decimales        
    	totalSupply = initialSupply * 10 ** uint256(decimals);

        //al sender del contrato, le damos todos los tokens al principio        
        balanceOf[msg.sender] = totalSupply;

        //nombre del token        
        name = tokenName;

        //simbolo del token        
        symbol = tokenSymbol;

        //administrador de la moneda que puede cambiar la cantidad disponible (minter)       
        if(centralMinter != 0 ) owner = centralMinter;

    }        
    /**     
    *Funcion para cambiar el numero de tokens disponibles, solo el owner puede cambiarlos     
    *     
    *@param target direccion a la que se le cambiará el número de tokens     
    *@param mintedAmount cantidad que se desea añadir     
    **/    
    function mintToken(address target, uint256 mintedAmount) onlyOwner public    
    {        
    	balanceOf[target] += mintedAmount;

        totalSupply += mintedAmount;

        emit Transfer(0, owner, mintedAmount);

        emit Transfer(owner, target, mintedAmount);

    }     
    /**     
    * Destruye tokens (quema dinero), solo el propietario puede     
    *     
    * Remueve la cantidad de tokens en '_value' del sistema de forma irreversible     
    *     
    * @param _value La cantidad de dinero a quemar     
    */    
    function burn(uint256 _value) onlyOwner public returns (bool success)    
    {        
    // Actualiza el totalSupply        
    	totalSupply -= _value;

        emit Burn(_value);

        return true;

    }    
    /**    
    *Congela una cuenta    
    *    
    *@param target direccion de la cuenta que se desea congelar    
    *@param freeze booleano que decide si se desea congelar la cuenta (true) o descongelar (false)    
    **/    
    function freezeAccount(address target, bool freeze) onlyOwner public    
    {        
    	frozenAccount[target] = freeze;

        emit FrozenFunds(target, freeze);

    }    
    /**     
    * Transferencia interna, solo puede ser llamada por este contrato     
    *      
    *@param _from direccion de la cuenta desde donde se envian los tokens     
    *@param _to direccion de la cuenta a la que van los tokens     
    *@param _value Número de tokens a enviar     
    */    
    function _transfer(address _from, address _to, uint _value) internal {        
    // Previene la transferencia a una cuenta 0x0. Para destruir tokens es mejor usar burn()        
    	require(_to != 0x0);

        // Verificamos si el que envia tiene suficiente diner        
        require(balanceOf[_from] >= _value);

        // Verificamos si existe o no un overflow        
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        // Guardamos esta asercion en el futuro        
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        // Le quitamos tokens al que envia        
        balanceOf[_from] -= _value;

        // Le añadimos esa cantidad al que envia        
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);

        // asercion para encontrar bugs        
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

    }    
    /**     
    * Transferir tokens     
    *     
    * Envia '_value' de tokens a '_to' desde tu cuenta     
    *     
    * @param _to La dirección del receptor     
    * @param _value La cantidad a enviar     
    */    
    function transfer(address _to, uint256 _value) public returns (bool success)    
    {        
    	require(!frozenAccount[msg.sender]);

        _transfer(msg.sender, _to, _value);

        return true;

    }    
    /**     
    * Transferir tokens desde otra dirección     
    *     
    * Enviar la cantidad de tokens '_value' hacia la cuenta '_to' desde la cuenta '_from'     
    * Esta es una función que podria usarse para operaciones de caja     
    *     
    * @param _from la dirección de quien envia     
    * @param _to La dirección del receptor     
    * @param _value La cantidad de tokens a enviar     
    */    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)    {        
    	require(_value <= allowance[_from][msg.sender]);

     // Check allowance        
    	allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;

    }    
    /**     
    * Coloca la toleracia para otras direcciones     
    *     
    * Permite que el '_spender' no gaste mas que la cantidad de '_value' de tokens por parte tuya     
    *     
    * @param _spender La dirección a la que se autoriza gastar     
    * @param _value La cantidad máxima que pueden gastar     
    */    
    function approve(address _spender, uint256 _value) public returns (bool success)    {        
    	allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;

    }    
    /**     
    * Para funcionar con otros contratos     
    * En prueba     
    *     
    * Coloca la toleracia para otras direcciones y notificar     
    *     
    * Permite al '_spender' a gastar no mas de la cantidad de tokens de '_value' de tu cuenta y luego notificar al contrato     
    *     * @param _spender La dirección autorizada a gastar     * @param _value La cantidad máxima que pueden gastar     
    * @param _extraData Informacion extra a enviar al contrato     
    */    
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success)    {        
    	tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value))        
        {            
        	spender.receiveApproval(msg.sender, _value, this, _extraData);

            return true;

        }    
    }
}