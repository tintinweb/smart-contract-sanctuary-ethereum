/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {

        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function mintFromContract(uint256 _amount , address recipient) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721 /* is ERC165 */ {
            event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

            event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

            event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


            function balanceOf(address _owner) external view returns (uint256);

            function ownerOf(uint256 _tokenId) external view returns (address);

            function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

            function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

            function approve(address _approved, uint256 _tokenId) external payable;

            function setApprovalForAll(address _operator, bool _approved) external;

            function getApproved(uint256 _tokenId) external view returns (address);

            function isApprovedForAll(address _owner, address _operator) external view returns (bool);

            function mintFromContract(address _recepient,uint256 index) external returns(uint256);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}



abstract contract ERC721Recipient is IERC721Receiver {

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        // do stuff

        return IERC721Receiver.onERC721Received.selector;
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

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Lootbox is Context , Ownable{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public _company_address ;
    
    uint256 public minPrice ;
    uint8 public maxMintCount = 5;
    uint256[] public _dragonType;

    struct Minted {
        uint256 _start_index;
        uint256 _current_index;
        uint256 _max_index;
        address _contract_address;
        bool status;
    }

    mapping(uint8 => Minted) public Dragon;
    mapping(uint8 => bool) public mintCount;

    constructor() {
        _company_address = 0xc122e5a96104a11e8BE06d954d64351Aa8bd7F7a;
        minPrice = 100000000000000;
        mintCount[1] = true;
        mintCount[3] = true;
        mintCount[5] = true;
    }

    function mintDragon(uint8 _count) external payable {
        require(mintCount[_count] == true,"Mint Not available");
        uint256 _total_payable = uint256(_count).mul(minPrice);
        require(msg.value == _total_payable,"Payable Not Matched");
        uint i=0;
        uint256[] memory _result = randomArray(_dragonType);
        for(i;i<_count;i++){
            uint256 _indexId = _result[i];
            require(Dragon[uint8(_indexId)].status == true,"No More Available");
        
            uint256 _newIndexd = Dragon[uint8(_indexId)]._current_index.add(1);
            Dragon[uint8(_indexId)]._current_index = _newIndexd;

            if(_newIndexd >= Dragon[uint8(_indexId)]._max_index)
            {
                Dragon[uint8(_indexId)].status = false;
            }

            uint256 mintIndex =Dragon[uint8(_indexId)]._start_index.add(_newIndexd);

              IERC721 _nft = IERC721(Dragon[uint8(_indexId)]._contract_address); 
            _nft.mintFromContract(msg.sender,mintIndex);
        }

        if(_count == 5) {

            require(Dragon[6].status == true,"No More Available");
        
            uint256 _newIndexd = Dragon[6]._current_index.add(1);
            Dragon[6]._current_index = _newIndexd;

            if(_newIndexd >= Dragon[6]._max_index)
            {
                Dragon[6].status = false;
            }

            uint256 mintIndex =Dragon[6]._start_index.add(_newIndexd);

              IERC721 _nft = IERC721(Dragon[6]._contract_address); 
            _nft.mintFromContract(msg.sender,mintIndex);
        }
    }

    function testRandom() external view returns(uint[] memory) {
        
        return randomArray(_dragonType);
    }

    function random(uint number) private view returns(uint){
        
        uint value = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
        return value;
    }

    function randomArray(uint[] memory _myArray) private view returns(uint[] memory){
        uint a = _myArray.length; 
        uint b = _myArray.length;
        for(uint i = 0; i< b ; i++){
            uint randNumber =(uint(keccak256      
            (abi.encodePacked(block.timestamp,_myArray[i]))) % a)+1;
            uint interim = _myArray[randNumber - 1];
            _myArray[randNumber-1]= _myArray[a-1];
            _myArray[a-1] = interim;
            a = a-1;
        }
        uint[] memory result;
        result = _myArray;       
        return result;        
    }
     
     
    function changeMintFee(uint256 _fee) external onlyOwner {
        require(_fee > 0,"Valid Mint Fee");
        minPrice = _fee;
    }

    function changeCompanyAddress(address _addr) external onlyOwner {
        require(_addr != address(0),"Valid Address Required");
        _company_address = _addr;
    }

    function addDragon(uint8 _type , uint256 _start_index , uint256 _max_count) external onlyOwner {
        require(Dragon[_type].status == false ,"Only New can Do");
        Dragon[_type].status = true;
        Dragon[_type]._start_index = _start_index;
        Dragon[_type]._max_index  = _max_count;

        if(_type <= 5)
            _dragonType.push(uint256(_type));
    }

    function updateNFTAddress(uint8 _type,address _addr) external onlyOwner {
        Dragon[_type]._contract_address = _addr;
    }

    function withdrawToken(address _token,uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 _bal = token.balanceOf(address(this));
        
        require(_amount <= _bal,"Over Balance");

        token.safeTransfer(_company_address,_amount);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        address payable _temp = payable(_company_address);
        _temp.transfer(balance);
    }

    function deleteKey(uint256 _key) external onlyOwner {
        for(uint i = _key; i < _dragonType.length-1; i++){
        _dragonType[i] = _dragonType[i+1];      
        }
        _dragonType.pop();
    }
}