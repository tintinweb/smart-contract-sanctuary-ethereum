/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

// 0.1% fee needs to be implemented
// maybe reset on public esrow party b to 0x0 address on withdrawal

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract PrivateEscrowAccount is ReentrancyGuard {

    address public partyA;
    address public partyB;
    uint public tokenAmountA;
    uint public tokenAmountB;
    uint public depositedValueTokenA;
    uint public depositedValueTokenB;
    bool public partyADeposited;
    bool public partyBDeposited;
    address public owner;
    IERC20 public tokenContractA;
    IERC20 public tokenContractB;

    constructor (address _partyA, IERC20 _tokenContractA, uint _tokenAmountA, address _partyB, IERC20 _tokenContractB, uint _tokenAmountB) public {
    partyA = _partyA;
    tokenContractA = _tokenContractA;
    tokenAmountA = _tokenAmountA;
    partyB = _partyB;
    tokenContractB = _tokenContractB;
    tokenAmountB = _tokenAmountB;
    owner = msg.sender;
    }

    modifier onlyParties {  
    require(msg.sender == partyA || msg.sender == partyB);
      _;
   }

    event partyDeposit(IERC20, uint);
    event tradeComplete(address, IERC20, uint);
    event WithdrawTrade(address, IERC20, uint);

    function partyADeposit() external nonReentrant {
        require(msg.sender == partyA, "Only Party A May Deposit");
        require(partyADeposited == false);
        require(tokenContractA.approve(address(this), tokenAmountA));
        require(tokenContractA.transferFrom(msg.sender, address(this), tokenAmountA));
        partyADeposited = true;
        depositedValueTokenA = tokenAmountA + depositedValueTokenA;
        emit partyDeposit(tokenContractA, tokenAmountA);
    }

    function partyBDeposit() external nonReentrant {
        require(msg.sender == partyB, "Only Party B May Deposit");
        require(partyBDeposited == false);
        require(tokenContractB.approve(address(this), tokenAmountB));
        require(tokenContractB.transferFrom(msg.sender, address(this), tokenAmountB));
        partyBDeposited = true;
        depositedValueTokenB = tokenAmountB + depositedValueTokenB;
        emit partyDeposit(tokenContractB, tokenAmountB);
    }

    function executeTrade() external onlyParties nonReentrant { 
        require(depositedValueTokenA == tokenAmountA);
        require(depositedValueTokenB == tokenAmountB);
        require(tokenContractB.transferFrom(address(this), partyA, tokenAmountB)); // replace tokenamountsB with a netTokenAmounts that is minus 0.1% of the deposit
        require(tokenContractA.transferFrom(address(this), partyB, tokenAmountA)); // replace tokenamountsB with a netTokenAmounts that is minus 0.1% of the deposit
        // implement a fee collector address, create two new require transfer functions that send the fee amounts to the collector (EOA)
        depositedValueTokenA = 0;
        depositedValueTokenB = 0;
        emit tradeComplete(partyA, tokenContractB, tokenAmountB);
        emit tradeComplete(partyB, tokenContractA, tokenAmountA);
    }

      function withdrawTrade() external onlyParties nonReentrant { 
        require(tokenContractB.transferFrom(address(this), partyB, depositedValueTokenB));
        require(tokenContractA.transferFrom(address(this), partyA, depositedValueTokenA));
        depositedValueTokenA = 0;
        depositedValueTokenB = 0;
        partyADeposited = false;
        partyBDeposited = false;
        emit WithdrawTrade(partyA, tokenContractA, depositedValueTokenA);
        emit WithdrawTrade(partyB, tokenContractB, depositedValueTokenB);
    }

}

contract PublicEscrowAccount is ReentrancyGuard {

    address public partyA;
    address public partyB;
    uint public tokenAmountA;
    uint public tokenAmountB;
    uint public depositedValueTokenA;
    uint public depositedValueTokenB;
    bool public partyADeposited;
    bool public partyBDeposited;
    address public owner;
    IERC20 public tokenContractA;
    IERC20 public tokenContractB;

    constructor (address _partyA, IERC20 _tokenContractA, uint _tokenAmountA, IERC20 _tokenContractB, uint _tokenAmountB) public {
    partyA = _partyA;
    tokenContractA = _tokenContractA;
    tokenAmountA = _tokenAmountA;
    tokenContractB = _tokenContractB;
    tokenAmountB = _tokenAmountB;
    owner = msg.sender;
    }

    modifier onlyParties {  
    require(msg.sender == partyA || msg.sender == partyB);
      _;
   }

    event partyDeposit(IERC20, uint);
    event tradeComplete(address, IERC20, uint);
    event WithdrawTrade(address, IERC20, uint);

    function partyADeposit() external nonReentrant {
        require(msg.sender == partyA, "Only Party A May Deposit");
        require(partyADeposited == false);
        require(tokenContractA.approve(address(this), tokenAmountA));
        require(tokenContractA.transferFrom(msg.sender, address(this), tokenAmountA));
        partyADeposited = true;
        depositedValueTokenA = tokenAmountA + depositedValueTokenA;
        emit partyDeposit(tokenContractA, tokenAmountA);
    }

    function partyBDeposit() external nonReentrant {
        require(partyBDeposited == false);
        require(tokenContractA.approve(address(this), tokenAmountA));
        require(tokenContractB.transferFrom(msg.sender, address(this), tokenAmountB));
        partyB = msg.sender;
        partyBDeposited = true;
        depositedValueTokenB = tokenAmountB + depositedValueTokenB;
        emit partyDeposit(tokenContractB, tokenAmountB);
    }

    function executeTrade() external onlyParties nonReentrant { 
        require(depositedValueTokenA == tokenAmountA);
        require(depositedValueTokenB == tokenAmountB);
        require(tokenContractB.transferFrom(address(this), partyA, tokenAmountB));
        require(tokenContractA.transferFrom(address(this), partyB, tokenAmountA));
        depositedValueTokenA = 0;
        depositedValueTokenB = 0;
        emit tradeComplete(partyA, tokenContractB, tokenAmountB);
        emit tradeComplete(partyB, tokenContractA, tokenAmountA);
    }

      function withdrawTrade() external onlyParties nonReentrant { 
        require(tokenContractB.transferFrom(address(this), partyB, depositedValueTokenB));
        require(tokenContractA.transferFrom(address(this), partyA, depositedValueTokenA));
        depositedValueTokenA = 0;
        depositedValueTokenB = 0;
        partyADeposited = false;
        partyBDeposited = false;
        emit WithdrawTrade(partyA, tokenContractA, depositedValueTokenA);
        emit WithdrawTrade(partyB, tokenContractB, depositedValueTokenB);
    }

}

contract EscrowFactory {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function createPrivateEscrow(address _partyA, IERC20 _tokenContractA, uint _tokenAmountA, address _partyB, IERC20 _tokenContractB, uint _tokenAmountB) public returns(PrivateEscrowAccount) {
        PrivateEscrowAccount newescrowaccount = new PrivateEscrowAccount(_partyA, _tokenContractA, _tokenAmountA, _partyB, _tokenContractB, _tokenAmountB);
        return newescrowaccount;
    }

    function createPublicEscrow(address _partyA, IERC20 _tokenContractA, uint _tokenAmountA, IERC20 _tokenContractB, uint _tokenAmountB) public returns(PublicEscrowAccount) {
        PublicEscrowAccount newescrowaccount = new PublicEscrowAccount(_partyA, _tokenContractA, _tokenAmountA, _tokenContractB, _tokenAmountB);
        return newescrowaccount;
    }
}