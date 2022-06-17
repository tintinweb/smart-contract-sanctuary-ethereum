/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

//....................................................................
//.MMMMMMM.......MMMMMMM....LLLLL.............LMMMMMM........MMMMMMM..
//.MMMMMMM.......MMMMMMM....LLLLL.............LMMMMMM.......MMMMMMMM..
//.MMMMMMM.......MMMMMMM....LLLLL.............LMMMMMM.......MMMMMMMM..
//.MMMMMMMM.....MMMMMMMM....LLLLL.............LMMMMMMM......MMMMMMMM..
//.MMMMMMMM.....MMMMMMMM....LLLLL.............LMMMMMMM.....MMMMMMMMM..
//.MMMMMMMM.....MMMMMMMM....LLLLL.............LMMMMMMM.....MMMMMMMMM..
//.MMMMMMMMM....MMMMMMMM....LLLLL.............LMMMMMMMM....MMMMMMMMM..
//.MMMMMMMMM...MMMMMMMMM....LLLLL.............LMMMMMMMM...MMMMMMMMMM..
//.MMMM.MMMM...MMMM.MMMM....LLLLL.............LMMMMMMMM...MMMMMMMMMM..
//.MMMM.MMMMM..MMMM.MMMM....LLLLL.............LMMMMMMMMM..MMMM.MMMMM..
//.MMMM.MMMMM.MMMMM.MMMM....LLLLL.............LMMMMMMMMM.MMMMM.MMMMM..
//.MMMM..MMMM.MMMM..MMMM....LLLLL.............LMMMM.MMMM.MMMMM.MMMMM..
//.MMMM..MMMM.MMMM..MMMM....LLLLL.............LMMMM.MMMMMMMMM..MMMMM..
//.MMMM..MMMMMMMMM..MMMM....LLLLL.............LMMMM.MMMMMMMMM..MMMMM..
//.MMMM...MMMMMMM...MMMM....LLLLL.............LMMMM..MMMMMMMM..MMMMM..
//.MMMM...MMMMMMM...MMMM....LLLLL.............LMMMM..MMMMMMM...MMMMM..
//.MMMM...MMMMMMM...MMMM....LLLLLLLLLLLLLLLL..LMMMM..MMMMMMM...MMMMM..
//.MMMM....MMMMM....MMMM....LLLLLLLLLLLLLLLL..LMMMM...MMMMMM...MMMMM..
//.MMMM....MMMMM....MMMM....LLLLLLLLLLLLLLLL..LMMMM...MMMMM....MMMMM..
//.MMMM....MMMMM....MMMM....LLLLLLLLLLLLLLLL..LMMMM...MMMMM....MMMMM..
//....................................................................

pragma solidity ^0.8.9;

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
    address public bot;
    uint256 totalUsers;

    mapping(address => User) public user;
    mapping(address => Register) public registered;
    mapping(uint256 => address) public userID;
    mapping(address => bool) public _isAuthorized;
    mapping(address => uint256) public approvedAmount;

    uint256 [] public plan;

    struct Register {
        string name;
        address UserAddress;
    }

    struct User {
        string name;
        address userAddress;
        uint256 amountDeposit;
        bool alreadyExists;
    }
    modifier onlyAdmin() {
        require(admin == msg.sender, "only admin");
        _;
    }
    modifier onlyAuthorized() {
        require(_isAuthorized[msg.sender] == true, "Not an Authorized");
        _;
    }
    event Deposit(address user, uint256 amount);

    constructor(
        address _admin,
        address _usdt,
        address _bot
    ) {
        admin = _admin;
        bot = _bot;
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
        registered[users].name = _name;
        registered[users].UserAddress = users;
    }

    function addRegisterData(string memory _name, address users)
        public
        onlyAdmin
    {
        registered[users].name = _name;
        registered[users].UserAddress = users;
    }

    function updateRegisterData2(
        string memory _name,
        address oldUser,
        address newUser
    ) public onlyAdmin {
        registered[oldUser].name = _name;
        registered[oldUser].UserAddress = newUser;
    }

    function DeletRegisterData(address users) public onlyAdmin {
        delete registered[users];
    }

    function deposit(uint256 amount, string memory _name , uint256 index) public {
        require(index < plan.length, "Index out of range");
        require(amount >= 0, "amount should be more than 0");
        require(amount == plan[index]*(10**usdt.decimals()), "amount should be according to the plan");
        if (!user[msg.sender].alreadyExists) {
            user[msg.sender].alreadyExists = true;

            totalUsers++;
        }
        usdt.transferFrom(msg.sender, address(this), amount);

        user[msg.sender].name = _name;
        user[msg.sender].userAddress = msg.sender;
        user[msg.sender].amountDeposit = user[msg.sender].amountDeposit+(
            amount
        );
        usdt.transfer(bot, amount);
        emit Deposit(msg.sender, amount);
    }

    function AuthorizeUser(address _user, bool _state) public onlyAdmin {
        _isAuthorized[_user] = _state;
    }

    function distribute(address[] memory recivers, uint256[] memory amount)
        public
        onlyAuthorized
    {
        require(recivers.length == amount.length, "unMatched Data");
        for (uint256 i; i < recivers.length; i++) {
            approvedAmount[recivers[i]] += amount[i];
        }
    }

    function claim() public {
        require(approvedAmount[msg.sender] >= 0, "not authorized");
        uint256 amount = approvedAmount[msg.sender];
        usdt.transfer(msg.sender, amount);
        approvedAmount[msg.sender] = 0;
    }

    function changeAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }

    function changeToken(address newToken) public onlyAdmin {
        usdt = IERC20(newToken);
    }

    function changeBot(address newBot) public onlyAdmin {
        bot = newBot;
    }

    function updateplanAtIndex(uint256 index, uint256 amount) public onlyAdmin {
        require(index < plan.length, "index out of range");
        plan[index] = amount;
    }
    function addnewplan(uint256 amount) public onlyAdmin {
        plan.push(amount);
    }
    function removeplan(uint256 index) public onlyAdmin {
        require(index < plan.length, "index out of range");

        delete plan[index];
    }

}