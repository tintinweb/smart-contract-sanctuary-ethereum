// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

// Queremos hacer:
// Stake tokens,
// UnStake tokens
// issueTokens
// addAllowedTokens
// getEthValue

// Importante notar que los tokens stakeados se guardaran en este contrato

contract TokenFarm is Ownable {
    address[] public tokensAllowed;
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokenStaked;
    mapping(address => address) public tokenPriceFeed;
    address[] public stakers;
    IERC20 public dappToken;
    AggregatorV3Interface public priceFeed;

    constructor(address _dappTokenAddress) {
        // Cuando hacemos el deploy del contract tenemos que saber con cual token haremos los rewards.
        dappToken = IERC20(_dappTokenAddress);
    }

    // Para hacer un stake, las cosas mas importantes que necesitamos saber son la cantidad y el address del token a stakear.
    function stakeToken(uint256 _amount, address _token) public {
        // Para hacer el stake tenemos que hacernos dos preguntas: Cuales tokens se le puede hacer stake y que cantidad se le puede hacer stake

        require(_amount > 0, "You have to stake more than 0");
        require(isTokenAllowed(_token), "This token is not allowed");

        // Procedemos a transferir el token a stakear
        // Definimos si usar transfer o transferFrom dependiendo de si este contrato ese el dueÃ±o del token, (que no lo es), por lo cual se usa transferFrom

        // Para usar transferFrom tenemos que importar el contrato ERC20 o usar una interfaz, como no vamos a crear ningun token, usamos a interfaz

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // Una vez que hacemos la transferencia, tenemos que actualizar que salvar esa informacion en un registro, para saber quien ha mandado, que token ha mandado y cuanto.

        // Ya habiendo aprobado los requisitos para el stake, agregamos su address en un registro donde salvamos los stakers y la cantidad de tokens que esta stakeando

        // En caso de que el que manda el stake command sea primera vez que hace stake de cualquier token, entonces lo metemos a la lista de stakers
        if (uniqueTokenStaked[msg.sender] == 0) {
            stakers.push(msg.sender);

            updateUniqueTokensStaked(_token, msg.sender);

            // Registramos esa transaccion de stake

            stakingBalance[_token][msg.sender] =
                stakingBalance[_token][msg.sender] +
                _amount;
        }
    }

    function unstakeToken(address _token) public {
        // Primero chequeamos el balance de la cuenta
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Your balance of this token is 0 ");
        IERC20(_token).transfer(msg.sender, balance);

        //RECORDAR SIEMPRE ACTUALIZAR EL BALANCE LUEGO DE HACER UNA FUNCION DE TRANSFER

        stakingBalance[_token][msg.sender] = 0;
        uniqueTokenStaked[msg.sender] = uniqueTokenStaked[msg.sender] - 1;
        // Podriamos verificar si la direccion que hace el unstake ya no esta stakeando mas tokens para eliminarlo del array de stakers.
    }

    // Ademas es necesario saber si el token al que queremos hacer stake esta permitido por la plataforma
    function isTokenAllowed(address _token) public returns (bool) {
        for (uint256 i = 0; i < tokensAllowed.length; i++) {
            if (tokensAllowed[i] == _token) {
                return true;
            }
        }
        return false;
    }

    // Creamos una funcion tambien para poder agregar tokens permitidos, los mismos deben poder ser agregados solo por el owner o admin del contrato
    function addAllowedToken(address newToken) public onlyOwner {
        tokensAllowed.push(newToken);
    }

    function updateUniqueTokensStaked(address _token, address sender) internal {
        // Este registro sirve para saber cuantos tokens tiene el sender del stake command.

        // Si su balance del token es cero, entonces es primera vez que esta stakeando este token, y por ende hay que sumarle +1 a su numero de tokens stakeados
        if (stakingBalance[_token][sender] <= 0) {
            uniqueTokenStaked[sender] = uniqueTokenStaked[sender] + 1;
        }
    }

    // Procedemos a crear una funcion que permita generar los tokens para el reward
    function issueToken() public onlyOwner {
        // Para poder emitir tonkens de reward, primero necesitamos saber quienes son los que tienen algun stake en el contract.

        for (uint256 i = 0; i < stakers.length; i++) {
            address rewardRecipient = stakers[i];

            // Teniendo el recipiente que seria cada uno de los stakers, procedemos a mandar los rewards en base al total stakeado
            // Para saber cuanto reward le damos tenemos que calcular primero el valor del total stakeado, para esto necesitamos obtener el precio de los tokens que posee
            uint256 rewardAmount = valueOfTokensStaked(rewardRecipient);
            // Se usa dappToken y no una interfaz IERC20(otroToken) porque aqui los tokens que mandamos como rewards estan ya predefinidos como los dapp en el constructor del contrato.
            dappToken.transfer(rewardRecipient, rewardAmount);
        }
    }

    function valueOfTokensStaked(address _recipient) public returns (uint256) {
        uint256 recipientStakeTotalValue = 0;

        // Primero necesitamos saber que tokens tiene

        for (
            uint256 stakedTokenIndex = 0;
            stakedTokenIndex < tokensAllowed.length;
            stakedTokenIndex++
        ) {
            address tokenAddress = tokensAllowed[stakedTokenIndex];

            // Verificamos entre todos los tokens permitidos cuales son los que posee
            // Chequeamos el balance para saber si tiene o no el token
            if (stakingBalance[tokenAddress][_recipient] > 0) {
                uint256 stakedTokenQuantity = stakingBalance[tokenAddress][
                    _recipient
                ];

                (uint256 tokenPrice, uint256 decimals) = getTokenPriceInUSD(
                    tokenAddress
                );
                recipientStakeTotalValue =
                    ((stakedTokenQuantity * tokenPrice) / 10**decimals) +
                    recipientStakeTotalValue;
                // Practicamente obtenemos por cada moneda stakeada el equivalente a su precio en usd.
            }
        }
        return recipientStakeTotalValue;
    }

    // Para obtener los priceFeed, tendremos que hacerlo manualmente y setearlo en base a la lista de tokensAllowed.
    // Solo lo puede hacer el owner del contrato
    function setTokenPriceFeed(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeed[_token] = _priceFeed;
    }

    // Obtenemos el precio del token en USD
    function getTokenPriceInUSD(address _tokenAddress)
        internal
        returns (uint256, uint256)
    {
        address _tokenPriceFeed = tokenPriceFeed[_tokenAddress];
        priceFeed = AggregatorV3Interface(_tokenPriceFeed);
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint8 _decimals = priceFeed.decimals();
        return (uint256(price), uint256(_decimals));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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