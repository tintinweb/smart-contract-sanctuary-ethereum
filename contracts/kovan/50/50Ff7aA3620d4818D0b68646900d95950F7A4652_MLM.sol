/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

//....................................................................
//.MMMMMMM.......MMMMMMM....LLLLL.............MMMMMMM........MMMMMMM..
//.MMMMMMM.......MMMMMMM....LLLLL.............MMMMMMM.......MMMMMMMM..
//.MMMMMMM.......MMMMMMM....LLLLL.............MMMMMMM.......MMMMMMMM..
//.MMMMMMMM.....MMMMMMMM....LLLLL.............MMMMMMMM......MMMMMMMM..
//.MMMMMMMM.....MMMMMMMM....LLLLL.............MMMMMMMM.....MMMMMMMMM..
//.MMMMMMMM.....MMMMMMMM....LLLLL.............MMMMMMMM.....MMMMMMMMM..
//.MMMMMMMMM....MMMMMMMM....LLLLL.............MMMMMMMMM....MMMMMMMMM..
//.MMMMMMMMM...MMMMMMMMM....LLLLL.............MMMMMMMMM...MMMMMMMMMM..
//.MMMM.MMMM...MMMM.MMMM....LLLLL.............MMMMMMMMM...MMMMMMMMMM..
//.MMMM.MMMMM..MMMM.MMMM....LLLLL.............MMMMMMMMMM..MMMM.MMMMM..
//.MMMM.MMMMM.MMMMM.MMMM....LLLLL.............MMMMMMMMMM.MMMMM.MMMMM..
//.MMMM..MMMM.MMMM..MMMM....LLLLL.............MMMMM.MMMM.MMMMM.MMMMM..
//.MMMM..MMMM.MMMM..MMMM....LLLLL.............MMMMM.MMMMMMMMM..MMMMM..
//.MMMM..MMMMMMMMM..MMMM....LLLLL.............MMMMM.MMMMMMMMM..MMMMM..
//.MMMM...MMMMMMM...MMMM....LLLLL.............MMMMM..MMMMMMMM..MMMMM..
//.MMMM...MMMMMMM...MMMM....LLLLL.............MMMMM..MMMMMMM...MMMMM..
//.MMMM...MMMMMMM...MMMM....LLLLLLLLLLLLLLLL..MMMMM..MMMMMMM...MMMMM..
//.MMMM....MMMMM....MMMM....LLLLLLLLLLLLLLLL..MMMMM...MMMMMM...MMMMM..
//.MMMM....MMMMM....MMMM....LLLLLLLLLLLLLLLL..MMMMM...MMMMM....MMMMM..
//.MMMM....MMMMM....MMMM....LLLLLLLLLLLLLLLL..MMMMM...MMMMM....MMMMM..
//....................................................................

pragma solidity ^0.8.15;

// SPDX-License-Identifier: MIT

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}

contract MLM {
    IERC20 public usdt;

    address public admin;
    address public paymentWallet;
    address public rewardWallet;
    uint256 totalUsers;

    mapping(address => User) public user;
    mapping(address => Register) public registered;
    mapping(uint256 => address) public userID;
    mapping(address => bool) public _isAuthorized;
    mapping(address => uint256) public approvedAmount;

    uint256[] public plan;

    struct Register {
        string name;
        address UserAddress;
        bool alreadyExists;
    }

    struct User {
        string name;
        address userAddress;
        uint256 amountDeposit;
    }
    modifier onlyAuthorized() {
        require(_isAuthorized[msg.sender] == true, "Not an Authorized");
        _;
    }
    event Deposit(address user, uint256 amount);

    constructor(
        address _admin,
        address _usdt,
        address _paymentWallet,
        address _rewardWallet
    ) {
        admin = _admin;
        _isAuthorized[admin] = true;
        paymentWallet = _paymentWallet;
        rewardWallet = _rewardWallet;
        usdt = IERC20(_usdt);
        plan.push(1000);
        plan.push(2000);
        plan.push(3000);
        plan.push(4000);
        plan.push(5000);
        plan.push(6000);
    }

    function register(string memory _name, address users)
        public
        onlyAuthorized
    {
        require(!registered[users].alreadyExists, "User already registered");
        registered[users].name = _name;
        registered[users].UserAddress = users;
        registered[users].alreadyExists = true;
    }

    function addRegisterData(string memory _name, address users)
        public
        onlyAuthorized
    {
        require(registered[users].alreadyExists, "User not registered");
        registered[users].name = _name;
        registered[users].UserAddress = users;
    }

    function updateRegisterData2(
        string memory _name,
        address oldUser,
        address newUser
    ) public onlyAuthorized {
        require(registered[oldUser].alreadyExists, "User not registered");
        require(!registered[newUser].alreadyExists, "User already registered");
        registered[oldUser].name = _name;
        registered[oldUser].UserAddress = newUser;
    }

    function DeletRegisterData(address users) public onlyAuthorized {
        delete registered[users];
    }

    function deposit(
        uint256 amount,
        string memory _name,
        uint256 index
    ) public {
        require(index < plan.length, "Index out of range");
        require(amount >= 0, "amount should be more than 0");
        require(
            amount == plan[index] * (10**usdt.decimals()),
            "amount should be according to the plan"
        );
        require(registered[msg.sender].alreadyExists, "User not registered");
        usdt.transferFrom(msg.sender, paymentWallet, amount);

        user[msg.sender].name = _name;
        user[msg.sender].userAddress = msg.sender;
        user[msg.sender].amountDeposit =
            user[msg.sender].amountDeposit +
            (amount);
        emit Deposit(msg.sender, amount);
    }

    function AuthorizeUser(address _user, bool _state) public {
        require(admin == msg.sender, "Only admin can authorize user");
        _isAuthorized[_user] = _state;
    }

    function distribute(address[] memory recivers, uint256[] memory amount)
        public
        onlyAuthorized
    {
        require(recivers.length == amount.length, "unMatched Data");

        for (uint256 i; i < recivers.length; i++) {
            require(
                registered[recivers[i]].alreadyExists,
                "User not registered"
            );
            approvedAmount[recivers[i]] += amount[i];
        }
    }

    function claim() public {
        require(approvedAmount[msg.sender] >= 0, "not authorized");
        uint256 amount = approvedAmount[msg.sender];
        usdt.transferFrom(rewardWallet, msg.sender, amount);
        approvedAmount[msg.sender] = 0;
    }

    function changeAdmin(address newAdmin) public {
        require(msg.sender == admin, "Not an admin");
        admin = newAdmin;
    }

    function changeToken(address newToken) public onlyAuthorized {
        usdt = IERC20(newToken);
    }

    function changepaymentWallet(address newpaymentWallet)
        public
        onlyAuthorized
    {
        paymentWallet = newpaymentWallet;
    }

    function changerewardWallet(address newrewardWallet) public onlyAuthorized {
        rewardWallet = newrewardWallet;
    }

    function updateplanAtIndex(uint256 index, uint256 amount)
        public
        onlyAuthorized
    {
        require(index < plan.length, "index out of range");
        plan[index] = amount;
    }

    function addnewplan(uint256 amount) public onlyAuthorized {
        plan.push(amount);
    }

    function removeplan(uint256 index) public onlyAuthorized {
        require(index < plan.length, "index out of range");

        delete plan[index];
    }

    function withdrawStukFunds(IERC20 token) public onlyAuthorized {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}