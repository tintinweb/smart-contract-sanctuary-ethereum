/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// File: contracts/AvastarTypes.sol

pragma solidity 0.5.14;

/**
 * @title Avastar Data Types
 * @author Cliff Hall
 */
contract AvastarTypes {

    enum Generation {
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }

    enum Series {
        PROMO,
        ONE,
        TWO,
        THREE,
        FOUR,
        FIVE
    }

    enum Wave {
        PRIME,
        REPLICANT
    }

    enum Gene {
        SKIN_TONE,
        HAIR_COLOR,
        EYE_COLOR,
        BG_COLOR,
        BACKDROP,
        EARS,
        FACE,
        NOSE,
        MOUTH,
        FACIAL_FEATURE,
        EYES,
        HAIR_STYLE
    }

    enum Gender {
        ANY,
        MALE,
        FEMALE
    }

    enum Rarity {
        COMMON,
        UNCOMMON,
        RARE,
        EPIC,
        LEGENDARY
    }

    struct Trait {
        uint256 id;
        Generation generation;
        Gender gender;
        Gene gene;
        Rarity rarity;
        uint8 variation;
        Series[] series;
        string name;
        string svg;

    }

    struct Prime {
        uint256 id;
        uint256 serial;
        uint256 traits;
        bool[12] replicated;
        Generation generation;
        Series series;
        Gender gender;
        uint8 ranking;
    }

    struct Replicant {
        uint256 id;
        uint256 serial;
        uint256 traits;
        Generation generation;
        Gender gender;
        uint8 ranking;
    }

    struct Avastar {
        uint256 id;
        uint256 serial;
        uint256 traits;
        Generation generation;
        Wave wave;
    }

    struct Attribution {
        Generation generation;
        string artist;
        string infoURI;
    }

}

// File: contracts/IAvastarTeleporter.sol

pragma solidity 0.5.14;


/**
 * @title AvastarTeleporter Interface
 * @author Cliff Hall
 * @notice Declared as abstract contract rather than interface as it must inherit for enum types.
 * Used by AvastarMinter contract to interact with subset of AvastarTeleporter contract functions.
 */
contract IAvastarTeleporter is AvastarTypes {

    /**
     * @notice Acknowledge contract is `AvastarTeleporter`
     * @return always true if the contract is in fact `AvastarTeleporter`
     */
    function isAvastarTeleporter() external pure returns (bool);

    /**
     * @notice Get token URI for a given Avastar Token ID.
     * Reverts if given token id is not a valid Avastar Token ID.
     * @param _tokenId the Token ID of a previously minted Avastar Prime or Replicant
     * @return uri the off-chain URI to the JSON metadata for the given Avastar
     */
    function tokenURI(uint _tokenId)
    external view
    returns (string memory uri);

    /**
     * @notice Get an Avastar's Wave by token ID.
     * @param _tokenId the token id of the given Avastar
     * @return wave the Avastar's wave (Prime/Replicant)
     */
    function getAvastarWaveByTokenId(uint256 _tokenId)
    external view
    returns (Wave wave);

    /**
     * @notice Get the Avastar Prime metadata associated with a given Token ID.
     * @param _tokenId the Token ID of the specified Prime
     * @return tokenId the Prime's token ID
     * @return serial the Prime's serial
     * @return traits the Prime's trait hash
     * @return generation the Prime's generation
     * @return series the Prime's series
     * @return gender the Prime's gender
     * @return ranking the Prime's ranking
     */
    function getPrimeByTokenId(uint256 _tokenId)
    external view
    returns (
        uint256 tokenId,
        uint256 serial,
        uint256 traits,
        Generation generation,
        Series series,
        Gender gender,
        uint8 ranking
    );

    /**
     * @notice Get the Avastar Replicant metadata associated with a given Token ID
     * @param _tokenId the token ID of the specified Replicant
     * @return tokenId the Replicant's token ID
     * @return serial the Replicant's serial
     * @return traits the Replicant's trait hash
     * @return generation the Replicant's generation
     * @return gender the Replicant's gender
     * @return ranking the Replicant's ranking
     */
    function getReplicantByTokenId(uint256 _tokenId)
    external view
    returns (
        uint256 tokenId,
        uint256 serial,
        uint256 traits,
        Generation generation,
        Gender gender,
        uint8 ranking
    );

    /**
     * @notice Retrieve a Trait's info by ID.
     * @param _traitId the ID of the Trait to retrieve
     * @return id the ID of the trait
     * @return generation generation of the trait
     * @return series list of series the trait may appear in
     * @return gender gender(s) the trait is valid for
     * @return gene gene the trait belongs to
     * @return variation variation of the gene the trait represents
     * @return rarity the rarity level of this trait
     * @return name name of the trait
     */
    function getTraitInfoById(uint256 _traitId)
    external view
    returns (
        uint256 id,
        Generation generation,
        Series[] memory series,
        Gender gender,
        Gene gene,
        Rarity rarity,
        uint8 variation,
        string memory name
    );


    /**
     * @notice Retrieve a Trait's name by ID.
     * @param _traitId the ID of the Trait to retrieve
     * @return name name of the trait
     */
    function getTraitNameById(uint256 _traitId)
    external view
    returns (string memory name);

    /**
     * @notice Get Trait ID by Generation, Gene, and Variation.
     * @param _generation the generation the trait belongs to
     * @param _gene gene the trait belongs to
     * @param _variation the variation of the gene
     * @return traitId the ID of the specified trait
     */
    function getTraitIdByGenerationGeneAndVariation(
        Generation _generation,
        Gene _gene,
        uint8 _variation
    )
    external view
    returns (uint256 traitId);

    /**
     * @notice Get the artist Attribution for a given Generation, combined into a single string.
     * @param _generation the generation to retrieve artist attribution for
     * @return attribution a single string with the artist and artist info URI
     */
    function getAttributionByGeneration(Generation _generation)
    external view
    returns (
        string memory attribution
    );

    /**
     * @notice Mint an Avastar Prime
     * Only invokable by minter role, when contract is not paused.
     * If successful, emits a `NewPrime` event.
     * @param _owner the address of the new Avastar's owner
     * @param _traits the new Prime's trait hash
     * @param _generation the new Prime's generation
     * @return _series the new Prime's series
     * @param _gender the new Prime's gender
     * @param _ranking the new Prime's rarity ranking
     * @return tokenId the newly minted Prime's token ID
     * @return serial the newly minted Prime's serial
     */
    function mintPrime(
        address _owner,
        uint256 _traits,
        Generation _generation,
        Series _series,
        Gender _gender,
        uint8 _ranking
    )
    external
    returns (uint256, uint256);

    /**
     * @notice Mint an Avastar Replicant.
     * Only invokable by minter role, when contract is not paused.
     * If successful, emits a `NewReplicant` event.
     * @param _owner the address of the new Avastar's owner
     * @param _traits the new Replicant's trait hash
     * @param _generation the new Replicant's generation
     * @param _gender the new Replicant's gender
     * @param _ranking the new Replicant's rarity ranking
     * @return tokenId the newly minted Replicant's token ID
     * @return serial the newly minted Replicant's serial
     */
    function mintReplicant(
        address _owner,
        uint256 _traits,
        Generation _generation,
        Gender _gender,
        uint8 _ranking
    )
    external
    returns (uint256, uint256);

    /**
     * Gets the owner of the specified token ID.
     * @param tokenId the token ID to search for the owner of
     * @return owner the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Gets the total amount of tokens stored by the contract.
     * @return count total number of tokens
     */
    function totalSupply() public view returns (uint256 count);
}

// File: @openzeppelin/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/AccessControl.sol

pragma solidity 0.5.14;



/**
 * @title Access Control
 * @author Cliff Hall
 * @notice Role-based access control and contract upgrade functionality.
 */
contract AccessControl {

    using SafeMath for uint256;
    using SafeMath for uint16;
    using Roles for Roles.Role;

    Roles.Role private admins;
    Roles.Role private minters;
    Roles.Role private owners;

    /**
     * @notice Sets `msg.sender` as system admin by default.
     * Starts paused. System admin must unpause, and add other roles after deployment.
     */
    constructor() public {
        admins.add(msg.sender);
    }

    /**
     * @notice Emitted when contract is paused by system administrator.
     */
    event ContractPaused();

    /**
     * @notice Emitted when contract is unpaused by system administrator.
     */
    event ContractUnpaused();

    /**
     * @notice Emitted when contract is upgraded by system administrator.
     * @param newContract address of the new version of the contract.
     */
    event ContractUpgrade(address newContract);


    bool public paused = true;
    bool public upgraded = false;
    address public newContractAddress;

    /**
     * @notice Modifier to scope access to minters
     */
    modifier onlyMinter() {
        require(minters.has(msg.sender));
        _;
    }

    /**
     * @notice Modifier to scope access to owners
     */
    modifier onlyOwner() {
        require(owners.has(msg.sender));
        _;
    }

    /**
     * @notice Modifier to scope access to system administrators
     */
    modifier onlySysAdmin() {
        require(admins.has(msg.sender));
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @notice Modifier to make a function callable only when the contract not upgraded.
     */
    modifier whenNotUpgraded() {
        require(!upgraded);
        _;
    }

    /**
     * @notice Called by a system administrator to  mark the smart contract as upgraded,
     * in case there is a serious breaking bug. This method stores the new contract
     * address and emits an event to that effect. Clients of the contract should
     * update to the new contract address upon receiving this event. This contract will
     * remain paused indefinitely after such an upgrade.
     * @param _newAddress address of new contract
     */
    function upgradeContract(address _newAddress) external onlySysAdmin whenPaused whenNotUpgraded {
        require(_newAddress != address(0));
        upgraded = true;
        newContractAddress = _newAddress;
        emit ContractUpgrade(_newAddress);
    }

    /**
     * @notice Called by a system administrator to add a minter.
     * Reverts if `_minterAddress` already has minter role
     * @param _minterAddress approved minter
     */
    function addMinter(address _minterAddress) external onlySysAdmin {
        minters.add(_minterAddress);
        require(minters.has(_minterAddress));
    }

    /**
     * @notice Called by a system administrator to add an owner.
     * Reverts if `_ownerAddress` already has owner role
     * @param _ownerAddress approved owner
     * @return added boolean indicating whether the role was granted
     */
    function addOwner(address _ownerAddress) external onlySysAdmin {
        owners.add(_ownerAddress);
        require(owners.has(_ownerAddress));
    }

    /**
     * @notice Called by a system administrator to add another system admin.
     * Reverts if `_sysAdminAddress` already has sysAdmin role
     * @param _sysAdminAddress approved owner
     */
    function addSysAdmin(address _sysAdminAddress) external onlySysAdmin {
        admins.add(_sysAdminAddress);
        require(admins.has(_sysAdminAddress));
    }

    /**
     * @notice Called by an owner to remove all roles from an address.
     * Reverts if address had no roles to be removed.
     * @param _address address having its roles stripped
     */
    function stripRoles(address _address) external onlyOwner {
        require(msg.sender != _address);
        bool stripped = false;
        if (admins.has(_address)) {
            admins.remove(_address);
            stripped = true;
        }
        if (minters.has(_address)) {
            minters.remove(_address);
            stripped = true;
        }
        if (owners.has(_address)) {
            owners.remove(_address);
            stripped = true;
        }
        require(stripped == true);
    }

    /**
     * @notice Called by a system administrator to pause, triggers stopped state
     */
    function pause() external onlySysAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @notice Called by a system administrator to un-pause, returns to normal state
     */
    function unpause() external onlySysAdmin whenPaused whenNotUpgraded {
        paused = false;
        emit ContractUnpaused();
    }

}

// File: contracts/AvastarPrimeMinter.sol

pragma solidity 0.5.14;




/**
 * @title Avastar Prime Minter Proxy
 * @author Cliff Hall
 * @notice Mints Avastar Primes using the `AvastarTeleporter` contract on behalf of depositors.
 * Allows system admin to set current generation and series.
 * Manages accounting of depositor and franchise balances.
 */
contract AvastarPrimeMinter is AvastarTypes, AccessControl {

    /**
     * @notice Event emitted when the current Generation is changed
     * @param currentGeneration the new value of currentGeneration
     */
    event CurrentGenerationSet(Generation currentGeneration);

    /**
     * @notice Event emitted when the current Series is changed
     * @param currentSeries the new value of currentSeries
     */
    event CurrentSeriesSet(Series currentSeries);

    /**
     * @notice Event emitted when ETH is deposited or withdrawn by a depositor
     * @param depositor the address who deposited or withdrew ETH
     * @param balance the depositor's resulting ETH balance in the contract
     */
    event DepositorBalance(address indexed depositor, uint256 balance);

    /**
     * @notice Event emitted upon the withdrawal of the franchise's balance
     * @param owner the contract owner
     * @param amount total ETH withdrawn
     */
    event FranchiseBalanceWithdrawn(address indexed owner, uint256 amount);

    /**
     * @notice Event emitted when AvastarTeleporter contract is set
     * @param contractAddress the address of the AvastarTeleporter contract
     */
    event TeleporterContractSet(address contractAddress);

    /**
     * @notice Address of the AvastarTeleporter contract
     */
    IAvastarTeleporter private teleporterContract ;

    /**
     * @notice The current Generation of Avastars being minted
     */
    Generation private currentGeneration;

    /**
     * @notice The current Series of Avastars being minted
     */
    Series private currentSeries;

    /**
     * @notice Track the deposits made by address
     */
    mapping (address => uint256) private depositsByAddress;

    /**
     * @notice Current total of unspent deposits by all depositors
     */
    uint256 private unspentDeposits;

    /**
     * @notice Set the address of the `AvastarTeleporter` contract.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * To be used if the Teleporter contract has to be upgraded and a new instance deployed.
     * If successful, emits an `TeleporterContractSet` event.
     * @param _address address of `AvastarTeleporter` contract
     */
    function setTeleporterContract(address _address) external onlySysAdmin whenPaused whenNotUpgraded {

        // Cast the candidate contract to the IAvastarTeleporter interface
        IAvastarTeleporter candidateContract = IAvastarTeleporter(_address);

        // Verify that we have the appropriate address
        require(candidateContract.isAvastarTeleporter());

        // Set the contract address
        teleporterContract = IAvastarTeleporter(_address);

        // Emit the event
        emit TeleporterContractSet(_address);
    }

    /**
     * @notice Set the Generation to be minted.
     * Resets `currentSeries` to `Series.ONE`.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * Emits `GenerationSet` event with new value of `currentGeneration`.
     * @param _generation the new value for currentGeneration
     */
    function setCurrentGeneration(Generation _generation) external onlySysAdmin whenPaused whenNotUpgraded {
        currentGeneration = _generation;
        emit CurrentGenerationSet(currentGeneration);
        setCurrentSeries(Series.ONE);
    }

    /**
     * @notice Set the Series to be minted.
     * Only invokable by system admin role, when contract is paused and not upgraded.
     * Emits `CurrentSeriesSet` event with new value of `currentSeries`.
     * @param _series the new value for currentSeries
     */
    function setCurrentSeries(Series _series) public onlySysAdmin whenPaused whenNotUpgraded {
        currentSeries = _series;
        emit CurrentSeriesSet(currentSeries);
    }

    /**
     * @notice Allow owner to check the withdrawable franchise balance.
     * Remaining balance must be enough for all unspent deposits to be withdrawn by depositors.
     * Invokable only by owner role.
     * @return franchiseBalance the available franchise balance
     */
    function checkFranchiseBalance() external view onlyOwner returns (uint256 franchiseBalance) {
        return uint256(address(this).balance).sub(unspentDeposits);
    }

    /**
     * @notice Allow an owner to withdraw the franchise balance.
     * Invokable only by owner role.
     * Entire franchise balance is transferred to `msg.sender`.
     * If successful, emits `FranchiseBalanceWithdrawn` event with amount withdrawn.
     * @return amountWithdrawn amount withdrawn
     */
    function withdrawFranchiseBalance() external onlyOwner returns (uint256 amountWithdrawn) {
        uint256 franchiseBalance = uint256(address(this).balance).sub(unspentDeposits);
        require(franchiseBalance > 0);
        msg.sender.transfer(franchiseBalance);
        emit FranchiseBalanceWithdrawn(msg.sender, franchiseBalance);
        return franchiseBalance;
    }

    /**
     * @notice Allow anyone to deposit ETH.
     * Before contract will mint on behalf of a user, they must have sufficient ETH on deposit.
     * Invokable by any address (other than 0) when contract is not paused.
     * Must have a non-zero ETH value.
     * If successful, emits a `DepositorBalance` event with depositor's resulting balance.
     */
    function deposit() external payable whenNotPaused {
        require(msg.value > 0);
        depositsByAddress[msg.sender] = depositsByAddress[msg.sender].add(msg.value);
        unspentDeposits = unspentDeposits.add(msg.value);
        emit DepositorBalance(msg.sender, depositsByAddress[msg.sender]);
    }

    /**
     * @notice Allow anyone to check their deposit balance.
     * Invokable by any address (other than 0).
     * @return the depositor's current ETH balance in the contract
     */
    function checkDepositorBalance() external view returns (uint256){
        return depositsByAddress[msg.sender];
    }

    /**
     * @notice Allow a depositor with a balance to withdraw it.
     * Invokable by any address (other than 0) with an ETH balance on deposit.
     * Entire depositor balance is transferred to `msg.sender`.
     * Emits `DepositorBalance` event of 0 amount once transfer is complete.
     * @return amountWithdrawn amount withdrawn
     */
    function withdrawDepositorBalance() external returns (uint256 amountWithdrawn) {
        uint256 depositorBalance = depositsByAddress[msg.sender];
        require(depositorBalance > 0 && address(this).balance >= depositorBalance);
        depositsByAddress[msg.sender] = 0;
        unspentDeposits = unspentDeposits.sub(depositorBalance);
        msg.sender.transfer(depositorBalance);
        emit DepositorBalance(msg.sender, 0);
        return depositorBalance;
    }

    /**
     * @notice Mint an Avastar Prime for a purchaser who has previously deposited funds.
     * Invokable only by minter role, when contract is not paused.
     * Minted token will be owned by `_purchaser` address.
     * If successful, emits a `DepositorBalance` event with the depositor's remaining balance,
     * and the `AvastarTeleporter` contract will emit a `NewPrime` event.
     * @param _purchaser address that will own the token
     * @param _price price in ETH of token, removed from purchaser's deposit balance
     * @param _traits the Avastar's Trait hash
     * @param _gender the Avastar's Gender
     * @param _ranking the Avastar's Ranking
     * @return tokenId the Avastar's tokenId
     * @return serial the Prime's serial
     */
    function purchasePrime(
        address _purchaser,
        uint256 _price,
        uint256 _traits,
        Gender _gender,
        uint8 _ranking
    )
    external
    onlyMinter
    whenNotPaused
    returns (uint256 tokenId, uint256 serial)
    {
        require(_purchaser != address(0));
        require (depositsByAddress[_purchaser] >= _price);
        require(_gender > Gender.ANY);
        depositsByAddress[_purchaser] = depositsByAddress[_purchaser].sub(_price);
        unspentDeposits = unspentDeposits.sub(_price);
        (tokenId, serial) = teleporterContract.mintPrime(_purchaser, _traits, currentGeneration, currentSeries, _gender, _ranking);
        emit DepositorBalance(_purchaser, depositsByAddress[_purchaser]);
        return (tokenId, serial);
    }

}