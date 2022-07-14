// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import '../common/AccessControl.sol';

/**
 * @dev Partial interface of the ERC20.
 */
interface IERC20 {
    function decimals() external view returns (uint8);
}

/**
 * @dev Partial interface of the chain.link feed.
 */
interface IChain_Link {
    function decimals() external view returns (uint8);
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

/**
 * @dev Partial interface of the ERC20 standard according to the needs of the e2p contract.
 */
interface ILP {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112, uint112, uint32);
}

/*
 * This contract utilizes usd rate calculation for specific token contract using ChainLink feeds
 * or LP pairs with possibility of manual rate setting
 */
contract Rates is AccessControl {
    struct Rate {
        address chainLinkAddress; // ChainLink feed address
        address lpAddress; // LP pair contract
        uint8 decimals; // decimals of the token
        uint8 decimals0; // decimals of the token0 in LP pair
        uint8 decimals1; // decimals of the token1 in LP pair
        uint256 rate; // manually set rate
        uint256 cachedRate; // last saved price
        uint256 lastRate; // last saved price
        uint256 lastRateTime; // time when last price was saved
        bool reversed; // order of the token0 and token1 when rate is calculated
    }
    mapping (address => Rate) internal _usdRates;
    uint256 internal _maxTimeGap; // maximum time gap for real time requests
    uint256 internal _minRateUpdatePeriod; // minimal period between lastRate and current rate
    uint256 internal constant _SHIFT_18 = 1 ether;
    bytes32 internal constant MANAGER = keccak256(abi.encode('MANAGER'));
    bytes32 internal constant RATES_UPDATER = keccak256(abi.encode('RATES_UPDATER'));

    constructor (
        address newOwner,
        address ratesUpdater
    ) {
        require(newOwner != address(0), 'Owner address can not be zero');
        _owner = newOwner;
        _grantRole(MANAGER, newOwner);
        _grantRole(RATES_UPDATER, ratesUpdater);
        _maxTimeGap = 300; // initially set to 5 minutes
        _minRateUpdatePeriod = 3600; // initially set to 1 hour
    }

    /**
     * Setting of all necessary data for rate calculation for specific token using LP pair contract
     */
    function setLp (
        address contractAddress,
        address lpAddress
    ) external hasRole(MANAGER) returns (bool) {
        require(lpAddress != address(0), 'LP pair address can not be zero');
        _usdRates[contractAddress].lpAddress = lpAddress;
        ILP lpContract = ILP(lpAddress);
        address token0 = lpContract.token0();
        address token1 = lpContract.token1();

        if (token1 == contractAddress) {
            _usdRates[contractAddress].reversed = true;
        } else {
            require(token0 == contractAddress, 'LP pair does not match contract address');
        }
        _usdRates[contractAddress].decimals = IERC20(contractAddress).decimals();
        _usdRates[contractAddress].decimals0 = IERC20(token0).decimals();
        _usdRates[contractAddress].decimals1 = IERC20(token1).decimals();
        _usdRates[contractAddress].chainLinkAddress = address(0);
        _saveUsdRate(contractAddress);
        _usdRates[contractAddress].cachedRate = _usdRates[contractAddress].lastRate;

        return true;
    }


    /**
     * Setting of all necessary data for rate calculation for specific token using Chain Link feed
     */
    function setChainLink (
        address contractAddress,
        address chainLinkAddress
    ) external hasRole(MANAGER) returns (bool) {
        require(chainLinkAddress != address(0), 'Feed address can not be zero');
        if (contractAddress == address(0)) _usdRates[contractAddress].decimals = 18;
        else _usdRates[contractAddress].decimals = IERC20(contractAddress).decimals();
        _usdRates[contractAddress].chainLinkAddress = chainLinkAddress;
        _usdRates[contractAddress].lpAddress = address(0);
        return true;
    }

    /**
     * Setting of the rate for contract address (usd rate, decimals = 18)
     */
    function setUsdRate (
        address contractAddress,
        uint256 rate // with decimals 18
    ) external hasRole(MANAGER) returns (bool) {
        if (contractAddress == address(0)) _usdRates[contractAddress].decimals = 18;
        else _usdRates[contractAddress].decimals = IERC20(contractAddress).decimals();
        _usdRates[contractAddress].rate = rate;
        _usdRates[contractAddress].chainLinkAddress = address(0);
        _usdRates[contractAddress].lpAddress = address(0);
        return true;
    }

    /**
     * Setting of the maximum time gap for real time requests
     */
    function setMaxTimeGap (
        uint256 maxTimeGap
    ) external hasRole(MANAGER) returns (bool) {
        _maxTimeGap = maxTimeGap;
        return true;
    }

    /**
     * Setting of the minimal rate update period
     */
    function setMinRateUpdatePeriod (
        uint256 minRateUpdatePeriod
    ) external hasRole(MANAGER) returns (bool) {
        _minRateUpdatePeriod = minRateUpdatePeriod;
        return true;
    }

    /**
     * Updating last rate for rates calculation using LP
     */
    function saveUsdRate (
        address contractAddress
    ) external hasRole(RATES_UPDATER) returns (bool) {
        return _saveUsdRate(contractAddress);
    }

    /**
     * Setting of all necessary data for rate calculation for specific token
     */
    function _saveUsdRate (
        address contractAddress
    ) internal returns (bool) {
        require(_usdRates[contractAddress].lpAddress != address(0), 'LP contract is not set');
        if (
            (block.timestamp - _usdRates[contractAddress].lastRateTime) < _minRateUpdatePeriod
        ) return false;
        uint256 rate = _getUsdRateFromLp(contractAddress);
        if (rate == 0) return false;
        _usdRates[contractAddress].cachedRate = _usdRates[contractAddress].lastRate;
        _usdRates[contractAddress].lastRate = rate;
        _usdRates[contractAddress].lastRateTime = block.timestamp;
        return true;
    }

    /**
     * Getting of rate data set for specific token
     */
    function getUsdRateData (
        address contractAddress
    ) external view returns (
        address chainLinkAddress,
        address lpAddress,
        uint8 decimals,
        uint256 rate
    ) {
        return (
            _usdRates[contractAddress].chainLinkAddress,
            _usdRates[contractAddress].lpAddress,
            _usdRates[contractAddress].decimals,
            _usdRates[contractAddress].rate
        );
    }

    /**
     * Getting of LP specific rate data set for a contract address
     */
    function getLpRateData (
        address contractAddress
    ) external view returns (
        uint8 decimals0,
        uint8 decimals1,
        uint256 cachedRate,
        uint256 lastRate,
        uint256 lastRateTime,
        bool reversed
    ) {
        return (
            _usdRates[contractAddress].decimals0,
            _usdRates[contractAddress].decimals1,
            _usdRates[contractAddress].cachedRate,
            _usdRates[contractAddress].lastRate,
            _usdRates[contractAddress].lastRateTime,
            _usdRates[contractAddress].reversed
        );
    }

    /**
     * Getting of the usd rate for specific token. Rate is given using
     * decimals point shifting. Decimal exponent uses formula
     * 18 + (18 - token decimals). For any token when amount is multiplied
     * to the rate it will be equal to usd rate with 18 decimals
     */
    function getUsdRate (
        address contractAddress,
        bool realTime
    ) external view returns (uint256) {
        uint256 rate;
        if (_usdRates[contractAddress].chainLinkAddress != address(0)) {
            rate = _getChainLinkRate(contractAddress, realTime);
        } else if (_usdRates[contractAddress].lpAddress != address(0)) {
            rate = _getLpRate(contractAddress, realTime);
        } else {
            rate = _usdRates[contractAddress].rate;
        }
        require(rate > 0, 'Price feed error');
        return rate;
    }

    /**
     * Getting of the maximum time gap for real time requests
     */
    function getMaxTimeGap () external view returns (uint256) {
        return _maxTimeGap;
    }

    /**
     * Getting of the usd rate for specific token with last rate caching. Rate is given using
     * decimals point shifting. Decimal exponent uses formula
     * 18 + (18 - token decimals). For example if rate is 1.2 and
     * token decimals is 6 rate will be 1.2 * 10**30
     */
    function _getChainLinkRate (
        address contractAddress,
        bool realTime
    ) internal view returns (uint256) {
        require(_usdRates[contractAddress].chainLinkAddress != address(0), 'Rate feed is not set');
        IChain_Link feedContract = IChain_Link(_usdRates[contractAddress].chainLinkAddress);
        uint256 decimals = feedContract.decimals();
        (,int256 rate,,uint256 updatedAt,) = feedContract.latestRoundData();
        require(rate > 0, 'ChainLink feed error');
        require(!realTime || (block.timestamp - updatedAt) < _maxTimeGap, 'Rate data is outdated');
        uint256 result = uint256(rate);
        result *= _SHIFT_18;
        if (_usdRates[contractAddress].decimals < 18) {
            result *= 10 ** (18 - _usdRates[contractAddress].decimals);
        }
        return result / 10 ** decimals;
    }

    /**
     * Getting of the usd rate for specific token. Rate is given using
     * decimals point shifting. Decimal exponent uses formula
     * 18 + (18 - token decimals). For example if rate is 1.2 and
     * token decimals is 6 rate will be 1.2 * 10**30
     */
    function _getLpRate (
        address contractAddress,
        bool realTime
    ) internal view returns (uint256) {
        if (realTime) return _getUsdRateFromLp(contractAddress);
        else return _usdRates[contractAddress].cachedRate;
    }

    /**
     * Getting of the usd rate for specific token. Rate is given using
     * decimals point shifting. Decimal exponent uses formula
     * 18 + (18 - token decimals). For example if rate is 1.2 and
     * token decimals is 6 rate will be 1.2 * 10**30
     */
    function _getUsdRateFromLp (
        address contractAddress
    ) internal view returns (uint256) {
        require(_usdRates[contractAddress].lpAddress != address(0), 'LP contract is not set');
        ILP lpToken = ILP(_usdRates[contractAddress].lpAddress);
        (uint112 reserve0, uint112 reserve1,) = lpToken.getReserves();
        require(reserve0 > 0 && reserve1 > 0, 'Reserves request error');
        if (_usdRates[contractAddress].decimals0 < 18) {
            reserve0 *= uint112(10 ** (18 - _usdRates[contractAddress].decimals0));
        }
        if (_usdRates[contractAddress].decimals1 < 18) {
            reserve1 *= uint112(10 ** (18 - _usdRates[contractAddress].decimals1));
        }
        uint256 rate;
        if (_usdRates[contractAddress].reversed) {
            rate = _SHIFT_18
            * uint256(reserve0) / uint256(reserve1);
        } else {
            rate = _SHIFT_18
            * uint256(reserve1) / uint256(reserve0);
        }
        if (_usdRates[contractAddress].decimals < 18) {
            rate *= 10 ** (18 - _usdRates[contractAddress].decimals);
        }
        return rate;
    }

    /**
     * Getting of the minimal rate update period
     */
    function getMinRateUpdatePeriod () external view returns (uint256) {
        return _minRateUpdatePeriod;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
 * @dev Access control contract,
 * functions names are self explanatory
 */
contract AccessControl {
    modifier onlyOwner() {
        require(msg.sender == _owner, 'Caller is not the owner');
        _;
    }
    modifier hasRole(bytes32 role) {
        require(_checkRole(role, msg.sender), 'Caller is not authorized for this action'
        );
        _;
    }

    mapping (bytes32 => mapping(address => bool)) internal _roles;
    address internal _owner;

    constructor () {
        _owner = msg.sender;
    }

    /**
     * @dev Transfer ownership to another account
     */
    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), 'newOwner should not be zero address');
        _owner = newOwner;
        return true;
    }

    /**
     * @dev Grant role to account
     */
    function _grantRole (
        bytes32 role,
        address userAddress
    ) internal returns (bool) {
        _roles[role][userAddress] = true;
        return true;
    }

    /**
     * @dev Grant role to account
     */
    function grantRole (
        string memory role,
        address userAddress
    ) external onlyOwner returns (bool) {
        _grantRole(keccak256(abi.encode(role)), userAddress);
        return true;
    }

    /**
     * @dev Revoke role from account
     */
    function _revokeRole (
        bytes32 role,
        address userAddress
    ) internal returns (bool) {
        _roles[role][userAddress] = false;
        return true;
    }

    /**
     * @dev Revoke role from account
     */
    function revokeRole (
        string memory role,
        address userAddress
    ) external onlyOwner returns (bool) {
        _revokeRole(keccak256(abi.encode(role)), userAddress);
        return true;
    }

    /**
     * @dev Check is account has specific role
     */
    function _checkRole (
        bytes32 role,
        address userAddress
    ) internal view returns (bool) {
        return _roles[role][userAddress];
    }

    /**
     * @dev Check is account has specific role
     */
    function checkRole (
        string memory role,
        address userAddress
    ) external view returns (bool) {
        return _checkRole(keccak256(abi.encode(role)), userAddress);
    }

    /**
     * @dev Owner address getter
     */
    function owner() public view returns (address) {
        return _owner;
    }
}