// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import './TokenSale.sol';
import './CrowdSaleBonus.sol';

contract CrowdSale is TokenSale {

    uint256 public startTime = 0;
    uint256 public endTime = 0;

    CrowdSaleBonus[] private bonuses;

    constructor(
        address _saleAddress,
        address payable _beneficiary,
        uint256 _tokensForSale,
        uint256 _tokensPerETH,
        uint256 _decimals,
        uint256 _startTime, // 1646179604 | March 2nd, 2022 06:44 GMT
        uint256 _endTime // 1648318680 | March 26th 2022, 18:18 GMT
    ) TokenSale(
        _saleAddress,
        address(0),
        _beneficiary,
        _tokensForSale,
        _tokensPerETH,
        _decimals
    ) lessThan(_startTime, _endTime) {
        startTime = _startTime;
        endTime = _endTime;
        // Add a fallback 1x bonus
        bonuses.push(new CrowdSaleBonus(1, 0, _startTime, _endTime));
    }

    /**
        Adds a bonus multiplier for the period of time specified
    */
    function addBonusMultiplier(
        uint256 _multiplier,
        uint256 _decimals,
        uint256 _startTime,
        uint256 _endTime
    ) saleNotActive ownerRestricted public {
        bonuses.push(new CrowdSaleBonus(_multiplier, _decimals, _startTime, _endTime));
    }

    /**
        Checks if pre-start conditions are met for the sale
    */
    function isStartable() public view virtual override returns (bool) {
        return super.isStartable() && endTime <= token.CROWDSALE_END_TIME();
    }

    /**
        Checks if the sale is active
    */
    function isActive() public view virtual override returns (bool) {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            return false;
        }
        return super.isActive();
    }

    /**
        Returns the equivalent value of tokens for the ETH provided with the bonus multiplier
    */
    function getTotalTokensForETH(uint256 _eth) public view virtual override returns (uint256) {
        uint256 totalTokens = super.getTotalTokensForETH(_eth);
        return getTotalTokensWithBonus(totalTokens);
    }

    /**
        Checks for the highest active bonus multiplier, if there is none active it returns 1
    */
    function getTotalTokensWithBonus(uint256 _totalTokens) internal view returns (uint256) {
        CrowdSaleBonus bonus = findActiveBonus();
        return bonus.calculateAmountWithBonus(_totalTokens);
    }

    /**
        Checks for an active bonus with the highest multiplier
    */
    function findActiveBonus() internal view returns (CrowdSaleBonus activeBonus) {
        uint256 assigned = 0;
        for (uint256 index = 0; index < bonuses.length; index++) {
            CrowdSaleBonus bonus = bonuses[index];
            if (bonus.isActive() == false) {
                continue;
            }

            if (assigned != 0 && bonus.multiplier() < activeBonus.multiplier()) {
                continue;
            }

            assigned = 1;
            activeBonus = bonus;
        }
        return activeBonus;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

contract Math {
    /**
        Validates that the first value is less than the second
    */
    modifier lessThan(uint256 _a, uint256 _b) {
        assert(_a < _b);
        _;
    }

    /**
        Returns the sum of _a and _b, asserts if the calculation overflows
    */
    function safeAdd(uint256 _a, uint256 _b) pure internal returns (uint256) {
        uint256 z = _a + _b;
        assert(z >= _a);
        return z;
    }

    /**
        Returns the difference of _a minus _b, asserts if the subtraction results in a negative number
    */
    function safeSub(uint256 _a, uint256 _b) pure internal returns (uint256) {
        assert(_a >= _b);
        return _a - _b;
    }

    /**
        Returns the product of multiplying _a by _b, asserts if the calculation overflows
    */
    function safeMul(uint256 _a, uint256 _b) pure internal returns (uint256) {
        uint256 z = _a * _b;
        assert(_a == 0 || z / _a == _b);
        return z;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

contract Address {
    /**
        Verifies that the address is not null
    */
    modifier isValidAddress(address _address) {
        assert(_address != address(0));
        _;
    }

    /**
        Verifies that the address does not match the one provided
    */
    modifier isNotAddress(address _address, address _restricted) {
        assert(_address != _restricted);
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

interface IERC20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import './ERC20Token.sol';
import './Owned.sol';
import './TeamTranche.sol';
import './TokenSale.sol';

contract TruthereumToken is ERC20Token, Owned {

    // Constants
    string constant private NAME = "Truthereum";
    string constant private SYMBOL = "TRE";
    uint8 constant private DECIMALS = 18;

    uint256 constant private TOKEN_UNIT = 10 ** DECIMALS;
    uint256 constant private TOTAL_SUPPLY = 5488039296144 * TOKEN_UNIT;
    uint256 constant public PUBLIC_SUPPLY = 4168188989144 * TOKEN_UNIT;
    uint256 constant public TEAM_SUPPLY = 1319850307000 * TOKEN_UNIT;
    
    uint256 constant public CROWDSALE_END_TIME = 1650151353; // 1650151353 April 16th, 2022 11:22:33 GMT
    uint256 constant public MAX_SALE_AMOUNT = 120736864515 * TOKEN_UNIT; // Never more than 2.2% of the total supply

    // 12.5% every 3 months is distributed to the teams
    TeamTranche[] private TEAM_TRANCHES = [
        new TeamTranche(1654041600, 164981288375 * TOKEN_UNIT), // June 1st 2022, 00:00 GMT
        new TeamTranche(1661990400, 164981288375 * TOKEN_UNIT), // September 1st 2022, 00:00 GMT
        new TeamTranche(1669852800, 164981288375 * TOKEN_UNIT), // December 1st 2022, 00:00 GMT
        new TeamTranche(1677628800, 164981288375 * TOKEN_UNIT), // March 1st 2023, 00:00 GMT
        new TeamTranche(1685577600, 164981288375 * TOKEN_UNIT), // June 1st 2023, 00:00 GMT
        new TeamTranche(1693526400, 164981288375 * TOKEN_UNIT), // September 1st 2023, 00:00 GMT
        new TeamTranche(1701388800, 164981288375 * TOKEN_UNIT), // December 1st 2023, 00:00 GMT
        new TeamTranche(1709251200, 164981288375 * TOKEN_UNIT) // March 1st 2024, 00:00 GMT
    ];

    // Variables
    uint256 public totalAllocated = 0;
    uint256 public totalTeamReleased = 0;

    address public publicAddress;
    address public teamAddress;
    address public saleAddress = address(0);

    TokenSale tokenSale;

    // Modifiers
    modifier saleAddressRestricted() {
        require(msg.sender == saleAddress, 'ERROR: Can only be called from the saleAddress');
        _;
    }

    constructor(address _publicAddress, address _teamAddress) ERC20Token(NAME, SYMBOL, DECIMALS, TOTAL_SUPPLY) {
        publicAddress = _publicAddress;
        teamAddress = _teamAddress;
        balanceOf[_publicAddress] = PUBLIC_SUPPLY;
    }

    /**
        Starts a new token sale, only one can be active at a time and the total amount for sale must be
        less than the public supply still available for distribution
    */
    function addTokenSale(address payable _saleAddress) isValidAddress(_saleAddress) ownerRestricted public {
        require(isSaleWindow() == false, 'ERROR: There is already an active sale');
        tokenSale = TokenSale(_saleAddress);
        require(tokenSale.isStartable() == true, 'ERROR: The sale is not in a startable state');
        uint256 tokensForSale = tokenSale.tokensForSale();
        require(
            tokensForSale <= balanceOf[publicAddress] &&
            (hasCrowdsaleEnded() == false || tokensForSale <= MAX_SALE_AMOUNT),
            'ERROR: There sale amount exceeds the public balance or max sale amount'
        );
        saleAddress = _saleAddress;
        allowance[publicAddress][saleAddress] = tokensForSale;
    }

    /**
        Ends the current token sale and returns and outstanding unsold amount to the public address
    */
    function endTokenSale() saleAddressRestricted public {
        require(isSaleWindow() == true, 'ERROR: There is no sale active');
        address unsoldAddress = tokenSale.unsoldAddress();

        // The crowdsale will not have an unsold address
        if (unsoldAddress != address(0)) {
            uint256 unsoldTokens = tokenSale.availableForSale();
            balanceOf[unsoldAddress] = unsoldTokens;
            balanceOf[publicAddress] = safeSub(balanceOf[publicAddress], unsoldTokens);
        }
        
        allowance[publicAddress][saleAddress] = 0;
        saleAddress = address(0);
    }

    /**
        Handles the transfer if the crowdsale has ended or the sender is the public address
    */
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        if (hasCrowdsaleEnded() == true || msg.sender == publicAddress) {
            assert(super.transfer(_to, _value));
            return true;
        }
        revert();        
    }

    /**
        Handles the transfer from if the crowdsale has ended or the sender is the public address
    */
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        if (hasCrowdsaleEnded() == true || _from == publicAddress) {  
            assert(super.transferFrom(_from, _to, _value));
            return true;
        }
        revert();
    }

    /**
        Iterates through all of the team tranches and attempts to release them
    */
    function releaseTeamTranches() ownerRestricted public {
        require(totalTeamReleased < TEAM_SUPPLY, 'ERROR: The entire team supply has already been released');
        for (uint index = 0; index < TEAM_TRANCHES.length; index++) {
            releaseTeamTranche(TEAM_TRANCHES[index]);
        }
    }

    /**
        Releases the team tranche if the release conditions are met
    */
    function releaseTeamTranche(TeamTranche _tranche) internal returns(bool) {
        if (_tranche.isReleasable() == false) {
            return false;
        }
        balanceOf[teamAddress] = safeAdd(balanceOf[teamAddress], _tranche.amount());
        emit Transfer(address(0), teamAddress, _tranche.amount());
        totalAllocated = safeAdd(totalAllocated, _tranche.amount());
        totalTeamReleased = safeAdd(totalTeamReleased, _tranche.amount());
        _tranche.setReleased();
        return true;
    }

    /**
        Adds to the total amount of tokens allocated
    */
    function addToAllocation(uint256 _amount) public saleAddressRestricted {
        totalAllocated = safeAdd(totalAllocated, _amount);
    }

    /**
        Checks if the crowdsale has ended
    */
    function hasCrowdsaleEnded() public view returns(bool) {
        if (block.timestamp > CROWDSALE_END_TIME) {
            return true;
        }
        return false;
    }

    /**
        Checks if it is currently a sale window
    */
    function isSaleWindow() public view returns(bool) {
        if (saleAddress == address(0)) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import './TruthereumToken.sol';
import './Owned.sol';

contract TokenSale is Owned {

    // Variables
    address public tokenAddress = address(0); // address of the token itself
    address public saleAddress; // address where the tokens are stored
    address public unsoldAddress; // address to send any unsold tokens to
    address payable public beneficiary; // address to receive ETH contributions
    uint256 public tokensForSale;
    uint256 public tokensPerETH;

    TruthereumToken token;

    // Events
    event SaleContribution(address _contributor, uint256 _amount, uint256 _return);

    // Modifiers
    modifier saleActive() {
        require(isActive() == true, 'ERROR: There is currently no active sale');
        _;
    }

    modifier saleNotActive() {
        require(isActive() == false, 'ERROR: There is currently an active sale');
        _;
    }

    constructor(
        address _saleAddress,
        address _unsoldAddress,
        address payable _beneficiary,
        uint256 _tokensForSale,
        uint256 _tokensPerETH,
        uint256 _decimals
    ) {
        saleAddress = _saleAddress;
        unsoldAddress = _unsoldAddress;
        beneficiary = _beneficiary;
        tokensForSale = safeMul(_tokensForSale, (10 ** _decimals));
        tokensPerETH = _tokensPerETH;
    }

    /**
        Checks if pre-start conditions are met for the sale
    */
    function isStartable() isValidAddress(tokenAddress) public view virtual returns (bool) {
        return true;
    }

    /**
        Checks if the sale is active
    */
    function isActive() public view virtual returns (bool) {
        if (tokenAddress == address(0)) {
            return false;
        }
        if (availableForSale() <= 0) {
            return false;
        }
        return true;
    }

    /**
        Returns the total amount of tokens still available in this sale
    */
    function availableForSale() public view returns (uint256) {
        return token.allowance(saleAddress, address(this));
    }

    /**
        Sets the token variable, this can only be done once
    */
    function setToken(address _tokenAddress) isValidAddress(_tokenAddress) ownerRestricted public {
        require(tokenAddress == address(0), 'ERROR: The tokenAddress must be 0x0');
        tokenAddress = _tokenAddress;
        token = TruthereumToken(_tokenAddress);
    }

    /**
        Sets the address to receive the ETH contributions
    */
    function setBeneficiary(address payable _beneficiary) isValidAddress(_beneficiary) ownerRestricted public {
        beneficiary = _beneficiary;
    }

    /**
        Ends the token sale and no longer allows for contributions
    */
    function endSale() ownerRestricted public {
        token.endTokenSale();
    }

    /**
        Handles ETH contributions and validates the address before further processing
    */
    function handleETHContribution(address _to) public payable saleActive isValidAddress(_to) returns (uint256) {
        return handleContribution(_to);
    }

    /**
        Transfers the ETH to the beneficiary and transfers the amount of tokens in return
    */
    function handleContribution(address _to) isNotAddress(_to, token.publicAddress()) private returns (uint256) {
        uint256 tokens = getTotalTokensForETH(msg.value);
        require(availableForSale() > tokens, 'ERROR: There are not enough tokens available to cover the contribution');
        beneficiary.transfer(msg.value);
        token.transferFrom(token.publicAddress(), _to, tokens);
        token.addToAllocation(tokens);
        emit SaleContribution(_to, msg.value, tokens);
        return tokens;
    }

    /**
        Returns the equivalent value of tokens for the ETH provided 
    */
    function getTotalTokensForETH(uint256 _eth) public view virtual returns (uint256) {
        return safeMul(_eth, tokensPerETH);
    }

    /**
        The entry point to purchase tokens
    */
    receive() payable external {
        handleETHContribution(msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import './Owned.sol';

contract TeamTranche is Owned {
    uint256 public releaseTime;
    uint256 public amount;

    bool private released = false; 

    constructor(uint256 _releaseTime, uint256 _amount) {
        releaseTime = _releaseTime;
        amount = _amount;
    }

    /**
        Checks if the tranche can be released
    */
    function isReleasable() public view returns (bool) {
        if (released == true) return false;
        return block.timestamp > releaseTime;
    }

    /**
        Updated the tranches released value to true
    */
    function setReleased() ownerRestricted public {
        released = true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import './utilities/Address.sol';
import './utilities/Math.sol';

contract Owned is Address, Math {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /**
        A modifier to only allow modifications by the owner of the contract
    */
    modifier ownerRestricted {
        require(msg.sender == owner, 'ERROR: Can only be called from the owner');
        _;
    }

    /**
        Reassigns the owner to the contract specified
    */
    function assignOwner(address _address) ownerRestricted isValidAddress(_address) isNotAddress(_address, owner) public {
        owner = _address;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import './interfaces/IERC20Token.sol';
import './utilities/Address.sol';
import './utilities/Math.sol';

contract ERC20Token is IERC20Token, Address, Math {
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        require(bytes(_name).length > 0, 'ERROR: No name was provided');
        require(bytes(_symbol).length > 0, 'ERROR: No symbol was provided');

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
    }

    function transfer(address _to, uint256 _value) public virtual isValidAddress(_to) returns (bool success) {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        public virtual
        isValidAddress(_from)
        isValidAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        isValidAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowance[msg.sender][_spender] == 0, 'ERROR: Cannot approve as the allowance or value is 0');

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import './Owned.sol';

contract CrowdSaleBonus is Owned {
    uint256 public multiplier;
    uint256 public decimals;
    uint256 public startTime;
    uint256 public endTime;

    constructor(uint256 _multiplier, uint256 _decimals, uint256 _startTime, uint256 _endTime) lessThan(_startTime, _endTime) {
        multiplier = _multiplier;
        decimals = _decimals;
        startTime = _startTime;
        endTime = _endTime;
    }

    /**
        Checks if the bonus is active
    */
    function isActive() public view returns (bool) {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            return false;
        }
        return true;
    }

    /**
        Gets the amount with the bonus included
    */
    function calculateAmountWithBonus(uint256 _amount) public view returns (uint256) {
        uint256 divisor = 10 ** decimals;
        uint256 divided = divisor > 0 ? (_amount / divisor) : _amount;
        return safeMul(divided, multiplier);
    }
}