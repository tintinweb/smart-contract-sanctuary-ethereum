// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


import "./ERC20MintableBurnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract JeDAO is ReentrancyGuard {
    address public chairman;
    uint256 private _minQuorum;
    uint256 private _debatePeriod;
    uint256 private _proposalID;
    ERC20MintableBurnable private _voteToken;

    struct Proposal {
        uint256 finishTime; 
        uint256 votesFor;
        uint256 votesAgainst;
        address recipient;
        bytes callData;
        string description;
    }

    struct Voter {
        uint256 deposit;
        uint256 withdrawTime;
        mapping(uint256 => uint256) votedAmount;
    }
    
    mapping(uint256 => Proposal) private _proposals;
    mapping(address => Voter) private _voters;


    constructor(
        address chairPerson,
        address voteToken,
        uint256 minimumQuorum,
        uint256 debatingPeriodDuration
    ) {
        chairman = chairPerson;
        _voteToken = ERC20MintableBurnable(voteToken);
        _minQuorum = minimumQuorum;
        _debatePeriod = debatingPeriodDuration;
    }


    modifier onlyChairman {
       require(msg.sender == chairman, "Chairman only");
       _;
    }


    function addProposal(
        bytes memory callData,
        address _recipient,
        string memory description
    ) external onlyChairman returns(uint256) {
        Proposal storage newProposal = _proposals[_proposalID];
        _proposalID++;

        newProposal.finishTime = block.timestamp + _debatePeriod;
        newProposal.recipient = _recipient;
        newProposal.callData = callData;
        newProposal.description = description;

        return _proposalID;
    }


    function vote(
        uint256 proposalID,
        uint256 amount,
        bool isVoteFor
    ) external returns(bool) {
        Proposal storage proposal = _proposals[proposalID];
        Voter storage voter = _voters[msg.sender];

        require(proposal.finishTime > 0, "Proposal is not active");
        require(voter.deposit - voter.votedAmount[proposalID] >= amount, "Not enough tokens");

        if(isVoteFor) {
            proposal.votesFor += amount;
            voter.votedAmount[proposalID] += amount;
        } else {
            proposal.votesAgainst += amount;
            voter.votedAmount[proposalID] += amount;
        }

        if(voter.withdrawTime < proposal.finishTime) {
            voter.withdrawTime = proposal.finishTime;
        }

        return true;
    }

    function finishProposal(uint256 proposalID) external returns(bool) {
        Proposal storage proposal = _proposals[proposalID];
        require(block.timestamp >= proposal.finishTime, "Proposal is not finished");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes >= _minQuorum, "Not enough votes");

        if(proposal.votesFor > proposal.votesAgainst) {
            (bool success, ) = proposal.recipient.call{value: 0}
                (proposal.callData);

             require(success, "Operation failed");
        }

        proposal.finishTime = 0;

        return true;
    }


    function deposit(uint256 amount) external returns(bool) {
        _voteToken.transferFrom(msg.sender, address(this), amount);
        _voters[msg.sender].deposit += amount;

        return true;
    }
    

    function withdraw(uint256 amount) external nonReentrant returns(bool) {
        Voter storage voter = _voters[msg.sender];

        require(block.timestamp >= voter.withdrawTime, "Can't withdraw yet");
        require(voter.deposit >= amount, "Not enough tokens");

        _voteToken.transfer(msg.sender, amount);
        voter.deposit -= amount;

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title ERC20 token contract with EIP20 compatibility
/// @author Omur Kubanychbekov
/// @notice You can use this contract for make your own ERC20 token
/// @dev All functions tested successfully and have no errors

contract ERC20MintableBurnable is Ownable, AccessControl {
   address private _owner;
   address private _comissionReciever;
   string public name;
   string public symbol;
   uint256 public totalSupply;
   uint256 private _comission;
   uint8 public decimals;

   bytes32 public constant MINTER_BURNER = keccak256("MINTER_BURNER");

   modifier onlyMinterBurner {
       require(hasRole(MINTER_BURNER, msg.sender), "Caller is not a minter");
       _;
   }

   function setMinterBurner(address minter) external onlyOwner returns(bool) {
       _setupRole(MINTER_BURNER, minter);

       return true;
   }
   
   mapping(address => bool) private _isDex;
   mapping(address => uint256) private _balances;
   mapping(address => mapping(address => uint256)) private _allowances;

   /// @notice Deploys the contract with the initial parameters(name, symbol, initial supply, decimals)
   /// @dev Constructor should be used when deploying contract,
   /// owner is the address that deploys the contract
   /// @param _name Name of the token
   /// @param _symbol Symbol of the token
   /// @param _initialSupply Initial supply of the token,
   /// may be changed later with `mint` or 'burn' function
   /// @param _decimals The number of decimals used by the token
   constructor(
      string memory _name,
      string memory _symbol,
      uint256 _initialSupply,
      uint8 _decimals
   ) {
      _owner = msg.sender;

      name = _name;
      symbol = _symbol;
      totalSupply = _initialSupply;
      decimals = _decimals;

      _balances[_owner] += _initialSupply;
   }

   /// @dev Modifier for functions 'mint' and 'burn',
   /// that can only be called by the owner of the contract
   modifier ownerOnly {
        require (
            msg.sender == _owner, "Permission denied"
        );
        _;
    }

   /// @notice Event that notices about transfer operations
   event Transfer(address indexed _from, address indexed _to, uint256 _value);

   /// @notice Event that notices about approval operations
   event Approval(address indexed _owner, address indexed _spender, uint256 _value);


   /// @notice Function that returns token balance in exact address
   /// @param _of Address of the token holder
   /// @return amount of the token in numbers
   function balanceOf(address _of) external view returns(uint256) {
      return _balances[_of];
   }

   /// @notice Function that allows to transfer tokens from one address to another
   /// @param _spender Address who can spend the tokens
   /// @param _value Amount of tokens to allow
   /// @return true if transaction is successful
   function approve(address _spender, uint256 _value) external returns(bool) {
      require(_balances[msg.sender] >= _value, "Not enough token");

      _allowances[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);

      return true;
   }

   /// @notice Function that allows to transfer tokens from one address to another
   /// Secure version of the function, that checks the current allowance of the spender
   /// @param _spender Address who can spend the tokens
   /// @param _currentValue Current allowance of the spender
   /// @param _value Amount of new tokens to allow
   /// @return true if transaction is successful
   function safeApprove(
      address _spender,
      uint256 _currentValue,
      uint256 _value
   ) external returns(bool) {
      require(_balances[msg.sender] >= _value, "Not enough token");
      require(_allowances[msg.sender][_spender] == _currentValue,
         "Old allowance was transfered!");

      _allowances[msg.sender][_spender] = _value;
      emit Approval(msg.sender, _spender, _value);

      return true;
   }

   /// @notice Function that returns the amount of tokens,
   /// that are allowed to be spent by the spender from _of address
   /// @param _of Address of the token allower
   /// @param _spender Address who can spend the tokens
   /// @return amount of the tokens allowed to spend
   function allowance(address _of, address _spender) external view returns(uint256) {
      return _allowances[_of][_spender];
   }

   /// @notice Function that transfers tokens from caller to another address
   /// If _to is a Dex address, it takes _comission and sends amount to _comissionReciever
   /// @param _to Address of the reciever
   /// @param _value Amount of tokens to transfer
   /// @return true if transaction is successful
   function transfer(address _to, uint256 _value) external returns(bool) {
      require(_balances[msg.sender] >= _value, "Not enough token");
    
      _balances[msg.sender] -= _value;

      if (_isDex[_to]) {
          uint256 comission = (_value / 100) * _comission;
          _balances[_to] += _value - comission;
          _balances[_comissionReciever] += comission;
          emit Transfer(msg.sender, _to, _value - comission);
      } else {
          _balances[_to] += _value;
          emit Transfer(msg.sender, _to, _value);
      }

      return true;
   }

   /// @notice Function that transfers tokens from one address to another
   /// Caller must have allowance to spend the tokens from _from address
   /// If _to is a Dex address, it takes _comission and sends amount to _comissionReciever
   /// @param _from Address spend the tokens from
   /// @param _to Address of the reciever
   /// @param _value Amount of tokens to transfer
   /// @return true if transaction is successful
   function transferFrom(
      address _from,
      address _to,
      uint256 _value
   ) external returns(bool) {
      require(_allowances[_from][msg.sender] >= _value, "Allowance is not enough");
      require(_balances[_from] >= _value, "Balance is not enough");

      _balances[_from] -= _value;
      _allowances[_from][msg.sender] -= _value;

      if (_isDex[_to]) {
          uint256 comission = (_value / 100) * _comission;
          _balances[_to] += _value - comission;
          _balances[_comissionReciever] += comission;
          emit Transfer(_from, _to, _value - comission);
      } else {
          _balances[_to] += _value;
          emit Transfer(_from, _to, _value);
      }

      return true;
   }

   /// @notice Function that adds new tokens to _to address
   /// @dev totalSupply is increased by _value
   /// @param _to Address of the reciever
   /// @param _value Amount of tokens to mint
   /// @return true if transaction is successful
   function mint(address _to, uint256 _value) external onlyMinterBurner returns(bool) {
      _balances[_to] += _value;
      totalSupply += _value;
      emit Transfer(address(0), _to, _value);
      
      return true;
   }

   /// @notice Function that burns tokens from _of address
   /// @dev totalSupply is decreased by _value
   /// @param _of Address of the spender
   /// @param _value Amount of tokens to burn
   /// @return true if transaction is successful
   function burn(address _of, uint256 _value) external onlyMinterBurner returns(bool) {
      require(_balances[_of] >= _value, "Not enough token");

      _balances[_of] -= _value;
      totalSupply -= _value;
      emit Transfer(_of, address(0), _value);

      return true;
   }

   /// @notice Function that sets Treasury Reciever address
   /// @param _reciever Address of the comission reciever
   /// @return true if transaction is successful
   function setReciever(address _reciever) external ownerOnly returns(bool) {
       _comissionReciever = _reciever;

       return true;
   }

   /// @notice Function that sets percent amount of comission
   /// @param _value Percent amount between 1 and 99
   /// @return true if transaction is successful
   function setComission(uint256 _value) external ownerOnly returns(bool) {
       require(_value > 0 && _value < 100, "Enter right percent");

       _comission = _value;

       return true;
   }

   /// @notice Function that adds address of new Dex
   /// @param _dex Address of the Dex
   /// @return true if transaction is successful 
   function addDex(address _dex) external ownerOnly returns(bool) {
       require(_dex != address(0), "Zero address cant be added");

       _isDex[_dex] = true;

       return true;
   }

   /// @notice Function that removes added address of Dex
   /// @param _dex Address of the Dex
   /// @return true if transaction is successful  
   function removeDex(address _dex) external ownerOnly returns(bool) {
       _isDex[_dex] = false;

       return true;
   }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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