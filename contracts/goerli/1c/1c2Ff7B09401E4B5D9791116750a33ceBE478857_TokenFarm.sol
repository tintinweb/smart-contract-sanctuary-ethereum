// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";


contract TokenFarm is Ownable
{
    // Obiettivi di questo smart contract:
    // Stake tokens - DONE!
    // Unstake tokens
    // issueTokens (dare ricompense con i DappToken agli utenti per usare la nostra piattaforma) - DONE!
    // addAllowedTokens: aggiungere piÃ¹ token consentiti da usare nella piattaforma - DONE!
    // getValue - DONE!

    address[] public allowedTokens;

    // Mapping: token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;

    // Gli indirizzi degli utenti della piataforma che stakeano dei token
    address[] public stakers;

    // Sappiamo per ciscun utente (indirizzo) quanti token diversi sta stakeando
    mapping(address => uint256) public uniqueTokensStaked;

    // Memorizziamo in una variabile l'intero dappToken, non solo il suo indirizzo
    IERC20 public dappToken;

    // mapping tra indirizzo del token a indirizzo del priceFeedAddress associato a quel token
    mapping(address => address) public tokenToPriceFeed;


    constructor(address _dappTokenAddress) public
    {
        dappToken = IERC20(_dappTokenAddress);
    }


    // Aggiorniamo la mapping tokenToPriceFeed
    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner
    {
        tokenToPriceFeed[_token] = _priceFeed;
    }


    function stakeTokens(uint256 _amount, address _token) public
    {
        // Quanto si puÃ² stakeare? Qualsiasi amount maggiore di 0
        // Che token si puÃ² stakeare
        require(_amount > 0, "Amount mus be more than 0");
        require(isTokenAllowed(_token), "Token is currently not allowed");
        // Ora bisogna chiamare la funzione transferFrom di ERC20 per effettuare il deposito
        // transfer la usiamo se il msg.sender Ã¨ l'indirizzo che possiede i token
        // transferFrom la usiamo se l'indirizzo con i token Ã¨ un altro 
        // (a quel punto bisogna prima approvare che i token possano essere trasferiti con approve())
        // In questo caso, chiamando transferFrom il msg.sender Ã¨ lo smart contract stesso: TokenFarm
        // quindi necessariamente chiamiamo transferFrom anzichÃ¨ transfer cosicchÃ¨ si possa settare
        // che il mandante Ã¨ effettivamente msg.sender e cioÃ¨ chi chiama stakeTokens.
        // Parametri: pagante, ricevente, amount
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        // Aggiorna uniqueTokensStaked
        updateUniqueTokenStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] += _amount;

        // Se Ã¨ la prima volta che depositano e quindi la prima volta che usano la piattaforma li
        // aggiungiamo a stakers
        if(uniqueTokensStaked[msg.sender] == 1)
        {
            stakers.push(msg.sender);
        }
    }


    // Permette di prelevare i tokens depositati
    function unStakeTokens(address _token) public
    {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0");
        // Ritrasferisco tutto a msg.sender
        IERC20(_token).transfer(msg.sender, balance);
        // Potrebbe essere poco sicuro ad alcuni attacchi
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] -= 1;
        // Dovremmo eliminare lo user da stakers[] se non avesse piÃ¹ nulla stakeato
    }

    
    // Restituisce true se _token Ã¨ allowed
    function isTokenAllowed(address _token) public returns (bool)
    {
        for(uint256 i = 0; i < allowedTokens.length; i++)
        {
            if(_token == allowedTokens[i])
            {
                return true;
            }
        }

        return false;
    }


    // Aggiunge un token agli allowedTokens, solo l'owner della piataforma puÃ² farlo
    function addAllowedTokens(address _token) public onlyOwner
    {
        allowedTokens.push(_token);
    }


    // Solo questo contratto puÃ² chiamare questa funzione
    // Incrementa di 1 uniqueTokensStaked[_user] se deposita per la prima volta questo token
    function updateUniqueTokenStaked(address _user, address _token) internal
    {
        if(stakingBalance[_token][_user] <= 0)
        {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    // Dare ricompense agli utenti in base a quanti token stakeano sulla nostra piattaforma
    // dobbiamo decidere intanto il ratio di premio rispetto ad un altro token che decidiamo
    // noi, che potrebbe essere ad esempio ETH. Se usiamo ETH dobbiamo convertire tutti gli altri
    // allowed tokens in ETH e trasferire l'amount che ne consegue di DAPP
    // Ã¨ molto piÃ¹ gas efficient se fosse l'utente a decidere quando claimare la ricompensa
    function issueTokens() public onlyOwner
    {
        for(uint256 i = 0; i < stakers.length; i++)
        {
            address recipient = stakers[i];
            // Gli mandiamo una ricompensa in base a quanto hanno depositato
            uint256 userTotalReward = getUserTotalReward(recipient);
            // TokenFarm sarÃ  il proprietario di tutti i DappToken
            dappToken.transfer(recipient, userTotalReward);
        }
    }

    // Prendiamo la ricompensa espressa in wei del nostro token DAPP
    function getUserTotalReward(address _user) public view returns (uint256)
    {
        uint256 totalReward = 0;
        // Se non abbiamo alcun token depositato usciamo
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        // Guardiamo per ciascun allowedToken quanto ne ha depositato l'utente
        for (uint256 i = 0; i < allowedTokens.length; i++)
        {
            totalReward += getUserSingleTokenReward(_user, allowedTokens[i]);
        }

        return totalReward;
    }


    // Restituisce quanto vale il singolo _token in DAPP in base a quanto ne ha depositato _user
    function getUserSingleTokenReward(address _user, address _token) public view returns (uint256)
    {
        // Vogliamo che 1 DAPP equivalga ad 1 dollaro stakeato in qualsiasi token

        // Vogliamo comunque andare avanti anche se l'utente non ha depositato nulla
        if (uniqueTokensStaked[_user] <= 0)
            return 0;

        // price del token e moltiplicarlo per lo stakingBalance dello user
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        // 1 DAPP = 1 dollaro stakeato. In dollari, per _token, lo user ha stakingBalance[_token][user] * price
        // questo price feed avrÃ  decimals decimali, quindi dividiamo per questi decimali per trovare
        // quanti DAPP dargli
        return (stakingBalance[_token][_user] * price / (10 ** decimals));
    }

    
    // Restituisce il valore del singolo token in USD
    function getTokenValue(address _token) public view returns (uint256, uint256)
    {
        // Abbiamo bisogno di un priceFeedAddress
        address priceFeedAddress = tokenToPriceFeed[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        // Prendiamo l'ultimo price feed
        (,int256 price, , ,) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        // Restituiamo price e i suoi decimali cosicchÃ¨ si possa usare la stessa unitÃ  di misura
        return (uint256(price), decimals);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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