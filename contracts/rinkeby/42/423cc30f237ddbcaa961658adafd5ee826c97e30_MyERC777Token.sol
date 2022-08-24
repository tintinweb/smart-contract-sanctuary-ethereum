/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;


interface IERC777 {
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function granularity() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function send(address recipient,uint256 amount,bytes calldata data) external;

    function burn(uint256 amount, bytes calldata data) external;

    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    function authorizeOperator(address operator) external;

    function revokeOperator(address operator) external;

    function defaultOperators() external view returns (address[] memory);

    function operatorSend(address sender,address recipient,uint256 amount,bytes calldata data,bytes calldata operatorData) external;

    function operatorBurn(address account,uint256 amount,bytes calldata data,bytes calldata operatorData) external;

    event Sent(address indexed operator,address indexed from,address indexed to,uint256 amount,bytes data,bytes operatorData);
}

interface IERC777Recipient {
    function tokensReceived(address operator,address from,address to,uint256 amount,bytes calldata userData,bytes calldata operatorData) external;
}

interface IERC777Sender {
    function tokensToSend(address operator,address from,address to,uint256 amount,bytes calldata userData,bytes calldata operatorData) external;
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

library Address {
  
    function isContract(address account) internal view returns (bool) {
    
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target,bytes memory data,uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target,bytes memory data,uint256 value,string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target,bytes memory data,string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target,bytes memory data,string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC1820Registry {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);
    event ManagerChanged(address indexed account, address indexed newManager);
    function setManager(address account, address newManager) external;
    function getManager(address account) external view returns (address);
    function setInterfaceImplementer(address account,bytes32 _interfaceHash,address implementer) external;
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);
    function updateERC165Cache(address account, bytes4 interfaceId) external;
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}
interface Staking {
   function checkBool(address user) external view returns (bool);
}

contract MyERC777Token is Context, IERC777, IERC20 {
    using Address for address;

    IERC1820Registry internal constant _ERC1820_REGISTRY = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
  

    Staking public StakeContract;
    string private _name;
    string private _symbol;
    address private owner;
    uint256 private _totalSupply;
    address[] private _defaultOperatorsArray;
    uint256 public rewardBurningPercentage = 3 ;

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");


    mapping(address => uint256) private _balances;
    mapping(address => bool) private _defaultOperators;
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;
    mapping(address => mapping(address => uint256)) private _allowances;


    constructor(string memory name_,string memory symbol_, address[] memory defaultOperators_) {
        _name = name_;
        _symbol = symbol_;
        _defaultOperatorsArray = defaultOperators_;
        _totalSupply = 10000000000 ether;
        owner == msg.sender;
        _balances[address(this)] = _totalSupply;
        _defaultOperatorsArray = defaultOperators_;
        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _defaultOperators[defaultOperators_[i]] = true;
        }

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    function granularity() public view virtual override returns (uint256) {
        return 1;
    }

    function totalSupply() public view virtual override(IERC20, IERC777) returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenHolder) public view virtual override(IERC20, IERC777) returns (uint256) {
        return _balances[tokenHolder];
    }

    function send(address recipient,uint256 amount,bytes memory data) public virtual override {
        _send(_msgSender(), recipient, amount, data, "", true);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _send(_msgSender(), recipient, amount, "", "", false);
        return true;
    }

    function burn(uint256 amount, bytes memory data) public virtual override {
        _burn(_msgSender(), amount, data, "");
    }

    function isOperatorFor(address operator, address tokenHolder) public view virtual override returns (bool) {
        return
            operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }

    function authorizeOperator(address operator) public virtual override {
        require(_msgSender() != operator, "ERC777: authorizing self as operator");

        if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[_msgSender()][operator];
        } else {
            _operators[_msgSender()][operator] = true;
        }

        emit AuthorizedOperator(operator, _msgSender());
    }

    function revokeOperator(address operator) public virtual override {
        require(operator != _msgSender(), "ERC777: revoking self as operator");

        if (_defaultOperators[operator]) {
            _revokedDefaultOperators[_msgSender()][operator] = true;
        } else {
            delete _operators[_msgSender()][operator];
        }

        emit RevokedOperator(operator, _msgSender());
    }

    function defaultOperators() public view virtual override returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    function operatorSend(address sender,address recipient,uint256 amount,bytes memory data,bytes memory operatorData) public virtual override {
        require(isOperatorFor(_msgSender(), sender), "ERC777: caller is not an operator for holder");
        _send(sender, recipient, amount, data, operatorData, true);
    }

    function operatorBurn(address account,uint256 amount,bytes memory data,bytes memory operatorData) public virtual override {
        require(isOperatorFor(_msgSender(), account), "ERC777: caller is not an operator for holder");
        _burn(account, amount, data, operatorData);
    }

    function allowance(address holder, address spender) public view virtual override returns (uint256) {
        return _allowances[holder][spender];
    }

  
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address holder = _msgSender();
        _approve(holder, spender, value);
        return true;
    }

    function transferFrom(address holder,address recipient,uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(holder, spender, amount);
        _send(holder, recipient, amount, "", "", false);
        return true;
    }

    function _mint(address account,uint256 amount,bytes memory userData,bytes memory operatorData) internal virtual {
        _mint(account, amount, userData, operatorData, true);
    }

    function _mint(address account,uint256 amount,bytes memory userData,bytes memory operatorData,bool requireReceptionAck) internal virtual {
        require(account != address(0), "ERC777: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, amount);

        // Update state variables
        _totalSupply += amount;
        _balances[account] += amount;

        _callTokensReceived(operator, address(0), account, amount, userData, operatorData, requireReceptionAck);

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    function _send(address from,address to,uint256 amount,bytes memory userData,bytes memory operatorData,bool requireReceptionAck) internal virtual {
        require(from != address(0), "ERC777: transfer from the zero address");
        require(to != address(0), "ERC777: transfer to the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, to, amount, userData, operatorData);

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }

    function _burn(address from,uint256 amount,bytes memory data,bytes memory operatorData) internal virtual {
        require(from != address(0), "ERC777: burn from the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, address(0), amount, data, operatorData);

        _beforeTokenTransfer(operator, from, address(0), amount);

        // Update state variables
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: burn amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _totalSupply -= amount;

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    function _move(address operator,address from,address to,uint256 amount,bytes memory userData,bytes memory operatorData) private {
        _beforeTokenTransfer(operator, from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    function _approve(address holder,address spender,uint256 value) internal virtual {
        require(holder != address(0), "ERC777: approve from the zero address");
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    function _callTokensToSend(address operator,address from,address to,uint256 amount,bytes memory userData,bytes memory operatorData) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(from, _TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }

    function _callTokensReceived(address operator,address from,address to,uint256 amount,bytes memory userData,bytes memory operatorData,bool requireReceptionAck) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(to, _TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777Recipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (requireReceptionAck) {
            require(!to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
    }

    function _spendAllowance(address _owner,address spender,uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(_owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC777: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(address operator,address from,address to,uint256 amount) internal virtual {}

    modifier onlyStaking{
        require( StakeContract.checkBool(tx.origin) == true ," Only Staking Allowed ");
        _;
    }
    
    function addStaking(Staking _contract) public   {
        StakeContract = _contract;
    }

    function getPercentage(uint256 _value) public view returns(uint256,uint256) {
       uint256 burnpercentage = (_value * (rewardBurningPercentage)) / (100);
       uint256 reward = _value - (burnpercentage);
       uint256 burnAmount;
       burnAmount = burnpercentage;
       return (reward,burnAmount);
    }

    function updateBurningPercentage(uint256 _percentage) public  {
        rewardBurningPercentage = _percentage ; 
    }
    
    function WithdrawStakingReward( uint256 _value)  external onlyStaking {
        (uint256 rewardY,uint256 burnAmount) =  getPercentage(_value);
         _send (address(this),tx.origin, rewardY,"","",true);
        _burn(tx.origin,burnAmount,"","");
    }

}