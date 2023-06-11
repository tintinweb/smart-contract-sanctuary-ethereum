/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: MIT

// *************************************************************************************************************************************
// *************************************************************************************************************************************
// *****************.     .,*/**********************************************************************************************************
// ************                 ,*******************************************************************************************************
// *********.          .         **********************************************************************/********************************
// ********      ############ ,**********&@@@@@@@@@@@@@@@@/****@@@@@@@@@@@@@@@@@@%/**%@&*************/@@****&@@@@@@@@@@@@@@@@@@@&/******
// *******     #############*   ********@@***************/*****@@**************/*@@**%@&**************@@*************%@&****************
// *****/     #####**(###(**    .*******@@@********************@@****************%@@*%@&**************@@*************%@&****************
// ******     ####********/##     *********&@@@@@#/************@@***************/@@**%@&**************@@*************%@&****************
// ******.    ###***/****/####    *****************%@@@@@/*****@@@@@@@@@@@@@@@@@@****%@&**************@@*************%@&****************
// *******     /**####**(###%.    ***********************@@@***@@********************%@&**************@@*************%@&****************
// ********,  .(############,     ************************@@***@@*********************@@**************@@*************%@&****************
// ********** (###########..     *******@@@@@@@@@@@@@@@@@@@****@@**********************@@@@@@@@@%(****@@*************%@&****************
// *******,           .       .*************/((((((((/*********//*************************************/*********************************
// ********.                .***********************************************************************************************************
// *************.     .,****************************************************************************************************************
// *************************************************************************************************************************************
// *************************************************************************************************************************************

pragma solidity 0.8.13;

interface ICallProxy {
    function anyCall(address _to, bytes calldata _data, address _fallback, uint256 _toChainID, uint256 _flags) external payable;
    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
    function executor() external view returns (address executor);
}

contract SPLXToken {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed owner);
    event BridgeTransferSent(address indexed from, address indexed to, uint256 value, uint256 destChainID);
    event BridgeTransferReceived(address indexed from, address indexed to, uint256 value, uint256 fromChainID);

    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowance;
    uint256 private _totalSupply;
    address private deployer;
    address public router;
    string private constant _name = "Split Token";
    string private constant _symbol = "SPLX";
    uint8 private constant _decimals = 18;
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ANYCALL = 0xC10Ef9F491C9B59f936957026020C321651ac078;

    modifier onlyOwner() {
        require(msg.sender == deployer, "Split: Not allowed");
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == router && router != address(0), "Split: Not router");
        _;
    }

    constructor() {
        deployer = msg.sender;
        //_mint(msg.sender, 1e27);
    }

    receive() external payable {

    }

    fallback() external payable {

    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowance[owner][spender];
    }

    function bridgeTransfer(address recipient, uint256 amount, uint256 destChainID) public payable returns (bool) {
        uint256 beforeBalance = address(this).balance - msg.value;
        _burn(msg.sender, amount);
        emit BridgeTransferSent(msg.sender, recipient, amount, destChainID);
        bytes memory data = abi.encode(msg.sender, recipient, amount);
        ICallProxy(ANYCALL).anyCall{value: msg.value}(address(this), data, address(this), destChainID, 2);
        uint256 delta = address(this).balance - beforeBalance;
        assembly {
            if gt(delta, 0) {
                if iszero(call(gas(), caller(), delta, 0, 0, 0, 0)) { revert(0, 0) }
            }
        }
        return true;
    }

    function bridgeTransferFrom(address sender, address recipient, uint256 amount, uint256 destChainID) public payable returns (bool) {
        uint256 beforeBalance = address(this).balance - msg.value;
        _burn(sender, amount);
        uint256 currentAllowance = _allowance[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, msg.sender, currentAllowance - amount);
        }
        emit BridgeTransferSent(sender, recipient, amount, destChainID);
        bytes memory data = abi.encode(sender, recipient, amount);
        ICallProxy(ANYCALL).anyCall{value: msg.value}(address(this), data, address(this), destChainID, 2);
        uint256 delta = address(this).balance - beforeBalance;
        assembly {
            if gt(delta, 0) {
                if iszero(call(gas(), caller(), delta, 0, 0, 0, 0)) { revert(0, 0) }
            }
        }
        return true;
    }

    function anyExecute(bytes calldata _data) external returns (bool success, bytes memory result) {
        address anyCallExecutor = ICallProxy(ANYCALL).executor();
        (address from, uint256 fromChainID,) = ICallProxy(anyCallExecutor).context();
        require(from == address(this), "Split: verification failed");
        (address sender, address recipient, uint256 amount) = abi.decode(_data, (address, address, uint256));
        _mint(recipient, amount);
        emit BridgeTransferReceived(sender, recipient, amount, fromChainID);
        success = true;
        result = "";
    }

    function destroySelf() external onlyOwner {
        assembly {
            selfdestruct(caller())
        }
    }

    function rescueFunds(address token) external onlyOwner {
        assembly {
            if eq(token, ETH) {
                if iszero(call(gas(), caller(), balance(address()), 0, 0, 0, 0)) { revert(0, 0) }
            }
            if iszero(eq(token, ETH)) {
                let ptr := mload(0x40)
                mstore(ptr, shl(0xe0, 0x70a08231))
                mstore(add(ptr, 0x04), address())
                if iszero(staticcall(gas(), token, ptr, 0x24, ptr, 0x20)) { revert(0, 0) }
                let amount := mload(ptr)
                mstore(ptr, shl(0xe0, 0xa9059cbb))
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), amount)
                if iszero(call(gas(), token, 0, ptr, 0x44, 0, 0)) { revert(0, 0) }
            }
        }
    }

    function setRouter(address newRouter) external onlyOwner {
        router = newRouter;
    }

    function transferOwnership(address owner) external onlyOwner {
        deployer = owner;
        emit OwnershipTransferred(owner);
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowance[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowance[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowance[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) external onlyRouter returns (bool) {
        _burn(account, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balanceOf[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balanceOf[sender] = senderBalance - amount;
        }
        _balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        _totalSupply += amount;
        _balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
        uint256 accountBalance = _balanceOf[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balanceOf[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}