/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
// WARNING this contract has not been independently tested or audited
// DO NOT use this contract with funds of real value until officially tested and audited by an independent expert or group

pragma solidity 0.8.11;

interface IERC20 {
    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    function balanceOf(address tokenOwner) external returns (uint256 balance);
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract LinearTimelock {
    // boolean to prevent reentrancy
    bool internal locked;

    // Library usage
    using SafeMath for uint256;

    // Contract owner
    address payable public owner;

    // Contract owner access
    bool public allIncomingDepositsFinalised;

    // Timestamp related variables
    // The epoch in seconds "as at" the time when the smart contract is initialized (via the setTimestamp function) by the owner
    uint256 public initialTimestamp;
    // Last time a recipient accessed the unlock function
    mapping(address => uint256) public mostRecentUnlockTimestamp;

    // Token amount variables
    mapping(address => uint256) public alreadyWithdrawn;
    mapping(address => uint256) public balances;
    uint256 public contractBalance;

    // ERC20 contract address
    IERC20 public erc20Contract;

    // to address
    address public ecologyAddress;
    address public privatePlacementAddress;
    address public teamAddress;

    // cliffEdge & releaseEdge
    mapping(address => uint256) public nextCliffTimestampMap;
    mapping(address => uint256) public unlockFrequencyMap;
    mapping(address => uint256) public unlockAmountPerFrequencyMap;

    // timestamp
    uint256 public quarterTimestamp = 540;
    uint256 public monthTimestamp = 180;

    // Events
    event TokensDeposited(address from, uint256 amount);
    event AllocationPerformed(address recipient, uint256 amount);
    event TokensUnlocked(address recipient, uint256 amount);

    /// @dev Deploys contract and links the ERC20 token which we are timelocking, also sets owner as msg.sender and sets timestampSet bool to false.
    /// @param _erc20_contract_address.
    constructor(IERC20 _erc20_contract_address) {
        // Allow this contract's owner to make deposits by setting allIncomingDepositsFinalised to false
        allIncomingDepositsFinalised = false;
        // Set contract owner
        owner = payable(msg.sender);
        // Set the erc20 contract address which this timelock is deliberately paired to
        require(
            address(_erc20_contract_address) != address(0),
            "_erc20_contract_address address can not be zero"
        );
        erc20Contract = _erc20_contract_address;
        // Initialize the reentrancy variable to not locked
        locked = false;
    }

    // Modifier
    /**
     * @dev Throws if allIncomingDepositsFinalised is true.
     */
    modifier incomingDepositsStillAllowed() {
        require(
            allIncomingDepositsFinalised == false,
            "Incoming deposits have been finalised."
        );
        _;
    }

    // Modifier
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Message sender must be the contract's owner."
        );
        _;
    }

    receive() external payable incomingDepositsStillAllowed {
        contractBalance = contractBalance.add(msg.value);
        emit TokensDeposited(msg.sender, msg.value);
    }

    // @dev Takes away any ability (for the contract owner) to assign any tokens to any recipients. This function is only to be called by the contract owner. Calling this function can not be undone. Calling this function must only be performed when all of the addresses and amounts are allocated (to the recipients). This function finalizes the contract owners involvement and at this point the contract's timelock functionality is non-custodial
    function finalizeAllIncomingDeposits()
        public
        onlyOwner
        incomingDepositsStillAllowed
    {
        allIncomingDepositsFinalised = true;
    }

    function initEcologyConfig(address _ecologyAdd, uint256 _cliffTimestamp, uint256 _unlockAmountPerFrequency) public onlyOwner {
        require(_ecologyAdd != address(0), "ERC20: transfer to the zero address");
        ecologyAddress = _ecologyAdd;
        nextCliffTimestampMap[_ecologyAdd] = _cliffTimestamp;
        unlockAmountPerFrequencyMap[_ecologyAdd] = _unlockAmountPerFrequency;
    }

    function initPrivatePlacementConfig(address _privatePlacementAdd, uint256 _cliffTimestamp, uint256 _unlockAmountPerFrequency) public onlyOwner {
        require(_privatePlacementAdd != address(0), "ERC20: transfer to the zero address");
        privatePlacementAddress = _privatePlacementAdd;
        nextCliffTimestampMap[_privatePlacementAdd] = _cliffTimestamp;
        unlockAmountPerFrequencyMap[_privatePlacementAdd] = _unlockAmountPerFrequency;
    }

    function initTeamConfig(address _teamAdd, uint256 _cliffTimestamp, uint256 _unlockAmountPerFrequency) public onlyOwner {
        require(_teamAdd != address(0), "ERC20: transfer to the zero address");
        teamAddress = _teamAdd;
        nextCliffTimestampMap[_teamAdd] = _cliffTimestamp;
        unlockAmountPerFrequencyMap[_teamAdd] = _unlockAmountPerFrequency;
    }

    /// @dev Function to withdraw Eth in case Eth is accidently sent to this contract.
    /// @param amount of network tokens to withdraw (in wei).
    function withdrawEth(uint256 amount) public onlyOwner {
        require(amount <= contractBalance, "Insufficient funds");
        contractBalance = contractBalance.sub(amount);
        // Transfer the specified amount of Eth to the owner of this contract
        owner.transfer(amount);
    }

    /// @dev Allows the contract owner to allocate official ERC20 tokens to each future recipient (only one at a time).
    /// @param recipient, address of recipient.
    /// @param amount to allocate to recipient.
    function depositTokens(address recipient, uint256 amount)
        public
        onlyOwner
    {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        balances[recipient] = balances[recipient].add(amount);
        emit AllocationPerformed(recipient, amount);
    }

    /// @dev Allows recipient to start linearly unlocking tokens (after cliffEdge has elapsed) or unlock up to entire balance (after releaseEdge has elapsed)
    /// @param token - address of the official ERC20 token which is being unlocked here.
    /// @param to - the recipient's account address.
    /// @param amount - the amount to unlock (in wei)
    function transferTimeLockedQuarter(
        IERC20 token,
        address to,
        uint256 amount
    ) public {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            balances[to] >= amount,
            "Insufficient token balance, try lesser amount"
        );
        require(
            msg.sender == to,
            "Only the token recipient can perform the unlock"
        );
        require(
            token == erc20Contract,
            "Token parameter must be the same as the erc20 contract address which was passed into the constructor"
        );
        require(
            block.timestamp > nextCliffTimestampMap[to] + quarterTimestamp,
            "Tokens are only available after correct time period has elapsed"
        );
        // Ensure that the amount is available to be unlocked at this current point in time
        alreadyWithdrawn[to] = alreadyWithdrawn[to].add(amount);
        balances[to] = balances[to].sub(amount);
        mostRecentUnlockTimestamp[to] = block.timestamp;
        nextCliffTimestampMap[to] = nextCliffTimestampMap[to].add(quarterTimestamp);
        unlockFrequencyMap[to] = unlockFrequencyMap[to].add(1);
        token.transfer(to, amount);
        emit TokensUnlocked(to, amount);
    }

    /// @dev Allows recipient to start linearly unlocking tokens (after cliffEdge has elapsed) or unlock up to entire balance (after releaseEdge has elapsed)
    /// @param token - address of the official ERC20 token which is being unlocked here.
    /// @param to - the recipient's account address.
    /// @param amount - the amount to unlock (in wei)
    function transferTimeLockedMonth(
        IERC20 token,
        address to,
        uint256 amount
    ) public {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            balances[to] >= amount,
            "Insufficient token balance, try lesser amount"
        );
        require(
            msg.sender == to,
            "Only the token recipient can perform the unlock"
        );
        require(
            token == erc20Contract,
            "Token parameter must be the same as the erc20 contract address which was passed into the constructor"
        );
        
        // Ensure that the amount is available to be unlocked at this current point in time
        require(
            block.timestamp > nextCliffTimestampMap[to] + monthTimestamp,
            "Tokens are only available after correct time period has elapsed"
        );
        alreadyWithdrawn[to] = alreadyWithdrawn[to].add(amount);
        balances[to] = balances[to].sub(amount);
        mostRecentUnlockTimestamp[to] = block.timestamp;
        nextCliffTimestampMap[to] = nextCliffTimestampMap[to] + monthTimestamp;
        unlockFrequencyMap[to] = unlockFrequencyMap[to] + 1;
        token.transfer(to, amount);
        emit TokensUnlocked(to, amount);
    }

    function ecologyUnlock() public {
        require(
            msg.sender == ecologyAddress,
            "Only the token recipient can perform the unlock"
        );
        transferTimeLockedQuarter(erc20Contract, ecologyAddress, unlockAmountPerFrequencyMap[ecologyAddress]);
    }

    function privatePlacementUnlock() public {
        require(
            msg.sender == privatePlacementAddress,
            "Only the token recipient can perform the unlock"
        );
        transferTimeLockedMonth(erc20Contract, privatePlacementAddress, unlockAmountPerFrequencyMap[privatePlacementAddress]);
    }

    function teamUnlock() public {
        require(
            msg.sender == teamAddress,
            "Only the token recipient can perform the unlock"
        );
        transferTimeLockedMonth(erc20Contract, teamAddress, unlockAmountPerFrequencyMap[teamAddress]);
    }

    /// @dev Transfer accidentally locked ERC20 tokens.
    /// @param token - ERC20 token address.
    /// @param amount of ERC20 tokens to remove.
    function transferAccidentallyLockedTokens(IERC20 token, uint256 amount)
        public
        onlyOwner
    {
        require(address(token) != address(0), "Token address can not be zero");
        // This function can not access the official timelocked tokens; just other random ERC20 tokens that may have been accidently sent here
        require(
            token != erc20Contract,
            "Token address can not be ERC20 address which was passed into the constructor"
        );
        // Transfer the amount of the specified ERC20 tokens, to the owner of this contract
        token.transfer(owner, amount);
    }
}