/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/ISPMigratable.sol


pragma solidity 0.8.6;

interface ISPMigratable {
  function prepForMigrationOf(uint256 _projectId, address _from) external;
}

// File: contracts/structs/SPOperatorData.sol


pragma solidity 0.8.6;

/** 
  @member operator The address of the operator.
  @member domain The domain within which the operator is being given permissions. A domain of 0 is a wildcard domain, which gives an operator access to all domains.
  @member permissionIndexes The indexes of the permissions the operator is being given.
*/
struct SPOperatorData {
  address operator;
  uint256 domain;
  uint256[] permissionIndexes;
}

// File: contracts/interfaces/ISPOperatorStore.sol


pragma solidity 0.8.6;


interface ISPOperatorStore {
  event SetOperator(
    address indexed operator,
    address indexed account,
    uint256 indexed domain,
    uint256[] permissionIndexes,
    uint256 packed
  );

  function permissionsOf(
    address _operator,
    address _account,
    uint256 _domain
  ) external view returns (uint256);

  function hasPermission(
    address _operator,
    address _account,
    uint256 _domain,
    uint256 _permissionIndex
  ) external view returns (bool);

  function hasPermissions(
    address _operator,
    address _account,
    uint256 _domain,
    uint256[] calldata _permissionIndexes
  ) external view returns (bool);

  function setOperator(SPOperatorData calldata _operatorData) external;

  function setOperators(SPOperatorData[] calldata _operatorData) external;
}

// File: contracts/interfaces/ISPOperatable.sol


pragma solidity 0.8.6;


interface ISPOperatable {
  function operatorStore() external view returns (ISPOperatorStore);
}

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


pragma solidity 0.8.6;

struct SPProjectMetadata {
  uint256 totalPrice;
  uint256 tokenPrice;
  string propertyAddress;
  string ipfsDomain;
}

// File: contracts/interfaces/ISPProjects.sol


pragma solidity 0.8.6;


interface ISPProjects {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    SPProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, SPProjectMetadata metadata, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function createFor(address _owner, SPProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, SPProjectMetadata calldata _metadata) external;
}

// File: contracts/interfaces/ISPTokenStore.sol


pragma solidity 0.8.6;



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
    bool tokensWereClaimed,
    bool preferClaimedTokens,
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

  function changeFor(
    uint256 _projectId,
    ISPToken _token,
    address _newOwner
  ) external returns (ISPToken oldToken);

  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function shouldRequireClaimingFor(uint256 _projectId, bool _flag) external;

  function claimFor(
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: contracts/interfaces/ISPPaymentTerminal.sol


pragma solidity 0.8.6;


interface ISPPaymentTerminal is IERC165 {
  function acceptsToken(address _token, uint256 _projectId) external view returns (bool);

  function currencyForToken(address _token) external view returns (uint256);

  function decimalsForToken(address _token) external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}

// File: contracts/interfaces/ISPDirectory.sol


pragma solidity 0.8.6;

//import './ISPFundingCycleStore.sol';



interface ISPDirectory {
  event SetController(uint256 indexed projectId, address indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, ISPPaymentTerminal indexed terminal, address caller);

  event SetTerminals(uint256 indexed projectId, ISPPaymentTerminal[] terminals, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    ISPPaymentTerminal indexed terminal,
    address caller
  );

  event SetIsAllowedToSetFirstController(address indexed addr, bool indexed flag, address caller);

  function projects() external view returns (ISPProjects);

  function controllerOf(uint256 _projectId) external view returns (address);

  function isAllowedToSetFirstController(address _address) external view returns (bool);

  function terminalsOf(uint256 _projectId) external view returns (ISPPaymentTerminal[] memory);

  function isTerminalOf(uint256 _projectId, ISPPaymentTerminal _terminal)
    external
    view
    returns (bool);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (ISPPaymentTerminal);

  function setControllerOf(uint256 _projectId, address _controller) external;

  function setTerminalsOf(uint256 _projectId, ISPPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(
    uint256 _projectId,
    address _token,
    ISPPaymentTerminal _terminal
  ) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// File: contracts/interfaces/ISPController.sol


pragma solidity 0.8.6;







interface ISPController is IERC165 {
  event LaunchProject(uint256 projectId, address caller);

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    address caller
  );

  function projects() external view returns (ISPProjects);

  function tokenStore() external view returns (ISPTokenStore);

  function directory() external view returns (ISPDirectory);

  function launchProjectFor(
    address _owner,
    SPProjectMetadata calldata _projectMetadata,
    ISPPaymentTerminal[] memory _terminal
  ) external returns (uint256 projectId);

  function issueTokenFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (ISPToken token);
  
  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    bool _preferClaimedTokens
  ) external returns (uint256 beneficiaryTokenCount);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: contracts/SPController.sol


pragma solidity 0.8.6;








/**
  @notice
  Stitches together funding cycles and community tokens, making sure all activity is accounted for and correct.

  @dev
  Adheres to -
  ISPController: General interface for the generic controller methods in this contract that interacts with funding cycles and tokens according to the protocol's rules.
  ISPMigratable: Allows migrating to this contract, with a hook called to prepare for the migration.

  @dev
  Inherits from -
  SPOperatable: Several functions in this contract can only be accessed by a project owner, or an address that has been preconfifigured to be an operator of the project.
  ERC165: Introspection on interface adherance. 
*/
contract SPController is ISPController, ERC165 {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error BURN_PAUSED_AND_SENDER_NOT_VALID_TERMINAL_DELEGATE();
  error CANT_MIGRATE_TO_CURRENT_CONTROLLER();
  error CHANGE_TOKEN_NOT_ALLOWED();
  error FUNDING_CYCLE_ALREADY_LAUNCHED();
  error INVALID_BALLOT_REDEMPTION_RATE();
  error INVALID_DISTRIBUTION_LIMIT();
  error INVALID_DISTRIBUTION_LIMIT_CURRENCY();
  error INVALID_OVERFLOW_ALLOWANCE();
  error INVALID_OVERFLOW_ALLOWANCE_CURRENCY();
  error INVALID_REDEMPTION_RATE();
  error INVALID_RESERVED_RATE();
  error MIGRATION_NOT_ALLOWED();
  error MINT_NOT_ALLOWED_AND_NOT_TERMINAL_DELEGATE();
  error NO_BURNABLE_TOKENS();
  error NOT_CURRENT_CONTROLLER();
  error ZERO_TOKENS_TO_MINT();

  //*********************************************************************//
  // --------------------- internal stored properties ------------------ //
  //*********************************************************************//

  //*********************************************************************//
  // --------------- public immutable stored properties ---------------- //
  //*********************************************************************//

  ISPProjects public immutable override projects;

  /**
    @notice
    The contract that manages token minting and burning.
  */
  ISPTokenStore public immutable override tokenStore;

  ISPDirectory public immutable override directory;
  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  //*********************************************************************//
  // -------------------------- public views --------------------------- //
  //*********************************************************************//

  /**
    @notice
    Indicates if this contract adheres to the specified interface.

    @dev 
    See {IERC165-supportsInterface}.

    @param _interfaceId The ID of the interface to check for adherance to.
  */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      _interfaceId == type(ISPController).interfaceId ||
      _interfaceId == type(ISPMigratable).interfaceId ||
      _interfaceId == type(ISPOperatable).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  //*********************************************************************//
  // ---------------------------- constructor -------------------------- //
  //*********************************************************************//

  /**
    @param _projects A contract which mints ERC-721's that represent project ownership and transfers.
    @param _directory A contract storing directories of terminals and controllers for each project.
    @param _tokenStore A contract that manages token minting and burning.
  */
  constructor(
    ISPProjects _projects,
    ISPDirectory _directory,
    ISPTokenStore _tokenStore
  ) {
    projects = _projects;
    directory = _directory;
    tokenStore = _tokenStore;
  }

  //*********************************************************************//
  // --------------------- external transactions ----------------------- //
  //*********************************************************************//

  /**
    @notice
    Creates a project. This will mint an ERC-721 into the specified owner's account, configure a first funding cycle, and set up any splits.

    @dev
    Each operation within this transaction can be done in sequence separately.

    @dev
    Anyone can deploy a project on an owner's behalf.

    @param _owner The address to set as the owner of the project. The project ERC-721 will be owned by this address.
    @param _projectMetadata Metadata to associate with the project within a particular domain. This can be updated any time by the owner of the project.
    @param _terminals Payment terminals to add for the project.

    @return projectId The ID of the project.
  */
  function launchProjectFor(
    address _owner,
    SPProjectMetadata calldata _projectMetadata,
    ISPPaymentTerminal[] memory _terminals
  ) external virtual override returns (uint256 projectId) {
    // Mint the project into the wallet of the message sender.
    projectId = projects.createFor(_owner, _projectMetadata);

    // Set this contract as the project's controller in the directory.
    directory.setControllerOf(projectId, address(this));

    // Add the provided terminals to the list of terminals.
    if (_terminals.length > 0) directory.setTerminalsOf(projectId, _terminals);

    emit LaunchProject(projectId, msg.sender);
  }

  /**
    @notice
    Issues an owner's ERC20 SPTokens that'll be used when claiming tokens.

    @dev
    Deploys a project's ERC20 SPToken contract.

    @dev
    Only a project's owner or operator can issue its token.

    @param _projectId The ID of the project being issued tokens.
    @param _name The ERC20's name.
    @param _symbol The ERC20's symbol.
  */
  function issueTokenFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  )
    external
    virtual
    override
    returns (ISPToken token)
  {
    // Issue the token in the store.
    return tokenStore.issueFor(_projectId, _name, _symbol);
  }

  /**
    @notice
    Mint new token supply into an account, and optionally reserve a supply to be distributed according to the project's current funding cycle configuration.

    @dev
    Only a project's owner, a designated operator, one of its terminals, or the current data source can mint its tokens.

    @param _projectId The ID of the project to which the tokens being minted belong.
    @param _tokenCount The amount of tokens to mint in total, counting however many should be reserved.
    @param _beneficiary The account that the tokens are being minted for.
    @param _preferClaimedTokens A flag indicating whether a project's attached token contract should be minted if they have been issued.

    @return beneficiaryTokenCount The amount of tokens minted for the beneficiary.
  */
  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    bool _preferClaimedTokens
  ) external virtual override returns (uint256 beneficiaryTokenCount) {
    // There should be tokens to mint.
    if (_tokenCount == 0) revert ZERO_TOKENS_TO_MINT();

    beneficiaryTokenCount = _tokenCount;
    tokenStore.mintFor(_beneficiary, _projectId, beneficiaryTokenCount, _preferClaimedTokens);

    emit MintTokens(
      _beneficiary,
      _projectId,
      _tokenCount,
      beneficiaryTokenCount,
      msg.sender
    );
  }
}