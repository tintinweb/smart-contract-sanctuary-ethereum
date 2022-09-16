/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// File: contracts/interfaces/ISPToken.sol

pragma solidity 0.8.6;

interface ISPToken {
  function decimals() external view returns (uint8);

  function totalSupply(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _account, uint256 _projectId) external view returns (uint256);

  function mint(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function burn(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function approve(
    uint256,
    address _spender,
    uint256 _amount
  ) external;

  function transfer(
    uint256 _projectId,
    address _to,
    uint256 _amount
  ) external;

  function transferFrom(
    uint256 _projectId,
    address _from,
    address _to,
    uint256 _amount
  ) external;

  function transferOwnership(uint256 _projectId, address _newOwner) external;
}

// File: contracts/structs/SPProjectMetadata.sol

struct SPProjectMetadata {
  uint256 totalPrice;
  uint256 tokenPrice;
  string propertyAddress;
  string ipfsDomain;
}

// File: contracts/interfaces/ISPProjects.sol

interface ISPProjects {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    SPProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, SPProjectMetadata metadata, address caller);

  function count() external view returns (uint256);

  function creators(uint256) external view returns (address);

  function crowdfundingAmount(uint256) external view returns (uint256);

  function crowdfundingEndState(uint256) external view returns (bool);

  function getMetadataOf(uint256 _projectId) external view returns (SPProjectMetadata memory meta);

  function createFor(address _owner, SPProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, SPProjectMetadata calldata _metadata) external;
}

// File: contracts/interfaces/ISPTokenStore.sol

interface ISPTokenStore {
  event Issue(
    uint256 indexed projectId,
    ISPToken indexed token,
    string name,
    string symbol,
    address caller
  );

  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 initialUnclaimedBalance,
    uint256 initialClaimedBalance,
    bool preferClaimedTokens,
    address caller
  );

  event Claim(
    address indexed holder,
    uint256 indexed projectId,
    uint256 initialUnclaimedBalance,
    uint256 amount,
    address caller
  );

  event ShouldRequireClaim(uint256 indexed projectId, bool indexed flag, address caller);

  event Change(
    uint256 indexed projectId,
    ISPToken indexed newToken,
    ISPToken indexed oldToken,
    address owner,
    address caller
  );

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (ISPToken);

  function projectOf(ISPToken _token) external view returns (uint256);

  function projects() external view returns (ISPProjects);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function requireClaimFor(uint256 _projectId) external view returns (bool);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (ISPToken token);

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function transferFrom(
    address _holder,
    uint256 _projectId,
    address _recipient,
    uint256 _amount
  ) external;
}

// File: contracts/interfaces/ISPPayer.sol

interface ISPPayer {
  event InvestedFunds(
    uint256 indexed funds
  );

  event Pay(
    uint256 mintTokenAmount,
    address caller
  );

  function store() external view returns (ISPTokenStore);
  
  function projects() external view returns (ISPProjects);

  function payments(uint256, address) external view returns (uint256);

  function paymentsOfHolders(address, uint256) external view returns (uint256);

  function pay(
    uint256 _projectId,
    address _token,
    uint256 _tokenPrice,
    uint256 _amount
  ) external;

  function investedFunds(
    uint256 _projectId,
    address _token
  ) external view returns (uint256 funds);

  function withdraw(uint256 _projectId, address _token, uint256 _amount) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: contracts/SPPayer.sol

contract SPPayer is ISPPayer {
  ISPTokenStore public immutable override store;
  ISPProjects public immutable override projects;

  mapping(uint256 => mapping(address => uint256)) public override payments;

  mapping(address => mapping(uint256 => uint256)) public override paymentsOfHolders;

  uint256 public decimals = 18;

  constructor(ISPTokenStore _store, ISPProjects _projects) {
    store = _store;
    projects = _projects;
  }

  function pay(uint256 _projectId, address _token, uint256 _tokenPrice, uint256 _amount) external override {
    require(!ISPProjects(projects).crowdfundingEndState(_projectId));
    uint256 mintTokenAmount = _amount / _tokenPrice;
    paymentsOfHolders[msg.sender][_projectId] = paymentsOfHolders[msg.sender][_projectId] + _amount;
    payments[_projectId][address(_token)] = payments[_projectId][address(_token)] + _amount;

    IERC20(_token).transferFrom(msg.sender, address(this), _amount * (10 ** decimals));
    store.mintFor(msg.sender, _projectId, mintTokenAmount * (10 ** decimals));
  }

  function investedFunds(uint256 _projectId, address _token) external view override returns (uint256 funds) {
    funds = payments[_projectId][_token];
    return funds;
  }

  function withdraw(uint256 _projectId, address _token, uint256 _amount) external override {
    require(ISPProjects(projects).creators(_projectId) == msg.sender, "You are not allowed to withdraw funds");
    require(payments[_projectId][address(_token)] >= _amount, "No enough funds!");
    IERC20(address(_token)).transfer(msg.sender, _amount * (10 ** decimals));
  }
}