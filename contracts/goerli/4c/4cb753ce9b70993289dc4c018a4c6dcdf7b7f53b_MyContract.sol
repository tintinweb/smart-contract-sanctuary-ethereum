/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract ERC20Basic is IERC20 {

    string public constant name = "ERC20Basic";
    string public constant symbol = "ERC";
    uint8 public constant decimals = 18;


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 10000;


   constructor() {
    balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
    return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender]-numTokens;
        balances[receiver] = balances[receiver]+numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner]-numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender]-numTokens;
        balances[buyer] = balances[buyer]+numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

contract MyContract {

    address constant usdtAddress = 0x791e8aa6A49A59FA37279247f136748c7DF38055;

    IERC20 usdt = IERC20(address(usdtAddress));

    // IERC20 public usdt;    

    // constructor() {
    //     usdt = new ERC20Basic();
    // }

    address admin;
    uint256 public totalBalance;
    struct Transaction {
        address buyer;
        uint256 amount;
        bool locked;
        bool spent;
    }
    mapping(address => mapping(address => Transaction)) public balances;


    function accept(address _tx_id, address _buyer, uint256 _amount) external returns (uint256) {

        IERC20 usdtToken = IERC20(address(usdtAddress));

        // P2PM token = P2PM(p2pmAddress);
        usdtToken.transferFrom(msg.sender, address(this), _amount);
        totalBalance += _amount;
        balances[msg.sender][_tx_id].amount = _amount;
        balances[msg.sender][_tx_id].buyer = _buyer;
        balances[msg.sender][_tx_id].locked = true;
        balances[msg.sender][_tx_id].spent = false;
        return usdtToken.balanceOf(msg.sender);
    }

    event Bought(uint256 amount);
    event Sold(uint256 amount);

    // Do not use in production
    // This function can be executed by anyone
    function sendUSDT(address _to, uint256 _amount) external {
         // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        // IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        // IERC20 usdt = IERC20(address(0xD92E713d051C37EbB2561803a3b5FBAbc4962431));
        
        // transfers USDT that belong to your contract to the specified address
        usdt.transfer(_to, _amount);
    }

    function sendUSDTFromTo(address _from, uint256 _amount) external {
         // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        // IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        // IERC20 usdt = IERC20(address(0xD92E713d051C37EbB2561803a3b5FBAbc4962431));
        
        // transfers USDT that belong to your contract to the specified address
        usdt.transferFrom(_from,address(this), _amount);
        // usdt.transfer(_to, _amount);
    }

    function buy() payable public {
        uint256 amountTobuy = msg.value;
        // uint256 dexBalance = usdt.balanceOf(address(this));
        uint256 dexBalance = usdt.balanceOf(address(0xab23fc9Ea59Fcc8Bdd40B12335dB121CAD950549));
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        usdt.transfer(msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }

    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = usdt.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        usdt.transferFrom(msg.sender, address(this), amount);
        payable(msg.sender).transfer(amount);
        emit Sold(amount);
    }


     // NOTE: Deposit token that you specificied into smart contract constructor 
    function depositToken(uint _amount) public {
        // require(_amount >= cost * _mintAmount);
        usdt.transferFrom(msg.sender, address(this), _amount);
    }

    // NOTE: You can check how many tokens have your smart contract balance   
    function getSmartContractBalance() external view returns(uint) {
        return usdt.balanceOf(address(this));
    }
}