/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract PrivateEscrowAccount {

    address public partyA;
    address public partyB;
    uint public tokenAmountA;
    uint public tokenAmountB;
    uint public depositedValueTokenA;
    uint public depositedValueTokenB;
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

    event partyDeposit(IERC20, uint);
    event tradeComplete(address, IERC20, uint);
    event RenegTrade(address, IERC20, uint);

    // add modifier to reneg and execute functions so only parties a and b can execute

    modifier onlyParties {  
      require(msg.sender == partyA || msg.sender == partyB);
      _;
   }

    function partyADeposit() external {
        require(msg.sender == partyA, "Only Party A May Deposit");
        require(tokenContractA.transferFrom(msg.sender, address(this), tokenAmountA));
        depositedValueTokenA = tokenAmountA;
        emit partyDeposit(tokenContractA, tokenAmountA);
    }

    function partyBDeposit() external {
        require(msg.sender == partyB, "Only Party B May Deposit");
        require(tokenContractB.transferFrom(msg.sender, address(this), tokenAmountB));
        depositedValueTokenB = tokenAmountB;
        emit partyDeposit(tokenContractB, tokenAmountB);
    }

    function executeTrade() external onlyParties {
        require(depositedValueTokenA == tokenAmountA);
        require(depositedValueTokenB == tokenAmountB);
        require(tokenContractB.transferFrom(address(this), partyA, tokenAmountB));
        require(tokenContractA.transferFrom(address(this), partyB, tokenAmountA));
        emit tradeComplete(partyA, tokenContractB, tokenAmountB);
        emit tradeComplete(partyB, tokenContractA, tokenAmountA);
    }

      function renegTrade() external onlyParties {
        require(tokenContractB.transferFrom(address(this), partyB, tokenAmountB));
        require(tokenContractA.transferFrom(address(this), partyA, tokenAmountA));
        emit RenegTrade(partyA, tokenContractA, tokenAmountA);
        emit RenegTrade(partyB, tokenContractB, tokenAmountB);
    }

}

contract PublicEscrowAccount {

    address public partyA;
    address public partyB;
    uint public tokenAmountA;
    uint public tokenAmountB;
    uint public depositedValueTokenA;
    uint public depositedValueTokenB;
    address public owner;
    bool public partybregistered;
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

    event partyDeposit(IERC20, uint);
    event tradeComplete(address, IERC20, uint);
    event RenegTrade(address, IERC20, uint);
    event partyBAssigned(address);

    modifier onlyParties {  
      require(msg.sender == partyA || msg.sender == partyB);
      _;
   }

    function partyADeposit() external {
        require(msg.sender == partyA, "Only Party A May Deposit");
        require(tokenContractA.transferFrom(msg.sender, address(this), tokenAmountA));
        depositedValueTokenA = tokenAmountA;
        emit partyDeposit(tokenContractA, tokenAmountA);
    }

    function partyBDeposit() external {
        require(tokenContractB.transferFrom(msg.sender, address(this), tokenAmountB));
        require(partybregistered = false);
        partybregistered = true;
        partyB = msg.sender;
        depositedValueTokenB = tokenAmountB;
        emit partyDeposit(tokenContractB, tokenAmountB);
        emit partyBAssigned(partyB);
    }

    function executeTrade() external onlyParties {
        require(depositedValueTokenA == tokenAmountA);
        require(depositedValueTokenB == tokenAmountB);
        require(tokenContractB.transferFrom(address(this), partyA, tokenAmountB));
        require(tokenContractA.transferFrom(address(this), partyB, tokenAmountA));
        emit tradeComplete(partyA, tokenContractB, tokenAmountB);
        emit tradeComplete(partyB, tokenContractA, tokenAmountA);
    }

      function renegTrade() external onlyParties {
        require(tokenContractB.transferFrom(address(this), partyB, tokenAmountB));
        require(tokenContractA.transferFrom(address(this), partyA, tokenAmountA));
        emit RenegTrade(partyA, tokenContractA, tokenAmountA);
        emit RenegTrade(partyB, tokenContractB, tokenAmountB);
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