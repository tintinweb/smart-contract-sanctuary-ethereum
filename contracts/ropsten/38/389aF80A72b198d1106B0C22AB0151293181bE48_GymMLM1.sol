// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./IERC20.sol";
import "./OwnableUpgradeable.sol";
import "./IWETH.sol";
import "./console.sol";

contract GymMLM1 is OwnableUpgradeable {
    uint256 public currentId;
    uint256 public oldUserTransferTimestampLimit;

    address public bankAddress;

    uint256[25] public directReferralBonuses;
    uint256[25] public levels;
    uint256[25] public oldUserLevels;

    mapping(address => uint256) public addressToId;
    mapping(uint256 => address) public idToAddress;
    mapping(address => uint256) public investment;
    mapping(address => address) public userToReferrer;
    mapping(address => uint256) public scoring;
    mapping(address => uint256) public firstDepositTimestamp;

    address public farming;

    event NewReferral(address indexed user, address indexed referral);

    event ReferralRewardReceived(
        address indexed user,
        address indexed referral,
        uint256 level,
        uint256 amount,
        address wantAddress
    );

    function initialize() external initializer {
        directReferralBonuses = [1000, 700, 500, 400, 400, 300, 100, 100, 100, 50, 50, 50, 50, 50, 25, 25, 25, 25, 16, 16, 16, 9, 9, 9 ,4];
        addressToId[0x8a85AAA434273A3018d8E38B09839f194c0D2e2d] = 1;
        idToAddress[1] = 0x8a85AAA434273A3018d8E38B09839f194c0D2e2d;
        userToReferrer[0x8a85AAA434273A3018d8E38B09839f194c0D2e2d] = 0x8a85AAA434273A3018d8E38B09839f194c0D2e2d;
        currentId = 2;
        levels = [0.05 ether,0.1 ether,0.25 ether,0.5 ether,1 ether,3 ether,5 ether,10 ether,15 ether,25 ether,30 ether,35 ether,40 ether,70 ether,100 ether,200 ether,210 ether,220 ether,230 ether,240 ether,250 ether,260 ether,270 ether,280 ether,290 ether];
        oldUserLevels = [0 ether,0.045 ether,0.045 ether,0.045 ether,0.045 ether,0.045 ether,1.35 ether,4.5 ether,9 ether,13.5 ether,22.5 ether,27 ether,31.5 ether,36 ether,45 ether,90 ether,4.5 ether,9 ether,15 ether,25 ether,37 ether,45 ether,56 ether,75 ether,90 ether];

        __Ownable_init();
    }

    modifier onlyBank() {
        require(msg.sender == bankAddress || msg.sender == farming, "GymMLM:: Only bank");
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function updateScoring(address _token, uint256 _score) external onlyOwner {
        scoring[_token] = _score;
    }

    function _addUser(address _user, address _referrer) private {
        addressToId[_user] = currentId;
        idToAddress[currentId] = _user;
        userToReferrer[_user] = _referrer;
        currentId++;
        emit NewReferral(_referrer, _user);
    }

    /**
     * @notice  Function to add GymMLM
     * @param _user Address of user
     * @param _referrerId Address of referrer
     */
    function addGymMLM(address _user, uint256 _referrerId) external onlyBank {
        address _referrer = userToReferrer[_user];

        if (_referrer == address(0)) {
            _referrer = idToAddress[_referrerId];
        }

        require(_user != address(0), "GymMLM::user is zero address");

        require(_referrer != address(0), "GymMLM::referrer is zero address");

        require(
            userToReferrer[_user] == address(0) || userToReferrer[_user] == _referrer,
            "GymMLM::referrer is zero address"
        );

        // If user didn't exsist before
        if (addressToId[_user] == 0) {
            _addUser(_user, _referrer);
        }
    }

    /**
     * @notice  Function to distribute rewards to referrers
     * @param _wantAmt Amount of assets that will be distributed
     * @param _wantAddr Address of want token contract
     * @param _user Address of user
     */
    function distributeRewards(
        uint256 _wantAmt,
        address _wantAddr,
        address _user
    ) public onlyBank {
        uint256 index;
        uint256 length = directReferralBonuses.length;

        IERC20 token = IERC20(_wantAddr);

        while (index < length && addressToId[userToReferrer[_user]] != 1) {
            address referrer = userToReferrer[_user];
            uint256 levellimit = firstDepositTimestamp[referrer] != 0 &&
                firstDepositTimestamp[referrer] < oldUserTransferTimestampLimit
                ? oldUserLevels[index]
                : levels[index];
            if (investment[referrer] >= levellimit) {
                uint256 reward = (_wantAmt * directReferralBonuses[index]) / 10000;
                token.transfer(referrer, reward);
                emit ReferralRewardReceived(referrer, _user, index, reward, _wantAddr);
            }
            _user = userToReferrer[_user];
            index++;
        }

        if (token.balanceOf(address(this)) > 0) {
            token.transfer(bankAddress, token.balanceOf(address(this)));
        }

        return;
    }

    function setBankAddress(address _bank) external onlyOwner {
        bankAddress = _bank;
    }

    function setOldUserTransferTimestampLimit(uint256 _limit) external onlyOwner {
        oldUserTransferTimestampLimit = _limit;
    }

    function setFarmingAddress(address _address) external onlyOwner {
        farming = _address;
    }

    function seedUsers(address[] memory _users, address[] memory _referrers) external onlyOwner {
        require(_users.length == _referrers.length, "Length mismatch");
        for (uint256 i; i < _users.length; i++) {
            addressToId[_users[i]] = currentId;
            idToAddress[currentId] = _users[i];
            userToReferrer[_users[i]] = _referrers[i];
            currentId++;

            emit NewReferral(_referrers[i], _users[i]);
        }
    }

    function updateInvestment(address _user, uint256 _newInvestment) external onlyBank {
        if (firstDepositTimestamp[_user] == 0) firstDepositTimestamp[_user] = block.timestamp;
        investment[_user] = _newInvestment;
    }
}