// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

interface IWETHGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external;

    function repayETH(
        address pool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable;

    function borrowETH(
        address pool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
    ) external;

    function withdrawETHWithPermit(
        address pool,
        uint256 amount,
        address to,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;
}

contract bWallet {
    address public owner;
    uint256 public nonce;
    event Received(address, uint256);
    event Sent(address, uint256);
    event Staked(address, uint256, bytes);
    event Replayed(address, uint256, uint256 fee);
    event FeeIncoming(address, uint256 finalAmt, uint256 fee);

    event StakedAave(address, uint256);
    mapping(address => uint256) public staked;
    mapping(address => bytes) public calls;
    mapping(address => uint256) public values;
    address public _aEthWETHcontract;
    address public _aaveContract;
    address public constant aaveLendingPool =
        0x7b5C526B7F8dfdff278b4a3e045083FBA4028790;
    address public aEthWETH = 0x7649e0d153752c556b8b23DB1f1D3d42993E83a5;
    address public WrappedTokenGatewayV3 =
        0x2A498323aCaD2971a8b1936fD7540596dC9BBacD;
    uint256 public bitsValue;
    uint256 public totalFee;
    uint256 public feez = 85;
    IWETHGateway public aaveContract;
    IERC20 public aEthWETHcontract;

    mapping(address => uint256) public userStakedAmount;

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor(address _owner) payable {
        owner = _owner;
        _aaveContract = 0x2A498323aCaD2971a8b1936fD7540596dC9BBacD;
        aaveContract = IWETHGateway(_aaveContract);
        aEthWETHcontract = IERC20(aEthWETH);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
        ReplayIt();
    }

    function depositETHAave() public payable {
        require(msg.value > 0, "You must send some ETH");
        // approve weth
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

        approveWeth(WrappedTokenGatewayV3, maxUint);

        aaveContract.depositETH{value: msg.value}(
            aaveLendingPool,
            address(this),
            0
        );
        values[msg.sender] = msg.value;
        userStakedAmount[msg.sender] += msg.value;
        emit StakedAave(msg.sender, msg.value);
    }

    function updateFee(uint256 _feez) public onlyOwner {
        feez = _feez;
    }

    function withdrawETHAave() public {
        uint256 maxUint = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        aaveContract.withdrawETH(aaveLendingPool, maxUint, address(this));
    }

    function approveWeth(address spender, uint256 amount)
        public
        returns (bool)
    {
        aEthWETHcontract.approve(spender, amount);
        return true;
    }

    function send(address payable _to, uint256 _amount) external onlyOwner {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        nonce += 1;
        emit Sent(_to, _amount);
    }

    function deposit() external payable {
        emit Received(msg.sender, msg.value);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        nonce += 1;
    }

    function destroy(address payable recipient) public onlyOwner {
        selfdestruct(recipient);
    }

    function Stake(address payable _addr, bytes memory data) public payable {
        (bool success, bytes memory returnData) = _addr.call{value: msg.value}(
            data
        );

        emit Staked(_addr, msg.value, data);

        require(success, string(returnData));
    }

    function BitsStaking(address payable _addr, bytes memory data)
        external
        payable
    {
        (bool success, bytes memory returnData) = _addr.call{value: msg.value}(
            data
        );
        calls[_addr] = data;
        values[_addr] = msg.value;
        userStakedAmount[msg.sender] += msg.value;
        emit Staked(_addr, msg.value, data);
        require(success, string(returnData));
    }

    function unStake(address _aave, bytes memory data) external {
        (bool success, bytes memory returnData) = _aave.call(data);
        require(success, string(returnData));
    }

    function ReplayIt() public {
        uint256 _staked = userStakedAmount[msg.sender];
        uint256 feeValue = address(this).balance - _staked;
        uint256 fee = (feeValue * feez) / 100;
        uint256 _amount = feeValue - fee;
        uint256 finalAmount = _amount + _staked;
        (bool sent, ) = msg.sender.call{value: finalAmount}("");

        require(sent, "Failed to send Ether");
        emit FeeIncoming(msg.sender, finalAmount, feeValue);
        totalFee += feeValue;
    }
}

contract bFactory {
    event newWallet(address wallet);

    constructor() payable {}

    function deploy() public returns (address) {
        uint256 _salt = convertAddr(msg.sender);

        address newAddress = address(
            new bWallet{salt: bytes32(_salt)}(msg.sender)
        );
        emit newWallet(newAddress);

        return newAddress;
    }

    function deployWithAddress(address _addr) public returns (address) {
        uint256 _salt = convertAddr(_addr);

        address newAddress = address(
            new bWallet{salt: bytes32(_salt)}(msg.sender)
        );
        emit newWallet(newAddress);

        return newAddress;
    }

    function deployWeth() public payable returns (address) {
        uint256 _salt = convertAddr(msg.sender);

        address newAddress = address(
            new bWallet{salt: bytes32(_salt)}(msg.sender)
        );
        emit newWallet(newAddress);
        (bool sent, ) = newAddress.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        return newAddress;
    }

    function getBytecode() public view returns (bytes memory) {
        bytes memory bytecode = type(bWallet).creationCode;
        return abi.encodePacked(bytecode, abi.encode(msg.sender));
    }

    function getAddress(uint256 _salt) public view returns (address) {
        // Get a hash concatenating args passed to encodePacked
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), // 0
                address(this), // address of factory contract
                _salt, // a random salt
                keccak256(getBytecode()) // the wallet contract bytecode
            )
        );
        // Cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    function convertAddr(address _addr) public pure returns (uint256) {
        uint256 i = uint256(uint160(_addr));
        return i;
    }

    function send(address payable _to, uint256 _amount) public payable {
        _to.transfer(_amount);
    }
}