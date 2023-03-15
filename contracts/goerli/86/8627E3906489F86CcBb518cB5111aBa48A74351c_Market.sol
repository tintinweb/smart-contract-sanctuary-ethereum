/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// SPDX-License-Identifier: GPL-3.0

// File: contracts/Seastead.sol


pragma solidity ^0.8.17;

interface IMarket {
    function delistSale(address payable) external;

    function activeSales(address) external view returns (bool);

    function getAdmin() external returns (address payable[] memory);

    function tokenPrice() external returns (uint32);

    function steadToken() external returns (address);
}

interface IOps {
    function payDues(
        address _operator,
        address _seastead,
        uint48 _amount,
        uint48 _steadTokens
    ) external returns (bool);

    function voidOperations(address _operator) external returns (bool);
}

interface ISteadtoken {
    function balanceOf(address) external view returns (uint256);

    function generateSupply(uint48 amount) external returns (bool);

    function reduceSupply(uint48 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function decimals() external pure returns (uint8);
}

interface IUSDC {
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Seastead {
    address public operator;
    bool public sold;
    bool public operational;

    uint8 public bracingGirders;
    uint8 public platformGirders;

    uint32 public tokenSold;
    uint48 public tokenPrice;
    uint48 public totalTokens;

    uint8 private constant _deci = 6;
    uint48 private amountWithdrawn;
    address private _token;
    address payable[] private admin = new address payable[](3);
    IOps private Operations;

    uint32 public immutable totalCost;
    uint48 public immutable index;
    uint64 public immutable serialNumber;

    uint8 private immutable exp;
    IMarket private immutable Market;
    ISteadtoken private immutable SteadToken;
    IUSDC private immutable USDC;

    /**
     *@dev _admin is used for additional security. Making sure that the seastead
     * deployment is coming from the same marketplace that's controlled by the
     * Arkpad admin.
     * @param platform the seastead platform code
     * @param bracing the seastead bracing code
     * @param _totalCost the total cost of building the seastead (USD)
     * @param serial the seastead serial number
     * @param _USDC the USDC token address. This ensures we are really accepting the
     * legitimate USDC.
     */
    constructor(
        address payable[] memory _admin,
        uint8 platform,
        uint8 bracing,
        uint32 _totalCost,
        uint48 _index,
        uint64 serial,
        address _USDC
    ) {
        // Initialise the Market interface:
        Market = IMarket(msg.sender);
        admin = Market.getAdmin();
        require(_admin[0] == admin[0], "102");
        require(_admin[1] == admin[1], "102");
        require(_admin[2] == admin[2], "102");
        require(_admin[3] == admin[3], "102");

        _token = Market.steadToken();
        require(address(_token) != address(0x0), "202");

        // Initialise the SteadToken interface:
        SteadToken = ISteadtoken(_token);
        exp = 2 * SteadToken.decimals();

        platformGirders = platform;
        bracingGirders = bracing;

        tokenPrice = Market.tokenPrice();
        totalCost = _totalCost;
        amountWithdrawn = 0;

        index = _index;
        serialNumber = serial;

        totalTokens = uint48((_totalCost * (10 ** exp)) / tokenPrice);

        bool success = SteadToken.generateSupply(totalTokens);
        require(success, "301");

        // Initialise the USDC interface:
        USDC = IUSDC(_USDC);
    }

    modifier adminOnly() {
        require(
            msg.sender == admin[0] ||
                msg.sender == admin[1] ||
                msg.sender == admin[2] ||
                msg.sender == admin[3],
            "100"
        );
        _;
    }

    /**
     * @dev The buy transaction. The user has to authorise the seastead to
     * spend on his/her behalf first via ERC20 increaseAllowance. Once confirm,
     * this function can be invoke to make the USDC and Stead Token transfers
     * @param _USDCPayment the amount of USDC paid in exchange for tokens.
     * @return _tokens the amount of transferred tokens (prompt only)
     */
    function buyTokens(uint64 _USDCPayment) external returns (uint48) {
        require(Market.activeSales(address(this)), "401");
        uint48 _tokens = uint48((_USDCPayment * 10 ** _deci) / tokenPrice);
        uint48 _currentBalance = uint48(SteadToken.balanceOf(address(this)));
        require(_currentBalance >= _tokens, "402");

        bool success = USDC.transferFrom(
            msg.sender,
            address(this),
            _USDCPayment
        );
        require(success, "403");
        SteadToken.transfer(msg.sender, _tokens);
        return _tokens;
    }

    /**
     * @dev Burns tokens
     * @param _steadTokens the amount of tokens to be burned
     */
    function burnTokens(uint48 _steadTokens) external returns (bool) {
        require(operational == true, "411");
        if (msg.sender != operator) {
            require(
                msg.sender == admin[0] ||
                    msg.sender == admin[1] ||
                    msg.sender == admin[2] ||
                    msg.sender == admin[3],
                "104"
            );
        } else {
            require(msg.sender == operator, "104");
        }
        require(address(SteadToken) != address(0x0), "202");
        uint48 marketPrice = Market.tokenPrice();
        uint48 _amount = _steadTokens / marketPrice;
        _amount = uint48(_amount * (10 ** _deci));

        bool paid = Operations.payDues(
            operator,
            address(this),
            _amount,
            _steadTokens
        );
        require(paid == true, "404 Unpaid");

        bool success = SteadToken.reduceSupply(_steadTokens);
        require(success == true, "404");

        totalTokens -= _steadTokens;
        return success;
    }

    /**
     * @dev Cancels a seastead for sale by delisting it
     */
    function cancel() external adminOnly {
        require(operational == true, "411");
        bool success = Operations.voidOperations(operator);
        require(success == true, "409");
        Market.delistSale(payable(address(this)));
        operator = address(0x0);
    }

    /**
     * @dev gets the address of this seastead
     * @return address the address of this seastead
     */
    function getAddress() external view returns (address payable) {
        return payable(address(this));
    }

    /**
     * @dev sets the operations contract
     * This is Operations for now; it could be extended to mortgage
     * or other types of operational requirements
     * @param _operations address of the governing contract
     */
    function setOperations(
        address _operations,
        address _operator
    ) external adminOnly {
        require(operational == false, "410");
        Operations = IOps(_operations);
        operational = true;
        operator = _operator;
    }

    /**
     * @dev The function used by the admin to withdraw USDC from the seastead sale.
     * The funds will be used for the seastead production/building
     */
    function withdraw(uint48 _amount) external adminOnly returns (bool) {
        require(amountWithdrawn <= totalCost, "405");
        uint48 _usdcAmount = uint48(_amount * (10 ** _deci));
        bool success = USDC.transfer(msg.sender, _usdcAmount);
        amountWithdrawn += _amount;
        return success;
    }
}

// File: contracts/Arkpad.sol


pragma solidity ^0.8.17;

/**
 * @dev Arkpad contains the implementation regarding the controls
 * admin wallet assignments and removal. The first admin is the
 * wallet address which made the contract deployment.
 */
abstract contract Arkpad {
    address payable[] internal admin = new address payable[](4);
    address payable internal approver = payable(address(0x0));
    bool internal approved = false;

    constructor() {
        admin[0] = payable(msg.sender);
        admin[1] = payable(address(0x0));
        admin[2] = payable(address(0x0));
        admin[3] = payable(address(0x0));
    }

    /**
     * @dev Events which may be monitored via front-end or other off-chain apps
     */
    event adminApproved(address payable _approver);

    event adminAssigned(
        address payable indexed _by,
        address payable indexed _assigned
    );

    event adminRemoved(
        address payable indexed _by,
        address payable indexed _removed
    );

    event adminReplaced(
        address payable indexed _by,
        address payable indexed _removed,
        address payable indexed _from
    );

    event adminRequest(
        address payable indexed _by,
        address payable indexed _approver
    );

    /**
     * @dev Admin access restriction
     */
    modifier byArkpadOnly() {
        require(
            msg.sender == admin[0] ||
                msg.sender == admin[1] ||
                msg.sender == admin[2] ||
                msg.sender == admin[3]
        );
        _;
    }

    /**
     * @dev Ensures that the number of admin wallet addresses is limited
     */
    modifier limitIndex(uint8 _index) {
        require(_index >= 0 && _index < 4);
        _;
    }

    /**
     * Adds an admin wallet account
     */
    function addAdmin(address payable newAdmin, uint8 index)
        external
        limitIndex(index)
        byArkpadOnly
    {
        require(admin[index] == payable(address(0x0)));
        admin[index] = newAdmin;
        emit adminAssigned(payable(msg.sender), newAdmin);
    }

    /**
     * @dev Allows the nominated admin wallet to approve the request
     */
    function approveAdmin() external byArkpadOnly {
        require(msg.sender == approver);
        approved = true;
        emit adminApproved(approver);
    }

    /**
     * @dev Request for admin wallet removal
     */
    function removeAdmin(address payable currentAdmin, uint8 index)
        external
        limitIndex(index)
        byArkpadOnly
    {
        require(approved);
        if (admin[index] == currentAdmin) {
            admin[index] = payable(address(0x0));
        }
        approved = false;
        emit adminRemoved(payable(msg.sender), currentAdmin);
    }

    /**
     * @dev Request for admin wallet replacement
     */
    function replaceAdmin(
        address payable currentAdmin,
        address payable newAdmin,
        uint8 index
    ) external byArkpadOnly limitIndex(index) {
        require(approved);
        if (admin[index] == currentAdmin) {
            admin[index] = newAdmin;
        }
        approved = false;
        emit adminReplaced(newAdmin, currentAdmin, payable(msg.sender));
    }

    /**
     * @dev Request for admin wallet approval. Required by both
     * replaceAdmin and removeAdmin
     */
    function requestAdmin(address payable _approver) external {
        require(msg.sender != _approver);
        approver = _approver;
        emit adminRequest(payable(msg.sender), _approver);
    }
}

// File: contracts/Market.sol


pragma solidity ^0.8.17;



/**
 * @dev The main Marketplace contract; only deployed once.
 */
contract Market is Arkpad {
    uint48 public salesCount;
    uint48 public tokenPrice;
    address payable public lastDeployed;
    mapping(address => bool) public activeSales; // handled via implicit conversion

    uint16 private monthlyPeriods;
    uint24 private ratePeriod;
    uint256 private deployTime;
    address payable[] private arkpadSales;

    address public immutable steadToken;
    address private immutable _USDC;

    /**
     * @param _ratePeriod uint24, specifices the period of token price updates in seconds,
     * e.g. 30 days = 2592000s
     * @param _USDCAddress address, the USDC address in the Ethereum Network
     * @param _steadToken address, the Stead Token deployed address
     */
    constructor(
        uint24 _ratePeriod,
        address _USDCAddress,
        address _steadToken
    ) {
        tokenPrice = 10**6;
        salesCount = 0;
        monthlyPeriods = 1;
        ratePeriod = _ratePeriod;
        deployTime = block.timestamp;
        _USDC = _USDCAddress;
        steadToken = _steadToken;
    }

    /**
     * @dev Creates the Seastead sale in the marketplace. This function is exclusive to the marketplace
     * Restricted to admin
     * @param platform the seastead platform code
     * @param bracing the seastead bracing code
     * @param _totalCost the total cost of building the seastead (USD)
     * @param serial the seastead serial number
     */
    function createSale(
        uint8 platform,
        uint8 bracing,
        uint32 _totalCost,
        uint64 serial
    ) external byArkpadOnly {
        Seastead newSale = new Seastead(
            admin,
            platform,
            bracing,
            _totalCost,
            salesCount,
            serial,
            _USDC
        );
        arkpadSales.push(payable(address(newSale)));
        activeSales[address(newSale)] = true;
        salesCount++;
        lastDeployed = payable(address(newSale));
    }

    /**
     * @dev delists the seastead and prevents it from selling further tokens.
     * Invoked by the seastead itself
     */
    function delistSale(address payable sold) external {
        require(msg.sender == sold, "101");
        activeSales[sold] = false;
    }

    /**
     * @dev updates the token price based on the ratePeriod; makes use of the
     * internal function updateTokenPrice
     * This function is invoked externally via Chainlink Upkeep
     */
    function setPriceUpdate() external {
        require(
            block.timestamp >= deployTime + (ratePeriod * monthlyPeriods),
            "201"
        );
        tokenPrice = updateTokenPrice(tokenPrice);
        monthlyPeriods++;
    }

    /**
     * @dev Gets the admin wallet addresses in a single array
     * @return admin array of addresses
     */
    function getAdmin() external view returns (address payable[] memory) {
        return admin;
    }

    /**
     * @dev Gets the created seastead sales addresses in a single array
     * @return arkpadSales array of addresses
     */
    function getArkpadSales() external view returns (address payable[] memory) {
        return arkpadSales;
    }

    /**
     * @dev internal function to update the token price
     * @param currentPrice current token price
     * @return uint48 the updated token price
     */
    function updateTokenPrice(uint48 currentPrice)
        internal
        pure
        returns (uint48)
    {
        return (currentPrice * 10065) / 10**4;
    }
}