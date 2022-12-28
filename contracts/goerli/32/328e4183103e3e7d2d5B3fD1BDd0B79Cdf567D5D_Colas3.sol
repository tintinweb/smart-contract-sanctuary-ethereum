// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Colas3 is Ownable, ReentrancyGuard {

    struct Reserva {
        uint id;
        uint precioVenta;
        address payable owner;
        string nombre;
        string apellido;
        string dni;
        string telefono;
        string mail;
        bool cancelada;
        bool comprada;
    }
    
    Reserva[] public reservas;
    uint public numeroReservas;
    uint public numeroReservasCompradas;
    uint public numeroReservasCanceladas;
    
    mapping(uint => Reserva) public reservasPorId;
    mapping(address => Reserva) public reservasPorOwner;
    
    event ReservaCreada(
        uint id, 
        uint precioVenta, 
        address payable owner, 
        string nombre, 
        string apellido, 
        string dni, 
        string telefono, 
        string mail, 
        bool cancelada, 
        bool comprada);

    event ReservaCancelada(
        uint id, 
        uint precioVenta, 
        address payable owner, 
        string nombre, 
        string apellido, 
        string dni, 
        string telefono, 
        string mail, 
        bool cancelada, 
        bool comprada);

    event ReservaComprada(
        uint id, 
        uint precioVenta, 
        address payable owner, 
        string nombre, 
        string apellido, 
        string dni, 
        string telefono, 
        string mail, 
        bool cancelada, 
        bool comprada);
    
    function crearReserva(
        uint _precioVenta, 
        string memory _nombre, 
        string memory _apellido, 
        string memory _dni, 
        string memory _telefono, 
        string memory _mail) public payable onlyOwner {
        
        require(_precioVenta > 0, "El precio de la venta debe ser mayor que 0");
        require(bytes(_nombre).length > 0, "El nombre no puede estar vacio");
        require(bytes(_apellido).length > 0, "El apellido no puede estar vacio");
        require(bytes(_dni).length > 0, "El dni no puede estar vacio");
        require(bytes(_telefono).length > 0, "El telefono no puede estar vacio");
        require(bytes(_mail).length > 0, "El mail no puede estar vacio");
        
        numeroReservas++;
        reservas.push(
            Reserva(
                numeroReservas,                
                 _precioVenta, 
                 payable(msg.sender), 
                 _nombre, 
                 _apellido, 
                 _dni, 
                 _telefono, 
                 _mail, 
                 false, 
                 false));
        reservasPorId[numeroReservas] = 
        Reserva(
            numeroReservas,              
            _precioVenta, 
            payable(msg.sender), 
            _nombre, 
            _apellido, 
            _dni, 
            _telefono, 
            _mail, 
            false, 
            false);
        reservasPorOwner[payable(msg.sender)] = 
        Reserva(
            numeroReservas,             
            _precioVenta, 
            payable(msg.sender), 
            _nombre,
            _apellido, 
            _dni, 
            _telefono, 
            _mail, 
            false, 
            false);

        emit ReservaCreada(
            numeroReservas,            
            _precioVenta, 
            payable(msg.sender), 
            _nombre, 
            _apellido, 
            _dni, 
            _telefono, 
            _mail, 
            false, 
            false);
    }

    function cancelarReserva(uint _id) public payable {
        require(_id > 0 && _id <= numeroReservas, "La reserva no existe");
        require(reservasPorId[_id].owner == msg.sender, "Solo el owner de la reserva puede cancelarla");
        require(reservasPorId[_id].cancelada == false, "La reserva ya esta cancelada");
        require(reservasPorId[_id].comprada == false, "La reserva ya esta comprada");
        
        reservasPorId[_id].cancelada = true;        
        numeroReservasCanceladas++;
        
        emit ReservaCancelada(
            _id,             
            reservasPorId[_id].precioVenta, 
            reservasPorId[_id].owner, 
            reservasPorId[_id].nombre, 
            reservasPorId[_id].apellido, 
            reservasPorId[_id].dni, 
            reservasPorId[_id].telefono, 
            reservasPorId[_id].mail, 
            true, 
            false);
    }

    function comprarReserva(
        uint _id, 
        string memory _nombre, 
        string memory _apellido, 
        string memory _dni, 
        string memory _telefono, 
        string memory _mail) public payable nonReentrant {

        require(_id > 0 && _id <= numeroReservas, "La reserva no existe");
        require(reservasPorId[_id].cancelada == false, "La reserva esta cancelada");
        require(reservasPorId[_id].comprada == false, "La reserva ya esta comprada");
        require(msg.value == reservasPorId[_id].precioVenta, "El precio de la reserva no es correcto");
        require(bytes(_nombre).length > 0, "El nombre no puede estar vacio");
        require(bytes(_apellido).length > 0, "El apellido no puede estar vacio");
        require(bytes(_dni).length > 0, "El dni no puede estar vacio");
        require(bytes(_telefono).length > 0, "El telefono no puede estar vacio");
        require(bytes(_mail).length > 0, "El mail no puede estar vacio");
        
        reservasPorId[_id].comprada = true;
        reservasPorId[_id].owner.transfer(reservasPorId[_id].precioVenta);
        reservasPorId[_id].owner = payable(msg.sender);
        reservasPorId[_id].nombre = _nombre;
        reservasPorId[_id].apellido = _apellido;
        reservasPorId[_id].dni = _dni;
        reservasPorId[_id].telefono = _telefono;
        reservasPorId[_id].mail = _mail;
        numeroReservasCompradas++;
        
        emit ReservaComprada(
            _id,             
            reservasPorId[_id].precioVenta, 
            payable(msg.sender), 
            _nombre, 
            _apellido, 
            _dni, 
            _telefono, 
            _mail, 
            false, 
            true);
    }   

    function getReservasPorId(uint _id) public view returns (Reserva memory) {
        return reservasPorId[_id];
    }

    function getReservasPorOwner(address _owner) public view returns (Reserva memory) {
        return reservasPorOwner[_owner];
    }

    function getNumeroReservas() public view returns (uint) {
        return numeroReservas;
    }    

    function getNumeroReservasCompradas() public view returns (uint) {
        return numeroReservasCompradas;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}