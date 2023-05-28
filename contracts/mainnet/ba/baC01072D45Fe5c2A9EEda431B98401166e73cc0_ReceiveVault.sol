/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BBGGGGGPPPPGGGGBB##&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&#BGPPPPPPPPPPPPPPPPPPPPPPPGGB#&@@@@@@@@@@@@#GGB&@@@@@@@
@@@@@@@@@@@@@@@@@@@@@&#GPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPG#&@@@@@@@#GPPPP#@@@@@@@
@@@@@@@@@@@@@@@@@@@&BPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPG#@@&BGPPPPPP#@@@@@@@
@@@@@@@@@@@@@@@@@&GPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGBGPPPPPPPP#@@@@@@@
@@@@@@@@@@@@@@@@BPPPPPPPPGGGGGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@@@
@@@@@@@@@@@@@@&GPPGGB#&&&@@@@@@&&&#BBGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@@@
@@@@@@@@@@@@@&PPB#@@@@@@@@@@@@@@@@@@@@&#BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@@@
@@@@@@@@@@@@&GB&@@@@@@@@@@@@@@@@@@@@@@@@@@&#GPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@@@
@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#GPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#PPPPPPPPPPPPPPPPPPPPPPP#@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GPPPPPPPPPPPPPPPPPPPPPPP#@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@@@
@@@@@[email protected]@@@@@@@BGPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@@@
@@@@@[email protected]@@@@@@#PPPPPPPPPPPPPPPPPPPPPPPPPPPPP#@@@@@@@
@@@@@GPPPPPPPPPPPPPPPPPPPPPPPPPPB&@@@@@@@@@&###########################&@@@@@@@@
@@@@@GPPPPPPPPPPPPPPPPPPPPPPPPB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@GPPPPPPPPPPPPPPPPPPPPPPG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@GPPPPPPPPPPPPPPPPPPPPPPPB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@GPPPPPPPPPPPPPPPPPPPPPPPPPGB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@
@@@@@GPPPPPPPPPPPPPPPPPPPPPPPPPPPPGB#&@@@@@@@@@@@@@@@@@@@@@@&#[email protected]@@@@@@@@@@@@@@@
@@@@@GPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPGB#&&@@@@@@@@@@@@@&&BGPPG&@@@@@@@@@@@@@@@@
@@@@@[email protected]@@@@@@@@@@@@@@@@@
@@@@@GPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPG#@@@@@@@@@@@@@@@@@@@
@@@@@GPPPPPPPB&&BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPG#@@@@@@@@@@@@@@@@@@@@@
@@@@@PPPPPPB&@@@@@#BGPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPPB#@@@@@@@@@@@@@@@@@@@@@@@
@@@@@GPPGB&@@@@@@@@@@&BGPPPPPPPPPPPPPPPPPPPPPPPPPPPGB#@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@&&@@@@@@@@@@@@@@@@@&#BGGPPPPPPPPPPPPPPPGGBB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&#########&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/                                          

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

pragma solidity >=0.8.4;

pragma experimental ABIEncoderV2;

interface IReceiveVault {
    function open(uint collateral, uint amount, uint id, uint synid) external;
    function close(uint id) external;
    function deposit(uint id, uint collateral) external;
    function withdraw(uint id, uint amount) external;
    function burn(uint id, uint amount) external;
    function mint(uint id, uint amount) external;
    function liquidate(uint id, address account, uint amount) external;
}

interface pToken {

function mint(address _to, uint256 _amount) external returns (bool);
function burn(address _from, uint256 _amount) external returns (bool);
function balanceOf(address account) external view returns (uint256);

}    

contract ReceiveVault is IReceiveVault {
    
    using SafeERC20 for IERC20;
    
    struct Safe {
        uint id;                    // ID for the Safe
        address payable account;    //  Acccount that created the Safe
        uint collateral;            //  Amount of collateral deposited
        uint amount;                //  Amount of pToken minted
        uint lastInteraction;       // Time of last interaction.
        uint stableToken;           // Underline contract
        uint synToken;
    }
    
    struct TokenInfo {
        IERC20 stableToken;           
        uint underlyingContractDecimals;
        bool canMint;
    }
    
    struct SynInfo {
        pToken synToken;
        address oracle;
        bool canMint;
        bool nasdaqTimer;
        uint minCratio;
    }
    
   address public admin; 
   address public collector;
   bool public canMint = true;
   // bool public nasdaqTimer = true;
   uint public totalSafes = 0;
   // uint public minCratio;
   uint public maxCollateral;
   uint public minCollateral;
   uint public maxSafes = 50;
   uint public startTime = 1617595200;
   
   
   TokenInfo[] public tokenInfo;
   SynInfo[] public synInfo;
   mapping(address => Safe[]) public safes;
   
   event Open(address indexed account, uint indexed id, uint amount, uint collateral, uint stableToken, uint synToken);
   event Close(address indexed account, uint indexed id);
   event Deposit(address indexed account, uint indexed id, uint collateral);
   event Withdraw(address indexed account, uint indexed id, uint amount);
   event Burn(address indexed account, uint indexed id, uint amount);
   event Mint(address indexed account, uint indexed id, uint amount);
   event Liquidate(address indexed account, address indexed liquidator, uint indexed id, uint collateral, uint amount, uint fee);
   
    constructor(    
        uint _maxCollateral,
        uint _minCollateral,
        address _collector
    ) {
        admin = msg.sender;
        collector = _collector;
        maxCollateral = _maxCollateral;
        minCollateral = _minCollateral;
    }

    function open(uint collateral, uint amount, uint id, uint synid) external override {
        
        SynInfo storage syn = synInfo[synid];
        TokenInfo storage token = tokenInfo[id];
        
        require(syn.canMint == true && token.canMint == true && canMint == true, "Market closed");
        require(getNumSafes(msg.sender) <= maxSafes, "Max safes reached");
        
        if (syn.nasdaqTimer == true) {
            uint nasdaqTime = (block.timestamp - startTime) % 86400;
            require(nasdaqTime > 34200 && nasdaqTime < 57600 && (block.timestamp - startTime) % 604800 < 432000, "Market closed");
        }
        
        require(collateral <= token.stableToken.allowance(msg.sender, address(this)), "Allowance not high enough");
        token.stableToken.safeTransferFrom(msg.sender, address(this), collateral);
        
        if (token.underlyingContractDecimals < 1000000000000000000) {
            collateral = collateral * token.underlyingContractDecimals;
        }
        
        require(collateral >= minCollateral, "Not enough collateral to open");
        require(collateral <= maxCollateral, "Too much collateral to open");
        
        if (amount > 0) {
            
            (, int price, uint startedAt, uint updatedAt, ) = AggregatorV3Interface(syn.oracle).latestRoundData();
            require(price > 0 && startedAt > 0 && updatedAt > 0, "Zero is not valid");
            
            uint maxAmount = collateral * 10000000000000000000 / (uint(price) * syn.minCratio);
            if (maxAmount % 10 >= 5) {
                maxAmount += 10;
            }
            maxAmount = maxAmount / 10;
            amount = amount > maxAmount ? maxAmount : amount;
        }
        
        totalSafes = totalSafes + 1;
        
        safes[msg.sender].push(Safe({
            id: totalSafes,
            account: payable(msg.sender),
            collateral: collateral,
            amount: amount,
            lastInteraction: block.number,
            stableToken: id + 1,
            synToken: synid + 1
        }));
        
        if (amount > 0) {
            syn.synToken.mint(msg.sender, amount);
        }
        
        emit Open(msg.sender, totalSafes, amount, collateral, id, synid);
    }
    
    function getSafe(address account, uint256 safeID) public view returns (Safe memory) {
        Safe[] memory accountSafes = safes[account];
        Safe memory Safe_;
        for (uint i = 0; i < accountSafes.length; i++) {
            if (accountSafes[i].id == safeID) {
                Safe_ = (accountSafes[i]);
            }
        }
        return Safe_;
    }
    
    function updateSafe(Safe memory safe) internal {
        Safe[] storage accountSafes = safes[safe.account];
        for (uint i = 0; i < accountSafes.length; i++) {
            if (accountSafes[i].id == safe.id) {
                safes[safe.account][i] = safe;
            }
        }
    }
    
    function getNumSafes(address account) public view returns (uint numSafes) {
        return safes[account].length;
    }
    
    function close(uint id) external override {
        
        Safe memory safe = getSafe(msg.sender, id);
        
        require(safe.collateral > 0, "Safe closed");
        require(safe.lastInteraction < block.number, "Safe recently interacted with");
        require(msg.sender == safe.account, "Only issuer");
        
        SynInfo storage syn = synInfo[safe.synToken - 1];
        
        if (safe.amount > 0) {
            require(syn.synToken.balanceOf(msg.sender) >= safe.amount, "Not enough PToken balance");
            syn.synToken.burn(msg.sender, safe.amount);
        }
    
        uint collateral = safe.collateral;
        
        safe.amount = 0;
        safe.collateral = 0;
        safe.lastInteraction = block.number;
        updateSafe(safe);
        
        TokenInfo storage token = tokenInfo[safe.stableToken - 1];
        
        if (token.underlyingContractDecimals < 1000000000000000000) {
            collateral = collateral * 10 / token.underlyingContractDecimals;
            if (collateral % 10 >= 5) {
                collateral += 10;
            }
            collateral = collateral / 10;
        }
        
        uint fee = collateral / 10;
        if (fee % 10 >= 5) {
            fee += 10;
        }
        fee = fee / 10;        
    
        token.stableToken.safeTransfer(collector, fee);   
        token.stableToken.safeTransfer(msg.sender, collateral - fee);  
        
        emit Close(msg.sender, id);
    }    
    
    function deposit(uint id, uint collateral) external override {
        
        Safe memory safe = getSafe(msg.sender, id);
        TokenInfo storage token = tokenInfo[safe.stableToken - 1];
        
        require(token.canMint == true, "Market closed");
        
        require(collateral <= token.stableToken.allowance(msg.sender, address(this)), "Allowance not high enough");
        token.stableToken.safeTransferFrom(msg.sender, address(this), collateral);
        
        if (token.underlyingContractDecimals < 1000000000000000000) {
            collateral = collateral * token.underlyingContractDecimals;
        }
        
        require(safe.lastInteraction < block.number, "Safe recently interacted with");
        require(msg.sender == safe.account, "Only issuer");
        require(safe.collateral > 0, "Safe closed");
        require(collateral > 1000000000000000000, "Collateral too small");
        require((safe.collateral + collateral) <= maxCollateral, "maxAmount collateral reached");
        
        safe.collateral = safe.collateral + collateral;
        safe.lastInteraction = block.number;
        updateSafe(safe);
        
        emit Deposit(msg.sender, id, collateral);
    } 
    
    function withdraw(uint id, uint amount) external override {
        
        Safe memory safe = getSafe(msg.sender, id);
        SynInfo storage syn = synInfo[safe.synToken - 1];
        TokenInfo storage token = tokenInfo[safe.stableToken - 1];
        
        require(syn.canMint == true && canMint == true, "Market closed");
        
        if (syn.nasdaqTimer == true) {
            uint nasdaqTime = (block.timestamp - startTime) % 86400;
            require(nasdaqTime > 34200 && nasdaqTime < 57600 && (block.timestamp - startTime) % 604800 < 432000, "Market closed");
        }
        
        require(safe.lastInteraction < block.number, "Safe recently interacted with");
        require(msg.sender == safe.account, "Only issuer");
        require(amount > 0, "Cant withdraw 0");
        
        if (token.underlyingContractDecimals < 1000000000000000000) {
            amount = amount * token.underlyingContractDecimals;
        }
        
        require((safe.collateral - amount) >= minCollateral, "Min collateral reached");
    
        (, int price, uint startedAt, uint updatedAt, ) = AggregatorV3Interface(syn.oracle).latestRoundData();
        require(price > 0 && startedAt > 0 && updatedAt > 0, "Zero is not valid");
        
        uint maxAmount = ((safe.collateral * 1000000000000000000) - (safe.amount * uint(price) * syn.minCratio)) / 100000000000000000;
        
        if (maxAmount % 10 >= 5) {
           maxAmount += 10;
        }
        maxAmount = maxAmount / 10;
        amount = amount > maxAmount ? maxAmount : amount;
        
        safe.collateral = safe.collateral - amount;
        safe.lastInteraction = block.number;
        updateSafe(safe);
        
        if (token.underlyingContractDecimals < 1000000000000000000) {
            amount = amount * 10 / token.underlyingContractDecimals;
            if (amount % 10 >= 5) {
                amount += 10;
            }
            amount = amount / 10;            
        }
             
        uint fee = amount / 10;
        if (fee % 10 >= 5) {
           fee += 10;
        }
        fee = fee / 10;        
        
        token.stableToken.safeTransfer(collector, fee); 
        token.stableToken.safeTransfer(msg.sender, amount - fee);
        
        emit Withdraw(msg.sender, id, amount);
    }
    
    function burn(uint id, uint amount) external override {
    
        Safe memory safe = getSafe(msg.sender, id);
        
        require(safe.collateral > 0, "Safe closed");
        require(safe.lastInteraction < block.number, "Safe recently interacted with");
        require(msg.sender == safe.account, "Only issuer");
        require(amount > 0, "Cant burn zero");
        require(safe.amount >= amount, "Cant burn more");
        
        safe.amount = safe.amount - amount;
        safe.lastInteraction = block.number;
        updateSafe(safe);
        
        SynInfo storage syn = synInfo[safe.synToken - 1];
        
        require(syn.synToken.balanceOf(msg.sender) >= amount, "Not enough PToken balance");
        syn.synToken.burn(msg.sender, amount);
        
        emit Burn(msg.sender, id, amount);
    }
    
    function mint(uint id, uint amount) external override {
        
        Safe memory safe = getSafe(msg.sender, id);
        SynInfo storage syn = synInfo[safe.synToken - 1];
        
        require(syn.canMint == true && canMint == true, "Market closed");
        
        if (syn.nasdaqTimer == true) {
            uint nasdaqTime = (block.timestamp - startTime) % 86400;
            require(nasdaqTime > 34200 && nasdaqTime < 57600 && (block.timestamp - startTime) % 604800 < 432000, "Market closed");
        }
        
        require(safe.collateral >= minCollateral, "Min collateral reached");
        require(safe.lastInteraction < block.number, "Safe recently interacted with");
        require(msg.sender == safe.account, "Only issuer");
        require(amount > 0, "Cant mint zero");
        
        (, int price, uint startedAt, uint updatedAt, ) = AggregatorV3Interface(syn.oracle).latestRoundData();
        require(price > 0 && startedAt > 0 && updatedAt > 0, "Zero is not valid");
        
        uint maxAmount = ((safe.collateral * 1000000000000000000) - (safe.amount * uint(price) * syn.minCratio)) * 10 / (uint(price) * syn.minCratio);
        if (maxAmount % 10 >= 5) {
           maxAmount += 10;
        }
        maxAmount = maxAmount / 10;
        amount = amount > maxAmount ? maxAmount : amount;
        
        safe.amount = safe.amount + amount;
        safe.lastInteraction = block.number;
        updateSafe(safe);
        
        syn.synToken.mint(msg.sender, amount);
        
        emit Mint(msg.sender, id, amount);
    }
    
    function liquidate(uint id, address account, uint amount) external override {
        
        Safe memory safe = getSafe(account, id);
        SynInfo storage syn = synInfo[safe.synToken - 1];
        
        require(syn.canMint == true && canMint == true, "Market closed");
        
        if (syn.nasdaqTimer == true) {
            uint nasdaqTime = (block.timestamp - startTime) % 86400;
            require(nasdaqTime > 34200 && nasdaqTime < 57600 && (block.timestamp - startTime) % 604800 < 432000, "Market closed");
        }
        
        require(safe.collateral > 0, "Safe closed");
        require(safe.lastInteraction < block.number, "Safe recently interacted with");
        require(amount > 0, "Cant burn zero");
        require(safe.amount >= amount, "Cant burn more");
        
        (, int price, uint startedAt, uint updatedAt, ) = AggregatorV3Interface(syn.oracle).latestRoundData();
        require(price > 0 && startedAt > 0 && updatedAt > 0, "Zero is not valid");
        
        require(safe.collateral * 1000000000000000000 / (safe.amount * uint(price)) < syn.minCratio, "Collateral too high");
        
        require(syn.synToken.balanceOf(msg.sender) >= amount, "Not enough PToken balance");
        syn.synToken.burn(msg.sender, amount);
        
        uint collateral = safe.collateral * amount * 10000000000000000000 / (safe.amount * 1000000000000000000);
            if (collateral % 10 >= 5) {
                collateral += 10;
            }
        collateral = collateral / 10;
        
        safe.collateral = safe.collateral - collateral;
        safe.amount = safe.amount - amount;
        safe.lastInteraction = block.number;
        updateSafe(safe);
        
        TokenInfo storage token = tokenInfo[safe.stableToken - 1];
        
        if (token.underlyingContractDecimals < 1000000000000000000) {
            collateral = collateral * 10 / token.underlyingContractDecimals;
            if (collateral % 10 >= 5) {
                collateral += 10;
            }
            collateral = collateral / 10;            
        }
        
        uint fee = collateral / 5;
        if (fee % 10 >= 5) {
           fee += 10;
        }
        fee = fee / 10;       
        
        collateral = collateral - fee;
        
        uint liquidationFee = collateral * 8;
        if (liquidationFee % 10 >= 5) {
           liquidationFee += 10;
        }
        liquidationFee = liquidationFee / 10; 
        
        token.stableToken.safeTransfer(collector, fee);
        token.stableToken.safeTransfer(msg.sender, liquidationFee);
        token.stableToken.safeTransfer(safe.account, collateral - liquidationFee);
        
        emit Liquidate(safe.account, msg.sender, id, collateral, amount, fee);
    }
    
    function setAdmin(address _admin) external {
        require(msg.sender == admin, "Admin only");
        admin = _admin;
    }
    
    function setCanMint(bool _canMint) external {
        require(msg.sender == admin, "Admin only");
        canMint = _canMint;
    }
    
    
    function setCollector(address _collector) external {
        require(msg.sender == admin, "Admin only");
        collector = _collector;
    }
    
    function setMinCollateral(uint _minCollateral) external {
        require(msg.sender == admin, "Admin only");
        minCollateral = _minCollateral;
    }
    
    function setMaxCollateral(uint _maxCollateral) external {
        require(msg.sender == admin, "Admin only");
        maxCollateral = _maxCollateral;
    }
    
    function setStartTime(uint _startTime) external {
        require(msg.sender == admin, "Admin only");
        startTime = _startTime;
    }
    
    function setSynCanMint(bool _canMint, uint id) external {
        require(msg.sender == admin, "Admin only");
        synInfo[id].canMint = _canMint;
    }
    
    function setStableTokenCanMint(bool _canMint, uint id) external {
        require(msg.sender == admin, "Admin only");
        tokenInfo[id].canMint = _canMint;
    }
    
    function setSynOracle(address _oracle, uint id) external {
        require(msg.sender == admin, "Admin only");
        synInfo[id].oracle = _oracle;
    }
    
    function addStableToken(IERC20 _stableToken, uint256 _underlyingContractDecimals, bool _canMint) external {
        require(msg.sender == admin, "Admin only");
        tokenInfo.push(TokenInfo({
        stableToken: _stableToken,
        underlyingContractDecimals: _underlyingContractDecimals,
        canMint: _canMint
        }));
    }
    
    function addSynToken(pToken _synToken, address _oracle, bool _canMint, bool _nasdaqTimer, uint _minCratio) external {
        require(msg.sender == admin, "Admin only");
        synInfo.push(SynInfo({
        synToken: _synToken,
        oracle: _oracle,
        canMint: _canMint,
        nasdaqTimer: _nasdaqTimer,
        minCratio: _minCratio
        }));
    }
    
}

// File: @openzeppelin/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}



pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

    using Address for address;
    
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }



    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}