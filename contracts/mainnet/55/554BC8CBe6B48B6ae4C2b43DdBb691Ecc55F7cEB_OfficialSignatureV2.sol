/**
 *Submitted for verification at Etherscan.io on 2023-03-19
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

contract OfficialSignatureV2 {
    string private _projectFlag;
    address private _contractOwner;
    address private _bannedContract;
    address private _unknownTokenContract;

    //already verify info
    mapping(string => bool) private _packageSign;

    event Deploy(address owner, string projectFlag, address bannedContract, address utContract);
    event UserCommit(address user, uint256 blockNumber, string packageName, string desc, string sign, bool isGenuine);
    event VerifySign(address verifier, string packageSign, address contributor, bool isGenuine);
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
        _projectFlag = "OfficialSignatureV2";
        _contractOwner = owner;
        _bannedContract = banned;
        _unknownTokenContract = ut;

        emit Deploy(_contractOwner, _projectFlag, _bannedContract, _unknownTokenContract);
    }

    function isGenuineSign(string memory packageSign) public view returns (bool) {
        return (_packageSign[packageSign]);
    }

    function calculatePackageSign(string memory package, string memory sign) public view returns(string memory) {
        string memory packageSign = string(abi.encodePacked(package, sign));
        return packageSign;
    }

    //user commit
    function commitPackageSigns(string[] memory packageNames, string[] memory signs, string[] memory desc, bool[] memory isGenuine) public onlyNotBanned {
        require(packageNames.length > 0, "must input 1 package.");
        require(signs.length == packageNames.length, "array length should equal.");
        require(signs.length == desc.length, "array length should equal.");
        require(signs.length == isGenuine.length, "array length should equal.");

        for(uint i=0;i < signs.length;i ++) {
            if((bytes(signs[i]).length != 32))
                revert();
            if((bytes(packageNames[i]).length > 256))
                revert();
            if((bytes(desc[i]).length > 256))
                revert();

            emit UserCommit(msg.sender, block.number, packageNames[i], desc[i], signs[i], isGenuine[i]);
        }
    }

    //verify & reward - manager operate
    function setBannedContract(address newBanned) public onlyOwner {
        _bannedContract = newBanned;

        emit SetBanned(msg.sender, block.number, newBanned);
    }

    function verifySignatureInfo(string[] memory packageSigns, address[] memory contributors) public onlyOwner {
        require(packageSigns.length == contributors.length, "array length should equal.");

        for(uint256 off = 0; off < packageSigns.length; off ++) {
            if(!_packageSign[packageSigns[off]]) {
                _packageSign[packageSigns[off]] = true;
                UnknownToken(_unknownTokenContract).transferFrom(msg.sender, contributors[off], 500);
                emit VerifySign(msg.sender, packageSigns[off], contributors[off], true);
            } else {
                _packageSign[packageSigns[off]] = false;
                UnknownToken(_unknownTokenContract).transferFrom(msg.sender, contributors[off], 500);
                emit VerifySign(msg.sender, packageSigns[off], contributors[off], false);
            }
        }

    }

}