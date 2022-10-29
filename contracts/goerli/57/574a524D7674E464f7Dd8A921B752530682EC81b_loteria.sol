// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract loteria {
    // instancia token
    ERC20Basic private token;

    // Direcciones
    // Direccion del owner de este smart contract
    // Tiene los tokens
    address public owner;
    // Direccion del smart contract que es quien va a instanciar el token y quien va a recibir los tokens
    // Tiene los eth
    address public contrato;
    // Tokens iniciales
    uint256 public token_iniciales = 10000;

    constructor() public {
        // Instancia del contrato de los tokens
        token = new ERC20Basic(token_iniciales);
        // Owner de este contrato
        owner = msg.sender;
        // Direccion de este contrato, quien es el owner / msg.sender del contrato de tokens
        contrato = address(this);
    }

    event ComprandoTokens(address, uint256);

    // ---------- TOKEN ---------- //
    // Establecer el precio de los tokens en ethers
    function PrecioToken(uint256 _precioToken) internal pure returns (uint256) {
        return _precioToken * (1 ether);
    }

    function CrearNuevosTokens(uint256 _newTokens) public isAdmin(msg.sender) {
        token.increaseTotalSuply(_newTokens);
    }

    function TokenTotalSupply() public view returns (uint256) {
        return token.totalSupply();
    }

    modifier isAdmin(address sender) {
        require(sender == owner, "User not authorized");
        _;
    }

    function ComprarTokens(uint256 _tokensAcomprar) public payable {
        // Valido que haya disponible la cantidad de tokens a comprar
        require(
            _tokensAcomprar <= ContractTokenBalance(),
            "No hay disponibles esa cantidad de tokens"
        );

        // Valido que el valor en ether equivalente a la cantidad de tokens a comprar
        // sea menor o igual que la cantidad de ethers enviados
        uint256 valorEnEthers = PrecioToken(_tokensAcomprar);
        require(msg.value >= valorEnEthers, "Saldo en ethers insuficiente");

        // Devolver la diferencia de ethers enviados
        msg.sender.transfer(msg.value - valorEnEthers);

        // Usar transfer porque el origen es la direccion de este contrato
        // que del lado del contrato token el msg.sender es este contrato
        token.transfer(msg.sender, _tokensAcomprar);

        emit ComprandoTokens(msg.sender, _tokensAcomprar);
    }

    // Ver el balance de tokens del contrato
    function ContractTokenBalance() public view returns (uint256) {
        return token.balanceOf(contrato);
    }

    // Ver el balance de tokens del usuario
    function UserTokenBalance() public view returns (uint256) {
        return token.balanceOf(msg.sender);
    }

    function Pozo() public view returns (uint256) {
        return token.balanceOf(owner);
    }

    // --------- LOTERIA --------- //
    // Precio boleto Tokens
    uint256 public PrecioBoleto = 5;

    // Relacion MUCHOS A MUCHOS
    // Relacion entre la persona ya los boletos comprados
    mapping(address => uint256[]) boletosDelaPersona;
    // Relacion inversa que tiene a cada boleto con una dirección
    mapping(uint256 => address[]) personasConElBoleto;

    // Numero aleatorio
    uint256 randNonce = 0;
    // Boletos generados al momento.
    uint256[] boletos_comprados;
    // Eventos
    event boleto_comprado(uint256, address); // Cuando se compra un nuevo boleto
    event boleto_ganador(uint256); // Cuando gana un boleto

    // Funcion para comprar boletos de loteria
    function ComprarBoleto(uint256 _boletos) public {
        // Precio de los boletos
        uint256 tokenTotales = _boletos * PrecioBoleto;
        // Validar que el usuario tenga los tokens necesarios para comprar los boletos
        require(tokenTotales <= UserTokenBalance(), "Tokens insuficientes");

        // Se usa transfer_loteria porque transfer del contracto ERC20 usa el msg.sender, la cual del lado del ERC20 es este contrato
        // Lo que nosotros queremos hacer es sacarle los tokens al cliente y depositarlos en el owner
        // De usar transfer lo que hariamos es sacar los tokens de este contrato y depositarlos al owner QUE ES QUIEN TIENE EL POZO
        token.transferencia_loteria(msg.sender, owner, tokenTotales);

        for (uint256 i = 0; i < _boletos; i++) {
            uint256 numeroBoleto = uint256(
                keccak256(abi.encodePacked(now, msg.sender, randNonce))
            ) % 10000; // % (funcion modulo) %10000 nos da los ultimos 4 digitos que van de 0 a 9999. Por lo tanto tenemos 10mil boletos
            randNonce++;

            // Almacenar los datos de los boletos
            boletosDelaPersona[msg.sender].push(numeroBoleto);
            personasConElBoleto[numeroBoleto].push(msg.sender);
            emit boleto_comprado(numeroBoleto, msg.sender);
        }
    }

    // Funcion que le permite al usuario ver sus boletos
    function BoletosComprados() public view returns (uint256[] memory) {
        return boletosDelaPersona[msg.sender];
    }

    function GenerarGanador() public isAdmin(msg.sender) {
        // Validar que haya boletos comprados
        uint256 cantidadBoletos = boletos_comprados.length;
        require(cantidadBoletos > 0, "No hay boletos comprados");

        // Elegir aleatoreamente entre 0 y la longitud
        uint256 posicionGanador = uint256(
            uint256(keccak256(abi.encodePacked(now))) % cantidadBoletos
        );
        // Seleccion del numero aleatorio mediante la posicion del array aleatoria
        uint256 boletoGanador = boletos_comprados[posicionGanador];
        emit boleto_ganador(boletoGanador);

        // Como puede haber mas de una persona que haya comprado el mismo boleto hay que iterar entre los ganadores
        address[] memory ganadores = personasConElBoleto[boletoGanador];
        uint256 pozoRepartido = Pozo() / ganadores.length;
        for (uint256 i = 0; i < ganadores.length; i++) {
            token.transferencia_loteria(owner, ganadores[i], pozoRepartido);
        }
    }

    function DevolverTokensNoUsados(uint256 _numTokens) public payable {
        require(_numTokens >= 0, "Cantidad minima de tokens a devolver es 0");
        require(
            UserTokenBalance() >= _numTokens,
            "No tiene esa cantidad de token disponibles"
        );

        // El sender devuelve los tokens al owner
        token.transferencia_loteria(msg.sender, owner, _numTokens);

        // Devolver la diferencia de ethers enviados
        msg.sender.transfer(PrecioToken(_numTokens));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./SafeMath.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferencia_loteria(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20Basic is IERC20 {
    string public constant name = "ERC20Basic";
    string public constant symbol = "JBJ-TOKEN";
    uint8 public constant decimals = 2;

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 totalSupply_;

    using SafeMath for uint256;

    constructor(uint256 total) public {
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public view override returns (uint256) {
        return totalSupply_;
    }

    function increaseTotalSuply(uint256 newTokens) public {
        totalSupply_ += newTokens;
        balances[msg.sender] += newTokens;
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256)
    {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens)
        public
        override
        returns (bool)
    {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function transferencia_loteria(
        address sender,
        address receiver,
        uint256 numTokens
    ) public override returns (bool) {
        require(numTokens <= balances[sender]);
        balances[sender] = balances[sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens)
        public
        override
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        override
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;


// Implementacion de la libreria SafeMath para realizar las operaciones de manera segura
// Fuente: "https://gist.github.com/giladHaimov/8e81dbde10c9aeff69a1d683ed6870be"

library SafeMath{
    // Restas
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    // Sumas
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    
    // Multiplicacion
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
}