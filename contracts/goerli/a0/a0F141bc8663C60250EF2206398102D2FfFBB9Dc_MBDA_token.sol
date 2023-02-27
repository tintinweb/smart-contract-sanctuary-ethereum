pragma solidity 0.8.17;

// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // Metadata optional
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

/**
 * @title MBDA_token is a template for MB Digital Asset token
 * */
contract MBDA_token is IERC20 {
    //
    // events
    //

    // mint/burn events
    event Mint(address indexed to, uint256 amount, uint256 newTotalSupply);
    event Burn(address indexed from, uint256 amount, uint256 newTotalSupply);

    // admin events
    event BlockLockSet(uint256 value);
    event AdditionalInfoSet(string _additionalInfo);
    event AdminTransfer(address oldAdmin, address newAdmin);
    event backupAdminTransfer(address oldBackupAdmin, address newBackupAdmin);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this operation");
        _;
    }

    modifier adminOrbackupAdmin() {
        require(
            msg.sender == admin || msg.sender == backupAdmin,
            "Only admin or backupAdmin can perform this operation"
        );
        _;
    }

    modifier onlyBackupAdmin() {
        require(
            msg.sender == backupAdmin,
            "Only backupAdmin can perform this operation"
        );
        _;
    }

    modifier onlyIfMintable() {
        require(mintable, "Token minting is disabled");
        _;
    }

    modifier blockLock() {
        if (msg.sender != admin)
            require(
                lockedUntilBlock <= block.number,
                "Contract is locked except for the admin"
            );
        _;
    }

    address public admin;
    address public backupAdmin;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    string public financialDetailsURL;
    string public additionalInfo;
    bool public mintable;
    uint256 public lockedUntilBlock;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /**
     * @dev Constructor
     * @param _backupAdmin - Contract backcup admin
     * @param _name - Detailed ERC20 token name
     * @param _symbol - ERC20 token symbol
     * @param _decimals - ERC20 decimal units
     * @param _totalSupply - Total Supply owned, inittialy owned by the admin
     * @param _lockedUntilBlock - Block lock
     * @param _financialDetailsURL - Link of a document containting a description of the token
     * @param _mintable - Specifies if the token is mintable
     */
    constructor(
        address _backupAdmin,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply,
        uint256 _lockedUntilBlock,
        string memory _financialDetailsURL,
        bool _mintable
    ) {
        require(_decimals <= 18, "Decimal units should be 18 or lower");
        require(
            _backupAdmin != address(0),
            "Invalid backupAdmin: null address"
        );
        require(
            _backupAdmin != msg.sender,
            "Admin and backupAdmin cannot be the same address"
        );

        // Metadata
        name = _name;
        decimals = _decimals;
        symbol = _symbol;

        // Addresses
        admin = msg.sender;
        backupAdmin = _backupAdmin;

        // Balances
        totalSupply = _totalSupply;
        balanceOf[admin] = _totalSupply;

        // Last details
        lockedUntilBlock = _lockedUntilBlock;
        financialDetailsURL = _financialDetailsURL;
        mintable = _mintable;

        emit Mint(admin, 0, _totalSupply);
        emit AdminTransfer(address(0), admin);
        emit backupAdminTransfer(address(0), _backupAdmin);
        emit BlockLockSet(_lockedUntilBlock);
    }

    /**
     * @dev ERC20 Transfer
     * @param _to - destination address
     * @param _value - value to transfer
     * @return True if success
     */
    function transfer(address _to, uint256 _value)
        external
        blockLock
        returns (bool)
    {
        require(_to != address(0), "Invalid receiver: null address");
        require(_to != address(this), "Invalid receiver: contract address");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @dev ERC20 Approve
     * @param _spender - destination address
     * @param _value - value to be approved
     * @return True if success
     */
    function approve(address _spender, uint256 _value)
        external
        blockLock
        returns (bool)
    {
        require(_spender != address(0), "Invalid spender: null address");
        require(_spender != address(this), "Invalid spender: contract address");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * @dev ERC20 TransferFrom
     * @param _from - source address
     * @param _to - destination address
     * @param _value - value
     * @return True if success
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external blockLock returns (bool) {
        require(_to != address(0), "Invalid sender: null address");
        require(_to != address(this), "Invalid sender: contract address");

        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    /**
     * @dev Burn tokens
     * @param _account - address
     * @param _value - value
     * @return True if success
     */
    function burn(address payable _account, uint256 _value)
        external
        onlyAdmin
        blockLock
        returns (bool)
    {
        totalSupply -= _value;
        balanceOf[_account] -= _value;

        emit Burn(_account, _value, totalSupply);
        emit Transfer(_account, address(0), _value);

        return true;
    }

    /**
     * @dev Mint new tokens. Can only be called by minter or owner
     * @param _to - destination address
     * @param _value - value
     * @return True if success
     */
    function mint(address _to, uint256 _value)
        external
        onlyIfMintable
        onlyAdmin
        blockLock
        returns (bool)
    {
        balanceOf[_to] += _value;
        totalSupply += _value;

        emit Mint(_to, _value, totalSupply);
        emit Transfer(address(0), _to, _value);

        return true;
    }

    /**
     * @dev Set additional info
     * @param _additionalInfo - AdditionalInfo
     * @return True if success
     */
    function setAdditionalInfo(string memory _additionalInfo)
        public
        onlyAdmin
        returns (bool)
    {
        additionalInfo = _additionalInfo;

        emit AdditionalInfoSet(_additionalInfo);

        return true;
    }

    /**
     * @dev Set block lock. Until that block (exclusive) transfers are disallowed
     * @param _lockedUntilBlock - Block Number
     * @return True if success
     */
    function setBlockLock(uint256 _lockedUntilBlock)
        external
        onlyAdmin
        returns (bool)
    {
        lockedUntilBlock = _lockedUntilBlock;

        emit BlockLockSet(_lockedUntilBlock);

        return true;
    }

    /**
     * @dev Replace current admin with new one
     * @param _newAdmin New token admin
     * @return True if success
     */
    function replaceAdmin(address _newAdmin)
        external
        adminOrbackupAdmin
        returns (bool)
    {
        require(_newAdmin != address(0), "Invalid admin: null address");
        require(_newAdmin != address(this), "Invalid admin: contract address");
        require(
            _newAdmin != backupAdmin,
            "Admin and backupAdmin cannot be the same address"
        );

        admin = _newAdmin;

        emit AdminTransfer(admin, _newAdmin);

        return true;
    }

    function replaceBackupAdmin(address _newBackupAdmin)
        external
        adminOrbackupAdmin
        returns (bool)
    {
        require(
            _newBackupAdmin != address(0),
            "Invalid backupAdmin: null address"
        );
        require(
            _newBackupAdmin != address(this),
            "Invalid backupAdmin: contract address"
        );
        require(
            _newBackupAdmin != admin,
            "Admin and backupAdmin cannot be the same address"
        );

        backupAdmin = _newBackupAdmin;

        emit backupAdminTransfer(backupAdmin, _newBackupAdmin);

        return true;
    }
}