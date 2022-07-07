/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

pragma solidity 0.8.13;
//SPDX-License-Identifier:Unlicensed

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        assembly {
            c := add(a,b)
        }
        require(c >= a, "SafeMath: addition overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "SafeMath subraction overFloe");
        assembly {
            c := sub(a,b)
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        assembly {
            c := mul(a,b)
        }
        require(c / a == b, "SafeMath: multiplication overflow");
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0,  "SafeMath: division by zero");
        assembly {
            c := div(a,b)
        }
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256 res) {
        require(b != 0, "SafeMath: modulo by zero");
        assembly {
            res := mod(a,b)
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

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract preSaleNFT is Ownable{

    using SafeMath for uint256;

    error wrongValue(string _msg, uint256 _price);

    event BookNFT(address indexed _buyer, uint256[] indexed _tokenId, uint256[] indexed _amount, uint256 _value);

    struct details {
        uint256[] id;
        uint256[] amount;
    }

    uint256 private price = 1 ether;
    bool private saleStatus;
    uint256 private numberOfUser;
    address public nftContract;

    bytes4 private constant SELECTORMINT = bytes4(keccak256(bytes('mintBatch(address,uint256[],uint256[],bytes)')));

    mapping(uint256 => address) private userList;
    mapping(address => details) private detail;

    constructor(address _contractAddress){
        nftContract = _contractAddress;
    }

    function startSale() external onlyOwner {
        require(!saleStatus, "ALREADY STARTED");
        saleStatus = true;
    }

    function stopSale() external onlyOwner {
        require(saleStatus, "ALREADY STOPPED");
        saleStatus = false;
    }

    function updatePrice(uint256 _amount) external onlyOwner{
        price = _amount;
    }

    function findAddress(uint256 _userID) external view returns(address){
        require(_userID > 0 && _userID <= numberOfUser,"wrong userID");
        return userList[_userID];
    }

    function currentPrice() external view returns(uint256){
        return price;
    }

    function saleCurrentStatus() external view returns(bool){
        return saleStatus;
    }

    function numberOfUsers() external view returns(uint256){
        return numberOfUser;
    }

    function getDetails(address _account) external view returns(details memory){
        return detail[_account];
    }

    function bookNFT(uint256[] calldata _id, uint256[] calldata _amount) external payable{
        require(_id.length == _amount.length, "ID AND AMOUNT LENGTH IS NOT MATCHING");
        require(saleStatus,"SALE IS NOT STARTED");

        uint256 _msgValue = price.mul(_amount.length);
        if(msg.value != _msgValue){
            revert wrongValue("Your Price is",_msgValue);
        }

        _transferFee(owner(),_msgValue);
        _registerDetails(_id,_amount);

        emit BookNFT(_msgSender(),_id,_amount,_msgValue);
    }

    function _transferFee(address _account, uint256 _amount) internal{
        payable(_account).transfer(_amount);
    }

    function _registerDetails(uint256[] calldata _id, uint256[] calldata _amount) internal {
        details storage Details = detail[_msgSender()];

        for(uint256 i=0; i < _amount.length; i++){
            Details.id.push(_id[i]);
            Details.amount.push(_amount[i]);
        }

        numberOfUser++;
        userList[numberOfUser] = _msgSender();
    }

    function provideNFT() external onlyOwner{
        require(!saleStatus, "SALE NEED TO STOP");
        require(checkRights(), "PLEASE GET RIGHTS");

        for(uint256 i = 1; i <= numberOfUser; i++){
            address _user = userList[i];

            uint256[] memory value = detail[_user].id;
            uint256[] memory Amount = detail[_user].amount;

            (bool success, ) = nftContract.call(abi.encodeWithSelector(SELECTORMINT,_user,value,Amount,"0x00000000"));
            if(success){
                delete detail[_user];
                delete userList[i];
            }
        }
    }

    function checkRights() internal returns(bool){
        (,bytes memory data ) = nftContract.call(abi.encodeWithSignature("rightsStatus(address)",address(this)));
        return abi.decode(data,(bool));
    }
}