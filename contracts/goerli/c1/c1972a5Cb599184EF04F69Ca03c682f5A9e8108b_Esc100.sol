/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: Esc.sol


pragma solidity ^0.8.7;


contract Esc100 {

    enum EstadoEsc {
            OrdCre,
            CriPro,
            CriLib
    }

    enum TipoEs {
        SD,
        QuVenCri,
        QuCompCri
    }

    uint public idenEsc = 0;

    struct Esc {
        uint idUnico;
        address pCrip;
        address pFI;
        uint mon;
        IERC20 tok;
        EstadoEsc estadoEsc;
        TipoEs tipoEs;
    }    

    mapping (uint => Esc) public MapEsc;

    function crearEsc(address _pFI, uint _mon, IERC20 _tok, TipoEs _tipo) public {
        require(_mon > 0, "La cantidad debe ser mayor que cero");
        require(_tok.allowance(msg.sender, address(this)) >= _mon, "La aprobacion es insuficiente");

        Esc memory EscAdd = Esc(idenEsc, msg.sender, _pFI, _mon, _tok,EstadoEsc.CriPro,TipoEs.SD);
        EscAdd.tipoEs = _tipo;
        bool success = _tok.transferFrom(msg.sender,address(this),_mon);
        require(success, "La transferencia ha fallado");
        MapEsc[idenEsc] = EscAdd;
        idenEsc ++;
    }


    function libCriPro(uint _idABuscar)public {
        require(MapEsc[_idABuscar].pCrip == msg.sender, "No puedes liberar ya que no te pertenece el esc");
        bool success = MapEsc[_idABuscar].tok.transfer(MapEsc[_idABuscar].pFI,MapEsc[_idABuscar].mon);        
        require(success, "La liberacion de las crip ha fallado");
        MapEsc[_idABuscar].estadoEsc = EstadoEsc.CriLib ;
    }    
}