pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
      address indexed previousOwner,
      address indexed newOwner
    );


    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    /**
    * @dev Allows the current owner to relinquish control of the contract.
    */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
    * @dev Transfers control of the contract to a newOwner.
    * @param _newOwner The address to transfer ownership to.
    */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Invalid address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract IERC20 {

    string public name;
    string public symbol;
    uint8 public decimals;

    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value) public returns (bool);
    
    function allowance(address _owner, address _spender) public view returns (uint256);

}

/**
 * @dev ??????????????????
 */
contract IModuleFactory is Ownable {

    // ??????Token
    IERC20 public platformToken;
    // ????????????
    uint256 public setupCost;
    // ????????????
    uint256 public usageCost;
    // ???????????????
    uint256 public monthlySubscriptionCost;

    // ??????????????????????????????
    event LogChangeFactorySetupFee(uint256 _oldSetupcost, uint256 _newSetupCost, address _moduleFactoryAddress);
    // ??????????????????????????????
    event LogChangeFactoryUsageFee(uint256 _oldUsageCost, uint256 _newUsageCost, address _moduleFactoryAddress);
    // ??????????????????????????????
    event LogChangeFactorySubscriptionFee(uint256 _oldSubscriptionCost, uint256 _newMonthlySubscriptionCost, address _moduleFactoryAddress);
    // ???????????????????????????
    event LogGenerateModuleFromFactory(address _moduleAddress, bytes32 indexed _moduleName, address indexed _moduleFactoryAddress, address _creator, uint256 _timestamp);

   
    /**
     * @dev ????????????
     * @param _platformTokenAddress ??????token??????
     * @param _setupCost ????????????
     * @param _usageCost ????????????
     * @param _subscriptionCost ????????????
     */
    constructor (address _platformTokenAddress, uint256 _setupCost, uint256 _usageCost, uint256 _subscriptionCost) public {
        platformToken = IERC20(_platformTokenAddress);
        setupCost = _setupCost;
        usageCost = _usageCost;
        monthlySubscriptionCost = _subscriptionCost;
    }

    function create(bytes calldata _data) external returns(address);

    function getType() public view returns(uint8);

    function getName() public view returns(bytes32);

    function getDescription() public view returns(string memory);

    function getTitle() public view returns(string memory);

    function getInstructions() public view returns (string memory);

    function getTags() public view returns (bytes32[] memory);

    function getSig(bytes memory _data) internal pure returns (bytes32 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint i = 0; i < len; i++) {
            sig = bytes32(uint(sig) + uint8(_data[i]) * (2 ** (8 * (len - 1 - i))));
        }
    }

    
    /**
     * @dev ??????????????????
     * @param _newSetupCost ??????????????????
     */
    function changeFactorySetupFee(uint256 _newSetupCost) public onlyOwner {
        emit LogChangeFactorySetupFee(setupCost, _newSetupCost, address(this));
        setupCost = _newSetupCost;
    }

    /**
     * @dev ??????????????????
     * @param _newUsageCost ??????????????????
     */
    function changeFactoryUsageFee(uint256 _newUsageCost) public onlyOwner {
        emit LogChangeFactoryUsageFee(usageCost, _newUsageCost, address(this));
        usageCost = _newUsageCost;
    }

    /**
     * @dev ??????????????????
     * @param _newSubscriptionCost ??????????????????
     */
    function changeFactorySubscriptionFee(uint256 _newSubscriptionCost) public onlyOwner {
        emit LogChangeFactorySubscriptionFee(monthlySubscriptionCost, _newSubscriptionCost, address(this));
        monthlySubscriptionCost = _newSubscriptionCost;
        
    }

}

/**
 * @dev ??????????????????
 */
contract IPermissionManager {

    /**
     * @dev ????????????
     */
    function checkPermission(address _delegateAddress, address _moduleAddress, bytes32 _perm) public view returns(bool);

    /**
     * @dev ????????????
     */
    function changePermission(address _delegateAddress, address _moduleAddress, bytes32 _perm, bool _valid) public returns(bool);

    /**
     * @dev ??????????????????
     */
    function getDelegateDetails(address _delegateAddress) public view returns(bytes32);

}

contract IERC20Extend is IERC20 {

    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool);

    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool);
}

contract IERC20Detail is IERC20 {

    constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract StandardToken is IERC20,IERC20Detail,IERC20Extend {

    using SafeMath for uint256;
    

    mapping(address => uint256) balances;

    uint256 totalSupply_;

    mapping (address => mapping (address => uint256)) internal allowed;

    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

    function balanceOf(address who) public view returns (uint256){
        return balances[who];
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool){

        require(to != address(0), "Invalid address");

        require(balances[msg.sender] >= value, "Insufficient tokens transferable");

        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);

        emit Transfer(msg.sender, to, value);

        return true;
    }

    function approve(address spender, uint256 value) public returns (bool){

        require(balances[msg.sender] >= value, "Insufficient tokens approval");

        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {

        require(to != address(0), "Invalid address");
        require(balances[from] >= value, "Insufficient tokens transferable");
        require(allowed[from][msg.sender] >= value, "Insufficient tokens allowable");

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);

        emit Transfer(from, to, value);

        return true;
    }

    function increaseApproval(address spender, uint256 value) public returns(bool) {

        require(balances[msg.sender] >= value, "Insufficient tokens approval");

        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(value);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);

        return true;
    }

    function decreaseApproval(address spender, uint256 value) public returns(bool){

        uint256 oldApproval = allowed[msg.sender][spender];

        if(oldApproval > value){
            allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(value);
        }else {
            allowed[msg.sender][spender] = 0;
        }

        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);

        return true;
    }
}

/**
 * @title Security Token Exchange Protocol ???STEP 1.0???
 */
contract ISTEP is StandardToken {

    string public tokenDetails;

    // ????????????
    event LogMint(address indexed _to, uint256 _amount);

    /**
     * @notice ????????????
     * @param _from ???????????????
     * @param _to ???????????????
     * @param _amount ??????
     */
    function verifyTransfer(address _from, address _to, uint256 _amount) public returns (bool);

    /**
     * @notice ??????
     * @param _investor ???????????????
     * @param _amount token??????
     */
    function mint(address _investor, uint256 _amount) public returns (bool);

}

contract ISecurityToken is ISTEP, Ownable {
    
    uint8 public constant PERMISSIONMANAGER_KEY = 1;
    uint8 public constant TRANSFERMANAGER_KEY = 2;
    uint8 public constant STO_KEY = 3;
    
    // ???????????????????????????????????????
    uint256 public granularity;

    uint256 public investorCount;

    address[] public investors;

    /**
     * @notice ????????????
     * @param _delegate ????????????
     * @param _module ????????????
     * @param _perm ?????????
     */
    function checkPermission(address _delegate, address _module, bytes32 _perm) public view returns(bool);
    
    /**
     * @notice ????????????
     * @param _moduleType ????????????
     * @param _moduleIndex ????????????
     */
    function getModule(uint8 _moduleType, uint _moduleIndex) public view returns (bytes32, address);

    /**
     * @notice ????????????????????????
     * @param _moduleType ????????????
     * @param _name ?????????
     */
    function getModuleByName(uint8 _moduleType, bytes32 _name) public view returns (bytes32, address);

    /**
     * @notice ?????????????????????
     */
    function getInvestorsLength() public view returns(uint256);

    
}

/**
 * @title ????????????
 */
contract IModule {

    // ????????????
    address public factoryAddress;

    // ST??????
    address public securityTokenAddress;

    bytes32 public constant FEE_ADMIN = "FEE_ADMIN";

    // ?????????
    IERC20 public platformToken;

    /**
     * @notice ?????????
     */
    constructor (address _securityTokenAddress, address _platformTokenAddress) public {
        securityTokenAddress = _securityTokenAddress;
        factoryAddress = msg.sender;
        platformToken = IERC20(_platformTokenAddress);
    }

    function getInitFunction() public pure returns (bytes4);


    modifier withPerm(bytes32 _perm) {
        bool isOwner = msg.sender == ISecurityToken(securityTokenAddress).owner();
        bool isFactory = msg.sender == factoryAddress;
        require(isOwner || isFactory || ISecurityToken(securityTokenAddress).checkPermission(msg.sender, address(this), _perm), "Permission check failed");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == ISecurityToken(securityTokenAddress).owner(), "Sender is not owner");
        _;
    }

    modifier onlyFactory {
        require(msg.sender == factoryAddress, "Sender is not factory");
        _;
    }

    modifier onlyFactoryOwner {
        require(msg.sender == IModuleFactory(factoryAddress).owner(), "Sender is not factory owner");
        _;
    }

    function getPermissions() public view returns(bytes32[] memory);

    function takeFee(uint256 _amount) public withPerm(FEE_ADMIN) returns(bool) {
        require(platformToken.transferFrom(address(this), IModuleFactory(factoryAddress).owner(), _amount), "Unable to take fee");
        return true;
    }
}

/**
 * @dev ????????????
 */
contract GeneralPermissionManager is IModule, IPermissionManager {


    mapping (address => mapping (address => mapping (bytes32 => bool))) public perms;

    mapping (address => bytes32) public delegateDetails;


    // ???????????????
    bytes32 public constant CHANGE_PERMISSION = "CHANGE_PERMISSION";

    // ??????????????????
    event LogChangePermission(address _delegateAddress, address _moduleAddress, bytes32 _perm, bool _valid, uint256 _timestamp);

    // ??????????????????
    event LogAddPermission(address _delegateAddress, bytes32 _details, uint256 _timestamp);

    // ????????????
    constructor (address _securityTokenAddress, address _platformTokenAddress) public
    IModule(_securityTokenAddress, _platformTokenAddress)
    {
    }

    function getInitFunction() public pure returns (bytes4) {
        return bytes4(0);
    }

    /**
     * @dev ????????????
     */
    function checkPermission(address _delegateAddress, address _moduleAddress, bytes32 _perm) public view returns(bool) {
        if (delegateDetails[_delegateAddress] != bytes32(0)) {
            return perms[_moduleAddress][_delegateAddress][_perm];
        }else
            return false;
    }

    /**
     * @dev ????????????
     */
    function addPermission(address _delegateAddress, bytes32 _details) public withPerm(CHANGE_PERMISSION) {
        delegateDetails[_delegateAddress] = _details;
        emit LogAddPermission(_delegateAddress, _details, now);
    }

    /**
     * @dev ????????????
     */
    function changePermission(
        address _delegateAddress,
        address _moduleAddress,
        bytes32 _perm,
        bool _valid
    )
    public
    withPerm(CHANGE_PERMISSION)
    returns(bool)
    {
        require(delegateDetails[_delegateAddress] != bytes32(0), "Delegate details not set");
        perms[_moduleAddress][_delegateAddress][_perm] = _valid;
        emit LogChangePermission(_delegateAddress, _moduleAddress, _perm, _valid, now);
        return true;
    }

    /**
     * @dev ??????????????????
     */
    function getDelegateDetails(address _delegateAddress) public view returns(bytes32) {
        return delegateDetails[_delegateAddress];
    }

    /**
     * @dev ????????????
     */
    function getPermissions() public view returns(bytes32[] memory) {
        bytes32[] memory allPermissions = new bytes32[](1);
        allPermissions[0] = CHANGE_PERMISSION;
        return allPermissions;
    }
}

/**
  * @dev ???????????????????????????
  */
contract GeneralPermissionManagerFactory is IModuleFactory {

    
    /**
     * @dev ???????????????????????????????????????
     */
    constructor (address _paltformTokenAddress, uint256 _setupCost, uint256 _usageCost, uint256 _subscriptionCost) public
      IModuleFactory(_paltformTokenAddress, _setupCost, _usageCost, _subscriptionCost)
    {

    }

    /**
     * @dev ????????????
     */
    function create(bytes calldata /* data */) external returns(address) {
        // ????????????????????????
        if(setupCost > 0){
            require(platformToken.transferFrom(msg.sender, owner, setupCost), "Failed transferFrom because of sufficent Allowance is not provided");
        }
        // ????????????
        address permissionManagerAddress = address(new GeneralPermissionManager(msg.sender, address(platformToken)));

        // ????????????
        emit LogGenerateModuleFromFactory(permissionManagerAddress, getName(), address(this), msg.sender, now);

        return permissionManagerAddress;
    }

    
    function getType() public view returns(uint8) {
        return 1;
    }

    
    function getName() public view returns(bytes32) {
        return "PermissionManager";
    }

    function getDescription() public view returns(string memory) {
        return "Manage permissions within the Security Token and attached modules";
    }

    
    function getTitle() public  view returns(string memory) {
        return "Permission Manager";
    }

    function getInstructions() public view returns(string memory) {
        return "Add and remove permissions for the SecurityToken and associated modules. Permission types should be encoded as bytes32 values, and attached using the withPerm modifier to relevant functions.No initFunction required.";
    }

    function getTags() public view returns(bytes32[] memory) {
        bytes32[] memory availableTags = new bytes32[](0);
        return availableTags;
    }
}