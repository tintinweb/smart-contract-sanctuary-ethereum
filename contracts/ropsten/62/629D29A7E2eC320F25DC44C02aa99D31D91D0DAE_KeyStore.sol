/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract KeyStore {

    address public owner;

    mapping(address => uint256) public totalCount;
    // store account:priv structure, account must be unique!! in fact, account just a name string
    mapping(address => mapping(string => string)) private _storeBox;
    mapping(address => string[]) internal userAccounts;

    // 存储一个2FA的字符码
    mapping(address => string) public verifyCode;

    constructor() {
        owner = msg.sender;
    }

    // events about state change
    event Store(address _from, string _account);
    event Update(address _from, string _account);
    event Delete(address _from, string _account);

    // check params
    modifier beforeChange(string memory account, string memory priv) {
        require(keccak256(abi.encodePacked(account)) != keccak256(abi.encodePacked("")), "account name do not empty.");
        require(keccak256(abi.encodePacked(priv)) != keccak256(abi.encodePacked("")), "account private do not empty.");
        _;
    }

    // create
    function store(string memory account, string memory priv) external beforeChange(account, priv) {
        require(_exists(account) == false, "account existed, do not create.");
        _storeBox[msg.sender][account] = priv;
        userAccounts[msg.sender].push(account);
        totalCount[msg.sender] += 1;

        emit Store(msg.sender, account);
    }

    // search
    function getUserItem(string memory _account) external view returns(string memory) {
        return _storeBox[msg.sender][_account];
    }

    // get user all accounts
    function getUserAllAccounts(address user) external view returns(string[] memory) {
        require(user == msg.sender, "only user self can query");
        return userAccounts[msg.sender];
    }

    // update
    function updatePrivByAccount(string memory account, string memory priv) external beforeChange(account, priv) {
        require(_exists(account), "account do not exists.");
        _storeBox[msg.sender][account] = priv;

        emit Update(msg.sender, account);
    }

    // delete
    function deleteItem(string memory account, string memory priv) external {
        require(_exists(account), "account do not exists.");
        string memory _priv = _storeBox[msg.sender][account];
        require(keccak256(abi.encodePacked(priv)) == keccak256(abi.encodePacked(_priv)), "private do not same.");
        require(totalCount[msg.sender] >= 1, "account total count is zero.");
        delete _storeBox[msg.sender][account];
        totalCount[msg.sender] -= 1;

        for (uint256 i; i < userAccounts[msg.sender].length; i++) {
            string memory _account = userAccounts[msg.sender][i];
            if (keccak256(abi.encodePacked(_account)) == keccak256(abi.encodePacked(account))) {
                // delete userAccounts[msg.sender][i];
                uint256 _lastIdx = userAccounts[msg.sender].length - 1;
                string memory lastAccount = userAccounts[msg.sender][_lastIdx];
                userAccounts[msg.sender][i] = lastAccount;
                userAccounts[msg.sender].pop();
                break;
            }
        }

        emit Delete(msg.sender, account);
    }

    // check account exists
    function _exists(string memory account) internal view returns(bool) {
        string memory priv = _storeBox[msg.sender][account];
        return keccak256(abi.encodePacked(priv)) != keccak256(abi.encodePacked(""));
    }

    // just update verify code
    function updateVerifyCode(string memory _code) external {
        verifyCode[msg.sender] = _code;
    }
}