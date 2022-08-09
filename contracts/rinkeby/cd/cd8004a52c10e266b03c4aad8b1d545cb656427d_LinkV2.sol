/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

interface IERC721{
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface Ifactory{
    function getToken(address nft, address userB, uint256 id) external;
}


contract Initialize {
    bool internal initialized;
    modifier noInit(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}


contract Enum {
    Status public status;
    enum Status {INITED, AGREED, CLOSED}
    enum MethodId {setUserB, agree, reject, pledge, depledge, close, repealCloseReq, rejectClose, wtihdrawSelf}
    
    function _init() internal {status = Status.INITED;}

    function _agree() internal {status = Status.AGREED;}

    function _close() internal {status = Status.CLOSED;}
}


contract LinkV2 is Initialize, Enum{
    using SafeMath for uint256;
    //string  public symbol;
    address public factory;
    address public NFT;
    address public userA;
    address public userB;
    uint256 public idA;
    uint256 public idB;
    address public closer;
    uint256 public lockDays;
    uint256 public startTime;
    uint256 public expiredTime;
    bool    public closeReqA;
    bool    public closeReqB;
    uint256 public closeTime;

    modifier onlyFactory(){
        require(msg.sender == factory, "Link: noly factory");
        _;
    }

    modifier onlyLinkUser(){
        require(msg.sender == userA || msg.sender == userB, "Link: access denied");
        _;
    }

    modifier onlyUserB(){
        require(msg.sender == userB, "Link: noly userB");
        _;
    }

    modifier onlyINITED(){
        require(status == Status.INITED, "Link: only initialized");
        _;
    }

    modifier onlyAGREED(){
        require(status == Status.AGREED, "Link: only agreed");
        _;
    }

    modifier unCLOSED(){
        require(status != Status.CLOSED, "Link: only unclosed");
        _;
    }

    function initialize(address _factory, address _nft, address _userA, address _userB, uint256 _idA, uint256 _idB, uint256 _lockDays) external{
        (factory, NFT, userA, userB, idA, idB, lockDays ) = (_factory, _nft, _userA, _userB, _idA, _idB, _lockDays);
     
        if(_idB != 0){
            startTime = block.timestamp;
            expiredTime = startTime.add(lockDays.mul(1 days));
            _agree();
        }else{
            _init();
        }
    }

    function agree(uint256 _idB) external onlyUserB onlyINITED{
        require(_idB != 0, "idB can`t be 0");
        idB = _idB;
        Ifactory(factory).getToken(NFT, userB, idB);
        startTime = block.timestamp;
        expiredTime = startTime.add(lockDays.mul(1 days));
        _agree();
    }

    function reject() external onlyUserB onlyINITED{
        _close();
    }


    function close() external onlyLinkUser unCLOSED{
        if(msg.sender == userA){
            require(!closeReqA,"repeat close");
            closeReqA = true;
        }else{
            require(!closeReqB,"repeat close");
            closeReqB = true;
        }
        //到期判断
        require(block.timestamp >= expiredTime);

        if (closeReqA && closeReqB){
            IERC721(NFT).transferFrom(address(this), userA, idA);
            IERC721(NFT).transferFrom(address(this), userB, idB);
        }

        _close();
        closer = msg.sender;
        closeTime = block.timestamp;
    }

}