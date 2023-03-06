// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface CallProxy {
    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;

    function context()
        external
        view
        returns (
            address from,
            uint256 fromChainID,
            uint256 nonce
        );

    function executor() external view returns (address executor);
}

contract VestedERC20 {
    string public constant name = "Vested Token";
    string public constant symbol = "VTK";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    address public verifiedcaller;
    address public anycallExecutor;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowances;

    address public owner;

    constructor(uint256 initialSupply, address anycallProxyContract) {
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        owner = msg.sender;
        anycallExecutor = CallProxy(anycallProxyContract).executor();
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can perform this action"
        );
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256)
    {
        return allowances[_owner][_spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 allowed = allowances[sender][msg.sender];
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(
            balances[sender] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        require(allowed >= amount, "ERC20: transfer amount exceeds allowance");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _mint(uint256 amount, address to) private {
        totalSupply += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function changeverifiedcaller(address _contractcaller) external onlyOwner {
        verifiedcaller = _contractcaller;
    }

    function anyExecute(bytes memory _data)
        external
        returns (bool success, bytes memory result)
    {
        (address _to, uint256 amount) = abi.decode(_data, (address, uint256));
        (address from, , ) = CallProxy(anycallExecutor).context();
        require(verifiedcaller == from, "AnycallClient: wrong context");
        _mint(amount, _to);
        success = true;
        result = "";
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}