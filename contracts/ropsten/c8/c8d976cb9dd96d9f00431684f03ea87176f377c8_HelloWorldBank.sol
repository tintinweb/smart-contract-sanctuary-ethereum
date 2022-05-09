/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: AGPL-3
// @title: Meterverse Research Contracts
// @version v0.0.1
pragma solidity >=0.7.0 <0.9.0;


interface IHelloWorldBank {
    event logDeposit(uint256 _custoerAccountId, address _from, uint256 _amount, uint256 _currentAmount);
    event logWithdraw(uint256 _custoerAccountId, address _from, address _to, uint256 _amount);
    event logOperator(string _type, address _granter, address _grantee);
    event logOther(string _type, string _log);

    /// @notice 잔액 조회
    /// @dev Explain to a developer any extra details
    /// @return amount 잔액
    function getBalance() external view returns(uint256 amount);

    /// @notice 잔액 조회(운영자 전용)
    /// @dev 운영자 여부를 체크하여 예외처리
    /// @param _customerAddress 조회 대상 고객 address
    /// @return amount 잔액
    function getBalance(address _customerAddress) external view returns(uint256 amount);

    /// @notice 송금자의 address로 입금
    /// @dev Explain to a developer any extra details
    function doDeposit() external payable returns(uint256 custoerAccountId);

    /// @notice 지정한 address로 입금(운영자 전용)
    /// @dev 운영자 여부를 체크하여 예외처리
    /// @param _customerAddress 입금할 address
    function doDeposit(address _customerAddress) external payable;

    /// @notice 지정한 address로 입금
    /// @dev Explain to a developer any extra details
    /// @param _customerAddress 입금할 address
    function doDepositByOperator(address _customerAddress) external payable;

    /// @notice 지정한 address로 출금
    /// @dev Explain to a developer any extra details
    /// @param  _to 송금받을 address
    /// @param  _amount 출금할 금액
    function doWithdraw(address _to, uint256 _amount) external payable;

    /// @notice 본인 address로 출금
    /// @dev Explain to a developer any extra details
    /// @param  _amount 출금할 금액
    function doWithdraw(uint256 _amount) external payable;

    /// @notice 운영자 address 추가
    /// @dev Explain to a developer any extra details
    /// @param _operatorAddress 운영자 address
    function addOperator(address _operatorAddress) external;

    /// @notice 운영자 address 제거
    /// @dev Explain to a developer any extra details
    /// @param _operatorAddress 운영자 address
    function removeOperator(address _operatorAddress) external;

}

/// @title HelloWorld Bank Contract
/// @author NathanCho [email protected]
/// @notice 은행 입금, 출금, 잔액조회
/// @dev getBalance, doWithdraw
/**
 * @custom:dev-run-script browser/HelloWorldNFT/test/HelloWorldBank-test.remix2.js
 */
contract HelloWorldBank is IHelloWorldBank {

    uint256 internal accountId = 1;
    mapping(uint256 => mapping(address => uint256)) internal bankLedger;
    mapping(address => uint256) internal custoerAddressToAccountId;
    mapping(address => bool) internal operators;

    address private deployer;

    constructor() {
        operators[msg.sender] = true;
        deployer = msg.sender;
    }

    modifier checkDepositAmount(uint256 _amount) {
        require(_amount > 0, "Must be grater then 0");
        _;
    }
    modifier checkCustomerOnly() {
        require(custoerAddressToAccountId[msg.sender] > 0, "customer only service");
        _;
    }
    modifier checkOperatorOnly() {
        require(operators[msg.sender], "operator only service");
        _;
    }
    
    receive() virtual external payable checkDepositAmount(msg.value) {
        require(msg.value > 0, "Must be grater then 0");
        doDepositInternal(msg.sender, msg.value);
    }

    fallback() virtual external payable {
        emit logOther("INFO", "call fallback");
    }

    function doDeposit() override external payable checkDepositAmount(msg.value) returns(uint256 custoerAccountId) {
        (bool depositSuccess,) = payable(address(this)).call{value:msg.value}("receive");
        require(depositSuccess, "Failed to deposit");
        return doDepositInternal(msg.sender, msg.value);
    }

    function doDeposit(address _customerAddress) override external payable checkDepositAmount(msg.value) {
        (bool depositSuccess,) = payable(address(this)).call{value:msg.value}("receive");
        require(depositSuccess, "Failed to deposit");
        doDepositInternal(_customerAddress, msg.value);
    }

    function doDepositByOperator(address _customerAddress) external payable checkOperatorOnly {
        (bool depositSuccess,) = payable(address(this)).call{value:msg.value}("receive");
        require(depositSuccess, "Failed to deposit");
        doDepositInternal(_customerAddress, msg.value);
    }

    function doDepositInternal(address _customerAddress, uint256 _amount) internal returns(uint256 custoerAccountId) {
        if(custoerAddressToAccountId[_customerAddress] == 0) {
            custoerAddressToAccountId[_customerAddress] = accountId;
            bankLedger[accountId][_customerAddress] = 0;
            accountId++;
        }

        custoerAccountId = custoerAddressToAccountId[_customerAddress];
        bankLedger[custoerAccountId][_customerAddress] += _amount;
        emit logDeposit(custoerAccountId, _customerAddress, _amount, bankLedger[custoerAccountId][_customerAddress]);

        return custoerAccountId;
    }

    function getBalance() override external view checkCustomerOnly returns(uint256 _amount) {
        uint256 custoerAccountId = custoerAddressToAccountId[msg.sender];
        return getBalanceInternal(custoerAccountId, msg.sender);
    }
    function getBalance(address _customerAddress) override external view checkOperatorOnly returns(uint256 _amount) {
        uint256 custoerAccountId = custoerAddressToAccountId[_customerAddress];
        return getBalanceInternal(custoerAccountId, _customerAddress);
    }
    function getBalanceInternal(uint256 _customerAccountId, address _customerAddress) internal view returns(uint256 _amount) {
        return bankLedger[_customerAccountId][_customerAddress];
    }

    function getContractBalance() external view checkOperatorOnly returns(uint256 _amount) {
        return address(this).balance;
    }

    function doWithdraw(uint256 _amount) override external payable  {
        doWithdraw(msg.sender, _amount);
    }
    function doWithdraw(address _to, uint256 _amount) override public payable {
        uint256 custoerAccountId = custoerAddressToAccountId[msg.sender];
        uint256 beforeCustomerAmount = getBalanceInternal(custoerAccountId, msg.sender);
        require(beforeCustomerAmount >= _amount, "not sufficient amount");
        
        bankLedger[custoerAccountId][msg.sender] -= _amount;
        uint256 afterCustomerAmount = getBalanceInternal(custoerAccountId, msg.sender);
        require(afterCustomerAmount <= beforeCustomerAmount, "negative amount is not allowd");

        (bool withdrawSuccess,) = payable(_to).call{value:_amount}("");
        require(withdrawSuccess, "Failed to withdraw");

        emit logWithdraw(custoerAccountId, msg.sender, _to, _amount);
    }

    function addOperator(address _operatorAddress) override external checkOperatorOnly {
        require(operators[_operatorAddress] == false, "already registerd operator");
        emit logOperator("addOperator", msg.sender, _operatorAddress);
        operators[_operatorAddress] = true;
    }

    function removeOperator(address _operatorAddress) override external checkOperatorOnly {
        require(deployer != _operatorAddress, "Deploy address is NOT permit remove operator");
        require(operators[_operatorAddress] == true, "not registerd operator");
        emit logOperator("removeOperator", msg.sender, _operatorAddress);
        operators[_operatorAddress] = false;
    }
}