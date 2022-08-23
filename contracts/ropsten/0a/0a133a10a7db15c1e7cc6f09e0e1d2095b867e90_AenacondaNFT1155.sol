/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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
contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) internal onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


contract AenacondaNFT1155 is Ownable, Context {
    using SafeMath for uint256;
    using Address for address;

    event Updatedata(address indexed _from,address indexed _to,uint256 _id);
    event TransferSingle(address indexed _creator, uint256 _tokenid, uint256 _value);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    struct ownerDetail{
        address[] _history;
        uint256[] _amount;
    }
   
    mapping (uint256 => mapping(address => uint256)) internal balances;

    mapping (uint256 => address) public _creator;

    mapping(address => mapping(address => bool)) public operatorApproval;
    mapping(address => mapping(address => mapping (uint256 => uint256))) public operatorValueApproval;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) public totalQuantity;
    mapping(uint256 => uint256) public royaltyrates;
    mapping(uint256 => uint256) public valueof;
    mapping(uint256 => mapping(uint256 => uint256)) public valueSellcount;

    mapping(uint256 => ownerDetail) internal ownerDetails;

    string public name;
    string public symbol;
    address public admin;

   

    // uint256[] public 

    uint256 private tokenID;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        admin = msg.sender;
    }

    modifier onlyAdmin() {
            require(msg.sender == admin);
            _;
        }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function changeAdmin(address _newAdmin) public onlyAdmin returns(bool){
        admin = _newAdmin;
        return true;
    }

    function _transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        transferOwnership(newOwner);
    }

    function creatoR(uint256 tokenId) public view returns(address){
        return _creator[tokenId];
    } 

    function royalty(uint256 _tokenid) public view returns(uint256) {
        return royaltyrates[_tokenid];
    }

    function safeTransferFrom(address _from, address _to, uint256 _id,uint256 _value) public {
        require(_to != address(0x0), "not transfer to the address of 0x0");

        if(_from == msg.sender){
            balances[_id][_from] = balances[_id][_from].sub(_value);
            balances[_id][_to]   = _value.add(balances[_id][_to]);

            emit TransferSingle(msg.sender, _id, _value);
        }

        else{
            require(operatorApproval[_from][msg.sender]);
            balances[_id][_from] = balances[_id][_from].sub(_value);
            balances[_id][_to]   = _value.add(balances[_id][_to]);

            emit TransferSingle(msg.sender, _id, _value);
        }
        // updatedata(_from,_to,_id);
        // MUST emit event

    }
    function updatedata(address _from,address _to,uint256 _id)internal returns(bool) {
        address[] memory _totalAddress =  ownerDetails[_id]._history;
        bool fropm;
        bool topm;
        for(uint256 i=0;i<_totalAddress.length;i++){
            if(_from == _totalAddress[i]){
                fropm = true;
                ownerDetails[_id]._history[i] = _from;
                ownerDetails[_id]._amount[i] = balances[_id][_from];
            }
            if(_to == _totalAddress[i]){
                topm = true;
                ownerDetails[_id]._history[i] = _to;
                ownerDetails[_id]._amount[i] = balances[_id][_to];
            }
        }
        if(!fropm){
            ownerDetails[_id]._history.push(_from);
            ownerDetails[_id]._amount.push(balances[_id][_from]);
        }
        if(!topm){
            ownerDetails[_id]._history.push(_to);
            ownerDetails[_id]._amount.push(balances[_id][_to]);
        }
        emit Updatedata(_from, _to, _id);
        return true;
    }
    function balanceOf(address _owner, uint256 _id) public view returns (uint256) {
        return balances[_id][_owner];
    }
    
    mapping(address=>mapping(address=>mapping(uint256=>mapping(uint256=> bool)))) public operatorApprovalByValue; 
    
    function setApprovalForAll(address from, address to, bool _approved, uint256 _id, uint256 _value) public returns(bool){
        require(from != to, "ERC1155: setting approval status for self");
        require(balances[_id][from] >= _value);
        operatorApproval[from][to] = _approved;
        operatorApprovalByValue[from][to][_id][_value] = _approved;
        operatorValueApproval[from][to][_id] = _value;
        emit ApprovalForAll(from, to, _approved);

        return true;
    }
    function setApprovalForAll(address to, bool _approved) public{
        require(msg.sender != to, "ERC1155: setting approval status for self");
        operatorApproval[msg.sender][to] = _approved;
        emit ApprovalForAll(msg.sender, to, _approved);
    }
    function isApprovedForAll(address from,address to)public view returns(bool){
        require(from != to, "ERC1155: setting approval status for self");
        return operatorApproval[from][to]; 
    }

    function getApproved(address from,address to,uint256 _id,uint256 _value)public view returns(bool){
        return (operatorApprovalByValue[from][to][_id][_value]);
    }

    function mint(uint256 _royaltyrate, uint256 _supply, string memory _uri) public returns(bool){
        tokenID = tokenID + 1;
        require(_creator[tokenID] == address(0x0), "Token is already minted");
        require(_supply != 0, "Supply should be positive");
        require(bytes(_uri).length > 0, "uri should be set");
        require(_royaltyrate <= 50, " Maximum Royaltyrate is 50%");

        _creator[tokenID] = msg.sender;
        valueof[tokenID] = _supply;
        balances[tokenID][msg.sender] = _supply;
        _setTokenURI(tokenID, _uri);
        totalQuantity[tokenID] = _supply;
        royaltyrates[tokenID] = _royaltyrate;

        emit TransferSingle(msg.sender, tokenID, _supply);

        return true;
    }
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        _tokenURIs[tokenId] = uri;
        emit URI(uri, tokenId);
    }

    function burn(address from, uint256 _id, uint256 _value) public {
        require(balances[_id][from] >= _value, "Only Burn Allowed Token Owner or insufficient Token Balance");
        require(operatorApproval[_creator[_id]][owner()] == true || from == msg.sender, "Need operator approval for 3rd party burns.");
        require(operatorValueApproval[from][owner()][_id] >= _value || from == msg.sender, "Value is not Approved by owner!");
        balances[_id][from] = balances[_id][from].sub(_value);
        if(totalQuantity[_id] == _value){
             address own = owner(); 
             operatorApproval[_creator[_id]][own] == false;
             delete _creator[_id];
        }
        totalQuantity[_id] = totalQuantity[_id].sub(_value);
        if(totalQuantity[_id] == 0){
            delete _tokenURIs[_id];
        }
        emit TransferSingle(from, _id, _value);
    }

    function listofOwner(uint256 tokenId)public view returns(address[] memory,uint256[] memory){
        require(_creator[tokenID] != address(0x0), "Token is not minted");
        return (ownerDetails[tokenId]._history, ownerDetails[tokenId]._amount);
    }

}