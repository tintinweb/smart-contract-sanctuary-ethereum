/**
 *Submitted for verification at Etherscan.io on 2022-10-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract crodwfounding is Ownable {

    using SafeMath for uint256;
    
    uint public totalFounding = 0;

    uint public basePorcentaje = 10000;
  
  //FEE DEPOSITOS
    uint public feeDeposit = 200;
    uint public feeRestanteDesposit = basePorcentaje.sub(feeDeposit);

  //FEE RECLAMO DE GANANCIAS
    uint public claimfee = 1000;
    uint public claimFeeFail = basePorcentaje.sub(claimfee);

  //FEE SI NO SE LLENA LA POOL
   uint public feeNoComplet = 1000;
   uint public restanNoCompleteFee = basePorcentaje.sub(feeNoComplet);

   address addrFee = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 ;

    IERC20 public DAI;

    struct Datos {
      string tittle;
      string description;
      string urlImg;
    }

    struct Niveles{
       uint bronze;
        uint silver;
        uint gold;
        uint diamond;
        uint platinum;
        uint palladium;
    }

    struct PoolFounding {
        uint pid;
        address creator;
        uint totalToCollect;
        Niveles nivel;
        uint income;
        uint deadline;
        address[] users;
        Datos dato;
        bool active;
        uint min;
    }

    struct Inversor {
        address inversor;
        uint pid;
        uint cantidadIngresada;
        uint cantidadConFee;
        string nivel;
        string mail;
        bool devuelto;
    }

    constructor(address _dai){
        DAI = IERC20 (_dai);
    }


    event createFounding (uint pid, address creator, uint totalToCollect );
    event sendInversion (uint pid, uint amount, address inversor);


    mapping(uint => PoolFounding) public poolFounding;

    mapping(uint256 => mapping(address => Inversor)) public inversor;
    
    mapping(uint => mapping(address => bool)) public isConfirmed;


///agregar cantidad minima
    function createCrodwFounding( string memory _title, string  memory _description,
        uint _totalToCollect, uint _bronze, 
        uint _silver,
        uint _gold,
        uint _diamond,
        uint _platinum,
        uint _palladium,
        uint _deadline, address _creator) public onlyOwner {

        uint totalCollect =  _totalToCollect.mul(1000000);
        string memory title = _title;
        string memory description = _description;
       // string memory url = _url;
        uint bronze = _bronze.mul(1000000);
        uint silver = _silver.mul(1000000);
        require(bronze < silver , "bronze tiene q ser menor a silver");
        uint gold = _gold.mul(1000000);
        require(silver < gold , "silver tiene q ser menor a gold");
        uint diamon = _diamond.mul(1000000);
        require(gold < diamon , "gold tiene q ser menor a diamon");
        uint platinum = _platinum.mul(1000000);
        require(diamon < platinum , "diamon tiene q ser menor a platinum");
        uint palladium = _palladium.mul(1000000);
        require(platinum< palladium, "menor que platinum");


        uint deadLIne = _deadline.mul(1 days);  
        uint dayDealine = block.timestamp.add(deadLIne);

        PoolFounding storage pool = poolFounding[totalFounding];
          pool.pid = totalFounding;
          pool.creator = _creator;
          pool.totalToCollect = totalCollect;
          pool.nivel = Niveles(bronze,silver, gold, diamon,platinum, palladium);
          pool.income = 0;
          pool.deadline = dayDealine;
          pool.dato = Datos(title,description,title);
          pool.active = true;
 
          totalFounding += 1;

        emit createFounding (totalFounding, msg.sender, totalCollect);
    } 

    function depositMoney(uint _pid, uint _amount, string memory _mail)internal {
        PoolFounding storage pool = poolFounding[_pid];
        uint amount = _amount.mul(1000000);
        require(pool.deadline > block.timestamp," ya expiroooo");
        require(pool.active == true, "no esta activa");
        require(amount.add(pool.income) <= pool.totalToCollect.add(pool.totalToCollect.mul(feeDeposit).div(basePorcentaje)), "poner menos que ya esta casi completa ");
        uint256 allowance = IERC20(DAI).allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        uint amounFee = amount.mul(feeDeposit).div(basePorcentaje);
        uint amountFinal = amount.mul(feeRestanteDesposit).div(basePorcentaje);
        if(amount > 0){
            require(IERC20(DAI).transferFrom(msg.sender, addrFee, amounFee ),"DASDAS");   
            require(IERC20(DAI).transferFrom(msg.sender, address(this),amountFinal),"DASDAS"); 
        }

        Inversor storage infoInver = inversor[_pid][msg.sender];

        if(isConfirmed[_pid][msg.sender] == true){
            infoInver.cantidadIngresada += amountFinal;
            infoInver.cantidadConFee += amounFee;
            pool.income +=amountFinal;
            infoInver.nivel = nivel(_pid, infoInver.cantidadIngresada);
        }else{
             Inversor memory newInersor = Inversor(
                msg.sender,
                _pid,
                amountFinal,
                amounFee,
                nivel(_pid, amountFinal),
                _mail,
                false
                );
                pool.users.push(msg.sender);
                inversor[_pid][msg.sender] = newInersor;
                isConfirmed[_pid][msg.sender] = true;
                pool.income +=amountFinal;
        }

        emit sendInversion(_pid, amountFinal, msg.sender);

    }

  function deposit(uint _pid, uint _amount, string memory _mail) public {
    depositMoney(_pid,_amount, _mail);
  }



    function nivel(uint _pid, uint _amount) internal  returns (string memory nivel1){
        PoolFounding storage pool = poolFounding[_pid];
        Inversor storage infoInver = inversor[_pid][msg.sender];
          if(_amount < pool.nivel.bronze){
              return infoInver.nivel = "BRONZE";
            } else if(_amount < pool.nivel.silver ){
              return  infoInver.nivel = "SILVER";
            }else if(_amount < pool.nivel.gold ){
              return  infoInver.nivel = "GOLD";
            }else if(_amount < pool.nivel.diamond ){
              return  infoInver.nivel = "DIAMOND";
            }else if(_amount < pool.nivel.platinum ){
              return  infoInver.nivel = "PLATINIUM";
            }else if(_amount < pool.nivel.palladium ||  _amount > pool.nivel.palladium){
              return  infoInver.nivel = "PALLADIUM";
          }
    }
            

    function claimReward(uint _pid) public {
        PoolFounding storage pool = poolFounding[_pid];
          require(msg.sender == pool.creator, "vos no podes");
          require(pool.income >= pool.totalToCollect, "tienen que tener el mismo valor");
          require(pool.active == true, "no esta activa");
      //  require(pool.deadline < block.timestamp," no expiroooo aun");
        if( pool.totalToCollect > 0){
            IERC20(DAI).approve(address(this),pool.totalToCollect);
            require(IERC20(DAI).transferFrom(address(this), addrFee ,pool.totalToCollect.mul(claimfee).div(basePorcentaje)),"DASDAS"); 
            require(IERC20(DAI).transferFrom(address(this), pool.creator ,pool.totalToCollect.mul(claimFeeFail).div(basePorcentaje)),"DASDAS");
        }
        pool.active = false;
    }


    function devolverRewards(uint _pid) public onlyOwner{
      PoolFounding storage pool = poolFounding[_pid];
      require(pool.active == true, "no esta activa");
    //require(pool.deadline < block.timestamp," no expiroooo aun");
      uint cantidadSobrante = pool.income;
      for(uint i = 0; i< pool.users.length; i++){
        Inversor storage infoInver = inversor[_pid][pool.users[i]];
        if(infoInver.devuelto == false){
         IERC20(DAI).approve(address(this),pool.totalToCollect);
         require(IERC20(DAI).transferFrom(address(this), infoInver.inversor , infoInver.cantidadIngresada.mul(restanNoCompleteFee).div(basePorcentaje)),"DASDAS");
        }
        infoInver.devuelto = true; 
      }
        uint cantidadFee = cantidadSobrante.mul(feeNoComplet).div(basePorcentaje);
        require(IERC20(DAI).transferFrom(address(this), addrFee , cantidadFee),"DASDAS");
        pool.active = false;
    }


      function claimRewardCadauNO(uint _pid) public{
        PoolFounding storage pool = poolFounding[_pid];
        require(pool.active == true, "no esta activa");
        require(pool.deadline < block.timestamp," no expiroooo aun");
        Inversor storage infoInver = inversor[_pid][msg.sender];
        if( pool.totalToCollect > 0){
            IERC20(DAI).approve(address(this),pool.totalToCollect);
            require(IERC20(DAI).transferFrom(address(this), addrFee ,infoInver.cantidadIngresada.mul(claimfee).div(basePorcentaje)),"DASDAS"); 
            require(IERC20(DAI).transferFrom(address(this), infoInver.inversor ,infoInver.cantidadIngresada.mul(claimFeeFail).div(basePorcentaje)),"DASDAS");
        }

        infoInver.devuelto = true;
    }



    

    function balanceDai() public view returns(uint balanceStable){
      uint balance = IERC20(DAI).balanceOf(address(this));
      return balance.div(1000000);
    }


    function addresPool (uint _pid) public view returns(address[] memory usuarios){
      PoolFounding storage pool = poolFounding[_pid]; 
      return pool.users;
    }



    function cambiarFee(uint _fee) public onlyOwner {
      feeDeposit= _fee;
      feeRestanteDesposit = basePorcentaje.sub(feeDeposit);
    }


    function cambiarFeeClaim(uint _fee) public onlyOwner {
      claimfee= _fee;
      claimFeeFail = basePorcentaje.sub(claimfee);
    }

      function cambiarFeeNoReclam(uint _fee) public onlyOwner {
      feeNoComplet= _fee;
      restanNoCompleteFee = basePorcentaje.sub(feeNoComplet);
    }

    function apagarPool (uint _pid) public onlyOwner {
       PoolFounding storage pool = poolFounding[_pid]; 
       pool.active = false;
    }


}