//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BEP1155.sol";


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface  BEP20 {
    
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract OREFORGE is BEP1155, Ownable, BEP1155Burnable{
    event Approve(
        address indexed owner,
        uint256 indexed token_id,
        bool approved
    );
    event OrderPlace(
        address indexed from,
        uint256 indexed tokenId,
        uint256 indexed value
    );
    event CancelOrder(address indexed from, uint256 indexed tokenId);
    event ChangePrice(address indexed from, uint256 indexed tokenId, uint256 indexed value);
    using SafeMath for uint256;
    struct Order {
        uint256 tokenId;
        uint256 price;
    }
    mapping(address => mapping(uint256 => Order)) public order_place;
    mapping(uint256 => mapping(address => bool)) public checkOrder;
    mapping(uint256 => uint256) public totalQuantity;
    
    mapping(uint256 => uint256) public _royal;
    mapping(string => address) private tokentype;
    uint256 private serviceValue;
    string private _currentBaseURI;
    uint256 public _tid;
    
    
    constructor(
        uint256 id,
        uint256 _serviceValue,
        string memory _name,
        string memory _symbol
    ) BEP1155("",_name,_symbol) {
         _tid = id;
        serviceValue = _serviceValue;
    }
    function getServiceFee() public view returns (uint256) {
        return serviceValue;
    }
    function serviceFunction(uint256 _serviceValue) public onlyOwner{
        serviceValue = _serviceValue;
    }
    function addID(uint256 value) public returns (uint256) {
        _tid = _tid + value;
        return _tid;
    }
    function getTokenAddress(string memory _type)
        public
        view
        returns (address)
    {
        return tokentype[_type];
    }
    function addTokenType(string memory _type, address tokenAddress)
        public
        onlyOwner
    {
        tokentype[_type] = tokenAddress;
    }
    function setApproval(address operator, bool approved)
        public
        returns (uint256)
    {
        setApprovalForAll(operator, approved);
        uint256 id_ = addID(1).add(block.timestamp);
        emit Approve(msg.sender, id_, approved);
        return id_;
    }
    function mint(uint256 id, uint256 value, uint256 royal, uint256 nooftoken, string memory ipfsname,
        string memory ipfsimage,
         string memory ipfsmetadata ) public {
        _mint(msg.sender, id, nooftoken, "");
        token_id[id] = Metadata(ipfsname, ipfsimage, ipfsmetadata);
        _creator[id]=msg.sender;
       _royal[id]=royal.mul(1e18);
       if(value != 0){
            orderPlace(id, value);
        }
    }
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {
        _mintBatch(to, ids, amounts, "");
    }
    function saleWithToken(
        address payable from,
        uint256 tokenId,
        uint256 amount,
        uint256 nooftoken,
        string memory bidtoken
        ) public{
            checker[tokenId][from] = true;
            _saleToken(from, tokenId, amount, bidtoken);
            saleTokenTransfer(from, tokenId, nooftoken);
            
        }
    
    function saleToken(
        address payable from,
        uint256 tokenId,
        uint256 amount,
        uint256 nooftoken
    ) public payable {
        require(amount == order_place[from][tokenId].price.mul(nooftoken) , "Invalid Balance");
        checker[tokenId][from] = true;
        _saleToken(from, tokenId, amount, "BNB");
        saleTokenTransfer(from, tokenId, nooftoken);
    }
    function _saleToken(
        address payable from,
        uint256 tokenId,
        uint256 amount,
        string memory bidtoken
    ) internal {
        uint256 val = pBEPent(amount, serviceValue).add(amount);
        if(keccak256(abi.encodePacked((bidtoken))) == keccak256(abi.encodePacked(("BNB")))){   
            require( msg.value == val, "Insufficient Balance");
            address payable create = payable(_creator[tokenId]);
            (uint256 _adminfee, uint256 roy, uint256 netamount) = calc(amount, _royal[tokenId], serviceValue);
            require( msg.value == _adminfee.add(roy.add(netamount)), "Insufficient Balance");
            address payable admin = payable(owner());
            admin.transfer(_adminfee);
            create.transfer(roy);
            from.transfer(netamount);
        }
        else{
            BEP20 t = BEP20(tokentype[bidtoken]);
            uint256 approveValue = t.allowance(msg.sender, address(this));
            require( approveValue >= val, "Insufficient Balance");
            (uint256 _adminfee, uint256 roy, uint256 netamount) = calc(amount, _royal[tokenId], serviceValue);
            require( approveValue >= _adminfee.add(roy.add(netamount)), "Insufficient Balance");
            t.transferFrom(msg.sender, owner(), _adminfee);
            t.transferFrom(msg.sender,_creator[tokenId],roy);
            t.transferFrom(msg.sender,from,netamount);
        }
    }
    function pBEPent(uint256 value1, uint256 value2)
        internal
        pure
        returns (uint256)
    {
        uint256 result = value1.mul(value2).div(1e20);
        return (result);
    }
    function calc(
        uint256 amount,
        uint256 royal,
        uint256 _serviceValue
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 fee = pBEPent(amount, _serviceValue);
        uint256 roy = pBEPent(amount, royal);
        uint256 netamount = amount.sub(fee.add(roy));
        fee = fee.add(fee);
        return (fee, roy, netamount);
    }
    function saleTokenTransfer(
        address payable from,
        uint256 tokenId,
        uint256 NOFToken
    ) internal {
        safeTransferFrom(from, msg.sender, tokenId, NOFToken, "");
    }
  
    function acceptBId(string memory bidtoken,address bidaddr, uint256 amount, uint256 tokenId, uint256 NOFToken) public{
        _acceptBId(bidtoken, bidaddr, amount, tokenId, owner());
        tokenTrans(tokenId, msg.sender, bidaddr, NOFToken);
            if(checkOrder[tokenId][msg.sender] == true){
                if(_balances[tokenId][msg.sender] == 0){   
                    delete order_place[msg.sender][tokenId];
                    checkOrder[tokenId][msg.sender] = false;
                }
            }
    }
    function _acceptBId(string memory tokenAss,address from, uint256 amount, uint256 tokenId, address admin) internal{
        uint256 val = pBEPent(amount, serviceValue).add(amount);
        BEP20 t = BEP20(tokentype[tokenAss]);
        uint256 approveValue = t.allowance(from, address(this));
        require( approveValue >= val, "Insufficient Balance");
        require(_balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        (uint256 _adminfee, uint256 roy, uint256 netamount) = calc(amount, _royal[tokenId], serviceValue);
        require( approveValue >= _adminfee.add(roy.add(netamount)), "Insufficient Balance");
        t.transferFrom(from, admin, _adminfee);
        t.transferFrom(from,_creator[tokenId],roy);
        t.transferFrom(from,msg.sender,netamount);
    }
    function tokenTrans(uint256 tokenId,address from, address to, uint256 NOFToken) internal{
            safeTransferFrom(from,to, tokenId, NOFToken, ""); 
    }
    function orderPlace(uint256 tokenId, uint256 _price) public{
        require( _balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        Order memory order;
        order.tokenId = tokenId;
        order.price = _price;
        order_place[msg.sender][tokenId] = order;
        checkOrder[tokenId][msg.sender] = true;
        emit OrderPlace(msg.sender, tokenId, _price);
    }
    function cancelOrder(uint256 tokenId) public{
        require(_balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        delete order_place[msg.sender][tokenId];
        checkOrder[tokenId][msg.sender] = false;
        emit CancelOrder(msg.sender, tokenId);
    }
    function changePrice(uint256 value, uint256 tokenId) public{
        require( _balances[tokenId][msg.sender] > 0, "Is Not a Owner");
        require( value < order_place[msg.sender][tokenId].price);
        order_place[msg.sender][tokenId].price = value;
        emit ChangePrice(msg.sender, tokenId, value);
    }
    function burnToken(address from, uint256 tokenId, uint256 NOFToken ) public{
        require( (_balances[tokenId][from] >= NOFToken && from == msg.sender) || msg.sender == owner(), "Your Not a Token Owner or insufficient Token Balance");
        require( _balances[tokenId][from] >= NOFToken, "Your Not a Token Owner or insufficient Token Balance");
            burn(from, tokenId, NOFToken);
            if(_balances[tokenId][from] == NOFToken){
                if(checkOrder[tokenId][from]==true){
                    delete order_place[from][tokenId];
                    checkOrder[tokenId][from] = false;
                }
            }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
import "@openzeppelin/contracts/access/Ownable.sol";


interface IBEP165 {
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract BEP165 is IBEP165 {
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IBEP165).interfaceId;
    }
}
interface IBEP1155 is IBEP165 {
    
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
    
    event URI(string value, uint256 indexed id);
    
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
    
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    
    function setApprovalForAll(address operator, bool approved) external;
    
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
interface IBEP1155MetadataURI is IBEP1155 {
    
    
    function uri(uint256 id) external view returns (string memory);
     
    function name() external view returns (string memory);
    
    function symbol() external view returns (string memory);
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }
    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }
    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    
    function toString(uint256 value) internal pure returns (string memory) {
        
        
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
    
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

interface IBEP1155Receiver is IBEP165 {
    
    function onBEP1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
    
    function onBEP1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

contract BEP1155 is Context, BEP165, IBEP1155, IBEP1155MetadataURI {
    using Address for address;
    using Strings for uint256;
       
    string private _name;
    
    string private _symbol;
    struct Metadata {
        string name;
        string ipfsimage;
        string ipfsmetadata;
    }
    
    mapping(uint256 => mapping(address => uint256)) public _balances;
    mapping(uint256 => Metadata) token_id;
    
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) public _creator;
    mapping(uint256 => mapping(address => bool)) public checker;
    
    string private _uri;
    
    constructor(string memory uri_,string memory name_, string memory symbol_) {
        _setURI(uri_);
         _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
  
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BEP165, IBEP165)
        returns (bool)
    {
        return
            interfaceId == type(IBEP1155).interfaceId ||
            interfaceId == type(IBEP1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    
    function uri(uint256 tokenId) public view virtual override returns (string memory ipfsmetadata) {
        
        Metadata memory date = token_id[tokenId];
        ipfsmetadata = date.ipfsmetadata;
        
        return ipfsmetadata;
        
    }
    
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            account != address(0),
            "BEP1155: balance query for the zero address"
        );
        return _balances[id][account];
    }
    
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "BEP1155: accounts and ids length mismatch"
        );
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }
    
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "BEP1155: setting approval status for self"
        );
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            isApprovedForAll(_creator[id], address(this)),
            "BEP1155: caller is not approved"
        );
        require(
            from == _msgSender() || checker[id][from] == true,
            "BEP1155: caller is not owner"
        );
        _safeTransferFrom(from, to, id, amount, data);
        if(_msgSender() != from){
            checker[id][from] = false;
        }
    }
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, address(this)),
            "BEP1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "BEP1155: transfer to the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );
        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "BEP1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;
        emit TransferSingle(operator, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }
    
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "BEP1155: ids and amounts length mismatch"
        );
        require(to != address(0), "BEP1155: transfer to the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "BEP1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }
        emit TransferBatch(operator, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }
    
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }
    
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "BEP1155: mint to the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );
        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);
        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            account,
            id,
            amount,
            data
        );
    }
    
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "BEP1155: mint to the zero address");
        require(
            ids.length == amounts.length,
            "BEP1155: ids and amounts length mismatch"
        );
        address operator = _msgSender();
        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }
        emit TransferBatch(operator, address(0), to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            data
        );
    }
    
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "BEP1155: burn from the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );
        uint256 accountBalance = _balances[id][account];
        require(
            accountBalance >= amount,
            "BEP1155: burn amount exceeds balance"
        );
        unchecked {
            _balances[id][account] = accountBalance - amount;
        }
        emit TransferSingle(operator, account, address(0), id, amount);
    }
    
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "BEP1155: burn from the zero address");
        require(
            ids.length == amounts.length,
            "BEP1155: ids and amounts length mismatch"
        );
        address operator = _msgSender();
        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 accountBalance = _balances[id][account];
            require(
                accountBalance >= amount,
                "BEP1155: burn amount exceeds balance"
            );
            unchecked {
                _balances[id][account] = accountBalance - amount;
            }
        }
        emit TransferBatch(operator, account, address(0), ids, amounts);
    }
    
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IBEP1155Receiver(to).onBEP1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IBEP1155Receiver.onBEP1155Received.selector) {
                    revert("BEP1155: BEP1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("BEP1155: transfer to non BEP1155Receiver implementer");
            }
        }
    }
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IBEP1155Receiver(to).onBEP1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IBEP1155Receiver.onBEP1155BatchReceived.selector
                ) {
                    revert("BEP1155: BEP1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("BEP1155: transfer to non BEP1155Receiver implementer");
            }
        }
    }
    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }
}

abstract contract BEP1155Burnable is BEP1155, Ownable {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, address(this)) || owner() == _msgSender(),
            "BEP1155: caller is not owner nor approved"
        );
        _burn(account, id, value);
    }
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, address(this)),
            "BEP1155: caller is not owner nor approved"
        );
        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}