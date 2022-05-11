/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: OpenZeppelin/[email protected]/Context

/*
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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: TokenFarm.sol

contract TokenFarm is Ownable{

    address[] public allowedTokens;
    //mapping token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public stakers;


    //constructor necesario para poder dar los tokens
    //lo primero es crear una variable que sirva para registrar los tokens de tipo IERC20
    IERC20 public dappToken;

    //lo segundo seria un constructor en el cual le damos el address del dapp token y lo registra en la variable previamente mencionada
    //una vez registrado dicho dapp token, ya podemos usar las funciones del token
    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }
    //`ponemos primero el address del token que queremos incluir, y depsues el price feed
    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner{
        tokenPriceFeedMapping[_token] = _priceFeed;
    }



    function stakeTokens(uint256 _amount, address _token) public {
        //what tokens can they stake?
        //how much can they stake?
        require(_amount > 0, "amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currently not allowed");
        //tenemos que hacer call de transfer function del ERC20                                 https://eips.ethereum.org/EIPS/eip-20
        //ERC20 tiene dos funciones, transfer(solo funciona si es llamado desde el wallet que controla los tokens)
        // y transfer from, si no eres el dueÃ±o pero los tienes delegados

        //como nuestro TokenFarm no es el wallet que es dueÃ±o de los ERC20 tokens, tenemos que usar la funcion transferFrom
        //necesitamos el ABI para poder call la funcion transfer del ERC20, para ello importamos el contrato de openzeppelin, pero bien podriamos copiar el interfaz y usarlo de esa manera
        IERC20(_token).transferFrom(msg.sender, address(this), _amount); //hacemos un wrap del address del token para asi darle funciones con el ABI.
        //creamos el "contrato del token" diciendo que el _token es el address de un IERC20, por lo que tiene el mismo ABI, y ejecutamos la funcion transferFrom
        //el transfer se hace del msg.sender, al address del TokenFarm, y la cantidad
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount; //con el mapping creado decimos que: 
        //del token x del sender su balance es igual al balance anterior mas amount
        updateUniqueTokensStaked(msg.sender, _token);
        if (uniqueTokensStaked[msg.sender]== 1){
            //vamos a registrar solo la primera vez que tiene un token, a partir de ahi ya no lo pusheamos en los stakers porque ya esta metido
            stakers.push(msg.sender);
        }
    }

    function unstakeTokens(address _token) public {
        uint256  balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0; //vulnerable to reentrency attacks?
        uniqueTokensStaked[msg.sender]=uniqueTokensStaked[msg.sender]-1;
        //en teoria aqui podriamos meter una funcion para ver si el msg.sender ya no tiene nada en stake, por lo que deberiamos eliminarlo de la lista de stakers.
        //tendriamos que hacer un bucle for que pasa por cada uno de los tokens, y revisa si el msg.sender tiene algo mayor de 0, si lo tiene se queda, si el bucle 
        //acaba sin detectar nada mayor de 0 quita al usuario de la lista de stakers.
    }


    function addAllowedTokens(address _token) public onlyOwner{
        allowedTokens.push(_token);
    }


    function tokenIsAllowed(address _token) public returns( bool){
        for(uint256 allowedTokensIndex = 0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex ++){
            if(allowedTokens[allowedTokensIndex] == _token){
            return true;
            }
        }
        return false;
    }

    function issueTokens() public onlyOwner{
        for( uint256 stakersIndex = 0;
        stakersIndex < stakers.length;
        stakersIndex ++){
            address recipient = stakers[stakersIndex];
            //send them a token reward
             //aqui creamos la parte del constructor para poder enviar dappTokens
            //dappToken.transfer(recipient, );
            //based on their total value locked
            uint256 userTotalValue = getUserTotalValue(recipient);
            //la cantidad que tenga en valor total se lo transferimos de nuestro dapp token
            dappToken.transfer(recipient, userTotalValue);
        }
    }
    function getUserTotalValue(address _user) public view returns(uint256){
        //esta funcion hara un ciclo a traves de los diferentes tokens, y para cada uno de los tokens diferentes sumara su valor, 
        //para conseguir el valor monetario de los tokens llama a la funcion getUserSingleTokenValue, y esta le da el valor que tiene ese usuario de ese token en dollars
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "no tokens staked");
        for (uint256 allowedTokensIndex = 0;
        allowedTokensIndex < allowedTokens.length;
        allowedTokensIndex ++){
            totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[allowedTokensIndex]);
        }
        return totalValue;


    }
    function getUserSingleTokenValue(address _user, address _token) public view returns(uint256){
        //esta funcion hara el cambio de valor de la moneda y devolvera directamente el valor por la cantidad
        if (uniqueTokensStaked[_user] <= 0){
            return 0;//no usamos require porque eso haria revert, y queremos que siga yendo porque quizas tenga otras monedas.
        }
        //price of token x staking balance[token][user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return (stakingBalance[_token][_user] * price / 10**decimals);
    }
    function getTokenValue(address _token)public view returns(uint256, uint256){
        //priceFeedAddress
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        //tenemos que crear el AggregatorV3Interface para el pricefeed correcto:
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);

        (,int256 price,,,)= priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals()); //tenemos que hacer wrap de decimals, ya que decimals devuelve un uint8
        return(uint256(price), decimals);
    }



    function updateUniqueTokensStaked(address _user, address _token) internal {
        //esta funcion se activa despues de haber hecho una transferencia
        //mira si el staking balance de ese token(que puede ser nuevo no haber ya stakeado) tiene algo, si no tenia nada aÃ±ade 1 al uniqueTokensStaked
        if (stakingBalance[_token][_user]<=0){
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }
    
}