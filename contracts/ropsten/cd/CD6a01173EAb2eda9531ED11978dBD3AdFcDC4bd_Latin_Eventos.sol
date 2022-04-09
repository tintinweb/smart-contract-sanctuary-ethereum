// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IVIP.sol";
contract Latin_Eventos  {

    event evento_creado(uint e_id,address indexed autor,uint32 Inicio,uint32 Fin);
    event aporte(uint indexed e_id,uint indexed a_id, address indexed participante, uint256 monto);
    event devolucion(uint indexed e_id, address indexed participante, uint256 monto);
    event ganador_loteria(uint e_id,  uint256 randomnumber , address indexed participante, uint256 monto);
    event extraccion(address indexed usuario, uint256 monto);
    event evento_cancelado(uint e_id, address op, string motivo);
    event evento_eliminado(uint e_id);
    event estado_creacion_eventos(bool e_creacion_eventos);
    event evento_finalizado(uint indexed e_id, address indexed autor, uint256 recaudado);


    struct Evento {
        // autor of Evento
        address autor;
        // autor of Evento
        address verificador;
        // autor of Evento
        uint p_autor;
        // Total monto aporte
        uint256 recaudado;
        // Timestamp of start of Evento
        uint32 inicio;
        // Timestamp of end of Evento
        uint32 fin;
        // Verdadero en caso de reportes, habilita la devolución
        bool cancelado;
        // Codigo LatinSER auntenticador
        bool finalizado;
        // Codigo LatinSER auntenticador
        string codigo_latin;
    }

    IERC20 public immutable LatinSER;
    VIP public LatinVIP;
    
    
        // permite pausar la generación de eventos en casos de
        // mejoras y creación de un nuevo contrato de eventos.
        bool public e_create_eventos=true;

       
        // Total count of Eventos created.
        // It is also used to generate e_id for new Eventos.
        uint public e_id;

        mapping(address => bool)  Owner;
        mapping(address => bool)  Staff;
        mapping(address => bool)  Verif;

        uint256 public p_vip=5; // % VIP

        uint256 public ah_VIP;
        uint256 public as_VIP;
        mapping(address => uint256) public b_VIP;

        
        
        uint32 public D_VIP_Last;
    
        uint256 public ah_autor;
        mapping(address => uint256) public b_autor;
    
        uint256 public ah_verificador;
        mapping(address => uint256) public  b_verificador;
        uint256 public p_verif=2;

        uint256 public ah_loteria;
        mapping(address => uint256) public  b_loteria;

        uint256 public ah_staff;

        uint256 public b_staff;
        uint256 public p_staff=3;

        // Mapping from id to Evento
        mapping(uint => Evento) public eventos;

        mapping(uint=> uint) public id_aporte_e;

        mapping(uint =>  mapping(uint => uint256)) public id_monto_e;
        mapping(uint =>  mapping(uint => address)) public id_monto_a;

        // Mapping from Evento id =>  address
        mapping(uint =>  mapping(address => uint256)) public montoAportado;
        mapping(uint =>  mapping(address => uint)) public c_aportes;
        mapping(uint =>  mapping(uint => mapping(address => uint256))) public id_montoAportado;


        constructor(address _token_SER, address _Latin_VIP) {
        LatinSER =IERC20(_token_SER);
        LatinVIP =VIP(_Latin_VIP);
        Owner[msg.sender] =true;

        }

        // Update the value at this address
    function set_rol(bool  _tm, address  _addr, uint  _rol) external {
   require((_rol >= 1 && _rol <=3 && Owner[msg.sender] ) || (_rol ==3 && Staff[msg.sender]),"No autorizado");

            if (_rol == 1) Owner[_addr] = _tm;
            if (_rol == 2) Staff[_addr] = _tm;
            if (_rol == 3) Verif[_addr] = _tm;
        }

    function pausa_creacion_eventos(bool  _p_eventos) external 
        {
    
        require(Owner[msg.sender],"no autorizado");
        e_create_eventos=_p_eventos;
        emit estado_creacion_eventos(e_create_eventos);
        }

    function D_VIP_semanal() external 
    {
    uint32 lb=LatinVIP.get_blck_bsc_ts();
    require(D_VIP_Last < lb, "Nuevo Balance no disponible" ) ;       
    require(Staff[msg.sender],"no autorizado"); 
    D_VIP_Last=lb;
    uint256 vipshare;
    uint256 as_VIP_a_Dist=as_VIP;
    uint256 hb;
    uint256 supply=20000000;
    
    for (uint32 i = 0; i < LatinVIP.get_n_holders(); i++) {
        hb=LatinVIP.get_bal(LatinVIP.get_holder(i));
        if (hb > 0) 
        { 
            vipshare = (as_VIP_a_Dist *  (hb * 100/ supply)) / 100;
            as_VIP-=vipshare;
            b_VIP[LatinVIP.get_holder(i)]+=vipshare;

        }
    
    }}


    function crea_evento(
        address     _verif,
        uint        _p_autor,
        uint32      _inicio,
        uint32      _fin,
        string calldata _codigo_latin
    ) external {
        require(e_create_eventos,"Creacion de eventos pausado por Mantenimiento");
        require( Verif[_verif] ,"verificador no autorizado" );
        require(_p_autor>=0 && _p_autor<=90,"porcentaje autor fuera de rango");
        require(_inicio >= block.timestamp, "start at < now");
        require(_fin >= _inicio, "end at < start at");
        require(_fin <= block.timestamp + 7 days, "end at > max duration");

        e_id += 1;
        eventos[e_id] = Evento({

            autor: msg.sender,
            verificador: _verif,
            p_autor: _p_autor,
            recaudado: 0,
            inicio: _inicio,
            fin: _fin,
            cancelado: false, // Utilizado por Autor , Owner o Staff - detiene la recaudación del evento
            finalizado:false, // Utilizado por Autor , Owner o Staff - distribuye la recaudación del evento
            codigo_latin:_codigo_latin //2FA asegura que se crea el evento desde la plataforma
        });

        emit evento_creado(e_id, msg.sender, _inicio, _fin);
    }

    function eliminar_e(uint _id) external { // Si el autor lo creó por error
    require(_id <= e_id, "Id evento Inexistente");
        Evento memory evento = eventos[_id];
        require(evento.autor == msg.sender || Staff[msg.sender] || Verif[msg.sender], "no autorizado");
        require(block.timestamp < evento.inicio, "started");

        delete eventos[_id];
        emit evento_eliminado(_id);
    }
      
    function cancelar_e(uint  _id, string memory motivo) external {
        require(_id <= e_id, "Id evento Inexistente");
        Evento storage evento = eventos[_id];
        require(evento.autor == msg.sender || Staff[msg.sender] || Verif[msg.sender], "no autorizado");
        require(block.timestamp >= evento.inicio, "no iniciado - Utilizar Eliminar");
        require(!evento.cancelado, "Cancelated");

        evento.cancelado = true;

        emit evento_cancelado(_id,  msg.sender, motivo);


       }

    function finalizar_e(uint  _id) external {
        require(_id <= e_id, "Id evento Inexistente");
        Evento storage evento = eventos[_id];
        //require(evento.autor == msg.sender || Staff[msg.sender] || Verif[msg.sender], "no autorizado");
        require(block.timestamp > evento.fin, "not ended");
        require(!evento.cancelado, "Cancelated");
        require(!evento.finalizado, "Finalizado");
           
        //calcular loteria
        uint256 lot = evento.recaudado * (90 - evento.p_autor) / 100 ;
        

            if (lot > 0) {
            bytes32 bHash = blockhash(block.number - 1);
            uint256 randomNumber = 
            uint256(keccak256(abi.encodePacked(block.timestamp, bHash, _id))) % (evento.recaudado + 1);
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
            emit ganador_loteria(_id, randomNumber,g_loteria , lot);

            }

        evento.finalizado = true;
            
        uint256 autor= evento.recaudado * evento.p_autor / 100;
        ah_autor += autor;
        b_autor[evento.autor] += autor;

        uint256 verif = evento.recaudado * p_verif / 100;
        ah_verificador += verif;
        b_verificador[evento.verificador] += verif;
        
        uint256 vip = evento.recaudado * p_vip / 100; // agregar función calculo distribucion vip
        ah_VIP += vip;
        as_VIP += vip;

        uint256 staff = evento.recaudado - (lot + autor + verif + vip );// 3 % Staff
        ah_staff += staff;
        b_staff += staff;

  
          emit evento_finalizado(_id,msg.sender,evento.recaudado);
       }

    function aportar(uint  _id, uint256  _monto) external {
        require(_id <= e_id, "Id evento Inexistente");
        require(LatinSER.balanceOf(msg.sender)>= _monto,"Saldo LatinSER Insuficiente");
        Evento storage evento = eventos[_id];
        require(block.timestamp >= evento.inicio, "no iniciado");
        require(block.timestamp <= evento.fin, "finalizado");
        require(!evento.cancelado,"Evento Cancelado");

        evento.recaudado += _monto;
        id_aporte_e[_id] +=1;
        montoAportado[_id][msg.sender] += _monto;
        id_montoAportado[_id][id_aporte_e[_id]][msg.sender] += _monto;
        c_aportes[_id][msg.sender] +=1;
       
        id_monto_e[_id][id_aporte_e[_id]] =_monto;
        id_monto_a[_id][id_aporte_e[_id]] =msg.sender;
        
        LatinSER.transferFrom(msg.sender, address(this), _monto);

        emit aporte(_id, id_aporte_e[_id] , msg.sender, _monto);
    }

    function g_devolucion(uint  _id,  uint256  _monto) external {
        require(_id <= e_id, "Id evento Inexistente");
        Evento storage evento = eventos[_id];
        require(!evento.finalizado, "evento finalizado");
        require(montoAportado[_id][msg.sender] == _monto, "Monto solicitado diferente aportado");

        evento.recaudado -= _monto;
        montoAportado[_id][msg.sender] -= _monto;

        for(uint a=1 ;a <= id_aporte_e[_id];a++)
        {
            if (id_monto_a[_id][a] == msg.sender) id_monto_e[_id][a] =0;
        }
        LatinSER.transfer(msg.sender, _monto);

        emit devolucion(_id, msg.sender, _monto);
    }

   function s_LatinSER() view public returns(uint256 _saldo) {
        uint256  saldo = b_autor[msg.sender] + b_loteria[msg.sender] + b_verificador[msg.sender] + b_VIP[msg.sender];
        return saldo;
    }
    
    function r_staff() external {
        require(b_staff >0, "Saldo Insuficiente");
        require(Staff[msg.sender] , "not autorized");
        uint256 monto = b_staff;
        b_staff = 0;
        LatinSER.transfer(msg.sender, monto);

        emit extraccion( msg.sender, monto);
    }

    function retiro() external {
        uint256  saldo = b_autor[msg.sender] + b_loteria[msg.sender] + b_verificador[msg.sender] + b_VIP[msg.sender];
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
pragma solidity >=0.4.22 <0.9.0;

interface VIP  {

function get_bal(address account) external view returns (uint256);
function get_blck_bsc() external view returns (uint32);
function get_blck_bsc_ts() external view returns (uint32);
function get_holder(uint32 n) external view returns (address);
function get_n_holders() external view returns (uint256);

}