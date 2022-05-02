// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IVIP.sol";
contract Latin_Eventos  {

    event evento_creado(uint indexed e_id, bytes12 indexed Codigo_Latin, address indexed autor,uint porcentaje,uint32 Inicio,uint32 Fin,address Verificador);
    event aporte(uint indexed e_id, bytes12 indexed Codigo_Latin, address indexed participante, uint256 monto,uint a_id);
    event devolucion(uint indexed e_id,bytes12 indexed Codigo_Latin, address indexed participante, uint256 monto);
    event ganador_loteria(uint e_id,bytes12 indexed Codigo_Latin , address indexed participante, uint256 monto ,  uint256 randomnumber);
    event cierre_evento(uint indexed e_id, bytes12 indexed Codigo_Latin ,address indexed autor, address op, uint256 recaudado );
    event evento_cancelado(uint e_id, bytes12 indexed Codigo_Latin , address indexed Operador, string motivo);
    event estado_creacion_eventos(bool Contrato_Activo);
    event extraccion(address indexed usuario, uint256 monto);


    struct Evento {
        address autor;// Autor del Evento
        address verificador;// Responsable aprobación Evento
        uint p_autor;// Porcentaje (0 a 90 %) que toma el autor. La diferencia a 90% queda para Lotería.
        uint256 recaudado; // Monto recaudado del evento
        uint32 inicio;// Timestamp echo unix Inicio Evento (Vigencia)
        uint32 fin;// Timestamp echo unix Fin Evento (Vigencia)
        bool cancelado;// Verdadero en caso de reportes, habilita la devolución.
        bool finalizado;// Marca de Fvento Finalizado y Proceso de distribución realizado
        bytes12 codigo_latin; // Codigo LatinSER auntenticador
    }

    IERC20 public immutable LatinSER;
    VIP public LatinVIP;
    
    
        // Permite pausar la generación de eventos en casos de
        // mejoras y creación de un nuevo contrato de eventos.
        // No afecta retiros.
        bool public Contrato_Activo=true;

       
        // Almacena la cantidad total de eventos.
        // Sirve como indice de los eventos. ID
        uint public e_id;

        //Roles en la plataforma
        mapping(address => bool)  Owner;
        mapping(address => bool)  Staff;
        mapping(address => bool)  Verif;

        //Porcentajes fijos de la plataforma
        //Total 10 %
        uint256 public p_vip= 5; // Distribución para holders VIP
        uint256 public p_verif= 2; // Verificador de eventos y moderador
        uint256 public p_staff= 3; // Porcentaje para desarrollo y marketing


        //Acumuladores históricos para estadísticas
        uint256 public ah_VIP;
        uint256 public ah_autor;
        uint256 public ah_verificador;
        uint256 public ah_loteria;
        uint256 public ah_staff;

        //Balances(saldos) actuales por address
        mapping(address => uint256) public b_VIP;
        mapping(address => uint256) public b_autor;
        mapping(address => uint256) public b_verificador;
        mapping(address => uint256) public b_loteria;

        //Balances(saldos) actuales
        uint256 public b_staff;
        uint256 public ac_VIP;
        
        //Timestamp del ultimo balance holders VIPs LatinSD SmartDeFi
        uint32 public D_VIP_Last;
    
        // Permite consultar Eventos por Id
        mapping(uint => Evento) public eventos;

        // Permite consultar cantidad de aportes por Id de Evento
        mapping(uint=> uint) public id_aporte_e;

        // Permiten consultar por Id_Evento Id_Aporte el monto del aporte y el address
        //Cada address puede aportar mas de una vez en un evento
        mapping(uint =>  mapping(uint => uint256)) public id_monto_e;//Id_Evento.Id_Aporte=>Monto
        mapping(uint =>  mapping(uint => address)) public id_monto_a;//Id_Evento.Id_Aporte=>Address
        mapping(uint =>  mapping(address => uint256)) public montoAportado;//Id_Evento.Address=>Monto
        mapping(uint =>  mapping(address => uint)) public c_aportes;//Id_Evento.Address=>Cantidad_Aportes
        mapping(uint =>  mapping(uint => mapping(address => uint256))) public id_montoAportado;//Id_Evento.Id_Aporte.Address=>Id_montoaportado en caso de varios aportes al mismo evento


        constructor(address _token_SER, address _Latin_VIP) {
        LatinSER =IERC20(_token_SER);
        LatinVIP =VIP(_Latin_VIP);
        Owner[msg.sender] =true;

        }

        // Delegación de Roles
    function set_rol(bool  _tm, address  _addr, uint  _rol) external {
    require((_rol >= 1 && _rol <=3 && Owner[msg.sender] ) || (_rol ==3 && Staff[msg.sender]),"No autorizado");

            if (_rol == 1) Owner[_addr] = _tm;
            if (_rol == 2) Staff[_addr] = _tm;
            if (_rol == 3) Verif[_addr] = _tm;
        }

    //Permite pausar la creación de eventos en caso de Migración de contratos para mejoras
    //No afecta retiros o eventos en curso
    function pausa_creacion_eventos(bool  _p_eventos) external 
        {
    
        require(Owner[msg.sender],"No autorizado");
        Contrato_Activo=_p_eventos;
        emit estado_creacion_eventos(Contrato_Activo);
        }

    // Permite la distribución de los dividendos acumulados
    // para los Holders VIP Latin SmartDefi

    function Distribuir_VIP() external 
    {
    uint32 lb=LatinVIP.get_blck_bsc_ts();
    require(D_VIP_Last < lb, "Nuevo Balance no disponible" ) ;       
    require(Staff[msg.sender],"no autorizado"); 
    D_VIP_Last=lb;
    uint256 vipshare;
    uint256 ac_VIP_a_Dist=ac_VIP;
    uint256 hb;
    uint256 supply=20000000;
    
    for (uint32 i = 0; i < LatinVIP.get_n_holders(); i++) {
        hb=LatinVIP.get_bal(LatinVIP.get_holder(i));
        if (hb > 0) 
        { 
            vipshare = (ac_VIP_a_Dist *  (hb * 100/ supply)) / 100;
            ac_VIP-=vipshare;
            b_VIP[LatinVIP.get_holder(i)]+=vipshare;

        }
    
    }}

    //Creación de Eventos deade la plataforma
    function crea_evento(
        address     _verif,
        uint        _p_autor,
        uint32      _inicio,
        uint32      _fin,
        bytes12     _codigo_latin
    ) external {
        require(Contrato_Activo,"Creacion de eventos pausado por Mantenimiento");
        require( Verif[_verif] ,"verificador no autorizado" );
        require(_p_autor>=0 && _p_autor<=90,"porcentaje autor fuera de rango");
        require(_inicio >= block.timestamp, "start at < now");
        require(_fin >= _inicio, "end at < start at");
        require(_fin <= block.timestamp + 30 days, "end at > max duration");

        e_id += 1;
        eventos[e_id] = Evento({
            autor: msg.sender,
            verificador: _verif,
            p_autor: _p_autor,
            recaudado: 0,
            inicio: _inicio,
            fin: _fin,
            cancelado: false, // Detiene la recaudación del evento y habilita devolucion a los aportantes del evento
            finalizado:false, // Detiene la recaudación del evento
            codigo_latin:_codigo_latin //2FA asegura que se crea el evento desde la plataforma
        });
//evento_creado(uint indexed e_id, bytes12 indexed Codigo_Latin, address indexed autor,uint porcentaje,uint32 Inicio,uint32 Fin,address Verificador);
        emit evento_creado(e_id, _codigo_latin, msg.sender,_p_autor, _inicio, _fin,_verif);
    }

      //Proceso que acumula aportes
    function aportar(uint  _id, uint256  _monto) external {
        require(_id <= e_id && _id > 0, "Id evento Inexistente");
        require(LatinSER.balanceOf(msg.sender)>= _monto,"Saldo LatinSER Insuficiente");
        Evento storage evento = eventos[_id];
        require(block.timestamp >= evento.inicio, "No iniciado");
        require(block.timestamp <= evento.fin, "No Vigente");
        require(!evento.cancelado,"Evento Cancelado");
        require(!evento.finalizado,"Evento Finalizado");

        evento.recaudado += _monto;
        id_aporte_e[_id] +=1;
        montoAportado[_id][msg.sender] += _monto;
        id_montoAportado[_id][id_aporte_e[_id]][msg.sender] += _monto;
        c_aportes[_id][msg.sender] +=1;
       
        id_monto_e[_id][id_aporte_e[_id]] =_monto;
        id_monto_a[_id][id_aporte_e[_id]] =msg.sender;
        
        LatinSER.transferFrom(msg.sender, address(this), _monto);
 
        emit aporte(_id,evento.codigo_latin , msg.sender, _monto , id_aporte_e[_id]);
    }

    //Proceso que libera los fondos para devolución  
    function cancelar_e(uint  _id, string memory motivo) external {
        require(_id <= e_id && _id > 0, "Id evento Inexistente");
        Evento storage evento = eventos[_id];
        require(evento.autor == msg.sender || Staff[msg.sender] || Verif[msg.sender], "no autorizado");
        require(!evento.finalizado, "Finalizado");
        require(!evento.cancelado, "Cancelated");
        evento.cancelado = true;
  
        emit evento_cancelado(_id, evento.codigo_latin, msg.sender, motivo);
       }
       
    // Proceso que distribuye los fondos y cierra el evento
    // Permite Distribución de la recaudación luego de 48 hs de inicado el evento,
    // por medidas de seguridad para mitigar posibles fraudes detectados/reportados por la comunidad
  
    function Cierre_e(uint  _id) external {
        require(_id > 0 && _id <= e_id, "Id evento Inexistente");
        Evento storage evento = eventos[_id];
        require(evento.autor == msg.sender || Staff[msg.sender] || Verif[msg.sender], "no autorizado");
        require(block.timestamp > evento.inicio + 15 minutes, "Security Period"); //-------*******----------------------------------*********---- cambiar a "2 days" en Produccion !!!!
        require(!evento.cancelado, "Cancelated");
        require(!evento.finalizado, "Finalizado");

        evento.finalizado = true; // evita reentradas

    //calcular loteria si el autor utilizó la opción.
        uint256 lot = evento.recaudado * (90 - evento.p_autor) / 100 ;
        if (lot > 0) 
                {
                    bytes32 bHash = blockhash(block.number - 1);
                    uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, bHash, _id))) % (evento.recaudado + 1);
                    ah_loteria += lot;
                    uint c_a = id_aporte_e[_id];
                    uint256 tickets ; 
                    address g_loteria;

                    for (uint a= 1; a<= c_a ; a++  )
                    {
                    tickets += id_monto_e[_id][a];
                    if (tickets >= randomNumber) 
                        {   g_loteria=id_monto_a[_id][a];
                            b_loteria[g_loteria]=lot ;
                            a=c_a+1;}

                    }

                    require(g_loteria != address(0),"Error Loteria");
                    
                    emit ganador_loteria(_id, evento.codigo_latin , g_loteria , lot , randomNumber);
                }
            
        uint256 autor= evento.recaudado * evento.p_autor / 100;
        ah_autor += autor;
        b_autor[evento.autor] += autor;

        uint256 verif = evento.recaudado * p_verif / 100;
        ah_verificador += verif;
        b_verificador[evento.verificador] += verif;
        
        uint256 vip = evento.recaudado * p_vip / 100; 
        ah_VIP += vip;
        ac_VIP += vip;

        uint256 staff = evento.recaudado - (lot + autor + verif + vip );
        ah_staff += staff;
        b_staff += staff;

     emit cierre_evento(_id, evento.codigo_latin,evento.autor, msg.sender, evento.recaudado);
       }

    //Proceso devolución aporte al evento
    function g_devolucion(uint  _id) external {
        require(_id>0 && _id <= e_id, "Id evento Inexistente");
        Evento storage evento = eventos[_id];
        require(!evento.finalizado, "evento finalizado");
        require(montoAportado[_id][msg.sender] > 0 , "Sin Aportes al Evento");
        
        uint256 _monto = montoAportado[_id][msg.sender];
        montoAportado[_id][msg.sender] -= _monto;
        evento.recaudado -= _monto;

        for(uint a=1 ;a <= id_aporte_e[_id];a++)
        {
            if (id_monto_a[_id][a] == msg.sender) id_monto_e[_id][a] =0;
        }
        LatinSER.transfer(msg.sender, _monto);

        emit devolucion(_id, evento.codigo_latin, msg.sender, _monto);
    }

    //Proceso informa saldo total
   function s_LatinSER(address  _addr) view public returns(uint256 _saldo) {
        uint256  saldo = b_autor[_addr] + b_loteria[_addr] + b_verificador[_addr] + b_VIP[_addr];
        if (Staff[_addr] && b_staff >0) 
        { saldo += b_staff;
           }
        return saldo;
    }
    
    //Proceso permite retiro monto acumulado del address
    function retiro() external {
        uint256  saldo = b_autor[msg.sender] + b_loteria[msg.sender] + b_verificador[msg.sender] + b_VIP[msg.sender];
        if (Staff[msg.sender] && b_staff >0) 
        { saldo += b_staff;
            b_staff=0;}
        require( saldo > 0 , "Saldo insuficiente");
        
        b_autor[msg.sender] = 0 ;
        b_loteria[msg.sender]= 0;
        b_verificador[msg.sender]= 0;
        b_VIP[msg.sender]= 0;

        LatinSER.transfer(msg.sender, saldo);

        emit extraccion( msg.sender, saldo);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12 <0.9.0;

interface VIP  {

function get_bal(address account) external view returns (uint256);
function get_blck_bsc() external view returns (uint32);
function get_blck_bsc_ts() external view returns (uint32);
function get_holder(uint32 n) external view returns (address);
function get_n_holders() external view returns (uint256);

}