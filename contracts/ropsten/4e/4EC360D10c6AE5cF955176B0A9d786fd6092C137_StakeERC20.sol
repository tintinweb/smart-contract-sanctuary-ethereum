/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// File: contracts/4_ERC20.sol



pragma solidity ^0.8.3;

contract ERC_20 {

    event Transfer(address from, address to, uint256 value);
    event Approval(address owner, address spender, uint256 value);

    string private tokenName;
    string private tokenSymbol;
    uint256 private tokenTotalSupply;
    mapping(address => uint256) private balance;
    mapping(address => mapping(address => uint256)) private approvalLimit;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _tokenTotalSupply
    ) {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        tokenTotalSupply = _tokenTotalSupply;
        balance[msg.sender] = _tokenTotalSupply;
    }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function totalSupply() public view returns (uint256) {
        return tokenTotalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balance[_owner];
    }

    function transfer(address _to, uint256 _value)
        public
        virtual
        returns (bool success)
    {
        require(_to != address(0), "Address should not be 0!");
        require(_to != msg.sender, "Cannot Transfer to tokens itself");
        require(
            balance[msg.sender] >= _value,
            "You don't have requsted number of tokens"
        );

        balance[msg.sender] -= _value;
        balance[_to] += _value;
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public
      virtual
     returns (bool success) {
        require(_to != address(0), "Address should not be 0!");
        require(_from != address(0), "Address should not be 0!");
        require(approvalLimit[_from][msg.sender] >= _value,"You dont have Approval");
        // if (approvalLimit[msg.sender][_from]>=_value){
        // msg.sender = omar
        //              usama=>omar=>10;
        if (approvalLimit[_from][msg.sender] >= _value) {
            balance[_from] -= _value;
            balance[_to] += _value;
            approvalLimit[_from][msg.sender] -=_value;
            return true;
        } else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
            require(
            msg.sender != _spender,
            "Sender is Already approve to spend his spendings!"
        );
        require(balance[msg.sender]>=_value,"You don't have requsted number of tokens");
        if (balance[msg.sender] >= _value) {
            // msg.sender = usama
            //              usama=>omar=>10;
            approvalLimit[msg.sender][_spender] = _value;
            emit Approval(msg.sender, _spender, _value);
            return true;
        } else {
            return false;
        }
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        require(_owner != address(0), "Address should not be 0!");
        require(_spender != address(0), "Address should not be 0!");
        return approvalLimit[_owner][_spender];
    }
}

// #// Addresses for testing
// 1// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 2// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 3// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// 4// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB

// File: contracts/10_ERC20Staking.sol



pragma solidity ^0.8.3;

contract TestToken is ERC_20 {
    uint256 public _totalSupply = 5000000;

    address payable public owner;

    constructor() ERC_20("DEVCOIN", "DEVS", _totalSupply) {}

    function transferToken(address to, uint256 amount) external onlyOwner {
        require(this.transfer(to, amount), "Token transfer failed!");
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Message sender must be the contract's owner."
        );
        _;
    }
    // function transfertoken
}

contract StakeERC20 {
    event TransferTest(address from, address to, uint256 stakeAmount);

    ERC_20 erc20Contract;
    //86400 -> 1 Day

    // 3 Days (30 * 24 * 60 * 60)
    uint256 public StakingDuration = 259200;

    // 18 Days (18 * 24 * 60 * 60)
    uint256 StakesExpired = 1555200;

    //intrest rate per second -> 1 token per min for every staked
    uint8 public interestRate = 1;
    uint256 public ContractExpired;
    uint8 public totalStakers;

    struct StakeInfo {
        uint256 startTS;
        uint256 endTS;
        uint256 amount;
        uint256 claimed;
        uint256 stakeDuration;
    }

    event Staked(address indexed from, uint256 amount);
    event Claimed(address indexed from, uint256 amount);

    mapping(address => StakeInfo) public stakeInfos;
    mapping(address => bool) public addressStaked;
    bool private locked;
    address payable public owner;
    uint256 totalSupply;
    uint256 stakeable;

    constructor(ERC_20 _tokenAddress, uint256 _totalSupply) {
        require(
            address(_tokenAddress) != address(0),
            "Token Address cannot be address 0"
        );
        erc20Contract = _tokenAddress;
        ContractExpired = block.timestamp + StakesExpired;
        totalStakers = 0;
        totalSupply = _totalSupply;
        stakeable = 0;
        StakingDuration += block.timestamp;
        owner = payable(msg.sender);
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Message sender must be the contract's owner."
        );
        _;
    }

    function transferToken(address to, uint256 amount) external onlyOwner {
        require(erc20Contract.transfer(to, amount), "Token transfer failed!");
    }

    function claimReward() external returns (bool) {
        require(addressStaked[msg.sender] == true, "You are not participated");
        require(
            stakeInfos[msg.sender].endTS < block.timestamp,
            "Stake Time is not over yet"
        );
        require(stakeInfos[msg.sender].claimed == 0, "Already claimed");

        uint256 stakeAmount = stakeInfos[msg.sender].amount;
        uint256 totalTokens = stakeAmount +
           (interestRate  * (stakeInfos[msg.sender].stakeDuration/60) * stakeAmount);
           
            // ((stakeAmount * interestRate) / 100)*stakeInfos[msg.sender].endTS;
        stakeInfos[msg.sender].claimed == totalTokens;
        erc20Contract.transfer(msg.sender, totalTokens);

        emit Claimed(msg.sender, totalTokens);

        return true;
    }

    function getTokenExpiry() external view returns (uint256) {
        require(addressStaked[msg.sender] == true, "You are not participated");
        return stakeInfos[msg.sender].endTS;
    }

    /// StakeAmount-> Amount of Tokens Staked
    /// StakeTime-> Time in seconds for Staking tokens
    function stakeToken(uint256 stakeAmount, uint256 stakeTime)
        external
        payable
        noReentrant
    {
        require(stakeAmount > 0, "Stake amount should be correct");
        require(
            block.timestamp < StakingDuration,
            "Staking new tokens is stopped"
        );
        require(addressStaked[msg.sender] == false, "You already participated");
        require(erc20Contract.balanceOf(msg.sender) >= stakeAmount,
            "Insufficient Tokens Balance"
        );
        require((interestRate  * (stakeTime/60) * stakeAmount) + stakeable <= totalSupply,
            "Cannot Stake This much amount"
        );


        // Approve the Contract to send tokens here
        erc20Contract.transferFrom(msg.sender, address(this), stakeAmount);

        totalStakers++;
        addressStaked[msg.sender] = true;

        stakeInfos[msg.sender] = StakeInfo({
            startTS: block.timestamp,
            endTS: block.timestamp + stakeTime,
            amount: stakeAmount,
            claimed: 0,
            stakeDuration:stakeTime
        });
        stakeable += (interestRate  * (stakeTime/60) * stakeAmount);
        emit Staked(msg.sender, stakeAmount);
    }
}

// #// Addresses for testing
// 1// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 2// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
// 3// 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
// 4// 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB