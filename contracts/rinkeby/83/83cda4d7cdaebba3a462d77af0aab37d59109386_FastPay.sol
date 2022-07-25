// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";

contract FastPay is Initializable, OwnableUpgradeable{


    address public manager;

    event AddMerchantAddress(address indexed merchant, address indexed addr);

    event SweepWithdraw(address indexed merchant, address indexed token, string orderNo);

    event CashSweep(address indexed merchant, address indexed token, uint256 sweepAmt, uint256 sweepCount);

    event ClaimFee(address indexed caller, address indexed token, uint256 amount);


    mapping(address => uint256) totalFeesOf;

    mapping(address => mapping(address => uint256)) public balanceOf;

    mapping(address => address[]) public merchantAddress;

    mapping(string => bool) public ordersOf;


    struct Withdraw {
        uint8 v;
        bytes32 r;
        bytes32 s;
        string orderNo;
        address token;
        address merchant;
        uint256 merchantAmt;
        address proxy;
        uint256 proxyAmt;
        uint256 fee;
        uint256 deadLine;
    }

    constructor(address _manager) {
        manager = _manager;
    }

    function initialize()public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function addMerchantAddress(
        address _merchant,
        address _addr
    ) external onlyManager {

        require(address(0) != _merchant);
        require(address(0) != _addr);

        merchantAddress[_merchant].push(_addr);

        emit AddMerchantAddress(_merchant, _addr);

    }

    function cashSweep(
        address _token,
        uint256 _start
    ) external returns (uint256 sweepAmt, uint256 sweepCount) {

        (sweepAmt, sweepCount) = sweep(msg.sender, _token, _start);

        return (sweepAmt, sweepCount);

    }

    function cashSweepAndWithdraw(
        Withdraw memory withdraw
    ) external {

        require(address(0) != withdraw.merchant);
        require(msg.sender == withdraw.merchant);
        require(withdraw.merchantAmt > 0);
        require(withdraw.deadLine > getTimes());

        verifyFee(withdraw);

        if(checkBalance(withdraw)) {

            withdrawFromBalance(withdraw);

        } else {

            sweep(withdraw.merchant, withdraw.token, 0);

            require(checkBalance(withdraw));

            withdrawFromBalance(withdraw);

        }

    }

    function checkBalance(
        Withdraw memory withdraw
    ) view internal returns(bool) {
        return balanceOf[withdraw.merchant][withdraw.token] >= withdraw.merchantAmt + withdraw.proxyAmt + withdraw.fee;
    }

    function withdrawFromBalance(
        Withdraw memory withdraw
    ) internal {

        TransferHelper.safeTransfer(withdraw.token, withdraw.merchant, withdraw.merchantAmt);
        balanceOf[withdraw.merchant][withdraw.token] -= withdraw.merchantAmt;

        if(address(0) != withdraw.proxy && 0 < withdraw.proxyAmt) {
            TransferHelper.safeTransfer(withdraw.token, withdraw.proxy, withdraw.proxyAmt);
            balanceOf[withdraw.merchant][withdraw.token] -= withdraw.proxyAmt;
        }

        balanceOf[withdraw.merchant][withdraw.token] -= withdraw.fee;
        totalFeesOf[withdraw.token] += withdraw.fee;

        require(balanceOf[withdraw.merchant][withdraw.token] >= 0);
        require(totalFeesOf[withdraw.token] >= withdraw.fee);

        ordersOf[withdraw.orderNo] = true;

        emit SweepWithdraw(withdraw.merchant, withdraw.token, withdraw.orderNo);

    }

    function sweep(
        address _merchant,
        address _token,
        uint256 _start
    ) internal returns (uint256,uint256) {

        address [] memory addresses = merchantAddress[_merchant];

        uint256 sweepCount = 0;
        uint256 index = _start;
        uint256 sweepAmount = 0;

        while(true) {

            if(address(0) == addresses[index]) {
                break;
            }

            uint256 balance = IERC20(_token).balanceOf(addresses[index]);
            if(balance <= 0) {
                index ++;
                continue;
            }

            TransferHelper.safeTransferFrom(_token, addresses[index], address(this), balance);

            index ++;

            sweepCount += 1;
            sweepAmount =  SafeMath.add(sweepCount, balance);

            if(sweepCount >= 500) {
                break;
            }

        }

        balanceOf[_merchant][_token] += sweepAmount;

        emit CashSweep(_merchant, _token, sweepAmount, index - _start);

        return (sweepAmount, index - _start);

    }

    function verifyFee(
        Withdraw memory withdraw
    ) view public {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("CashSweep")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        bytes32 hashStruct = keccak256(
            abi.encode(
                keccak256("cashSweep(address merchant,uint256 merchantAmt,address proxy,uint256 proxyAmt,uint256 fee,uint256 deadLine)"),
                withdraw.merchant,
                withdraw.merchantAmt,
                withdraw.proxy,
                withdraw.proxyAmt,
                withdraw.fee,
                withdraw.deadLine
            )
        );

        bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        address signer = ecrecover(hash, withdraw.v, withdraw.r, withdraw.s);
        require(signer == manager, "MyFunction: invalid signature");
        require(signer != address(0), "ECDSA: invalid signature");
    }

    function getTimes() view public returns(uint256) {
        return block.timestamp;
    }

    function changeSinger(
        address _newManager
    ) external onlyOwner {
        manager = _newManager;
    }

    function claimFee(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(totalFeesOf[_token] >= _amount);
        TransferHelper.safeTransfer(_token, msg.sender, _amount);
        emit ClaimFee(msg.sender, _token, _amount);
    }

    modifier onlyManager() {
        require(manager == msg.sender, "Manager: caller is not the manager");
        _;
    }
}