/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// SPDX-License-Identifier: BUSL-1.1
// author: [email protected] 


pragma solidity ^0.8.0;


contract Administrator {
    address public Admin;                           //管理员，热钱包，执行日常操作

    modifier onlyAdmin {
        require(msg.sender == Admin || msg.sender == SuperAdmin);
        _;
    }

    function setAdmin(address _value) onlyAdmin external {
        Admin = _value;
    }

    address public SuperAdmin;                      //超级管理员，冷钱包  万不得已的时候使用   安全性加强

    modifier onlySuperAdmin {
        require(msg.sender == SuperAdmin, "2");
        _;                     
    }

    function setSuperAdmin(address _value) onlySuperAdmin external {
        SuperAdmin = _value;
    }

    constructor(address admin_, address superAdmin_) 
    {
        Admin = admin_;
        SuperAdmin = superAdmin_;
    }

}


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract AppInfo is Administrator{

    uint public FromBlock;      

    constructor (address admin_, address superAdmin_)  Administrator (admin_, superAdmin_) {
        FromBlock = block.number - 1;
        Donation= admin_;               //捐款地址默认是Admin， 不能用 SuperAdmin ！ 
    }
    
    /////////////////////////////////////////////////////////////////////

    address public Donation;            //捐款钱包 不能是合约，可能会执行失败的。      

    function setDonation(address _value) external onlyAdmin {
        Donation = _value;
    }

    string public ContactInfo;          //联系信息

    function setContactInfo(string calldata _ContactInfo) external onlyAdmin {
        ContactInfo = _ContactInfo;
    }

    /////////////////////////////////////////////////////////////////////

    struct Download {   
        string  HttpLink;           //http 链接，
        string  BTLink;             //如果BT采用Margin链接，仍然是一个 bytes32 ，使用 string 具有很强的扩展性
        string  eMuleLink;          //edonkey 链接，包括多部分信息，唯一标识（bytes32），标题，等
        string  IpfsLink;           //ipfs Source
        string  OtherLink;          //swarm source 没有使用了，（类似：bzzr://645ee12d73db47fd78ba77fa1f824c3c8f9184061b3b10386beb4dc9236abb28）
    }
       
    //AppId, 唯一标识一个App， 
    struct AppVersion {   
        uint    Version;            
        bytes32 Sha256Value;
        string  AppName;
        string  UpdateInfo;
        string  IconUri;            //App的图标地址
    }
   

    mapping(uint => mapping(uint => AppVersion))    public CurAppVersionOf;         // AppId =》 操作系统平台 => 信息（当前版本）
    mapping(uint => mapping(uint => Download))      public CurAppDownloadOf;        // AppId =》 操作系统平台 => 下载（当前版本）
    
    uint public CurEventId = 1;
    function getEventId() internal returns(uint _result) {
        _result = CurEventId;
        CurEventId ++;
    }

    event OnPublishAppVersion(uint indexed _AppId, uint indexed _PlatformId, uint indexed _Version, bytes32 _Sha256Value,
                                string  _AppName, string  _UpdateInfo, string  _IconUri, uint _eventId);
    
    function publishAppVersion(uint _AppId, uint _PlatformId, uint _Version, bytes32  _Sha256Value, string calldata _AppName, 
        string calldata _UpdateInfo, string calldata _IconUri) external onlyAdmin
    {
        require(bytes(_AppName).length <= 128, "1");
        require(bytes(_UpdateInfo).length <= 1024, "2");
        require(bytes(_IconUri).length <= 1024, "3");
        // require(_PlatformId >= 10 && _PlatformId <= 99, "PA");
        AppVersion memory VersionInfo = AppVersion({
            Version : _Version,    
            Sha256Value : _Sha256Value,
            AppName : _AppName,
            UpdateInfo : _UpdateInfo,
            IconUri : _IconUri
        });

        CurAppVersionOf[_AppId][_PlatformId] = VersionInfo;             
        emit OnPublishAppVersion(_AppId,  _PlatformId,  _Version,   _Sha256Value,   _AppName,   _UpdateInfo,   _IconUri, getEventId());
    }

    event OnPublishAppDownload(uint _AppId, uint indexed _PlatformId, uint indexed _version, string  _HttpLink,  string _BTLink, string _eMuleLink, 
                                    string _IpfsLink, string _OtherLink, uint _eventId);
    
    function publishAppDownload(uint _AppId, uint _PlatformId, uint _Version, string[] calldata _Links) external onlyAdmin
    {
        require(_Links.length == 5, "0");
        require(bytes(_Links[0]).length <= 1024, "1");
        require(bytes(_Links[1]).length <= 1024, "2");
        require(bytes(_Links[2]).length <= 1024, "3");
        require(bytes(_Links[3]).length <= 1024, "4");
        require(bytes(_Links[4]).length <= 1024, "5");
        // require(_PlatformId >= 10 && _PlatformId <= 99, "PA");
        // VersionInfo storage vi =  CurAppVersionOf[_AppId][_PlatformId];
        // require(vi.Version == _Version, "Version");        
        Download memory DownloadInfo = Download({
            HttpLink    : _Links[0],
            BTLink      : _Links[1],
            eMuleLink   : _Links[2],
            IpfsLink    : _Links[3],
            OtherLink   : _Links[4]
        });

        CurAppDownloadOf[_AppId][_PlatformId] = DownloadInfo;             
        emit OnPublishAppDownload(_AppId, _PlatformId, _Version, _Links[0], _Links[1], _Links[2], _Links[3], _Links[4], getEventId());
    }

    /////////////////////////////////////////////////////////////////////
      
    event OnPublishNotice(uint _appId, string _subject, string _body, address _publisher); 

    //发布通知消息, 通过这种方式，可以给特定的页面发送通知消息！只需要在客户端定义好 _noticeId 就行。这个功能已经在使用了！
    function PublishNotice(uint _appId, string calldata _subject, string calldata _body) external onlyAdmin returns (bool _result) {
        require(0 < _appId && _appId < 2**63 , "P1");                             //8 字节，不要太大，对应 bigint	-2^63 (-9,223,372,036,854,775,808) 到 2^63-1 (9,223,372,036,854,775,807)	
        require(bytes(_subject).length > 0 && bytes(_subject).length < 256, "P2");
        require(bytes(_body).length > 0, "P3");
        emit OnPublishNotice( _appId, _subject,  _body, msg.sender);
        return true;
    }   

    /////////////////////////////////////////////////////////////////////

    //把各个合约的地址注册到这里

    function getKey(string calldata _strkey) public pure returns (uint) { 
        bytes32 Hashvalue = keccak256(abi.encode(_strkey)); // keccak256(_strkey);
        uint key = uint(Hashvalue);
        return key;       
    }

    mapping(uint256 => address) public KeyAddress;     //保存地址    

    function getKeyAddress(uint256 _key)  external  view returns (address) {    
        return KeyAddress[_key];
    }

    function getKeyAddress1(string calldata _strkey) external  view returns (address) {    
        uint _key = getKey(_strkey);
        return KeyAddress[_key];
    }

    function saveKeyAddress(uint256 _key, address _value)  external  onlyAdmin { 
        require(_key > 0, "V3");
        KeyAddress[_key] = _value;
    }

    function saveKeyAddress1(string calldata _strkey, address _value)  external  onlyAdmin { 
        uint _key = getKey(_strkey);
        require(_key > 0, "V4");
        KeyAddress[_key] = _value;
    }
    

    mapping(uint256 => string) public KeyString;            //保存字符串     

    function getKeyString(uint256 _key)  external  view returns (string memory) {    
        return KeyString[_key];
    }

    function getKeyString1(string calldata _strkey) external  view returns (string memory) {    
        uint _key = getKey(_strkey);
        return KeyString[_key];
    }

    function saveKeyString(uint256 _key, string calldata _value)  external  onlyAdmin { 
        require(_key > 0, "V1");
        KeyString[_key] = _value;
    }

    function saveKeyString1(string calldata _strkey, string calldata _value) external  onlyAdmin { 
        uint _key = getKey(_strkey);
        require(_key > 0, "V2");
        KeyString[_key] = _value;
    }

    /////////////////////////////////////////////////////////////////////

    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }


    /////////////////////////////////////////////////////////////////////


    //捐款可能打过来！
    function withdraw(address _token) external {
        if (_token == address(0)) {
            uint amount = address(this).balance;
            if (amount > 0) {
                payable(Donation).transfer(amount);
            }          
        }
        else
        {
            uint amount = IERC20(_token).balanceOf(address(this));  
            if (amount > 0) {
                IERC20(_token).transfer(Donation, amount);
            }          
        }
    } 


    // receive() external payable {        
    // }
    
    // fallback() external {
    // }

}