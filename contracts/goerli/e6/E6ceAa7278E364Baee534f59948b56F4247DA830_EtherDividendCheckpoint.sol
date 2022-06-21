pragma solidity 0.5.8;

import "../DividendCheckpoint.sol";
import "../../../../interfaces/IOwnable.sol";

/**
 * @title Checkpoint module for issuing ether dividends
 */
contract EtherDividendCheckpoint is DividendCheckpoint {
    using SafeMath for uint256;

    event EtherDividendDeposited(
        address indexed _depositor,
        uint256 _checkpointId,
        uint256 _maturity,
        uint256 _expiry,
        uint256 _amount,
        uint256 _totalSupply,
        uint256 indexed _dividendIndex,
        bytes32 indexed _name
    );
    event EtherDividendClaimed(address indexed _payee, uint256 indexed _dividendIndex, uint256 _amount, uint256 _withheld);
    event EtherDividendReclaimed(address indexed _claimer, uint256 indexed _dividendIndex, uint256 _claimedAmount);
    event EtherDividendClaimFailed(address indexed _payee, uint256 indexed _dividendIndex, uint256 _amount, uint256 _withheld);
    event EtherDividendWithholdingWithdrawn(address indexed _claimer, uint256 indexed _dividendIndex, uint256 _withheldAmount);

    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     */
    constructor(address _securityToken, address _polyToken) public Module(_securityToken, _polyToken) {

    }

    /**
     * @notice Creates a dividend and checkpoint for the dividend, using global list of excluded addresses
     * @param _maturity Time from which dividend can be paid
     * @param _expiry Time until dividend can no longer be paid, and can be reclaimed by issuer
     * @param _name Name/title for identification
     */
    function createDividend(uint256 _maturity, uint256 _expiry, bytes32 _name) external payable withPerm(ADMIN) {
        createDividendWithExclusions(_maturity, _expiry, excluded, _name);
    }

    /**
     * @notice Creates a dividend with a provided checkpoint, using global list of excluded addresses
     * @param _maturity Time from which dividend can be paid
     * @param _expiry Time until dividend can no longer be paid, and can be reclaimed by issuer
     * @param _checkpointId Id of the checkpoint from which to issue dividend
     * @param _name Name/title for identification
     */
    function createDividendWithCheckpoint(
        uint256 _maturity,
        uint256 _expiry,
        uint256 _checkpointId,
        bytes32 _name
    )
        external
        payable
        withPerm(ADMIN)
    {
        _createDividendWithCheckpointAndExclusions(_maturity, _expiry, _checkpointId, excluded, _name);
    }

    /**
     * @notice Creates a dividend and checkpoint for the dividend, specifying explicit excluded addresses
     * @param _maturity Time from which dividend can be paid
     * @param _expiry Time until dividend can no longer be paid, and can be reclaimed by issuer
     * @param _excluded List of addresses to exclude
     * @param _name Name/title for identification
     */
    function createDividendWithExclusions(
        uint256 _maturity,
        uint256 _expiry,
        address[] memory _excluded,
        bytes32 _name
    )
        public
        payable
        withPerm(ADMIN)
    {
        uint256 checkpointId = securityToken.createCheckpoint();
        _createDividendWithCheckpointAndExclusions(_maturity, _expiry, checkpointId, _excluded, _name);
    }

    /**
     * @notice Creates a dividend with a provided checkpoint, specifying explicit excluded addresses
     * @param _maturity Time from which dividend can be paid
     * @param _expiry Time until dividend can no longer be paid, and can be reclaimed by issuer
     * @param _checkpointId Id of the checkpoint from which to issue dividend
     * @param _excluded List of addresses to exclude
     * @param _name Name/title for identification
     */
    function createDividendWithCheckpointAndExclusions(
        uint256 _maturity,
        uint256 _expiry,
        uint256 _checkpointId,
        address[] memory _excluded,
        bytes32 _name
    )
        public
        payable
        withPerm(ADMIN)
    {
        _createDividendWithCheckpointAndExclusions(_maturity, _expiry, _checkpointId, _excluded, _name);
    }

    /**
     * @notice Creates a dividend with a provided checkpoint, specifying explicit excluded addresses
     * @param _maturity Time from which dividend can be paid
     * @param _expiry Time until dividend can no longer be paid, and can be reclaimed by issuer
     * @param _checkpointId Id of the checkpoint from which to issue dividend
     * @param _excluded List of addresses to exclude
     * @param _name Name/title for identification
     */
    function _createDividendWithCheckpointAndExclusions(
        uint256 _maturity,
        uint256 _expiry,
        uint256 _checkpointId,
        address[] memory _excluded,
        bytes32 _name
    )
        internal
    {
        require(_excluded.length <= EXCLUDED_ADDRESS_LIMIT, "Too many addresses excluded");
        require(_expiry > _maturity, "Expiry is before maturity");
        /*solium-disable-next-line security/no-block-members*/
        require(_expiry > now, "Expiry is in the past");
        require(msg.value > 0, "No dividend sent");
        require(_checkpointId <= securityToken.currentCheckpointId());
        require(_name[0] != bytes32(0));
        uint256 dividendIndex = dividends.length;
        uint256 currentSupply = securityToken.totalSupplyAt(_checkpointId);
        require(currentSupply > 0, "Invalid supply");
        uint256 excludedSupply = 0;
        dividends.push(
            Dividend(
                _checkpointId,
                now, /*solium-disable-line security/no-block-members*/
                _maturity,
                _expiry,
                msg.value,
                0,
                0,
                false,
                0,
                0,
                _name
            )
        );

        for (uint256 j = 0; j < _excluded.length; j++) {
            require(_excluded[j] != address(0), "Invalid address");
            require(!dividends[dividendIndex].dividendExcluded[_excluded[j]], "duped exclude address");
            excludedSupply = excludedSupply.add(securityToken.balanceOfAt(_excluded[j], _checkpointId));
            dividends[dividendIndex].dividendExcluded[_excluded[j]] = true;
        }
        require(currentSupply > excludedSupply, "Invalid supply");
        dividends[dividendIndex].totalSupply = currentSupply - excludedSupply;
        /*solium-disable-next-line security/no-block-members*/
        emit EtherDividendDeposited(msg.sender, _checkpointId, _maturity, _expiry, msg.value, currentSupply, dividendIndex, _name);
    }

    /**
     * @notice Internal function for paying dividends
     * @param _payee address of investor
     * @param _dividend storage with previously issued dividends
     * @param _dividendIndex Dividend to pay
     */
    function _payDividend(address payable _payee, Dividend storage _dividend, uint256 _dividendIndex) internal {
        (uint256 claim, uint256 withheld) = calculateDividend(_dividendIndex, _payee);
        _dividend.claimed[_payee] = true;
        uint256 claimAfterWithheld = claim.sub(withheld);
        /*solium-disable-next-line security/no-send*/
        if (_payee.send(claimAfterWithheld)) {
            _dividend.claimedAmount = _dividend.claimedAmount.add(claim);
            if (withheld > 0) {
                _dividend.totalWithheld = _dividend.totalWithheld.add(withheld);
                _dividend.withheld[_payee] = withheld;
            }
            emit EtherDividendClaimed(_payee, _dividendIndex, claim, withheld);
        } else {
            _dividend.claimed[_payee] = false;
            emit EtherDividendClaimFailed(_payee, _dividendIndex, claim, withheld);
        }
    }

    /**
     * @notice Issuer can reclaim remaining unclaimed dividend amounts, for expired dividends
     * @param _dividendIndex Dividend to reclaim
     */
    function reclaimDividend(uint256 _dividendIndex) external withPerm(OPERATOR) {
        require(_dividendIndex < dividends.length, "Incorrect dividend index");
        /*solium-disable-next-line security/no-block-members*/
        require(now >= dividends[_dividendIndex].expiry, "Dividend expiry is in the future");
        require(!dividends[_dividendIndex].reclaimed, "Dividend is already claimed");
        Dividend storage dividend = dividends[_dividendIndex];
        dividend.reclaimed = true;
        uint256 remainingAmount = dividend.amount.sub(dividend.claimedAmount);
        address payable wallet = getTreasuryWallet();
        wallet.transfer(remainingAmount);
        emit EtherDividendReclaimed(wallet, _dividendIndex, remainingAmount);
    }

    /**
     * @notice Allows issuer to withdraw withheld tax
     * @param _dividendIndex Dividend to withdraw from
     */
    function withdrawWithholding(uint256 _dividendIndex) external withPerm(OPERATOR) {
        require(_dividendIndex < dividends.length, "Incorrect dividend index");
        Dividend storage dividend = dividends[_dividendIndex];
        uint256 remainingWithheld = dividend.totalWithheld.sub(dividend.totalWithheldWithdrawn);
        dividend.totalWithheldWithdrawn = dividend.totalWithheld;
        address payable wallet = getTreasuryWallet();
        wallet.transfer(remainingWithheld);
        emit EtherDividendWithholdingWithdrawn(wallet, _dividendIndex, remainingWithheld);
    }

}

pragma solidity 0.5.8;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "../../interfaces/ISecurityToken.sol";
/**
 * @title Storage for Module contract
 * @notice Contract is abstract
 */
contract ModuleStorage {
    address public factory;

    ISecurityToken public securityToken;

    // Permission flag
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant OPERATOR = "OPERATOR";

    bytes32 internal constant TREASURY = 0xaae8817359f3dcb67d050f44f3e49f982e0359d90ca4b5f18569926304aaece6; // keccak256(abi.encodePacked("TREASURY_WALLET"))

    IERC20 public polyToken;

    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     * @param _polyAddress Address of the polytoken
     */
    constructor(address _securityToken, address _polyAddress) public {
        securityToken = ISecurityToken(_securityToken);
        factory = msg.sender;
        polyToken = IERC20(_polyAddress);
    }

}

pragma solidity 0.5.8;

/**
 * @title Holds the storage variable for the DividendCheckpoint modules (i.e ERC20, Ether)
 * @dev abstract contract
 */
contract DividendCheckpointStorage {

    // Address to which reclaimed dividends and withholding tax is sent
    address payable public wallet;
    uint256 public EXCLUDED_ADDRESS_LIMIT = 150;

    struct Dividend {
        uint256 checkpointId;
        uint256 created; // Time at which the dividend was created
        uint256 maturity; // Time after which dividend can be claimed - set to 0 to bypass
        uint256 expiry;  // Time until which dividend can be claimed - after this time any remaining amount can be withdrawn by issuer -
                         // set to very high value to bypass
        uint256 amount; // Dividend amount in WEI
        uint256 claimedAmount; // Amount of dividend claimed so far
        uint256 totalSupply; // Total supply at the associated checkpoint (avoids recalculating this)
        bool reclaimed;  // True if expiry has passed and issuer has reclaimed remaining dividend
        uint256 totalWithheld;
        uint256 totalWithheldWithdrawn;
        mapping (address => bool) claimed; // List of addresses which have claimed dividend
        mapping (address => bool) dividendExcluded; // List of addresses which cannot claim dividends
        mapping (address => uint256) withheld; // Amount of tax withheld from claim
        bytes32 name; // Name/title - used for identification
    }

    // List of all dividends
    Dividend[] public dividends;

    // List of addresses which cannot claim dividends
    address[] public excluded;

    // Mapping from address to withholding tax as a percentage * 10**16
    mapping (address => uint256) public withholdingTax;

    // Total amount of ETH withheld per investor
    mapping(address => uint256) public investorWithheld;

}

pragma solidity 0.5.8;

import "../interfaces/IModule.sol";
import "../Pausable.sol";
import "../interfaces/IModuleFactory.sol";
import "../interfaces/IDataStore.sol";
import "../interfaces/ISecurityToken.sol";
import "../interfaces/ICheckPermission.sol";
import "../storage/modules/ModuleStorage.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

/**
 * @title Interface that any module contract should implement
 * @notice Contract is abstract
 */
contract Module is IModule, ModuleStorage, Pausable {
    /**
     * @notice Constructor
     * @param _securityToken Address of the security token
     */
    constructor (address _securityToken, address _polyAddress) public
    ModuleStorage(_securityToken, _polyAddress)
    {
    }

    //Allows owner, factory or permissioned delegate
    modifier withPerm(bytes32 _perm) {
        require(_checkPerm(_perm, msg.sender), "Invalid permission");
        _;
    }

    function _checkPerm(bytes32 _perm, address _caller) internal view returns (bool) {
        bool isOwner = _caller == Ownable(address(securityToken)).owner();
        bool isFactory = _caller == factory;
        return isOwner || isFactory || ICheckPermission(address(securityToken)).checkPermission(_caller, address(this), _perm);
    }

    function _onlySecurityTokenOwner() internal view {
        require(msg.sender == Ownable(address(securityToken)).owner(), "Sender is not owner");
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Sender is not factory");
        _;
    }

    /**
     * @notice Pause (overridden function)
     */
    function pause() public {
        _onlySecurityTokenOwner();
        super._pause();
    }

    /**
     * @notice Unpause (overridden function)
     */
    function unpause() public {
        _onlySecurityTokenOwner();
        super._unpause();
    }

    /**
     * @notice used to return the data store address of securityToken
     */
    function getDataStore() public view returns(IDataStore) {
        return IDataStore(securityToken.dataStore());
    }

    /**
    * @notice Reclaims ERC20Basic compatible tokens
    * @dev We duplicate here due to the overriden owner & onlyOwner
    * @param _tokenContract The address of the token contract
    */
    function reclaimERC20(address _tokenContract) external {
        _onlySecurityTokenOwner();
        require(_tokenContract != address(0), "Invalid address");
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Transfer failed");
    }

   /**
    * @notice Reclaims ETH
    * @dev We duplicate here due to the overriden owner & onlyOwner
    */
    function reclaimETH() external {
        _onlySecurityTokenOwner();
        msg.sender.transfer(address(this).balance);
    }
}

pragma solidity 0.5.8;

/**
 * @title Interface to be implemented by all checkpoint modules
 */
/*solium-disable-next-line no-empty-blocks*/
interface ICheckpoint {

}

/**
 * DISCLAIMER: Under certain conditions, the function pushDividendPayment
 * may fail due to block gas limits.
 * If the total number of investors that ever held tokens is greater than ~15,000 then
 * the function may fail. If this happens investors can pull their dividends, or the Issuer
 * can use pushDividendPaymentToAddresses to provide an explict address list in batches
 */
pragma solidity 0.5.8;

import ".././ICheckpoint.sol";
import "../../../storage/modules/Checkpoint/Dividend/DividendCheckpointStorage.sol";
import "../../Module.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/math/Math.sol";

/**
 * @title Checkpoint module for issuing ether dividends
 * @dev abstract contract
 */
contract DividendCheckpoint is DividendCheckpointStorage, ICheckpoint, Module {
    using SafeMath for uint256;
    uint256 internal constant e18 = uint256(10) ** uint256(18);

    event SetDefaultExcludedAddresses(address[] _excluded);
    event SetWithholding(address[] _investors, uint256[] _withholding);
    event SetWithholdingFixed(address[] _investors, uint256 _withholding);
    event SetWallet(address indexed _oldWallet, address indexed _newWallet);
    event UpdateDividendDates(uint256 indexed _dividendIndex, uint256 _maturity, uint256 _expiry);

    function _validDividendIndex(uint256 _dividendIndex) internal view {
        require(_dividendIndex < dividends.length, "Invalid dividend");
        require(!dividends[_dividendIndex].reclaimed, "Dividend reclaimed");
        /*solium-disable-next-line security/no-block-members*/
        require(now >= dividends[_dividendIndex].maturity, "Dividend maturity in future");
        /*solium-disable-next-line security/no-block-members*/
        require(now < dividends[_dividendIndex].expiry, "Dividend expiry in past");
    }

    /**
     * @notice Function used to intialize the contract variables
     * @param _wallet Ethereum account address to receive reclaimed dividends and tax
     */
    function configure(
        address payable _wallet
    ) public onlyFactory {
        _setWallet(_wallet);
    }

    /**
    * @notice Init function i.e generalise function to maintain the structure of the module contract
    * @return bytes4
    */
    function getInitFunction() public pure returns(bytes4) {
        return this.configure.selector;
    }

    /**
     * @notice Function used to change wallet address
     * @param _wallet Ethereum account address to receive reclaimed dividends and tax
     */
    function changeWallet(address payable _wallet) external {
        _onlySecurityTokenOwner();
        _setWallet(_wallet);
    }

    function _setWallet(address payable _wallet) internal {
        emit SetWallet(wallet, _wallet);
        wallet = _wallet;
    }

    /**
     * @notice Return the default excluded addresses
     * @return List of excluded addresses
     */
    function getDefaultExcluded() external view returns(address[] memory) {
        return excluded;
    }

    /**
     * @notice Returns the treasury wallet address
     */
    function getTreasuryWallet() public view returns(address payable) {
        if (wallet == address(0)) {
            address payable treasuryWallet = address(uint160(IDataStore(getDataStore()).getAddress(TREASURY)));
            require(address(treasuryWallet) != address(0), "Invalid address");
            return treasuryWallet;
        }
        else
            return wallet;
    }

    /**
     * @notice Creates a checkpoint on the security token
     * @return Checkpoint ID
     */
    function createCheckpoint() public withPerm(OPERATOR) returns(uint256) {
        return securityToken.createCheckpoint();
    }

    /**
     * @notice Function to clear and set list of excluded addresses used for future dividends
     * @param _excluded Addresses of investors
     */
    function setDefaultExcluded(address[] memory _excluded) public withPerm(ADMIN) {
        require(_excluded.length <= EXCLUDED_ADDRESS_LIMIT, "Too many excluded addresses");
        for (uint256 j = 0; j < _excluded.length; j++) {
            require(_excluded[j] != address(0), "Invalid address");
            for (uint256 i = j + 1; i < _excluded.length; i++) {
                require(_excluded[j] != _excluded[i], "Duplicate exclude address");
            }
        }
        excluded = _excluded;
        /*solium-disable-next-line security/no-block-members*/
        emit SetDefaultExcludedAddresses(excluded);
    }

    /**
     * @notice Function to set withholding tax rates for investors
     * @param _investors Addresses of investors
     * @param _withholding Withholding tax for individual investors (multiplied by 10**16)
     */
    function setWithholding(address[] memory _investors, uint256[] memory _withholding) public withPerm(ADMIN) {
        require(_investors.length == _withholding.length, "Mismatched input lengths");
        /*solium-disable-next-line security/no-block-members*/
        emit SetWithholding(_investors, _withholding);
        for (uint256 i = 0; i < _investors.length; i++) {
            require(_withholding[i] <= e18, "Incorrect withholding tax");
            withholdingTax[_investors[i]] = _withholding[i];
        }
    }

    /**
     * @notice Function to set withholding tax rates for investors
     * @param _investors Addresses of investor
     * @param _withholding Withholding tax for all investors (multiplied by 10**16)
     */
    function setWithholdingFixed(address[] memory _investors, uint256 _withholding) public withPerm(ADMIN) {
        require(_withholding <= e18, "Incorrect withholding tax");
        /*solium-disable-next-line security/no-block-members*/
        emit SetWithholdingFixed(_investors, _withholding);
        for (uint256 i = 0; i < _investors.length; i++) {
            withholdingTax[_investors[i]] = _withholding;
        }
    }

    /**
     * @notice Issuer can push dividends to provided addresses
     * @param _dividendIndex Dividend to push
     * @param _payees Addresses to which to push the dividend
     */
    function pushDividendPaymentToAddresses(
        uint256 _dividendIndex,
        address payable[] memory _payees
    )
        public
        withPerm(OPERATOR)
    {
        _validDividendIndex(_dividendIndex);
        Dividend storage dividend = dividends[_dividendIndex];
        for (uint256 i = 0; i < _payees.length; i++) {
            if ((!dividend.claimed[_payees[i]]) && (!dividend.dividendExcluded[_payees[i]])) {
                _payDividend(_payees[i], dividend, _dividendIndex);
            }
        }
    }

    /**
     * @notice Issuer can push dividends using the investor list from the security token
     * @param _dividendIndex Dividend to push
     * @param _start Index in investor list at which to start pushing dividends
     * @param _end Index in investor list at which to stop pushing dividends
     */
    function pushDividendPayment(
        uint256 _dividendIndex,
        uint256 _start,
        uint256 _end
    )
        public
        withPerm(OPERATOR)
    {
        //NB If possible, please use pushDividendPaymentToAddresses as it is cheaper than this function
        _validDividendIndex(_dividendIndex);
        Dividend storage dividend = dividends[_dividendIndex];
        uint256 checkpointId = dividend.checkpointId;
        address[] memory investors = securityToken.getInvestorsSubsetAt(checkpointId, _start, _end);
        // The investors list maybe smaller than _end - _start becuase it only contains addresses that had a positive balance
        // the _start and _end used here are for the address list stored in the dataStore
        for (uint256 i = 0; i < investors.length; i++) {
            address payable payee = address(uint160(investors[i]));
            if ((!dividend.claimed[payee]) && (!dividend.dividendExcluded[payee])) {
                _payDividend(payee, dividend, _dividendIndex);
            }
        }
    }

    /**
     * @notice Investors can pull their own dividends
     * @param _dividendIndex Dividend to pull
     */
    function pullDividendPayment(uint256 _dividendIndex) public whenNotPaused {
        _validDividendIndex(_dividendIndex);
        Dividend storage dividend = dividends[_dividendIndex];
        require(!dividend.claimed[msg.sender], "Dividend already claimed");
        require(!dividend.dividendExcluded[msg.sender], "msg.sender excluded from Dividend");
        _payDividend(msg.sender, dividend, _dividendIndex);
    }

    /**
     * @notice Internal function for paying dividends
     * @param _payee Address of investor
     * @param _dividend Storage with previously issued dividends
     * @param _dividendIndex Dividend to pay
     */
    function _payDividend(address payable _payee, Dividend storage _dividend, uint256 _dividendIndex) internal;

    /**
     * @notice Issuer can reclaim remaining unclaimed dividend amounts, for expired dividends
     * @param _dividendIndex Dividend to reclaim
     */
    function reclaimDividend(uint256 _dividendIndex) external;

    /**
     * @notice Calculate amount of dividends claimable
     * @param _dividendIndex Dividend to calculate
     * @param _payee Affected investor address
     * @return claim, withheld amounts
     */
    function calculateDividend(uint256 _dividendIndex, address _payee) public view returns(uint256, uint256) {
        require(_dividendIndex < dividends.length, "Invalid dividend");
        Dividend storage dividend = dividends[_dividendIndex];
        if (dividend.claimed[_payee] || dividend.dividendExcluded[_payee]) {
            return (0, 0);
        }
        uint256 balance = securityToken.balanceOfAt(_payee, dividend.checkpointId);
        uint256 claim = balance.mul(dividend.amount).div(dividend.totalSupply);
        uint256 withheld = claim.mul(withholdingTax[_payee]).div(e18);
        return (claim, withheld);
    }

    /**
     * @notice Get the index according to the checkpoint id
     * @param _checkpointId Checkpoint id to query
     * @return uint256[]
     */
    function getDividendIndex(uint256 _checkpointId) public view returns(uint256[] memory) {
        uint256 counter = 0;
        for (uint256 i = 0; i < dividends.length; i++) {
            if (dividends[i].checkpointId == _checkpointId) {
                counter++;
            }
        }

        uint256[] memory index = new uint256[](counter);
        counter = 0;
        for (uint256 j = 0; j < dividends.length; j++) {
            if (dividends[j].checkpointId == _checkpointId) {
                index[counter] = j;
                counter++;
            }
        }
        return index;
    }

    /**
     * @notice Allows issuer to withdraw withheld tax
     * @param _dividendIndex Dividend to withdraw from
     */
    function withdrawWithholding(uint256 _dividendIndex) external;

    /**
     * @notice Allows issuer to change maturity / expiry dates for dividends
     * @dev NB - setting the maturity of a currently matured dividend to a future date
     * @dev will effectively refreeze claims on that dividend until the new maturity date passes
     * @ dev NB - setting the expiry date to a past date will mean no more payments can be pulled
     * @dev or pushed out of a dividend
     * @param _dividendIndex Dividend to withdraw from
     * @param _maturity updated maturity date
     * @param _expiry updated expiry date
     */
    function updateDividendDates(uint256 _dividendIndex, uint256 _maturity, uint256 _expiry) external withPerm(ADMIN) {
        require(_dividendIndex < dividends.length, "Invalid dividend");
        require(_expiry > _maturity, "Expiry before maturity");
        Dividend storage dividend = dividends[_dividendIndex];
        require(dividend.expiry > now, "Dividend already expired");
        dividend.expiry = _expiry;
        dividend.maturity = _maturity;
        emit UpdateDividendDates(_dividendIndex, _maturity, _expiry);
    }

    /**
     * @notice Get static dividend data
     * @return uint256[] timestamp of dividends creation
     * @return uint256[] timestamp of dividends maturity
     * @return uint256[] timestamp of dividends expiry
     * @return uint256[] amount of dividends
     * @return uint256[] claimed amount of dividends
     * @return bytes32[] name of dividends
     */
    function getDividendsData() external view returns (
        uint256[] memory createds,
        uint256[] memory maturitys,
        uint256[] memory expirys,
        uint256[] memory amounts,
        uint256[] memory claimedAmounts,
        bytes32[] memory names)
    {
        createds = new uint256[](dividends.length);
        maturitys = new uint256[](dividends.length);
        expirys = new uint256[](dividends.length);
        amounts = new uint256[](dividends.length);
        claimedAmounts = new uint256[](dividends.length);
        names = new bytes32[](dividends.length);
        for (uint256 i = 0; i < dividends.length; i++) {
            (createds[i], maturitys[i], expirys[i], amounts[i], claimedAmounts[i], names[i]) = getDividendData(i);
        }
    }

    /**
     * @notice Get static dividend data
     * @return uint256 timestamp of dividend creation
     * @return uint256 timestamp of dividend maturity
     * @return uint256 timestamp of dividend expiry
     * @return uint256 amount of dividend
     * @return uint256 claimed amount of dividend
     * @return bytes32 name of dividend
     */
    function getDividendData(uint256 _dividendIndex) public view returns (
        uint256 created,
        uint256 maturity,
        uint256 expiry,
        uint256 amount,
        uint256 claimedAmount,
        bytes32 name)
    {
        created = dividends[_dividendIndex].created;
        maturity = dividends[_dividendIndex].maturity;
        expiry = dividends[_dividendIndex].expiry;
        amount = dividends[_dividendIndex].amount;
        claimedAmount = dividends[_dividendIndex].claimedAmount;
        name = dividends[_dividendIndex].name;
    }

    /**
     * @notice Retrieves list of investors, their claim status and whether they are excluded
     * @param _dividendIndex Dividend to withdraw from
     * @return address[] list of investors
     * @return bool[] whether investor has claimed
     * @return bool[] whether investor is excluded
     * @return uint256[] amount of withheld tax (estimate if not claimed)
     * @return uint256[] amount of claim (estimate if not claimeed)
     * @return uint256[] investor balance
     */
    function getDividendProgress(uint256 _dividendIndex) external view returns (
        address[] memory investors,
        bool[] memory resultClaimed,
        bool[] memory resultExcluded,
        uint256[] memory resultWithheld,
        uint256[] memory resultAmount,
        uint256[] memory resultBalance)
    {
        require(_dividendIndex < dividends.length, "Invalid dividend");
        //Get list of Investors
        Dividend storage dividend = dividends[_dividendIndex];
        uint256 checkpointId = dividend.checkpointId;
        investors = securityToken.getInvestorsAt(checkpointId);
        resultClaimed = new bool[](investors.length);
        resultExcluded = new bool[](investors.length);
        resultWithheld = new uint256[](investors.length);
        resultAmount = new uint256[](investors.length);
        resultBalance = new uint256[](investors.length);
        for (uint256 i; i < investors.length; i++) {
            resultClaimed[i] = dividend.claimed[investors[i]];
            resultExcluded[i] = dividend.dividendExcluded[investors[i]];
            resultBalance[i] = securityToken.balanceOfAt(investors[i], dividend.checkpointId);
            if (!resultExcluded[i]) {
                if (resultClaimed[i]) {
                    resultWithheld[i] = dividend.withheld[investors[i]];
                    resultAmount[i] = resultBalance[i].mul(dividend.amount).div(dividend.totalSupply).sub(resultWithheld[i]);
                } else {
                    (uint256 claim, uint256 withheld) = calculateDividend(_dividendIndex, investors[i]);
                    resultWithheld[i] = withheld;
                    resultAmount[i] = claim.sub(withheld);
                }
            }
        }
    }

    /**
     * @notice Retrieves list of investors, their balances, and their current withholding tax percentage
     * @param _checkpointId Checkpoint Id to query for
     * @return address[] list of investors
     * @return uint256[] investor balances
     * @return uint256[] investor withheld percentages
     */
    function getCheckpointData(uint256 _checkpointId) external view returns (address[] memory investors, uint256[] memory balances, uint256[] memory withholdings) {
        require(_checkpointId <= securityToken.currentCheckpointId(), "Invalid checkpoint");
        investors = securityToken.getInvestorsAt(_checkpointId);
        balances = new uint256[](investors.length);
        withholdings = new uint256[](investors.length);
        for (uint256 i; i < investors.length; i++) {
            balances[i] = securityToken.balanceOfAt(investors[i], _checkpointId);
            withholdings[i] = withholdingTax[investors[i]];
        }
    }

    /**
     * @notice Checks whether an address is excluded from claiming a dividend
     * @param _dividendIndex Dividend to withdraw from
     * @return bool whether the address is excluded
     */
    function isExcluded(address _investor, uint256 _dividendIndex) external view returns (bool) {
        require(_dividendIndex < dividends.length, "Invalid dividend");
        return dividends[_dividendIndex].dividendExcluded[_investor];
    }

    /**
     * @notice Checks whether an address has claimed a dividend
     * @param _dividendIndex Dividend to withdraw from
     * @return bool whether the address has claimed
     */
    function isClaimed(address _investor, uint256 _dividendIndex) external view returns (bool) {
        require(_dividendIndex < dividends.length, "Invalid dividend");
        return dividends[_dividendIndex].claimed[_investor];
    }

    /**
     * @notice Return the permissions flag that are associated with this module
     * @return bytes32 array
     */
    function getPermissions() public view returns(bytes32[] memory) {
        bytes32[] memory allPermissions = new bytes32[](2);
        allPermissions[0] = ADMIN;
        allPermissions[1] = OPERATOR;
        return allPermissions;
    }

}

pragma solidity 0.5.8;

/**
 * @title Interface for all security tokens
 */
interface ISecurityToken {
    // Standard ERC20 interface
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns(bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code
     */
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (byte statusCode, bytes32 reasonCode);

    // Emit at the time when module get added
    event ModuleAdded(
        uint8[] _types,
        bytes32 indexed _name,
        address indexed _moduleFactory,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    );

    // Emit when the token details get updated
    event UpdateTokenDetails(string _oldDetails, string _newDetails);
    // Emit when the token name get updated
    event UpdateTokenName(string _oldName, string _newName);
    // Emit when the granularity get changed
    event GranularityChanged(uint256 _oldGranularity, uint256 _newGranularity);
    // Emit when is permanently frozen by the issuer
    event FreezeIssuance();
    // Emit when transfers are frozen or unfrozen
    event FreezeTransfers(bool _status);
    // Emit when new checkpoint created
    event CheckpointCreated(uint256 indexed _checkpointId, uint256 _investorLength);
    // Events to log controller actions
    event SetController(address indexed _oldController, address indexed _newController);
    //Event emit when the global treasury wallet address get changed
    event TreasuryWalletChanged(address _oldTreasuryWallet, address _newTreasuryWallet);
    event DisableController();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenUpgraded(uint8 _major, uint8 _minor, uint8 _patch);

    // Emit when Module get archived from the securityToken
    event ModuleArchived(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when Module get unarchived from the securityToken
    event ModuleUnarchived(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when Module get removed from the securityToken
    event ModuleRemoved(uint8[] _types, address _module); //Event emitted by the tokenLib.
    // Emit when the budget allocated to a module is changed
    event ModuleBudgetChanged(uint8[] _moduleTypes, address _module, uint256 _oldBudget, uint256 _budget); //Event emitted by the tokenLib.

    // Transfer Events
    event TransferByPartition(
        bytes32 indexed _fromPartition,
        address _operator,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Operator Events
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

    // Issuance / Redemption Events
    event IssuedByPartition(bytes32 indexed partition, address indexed to, uint256 value, bytes data);
    event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);

    // Document Events
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

    // Controller Events
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    // Issuance / Redemption Events
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

    /**
     * @notice Initialization function
     * @dev Expected to be called atomically with the proxy being created, by the owner of the token
     * @dev Can only be called once
     */
    function initialize(address _getterDelegate) external;

    /**
     * @notice The standard provides an on-chain function to determine whether a transfer will succeed,
     * and return details indicating the reason if the transfer is not valid.
     * @param _from The address from whom the tokens get transferred.
     * @param _to The address to which to transfer tokens to.
     * @param _partition The partition from which to transfer tokens
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @return ESC (Ethereum Status Code) following the EIP-1066 standard
     * @return Application specific reason codes with additional details
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view
        returns (byte statusCode, bytes32 reasonCode, bytes32 partition);

    /**
     * @notice Transfers of securities may fail for a number of reasons. So this function will used to understand the
     * cause of failure by getting the byte value. Which will be the ESC that follows the EIP 1066. ESC can be mapped
     * with a reson string to understand the failure cause, table of Ethereum status code will always reside off-chain
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     * @return byte Ethereum status code (ESC)
     * @return bytes32 Application specific reason code
     */
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (byte statusCode, bytes32 reasonCode);

    /**
     * @notice Used to attach a new document to the contract, or update the URI or hash of an existing attached document
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     * @param _uri Off-chain uri of the document from where it is accessible to investors/advisors to read.
     * @param _documentHash hash (of the contents) of the document.
     */
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external;

    /**
     * @notice Used to remove an existing document from the contract by giving the name of the document.
     * @dev Can only be executed by the owner of the contract.
     * @param _name Name of the document. It should be unique always
     */
    function removeDocument(bytes32 _name) external;

    /**
     * @notice Used to return the details of a document with a known name (`bytes32`).
     * @param _name Name of the document
     * @return string The URI associated with the document.
     * @return bytes32 The hash (of the contents) of the document.
     * @return uint256 the timestamp at which the document was last modified.
     */
    function getDocument(bytes32 _name) external view returns (string memory documentUri, bytes32 documentHash, uint256 documentTime);

    /**
     * @notice Used to retrieve a full list of documents attached to the smart contract.
     * @return bytes32 List of all documents names present in the contract.
     */
    function getAllDocuments() external view returns (bytes32[] memory documentNames);

    /**
     * @notice In order to provide transparency over whether `controllerTransfer` / `controllerRedeem` are useable
     * or not `isControllable` function will be used.
     * @dev If `isControllable` returns `false` then it always return `false` and
     * `controllerTransfer` / `controllerRedeem` will always revert.
     * @return bool `true` when controller address is non-zero otherwise return `false`.
     */
    function isControllable() external view returns (bool controlled);

    /**
     * @notice Checks if an address is a module of certain type
     * @param _module Address to check
     * @param _type type to check against
     */
    function isModule(address _module, uint8 _type) external view returns(bool isValid);

    /**
     * @notice This function must be called to increase the total supply (Corresponds to mint function of ERC20).
     * @dev It only be called by the token issuer or the operator defined by the issuer. ERC1594 doesn't have
     * have the any logic related to operator but its superset ERC1400 have the operator logic and this function
     * is allowed to call by the operator.
     * @param _tokenHolder The account that will receive the created tokens (account should be whitelisted or KYCed).
     * @param _value The amount of tokens need to be issued
     * @param _data The `bytes _data` allows arbitrary data to be submitted alongside the transfer.
     */
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice issue new tokens and assigns them to the target _tokenHolder.
     * @dev Can only be called by the issuer or STO attached to the token.
     * @param _tokenHolders A list of addresses to whom the minted tokens will be dilivered
     * @param _values A list of number of tokens get minted and transfer to corresponding address of the investor from _tokenHolders[] list
     * @return success
     */
    function issueMulti(address[] calldata _tokenHolders, uint256[] calldata _values) external;

    /**
     * @notice Increases totalSupply and the corresponding amount of the specified owners partition
     * @param _partition The partition to allocate the increase in balance
     * @param _tokenHolder The token holder whose balance should be increased
     * @param _value The amount by which to increase the balance
     * @param _data Additional data attached to the minting of tokens
     */
    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of msg.sender
     * @param _partition The partition to allocate the decrease in balance
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     */
    function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data) external;

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeem(uint256 _value, bytes calldata _data) external;

    /**
     * @notice This function redeem an amount of the token of a msg.sender. For doing so msg.sender may incentivize
     * using different ways that could be implemented with in the `redeem` function definition. But those implementations
     * are out of the scope of the ERC1594.
     * @dev It is analogy to `transferFrom`
     * @param _tokenHolder The account whose tokens gets redeemed.
     * @param _value The amount of tokens need to be redeemed
     * @param _data The `bytes _data` it can be used in the token contract to authenticate the redemption.
     */
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Decreases totalSupply and the corresponding amount of the specified partition of tokenHolder
     * @dev This function can only be called by the authorised operator.
     * @param _partition The partition to allocate the decrease in balance.
     * @param _tokenHolder The token holder whose balance should be decreased
     * @param _value The amount by which to decrease the balance
     * @param _data Additional data attached to the burning of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     */
    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

    /**
     * @notice Validate permissions with PermissionManager if it exists, If no Permission return false
     * @dev Note that IModule withPerm will allow ST owner all permissions anyway
     * @dev this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
     * @param _delegate address of delegate
     * @param _module address of PermissionManager module
     * @param _perm the permissions
     * @return success
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool hasPermission);

    /**
     * @notice Returns module list for a module type
     * @param _module Address of the module
     * @return bytes32 Name
     * @return address Module address
     * @return address Module factory address
     * @return bool Module archived
     * @return uint8 Array of module types
     * @return bytes32 Module label
     */
    function getModule(address _module) external view returns (bytes32 moduleName, address moduleAddress, address factoryAddress, bool isArchived, uint8[] memory moduleTypes, bytes32 moduleLabel);

    /**
     * @notice Returns module list for a module name
     * @param _name Name of the module
     * @return address[] List of modules with this name
     */
    function getModulesByName(bytes32 _name) external view returns(address[] memory modules);

    /**
     * @notice Returns module list for a module type
     * @param _type Type of the module
     * @return address[] List of modules with this type
     */
    function getModulesByType(uint8 _type) external view returns(address[] memory modules);

    /**
     * @notice use to return the global treasury wallet
     */
    function getTreasuryWallet() external view returns(address treasuryWallet);

    /**
     * @notice Queries totalSupply at a specified checkpoint
     * @param _checkpointId Checkpoint ID to query as of
     */
    function totalSupplyAt(uint256 _checkpointId) external view returns(uint256 supply);

    /**
     * @notice Queries balance at a specified checkpoint
     * @param _investor Investor to query balance for
     * @param _checkpointId Checkpoint ID to query as of
     */
    function balanceOfAt(address _investor, uint256 _checkpointId) external view returns(uint256 balance);

    /**
     * @notice Creates a checkpoint that can be used to query historical balances / totalSuppy
     */
    function createCheckpoint() external returns(uint256 checkpointId);

    /**
     * @notice Gets list of times that checkpoints were created
     * @return List of checkpoint times
     */
    function getCheckpointTimes() external view returns(uint256[] memory checkpointTimes);

    /**
     * @notice returns an array of investors
     * NB - this length may differ from investorCount as it contains all investors that ever held tokens
     * @return list of addresses
     */
    function getInvestors() external view returns(address[] memory investors);

    /**
     * @notice returns an array of investors at a given checkpoint
     * NB - this length may differ from investorCount as it contains all investors that ever held tokens
     * @param _checkpointId Checkpoint id at which investor list is to be populated
     * @return list of investors
     */
    function getInvestorsAt(uint256 _checkpointId) external view returns(address[] memory investors);

    /**
     * @notice returns an array of investors with non zero balance at a given checkpoint
     * @param _checkpointId Checkpoint id at which investor list is to be populated
     * @param _start Position of investor to start iteration from
     * @param _end Position of investor to stop iteration at
     * @return list of investors
     */
    function getInvestorsSubsetAt(uint256 _checkpointId, uint256 _start, uint256 _end) external view returns(address[] memory investors);

    /**
     * @notice generates subset of investors
     * NB - can be used in batches if investor list is large
     * @param _start Position of investor to start iteration from
     * @param _end Position of investor to stop iteration at
     * @return list of investors
     */
    function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[] memory investors);

    /**
     * @notice Gets current checkpoint ID
     * @return Id
     */
    function currentCheckpointId() external view returns(uint256 checkpointId);

    /**
     * @notice Determines whether `_operator` is an operator for all partitions of `_tokenHolder`
     * @param _operator The operator to check
     * @param _tokenHolder The token holder to check
     * @return Whether the `_operator` is an operator for all partitions of `_tokenHolder`
     */
    function isOperator(address _operator, address _tokenHolder) external view returns (bool isValid);

    /**
     * @notice Determines whether `_operator` is an operator for a specified partition of `_tokenHolder`
     * @param _partition The partition to check
     * @param _operator The operator to check
     * @param _tokenHolder The token holder to check
     * @return Whether the `_operator` is an operator for a specified partition of `_tokenHolder`
     */
    function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool isValid);

    /**
     * @notice Return all partitions
     * @param _tokenHolder Whom balance need to queried
     * @return List of partitions
     */
    function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory partitions);

    /**
     * @notice Gets data store address
     * @return data store address
     */
    function dataStore() external view returns (address dataStoreAddress);

    /**
    * @notice Allows owner to change data store
    * @param _dataStore Address of the token data store
    */
    function changeDataStore(address _dataStore) external;


    /**
     * @notice Allows to change the treasury wallet address
     * @param _wallet Ethereum address of the treasury wallet
     */
    function changeTreasuryWallet(address _wallet) external;

    /**
     * @notice Allows the owner to withdraw unspent POLY stored by them on the ST or any ERC20 token.
     * @dev Owner can transfer POLY to the ST which will be used to pay for modules that require a POLY fee.
     * @param _tokenContract Address of the ERC20Basic compliance token
     * @param _value Amount of POLY to withdraw
     */
    function withdrawERC20(address _tokenContract, uint256 _value) external;

    /**
    * @notice Allows owner to increase/decrease POLY approval of one of the modules
    * @param _module Module address
    * @param _change Change in allowance
    * @param _increase True if budget has to be increased, false if decrease
    */
    function changeModuleBudget(address _module, uint256 _change, bool _increase) external;

    /**
     * @notice Changes the tokenDetails
     * @param _newTokenDetails New token details
     */
    function updateTokenDetails(string calldata _newTokenDetails) external;

    /**
    * @notice Allows owner to change token name
    * @param _name new name of the token
    */
    function changeName(string calldata _name) external;

    /**
    * @notice Allows the owner to change token granularity
    * @param _granularity Granularity level of the token
    */
    function changeGranularity(uint256 _granularity) external;

    /**
     * @notice Freezes all the transfers
     */
    function freezeTransfers() external;

    /**
     * @notice Un-freezes all the transfers
     */
    function unfreezeTransfers() external;

    /**
     * @notice Permanently freeze issuance of this security token.
     * @dev It MUST NOT be possible to increase `totalSuppy` after this function is called.
     */
    function freezeIssuance(bytes calldata _signature) external;

    /**
      * @notice Attachs a module to the SecurityToken
      * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
      * @dev to control restrictions on transfers.
      * @param _moduleFactory is the address of the module factory to be added
      * @param _data is data packed into bytes used to further configure the module (See STO usage)
      * @param _maxCost max amount of POLY willing to pay to the module.
      * @param _budget max amount of ongoing POLY willing to assign to the module.
      * @param _label custom module label.
      * @param _archived whether to add the module as an archived module
      */
    function addModuleWithLabel(
        address _moduleFactory,
        bytes calldata _data,
        uint256 _maxCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    ) external;

    /**
     * @notice Function used to attach a module to the security token
     * @dev  E.G.: On deployment (through the STR) ST gets a TransferManager module attached to it
     * @dev to control restrictions on transfers.
     * @dev You are allowed to add a new moduleType if:
     * @dev - there is no existing module of that type yet added
     * @dev - the last member of the module list is replacable
     * @param _moduleFactory is the address of the module factory to be added
     * @param _data is data packed into bytes used to further configure the module (See STO usage)
     * @param _maxCost max amount of POLY willing to pay to module. (WIP)
     * @param _budget max amount of ongoing POLY willing to assign to the module.
     * @param _archived whether to add the module as an archived module
     */
    function addModule(address _moduleFactory, bytes calldata _data, uint256 _maxCost, uint256 _budget, bool _archived) external;

    /**
    * @notice Archives a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function archiveModule(address _module) external;

    /**
    * @notice Unarchives a module attached to the SecurityToken
    * @param _module address of module to unarchive
    */
    function unarchiveModule(address _module) external;

    /**
    * @notice Removes a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function removeModule(address _module) external;

    /**
     * @notice Used by the issuer to set the controller addresses
     * @param _controller address of the controller
     */
    function setController(address _controller) external;

    /**
     * @notice This function allows an authorised address to transfer tokens between any two token holders.
     * The transfer must still respect the balances of the token holders (so the transfer must be for at most
     * `balanceOf(_from)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _from Address The address which you want to send tokens from
     * @param _to Address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    /**
     * @notice This function allows an authorised address to redeem tokens for any token holder.
     * The redemption must still respect the balances of the token holder (so the redemption must be for at most
     * `balanceOf(_tokenHolder)` tokens) and potentially also need to respect other transfer restrictions.
     * @dev This function can only be executed by the `controller` address.
     * @param _tokenHolder The account whose tokens will be redeemed.
     * @param _value uint256 the amount of tokens need to be redeemed.
     * @param _data data to validate the transfer. (It is not used in this reference implementation
     * because use of `_data` parameter is implementation specific).
     * @param _operatorData data attached to the transfer by controller to emit in event. (It is more like a reason string
     * for calling this function (aka force transfer) which provides the transparency on-chain).
     */
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

    /**
     * @notice Used by the issuer to permanently disable controller functionality
     * @dev enabled via feature switch "disableControllerAllowed"
     */
    function disableController(bytes calldata _signature) external;

    /**
     * @notice Used to get the version of the securityToken
     */
    function getVersion() external view returns(uint8[] memory version);

    /**
     * @notice Gets the investor count
     */
    function getInvestorCount() external view returns(uint256 investorCount);

    /**
     * @notice Gets the holder count (investors with non zero balance)
     */
    function holderCount() external view returns(uint256 count);

    /**
      * @notice Overloaded version of the transfer function
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * @return bool success
      */
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;

    /**
      * @notice Overloaded version of the transferFrom function
      * @param _from sender of transfer
      * @param _to receiver of transfer
      * @param _value value of transfer
      * @param _data data to indicate validation
      * @return bool success
      */
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes calldata _data) external returns (bytes32 partition);

    /**
     * @notice Get the balance according to the provided partitions
     * @param _partition Partition which differentiate the tokens.
     * @param _tokenHolder Whom balance need to queried
     * @return Amount of tokens as per the given partitions
     */
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns(uint256 balance);

    /**
      * @notice Provides the granularity of the token
      * @return uint256
      */
    function granularity() external view returns(uint256 granularityAmount);

    /**
      * @notice Provides the address of the polymathRegistry
      * @return address
      */
    function polymathRegistry() external view returns(address registryAddress);

    /**
    * @notice Upgrades a module attached to the SecurityToken
    * @param _module address of module to archive
    */
    function upgradeModule(address _module) external;

    /**
    * @notice Upgrades security token
    */
    function upgradeToken() external;

    /**
     * @notice A security token issuer can specify that issuance has finished for the token
     * (i.e. no new tokens can be minted or issued).
     * @dev If a token returns FALSE for `isIssuable()` then it MUST always return FALSE in the future.
     * If a token returns FALSE for `isIssuable()` then it MUST never allow additional tokens to be issued.
     * @return bool `true` signifies the minting is allowed. While `false` denotes the end of minting
     */
    function isIssuable() external view returns (bool issuable);

    /**
     * @notice Authorises an operator for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being authorised.
     */
    function authorizeOperator(address _operator) external;

    /**
     * @notice Revokes authorisation of an operator previously given for all partitions of `msg.sender`.
     * NB - Allowing investors to authorize an investor to be an operator of all partitions
     * but it doesn't mean we operator is allowed to transfer the LOCKED partition values.
     * Logic for this restriction is written in `operatorTransferByPartition()` function.
     * @param _operator An address which is being de-authorised
     */
    function revokeOperator(address _operator) external;

    /**
     * @notice Authorises an operator for a given partition of `msg.sender`
     * @param _partition The partition to which the operator is authorised
     * @param _operator An address which is being authorised
     */
    function authorizeOperatorByPartition(bytes32 _partition, address _operator) external;

    /**
     * @notice Revokes authorisation of an operator previously given for a specified partition of `msg.sender`
     * @param _partition The partition to which the operator is de-authorised
     * @param _operator An address which is being de-authorised
     */
    function revokeOperatorByPartition(bytes32 _partition, address _operator) external;

    /**
     * @notice Transfers the ownership of tokens from a specified partition from one address to another address
     * @param _partition The partition from which to transfer tokens.
     * @param _from The address from which to transfer tokens from
     * @param _to The address to which to transfer tokens to
     * @param _value The amount of tokens to transfer from `_partition`
     * @param _data Additional data attached to the transfer of tokens
     * @param _operatorData Additional data attached to the transfer of tokens by the operator
     * @return The partition to which the transferred tokens were allocated for the _to address
     */
    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
        returns (bytes32 partition);

    /*
    * @notice Returns if transfers are currently frozen or not
    */
    function transfersFrozen() external view returns (bool isFrozen);

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() external view returns (bool);

    /**
     * @return the address of the owner.
     */
    function owner() external view returns (address ownerAddress);

    function controller() external view returns(address controllerAddress);

    function moduleRegistry() external view returns(address moduleRegistryAddress);

    function securityTokenRegistry() external view returns(address securityTokenRegistryAddress);

    function polyToken() external view returns(address polyTokenAddress);

    function tokenFactory() external view returns(address tokenFactoryAddress);

    function getterDelegate() external view returns(address delegate);

    function controllerDisabled() external view returns(bool isDisabled);

    function initialized() external view returns(bool isInitialized);

    function tokenDetails() external view returns(string memory details);

    function updateFromRegistry() external;

}

pragma solidity 0.5.8;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
interface IOwnable {
    /**
    * @dev Returns owner
    */
    function owner() external view returns(address ownerAddress);

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    */
    function renounceOwnership() external;

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external;

}

pragma solidity 0.5.8;

/**
 * @title Interface that every module factory contract should implement
 */
interface IModuleFactory {
    event ChangeSetupCost(uint256 _oldSetupCost, uint256 _newSetupCost);
    event ChangeCostType(bool _isOldCostInPoly, bool _isNewCostInPoly);
    event GenerateModuleFromFactory(
        address _module,
        bytes32 indexed _moduleName,
        address indexed _moduleFactory,
        address _creator,
        uint256 _setupCost,
        uint256 _setupCostInPoly
    );
    event ChangeSTVersionBound(string _boundType, uint8 _major, uint8 _minor, uint8 _patch);

    //Should create an instance of the Module, or throw
    function deploy(bytes calldata _data) external returns(address moduleAddress);

    /**
     * @notice Get the tags related to the module factory
     */
    function version() external view returns(string memory moduleVersion);

    /**
     * @notice Get the tags related to the module factory
     */
    function name() external view returns(bytes32 moduleName);

    /**
     * @notice Returns the title associated with the module
     */
    function title() external view returns(string memory moduleTitle);

    /**
     * @notice Returns the description associated with the module
     */
    function description() external view returns(string memory moduleDescription);

    /**
     * @notice Get the setup cost of the module in USD
     */
    function setupCost() external returns(uint256 usdSetupCost);

    /**
     * @notice Type of the Module factory
     */
    function getTypes() external view returns(uint8[] memory moduleTypes);

    /**
     * @notice Get the tags related to the module factory
     */
    function getTags() external view returns(bytes32[] memory moduleTags);

    /**
     * @notice Used to change the setup fee
     * @param _newSetupCost New setup fee
     */
    function changeSetupCost(uint256 _newSetupCost) external;

    /**
     * @notice Used to change the currency and amount setup cost
     * @param _setupCost new setup cost
     * @param _isCostInPoly new setup cost currency. USD or POLY
     */
    function changeCostAndType(uint256 _setupCost, bool _isCostInPoly) external;

    /**
     * @notice Function use to change the lower and upper bound of the compatible version st
     * @param _boundType Type of bound
     * @param _newVersion New version array
     */
    function changeSTVersionBounds(string calldata _boundType, uint8[] calldata _newVersion) external;

    /**
     * @notice Get the setup cost of the module
     */
    function setupCostInPoly() external returns (uint256 polySetupCost);

    /**
     * @notice Used to get the lower bound
     * @return Lower bound
     */
    function getLowerSTVersionBounds() external view returns(uint8[] memory lowerBounds);

    /**
     * @notice Used to get the upper bound
     * @return Upper bound
     */
    function getUpperSTVersionBounds() external view returns(uint8[] memory upperBounds);

    /**
     * @notice Updates the tags of the ModuleFactory
     * @param _tagsData New list of tags
     */
    function changeTags(bytes32[] calldata _tagsData) external;

    /**
     * @notice Updates the name of the ModuleFactory
     * @param _name New name that will replace the old one.
     */
    function changeName(bytes32 _name) external;

    /**
     * @notice Updates the description of the ModuleFactory
     * @param _description New description that will replace the old one.
     */
    function changeDescription(string calldata _description) external;

    /**
     * @notice Updates the title of the ModuleFactory
     * @param _title New Title that will replace the old one.
     */
    function changeTitle(string calldata _title) external;

}

pragma solidity 0.5.8;

/**
 * @title Interface that every module contract should implement
 */
interface IModule {
    /**
     * @notice This function returns the signature of configure function
     */
    function getInitFunction() external pure returns(bytes4 initFunction);

    /**
     * @notice Return the permission flags that are associated with a module
     */
    function getPermissions() external view returns(bytes32[] memory permissions);

}

pragma solidity 0.5.8;

interface IDataStore {
    /**
     * @dev Changes security token atatched to this data store
     * @param _securityToken address of the security token
     */
    function setSecurityToken(address _securityToken) external;

    /**
     * @dev Stores a uint256 data against a key
     * @param _key Unique key to identify the data
     * @param _data Data to be stored against the key
     */
    function setUint256(bytes32 _key, uint256 _data) external;

    function setBytes32(bytes32 _key, bytes32 _data) external;

    function setAddress(bytes32 _key, address _data) external;

    function setString(bytes32 _key, string calldata _data) external;

    function setBytes(bytes32 _key, bytes calldata _data) external;

    function setBool(bytes32 _key, bool _data) external;

    /**
     * @dev Stores a uint256 array against a key
     * @param _key Unique key to identify the array
     * @param _data Array to be stored against the key
     */
    function setUint256Array(bytes32 _key, uint256[] calldata _data) external;

    function setBytes32Array(bytes32 _key, bytes32[] calldata _data) external ;

    function setAddressArray(bytes32 _key, address[] calldata _data) external;

    function setBoolArray(bytes32 _key, bool[] calldata _data) external;

    /**
     * @dev Inserts a uint256 element to the array identified by the key
     * @param _key Unique key to identify the array
     * @param _data Element to push into the array
     */
    function insertUint256(bytes32 _key, uint256 _data) external;

    function insertBytes32(bytes32 _key, bytes32 _data) external;

    function insertAddress(bytes32 _key, address _data) external;

    function insertBool(bytes32 _key, bool _data) external;

    /**
     * @dev Deletes an element from the array identified by the key.
     * When an element is deleted from an Array, last element of that array is moved to the index of deleted element.
     * @param _key Unique key to identify the array
     * @param _index Index of the element to delete
     */
    function deleteUint256(bytes32 _key, uint256 _index) external;

    function deleteBytes32(bytes32 _key, uint256 _index) external;

    function deleteAddress(bytes32 _key, uint256 _index) external;

    function deleteBool(bytes32 _key, uint256 _index) external;

    /**
     * @dev Stores multiple uint256 data against respective keys
     * @param _keys Array of keys to identify the data
     * @param _data Array of data to be stored against the respective keys
     */
    function setUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function setBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function setAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function setBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

    /**
     * @dev Inserts multiple uint256 elements to the array identified by the respective keys
     * @param _keys Array of keys to identify the data
     * @param _data Array of data to be inserted in arrays of the respective keys
     */
    function insertUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function insertBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function insertAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function insertBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

    function getUint256(bytes32 _key) external view returns(uint256);

    function getBytes32(bytes32 _key) external view returns(bytes32);

    function getAddress(bytes32 _key) external view returns(address);

    function getString(bytes32 _key) external view returns(string memory);

    function getBytes(bytes32 _key) external view returns(bytes memory);

    function getBool(bytes32 _key) external view returns(bool);

    function getUint256Array(bytes32 _key) external view returns(uint256[] memory);

    function getBytes32Array(bytes32 _key) external view returns(bytes32[] memory);

    function getAddressArray(bytes32 _key) external view returns(address[] memory);

    function getBoolArray(bytes32 _key) external view returns(bool[] memory);

    function getUint256ArrayLength(bytes32 _key) external view returns(uint256);

    function getBytes32ArrayLength(bytes32 _key) external view returns(uint256);

    function getAddressArrayLength(bytes32 _key) external view returns(uint256);

    function getBoolArrayLength(bytes32 _key) external view returns(uint256);

    function getUint256ArrayElement(bytes32 _key, uint256 _index) external view returns(uint256);

    function getBytes32ArrayElement(bytes32 _key, uint256 _index) external view returns(bytes32);

    function getAddressArrayElement(bytes32 _key, uint256 _index) external view returns(address);

    function getBoolArrayElement(bytes32 _key, uint256 _index) external view returns(bool);

    function getUint256ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(uint256[] memory);

    function getBytes32ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bytes32[] memory);

    function getAddressArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(address[] memory);

    function getBoolArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bool[] memory);
}

pragma solidity 0.5.8;

interface ICheckPermission {
    /**
     * @notice Validate permissions with PermissionManager if it exists, If no Permission return false
     * @dev Note that IModule withPerm will allow ST owner all permissions anyway
     * @dev this allows individual modules to override this logic if needed (to not allow ST owner all permissions)
     * @param _delegate address of delegate
     * @param _module address of PermissionManager module
     * @param _perm the permissions
     * @return success
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool hasPerm);
}

pragma solidity 0.5.8;

/**
 * @title Utility contract to allow pausing and unpausing of certain functions
 */
contract Pausable {
    event Pause(address account);
    event Unpause(address account);

    bool public paused = false;

    /**
    * @notice Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    /**
    * @notice Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    /**
    * @notice Called by the owner to pause, triggers stopped state
    */
    function _pause() internal whenNotPaused {
        paused = true;
        /*solium-disable-next-line security/no-block-members*/
        emit Pause(msg.sender);
    }

    /**
    * @notice Called by the owner to unpause, returns to normal state
    */
    function _unpause() internal whenPaused {
        paused = false;
        /*solium-disable-next-line security/no-block-members*/
        emit Unpause(msg.sender);
    }

}

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.2;

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Calculates the average of two numbers. Since these are integers,
     * averages of an even and odd number cannot be represented, and will be
     * rounded down.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}