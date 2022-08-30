/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

interface IERC20 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external view returns(uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721Receiver {
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) external returns (bytes4);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(address,address,uint256,bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function verifyCallResultFromTarget(address target,bool success,bytes memory returndata,string memory errorMessage) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(bool success,bytes memory returndata,string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

library SafeERC20 {

    using Address for address;

    function safeTransfer(IERC20 token,address to,uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token,address from,address to,uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

}

abstract contract Context {

    function _msgSender() internal view returns(address){
        return(msg.sender);
    }

    function _msgData() internal pure returns(bytes memory){
        return(msg.data);
    }

}

abstract contract Ownable is Context{

    address private _owner;

    event TransferOwnerShip(address indexed oldOwner, address indexed newOwner, uint256 indexed time);

    constructor () {
        _owner = _msgSender();
        emit TransferOwnerShip(address(0), _owner ,block.timestamp);
    }

    function owner() public view returns(address){
        return _owner;
    }

    modifier onlyOwner {
        require(_owner == _msgSender(),"NOT AN OWNER");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0),"ZEROADDRESS");
        require(newOwner != _owner, "ENTERING OLD_OWNER_ADDRESS");

        address _oldOwner = _owner;
        _transferOwnership(newOwner);

        emit TransferOwnerShip(_oldOwner, newOwner ,block.timestamp);
    }

    function _transferOwnership(address newOwner) internal onlyOwner {
        _owner = newOwner;
    }

    function renonceOwnerShip() public onlyOwner {
        _owner = address(0);
    }
}

contract vesting is Ownable, ERC721Holder{

    address public ERC20;

    uint256 public sequenceId;
    uint256 public stackingFees = 1 * 10 ** 18;
    uint256 public rate = 2;
    uint256 private rewardMulitiplier = 2;
    uint256 private constant denominator = 1000;

    struct userDetails{
        address token;
        uint256[] tokenId;
        uint256 amount;
        uint256 expiry;
    }

    mapping(address => mapping(uint256 => userDetails)) public details;

    event Stack(
        address _token,
        address indexed _user,
        uint256 indexed _sequenceId,
        uint256[] indexed _tokenId,
        uint256 time
    );

    event Claim(
        address _token,
        address indexed _user,
        uint256 indexed _sequenceId,
        uint256[] indexed _tokenId,
        uint256 reward,
        uint256 time
    );

    function stack(address _token, uint256[] calldata _tokenId, uint256 _amount) external {
        require(_token != address(0), 'ZERO ADDRESS');
        require(_amount == calculatePrice(_tokenId.length), 'INVALID AMOUNT');

        sequenceId++;
        SafeERC20.safeTransferFrom(IERC20(ERC20), _msgSender(), address(this), _amount);

        userDetails storage user = details[_msgSender()][sequenceId];
        user.token = _token;
        user.amount = _amount;
        user.expiry = block.timestamp + 30 days;

        for(uint i=0; i<_tokenId.length; i++){
            require(IERC721(_token).ownerOf(_tokenId[i]) == _msgSender(), 'NOT AN OWNER OF TOKEN');
            IERC721(_token).safeTransferFrom(_msgSender(),address(this),_tokenId[i]);
            user.tokenId.push(_tokenId[i]);
        }

        emit Stack(_token, _msgSender(), sequenceId, _tokenId, block.timestamp);
    }

    function claim(uint256 _sequenceId) external {
        require(_sequenceId <= sequenceId && _sequenceId != 0, 'INVALID SEQUENCE ID');
        userDetails memory user = details[_msgSender()][_sequenceId];
        require(user.expiry <= block.timestamp, 'EXPIRY TIME IS NOT EXPIRY');

        IERC721 token = IERC721(user.token);
        uint256 length = user.tokenId.length;
        uint256[] memory tokenId = user.tokenId;
        uint32 numberOfSeconds = uint32(block.timestamp) - uint32(user.expiry);
        uint32 numberOfDays = numberOfSeconds / 24 / 60 / 60;
        uint256 amount = user.amount;
        uint256 reward = amount * rewardMulitiplier;
        address NFTreceiver = _msgSender();

        if(numberOfDays > 2){
            reward = penalityCalculation(numberOfDays, amount);
            if(numberOfDays > 10) NFTreceiver = owner();
        }

        for(uint i=0; i<length; i++){
            token.safeTransferFrom(address(this), NFTreceiver, tokenId[i]);
        }

        SafeERC20.safeTransfer(IERC20(ERC20), _msgSender(), reward);
        delete details[_msgSender()][_sequenceId];

        emit Claim(address(token), _msgSender(), _sequenceId, tokenId, reward, block.timestamp);
    }

    function setRate(uint256 _rate) external onlyOwner{
        require(_rate > 0, 'INVALID RATE');
        rate = _rate;
    }

    function setStackingFees(uint256 _fees) external onlyOwner returns(bool){
        require(_fees != 0, 'INVALID FEES');
        stackingFees = _fees;
        return true;
    }

    function setRewardMultiplier(uint256 _multiplier) external onlyOwner returns(bool){
        require(_multiplier != 0, 'INVALID FEES');
        rewardMulitiplier = _multiplier;
        return true;
    }

    function setToken(address _token) external onlyOwner returns(bool){
        ERC20 = _token;
        return true;
    }

    function calculatePrice(uint256 _numTokens) public view returns(uint256){
        return _numTokens * stackingFees;
    }

    function penalityCalculation(uint32 _numberOfDays, uint256 _amount) internal view returns(uint256 reward){
        uint256 penality = _amount * _numberOfDays / denominator;
        reward = _amount - penality;
        if(reward <= 0) reward = 0;
        this;
    }

}