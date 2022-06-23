/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


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

// File: docs.chain.link/samples/PriceFeeds/PriceConsumerV3.sol


pragma solidity ^0.8.0;


contract PriceConsumerV3 {

    AggregatorV3Interface internal priceFeed; 
    mapping(string => AggregatorV3Interface) public priceFeeds;

    // All the price feeds will return a dollar amount (<token_symbol>/USD)
    constructor(){
        priceFeeds["DAI"]   =  AggregatorV3Interface(0x777A68032a88E5A84678A77Af2CD65A7b3c0775a);
        priceFeeds["BAT"]   =  AggregatorV3Interface(0x8e67A0CFfbbF6A346ce87DFe06daE2dc782b3219);
        priceFeeds["COMP"]  =  AggregatorV3Interface(0xECF93D14d25E02bA2C13698eeDca9aA98348EFb6);
        priceFeeds["ZRX"]   =  AggregatorV3Interface(0x24D6B177CF20166cd8F55CaaFe1c745B44F6c203);
        priceFeeds["USDC"]  =  AggregatorV3Interface(0x9211c6b3BF41A10F78539810Cf5c64e1BB78Ec60);
        priceFeeds["USDT"]  =  AggregatorV3Interface(0x2ca5A90D34cA333661083F89D831f757A9A50148);
        priceFeeds["UNI"]   =  AggregatorV3Interface(0xDA5904BdBfB4EF12a3955aEcA103F51dc87c7C39);
    }

    /****
        @notice this function returns the price of a token in USD through chainlink data feeds
        @param _symbol the symbol of the token to get the price for (for example: ETH)
        @return (int) the price of the token in USD
    *****/
    function getLatestPriceOfToken(string memory _symbol) public view returns (int) {
          (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        )  = priceFeeds[_symbol].latestRoundData();
        return price / 10 ** 8;
    }
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: docs.chain.link/samples/PriceFeeds/DapperBankKovan.sol

pragma solidity ^0.8.0;




contract DapperBankKovan  {

    struct Stake {
        address investor;
        address token;
        uint amount;
        uint timestamp;
        bool staked;
    }

    struct Loan {
        address issuer;
        address token;
        uint intrest;
        uint amount;
        uint duration;
        uint timestamp;
    }

    event Staked(
        address indexed investor, 
        uint256 indexed timestamp,
        uint indexed amount,
        string symbol
    );

    event Unstaked(
        address indexed investor, 
        uint256 indexed timestamp,
        uint indexed amount,
        string symbol
    );

    event Borrowed(
        address indexed issuer, 
        uint256 indexed timestamp,
        uint indexed amount,
        string symbol
    );

    event Repaid(
        address indexed borrower,
        uint indexed amount,
        bool indexed success,
        uint256 timestamp,
        string symbol
    );

    /// @notice token address -> investor address -> amount staked
    mapping(address => mapping(address => Stake)) public stakedBalances;

    /// @notice token address -> amount of tokens stored in the contract (This way we can now how much liquidity is in the contract)
    mapping(address => uint256) public  tokenBalances;

    /// @notice token address -> amount of rewards per user
    mapping(address => uint) public rewardsEarned;

    /// @notice user address => token address -> amount of tokens that are locked due to a lend
    mapping(address => mapping(address => uint)) public lockedAssets;

    /// @notice user address => token address -> amount of rewards that are locked due to a lend
    mapping(address => mapping(address => uint)) public lockedRewards;

    /// @notice user address -> token address -> amount of tokens loaned
    mapping(address => mapping(address => Loan)) public loans;

    /// @notice a user needs to stake his tokens at least for 300 seconds or 5 mins to receive the reward 
    uint256 private rewardPeriod = 60;

    /// @notice the contract of the reward token
    IERC20 public dpkToken;

    /// @notice price feed contract of Chainlink in order to get off chain data
    PriceConsumerV3 public priceConsumer;

    address[] public assets;
    address public owner;
  
    /// @notice the list of stakers, this will be important in order to issue the rewards
    address[] public stakers;

    /// @notice this mapping will track how many different tokens the user has staked
    mapping(address => uint) public distinctTokensStaked;


    /// @notice constructor -> set owner to the person who deployed the contract
    constructor(address _dpkToken, address _priceConsumer) {
        owner = msg.sender;
        dpkToken = IERC20(_dpkToken);
        priceConsumer = PriceConsumerV3(_priceConsumer);
    }

    /// @param _token The address of any ERC-20 token 
    /// @return boolean value that indicates whether the token is a asset that our contract supports
    function inAssets(address _token) public view returns (bool) {
        for (uint i = 0; i < assets.length; i+=1) {
            if (assets[i] == _token) {
                return true;
            }
        }
        return false;
    }

    modifier isOwner {
        require(msg.sender == owner, "Only the owner is allowed to perform this operation");
        _;
    }

    modifier isAsset(address _token){
        require(inAssets(_token), "The token is not an asset that our contract supports");
        _;
    }

    /// @param _token the token has to be added to the list of assets
    /// @notice only the owner should be able to add a token to the assets list thats why we use the owner modifier  
    function addTokenToAssets(address _token) external isOwner{
        assets.push(_token);
    }

    /// @param _amount the amount of tokens that the user wants to stake
    /// @param _token The address of the ERC-20 token that the user wants to stake
    function stake(uint _amount, address _token) external payable isAsset(_token) {
        require(_amount > 0, "Amount must be greater than 0");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        if(stakedBalances[_token][msg.sender].amount == 0){
            distinctTokensStaked[msg.sender] += 1;
        }

        if(distinctTokensStaked[msg.sender] == 1){
            stakers.push(msg.sender);
        }

        stakedBalances[_token][msg.sender].investor = msg.sender;
        stakedBalances[_token][msg.sender].token = _token;
        stakedBalances[_token][msg.sender].amount += _amount;

        if (stakedBalances[_token][msg.sender].timestamp == 0){
            stakedBalances[_token][msg.sender].timestamp = block.timestamp;
        }

        stakedBalances[_token][msg.sender].staked = true;
        tokenBalances[_token] += _amount;
        string memory _symbol = ERC20(_token).symbol();
        emit Staked(msg.sender, block.timestamp, _amount, _symbol);
    }

    /// @param _token The address of the ERC-20 token that the user wants to unstake
    function unstake(address _token, uint amount) external isAsset(_token){
        require(stakedBalances[_token][msg.sender].amount > 0, "Balance must be greater than 0");
        require(stakedBalances[_token][msg.sender].amount >= amount , "The amount that you want to withdraw is to high");
        IERC20(_token).transfer(msg.sender, amount);
        stakedBalances[_token][msg.sender].amount = stakedBalances[_token][msg.sender].amount - amount;

        if (stakedBalances[_token][msg.sender].amount == 0){
            stakedBalances[_token][msg.sender].timestamp = 0;
            stakedBalances[_token][msg.sender].staked = false;
            stakedBalances[_token][msg.sender].token = address(0);
        }

        tokenBalances[_token] = tokenBalances[_token] - amount;
        string memory _symbol = ERC20(_token).symbol();
        emit Unstaked(msg.sender, block.timestamp, amount, _symbol);
    }


    /// @notice getter function to get all the assets that are supported by the smart contract
    function getAssets() public view returns (address[] memory) {
        return assets;
    }

    /// @notice reward is determined based on the amount of time that the user has staked (1 token = 5 mins)
    function claimRewards(address[] memory _tokens) external {
        for (uint i=0; i < _tokens.length; i+=1){
            uint reward;
            string memory _symbol = ERC20(_tokens[i]).symbol();
            Stake storage stakeStruct = stakedBalances[_tokens[i]][msg.sender];
            uint tokenAmount = stakeStruct.amount / 10**18;
            uint usdPrice = uint(priceConsumer.getLatestPriceOfToken(_symbol));
            uint multiplier = (tokenAmount * usdPrice) / 100; // 1 DPK token for each 100 USD staked

            if (stakeStruct.amount > 0 && stakeStruct.timestamp > 0) {
                reward = ((uint(block.timestamp - stakeStruct.timestamp) / uint(rewardPeriod)) * multiplier) * (10**18);
               
                if (reward > 0) {
                    if(dpkToken.transfer(msg.sender, reward)){
                        rewardsEarned[msg.sender] += reward;
                        // reset timestamp
                        stakeStruct.timestamp = block.timestamp;
                        stakedBalances[_tokens[i]][msg.sender] = stakeStruct;
                    }
                }   
            }
        }
    }

    /// @param _amount The amount that the issuer wants to get from his loan
    /// @param _token The address of the ERC-20 token that the issuer wants to get from his loan
    function takeLoan(uint _amount, address _token) external payable isAsset(_token){
        require(tokenBalances[_token] > _amount, "Insufficient liquidity for the token");
        require(loans[msg.sender][_token].amount == 0, "You already have a loan");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        IERC20(_token).transfer(msg.sender, _amount);
        uint intrest = (_amount / 100) * 5;
        uint duration = 120;
        Loan memory loan = Loan(msg.sender, _token, intrest, _amount, duration, block.timestamp);
        loans[msg.sender][_token] = loan;
        lockedAssets[msg.sender][_token] += _amount;
        tokenBalances[_token] = tokenBalances[_token] - _amount;
        emit Borrowed(msg.sender, block.timestamp, _amount, ERC20(_token).symbol());
    }

    function repayLoan(address _token) external payable isAsset(_token){
        require(loans[msg.sender][_token].amount > 0, "You do not have a loan");
        string memory _symbol = ERC20(_token).symbol();

        if (block.timestamp > (loans[msg.sender][_token].timestamp + loans[msg.sender][_token].duration)){
            // take colleteral from him because he couldn't pay the loan in time
            tokenBalances[_token] += lockedAssets[msg.sender][_token];
            emit Repaid(msg.sender, lockedAssets[msg.sender][_token], false, block.timestamp, _symbol);
            lockedAssets[msg.sender][_token] = 0;

            // also take the rewards that he got on the locked assets
            lockedRewards[msg.sender][_token] = 0;
        }

        else {
            uint total = loans[msg.sender][_token].amount + loans[msg.sender][_token].intrest;
            IERC20(_token).transferFrom(msg.sender, address(this), total);
            tokenBalances[_token] += lockedAssets[msg.sender][_token];
            
            // calculate yield on the locked assets
            uint usdPrice = uint(priceConsumer.getLatestPriceOfToken(_symbol));
            uint tokenAmount = lockedAssets[msg.sender][_token] / 10**18;
            uint multiplier = (tokenAmount * usdPrice) / 100; // 1 DPK token for each 100 USD staked

            uint rewardsForLockedAssets = ((uint(block.timestamp - loans[msg.sender][_token].timestamp) / uint(rewardPeriod)) * multiplier) * (10**18);

            // add lockedRewards
            if(rewardsForLockedAssets > 0){
                lockedRewards[msg.sender][_token] += rewardsForLockedAssets;
            }

            if(IERC20(_token).transfer(msg.sender, lockedAssets[msg.sender][_token])){
                lockedAssets[msg.sender][_token] = 0;
            }

            // pay the rewards that he got on the locked assets
            if(lockedRewards[msg.sender][_token] > 0){
                if(IERC20(dpkToken).transfer(msg.sender, lockedRewards[msg.sender][_token])){
                    lockedRewards[msg.sender][_token] = 0;
                }
            }

            emit Repaid(msg.sender, total, true, block.timestamp, _symbol);
        }

        // reset loan
        Loan memory l = loans[msg.sender][_token];
        l.issuer = address(0);
        l.amount = 0;
        l.intrest = 0;
        l.duration = 0;
        l.timestamp = 0;
        l.token = address(0);

        loans[msg.sender][_token] = l;
    }
}