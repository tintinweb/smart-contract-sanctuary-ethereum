/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


interface ISwapFactory {
    function balanceCallback(address hashAddress, uint256 foreignBalance) external returns(bool);
    function balancesCallback(
        address hashAddress, 
        uint256 foreignBalance, // total user's tokens balance on foreign chain
        uint256 foreignSpent,   // total tokens spent by SmartSwap pair
        uint256 nativeEncoded   // (nativeSpent, nativeRate) = _decode(nativeEncoded)
    ) external returns(bool);
}

// 1 - BNB, 2 - ETH, 3 - BTC, 4 - MATIC
interface ICompanyOracle {
    function getBalance(uint256 network,address token,address user) external returns(uint256);
    function getPriceAndBalance(address tokenA,address tokenB,uint256 network,address token,address[] calldata user) external returns(uint256);
}

interface IPriceFeed {
    function latestAnswer() external returns (int256);
}


contract Validator is Ownable {

    uint256 constant NETWORK = 137;  // ETH mainnet = 1, Ropsten = 3,Kovan - 42, BSC_TESTNET = 97, BSC_MAINNET = 56, MATIC = 137
    uint256 constant NOMINATOR = 10**18;     // rate nominator

    
    mapping(address => bool) public isAllowedAddress; 
    address public factory;
    address public companyOracle;
    mapping (uint256 => address) public companyOracleRequests;  // companyOracleRequest ID => user (hashAddress)
    mapping (uint256 => uint256) public gasLimit;  // request type => amount of gas
    uint256 public customGasPrice = 50 * 10**9; // 20 GWei
    mapping(address => IPriceFeed) tokenPriceFeed;

    event LogMsg(string description);

    modifier onlyAllowed() {
        require(isAllowedAddress[msg.sender] || owner() == msg.sender,"ERR_ALLOWED_ADDRESS_ONLY");
        _;
    }


    constructor (address _oracle) {
        companyOracle = _oracle;
        //Kovan Testnet
        //tokenPriceFeed[address(1)] = IPriceFeed(0x8993ED705cdf5e84D0a3B754b5Ee0e1783fcdF16);    // BNB/USD
        //tokenPriceFeed[address(2)] = IPriceFeed(0x9326BFA02ADD2366b30bacB125260Af641031331);    // ETH/USD
        // BSC Testnet
        //tokenPriceFeed[address(1)] = IPriceFeed(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);    // BNB/USD
        //tokenPriceFeed[address(2)] = IPriceFeed(0x143db3CEEfbdfe5631aDD3E50f7614B6ba708BA7);    // ETH/USD

        // ETH mainnet
        tokenPriceFeed[address(1)] = IPriceFeed(0x14e613AC84a31f709eadbdF89C6CC390fDc9540A);    // BNB/USD
        tokenPriceFeed[address(2)] = IPriceFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);    // ETH/USD
        tokenPriceFeed[address(4)] = IPriceFeed(0x7bAC85A8a13A4BcD8abb3eB7d6b4d632c5a57676);    // MATIC/USD
        // BSC mainnet
        //tokenPriceFeed[address(1)] = IPriceFeed(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);    // BNB/USD
        //tokenPriceFeed[address(2)] = IPriceFeed(0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e);    // ETH/USD
        //tokenPriceFeed[address(4)] = IPriceFeed(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);    // MATIC/USD



    }

    // returns rate (with 9 decimals) = Token B price / Token A price
    function getRate(address tokenA, address tokenB) external returns (uint256 rate) {
        int256 priceA = tokenPriceFeed[tokenA].latestAnswer();
        int256 priceB = tokenPriceFeed[tokenB].latestAnswer();
        require(priceA > 0 && priceB > 0, "Zero price");
        rate = uint256(priceB * int256(NOMINATOR) / priceA);     // get rate on BSC side: ETH price / BNB price
    }

    function setCompanyOracle(address _addr) external onlyOwner returns(bool) {
        companyOracle = _addr;
        return true;
    }

    function setFactory(address _addr) external onlyOwner returns(bool) {
        factory = _addr;
        return true;
    }

    function changeAllowedAddress(address _which,bool _bool) external onlyOwner returns(bool){
        isAllowedAddress[_which] = _bool;
        return true;
    }

    // returns: oracle fee
    function getOracleFee(uint256 req) external view returns(uint256) {  //req: 1 - cancel, 2 - claim, returns: value
        return gasLimit[req] * customGasPrice;
    }

    function checkBalance(address foreignFactory, address user) external returns(uint256) {
        require(msg.sender == factory, "Not factory");
        uint256 myId = ICompanyOracle(companyOracle).getBalance(NETWORK, foreignFactory, user);
        companyOracleRequests[myId] = user;
        return myId;
    }

    function oracleCallback(uint256 requestId, uint256 balance) external returns(bool) {
        require (companyOracle == msg.sender, "Wrong Oracle");
        address hashAddress = companyOracleRequests[requestId];
        require(hashAddress != address(0), "Wrong requestId");
        delete companyOracleRequests[requestId];   // requestId fulfilled
        ISwapFactory(factory).balanceCallback(hashAddress, balance);
        return true;
    }

    function checkBalances(address foreignFactory, address[] calldata users) external returns(uint256) {
        require(msg.sender == factory, "Not factory");
        uint256 myId = ICompanyOracle(companyOracle).getPriceAndBalance(address(1), address(2), NETWORK, foreignFactory, users);
        companyOracleRequests[myId] = users[0];
        return myId;
    }

    function oraclePriceAndBalanceCallback(uint256 requestId,uint256 priceA,uint256 priceB,uint256[] calldata balances) external returns(bool) {
        require (companyOracle == msg.sender, "Wrong Oracle");
        priceA = priceB; // remove unused
        address hashAddress = companyOracleRequests[requestId];
        require(hashAddress != address(0), "Wrong requestId");
        delete companyOracleRequests[requestId];   // requestId fulfilled
        ISwapFactory(factory).balancesCallback(hashAddress, balances[0], balances[1], balances[2]);
        return true;
    }

    function withdraw(uint256 amount) external onlyAllowed returns (bool) {
        payable(msg.sender).transfer(amount);
        return true;
    }

    // set gas limit to request: 1 - cancel request, 2 - claim request
    function setGasLimit(uint256 req, uint256 amount) external onlyAllowed returns (bool) {
        gasLimit[req] = amount;
        return true;
    }

    function setCustomGasPrice(uint256 amount) external onlyAllowed returns (bool) {
        customGasPrice = amount;
        //provable_setCustomGasPrice(amount);
        return true;
    }

    receive() external payable {}
}