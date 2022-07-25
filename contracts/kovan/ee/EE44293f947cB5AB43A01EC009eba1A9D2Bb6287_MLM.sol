/**
 *Submitted for verification at Etherscan.io on 2022-07-15
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
    address public BOT_A;
    address public BOT_B;
    uint256 totalUsers;

    mapping(address => User) public user;
    mapping(address => Register) public registered;
    mapping(uint256 => address) public userID;
    mapping(address => bool) public _isAuthorized;
    mapping(address => uint256) public approvedAmount;

    mapping(string => uint256) public plan;
    string [] plannames;

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
        address _BOT_A,
        address _BOT_B
    ) {
        admin = _admin;
        _isAuthorized[admin] = true;
        BOT_A = _BOT_A;
        BOT_B = _BOT_B;
        usdt = IERC20(_usdt);
        plan["first"] = 45;
        plannames.push("first");
        plan["second"] = 27;
        plannames.push("second");

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
        string memory _planname
    ) public {
        require(plan[_planname] > 0, "plan not found");
        require(amount >= 0, "amount should be more than 0");
        require(
            amount == plan[_planname] * (10**usdt.decimals()),
            "amount should be according to the plan"
        );
        require(registered[msg.sender].alreadyExists, "User not registered");
        usdt.transferFrom(msg.sender, BOT_A, amount);

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
        usdt.transferFrom(BOT_B, msg.sender, amount);
        approvedAmount[msg.sender] = 0;
    }

    function changeAdmin(address newAdmin) public {
        require(msg.sender == admin, "Not an admin");
        admin = newAdmin;
    }

    function changeToken(address newToken) public onlyAuthorized {
        usdt = IERC20(newToken);
    }

    function changeBOT_A(address newBOT_A)
        public
        onlyAuthorized
    {
        BOT_A = newBOT_A;
    }

    function changeBOT_B(address newBOT_B) public onlyAuthorized {
        BOT_B = newBOT_B;
    }

    function setplan(string calldata _planname, uint256 amount)
        public
        onlyAuthorized
    {
        require(plan[_planname] > 0, "plan not found");
        plan[_planname] = amount;
    }

    function addplan(string calldata _planname, uint256 amount)
        public
        onlyAuthorized
    {
        require(!checkplanexists(_planname), "plan already exists");
        plan[_planname] = amount;
        plannames.push(_planname);
    }

    function checkplanexists(string memory _planname) public view returns (bool val) {
        for(uint256 i = 0; i < plannames.length; i++) {
            if(keccak256(bytes(plannames[i])) == keccak256(bytes(_planname))) {
                return true;
            }
        }
    }

    function getplannames() public view returns (string [] memory names) {
        return plannames;
    }

    function removeplan(string memory _planname) public onlyAuthorized {
      require(checkplanexists(_planname), "plan not found");
      for(uint256 i = 0; i < plannames.length; i++) {
        if(keccak256(bytes(plannames[i])) == keccak256(bytes(_planname))) {
          delete plannames[i];
          delete plan[_planname];
          return;
        }
    }
    }

    function withdrawStukFunds(IERC20 token) public onlyAuthorized {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}