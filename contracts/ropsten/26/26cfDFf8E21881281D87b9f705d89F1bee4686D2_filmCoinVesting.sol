/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


interface IERC20{
    function name() external view returns(string memory);

    function symbol() external view returns(string memory);

    function totalSupply() external view returns (uint );

    function decimals() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function approve(address sender , uint value)external returns(bool);

    function allowance(address sender, address spender) external view returns (uint256);

    function transfer(address recepient , uint value) external returns(bool);

    function transferFrom(address sender,address recepient, uint value) external returns(bool);

    event Transfer(address indexed from , address indexed to , uint value);

    event Approval(address indexed sender , address indexed  spender , uint value);
}

contract filmCoinVesting{
    using SafeMath for uint256;

    uint public totalBalance;
    
    IERC20 public token;
    address public Owner;

    struct wallets {
        address FounderWallet;      //20%
        address TeamWallet;         //3%
        address TreasuryWallet;     //31%
        address LiquidityWallet;    //10%
        address PartnersWallet;     //3%
        address BurnWallet;         //2%
        address MarketingWallet;    //10%
        address communityWallet;    //8%
    }

    struct userDetailsStruct{
        address userwallet;
        bool isExist;
        bool[] isClaimed;
        uint startPeriod;
        uint currIndex;
        uint totalAllocs;
    }

    bytes32 public founderClass = keccak256("founderClass");
    bytes32 public teamClass = keccak256("teamClass");
    bytes32 public treasuryClass = keccak256("treasuryClass");
    bytes32 public liquidityClass = keccak256("liquidityClass");
    bytes32 public partnersClass = keccak256("partnersClass");
    bytes32 public burnClass = keccak256("burnClass");
    bytes32 public marketClass = keccak256("marketClass");
    bytes32 public communityClass = keccak256("communityClass");


   // mapping(uint => wallets) usersWallet;
    wallets[] public usersWallet;
    mapping(bytes32 => uint) public totalAlloc;

    mapping(bytes32 => uint[])public cliffAndreleases;
    mapping(address =>userDetailsStruct)public UserDetailsstruct;

    event ClaimedUserToken(address indexed User, uint value);

    constructor(address _token, address[] memory userWallet){  
        token = IERC20(_token);
        Owner = msg.sender;    

        usersWallet.push(wallets({
            FounderWallet : userWallet[0],
            TeamWallet : userWallet[1],
            TreasuryWallet : userWallet[2],
            LiquidityWallet : userWallet[3],
            PartnersWallet : userWallet[4],
            BurnWallet : userWallet[5],
            MarketingWallet : userWallet[6],
            communityWallet : userWallet[7]
        }));
    }
    

    modifier OnlyOwner(){
        require(Owner == msg.sender,"caller is not the Owner");
        _;
    }

    modifier OnDeposit(){
        require(totalBalance != 0,"Owner should deposit the initial amount to contract before claiming tokens");
        _;
    }

    function CliffsAndPercentages() public OnDeposit OnlyOwner{
        require(cliffAndreleases[founderClass].length == 0, "Updating Founder Cliffs And percentages can only called once");   
                                            /*[0]        [1]  [2]        [3]  [4]       [5]  [6]      [7]  */
        cliffAndreleases[founderClass]   =  ([180 days , 20 , 360 days , 20 , 540 days, 30, 720 days, 30]);
        cliffAndreleases[teamClass]      =  ([180 days , 20 , 300 days , 30 , 480 days , 50]);
        cliffAndreleases[treasuryClass]  =  ([120 days , 50 , 240 days , 50]);
        cliffAndreleases[liquidityClass] =  ([120 days , 50 , 180 days , 50]);
        cliffAndreleases[partnersClass]  =  ([180 days , 50 , 300 days , 50]);
        cliffAndreleases[burnClass]      =  ([180 days , 100]);
        cliffAndreleases[marketClass]    =  ([60 days , 50 , 120 days , 50]);
        cliffAndreleases[communityClass] =  ([60 days , 100]);

        totalAlloc[founderClass] = totalBalance.mul(20e18).div(100e18);      
        totalAlloc[teamClass] = totalBalance.mul(3e18).div(100e18);      
        totalAlloc[treasuryClass] = totalBalance.mul(31e18).div(100e18);      
        totalAlloc[liquidityClass] = totalBalance.mul(10e18).div(100e18);      
        totalAlloc[partnersClass] = totalBalance.mul(3e18).div(100e18);      
        totalAlloc[burnClass] = totalBalance.mul(2e18).div(100e18);      
        totalAlloc[marketClass] = totalBalance.mul(10e18).div(100e18);      
        totalAlloc[communityClass] = totalBalance.mul(8e18).div(100e18);      

    }

    function startCliffsAndReleases(address[] memory userWallet) public OnDeposit OnlyOwner{
        require(usersWallet.length != 0 ,"Wallets are empty!"); 
        
        for(uint i = 0; i < 8; i++){
            require(UserDetailsstruct[userWallet[i]].isExist == false, "Users periods are already added!!!");
            UserDetailsstruct[userWallet[i]].userwallet = userWallet[i];
            UserDetailsstruct[userWallet[i]].isExist = true;
            UserDetailsstruct[userWallet[i]].isClaimed = [true,false,false,false];
            UserDetailsstruct[userWallet[i]].startPeriod = block.timestamp;
            UserDetailsstruct[userWallet[i]].currIndex = 0;
            UserDetailsstruct[userWallet[i]].totalAllocs = 0;
        }  
    }

    function claimToken(address user , bytes32 userClass) public OnDeposit{
        require(UserDetailsstruct[user].isExist == true,"User does not exist");
        require(user != address(0),"0 address");

        uint totalAmount;
        uint index =  UserDetailsstruct[user].currIndex;
        for(uint i = index; i < cliffAndreleases[userClass].length; i++){
            if((UserDetailsstruct[user].isClaimed[i/2] == true) && ((UserDetailsstruct[user].startPeriod + cliffAndreleases[userClass][i]) < block.timestamp)){
                totalAmount += totalAlloc[userClass].mul(cliffAndreleases[userClass][i+1] * 1e18).div(100e18);
                UserDetailsstruct[user].isClaimed[i/2] = false;
                if((i/2) + 1 < UserDetailsstruct[user].isClaimed.length) {
                        UserDetailsstruct[user].isClaimed[(i/2) + 1] = true;
                }
                UserDetailsstruct[user].currIndex = i + 2;
            }else{
                break;
            }
            i = i + 1;
        }
            require(UserDetailsstruct[user].totalAllocs <= totalAlloc[userClass] && totalAmount > 0,"userWallet's allocated tokens are fully claimed"); 
            if(totalAmount != 0){
                UserDetailsstruct[user].totalAllocs += totalAmount;
                token.transfer(user,totalAmount);
            } 
            emit ClaimedUserToken(msg.sender, totalAmount);
    }

    function depositAmountToContract(uint amount) public OnlyOwner{
        require(amount <= token.balanceOf(msg.sender) , "Amount must be lesser than the balance!!!");
        require(amount != 0,"Amount must be greater than 0!!!");
        require(totalBalance == 0,"TotalBalnce already added");

        totalBalance = amount;
        token.transferFrom(msg.sender,address(this),amount);
    }

    function walletDetails(address _wallet)public view returns(userDetailsStruct memory){
        return UserDetailsstruct[_wallet];
    }

    function Retrieve(uint8 _type,address _toUser,uint amount)public OnlyOwner returns(bool status){
           require(_toUser != address(0), "Invalid Address");
        if (_type == 1) {
            require(address(this).balance >= amount, "Insufficient balance");
            require(payable(_toUser).send(amount), "Transaction failed");
            return true;
        }
        else if (_type == 2) {
            require(token.balanceOf(address(this)) >= amount);
            token.transfer(_toUser,amount);
            return true;
        }
        else if (_type == 3) {
            require(token.balanceOf(Owner) >= amount);
            token.transfer(_toUser,amount);
            return true;
        }
    }
}