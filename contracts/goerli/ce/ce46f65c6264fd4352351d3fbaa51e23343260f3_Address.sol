/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

/**
 *Submitted for verification at BscScan.com on 2022-09-01
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.4.22 <0.9.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) +
            (value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }
    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) -
            (value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}
contract Smart_Binary is Context {
    using SafeERC20 for IERC20;
    struct Node {
        uint256 leftDirect;
        uint256 rightDirect;
        uint256 ALLleftDirect;
        uint256 ALLrightDirect;
        uint256 todayCountPoint;
        uint256 depth;
        uint256 childs;
        uint256 leftOrrightUpline;
        address UplineAddress;
        address leftDirectAddress;
        address rightDirectAddress;
    }
    mapping(address => Node) private _users;
    mapping(uint256 => address) private _allUsersAddress;
    mapping(uint256 => address) private Flash_User;
    address private owner;
    address private tokenAddress;
    address private Last_Reward_Order;
    address[] private Lottery_candida;
    uint256 private _listingNetwork;
    uint256 private _lotteryNetwork;
    uint256 private _counter_Flash;
    uint256 private _userId;
    uint256 private lastRun;
    uint256 private All_Payment;
    uint256 private _count_Lottery_Candidate;
    uint256 private Value_LotteryANDFee;
    uint256[] private _randomNumbers;
    uint256 private Lock = 0;
    uint256 private Max_Point;
    uint256 private Max_Lottery_Price;
    uint256 private Count_Last_Users;
    IERC20 private _depositToken;

    constructor() {
        owner = _msgSender();
        _listingNetwork = 100 * 10**18;
        _lotteryNetwork = 2500000 * 10**18;
        Max_Point = 50;
        Max_Lottery_Price = 25;
        lastRun = block.timestamp;
        tokenAddress = 0x4DB1B84d1aFcc9c6917B5d5cF30421a2f2Cab4cf; 
        _depositToken = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        Count_Last_Users = 0;
        All_Payment = 26200 * 10**18;
    }

    function Reward_24() public {
        require(Lock == 0, "Proccesing");
        require(
            _users[_msgSender()].todayCountPoint > 0,
            "You Dont Have Any Point Today"
        );

        require(
            block.timestamp > lastRun + 24 hours,
            "The Reward_24 Time Has Not Come"
        );

        Lock = 1;
        Last_Reward_Order = _msgSender();
        All_Payment += _depositToken.balanceOf(address(this));

        uint256 Value_Reward = Price_Point() * 90;
        Value_LotteryANDFee = Price_Point();

        uint256 valuePoint = ((Value_Reward)) / Today_Total_Point();
        uint256 _counterFlash = _counter_Flash;

        uint256 RewardClick = Today_Reward_Writer_Reward() * 10**18;

        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            Node memory TempNode = _users[_allUsersAddress[i]];
            uint256 Point;
            uint256 Result = TempNode.leftDirect <= TempNode.rightDirect
                ? TempNode.leftDirect
                : TempNode.rightDirect;
            if (Result > 0) {
                if (Result > Max_Point) {
                    Point = Max_Point;
                    if (TempNode.leftDirect < Result) {
                        TempNode.leftDirect = 0;
                        TempNode.rightDirect -= Result;
                    } else if (TempNode.rightDirect < Result) {
                        TempNode.leftDirect -= Result;
                        TempNode.rightDirect = 0;
                    } else {
                        TempNode.leftDirect -= Result;
                        TempNode.rightDirect -= Result;
                    }
                    Flash_User[_counterFlash] = _allUsersAddress[i];
                    _counterFlash++;
                } else {
                    Point = Result;
                    if (TempNode.leftDirect < Point) {
                        TempNode.leftDirect = 0;
                        TempNode.rightDirect -= Point;
                    } else if (TempNode.rightDirect < Point) {
                        TempNode.leftDirect -= Point;
                        TempNode.rightDirect = 0;
                    } else {
                        TempNode.leftDirect -= Point;
                        TempNode.rightDirect -= Point;
                    }
                }
                TempNode.todayCountPoint = 0;
                _users[_allUsersAddress[i]] = TempNode;

                if (
                    Point * valuePoint > _depositToken.balanceOf(address(this))
                ) {
                    _depositToken.safeTransfer(
                        _allUsersAddress[i],
                        _depositToken.balanceOf(address(this))
                    );
                } else {
                    _depositToken.safeTransfer(
                        _allUsersAddress[i],
                        Point * valuePoint
                    );
                }

                if (
                    Point * 1000000 * 10**18 <=
                    IERC20(tokenAddress).balanceOf(address(this))
                ) {
                    IERC20(tokenAddress).transfer(
                        _allUsersAddress[i],
                        Point * 1000000 * 10**18
                    );
                }
            }
        }
        _counter_Flash = _counterFlash;
        lastRun = block.timestamp;

        if (RewardClick <= _depositToken.balanceOf(address(this))) {
            _depositToken.safeTransfer(_msgSender(), RewardClick);
        }

       // Lottery_Reward();

        _depositToken.safeTransfer(
            owner,
            _depositToken.balanceOf(address(this))
        );

        Lock = 0;
    }

    function X_Emergency_72() public {
        require(_msgSender() == owner, "Just Owner Can Run This Order!");
        require(
            block.timestamp > lastRun + 72 hours,
            "The X_Emergency_72 Time Has Not Come"
        );
        _depositToken.safeTransfer(
            owner,
            _depositToken.balanceOf(address(this))
        );
    }

    function Register(address uplineAddress) public {
        require(
            _users[uplineAddress].childs != 2,
            "This address have two directs and could not accept new members!"
        );
        require(
            _msgSender() != uplineAddress,
            "You can not enter your own address!"
        );
        bool testUser = false;
        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            if (_allUsersAddress[i] == _msgSender()) {
                testUser = true;
                break;
            }
        }
        require(testUser == false, "This address is already registered!");

        bool testUpline = false;
        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            if (_allUsersAddress[i] == uplineAddress) {
                testUpline = true;
                break;
            }
        }
        require(testUpline == true, "This Upline address is Not Exist!");

        _depositToken.safeTransferFrom(
            _msgSender(),
            address(this),
            _listingNetwork
        );       
        _allUsersAddress[_userId] = _msgSender();
        _userId++;
        uint256 depthChild = _users[uplineAddress].depth + 1;
        _users[_msgSender()] = Node(
            0,
            0,
            0,
            0,
            0,
            depthChild,
            0,
            _users[uplineAddress].childs,
            uplineAddress,
            address(0),
            address(0)
        );
        if (_users[uplineAddress].childs == 0) {
            _users[uplineAddress].leftDirect++;
            _users[uplineAddress].ALLleftDirect++;
            _users[uplineAddress].leftDirectAddress = _msgSender();
        } else {
            _users[uplineAddress].rightDirect++;
            _users[uplineAddress].ALLrightDirect++;
            _users[uplineAddress].rightDirectAddress = _msgSender();
        }
        _users[uplineAddress].childs++;
        setTodayPoint(uplineAddress);
        address uplineNode = _users[uplineAddress].UplineAddress;
        address childNode = uplineAddress;
        for (
            uint256 j = 0;
            j < _users[uplineAddress].depth;
            j = unsafe_inc(j)
        ) {
            if (_users[childNode].leftOrrightUpline == 0) {
                _users[uplineNode].leftDirect++;
                _users[uplineNode].ALLleftDirect++;
            } else {
                _users[uplineNode].rightDirect++;
                _users[uplineNode].ALLrightDirect++;
            }
            setTodayPoint(uplineNode);
            childNode = uplineNode;
            uplineNode = _users[uplineNode].UplineAddress;
        }
        IERC20(tokenAddress).transfer(_msgSender(), 100000000 * 10**18);
    }

    // function Lottery_Reward() private {
    //     uint256 Numer_Win = ((Value_LotteryANDFee * 9) / 10**18) /
    //         Max_Lottery_Price;

    //     if (Numer_Win != 0 && _count_Lottery_Candidate != 0) {
    //         if (_count_Lottery_Candidate > Numer_Win) {
    //             for (
    //                 uint256 i = 1;
    //                 i <= _count_Lottery_Candidate;
    //                 i = unsafe_inc(i)
    //             ) {
    //                 _randomNumbers.push(i);
    //             }

    //             for (uint256 i = 1; i <= Numer_Win; i = unsafe_inc(i)) {
    //                 uint256 randomIndex = uint256(
    //                     keccak256(
    //                         abi.encodePacked(block.timestamp, msg.sender, i)
    //                     )
    //                 ) % _count_Lottery_Candidate;
    //                 uint256 resultNumber = _randomNumbers[randomIndex];

    //                 _randomNumbers[randomIndex] = _randomNumbers[
    //                     _randomNumbers.length - 1
    //                 ];
    //                 _randomNumbers.pop();

    //                 _depositToken.safeTransfer(
    //                     Lottery_candida[resultNumber - 1],
    //                     Max_Lottery_Price * 10**18
    //                 );
    //             }

    //             for (
    //                 uint256 i = 0;
    //                 i < (_count_Lottery_Candidate - Numer_Win);
    //                 i = unsafe_inc(i)
    //             ) {
    //                 _randomNumbers.pop();
    //             }
    //         } else {
    //             for (
    //                 uint256 i = 0;
    //                 i < _count_Lottery_Candidate;
    //                 i = unsafe_inc(i)
    //             ) {
    //                 _depositToken.safeTransfer(
    //                     Lottery_candida[i],
    //                     Max_Lottery_Price * 10**18
    //                 );
    //             }
    //         }
    //     }

    //     for (uint256 i = 0; i < _count_Lottery_Candidate; i = unsafe_inc(i)) {
    //         Lottery_candida.pop();
    //     }

    //     _count_Lottery_Candidate = 0;
    // }

    function Smart_Gift() public {
        require(
            _users[_msgSender()].todayCountPoint < 1,
            "You Have Point Today"
        );
        require(
            IERC20(tokenAddress).balanceOf(_msgSender()) >= _lotteryNetwork,
            "You Dont Have Enough Smart Binary Token!"
        );

        bool testUser = false;
        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            if (_allUsersAddress[i] == _msgSender()) {
                testUser = true;
                break;
            }
        }
        require(
            testUser == true,
            "This address is not in Smart Binary Contract!"
        );

        IERC20(tokenAddress).safeTransferFrom(
            _msgSender(),
            address(this),
            _lotteryNetwork
        );

        Lottery_candida.push(_msgSender());
        _count_Lottery_Candidate++;
    }

    function Upload_Old_Users(
        address person,
        uint256 leftDirect,
        uint256 rightDirect,
        uint256 ALLleftDirect,
        uint256 ALLrightDirect,
        uint256 depth,
        uint256 childs,
        uint256 leftOrrightUpline,
        address UplineAddress,
        address leftDirectAddress,
        address rightDirectAddress
    ) public {
        require(_msgSender() == owner, "Just Owner Can Run This Order!");
        require(Count_Last_Users <= 262, "The number of old users is over!");

        _allUsersAddress[_userId] = person;
        _users[_allUsersAddress[_userId]] = Node(
            leftDirect,
            rightDirect,
            ALLleftDirect,
            ALLrightDirect,
            0,
            depth,
            childs,
            leftOrrightUpline,
            UplineAddress,
            leftDirectAddress,
            rightDirectAddress
        );
        IERC20(tokenAddress).transfer(person, 100000000 * 10**18);
        Count_Last_Users++;
        _userId++;
    }

    function unsafe_inc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function User_Information(address UserAddress)
        public
        view
        returns (Node memory)
    {
        return _users[UserAddress];
    }

    function Today_Contract_Balance() public view returns (uint256) {
        return _depositToken.balanceOf(address(this)) / 10**18;
    }

    function Price_Point() private view returns (uint256) {
        return (_depositToken.balanceOf(address(this))) / 100;
    }

    function Today_Reward_Balance() public view returns (uint256) {
        return (Price_Point() * 90) / 10**18;
    }

    function Today_Gift_Balance() public view returns (uint256) {
        return (Price_Point() * 9) / 10**18;
    }

    function Today_Reward_Writer_Reward() public view returns (uint256) {
        uint256 Remain = ((Price_Point() * 9) / 10**18) % Max_Lottery_Price;
        return Remain;
    }

    function Number_Of_Gift_Candidate() public view returns (uint256) {
        return _count_Lottery_Candidate;
    }

    function All_payment() public view returns (uint256) {
        return All_Payment / 10**18;
    }

    function X_Old_Users_Counter() public view returns (uint256) {
        return Count_Last_Users;
    }

    function Contract_Address() public view returns (address) {
        return address(this);
    }

    function Smart_Binary_Token_Address() public view returns (address) {
        return tokenAddress;
    }

    function Total_Register() public view returns (uint256) {
        return _userId;
    }

    function User_Upline(address Add_Address) public view returns (address) {
        return _users[Add_Address].UplineAddress;
    }

    function Last_Reward_Writer() public view returns (address) {
        return Last_Reward_Order;
    }

    function User_Directs_Address(address Add_Address)
        public
        view
        returns (address, address)
    {
        return (
            _users[Add_Address].leftDirectAddress,
            _users[Add_Address].rightDirectAddress
        );
    }

    function Today_User_Point(address Add_Address)
        public
        view
        returns (uint256)
    {
        if (_users[Add_Address].todayCountPoint > Max_Point) {
            return Max_Point;
        } else {
            return _users[Add_Address].todayCountPoint;
        }
    }

    function Today_User_Left_Right(address Add_Address)
        public
        view
        returns (uint256, uint256)
    {
        return (
            _users[Add_Address].leftDirect,
            _users[Add_Address].rightDirect
        );
    }

    function All_Time_User_Left_Right(address Add_Address)
        public
        view
        returns (uint256, uint256)
    {
        return (
            _users[Add_Address].ALLleftDirect,
            _users[Add_Address].ALLrightDirect
        );
    }

    function Today_Total_Point() public view returns (uint256) {
        uint256 TPoint;
        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            uint256 min = _users[_allUsersAddress[i]].leftDirect <=
                _users[_allUsersAddress[i]].rightDirect
                ? _users[_allUsersAddress[i]].leftDirect
                : _users[_allUsersAddress[i]].rightDirect;

            if (min > Max_Point) {
                min = Max_Point;
            }
            TPoint += min;
        }
        return TPoint;
    }

    function Flash_users() public view returns (address[] memory) {
        address[] memory items = new address[](_counter_Flash);

        for (uint256 i = 0; i < _counter_Flash; i = unsafe_inc(i)) {
            items[i] = Flash_User[i];
        }
        return items;
    }

    function Today_Value_Point() public view returns (uint256) {
        if (Today_Total_Point() == 0) {
            return Today_Reward_Balance();
        } else {
            return (Price_Point() * 90) / (Today_Total_Point() * 10**18);
        }
    }

    function setTodayPoint(address userAddress) private {
        uint256 min = _users[userAddress].leftDirect <=
            _users[userAddress].rightDirect
            ? _users[userAddress].leftDirect
            : _users[userAddress].rightDirect;
        if (min > 0) {
            _users[userAddress].todayCountPoint = min;
        }
    }
  
    function User_Exist(address Useraddress)
        public
        view
        returns (string memory)
    {
        bool test = false;
        for (uint256 i = 0; i <= _userId; i = unsafe_inc(i)) {
            if (_allUsersAddress[i] == Useraddress) {
                test = true;
            }
        }
        if (test) {
            return "YES!";
        } else {
            return "NO!";
        }
    }
}