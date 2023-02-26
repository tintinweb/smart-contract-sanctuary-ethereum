/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

pragma solidity ^0.8.14;

interface UnknownToken {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function burnFrom(address from, uint256 amount) external returns(bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
}

interface Banned {
    function isBanned(address account) external view returns (bool);
}

contract OfficialSignature {
    string private _projectFlag;
    address private _contractOwner;
    address private _bannedContract;
    address private _unknownTokenContract;

    struct SignatureInfo {
        bytes32 commit;
        string[] signatures;
    }

    struct UserCommitPackageSign {
        uint256 isVerify;
        bytes32 commit;
        address contributor;
        string packageName;
        string[] signatures;
    }

    //already verify info
    mapping(string => string[]) private _packageSign;

    //user commit official package & sign
    UserCommitPackageSign[] private _userCommitPackageSign;

    event Deploy(address owner, string projectFlag, address bannedContract, address utContract);
    event UserCommit(address user, uint256 blockNumber, string packageName, string desc, string[] signData);
    event VerifySign(address verifier, uint256 blockNumber, string packageName, string[] signatures);
    event SetBanned(address contractOwner, uint256 blockNumber, address newBanned);

    modifier onlyOwner() {
        require(msg.sender == _contractOwner);
        _;
    }

    modifier onlyNotBanned() {
        if(address(_bannedContract) != address(0)) {
            require(!Banned(_bannedContract).isBanned(msg.sender), "account was banned.");
        }
        _;
    }

    constructor(address owner, address banned, address ut) {
        _projectFlag = "OfficialSignatureV1";
        _contractOwner = owner;
        _bannedContract = banned;
        _unknownTokenContract = ut;

        emit Deploy(_contractOwner, _projectFlag, _bannedContract, _unknownTokenContract);
    }

    function getUserCommitPackageSign(uint256 off) public view returns (UserCommitPackageSign memory) {
        return _userCommitPackageSign[off];
    }

    function getUserCommitsLength() public view returns (uint256) {
        return _userCommitPackageSign.length;
    }

    function getSignatureInfo(string memory package) public view returns (string[] memory) {
        return (_packageSign[package]);
    }

    //user commit
    function commitPackageSign(string memory packageName, string[] memory signs, string memory desc) public onlyNotBanned {
        require(signs.length > 0, "signs length must more than 0.");
        require(bytes(desc).length <= 128, "desc length more than 128 bytes.");
        require(bytes(packageName).length <= 256, "packageName length more than 256 bytes.");
        require(bytes(packageName).length > 0, "package name not null.");

        string memory signData = "";
        for(uint i=0;i < signs.length;i ++) {
            if((bytes(signs[i]).length != 32))
                revert();

            signData = string(abi.encodePacked(signData, signs[i]));
        }

        bytes32 commit = keccak256(abi.encodePacked(block.number, msg.sender, packageName, desc, signData));
        UserCommitPackageSign memory packageSignInfo = UserCommitPackageSign(0, commit, msg.sender, packageName, signs);
        _userCommitPackageSign.push(packageSignInfo);

        emit UserCommit(msg.sender, block.number, packageName, desc, signs);
    }

    //verify & reward - manager operate
    function setBannedContract(address newBanned) public onlyOwner {
        _bannedContract = newBanned;

        emit SetBanned(msg.sender, block.number, newBanned);
    }

    function verifySignatureInfo(bytes32[] memory verifyCommits, uint256 begin, uint256 end) public onlyOwner {
        uint256 arrayLength = _userCommitPackageSign.length;
        if(end == 0)
            end = arrayLength;

        require(end > begin, "the begin of array more than end.");

        uint256 verifyUsed = 0;
        for(uint256 off = begin; off < end; off ++) {
            if(verifyCommits[verifyUsed] == _userCommitPackageSign[off].commit) {
                if(_userCommitPackageSign[off].isVerify == 0) {
                    _packageSign[_userCommitPackageSign[off].packageName] = _userCommitPackageSign[off].signatures;
                    UnknownToken(_unknownTokenContract).transferFrom(msg.sender, _userCommitPackageSign[off].contributor, 1000);
                    _userCommitPackageSign[off].isVerify = 1;

                    emit VerifySign(msg.sender, block.number, _userCommitPackageSign[off].packageName, _userCommitPackageSign[off].signatures);
                }
                verifyUsed += 1;
            }

            if(verifyUsed == verifyCommits.length)
                break;
        }

    }

}