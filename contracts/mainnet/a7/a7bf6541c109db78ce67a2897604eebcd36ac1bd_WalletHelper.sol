/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

//refrence https://github.com/OpenZeppelin/openzeppelin-contracts

library Address {     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
      
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "A1");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "A2");
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {      
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "S1"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + (value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - (value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
  
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "S2");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "S3");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "S4");
        }
    }
}

// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Create2.sol
library Create2 {
  
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "C1");
        require(bytecode.length != 0, "C2");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "C3");
        return addr;
    }
 
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }
    
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}


contract ContractCreate2 {

    event OnDeployContract(address indexed _user, uint256 _amount, bytes32 _salt,  bytes32 _bytecodeHash, address _contract);

    //部署合约。不管在哪个chainid，如果输入参数是一样的，通过这种方式部署的合约地址都是一样的！
    function deployContract(bytes32 _salt, bytes memory _bytecode) external payable returns (address) {
        uint256 _amount = msg.value;
        address  _contract = Create2.deploy(_amount, _salt, _bytecode);     //参数一样，重复部署会失败！
        bytes32 _bytecodeHash = keccak256(_bytecode);
        emit OnDeployContract(msg.sender, _amount,  _salt, _bytecodeHash, _contract);
        return _contract;
    }

    //计算通过本合约部署的合约的地址。      注意：输入的是hash， _bytecodeHash
    function computeContractAddress1(bytes32 _salt, bytes32 _bytecodeHash) external view returns (address) {
        return Create2.computeAddress(_salt, _bytecodeHash);
    }

    //通用的计算合约地址。                  注意：输入的是hash， _bytecodeHash
    function computeContractAddress2(bytes32 _salt, bytes32 _bytecodeHash, address _deployer) public pure returns (address) {
        return Create2.computeAddress(_salt,  _bytecodeHash,  _deployer);
    }

}


interface IBatchTransfer {
    function batchTransfer1(address payable[] calldata _tos, uint256 _amount, uint256 _batchId, bool _isShowSuccess) external payable;
    function batchTransfer2(address payable[] calldata _tos, uint256[] calldata _amounts, uint256 _batchId, bool _isShowSuccess) external payable;
    function tokenTransfer(address _erc20Token, address _to, uint256 _amount, bool _isShowSuccess) external;
    function batchTokenTransfer1(address _erc20Token, address[] calldata _tos, uint256 _amount, uint256 _batchId, bool _isShowSuccess) external;
    function batchTokenTransfer2(address _erc20Token, address [] calldata _tos, uint256[] calldata _amounts, uint256 _batchId, bool _isShowSuccess) external;
}


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "TS");
        return string(buffer);
    }

}




contract WalletHelper is ContractCreate2, IBatchTransfer {
    using Address for address;
    using SafeERC20 for IERC20;

    address payable public Admin;

    constructor (address payable _admin) {
        require(_admin != address(0));
        Admin = _admin;
    }

    bool private unlocked = true;           //避免重入。有调用外部合约的时候，可以谨慎使用！
    modifier lock() {
        require(unlocked == true, "L");
        unlocked = false;
        _;
        unlocked = true;
    }
    
    ///////////////////////////////////////////////////////////////////////////////

    // 得到以太坊的事务签名。输入：消息Hash；输出：事务Hash。
    function GetBytesHash(bytes calldata _bytecode) external pure returns (bytes32) {
        return keccak256(_bytecode);
    }
 
    function GetBytes32Hash(bytes32 _data) external pure returns (bytes32) {
        return keccak256(abi.encode(_data));            // 一个bytes32值情况下 abi.encode  和 abi.encodePacked 一样
    }

    // 得到以太坊的事务签名。输入：消息Hash；输出：事务Hash。
    function GetEthSignedMessageHash(bytes32 _hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    ///////////////////////////////////////////////////////////////////////////////

    function ToString(uint256 value) external pure  returns (string memory) {
        return Strings.toString(value);
    }

    function ToHexString1(uint256 value) external pure  returns (string memory) {
        return Strings.toHexString(value);
    }

    function ToHexStrin2(uint256 value, uint256 length) external pure  returns (string memory) {
        return Strings.toHexString(value, length);
    }

    ///////////////////////////////////////////////////////////////////////////////


    function IsContract(address account) public view returns (bool) {
        return account.isContract();
    }     

    function getAddress1(bytes32 h, bytes32 _r, bytes32 _s, uint8 _v) public pure returns (address _address) 
    {
        _address = ecrecover(h, _v, _r, _s);
    }

    function getAddress2(bytes32 h, bytes memory sig) public pure returns (address _address) 
    {
        bytes32 _r;
        bytes32 _s;
        uint8 _v;
        if (sig.length == 65) {
            assembly {
                _r := mload(add(sig, 32))
                _s := mload(add(sig, 64))
                _v := and(mload(add(sig, 65)), 255)
            }
            if (_v < 27) {
                _v += 27;
            }
            if (_v == 27 || _v == 28) {
                _address = ecrecover(h, _v, _r, _s);
            }
        }
    }

    function GetRSV(bytes32 h, bytes memory sig) public pure returns (address _address,  bytes32 _r, bytes32 _s, uint8 _v) 
    {
        if (sig.length == 65) {
            assembly {
                _r := mload(add(sig, 32))
                _s := mload(add(sig, 64))
                _v := and(mload(add(sig, 65)), 255)
            }
            if (_v < 27) {
                _v += 27;
            }
            if (_v == 27 || _v == 28) {
                _address = ecrecover(h, _v, _r, _s);
            }
        }
    }


    ///////////////////////////////////////////////////////////////////////////////
  
    event OnTransfer(uint256 indexed _batchId, address indexed _to, bool indexed _done, uint256 _amount, address _sender);

    function batchTransfer1(address payable[] calldata _tos, uint256 _amount, uint256 _batchId, bool _isShowSuccess) 
        external payable override lock 
    {
        require(_amount > 0, "B1");
        require(_tos.length > 0, "B2");
        uint RemAmount = msg.value - (_amount * (_tos.length));
        for(uint i = 0; i < _tos.length; i++){
            address payable to = _tos[i];
            // if(to != address(0)){
            if(to != address(0) && _amount > 0 && !address(to).isContract()){   //对方是合约，不处理，有风险！   
                to.transfer(_amount);                                           //如果接收方是恶意的合约，在接受时候抛出异常了，所有转账会失败的。 只有以太币有这个问题， token没有。
                
                if (_isShowSuccess){
                    emit OnTransfer(_batchId, to, true, _amount, msg.sender);
                }
            }
            else
            {
                emit OnTransfer(_batchId, to, false, _amount, msg.sender);
            }     
        }
        if(RemAmount > 0)
        {
            payable(msg.sender).transfer(RemAmount);  
        }
    }

    function batchTransfer2(address payable[] calldata _tos, uint256[] calldata _amounts, uint256 _batchId, bool _isShowSuccess) 
        external payable override  lock  
    {
        require(_amounts.length > 0, "B3");
        require(_tos.length > 0, "B4");
        require(_amounts.length == _tos.length, "B5");
        uint RemAmount = msg.value;
        for(uint i = 0; i < _tos.length; i++){
            address payable to = _tos[i];
            uint amount = _amounts[i];
            // if(to != address(0) && amount > 0){
            if(to != address(0) && amount > 0 && !address(to).isContract()){    //对方是合约，不处理，有风险！   
                RemAmount = RemAmount - (amount);
                to.transfer(amount);                                            //不支持合约收款（ETH）
                if (_isShowSuccess){
                    emit OnTransfer(_batchId, to, true, amount, msg.sender);
                }
            }
            else
            {
                emit OnTransfer(_batchId, to, false, amount, msg.sender);
            }     
        }
        if(RemAmount > 0)
        {
            payable(msg.sender).transfer(RemAmount);  
        }
    }
    
    event OnTokenTransfer(uint256 indexed _batchId, address indexed _to, bool indexed _done, uint256 _amount, address _sender, address _erc20Token);

    function tokenTransfer(address _erc20Token, address _to, uint256 _amount, bool _isShowSuccess) external override  lock  {
        require(_erc20Token != address(0), "T1");
        require(_to != address(0), "T2");
        require(_amount > 0, "T3");

        IERC20 token = IERC20(_erc20Token);
        token.safeTransferFrom(msg.sender, _to, _amount);                                           //aprove
        if (_isShowSuccess){
            emit OnTokenTransfer(0, _to, true, _amount, msg.sender, _erc20Token);
        }         
    }

    function batchTokenTransfer1(address _erc20Token, address[] calldata _tos, uint256 _amount, 
        uint256 _batchId, bool _isShowSuccess) external override  lock  
    {
        require(_erc20Token != address(0), "B10");
        require(_amount > 0, "B11");
        require(_tos.length > 0, "B12");
        IERC20 token = IERC20(_erc20Token);
        for(uint i = 0; i < _tos.length; i++){
            address to = _tos[i];
            if(to != address(0)){
                token.safeTransferFrom(msg.sender, to, _amount);
                if (_isShowSuccess){
                    emit OnTokenTransfer(_batchId, to, true, _amount, msg.sender, _erc20Token);     //aprove
                }
            }
            else
            {
                emit OnTokenTransfer(_batchId, to, false, _amount, msg.sender, _erc20Token);
            }     
        }
    }

    function batchTokenTransfer2(address _erc20Token, address [] calldata _tos, uint256[] calldata _amounts, 
        uint256 _batchId, bool _isShowSuccess) external override  lock  
    {
        require(_erc20Token != address(0), "B20");
        require(_amounts.length > 0, "B21");
        require(_tos.length > 0, "B22");
        require(_amounts.length == _tos.length, "B23");
        IERC20 token = IERC20(_erc20Token);
        for(uint i = 0; i < _tos.length; i++){
            if(_tos[i] != address(0) && _amounts[i] > 0){
                token.safeTransferFrom(msg.sender, _tos[i], _amounts[i]);                           //aprove
                if (_isShowSuccess){
                    emit OnTokenTransfer(_batchId, _tos[i], true, _amounts[i], msg.sender, _erc20Token);
                }
            }
            else
            {
                emit OnTokenTransfer(_batchId, _tos[i], false, _amounts[i], msg.sender, _erc20Token);
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////////

    //管理员取走所有资产, 会有人往这个合约打款吗？ 估计没有，预留此功能吧（就像很多人给热门合约转token一样，转进去就无法取出）。
    function withdraw(address _token) external lock {
        if (_token == address(0)) {
            uint amount = address(this).balance;
            if (amount > 0) {
                Admin.transfer(amount);
            }          
        }
        else
        {
            uint amount = IERC20(_token).balanceOf(address(this));  
            if (amount > 0) {
                IERC20(_token).transfer(Admin, amount);
            }          
        }
    } 

    receive() external payable {        
    }
    
    // fallback() external {
    // }

    ///////////////////////////////////////////////////////////////////////////////

}